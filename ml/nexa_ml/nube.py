"""Acceso a AWS y a MongoDB para la Lambda mediadora. Todo lo que habla con la red vive aquí.

- S3 (`BUCKET`): `modelos/actual.json` → {"version": n, "prefijo": "modelos/vN/"}; en el prefijo,
  `metadatos.json`, `factores.json` y `modelo.tflite`.
- DynamoDB (`TABLA`): ítem `programacion` y un ítem por entrenamiento (`tipo = entrenamiento`).
- Parameter Store: `PARAM_JWT` (secreto del JWT de la web) y `PARAM_MONGO` (usuario de solo lectura).
- MongoDB Atlas (`motvirsweb.servicios`): solo lectura y con proyección, nunca colecciones completas.
"""
from __future__ import annotations

import json
import os
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from pathlib import Path
from typing import Any

import boto3
from botocore.exceptions import ClientError

from . import caracteristicas as car
from . import satisfaccion as sat
from .datos import CAMPOS

# Solo los campos que usan el modelo y el panel (nada de nombres, teléfonos ni recorridos).
_CAMPOS_VIAJE = {c: 1 for c in (*CAMPOS, "origen", "destino", "estado")}


def _a_dynamo(valor: Any) -> Any:
    """DynamoDB no acepta float: se guardan como Decimal."""
    return json.loads(json.dumps(valor), parse_float=Decimal)


def _de_dynamo(valor: Any) -> Any:
    if isinstance(valor, list):
        return [_de_dynamo(v) for v in valor]
    if isinstance(valor, dict):
        return {k: _de_dynamo(v) for k, v in valor.items()}
    if isinstance(valor, Decimal):
        return int(valor) if valor == valor.to_integral_value() else float(valor)
    return valor


class Nube:
    """Implementación real. La Lambda crea una por contenedor y la reutiliza entre invocaciones."""

    def __init__(self, entorno: dict | None = None):
        e = entorno or os.environ
        self.bucket = e["BUCKET"]
        self.tabla = boto3.resource("dynamodb").Table(e["TABLA"])
        self.param_jwt = e.get("PARAM_JWT", "")
        self.param_mongo = e["PARAM_MONGO"]
        self.base = e.get("MONGO_BASE", "motvirsweb")
        # Tarea de entrenamiento en ECS Fargate (la lanza la mediadora).
        self.cluster = e.get("CLUSTER", "")
        self.tarea = e.get("TAREA", "")
        self.subredes = [s for s in e.get("SUBREDES", "").split(",") if s]
        self.grupo_seguridad = e.get("GRUPO_SEGURIDAD", "")
        self.rol_programador = e.get("ROL_PROGRAMADOR", "")
        self.mi_arn = e.get("MI_ARN", "")
        self.s3 = boto3.client("s3")
        self.ssm = boto3.client("ssm")
        self.ecs = boto3.client("ecs")
        self.scheduler = boto3.client("scheduler")
        self._secretos: dict[str, str] = {}
        self._mongo = None
        self._cache_modelo: dict[str, Any] = {}

    # ----------------------------------------------------------------- secretos
    def secreto(self, nombre: str) -> str:
        if nombre not in self._secretos:
            r = self.ssm.get_parameter(Name=nombre, WithDecryption=True)
            self._secretos[nombre] = r["Parameter"]["Value"]
        return self._secretos[nombre]

    def secreto_jwt(self) -> str:
        return self.secreto(self.param_jwt)

    # ----------------------------------------------------------------- MongoDB
    def _servicios(self):
        if self._mongo is None:
            from pymongo import MongoClient  # import tardío: arranque en frío más corto si no se usa

            self._mongo = MongoClient(self.secreto(self.param_mongo), serverSelectionTimeoutMS=8000,
                                      connectTimeoutMS=8000, maxPoolSize=2)
        return self._mongo[self.base]["servicios"]

    def viajes_finalizados(self, desde: datetime, hasta: datetime, limite: int = 20_000) -> list[dict]:
        cursor = (self._servicios()
                  .find({"estado": "FINALIZADO", "fechaFinalizacion": {"$gte": desde, "$lt": hasta}},
                        _CAMPOS_VIAJE)
                  .sort("fechaFinalizacion", 1).limit(limite))
        return list(cursor)

    def conteos_notas(self) -> dict:
        """Notas y 'no' por lado en los viajes que el entrenamiento puede usar (con llegada verificada)."""
        filtro = {"estado": "FINALIZADO", "fechaLlegada": {"$ne": None}}
        salida = {}
        for lado, campo in sat.CAMPO_NOTA.items():
            col = self._servicios()
            notas = col.count_documents({**filtro, campo: {"$ne": None}})
            no = col.count_documents({**filtro, campo: {"$lt": sat.NOTA_SATISFECHO}})
            salida[lado] = {"calificaciones": notas, "no": no}
        return salida

    def finalizados_desde(self, desde: datetime | None) -> int:
        filtro: dict = {"estado": "FINALIZADO", "fechaLlegada": {"$ne": None},
                        "$or": [{c: {"$ne": None}} for c in sat.CAMPO_NOTA.values()]}
        if desde is not None:
            filtro["fechaFinalizacion"] = {"$gt": desde}
        return self._servicios().count_documents(filtro)

    # ----------------------------------------------------------------- S3 (modelo publicado)
    def _json_s3(self, clave: str) -> dict | None:
        try:
            return json.loads(self.s3.get_object(Bucket=self.bucket, Key=clave)["Body"].read())
        except ClientError as e:
            if e.response["Error"]["Code"] in ("NoSuchKey", "404"):
                return None
            raise

    def modelo_publicado(self) -> tuple[dict | None, dict | None, dict | None]:
        """(actual, metadatos, factores) del modelo publicado; (None, None, None) si no hay ninguno."""
        actual = self._json_s3("modelos/actual.json")
        if not actual:
            return None, None, None
        clave = f"{actual['prefijo']}|{actual['version']}"
        if self._cache_modelo.get("clave") != clave:
            self._cache_modelo = {
                "clave": clave,
                "meta": self._json_s3(actual["prefijo"] + "metadatos.json"),
                "factores": self._json_s3(actual["prefijo"] + "factores.json"),
                "predictor": None,
            }
        return actual, self._cache_modelo["meta"], self._cache_modelo["factores"]

    def predictor(self):
        """Predictor LiteRT del modelo publicado (se descarga a /tmp una vez por versión)."""
        actual, meta, _ = self.modelo_publicado()
        if not actual or not meta:
            return None
        if self._cache_modelo.get("predictor") is None:
            from .inferencia import Predictor

            ruta = Path("/tmp") / f"modelo-v{actual['version']}.tflite"
            if not ruta.exists():
                self.s3.download_file(self.bucket, actual["prefijo"] + "modelo.tflite", str(ruta))
            self._cache_modelo["predictor"] = Predictor(ruta)
        return self._cache_modelo["predictor"]

    # ----------------------------------------------------------------- DynamoDB
    def programacion(self) -> tuple[dict, datetime | None]:
        item = self.tabla.get_item(Key={"id": "programacion"}).get("Item")
        if not item:
            return dict(sat.PROGRAMACION_INICIAL), None
        item = _de_dynamo(item)
        guardada = datetime.fromisoformat(item["guardadaEn"]) if item.get("guardadaEn") else None
        return {k: item.get(k, v) for k, v in sat.PROGRAMACION_INICIAL.items()}, guardada

    def guardar_programacion(self, p: dict, momento: datetime) -> None:
        self.tabla.put_item(Item=_a_dynamo({"id": "programacion", **p, "guardadaEn": momento.isoformat()}))

    def entrenamientos(self) -> list[dict]:
        """Todos los registros de entrenamiento, del más nuevo al más viejo (la tabla es pequeña)."""
        items, inicio = [], None
        while True:
            kw = {"FilterExpression": "tipo = :t", "ExpressionAttributeValues": {":t": "entrenamiento"}}
            if inicio:
                kw["ExclusiveStartKey"] = inicio
            r = self.tabla.scan(**kw)
            items.extend(_de_dynamo(i) for i in r.get("Items", []))
            inicio = r.get("LastEvaluatedKey")
            if not inicio:
                break
        return sorted(items, key=lambda i: i.get("fecha") or "", reverse=True)

    def entrenamiento(self, ident: str) -> dict | None:
        item = self.tabla.get_item(Key={"id": ident}).get("Item")
        return _de_dynamo(item) if item and item.get("tipo") == "entrenamiento" else None

    def guardar_entrenamiento(self, registro: dict) -> None:
        self.tabla.put_item(Item=_a_dynamo(registro))

    def cancelar_entrenamiento(self, ident: str) -> bool:
        """Marca CANCELADO solo si sigue en curso (condicional: no pisa un final)."""
        finales = list(sat.ESTADOS_FINALES)
        valores = {f":f{i}": e for i, e in enumerate(finales)}
        try:
            self.tabla.update_item(
                Key={"id": ident},
                UpdateExpression="SET cancelar = :si, estado = :c, mensaje = :m",
                ConditionExpression="attribute_exists(id) AND NOT estado IN (" + ", ".join(valores) + ")",
                ExpressionAttributeValues={":si": True, ":c": "CANCELADO", ":m": "Cancelado por el admin", **valores},
            )
            return True
        except ClientError as e:
            if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
                return False
            raise

    # ----------------------------------------------------------------- entrenar y programar
    def lanzar_entrenamiento(self, carga: dict) -> bool:
        """Lanza la tarea de entrenamiento en ECS Fargate. False si todavía no está desplegada."""
        if not (self.cluster and self.tarea and self.subredes and self.grupo_seguridad):
            return False
        try:
            r = self.ecs.run_task(
                cluster=self.cluster, taskDefinition=self.tarea, launchType="FARGATE", count=1,
                networkConfiguration={"awsvpcConfiguration": {
                    "subnets": self.subredes, "securityGroups": [self.grupo_seguridad],
                    "assignPublicIp": "ENABLED"}},  # sale a internet (Atlas, S3) sin NAT
                overrides={"containerOverrides": [{"name": "entrenamiento", "environment": [
                    {"name": "ENTRENAMIENTO_ID", "value": carga["id"]},
                    {"name": "PUBLICAR_SOLO_SI_MEJORA", "value": str(bool(carga.get("publicarSoloSiMejora", True))).lower()},
                ]}]},
                startedBy=carga["id"][:36],
            )
        except ClientError as e:
            if e.response["Error"]["Code"] in ("ClusterNotFoundException", "AccessDeniedException",
                                               "InvalidParameterException"):
                return False
            raise
        return bool(r.get("tasks"))

    # ----------------------------------------------------------------- escritura (solo la entrenadora)
    def subir(self, clave: str, contenido: bytes, tipo: str) -> None:
        self.s3.put_object(Bucket=self.bucket, Key=clave, Body=contenido, ContentType=tipo)

    def subir_json(self, clave: str, valor: Any) -> None:
        self.subir(clave, json.dumps(valor, ensure_ascii=False, indent=2, default=str).encode("utf-8"),
                   "application/json")

    def programar(self, p: dict) -> None:
        """Crea, actualiza o apaga el horario `nexa-entrenamiento` de EventBridge Scheduler."""
        nombre = "nexa-entrenamiento"
        if not self.rol_programador or not self.mi_arn:
            raise sat.ErrorContrato(503, "programacion_no_disponible",
                                    "La programación todavía no está configurada en AWS.")
        definicion = {
            "Name": nombre,
            "ScheduleExpression": sat.expresion_programacion(p),
            "ScheduleExpressionTimezone": "America/Bogota",
            "FlexibleTimeWindow": {"Mode": "OFF"},
            "State": "ENABLED" if p["activa"] else "DISABLED",
            "Target": {"Arn": self.mi_arn, "RoleArn": self.rol_programador,
                       "Input": json.dumps({"accion": "entrenar_programado"})},
        }
        try:
            self.scheduler.update_schedule(**definicion)
        except ClientError as e:
            if e.response["Error"]["Code"] != "ResourceNotFoundException":
                raise
            self.scheduler.create_schedule(**definicion)

    def fin_ultimo_modelo(self) -> datetime | None:
        """Fecha del último viaje usado por el modelo publicado (para 'solo con datos nuevos')."""
        _, meta, _ = self.modelo_publicado()
        hasta = ((meta or {}).get("datos") or {}).get("hasta")
        if not hasta:
            return None
        fecha = datetime.fromisoformat(str(hasta).replace("Z", "+00:00"))
        return fecha if fecha.tzinfo else fecha.replace(tzinfo=timezone.utc)


def hace_dias(n: int) -> datetime:
    return datetime.now(timezone.utc) - timedelta(days=n)


__all__ = ["Nube", "hace_dias", "car"]
