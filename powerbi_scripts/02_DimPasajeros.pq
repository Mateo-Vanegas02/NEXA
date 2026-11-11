// ============================================================
// SCRIPT POWER QUERY M — Crear tabla "DimPasajeros"
// ============================================================
// INSTRUCCIONES:
// 1. En Power Query, click derecho en tabla "Usuarios"
// 2. Seleccionar "Referencia" (esto crea una copia vinculada)
// 3. Renombrar la nueva tabla a "DimPasajeros"
// 4. Click en "Editor avanzado" 
// 5. Reemplazar TODO el contenido con este script
// ============================================================

let
    // Obtener datos de la tabla Usuarios original
    Source = Usuarios,

    // Filtrar solo usuarios con rol PASAJERO
    FiltroPasajeros = Table.SelectRows(Source, each 
        [rol] = "PASAJERO" or [rol] = "Pasajero" or [_class] = "PASAJERO"
    ),

    // Convertir _id a texto para compatibilidad con servicios
    ConvertirID = Table.TransformColumnTypes(FiltroPasajeros, {{"_id", type text}}),

    // Seleccionar solo columnas relevantes para la dimensión
    ColumnasRelevantes = try Table.SelectColumns(ConvertirID, {
        "_id", "email", "fechaRegistro", "rol", "estadoValidacion",
        "nombreCompleto", "telefono"
    }) otherwise ConvertirID,

    // Renombrar _id para claridad
    Renombrar = Table.RenameColumns(ColumnasRelevantes, {{"_id", "PasajeroID"}})
in
    Renombrar
