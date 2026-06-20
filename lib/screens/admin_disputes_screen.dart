import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import '../providers/auth_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AdminDisputesScreen extends ConsumerStatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  ConsumerState<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends ConsumerState<AdminDisputesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateDisputeStatus(String disputeId, String newStatus, String? note) async {
    try {
      await _supabase.from('disputes').update({
        'status': newStatus,
        'resolution_note': note,
      }).eq('id', disputeId);
      
      if (mounted) {
        setState(() {}); // Refresh local view
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dispute marked as $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating dispute: $e')),
        );
      }
    }
  }

  Future<void> _moderateReview(String reviewId, String status) async {
    try {
      await _supabase.from('reviews').update({
        'status': status,
      }).eq('id', reviewId);
      
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review status changed to $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error moderating review: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.brandPrimary,
          tabs: const [
            Tab(text: 'Disputes'),
            Tab(text: 'Review Moderation'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DisputesList(onUpdate: _updateDisputeStatus),
          _ReviewsModerationList(onModerate: _moderateReview),
        ],
      ),
    );
  }
}

class _DisputesList extends StatelessWidget {
  final Future<void> Function(String, String, String?) onUpdate;

  const _DisputesList({required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return FutureBuilder<List<dynamic>>(
      future: supabase.from('disputes').select('''
        *,
        job_posts(title),
        contractor:user_profiles!contractor_id(business_name, username),
        customer:user_profiles!customer_id(username)
      ''').order('status', ascending: true),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final disputes = snapshot.data!;

        if (disputes.isEmpty) {
          return const Center(child: Text('No active disputes.'));
        }

        return ListView.builder(
          itemCount: disputes.length,
          itemBuilder: (context, index) {
            final d = disputes[index];
            final status = d['status'] as String;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ExpansionTile(
                leading: Icon(
                  status == 'open' ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                  color: status == 'open' ? Colors.orange : Colors.green,
                ),
                title: Text('Dispute: ${d['job_posts']?['title'] ?? 'Generic'}'),
                subtitle: Text('Reason: ${d['reason']}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contractor: ${d['contractor']['business_name'] ?? d['contractor']['username']}'),
                        Text('Customer: ${d['customer']['username']}'),
                        const Divider(),
                        if (status == 'open') ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _showResolveDialog(context, d['id']),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPrimary, foregroundColor: Colors.white),
                                  child: const Text('Resolve Dispute'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => onUpdate(d['id'], 'closed', 'Closed without action'),
                                  child: const Text('Close'),
                                ),
                              ),
                            ],
                          )
                        ] else ...[
                          Text('Resolution: ${d['resolution_note'] ?? 'No note'}', style: const TextStyle(fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showResolveDialog(BuildContext context, String id) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Dispute'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Enter resolution note...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              onUpdate(id, 'resolved', controller.text);
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _ReviewsModerationList extends StatelessWidget {
  final Future<void> Function(String, String) onModerate;

  const _ReviewsModerationList({required this.onModerate});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return FutureBuilder<List<dynamic>>(
      future: supabase.from('reviews').select('''
        *,
        author:user_profiles!author_id(username),
        subject:user_profiles!subject_id(username, business_name)
      ''').order('id', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final reviews = snapshot.data!;

        return ListView.builder(
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final r = reviews[index];
            final categories = r['categories'] as Map<String, dynamic>;
            final isRemoved = r['status'] == 'removed';
            
            return ListTile(
              isThreeLine: true,
              leading: ReliabilityBadge(score: (r['rating'] as num).toDouble(),reviewCount: 0,),
              title: Text('${r['author']['username']} → ${r['subject']['business_name'] ?? r['subject']['username']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Category Ratings: ${categories.entries.map((e) => "${e.key}: ${e.value}").join(", ")}'),
                  if (isRemoved) 
                    const Text('REMOVED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (val) => onModerate(r['id'], val),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'published', child: Text('Approve / Restore')),
                  const PopupMenuItem(value: 'removed', child: Text('Remove Review', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
