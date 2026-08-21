import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';

class PdfViewerScreen extends StatelessWidget {
  final String path;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.path,
    this.title = 'Invoice',
  });

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        // Use standard Android public downloads directory
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!downloadsDir.existsSync()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir != null) {
        final fileName = path.split('/').last;
        final savedPath = '${downloadsDir.path}/$fileName';
        await File(path).copy(savedPath);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to Downloads: $fileName')),
          );
        }
      } else {
        throw Exception('Could not find downloads directory');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download PDF',
            onPressed: () => _downloadPdf(context),
          ),
        ],
      ),
      body: SfPdfViewer.file(File(path)),
    );
  }
}
