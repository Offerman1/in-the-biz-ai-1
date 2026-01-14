import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL || 'https://bokdjidrybwxbomemmrg.supabase.co';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseServiceKey) {
  console.error('❌ SUPABASE_SERVICE_ROLE_KEY not found in .env');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: { autoRefreshToken: false, persistSession: false }
});

async function main() {
  console.log('🔧 Creating shift-photos bucket...');
  
  // Check if bucket exists
  const { data: buckets, error: listError } = await supabase.storage.listBuckets();
  
  if (listError) {
    console.error('❌ Error listing buckets:', listError.message);
    process.exit(1);
  }
  
  const existingBucket = buckets?.find(b => b.name === 'shift-photos');
  
  if (existingBucket) {
    console.log('✅ Bucket "shift-photos" already exists!');
  } else {
    // Create the bucket
    const { data, error } = await supabase.storage.createBucket('shift-photos', {
      public: true, // Make it public from the start
      fileSizeLimit: 5242880, // 5MB max per image
      allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/heic']
    });
    
    if (error) {
      console.error('❌ Error creating bucket:', error.message);
      process.exit(1);
    }
    
    console.log('✅ Bucket "shift-photos" created successfully and set to PUBLIC!');
  }

  // List all buckets to verify
  const { data: allBuckets } = await supabase.storage.listBuckets();
  console.log('\nAll buckets:');
  allBuckets?.forEach(b => console.log('  -', b.name, b.public ? '(PUBLIC)' : '(PRIVATE)'));
}

main().catch(console.error);