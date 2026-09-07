import 'package:flutter/material.dart';

import 'package:scoped_model/scoped_model.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:mogicians_manual/main.dart';
import 'package:mogicians_manual/ui/tiles/basic_tile.dart';
import 'package:mogicians_manual/ui/tiles/text_tile.dart';
import 'package:mogicians_manual/ui/tiles/image_tile.dart';
import 'package:mogicians_manual/ui/tiles/music_tile.dart';
import 'package:mogicians_manual/ui/tiles/document_tile.dart';
import 'package:mogicians_manual/data/list_items.dart';
import 'package:mogicians_manual/data/models.dart';

typedef MusicItemTapCallback = void Function(int);

abstract class BaseTab extends StatelessWidget {
  const BaseTab(this.isNovember, {super.key});

  final bool isNovember;

  static const int colSizeTablet = 5;
  static const int colSizePhone = 3;

  Widget _itemBuilder(ListItem item) {
    if (item is HeaderItem) {
      return HeaderTile(item);
    } else if (item is FooterItem) {
      return const FooterTile();
    } else {
      throw Exception('Unknown ListItem type!');
    }
  }

  Widget _textItemBuilder(ListItem item) {
    if (item is TextItem) {
      return TextTile(item, isNovember);
    } else {
      return _itemBuilder(item);
    }
  }

  Widget _musicItemBuilder(ListItem item, int index, ItemTapCallback callback) {
    if (item is MusicItem) {
      return MusicTile(item, index, callback, isNovember);
    } else {
      return _itemBuilder(item);
    }
  }

  Widget _documentItemBuilder(ListItem item) {
    if (item is DocumentItem) {
      return DocumentTile(item);
    } else {
      return _itemBuilder(item);
    }
  }
}

class TabShuo extends BaseTab {
  const TabShuo(super.isNovember, {super.key});

  @override
  Widget build(BuildContext context) => ScopedModelDescendant<TabShuoModel>(
    builder: (context, child, model) => Scrollbar(
      child: ListView.builder(
        key: const PageStorageKey<String>('tab_shuo'),
        itemCount: model.items.length,
        itemBuilder: (context, index) => _textItemBuilder(model.items[index]),
      ),
    ),
  );
}

class TabXue extends BaseTab {
  const TabXue(super.isNovember, {super.key});

  @override
  Widget build(BuildContext context) => ScopedModelDescendant<TabXueModel>(
    builder: (context, child, model) => Scrollbar(
      child: ListView.builder(
        key: const PageStorageKey<String>('tab_xue'),
        itemCount: model.items.length,
        itemBuilder: (context, index) => _textItemBuilder(model.items[index]),
      ),
    ),
  );
}

class TabDou extends BaseTab {
  const TabDou(super.isNovember, {super.key});

  /// Height of the full-width header/footer rows inside the image grid.
  static const double _bannerExtent = 60;

  @override
  Widget build(BuildContext context) {
    final isTablet = isTabletLayout(context);
    final crossAxisCount = isTablet
        ? BaseTab.colSizeTablet
        : BaseTab.colSizePhone;

    return ScopedModelDescendant<TabDouModel>(
      builder: (context, child, model) => Scrollbar(
        child: CustomScrollView(
          key: const PageStorageKey<String>('tab_dou'),
          slivers: _buildSlivers(model.items, crossAxisCount, isTablet),
        ),
      ),
    );
  }

  /// Turns the flat item list into one sliver per section: a full-width
  /// header followed by a lazily built masonry grid of that section's images.
  List<Widget> _buildSlivers(
    List<ListItem> items,
    int crossAxisCount,
    bool isTablet,
  ) {
    final slivers = <Widget>[];
    var pendingImages = <ImageItem>[];

    void flushImages() {
      if (pendingImages.isEmpty) return;
      final images = pendingImages;
      pendingImages = <ImageItem>[];
      slivers.add(
        SliverMasonryGrid.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 0,
          crossAxisSpacing: 0,
          childCount: images.length,
          itemBuilder: (BuildContext context, int index) =>
              ImageTile(images[index], isTablet, isNovember),
        ),
      );
    }

    for (final item in items) {
      if (item is ImageItem) {
        pendingImages.add(item);
        continue;
      }
      flushImages();
      slivers.add(
        SliverToBoxAdapter(
          child: SizedBox(height: _bannerExtent, child: _itemBuilder(item)),
        ),
      );
    }
    flushImages();
    return slivers;
  }
}

class TabChang extends BaseTab {
  const TabChang(super.isNovember, this.onItemTap, {super.key});

  final MusicItemTapCallback onItemTap;

  @override
  Widget build(BuildContext context) => ScopedModelDescendant<TabChangModel>(
    builder: (context, child, model) => Scrollbar(
      child: ListView.builder(
        key: const PageStorageKey<String>('tab_chang'),
        itemCount: model.items.length,
        itemBuilder: (context, index) =>
            _musicItemBuilder(model.items[index], index, onItemTap),
      ),
    ),
  );
}

class TabGen extends BaseTab {
  const TabGen(super.isNovember, {super.key});

  @override
  Widget build(BuildContext context) => ScopedModelDescendant<TabGenModel>(
    builder: (context, child, model) => Scrollbar(
      child: ListView.builder(
        key: const PageStorageKey<String>('tab_gen'),
        itemCount: model.items.length,
        itemBuilder: (context, index) =>
            _documentItemBuilder(model.items[index]),
      ),
    ),
  );
}
