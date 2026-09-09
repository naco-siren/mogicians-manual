import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mogicians_manual/data/list_items.dart';
import 'package:mogicians_manual/service/toast_util.dart';

class TextTile extends StatefulWidget {
  const TextTile(this.item, this.isNovember, {super.key});

  final TextItem item;
  final bool isNovember;

  @override
  State<TextTile> createState() => _TextTileState();
}

class _TextTileState extends State<TextTile> with ToastUtil {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Card(
      shape: const BeveledRectangleBorder(),
      color: Theme.of(context).cardColor,
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          setState(() {
            item.isExpanded = !item.isExpanded;
          });
        },
        onLongPress: () {
          if (item.isExpanded) {
            _copyToClipboard(context, item.title, item.body);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _generateChildren(),
        ),
      ),
    );
  }

  List<Widget> _generateChildren() {
    final item = widget.item;
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium ?? const TextStyle();

    final contents = <Widget>[];
    contents.add(
      Text(
        item.title,
        style: bodyStyle.copyWith(
          color: theme.colorScheme.onSurface,
          letterSpacing: 1.1,
          fontSize: 18,
        ),
      ),
    );
    if (item.isExpanded) {
      contents.add(const SizedBox(height: 8));
      contents.add(
        Text(
          item.body,
          style: bodyStyle.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1.02,
            height: 1.05,
            fontSize: 16,
          ),
        ),
      );
    }

    final children = <Widget>[];

    children.add(Container(color: theme.dividerColor, height: 1));

    children.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: contents,
        ),
      ),
    );

    return children;
  }

  Future<void> _copyToClipboard(
    BuildContext context,
    String title,
    String body,
  ) async {
    final content = '【$title】\n$body';
    var message = '已复制到剪贴板';
    if (widget.isNovember) message += '。阿门……';
    await Clipboard.setData(ClipboardData(text: content));
    if (!context.mounted) return;
    showToast(context, message);
  }
}
