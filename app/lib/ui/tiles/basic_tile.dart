import 'package:flutter/material.dart';
import 'package:mogicians_manual/data/list_items.dart';

class HeaderTile extends StatelessWidget {
  const HeaderTile(this._item, {super.key});

  final HeaderItem _item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.titleMedium ?? const TextStyle();
    return Container(
      padding: const EdgeInsets.only(left: 18, top: 20, bottom: 8),
      child: Text(
        _item.heading,
        style: baseStyle.apply(
          color: HSLColor.fromColor(theme.colorScheme.secondary)
              .withLightness(0.6)
              .withSaturation(0.9)
              .toColor(),
          fontWeightDelta: 2,
        ),
      ),
    );
  }
}

class FooterTile extends StatelessWidget {
  const FooterTile({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(height: 64);
}
