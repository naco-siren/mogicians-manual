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
}

class TabGenModel extends TabModel {
  @override
  String get dataJsonFilename => 'gen';

  @override
  ItemParser get parseItems => parseDocumentItems;
}
