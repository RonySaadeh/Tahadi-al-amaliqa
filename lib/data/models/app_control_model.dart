import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Live app-wide operator state, stored at the single document
/// `appControl/status`. Every field here is set from the App Control panel
/// (`features/app_control/`) by an admin (`UserModel.isAdmin`) and read by
/// every signed-in *and* signed-out client — see `AppRoutes`'s redirect
/// logic in `app_router.dart`, which is what actually turns these flags into
/// a blocked screen, and `firestore.rules`, which is why this doc is
/// client-write-blocked: every write goes through a callable in
/// `functions/src/admin/appControl.ts` that checks `isAdmin` itself.
///
/// A missing document (nothing configured yet) parses to every flag off via
/// [AppControlModel.empty] — the app runs normally until an admin turns
/// something on.
class AppControlModel extends Equatable {
  const AppControlModel({
    this.maintenanceEnabled = false,
    this.maintenanceMessage = '',
    this.forceUpdateEnabled = false,
    this.minVersion = '',
    this.updateMessage = '',
    this.updateUrl = '',
    this.eventActive = false,
    this.eventTitle = '',
    this.eventDescription = '',
    this.eventEndsAt,
  });

  static const empty = AppControlModel();

  final bool maintenanceEnabled;
  final String maintenanceMessage;

  final bool forceUpdateEnabled;
  final String minVersion;
  final String updateMessage;
  final String updateUrl;

  final bool eventActive;
  final String eventTitle;
  final String eventDescription;

  /// Null means "no end date" — the event stays live until an admin turns
  /// it off by hand.
  final DateTime? eventEndsAt;

  /// Whether the limited-time event banner should currently be shown: the
  /// toggle is on, and (if an end time was set) it hasn't passed yet. A
  /// stale event with a past [eventEndsAt] simply stops showing on its own
  /// without an admin having to remember to flip [eventActive] back off.
  bool get isEventLive => eventActive && (eventEndsAt == null || eventEndsAt!.isAfter(DateTime.now()));

  factory AppControlModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return AppControlModel.empty;

    final maintenance = data['maintenance'] as Map<String, dynamic>? ?? const {};
    final update = data['update'] as Map<String, dynamic>? ?? const {};
    final event = data['event'] as Map<String, dynamic>? ?? const {};

    return AppControlModel(
      maintenanceEnabled: maintenance['enabled'] as bool? ?? false,
      maintenanceMessage: maintenance['message'] as String? ?? '',
      forceUpdateEnabled: update['enabled'] as bool? ?? false,
      minVersion: update['minVersion'] as String? ?? '',
      updateMessage: update['message'] as String? ?? '',
      updateUrl: update['url'] as String? ?? '',
      eventActive: event['active'] as bool? ?? false,
      eventTitle: event['title'] as String? ?? '',
      eventDescription: event['description'] as String? ?? '',
      eventEndsAt: (event['endsAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [
    maintenanceEnabled,
    maintenanceMessage,
    forceUpdateEnabled,
    minVersion,
    updateMessage,
    updateUrl,
    eventActive,
    eventTitle,
    eventDescription,
    eventEndsAt,
  ];
}
