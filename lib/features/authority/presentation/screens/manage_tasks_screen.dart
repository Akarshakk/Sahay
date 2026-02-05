import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/providers/tasks_provider.dart';
import '../../../../core/services/api_service.dart';
import 'create_task_screen.dart';

/// Authority Task Management Screen - Manage real backend tasks with CRUD
class AuthorityManageTasksScreen extends ConsumerStatefulWidget {
  const AuthorityManageTasksScreen({super.key});

  @override
  ConsumerState<AuthorityManageTasksScreen> createState() =>
      _AuthorityManageTasksScreenState();
}

class _AuthorityManageTasksScreenState
    extends ConsumerState<AuthorityManageTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final myTasksAsync = ref.watch(getMyTasksProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Task Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.neutralGray,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.authorityAccent,
          labelColor: AppTheme.authorityAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Open'),
            Tab(text: 'In Progress'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: myTasksAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryRed),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text('Failed to load tasks: $error'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(getMyTasksProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.authorityAccent,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (tasks) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(tasks, filterStatus: 'open'),
              _buildTaskList(tasks, filterStatus: 'in_progress'),
              _buildTaskList(tasks, filterStatus: null),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AuthorityCreateTaskScreen(
                region: 'general',
                areaId: 'general',
              ),
            ),
          );
          // Refresh tasks after returning from create screen
          ref.refresh(getMyTasksProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
        backgroundColor: AppTheme.authorityAccent,
      ),
    );
  }

  Widget _buildTaskList(List<Task> allTasks, {String? filterStatus}) {
    final filtered = filterStatus == null
        ? allTasks
        : allTasks.where((t) => t.status == filterStatus).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No tasks found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildTaskCard(filtered[index], index);
      },
    );
  }

  Widget _buildTaskCard(Task task, int index) {
    final priorityColor = _getPriorityColor(task.priority);
    final deadline = task.deadline;
    final isOverdue =
        deadline != null && deadline.isBefore(DateTime.now()) && task.status == 'open';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showTaskDetails(task),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with priority and actions
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      task.priority.toUpperCase(),
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          task.region,
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Mark completed'),
                          ],
                        ),
                        onTap: () => _markCompleted(task),
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.delete,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                        onTap: () => _deleteTask(task),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title and description
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                style: TextStyle(color: Colors.grey[700], height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Deadline and reward
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deadline != null
                                  ? _formatDate(deadline)
                                  : 'No deadline',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                            if (isOverdue)
                              Text(
                                'OVERDUE',
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.star,
                            size: 16, color: Colors.amber[600]),
                        const SizedBox(width: 6),
                        Text(
                          '${task.rewardPoints} pts',
                          style: TextStyle(
                            color: Colors.amber[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Status chip
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(task.status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.2, end: 0);
  }

  Future<void> _markCompleted(Task task) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.updateTask(task.id, status: 'completed');
      ref.invalidate(getMyTasksProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task marked as completed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Task'),
        content: Text(
          'Are you sure you want to delete "${task.title}"?\nAll submissions will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final api = ref.read(apiServiceProvider);
                await api.deleteTask(task.id);
                ref.invalidate(getMyTasksProvider);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete task: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  task.description,
                  style: TextStyle(color: Colors.grey[700], height: 1.5),
                ),
                const SizedBox(height: 20),
                _buildDetailRow('Region:', task.region),
                _buildDetailRow('Area:', task.areaId),
                _buildDetailRow('Priority:', task.priority.toUpperCase()),
                _buildDetailRow('Reward Points:', '${task.rewardPoints}'),
                _buildDetailRow(
                  'Deadline:',
                  task.deadline != null
                      ? _formatDate(task.deadline!)
                      : 'Not set',
                ),
                _buildDetailRow('Status:', task.status),
                const SizedBox(height: 20),
                const Divider(),
                const Text('Submissions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                FutureBuilder<List<dynamic>>( // Use dynamic to avoid import issues if model not exported
                  future: ref.read(apiServiceProvider).getTaskSubmissions(task.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                       return Text('Error: ${snapshot.error}');
                    }
                    final submissions = snapshot.data ?? [];
                    if (submissions.isEmpty) {
                      return const Text('No submissions yet.', style: TextStyle(color: Colors.grey));
                    }
                    return Column(
                      children: submissions.map((sub) {
                        // sub is TaskSubmission model
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16),
                                    const SizedBox(width: 4),
                                    Text(sub.volunteerName ?? 'Volunteer', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    Text(sub.status.toUpperCase(), 
                                      style: TextStyle(
                                        color: sub.status == 'verified' ? Colors.green : Colors.orange,
                                        fontSize: 12, fontWeight: FontWeight.bold
                                      )
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (sub.submissionImageUrl != null && sub.submissionImageUrl!.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      sub.submissionImageUrl!,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_,__,___) => const Text('Image load failed'),
                                    ),
                                  ),
                                if (sub.submissionNotes != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text('Notes: ${sub.submissionNotes}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                  ),
                                const SizedBox(height: 8),
                                if (sub.status == 'submitted')
                                  ElevatedButton(
                                    onPressed: () async {
                                      await ref.read(apiServiceProvider).verifySubmission(
                                        submissionId: sub.id, 
                                        status: 'verified'
                                      );
                                      Navigator.pop(context); // Close dialog to refresh or simple snackbar
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission Verified!'), backgroundColor: Colors.green));
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text('Verify Submission'),
                                  )
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _markCompleted(task);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Mark Completed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.authorityAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteTask(task);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppTheme.primaryRed;
      case 'medium':
        return AppTheme.primaryOrange;
      case 'low':
      default:
        return AppTheme.primaryGreen;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return AppTheme.primaryOrange;
      case 'in_progress':
        return AppTheme.primaryRed;
      case 'completed':
      case 'verified':
        return AppTheme.primaryGreen;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
}
