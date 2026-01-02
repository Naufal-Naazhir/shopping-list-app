// lib/services/iap_service.dart
import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:belanja_praktis/config/appwrite_db.dart';
import 'package:belanja_praktis/data/repositories/auth_repository.dart';
import 'package:belanja_praktis/main.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

// ID Produk untuk langganan
const String _monthlySubscriptionId = 'premium_monthly';
const String _yearlySubscriptionId = 'premium_yearly';
const List<String> _kProductIds = [
  _monthlySubscriptionId,
  _yearlySubscriptionId,
];

class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final Databases _databases = getIt<Databases>();
  final Account _account = getIt<Account>();

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  List<ProductDetails> _products = [];
  bool isAvailable = false;
  bool _isLoading = false;
  bool _initialized = false;

  // Notifier untuk update UI
  final ValueNotifier<List<ProductDetails>> productsNotifier = ValueNotifier(
    [],
  );
  final ValueNotifier<bool> isPremiumNotifier = ValueNotifier(false);
  final ValueNotifier<String> errorNotifier = ValueNotifier('');

  // Public getter
  List<ProductDetails> get products => _products;
  bool get isLoading => _isLoading;

  IapService() {
    initialize();
  }

  Future<void> initialize() async {
    try {
      if (_initialized) return;

      debugPrint('=== IAP SERVICE INITIALIZATION START ===');

      isAvailable = await _iap.isAvailable();
      if (!isAvailable) {
        errorNotifier.value = 'Pembayaran tidak tersedia di perangkat ini';
        debugPrint('IAP not available on this device');
        return;
      }

      debugPrint('IAP is available, setting up purchase stream...');

      // Inisialisasi stream pembelian SEBELUM restore
      await _purchaseSubscription?.cancel();
      _purchaseSubscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdate,
        onDone: () {
          debugPrint('Purchase stream done');
          _purchaseSubscription?.cancel();
        },
        onError: (error) {
          debugPrint('Purchase stream error: $error');
          errorNotifier.value = 'Error: $error';
        },
      );

      debugPrint('Purchase stream initialized');

      // Muat produk
      debugPrint('Loading products...');
      await loadProducts();

      // CRITICAL: Process any pending purchases first
      debugPrint('Checking for pending purchases...');
      await _processPendingPurchases();

      // Check active subscriptions from database
      debugPrint('Checking active subscriptions...');
      await _checkActiveSubscriptions();

      _initialized = true;
      debugPrint('=== IAP SERVICE INITIALIZATION COMPLETE ===');
    } catch (e) {
      _initialized = false;
      errorNotifier.value = 'Gagal menginisialisasi pembayaran: $e';
      debugPrint('IAP Init Error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  // Process any pending purchases that haven't been completed
  Future<void> _processPendingPurchases() async {
    try {
      debugPrint('=== PROCESSING PENDING PURCHASES ===');

      // Restore purchases - this will trigger the purchase stream for any active subscriptions
      debugPrint('Calling restorePurchases...');
      await _iap.restorePurchases();

      // Wait a bit for the purchase stream to process events
      await Future.delayed(const Duration(seconds: 2));

      debugPrint('=== PENDING PURCHASES PROCESSED ===');
    } catch (e) {
      debugPrint('Error processing pending purchases: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      // Don't throw - continue initialization even if this fails
    }
  }

  void dispose() {
    _purchaseSubscription?.cancel();
  }

  Future<void> loadProducts() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final available = await _iap.isAvailable();
      if (!available) {
        isAvailable = false;
        errorNotifier.value =
            'In-app purchases are not available on this device';
        return;
      }

      isAvailable = true;
      final response = await _iap.queryProductDetails(_kProductIds.toSet());

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
          'The following product IDs were not found: ${response.notFoundIDs}',
        );
      }

      _products = response.productDetails;
      productsNotifier.value = _products;

      // Debug print loaded products
      for (var product in _products) {
        debugPrint('Loaded product: ${product.id} - ${product.title}');
        debugPrint('Price: ${product.price}');
        debugPrint('Description: ${product.description}');
      }

      if (_products.isEmpty) {
        errorNotifier.value = 'No products available for purchase';
      }
    } catch (e) {
      errorNotifier.value = 'Failed to load products: $e';
      debugPrint('Error loading products: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Validates if a purchase is truly completed and ready to be processed
  bool _isPurchaseValid(PurchaseDetails purchase) {
    debugPrint('=== VALIDATING PURCHASE ===');
    debugPrint('Purchase ID: ${purchase.purchaseID}');
    debugPrint('Status: ${purchase.status}');
    debugPrint('Product ID: ${purchase.productID}');

    // Check if purchase has valid ID (null or empty means incomplete)
    if (purchase.purchaseID == null || purchase.purchaseID!.isEmpty) {
      debugPrint(
        '❌ VALIDATION FAILED: Purchase ID is null or empty - payment not completed',
      );
      debugPrint(
        'This usually means user did not complete the payment swipe/gesture',
      );
      return false;
    }

    // Check if purchase is in pending state
    if (purchase.status == PurchaseStatus.pending) {
      debugPrint('⏳ VALIDATION FAILED: Purchase is still pending');
      return false;
    }

    // Check if purchase has verification data
    if (purchase.verificationData.serverVerificationData.isEmpty) {
      debugPrint(
        '❌ VALIDATION FAILED: No verification data - purchase not completed',
      );
      debugPrint('User may have cancelled or not completed the payment');
      return false;
    }

    debugPrint('✅ VALIDATION PASSED: Purchase is valid and completed');
    return true;
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    debugPrint('=== PURCHASE UPDATE RECEIVED ===');
    debugPrint('Number of purchases: ${purchaseDetailsList.length}');

    for (final purchase in purchaseDetailsList) {
      debugPrint('--- Processing Purchase ---');
      debugPrint('Status: ${purchase.status}');
      debugPrint('Product ID: ${purchase.productID}');
      debugPrint('Purchase ID: ${purchase.purchaseID}');
      debugPrint('Error: ${purchase.error?.message}');
      debugPrint('Pending Complete: ${purchase.pendingCompletePurchase}');

      if (purchase.status == PurchaseStatus.pending) {
        debugPrint('Purchase is pending...');
        // Tampilkan indikator loading
      } else {
        if (purchase.status == PurchaseStatus.error) {
          debugPrint('Purchase ERROR: ${purchase.error?.message}');
          errorNotifier.value = 'Error pembelian: ${purchase.error?.message}';
        } else if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          debugPrint('Purchase status is SUCCESS/RESTORED - validating...');

          // CRITICAL: Validate purchase before processing
          if (_isPurchaseValid(purchase)) {
            debugPrint('✅ Purchase validated - calling verification...');
            await _verifyAndDeliverProduct(purchase);
          } else {
            debugPrint('❌ Purchase validation failed - NOT processing');
            debugPrint('User did not complete payment. Treating as cancelled.');
            errorNotifier.value =
                'Pembayaran dibatalkan atau belum selesai. Silakan coba lagi.';

            // Still complete the purchase to clear it from the queue
            if (purchase.pendingCompletePurchase) {
              debugPrint('Completing invalid purchase to clear queue...');
              await _iap.completePurchase(purchase);
            }
            continue; // Skip to next purchase
          }
        }

        if (purchase.pendingCompletePurchase) {
          debugPrint('Completing purchase in main handler...');
          await _iap.completePurchase(purchase);
        }
      }
    }
    debugPrint('=== PURCHASE UPDATE END ===');
  }

  Future<void> _verifyAndDeliverProduct(PurchaseDetails purchase) async {
    try {
      debugPrint('=== VERIFY AND DELIVER PRODUCT START ===');
      debugPrint('Purchase status: ${purchase.status}');
      debugPrint('Product ID: ${purchase.productID}');
      debugPrint('Purchase ID: ${purchase.purchaseID}');
      debugPrint(
        'Pending complete purchase: ${purchase.pendingCompletePurchase}',
      );

      // Update UI immediately to show premium status
      debugPrint('Setting isPremiumNotifier to true immediately...');
      isPremiumNotifier.value = true;

      // Update status premium di database
      debugPrint('Calling _updatePremiumStatus...');
      await _updatePremiumStatus(purchase.productID);

      debugPrint('_updatePremiumStatus completed successfully');

      // Tandai pembelian selesai
      if (purchase.pendingCompletePurchase) {
        debugPrint('Completing purchase...');
        await _iap.completePurchase(purchase);
        debugPrint('Purchase completed');
      }

      // Force refresh to ensure everything is in sync
      debugPrint('Force refreshing premium status...');
      await forceRefreshPremiumStatus();

      debugPrint('=== VERIFY AND DELIVER PRODUCT END ===');
    } catch (e) {
      debugPrint('=== VERIFY AND DELIVER PRODUCT ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      errorNotifier.value = 'Gagal memverifikasi pembelian: $e';

      // Even if there's an error, try to refresh status
      try {
        await _checkActiveSubscriptions();
      } catch (refreshError) {
        debugPrint('Failed to refresh after error: $refreshError');
      }

      rethrow;
    }
  }

  Future<bool> buyProduct(ProductDetails product) async {
    try {
      debugPrint('🛒 === BUY PRODUCT START ===');
      debugPrint('Product ID: ${product.id}');
      debugPrint('Product Title: ${product.title}');
      debugPrint('Product Price: ${product.price}');

      if (!isAvailable) {
        debugPrint('❌ IAP not available');
        errorNotifier.value = 'Pembayaran tidak tersedia di perangkat ini';
        return false;
      }

      // Pastikan produk sudah dimuat dengan benar
      if (_products.isEmpty) {
        debugPrint('⚠️ Products not loaded, loading now...');
        await loadProducts();
      }

      debugPrint('Platform: ${defaultTargetPlatform}');

      PurchaseParam purchaseParam;
      if (defaultTargetPlatform == TargetPlatform.android) {
        debugPrint('📱 Android platform detected');
        // --- LOGIC KHUSUS ANDROID ---
        if (product is! GooglePlayProductDetails) {
          debugPrint(
            '❌ Fatal: Produk bukan GooglePlayProductDetails. Tipe: ${product.runtimeType}',
          );
          errorNotifier.value = 'Tipe produk salah. Hubungi pengembang.';
          return false;
        }

        final googleProduct = product;

        // Debugging detail penawaran (Offers)
        debugPrint('--- GOOGLE PLAY PRODUCT DETAILS ---');
        debugPrint('ID: ${googleProduct.id}');
        debugPrint('Title: ${googleProduct.title}');
        debugPrint('OfferToken (Direct): ${googleProduct.offerToken}');
        debugPrint(
          'SubscriptionOfferDetails: ${googleProduct.productDetails.subscriptionOfferDetails}',
        );

        String? offerToken = googleProduct.offerToken;

        // Jika token kosong, coba cari manual di dalam detail penawaran
        if ((offerToken == null || offerToken.isEmpty) &&
            googleProduct.productDetails.subscriptionOfferDetails != null &&
            googleProduct.productDetails.subscriptionOfferDetails!.isNotEmpty) {
          // Ambil token dari penawaran pertama (Base Plan biasanya)
          // Menggunakan dynamic karena analyzer terkadang tidak mendeteksi getter offerToken
          final offerDetails =
              googleProduct.productDetails.subscriptionOfferDetails!.first
                  as dynamic;
          offerToken = offerDetails.offerToken as String?;
          debugPrint('OfferToken ditemukan manual: $offerToken');
        }

        if (offerToken == null || offerToken.isEmpty) {
          debugPrint('❌ FATAL: Offer token tetap kosong setelah pencarian.');
          errorNotifier.value =
              'Gagal memuat detail penawaran Google Play.\n\n'
              'Pastikan:\n'
              '1. Akun email di HP ini terdaftar di "License Testers" Console.\n'
              '2. Anda download aplikasi dari link Internal Test.\n'
              '3. Produk di Console berstatus ACTIVE.';
          return false;
        }

        purchaseParam = GooglePlayPurchaseParam(
          productDetails: product,
          applicationUserName: null,
          offerToken: offerToken, // Pastikan token ini terisi
        );

        debugPrint('✅ Purchase param created with offer token');
      } else {
        debugPrint('🍎 iOS/Other platform detected');
        // --- iOS / Lainnya ---
        purchaseParam = PurchaseParam(
          productDetails: product,
          applicationUserName: null,
        );
      }

      // Lakukan pembelian
      debugPrint('💳 Initiating purchase for ${product.id}...');
      debugPrint('⏳ Waiting for Google Play response...');

      if (product.id == _monthlySubscriptionId ||
          product.id == _yearlySubscriptionId) {
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
        debugPrint('✅ buyNonConsumable called successfully');
        debugPrint('⏳ Purchase stream should receive event soon...');
        return true;
      }

      debugPrint('❌ Product ID does not match subscription IDs');
      return false;
    } catch (e) {
      debugPrint('❌ Buy product error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      errorNotifier.value = 'Gagal melakukan pembelian: $e';
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      await _checkActiveSubscriptions();
    } catch (e) {
      errorNotifier.value = 'Gagal memulihkan pembelian: $e';
      debugPrint('Restore purchases error: $e');
      rethrow;
    }
  }

  // Internal method to check active subscriptions
  Future<void> _checkActiveSubscriptions() async {
    try {
      final user = await _account.get();

      // Look up document by UID first
      final response = await _databases.listDocuments(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.usersCollectionId,
        queries: [Query.equal('uid', user.$id)],
      );

      if (response.documents.isEmpty) {
        debugPrint(
          'User document not found for uid: ${user.$id} during subscription check',
        );
        isPremiumNotifier.value = false;
        return;
      }

      final document = response.documents.first;

      bool isPremium = document.data['isPremium'] ?? false;

      isPremiumNotifier.value = isPremium;
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      isPremiumNotifier.value = false;
    }
  }

  /// Helper method untuk membuat user document jika tidak ada
  Future<String> _createUserDocumentIfNotExists(models.User user) async {
    try {
      debugPrint('🔨 Attempting to create user document...');

      // Try to get existing document first
      try {
        final existingDoc = await _databases.getDocument(
          databaseId: AppwriteDB.databaseId,
          collectionId: AppwriteDB.usersCollectionId,
          documentId: user.$id,
        );
        debugPrint('✅ Document already exists: ${existingDoc.$id}');
        return existingDoc.$id;
      } catch (e) {
        debugPrint(
          'Document does not exist (confirmed by getDocument), creating new one...',
        );
      }

      // Create new user document
      final newUserData = {
        'uid': user.$id,
        'username': user.name.isEmpty ? 'User' : user.name,
        'email': user.email.isEmpty ? '' : user.email,
        'isPremium': false,
      };

      debugPrint('Creating new user document with data: $newUserData');

      final newDoc = await _databases.createDocument(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.usersCollectionId,
        documentId: user.$id,
        data: newUserData,
        permissions: [
          Permission.read(Role.user(user.$id)),
          Permission.update(Role.user(user.$id)),
        ],
      );

      debugPrint('✅ User document created successfully: ${newDoc.$id}');
      return newDoc.$id;
    } catch (e) {
      debugPrint('❌ Failed to create user document: $e');
      // RETHROW agar caller tahu kalau ini gagal
      throw Exception('Gagal membuat dokumen user baru: $e');
    }
  }

  Future<void> _updatePremiumStatus(String productId) async {
    try {
      debugPrint('=== UPDATE PREMIUM STATUS START ===');
      debugPrint('Product ID: $productId');

      final user = await _account.get();
      debugPrint('✅ User ID: ${user.$id}');
      debugPrint('✅ User Email: ${user.email}');

      // Cek status saat ini sebelum update
      debugPrint('📡 Searching for user document...');

      String documentId;
      try {
        // STRATEGI 1: Cari by UID
        final response = await _databases.listDocuments(
          databaseId: AppwriteDB.databaseId,
          collectionId: AppwriteDB.usersCollectionId,
          queries: [Query.equal('uid', user.$id)],
        );

        if (response.documents.isNotEmpty) {
          documentId = response.documents.first.$id;
          debugPrint('✅ Found document by UID query: $documentId');
        } else {
          debugPrint('⚠️ User document not found by uid query.');

          // STRATEGI 2: Cari by Email (Backup)
          // Berguna jika uid tidak tersimpan tapi email ada
          if (user.email.isNotEmpty) {
            debugPrint('Trying to find by email...');
            final emailResponse = await _databases.listDocuments(
              databaseId: AppwriteDB.databaseId,
              collectionId: AppwriteDB.usersCollectionId,
              queries: [Query.equal('email', user.email)],
            );

            if (emailResponse.documents.isNotEmpty) {
              documentId = emailResponse.documents.first.$id;
              debugPrint('✅ Found document by Email query: $documentId');

              // Optional: Update UID di dokumen ini agar next time ketemu via UID
              try {
                await _databases.updateDocument(
                  databaseId: AppwriteDB.databaseId,
                  collectionId: AppwriteDB.usersCollectionId,
                  documentId: documentId,
                  data: {'uid': user.$id},
                );
              } catch (_) {}
            } else {
              throw Exception('Not found by email');
            }
          } else {
            throw Exception('Email empty, cannot search by email');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Document search failed or returned empty: $e');

        // STRATEGI 3: Fallback ke Auth ID & Coba Create
        debugPrint('Trying to use Auth ID or Create New Document...');
        try {
          // _createUserDocumentIfNotExists sekarang akan me-return ID atau throw error
          documentId = await _createUserDocumentIfNotExists(user);
          debugPrint('✅ Using document ID from creation/check: $documentId');
        } catch (createError) {
          debugPrint('❌ Critical: Failed to find OR create document.');
          throw Exception(
            'Gagal mencari atau membuat data user di database. Error: $createError',
          );
        }
      }

      // Update dokumen pengguna di Appwrite
      debugPrint('💾 UPDATING DATABASE...');
      debugPrint('Database ID: ${AppwriteDB.databaseId}');
      debugPrint('Collection ID: ${AppwriteDB.usersCollectionId}');
      debugPrint('Document ID: $documentId');

      final updateData = {
        'isPremium': true, // ✅ Set premium status to true
      };

      debugPrint('Update data: $updateData');

      try {
        await _databases.updateDocument(
          databaseId: AppwriteDB.databaseId,
          collectionId: AppwriteDB.usersCollectionId,
          documentId: documentId,
          data: updateData,
        );

        debugPrint('✅✅✅ DATABASE UPDATE SUCCESS! ✅✅✅');
        debugPrint('Updated data: isPremium=true');
      } catch (updateError) {
        debugPrint('❌❌❌ DATABASE UPDATE FAILED! ❌❌❌');
        debugPrint('Error type: ${updateError.runtimeType}');
        debugPrint('Error message: $updateError');

        // Show error to user
        errorNotifier.value =
            'GAGAL UPDATE DATABASE!\n'
            'Error: $updateError\n\n'
            'Silakan screenshot dan hubungi developer.';

        throw Exception('Database update failed: $updateError');
      }

      // Verifikasi update dengan membaca kembali dari database
      debugPrint('🔍 Verifying database update...');

      try {
        final updatedDoc = await _databases.getDocument(
          databaseId: AppwriteDB.databaseId,
          collectionId: AppwriteDB.usersCollectionId,
          documentId: documentId,
        );

        final isPremiumUpdated = updatedDoc.data['isPremium'] ?? false;

        debugPrint('Database verification result:');
        debugPrint('  isPremium: $isPremiumUpdated');

        if (!isPremiumUpdated) {
          debugPrint('❌ VERIFICATION FAILED - isPremium still false!');
          throw Exception(
            'Database verification failed - isPremium is still false',
          );
        } else {
          debugPrint('✅ VERIFICATION SUCCESS - isPremium is true!');
        }
      } catch (verifyError) {
        debugPrint('❌ Verification error: $verifyError');
        throw Exception('Database verification failed: $verifyError');
      }

      // Update status premium di UI
      isPremiumNotifier.value = true;
      debugPrint('UI notifier updated: isPremiumNotifier.value = true');

      // Refresh subscription check untuk memastikan sinkron
      debugPrint('Refreshing subscription status...');
      await _checkActiveSubscriptions();

      // Refresh AuthRepository cache to ensure app-wide consistency
      try {
        if (getIt.isRegistered<AuthRepository>()) {
          debugPrint('Clearing AuthRepository cache...');
          final authRepo = getIt<AuthRepository>();
          await authRepo.refreshUser();

          // Verify the refresh worked
          final isPremiumAfterRefresh = await authRepo.isCurrentUserPremium();
          debugPrint(
            'AuthRepository premium status after refresh: $isPremiumAfterRefresh',
          );
        }
      } catch (e) {
        debugPrint('Failed to refresh AuthRepository: $e');
      }

      debugPrint('=== UPDATE PREMIUM STATUS END ===');
    } catch (e) {
      debugPrint('=== UPDATE PREMIUM STATUS ERROR ===');
      debugPrint('❌❌❌ CRITICAL ERROR ❌❌❌');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');

      // CRITICAL: Show error to user
      errorNotifier.value =
          '❌ GAGAL UPDATE STATUS PREMIUM!\n\n'
          'Error: $e\n\n'
          'Pembayaran Anda sudah berhasil di Google Play.\n'
          'Silakan hubungi developer dengan screenshot ini.';

      rethrow;
    }
  }

  Future<bool> checkSubscriptionStatus() async {
    try {
      await _checkActiveSubscriptions();
      return isPremiumNotifier.value;
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      return false;
    }
  }

  Future<bool> purchaseSubscription(ProductDetails product) async {
    try {
      debugPrint('=== PURCHASE SUBSCRIPTION START ===');
      debugPrint('Product: ${product.id} - ${product.title}');

      final result = await buyProduct(product);

      debugPrint('BuyProduct result: $result');

      if (result) {
        // CRITICAL: Manually trigger database update as fallback
        // This ensures database gets updated even if purchase stream is delayed
        debugPrint('⚠️ MANUALLY TRIGGERING DATABASE UPDATE AS FALLBACK...');

        try {
          // Wait a bit for purchase to be processed by Google Play
          await Future.delayed(const Duration(seconds: 3));

          // Force update database directly
          await _updatePremiumStatus(product.id);
          debugPrint('✅ Manual database update completed');
        } catch (e) {
          debugPrint('❌ Manual database update failed: $e');
          // Continue anyway - purchase stream might still work
        }

        // Tunggu sebentar untuk memastikan purchase event diproses
        await Future.delayed(const Duration(seconds: 2));

        // Verifikasi status premium setelah pembelian
        debugPrint('Verifying premium status after purchase...');
        await _checkActiveSubscriptions();

        debugPrint('Final premium status: ${isPremiumNotifier.value}');
      }

      debugPrint('=== PURCHASE SUBSCRIPTION END ===');

      return result;
    } catch (e) {
      debugPrint('❌ Failed to purchase subscription: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Method untuk manual force refresh premium status
  Future<void> forceRefreshPremiumStatus() async {
    try {
      debugPrint('=== FORCE REFRESH PREMIUM STATUS ===');
      await _checkActiveSubscriptions();

      // Refresh AuthRepository cache
      if (getIt.isRegistered<AuthRepository>()) {
        await getIt<AuthRepository>().refreshUser();
        debugPrint('AuthRepository user refreshed');
      }

      debugPrint(
        'Force refresh completed. Premium status: ${isPremiumNotifier.value}',
      );
      debugPrint('=== FORCE REFRESH PREMIUM STATUS END ===');
    } catch (e) {
      debugPrint('Error during force refresh: $e');
    }
  }

  // 🚨 EMERGENCY: Manual force update premium status
  // Use this if automatic update fails after payment
  Future<void> forceUpdatePremiumManual(String productId) async {
    try {
      debugPrint('🚨🚨🚨 EMERGENCY MANUAL UPDATE TRIGGERED 🚨🚨🚨');
      debugPrint('Product ID: $productId');

      await _updatePremiumStatus(productId);

      debugPrint('✅ Emergency manual update completed');

      // Show success to user
      errorNotifier.value = '';
    } catch (e) {
      debugPrint('❌ Emergency manual update failed: $e');
      errorNotifier.value = 'Manual update failed: $e';
      rethrow;
    }
  }
}
