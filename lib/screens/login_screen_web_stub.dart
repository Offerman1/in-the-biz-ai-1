// Stub file for non-web platforms
// This provides empty implementations so Android/iOS can compile

import 'package:flutter/material.dart';

Widget renderButton() {
  // This should never be called on non-web platforms
  // because login_screen.dart checks kIsWeb before using it
  return const SizedBox.shrink();
}
