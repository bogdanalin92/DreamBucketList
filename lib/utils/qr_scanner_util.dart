import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class QRScannerUtil {
  static final BarcodeScanner _barcodeScanner = BarcodeScanner(
    formats: [BarcodeFormat.qrCode],
  );

  /// Scans an image file for QR codes
  static Future<String?> scanQRFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final List<Barcode> barcodes = await _barcodeScanner.processImage(
        inputImage,
      );

      for (Barcode barcode in barcodes) {
        final String? value = barcode.rawValue;
        if (value != null) {
          return value;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error scanning QR code from image: $e');
      return null;
    }
  }

  /// Clean up resources
  static void dispose() {
    _barcodeScanner.close();
  }
}
