import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';

class DButton extends StatelessWidget {
  const DButton({super.key, required this.label, this.onPressed, this.tint = false, this.dark = false, this.expand = true, this.icon});
  final String label;
  final VoidCallback? onPressed;

  /// Secondary style (accent tint).
  final bool tint;

  /// On a dark card: white fill, ink text.
  final bool dark;
  final bool expand;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? Colors.white : (tint ? DColors.accentTint : DColors.accent);
    final fg = dark ? DColors.ink : (tint ? DColors.accentDark : Colors.white);
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Flexible(child: Text(label, style: DText.button.copyWith(color: fg), overflow: TextOverflow.ellipsis)),
      ],
    );
    final button = Material(
      color: bg,
      borderRadius: BorderRadius.circular(DRadius.button),
      child: InkWell(
        borderRadius: BorderRadius.circular(DRadius.button),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: DSpace.minTouch + 4, minWidth: DSpace.minTouch),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Center(widthFactor: expand ? null : 1, child: child),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class DTextButton extends StatelessWidget {
  const DTextButton(this.label, {super.key, this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
            minimumSize: const Size(DSpace.minTouch, DSpace.minTouch),
            foregroundColor: DColors.textSecondary),
        child: Text(label, style: DText.button),
      );
}

/// Neutral 40dp icon tile used in lists.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.size = 40, this.color = DColors.iconTile, this.iconColor = DColors.ink});
  final IconData icon;
  final double size;
  final Color color;
  final Color iconColor;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(DRadius.tile)),
        child: Icon(icon, size: size * 0.5, color: iconColor),
      );
}

class DCard extends StatelessWidget {
  const DCard({super.key, required this.child, this.padding = EdgeInsets.zero, this.color = DColors.card});
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(DRadius.card),
          border: color == DColors.card ? Border.all(color: DColors.border) : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}

/// Pulsing urgent dot (red only for urgent).
class UrgentDot extends StatelessWidget {
  const UrgentDot({super.key, this.size = 8});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: DColors.urgentDot, shape: BoxShape.circle),
      );
}
