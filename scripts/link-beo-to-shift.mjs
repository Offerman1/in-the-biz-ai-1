import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const client = new pg.Client({
  connectionString: process.env.DATABASE_URL,
});

async function main() {
  await client.connect();
  
  // Get first BEO for BASS United
  const beo = await client.query("SELECT id FROM beo_events WHERE event_name = 'BASS United' LIMIT 1");
  
  if (beo.rows.length > 0) {
    const beoId = beo.rows[0].id;
    console.log('Found BEO:', beoId.substring(0, 8));
    
    // Update shifts to link to this BEO
    const result = await client.query(
      "UPDATE shifts SET beo_event_id = $1 WHERE event_name = 'BASS United' AND beo_event_id IS NULL RETURNING id",
      [beoId]
    );
    console.log('Updated', result.rowCount, 'shifts to link to BEO');
  } else {
    console.log('No BEO found');
  }
  
  await client.end();
}

main().catch(e => {
  console.error('Error:', e.message);
  client.end();
});
