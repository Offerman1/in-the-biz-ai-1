// Create scan-images storage bucket in Supabase
// Run: node scripts/create-scan-images-bucket.mjs

import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL || 'https://bokdjidrybwxbomemmrg.supabase.co';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseServiceKey) {
  console.error('❌ SUPABASE_SERVICE_ROLE_KEY not found in .env');
  console.log('Add it to your .env file:');
  console.log('SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: { autoRefreshToken: false, persistSession: false }
});

async function createBucket() {
  console.log('🔧 Creating scan-images bucket...');
  
  // Check if bucket exists
  const { data: buckets, error: listError } = await supabase.storage.listBuckets();
  
  if (listError) {
    console.error('❌ Error listing buckets:', listError.message);
    process.exit(1);
  }
  
  const existingBucket = buckets?.find(b => b.name === 'scan-images');
  
  if (existingBucket) {
    console.log('✅ Bucket "scan-images" already exists!');
    return;
  }
  
  // Create the bucket
  const { data, error } = await supabase.storage.createBucket('scan-images', {
    public: false,
    fileSizeLimit: 5242880, // 5MB max per image
    allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/heic']
  });
  
  if (error) {
    console.error('❌ Error creating bucket:', error.message);
    process.exit(1);
  }
  
  console.log('✅ Bucket "scan-images" created successfully!');
  console.log('');
  console.log('📋 Next step: Add RLS policies in Supabase Dashboard:');
  console.log('   1. Go to Storage > scan-images > Policies');
  console.log('   2. Add SELECT policy: authenticated users can read their own files');
  console.log('   3. Add INSERT policy: authenticated users can upload to their own folder');
  console.log('   4. Add DELETE policy: authenticated users can delete their own files');
}

createBucket().catch(console.error);
