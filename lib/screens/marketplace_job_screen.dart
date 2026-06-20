import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import '../providers/auth_providers.dart';
import '../providers/data_providers.dart';
import '../services/openai_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class MarketplaceJobScreen extends ConsumerStatefulWidget {
  final String jobId;

  const MarketplaceJobScreen({super.key, required this.jobId});

  @override
  ConsumerState<MarketplaceJobScreen> createState() => _MarketplaceJobScreenState();
}

class _MarketplaceJobScreenState extends ConsumerState<MarketplaceJobScreen> {
  final _supabase = Supabase.instance.client;
  bool _isAiGenerating = false;
  final _quoteController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _quoteController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _generateAiQuote(JobPost job) async {
    setState(() => _isAiGenerating = true);
    try {
      final aiService = OpenAIService();
      final prompt = [
        {
          'role': 'system',
          'content': 'You are an expert UK trade estimator. Based on the job title and description, suggest a reasonable labour and materials quote in GBP. Provide a brief breakdown.'
        },
        {
          'role': 'user',
          'content': 'Job Title: ${job.title}\nDescription: ${job.description ?? "No description provided"}\nBudget: ${job.budget ?? "Not specified"}'
        }
      ];

      final response = await aiService.chat(messages: prompt);
      
      // Basic extraction of a number from the AI text for the controller
      final RegExp regExp = RegExp(r'£?(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)');
      final match = regExp.firstMatch(response);
      if (match != null) {
        _quoteController.text = match.group(1)?.replaceAll(',', '') ?? '';
      }
      _messageController.text = response;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI Error: $e')),
      );
    } finally {
      setState(() => _isAiGenerating = false);
    }
  }

  Future<void> _submitApplication(String userId) async {
    if (_quoteController.text.isEmpty) return;

    try {
      await _supabase.from('job_applications').insert({
        'job_post_id': widget.jobId,
        'contractor_id': userId,
        'quote_amount': double.parse(_quoteController.text),
        'message': _messageController.text,
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote submitted successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    }
  }

  Future<void> _acceptApplication(JobApplication app, JobPost job) async {
    try {
      // 1. Update application status
      await _supabase
          .from('job_applications')
          .update({'status': 'accepted'})
          .eq('id', app.id);

      // 2. Update job post status
      await _supabase
          .from('job_posts')
          .update({'status': 'in_progress'})
          .eq('id', job.id);

      // 3. Create private job for contractor
      await _supabase.from('private_jobs').insert({
        'contractor_id': app.contractorId,
        'title': job.title,
        'customer': (await _supabase.from('user_profiles').select('business_name').eq('id', job.clientId).single())['business_name'] ?? 'Customer',
        'status': 'accepted',
        'total': app.quoteAmount,
        'labour': app.quoteAmount * 0.7, // Estimate split
        'materials': app.quoteAmount * 0.3,
        'vat': 0,
        'source_job_post_id': job.id,
      });

      if (mounted) {
        context.go('/jobs');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).value;
    final jobAsync = ref.watch(jobPostProvider(widget.jobId));
    final appsAsync = ref.watch(jobApplicationsProvider(widget.jobId));

    if (profile == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (job) {
          if (job == null) return const Center(child: Text('Job not found'));

          final isOwner = job.clientId == profile.id;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildJobHeader(job),
                const Divider(height: 32),
                if (isOwner) 
                  _buildApplicationsList(appsAsync, job)
                else 
                  _buildContractorQuoteForm(profile, job),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobHeader(JobPost job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(job.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.brandPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                job.status.toUpperCase(),
                style: const TextStyle(color: AppTheme.brandPrimary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(job.trade ?? 'General Trade', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        const SizedBox(height: 16),
        const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(job.description ?? 'No description.', style: const TextStyle(fontSize: 16)),
        if (job.budget != null) ...[
          const SizedBox(height: 16),
          Text('Budget: £${job.budget?.toStringAsFixed(2)}', 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ],
    );
  }

  Widget _buildApplicationsList(AsyncValue<List<JobApplication>> appsAsync, JobPost job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quotes Received', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        appsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading applications: $e'),
          data: (apps) {
            if (apps.isEmpty) return const Text('No quotes yet.');
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: apps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final app = apps[index];
                return Card(
                  child: ListTile(
                    title: Text('£${app.quoteAmount.toStringAsFixed(2)}'),
                    subtitle: Text(app.message ?? 'No message'),
                    trailing: job.status == 'open' 
                      ? ElevatedButton(
                          onPressed: () => _acceptApplication(app, job),
                          child: const Text('Accept'),
                        )
                      : Text(app.status),
                    onTap: () => context.push('/contractor/${app.contractorId}'),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildContractorQuoteForm(UserProfile profile, JobPost job) {
    if (job.status != 'open') {
      return const Center(child: Text('This job is no longer accepting quotes.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Submit a Quote', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _quoteController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quote Amount (£)',
                  border: OutlineInputBorder(),
                  prefixText: '£ ',
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: _isAiGenerating ? null : () => _generateAiQuote(job),
              icon: _isAiGenerating 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
              tooltip: 'AI-Assisted Quote',
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _messageController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Scope / Message to Client',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => _submitApplication(profile.id),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPrimary, foregroundColor: Colors.white),
            child: const Text('Submit Quote', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}