// ============================================================
// SCRIPT POWER QUERY M — Transformación de tabla "servicios"
// ============================================================
// INSTRUCCIONES:
// 1. En Power BI → Inicio → Transformar datos
// 2. Click en tabla "servicios" (panel izquierdo)
// 3. Click en "Editor avanzado" (pestaña Inicio)
// 4. Reemplazar TODO el contenido con este script
// 5. Click en "Listo"
// ============================================================

let
    // Paso 1: Obtener los datos originales de la tabla servicios
    Source = servicios_Original,

    // Paso 2: Expandir campo embebido "pasajero" → columnas separadas
    ExpandPasajero = Table.ExpandRecordColumn(Source, "pasajero", 
        {"_id", "nombre", "email"}, 
        {"PasajeroID", "PasajeroNombre", "PasajeroEmail"}),

    // Paso 3: Expandir campo embebido "conductor" → columnas separadas
    ExpandConductor = Table.ExpandRecordColumn(ExpandPasajero, "conductor", 
        {"_id", "nombre"}, 
        {"ConductorID", "ConductorNombre"}),

    // Paso 4: Expandir referencia DBRef de "vehiculo" → solo el $id
    ExpandVehiculo = try Table.ExpandRecordColumn(ExpandConductor, "vehiculo", 
        {"$id"}, 
        {"VehiculoID"}) 
        otherwise ExpandConductor,

    // Paso 5: Expandir coordenadas si existen
    ExpandOrigenCoord = try Table.ExpandRecordColumn(ExpandVehiculo, "ubicacionOrigen",
        {"latitud", "longitud"},
        {"OrigenLatitud", "OrigenLongitud"})
        otherwise ExpandVehiculo,

    ExpandDestinoCoord = try Table.ExpandRecordColumn(ExpandOrigenCoord, "ubicacionDestino",
        {"latitud", "longitud"},
        {"DestinoLatitud", "DestinoLongitud"})
        otherwise ExpandOrigenCoord,

    // Paso 6: Convertir tipos de datos
    TiposCorrectos = Table.TransformColumnTypes(ExpandDestinoCoord, {
        {"PasajeroID", type text},
        {"ConductorID", type text},
        {"tarifa", type number},
        {"distanciaKM", type number},
        {"fechaHora", type datetime}
    }),

    // Paso 7: Asegurar VehiculoID como texto (si existe)
    VehiculoIDTexto = try Table.TransformColumnTypes(TiposCorrectos, {{"VehiculoID", type text}}) otherwise TiposCorrectos
in
    VehiculoIDTexto
