import 'package:flutter/material.dart';

import 'package:pdfx/pdfx.dart';

import 'package:mogicians_manual/data/list_items.dart';
import 'package:mogicians_manual/utils/share_helper.dart';

class DocumentViewer extends StatefulWidget {
  const DocumentViewer(this.item, {super.key});

  final DocumentItem item;

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  late final PdfControllerPinch _controller = PdfControllerPinch(
    document: PdfDocument.openAsset(widget.item.path),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => shareDocument(widget.item),
          ),
        ],
        title: Text(widget.item.title),
      ),
      body: PdfViewPinch(
        controller: _controller,
        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) => const Center(
            child: SizedBox(
              height: 80.0,
              width: 80.0,
              child: CircularProgressIndicator(),
            ),
          ),
          pageLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, error) => Center(child: Text(error.toString())),
        ),
      ),
    );
  }
}
