// The base class for the different types of items the List can contain
abstract class ListItem {}

// A ListItem that contains a header
class HeaderItem implements ListItem {
  final String heading;

  HeaderItem(this.heading);
}

// A ListItem that contains text data with a title and a body
class TextItem implements ListItem {
  final String title;
  final String body;

  TextItem(this.title, this.body);

  TextItem.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        body = json['body'];

  Map<String, dynamic> toJson() =>
      {
        'title': title,
        'body': body,
      };
}

// A ListItem that serves as a footer
class FooterItem implements ListItem {}
