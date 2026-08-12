import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../models/delivery_log.dart';
import '../services/invoice_service.dart';

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
              title: 'Proof of Delivery Photos',
              children: [
                if (deliveryLog.photoPaths != null && deliveryLog.photoPaths!.isNotEmpty)
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: deliveryLog.photoPaths!.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(File(deliveryLog.photoPaths![index])),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
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
                GestureDetector(
                  onTap: () async {
                    if (deliveryLog.videoPath != null) {
                      try {
                        await OpenFilex.open(deliveryLog.videoPath!);
                      } catch (e) {
                        debugPrint("Error opening video: $e");
                      }
                    }
                  },
                  child: Container(
                    height: 80,
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          deliveryLog.videoPath != null
                              ? Icons.play_circle_fill
                              : Icons.videocam_off,
                          color: deliveryLog.videoPath != null
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade400,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            deliveryLog.videoPath != null
                                ? 'Tap to play video proof'
                                : 'No video uploaded',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: deliveryLog.videoPath != null ? Colors.black87 : Colors.grey,
                              fontWeight: deliveryLog.videoPath != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final path = await InvoiceService.generateInvoicePdf(
                    customer: deliveryLog.customer,
                    deliveryDate: deliveryLog.timestamp,
                    photoPaths: deliveryLog.photoPaths,
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
            const SizedBox(height: 12),
            OutlinedButton(
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