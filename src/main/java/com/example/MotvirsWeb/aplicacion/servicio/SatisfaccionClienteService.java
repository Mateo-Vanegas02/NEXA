package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.ModeloInfo;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import com.example.MotvirsWeb.dominio.repositorio.ModeloInfoRepository;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import weka.classifiers.trees.J48;
import weka.core.*;

import java.io.File;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
public class SatisfaccionClienteService {

    @Autowired
    private ServicioRepository servicioRepository;

    @Autowired
    private ModeloInfoRepository modeloInfoRepository;

    @Autowired
    private org.springframework.data.mongodb.core.MongoTemplate mongoTemplate;

    /** Con menos viajes calificados el árbol no aprende nada útil: se deja el modelo anterior. */
    static final int MINIMO_INSTANCIAS = 30;
    /** Tope de viajes que se leen para entrenar (el servidor tiene poca memoria). */
    static final int MAX_INSTANCIAS = 50000;

    @Value("${motvirs.model.path}")
    private String modelFilePath;

    // --- ESTADO DEL MODELO EN MEMORIA ---
    private J48 j48Model;       // El modelo J48 entrenado
    private Instances dataHeader; // La "plantilla" de los datos (atributos)

    /**
     * Se ejecuta al iniciar la app. Carga el modelo binario desde el disco.
     */
    @PostConstruct
    public void init() {
        log.info("Iniciando servicio de predicción de satisfacción...");
        try {
            cargarModelo();
        } catch (Exception e) {
            log.warn("No se pudo cargar el modelo desde {}. Se entrenará uno nuevo en la primera predicción. Causa: {}",
                    modelFilePath, e.getMessage());
        }
    }

    /**
     * Carga el modelo binario (J48) y la cabecera (dataHeader) desde el archivo.
     */
    public void cargarModelo() throws Exception {
        File modelFile = new File(modelFilePath);
        if (modelFile.exists()) {
            log.info("Cargando modelo J48 existente desde: {}", modelFilePath);
            Object[] loadedObjects = SerializationHelper.readAll(modelFilePath);
            this.j48Model = (J48) loadedObjects[0];
            this.dataHeader = (Instances) loadedObjects[1];
            log.info("Modelo J48 cargado exitosamente.");
        } else {
            log.info("El archivo de modelo {} no existe. Se debe entrenar.", modelFilePath);
        }
    }

    /**
     * Define la estructura (atributos) que Weka espera.
     */
    private ArrayList<Attribute> definirAtributos() {
        ArrayList<Attribute> attributes = new ArrayList<>();

        // Atributo 1: Duración del viaje en minutos
        attributes.add(new Attribute("duracion"));

        // Atributo 2: Distancia del viaje en KM
        attributes.add(new Attribute("distancia"));

        // Atributo 3: Tarifa del viaje
        attributes.add(new Attribute("tarifa"));

        // Atributo 4: Clase Objetivo (lo que queremos predecir)
        List<String> valoresClase = List.of("si", "no");
        attributes.add(new Attribute("satisfaccion", valoresClase));

        return attributes;
    }

    /**
     * Proceso principal: Carga datos, calcula estadísticas, transforma y entrena el J48.
     * Guarda el modelo binario en disco Y el resultado de texto + stats en MongoDB.
     */
    public String entrenarModelo() throws Exception {
        log.info("Iniciando re-entrenamiento del modelo J48...");

        // 1. Definir la estructura de los datos
        ArrayList<Attribute> attributes = definirAtributos();
        Instances data = new Instances("satisfaccion_dataset", attributes, 0);
        data.setClassIndex(attributes.size() - 1);

        // Guardamos la cabecera para futuras predicciones
        this.dataHeader = new Instances(data, 0);

        // 2. Solo viajes del modelo de tarifas v2.2: los anteriores se cobraban con otras reglas y enseñarían
        //    al árbol precios que ya no existen. Se leen solo los campos necesarios.
        LocalDateTime desde = inicioModeloV22();
        List<Servicio> serviciosCompletados = viajesParaEntrenar(desde);
        log.info("Obtenidos {} servicios finalizados del modelo v2.2 (desde {}).", serviciosCompletados.size(), desde);

        // --- VARIABLES PARA ESTADÍSTICAS ---
        int countSi = 0;
        int countNo = 0;
        double sumaTarifaSi = 0;
        double sumaTarifaNo = 0;
        double sumaDistSi = 0;
        double sumaDistNo = 0;

        // 3. Proceso ETL y Cálculo de Estadísticas
        for (Servicio s : serviciosCompletados) {

            // Feature 1: Duración
            double duracion = 0;
            if (s.getFechaInicio() != null && s.getFechaFinalizacion() != null) {
                duracion = ChronoUnit.MINUTES.between(s.getFechaInicio(), s.getFechaFinalizacion());
            }

            // Feature 2: Distancia
            double distancia = s.getDistanciaKM();

            // Feature 3: Tarifa realmente pagada por el viaje
            double tarifa = tarifaPagada(s);

            // Variable Objetivo (Target)
            Double promedio = s.getCalificacionPromedio();
            String satisfaccion;

            if (promedio == null) {
                continue; // Ignorar registros sin calificación
            } else {
                // Regla de negocio: >= 4.0 es "si"
                boolean isSatisfied = promedio >= 4.0;
                satisfaccion = isSatisfied ? "si" : "no";

                // --- ACUMULAR ESTADÍSTICAS ---
                if (isSatisfied) {
                    countSi++;
                    sumaTarifaSi += tarifa;
                    sumaDistSi += distancia;
                } else {
                    countNo++;
                    sumaTarifaNo += tarifa;
                    sumaDistNo += distancia;
                }
            }

            // Crear Instance Weka
            Instance inst = new DenseInstance(attributes.size());
            inst.setDataset(this.dataHeader);
            inst.setValue(attributes.get(0), duracion);
            inst.setValue(this.dataHeader.attribute("distancia"), distancia);
            inst.setValue(attributes.get(2), tarifa);
            inst.setValue(attributes.get(3), satisfaccion);

            data.add(inst);
        }

        if (data.numInstances() < MINIMO_INSTANCIAS) {
            log.warn("Solo hay {} viajes calificados del modelo v2.2: no se reentrena.", data.numInstances());
            return "Entrenamiento cancelado: hay " + data.numInstances() + " viajes calificados con las tarifas "
                    + "actuales y se necesitan al menos " + MINIMO_INSTANCIAS + ". Se mantiene el modelo anterior.";
        }

        log.info("Datos transformados. {} instancias listas para entrenar.", data.numInstances());

        // 4. Entrenar el clasificador J48
        this.j48Model = new J48();
        this.j48Model.buildClassifier(data);
        log.info("Modelo J48 entrenado exitosamente.");

        // 5. Guardar el modelo BINARIO en el disco
        log.info("Guardando modelo binario en: {}", modelFilePath);
        Object[] toSave = new Object[2];
        toSave[0] = this.j48Model;
        toSave[1] = this.dataHeader;
        SerializationHelper.writeAll(modelFilePath, toSave);

        // 6. Guardar el resultado de TEXTO y ESTADÍSTICAS en MongoDB
        String arbolString = this.j48Model.toString();

        ModeloInfo info = new ModeloInfo();
        info.setNombreModelo("J48_Satisfaccion");
        info.setFechaEntrenamiento(LocalDateTime.now());
        info.setArbolDecisionTexto(arbolString);
        info.setInstanciasUsadas(data.numInstances());

        // Asignar Totales
        info.setTotalSatisfactorios(countSi);
        info.setTotalInsatisfactorios(countNo);

        // Asignar Promedios (Evitando división por cero)
        info.setPromedioTarifaSi(countSi > 0 ? sumaTarifaSi / countSi : 0);
        info.setPromedioDistanciaSi(countSi > 0 ? sumaDistSi / countSi : 0);

        info.setPromedioTarifaNo(countNo > 0 ? sumaTarifaNo / countNo : 0);
        info.setPromedioDistanciaNo(countNo > 0 ? sumaDistNo / countNo : 0);

        modeloInfoRepository.save(info);
        log.info("Resultado del entrenamiento y estadísticas guardados en MongoDB.");

        return arbolString;
    }

    /**
     * Predice la satisfacción de un nuevo servicio.
     */
    public String predecirSatisfaccion(Servicio nuevoServicio) throws Exception {
        if (this.j48Model == null) {
            log.warn("El modelo no está cargado. Se iniciará el entrenamiento ahora.");
            entrenarModelo();
            if (this.j48Model == null) {
                log.error("Fallo en el entrenamiento, no se puede predecir.");
                return "Error: Modelo no disponible";
            }
        }

        // 1. Crear una instancia Weka vacía CON LA CABECERA
        Instance inst = new DenseInstance(this.dataHeader.numAttributes());
        inst.setDataset(this.dataHeader);

        // 2. Calcular los mismos features que en el entrenamiento
        double duracion = ChronoUnit.MINUTES.between(nuevoServicio.getFechaInicio(), nuevoServicio.getFechaFinalizacion());
        double distancia = nuevoServicio.getDistanciaKM();
        double tarifa = tarifaPagada(nuevoServicio);

        // 3. Poblar la instancia
        inst.setValue(this.dataHeader.attribute("duracion"), duracion);
        inst.setValue(this.dataHeader.attribute("distancia"), distancia);
        inst.setValue(this.dataHeader.attribute("tarifa"), tarifa);
        inst.setClassMissing();

        // 4. Clasificar la instancia
        double predictionIndex = this.j48Model.classifyInstance(inst);

        // 5. Devolver el resultado
        return this.dataHeader.classAttribute().value((int) predictionIndex);
    }

    /** Lo que pagó el pasajero por el viaje (v2.2); en viajes sin desglose, la tarifa guardada. */
    static double tarifaPagada(Servicio s) {
        return s.getDesglose() != null && s.getDesglose().getTotalPasajero() > 0
                ? s.getDesglose().getTotalPasajero()
                : s.getTarifa();
    }

    /** Fecha en que se aplicó la migración a niveles v2.2 (marcador en {@code migraciones}); null si no hay. */
    private LocalDateTime inicioModeloV22() {
        try {
            org.bson.Document marcador = mongoTemplate.getCollection("migraciones")
                    .find(new org.bson.Document("_id", "niveles-v2.2")).first();
            Object fecha = marcador == null ? null : marcador.get("fecha");
            return fecha == null ? null : LocalDateTime.parse(fecha.toString());
        } catch (RuntimeException e) {
            log.warn("No se pudo leer la fecha de la migración v2.2: se entrena con todos los viajes", e);
            return null;
        }
    }

    private List<Servicio> viajesParaEntrenar(LocalDateTime desde) {
        org.springframework.data.mongodb.core.query.Criteria c =
                org.springframework.data.mongodb.core.query.Criteria.where("estado").is(EstadoServicio.FINALIZADO);
        if (desde != null) {
            c = c.and("fechaFinalizacion").gte(desde);
        }
        org.springframework.data.mongodb.core.query.Query q = org.springframework.data.mongodb.core.query.Query.query(c);
        q.fields().include("fechaInicio", "fechaFinalizacion", "distanciaKM", "tarifa", "desglose.totalPasajero",
                "calificacionConductor", "calificacionPasajero");
        return mongoTemplate.find(q.limit(MAX_INSTANCIAS), Servicio.class);
    }
}