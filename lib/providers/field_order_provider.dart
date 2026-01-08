import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages custom field ordering for Add/Edit Shift and Shift Details screens
/// Users can long-press and drag to reorder sections
class FieldOrderProvider extends ChangeNotifier {
  // Default order for Add/Edit Shift screens
  static const List<String> _defaultFormOrder = [
    'time_section',
    'earnings_section',
    'event_details_section',
    'work_details_section',
    'documentation_section',
    'attachments_section',
    'event_team_section',
    'invoices_section',
    'receipts_section',
  ];

  // Default order for Shift Details screen
  static const List<String> _defaultDetailsOrder = [
    'earnings_section',
    'event_details_section',
    'work_details_section',
    'time_section',
    'documentation_section',
    'photos_section',
    'attachments_section',
    'event_team_section',
    'checkout_section',
    'invoices_section',
    'receipts_section',
  ];

  List<String> _formFieldOrder = [..._defaultFormOrder];
  List<String> _detailsFieldOrder = [..._defaultDetailsOrder];

  List<String> get formFieldOrder => _formFieldOrder;
  List<String> get detailsFieldOrder => _detailsFieldOrder;

  FieldOrderProvider() {
    _loadFieldOrders();
  }

  /// Load saved field orders from SharedPreferences
  Future<void> _loadFieldOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load form field order
      final formOrderJson = prefs.getString('shift_form_field_order');
      if (formOrderJson != null) {
        final List<dynamic> decoded = jsonDecode(formOrderJson);
        _formFieldOrder = decoded.cast<String>();
      }

      // Load details field order
      final detailsOrderJson = prefs.getString('shift_details_field_order');
      if (detailsOrderJson != null) {
        final List<dynamic> decoded = jsonDecode(detailsOrderJson);
        _detailsFieldOrder = decoded.cast<String>();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading field orders: $e');
      // Keep default orders
    }
  }

  /// Update form field order (Add/Edit Shift screens)
  Future<void> updateFormFieldOrder(List<String> newOrder) async {
    _formFieldOrder = [...newOrder];
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('shift_form_field_order', jsonEncode(newOrder));
    } catch (e) {
      debugPrint('Error saving form field order: $e');
    }
  }

  /// Update details field order (Shift Details screen)
  Future<void> updateDetailsFieldOrder(List<String> newOrder) async {
    _detailsFieldOrder = [...newOrder];
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('shift_details_field_order', jsonEncode(newOrder));
    } catch (e) {
      debugPrint('Error saving details field order: $e');
    }
  }

  /// Reset form field order to default
  Future<void> resetFormFieldOrder() async {
    _formFieldOrder = [..._defaultFormOrder];
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('shift_form_field_order');
    } catch (e) {
      debugPrint('Error resetting form field order: $e');
    }
  }

  /// Reset details field order to default
  Future<void> resetDetailsFieldOrder() async {
    _detailsFieldOrder = [..._defaultDetailsOrder];
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('shift_details_field_order');
    } catch (e) {
      debugPrint('Error resetting details field order: $e');
    }
  }
}
