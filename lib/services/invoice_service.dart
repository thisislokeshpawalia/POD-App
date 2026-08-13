import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;

import '../models/customer.dart';

class InvoiceService {
  /// Generates a branded invoice PDF and saves it
  /// inside the app's local documents directory.
  ///
  /// Returns the FULL PATH of the generated PDF.
  static Future<String> generateInvoicePdf({
    required Customer customer,
    required DateTime deliveryDate,
    List<String>? photoPaths,
    String? farmerFacePhotoPath,
    bool forceOverwrite = false,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final invoiceDirectory = Directory('${directory.path}/invoices');

      if (!await invoiceDirectory.exists()) {
        await invoiceDirectory.create(recursive: true);
      }

      final file = File('${invoiceDirectory.path}/invoice_${customer.id}.pdf');

      // If the file already exists (likely has the photo) and we aren't forcing an overwrite,
      // just return the existing file rather than generating a new one without the photo.
      if (file.existsSync() && !forceOverwrite && (photoPaths == null || photoPaths.isEmpty)) {
        return file.path;
      }

      // Pre-fetch images to support both local and remote paths
      final List<pw.MemoryImage> invoiceImages = [];
      if (photoPaths != null) {
        for (final path in photoPaths) {
          if (path.startsWith('http://') || path.startsWith('https://')) {
            try {
              final response = await http.get(Uri.parse(path));
              if (response.statusCode == 200) {
                invoiceImages.add(pw.MemoryImage(response.bodyBytes));
              }
            } catch (_) {}
          } else {
            final localFile = File(path);
            if (localFile.existsSync()) {
              invoiceImages.add(pw.MemoryImage(localFile.readAsBytesSync()));
            }
          }
        }
      }

      final pdf = pw.Document();

      // App Theme Colors (Matching a clean pet-care aesthetic)
      const primaryColor = PdfColor.fromInt(0xFF0A4A6F); // Dark Blue matching our previous design
      const secondaryColor = PdfColor.fromInt(0xFFEBF3FA); // Light Blue Tint
      const textColor = PdfColor.fromInt(0xFF333333);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            return [
              // ==================================================
                  // HEADER WITH BRANDING
                  // ==================================================
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: 'My',
                                  style: pw.TextStyle(
                                    fontSize: 32,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColor.fromHex('#296ebb'),
                                  ),
                                ),
                                pw.TextSpan(
                                  text: 'Animal\n',
                                  style: pw.TextStyle(
                                    fontSize: 32,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColor.fromHex('#52a632'),
                                  ),
                                ),
                                pw.TextSpan(
                                  text: 'Leading the Animal Tech Revolution',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColor.fromHex('#52a632'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 4),
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
                    pw.SizedBox(height: 8),
                    pw.UrlLink(
                      destination: customer.videoUrl!,
                      child: pw.Container(
                        width: 160,
                        height: 90,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.black,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                        ),
                        child: pw.Center(
                          child: pw.SvgImage(
                            svg: '<svg viewBox="0 0 24 24"><path fill="white" d="M8 5v14l11-7z"/></svg>',
                            width: 32,
                            height: 32,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Tap thumbnail to play video',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],

                  if (invoiceImages.isNotEmpty) ...[
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'Proof of Delivery Photos:',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: invoiceImages
                          .map((img) => pw.Image(
                                img,
                                height: 200,
                                fit: pw.BoxFit.contain,
                                alignment: pw.Alignment.centerLeft,
                              ))
                          .toList(),
                    ),
                  ],

                  if (farmerFacePhotoPath != null && File(farmerFacePhotoPath).existsSync()) ...[
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'Farmer Face Verification:',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Image(
                      pw.MemoryImage(File(farmerFacePhotoPath).readAsBytesSync()),
                      height: 200,
                      fit: pw.BoxFit.contain,
                      alignment: pw.Alignment.centerLeft,
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
            ];
          },
        ),
      );

      // ============================================================
      // FILE STORAGE HANDLING
      // ============================================================
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
