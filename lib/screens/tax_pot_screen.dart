import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import '../providers/auth_providers.dart';
import '../providers/data_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class TaxPotScreen extends ConsumerStatefulWidget {
  const TaxPotScreen({super.key});

  @override
  ConsumerState<TaxPotScreen> createState() => _TaxPotScreenState();
}

class _TaxPotScreenState extends ConsumerState<TaxPotScreen> {
  final _supabase = Supabase.instance.client;

  Future<void> _updateTaxRate(double rate) async {
    final user = ref.read(userProvider);
    if (user == null) return;

    try {
      await _supabase
          .from('user_profiles')
          .update({'tax_rate': rate})
          .eq('id', user.id);
      ref.invalidate(userProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update tax rate: $e')),
        );
      }
    }
  }

  void _showAddIncomeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddIncomeModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final manualIncomeAsync = ref.watch(manualIncomeProvider);
    final privateJobsAsync = ref.watch(privateJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Pot'),
        actions: [
          IconButton(
            onPressed: _showAddIncomeModal,
            icon: const Icon(Icons.add_chart),
            tooltip: 'Add Manual Income',
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profile not found'));

          final privateJobs = privateJobsAsync.value ?? [];
          final manualIncome = manualIncomeAsync.value ?? [];

          // Calculate Paid PAI Jobs
          final paiEarnings = privateJobs
              .Where((j) => j.status == 'paid')
              .fold(0.0, (sum, item) => sum + item.total);

          // Calculate Manual Income
          final manualTotal = manualIncome.fold(0.0, (sum, item) => sum + item.amount);
          
          final totalEarnings = paiEarnings + manualTotal;
          final estimatedTax = (totalEarnings * (profile.taxRate / 100));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTaxOverview(totalEarnings, estimatedTax, profile.taxRate),
              const SizedBox(height: 24),
              _buildTaxRateSelector(profile.taxRate),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Income Log', style: Theme.of(context).textTheme.titleLarge),
                  TextButton.icon(
                    onPressed: _showAddIncomeModal,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Entry'),
                  ),
                ],
              ),
              const Divider(),
              ...manualIncome.map((income) => _ManualIncomeTile(income: income)),
              const SizedBox(height: 16),
              Text('PAI Platform Earnings', style: Theme.of(context).textTheme.titleSmall),
              const Divider(),
              ...privateJobs
                  .where((j) => j.status == 'paid')
                  .map((job) => ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(job.title),
                        subtitle: Text(job.customer ?? 'Client'),
                        trailing: Text(
                          '£${job.total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaxOverview(double total, double tax, double rate) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total Earnings',
                value: '£${total.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Tax Pot (${rate.toInt()}%)',
                value: '£${tax.toStringAsFixed(2)}',
                icon: Icons.savings,
                color: AppTheme.brandPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaxRateSelector(double currentRate) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tax Rate Setting',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose your estimated tax liability based on the UK standard rates for self-employment or CIS.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('CIS (20%)')),
                    selected: currentRate == 20.0,
                    onSelected: (val) if (val) _updateTaxRate(20.0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('General (30%)')),
                    selected: currentRate == 30.0,
                    onSelected: (val) if (val) _updateTaxRate(30.0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualIncomeTile extends StatelessWidget {
  final ManualIncome income;
  const _ManualIncomeTile({required this.income});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: Colors.blueGrey,
        child: Icon(Icons.history, color: Colors.white, size: 20),
      ),
      title: Text(income.customerName ?? 'External Client'),
      subtitle: Text('${income.date.day}/${income.date.month}/${income.date.year} • Tax Set-Aside: £${income.taxSetAside.toStringAsFixed(2)}'),
      trailing: Text(
        '+£${income.amount.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
      ),
    );
  }
}

class _AddIncomeModal extends ConsumerStatefulWidget {
  const _AddIncomeModal();

  @override
  ConsumerState<_AddIncomeModal> createState() => _AddIncomeModalState();
}

class _AddIncomeModalState extends ConsumerState<_AddIncomeModal> {
  final _amountController = TextEditingController();
  final _customerController = TextEditingController();
  bool _isSaving = false;

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isSaving = true);
    final profile = ref.read(userProfileProvider).value;
    final user = ref.read(userProvider);

    if (profile == null || user == null) return;

    final taxSetAside = amount * (profile.taxRate / 100);

    try {
      await Supabase.instance.client.from('manual_income').insert({
        'contractor_id': user.id,
        'amount': amount,
        'customer_name': _customerController.text.trim(),
        'date': DateTime.now().toIso8601String(),
        'tax_rate': profile.taxRate,
        'tax_set_aside': taxSetAside,
      });

      ref.invalidate(manualIncomeProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add External Income', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount (£)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.currency_pound),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customerController,
            decoration: const InputDecoration(
              labelText: 'Customer Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandPrimary,
                foregroundColor: Colors.white,
              ),
              child: _isSaving 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text('Add to Tax Pot'),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}