import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/app_models.dart';
import '../providers/auth_providers.dart';
import '../providers/data_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  String? _selectedTrade;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _tradeOptions = [
    'Plumbing',
    'Electrician',
    'Carpentry',
    'Painting',
    'Bricklaying',
    'Roofing',
    'Plastering',
    'Landscaping',
    'General Labor'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (profile) {
        if (profile == null) return const Scaffold(body: Center(child: Text('No profile found')));

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Marketplace'),
              bottom: const TabBar(
                indicatorColor: AppTheme.brandPrimary,
                labelColor: AppTheme.brandPrimary,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: 'Public Jobs'),
                  Tab(text: 'Trade Network'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _PublicJobsView(
                  selectedTrade: _selectedTrade,
                  accountType: profile.accountType,
                  onTradeFilter: (val) => setState(() => _selectedTrade = val),
                ),
                _TradeNetworkView(),
              ],
            ),
            floatingActionButton: profile.accountType != AccountType.contractor
                ? FloatingActionButton.extended(
                    onPressed: () => _showPostJobModal(context),
                    label: const Text('Post a Job'),
                    icon: const Icon(Icons.add),
                    backgroundColor: AppTheme.brandPrimary,
                  )
                : null,
          ),
        );
      },
    );
  }

  void _showPostJobModal(BuildContext context) {
    // Navigates to a flow or opens modal defined in JobsScreen logic
    // For this context, we will navigate to the standard creation path
    context.push('/jobs/create');
  }
}

class _PublicJobsView extends ConsumerWidget {
  final String? selectedTrade;
  final AccountType accountType;
  final Function(String?) onTradeFilter;

  const _PublicJobsView({
    required this.selectedTrade,
    required this.accountType,
    required this.onTradeFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(publicJobsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: const Text("All Trades"),
                    selected: selectedTrade == null,
                    onSelected: (selected) => onTradeFilter(null),
                  ),
                ),
                ...['Plumbing', 'Electrician', 'Carpentry', 'Painting'].map((trade) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(trade),
                      selected: selectedTrade == trade,
                      onSelected: (selected) {
                        onTradeFilter(selected ? trade : null);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Expanded(
          child: jobsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading jobs')),
            data: (jobs) {
              final filteredJobs = selectedTrade == null
                  ? jobs
                  : jobs.where((j) => j.trade == selectedTrade).toList();

              if (filteredJobs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No jobs matching your criteria',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredJobs.length,
                itemBuilder: (context, index) {
                  final job = filteredJobs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: InkWell(
                      onTap: () => context.push('/marketplace/job/${job.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.brandPrimary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    job.trade?.toUpperCase() ?? 'GENERAL',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.brandPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '£${job.budget?.toStringAsFixed(0) ?? 'TBD'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.primaryNavy,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              job.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              job.description ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  "London, UK", // Usually joined from client location or direct field
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                const Spacer(),
                                const Text(
                                  'View Details',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.brandPrimary,
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 16, color: AppTheme.brandPrimary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TradeNetworkView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real app, this would query user_profiles filtered by account_type='contractor'
    // To implement the specification's "Contractor to Contractor hiring" feature.
    return FutureBuilder(
      future: ref.read(supabaseServiceProvider).getContractors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final contractors = snapshot.data as List<UserProfile>? ?? [];

        if (contractors.isEmpty) {
          return const Center(child: Text("No contractors in the network yet."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contractors.length,
          itemBuilder: (context, index) {
            final contractor = contractors[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              leading: CircleAvatar(
                backgroundColor: AppTheme.brandPrimary.withOpacity(0.1),
                child: Text(contractor.businessName?.substring(0, 1) ?? "P"),
              ),
              title: Text(contractor.businessName ?? "Independent Trader"),
              subtitle: Text(contractor.trades.join(', ')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => context.push('/contractor/${contractor.id}'),
            );
          },
        );
      },
    );
  }
}