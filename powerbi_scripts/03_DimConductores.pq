// ============================================================
// SCRIPT POWER QUERY M — Crear tabla "DimConductores"
// ============================================================
// INSTRUCCIONES:
// 1. En Power Query, click derecho en tabla "Usuarios"
// 2. Seleccionar "Referencia" (esto crea una copia vinculada)
// 3. Renombrar la nueva tabla a "DimConductores"
// 4. Click en "Editor avanzado"
// 5. Reemplazar TODO el contenido con este script
// ============================================================

let
    // Obtener datos de la tabla Usuarios original
    Source = Usuarios,

    // Filtrar solo usuarios con rol CONDUCTOR
    FiltroConductores = Table.SelectRows(Source, each 
        [rol] = "CONDUCTOR" or [rol] = "Conductor" or [_class] = "CONDUCTOR"
    ),

    // Convertir _id a texto
    ConvertirID = Table.TransformColumnTypes(FiltroConductores, {{"_id", type text}}),

    // Seleccionar solo columnas relevantes para la dimensión
    ColumnasRelevantes = try Table.SelectColumns(ConvertirID, {
        "_id", "email", "fechaRegistro", "rol", "estadoValidacion",
        "nombre_y_Apellido", "ntelefono", "licencia", "soat", "tarjeta_de_propiedad"
    }) otherwise ConvertirID,

    // Renombrar _id para claridad
    Renombrar = Table.RenameColumns(ColumnasRelevantes, {{"_id", "ConductorID"}})
in
    Renombrar
