import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/incident_model.dart';
import '../../../../core/services/location_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/incident_provider.dart';

/// Modern Incident Reporting Form with Offline-First Architecture
/// - Captures location automatically
/// - Stores locally when offline
/// - Syncs when network is restored
/// - Shows deduplication warnings
class IncidentReportFormScreen extends ConsumerStatefulWidget {
  final IncidentType incidentType;

  const IncidentReportFormScreen({
    super.key,
    required this.incidentType,
  });

  @override
  ConsumerState<IncidentReportFormScreen> createState() => _IncidentReportFormScreenState();
}

class _IncidentReportFormScreenState extends ConsumerState<IncidentReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  
  LocationData? _currentLocation;
  String _address = 'Detecting location...';
  bool _isLoadingLocation = true;
  bool _isOffline = false;
  bool _isDuplicateWarning = false;
  
  IncidentSeverity _selectedSeverity = IncidentSeverity.medium;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _getCurrentLocation();
  }

  Future<void> _checkConnectivity() async {
    // Web always has connectivity for demo purposes
    setState(() {
      _isOffline = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentLocation();
      
      if (position != null) {
        final address = await locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        setState(() {
          _currentLocation = LocationData(
            latitude: position.latitude,
            longitude: position.longitude,
            address: address,
          );
          _address = address;
          _isLoadingLocation = false;
        });
        
        // Check for duplicates after getting location
        _checkForDuplicates();
      } else {
        setState(() {
          _address = 'Location permission denied';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Unable to detect location';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _checkForDuplicates() async {
    if (_currentLocation == null) return;

    try {
      final duplicateCheck = await ref
          .read(incidentControllerProvider.notifier)
          .checkDuplicate(_currentLocation!.latitude, _currentLocation!.longitude);

      if (duplicateCheck.isSuccess && duplicateCheck.data != null) {
        setState(() {
          _isDuplicateWarning = true;
        });
      }
    } catch (e) {
      // Silently fail - duplicate check is optional
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('Report ${widget.incidentType.name.toUpperCase()}'),
        actions: [
          if (_isOffline)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: const Text('Offline', style: TextStyle(fontSize: 12)),
                backgroundColor: AppTheme.primaryOrange.withOpacity(0.2),
                avatar: const Icon(Icons.cloud_off, size: 16),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isDuplicateWarning) _buildDuplicateWarning(),
            const SizedBox(height: 16),
            _buildIncidentTypeCard(),
            const SizedBox(height: 24),
            _buildLocationCard(),
            const SizedBox(height: 24),
            _buildSeveritySelector(),
            const SizedBox(height: 24),
            _buildDescriptionField(),
            const SizedBox(height: 24),
            _buildMediaUpload(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
            const SizedBox(height: 16),
            if (_isOffline) _buildOfflineMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildDuplicateWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.primaryOrange),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '⚠️ Emergency already reported nearby!\nHelp is on the way. Submit only if this is a different incident.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentTypeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getIncidentColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIncidentIcon(),
              color: _getIncidentColor(),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.incidentType.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutralGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Emergency Response',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              const Text(
                'Incident Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingLocation)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Detecting your location...'),
              ],
            )
          else
            Text(
              _address,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          if (_currentLocation != null) ...[
            const SizedBox(height: 8),
            Text(
              'Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}, Lon: ${_currentLocation!.longitude.toStringAsFixed(6)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeveritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Incident Severity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSeverityChip(IncidentSeverity.low, 'Low', AppTheme.primaryGreen),
            const SizedBox(width: 8),
            _buildSeverityChip(IncidentSeverity.medium, 'Medium', AppTheme.primaryOrange),
            const SizedBox(width: 8),
            _buildSeverityChip(IncidentSeverity.high, 'High', AppTheme.primaryRed),
            const SizedBox(width: 8),
            _buildSeverityChip(IncidentSeverity.critical, 'Critical', const Color(0xFF7B1FA2)),
          ],
        ),
      ],
    );
  }

  Widget _buildSeverityChip(IncidentSeverity severity, String label, Color color) {
    final isSelected = _selectedSeverity == severity;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSeverity = severity;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Describe the Situation',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Briefly describe the emergency situation...',
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please describe the situation';
            }
            if (value.trim().length < 10) {
              return 'Please provide more details (at least 10 characters)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMediaUpload() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Add Photos/Videos (Optional)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Implement media picker
            },
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Upload Media'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
        ),
        child: Text(
          _isOffline ? 'Save Locally (Will Sync Later)' : 'Submit Report',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.primaryOrange, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'No internet connection. Your report will be saved and automatically synced when online.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waiting for location...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final user = ref.read(authControllerProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to submit a report'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Map IncidentSeverity to SeverityLevel
    SeverityLevel severity;
    switch (_selectedSeverity) {
      case IncidentSeverity.low:
        severity = SeverityLevel.low;
        break;
      case IncidentSeverity.medium:
        severity = SeverityLevel.medium;
        break;
      case IncidentSeverity.high:
        severity = SeverityLevel.high;
        break;
      case IncidentSeverity.critical:
        severity = SeverityLevel.critical;
        break;
    }

    // Create incident
    final now = DateTime.now();
    final incident = IncidentModel(
      id: 'incident-${now.millisecondsSinceEpoch}',
      title: '${widget.incidentType.name.toUpperCase()} Incident',
      description: _descriptionController.text.trim(),
      type: widget.incidentType,
      severity: severity,
      latitude: _currentLocation!.latitude,
      longitude: _currentLocation!.longitude,
      reportedBy: user.phone,
      reportedAt: now,
      timestamp: now,
      status: IncidentStatus.pending,
      isSynced: false,
      mediaUrls: const [],
      verificationCount: 0,
    );

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Submitting report...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Submit report
    final result = await ref
        .read(incidentControllerProvider.notifier)
        .submitReport(incident: incident);

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Report submitted successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else if (result.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📡 No connection - Report queued for sync'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${result.error ?? "Failed to submit report"}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  IconData _getIncidentIcon() {
    switch (widget.incidentType) {
      case IncidentType.police:
        return Icons.local_police;
      case IncidentType.fire:
        return Icons.local_fire_department;
      case IncidentType.medical:
        return Icons.medical_services;
      case IncidentType.disaster:
        return Icons.warning;
      case IncidentType.woman:
        return Icons.woman;
      case IncidentType.child:
        return Icons.child_care;
      case IncidentType.elderly:
        return Icons.elderly;
      case IncidentType.railway:
        return Icons.train;
    }
  }

  Color _getIncidentColor() {
    switch (widget.incidentType) {
      case IncidentType.police:
        return const Color(0xFF1565C0);
      case IncidentType.fire:
        return const Color(0xFFD32F2F);
      case IncidentType.medical:
        return const Color(0xFFE53935);
      case IncidentType.disaster:
        return const Color(0xFFFF6F00);
      case IncidentType.woman:
        return const Color(0xFF8E24AA);
      case IncidentType.child:
        return const Color(0xFF00897B);
      case IncidentType.elderly:
        return const Color(0xFF6D4C41);
      case IncidentType.railway:
        return const Color(0xFF5E35B1);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
