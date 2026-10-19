import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show ValueChanged;

import 'package:in_app_purchase/in_app_purchase.dart';

/// Apple-only optional Supporter purchase.
///
/// The purchase unlocks a cosmetic badge; it never gates PDG data, notes,
/// references, PDFs or search.
class SupporterStore {
  SupporterStore({required this.onEntitlement});

  static const String productId = 'io.github.fkguo.particlelibrary.supporter';

  static bool get isSupportedPlatform => Platform.isIOS || Platform.isMacOS;

  final ValueChanged<bool> onEntitlement;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<void> initialize() async {
    if (!isSupportedPlatform) return;
    _subscription ??= _iap.purchaseStream.listen(_onPurchases);
  }

  Future<ProductDetails?> product() async {
    if (!isSupportedPlatform) return null;
    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) return null;
    return response.productDetails.first;
  }

  Future<void> buy(ProductDetails product) async {
    if (!isSupportedPlatform) return;
    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> restore() async {
    if (!isSupportedPlatform) return;
    await _iap.restorePurchases();
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.productID != productId) continue;
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          onEntitlement(true);
          if (purchase.pendingCompletePurchase) {
            unawaited(_iap.completePurchase(purchase));
          }
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          break;
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
