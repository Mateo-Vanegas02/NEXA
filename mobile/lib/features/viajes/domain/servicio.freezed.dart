// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'servicio.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Coordenada {

 double get latitud; double get longitud;
/// Create a copy of Coordenada
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoordenadaCopyWith<Coordenada> get copyWith => _$CoordenadaCopyWithImpl<Coordenada>(this as Coordenada, _$identity);

  /// Serializes this Coordenada to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Coordenada;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Coordenada&&(identical(other.latitud, _this.latitud) || other.latitud == _this.latitud)&&(identical(other.longitud, _this.longitud) || other.longitud == _this.longitud));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Coordenada;
  return Object.hash(runtimeType,_this.latitud,_this.longitud);
}

@override
String toString() {
  final _this = this as Coordenada;
  return 'Coordenada(latitud: ${_this.latitud}, longitud: ${_this.longitud})';
}


}

/// @nodoc
abstract mixin class $CoordenadaCopyWith<$Res>  {
  factory $CoordenadaCopyWith(Coordenada value, $Res Function(Coordenada) _then) = _$CoordenadaCopyWithImpl;
@useResult
$Res call({
 double latitud, double longitud
});




}
/// @nodoc
class _$CoordenadaCopyWithImpl<$Res>
    implements $CoordenadaCopyWith<$Res> {
  _$CoordenadaCopyWithImpl(this._self, this._then);

  final Coordenada _self;
  final $Res Function(Coordenada) _then;

/// Create a copy of Coordenada
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? latitud = null,Object? longitud = null,}) {
  return _then(Coordenada(
latitud: null == latitud ? _self.latitud : latitud // ignore: cast_nullable_to_non_nullable
as double,longitud: null == longitud ? _self.longitud : longitud // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Coordenada].
extension CoordenadaPatterns on Coordenada {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Coordenada value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Coordenada() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Coordenada value)  $default,){
final _that = this;
switch (_that) {
case _Coordenada():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Coordenada value)?  $default,){
final _that = this;
switch (_that) {
case _Coordenada() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double latitud,  double longitud)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Coordenada() when $default != null:
return $default(_that.latitud,_that.longitud);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double latitud,  double longitud)  $default,) {final _that = this;
switch (_that) {
case _Coordenada():
return $default(_that.latitud,_that.longitud);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double latitud,  double longitud)?  $default,) {final _that = this;
switch (_that) {
case _Coordenada() when $default != null:
return $default(_that.latitud,_that.longitud);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Coordenada implements Coordenada {
  const _Coordenada({required this.latitud, required this.longitud});
  factory _Coordenada.fromJson(Map<String, dynamic> json) => _$CoordenadaFromJson(json);

@override final  double latitud;
@override final  double longitud;

/// Create a copy of Coordenada
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoordenadaCopyWith<_Coordenada> get copyWith => __$CoordenadaCopyWithImpl<_Coordenada>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CoordenadaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Coordenada&&(identical(other.latitud, latitud) || other.latitud == latitud)&&(identical(other.longitud, longitud) || other.longitud == longitud));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,latitud,longitud);
}

@override
String toString() {
    return 'Coordenada(latitud: $latitud, longitud: $longitud)';
}


}

/// @nodoc
abstract mixin class _$CoordenadaCopyWith<$Res> implements $CoordenadaCopyWith<$Res> {
  factory _$CoordenadaCopyWith(_Coordenada value, $Res Function(_Coordenada) _then) = __$CoordenadaCopyWithImpl;
@override @useResult
$Res call({
 double latitud, double longitud
});




}
/// @nodoc
class __$CoordenadaCopyWithImpl<$Res>
    implements _$CoordenadaCopyWith<$Res> {
  __$CoordenadaCopyWithImpl(this._self, this._then);

  final _Coordenada _self;
  final $Res Function(_Coordenada) _then;

/// Create a copy of Coordenada
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? latitud = null,Object? longitud = null,}) {
  return _then(_Coordenada(
latitud: null == latitud ? _self.latitud : latitud // ignore: cast_nullable_to_non_nullable
as double,longitud: null == longitud ? _self.longitud : longitud // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$Participante {

@JsonKey(readValue: leerIdParticipante) String? get id; String get nombre; String? get email; String? get telefono; double? get calificacion; int? get viajes; int? get nivel; String? get vehiculo; String? get placa; String? get fotoUrl;
/// Create a copy of Participante
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParticipanteCopyWith<Participante> get copyWith => _$ParticipanteCopyWithImpl<Participante>(this as Participante, _$identity);

  /// Serializes this Participante to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Participante;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Participante&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nombre, _this.nombre) || other.nombre == _this.nombre)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.telefono, _this.telefono) || other.telefono == _this.telefono)&&(identical(other.calificacion, _this.calificacion) || other.calificacion == _this.calificacion)&&(identical(other.viajes, _this.viajes) || other.viajes == _this.viajes)&&(identical(other.nivel, _this.nivel) || other.nivel == _this.nivel)&&(identical(other.vehiculo, _this.vehiculo) || other.vehiculo == _this.vehiculo)&&(identical(other.placa, _this.placa) || other.placa == _this.placa)&&(identical(other.fotoUrl, _this.fotoUrl) || other.fotoUrl == _this.fotoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Participante;
  return Object.hash(runtimeType,_this.id,_this.nombre,_this.email,_this.telefono,_this.calificacion,_this.viajes,_this.nivel,_this.vehiculo,_this.placa,_this.fotoUrl);
}

@override
String toString() {
  final _this = this as Participante;
  return 'Participante(id: ${_this.id}, nombre: ${_this.nombre}, email: ${_this.email}, telefono: ${_this.telefono}, calificacion: ${_this.calificacion}, viajes: ${_this.viajes}, nivel: ${_this.nivel}, vehiculo: ${_this.vehiculo}, placa: ${_this.placa}, fotoUrl: ${_this.fotoUrl})';
}


}

/// @nodoc
abstract mixin class $ParticipanteCopyWith<$Res>  {
  factory $ParticipanteCopyWith(Participante value, $Res Function(Participante) _then) = _$ParticipanteCopyWithImpl;
@useResult
$Res call({
@JsonKey(readValue: leerIdParticipante) String? id, String nombre, String? email, String? telefono, double? calificacion, int? viajes, int? nivel, String? vehiculo, String? placa, String? fotoUrl
});




}
/// @nodoc
class _$ParticipanteCopyWithImpl<$Res>
    implements $ParticipanteCopyWith<$Res> {
  _$ParticipanteCopyWithImpl(this._self, this._then);

  final Participante _self;
  final $Res Function(Participante) _then;

/// Create a copy of Participante
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? nombre = null,Object? email = freezed,Object? telefono = freezed,Object? calificacion = freezed,Object? viajes = freezed,Object? nivel = freezed,Object? vehiculo = freezed,Object? placa = freezed,Object? fotoUrl = freezed,}) {
  return _then(Participante(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,telefono: freezed == telefono ? _self.telefono : telefono // ignore: cast_nullable_to_non_nullable
as String?,calificacion: freezed == calificacion ? _self.calificacion : calificacion // ignore: cast_nullable_to_non_nullable
as double?,viajes: freezed == viajes ? _self.viajes : viajes // ignore: cast_nullable_to_non_nullable
as int?,nivel: freezed == nivel ? _self.nivel : nivel // ignore: cast_nullable_to_non_nullable
as int?,vehiculo: freezed == vehiculo ? _self.vehiculo : vehiculo // ignore: cast_nullable_to_non_nullable
as String?,placa: freezed == placa ? _self.placa : placa // ignore: cast_nullable_to_non_nullable
as String?,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Participante].
extension ParticipantePatterns on Participante {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Participante value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Participante() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Participante value)  $default,){
final _that = this;
switch (_that) {
case _Participante():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Participante value)?  $default,){
final _that = this;
switch (_that) {
case _Participante() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(readValue: leerIdParticipante)  String? id,  String nombre,  String? email,  String? telefono,  double? calificacion,  int? viajes,  int? nivel,  String? vehiculo,  String? placa,  String? fotoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Participante() when $default != null:
return $default(_that.id,_that.nombre,_that.email,_that.telefono,_that.calificacion,_that.viajes,_that.nivel,_that.vehiculo,_that.placa,_that.fotoUrl);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(readValue: leerIdParticipante)  String? id,  String nombre,  String? email,  String? telefono,  double? calificacion,  int? viajes,  int? nivel,  String? vehiculo,  String? placa,  String? fotoUrl)  $default,) {final _that = this;
switch (_that) {
case _Participante():
return $default(_that.id,_that.nombre,_that.email,_that.telefono,_that.calificacion,_that.viajes,_that.nivel,_that.vehiculo,_that.placa,_that.fotoUrl);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(readValue: leerIdParticipante)  String? id,  String nombre,  String? email,  String? telefono,  double? calificacion,  int? viajes,  int? nivel,  String? vehiculo,  String? placa,  String? fotoUrl)?  $default,) {final _that = this;
switch (_that) {
case _Participante() when $default != null:
return $default(_that.id,_that.nombre,_that.email,_that.telefono,_that.calificacion,_that.viajes,_that.nivel,_that.vehiculo,_that.placa,_that.fotoUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Participante implements Participante {
  const _Participante({@JsonKey(readValue: leerIdParticipante) this.id, this.nombre = '', this.email, this.telefono, this.calificacion, this.viajes, this.nivel, this.vehiculo, this.placa, this.fotoUrl});
  factory _Participante.fromJson(Map<String, dynamic> json) => _$ParticipanteFromJson(json);

@override@JsonKey(readValue: leerIdParticipante) final  String? id;
@override@JsonKey() final  String nombre;
@override final  String? email;
@override final  String? telefono;
@override final  double? calificacion;
@override final  int? viajes;
@override final  int? nivel;
@override final  String? vehiculo;
@override final  String? placa;
@override final  String? fotoUrl;

/// Create a copy of Participante
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParticipanteCopyWith<_Participante> get copyWith => __$ParticipanteCopyWithImpl<_Participante>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParticipanteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Participante&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.email, email) || other.email == email)&&(identical(other.telefono, telefono) || other.telefono == telefono)&&(identical(other.calificacion, calificacion) || other.calificacion == calificacion)&&(identical(other.viajes, viajes) || other.viajes == viajes)&&(identical(other.nivel, nivel) || other.nivel == nivel)&&(identical(other.vehiculo, vehiculo) || other.vehiculo == vehiculo)&&(identical(other.placa, placa) || other.placa == placa)&&(identical(other.fotoUrl, fotoUrl) || other.fotoUrl == fotoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nombre,email,telefono,calificacion,viajes,nivel,vehiculo,placa,fotoUrl);
}

@override
String toString() {
    return 'Participante(id: $id, nombre: $nombre, email: $email, telefono: $telefono, calificacion: $calificacion, viajes: $viajes, nivel: $nivel, vehiculo: $vehiculo, placa: $placa, fotoUrl: $fotoUrl)';
}


}

/// @nodoc
abstract mixin class _$ParticipanteCopyWith<$Res> implements $ParticipanteCopyWith<$Res> {
  factory _$ParticipanteCopyWith(_Participante value, $Res Function(_Participante) _then) = __$ParticipanteCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(readValue: leerIdParticipante) String? id, String nombre, String? email, String? telefono, double? calificacion, int? viajes, int? nivel, String? vehiculo, String? placa, String? fotoUrl
});




}
/// @nodoc
class __$ParticipanteCopyWithImpl<$Res>
    implements _$ParticipanteCopyWith<$Res> {
  __$ParticipanteCopyWithImpl(this._self, this._then);

  final _Participante _self;
  final $Res Function(_Participante) _then;

/// Create a copy of Participante
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? nombre = null,Object? email = freezed,Object? telefono = freezed,Object? calificacion = freezed,Object? viajes = freezed,Object? nivel = freezed,Object? vehiculo = freezed,Object? placa = freezed,Object? fotoUrl = freezed,}) {
  return _then(_Participante(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,telefono: freezed == telefono ? _self.telefono : telefono // ignore: cast_nullable_to_non_nullable
as String?,calificacion: freezed == calificacion ? _self.calificacion : calificacion // ignore: cast_nullable_to_non_nullable
as double?,viajes: freezed == viajes ? _self.viajes : viajes // ignore: cast_nullable_to_non_nullable
as int?,nivel: freezed == nivel ? _self.nivel : nivel // ignore: cast_nullable_to_non_nullable
as int?,vehiculo: freezed == vehiculo ? _self.vehiculo : vehiculo // ignore: cast_nullable_to_non_nullable
as String?,placa: freezed == placa ? _self.placa : placa // ignore: cast_nullable_to_non_nullable
as String?,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Servicio {

 String get id; EstadoServicio get estado; Participante? get pasajero; Participante? get conductor; String get origen; String get destino; double get distanciaKM; Coordenada? get ubicacionOrigen; Coordenada? get ubicacionDestino; DateTime? get fechaHora; DateTime? get fechaLlegada; DateTime? get fechaInicio; DateTime? get fechaFinalizacion; double get duracionEstimadaMin; String? get rutaGeometria;/// Maniobras de la ruta con el nombre de la calle (OSRM).
 List<PasoRuta> get pasosRuta; double get tarifa; double get extraVoluntario; double get deudaCobrada; bool get finalizadoAntesDelDestino; double? get fraccionCobrada; String? get metodoPago; double? get calificacionConductor; double? get calificacionPasajero; int get nivelPasajero; int get xpGanadoPasajero; int get xpGanadoConductor; double? get gananciaEstimada;
/// Create a copy of Servicio
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServicioCopyWith<Servicio> get copyWith => _$ServicioCopyWithImpl<Servicio>(this as Servicio, _$identity);

  /// Serializes this Servicio to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Servicio;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Servicio&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.estado, _this.estado) || other.estado == _this.estado)&&(identical(other.pasajero, _this.pasajero) || other.pasajero == _this.pasajero)&&(identical(other.conductor, _this.conductor) || other.conductor == _this.conductor)&&(identical(other.origen, _this.origen) || other.origen == _this.origen)&&(identical(other.destino, _this.destino) || other.destino == _this.destino)&&(identical(other.distanciaKM, _this.distanciaKM) || other.distanciaKM == _this.distanciaKM)&&(identical(other.ubicacionOrigen, _this.ubicacionOrigen) || other.ubicacionOrigen == _this.ubicacionOrigen)&&(identical(other.ubicacionDestino, _this.ubicacionDestino) || other.ubicacionDestino == _this.ubicacionDestino)&&(identical(other.fechaHora, _this.fechaHora) || other.fechaHora == _this.fechaHora)&&(identical(other.fechaLlegada, _this.fechaLlegada) || other.fechaLlegada == _this.fechaLlegada)&&(identical(other.fechaInicio, _this.fechaInicio) || other.fechaInicio == _this.fechaInicio)&&(identical(other.fechaFinalizacion, _this.fechaFinalizacion) || other.fechaFinalizacion == _this.fechaFinalizacion)&&(identical(other.duracionEstimadaMin, _this.duracionEstimadaMin) || other.duracionEstimadaMin == _this.duracionEstimadaMin)&&(identical(other.rutaGeometria, _this.rutaGeometria) || other.rutaGeometria == _this.rutaGeometria)&&const DeepCollectionEquality().equals(other.pasosRuta, _this.pasosRuta)&&(identical(other.tarifa, _this.tarifa) || other.tarifa == _this.tarifa)&&(identical(other.extraVoluntario, _this.extraVoluntario) || other.extraVoluntario == _this.extraVoluntario)&&(identical(other.deudaCobrada, _this.deudaCobrada) || other.deudaCobrada == _this.deudaCobrada)&&(identical(other.finalizadoAntesDelDestino, _this.finalizadoAntesDelDestino) || other.finalizadoAntesDelDestino == _this.finalizadoAntesDelDestino)&&(identical(other.fraccionCobrada, _this.fraccionCobrada) || other.fraccionCobrada == _this.fraccionCobrada)&&(identical(other.metodoPago, _this.metodoPago) || other.metodoPago == _this.metodoPago)&&(identical(other.calificacionConductor, _this.calificacionConductor) || other.calificacionConductor == _this.calificacionConductor)&&(identical(other.calificacionPasajero, _this.calificacionPasajero) || other.calificacionPasajero == _this.calificacionPasajero)&&(identical(other.nivelPasajero, _this.nivelPasajero) || other.nivelPasajero == _this.nivelPasajero)&&(identical(other.xpGanadoPasajero, _this.xpGanadoPasajero) || other.xpGanadoPasajero == _this.xpGanadoPasajero)&&(identical(other.xpGanadoConductor, _this.xpGanadoConductor) || other.xpGanadoConductor == _this.xpGanadoConductor)&&(identical(other.gananciaEstimada, _this.gananciaEstimada) || other.gananciaEstimada == _this.gananciaEstimada));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Servicio;
  return Object.hashAll([runtimeType,_this.id,_this.estado,_this.pasajero,_this.conductor,_this.origen,_this.destino,_this.distanciaKM,_this.ubicacionOrigen,_this.ubicacionDestino,_this.fechaHora,_this.fechaLlegada,_this.fechaInicio,_this.fechaFinalizacion,_this.duracionEstimadaMin,_this.rutaGeometria,const DeepCollectionEquality().hash(_this.pasosRuta),_this.tarifa,_this.extraVoluntario,_this.deudaCobrada,_this.finalizadoAntesDelDestino,_this.fraccionCobrada,_this.metodoPago,_this.calificacionConductor,_this.calificacionPasajero,_this.nivelPasajero,_this.xpGanadoPasajero,_this.xpGanadoConductor,_this.gananciaEstimada]);
}

@override
String toString() {
  final _this = this as Servicio;
  return 'Servicio(id: ${_this.id}, estado: ${_this.estado}, pasajero: ${_this.pasajero}, conductor: ${_this.conductor}, origen: ${_this.origen}, destino: ${_this.destino}, distanciaKM: ${_this.distanciaKM}, ubicacionOrigen: ${_this.ubicacionOrigen}, ubicacionDestino: ${_this.ubicacionDestino}, fechaHora: ${_this.fechaHora}, fechaLlegada: ${_this.fechaLlegada}, fechaInicio: ${_this.fechaInicio}, fechaFinalizacion: ${_this.fechaFinalizacion}, duracionEstimadaMin: ${_this.duracionEstimadaMin}, rutaGeometria: ${_this.rutaGeometria}, pasosRuta: ${_this.pasosRuta}, tarifa: ${_this.tarifa}, extraVoluntario: ${_this.extraVoluntario}, deudaCobrada: ${_this.deudaCobrada}, finalizadoAntesDelDestino: ${_this.finalizadoAntesDelDestino}, fraccionCobrada: ${_this.fraccionCobrada}, metodoPago: ${_this.metodoPago}, calificacionConductor: ${_this.calificacionConductor}, calificacionPasajero: ${_this.calificacionPasajero}, nivelPasajero: ${_this.nivelPasajero}, xpGanadoPasajero: ${_this.xpGanadoPasajero}, xpGanadoConductor: ${_this.xpGanadoConductor}, gananciaEstimada: ${_this.gananciaEstimada})';
}


}

/// @nodoc
abstract mixin class $ServicioCopyWith<$Res>  {
  factory $ServicioCopyWith(Servicio value, $Res Function(Servicio) _then) = _$ServicioCopyWithImpl;
@useResult
$Res call({
 String id, EstadoServicio estado, Participante? pasajero, Participante? conductor, String origen, String destino, double distanciaKM, Coordenada? ubicacionOrigen, Coordenada? ubicacionDestino, DateTime? fechaHora, DateTime? fechaLlegada, DateTime? fechaInicio, DateTime? fechaFinalizacion, double duracionEstimadaMin, String? rutaGeometria, List<PasoRuta> pasosRuta, double tarifa, double extraVoluntario, double deudaCobrada, bool finalizadoAntesDelDestino, double? fraccionCobrada, String? metodoPago, double? calificacionConductor, double? calificacionPasajero, int nivelPasajero, int xpGanadoPasajero, int xpGanadoConductor, double? gananciaEstimada
});


$ParticipanteCopyWith<$Res>? get pasajero;$ParticipanteCopyWith<$Res>? get conductor;$CoordenadaCopyWith<$Res>? get ubicacionOrigen;$CoordenadaCopyWith<$Res>? get ubicacionDestino;

}
/// @nodoc
class _$ServicioCopyWithImpl<$Res>
    implements $ServicioCopyWith<$Res> {
  _$ServicioCopyWithImpl(this._self, this._then);

  final Servicio _self;
  final $Res Function(Servicio) _then;

/// Create a copy of Servicio
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? estado = null,Object? pasajero = freezed,Object? conductor = freezed,Object? origen = null,Object? destino = null,Object? distanciaKM = null,Object? ubicacionOrigen = freezed,Object? ubicacionDestino = freezed,Object? fechaHora = freezed,Object? fechaLlegada = freezed,Object? fechaInicio = freezed,Object? fechaFinalizacion = freezed,Object? duracionEstimadaMin = null,Object? rutaGeometria = freezed,Object? pasosRuta = null,Object? tarifa = null,Object? extraVoluntario = null,Object? deudaCobrada = null,Object? finalizadoAntesDelDestino = null,Object? fraccionCobrada = freezed,Object? metodoPago = freezed,Object? calificacionConductor = freezed,Object? calificacionPasajero = freezed,Object? nivelPasajero = null,Object? xpGanadoPasajero = null,Object? xpGanadoConductor = null,Object? gananciaEstimada = freezed,}) {
  return _then(Servicio(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoServicio,pasajero: freezed == pasajero ? _self.pasajero : pasajero // ignore: cast_nullable_to_non_nullable
as Participante?,conductor: freezed == conductor ? _self.conductor : conductor // ignore: cast_nullable_to_non_nullable
as Participante?,origen: null == origen ? _self.origen : origen // ignore: cast_nullable_to_non_nullable
as String,destino: null == destino ? _self.destino : destino // ignore: cast_nullable_to_non_nullable
as String,distanciaKM: null == distanciaKM ? _self.distanciaKM : distanciaKM // ignore: cast_nullable_to_non_nullable
as double,ubicacionOrigen: freezed == ubicacionOrigen ? _self.ubicacionOrigen : ubicacionOrigen // ignore: cast_nullable_to_non_nullable
as Coordenada?,ubicacionDestino: freezed == ubicacionDestino ? _self.ubicacionDestino : ubicacionDestino // ignore: cast_nullable_to_non_nullable
as Coordenada?,fechaHora: freezed == fechaHora ? _self.fechaHora : fechaHora // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaLlegada: freezed == fechaLlegada ? _self.fechaLlegada : fechaLlegada // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaInicio: freezed == fechaInicio ? _self.fechaInicio : fechaInicio // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaFinalizacion: freezed == fechaFinalizacion ? _self.fechaFinalizacion : fechaFinalizacion // ignore: cast_nullable_to_non_nullable
as DateTime?,duracionEstimadaMin: null == duracionEstimadaMin ? _self.duracionEstimadaMin : duracionEstimadaMin // ignore: cast_nullable_to_non_nullable
as double,rutaGeometria: freezed == rutaGeometria ? _self.rutaGeometria : rutaGeometria // ignore: cast_nullable_to_non_nullable
as String?,pasosRuta: null == pasosRuta ? _self.pasosRuta : pasosRuta // ignore: cast_nullable_to_non_nullable
as List<PasoRuta>,tarifa: null == tarifa ? _self.tarifa : tarifa // ignore: cast_nullable_to_non_nullable
as double,extraVoluntario: null == extraVoluntario ? _self.extraVoluntario : extraVoluntario // ignore: cast_nullable_to_non_nullable
as double,deudaCobrada: null == deudaCobrada ? _self.deudaCobrada : deudaCobrada // ignore: cast_nullable_to_non_nullable
as double,finalizadoAntesDelDestino: null == finalizadoAntesDelDestino ? _self.finalizadoAntesDelDestino : finalizadoAntesDelDestino // ignore: cast_nullable_to_non_nullable
as bool,fraccionCobrada: freezed == fraccionCobrada ? _self.fraccionCobrada : fraccionCobrada // ignore: cast_nullable_to_non_nullable
as double?,metodoPago: freezed == metodoPago ? _self.metodoPago : metodoPago // ignore: cast_nullable_to_non_nullable
as String?,calificacionConductor: freezed == calificacionConductor ? _self.calificacionConductor : calificacionConductor // ignore: cast_nullable_to_non_nullable
as double?,calificacionPasajero: freezed == calificacionPasajero ? _self.calificacionPasajero : calificacionPasajero // ignore: cast_nullable_to_non_nullable
as double?,nivelPasajero: null == nivelPasajero ? _self.nivelPasajero : nivelPasajero // ignore: cast_nullable_to_non_nullable
as int,xpGanadoPasajero: null == xpGanadoPasajero ? _self.xpGanadoPasajero : xpGanadoPasajero // ignore: cast_nullable_to_non_nullable
as int,xpGanadoConductor: null == xpGanadoConductor ? _self.xpGanadoConductor : xpGanadoConductor // ignore: cast_nullable_to_non_nullable
as int,gananciaEstimada: freezed == gananciaEstimada ? _self.gananciaEstimada : gananciaEstimada // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}
/// Create a copy of Servicio
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParticipanteCopyWith<$Res>? get pasajero {
    if (_self.pasajero == null) {
    return null;
  }

  return $ParticipanteCopyWith<$Res>(_self.pasajero!, (value) {
    return _then(_self.copyWith(pasajero: value));
  });
}/// Create a copy of Servicio
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParticipanteCopyWith<$Res>? get conductor {
    if (_self.conductor == null) {
    return null;
  }

  return $ParticipanteCopyWith<$Res>(_self.conductor!, (value) {
    return _then(_self.copyWith(conductor: value));
  });
}/// Create a copy of Servicio
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoordenadaCopyWith<$Res>? get ubicacionOrigen {
    if (_self.ubicacionOrigen == null) {
    return null;
  }

  return $CoordenadaCopyWith<$Res>(_self.ubicacionOrigen!, (value) {
    return _then(_self.copyWith(ubicacionOrigen: value));
  });
}/// Create a copy of Servicio
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoordenadaCopyWith<$Res>? get ubicacionDestino {
    if (_self.ubicacionDestino == null) {
    return null;
  }

  return $CoordenadaCopyWith<$Res>(_self.ubicacionDestino!, (value) {
    return _then(_self.copyWith(ubicacionDestino: value));
  });
}
}


/// Adds pattern-matching-related methods to [Servicio].
extension ServicioPatterns on Servicio {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Servicio value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Servicio() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Servicio value)  $default,){
final _that = this;
switch (_that) {
case _Servicio():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Servicio value)?  $default,){
final _that = this;
switch (_that) {
case _Servicio() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  EstadoServicio estado,  Participante? pasajero,  Participante? conductor,  String origen,  String destino,  double distanciaKM,  Coordenada? ubicacionOrigen,  Coordenada? ubicacionDestino,  DateTime? fechaHora,  DateTime? fechaLlegada,  DateTime? fechaInicio,  DateTime? fechaFinalizacion,  double duracionEstimadaMin,  String? rutaGeometria,  List<PasoRuta> pasosRuta,  double tarifa,  double extraVoluntario,  double deudaCobrada,  bool finalizadoAntesDelDestino,  double? fraccionCobrada,  String? metodoPago,  double? calificacionConductor,  double? calificacionPasajero,  int nivelPasajero,  int xpGanadoPasajero,  int xpGanadoConductor,  double? gananciaEstimada)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Servicio() when $default != null:
return $default(_that.id,_that.estado,_that.pasajero,_that.conductor,_that.origen,_that.destino,_that.distanciaKM,_that.ubicacionOrigen,_that.ubicacionDestino,_that.fechaHora,_that.fechaLlegada,_that.fechaInicio,_that.fechaFinalizacion,_that.duracionEstimadaMin,_that.rutaGeometria,_that.pasosRuta,_that.tarifa,_that.extraVoluntario,_that.deudaCobrada,_that.finalizadoAntesDelDestino,_that.fraccionCobrada,_that.metodoPago,_that.calificacionConductor,_that.calificacionPasajero,_that.nivelPasajero,_that.xpGanadoPasajero,_that.xpGanadoConductor,_that.gananciaEstimada);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  EstadoServicio estado,  Participante? pasajero,  Participante? conductor,  String origen,  String destino,  double distanciaKM,  Coordenada? ubicacionOrigen,  Coordenada? ubicacionDestino,  DateTime? fechaHora,  DateTime? fechaLlegada,  DateTime? fechaInicio,  DateTime? fechaFinalizacion,  double duracionEstimadaMin,  String? rutaGeometria,  List<PasoRuta> pasosRuta,  double tarifa,  double extraVoluntario,  double deudaCobrada,  bool finalizadoAntesDelDestino,  double? fraccionCobrada,  String? metodoPago,  double? calificacionConductor,  double? calificacionPasajero,  int nivelPasajero,  int xpGanadoPasajero,  int xpGanadoConductor,  double? gananciaEstimada)  $default,) {final _that = this;
switch (_that) {
case _Servicio():
return $default(_that.id,_that.estado,_that.pasajero,_that.conductor,_that.origen,_that.destino,_that.distanciaKM,_that.ubicacionOrigen,_that.ubicacionDestino,_that.fechaHora,_that.fechaLlegada,_that.fechaInicio,_that.fechaFinalizacion,_that.duracionEstimadaMin,_that.rutaGeometria,_that.pasosRuta,_that.tarifa,_that.extraVoluntario,_that.deudaCobrada,_that.finalizadoAntesDelDestino,_that.fraccionCobrada,_that.metodoPago,_that.calificacionConductor,_that.calificacionPasajero,_that.nivelPasajero,_that.xpGanadoPasajero,_that.xpGanadoConductor,_that.gananciaEstimada);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  EstadoServicio estado,  Participante? pasajero,  Participante? conductor,  String origen,  String destino,  double distanciaKM,  Coordenada? ubicacionOrigen,  Coordenada? ubicacionDestino,  DateTime? fechaHora,  DateTime? fechaLlegada,  DateTime? fechaInicio,  DateTime? fechaFinalizacion,  double duracionEstimadaMin,  String? rutaGeometria,  List<PasoRuta> pasosRuta,  double tarifa,  double extraVoluntario,  double deudaCobrada,  bool finalizadoAntesDelDestino,  double? fraccionCobrada,  String? metodoPago,  double? calificacionConductor,  double? calificacionPasajero,  int nivelPasajero,  int xpGanadoPasajero,  int xpGanadoConductor,  double? gananciaEstimada)?  $default,) {final _that = this;
switch (_that) {
case _Servicio() when $default != null:
return $default(_that.id,_that.estado,_that.pasajero,_that.conductor,_that.origen,_that.destino,_that.distanciaKM,_that.ubicacionOrigen,_that.ubicacionDestino,_that.fechaHora,_that.fechaLlegada,_that.fechaInicio,_that.fechaFinalizacion,_that.duracionEstimadaMin,_that.rutaGeometria,_that.pasosRuta,_that.tarifa,_that.extraVoluntario,_that.deudaCobrada,_that.finalizadoAntesDelDestino,_that.fraccionCobrada,_that.metodoPago,_that.calificacionConductor,_that.calificacionPasajero,_that.nivelPasajero,_that.xpGanadoPasajero,_that.xpGanadoConductor,_that.gananciaEstimada);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Servicio extends Servicio {
  const _Servicio({required this.id, required this.estado, this.pasajero, this.conductor, this.origen = '', this.destino = '', this.distanciaKM = 0, this.ubicacionOrigen, this.ubicacionDestino, this.fechaHora, this.fechaLlegada, this.fechaInicio, this.fechaFinalizacion, this.duracionEstimadaMin = 0, this.rutaGeometria,  List<PasoRuta> pasosRuta = const <PasoRuta>[], this.tarifa = 0, this.extraVoluntario = 0, this.deudaCobrada = 0, this.finalizadoAntesDelDestino = false, this.fraccionCobrada, this.metodoPago, this.calificacionConductor, this.calificacionPasajero, this.nivelPasajero = 0, this.xpGanadoPasajero = 0, this.xpGanadoConductor = 0, this.gananciaEstimada}): _pasosRuta = pasosRuta,super._();
  factory _Servicio.fromJson(Map<String, dynamic> json) => _$ServicioFromJson(json);

@override final  String id;
@override final  EstadoServicio estado;
@override final  Participante? pasajero;
@override final  Participante? conductor;
@override@JsonKey() final  String origen;
@override@JsonKey() final  String destino;
@override@JsonKey() final  double distanciaKM;
@override final  Coordenada? ubicacionOrigen;
@override final  Coordenada? ubicacionDestino;
@override final  DateTime? fechaHora;
@override final  DateTime? fechaLlegada;
@override final  DateTime? fechaInicio;
@override final  DateTime? fechaFinalizacion;
@override@JsonKey() final  double duracionEstimadaMin;
@override final  String? rutaGeometria;
/// Maniobras de la ruta con el nombre de la calle (OSRM).
 final  List<PasoRuta> _pasosRuta;
/// Maniobras de la ruta con el nombre de la calle (OSRM).
@override@JsonKey() List<PasoRuta> get pasosRuta {
  if (_pasosRuta is EqualUnmodifiableListView) return _pasosRuta;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pasosRuta);
}

@override@JsonKey() final  double tarifa;
@override@JsonKey() final  double extraVoluntario;
@override@JsonKey() final  double deudaCobrada;
@override@JsonKey() final  bool finalizadoAntesDelDestino;
@override final  double? fraccionCobrada;
@override final  String? metodoPago;
@override final  double? calificacionConductor;
@override final  double? calificacionPasajero;
@override@JsonKey() final  int nivelPasajero;
@override@JsonKey() final  int xpGanadoPasajero;
@override@JsonKey() final  int xpGanadoConductor;
@override final  double? gananciaEstimada;

/// Create a copy of Servicio
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServicioCopyWith<_Servicio> get copyWith => __$ServicioCopyWithImpl<_Servicio>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServicioToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Servicio&&(identical(other.id, id) || other.id == id)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.pasajero, pasajero) || other.pasajero == pasajero)&&(identical(other.conductor, conductor) || other.conductor == conductor)&&(identical(other.origen, origen) || other.origen == origen)&&(identical(other.destino, destino) || other.destino == destino)&&(identical(other.distanciaKM, distanciaKM) || other.distanciaKM == distanciaKM)&&(identical(other.ubicacionOrigen, ubicacionOrigen) || other.ubicacionOrigen == ubicacionOrigen)&&(identical(other.ubicacionDestino, ubicacionDestino) || other.ubicacionDestino == ubicacionDestino)&&(identical(other.fechaHora, fechaHora) || other.fechaHora == fechaHora)&&(identical(other.fechaLlegada, fechaLlegada) || other.fechaLlegada == fechaLlegada)&&(identical(other.fechaInicio, fechaInicio) || other.fechaInicio == fechaInicio)&&(identical(other.fechaFinalizacion, fechaFinalizacion) || other.fechaFinalizacion == fechaFinalizacion)&&(identical(other.duracionEstimadaMin, duracionEstimadaMin) || other.duracionEstimadaMin == duracionEstimadaMin)&&(identical(other.rutaGeometria, rutaGeometria) || other.rutaGeometria == rutaGeometria)&&const DeepCollectionEquality().equals(other.pasosRuta, _pasosRuta)&&(identical(other.tarifa, tarifa) || other.tarifa == tarifa)&&(identical(other.extraVoluntario, extraVoluntario) || other.extraVoluntario == extraVoluntario)&&(identical(other.deudaCobrada, deudaCobrada) || other.deudaCobrada == deudaCobrada)&&(identical(other.finalizadoAntesDelDestino, finalizadoAntesDelDestino) || other.finalizadoAntesDelDestino == finalizadoAntesDelDestino)&&(identical(other.fraccionCobrada, fraccionCobrada) || other.fraccionCobrada == fraccionCobrada)&&(identical(other.metodoPago, metodoPago) || other.metodoPago == metodoPago)&&(identical(other.calificacionConductor, calificacionConductor) || other.calificacionConductor == calificacionConductor)&&(identical(other.calificacionPasajero, calificacionPasajero) || other.calificacionPasajero == calificacionPasajero)&&(identical(other.nivelPasajero, nivelPasajero) || other.nivelPasajero == nivelPasajero)&&(identical(other.xpGanadoPasajero, xpGanadoPasajero) || other.xpGanadoPasajero == xpGanadoPasajero)&&(identical(other.xpGanadoConductor, xpGanadoConductor) || other.xpGanadoConductor == xpGanadoConductor)&&(identical(other.gananciaEstimada, gananciaEstimada) || other.gananciaEstimada == gananciaEstimada));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,estado,pasajero,conductor,origen,destino,distanciaKM,ubicacionOrigen,ubicacionDestino,fechaHora,fechaLlegada,fechaInicio,fechaFinalizacion,duracionEstimadaMin,rutaGeometria,const DeepCollectionEquality().hash(_pasosRuta),tarifa,extraVoluntario,deudaCobrada,finalizadoAntesDelDestino,fraccionCobrada,metodoPago,calificacionConductor,calificacionPasajero,nivelPasajero,xpGanadoPasajero,xpGanadoConductor,gananciaEstimada]);
}

@override
String toString() {
    return 'Servicio(id: $id, estado: $estado, pasajero: $pasajero, conductor: $conductor, origen: $origen, destino: $destino, distanciaKM: $distanciaKM, ubicacionOrigen: $ubicacionOrigen, ubicacionDestino: $ubicacionDestino, fechaHora: $fechaHora, fechaLlegada: $fechaLlegada, fechaInicio: $fechaInicio, fechaFinalizacion: $fechaFinalizacion, duracionEstimadaMin: $duracionEstimadaMin, rutaGeometria: $rutaGeometria, pasosRuta: $pasosRuta, tarifa: $tarifa, extraVoluntario: $extraVoluntario, deudaCobrada: $deudaCobrada, finalizadoAntesDelDestino: $finalizadoAntesDelDestino, fraccionCobrada: $fraccionCobrada, metodoPago: $metodoPago, calificacionConductor: $calificacionConductor, calificacionPasajero: $calificacionPasajero, nivelPasajero: $nivelPasajero, xpGanadoPasajero: $xpGanadoPasajero, xpGanadoConductor: $xpGanadoConductor, gananciaEstimada: $gananciaEstimada)';
}


}

/// @nodoc
abstract mixin class _$ServicioCopyWith<$Res> implements $ServicioCopyWith<$Res> {
  factory _$ServicioCopyWith(_Servicio value, $Res Function(_Servicio) _then) = __$ServicioCopyWithImpl;
@override @useResult
$Res call({
 String id, EstadoServicio estado, Participante? pasajero, Participante? conductor, String origen, String destino, double distanciaKM, Coordenada? ubicacionOrigen, Coordenada? ubicacionDestino, DateTime? fechaHora, DateTime? fechaLlegada, DateTime? fechaInicio, DateTime? fechaFinalizacion, double duracionEstimadaMin, String? rutaGeometria, List<PasoRuta> pasosRuta, double tarifa, double extraVoluntario, double deudaCobrada, bool finalizadoAntesDelDestino, double? fraccionCobrada, String? metodoPago, double? calificacionConductor, double? calificacionPasajero, int nivelPasajero, int xpGanadoPasajero, int xpGanadoConductor, double? gananciaEstimada
});


@override $ParticipanteCopyWith<$Res>? get pasajero;@override $ParticipanteCopyWith<$Res>? get conductor;@override $CoordenadaCopyWith<$Res>? get ubicacionOrigen;@override $CoordenadaCopyWith<$Res>? get ubicacionDestino;

}
/// @nodoc
class __$ServicioCopyWithImpl<$Res>
    implements _$ServicioCopyWith<$Res> {
  __$ServicioCopyWithImpl(this._self, this._then);

  final _Servicio _self;
  final $Res Function(_Servicio) _then;

/// Create a copy of Servicio
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? estado = null,Object? pasajero = freezed,Object? conductor = freezed,Object? origen = null,Object? destino = null,Object? distanciaKM = null,Object? ubicacionOrigen = freezed,Object? ubicacionDestino = freezed,Object? fechaHora = freezed,Object? fechaLlegada = freezed,Object? fechaInicio = freezed,Object? fechaFinalizacion = freezed,Object? duracionEstimadaMin = null,Object? rutaGeometria = freezed,Object? pasosRuta = null,Object? tarifa = null,Object? extraVoluntario = null,Object? deudaCobrada = null,Object? finalizadoAntesDelDestino = null,Object? fraccionCobrada = freezed,Object? metodoPago = freezed,Object? calificacionConductor = freezed,Object? calificacionPasajero = freezed,Object? nivelPasajero = null,Object? xpGanadoPasajero = null,Object? xpGanadoConductor = null,Object? gananciaEstimada = freezed,}) {
  return _then(_Servicio(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoServicio,pasajero: freezed == pasajero ? _self.pasajero : pasajero // ignore: cast_nullable_to_non_nullable
as Participante?,conductor: freezed == conductor ? _self.conductor : conductor // ignore: cast_nullable_to_non_nullable
as Participante?,origen: null == origen ? _self.origen : origen // ignore: cast_nullable_to_non_nullable
as String,destino: null == destino ? _self.destino : destino // ignore: cast_nullable_to_non_nullable
as String,distanciaKM: null == distanciaKM ? _self.distanciaKM : distanciaKM // ignore: cast_nullable_to_non_nullable
as double,ubicacionOrigen: freezed == ubicacionOrigen ? _self.ubicacionOrigen : ubicacionOrigen // ignore: cast_nullable_to_non_nullable
as Coordenada?,ubicacionDestino: freezed == ubicacionDestino ? _self.ubicacionDestino : ubicacionDestino // ignore: cast_nullable_to_non_nullable
as Coordenada?,fechaHora: freezed == fechaHora ? _self.fechaHora : fechaHora // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaLlegada: freezed == fechaLlegada ? _self.fechaLlegada : fechaLlegada // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaInicio: freezed == fechaInicio ? _self.fechaInicio : fechaInicio // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaFinalizacion: freezed == fechaFinalizacion ? _self.fechaFinalizacion : fechaFinalizacion // ignore: cast_nullable_to_non_nullable
as DateTime?,duracionEstimadaMin: null == duracionEstimadaMin ? _self.duracionEstimadaMin : duracionEstimadaMin // ignore: cast_nullable_to_non_nullable
as double,rutaGeometria: freezed == rutaGeometria ? _self.rutaGeometria : rutaGeometria // ignore: cast_nullable_to_non_nullable
as String?,pasosRuta: null == pasosRuta ? _self._pasosRuta : pasosRuta // ignore: cast_nullable_to_non_nullable
as List<PasoRuta>,tarifa: null == tarifa ? _self.tarifa : tarifa // ignore: cast_nullable_to_non_nullable
as double,extraVoluntario: null == extraVoluntario ? _self.extraVoluntario : extraVoluntario // ignore: cast_nullable_to_non_nullable
as double,deudaCobrada: null == deudaCobrada ? _self.deudaCobrada : deudaCobrada // ignore: cast_nullable_to_non_nullable
as double,finalizadoAntesDelDestino: null == finalizadoAntesDelDestino ? _self.finalizadoAntesDelDestino : finalizadoAntesDelDestino // ignore: cast_nullable_to_non_nullable
as bool,fraccionCobrada: freezed == fraccionCobrada ? _self.fraccionCobrada : fraccionCobrada // ignore: cast_nullable_to_non_nullable
as double?,metodoPago: freezed == metodoPago ? _self.metodoPago : metodoPago // ignore: cast_nullable_to_non_nullable
as String?,calificacionConductor: freezed == calificacionConductor ? _self.calificacionConductor : calificacionConductor // ignore: cast_nullable_to_non_nullable
as double?,calificacionPasajero: freezed == calificacionPasajero ? _self.calificacionPasajero : calificacionPasajero // ignore: cast_nullable_to_non_nullable
as double?,nivelPasajero: null == nivelPasajero ? _self.nivelPasajero : nivelPasajero // ignore: cast_nullable_to_non_nullable
as int,xpGanadoPasajero: null == xpGanadoPasajero ? _self.xpGanadoPasajero : xpGanadoPasajero // ignore: cast_nullable_to_non_nullable
as int,xpGanadoConductor: null == xpGanadoConductor ? _self.xpGanadoConductor : xpGanadoConductor // ignore: cast_nullable_to_non_nullable
as int,gananciaEstimada: freezed == gananciaEstimada ? _self.gananciaEstimada : gananciaEstimada // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

/// Create a copy of Servicio
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParticipanteCopyWith<$Res>? get pasajero {
    if (_self.pasajero == null) {
    return null;
  }

  return $ParticipanteCopyWith<$Res>(_self.pasajero!, (value) {
    return _then(_self.copyWith(pasajero: value));
  });
}/// Create a copy of Servicio
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParticipanteCopyWith<$Res>? get conductor {
    if (_self.conductor == null) {
    return null;
  }

  return $ParticipanteCopyWith<$Res>(_self.conductor!, (value) {
    return _then(_self.copyWith(conductor: value));
  });
}/// Create a copy of Servicio
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoordenadaCopyWith<$Res>? get ubicacionOrigen {
    if (_self.ubicacionOrigen == null) {
    return null;
  }

  return $CoordenadaCopyWith<$Res>(_self.ubicacionOrigen!, (value) {
    return _then(_self.copyWith(ubicacionOrigen: value));
  });
}/// Create a copy of Servicio
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoordenadaCopyWith<$Res>? get ubicacionDestino {
    if (_self.ubicacionDestino == null) {
    return null;
  }

  return $CoordenadaCopyWith<$Res>(_self.ubicacionDestino!, (value) {
    return _then(_self.copyWith(ubicacionDestino: value));
  });
}
}


/// @nodoc
mixin _$DesglosePasajero {

 double get tarifa; double get descuentoNivel; double get recargoEspera; double get extraVoluntario; double get totalPasajero; double get deudaAnterior; double get totalAPagar;
/// Create a copy of DesglosePasajero
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesglosePasajeroCopyWith<DesglosePasajero> get copyWith => _$DesglosePasajeroCopyWithImpl<DesglosePasajero>(this as DesglosePasajero, _$identity);

  /// Serializes this DesglosePasajero to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DesglosePasajero;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesglosePasajero&&(identical(other.tarifa, _this.tarifa) || other.tarifa == _this.tarifa)&&(identical(other.descuentoNivel, _this.descuentoNivel) || other.descuentoNivel == _this.descuentoNivel)&&(identical(other.recargoEspera, _this.recargoEspera) || other.recargoEspera == _this.recargoEspera)&&(identical(other.extraVoluntario, _this.extraVoluntario) || other.extraVoluntario == _this.extraVoluntario)&&(identical(other.totalPasajero, _this.totalPasajero) || other.totalPasajero == _this.totalPasajero)&&(identical(other.deudaAnterior, _this.deudaAnterior) || other.deudaAnterior == _this.deudaAnterior)&&(identical(other.totalAPagar, _this.totalAPagar) || other.totalAPagar == _this.totalAPagar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DesglosePasajero;
  return Object.hash(runtimeType,_this.tarifa,_this.descuentoNivel,_this.recargoEspera,_this.extraVoluntario,_this.totalPasajero,_this.deudaAnterior,_this.totalAPagar);
}

@override
String toString() {
  final _this = this as DesglosePasajero;
  return 'DesglosePasajero(tarifa: ${_this.tarifa}, descuentoNivel: ${_this.descuentoNivel}, recargoEspera: ${_this.recargoEspera}, extraVoluntario: ${_this.extraVoluntario}, totalPasajero: ${_this.totalPasajero}, deudaAnterior: ${_this.deudaAnterior}, totalAPagar: ${_this.totalAPagar})';
}


}

/// @nodoc
abstract mixin class $DesglosePasajeroCopyWith<$Res>  {
  factory $DesglosePasajeroCopyWith(DesglosePasajero value, $Res Function(DesglosePasajero) _then) = _$DesglosePasajeroCopyWithImpl;
@useResult
$Res call({
 double tarifa, double descuentoNivel, double recargoEspera, double extraVoluntario, double totalPasajero, double deudaAnterior, double totalAPagar
});




}
/// @nodoc
class _$DesglosePasajeroCopyWithImpl<$Res>
    implements $DesglosePasajeroCopyWith<$Res> {
  _$DesglosePasajeroCopyWithImpl(this._self, this._then);

  final DesglosePasajero _self;
  final $Res Function(DesglosePasajero) _then;

/// Create a copy of DesglosePasajero
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tarifa = null,Object? descuentoNivel = null,Object? recargoEspera = null,Object? extraVoluntario = null,Object? totalPasajero = null,Object? deudaAnterior = null,Object? totalAPagar = null,}) {
  return _then(DesglosePasajero(
tarifa: null == tarifa ? _self.tarifa : tarifa // ignore: cast_nullable_to_non_nullable
as double,descuentoNivel: null == descuentoNivel ? _self.descuentoNivel : descuentoNivel // ignore: cast_nullable_to_non_nullable
as double,recargoEspera: null == recargoEspera ? _self.recargoEspera : recargoEspera // ignore: cast_nullable_to_non_nullable
as double,extraVoluntario: null == extraVoluntario ? _self.extraVoluntario : extraVoluntario // ignore: cast_nullable_to_non_nullable
as double,totalPasajero: null == totalPasajero ? _self.totalPasajero : totalPasajero // ignore: cast_nullable_to_non_nullable
as double,deudaAnterior: null == deudaAnterior ? _self.deudaAnterior : deudaAnterior // ignore: cast_nullable_to_non_nullable
as double,totalAPagar: null == totalAPagar ? _self.totalAPagar : totalAPagar // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [DesglosePasajero].
extension DesglosePasajeroPatterns on DesglosePasajero {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesglosePasajero value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesglosePasajero() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesglosePasajero value)  $default,){
final _that = this;
switch (_that) {
case _DesglosePasajero():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesglosePasajero value)?  $default,){
final _that = this;
switch (_that) {
case _DesglosePasajero() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double tarifa,  double descuentoNivel,  double recargoEspera,  double extraVoluntario,  double totalPasajero,  double deudaAnterior,  double totalAPagar)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesglosePasajero() when $default != null:
return $default(_that.tarifa,_that.descuentoNivel,_that.recargoEspera,_that.extraVoluntario,_that.totalPasajero,_that.deudaAnterior,_that.totalAPagar);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double tarifa,  double descuentoNivel,  double recargoEspera,  double extraVoluntario,  double totalPasajero,  double deudaAnterior,  double totalAPagar)  $default,) {final _that = this;
switch (_that) {
case _DesglosePasajero():
return $default(_that.tarifa,_that.descuentoNivel,_that.recargoEspera,_that.extraVoluntario,_that.totalPasajero,_that.deudaAnterior,_that.totalAPagar);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double tarifa,  double descuentoNivel,  double recargoEspera,  double extraVoluntario,  double totalPasajero,  double deudaAnterior,  double totalAPagar)?  $default,) {final _that = this;
switch (_that) {
case _DesglosePasajero() when $default != null:
return $default(_that.tarifa,_that.descuentoNivel,_that.recargoEspera,_that.extraVoluntario,_that.totalPasajero,_that.deudaAnterior,_that.totalAPagar);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DesglosePasajero implements DesglosePasajero {
  const _DesglosePasajero({this.tarifa = 0, this.descuentoNivel = 0, this.recargoEspera = 0, this.extraVoluntario = 0, this.totalPasajero = 0, this.deudaAnterior = 0, this.totalAPagar = 0});
  factory _DesglosePasajero.fromJson(Map<String, dynamic> json) => _$DesglosePasajeroFromJson(json);

@override@JsonKey() final  double tarifa;
@override@JsonKey() final  double descuentoNivel;
@override@JsonKey() final  double recargoEspera;
@override@JsonKey() final  double extraVoluntario;
@override@JsonKey() final  double totalPasajero;
@override@JsonKey() final  double deudaAnterior;
@override@JsonKey() final  double totalAPagar;

/// Create a copy of DesglosePasajero
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesglosePasajeroCopyWith<_DesglosePasajero> get copyWith => __$DesglosePasajeroCopyWithImpl<_DesglosePasajero>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DesglosePasajeroToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesglosePasajero&&(identical(other.tarifa, tarifa) || other.tarifa == tarifa)&&(identical(other.descuentoNivel, descuentoNivel) || other.descuentoNivel == descuentoNivel)&&(identical(other.recargoEspera, recargoEspera) || other.recargoEspera == recargoEspera)&&(identical(other.extraVoluntario, extraVoluntario) || other.extraVoluntario == extraVoluntario)&&(identical(other.totalPasajero, totalPasajero) || other.totalPasajero == totalPasajero)&&(identical(other.deudaAnterior, deudaAnterior) || other.deudaAnterior == deudaAnterior)&&(identical(other.totalAPagar, totalAPagar) || other.totalAPagar == totalAPagar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,tarifa,descuentoNivel,recargoEspera,extraVoluntario,totalPasajero,deudaAnterior,totalAPagar);
}

@override
String toString() {
    return 'DesglosePasajero(tarifa: $tarifa, descuentoNivel: $descuentoNivel, recargoEspera: $recargoEspera, extraVoluntario: $extraVoluntario, totalPasajero: $totalPasajero, deudaAnterior: $deudaAnterior, totalAPagar: $totalAPagar)';
}


}

/// @nodoc
abstract mixin class _$DesglosePasajeroCopyWith<$Res> implements $DesglosePasajeroCopyWith<$Res> {
  factory _$DesglosePasajeroCopyWith(_DesglosePasajero value, $Res Function(_DesglosePasajero) _then) = __$DesglosePasajeroCopyWithImpl;
@override @useResult
$Res call({
 double tarifa, double descuentoNivel, double recargoEspera, double extraVoluntario, double totalPasajero, double deudaAnterior, double totalAPagar
});




}
/// @nodoc
class __$DesglosePasajeroCopyWithImpl<$Res>
    implements _$DesglosePasajeroCopyWith<$Res> {
  __$DesglosePasajeroCopyWithImpl(this._self, this._then);

  final _DesglosePasajero _self;
  final $Res Function(_DesglosePasajero) _then;

/// Create a copy of DesglosePasajero
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tarifa = null,Object? descuentoNivel = null,Object? recargoEspera = null,Object? extraVoluntario = null,Object? totalPasajero = null,Object? deudaAnterior = null,Object? totalAPagar = null,}) {
  return _then(_DesglosePasajero(
tarifa: null == tarifa ? _self.tarifa : tarifa // ignore: cast_nullable_to_non_nullable
as double,descuentoNivel: null == descuentoNivel ? _self.descuentoNivel : descuentoNivel // ignore: cast_nullable_to_non_nullable
as double,recargoEspera: null == recargoEspera ? _self.recargoEspera : recargoEspera // ignore: cast_nullable_to_non_nullable
as double,extraVoluntario: null == extraVoluntario ? _self.extraVoluntario : extraVoluntario // ignore: cast_nullable_to_non_nullable
as double,totalPasajero: null == totalPasajero ? _self.totalPasajero : totalPasajero // ignore: cast_nullable_to_non_nullable
as double,deudaAnterior: null == deudaAnterior ? _self.deudaAnterior : deudaAnterior // ignore: cast_nullable_to_non_nullable
as double,totalAPagar: null == totalAPagar ? _self.totalAPagar : totalAPagar // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$DesgloseConductor {

 double get recargoEspera; double get extraVoluntario; double get gananciaConductor;/// Lo que el conductor cobra en efectivo al pasajero (tarifa más el cargo
/// anterior del pasajero, si se cobró con este viaje). El conductor no ve
/// la comisión ni la deuda por separado.
 double get cobrarAlPasajero;
/// Create a copy of DesgloseConductor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesgloseConductorCopyWith<DesgloseConductor> get copyWith => _$DesgloseConductorCopyWithImpl<DesgloseConductor>(this as DesgloseConductor, _$identity);

  /// Serializes this DesgloseConductor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DesgloseConductor;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesgloseConductor&&(identical(other.recargoEspera, _this.recargoEspera) || other.recargoEspera == _this.recargoEspera)&&(identical(other.extraVoluntario, _this.extraVoluntario) || other.extraVoluntario == _this.extraVoluntario)&&(identical(other.gananciaConductor, _this.gananciaConductor) || other.gananciaConductor == _this.gananciaConductor)&&(identical(other.cobrarAlPasajero, _this.cobrarAlPasajero) || other.cobrarAlPasajero == _this.cobrarAlPasajero));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DesgloseConductor;
  return Object.hash(runtimeType,_this.recargoEspera,_this.extraVoluntario,_this.gananciaConductor,_this.cobrarAlPasajero);
}

@override
String toString() {
  final _this = this as DesgloseConductor;
  return 'DesgloseConductor(recargoEspera: ${_this.recargoEspera}, extraVoluntario: ${_this.extraVoluntario}, gananciaConductor: ${_this.gananciaConductor}, cobrarAlPasajero: ${_this.cobrarAlPasajero})';
}


}

/// @nodoc
abstract mixin class $DesgloseConductorCopyWith<$Res>  {
  factory $DesgloseConductorCopyWith(DesgloseConductor value, $Res Function(DesgloseConductor) _then) = _$DesgloseConductorCopyWithImpl;
@useResult
$Res call({
 double recargoEspera, double extraVoluntario, double gananciaConductor, double cobrarAlPasajero
});




}
/// @nodoc
class _$DesgloseConductorCopyWithImpl<$Res>
    implements $DesgloseConductorCopyWith<$Res> {
  _$DesgloseConductorCopyWithImpl(this._self, this._then);

  final DesgloseConductor _self;
  final $Res Function(DesgloseConductor) _then;

/// Create a copy of DesgloseConductor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? recargoEspera = null,Object? extraVoluntario = null,Object? gananciaConductor = null,Object? cobrarAlPasajero = null,}) {
  return _then(DesgloseConductor(
recargoEspera: null == recargoEspera ? _self.recargoEspera : recargoEspera // ignore: cast_nullable_to_non_nullable
as double,extraVoluntario: null == extraVoluntario ? _self.extraVoluntario : extraVoluntario // ignore: cast_nullable_to_non_nullable
as double,gananciaConductor: null == gananciaConductor ? _self.gananciaConductor : gananciaConductor // ignore: cast_nullable_to_non_nullable
as double,cobrarAlPasajero: null == cobrarAlPasajero ? _self.cobrarAlPasajero : cobrarAlPasajero // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [DesgloseConductor].
extension DesgloseConductorPatterns on DesgloseConductor {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesgloseConductor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesgloseConductor() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesgloseConductor value)  $default,){
final _that = this;
switch (_that) {
case _DesgloseConductor():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesgloseConductor value)?  $default,){
final _that = this;
switch (_that) {
case _DesgloseConductor() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double recargoEspera,  double extraVoluntario,  double gananciaConductor,  double cobrarAlPasajero)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesgloseConductor() when $default != null:
return $default(_that.recargoEspera,_that.extraVoluntario,_that.gananciaConductor,_that.cobrarAlPasajero);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double recargoEspera,  double extraVoluntario,  double gananciaConductor,  double cobrarAlPasajero)  $default,) {final _that = this;
switch (_that) {
case _DesgloseConductor():
return $default(_that.recargoEspera,_that.extraVoluntario,_that.gananciaConductor,_that.cobrarAlPasajero);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double recargoEspera,  double extraVoluntario,  double gananciaConductor,  double cobrarAlPasajero)?  $default,) {final _that = this;
switch (_that) {
case _DesgloseConductor() when $default != null:
return $default(_that.recargoEspera,_that.extraVoluntario,_that.gananciaConductor,_that.cobrarAlPasajero);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DesgloseConductor implements DesgloseConductor {
  const _DesgloseConductor({this.recargoEspera = 0, this.extraVoluntario = 0, this.gananciaConductor = 0, this.cobrarAlPasajero = 0});
  factory _DesgloseConductor.fromJson(Map<String, dynamic> json) => _$DesgloseConductorFromJson(json);

@override@JsonKey() final  double recargoEspera;
@override@JsonKey() final  double extraVoluntario;
@override@JsonKey() final  double gananciaConductor;
/// Lo que el conductor cobra en efectivo al pasajero (tarifa más el cargo
/// anterior del pasajero, si se cobró con este viaje). El conductor no ve
/// la comisión ni la deuda por separado.
@override@JsonKey() final  double cobrarAlPasajero;

/// Create a copy of DesgloseConductor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesgloseConductorCopyWith<_DesgloseConductor> get copyWith => __$DesgloseConductorCopyWithImpl<_DesgloseConductor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DesgloseConductorToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesgloseConductor&&(identical(other.recargoEspera, recargoEspera) || other.recargoEspera == recargoEspera)&&(identical(other.extraVoluntario, extraVoluntario) || other.extraVoluntario == extraVoluntario)&&(identical(other.gananciaConductor, gananciaConductor) || other.gananciaConductor == gananciaConductor)&&(identical(other.cobrarAlPasajero, cobrarAlPasajero) || other.cobrarAlPasajero == cobrarAlPasajero));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,recargoEspera,extraVoluntario,gananciaConductor,cobrarAlPasajero);
}

@override
String toString() {
    return 'DesgloseConductor(recargoEspera: $recargoEspera, extraVoluntario: $extraVoluntario, gananciaConductor: $gananciaConductor, cobrarAlPasajero: $cobrarAlPasajero)';
}


}

/// @nodoc
abstract mixin class _$DesgloseConductorCopyWith<$Res> implements $DesgloseConductorCopyWith<$Res> {
  factory _$DesgloseConductorCopyWith(_DesgloseConductor value, $Res Function(_DesgloseConductor) _then) = __$DesgloseConductorCopyWithImpl;
@override @useResult
$Res call({
 double recargoEspera, double extraVoluntario, double gananciaConductor, double cobrarAlPasajero
});




}
/// @nodoc
class __$DesgloseConductorCopyWithImpl<$Res>
    implements _$DesgloseConductorCopyWith<$Res> {
  __$DesgloseConductorCopyWithImpl(this._self, this._then);

  final _DesgloseConductor _self;
  final $Res Function(_DesgloseConductor) _then;

/// Create a copy of DesgloseConductor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? recargoEspera = null,Object? extraVoluntario = null,Object? gananciaConductor = null,Object? cobrarAlPasajero = null,}) {
  return _then(_DesgloseConductor(
recargoEspera: null == recargoEspera ? _self.recargoEspera : recargoEspera // ignore: cast_nullable_to_non_nullable
as double,extraVoluntario: null == extraVoluntario ? _self.extraVoluntario : extraVoluntario // ignore: cast_nullable_to_non_nullable
as double,gananciaConductor: null == gananciaConductor ? _self.gananciaConductor : gananciaConductor // ignore: cast_nullable_to_non_nullable
as double,cobrarAlPasajero: null == cobrarAlPasajero ? _self.cobrarAlPasajero : cobrarAlPasajero // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$Ingreso {

 String get fecha; double get monto; double get montoBruto; String get descripcion;/// Fecha y hora del viaje (ISO 8601); los servidores viejos no la envían.
 String? get hora;
/// Create a copy of Ingreso
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IngresoCopyWith<Ingreso> get copyWith => _$IngresoCopyWithImpl<Ingreso>(this as Ingreso, _$identity);

  /// Serializes this Ingreso to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Ingreso;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ingreso&&(identical(other.fecha, _this.fecha) || other.fecha == _this.fecha)&&(identical(other.monto, _this.monto) || other.monto == _this.monto)&&(identical(other.montoBruto, _this.montoBruto) || other.montoBruto == _this.montoBruto)&&(identical(other.descripcion, _this.descripcion) || other.descripcion == _this.descripcion)&&(identical(other.hora, _this.hora) || other.hora == _this.hora));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Ingreso;
  return Object.hash(runtimeType,_this.fecha,_this.monto,_this.montoBruto,_this.descripcion,_this.hora);
}

@override
String toString() {
  final _this = this as Ingreso;
  return 'Ingreso(fecha: ${_this.fecha}, monto: ${_this.monto}, montoBruto: ${_this.montoBruto}, descripcion: ${_this.descripcion}, hora: ${_this.hora})';
}


}

/// @nodoc
abstract mixin class $IngresoCopyWith<$Res>  {
  factory $IngresoCopyWith(Ingreso value, $Res Function(Ingreso) _then) = _$IngresoCopyWithImpl;
@useResult
$Res call({
 String fecha, double monto, double montoBruto, String descripcion, String? hora
});




}
/// @nodoc
class _$IngresoCopyWithImpl<$Res>
    implements $IngresoCopyWith<$Res> {
  _$IngresoCopyWithImpl(this._self, this._then);

  final Ingreso _self;
  final $Res Function(Ingreso) _then;

/// Create a copy of Ingreso
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fecha = null,Object? monto = null,Object? montoBruto = null,Object? descripcion = null,Object? hora = freezed,}) {
  return _then(Ingreso(
fecha: null == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as String,monto: null == monto ? _self.monto : monto // ignore: cast_nullable_to_non_nullable
as double,montoBruto: null == montoBruto ? _self.montoBruto : montoBruto // ignore: cast_nullable_to_non_nullable
as double,descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,hora: freezed == hora ? _self.hora : hora // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Ingreso].
extension IngresoPatterns on Ingreso {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Ingreso value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Ingreso() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Ingreso value)  $default,){
final _that = this;
switch (_that) {
case _Ingreso():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Ingreso value)?  $default,){
final _that = this;
switch (_that) {
case _Ingreso() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fecha,  double monto,  double montoBruto,  String descripcion,  String? hora)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Ingreso() when $default != null:
return $default(_that.fecha,_that.monto,_that.montoBruto,_that.descripcion,_that.hora);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fecha,  double monto,  double montoBruto,  String descripcion,  String? hora)  $default,) {final _that = this;
switch (_that) {
case _Ingreso():
return $default(_that.fecha,_that.monto,_that.montoBruto,_that.descripcion,_that.hora);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fecha,  double monto,  double montoBruto,  String descripcion,  String? hora)?  $default,) {final _that = this;
switch (_that) {
case _Ingreso() when $default != null:
return $default(_that.fecha,_that.monto,_that.montoBruto,_that.descripcion,_that.hora);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Ingreso implements Ingreso {
  const _Ingreso({required this.fecha, this.monto = 0, this.montoBruto = 0, this.descripcion = '', this.hora});
  factory _Ingreso.fromJson(Map<String, dynamic> json) => _$IngresoFromJson(json);

@override final  String fecha;
@override@JsonKey() final  double monto;
@override@JsonKey() final  double montoBruto;
@override@JsonKey() final  String descripcion;
/// Fecha y hora del viaje (ISO 8601); los servidores viejos no la envían.
@override final  String? hora;

/// Create a copy of Ingreso
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IngresoCopyWith<_Ingreso> get copyWith => __$IngresoCopyWithImpl<_Ingreso>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IngresoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ingreso&&(identical(other.fecha, fecha) || other.fecha == fecha)&&(identical(other.monto, monto) || other.monto == monto)&&(identical(other.montoBruto, montoBruto) || other.montoBruto == montoBruto)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.hora, hora) || other.hora == hora));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,fecha,monto,montoBruto,descripcion,hora);
}

@override
String toString() {
    return 'Ingreso(fecha: $fecha, monto: $monto, montoBruto: $montoBruto, descripcion: $descripcion, hora: $hora)';
}


}

/// @nodoc
abstract mixin class _$IngresoCopyWith<$Res> implements $IngresoCopyWith<$Res> {
  factory _$IngresoCopyWith(_Ingreso value, $Res Function(_Ingreso) _then) = __$IngresoCopyWithImpl;
@override @useResult
$Res call({
 String fecha, double monto, double montoBruto, String descripcion, String? hora
});




}
/// @nodoc
class __$IngresoCopyWithImpl<$Res>
    implements _$IngresoCopyWith<$Res> {
  __$IngresoCopyWithImpl(this._self, this._then);

  final _Ingreso _self;
  final $Res Function(_Ingreso) _then;

/// Create a copy of Ingreso
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fecha = null,Object? monto = null,Object? montoBruto = null,Object? descripcion = null,Object? hora = freezed,}) {
  return _then(_Ingreso(
fecha: null == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as String,monto: null == monto ? _self.monto : monto // ignore: cast_nullable_to_non_nullable
as double,montoBruto: null == montoBruto ? _self.montoBruto : montoBruto // ignore: cast_nullable_to_non_nullable
as double,descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,hora: freezed == hora ? _self.hora : hora // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
