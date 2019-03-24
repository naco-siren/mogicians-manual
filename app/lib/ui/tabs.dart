import 'package:flutter/material.dart';

import 'package:scoped_model/scoped_model.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:mogicians_manual/main.dart';
import 'package:mogicians_manual/ui/list_tiles.dart';
import 'package:mogicians_manual/data/list_items.dart';
import 'package:mogicians_manual/data/models.dart';

abstract class BaseTab extends StatelessWidget {
  final int colSizeTablet = 5;
  final int colSizePhone = 3;

  Widget _itemBuilder(ListItem item) {
    if (item is HeaderItem) {
      return HeaderTile(item);
    } else if (item is FooterItem) {
      return FooterTile();
    } else {
      throw Exception("Unknown ListItem type!");
    }
  }

  Widget _textItemBuilder(ListItem item) {
    if (item is TextItem) {
      return TextTile(item);
    } else {
      return _itemBuilder(item);
    }
  }

  Widget _imageItemBuilder(ListItem item, bool isTablet) {
    if (item is ImageItem) {
      return ImageTile(item, isTablet);
    } else {
      return _itemBuilder(item);
    }
  }
}

class TabShuo extends BaseTab {
  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<TabShuoModel>(
      builder: (context, child, model) =>
        ListView.builder(
            key: PageStorageKey<String>("tab_shuo"),
            itemCount: model.items.length,
            itemBuilder: (context, index) => _textItemBuilder(model.items[index]),
        ),
    );
  }
}

class TabXue extends BaseTab {
  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<TabXueModel>(
      builder: (context, child, model) =>
          ListView.builder(
              key: PageStorageKey<String>("tab_xue"),
              itemCount: model.items.length,
              itemBuilder: (context, index) => _textItemBuilder(model.items[index]),
          ),
    );
  }
}

class TabDou extends BaseTab {
  @override
  Widget build(BuildContext context) {
    final isTablet = isTabletLayout(context);
    final crossAxisCount = isTablet ? colSizeTablet : colSizePhone;

    return ScopedModelDescendant<TabDouModel>(
      builder: (context, child, model) =>
        StaggeredGridView.countBuilder(
          key: PageStorageKey<String>("tab_dou"),
          crossAxisCount: crossAxisCount,
          itemCount: model.items.length,
          itemBuilder: (BuildContext context, int index) =>
              _imageItemBuilder(model.items[index], isTablet),
          staggeredTileBuilder: (int index) {
            final item = model.items[index];
            if (item is HeaderItem || item is FooterItem) {
              return StaggeredTile.extent(crossAxisCount, 60);
            } else {
              return StaggeredTile.fit(1);
            }
          },
          mainAxisSpacing: 0, // isTablet ? spacingTablet : spacingPhone,
          crossAxisSpacing: 0, // isTablet ? spacingTablet : spacingPhone,
        )
    );
  }
}