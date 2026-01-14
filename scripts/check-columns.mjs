import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const client = new pg.Client({
  connectionString: process.env.DATABASE_URL,
});

async function main() {
  await client.connect();
  const result = await client.query(`
    SELECT column_name 
    FROM information_schema.columns 
    WHERE table_name = 'shifts' 
    AND column_name IN ('beo_event_id', 'section', 'checkout_id', 'shift_hidden_sections')
  `);
  console.log('Columns found:');
  result.rows.forEach(r => console.log('  -', r.column_name));
  await client.end();
}

main().catch(e => {
  console.error('Error:', e.message);
  client.end();
});
