import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const client = new pg.Client({
  connectionString: process.env.DATABASE_URL,
});

async function main() {
  await client.connect();
  
  // Make shift-photos bucket public
  const result = await client.query(
    "UPDATE storage.buckets SET public = true WHERE name = 'shift-photos'"
  );
  console.log('Updated shift-photos bucket to PUBLIC. Rows affected:', result.rowCount);
  
  // Verify all buckets
  const buckets = await client.query('SELECT name, public FROM storage.buckets ORDER BY name');
  console.log('\nAll buckets:');
  buckets.rows.forEach(b => console.log('  -', b.name, b.public ? '(PUBLIC)' : '(PRIVATE)'));
  
  await client.end();
}

main().catch(e => {
  console.error('Error:', e.message);
  client.end();
});