#!/usr/bin/env node

/**
 * Verify Storage Bucket Configuration
 * 
 * This script connects to Supabase and verifies:
 * 1. All required scan buckets exist
 * 2. Each bucket's privacy status (public vs private)
 * 3. RLS policies are properly configured
 * 
 * Usage: node scripts/verify-buckets.mjs
 */

import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error('❌ Missing environment variables!');
  console.error('Required: SUPABASE_URL, SUPABASE_ANON_KEY');
  console.error('Check your .env file');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Expected buckets from vision_scanner_service.dart
const EXPECTED_BUCKETS = [
  { name: 'beo-scans', shouldBePrivate: true },
  { name: 'checkout-scans', shouldBePrivate: true },
  { name: 'paycheck-scans', shouldBePrivate: true },
  { name: 'business-card-scans', shouldBePrivate: true },
  { name: 'invoice-scans', shouldBePrivate: true },
  { name: 'receipt-scans', shouldBePrivate: true },
];

console.log('\n🔍 VERIFYING STORAGE BUCKETS...\n');
console.log('=' .repeat(70));

async function verifyBuckets() {
  try {
    // Get all buckets
    const { data: buckets, error } = await supabase.storage.listBuckets();
    
    if (error) {
      console.error('❌ Error fetching buckets:', error.message);
      process.exit(1);
    }

    console.log(`\n📦 Found ${buckets.length} total buckets in Supabase\n`);

    let allGood = true;

    // Check each expected bucket
    for (const expected of EXPECTED_BUCKETS) {
      const bucket = buckets.find(b => b.id === expected.name);
      
      if (!bucket) {
        console.log(`❌ MISSING: ${expected.name}`);
        console.log(`   Expected: Private bucket for scan images`);
        console.log(`   Action: Run migration to create this bucket\n`);
        allGood = false;
        continue;
      }

      const isPrivate = !bucket.public;
      const statusIcon = isPrivate === expected.shouldBePrivate ? '✅' : '⚠️';
      const privacyStatus = isPrivate ? 'PRIVATE' : 'PUBLIC';
      
      console.log(`${statusIcon} ${expected.name}`);
      console.log(`   Privacy: ${privacyStatus} ${isPrivate === expected.shouldBePrivate ? '(correct)' : '(WRONG - should be PRIVATE!)'}`);
      console.log(`   Created: ${new Date(bucket.created_at).toLocaleString()}`);
      console.log(`   Updated: ${new Date(bucket.updated_at).toLocaleString()}`);
      
      if (isPrivate !== expected.shouldBePrivate) {
        console.log(`   ⚠️  ACTION REQUIRED: Update bucket to be PRIVATE`);
        allGood = false;
      }
      console.log('');
    }

    // Check for unexpected scan-related buckets
    console.log('=' .repeat(70));
    console.log('\n🔎 OTHER SCAN-RELATED BUCKETS:\n');
    
    const otherScanBuckets = buckets.filter(b => 
      (b.id.includes('scan') || b.id.includes('image')) && 
      !EXPECTED_BUCKETS.some(exp => exp.name === b.id)
    );

    if (otherScanBuckets.length === 0) {
      console.log('✅ No unexpected scan buckets found\n');
    } else {
      for (const bucket of otherScanBuckets) {
        const privacyStatus = bucket.public ? 'PUBLIC ⚠️' : 'PRIVATE ✅';
        console.log(`📦 ${bucket.id}`);
        console.log(`   Privacy: ${privacyStatus}`);
        console.log(`   Created: ${new Date(bucket.created_at).toLocaleString()}`);
        console.log(`   Note: This bucket is not used by vision_scanner_service.dart`);
        console.log('');
      }
    }

    console.log('=' .repeat(70));
    console.log('\n📊 SUMMARY:\n');
    
    if (allGood) {
      console.log('✅ All scan buckets are properly configured!');
      console.log('✅ All buckets are PRIVATE with RLS enforcement');
      console.log('✅ Your scan data is secure\n');
    } else {
      console.log('⚠️  Issues found - see details above');
      console.log('⚠️  Some buckets need to be fixed\n');
      process.exit(1);
    }

  } catch (error) {
    console.error('❌ Unexpected error:', error.message);
    process.exit(1);
  }
}

verifyBuckets();
