import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import '../providers/auth_providers.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  
  double _taxRate = 20.0;
  final List<String> _selectedTrades = [];
  bool _isLoading = false;

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
    _businessNameController.dispose();
    _cityController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(userProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final updates = {
        'id': user.id,
        'business_name': _businessNameController.text.trim(),
        'city': _cityController.text.trim(),
        'trades': _selectedTrades,
        'tax_rate': _taxRate,
        'hourly_rate': double.tryParse(_hourlyRateController.text) ?? 0,
        'onboarding_complete': true,
        'subscription_status': 'free_trial',
      };

      await Supabase.instance.client
          .from('user_profiles')
          .upsert(updates);

      // Invalidate the profile provider so the app state updates
      ref.invalidate(userProfileProvider);

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.maybeWhen(
      data: (profile) {
        final isContractor = profile?.accountType == AccountType.contractor || 
                             profile?.accountType == AccountType.both;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Complete Your Profile'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to PAI',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tell us a bit more about your business to get started.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(
                      labelText: 'Business Name',
                      hintText: 'e.g. Smith & Sons Plumbing',
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Field required' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City / Region',
                      hintText: 'e.g. London',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  if (isContractor) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Your Trades',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: _tradeOptions.map((trade) {
                        final isSelected = _selectedTrades.contains(trade);
                        return FilterChip(
                          label: Text(trade),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTrades.add(trade);
                              } else {
                                _selectedTrades.remove(trade);
                              }
                            });
                          },
                          selectedColor: AppTheme.brandPrimary.withOpacity(0.2),
                          checkmarkColor: AppTheme.brandPrimary,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Financial Setup (UK Tax)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<double>(
                      value: _taxRate,
                      decoration: const InputDecoration(
                        labelText: 'Tax Status',
                        prefixIcon: Icon(Icons.pie_chart),
                      ),
                      items: const [
                        DropdownMenuItem(value: 20.0, child: Text('CIS (20%)')),
                        DropdownMenuItem(value: 30.0, child: Text('Self-Employed (30%)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _taxRate = val);
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _hourlyRateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Standard Hourly Rate (£)',
                        prefixIcon: Icon(Icons.timer),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'required';
                        if (double.tryParse(val) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Complete Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}