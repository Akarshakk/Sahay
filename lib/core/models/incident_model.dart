import 'package:freezed_annotation/freezed_annotation.dart';
import '../enums/app_enums.dart';

part 'incident_model.freezed.dart';
part 'incident_model.g.dart';

@freezed
class IncidentModel with _$IncidentModel {
  const factory IncidentModel({
    required String id,
    required String title,
    required String description,
    @JsonKey(
      fromJson: _incidentTypeFromJson,
      toJson: _incidentTypeToJson,
    )
    required IncidentType type,
    @JsonKey(
      fromJson: _severityLevelFromJson,
      toJson: _severityLevelToJson,
    )
    required SeverityLevel severity,
    required double latitude,
    required double longitude,
    required String reportedBy,
    String? reporterName,
    String? reporterPhone,
    required DateTime reportedAt,
    required DateTime timestamp,
    @JsonKey(
      fromJson: _incidentStatusFromJson,
      toJson: _incidentStatusToJson,
    )
    required IncidentStatus status,
    required bool isSynced,
    required List<String> mediaUrls,
    required int verificationCount,
  }) = _IncidentModel;

  factory IncidentModel.fromJson(Map<String, dynamic> json) =>
      _$IncidentModelFromJson(json);
}

// JSON converters for enums
IncidentType _incidentTypeFromJson(String value) {
  return IncidentType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => IncidentType.police,
  );
}

String _incidentTypeToJson(IncidentType type) => type.name;

SeverityLevel _severityLevelFromJson(String value) {
  return SeverityLevel.values.firstWhere(
    (e) => e.name == value,
    orElse: () => SeverityLevel.medium,
  );
}

String _severityLevelToJson(SeverityLevel severity) => severity.name;

IncidentStatus _incidentStatusFromJson(String value) {
  return IncidentStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => IncidentStatus.pending,
  );
}

String _incidentStatusToJson(IncidentStatus status) => status.name;

