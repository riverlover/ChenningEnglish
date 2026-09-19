import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/chenning_theme.dart';

Color roleColor(String role) {
  switch (role) {
    case 'prefix':
      return ChenningColors.prefix;
    case 'suffix':
      return ChenningColors.suffix;
    default:
      return ChenningColors.root;
  }
}

class BlockChip extends StatelessWidget {
  const BlockChip({
    super.key,
    required this.text,
    required this.role,
    this.large = false,
    this.onTap,
  });

  final String text;
  final String role;
  final bool large;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = roleColor(role);
    final chip = Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Rubik',
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: large ? 28 : 18,
        ),
      ),
    );
    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: chip,
      ),
    );
  }
}

class BlocksRow extends StatelessWidget {
  const BlocksRow({
    super.key,
    required this.blocks,
    this.large = false,
    this.onBlockTap,
  });

  final List<WordBlock> blocks;
  final bool large;
  final ValueChanged<WordBlock>? onBlockTap;

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (final b in blocks)
          BlockChip(
            text: b.text,
            role: b.role,
            large: large,
            onTap: onBlockTap == null ? null : () => onBlockTap!(b),
          ),
      ],
    );
  }
}

class SpeakButton extends StatelessWidget {
  const SpeakButton({super.key, required this.onPressed, this.label = '听'});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.volume_up_rounded),
      label: Text(label),
    );
  }
}
