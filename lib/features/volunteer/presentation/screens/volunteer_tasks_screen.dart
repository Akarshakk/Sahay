import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

/// Task model for volunteers
class VolunteerTask {
  final String id;
  final String title;
  final String description;
  final String location;
  final String type;
  final String urgency;
  final DateTime assignedAt;
  final DateTime? completedAt;
  final String status; // pending, in_progress, completed

  VolunteerTask({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.type,
    required this.urgency,
    required this.assignedAt,
    this.completedAt,
    required this.status,
  });
}

/// Volunteer Tasks Screen - Task management with filters
class VolunteerTasksScreen extends ConsumerStatefulWidget {
  const VolunteerTasksScreen({super.key});

  @override
  ConsumerState<VolunteerTasksScreen> createState() => _VolunteerTasksScreenState();
}

class _VolunteerTasksScreenState extends ConsumerState<VolunteerTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<VolunteerTask> _tasks = _getDemoTasks();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static List<VolunteerTask> _getDemoTasks() {
    return [
      VolunteerTask(
        id: '1',
        title: 'Verify Road Accident',
        description: 'Multiple vehicle collision reported on NH48. Verify situation and provide assistance if needed.',
        location: 'NH48, near Manesar Toll',
        type: 'Verification',
        urgency: 'High',
        assignedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        status: 'pending',
      ),
      VolunteerTask(
        id: '2',
        title: 'First Aid Support',
        description: 'Minor injuries reported at community center during event. First aid supplies available on site.',
        location: 'Sector 22 Community Hall',
        type: 'Medical',
        urgency: 'Medium',
        assignedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: 'in_progress',
      ),
      VolunteerTask(
        id: '3',
        title: 'Flood Relief Distribution',
        description: 'Distribute relief kits to affected families. Collect from warehouse and deliver to designated areas.',
        location: 'Relief Camp, Sector 15',
        type: 'Relief',
        urgency: 'Low',
        assignedAt: DateTime.now().subtract(const Duration(hours: 3)),
        status: 'pending',
      ),
      VolunteerTask(
        id: '4',
        title: 'Traffic Management',
        description: 'Assist police with traffic management during VIP movement.',
        location: 'MG Road Junction',
        type: 'Traffic',
        urgency: 'Medium',
        assignedAt: DateTime.now().subtract(const Duration(days: 1)),
        completedAt: DateTime.now().subtract(const Duration(hours: 20)),
        status: 'completed',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Tasks',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.volunteerAccent,
          labelColor: AppTheme.volunteerAccent,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList('pending'),
          _buildTaskList('in_progress'),
          _buildTaskList('completed'),
        ],
      ),
    );
  }

  Widget _buildTaskList(String status) {
    final filteredTasks = _tasks.where((t) => t.status == status).toList();

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'completed' ? Icons.check_circle_outline : Icons.inbox_outlined,
              size: 80,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              status == 'completed' ? 'No completed tasks yet' : 'No pending tasks',
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        return _buildTaskCard(filteredTasks[index], index);
      },
    );
  }

  Widget _buildTaskCard(VolunteerTask task, int index) {
    final urgencyColor = _getUrgencyColor(task.urgency);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: urgencyColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: urgencyColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [urgencyColor.withOpacity(0.2), Colors.transparent],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getTaskIcon(task.type), color: urgencyColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        task.type,
                        style: TextStyle(color: urgencyColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    task.urgency,
                    style: TextStyle(
                      color: urgencyColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.description,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white54, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        task.location,
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (task.status != 'completed') _buildActionButtons(task),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildActionButtons(VolunteerTask task) {
    if (task.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _declineTask(task),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white54,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Decline'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => _acceptTask(task),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.volunteerAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Accept Task'),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _completeTask(task),
          icon: const Icon(Icons.check),
          label: const Text('Mark Complete'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }
  }

  void _acceptTask(VolunteerTask task) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = VolunteerTask(
          id: task.id,
          title: task.title,
          description: task.description,
          location: task.location,
          type: task.type,
          urgency: task.urgency,
          assignedAt: task.assignedAt,
          status: 'in_progress',
        );
      }
    });
    _tabController.animateTo(1);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Task accepted!'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _declineTask(VolunteerTask task) {
    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task declined'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _completeTask(VolunteerTask task) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = VolunteerTask(
          id: task.id,
          title: task.title,
          description: task.description,
          location: task.location,
          type: task.type,
          urgency: task.urgency,
          assignedAt: task.assignedAt,
          completedAt: DateTime.now(),
          status: 'completed',
        );
      }
    });
    _tabController.animateTo(2);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Task completed! +15 points'),
        backgroundColor: AppTheme.volunteerAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'High':
        return AppTheme.primaryRed;
      case 'Medium':
        return AppTheme.primaryOrange;
      default:
        return AppTheme.primaryGreen;
    }
  }

  IconData _getTaskIcon(String type) {
    switch (type) {
      case 'Verification':
        return Icons.verified;
      case 'Medical':
        return Icons.medical_services;
      case 'Relief':
        return Icons.inventory_2;
      case 'Traffic':
        return Icons.traffic;
      default:
        return Icons.task_alt;
    }
  }
}
