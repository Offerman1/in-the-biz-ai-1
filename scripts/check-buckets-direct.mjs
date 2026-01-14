#!/usr/bin/env node
/**
 * Direct database query to verify storage buckets
 * Uses PostgreSQL connection to query storage.buckets table
 */

import pg from 'pg';
import { config } from 'dotenv';
import path from 'path';

config({ path: path.resolve(process.cwd(), '.env') });

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  console.error('❌ Missing DATABASE_URL in .env');
  process.exit(1);
}

console.log('\n🔍 QUERYING STORAGE.BUCKETS TABLE DIRECTLY...\n');
console.log('=' .repeat(80));

try {
  const client = new pg.Client({ 
    connectionString: databaseUrl, 
    ssl: { rejectUnauthorized: false } 
  });

  await client.connect();
  console.log('✅ Connected to PostgreSQL database\n');
  
  // Query all buckets
  const result = await client.query(`
    SELECT 
      id,
      name,
      public,
      created_at,
      updated_at,
      file_size_limit,
      allowed_mime_types
    FROM storage.buckets
    ORDER BY created_at;
  `);

  console.log(`📦 FOUND ${result.rows.length} STORAGE BUCKETS:\n`);

  result.rows.forEach((bucket, index) => {
    const privacyIcon = bucket.public ? '⚠️  PUBLIC' : '✅ PRIVATE';
    const sizeLimit = bucket.file_size_limit ? `${(bucket.file_size_limit / 1048576).toFixed(0)}MB` : 'Unset';
    
    console.log(`${index + 1}. ${bucket.name}`);
    console.log(`   ID: ${bucket.id}`);
    console.log(`   Privacy: ${privacyIcon}`);
    console.log(`   File Size Limit: ${sizeLimit}`);
    console.log(`   MIME Types: ${bucket.allowed_mime_types?.join(', ') || 'Any'}`);
    console.log(`   Created: ${new Date(bucket.created_at).toLocaleString()}`);
    console.log(`   Updated: ${new Date(bucket.updated_at).toLocaleString()}`);
    console.log('');
  });

  // Check for scan buckets specifically
  console.log('=' .repeat(80));
  console.log('\n🎯 SCAN BUCKETS CHECK:\n');
  
  const scanBuckets = [
    'beo-scans',
    'checkout-scans', 
    'paycheck-scans',
    'business-card-scans',
    'invoice-scans',
    'receipt-scans'
  ];

  scanBuckets.forEach(bucketName => {
    const found = result.rows.find(b => b.id === bucketName);
    if (found) {
      const status = found.public ? '⚠️  PUBLIC (WRONG!)' : '✅ PRIVATE (CORRECT)';
      console.log(`✅ ${bucketName.padEnd(25)} ${status}`);
    } else {
      console.log(`❌ ${bucketName.padEnd(25)} MISSING`);
    }
  });

  console.log('\n' + '=' .repeat(80) + '\n');

  await client.end();
} catch (err) {
  console.error('❌ Database query failed:', err.message);
  process.exit(1);
}
