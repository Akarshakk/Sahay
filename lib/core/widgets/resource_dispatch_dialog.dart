import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/sos_notification_provider.dart';

/// Resource selection item for dispatch
class ResourceSelection {
  final String id;
  final String name;
  final String category;
  final IconData icon;
  int quantity;
  bool selected;

  ResourceSelection({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    this.quantity = 1,
    this.selected = false,
  });

  DispatchedResource toDispatchedResource() {
    return DispatchedResource(
      resourceId: id,
      resourceName: name,
      quantity: quantity,
      category: category,
    );
  }
}

/// Resource Dispatch Dialog for authorities
/// Allows selecting resources with quantities before dispatching
class ResourceDispatchDialog extends StatefulWidget {
  final String sosId;
  final String citizenName;
  final Function(List<DispatchedResource>) onDispatch;
  final VoidCallback onCancel;

  const ResourceDispatchDialog({
    super.key,
    required this.sosId,
    required this.citizenName,
    required this.onDispatch,
    required this.onCancel,
  });

  @override
  State<ResourceDispatchDialog> createState() => _ResourceDispatchDialogState();
}

class _ResourceDispatchDialogState extends State<ResourceDispatchDialog> {
  final List<ResourceSelection> _resources = [
    ResourceSelection(
      id: 'police_patrol',
      name: 'Police Patrol',
      category: 'Police',
      icon: Icons.local_police,
    ),
    ResourceSelection(
      id: 'ambulance',
      name: 'Ambulance',
      category: 'Medical',
      icon: Icons.local_hospital,
    ),
    ResourceSelection(
      id: 'fire_truck',
      name: 'Fire Truck',
      category: 'Fire',
      icon: Icons.fire_truck,
    ),
    ResourceSelection(
      id: 'first_aid',
      name: 'First Aid Team',
      category: 'Medical',
      icon: Icons.medical_services,
    ),
    ResourceSelection(
      id: 'rescue_team',
      name: 'Rescue Team',
      category: 'Rescue',
      icon: Icons.person_search,
    ),
    ResourceSelection(
      id: 'traffic_control',
      name: 'Traffic Control',
      category: 'Police',
      icon: Icons.traffic,
    ),
  ];

  bool _isDispatching = false;

  List<ResourceSelection> get selectedResources =>
      _resources.where((r) => r.selected).toList();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select resources to dispatch:',
                      style: TextStyle(
                        color: AppTheme.getTextColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._buildResourceList(context),
                  ],
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.1, end: 0, duration: 300.ms).fadeIn();
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.citizenAccent.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.citizenAccent.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.citizenAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_shipping,
              color: AppTheme.citizenAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dispatch Resources',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'For: ${widget.citizenName}',
                  style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppTheme.getSecondaryTextColor(context)),
            onPressed: widget.onCancel,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResourceList(BuildContext context) {
    return _resources.map((resource) {
      final index = _resources.indexOf(resource);
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: resource.selected
              ? AppTheme.primaryGreen.withOpacity(0.1)
              : AppTheme.isDarkMode(context)
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: resource.selected
                ? AppTheme.primaryGreen
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              resource.selected = !resource.selected;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(resource.category).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    resource.icon,
                    color: _getCategoryColor(resource.category),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.name,
                        style: TextStyle(
                          color: AppTheme.getTextColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        resource.category,
                        style: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (resource.selected) ...[
                  _buildQuantityControl(resource),
                  const SizedBox(width: 8),
                ],
                Checkbox(
                  value: resource.selected,
                  onChanged: (value) {
                    setState(() {
                      resource.selected = value ?? false;
                    });
                  },
                  activeColor: AppTheme.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
    }).toList();
  }

  Widget _buildQuantityControl(ResourceSelection resource) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.isDarkMode(context)
            ? Colors.white.withOpacity(0.1)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              if (resource.quantity > 1) {
                setState(() {
                  resource.quantity--;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.remove,
                size: 16,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${resource.quantity}',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              if (resource.quantity < 10) {
                setState(() {
                  resource.quantity++;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.add,
                size: 16,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Police':
        return AppTheme.citizenAccent;
      case 'Medical':
        return AppTheme.primaryGreen;
      case 'Fire':
        return AppTheme.primaryRed;
      case 'Rescue':
        return AppTheme.primaryOrange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFooter(BuildContext context) {
    final hasSelectedResources = selectedResources.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.isDarkMode(context)
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        children: [
          if (hasSelectedResources) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${selectedResources.length} resource(s) selected',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: hasSelectedResources && !_isDispatching
                      ? () {
                          setState(() => _isDispatching = true);
                          final resources = selectedResources
                              .map((r) => r.toDispatchedResource())
                              .toList();
                          widget.onDispatch(resources);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isDispatching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Dispatch Now',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
