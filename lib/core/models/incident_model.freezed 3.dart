// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'incident_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

IncidentModel _$IncidentModelFromJson(Map<String, dynamic> json) {
  return _IncidentModel.fromJson(json);
}

/// @nodoc
mixin _$IncidentModel {
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _incidentTypeFromJson, toJson: _incidentTypeToJson)
  IncidentType get type => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _severityLevelFromJson, toJson: _severityLevelToJson)
  IncidentSeverity get severity => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  String get reportedBy => throw _privateConstructorUsedError;
  DateTime get reportedAt => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _incidentStatusFromJson, toJson: _incidentStatusToJson)
  IncidentStatus get status => throw _privateConstructorUsedError;
  bool get isSynced => throw _privateConstructorUsedError;
  List<String> get mediaUrls => throw _privateConstructorUsedError;
  int get verificationCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $IncidentModelCopyWith<IncidentModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IncidentModelCopyWith<$Res> {
  factory $IncidentModelCopyWith(
          IncidentModel value, $Res Function(IncidentModel) then) =
      _$IncidentModelCopyWithImpl<$Res, IncidentModel>;
  @useResult
  $Res call(
      {String title,
      String description,
      @JsonKey(fromJson: _incidentTypeFromJson, toJson: _incidentTypeToJson)
      IncidentType type,
      @JsonKey(fromJson: _severityLevelFromJson, toJson: _severityLevelToJson)
      IncidentSeverity severity,
      double latitude,
      double longitude,
      String reportedBy,
      DateTime reportedAt,
      @JsonKey(fromJson: _incidentStatusFromJson, toJson: _incidentStatusToJson)
      IncidentStatus status,
      bool isSynced,
      List<String> mediaUrls,
      int verificationCount});
}

/// @nodoc
class _$IncidentModelCopyWithImpl<$Res, $Val extends IncidentModel>
    implements $IncidentModelCopyWith<$Res> {
  _$IncidentModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? description = null,
    Object? type = null,
    Object? severity = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? reportedBy = null,
    Object? reportedAt = null,
    Object? status = null,
    Object? isSynced = null,
    Object? mediaUrls = null,
    Object? verificationCount = null,
  }) {
    return _then(_value.copyWith(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as IncidentType,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as IncidentSeverity,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      reportedBy: null == reportedBy
          ? _value.reportedBy
          : reportedBy // ignore: cast_nullable_to_non_nullable
              as String,
      reportedAt: null == reportedAt
          ? _value.reportedAt
          : reportedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as IncidentStatus,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      mediaUrls: null == mediaUrls
          ? _value.mediaUrls
          : mediaUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      verificationCount: null == verificationCount
          ? _value.verificationCount
          : verificationCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$IncidentModelImplCopyWith<$Res>
    implements $IncidentModelCopyWith<$Res> {
  factory _$$IncidentModelImplCopyWith(
          _$IncidentModelImpl value, $Res Function(_$IncidentModelImpl) then) =
      __$$IncidentModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String title,
      String description,
      @JsonKey(fromJson: _incidentTypeFromJson, toJson: _incidentTypeToJson)
      IncidentType type,
      @JsonKey(fromJson: _severityLevelFromJson, toJson: _severityLevelToJson)
      IncidentSeverity severity,
      double latitude,
      double longitude,
      String reportedBy,
      DateTime reportedAt,
      @JsonKey(fromJson: _incidentStatusFromJson, toJson: _incidentStatusToJson)
      IncidentStatus status,
      bool isSynced,
      List<String> mediaUrls,
      int verificationCount});
}

/// @nodoc
class __$$IncidentModelImplCopyWithImpl<$Res>
    extends _$IncidentModelCopyWithImpl<$Res, _$IncidentModelImpl>
    implements _$$IncidentModelImplCopyWith<$Res> {
  __$$IncidentModelImplCopyWithImpl(
      _$IncidentModelImpl _value, $Res Function(_$IncidentModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? description = null,
    Object? type = null,
    Object? severity = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? reportedBy = null,
    Object? reportedAt = null,
    Object? status = null,
    Object? isSynced = null,
    Object? mediaUrls = null,
    Object? verificationCount = null,
  }) {
    return _then(_$IncidentModelImpl(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as IncidentType,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as IncidentSeverity,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      reportedBy: null == reportedBy
          ? _value.reportedBy
          : reportedBy // ignore: cast_nullable_to_non_nullable
              as String,
      reportedAt: null == reportedAt
          ? _value.reportedAt
          : reportedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as IncidentStatus,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      mediaUrls: null == mediaUrls
          ? _value._mediaUrls
          : mediaUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      verificationCount: null == verificationCount
          ? _value.verificationCount
          : verificationCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IncidentModelImpl implements _IncidentModel {
  const _$IncidentModelImpl(
      {required this.title,
      required this.description,
      @JsonKey(fromJson: _incidentTypeFromJson, toJson: _incidentTypeToJson)
      required this.type,
      @JsonKey(fromJson: _severityLevelFromJson, toJson: _severityLevelToJson)
      required this.severity,
      required this.latitude,
      required this.longitude,
      required this.reportedBy,
      required this.reportedAt,
      @JsonKey(fromJson: _incidentStatusFromJson, toJson: _incidentStatusToJson)
      required this.status,
      required this.isSynced,
      required final List<String> mediaUrls,
      required this.verificationCount})
      : _mediaUrls = mediaUrls;

  factory _$IncidentModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$IncidentModelImplFromJson(json);

  @override
  final String title;
  @override
  final String description;
  @override
  @JsonKey(fromJson: _incidentTypeFromJson, toJson: _incidentTypeToJson)
  final IncidentType type;
  @override
  @JsonKey(fromJson: _severityLevelFromJson, toJson: _severityLevelToJson)
  final IncidentSeverity severity;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String reportedBy;
  @override
  final DateTime reportedAt;
  @override
  @JsonKey(fromJson: _incidentStatusFromJson, toJson: _incidentStatusToJson)
  final IncidentStatus status;
  @override
  final bool isSynced;
  final List<String> _mediaUrls;
  @override
  List<String> get mediaUrls {
    if (_mediaUrls is EqualUnmodifiableListView) return _mediaUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mediaUrls);
  }

  @override
  final int verificationCount;

  @override
  String toString() {
    return 'IncidentModel(title: $title, description: $description, type: $type, severity: $severity, latitude: $latitude, longitude: $longitude, reportedBy: $reportedBy, reportedAt: $reportedAt, status: $status, isSynced: $isSynced, mediaUrls: $mediaUrls, verificationCount: $verificationCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IncidentModelImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.reportedBy, reportedBy) ||
                other.reportedBy == reportedBy) &&
            (identical(other.reportedAt, reportedAt) ||
                other.reportedAt == reportedAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced) &&
            const DeepCollectionEquality()
                .equals(other._mediaUrls, _mediaUrls) &&
            (identical(other.verificationCount, verificationCount) ||
                other.verificationCount == verificationCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      title,
      description,
      type,
      severity,
      latitude,
      longitude,
      reportedBy,
      reportedAt,
      status,
      isSynced,
      const DeepCollectionEquality().hash(_mediaUrls),
      verificationCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$IncidentModelImplCopyWith<_$IncidentModelImpl> get copyWith =>
      __$$IncidentModelImplCopyWithImpl<_$IncidentModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IncidentModelImplToJson(
      this,
    );
  }
}

abstract class _IncidentModel implements IncidentModel {
  const factory _IncidentModel(
      {required final String title,
      required final String description,
      @JsonKey(fromJson: _incidentTypeFromJson, toJson: _incidentTypeToJson)
      required final IncidentType type,
      @JsonKey(fromJson: _severityLevelFromJson, toJson: _severityLevelToJson)
      required final IncidentSeverity severity,
      required final double latitude,
      required final double longitude,
      required final String reportedBy,
      required final DateTime reportedAt,
      @JsonKey(fromJson: _incidentStatusFromJson, toJson: _incidentStatusToJson)
      required final IncidentStatus status,
      required final bool isSynced,
      required final List<String> mediaUrls,
      required final int verificationCount}) = _$IncidentModelImpl;

  factory _IncidentModel.fromJson(Map<String, dynamic> json) =
      _$IncidentModelImpl.fromJson;

  @override
  String get title;
  @override
  String get description;
  @override
  @JsonKey(fromJson: _incidentTypeFromJson, toJson: _incidentTypeToJson)
  IncidentType get type;
  @override
  @JsonKey(fromJson: _severityLevelFromJson, toJson: _severityLevelToJson)
  IncidentSeverity get severity;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  String get reportedBy;
  @override
  DateTime get reportedAt;
  @override
  @JsonKey(fromJson: _incidentStatusFromJson, toJson: _incidentStatusToJson)
  IncidentStatus get status;
  @override
  bool get isSynced;
  @override
  List<String> get mediaUrls;
  @override
  int get verificationCount;
  @override
  @JsonKey(ignore: true)
  _$$IncidentModelImplCopyWith<_$IncidentModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
