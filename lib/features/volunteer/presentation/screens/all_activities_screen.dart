import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/tasks_provider.dart';
import '../../../../core/models/task_model.dart';

class AllActivitiesScreen extends ConsumerWidget {
  const AllActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(getMySubmissionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('All Activities'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: submissionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (submissions) {
          if (submissions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No activities yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Sort by newest first
          final sortedSubmissions = List<TaskSubmission>.from(submissions)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedSubmissions.length,
            itemBuilder: (context, index) {
              final submission = sortedSubmissions[index];
              return _buildActivityCard(context, submission);
            },
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, TaskSubmission submission) {
    // Status Logic
    Color statusColor;
    IconData icon;
    String statusText;

    switch (submission.status.toLowerCase()) {
      case 'verified':
        statusColor = AppTheme.primaryGreen;
        icon = Icons.verified;
        statusText = 'Verified';
        break;
      case 'rejected':
        statusColor = AppTheme.primaryRed;
        icon = Icons.cancel;
        statusText = 'Rejected';
        break;
      default:
        statusColor = AppTheme.volunteerAccent;
        icon = Icons.timer;
        statusText = 'Submitted';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // Ideally we fetch task title, but for now specific ID or generic text is fine
                    // or improved if we join with task details.
                    // For the "Recent Activity" list we often just show generic text if we don't have joined data.
                    // But here we might want to try to be more specific if possible.
                    // For V1, showing status and date is safe.
                    submission.status == 'verified' 
                        ? 'Task Verified' 
                        : 'Task Submitted',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, y • h:mm a').format(submission.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (submission.submissionNotes != null && submission.submissionNotes!.isNotEmpty)
                     Padding(
                       padding: const EdgeInsets.only(top: 8),
                       child: Text(
                         submission.submissionNotes!,
                         style: TextStyle(fontSize: 13, color: Colors.grey[800], fontStyle: FontStyle.italic),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.5)),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
