// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

User _$UserFromJson(Map<String, dynamic> json) {
  return _User.fromJson(json);
}

/// @nodoc
mixin _$User {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  UserRole get role => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get state => throw _privateConstructorUsedError;
  String? get district => throw _privateConstructorUsedError;
  String? get city => throw _privateConstructorUsedError;
  String? get profession => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  String? get registeredArea => throw _privateConstructorUsedError;
  String? get registeredAreaId => throw _privateConstructorUsedError;
  String? get identityDocumentUrl => throw _privateConstructorUsedError;
  String? get identityDocumentType => throw _privateConstructorUsedError;
  String? get authorityCode => throw _privateConstructorUsedError;
  String? get department => throw _privateConstructorUsedError;
  String? get registrationNumber => throw _privateConstructorUsedError;
  List<EmergencyContact>? get emergencyContacts =>
      throw _privateConstructorUsedError;
  bool get isAvailable => throw _privateConstructorUsedError;

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCopyWith<User> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCopyWith<$Res> {
  factory $UserCopyWith(User value, $Res Function(User) then) =
      _$UserCopyWithImpl<$Res, User>;
  @useResult
  $Res call(
      {String id,
      String name,
      String phone,
      UserRole role,
      String? email,
      String? state,
      String? district,
      String? city,
      String? profession,
      String? address,
      String? registeredArea,
      String? registeredAreaId,
      String? identityDocumentUrl,
      String? identityDocumentType,
      String? authorityCode,
      String? department,
      String? registrationNumber,
      List<EmergencyContact>? emergencyContacts,
      bool isAvailable});
}

/// @nodoc
class _$UserCopyWithImpl<$Res, $Val extends User>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? phone = null,
    Object? role = null,
    Object? email = freezed,
    Object? state = freezed,
    Object? district = freezed,
    Object? city = freezed,
    Object? profession = freezed,
    Object? address = freezed,
    Object? registeredArea = freezed,
    Object? registeredAreaId = freezed,
    Object? identityDocumentUrl = freezed,
    Object? identityDocumentType = freezed,
    Object? authorityCode = freezed,
    Object? department = freezed,
    Object? registrationNumber = freezed,
    Object? emergencyContacts = freezed,
    Object? isAvailable = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      state: freezed == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String?,
      district: freezed == district
          ? _value.district
          : district // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      profession: freezed == profession
          ? _value.profession
          : profession // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      registeredArea: freezed == registeredArea
          ? _value.registeredArea
          : registeredArea // ignore: cast_nullable_to_non_nullable
              as String?,
      registeredAreaId: freezed == registeredAreaId
          ? _value.registeredAreaId
          : registeredAreaId // ignore: cast_nullable_to_non_nullable
              as String?,
      identityDocumentUrl: freezed == identityDocumentUrl
          ? _value.identityDocumentUrl
          : identityDocumentUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      identityDocumentType: freezed == identityDocumentType
          ? _value.identityDocumentType
          : identityDocumentType // ignore: cast_nullable_to_non_nullable
              as String?,
      authorityCode: freezed == authorityCode
          ? _value.authorityCode
          : authorityCode // ignore: cast_nullable_to_non_nullable
              as String?,
      department: freezed == department
          ? _value.department
          : department // ignore: cast_nullable_to_non_nullable
              as String?,
      registrationNumber: freezed == registrationNumber
          ? _value.registrationNumber
          : registrationNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      emergencyContacts: freezed == emergencyContacts
          ? _value.emergencyContacts
          : emergencyContacts // ignore: cast_nullable_to_non_nullable
              as List<EmergencyContact>?,
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserImplCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$$UserImplCopyWith(
          _$UserImpl value, $Res Function(_$UserImpl) then) =
      __$$UserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String phone,
      UserRole role,
      String? email,
      String? state,
      String? district,
      String? city,
      String? profession,
      String? address,
      String? registeredArea,
      String? registeredAreaId,
      String? identityDocumentUrl,
      String? identityDocumentType,
      String? authorityCode,
      String? department,
      String? registrationNumber,
      List<EmergencyContact>? emergencyContacts,
      bool isAvailable});
}

/// @nodoc
class __$$UserImplCopyWithImpl<$Res>
    extends _$UserCopyWithImpl<$Res, _$UserImpl>
    implements _$$UserImplCopyWith<$Res> {
  __$$UserImplCopyWithImpl(_$UserImpl _value, $Res Function(_$UserImpl) _then)
      : super(_value, _then);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? phone = null,
    Object? role = null,
    Object? email = freezed,
    Object? state = freezed,
    Object? district = freezed,
    Object? city = freezed,
    Object? profession = freezed,
    Object? address = freezed,
    Object? registeredArea = freezed,
    Object? registeredAreaId = freezed,
    Object? identityDocumentUrl = freezed,
    Object? identityDocumentType = freezed,
    Object? authorityCode = freezed,
    Object? department = freezed,
    Object? registrationNumber = freezed,
    Object? emergencyContacts = freezed,
    Object? isAvailable = null,
  }) {
    return _then(_$UserImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      state: freezed == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String?,
      district: freezed == district
          ? _value.district
          : district // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      profession: freezed == profession
          ? _value.profession
          : profession // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      registeredArea: freezed == registeredArea
          ? _value.registeredArea
          : registeredArea // ignore: cast_nullable_to_non_nullable
              as String?,
      registeredAreaId: freezed == registeredAreaId
          ? _value.registeredAreaId
          : registeredAreaId // ignore: cast_nullable_to_non_nullable
              as String?,
      identityDocumentUrl: freezed == identityDocumentUrl
          ? _value.identityDocumentUrl
          : identityDocumentUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      identityDocumentType: freezed == identityDocumentType
          ? _value.identityDocumentType
          : identityDocumentType // ignore: cast_nullable_to_non_nullable
              as String?,
      authorityCode: freezed == authorityCode
          ? _value.authorityCode
          : authorityCode // ignore: cast_nullable_to_non_nullable
              as String?,
      department: freezed == department
          ? _value.department
          : department // ignore: cast_nullable_to_non_nullable
              as String?,
      registrationNumber: freezed == registrationNumber
          ? _value.registrationNumber
          : registrationNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      emergencyContacts: freezed == emergencyContacts
          ? _value._emergencyContacts
          : emergencyContacts // ignore: cast_nullable_to_non_nullable
              as List<EmergencyContact>?,
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserImpl implements _User {
  const _$UserImpl(
      {required this.id,
      required this.name,
      required this.phone,
      required this.role,
      this.email,
      this.state,
      this.district,
      this.city,
      this.profession,
      this.address,
      this.registeredArea,
      this.registeredAreaId,
      this.identityDocumentUrl,
      this.identityDocumentType,
      this.authorityCode,
      this.department,
      this.registrationNumber,
      final List<EmergencyContact>? emergencyContacts,
      this.isAvailable = true})
      : _emergencyContacts = emergencyContacts;

  factory _$UserImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String phone;
  @override
  final UserRole role;
  @override
  final String? email;
  @override
  final String? state;
  @override
  final String? district;
  @override
  final String? city;
  @override
  final String? profession;
  @override
  final String? address;
  @override
  final String? registeredArea;
  @override
  final String? registeredAreaId;
  @override
  final String? identityDocumentUrl;
  @override
  final String? identityDocumentType;
  @override
  final String? authorityCode;
  @override
  final String? department;
  @override
  final String? registrationNumber;
  final List<EmergencyContact>? _emergencyContacts;
  @override
  List<EmergencyContact>? get emergencyContacts {
    final value = _emergencyContacts;
    if (value == null) return null;
    if (_emergencyContacts is EqualUnmodifiableListView)
      return _emergencyContacts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final bool isAvailable;

  @override
  String toString() {
    return 'User(id: $id, name: $name, phone: $phone, role: $role, email: $email, state: $state, district: $district, city: $city, profession: $profession, address: $address, registeredArea: $registeredArea, registeredAreaId: $registeredAreaId, identityDocumentUrl: $identityDocumentUrl, identityDocumentType: $identityDocumentType, authorityCode: $authorityCode, department: $department, registrationNumber: $registrationNumber, emergencyContacts: $emergencyContacts, isAvailable: $isAvailable)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.district, district) ||
                other.district == district) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.profession, profession) ||
                other.profession == profession) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.registeredArea, registeredArea) ||
                other.registeredArea == registeredArea) &&
            (identical(other.registeredAreaId, registeredAreaId) ||
                other.registeredAreaId == registeredAreaId) &&
            (identical(other.identityDocumentUrl, identityDocumentUrl) ||
                other.identityDocumentUrl == identityDocumentUrl) &&
            (identical(other.identityDocumentType, identityDocumentType) ||
                other.identityDocumentType == identityDocumentType) &&
            (identical(other.authorityCode, authorityCode) ||
                other.authorityCode == authorityCode) &&
            (identical(other.department, department) ||
                other.department == department) &&
            (identical(other.registrationNumber, registrationNumber) ||
                other.registrationNumber == registrationNumber) &&
            const DeepCollectionEquality()
                .equals(other._emergencyContacts, _emergencyContacts) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        phone,
        role,
        email,
        state,
        district,
        city,
        profession,
        address,
        registeredArea,
        registeredAreaId,
        identityDocumentUrl,
        identityDocumentType,
        authorityCode,
        department,
        registrationNumber,
        const DeepCollectionEquality().hash(_emergencyContacts),
        isAvailable
      ]);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      __$$UserImplCopyWithImpl<_$UserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserImplToJson(
      this,
    );
  }
}

abstract class _User implements User {
  const factory _User(
      {required final String id,
      required final String name,
      required final String phone,
      required final UserRole role,
      final String? email,
      final String? state,
      final String? district,
      final String? city,
      final String? profession,
      final String? address,
      final String? registeredArea,
      final String? registeredAreaId,
      final String? identityDocumentUrl,
      final String? identityDocumentType,
      final String? authorityCode,
      final String? department,
      final String? registrationNumber,
      final List<EmergencyContact>? emergencyContacts,
      final bool isAvailable}) = _$UserImpl;

  factory _User.fromJson(Map<String, dynamic> json) = _$UserImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get phone;
  @override
  UserRole get role;
  @override
  String? get email;
  @override
  String? get state;
  @override
  String? get district;
  @override
  String? get city;
  @override
  String? get profession;
  @override
  String? get address;
  @override
  String? get registeredArea;
  @override
  String? get registeredAreaId;
  @override
  String? get identityDocumentUrl;
  @override
  String? get identityDocumentType;
  @override
  String? get authorityCode;
  @override
  String? get department;
  @override
  String? get registrationNumber;
  @override
  List<EmergencyContact>? get emergencyContacts;
  @override
  bool get isAvailable;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EmergencyContact _$EmergencyContactFromJson(Map<String, dynamic> json) {
  return _EmergencyContact.fromJson(json);
}

/// @nodoc
mixin _$EmergencyContact {
  String get name => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String get relation => throw _privateConstructorUsedError;

  /// Serializes this EmergencyContact to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EmergencyContact
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EmergencyContactCopyWith<EmergencyContact> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EmergencyContactCopyWith<$Res> {
  factory $EmergencyContactCopyWith(
          EmergencyContact value, $Res Function(EmergencyContact) then) =
      _$EmergencyContactCopyWithImpl<$Res, EmergencyContact>;
  @useResult
  $Res call({String name, String phone, String relation});
}

/// @nodoc
class _$EmergencyContactCopyWithImpl<$Res, $Val extends EmergencyContact>
    implements $EmergencyContactCopyWith<$Res> {
  _$EmergencyContactCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EmergencyContact
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? phone = null,
    Object? relation = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      relation: null == relation
          ? _value.relation
          : relation // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EmergencyContactImplCopyWith<$Res>
    implements $EmergencyContactCopyWith<$Res> {
  factory _$$EmergencyContactImplCopyWith(_$EmergencyContactImpl value,
          $Res Function(_$EmergencyContactImpl) then) =
      __$$EmergencyContactImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, String phone, String relation});
}

/// @nodoc
class __$$EmergencyContactImplCopyWithImpl<$Res>
    extends _$EmergencyContactCopyWithImpl<$Res, _$EmergencyContactImpl>
    implements _$$EmergencyContactImplCopyWith<$Res> {
  __$$EmergencyContactImplCopyWithImpl(_$EmergencyContactImpl _value,
      $Res Function(_$EmergencyContactImpl) _then)
      : super(_value, _then);

  /// Create a copy of EmergencyContact
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? phone = null,
    Object? relation = null,
  }) {
    return _then(_$EmergencyContactImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      relation: null == relation
          ? _value.relation
          : relation // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EmergencyContactImpl implements _EmergencyContact {
  const _$EmergencyContactImpl(
      {required this.name, required this.phone, required this.relation});

  factory _$EmergencyContactImpl.fromJson(Map<String, dynamic> json) =>
      _$$EmergencyContactImplFromJson(json);

  @override
  final String name;
  @override
  final String phone;
  @override
  final String relation;

  @override
  String toString() {
    return 'EmergencyContact(name: $name, phone: $phone, relation: $relation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EmergencyContactImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.relation, relation) ||
                other.relation == relation));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, phone, relation);

  /// Create a copy of EmergencyContact
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EmergencyContactImplCopyWith<_$EmergencyContactImpl> get copyWith =>
      __$$EmergencyContactImplCopyWithImpl<_$EmergencyContactImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EmergencyContactImplToJson(
      this,
    );
  }
}

abstract class _EmergencyContact implements EmergencyContact {
  const factory _EmergencyContact(
      {required final String name,
      required final String phone,
      required final String relation}) = _$EmergencyContactImpl;

  factory _EmergencyContact.fromJson(Map<String, dynamic> json) =
      _$EmergencyContactImpl.fromJson;

  @override
  String get name;
  @override
  String get phone;
  @override
  String get relation;

  /// Create a copy of EmergencyContact
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EmergencyContactImplCopyWith<_$EmergencyContactImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
