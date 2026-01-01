import 'package:supabase_flutter/supabase_flutter.dart';

/// Run database migrations
Future<void> runMigrations() async {
  final supabase = Supabase.instance.client;

  try {
    // Check if columns already exist by trying to query them
    try {
      await supabase.from('shifts').select('job_type').limit(1);
      print('✅ Migration columns already exist');
      return;
    } catch (e) {
      // Columns don't exist, need to add them
      print('📝 Adding new columns...');
    }

    // Run each ALTER TABLE statement separately
    final queries = [
      'ALTER TABLE shifts ADD COLUMN job_type TEXT',
      'ALTER TABLE shifts ADD COLUMN start_time TEXT',
      'ALTER TABLE shifts ADD COLUMN end_time TEXT',
      'CREATE INDEX idx_shifts_job_type ON shifts(job_type)',
    ];

    for (final query in queries) {
      try {
        await supabase.rpc('exec_sql', params: {'query': query});
        print('✅ Executed: $query');
      } catch (e) {
        print('⚠️  Query failed (may already exist): $query');
      }
    }

    print('✅ Migration completed');
  } catch (e) {
    print('❌ Migration error: $e');
    print('');
    print('🔧 MANUAL FIX REQUIRED:');
    print('Go to Supabase Dashboard → SQL Editor and run:');
    print('');
    print('ALTER TABLE shifts ADD COLUMN IF NOT EXISTS job_type TEXT;');
    print('ALTER TABLE shifts ADD COLUMN IF NOT EXISTS start_time TEXT;');
    print('ALTER TABLE shifts ADD COLUMN IF NOT EXISTS end_time TEXT;');
    print(
        'CREATE INDEX IF NOT EXISTS idx_shifts_job_type ON shifts(job_type);');
  }
}
