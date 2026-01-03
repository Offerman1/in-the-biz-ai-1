import 'dart:html' as html;

/// Web implementation
Uri getCurrentUri() {
  return Uri.parse(html.window.location.href);
}
