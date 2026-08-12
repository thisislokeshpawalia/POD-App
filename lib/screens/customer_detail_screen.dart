import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import '../models/customer.dart';
import '../services/invoice_service.dart';
import 'order_completion_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;
  final void Function(String customerId) onCustomerDelivered;

  const CustomerDetailScreen({
    super.key,
    required this.customer,
    required this.onCustomerDelivered,
  });

  Future<void> _launchPhone(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: customer.phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  Future<void> _launchMaps(BuildContext context) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${customer.latitude},${customer.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDelivered = customer.isDelivered;

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar + status
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: colorScheme.primary,
                    backgroundImage: (customer.photoUrls != null && customer.photoUrls!.isNotEmpty)
                        ? NetworkImage(customer.photoUrls!.first)
                        : null,
                    child: (customer.photoUrls != null && customer.photoUrls!.isNotEmpty)
                        ? null
                        : Text(
                            customer.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDelivered
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isDelivered ? 'Delivered' : 'Pending',
                      style: TextStyle(
                        color: isDelivered
                            ? colorScheme.primary
                            : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Info card
            _SectionCard(
              title: 'Farmer Details',
              children: [
                _DetailRow(icon: Icons.badge_outlined, label: 'ID', value: customer.id),
                _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: customer.phone),
                _DetailRow(icon: Icons.location_on_outlined, label: 'Address', value: customer.fullAddress),
                _DetailRow(
                  icon: Icons.pin_drop_outlined,
                  label: 'Coordinates',
                  value:
                  '${customer.latitude.toStringAsFixed(4)}, ${customer.longitude.toStringAsFixed(4)}',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Items card
            _SectionCard(
              title: 'Items to Deliver',
              children: customer.items
                  .map(
                    (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 18, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 10),
                      Text(item.displayText,
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              )
                  .toList(),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchPhone(context),
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchMaps(context),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Navigate'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (!isDelivered)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderCompletionScreen(
                        customer: customer,
                        onCustomerDelivered: onCustomerDelivered,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Complete Delivery'),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle,
                        color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Delivery Completed',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (isDelivered) ...[
              const SizedBox(height: 12),
              if (customer.videoUrl != null && customer.videoUrl!.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(customer.videoUrl!);
                    try {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      debugPrint("Could not launch video: $e");
                    }
                  },
                  icon: const Icon(Icons.play_circle_fill, color: Colors.red),
                  label: const Text('Play Delivery Proof Video'),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final path = await InvoiceService.generateInvoicePdf(
                      customer: customer,
                      deliveryDate: DateTime.now(), // Fallback for past deliveries
                    );
                    await OpenFilex.open(path);
                  } catch (e) {
                    debugPrint("Error generating invoice: $e");
                  }
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generate & View Invoice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A4A6F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ─── Detail Row ───────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}