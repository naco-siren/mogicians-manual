import 'package:flutter/material.dart';
import 'package:mogicians_manual/data/list_items.dart';
import 'package:mogicians_manual/ui/details/document_viewer.dart';

class DocumentTile extends StatelessWidget {
  DocumentTile(this.item) : super(key: ObjectKey(item));

  final DocumentItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: const BeveledRectangleBorder(),
      color: theme.cardColor,
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          _openDocumentViewer(context, item);
        },
        onLongPress: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(color: theme.dividerColor, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              child: Text(
                item.title,
                style: (theme.textTheme.bodyMedium ?? const TextStyle())
                    .copyWith(
                      color: theme.colorScheme.onSurface,
                      letterSpacing: 1.1,
                      fontSize: 18,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDocumentViewer(BuildContext context, DocumentItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DocumentViewer(item)),
    );
  }
}
