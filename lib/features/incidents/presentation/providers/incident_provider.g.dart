// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incident_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$incidentRepositoryHash() =>
    r'2c27fb692089dbaca2f3cc6ce9c19db340080e3f';

/// Repository Provider
///
/// Copied from [incidentRepository].
@ProviderFor(incidentRepository)
final incidentRepositoryProvider =
    AutoDisposeProvider<IIncidentRepository>.internal(
  incidentRepository,
  name: r'incidentRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$incidentRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IncidentRepositoryRef = AutoDisposeProviderRef<IIncidentRepository>;
String _$incidentListHash() => r'707186c7cb412f9f5a606861ee41958c37b38be6';

/// Incident List Provider
///
/// Copied from [IncidentList].
@ProviderFor(IncidentList)
final incidentListProvider = AutoDisposeAsyncNotifierProvider<IncidentList,
    List<IncidentModel>>.internal(
  IncidentList.new,
  name: r'incidentListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$incidentListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$IncidentList = AutoDisposeAsyncNotifier<List<IncidentModel>>;
String _$pendingIncidentListHash() =>
    r'44db64e0dec680a8539bdfa743be6d090368faef';

/// Pending Incidents Provider (for Volunteer Feed)
///
/// Copied from [PendingIncidentList].
@ProviderFor(PendingIncidentList)
final pendingIncidentListProvider = AutoDisposeAsyncNotifierProvider<
    PendingIncidentList, List<IncidentModel>>.internal(
  PendingIncidentList.new,
  name: r'pendingIncidentListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingIncidentListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PendingIncidentList = AutoDisposeAsyncNotifier<List<IncidentModel>>;
String _$incidentControllerHash() =>
    r'6ad6120f18dd5a1618ddfb73ec37374707724daf';

/// Incident Controller for Actions
///
/// Copied from [IncidentController].
@ProviderFor(IncidentController)
final incidentControllerProvider =
    AutoDisposeAsyncNotifierProvider<IncidentController, void>.internal(
  IncidentController.new,
  name: r'incidentControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$incidentControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$IncidentController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
