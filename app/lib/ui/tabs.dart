import 'package:flutter/material.dart';

import 'package:scoped_model/scoped_model.dart';

import 'package:mogicians_manual/ui/list_tiles.dart';
import 'package:mogicians_manual/data/list_items.dart';
import 'package:mogicians_manual/data/models.dart';

class TabShuo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<TabShuoModel>(
      builder: (context, child, model) =>
        ListView.builder(
            key: PageStorageKey<String>("tab_shuo"),
            itemCount: model.items.length,
            itemBuilder: (context, index) {
              final item = model.items[index];
              if (item is HeaderItem) {
                return HeaderTile(item);
              } else if (item is TextItem) {
                return TextTile(item);
              } else if (item is FooterItem) {
                return FooterTile();
              }
            }
        ),
    );
  }
}

class TabXue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<TabXueModel>(
      builder: (context, child, model) =>
          ListView.builder(
              key: PageStorageKey<String>("tab_xue"),
              itemCount: model.items.length,
              itemBuilder: (context, index) {
                final item = model.items[index];
                if (item is HeaderItem) {
                  return HeaderTile(item);
                } else if (item is TextItem) {
                  return TextTile(item);
                } else if (item is FooterItem) {
                  return FooterTile();
                }
              }
          ),
    );
  }
}
