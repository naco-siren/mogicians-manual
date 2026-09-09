import 'package:scoped_model/scoped_model.dart';

import 'package:mogicians_manual/data/list_items.dart';
import 'package:mogicians_manual/data/data_importer.dart';

typedef ItemParser = Future<List<ListItem>> Function(String fileName);

abstract class TabModel extends Model {
  final List<ListItem> _items = [];

  TabModel() {
    loadData();
  }

  /// Basename of the JSON file under `assets/data/` that backs this tab.
  String get dataJsonFilename;

  /// Parses that JSON file into the tab's list items.
  ItemParser get parseItems;

  List<ListItem> get items => List.unmodifiable(_items);

  /// Loads json assets into model asynchronously.
  Future<void> loadData() async {
    if (_items.isEmpty) {
      final loadedItems = await parseItems(dataJsonFilename);
      _items.addAll(loadedItems);
      notifyListeners();
    }
  }
}

class TabShuoModel extends TabModel {
  @override
  String get dataJsonFilename => 'shuo';

  @override
  ItemParser get parseItems => parseTextItems;
}

class TabXueModel extends TabModel {
  @override
  String get dataJsonFilename => 'xue';

  @override
  ItemParser get parseItems => parseTextItems;
}

class TabDouModel extends TabModel {
  @override
  String get dataJsonFilename => 'dou';

  @override
  ItemParser get parseItems => parseImageItems;
}

class TabChangModel extends TabModel {
  @override
  String get dataJsonFilename => 'chang';

  @override
  ItemParser get parseItems => parseMusicItems;

  int _curIdx = -1;

  int get curIdx => _curIdx;

  /// Every playable track of this tab in list order.
  List<MusicItem> get musicItems =>
      _items.whereType<MusicItem>().toList(growable: false);

  /// Highlights the track whose asset path is [path], e.g. after the media
  /// notification skipped to another one. Unknown paths are ignored.
  void selectByPath(String path) {
    final index = _items.indexWhere(
      (item) => item is MusicItem && item.path == path,
    );
    if (index >= 0) curIdx = index;
  }

  set curIdx(int value) {
    if (value == curIdx || value < 0 || value >= _items.length) return;

    for (final item in _items) {
      if (item is MusicItem) item.status = AudioStatus.stopped;
    }

    final curItem = _items[value];
    if (curItem is MusicItem) {
      curItem.status = AudioStatus.resumed;
    }

    _curIdx = value;
    notifyListeners();
  }

  /// Mirrors playback changes that happened outside the tab (the media
  /// notification's play/pause/stop buttons) onto the current item.
  void syncPlayback({required bool playing, required bool stopped}) {
    if (_curIdx < 0) return;
    final item = _items[_curIdx];
    if (item is! MusicItem) return;

    final status = stopped
        ? AudioStatus.stopped
        : playing
        ? AudioStatus.resumed
        : AudioStatus.paused;
    if (item.status == status) return;

    item.status = status;
    if (stopped) _curIdx = -1;
    notifyListeners();
  }
}

class TabGenModel extends TabModel {
  @override
  String get dataJsonFilename => 'gen';

  @override
  ItemParser get parseItems => parseDocumentItems;
}
