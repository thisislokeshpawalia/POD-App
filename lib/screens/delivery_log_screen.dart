import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/delivery_log.dart';

class DeliveryLogScreen extends StatelessWidget {
  final DeliveryLog deliveryLog;
  final VoidCallback onBackToHome;

  const DeliveryLogScreen({
    super.key,
    required this.deliveryLog,
    required this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTime =
    DateFormat('dd MMM yyyy, hh:mm a').format(deliveryLog.timestamp);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proof of Delivery'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF2E7D32),
              size: 72,
            ),
            const SizedBox(height: 12),
            const Text(
              'Order Completed Successfully',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 24),
            _InfoCard(
              title: 'Customer',
              children: [
                _InfoRow(label: 'Name', value: deliveryLog.customer.name),
                _InfoRow(label: 'Farmer ID', value: deliveryLog.customer.id),
                _InfoRow(label: 'Delivered At', value: formattedTime),
                _InfoRow(
                  label: 'GPS Coordinates',
                  value:
                  '${deliveryLog.latitude.toStringAsFixed(6)}, ${deliveryLog.longitude.toStringAsFixed(6)}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Items Delivered',
              children: deliveryLog.items
                  .map(
                    (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check,
                          size: 18, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 8),
                      Text(item.displayText),
                    ],
                  ),
                ),
              )
                  .toList(),
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Proof of Delivery Photo',
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: deliveryLog.photoPath != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(deliveryLog.photoPath!),
                      fit: BoxFit.cover,
                    ),
                  )
                      : Center(
                    child: Text(
                      'No photo',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Proof of Delivery Video',
              children: [
                Container(
                  height: 80,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        deliveryLog.videoPath != null
                            ? Icons.video_file
                            : Icons.videocam_off,
                        color: deliveryLog.videoPath != null
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          deliveryLog.videoPath != null
                              ? deliveryLog.videoPath!.split('/').last
                              : 'No video uploaded',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onBackToHome,
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.children,
  });

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
                fontWeight: FontWeight.w600,
                fontSize: 15,
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

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}