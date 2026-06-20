import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ContractorProfileScreen extends ConsumerWidget {
  final String contractorId;

  const ContractorProfileScreen({super.key, required this.contractorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<UserProfile?>(
      future: _fetchContractorProfile(contractorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final contractor = snapshot.data;
        if (contractor == null) {
          return const Scaffold(body: Center(child: Text('Contractor profile not found')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(contractor.businessName ?? contractor.username ?? 'Contractor Profile'),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderSection(contractor: contractor),
                const Divider(),
                _AvailabilityGrid(),
                const Divider(),
                _TradePortfolio(contractorId: contractorId),
                const Divider(),
                _ReviewList(contractorId: contractorId),
              ],
            ),
          ),
          bottomNavigationBar: _ContactBar(contractor: contractor),
        );
      },
    );
  }

  Future<UserProfile?> _fetchContractorProfile(String id) async {
    final response = await Supabase.instance.client
        .from('user_profiles')
        .select()
        .eq('id', id)
        .single();
    return UserProfile.fromJson(response);
  }
}

class _HeaderSection extends StatelessWidget {
  final UserProfile contractor;

  const _HeaderSection({required this.contractor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.brandPrimary.withValues(alpha: 0.1),
            child: const Icon(Icons.business, size: 40, color: AppTheme.brandPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contractor.businessName ?? 'Independent Contractor',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  contractor.city ?? 'Location not specified',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: contractor.trades.map((trade) => Chip(
                    label: Text(trade, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppTheme.brandPrimary.withValues(alpha: 0.05),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
                const SizedBox(height: 8),
                const ReliabilityBadge(score: 4.8, reviewCount: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Availability', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) {
              final isWeekend = day == 'Sat' || day == 'Sun';
              return Column(
                children: [
                  Text(day, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isWeekend ? Colors.grey[200] : Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: isWeekend ? Colors.grey[400]! : Colors.green),
                    ),
                    child: Icon(
                      isWeekend ? Icons.close : Icons.check,
                      size: 16,
                      color: isWeekend ? Colors.grey[600] : Colors.green[800],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TradePortfolio extends StatelessWidget {
  final String contractorId;

  const _TradePortfolio({required this.contractorId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Project Gallery', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => Container(
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  final String contractorId;

  const _ReviewList({required this.contractorId});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Reviews', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          FutureBuilder<List<dynamic>>(
            future: supabase
                .from('reviews')
                .select('*, author:user_profiles!author_id(username, business_name)')
                .eq('subject_id', contractorId)
                .eq('mode', 'customer_to_contractor')
                .eq('status', 'published')
                .order('id', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: LinearProgressIndicator());
              }
              final reviews = snapshot.data ?? [];
              if (reviews.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No reviews yet. Be the first to hire them!'),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  final author = review['author'];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              author['username'] ?? 'Anonymous Client',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: List.generate(5, (i) => Icon(
                                Icons.star,
                                size: 14,
                                color: i < (review['rating'] ?? 0) ? Colors.amber : Colors.grey[300],
                              )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verified Job',
                          style: TextStyle(fontSize: 10, color: Colors.green[700], fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          review['categories'] != null ? 
                            (review['categories'] as Map).entries.map((e) => "${e.key}: ${e.value}/5").join(" • ") 
                            : 'Perfectly completed.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ContactBar extends StatelessWidget {
  final UserProfile contractor;

  const _ContactBar({required this.contractor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contractor.hourlyRate != null ? '£${contractor.hourlyRate}/hr' : 'Quote required',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Text('Estimated Rate', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Navigation to Marketplace / Posting would go here to initiate a job
            },
            icon: const Icon(Icons.send),
            label: const Text('Invite to Quote'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}