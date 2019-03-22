import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:mogicians_manual/data/list_items.dart';


Future<List<ListItem>> parseTextItems(String fileName) async {
    List<ListItem> results = [];
    String rawData = await rootBundle.loadString('assets/data/$fileName.json');
    List<dynamic> sections = json.decode(rawData);
    for (Map<String, dynamic> section in sections) {
        String title = section['title'];
        results.add(HeaderItem(title));

        for (Map<String, dynamic> item in section['items'])
            results.add(TextItem.fromJson(item));
    }
    results.add(FooterItem());
    return results;
}