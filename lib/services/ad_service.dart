import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  // Check if we're on a supported platform (not web)
  bool get _isMobilePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // AdMob App IDs and Ad Unit IDs
  String get appId {
    if (!_isMobilePlatform) return '';

    if (Platform.isAndroid) {
      return 'ca-app-pub-1150666051629225~2172594466'; // Android App ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1150666051629225~3569436612'; // iOS App ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  String get interstitialAdUnitId {
    if (!_isMobilePlatform) return '';

    if (kDebugMode) {
      // Use test IDs in debug mode to avoid invalid traffic
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/1033173712'; // Google Test ID
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/4411468910'; // Google Test ID
      }
    }

    // Real Ad Unit IDs for production
    if (_isWebPlatform) {
      return 'ca-app-pub-1150666051629225/8744568210'; // Web uses Android ID
    }

    if (!_isMobilePlatform) return '';

    if (Platform.isAndroid) {
      return 'ca-app-pub-1150666051629225/8744568210'; // Android - Shift Save Ad
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1150666051629225/5222279697'; // iOS - Shift Save Ad
    }
    return '';
  }

  Future<void> initialize() async {
    if (!_isMobilePlatform) {
      debugPrint('Ads not supported on web platform - skipping initialization');
      return;
    }

    await MobileAds.instance.initialize();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    if (!_isMobilePlatform) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial Ad loaded.');
          _interstitialAd = ad;
          _isAdLoaded = true;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Ad dismissed.');
              ad.dispose();
              _loadInterstitialAd(); // Preload the next one
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Ad failed to show: $error');
              ad.dispose();
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial Ad failed to load: $error');
          _isAdLoaded = false;
        },
      ),
    );
  }

  Future<void> showInterstitialAd() async {
    if (!_isMobilePlatform) {
      debugPrint('Ads not supported on web platform - skipping ad display');
      return; // Just return immediately on web
    }

    if (_isAdLoaded && _interstitialAd != null) {
      await _interstitialAd!.show();
      _isAdLoaded = false;
      _interstitialAd = null;
    } else {
      debugPrint('Ad not ready yet.');
      // Try to load for next time
      _loadInterstitialAd();
    }
  }
}
