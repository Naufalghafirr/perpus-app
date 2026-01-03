import 'dart:io';
import 'package:flutter/foundation.dart';

String getBaseUrl() {
  if (kIsWeb) {
    return 'https://api-perpustakaan-mu.vercel.app';
  }
  if (Platform.isAndroid) {
    return 'https://api-perpustakaan-mu.vercel.app';
    // return 'http://10.0.2.2:3000';
  }
  return 'https://api-perpustakaan-mu.vercel.app';
}
