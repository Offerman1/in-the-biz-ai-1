import 'package:flutter/material.dart';
import '../models/shift.dart';
import '../services/database_service.dart';

class ShiftProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Shift> _shifts = [];
  bool _isLoading = false;
  String? _error;

  List<Shift> get shifts => _shifts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Calculate total income for the current list
  double get totalIncome =>
      _shifts.fold(0, (sum, item) => sum + item.totalIncome);

  // Calculate total hours
  double get totalHours =>
      _shifts.fold(0, (sum, item) => sum + item.hoursWorked);

  // Calculate total tips only
  double get totalTips => _shifts.fold(0, (sum, item) => sum + item.totalTips);

  // Get shifts for this week
  List<Shift> get thisWeekShifts {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return _shifts
        .where((s) =>
            s.date.isAfter(startDate) ||
            (s.date.year == startDate.year &&
                s.date.month == startDate.month &&
                s.date.day == startDate.day))
        .toList();
  }

  // Get shifts for this month
  List<Shift> get thisMonthShifts {
    final now = DateTime.now();
    return _shifts
        .where((s) => s.date.year == now.year && s.date.month == now.month)
        .toList();
  }

  Future<void> loadShifts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _shifts = await _db.getShifts();
      // Sort by date descending (newest first)
      _shifts.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Force reload shifts from database (useful after AI bulk operations)
  Future<void> forceReload() async {
    await loadShifts();
  }

  Future<Shift?> addShift(Shift shift) async {
    try {
      final newShift = await _db.saveShift(shift);
      // Immediately add to local list for instant UI update
      _shifts.insert(0, newShift);
      notifyListeners();
      // Also reload from database to ensure consistency
      await loadShifts();
      return newShift;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> updateShift(Shift shift) async {
    try {
      await _db.updateShift(shift);
      // Immediately update local list for instant UI update
      final index = _shifts.indexWhere((s) => s.id == shift.id);
      if (index != -1) {
        _shifts[index] = shift;
        notifyListeners();
      }
      // Also reload from database to ensure consistency
      await loadShifts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteShift(String shiftId) async {
    try {
      await _db.deleteShift(shiftId);
      // Immediately remove from local list for instant UI update
      _shifts.removeWhere((s) => s.id == shiftId);
      notifyListeners();
      // Also reload from database to ensure consistency
      await loadShifts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    try {
      await _db.clearAll();
      _shifts = [];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get shifts for a specific date
  List<Shift> getShiftsForDate(DateTime date) {
    return _shifts
        .where((s) =>
            s.date.year == date.year &&
            s.date.month == date.month &&
            s.date.day == date.day)
        .toList();
  }

  // Get shifts for a date range
  List<Shift> getShiftsForRange(DateTime start, DateTime end) {
    return _shifts
        .where((s) =>
            s.date.isAfter(start.subtract(const Duration(days: 1))) &&
            s.date.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }
}
