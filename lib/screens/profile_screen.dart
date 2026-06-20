import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/app_models.dart';
import '../providers/auth_providers.dart';
import '../providers/data_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/auth');
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profile not found'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(context, profile),
                const SizedBox(height: 24),
                _buildReliabilitySection(ref, profile),
                const SizedBox(height: 24),
                _buildBusinessDetails(profile),
                const SizedBox(height: 24),
                _buildPublicSharing(profile),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showEditProfileModal(context, ref, profile),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.brandPrimary,
                    ),
                    child: const Text('Edit Profile'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserProfile profile) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppTheme.primaryNavy.withOpacity(0.1),
          child: Text(
            (profile.businessName ?? profile.username ?? 'P')[0].toUpperCase(),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.businessName ?? profile.username ?? 'Unnamed Business',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                profile.city ?? 'Location not set',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  profile.accountType.name.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.brandPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReliabilitySection(WidgetRef ref, UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Platform Trust Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              ReliabilityBadge(score: 4.8, reviewCount: 24,), // In real implementation, derive from dynamic review logic
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('4.8/5.0 Stars', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Based on 24 completed jobs', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessDetails(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Business Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _detailRow(Icons.work_outline, 'Trades', profile.trades.join(', ')),
        _detailRow(Icons.payments_outlined, 'Base Rate', '£${profile.hourlyRate ?? 0}/hr'),
        _detailRow(Icons.receipt_long_outlined, 'Tax Status', profile.taxRate == 20.0 ? 'CIS (20%)' : 'Self-Employed (30%)'),
        _detailRow(Icons.star_border, 'Subscription', profile.subscriptionStatus.toUpperCase()),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildPublicSharing(UserProfile profile) {
    final publicUrl = 'https://pai-app.example.com/profile/${profile.id}';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('Public QR Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: QrImageView(
                data: publicUrl,
                version: QrVersions.auto,
                size: 150.0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Share this code with clients to show your portfolio and reliability rating.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showEditProfileModal(BuildContext context, WidgetRef ref, UserProfile profile) {
    final businessController = TextEditingController(text: profile.businessName);
    final cityController = TextEditingController(text: profile.city);
    final rateController = TextEditingController(text: profile.hourlyRate?.toString());
    double selectedTaxRate = profile.taxRate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Business Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: businessController,
                  decoration: const InputDecoration(labelText: 'Business Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Hourly Rate (£)'),
                ),
                const SizedBox(height: 16),
                const Text('Tax Configuration'),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('CIS (20%)'),
                      selected: selectedTaxRate == 20,
                      onSelected: (val) => setModalState(() => selectedTaxRate = 20),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Self-Employed (30%)'),
                      selected: selectedTaxRate == 30,
                      onSelected: (val) => setModalState(() => selectedTaxRate = 30),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await Supabase.instance.client.from('user_profiles').update({
                        'business_name': businessController.text.trim(),
                        'city': cityController.text.trim(),
                        'hourly_rate': double.tryParse(rateController.text) ?? 0,
                        'tax_rate': selectedTaxRate,
                      }).eq('id', profile.id);
                      
                      ref.invalidate(userProfileProvider);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save Changes'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
