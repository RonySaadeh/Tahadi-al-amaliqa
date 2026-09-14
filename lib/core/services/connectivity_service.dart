import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Whether the device actually has working internet access — not just a
/// wifi/cellular radio connected to *something*. `connectivity_plus` alone
/// only reports the radio's state, so a phone joined to a wifi network with
/// no real internet (a hotel captive portal, a router that's down) would
/// incorrectly read as "connected". Every check here follows up a positive
/// radio reading with a real DNS lookup to confirm the network actually
/// reaches the internet.
///
/// `dart:io`'s `InternetAddress.lookup` has no web implementation — it
/// throws `UnsupportedError` there, which isn't an `Exception`, so it isn't
/// caught below and used to leave the splash screen stuck forever on web
/// (the router waits on this stream to emit before it will navigate
/// anywhere). Browsers can't do a raw DNS lookup without going through an
/// actual network request anyway, so on web this just trusts the radio-level
/// reading from `connectivity_plus` instead of trying to verify it.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Emits the current real-connectivity state every time the OS reports a
  /// radio-level change, re-verified with a DNS lookup each time.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.asyncMap((results) => _resolve(results));
  }

  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    return _resolve(results);
  }

  Future<bool> _resolve(List<ConnectivityResult> results) async {
    if (results.every((r) => r == ConnectivityResult.none)) return false;
    if (kIsWeb) return true;
    return _hasRealInternet();
  }

  Future<bool> _hasRealInternet() async {
    try {
      final result = await InternetAddress.lookup(
        'firebase.google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on Exception {
      return false;
    }
  }
}
