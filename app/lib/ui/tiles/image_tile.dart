import 'package:flutter/material.dart';
import 'package:mogicians_manual/data/image_filters.dart';
import 'package:mogicians_manual/data/list_items.dart';
import 'package:mogicians_manual/ui/details/image_viewer.dart';
import 'package:mogicians_manual/utils/share_helper.dart';

class ImageTile extends StatefulWidget {
  const ImageTile(this.item, this.isTablet, this.greyedOut, {super.key});

  final ImageItem item;
  final bool isTablet;
  final bool greyedOut;

  @override
  State<ImageTile> createState() => _ImageTileState();
}

const double paddingTablet = 8.0;
const double paddingPhone = 4.0;

class _ImageTileState extends State<ImageTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(widget.isTablet ? paddingTablet : paddingPhone),
      child: Card(
        shape: const BeveledRectangleBorder(),
        color: theme.cardColor,
        elevation: 2,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => _openImageViewer(),
          onLongPress: () => shareImage(widget.item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Text(
                  widget.item.title,
                  style: (theme.textTheme.bodySmall ?? const TextStyle())
                      .copyWith(
                        color: theme.colorScheme.onSurface,
                        fontSize: widget.isTablet ? 15 : 12,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              widget.greyedOut
                  ? ColorFiltered(
                      colorFilter: greyscale,
                      child: Image(image: AssetImage(widget.item.path)),
                    )
                  : Image(image: AssetImage(widget.item.path)),
            ],
          ),
        ),
      ),
    );
  }

  void _openImageViewer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewer(widget.item, widget.greyedOut),
      ),
    );
  }
}
