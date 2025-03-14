import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// A widget to display native ads using platform-specific layouts
class NativeAdWidget extends StatefulWidget {
  final String factoryId;
  final double height;
  final Map<String, Object>? customOptions;

  const NativeAdWidget({
    Key? key,
    required this.factoryId,
    required this.height,
    this.customOptions,
  }) : super(key: key);

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  String? _errorMessage;
  bool _isRetrying = false;
  int _retryAttempt = 0;
  static const int maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    if (_isRetrying) return;

    try {
      final adService = await AdService.getInstance();

      if (!adService.isInitialized) {
        setState(() {
          _errorMessage = 'Ad service not initialized';
        });
        return;
      }

      final adUnitId = adService.getNativeAdUnitId();
      debugPrint('Loading native ad with unit ID: $adUnitId');

      _nativeAd = NativeAd(
        adUnitId: adUnitId,
        factoryId: widget.factoryId,
        customOptions: widget.customOptions,
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            debugPrint('Native ad loaded successfully: ${ad.adUnitId}');
            setState(() {
              _isAdLoaded = true;
              _errorMessage = null;
              _retryAttempt = 0;
            });
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint(
              'Native ad failed to load: ${error.message}. Code: ${error.code}',
            );
            ad.dispose();

            if (_retryAttempt < maxRetries) {
              _retryAttempt++;
              _isRetrying = true;
              debugPrint(
                'Retrying ad load (attempt $_retryAttempt of $maxRetries)...',
              );

              Future.delayed(Duration(seconds: _retryAttempt * 2), () {
                if (mounted) {
                  _isRetrying = false;
                  _loadAd();
                }
              });
            } else {
              if (mounted) {
                setState(() {
                  _errorMessage = 'Ad load failed after $maxRetries attempts';
                  _isAdLoaded = false;
                });
              }
            }
          },
          onAdOpened: (ad) => debugPrint('Native ad opened'),
          onAdClosed: (ad) => debugPrint('Native ad closed'),
          onAdClicked: (ad) => debugPrint('Native ad clicked'),
          onAdImpression: (ad) => debugPrint('Native ad impression'),
        ),
        request: const AdRequest(),
      );

      await _nativeAd?.load();
    } catch (e) {
      debugPrint('Error creating/loading native ad: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading ad: $e';
          _isAdLoaded = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded && _nativeAd != null) {
      return SizedBox(height: widget.height, child: AdWidget(ad: _nativeAd!));
    }

    // Show a placeholder with error message in debug mode
    if (kDebugMode && _errorMessage != null) {
      return Container(
        height: widget.height,
        color: Colors.grey[200],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ),
      );
    }

    // Return an empty container when ad is not loaded
    return SizedBox(height: widget.height);
  }
}
