import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- Auth ---

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required AccountType role,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'account_type': role.name},
    );
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.pai://login-callback/',
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // --- Profiles ---

  Future<UserProfile?> getProfile(String id) async {
    final data = await _client
        .from('user_profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
    
    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  Future<void> upsertProfile(UserProfile profile) async {
    await _client.from('user_profiles').upsert(profile.toJson());
  }

  Future<void> updateOnboardingStatus(String id, bool complete) async {
    await _client
        .from('user_profiles')
        .update({'onboarding_complete': complete})
        .eq('id', id);
  }

  // --- Job Posts (Marketplace) ---

  Stream<List<JobPost>> watchPublicJobs() {
    return _client
        .from('job_posts')
        .stream(primaryKey: ['id'])
        .eq('status', 'open')
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => JobPost.fromJson(json)).toList());
  }

  Future<List<JobPost>> getJobsByTrade(String trade) async {
    final data = await _client
        .from('job_posts')
        .select()
        .eq('trade', trade)
        .eq('status', 'open')
        .order('created_at', ascending: false);
    
    return (data as List).map((json) => JobPost.fromJson(json)).toList();
  }

  Future<void> createJobPost(JobPost job) async {
    await _client.from('job_posts').insert(job.toJson());
  }

  Future<List<UserProfile>> getContractors() async {
    final data = await _client
        .from('user_profiles')
        .select()
        .or('account_type.eq.contractor,account_type.eq.both')
        .order('id', ascending: false);
    return (data as List)
        .map((json) => UserProfile.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  // --- Job Applications ---

  Future<void> submitApplication(JobApplication application) async {
    await _client.from('job_applications').insert(application.toJson());
  }

  Future<List<JobApplication>> getApplicationsForPost(String jobPostId) async {
    final data = await _client
        .from('job_applications')
        .select()
        .eq('job_post_id', jobPostId);
    
    return (data as List).map((json) => JobApplication.fromJson(json)).toList();
  }

  // --- Private Jobs (Contractor Ledger) ---

  Stream<List<Map<String, dynamic>>> watchPrivateJobs(String contractorId) {
    return _client
        .from('private_jobs')
        .stream(primaryKey: ['id'])
        .eq('contractor_id', contractorId)
        .order('id', ascending: false);
  }

  Future<void> createPrivateJob(Map<String, dynamic> privateJobData) async {
    await _client.from('private_jobs').insert(privateJobData);
  }

  Future<void> updatePrivateJobStatus(String jobId, String status) async {
    await _client
        .from('private_jobs')
        .update({'status': status})
        .eq('id', jobId);
  }

  // --- Tax Pot & Manual Income ---

  Future<void> addManualIncome(Map<String, dynamic> incomeData) async {
    await _client.from('manual_income').insert(incomeData);
  }

  Future<List<Map<String, dynamic>>> getIncomeLogs(String contractorId) async {
    final data = await _client
        .from('manual_income')
        .select()
        .eq('contractor_id', contractorId)
        .order('date', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<double> getTotalEarnings(String contractorId) async {
    final res = await _client
        .from('private_jobs')
        .select('total')
        .eq('contractor_id', contractorId)
        .eq('status', 'paid');
    
    final manual = await _client
        .from('manual_income')
        .select('amount')
        .eq('contractor_id', contractorId);

    double total = 0;
    for (var row in res) {
      total += (row['total'] as num).toDouble();
    }
    for (var row in manual) {
      total += (row['amount'] as num).toDouble();
    }
    return total;
  }

  // --- Realtime Subscriptions ---

  RealtimeChannel subscribeToMarketplace(void Function(PostgresPygmyPayload) callback) {
    final channel = _client.channel('public:job_posts');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'job_posts',
      callback: (payload) => callback(payload),
    ).subscribe();
    return channel;
  }

  // --- Storage ---

  Future<String> uploadAvatar(String userId, List<int> bytes) async {
    final path = 'avatars/$userId.jpg';
    await _client.storage.from('profiles').uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    return _client.storage.from('profiles').getPublicUrl(path);
  }
}

typedef PostgresPygmyPayload = PostgresChangePayload;