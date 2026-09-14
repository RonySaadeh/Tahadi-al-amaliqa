import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../data/models/app_control_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_router.dart';
import '../app_control_controller.dart';

/// The admin-only screen behind `AppRoutes.appControl` — see
/// `features/app_control/README.md` for the feature overview and how to
/// become an admin. Reachable from the Profile settings drawer, but only
/// when `isAppAdminProvider` is true; nothing here is a bottom-nav tab.
///
/// Four independent sections, each a `Save`/`Send` away from a callable in
/// `functions/src/admin/appControl.ts`. The form seeds its controllers once
/// from the first live snapshot of `appControl/status` (see [_seeded]) and
/// then ignores further live updates while this screen is open — otherwise
/// an admin's own save (which round-trips through the stream) would fight
/// whatever they're mid-typing in a different section.
class AppControlScreen extends ConsumerStatefulWidget {
  const AppControlScreen({super.key});

  @override
  ConsumerState<AppControlScreen> createState() => _AppControlScreenState();
}

class _AppControlScreenState extends ConsumerState<AppControlScreen> {
  bool _seeded = false;

  bool _maintenanceEnabled = false;
  final _maintenanceMessageController = TextEditingController();

  bool _updateEnabled = false;
  final _minVersionController = TextEditingController();
  final _updateMessageController = TextEditingController();
  final _updateUrlController = TextEditingController();

  bool _eventActive = false;
  final _eventTitleController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  DateTime? _eventEndsAt;

  final _notificationTitleController = TextEditingController();
  final _notificationMessageController = TextEditingController();

  bool _savingMaintenance = false;
  bool _savingUpdate = false;
  bool _savingEvent = false;
  bool _sendingNotification = false;

  @override
  void dispose() {
    _maintenanceMessageController.dispose();
    _minVersionController.dispose();
    _updateMessageController.dispose();
    _updateUrlController.dispose();
    _eventTitleController.dispose();
    _eventDescriptionController.dispose();
    _notificationTitleController.dispose();
    _notificationMessageController.dispose();
    super.dispose();
  }

  void _seedFrom(AppControlModel appControl) {
    _maintenanceEnabled = appControl.maintenanceEnabled;
    _maintenanceMessageController.text = appControl.maintenanceMessage;
    _updateEnabled = appControl.forceUpdateEnabled;
    _minVersionController.text = appControl.minVersion;
    _updateMessageController.text = appControl.updateMessage;
    _updateUrlController.text = appControl.updateUrl;
    _eventActive = appControl.eventActive;
    _eventTitleController.text = appControl.eventTitle;
    _eventDescriptionController.text = appControl.eventDescription;
    _eventEndsAt = appControl.eventEndsAt;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveMaintenance() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _savingMaintenance = true);
    try {
      await ref
          .read(appControlControllerProvider)
          .setMaintenanceMode(enabled: _maintenanceEnabled, message: _maintenanceMessageController.text.trim());
      _showSnackBar(l10n.appControlSaved);
    } catch (_) {
      _showSnackBar(l10n.commonError);
    } finally {
      if (mounted) setState(() => _savingMaintenance = false);
    }
  }

  Future<void> _saveUpdate() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _savingUpdate = true);
    try {
      await ref
          .read(appControlControllerProvider)
          .setForceUpdate(
            enabled: _updateEnabled,
            minVersion: _minVersionController.text.trim(),
            message: _updateMessageController.text.trim(),
            updateUrl: _updateUrlController.text.trim(),
          );
      _showSnackBar(l10n.appControlSaved);
    } catch (_) {
      _showSnackBar(l10n.commonError);
    } finally {
      if (mounted) setState(() => _savingUpdate = false);
    }
  }

  Future<void> _saveEvent() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _savingEvent = true);
    try {
      await ref
          .read(appControlControllerProvider)
          .setLimitedEvent(
            active: _eventActive,
            title: _eventTitleController.text.trim(),
            description: _eventDescriptionController.text.trim(),
            endsAt: _eventEndsAt,
          );
      _showSnackBar(l10n.appControlSaved);
    } catch (_) {
      _showSnackBar(l10n.commonError);
    } finally {
      if (mounted) setState(() => _savingEvent = false);
    }
  }

  Future<void> _sendNotification() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _notificationTitleController.text.trim();
    final message = _notificationMessageController.text.trim();
    if (title.isEmpty || message.isEmpty) return;

    setState(() => _sendingNotification = true);
    try {
      await ref.read(appControlControllerProvider).sendGlobalNotification(title: title, message: message);
      _notificationTitleController.clear();
      _notificationMessageController.clear();
      _showSnackBar(l10n.appControlNotificationSent);
    } catch (_) {
      _showSnackBar(l10n.commonError);
    } finally {
      if (mounted) setState(() => _sendingNotification = false);
    }
  }

  Future<void> _pickEventEndDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _eventEndsAt ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eventEndsAt ?? now),
    );
    if (time == null) return;

    setState(() {
      _eventEndsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final appControlAsync = ref.watch(appControlProvider);

    // Belt-and-suspenders: the only path into this screen (the Profile
    // drawer) already hides itself for a non-admin, but this also covers a
    // deep link or a stale bookmark — bounce out rather than show a form
    // whose Save/Send buttons would just fail server-side anyway.
    if (!ref.watch(isAppAdminProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.home);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    appControlAsync.whenData((appControl) {
      if (_seeded) return;
      _seeded = true;
      // Deferred a frame: seeding text controllers during build would try to
      // call setState-adjacent work (TextEditingController mutation is fine,
      // but this keeps the pattern identical to NotificationsScreen's
      // one-shot post-load side effect for consistency).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _seedFrom(appControl));
      });
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appControlTitle)),
      body: appControlAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.commonError)),
        data: (_) => ResponsiveCenter(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(l10n.appControlSubtitle, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),

              _SectionCard(
                title: l10n.appControlMaintenanceSection,
                hint: l10n.appControlMaintenanceHint,
                icon: Icons.construction_rounded,
                enabled: _maintenanceEnabled,
                onEnabledChanged: (v) => setState(() => _maintenanceEnabled = v),
                saving: _savingMaintenance,
                onSave: _saveMaintenance,
                l10n: l10n,
                children: [
                  TextField(
                    controller: _maintenanceMessageController,
                    maxLines: 2,
                    decoration: InputDecoration(labelText: l10n.appControlMaintenanceMessageLabel),
                  ),
                ],
              ),

              _SectionCard(
                title: l10n.appControlUpdateSection,
                hint: l10n.appControlUpdateHint,
                icon: Icons.system_update_rounded,
                enabled: _updateEnabled,
                onEnabledChanged: (v) => setState(() => _updateEnabled = v),
                saving: _savingUpdate,
                onSave: _saveUpdate,
                l10n: l10n,
                children: [
                  TextField(
                    controller: _minVersionController,
                    decoration: InputDecoration(
                      labelText: l10n.appControlUpdateMinVersionLabel,
                      hintText: l10n.appControlUpdateMinVersionHint,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _updateMessageController,
                    maxLines: 2,
                    decoration: InputDecoration(labelText: l10n.appControlUpdateMessageLabel),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _updateUrlController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(labelText: l10n.appControlUpdateUrlLabel),
                  ),
                ],
              ),

              _SectionCard(
                title: l10n.appControlEventSection,
                hint: l10n.appControlEventHint,
                icon: Icons.celebration_rounded,
                enabled: _eventActive,
                onEnabledChanged: (v) => setState(() => _eventActive = v),
                saving: _savingEvent,
                onSave: _saveEvent,
                l10n: l10n,
                children: [
                  TextField(
                    controller: _eventTitleController,
                    decoration: InputDecoration(labelText: l10n.appControlEventTitleLabel),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _eventDescriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(labelText: l10n.appControlEventDescriptionLabel),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _eventEndsAt == null
                              ? l10n.appControlEventNoEndDate
                              : Formatters.dateTime(_eventEndsAt!, locale: locale),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      if (_eventEndsAt != null)
                        TextButton(
                          onPressed: () => setState(() => _eventEndsAt = null),
                          child: Text(l10n.appControlEventClearEndDate),
                        ),
                      TextButton(
                        onPressed: _pickEventEndDate,
                        child: Text(l10n.appControlEventPickDate),
                      ),
                    ],
                  ),
                ],
              ),

              _SectionCard(
                title: l10n.appControlNotificationSection,
                hint: l10n.appControlNotificationHint,
                icon: Icons.campaign_rounded,
                saving: _sendingNotification,
                onSave: _sendNotification,
                saveLabel: l10n.appControlNotificationSend,
                l10n: l10n,
                children: [
                  TextField(
                    controller: _notificationTitleController,
                    decoration: InputDecoration(labelText: l10n.appControlNotificationTitleLabel),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _notificationMessageController,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: l10n.appControlNotificationMessageLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One toggle-and-form block. [enabled]/[onEnabledChanged] are omitted for
/// the "Send Global Notification" section, which is a one-off action rather
/// than a persisted on/off state — see its `Save`-less [saveLabel] override.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.hint,
    required this.icon,
    required this.saving,
    required this.onSave,
    required this.l10n,
    required this.children,
    this.enabled,
    this.onEnabledChanged,
    this.saveLabel,
  });

  final String title;
  final String hint;
  final IconData icon;
  final bool? enabled;
  final ValueChanged<bool>? onEnabledChanged;
  final bool saving;
  final VoidCallback onSave;
  final AppLocalizations l10n;
  final List<Widget> children;
  final String? saveLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              if (enabled != null && onEnabledChanged != null)
                Switch(value: enabled!, onChanged: onEnabledChanged),
            ],
          ),
          Text(hint, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          ...children,
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              onPressed: saving ? null : onSave,
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(saveLabel ?? l10n.commonSave),
            ),
          ),
        ],
      ),
    );
  }
}
