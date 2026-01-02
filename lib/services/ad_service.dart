import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  // TODO: Replace with your actual AdMob App IDs when ready for production
  // These are Google's Test IDs
  String get appId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544~3347511713';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544~1458002511';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  String get interstitialAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/1033173712';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/4411468910';
      }
    }

    // TODO: Replace with your real Ad Unit IDs
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Placeholder
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Placeholder
    }
    return '';
  }

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
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
