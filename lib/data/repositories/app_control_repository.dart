import '../../core/services/cloud_functions_service.dart';
import '../../core/services/firestore_service.dart';
import '../models/app_control_model.dart';

/// Reads the live `appControl/status` singleton and, for an admin, writes it
/// through the callables in `functions/src/admin/appControl.ts`. Never
/// writes to Firestore directly — `firestore.rules` blocks it, the same way
/// every other trusted write in this app goes through a Cloud Function.
class AppControlRepository {
  AppControlRepository({FirestoreService? firestoreService, CloudFunctionsService? cloudFunctions})
    : _firestore = firestoreService ?? FirestoreService(),
      _cloudFunctions = cloudFunctions ?? CloudFunctionsService();

  final FirestoreService _firestore;
  final CloudFunctionsService _cloudFunctions;

  Stream<AppControlModel> watchAppControl() {
    return _firestore.appControlStatus.snapshots().map(AppControlModel.fromFirestore);
  }

  Future<void> setMaintenanceMode({required bool enabled, required String message}) {
    return _cloudFunctions.setMaintenanceMode(enabled: enabled, message: message);
  }

  Future<void> setForceUpdate({
    required bool enabled,
    required String minVersion,
    required String message,
    required String updateUrl,
  }) {
    return _cloudFunctions.setForceUpdate(
      enabled: enabled,
      minVersion: minVersion,
      message: message,
      updateUrl: updateUrl,
    );
  }

  Future<void> setLimitedEvent({
    required bool active,
    required String title,
    required String description,
    DateTime? endsAt,
  }) {
    return _cloudFunctions.setLimitedEvent(
      active: active,
      title: title,
      description: description,
      endsAt: endsAt,
    );
  }

  Future<void> sendGlobalNotification({required String title, required String message}) {
    return _cloudFunctions.sendGlobalNotification(title: title, message: message);
  }

  Future<Map<String, dynamic>> cleanupResolvedNotifications() {
    return _cloudFunctions.cleanupResolvedNotifications();
  }
}
