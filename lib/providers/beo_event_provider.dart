import 'package:flutter/foundation.dart';
import '../models/beo_event.dart';
import '../services/beo_event_service.dart';

/// Provider for managing BEO events state
class BeoEventProvider extends ChangeNotifier {
  final BeoEventService _service = BeoEventService();

  List<BeoEvent> _beoEvents = [];
  bool _isLoading = false;
  String? _error;

  List<BeoEvent> get beoEvents => _beoEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get standalone BEO events (not linked to shifts)
  List<BeoEvent> get standaloneBeoEvents =>
      _beoEvents.where((e) => e.isStandalone).toList();

  /// Get BEO events for a specific date
  List<BeoEvent> getBeoEventsForDate(DateTime date) {
    return _beoEvents.where((event) {
      return event.eventDate.year == date.year &&
          event.eventDate.month == date.month &&
          event.eventDate.day == date.day;
    }).toList();
  }

  /// Get standalone BEO events for a specific date (for calendar)
  List<BeoEvent> getStandaloneBeoEventsForDate(DateTime date) {
    return _beoEvents.where((event) {
      return event.isStandalone &&
          event.eventDate.year == date.year &&
          event.eventDate.month == date.month &&
          event.eventDate.day == date.day;
    }).toList();
  }

  /// Load all BEO events
  Future<void> loadBeoEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _beoEvents = await _service.getAllBeoEvents();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading BEO events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force reload BEO events
  Future<void> forceReload() async {
    await loadBeoEvents();
  }

  /// Create a new BEO event
  Future<BeoEvent?> createBeoEvent(BeoEvent event) async {
    try {
      final created = await _service.createBeoEvent(event);
      _beoEvents.insert(0, created);
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating BEO event: $e');
      notifyListeners();
      return null;
    }
  }

  /// Update a BEO event
  Future<BeoEvent?> updateBeoEvent(BeoEvent event) async {
    try {
      final updated = await _service.updateBeoEvent(event);
      final index = _beoEvents.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _beoEvents[index] = updated;
        notifyListeners();
      }
      return updated;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating BEO event: $e');
      notifyListeners();
      return null;
    }
  }

  /// Delete a BEO event
  Future<bool> deleteBeoEvent(String id) async {
    try {
      await _service.deleteBeoEvent(id);
      _beoEvents.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting BEO event: $e');
      notifyListeners();
      return false;
    }
  }

  /// Get a BEO event by ID
  BeoEvent? getBeoEventById(String id) {
    try {
      return _beoEvents.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Fetch BEO event for a shift
  Future<BeoEvent?> getBeoEventForShift(String shiftId) async {
    return await _service.getBeoEventForShift(shiftId);
  }
}
