import 'package:scoped_model/scoped_model.dart';

import 'package:mogicians_manual/data/list_items.dart';
import 'package:mogicians_manual/data/data_importer.dart';

abstract class TabModel extends Model {
  final List<ListItem> _items = [];

  TabModel() {
    loadData();
  }

  Future<List<ListItem>> Function(String) _parseItemFunction;
  String _dataJsonFilename;

  List<ListItem> get items => List.unmodifiable(_items);

  /// Loads json assets into model asynchronously.
  Future<void> loadData() async {
    if (items.isEmpty) {
      List<ListItem> loadedItems = await _parseItemFunction(_dataJsonFilename);
      _items.addAll(loadedItems);
      notifyListeners();
    }
  }
}

class TabShuoModel extends TabModel {
  String _dataJsonFilename = "shuo";
  Future<List<ListItem>> Function(String) _parseItemFunction = parseTextItems;

  TabShuoModel() : super();
}

class TabXueModel extends TabModel {
  String _dataJsonFilename = "xue";
  Future<List<ListItem>> Function(String) _parseItemFunction = parseTextItems;

  TabXueModel() : super();
}

class TabDouModel extends TabModel {
  String _dataJsonFilename = "dou";
  Future<List<ListItem>> Function(String) _parseItemFunction = parseImageItems;

  TabDouModel() : super();
}

class TabChangModel extends TabModel {
  String _dataJsonFilename = "chang";
  Future<List<ListItem>> Function(String) _parseItemFunction = parseMusicItems;

  TabChangModel() : super();

  int _curIdx = -1;

  int get curIdx => _curIdx;

  set curIdx(int value) {
    if (value == curIdx || value < 0 || value >= items.length) return;

    for (var item in items) {
      if (item is MusicItem) item.status = AudioStatus.STOPPED;
    }

    final curItem = items[value];
    if (curItem is MusicItem) {
      curItem.status = AudioStatus.RESUMED;
    }

    _curIdx = value;
    notifyListeners();
  }
}

class TabGenModel extends TabModel {
  String _dataJsonFilename = "gen";
  Future<List<ListItem>> Function(String) _parseItemFunction = parseDocumentItems;

  TabGenModel() : super();
}
