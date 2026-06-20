import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import '../providers/auth_providers.dart';
import '../providers/data_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (profile) {
        if (profile == null) return const Scaffold(body: Center(child: Text('Not logged in')));

        final isContractor = profile.accountType == AccountType.contractor || profile.accountType == AccountType.both;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Jobs'),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: isContractor ? 'Private Ledger' : 'Active Postings'),
                const Tab(text: 'History'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              isContractor ? const _ContractorLedgerView() : const _CustomerPostingsView(),
              const _JobHistoryView(),
            ],
          ),
          floatingActionButton: isContractor 
              ? FloatingActionButton.extended(
                  onPressed: () => _showCreatePrivateJobModal(context),
                  label: const Text('Add Job'),
                  icon: const Icon(Icons.add),
                )
              : FloatingActionButton.extended(
                  onPressed: () => _showPostJobModal(context),
                  label: const Text('Post Job'),
                  icon: const Icon(Icons.publish),
                ),
        );
      },
    );
  }

  void _showCreatePrivateJobModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CreatePrivateJobSheet(),
    );
  }

  void _showPostJobModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _PostJobSheet(),
    );
  }
}

class _ContractorLedgerView extends ConsumerWidget {
  const _ContractorLedgerView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(privateJobsProvider);

    return jobsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (jobs) {
        final activeJobs = jobs.where((j) => j.status != 'paid').toList();
        if (activeJobs.isEmpty) {
          return const Center(child: Text('No active jobs in your ledger.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeJobs.length,
          itemBuilder: (context, index) {
            final job = activeJobs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Client: ${job.customer ?? "Generic"} • Status: ${job.status.toUpperCase()}'),
                trailing: Text('£${job.total.toStringAsFixed(2)}', 
                  style: const TextStyle(color: AppTheme.brandPrimary, fontWeight: FontWeight.bold)),
                onTap: () => context.push('/jobs/${job.id}'),
              ),
            );
          },
        );
      },
    );
  }
}

class _CustomerPostingsView extends ConsumerWidget {
  const _CustomerPostingsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final supabase = Supabase.instance.client;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('job_posts')
          .stream(primaryKey: ['id'])
          .eq('client_id', user?.id ?? '')
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final posts = snapshot.data!.where((p) => p['status'] != 'completed').toList();
        
        if (posts.isEmpty) {
          return const Center(child: Text('You haven\'t posted any jobs yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(post['title'] ?? 'Untitled Job'),
                subtitle: Text('Budget: £${post['budget'] ?? 'Open'} • Status: ${post['status']}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/marketplace/job/${post['id']}'),
              ),
            );
          },
        );
      },
    );
  }
}

class _JobHistoryView extends ConsumerWidget {
  const _JobHistoryView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(child: Text('Completed and invoiced jobs will appear here.'));
  }
}

class _CreatePrivateJobSheet extends StatefulWidget {
  const _CreatePrivateJobSheet();

  @override
  State<_CreatePrivateJobSheet> createState() => _CreatePrivateJobSheetState();
}

class _CreatePrivateJobSheetState extends State<_CreatePrivateJobSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _customerController = TextEditingController();
  final _totalController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    final userId = Supabase.instance.client.auth.currentUser?.id;
    try {
      await Supabase.instance.client.from('private_jobs').insert({
        'contractor_id': userId,
        'title': _titleController.text.trim(),
        'customer': _customerController.text.trim(),
        'total': double.parse(_totalController.text),
        'labour': double.parse(_totalController.text) * 0.7, // Estimate
        'materials': double.parse(_totalController.text) * 0.3, // Estimate
        'vat': 0,
        'status': 'sent',
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add Private Job', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Job Title')),
            TextFormField(controller: _customerController, decoration: const InputDecoration(labelText: 'Customer Name')),
            TextFormField(controller: _totalController, decoration: const InputDecoration(labelText: 'Quote Amount (£)'), keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Save to Ledger'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PostJobSheet extends StatefulWidget {
  const _PostJobSheet();

  @override
  State<_PostJobSheet> createState() => _PostJobSheetState();
}

class _PostJobSheetState extends State<_PostJobSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    final userId = Supabase.instance.client.auth.currentUser?.id;
    try {
      await Supabase.instance.client.from('job_posts').insert({
        'client_id': userId,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'budget': double.tryParse(_budgetController.text),
        'status': 'open',
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Post New Job', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'What needs doing?')),
            TextFormField(controller: _descController, decoration: const InputDecoration(labelText: 'Details/Requirements'), maxLines: 3),
            TextFormField(controller: _budgetController, decoration: const InputDecoration(labelText: 'Estimated Budget (£)'), keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Post to Marketplace'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}