import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:mogicians_manual/data/list_items.dart';

Future<List<ListItem>> parseListItems(String fileName,
    ListItem Function(Map<String, dynamic> item) itemConstructor) async {

  List<ListItem> results = [];
  String rawData = await rootBundle.loadString('assets/data/$fileName.json');
  List<dynamic> sections = json.decode(rawData);
  for (Map<String, dynamic> section in sections) {
    String title = section['title'];
    results.add(HeaderItem(title));

    for (Map<String, dynamic> item in section['items'])
      results.add(itemConstructor(item));
  }
  results.add(FooterItem());
  return results;
}

Future<List<ListItem>> parseTextItems(String fileName) async =>
    parseListItems(fileName, (item) => TextItem.fromJson(item));

Future<List<ListItem>> parseImageItems(String fileName) async =>
    parseListItems(fileName, (item) => ImageItem.fromJson(item));

Future<List<ListItem>> parseMusicItems(String fileName) async =>
    parseListItems(fileName, (item) => MusicItem.fromJson(item));

Future<List<ListItem>> parseDocumentItems(String fileName) async =>
    parseListItems(fileName, (item) => DocumentItem.fromJson(item));
