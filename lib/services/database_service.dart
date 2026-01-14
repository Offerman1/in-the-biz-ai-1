import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shift.dart';
import '../models/job.dart';
import '../models/event_contact.dart';
import '../models/shift_attachment.dart';
import 'calendar_sync_service.dart';
import 'google_calendar_service.dart';

class DatabaseService {
  static SupabaseClient get _supabase => Supabase.instance.client;

  /// Public getter for Supabase client (used by vision scanner)
  SupabaseClient get supabase => _supabase;

  /// Helper to format DateTime to YYYY-MM-DD in local timezone
  static String _formatDateLocal(DateTime date) {
    // Format in local time, not UTC
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // ============================================
  // SHIFTS
  // ============================================

  /// Save a new shift to Supabase
  Future<Shift> saveShift(Shift shift) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      print('💾 [DB] Saving shift...');
      print('💾 [DB] Job ID: ${shift.jobId}');
      print('💾 [DB] Date: ${shift.date}');
      print('💾 [DB] Status: ${shift.status}');

      final response = await _supabase
          .from('shifts')
          .insert({
            'user_id': userId,
            'date': _formatDateLocal(shift.date),
            'cash_tips': shift.cashTips,
            'credit_tips': shift.creditTips,
            'hourly_rate': shift.hourlyRate,
            'hours_worked': shift.hoursWorked,
            'notes': shift.notes,
            'image_url': shift.imageUrl,
            'job_id': shift.jobId,
            'job_type': shift.jobType,
            'start_time': shift.startTime,
            'end_time': shift.endTime,
            'event_name': shift.eventName,
            'hostess': shift.hostess,
            'guest_count': shift.guestCount,
            'location': shift.location,
            'client_name': shift.clientName,
            'project_name': shift.projectName,
            'commission': shift.commission,
            'mileage': shift.mileage,
            'flat_rate': shift.flatRate,
            'overtime_hours': shift.overtimeHours,
            'sales_amount': shift.salesAmount,
            'tipout_percent': shift.tipoutPercent,
            'additional_tipout': shift.additionalTipout,
            'additional_tipout_note': shift.additionalTipoutNote,
            'event_cost': shift.eventCost,
            'status': shift.status,
            'source': shift.source,
            'is_recurring': shift.isRecurring,
            'recurrence_rule': shift.recurrenceRule,
            'recurring_series_id': shift.recurringSeriesId,
            'calendar_event_id': shift.calendarEventId,
            // Rideshare & Delivery fields
            'rides_count': shift.ridesCount,
            'deliveries_count': shift.deliveriesCount,
            'dead_miles': shift.deadMiles,
            'fuel_cost': shift.fuelCost,
            'tolls_parking': shift.tollsParking,
            'surge_multiplier': shift.surgeMultiplier,
            'acceptance_rate': shift.acceptanceRate,
            'base_fare': shift.baseFare,
            // Music & Entertainment fields
            'gig_type': shift.gigType,
            'setup_hours': shift.setupHours,
            'performance_hours': shift.performanceHours,
            'breakdown_hours': shift.breakdownHours,
            'equipment_used': shift.equipmentUsed,
            'equipment_rental_cost': shift.equipmentRentalCost,
            'crew_payment': shift.crewPayment,
            'merch_sales': shift.merchSales,
            'audience_size': shift.audienceSize,
            // Artist & Crafts fields
            'pieces_created': shift.piecesCreated,
            'pieces_sold': shift.piecesSold,
            'materials_cost': shift.materialsCost,
            'sale_price': shift.salePrice,
            'venue_commission_percent': shift.venueCommissionPercent,
            // Retail/Sales fields
            'items_sold': shift.itemsSold,
            'transactions_count': shift.transactionsCount,
            'upsells_count': shift.upsellsCount,
            'upsells_amount': shift.upsellsAmount,
            'returns_count': shift.returnsCount,
            'returns_amount': shift.returnsAmount,
            'shrink_amount': shift.shrinkAmount,
            'department': shift.department,
            // Salon/Spa fields
            'service_type': shift.serviceType,
            'services_count': shift.servicesCount,
            'product_sales': shift.productSales,
            'repeat_client_percent': shift.repeatClientPercent,
            'chair_rental': shift.chairRental,
            'new_clients_count': shift.newClientsCount,
            'returning_clients_count': shift.returningClientsCount,
            'walkin_count': shift.walkinCount,
            'appointment_count': shift.appointmentCount,
            // Hospitality fields
            'room_type': shift.roomType,
            'rooms_cleaned': shift.roomsCleaned,
            'quality_score': shift.qualityScore,
            'shift_type': shift.shiftType,
            'room_upgrades': shift.roomUpgrades,
            'guests_checked_in': shift.guestsCheckedIn,
            'cars_parked': shift.carsParked,
            // Healthcare fields
            'patient_count': shift.patientCount,
            'shift_differential': shift.shiftDifferential,
            'on_call_hours': shift.onCallHours,
            'procedures_count': shift.proceduresCount,
            'specialization': shift.specialization,
            // Fitness fields
            'sessions_count': shift.sessionsCount,
            'session_type': shift.sessionType,
            'class_size': shift.classSize,
            'retention_rate': shift.retentionRate,
            'cancellations_count': shift.cancellationsCount,
            'package_sales': shift.packageSales,
            'supplement_sales': shift.supplementSales,
            // Construction/Trades fields
            'labor_cost': shift.laborCost,
            'subcontractor_cost': shift.subcontractorCost,
            'square_footage': shift.squareFootage,
            'weather_delay_hours': shift.weatherDelayHours,
            // Freelancer fields
            'revisions_count': shift.revisionsCount,
            'client_type': shift.clientType,
            'expenses': shift.expenses,
            'billable_hours': shift.billableHours,
            // Restaurant fields (additional)
            'table_section': shift.tableSection,
            'cash_sales': shift.cashSales,
            'card_sales': shift.cardSales,
            // BEO Event linkage
            'beo_event_id': shift.beoEventId,
            // Section field
            'section': shift.section,
            // Checkout ID
            'checkout_id': shift.checkoutId,
            // Shift hidden sections
            'shift_hidden_sections': shift.shiftHiddenSections,
          })
          .select()
          .single();

      print('💾 [DB] Insert successful, response received');
      print('💾 [DB] Response type: ${response.runtimeType}');
      print('💾 [DB] Response keys: ${response.keys.toList()}');

      final savedShift = Shift.fromSupabase(response);
      print('💾 [DB] Shift parsed successfully: ${savedShift.id}');

      // Auto-export to calendar if enabled
      await _autoExportShift(savedShift);

      print('💾 [DB] Save completed successfully');
      return savedShift;
    } catch (e, stackTrace) {
      print('❌ [DB] Error saving shift: $e');
      print('❌ [DB] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get all shifts for current user
  Future<List<Shift>> getShifts() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('shifts')
        .select()
        .eq('user_id', userId)
        .filter('deleted_at', 'is', null) // Filter out archived shifts
        .order('date', ascending: false);

    return (response as List).map((e) => Shift.fromSupabase(e)).toList();
  }

  /// Update a shift
  Future<void> updateShift(Shift shift) async {
    await _supabase.from('shifts').update({
      'date': _formatDateLocal(shift.date),
      'cash_tips': shift.cashTips,
      'credit_tips': shift.creditTips,
      'hourly_rate': shift.hourlyRate,
      'hours_worked': shift.hoursWorked,
      'notes': shift.notes,
      'image_url': shift.imageUrl,
      'job_id': shift.jobId,
      'job_type': shift.jobType,
      'start_time': shift.startTime,
      'end_time': shift.endTime,
      'event_name': shift.eventName,
      'hostess': shift.hostess,
      'guest_count': shift.guestCount,
      'location': shift.location,
      'client_name': shift.clientName,
      'project_name': shift.projectName,
      'commission': shift.commission,
      'mileage': shift.mileage,
      'flat_rate': shift.flatRate,
      'overtime_hours': shift.overtimeHours,
      'sales_amount': shift.salesAmount,
      'tipout_percent': shift.tipoutPercent,
      'additional_tipout': shift.additionalTipout,
      'additional_tipout_note': shift.additionalTipoutNote,
      'event_cost': shift.eventCost,
      'status': shift.status,
      'source': shift.source,
      'is_recurring': shift.isRecurring,
      'recurrence_rule': shift.recurrenceRule,
      'recurring_series_id': shift.recurringSeriesId,
      'calendar_event_id': shift.calendarEventId,
      // Rideshare & Delivery fields
      'rides_count': shift.ridesCount,
      'deliveries_count': shift.deliveriesCount,
      'dead_miles': shift.deadMiles,
      'fuel_cost': shift.fuelCost,
      'tolls_parking': shift.tollsParking,
      'surge_multiplier': shift.surgeMultiplier,
      'acceptance_rate': shift.acceptanceRate,
      'base_fare': shift.baseFare,
      // Music & Entertainment fields
      'gig_type': shift.gigType,
      'setup_hours': shift.setupHours,
      'performance_hours': shift.performanceHours,
      'breakdown_hours': shift.breakdownHours,
      'equipment_used': shift.equipmentUsed,
      'equipment_rental_cost': shift.equipmentRentalCost,
      'crew_payment': shift.crewPayment,
      'merch_sales': shift.merchSales,
      'audience_size': shift.audienceSize,
      // Artist & Crafts fields
      'pieces_created': shift.piecesCreated,
      'pieces_sold': shift.piecesSold,
      'materials_cost': shift.materialsCost,
      'sale_price': shift.salePrice,
      'venue_commission_percent': shift.venueCommissionPercent,
      // Retail/Sales fields
      'items_sold': shift.itemsSold,
      'transactions_count': shift.transactionsCount,
      'upsells_count': shift.upsellsCount,
      'upsells_amount': shift.upsellsAmount,
      'returns_count': shift.returnsCount,
      'returns_amount': shift.returnsAmount,
      'shrink_amount': shift.shrinkAmount,
      'department': shift.department,
      // Salon/Spa fields
      'service_type': shift.serviceType,
      'services_count': shift.servicesCount,
      'product_sales': shift.productSales,
      'repeat_client_percent': shift.repeatClientPercent,
      'chair_rental': shift.chairRental,
      'new_clients_count': shift.newClientsCount,
      'returning_clients_count': shift.returningClientsCount,
      'walkin_count': shift.walkinCount,
      'appointment_count': shift.appointmentCount,
      // Hospitality fields
      'room_type': shift.roomType,
      'rooms_cleaned': shift.roomsCleaned,
      'quality_score': shift.qualityScore,
      'shift_type': shift.shiftType,
      'room_upgrades': shift.roomUpgrades,
      'guests_checked_in': shift.guestsCheckedIn,
      'cars_parked': shift.carsParked,
      // Healthcare fields
      'patient_count': shift.patientCount,
      'shift_differential': shift.shiftDifferential,
      'on_call_hours': shift.onCallHours,
      'procedures_count': shift.proceduresCount,
      'specialization': shift.specialization,
      // Fitness fields
      'sessions_count': shift.sessionsCount,
      'session_type': shift.sessionType,
      'class_size': shift.classSize,
      'retention_rate': shift.retentionRate,
      'cancellations_count': shift.cancellationsCount,
      'package_sales': shift.packageSales,
      'supplement_sales': shift.supplementSales,
      // Construction/Trades fields
      'labor_cost': shift.laborCost,
      'subcontractor_cost': shift.subcontractorCost,
      'square_footage': shift.squareFootage,
      'weather_delay_hours': shift.weatherDelayHours,
      // Freelancer fields
      'revisions_count': shift.revisionsCount,
      'client_type': shift.clientType,
      'expenses': shift.expenses,
      'billable_hours': shift.billableHours,
      // Restaurant fields (additional)
      'table_section': shift.tableSection,
      'cash_sales': shift.cashSales,
      'card_sales': shift.cardSales,
      // BEO Event linkage
      'beo_event_id': shift.beoEventId,
      // Section field
      'section': shift.section,
      // Checkout ID
      'checkout_id': shift.checkoutId,
      // Shift hidden sections
      'shift_hidden_sections': shift.shiftHiddenSections,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', shift.id);

    // Auto-export to calendar if enabled and shift is already synced
    await _autoExportShift(shift);
  }

  /// Delete a shift
  Future<void> deleteShift(String shiftId) async {
    // Get shift first to check if it has a calendar event
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      try {
        final response = await _supabase
            .from('shifts')
            .select()
            .eq('id', shiftId)
            .eq('user_id', userId)
            .maybeSingle();

        if (response != null) {
          final shift = Shift.fromSupabase(response);

          // Delete calendar event if exists
          if (shift.calendarEventId != null) {
            final prefs = await SharedPreferences.getInstance();
            final autoSync = prefs.getBool('auto_sync_calendar') ?? false;

            if (autoSync) {
              try {
                if (kIsWeb) {
                  final googleCalendar = GoogleCalendarService();
                  await googleCalendar
                      .deleteCalendarEvent(shift.calendarEventId!);
                } else {
                  final calendarSync = CalendarSyncService();
                  final calendarId =
                      prefs.getString('selected_calendar_id') ?? 'primary';
                  await calendarSync.deleteCalendarEvent(
                      calendarId, shift.calendarEventId!);
                }
              } catch (e) {
                print('Failed to delete calendar event: $e');
                // Continue with shift deletion even if calendar deletion fails
              }
            }
          }
        }
      } catch (e) {
        print('Failed to fetch shift for calendar cleanup: $e');
      }
    }

    // Delete the shift
    await _supabase.from('shifts').delete().eq('id', shiftId);
  }

  /// Get shifts for a specific date range
  Future<List<Shift>> getShiftsByDateRange(DateTime start, DateTime end) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('shifts')
        .select()
        .eq('user_id', userId)
        .gte('date', _formatDateLocal(start))
        .lte('date', _formatDateLocal(end))
        .order('date', ascending: false);

    return (response as List).map((e) => Shift.fromSupabase(e)).toList();
  }

  /// Get shifts for a specific date
  Future<List<Shift>> getShiftsForDate(DateTime date) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final dateStr = _formatDateLocal(date);

    final response = await _supabase
        .from('shifts')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Shift.fromSupabase(e)).toList();
  }

  // ============================================
  // PHOTOS
  // ============================================

  /// Upload a photo for a shift
  Future<String> uploadPhoto({
    required String shiftId,
    required Uint8List imageBytes,
    required String fileName,
    String photoType = 'gallery',
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    // Upload to storage: userId/shiftId/filename
    final storagePath = '$userId/$shiftId/$fileName';

    await _supabase.storage.from('shift-photos').uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    // Save reference in shift_photos table
    await _supabase.from('shift_photos').insert({
      'shift_id': shiftId,
      'user_id': userId,
      'storage_path': storagePath,
      'photo_type': photoType,
    });

    return storagePath;
  }

  /// Get photos for a shift
  Future<List<Map<String, dynamic>>> getShiftPhotos(String shiftId) async {
    final response =
        await _supabase.from('shift_photos').select().eq('shift_id', shiftId);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get signed URL for a photo (valid for 1 hour)
  Future<String> getPhotoUrl(String storagePath) async {
    // Use public URLs on web, signed URLs on mobile
    // Web has issues with signed URLs from private buckets
    if (kIsWeb) {
      final response = _supabase.storage
          .from('shift-photos')
          .getPublicUrl(storagePath);
      return response;
    } else {
      final response = await _supabase.storage
          .from('shift-photos')
          .createSignedUrl(storagePath, 3600);
      return response;
    }
  }

  /// Delete a photo
  Future<void> deletePhoto(String photoId, String storagePath) async {
    // Delete from storage
    await _supabase.storage.from('shift-photos').remove([storagePath]);

    // Delete reference from database
    await _supabase.from('shift_photos').delete().eq('id', photoId);
  }

  // ============================================
  // JOBS
  // ============================================

  /// Create a new job
  Future<Job> createJob(Job job) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    // If this is the default job, unset any existing default
    if (job.isDefault) {
      await _supabase
          .from('jobs')
          .update({'is_default': false}).eq('user_id', userId);
    }

    final response =
        await _supabase.from('jobs').insert(job.toSupabase()).select().single();

    return Job.fromSupabase(response);
  }

  /// Get all jobs for current user
  Future<List<Map<String, dynamic>>> getJobs() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('jobs')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .filter('deleted_at', 'is',
            null) // Filter out archived jobs (keep only non-deleted)
        .order('is_default', ascending: false)
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get inactive jobs (jobs that ended but aren't archived)
  Future<List<Map<String, dynamic>>> getInactiveJobs() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('jobs')
        .select()
        .eq('user_id', userId)
        .eq('is_active', false)
        .filter('deleted_at', 'is', null) // Not archived
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get default job
  Future<Map<String, dynamic>?> getDefaultJob() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('jobs')
        .select()
        .eq('user_id', userId)
        .eq('is_default', true)
        .maybeSingle();

    return response;
  }

  /// Update a job
  Future<void> updateJob(Job job) async {
    await _supabase.from('jobs').update({
      ...job.toSupabase(),
      'updated_at': DateTime.now().toIso8601String()
    }).eq('id', job.id);
  }

  /// Update hourly rate for all existing shifts of a job
  Future<void> updateShiftsHourlyRate({
    required String jobId,
    required double newHourlyRate,
  }) async {
    await _supabase
        .from('shifts')
        .update({'hourly_rate': newHourlyRate})
        .eq('job_id', jobId)
        .isFilter('deleted_at', null); // Only update non-deleted shifts
  }

  /// Set job as default
  Future<void> setDefaultJob(String jobId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Unset all defaults
    await _supabase
        .from('jobs')
        .update({'is_default': false}).eq('user_id', userId);

    // Set new default
    await _supabase.from('jobs').update({'is_default': true}).eq('id', jobId);
  }

  /// Soft delete a job only (preserve shifts)
  Future<void> deleteJob(String jobId) async {
    await _supabase.from('jobs').update(
        {'deleted_at': DateTime.now().toIso8601String()}).eq('id', jobId);
  }

  /// Mark a job as inactive (end a job but keep all data)
  /// [reason] - The EndJobReason enum value (e.g., 'terminated', 'promoted')
  /// [notes] - Optional user notes about why the job ended
  Future<void> deactivateJob(
    String jobId, {
    String? reason,
    String? notes,
  }) async {
    await _supabase.from('jobs').update({
      'is_active': false,
      'end_reason': reason,
      'end_notes': notes,
      'ended_at': DateTime.now().toIso8601String(),
    }).eq('id', jobId);
  }

  /// Reactivate an inactive job
  Future<void> reactivateJob(String jobId) async {
    await _supabase.from('jobs').update({'is_active': true}).eq('id', jobId);
  }

  /// Soft delete a job and all associated shifts and goals
  Future<void> deleteJobAndShifts(String jobId) async {
    await _supabase.rpc('soft_delete_job', params: {'job_uuid': jobId});
  }

  /// Get deleted jobs (for restore UI)
  Future<List<Map<String, dynamic>>> getDeletedJobs() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('jobs')
        .select()
        .eq('user_id', userId)
        .not('deleted_at', 'is', null)
        .order('deleted_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Restore a deleted job and all associated data
  Future<void> restoreJob(String jobId) async {
    await _supabase.rpc('restore_job', params: {'job_uuid': jobId});
  }

  /// Get shift count for a specific job
  Future<int> getShiftCountForJob(String jobId) async {
    final response = await _supabase
        .from('shifts')
        .select('id')
        .eq('job_id', jobId)
        .isFilter('deleted_at', null);

    return (response as List).length;
  }

  /// Merge multiple jobs into one target job.
  /// All shifts from source jobs are reassigned to the target job.
  /// Source jobs are then deleted (soft delete).
  Future<void> mergeJobs({
    required String targetJobId,
    required List<String> sourceJobIds,
    String? newName,
    String? newEmployer,
    double? newRate,
  }) async {
    // 1. Update target job with new details if provided
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (newName != null && newName.isNotEmpty) {
      updates['name'] = newName;
    }
    if (newEmployer != null) {
      updates['employer'] = newEmployer;
    }
    if (newRate != null) {
      updates['hourly_rate'] = newRate;
    }

    await _supabase.from('jobs').update(updates).eq('id', targetJobId);

    // 2. Reassign all shifts from source jobs to target job
    for (final sourceJobId in sourceJobIds) {
      await _supabase
          .from('shifts')
          .update({
            'job_id': targetJobId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', sourceJobId)
          .isFilter('deleted_at', null);

      // Also update calendar_title_mappings if they exist
      try {
        await _supabase
            .from('calendar_title_mappings')
            .update({'job_id': targetJobId}).eq('job_id', sourceJobId);
      } catch (e) {
        // Ignore if table doesn't exist or no mappings
      }

      // Also update goals to point to new job
      try {
        await _supabase
            .from('goals')
            .update({'job_id': targetJobId})
            .eq('job_id', sourceJobId)
            .isFilter('deleted_at', null);
      } catch (e) {
        // Ignore if no goals
      }
    }

    // 3. Soft delete the source jobs
    for (final sourceJobId in sourceJobIds) {
      await _supabase.from('jobs').update({
        'deleted_at': DateTime.now().toIso8601String(),
        'is_active': false,
      }).eq('id', sourceJobId);
    }
  }

  /// Permanently delete old archived items (called automatically or manually)
  Future<void> cleanupOldDeletedItems() async {
    await _supabase.rpc('cleanup_old_deleted_items');
  }

  // ============================================
  // GOALS
  // ============================================

  /// Create a new goal
  Future<Map<String, dynamic>> createGoal({
    required String type, // 'weekly', 'monthly', 'yearly', 'custom'
    required double targetAmount,
    double? targetHours,
    String? jobId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await _supabase
        .from('goals')
        .insert({
          'user_id': userId,
          'job_id': jobId,
          'type': type,
          'target_amount': targetAmount,
          'target_hours': targetHours,
          'start_date': startDate != null ? _formatDateLocal(startDate) : null,
          'end_date': endDate != null ? _formatDateLocal(endDate) : null,
        })
        .select()
        .single();

    return response;
  }

  /// Get all active goals
  Future<List<Map<String, dynamic>>> getGoals() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('goals')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .filter('deleted_at', 'is', null) // Filter out archived goals
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Update a goal
  Future<void> updateGoal(String goalId, Map<String, dynamic> updates) async {
    await _supabase.from('goals').update({
      ...updates,
      'updated_at': DateTime.now().toIso8601String()
    }).eq('id', goalId);
  }

  /// Delete a goal (soft delete)
  Future<void> deleteGoal(String goalId) async {
    await _supabase.from('goals').update({'is_active': false}).eq('id', goalId);
  }

  // ============================================
  // USER SETTINGS
  // ============================================

  /// Get user settings (creates if not exists)
  Future<Map<String, dynamic>> getUserSettings() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    var response = await _supabase
        .from('user_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    // Create if doesn't exist
    response ??= await _supabase
        .from('user_settings')
        .insert({'user_id': userId})
        .select()
        .single();

    return response;
  }

  /// Update user settings
  Future<void> updateUserSettings(Map<String, dynamic> updates) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('user_settings').update({
      ...updates,
      'updated_at': DateTime.now().toIso8601String()
    }).eq('user_id', userId);
  }

  /// Mark onboarding as complete
  Future<void> completeOnboarding() async {
    await updateUserSettings({'has_completed_onboarding': true});
  }

  /// Check if onboarding is complete
  Future<bool> hasCompletedOnboarding() async {
    try {
      final settings = await getUserSettings();
      return settings['has_completed_onboarding'] == true;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // INDUSTRY TEMPLATES
  // ============================================

  /// Get all industry templates
  Future<List<Map<String, dynamic>>> getIndustryTemplates() async {
    final response = await _supabase
        .from('industry_templates')
        .select()
        .order('display_name');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get template by industry
  Future<Map<String, dynamic>?> getTemplateByIndustry(String industry) async {
    final response = await _supabase
        .from('industry_templates')
        .select()
        .eq('industry', industry)
        .maybeSingle();

    return response;
  }

  // ============================================
  // PROFILE
  // ============================================

  /// Get user profile
  Future<Map<String, dynamic>?> getProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  /// Update user profile
  Future<void> updateProfile({
    String? fullName,
    double? defaultHourlyRate,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('profiles').update({
      if (fullName != null) 'full_name': fullName,
      if (defaultHourlyRate != null) 'default_hourly_rate': defaultHourlyRate,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // ============================================
  // ANALYTICS & QUERIES
  // ============================================

  /// Get shifts by event/party name
  Future<List<Shift>> getShiftsByEventName(String eventName) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('shifts')
        .select()
        .eq('user_id', userId)
        .ilike('event_name', '%$eventName%')
        .order('date', ascending: false);

    return (response as List).map((e) => Shift.fromSupabase(e)).toList();
  }

  /// Get income for a specific event/party
  Future<double> getIncomeForEvent(String eventName) async {
    final shifts = await getShiftsByEventName(eventName);
    double total = 0.0;
    for (final s in shifts) {
      total += s.totalIncome;
    }
    return total;
  }

  /// Get year-over-year comparison
  Future<Map<int, double>> getYearlyTotals() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return {};

    final response = await _supabase
        .from('shifts')
        .select('date, cash_tips, credit_tips, hourly_rate, hours_worked')
        .eq('user_id', userId);

    final yearlyTotals = <int, double>{};
    for (final row in response) {
      final date = DateTime.parse(row['date']);
      final income = (row['cash_tips'] ?? 0.0) +
          (row['credit_tips'] ?? 0.0) +
          ((row['hourly_rate'] ?? 0.0) * (row['hours_worked'] ?? 0.0));
      yearlyTotals[date.year] = (yearlyTotals[date.year] ?? 0) + income;
    }

    return yearlyTotals;
  }

  /// Get shifts by job
  Future<List<Shift>> getShiftsByJob(String jobId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('shifts')
        .select()
        .eq('user_id', userId)
        .eq('job_id', jobId)
        .order('date', ascending: false);

    return (response as List).map((e) => Shift.fromSupabase(e)).toList();
  }

  /// Get income summary by job
  Future<Map<String, double>> getIncomeByJob() async {
    final jobs = await getJobs();
    final incomeByJob = <String, double>{};

    for (final job in jobs) {
      final shifts = await getShiftsByJob(job['id']);
      final total = shifts.fold(0.0, (sum, s) => sum + s.totalIncome);
      incomeByJob[job['name']] = total;
    }

    return incomeByJob;
  }

  /// Clear all data (for testing - deletes all user's shifts)
  Future<void> clearAll() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('shifts').delete().eq('user_id', userId);
  }

  // ============================================
  // IMPORT ANALYTICS
  // ============================================

  /// Log import analytics for developer insights
  Future<void> logImportAnalytics({
    required int totalRows,
    required int successfulImports,
    required int failedRows,
    required List<String> unmappedFields,
    required Map<String, dynamic> fieldSamples,
    required List<String> fileHeaders,
    double? confidenceScore,
    List<String>? warnings,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _supabase.from('import_analytics').insert({
      'user_id': userId,
      'total_rows': totalRows,
      'successful_imports': successfulImports,
      'failed_rows': failedRows,
      'unmapped_fields': unmappedFields,
      'field_samples': fieldSamples,
      'file_headers': fileHeaders,
      'confidence_score': confidenceScore,
      'warnings': warnings,
    });
  }

  /// Create a shift (used by import system)
  Future<void> createShift(Shift shift) async {
    await saveShift(shift);
  }

  /// Get import count for current user
  Future<int> getImportCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    final response = await _supabase
        .from('import_analytics')
        .select('id')
        .eq('user_id', userId);

    return (response as List).length;
  }

  // ============================================
  // CALENDAR TITLE MAPPINGS
  // ============================================

  /// Save calendar title mappings for a job group
  Future<void> saveCalendarTitleMappings({
    required String jobId,
    required List<String> calendarTitles,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    // Delete existing mappings for these titles
    await _supabase
        .from('calendar_title_mappings')
        .delete()
        .eq('user_id', userId)
        .inFilter('calendar_title', calendarTitles);

    // Insert new mappings
    final mappings = calendarTitles
        .map((title) => {
              'user_id': userId,
              'job_id': jobId,
              'calendar_title': title,
            })
        .toList();

    await _supabase.from('calendar_title_mappings').insert(mappings);
  }

  /// Get job ID from calendar title
  Future<String?> getJobIdFromCalendarTitle(String calendarTitle) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('calendar_title_mappings')
          .select('job_id')
          .eq('user_id', userId)
          .eq('calendar_title', calendarTitle)
          .maybeSingle();

      return response?['job_id'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Get all calendar title mappings for the current user
  Future<Map<String, String>> getCalendarTitleMappings() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return {};

    final response = await _supabase
        .from('calendar_title_mappings')
        .select('calendar_title, job_id')
        .eq('user_id', userId);

    final mappings = <String, String>{};
    for (final row in response as List) {
      mappings[row['calendar_title'] as String] = row['job_id'] as String;
    }

    return mappings;
  }

  /// Get unmapped calendar titles (titles that don't have a job mapping)
  Future<List<String>> getUnmappedCalendarTitles(
      List<String> calendarTitles) async {
    final mappings = await getCalendarTitleMappings();
    return calendarTitles
        .where((title) => !mappings.containsKey(title))
        .toList();
  }

  /// Delete calendar title mappings for a job
  Future<void> deleteCalendarTitleMappings(String jobId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('calendar_title_mappings')
        .delete()
        .eq('user_id', userId)
        .eq('job_id', jobId);
  }

  // ============================================
  // EVENT CONTACTS
  // ============================================

  /// Get all event contacts for current user
  Future<List<EventContact>> getEventContacts() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('event_contacts')
        .select()
        .eq('user_id', userId)
        .order('is_favorite', ascending: false)
        .order('name', ascending: true);

    return (response as List).map((e) => EventContact.fromSupabase(e)).toList();
  }

  /// Get event contacts for a specific shift
  Future<List<EventContact>> getEventContactsForShift(String shiftId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('event_contacts')
        .select()
        .eq('user_id', userId)
        .eq('shift_id', shiftId)
        .order('name', ascending: true);

    return (response as List).map((e) => EventContact.fromSupabase(e)).toList();
  }

  /// Get favorite contacts
  Future<List<EventContact>> getFavoriteContacts() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('event_contacts')
        .select()
        .eq('user_id', userId)
        .eq('is_favorite', true)
        .order('name', ascending: true);

    return (response as List).map((e) => EventContact.fromSupabase(e)).toList();
  }

  /// Search contacts by name or company
  Future<List<EventContact>> searchContacts(String query) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('event_contacts')
        .select()
        .eq('user_id', userId)
        .or('name.ilike.%$query%,company.ilike.%$query%')
        .order('name', ascending: true);

    return (response as List).map((e) => EventContact.fromSupabase(e)).toList();
  }

  /// Get contacts by role
  Future<List<EventContact>> getContactsByRole(ContactRole role) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('event_contacts')
        .select()
        .eq('user_id', userId)
        .eq('role', role.toDbString())
        .order('name', ascending: true);

    return (response as List).map((e) => EventContact.fromSupabase(e)).toList();
  }

  /// Save a new event contact
  Future<EventContact> saveEventContact(EventContact contact) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final data = contact.toSupabase();
    data['user_id'] = userId;

    final response =
        await _supabase.from('event_contacts').insert(data).select().single();

    return EventContact.fromSupabase(response);
  }

  /// Update an event contact
  Future<EventContact> updateEventContact(EventContact contact) async {
    if (contact.id == null) throw Exception('Contact ID required for update');

    final response = await _supabase
        .from('event_contacts')
        .update(contact.toSupabase())
        .eq('id', contact.id!)
        .select()
        .single();

    return EventContact.fromSupabase(response);
  }

  /// Delete an event contact
  Future<void> deleteEventContact(String contactId) async {
    await _supabase.from('event_contacts').delete().eq('id', contactId);
  }

  /// Toggle favorite status
  Future<void> toggleContactFavorite(String contactId, bool isFavorite) async {
    await _supabase
        .from('event_contacts')
        .update({'is_favorite': isFavorite}).eq('id', contactId);
  }

  /// Link a contact to a shift
  Future<void> linkContactToShift(String contactId, String shiftId) async {
    await _supabase
        .from('event_contacts')
        .update({'shift_id': shiftId}).eq('id', contactId);
  }

  /// Unlink a contact from a shift (makes it a general directory contact)
  Future<void> unlinkContactFromShift(String contactId) async {
    await _supabase
        .from('event_contacts')
        .update({'shift_id': null}).eq('id', contactId);
  }

  /// Get a single contact by ID
  Future<EventContact?> getEventContact(String contactId) async {
    final response = await _supabase
        .from('event_contacts')
        .select()
        .eq('id', contactId)
        .maybeSingle();

    if (response == null) return null;
    return EventContact.fromSupabase(response);
  }

  // ============================================
  // SHIFT ATTACHMENTS (Universal File Support)
  // ============================================

  /// Upload a file attachment to Supabase Storage
  Future<String> uploadShiftAttachment({
    required String shiftId,
    required File file,
    required String fileName,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    // Create unique file path: userId/shiftId/timestamp_filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '$userId/$shiftId/${timestamp}_$fileName';

    // Upload to Supabase Storage
    await _supabase.storage.from('shift-attachments').upload(
          filePath,
          file,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ),
        );

    return filePath;
  }

  /// Save attachment metadata to database
  Future<ShiftAttachment> saveAttachmentMetadata({
    required String shiftId,
    required String fileName,
    required String filePath,
    required String fileType,
    required int fileSize,
    required String fileExtension,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await _supabase
        .from('shift_attachments')
        .insert({
          'shift_id': shiftId,
          'user_id': userId,
          'file_name': fileName,
          'file_path': filePath,
          'file_type': fileType,
          'file_size': fileSize,
          'file_extension': fileExtension,
        })
        .select()
        .single();

    return ShiftAttachment.fromMap(response);
  }

  /// Get all attachments for a shift
  Future<List<ShiftAttachment>> getShiftAttachments(String shiftId) async {
    final response = await _supabase
        .from('shift_attachments')
        .select()
        .eq('shift_id', shiftId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => ShiftAttachment.fromMap(item))
        .toList();
  }

  /// Delete an attachment (both file and metadata)
  Future<void> deleteAttachment(ShiftAttachment attachment) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    // Delete from storage
    await _supabase.storage
        .from('shift-attachments')
        .remove([attachment.filePath]);

    // Delete metadata
    await _supabase.from('shift_attachments').delete().eq('id', attachment.id);
  }

  /// Get download URL for an attachment
  Future<String> getAttachmentUrl(String filePath) async {
    final url = _supabase.storage
        .from('shift-attachments')
        .createSignedUrl(filePath, 3600); // Valid for 1 hour

    return url;
  }

  /// Download an attachment to local storage
  Future<Uint8List> downloadAttachment(String filePath) async {
    final bytes =
        await _supabase.storage.from('shift-attachments').download(filePath);

    return bytes;
  }

  // ============================================================================
  // CHAT MESSAGES - Cross-device sync
  // ============================================================================

  /// Get chat history from Supabase (ordered by timestamp)
  Future<List<Map<String, dynamic>>> getChatMessages() async {
    final response = await _supabase
        .from('chat_messages')
        .select()
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Save a chat message to Supabase
  Future<void> saveChatMessage(String message, bool isUser) async {
    await _supabase.from('chat_messages').insert({
      'user_id': _supabase.auth.currentUser!.id,
      'message': message,
      'is_user': isUser,
    });
  }

  /// Clear all chat history for current user
  Future<void> clearChatHistory() async {
    await _supabase
        .from('chat_messages')
        .delete()
        .eq('user_id', _supabase.auth.currentUser!.id);
  }

  // ============================================
  // CALENDAR AUTO-EXPORT
  // ============================================

  /// Auto-export shift to calendar if auto-sync is enabled
  Future<void> _autoExportShift(Shift shift) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoSync = prefs.getBool('auto_sync_calendar') ?? false;

      if (!autoSync) return; // Auto-sync disabled

      // Export to calendar based on platform
      String? eventId;
      if (kIsWeb) {
        final googleCalendar = GoogleCalendarService();
        eventId = await googleCalendar.exportShiftToCalendar(shift);
      } else {
        final calendarSync = CalendarSyncService();
        final calendarId = prefs.getString('selected_calendar_id');
        eventId = await calendarSync.exportShiftToCalendar(shift,
            calendarId: calendarId);
      }

      // If we got an event ID and it's different, update the shift
      if (eventId != null && shift.calendarEventId != eventId) {
        await _supabase.from('shifts').update({
          'calendar_event_id': eventId,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', shift.id);
      }
    } catch (e) {
      print('Auto-export to calendar failed: $e');
      // Don't throw - we don't want to fail the shift save if calendar export fails
    }
  }

  // ============================================
  // INVOICES
  // ============================================

  /// Create a new invoice
  Future<String> createInvoice(Map<String, dynamic> invoiceData) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await _supabase
        .from('invoices')
        .insert({
          ...invoiceData,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Get all invoices for user
  Future<List<Map<String, dynamic>>> getInvoices({String? shiftId}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    var query = _supabase.from('invoices').select().eq('user_id', userId);

    if (shiftId != null) {
      query = query.eq('shift_id', shiftId);
    }

    final response = await query.order('invoice_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Update invoice
  Future<void> updateInvoice(
      String invoiceId, Map<String, dynamic> updates) async {
    await _supabase.from('invoices').update({
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', invoiceId);
  }

  /// Delete invoice
  Future<void> deleteInvoice(String invoiceId) async {
    await _supabase.from('invoices').delete().eq('id', invoiceId);
  }

  // ============================================
  // RECEIPTS
  // ============================================

  /// Create a new receipt
  Future<String> createReceipt(Map<String, dynamic> receiptData) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await _supabase
        .from('receipts')
        .insert({
          ...receiptData,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Get all receipts for user
  Future<List<Map<String, dynamic>>> getReceipts({String? shiftId}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    var query = _supabase.from('receipts').select().eq('user_id', userId);

    if (shiftId != null) {
      query = query.eq('shift_id', shiftId);
    }

    final response = await query.order('receipt_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Update receipt
  Future<void> updateReceipt(
      String receiptId, Map<String, dynamic> updates) async {
    await _supabase.from('receipts').update({
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', receiptId);
  }

  /// Delete receipt
  Future<void> deleteReceipt(String receiptId) async {
    await _supabase.from('receipts').delete().eq('id', receiptId);
  }
}
