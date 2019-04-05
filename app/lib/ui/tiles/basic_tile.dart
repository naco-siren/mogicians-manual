import 'package:flutter/material.dart';
import 'package:mogicians_manual/data/list_items.dart';

class HeaderTile extends StatelessWidget {
  HeaderTile(this._item);

  final HeaderItem _item;

  @override
  Widget build(BuildContext context) => Container(
      padding: EdgeInsets.only(left: 18, top: 20, bottom: 8),
      child: Text(
        _item.heading,
        style: Theme.of(context).textTheme.title.apply(
          color: Colors.yellowAccent.shade700,
          fontWeightDelta: 1,
        ),
      ));
}

class FooterTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(height: 64);
}
