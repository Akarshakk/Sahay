import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Area resource model
class AreaResource {
  final String areaId;
  final String areaName;
  final int ambulances;
  final int firetrucks;
  final int policeUnits;
  final int volunteers;
  final int shelterCapacity;
  final DateTime lastUpdated;

  AreaResource({
    required this.areaId,
    required this.areaName,
    this.ambulances = 0,
    this.firetrucks = 0,
    this.policeUnits = 0,
    this.volunteers = 0,
    this.shelterCapacity = 0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory AreaResource.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AreaResource(
      areaId: doc.id,
      areaName: data['areaName'] ?? doc.id,
      ambulances: data['ambulances'] ?? 0,
      firetrucks: data['firetrucks'] ?? 0,
      policeUnits: data['policeUnits'] ?? 0,
      volunteers: data['volunteers'] ?? 0,
      shelterCapacity: data['shelterCapacity'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'areaName': areaName,
      'ambulances': ambulances,
      'firetrucks': firetrucks,
      'policeUnits': policeUnits,
      'volunteers': volunteers,
      'shelterCapacity': shelterCapacity,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  AreaResource copyWith({
    int? ambulances,
    int? firetrucks,
    int? policeUnits,
    int? volunteers,
    int? shelterCapacity,
  }) {
    return AreaResource(
      areaId: areaId,
      areaName: areaName,
      ambulances: ambulances ?? this.ambulances,
      firetrucks: firetrucks ?? this.firetrucks,
      policeUnits: policeUnits ?? this.policeUnits,
      volunteers: volunteers ?? this.volunteers,
      shelterCapacity: shelterCapacity ?? this.shelterCapacity,
    );
  }
}

/// Area Resources Service
class AreaResourcesService {
  final FirebaseFirestore _firestore;

  AreaResourcesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _areaResources => _firestore.collection('area_resources');

  /// Get real-time stream of resources for a specific area
  Stream<AreaResource?> getAreaResourcesStream(String areaId) {
    return _areaResources.doc(areaId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AreaResource.fromFirestore(doc);
    });
  }

  /// Get all areas resources
  Stream<List<AreaResource>> getAllAreasStream() {
    return _areaResources.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AreaResource.fromFirestore(doc)).toList();
    });
  }

  /// Update a specific resource count
  Future<void> updateResource({
    required String areaId,
    required String resourceType,
    required int newCount,
  }) async {
    await _areaResources.doc(areaId).update({
      resourceType: newCount,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Increment/decrement a resource
  Future<void> adjustResource({
    required String areaId,
    required String resourceType,
    required int delta,
  }) async {
    await _areaResources.doc(areaId).update({
      resourceType: FieldValue.increment(delta),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Initialize area resources if they don't exist
  Future<void> initializeAreaResources(String areaId, String areaName) async {
    final doc = await _areaResources.doc(areaId).get();
    if (!doc.exists) {
      await _areaResources.doc(areaId).set({
        'areaName': areaName,
        'ambulances': 0,
        'firetrucks': 0,
        'policeUnits': 0,
        'volunteers': 0,
        'shelterCapacity': 0,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }
}

/// Provider for AreaResourcesService
final areaResourcesServiceProvider = Provider<AreaResourcesService>((ref) {
  return AreaResourcesService();
});

/// Provider for real-time area resources stream
final areaResourcesStreamProvider = StreamProvider.family<AreaResource?, String>((ref, areaId) {
  final service = ref.watch(areaResourcesServiceProvider);
  return service.getAreaResourcesStream(areaId);
});

/// Provider for all areas resources
final allAreasResourcesStreamProvider = StreamProvider<List<AreaResource>>((ref) {
  final service = ref.watch(areaResourcesServiceProvider);
  return service.getAllAreasStream();
});
