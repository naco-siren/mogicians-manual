import 'package:scoped_model/scoped_model.dart';

import 'package:mogicians_manual/data/list_items.dart';
import 'package:mogicians_manual/data/data_importer.dart';

class TabModel extends Model {
  final List<ListItem> _items = [];

  bool _hasLoaded = false;

  List<ListItem> get items => List.unmodifiable(_items);

  /// Loads json assets into model.
  Future<void> loadData() async {
    if (!_hasLoaded) {
      List<ListItem> loadedItems = await parseItems();
      _items.addAll(loadedItems);
      _hasLoaded = true;
      notifyListeners();
    }
  }
}
