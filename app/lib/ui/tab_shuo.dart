import 'package:flutter/material.dart';

import 'widgets/list_item.dart';

class TabShuo extends StatelessWidget {

  final items = List<ListItem>.generate(
    12,
        (i) => i % 6 == 0
        ? HeadingItem("语录 $i")
        : TextItem("三个代表 $i", "重要思想 $i"),
  );

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item is HeadingItem) {
            return HeadingTile(item);
          } else if (item is TextItem) {
            return TextTile(item);
          }
        }
    );
  }
}