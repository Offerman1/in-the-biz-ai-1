/// Stub implementation for non-web platforms
Uri getCurrentUri() {
  // On mobile, we don't have web URLs
  // Return empty URI - this screen should only be used on web
  return Uri.parse('');
}
