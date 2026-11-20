import 'package:flutter/foundation.dart';
import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';

/// Decides which IDFA reaches the iOS SDK.
class AdvertisingIdentifierGate {
  bool? _disableTrackingIds;
  ({String? identifier})? _heldIdentifier;

  /// Applies `disableTrackingIds` and passes on an identifier held before it.
  void init({required bool disableTrackingIds}) {
    _disableTrackingIds = disableTrackingIds;
    final heldIdentifier = _heldIdentifier;
    _heldIdentifier = null;
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    if (disableTrackingIds) {
      MindboxPlatform.instance.setAdvertisingIdentifier(null);
    } else if (heldIdentifier != null) {
      MindboxPlatform.instance
          .setAdvertisingIdentifier(heldIdentifier.identifier);
    }
  }

  /// Passes [identifier] on, or `null` when tracking ids are disabled; holds it until [init].
  void setAdvertisingIdentifier(String? identifier) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    final disableTrackingIds = _disableTrackingIds;
    if (disableTrackingIds == null) {
      _heldIdentifier = (identifier: identifier);
      return;
    }
    MindboxPlatform.instance
        .setAdvertisingIdentifier(disableTrackingIds ? null : identifier);
  }
}
