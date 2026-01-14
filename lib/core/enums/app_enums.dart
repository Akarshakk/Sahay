enum UserRole {
  citizen,
  volunteer,
  authority,
}

enum IncidentType {
  police,
  fire,
  medical,
  disaster,
  woman,
  child,
  elderly,
  railway,
}

enum IncidentStatus {
  pending,
  verified,
  assigned,
  inProgress,
  resolved,
  cancelled,
}

enum IncidentSeverity {
  low,
  medium,
  high,
  critical,
}

// Alias for compatibility
typedef SeverityLevel = IncidentSeverity;
