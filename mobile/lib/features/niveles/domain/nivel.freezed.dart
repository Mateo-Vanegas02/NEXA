// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nivel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Beneficio {

 String get clave; String get titulo; String get descripcion; int get nivelRequerido; bool get activo;
/// Create a copy of Beneficio
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BeneficioCopyWith<Beneficio> get copyWith => _$BeneficioCopyWithImpl<Beneficio>(this as Beneficio, _$identity);

  /// Serializes this Beneficio to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Beneficio;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Beneficio&&(identical(other.clave, _this.clave) || other.clave == _this.clave)&&(identical(other.titulo, _this.titulo) || other.titulo == _this.titulo)&&(identical(other.descripcion, _this.descripcion) || other.descripcion == _this.descripcion)&&(identical(other.nivelRequerido, _this.nivelRequerido) || other.nivelRequerido == _this.nivelRequerido)&&(identical(other.activo, _this.activo) || other.activo == _this.activo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Beneficio;
  return Object.hash(runtimeType,_this.clave,_this.titulo,_this.descripcion,_this.nivelRequerido,_this.activo);
}

@override
String toString() {
  final _this = this as Beneficio;
  return 'Beneficio(clave: ${_this.clave}, titulo: ${_this.titulo}, descripcion: ${_this.descripcion}, nivelRequerido: ${_this.nivelRequerido}, activo: ${_this.activo})';
}


}

/// @nodoc
abstract mixin class $BeneficioCopyWith<$Res>  {
  factory $BeneficioCopyWith(Beneficio value, $Res Function(Beneficio) _then) = _$BeneficioCopyWithImpl;
@useResult
$Res call({
 String clave, String titulo, String descripcion, int nivelRequerido, bool activo
});




}
/// @nodoc
class _$BeneficioCopyWithImpl<$Res>
    implements $BeneficioCopyWith<$Res> {
  _$BeneficioCopyWithImpl(this._self, this._then);

  final Beneficio _self;
  final $Res Function(Beneficio) _then;

/// Create a copy of Beneficio
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clave = null,Object? titulo = null,Object? descripcion = null,Object? nivelRequerido = null,Object? activo = null,}) {
  return _then(Beneficio(
clave: null == clave ? _self.clave : clave // ignore: cast_nullable_to_non_nullable
as String,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,nivelRequerido: null == nivelRequerido ? _self.nivelRequerido : nivelRequerido // ignore: cast_nullable_to_non_nullable
as int,activo: null == activo ? _self.activo : activo // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Beneficio].
extension BeneficioPatterns on Beneficio {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Beneficio value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Beneficio() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Beneficio value)  $default,){
final _that = this;
switch (_that) {
case _Beneficio():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Beneficio value)?  $default,){
final _that = this;
switch (_that) {
case _Beneficio() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clave,  String titulo,  String descripcion,  int nivelRequerido,  bool activo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Beneficio() when $default != null:
return $default(_that.clave,_that.titulo,_that.descripcion,_that.nivelRequerido,_that.activo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clave,  String titulo,  String descripcion,  int nivelRequerido,  bool activo)  $default,) {final _that = this;
switch (_that) {
case _Beneficio():
return $default(_that.clave,_that.titulo,_that.descripcion,_that.nivelRequerido,_that.activo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clave,  String titulo,  String descripcion,  int nivelRequerido,  bool activo)?  $default,) {final _that = this;
switch (_that) {
case _Beneficio() when $default != null:
return $default(_that.clave,_that.titulo,_that.descripcion,_that.nivelRequerido,_that.activo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Beneficio implements Beneficio {
  const _Beneficio({required this.clave, required this.titulo, this.descripcion = '', this.nivelRequerido = 0, this.activo = false});
  factory _Beneficio.fromJson(Map<String, dynamic> json) => _$BeneficioFromJson(json);

@override final  String clave;
@override final  String titulo;
@override@JsonKey() final  String descripcion;
@override@JsonKey() final  int nivelRequerido;
@override@JsonKey() final  bool activo;

/// Create a copy of Beneficio
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BeneficioCopyWith<_Beneficio> get copyWith => __$BeneficioCopyWithImpl<_Beneficio>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BeneficioToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Beneficio&&(identical(other.clave, clave) || other.clave == clave)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.nivelRequerido, nivelRequerido) || other.nivelRequerido == nivelRequerido)&&(identical(other.activo, activo) || other.activo == activo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,clave,titulo,descripcion,nivelRequerido,activo);
}

@override
String toString() {
    return 'Beneficio(clave: $clave, titulo: $titulo, descripcion: $descripcion, nivelRequerido: $nivelRequerido, activo: $activo)';
}


}

/// @nodoc
abstract mixin class _$BeneficioCopyWith<$Res> implements $BeneficioCopyWith<$Res> {
  factory _$BeneficioCopyWith(_Beneficio value, $Res Function(_Beneficio) _then) = __$BeneficioCopyWithImpl;
@override @useResult
$Res call({
 String clave, String titulo, String descripcion, int nivelRequerido, bool activo
});




}
/// @nodoc
class __$BeneficioCopyWithImpl<$Res>
    implements _$BeneficioCopyWith<$Res> {
  __$BeneficioCopyWithImpl(this._self, this._then);

  final _Beneficio _self;
  final $Res Function(_Beneficio) _then;

/// Create a copy of Beneficio
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clave = null,Object? titulo = null,Object? descripcion = null,Object? nivelRequerido = null,Object? activo = null,}) {
  return _then(_Beneficio(
clave: null == clave ? _self.clave : clave // ignore: cast_nullable_to_non_nullable
as String,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,nivelRequerido: null == nivelRequerido ? _self.nivelRequerido : nivelRequerido // ignore: cast_nullable_to_non_nullable
as int,activo: null == activo ? _self.activo : activo // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$NivelInfo {

 int get nivel; int get xp;/// Descuento en los viajes del pasajero (fracción: 0,03 = 3 %). Solo pasajeros.
 double? get descuento; List<Beneficio> get beneficios;/// Comisión del conductor en este nivel (fracción). Solo conductores.
 double? get comision;
/// Create a copy of NivelInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NivelInfoCopyWith<NivelInfo> get copyWith => _$NivelInfoCopyWithImpl<NivelInfo>(this as NivelInfo, _$identity);

  /// Serializes this NivelInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NivelInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NivelInfo&&(identical(other.nivel, _this.nivel) || other.nivel == _this.nivel)&&(identical(other.xp, _this.xp) || other.xp == _this.xp)&&(identical(other.descuento, _this.descuento) || other.descuento == _this.descuento)&&const DeepCollectionEquality().equals(other.beneficios, _this.beneficios)&&(identical(other.comision, _this.comision) || other.comision == _this.comision));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NivelInfo;
  return Object.hash(runtimeType,_this.nivel,_this.xp,_this.descuento,const DeepCollectionEquality().hash(_this.beneficios),_this.comision);
}

@override
String toString() {
  final _this = this as NivelInfo;
  return 'NivelInfo(nivel: ${_this.nivel}, xp: ${_this.xp}, descuento: ${_this.descuento}, beneficios: ${_this.beneficios}, comision: ${_this.comision})';
}


}

/// @nodoc
abstract mixin class $NivelInfoCopyWith<$Res>  {
  factory $NivelInfoCopyWith(NivelInfo value, $Res Function(NivelInfo) _then) = _$NivelInfoCopyWithImpl;
@useResult
$Res call({
 int nivel, int xp, double? descuento, List<Beneficio> beneficios, double? comision
});




}
/// @nodoc
class _$NivelInfoCopyWithImpl<$Res>
    implements $NivelInfoCopyWith<$Res> {
  _$NivelInfoCopyWithImpl(this._self, this._then);

  final NivelInfo _self;
  final $Res Function(NivelInfo) _then;

/// Create a copy of NivelInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nivel = null,Object? xp = null,Object? descuento = freezed,Object? beneficios = null,Object? comision = freezed,}) {
  return _then(NivelInfo(
nivel: null == nivel ? _self.nivel : nivel // ignore: cast_nullable_to_non_nullable
as int,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,descuento: freezed == descuento ? _self.descuento : descuento // ignore: cast_nullable_to_non_nullable
as double?,beneficios: null == beneficios ? _self.beneficios : beneficios // ignore: cast_nullable_to_non_nullable
as List<Beneficio>,comision: freezed == comision ? _self.comision : comision // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [NivelInfo].
extension NivelInfoPatterns on NivelInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NivelInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NivelInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NivelInfo value)  $default,){
final _that = this;
switch (_that) {
case _NivelInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NivelInfo value)?  $default,){
final _that = this;
switch (_that) {
case _NivelInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int nivel,  int xp,  double? descuento,  List<Beneficio> beneficios,  double? comision)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NivelInfo() when $default != null:
return $default(_that.nivel,_that.xp,_that.descuento,_that.beneficios,_that.comision);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int nivel,  int xp,  double? descuento,  List<Beneficio> beneficios,  double? comision)  $default,) {final _that = this;
switch (_that) {
case _NivelInfo():
return $default(_that.nivel,_that.xp,_that.descuento,_that.beneficios,_that.comision);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int nivel,  int xp,  double? descuento,  List<Beneficio> beneficios,  double? comision)?  $default,) {final _that = this;
switch (_that) {
case _NivelInfo() when $default != null:
return $default(_that.nivel,_that.xp,_that.descuento,_that.beneficios,_that.comision);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NivelInfo extends NivelInfo {
  const _NivelInfo({required this.nivel, required this.xp, this.descuento,  List<Beneficio> beneficios = const <Beneficio>[], this.comision}): _beneficios = beneficios,super._();
  factory _NivelInfo.fromJson(Map<String, dynamic> json) => _$NivelInfoFromJson(json);

@override final  int nivel;
@override final  int xp;
/// Descuento en los viajes del pasajero (fracción: 0,03 = 3 %). Solo pasajeros.
@override final  double? descuento;
 final  List<Beneficio> _beneficios;
@override@JsonKey() List<Beneficio> get beneficios {
  if (_beneficios is EqualUnmodifiableListView) return _beneficios;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_beneficios);
}

/// Comisión del conductor en este nivel (fracción). Solo conductores.
@override final  double? comision;

/// Create a copy of NivelInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NivelInfoCopyWith<_NivelInfo> get copyWith => __$NivelInfoCopyWithImpl<_NivelInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NivelInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NivelInfo&&(identical(other.nivel, nivel) || other.nivel == nivel)&&(identical(other.xp, xp) || other.xp == xp)&&(identical(other.descuento, descuento) || other.descuento == descuento)&&const DeepCollectionEquality().equals(other.beneficios, _beneficios)&&(identical(other.comision, comision) || other.comision == comision));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,nivel,xp,descuento,const DeepCollectionEquality().hash(_beneficios),comision);
}

@override
String toString() {
    return 'NivelInfo(nivel: $nivel, xp: $xp, descuento: $descuento, beneficios: $beneficios, comision: $comision)';
}


}

/// @nodoc
abstract mixin class _$NivelInfoCopyWith<$Res> implements $NivelInfoCopyWith<$Res> {
  factory _$NivelInfoCopyWith(_NivelInfo value, $Res Function(_NivelInfo) _then) = __$NivelInfoCopyWithImpl;
@override @useResult
$Res call({
 int nivel, int xp, double? descuento, List<Beneficio> beneficios, double? comision
});




}
/// @nodoc
class __$NivelInfoCopyWithImpl<$Res>
    implements _$NivelInfoCopyWith<$Res> {
  __$NivelInfoCopyWithImpl(this._self, this._then);

  final _NivelInfo _self;
  final $Res Function(_NivelInfo) _then;

/// Create a copy of NivelInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nivel = null,Object? xp = null,Object? descuento = freezed,Object? beneficios = null,Object? comision = freezed,}) {
  return _then(_NivelInfo(
nivel: null == nivel ? _self.nivel : nivel // ignore: cast_nullable_to_non_nullable
as int,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,descuento: freezed == descuento ? _self.descuento : descuento // ignore: cast_nullable_to_non_nullable
as double?,beneficios: null == beneficios ? _self._beneficios : beneficios // ignore: cast_nullable_to_non_nullable
as List<Beneficio>,comision: freezed == comision ? _self.comision : comision // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$Requisito {

 String get texto; bool get cumplido;
/// Create a copy of Requisito
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RequisitoCopyWith<Requisito> get copyWith => _$RequisitoCopyWithImpl<Requisito>(this as Requisito, _$identity);

  /// Serializes this Requisito to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Requisito;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Requisito&&(identical(other.texto, _this.texto) || other.texto == _this.texto)&&(identical(other.cumplido, _this.cumplido) || other.cumplido == _this.cumplido));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Requisito;
  return Object.hash(runtimeType,_this.texto,_this.cumplido);
}

@override
String toString() {
  final _this = this as Requisito;
  return 'Requisito(texto: ${_this.texto}, cumplido: ${_this.cumplido})';
}


}

/// @nodoc
abstract mixin class $RequisitoCopyWith<$Res>  {
  factory $RequisitoCopyWith(Requisito value, $Res Function(Requisito) _then) = _$RequisitoCopyWithImpl;
@useResult
$Res call({
 String texto, bool cumplido
});




}
/// @nodoc
class _$RequisitoCopyWithImpl<$Res>
    implements $RequisitoCopyWith<$Res> {
  _$RequisitoCopyWithImpl(this._self, this._then);

  final Requisito _self;
  final $Res Function(Requisito) _then;

/// Create a copy of Requisito
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? texto = null,Object? cumplido = null,}) {
  return _then(Requisito(
texto: null == texto ? _self.texto : texto // ignore: cast_nullable_to_non_nullable
as String,cumplido: null == cumplido ? _self.cumplido : cumplido // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Requisito].
extension RequisitoPatterns on Requisito {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Requisito value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Requisito() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Requisito value)  $default,){
final _that = this;
switch (_that) {
case _Requisito():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Requisito value)?  $default,){
final _that = this;
switch (_that) {
case _Requisito() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String texto,  bool cumplido)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Requisito() when $default != null:
return $default(_that.texto,_that.cumplido);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String texto,  bool cumplido)  $default,) {final _that = this;
switch (_that) {
case _Requisito():
return $default(_that.texto,_that.cumplido);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String texto,  bool cumplido)?  $default,) {final _that = this;
switch (_that) {
case _Requisito() when $default != null:
return $default(_that.texto,_that.cumplido);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Requisito implements Requisito {
  const _Requisito({required this.texto, this.cumplido = false});
  factory _Requisito.fromJson(Map<String, dynamic> json) => _$RequisitoFromJson(json);

@override final  String texto;
@override@JsonKey() final  bool cumplido;

/// Create a copy of Requisito
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RequisitoCopyWith<_Requisito> get copyWith => __$RequisitoCopyWithImpl<_Requisito>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RequisitoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Requisito&&(identical(other.texto, texto) || other.texto == texto)&&(identical(other.cumplido, cumplido) || other.cumplido == cumplido));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,texto,cumplido);
}

@override
String toString() {
    return 'Requisito(texto: $texto, cumplido: $cumplido)';
}


}

/// @nodoc
abstract mixin class _$RequisitoCopyWith<$Res> implements $RequisitoCopyWith<$Res> {
  factory _$RequisitoCopyWith(_Requisito value, $Res Function(_Requisito) _then) = __$RequisitoCopyWithImpl;
@override @useResult
$Res call({
 String texto, bool cumplido
});




}
/// @nodoc
class __$RequisitoCopyWithImpl<$Res>
    implements _$RequisitoCopyWith<$Res> {
  __$RequisitoCopyWithImpl(this._self, this._then);

  final _Requisito _self;
  final $Res Function(_Requisito) _then;

/// Create a copy of Requisito
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? texto = null,Object? cumplido = null,}) {
  return _then(_Requisito(
texto: null == texto ? _self.texto : texto // ignore: cast_nullable_to_non_nullable
as String,cumplido: null == cumplido ? _self.cumplido : cumplido // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ConductorInfo {

 double get comisionActual; double? get comisionSiguiente; double? get calificacion; double get aceptacion; double get cancelacion; List<Requisito> get requisitosSiguiente; bool get bloqueadoPorCalidad;
/// Create a copy of ConductorInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConductorInfoCopyWith<ConductorInfo> get copyWith => _$ConductorInfoCopyWithImpl<ConductorInfo>(this as ConductorInfo, _$identity);

  /// Serializes this ConductorInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ConductorInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConductorInfo&&(identical(other.comisionActual, _this.comisionActual) || other.comisionActual == _this.comisionActual)&&(identical(other.comisionSiguiente, _this.comisionSiguiente) || other.comisionSiguiente == _this.comisionSiguiente)&&(identical(other.calificacion, _this.calificacion) || other.calificacion == _this.calificacion)&&(identical(other.aceptacion, _this.aceptacion) || other.aceptacion == _this.aceptacion)&&(identical(other.cancelacion, _this.cancelacion) || other.cancelacion == _this.cancelacion)&&const DeepCollectionEquality().equals(other.requisitosSiguiente, _this.requisitosSiguiente)&&(identical(other.bloqueadoPorCalidad, _this.bloqueadoPorCalidad) || other.bloqueadoPorCalidad == _this.bloqueadoPorCalidad));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ConductorInfo;
  return Object.hash(runtimeType,_this.comisionActual,_this.comisionSiguiente,_this.calificacion,_this.aceptacion,_this.cancelacion,const DeepCollectionEquality().hash(_this.requisitosSiguiente),_this.bloqueadoPorCalidad);
}

@override
String toString() {
  final _this = this as ConductorInfo;
  return 'ConductorInfo(comisionActual: ${_this.comisionActual}, comisionSiguiente: ${_this.comisionSiguiente}, calificacion: ${_this.calificacion}, aceptacion: ${_this.aceptacion}, cancelacion: ${_this.cancelacion}, requisitosSiguiente: ${_this.requisitosSiguiente}, bloqueadoPorCalidad: ${_this.bloqueadoPorCalidad})';
}


}

/// @nodoc
abstract mixin class $ConductorInfoCopyWith<$Res>  {
  factory $ConductorInfoCopyWith(ConductorInfo value, $Res Function(ConductorInfo) _then) = _$ConductorInfoCopyWithImpl;
@useResult
$Res call({
 double comisionActual, double? comisionSiguiente, double? calificacion, double aceptacion, double cancelacion, List<Requisito> requisitosSiguiente, bool bloqueadoPorCalidad
});




}
/// @nodoc
class _$ConductorInfoCopyWithImpl<$Res>
    implements $ConductorInfoCopyWith<$Res> {
  _$ConductorInfoCopyWithImpl(this._self, this._then);

  final ConductorInfo _self;
  final $Res Function(ConductorInfo) _then;

/// Create a copy of ConductorInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? comisionActual = null,Object? comisionSiguiente = freezed,Object? calificacion = freezed,Object? aceptacion = null,Object? cancelacion = null,Object? requisitosSiguiente = null,Object? bloqueadoPorCalidad = null,}) {
  return _then(ConductorInfo(
comisionActual: null == comisionActual ? _self.comisionActual : comisionActual // ignore: cast_nullable_to_non_nullable
as double,comisionSiguiente: freezed == comisionSiguiente ? _self.comisionSiguiente : comisionSiguiente // ignore: cast_nullable_to_non_nullable
as double?,calificacion: freezed == calificacion ? _self.calificacion : calificacion // ignore: cast_nullable_to_non_nullable
as double?,aceptacion: null == aceptacion ? _self.aceptacion : aceptacion // ignore: cast_nullable_to_non_nullable
as double,cancelacion: null == cancelacion ? _self.cancelacion : cancelacion // ignore: cast_nullable_to_non_nullable
as double,requisitosSiguiente: null == requisitosSiguiente ? _self.requisitosSiguiente : requisitosSiguiente // ignore: cast_nullable_to_non_nullable
as List<Requisito>,bloqueadoPorCalidad: null == bloqueadoPorCalidad ? _self.bloqueadoPorCalidad : bloqueadoPorCalidad // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ConductorInfo].
extension ConductorInfoPatterns on ConductorInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConductorInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConductorInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConductorInfo value)  $default,){
final _that = this;
switch (_that) {
case _ConductorInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConductorInfo value)?  $default,){
final _that = this;
switch (_that) {
case _ConductorInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double comisionActual,  double? comisionSiguiente,  double? calificacion,  double aceptacion,  double cancelacion,  List<Requisito> requisitosSiguiente,  bool bloqueadoPorCalidad)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConductorInfo() when $default != null:
return $default(_that.comisionActual,_that.comisionSiguiente,_that.calificacion,_that.aceptacion,_that.cancelacion,_that.requisitosSiguiente,_that.bloqueadoPorCalidad);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double comisionActual,  double? comisionSiguiente,  double? calificacion,  double aceptacion,  double cancelacion,  List<Requisito> requisitosSiguiente,  bool bloqueadoPorCalidad)  $default,) {final _that = this;
switch (_that) {
case _ConductorInfo():
return $default(_that.comisionActual,_that.comisionSiguiente,_that.calificacion,_that.aceptacion,_that.cancelacion,_that.requisitosSiguiente,_that.bloqueadoPorCalidad);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double comisionActual,  double? comisionSiguiente,  double? calificacion,  double aceptacion,  double cancelacion,  List<Requisito> requisitosSiguiente,  bool bloqueadoPorCalidad)?  $default,) {final _that = this;
switch (_that) {
case _ConductorInfo() when $default != null:
return $default(_that.comisionActual,_that.comisionSiguiente,_that.calificacion,_that.aceptacion,_that.cancelacion,_that.requisitosSiguiente,_that.bloqueadoPorCalidad);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConductorInfo implements ConductorInfo {
  const _ConductorInfo({required this.comisionActual, this.comisionSiguiente, this.calificacion, this.aceptacion = 0, this.cancelacion = 0,  List<Requisito> requisitosSiguiente = const <Requisito>[], this.bloqueadoPorCalidad = false}): _requisitosSiguiente = requisitosSiguiente;
  factory _ConductorInfo.fromJson(Map<String, dynamic> json) => _$ConductorInfoFromJson(json);

@override final  double comisionActual;
@override final  double? comisionSiguiente;
@override final  double? calificacion;
@override@JsonKey() final  double aceptacion;
@override@JsonKey() final  double cancelacion;
 final  List<Requisito> _requisitosSiguiente;
@override@JsonKey() List<Requisito> get requisitosSiguiente {
  if (_requisitosSiguiente is EqualUnmodifiableListView) return _requisitosSiguiente;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requisitosSiguiente);
}

@override@JsonKey() final  bool bloqueadoPorCalidad;

/// Create a copy of ConductorInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConductorInfoCopyWith<_ConductorInfo> get copyWith => __$ConductorInfoCopyWithImpl<_ConductorInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConductorInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConductorInfo&&(identical(other.comisionActual, comisionActual) || other.comisionActual == comisionActual)&&(identical(other.comisionSiguiente, comisionSiguiente) || other.comisionSiguiente == comisionSiguiente)&&(identical(other.calificacion, calificacion) || other.calificacion == calificacion)&&(identical(other.aceptacion, aceptacion) || other.aceptacion == aceptacion)&&(identical(other.cancelacion, cancelacion) || other.cancelacion == cancelacion)&&const DeepCollectionEquality().equals(other.requisitosSiguiente, _requisitosSiguiente)&&(identical(other.bloqueadoPorCalidad, bloqueadoPorCalidad) || other.bloqueadoPorCalidad == bloqueadoPorCalidad));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,comisionActual,comisionSiguiente,calificacion,aceptacion,cancelacion,const DeepCollectionEquality().hash(_requisitosSiguiente),bloqueadoPorCalidad);
}

@override
String toString() {
    return 'ConductorInfo(comisionActual: $comisionActual, comisionSiguiente: $comisionSiguiente, calificacion: $calificacion, aceptacion: $aceptacion, cancelacion: $cancelacion, requisitosSiguiente: $requisitosSiguiente, bloqueadoPorCalidad: $bloqueadoPorCalidad)';
}


}

/// @nodoc
abstract mixin class _$ConductorInfoCopyWith<$Res> implements $ConductorInfoCopyWith<$Res> {
  factory _$ConductorInfoCopyWith(_ConductorInfo value, $Res Function(_ConductorInfo) _then) = __$ConductorInfoCopyWithImpl;
@override @useResult
$Res call({
 double comisionActual, double? comisionSiguiente, double? calificacion, double aceptacion, double cancelacion, List<Requisito> requisitosSiguiente, bool bloqueadoPorCalidad
});




}
/// @nodoc
class __$ConductorInfoCopyWithImpl<$Res>
    implements _$ConductorInfoCopyWith<$Res> {
  __$ConductorInfoCopyWithImpl(this._self, this._then);

  final _ConductorInfo _self;
  final $Res Function(_ConductorInfo) _then;

/// Create a copy of ConductorInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? comisionActual = null,Object? comisionSiguiente = freezed,Object? calificacion = freezed,Object? aceptacion = null,Object? cancelacion = null,Object? requisitosSiguiente = null,Object? bloqueadoPorCalidad = null,}) {
  return _then(_ConductorInfo(
comisionActual: null == comisionActual ? _self.comisionActual : comisionActual // ignore: cast_nullable_to_non_nullable
as double,comisionSiguiente: freezed == comisionSiguiente ? _self.comisionSiguiente : comisionSiguiente // ignore: cast_nullable_to_non_nullable
as double?,calificacion: freezed == calificacion ? _self.calificacion : calificacion // ignore: cast_nullable_to_non_nullable
as double?,aceptacion: null == aceptacion ? _self.aceptacion : aceptacion // ignore: cast_nullable_to_non_nullable
as double,cancelacion: null == cancelacion ? _self.cancelacion : cancelacion // ignore: cast_nullable_to_non_nullable
as double,requisitosSiguiente: null == requisitosSiguiente ? _self._requisitosSiguiente : requisitosSiguiente // ignore: cast_nullable_to_non_nullable
as List<Requisito>,bloqueadoPorCalidad: null == bloqueadoPorCalidad ? _self.bloqueadoPorCalidad : bloqueadoPorCalidad // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$NivelEstado {

 String get usuarioId; String get rol; int get nivel; int get xpActual; int get xpNivelActual; int? get xpSiguienteNivel; int get xpFaltante; double get progreso;/// Descuento actual del pasajero (fracción). 0 para conductores.
 double get descuento;/// Segundos de ventaja de recogida que da el nivel (pasajero).
 int get prioridadSegundos; List<NivelInfo> get niveles; List<Beneficio> get beneficiosActivos; ConductorInfo? get conductor;
/// Create a copy of NivelEstado
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NivelEstadoCopyWith<NivelEstado> get copyWith => _$NivelEstadoCopyWithImpl<NivelEstado>(this as NivelEstado, _$identity);

  /// Serializes this NivelEstado to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NivelEstado;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NivelEstado&&(identical(other.usuarioId, _this.usuarioId) || other.usuarioId == _this.usuarioId)&&(identical(other.rol, _this.rol) || other.rol == _this.rol)&&(identical(other.nivel, _this.nivel) || other.nivel == _this.nivel)&&(identical(other.xpActual, _this.xpActual) || other.xpActual == _this.xpActual)&&(identical(other.xpNivelActual, _this.xpNivelActual) || other.xpNivelActual == _this.xpNivelActual)&&(identical(other.xpSiguienteNivel, _this.xpSiguienteNivel) || other.xpSiguienteNivel == _this.xpSiguienteNivel)&&(identical(other.xpFaltante, _this.xpFaltante) || other.xpFaltante == _this.xpFaltante)&&(identical(other.progreso, _this.progreso) || other.progreso == _this.progreso)&&(identical(other.descuento, _this.descuento) || other.descuento == _this.descuento)&&(identical(other.prioridadSegundos, _this.prioridadSegundos) || other.prioridadSegundos == _this.prioridadSegundos)&&const DeepCollectionEquality().equals(other.niveles, _this.niveles)&&const DeepCollectionEquality().equals(other.beneficiosActivos, _this.beneficiosActivos)&&(identical(other.conductor, _this.conductor) || other.conductor == _this.conductor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NivelEstado;
  return Object.hash(runtimeType,_this.usuarioId,_this.rol,_this.nivel,_this.xpActual,_this.xpNivelActual,_this.xpSiguienteNivel,_this.xpFaltante,_this.progreso,_this.descuento,_this.prioridadSegundos,const DeepCollectionEquality().hash(_this.niveles),const DeepCollectionEquality().hash(_this.beneficiosActivos),_this.conductor);
}

@override
String toString() {
  final _this = this as NivelEstado;
  return 'NivelEstado(usuarioId: ${_this.usuarioId}, rol: ${_this.rol}, nivel: ${_this.nivel}, xpActual: ${_this.xpActual}, xpNivelActual: ${_this.xpNivelActual}, xpSiguienteNivel: ${_this.xpSiguienteNivel}, xpFaltante: ${_this.xpFaltante}, progreso: ${_this.progreso}, descuento: ${_this.descuento}, prioridadSegundos: ${_this.prioridadSegundos}, niveles: ${_this.niveles}, beneficiosActivos: ${_this.beneficiosActivos}, conductor: ${_this.conductor})';
}


}

/// @nodoc
abstract mixin class $NivelEstadoCopyWith<$Res>  {
  factory $NivelEstadoCopyWith(NivelEstado value, $Res Function(NivelEstado) _then) = _$NivelEstadoCopyWithImpl;
@useResult
$Res call({
 String usuarioId, String rol, int nivel, int xpActual, int xpNivelActual, int? xpSiguienteNivel, int xpFaltante, double progreso, double descuento, int prioridadSegundos, List<NivelInfo> niveles, List<Beneficio> beneficiosActivos, ConductorInfo? conductor
});


$ConductorInfoCopyWith<$Res>? get conductor;

}
/// @nodoc
class _$NivelEstadoCopyWithImpl<$Res>
    implements $NivelEstadoCopyWith<$Res> {
  _$NivelEstadoCopyWithImpl(this._self, this._then);

  final NivelEstado _self;
  final $Res Function(NivelEstado) _then;

/// Create a copy of NivelEstado
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? usuarioId = null,Object? rol = null,Object? nivel = null,Object? xpActual = null,Object? xpNivelActual = null,Object? xpSiguienteNivel = freezed,Object? xpFaltante = null,Object? progreso = null,Object? descuento = null,Object? prioridadSegundos = null,Object? niveles = null,Object? beneficiosActivos = null,Object? conductor = freezed,}) {
  return _then(NivelEstado(
usuarioId: null == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as String,rol: null == rol ? _self.rol : rol // ignore: cast_nullable_to_non_nullable
as String,nivel: null == nivel ? _self.nivel : nivel // ignore: cast_nullable_to_non_nullable
as int,xpActual: null == xpActual ? _self.xpActual : xpActual // ignore: cast_nullable_to_non_nullable
as int,xpNivelActual: null == xpNivelActual ? _self.xpNivelActual : xpNivelActual // ignore: cast_nullable_to_non_nullable
as int,xpSiguienteNivel: freezed == xpSiguienteNivel ? _self.xpSiguienteNivel : xpSiguienteNivel // ignore: cast_nullable_to_non_nullable
as int?,xpFaltante: null == xpFaltante ? _self.xpFaltante : xpFaltante // ignore: cast_nullable_to_non_nullable
as int,progreso: null == progreso ? _self.progreso : progreso // ignore: cast_nullable_to_non_nullable
as double,descuento: null == descuento ? _self.descuento : descuento // ignore: cast_nullable_to_non_nullable
as double,prioridadSegundos: null == prioridadSegundos ? _self.prioridadSegundos : prioridadSegundos // ignore: cast_nullable_to_non_nullable
as int,niveles: null == niveles ? _self.niveles : niveles // ignore: cast_nullable_to_non_nullable
as List<NivelInfo>,beneficiosActivos: null == beneficiosActivos ? _self.beneficiosActivos : beneficiosActivos // ignore: cast_nullable_to_non_nullable
as List<Beneficio>,conductor: freezed == conductor ? _self.conductor : conductor // ignore: cast_nullable_to_non_nullable
as ConductorInfo?,
  ));
}
/// Create a copy of NivelEstado
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConductorInfoCopyWith<$Res>? get conductor {
    if (_self.conductor == null) {
    return null;
  }

  return $ConductorInfoCopyWith<$Res>(_self.conductor!, (value) {
    return _then(_self.copyWith(conductor: value));
  });
}
}


/// Adds pattern-matching-related methods to [NivelEstado].
extension NivelEstadoPatterns on NivelEstado {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NivelEstado value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NivelEstado() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NivelEstado value)  $default,){
final _that = this;
switch (_that) {
case _NivelEstado():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NivelEstado value)?  $default,){
final _that = this;
switch (_that) {
case _NivelEstado() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String usuarioId,  String rol,  int nivel,  int xpActual,  int xpNivelActual,  int? xpSiguienteNivel,  int xpFaltante,  double progreso,  double descuento,  int prioridadSegundos,  List<NivelInfo> niveles,  List<Beneficio> beneficiosActivos,  ConductorInfo? conductor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NivelEstado() when $default != null:
return $default(_that.usuarioId,_that.rol,_that.nivel,_that.xpActual,_that.xpNivelActual,_that.xpSiguienteNivel,_that.xpFaltante,_that.progreso,_that.descuento,_that.prioridadSegundos,_that.niveles,_that.beneficiosActivos,_that.conductor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String usuarioId,  String rol,  int nivel,  int xpActual,  int xpNivelActual,  int? xpSiguienteNivel,  int xpFaltante,  double progreso,  double descuento,  int prioridadSegundos,  List<NivelInfo> niveles,  List<Beneficio> beneficiosActivos,  ConductorInfo? conductor)  $default,) {final _that = this;
switch (_that) {
case _NivelEstado():
return $default(_that.usuarioId,_that.rol,_that.nivel,_that.xpActual,_that.xpNivelActual,_that.xpSiguienteNivel,_that.xpFaltante,_that.progreso,_that.descuento,_that.prioridadSegundos,_that.niveles,_that.beneficiosActivos,_that.conductor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String usuarioId,  String rol,  int nivel,  int xpActual,  int xpNivelActual,  int? xpSiguienteNivel,  int xpFaltante,  double progreso,  double descuento,  int prioridadSegundos,  List<NivelInfo> niveles,  List<Beneficio> beneficiosActivos,  ConductorInfo? conductor)?  $default,) {final _that = this;
switch (_that) {
case _NivelEstado() when $default != null:
return $default(_that.usuarioId,_that.rol,_that.nivel,_that.xpActual,_that.xpNivelActual,_that.xpSiguienteNivel,_that.xpFaltante,_that.progreso,_that.descuento,_that.prioridadSegundos,_that.niveles,_that.beneficiosActivos,_that.conductor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NivelEstado extends NivelEstado {
  const _NivelEstado({required this.usuarioId, required this.rol, required this.nivel, this.xpActual = 0, this.xpNivelActual = 0, this.xpSiguienteNivel, this.xpFaltante = 0, this.progreso = 0, this.descuento = 0, this.prioridadSegundos = 0,  List<NivelInfo> niveles = const <NivelInfo>[],  List<Beneficio> beneficiosActivos = const <Beneficio>[], this.conductor}): _niveles = niveles,_beneficiosActivos = beneficiosActivos,super._();
  factory _NivelEstado.fromJson(Map<String, dynamic> json) => _$NivelEstadoFromJson(json);

@override final  String usuarioId;
@override final  String rol;
@override final  int nivel;
@override@JsonKey() final  int xpActual;
@override@JsonKey() final  int xpNivelActual;
@override final  int? xpSiguienteNivel;
@override@JsonKey() final  int xpFaltante;
@override@JsonKey() final  double progreso;
/// Descuento actual del pasajero (fracción). 0 para conductores.
@override@JsonKey() final  double descuento;
/// Segundos de ventaja de recogida que da el nivel (pasajero).
@override@JsonKey() final  int prioridadSegundos;
 final  List<NivelInfo> _niveles;
@override@JsonKey() List<NivelInfo> get niveles {
  if (_niveles is EqualUnmodifiableListView) return _niveles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_niveles);
}

 final  List<Beneficio> _beneficiosActivos;
@override@JsonKey() List<Beneficio> get beneficiosActivos {
  if (_beneficiosActivos is EqualUnmodifiableListView) return _beneficiosActivos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_beneficiosActivos);
}

@override final  ConductorInfo? conductor;

/// Create a copy of NivelEstado
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NivelEstadoCopyWith<_NivelEstado> get copyWith => __$NivelEstadoCopyWithImpl<_NivelEstado>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NivelEstadoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NivelEstado&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId)&&(identical(other.rol, rol) || other.rol == rol)&&(identical(other.nivel, nivel) || other.nivel == nivel)&&(identical(other.xpActual, xpActual) || other.xpActual == xpActual)&&(identical(other.xpNivelActual, xpNivelActual) || other.xpNivelActual == xpNivelActual)&&(identical(other.xpSiguienteNivel, xpSiguienteNivel) || other.xpSiguienteNivel == xpSiguienteNivel)&&(identical(other.xpFaltante, xpFaltante) || other.xpFaltante == xpFaltante)&&(identical(other.progreso, progreso) || other.progreso == progreso)&&(identical(other.descuento, descuento) || other.descuento == descuento)&&(identical(other.prioridadSegundos, prioridadSegundos) || other.prioridadSegundos == prioridadSegundos)&&const DeepCollectionEquality().equals(other.niveles, _niveles)&&const DeepCollectionEquality().equals(other.beneficiosActivos, _beneficiosActivos)&&(identical(other.conductor, conductor) || other.conductor == conductor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,usuarioId,rol,nivel,xpActual,xpNivelActual,xpSiguienteNivel,xpFaltante,progreso,descuento,prioridadSegundos,const DeepCollectionEquality().hash(_niveles),const DeepCollectionEquality().hash(_beneficiosActivos),conductor);
}

@override
String toString() {
    return 'NivelEstado(usuarioId: $usuarioId, rol: $rol, nivel: $nivel, xpActual: $xpActual, xpNivelActual: $xpNivelActual, xpSiguienteNivel: $xpSiguienteNivel, xpFaltante: $xpFaltante, progreso: $progreso, descuento: $descuento, prioridadSegundos: $prioridadSegundos, niveles: $niveles, beneficiosActivos: $beneficiosActivos, conductor: $conductor)';
}


}

/// @nodoc
abstract mixin class _$NivelEstadoCopyWith<$Res> implements $NivelEstadoCopyWith<$Res> {
  factory _$NivelEstadoCopyWith(_NivelEstado value, $Res Function(_NivelEstado) _then) = __$NivelEstadoCopyWithImpl;
@override @useResult
$Res call({
 String usuarioId, String rol, int nivel, int xpActual, int xpNivelActual, int? xpSiguienteNivel, int xpFaltante, double progreso, double descuento, int prioridadSegundos, List<NivelInfo> niveles, List<Beneficio> beneficiosActivos, ConductorInfo? conductor
});


@override $ConductorInfoCopyWith<$Res>? get conductor;

}
/// @nodoc
class __$NivelEstadoCopyWithImpl<$Res>
    implements _$NivelEstadoCopyWith<$Res> {
  __$NivelEstadoCopyWithImpl(this._self, this._then);

  final _NivelEstado _self;
  final $Res Function(_NivelEstado) _then;

/// Create a copy of NivelEstado
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? usuarioId = null,Object? rol = null,Object? nivel = null,Object? xpActual = null,Object? xpNivelActual = null,Object? xpSiguienteNivel = freezed,Object? xpFaltante = null,Object? progreso = null,Object? descuento = null,Object? prioridadSegundos = null,Object? niveles = null,Object? beneficiosActivos = null,Object? conductor = freezed,}) {
  return _then(_NivelEstado(
usuarioId: null == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as String,rol: null == rol ? _self.rol : rol // ignore: cast_nullable_to_non_nullable
as String,nivel: null == nivel ? _self.nivel : nivel // ignore: cast_nullable_to_non_nullable
as int,xpActual: null == xpActual ? _self.xpActual : xpActual // ignore: cast_nullable_to_non_nullable
as int,xpNivelActual: null == xpNivelActual ? _self.xpNivelActual : xpNivelActual // ignore: cast_nullable_to_non_nullable
as int,xpSiguienteNivel: freezed == xpSiguienteNivel ? _self.xpSiguienteNivel : xpSiguienteNivel // ignore: cast_nullable_to_non_nullable
as int?,xpFaltante: null == xpFaltante ? _self.xpFaltante : xpFaltante // ignore: cast_nullable_to_non_nullable
as int,progreso: null == progreso ? _self.progreso : progreso // ignore: cast_nullable_to_non_nullable
as double,descuento: null == descuento ? _self.descuento : descuento // ignore: cast_nullable_to_non_nullable
as double,prioridadSegundos: null == prioridadSegundos ? _self.prioridadSegundos : prioridadSegundos // ignore: cast_nullable_to_non_nullable
as int,niveles: null == niveles ? _self._niveles : niveles // ignore: cast_nullable_to_non_nullable
as List<NivelInfo>,beneficiosActivos: null == beneficiosActivos ? _self._beneficiosActivos : beneficiosActivos // ignore: cast_nullable_to_non_nullable
as List<Beneficio>,conductor: freezed == conductor ? _self.conductor : conductor // ignore: cast_nullable_to_non_nullable
as ConductorInfo?,
  ));
}

/// Create a copy of NivelEstado
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConductorInfoCopyWith<$Res>? get conductor {
    if (_self.conductor == null) {
    return null;
  }

  return $ConductorInfoCopyWith<$Res>(_self.conductor!, (value) {
    return _then(_self.copyWith(conductor: value));
  });
}
}

// dart format on
