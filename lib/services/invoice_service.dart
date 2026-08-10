import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/customer.dart';

class InvoiceService {
  /// Generates a branded invoice PDF and saves it
  /// inside the app's local documents directory.
  ///
  /// Returns the FULL PATH of the generated PDF.
  static Future<String> generateInvoicePdf({
    required Customer customer,
    required DateTime deliveryDate,
  }) async {
    try {
      final pdf = pw.Document();

      // App Theme Colors (Matching a clean pet-care aesthetic)
      const primaryColor = PdfColor.fromInt(0xFF0A4A6F); // Dark Blue matching our previous design
      const secondaryColor = PdfColor.fromInt(0xFFEBF3FA); // Light Blue Tint
      const textColor = PdfColor.fromInt(0xFF333333);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // HEADER WITH BRANDING
                  // ==================================================
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'MyAnimal',
                            style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Your Trusted Pet Care Partner',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            'Sector 132, Noida (default)',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: const pw.BoxDecoration(
                          color: secondaryColor,
                          borderRadius: pw.BorderRadius.all(
                            pw.Radius.circular(4),
                          ),
                        ),
                        child: pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 20),
                  pw.Divider(color: primaryColor, thickness: 1.5),
                  pw.SizedBox(height: 15),

                  // ==================================================
                  // ORDER & CUSTOMER DETAILS SECTION
                  // ==================================================
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      // Customer Info
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Billed To:',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text('Name: ${customer.name}',
                                style: const pw.TextStyle(color: textColor)),
                            pw.Text('Phone: ${customer.phone}',
                                style: const pw.TextStyle(color: textColor)),
                            pw.Text('Address: ${customer.fullAddress}',
                                style: const pw.TextStyle(color: textColor)),
                          ],
                        ),
                      ),
                      // Order Info
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Order Details:',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text('Farmer ID: ${customer.id}',
                              style: const pw.TextStyle(color: textColor)),
                          pw.Text(
                            'Delivery Date: '
                                '${deliveryDate.day.toString().padLeft(2, '0')}/'
                                '${deliveryDate.month.toString().padLeft(2, '0')}/'
                                '${deliveryDate.year}',
                            style: const pw.TextStyle(color: textColor),
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 30),

                  // ==================================================
                  // PRODUCT TABLE
                  // ==================================================
                  pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColors.grey300,
                      width: 0.5,
                    ),
                    children: [
                      // HEADER ROW
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: secondaryColor,
                        ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Text(
                              'Product Description',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Text(
                              'Quantity',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      ),

                      // PRODUCT ROWS
                      for (var item in customer.items)
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Text(item.name,
                                  style: const pw.TextStyle(color: textColor)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Text('${item.quantity} ${item.unit}',
                                  textAlign: pw.TextAlign.center,
                                  style: const pw.TextStyle(color: textColor)),
                            ),
                          ],
                        ),
                    ],
                  ),

                  pw.SizedBox(height: 30),
                  
                  // ==================================================
                  // VIDEO PROOF
                  // ==================================================
                  if (customer.videoUrl != null && customer.videoUrl!.isNotEmpty) ...[
                    pw.Text(
                      'Proof of Delivery Video:',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.UrlLink(
                      destination: customer.videoUrl!,
                      child: pw.Text(
                        'Tap here to view the Delivery Proof Video',
                        style: const pw.TextStyle(
                          color: PdfColors.blue,
                          decoration: pw.TextDecoration.underline,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'URL: ${customer.videoUrl}',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],

                  pw.Spacer(),

                  // ==================================================
                  // FOOTER
                  // ==================================================
                  pw.Divider(color: PdfColors.grey400),
                  pw.SizedBox(height: 10),
                  pw.Center(
                    child: pw.Text(
                      'Thank you for your business! Give your pets the best care.',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // ============================================================
      // FILE STORAGE HANDLING
      // ============================================================
      final directory = await getApplicationDocumentsDirectory();
      final invoiceDirectory = Directory('${directory.path}/invoices');

      if (!await invoiceDirectory.exists()) {
        await invoiceDirectory.create(recursive: true);
      }

      final file = File('${invoiceDirectory.path}/invoice_${customer.id}.pdf');
      final pdfBytes = await pdf.save();

      await file.writeAsBytes(pdfBytes, flush: true);

      if (!await file.exists()) {
        throw Exception('Invoice file was not created.');
      }

      return file.path;
    } catch (e) {
      rethrow;
    }
  }
}
