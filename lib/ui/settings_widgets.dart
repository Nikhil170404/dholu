import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'widgets.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection(this.title, this.children, {super.key});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DSpace.section),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: DText.caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        DCard(
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(indent: 16),
                children[i],
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: ListTile(
      minTileHeight: 60,
      title: Text(title, style: DText.bodyStrong),
      subtitle: subtitle == null ? null : Text(subtitle!, style: DText.caption),
      trailing: Switch(value: value, onChanged: onChanged),
      onTap: onChanged == null ? null : () => onChanged!(!value),
    ),
  );
}

class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon,
    required this.onTap,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 60,
    leading: icon == null ? null : IconTile(icon!),
    title: Text(title, style: DText.bodyStrong),
    subtitle: subtitle == null ? null : Text(subtitle!, style: DText.caption),
    trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

/// Secret / text field with an explicit Save button (keys never auto-save half typed).
class SaveField extends StatefulWidget {
  const SaveField({
    super.key,
    required this.label,
    required this.initial,
    required this.onSave,
    required this.saveLabel,
    this.obscure = false,
    this.hint,
  });
  final String label;
  final String initial;
  final String? hint;
  final bool obscure;
  final String saveLabel;
  final Future<void> Function(String) onSave;
  @override
  State<SaveField> createState() => _SaveFieldState();
}

class _SaveFieldState extends State<SaveField> {
  late final _c = TextEditingController(text: widget.initial);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _c,
            obscureText: widget.obscure,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        DButton(
          label: widget.saveLabel,
          tint: true,
          expand: false,
          onPressed: () => widget.onSave(_c.text.trim()),
        ),
      ],
    ),
  );
}
