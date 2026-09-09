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

  /// Height of the full-width header/footer rows between the image grids.
  static const double _bannerExtent = 60;

  @override
  Widget build(BuildContext context) {
    final isTablet = isTabletLayout(context);
    final crossAxisCount = isTablet
        ? BaseTab.colSizeTablet
        : BaseTab.colSizePhone;

    return ScopedModelDescendant<TabDouModel>(
      builder: (context, child, model) {
        final sections = _DouSection.split(model.items);
        // One list item per section. Each section's images are laid out by a
        // plain (non-sliver) StaggeredGrid: several SliverMasonryGrids in one
        // CustomScrollView throw the viewport back to the top once the first
        // grid is scrolled out of view (flutter_staggered_grid_view #265,
        // #299, #335), so the masonry must not be a sliver.
        return Scrollbar(
          child: ListView.builder(
            key: const PageStorageKey<String>('tab_dou'),
            itemCount: sections.length,
            itemBuilder: (context, index) =>
                _buildSection(sections[index], crossAxisCount, isTablet),
          ),
        );
      },
    );
  }

  Widget _buildSection(_DouSection section, int crossAxisCount, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: _bannerExtent, child: _itemBuilder(section.banner)),
        if (section.images.isNotEmpty)
          StaggeredGrid.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
            children: [
              for (final image in section.images)
                StaggeredGridTile.fit(
                  crossAxisCellCount: 1,
                  child: ImageTile(image, isTablet, isNovember),
                ),
            ],
          ),
      ],
    );
  }
}

/// A header (or the trailing footer) followed by the images under it.
class _DouSection {
  _DouSection(this.banner);

  final ListItem banner;
  final List<ImageItem> images = [];

  /// Groups the flat item list: every non-image item starts a new section.
  static List<_DouSection> split(List<ListItem> items) {
    final sections = <_DouSection>[];
    for (final item in items) {
      if (item is ImageItem) {
        if (sections.isEmpty) sections.add(_DouSection(FooterItem()));
        sections.last.images.add(item);
      } else {
        sections.add(_DouSection(item));
      }
    }
    return sections;
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
