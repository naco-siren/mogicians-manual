import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import 'package:mogicians_manual/data/list_items.dart';

typedef ItemConstructor = ListItem Function(Map<String, dynamic> item);

Future<List<ListItem>> parseListItems(
  String fileName,
  ItemConstructor itemConstructor,
) async {
  final results = <ListItem>[];
  // Decode on the main isolate: the JSON parse below runs there anyway, and
  // AssetBundle.loadString would otherwise hop to an isolate for files > 50 KB.
  final data = await rootBundle.load('assets/data/$fileName.json');
  final rawData = utf8.decode(Uint8List.sublistView(data));
  final sections = json.decode(rawData) as List<dynamic>;
  for (final section in sections.cast<Map<String, dynamic>>()) {
    results.add(HeaderItem(section['title'] as String));

    final items = section['items'] as List<dynamic>;
    for (final item in items.cast<Map<String, dynamic>>()) {
      results.add(itemConstructor(item));
    }
  }
  results.add(FooterItem());
  return results;
}

Future<List<ListItem>> parseTextItems(String fileName) =>
    parseListItems(fileName, TextItem.fromJson);

Future<List<ListItem>> parseImageItems(String fileName) =>
    parseListItems(fileName, ImageItem.fromJson);

Future<List<ListItem>> parseMusicItems(String fileName) =>
    parseListItems(fileName, MusicItem.fromJson);

Future<List<ListItem>> parseDocumentItems(String fileName) =>
    parseListItems(fileName, DocumentItem.fromJson);
