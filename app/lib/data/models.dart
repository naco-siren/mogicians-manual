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

  /// Loads json assets into model.
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
