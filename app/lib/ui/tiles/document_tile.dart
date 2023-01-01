import 'package:flutter/material.dart';
import 'package:mogicians_manual/data/list_items.dart';

class DocumentTile extends StatelessWidget {
  DocumentTile(this.item);

  final DocumentItem item;

  @override
  Widget build(BuildContext context) => Card(
      key: ObjectKey(item),
      shape: BeveledRectangleBorder(),
      color: Theme.of(context).cardColor,
      elevation: 2,
      margin: EdgeInsets.all(0),
      child: InkWell(
          onTap: () { /* TODO: navigate to PDF viewer */ },
          onLongPress: () {},
          child:  Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                color: Theme.of(context).dialogBackgroundColor,
                height: 1,
              ),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.bodyText2.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 1.1,
                        fontSize: 18
                    ),
                  )
              )
            ],
          )),
      );
}
