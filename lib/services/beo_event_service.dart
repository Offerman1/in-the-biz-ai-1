import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/beo_event.dart';

/// Service for managing BEO (Banquet Event Order) events
class BeoEventService {
  final _supabase = Supabase.instance.client;

  /// Fetch all BEO events for the current user
  Future<List<BeoEvent>> getAllBeoEvents() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('beo_events')
        .select()
        .eq('user_id', userId)
        .order('event_date', ascending: false);

    return (response as List)
        .map((json) => BeoEvent.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch only standalone BEO events (not linked to a shift)
  Future<List<BeoEvent>> getStandaloneBeoEvents() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('beo_events')
        .select()
        .eq('user_id', userId)
        .eq('is_standalone', true)
        .order('event_date', ascending: false);

    return (response as List)
        .map((json) => BeoEvent.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch BEO events for a specific date range
  Future<List<BeoEvent>> getBeoEventsInRange(
      DateTime start, DateTime end) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('beo_events')
        .select()
        .eq('user_id', userId)
        .gte('event_date', start.toIso8601String().split('T')[0])
        .lte('event_date', end.toIso8601String().split('T')[0])
        .order('event_date', ascending: true);

    return (response as List)
        .map((json) => BeoEvent.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single BEO event by ID
  Future<BeoEvent?> getBeoEventById(String id) async {
    final response =
        await _supabase.from('beo_events').select().eq('id', id).maybeSingle();

    if (response == null) return null;
    return BeoEvent.fromJson(response);
  }

  /// Create a new BEO event
  Future<BeoEvent> createBeoEvent(BeoEvent event) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final data = event.toJson();
    data['user_id'] = userId;
    data.remove('id'); // Let database generate ID

    final response =
        await _supabase.from('beo_events').insert(data).select().single();

    return BeoEvent.fromJson(response);
  }

  /// Update an existing BEO event
  Future<BeoEvent> updateBeoEvent(BeoEvent event) async {
    final data = event.toJson();
    data['updated_at'] = DateTime.now().toIso8601String();

    final response = await _supabase
        .from('beo_events')
        .update(data)
        .eq('id', event.id)
        .select()
        .single();

    return BeoEvent.fromJson(response);
  }

  /// Delete a BEO event
  Future<void> deleteBeoEvent(String id) async {
    await _supabase.from('beo_events').delete().eq('id', id);
  }

  /// Link a BEO event to a shift
  Future<void> linkBeoToShift(String beoEventId, String shiftId) async {
    // Update the shift to reference this BEO
    await _supabase
        .from('shifts')
        .update({'beo_event_id': beoEventId}).eq('id', shiftId);

    // Mark the BEO as no longer standalone
    await _supabase
        .from('beo_events')
        .update({'is_standalone': false}).eq('id', beoEventId);
  }

  /// Unlink a BEO event from a shift
  Future<void> unlinkBeoFromShift(String shiftId) async {
    // First get the current beo_event_id
    final shift = await _supabase
        .from('shifts')
        .select('beo_event_id')
        .eq('id', shiftId)
        .maybeSingle();

    if (shift != null && shift['beo_event_id'] != null) {
      final beoEventId = shift['beo_event_id'] as String;

      // Mark the BEO as standalone again
      await _supabase
          .from('beo_events')
          .update({'is_standalone': true}).eq('id', beoEventId);
    }

    // Remove the link from the shift
    await _supabase
        .from('shifts')
        .update({'beo_event_id': null}).eq('id', shiftId);
  }

  /// Get BEO event linked to a specific shift
  Future<BeoEvent?> getBeoEventForShift(String shiftId) async {
    final shift = await _supabase
        .from('shifts')
        .select('beo_event_id')
        .eq('id', shiftId)
        .maybeSingle();

    if (shift == null || shift['beo_event_id'] == null) return null;

    return getBeoEventById(shift['beo_event_id'] as String);
  }
}
