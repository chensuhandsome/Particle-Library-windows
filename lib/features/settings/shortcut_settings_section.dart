import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
import '../../app/settings_controller.dart';
import '../../app/shortcuts.dart';
import '../common/ui.dart';

/// Editable keyboard shortcuts. The defaults are supplied by [AppShortcuts];
/// a user override is persisted per command in [AppSettings.shortcuts].
class ShortcutSettingsSection extends StatelessWidget {
  const ShortcutSettingsSection({
    super.key,
    required this.settings,
    required this.strings,
  });

  final SettingsController settings;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final anyCustom = AppShortcutCommand.values.any(settings.shortcutIsCustom);
    return SectionCard(
      title: strings.settingsShortcuts,
      trailing: anyCustom
          ? TextButton(
              onPressed: () => settings.resetAllShortcuts(),
              child: Text(strings.settingsShortcutResetAll),
            )
          : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rows = <Widget>[
            for (final command in AppShortcutCommand.values)
              _ShortcutRow(
                command: command,
                settings: settings,
                strings: strings,
                onEdit: () => _edit(context, command),
              ),
          ];
          final twoColumns = constraints.maxWidth >= 560;
          final list = twoColumns
              ? Column(
                  children: [
                    for (var i = 0; i < rows.length; i += 2)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: rows[i]),
                          const SizedBox(width: Insets.l),
                          Expanded(
                            child: i + 1 < rows.length
                                ? rows[i + 1]
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                  ],
                )
              : Column(children: rows);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              list,
              const SizedBox(height: Insets.s),
              Text(
                strings.settingsShortcutsHint,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: palette.textSecondary),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(BuildContext context, AppShortcutCommand command) async {
    final current = settings.shortcutBindings(command);
    final result = await showDialog<_ShortcutEdit>(
      context: context,
      builder: (dialogContext) => _ShortcutRecorderDialog(
        commandLabel: strings.shortcutCommandLabel(command),
        initial: current.isEmpty ? null : current.first,
        strings: strings,
      ),
    );
    if (result == null || !context.mounted) return;
    if (result.clear) {
      await settings.setShortcut(command, null);
      return;
    }
    final binding = result.binding;
    if (binding == null) return;
    for (final other in AppShortcutCommand.values) {
      if (other == command) continue;
      if (settings
          .shortcutBindings(other)
          .any((candidate) => candidate == binding)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.settingsShortcutConflict(
                strings.shortcutCommandLabel(other),
              ),
            ),
          ),
        );
        return;
      }
    }
    await settings.setShortcut(command, binding);
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.command,
    required this.settings,
    required this.strings,
    required this.onEdit,
  });

  final AppShortcutCommand command;
  final SettingsController settings;
  final AppStrings strings;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final bindings = settings.shortcutBindings(command);
    final isCustom = settings.shortcutIsCustom(command);
    final label = bindings.isEmpty
        ? strings.settingsShortcutNotSet
        : bindings.first.label();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              strings.shortcutCommandLabel(command),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: Text(
              label,
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          IconButton(
            tooltip: strings.settingsShortcutReset,
            onPressed: isCustom ? () => settings.resetShortcut(command) : null,
            icon: const Icon(Icons.restart_alt, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ShortcutEdit {
  const _ShortcutEdit({this.binding, this.clear = false});

  final AppShortcutBinding? binding;
  final bool clear;
}

class _ShortcutRecorderDialog extends StatefulWidget {
  const _ShortcutRecorderDialog({
    required this.commandLabel,
    required this.initial,
    required this.strings,
  });

  final String commandLabel;
  final AppShortcutBinding? initial;
  final AppStrings strings;

  @override
  State<_ShortcutRecorderDialog> createState() =>
      _ShortcutRecorderDialogState();
}

class _ShortcutRecorderDialogState extends State<_ShortcutRecorderDialog> {
  AppShortcutBinding? _draft;
  String? _error;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.handled;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    if (_isModifier(key)) return KeyEventResult.handled;
    final keyboard = HardwareKeyboard.instance;
    final binding = AppShortcutBinding(
      keyId: key.keyId,
      meta: keyboard.isMetaPressed,
      control: keyboard.isControlPressed,
      alt: keyboard.isAltPressed,
      shift: keyboard.isShiftPressed,
    );
    setState(() {
      _draft = binding.hasModifier ? binding : null;
      _error = binding.hasModifier
          ? null
          : widget.strings.settingsShortcutNeedsModifier;
    });
    return KeyEventResult.handled;
  }

  bool _isModifier(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.metaLeft ||
      key == LogicalKeyboardKey.metaRight ||
      key == LogicalKeyboardKey.controlLeft ||
      key == LogicalKeyboardKey.controlRight ||
      key == LogicalKeyboardKey.altLeft ||
      key == LogicalKeyboardKey.altRight ||
      key == LogicalKeyboardKey.shiftLeft ||
      key == LogicalKeyboardKey.shiftRight ||
      key == LogicalKeyboardKey.capsLock;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AlertDialog(
      title: Text(widget.strings.settingsShortcutRecorderTitle),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.commandLabel,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: Insets.s),
            Focus(
              autofocus: true,
              onKeyEvent: _onKey,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.m,
                  vertical: Insets.l,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _error == null ? palette.divider : palette.error,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _draft?.label() ??
                          widget.strings.settingsShortcutRecorderHint,
                      textAlign: TextAlign.center,
                      style: _draft == null
                          ? Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: palette.textSecondary)
                          : Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: Insets.s),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: palette.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(const _ShortcutEdit(clear: true)),
          child: Text(widget.strings.settingsShortcutClear),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.strings.commonCancel),
        ),
        FilledButton(
          onPressed: _draft == null || _error != null
              ? null
              : () => Navigator.of(context).pop(_ShortcutEdit(binding: _draft)),
          child: Text(widget.strings.commonSave),
        ),
      ],
    );
  }
}
