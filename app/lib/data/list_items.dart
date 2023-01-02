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
  bool isExpanded = false;

  TextItem(this.title, this.body);

  TextItem.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        body = json['body'];
}

// A ListItem that contains image data with a title and an image
class ImageItem implements ListItem {
  final String title;
  final String src;

  ImageItem(this.title, this.src);

  ImageItem.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        src = json['src'];

  String get path => 'assets/images/$src';
}

// A ListItem that contains music data with a title and source file
class MusicItem implements ListItem {
  final String title;
  final String src;

  AudioStatus status = AudioStatus.STOPPED;

  MusicItem(this.title, this.src);

  MusicItem.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        src = json['src'];

  String get path => 'assets/audio/$src';
}

// A ListItem that contains document data with a title and source file
class DocumentItem implements ListItem {
  final String title;
  final String src;

  DocumentItem(this.title, this.src);

  DocumentItem.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        src = json['src'];

  String get path => 'assets/pdf/$src';
}

enum AudioStatus { STOPPED, RESUMED, PAUSED }

// A ListItem that serves as a footer
class FooterItem implements ListItem {}
