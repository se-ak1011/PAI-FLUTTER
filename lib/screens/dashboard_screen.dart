import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_providers.dart';
import '../providers/data_providers.dart';
import '../models/app_models.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';

final supabase = Supabase.instance.client;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('PAI Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profile not found'));

          if (profile.accountType == AccountType.contractor) {
            return _ContractorDashboard(profile: profile);
          } else {
            return _CustomerDashboard(profile: profile);
          }
        },
      ),
      bottomNavigationBar: const _DashboardNav(),
    );
  }
}

class _ContractorDashboard extends ConsumerWidget {
  final UserProfile profile;
  const _ContractorDashboard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privateJobsAsync = ref.watch(privateJobsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(privateJobsProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Welcome back, ${profile.businessName ?? profile.username ?? 'Pro'}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
          ),
          const SizedBox(height: 20),
          _buildFinancialSummary(context, ref),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Jobs',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => context.go('/jobs'),
                child: const Text('View All'),
              ),
            ],
          ),
          privateJobsAsync.when(
            data: (jobs) => jobs.isEmpty
                ? _EmptyDashboardState(
                    icon: Icons.work_outline,
                    message: 'No active jobs yet.',
                    buttonText: 'Find Work',
                    onPressed: () => context.go('/marketplace'),
                  )
                : Column(
                    children: jobs
                        .take(3)
                        .map((job) => _DashboardJobItem(
                              title: job.title,
                              subtitle: job.customer ?? 'Private Client',
                              amount: '£${job.total.toStringAsFixed(2)}',
                              status: job.status,
                            ))
                        .toList(),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('Error loading jobs'),
          ),
          const SizedBox(height: 24),
          _SubscriptionStatusCard(status: profile.subscriptionStatus),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(BuildContext context, WidgetRef ref) {
    // Basic calculation for the demo; in full app this uses more complex analytics
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        const StatCard(
          title: 'Total Earnings',
          value: '£0.00',
          icon: Icons.payments_outlined,
          color: AppTheme.brandPrimary,
        ),
        StatCard(
          title: 'Tax Pot Estimate',
          value: '£0.00',
          icon: Icons.account_balance_wallet_outlined,
          color: AppTheme.brandSecondary,
          subtitle: '${profile.taxRate}% Rate',
        ),
      ],
    );
  }
}

class _CustomerDashboard extends ConsumerWidget {
  final UserProfile profile;
  const _CustomerDashboard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publicJobsAsync = ref.watch(publicJobsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(publicJobsProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Hello, ${profile.username ?? 'there'}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
          ),
          const SizedBox(height: 8),
          const Text('Ready to start your next project?'),
          const SizedBox(height: 24),
          _CustomerActionCard(
            title: 'Post a New Job',
            subtitle: 'Get quotes from verified local tradespeople',
            icon: Icons.add_task,
            onTap: () => context.go('/jobs'), // Navigates to hub where Post Job modal exists
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Postings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => context.go('/jobs'),
                child: const Text('See All'),
              ),
            ],
          ),
          publicJobsAsync.when(
            data: (jobs) {
              final myJobs = jobs.where((j) => j.clientId == profile.id).toList();
              return myJobs.isEmpty
                  ? const _EmptyDashboardState(
                      icon: Icons.campaign_outlined,
                      message: 'You haven\'t posted any jobs yet.',
                    )
                  : Column(
                      children: myJobs
                          .take(3)
                          .map((job) => _DashboardJobItem(
                                title: job.title,
                                subtitle: job.trade ?? 'General',
                                amount: job.budget != null ? '£${job.budget}' : 'No Budget',
                                status: job.status,
                              ))
                          .toList(),
                    );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('Error loading postings'),
          ),
        ],
      ),
    );
  }
}

class _DashboardJobItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String status;

  const _DashboardJobItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimary.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.brandPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _CustomerActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryNavy, Color(0xFF2A3447)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryNavy.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _EmptyDashboardState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  const _EmptyDashboardState({
    required this.icon,
    required this.message,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: Colors.grey.shade500)),
            if (buttonText != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onPressed, child: Text(buttonText!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubscriptionStatusCard extends StatelessWidget {
  final String status;
  const _SubscriptionStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    return Card(
      elevation: 0,
      color: isActive ? Colors.green.shade50 : Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isActive ? Colors.green.shade100 : Colors.orange.shade100),
      ),
      child: ListTile(
        leading: Icon(
          isActive ? Icons.check_circle_outline : Icons.error_outline,
          color: isActive ? Colors.green : Colors.orange,
        ),
        title: Text(
          isActive ? 'Premium Plan Active' : 'Subscription Required',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.green.shade800 : Colors.orange.shade800,
          ),
        ),
        subtitle: Text(
          isActive ? 'You have full access to AI tools & Tax Pot.' : 'Unlock AI Quoting and advanced features.',
        ),
        trailing: isActive ? null : const Icon(Icons.chevron_right),
        onTap: isActive ? null : () => context.go('/profile'),
      ),
    );
  }
}

class _DashboardNav extends StatelessWidget {
  const _DashboardNav();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    int index = 0;
    if (location.startsWith('/marketplace')) index = 1;
    if (location.startsWith('/jobs')) index = 2;
    if (location.startsWith('/tax-pot')) index = 3;

    return BottomNavigationBar(
      currentIndex: index,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.brandPrimary,
      unselectedItemColor: Colors.grey,
      onTap: (i) {
        switch (i) {
          case 0: context.go('/dashboard'); break;
          case 1: context.go('/marketplace'); break;
          case 2: context.go('/jobs'); break;
          case 3: context.go('/tax-pot'); break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Find'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Jobs'),
        BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Tax Pot'),
      ],
    );
  }
}