import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import 'auth_providers.dart';

/// Provides a stream of all open job posts from the marketplace.
final publicJobsProvider = StreamProvider<List<JobPost>>((ref) {
  final supabase = Supabase.instance.client;
  return supabase
      .from('job_posts')
      .stream(primaryKey: ['id'])
      .eq('status', 'open')
      .order('created_at', ascending: false)
      .map((maps) => maps.map((map) => JobPost.fromJson(map)).toList());
});

/// Provides a stream of a specific job post by ID.
final jobPostDetailProvider = StreamProvider.family<JobPost, String>((ref, jobId) {
  final supabase = Supabase.instance.client;
  return supabase
      .from('job_posts')
      .stream(primaryKey: ['id'])
      .eq('id', jobId)
      .limit(1)
      .map((maps) => JobPost.fromJson(maps.first));
});

/// Provides a stream of the current contractor's private job ledger.
final privateJobsProvider = StreamProvider<List<PrivateJob>>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return Stream.value([]);
  
  final supabase = Supabase.instance.client;
  return supabase
      .from('private_jobs')
      .stream(primaryKey: ['id'])
      .eq('contractor_id', user.id)
      .order('id', ascending: false)
      .map((maps) => maps.map((map) => PrivateJob.fromJson(map)).toList());
});

/// Provides a stream of the current user's job applications.
final myApplicationsProvider = StreamProvider<List<JobApplication>>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return Stream.value([]);

  final supabase = Supabase.instance.client;
  return supabase
      .from('job_applications')
      .stream(primaryKey: ['id'])
      .eq('contractor_id', user.id)
      .map((maps) => maps.map((map) => JobApplication.fromJson(map)).toList());
});

/// Provides a stream of applications for a specific job (for customers).
final jobApplicationsProvider = StreamProvider.family<List<JobApplication>, String>((ref, jobPostId) {
  final supabase = Supabase.instance.client;
  return supabase
      .from('job_applications')
      .stream(primaryKey: ['id'])
      .eq('job_post_id', jobPostId)
      .map((maps) => maps.map((map) => JobApplication.fromJson(map)).toList());
});

/// Provides the manual income log for the Tax Pot.
final manualIncomeProvider = StreamProvider<List<ManualIncome>>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return Stream.value([]);

  final supabase = Supabase.instance.client;
  return supabase
      .from('manual_income')
      .stream(primaryKey: ['id'])
      .eq('contractor_id', user.id)
      .order('date', ascending: false)
      .map((maps) => maps.map((map) => ManualIncome.fromJson(map)).toList());
});

/// Calculates the aggregate financial data for the Tax Pot.
final taxPotCalculationProvider = Provider<TaxPotSummary>((ref) {
  final privateJobs = ref.watch(privateJobsProvider).value ?? [];
  final manualIncomes = ref.watch(manualIncomeProvider).value ?? [];
  final profile = ref.watch(userProfileProvider).value;

  double totalEarnings = 0;
  double totalTaxSetAside = 0;

  // Add earnings from PAI jobs marked as 'paid'
  for (final job in privateJobs) {
    if (job.status == 'paid') {
      totalEarnings += job.total;
      // Tax is usually calculated on labour + profit, 
      // but for this tracker we apply the user's rate to the total or specialized logic
      totalTaxSetAside += (job.total * (profile?.taxRate ?? 20) / 100);
    }
  }

  // Add earnings from manual entries
  for (final income in manualIncomes) {
    totalEarnings += income.amount;
    totalTaxSetAside += income.taxSetAside;
  }

  return TaxPotSummary(
    totalEarnings: totalEarnings,
    estimatedTaxLiability: totalTaxSetAside,
    taxRate: profile?.taxRate ?? 20,
  );
});

/// Provides a list of reviews for a specific user.
final userReviewsProvider = FutureProvider.family<List<Review>, String>((ref, userId) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('reviews')
      .select()
      .eq('subject_id', userId)
      .eq('status', 'published');
  
  return (response as List).map((json) => Review.fromJson(json)).toList();
});

/// Helper class for Tax Pot UI
class TaxPotSummary {
  final double totalEarnings;
  final double estimatedTaxLiability;
  final double taxRate;

  TaxPotSummary({
    required this.totalEarnings,
    required this.estimatedTaxLiability,
    required this.taxRate,
  });
}