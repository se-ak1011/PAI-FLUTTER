import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/app_models.dart';
import '../providers/data_providers.dart';
import '../theme/app_theme.dart';

class InvoiceScreen extends ConsumerWidget {
  final String jobId;

  const InvoiceScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privateJobsAsync = ref.watch(privateJobsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareInvoice(ref),
          ),
        ],
      ),
      body: privateJobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (jobs) {
          final job = jobs.firstWhere(
            (j) => j.id == jobId,
            orElse: () => throw Exception('Job not found'),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _InvoiceDocument(job: job),
                const SizedBox(height: 24),
                if (job.status == 'invoiced')
                  ElevatedButton.icon(
                    onPressed: () {
                      // Handled via Stripe Connect in job_detail or separate payment flow
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.payment),
                    label: const Text('PAY NOW'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _shareInvoice(WidgetRef ref) {
    final jobs = ref.read(privateJobsProvider).value;
    final job = jobs?.firstWhere((j) => j.id == jobId);
    if (job == null) return;

    final String text = '''
PAI INVOICE: ${job.title}
Status: ${job.status.toUpperCase()}
Customer: ${job.customer ?? 'N/A'}

Labour: £${job.labour.toStringAsFixed(2)}
Materials: £${job.materials.toStringAsFixed(2)}
VAT: £${job.vat.toStringAsFixed(2)}
TOTAL DUE: £${job.total.toStringAsFixed(2)}

Generated via PAI Platform
''';
    SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Invoice for ${job.title}',
      ),
    );
  }
}

class _InvoiceDocument extends StatelessWidget {
  final PrivateJob job;

  const _InvoiceDocument({required this.job});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '£');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _getStatusColor(job.status), width: 8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'INVOICE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                _StatusBadge(status: job.status),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BILL TO', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(job.customer ?? 'Guest Customer', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('DATE', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(DateFormat('dd MMM yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Divider(),
            _InvoiceRow(label: 'Description', value: 'Amount', isHeader: true),
            const Divider(),
            _InvoiceRow(label: 'Labour Costs ${job.actualHours != null ? "(${job.actualHours} hrs)" : ""}', value: currencyFormat.format(job.labour)),
            _InvoiceRow(label: 'Materials & Equipment', value: currencyFormat.format(job.materials)),
            const Divider(),
            const SizedBox(height: 16),
            _InvoiceRow(label: 'Subtotal', value: currencyFormat.format(job.labour + job.materials)),
            _InvoiceRow(label: 'VAT', value: currencyFormat.format(job.vat)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              color: Colors.grey[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL DUE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    currencyFormat.format(job.total),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.brandPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            Center(
              child: Text(
                'Thank you for your business!',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid': return Colors.green;
      case 'invoiced': return Colors.blue;
      case 'accepted': return Colors.orange;
      default: return Colors.grey;
    }
  }
}

class _InvoiceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHeader;

  const _InvoiceRow({required this.label, required this.value, this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, fontSize: isHeader ? 14 : 15))),
          Text(value, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, fontSize: isHeader ? 14 : 15)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    if (status == 'paid') color = Colors.green;
    if (status == 'invoiced') color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}