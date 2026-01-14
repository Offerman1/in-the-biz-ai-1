import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const client = new pg.Client({
  connectionString: process.env.DATABASE_URL,
});

async function main() {
  await client.connect();
  
  console.log('🔍 COMPLETE BUCKET AUDIT - CHECKING ALL EXISTING BUCKETS:');
  console.log('==================================================');
  
  // Get ALL buckets with their public status
  const buckets = await client.query('SELECT name, public, created_at FROM storage.buckets ORDER BY name');
  
  console.log(`Found ${buckets.rows.length} buckets:\n`);
  
  buckets.rows.forEach(b => {
    const status = b.public ? '🚨 PUBLIC (VIOLATION)' : '✅ PRIVATE (SAFE)';
    console.log(`${status} - ${b.name}`);
  });
  
  console.log('\n==================================================');
  console.log('PUBLIC BUCKETS THAT NEED TO BE MADE PRIVATE:');
  const publicBuckets = buckets.rows.filter(b => b.public);
  if (publicBuckets.length === 0) {
    console.log('✅ No public buckets found');
  } else {
    publicBuckets.forEach(b => {
      console.log(`🚨 ${b.name} - MAKE PRIVATE NOW`);
    });
  }
  
  await client.end();
}

main().catch(e => {
  console.error('Error:', e.message);
  client.end();
});