import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

/// Mutable Resource item model
class ResourceItem {
  final String id;
  final String name;
  final String category;
  int quantity;  // Made mutable
  final String location;
  bool available;  // Made mutable
  final IconData icon;

  ResourceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.location,
    required this.available,
    required this.icon,
  });
}

/// Resources Screen - Volunteer can view and manage resources
class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  final List<ResourceItem> _resources = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadResources();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 800));
    
    setState(() {
      _resources.addAll([
        ResourceItem(
          id: '1',
          name: 'First Aid Kits',
          category: 'Medical',
          quantity: 50,
          location: 'Warehouse A',
          available: true,
          icon: Icons.medical_services,
        ),
        ResourceItem(
          id: '2',
          name: 'Bottled Water (Cases)',
          category: 'Supplies',
          quantity: 200,
          location: 'Warehouse B',
          available: true,
          icon: Icons.water_drop,
        ),
        ResourceItem(
          id: '3',
          name: 'Emergency Blankets',
          category: 'Supplies',
          quantity: 100,
          location: 'Warehouse A',
          available: true,
          icon: Icons.bed,
        ),
        ResourceItem(
          id: '4',
          name: 'Flashlights',
          category: 'Equipment',
          quantity: 75,
          location: 'Warehouse C',
          available: true,
          icon: Icons.flashlight_on,
        ),
        ResourceItem(
          id: '5',
          name: 'Portable Radios',
          category: 'Equipment',
          quantity: 25,
          location: 'Warehouse A',
          available: false,
          icon: Icons.radio,
        ),
        ResourceItem(
          id: '6',
          name: 'Stretchers',
          category: 'Medical',
          quantity: 10,
          location: 'Warehouse A',
          available: true,
          icon: Icons.airline_seat_flat,
        ),
        ResourceItem(
          id: '7',
          name: 'Fire Extinguishers',
          category: 'Equipment',
          quantity: 30,
          location: 'Warehouse D',
          available: true,
          icon: Icons.fire_extinguisher,
        ),
        ResourceItem(
          id: '8',
          name: 'Food Rations',
          category: 'Supplies',
          quantity: 500,
          location: 'Warehouse B',
          available: true,
          icon: Icons.fastfood,
        ),
      ]);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.neutralGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Emergency Resources',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.neutralGray),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Medical'),
            Tab(text: 'Equipment'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatsBar(),
          Expanded(
            child: _isLoading
                ? _buildLoadingSkeleton()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildResourceList(null),
                      _buildResourceList('Medical'),
                      _buildResourceList('Equipment'),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRequestDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Request'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildStatsBar() {
    final available = _resources.where((r) => r.available).length;
    final total = _resources.length;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withOpacity(0.2),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('$available', 'Available', AppTheme.primaryGreen),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _buildStatColumn('${total - available}', 'In Use', AppTheme.primaryOrange),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _buildStatColumn('$total', 'Total', AppTheme.textDark),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1200.ms, color: Colors.white24);
      },
    );
  }

  Widget _buildResourceList(String? category) {
    final filtered = category == null
        ? _resources
        : _resources.where((r) => r.category == category).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No resources in this category',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildResourceCard(filtered[index], index);
      },
    );
  }

  Widget _buildResourceCard(ResourceItem resource, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: resource.available ? Colors.grey.shade200 : Colors.red.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (resource.available ? AppTheme.primaryGreen : Colors.red)
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                resource.icon,
                color: resource.available ? AppTheme.primaryGreen : Colors.red,
              ),
            ),
            title: Text(
              resource.name,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      resource.location,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: resource.available
                        ? AppTheme.primaryGreen.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    resource.available ? 'Available' : 'Out of Stock',
                    style: TextStyle(
                      color: resource.available ? AppTheme.primaryGreen : Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
              onPressed: () => _showResourceDetails(resource),
            ),
          ),
          // Quantity Controls
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stock: ${resource.quantity} units',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                Row(
                  children: [
                    // Decrease Button
                    GestureDetector(
                      onTap: () => _updateQuantity(resource, -1),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.remove, color: Colors.red, size: 20),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${resource.quantity}',
                        style: const TextStyle(
                          color: AppTheme.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Increase Button
                    GestureDetector(
                      onTap: () => _updateQuantity(resource, 1),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.add, color: AppTheme.primaryGreen, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }

  void _updateQuantity(ResourceItem resource, int change) {
    setState(() {
      resource.quantity += change;
      if (resource.quantity < 0) resource.quantity = 0;
      resource.available = resource.quantity > 0;
    });
    
    // Show feedback
    final message = change > 0 
        ? 'Added 1 ${resource.name}' 
        : 'Used 1 ${resource.name}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: change > 0 ? AppTheme.primaryGreen : Colors.orange,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showResourceDetails(ResourceItem resource) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(resource.icon, color: AppTheme.primaryGreen, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.name,
                        style: const TextStyle(
                          color: AppTheme.textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        resource.category,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(Icons.inventory_2, 'Quantity', '${resource.quantity} units'),
            _buildDetailRow(Icons.location_on, 'Location', resource.location),
            _buildDetailRow(
              Icons.check_circle,
              'Status',
              resource.available ? 'Available' : 'Currently in use',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: resource.available ? () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Resource request submitted!'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Request This Resource'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Request Resources', style: TextStyle(color: AppTheme.textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Resource name',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Quantity needed',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: AppTheme.textDark),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Request submitted!'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
