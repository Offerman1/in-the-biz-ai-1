import pg from 'pg';
import { readFileSync } from 'fs';
import { config } from 'dotenv';
import path from 'path';

// Load .env from project root
config({ path: path.resolve(process.cwd(), '.env') });

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  console.error('❌ Missing DATABASE_URL in .env');
  console.error('Add: DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[PROJECT].supabase.co:5432/postgres');
  process.exit(1);
}

const sqlFile = process.argv[2];
if (!sqlFile) {
  console.error('Usage: node scripts/run-migration.mjs <file.sql>');
  process.exit(1);
}

console.log(`Running migration: ${sqlFile}...`);

try {
  const sql = readFileSync(sqlFile, 'utf-8');
  const client = new pg.Client({ connectionString: databaseUrl, ssl: { rejectUnauthorized: false } });

  await client.connect();
  console.log('Connected to database.');
  
  await client.query('BEGIN');
  try {
    await client.query(sql);
    await client.query('COMMIT');
    console.log('✅ Migration successful!');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Failed:', err.message);
    process.exit(1);
  } finally {
    await client.end();
  }
} catch (err) {
  console.error('❌ Error reading file or connecting:', err.message);
  process.exit(1);
}
