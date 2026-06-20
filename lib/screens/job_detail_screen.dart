import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import '../providers/auth_providers.dart';
import '../providers/data_providers.dart';
import '../theme/app_theme.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  final _supabase = Supabase.instance.client;
  bool _isUpdating = false;

  Future<void> _updateJobStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await _supabase
          .from('private_jobs')
          .update({'status': newStatus})
          .eq('id', widget.jobId);
      
      ref.invalidate(privateJobsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateActualHours(double hours) async {
    try {
      await _supabase
          .from('private_jobs')
          .update({'actual_hours': hours})
          .eq('id', widget.jobId);
      ref.invalidate(privateJobsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating hours: $e')),
        );
      }
    }
  }

  void _showHoursDialog(double? currentHours) {
    final controller = TextEditingController(text: currentHours?.toString() ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Actual Hours'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Hours worked', suffixText: 'hrs'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                _updateActualHours(val);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(privateJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () => context.push('/invoice/${widget.jobId}'),
            tooltip: 'View Invoice',
          ),
        ],
      ),
      body: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (jobs) {
          final job = jobs.firstWhere(
            (j) => j.id == widget.jobId,
            orElse: () => throw Exception('Job not found'),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildJobHeader(job),
                const SizedBox(height: 24),
                _buildStatusTimeline(job),
                const SizedBox(height: 24),
                _buildFinancialBreakdown(job),
                const SizedBox(height: 24),
                if (job.jobType == 'hourly') _buildHourlyTracking(job),
                const SizedBox(height: 32),
                _buildActionButtons(job),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobHeader(PrivateJob job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(job.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Customer: ${job.customer ?? "Private Client"}', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.brandPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            job.status.toUpperCase(),
            style: const TextStyle(color: AppTheme.brandPrimary, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTimeline(PrivateJob job) {
    final statuses = ['draft', 'sent', 'accepted', 'invoiced', 'paid'];
    final currentIndex = statuses.indexOf(job.status.toLowerCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progress', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(statuses.length, (index) {
            final active = index <= currentIndex;
            return Expanded(
              child: Column(
                children: [
                  Container(
                    height: 4,
                    color: active ? AppTheme.brandPrimary : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statuses[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      color: active ? AppTheme.brandPrimary : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFinancialBreakdown(PrivateJob job) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Financial Summary', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            _financialRow('Labour', job.labour),
            _financialRow('Materials', job.materials),
            _financialRow('VAT', job.vat),
            const Divider(),
            _financialRow('Total', job.total, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _financialRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text('£${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildHourlyTracking(PrivateJob job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hourly Tracking', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${job.actualHours ?? 0} Hours Logged'),
          trailing: TextButton.icon(
            onPressed: () => _showHoursDialog(job.actualHours),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(PrivateJob job) {
    if (_isUpdating) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        if (job.status == 'accepted' || job.status == 'sent')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _updateJobStatus('invoiced'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Complete & Generate Invoice'),
            ),
          ),
        const SizedBox(height: 12),
        if (job.status == 'invoiced')
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _updateJobStatus('paid'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Mark as Paid'),
            ),
          ),
        const SizedBox(height: 12),
        if (job.status == 'paid')
           SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showReviewDialog(job),
              icon: const Icon(Icons.rate_review),
              label: const Text('Review Customer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
      ],
    );
  }

  void _showReviewDialog(PrivateJob job) {
    int rating = 5;
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review ${job.customer ?? "Customer"}', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setModalState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Internal nodes or review text',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final user = ref.read(userProvider);
                    if (user == null) return;

                    await _supabase.from('reviews').insert({
                      'author_id': user.id,
                      'subject_id': null, // In this app flow, subject_id would be target profile if available
                      'job_post_id': job.sourceJobPostId,
                      'mode': 'contractor_to_customer',
                      'rating': rating,
                      'categories': {'communication': rating, 'reliability': rating},
                      'status': 'published'
                    });
                    
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Submit Review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}