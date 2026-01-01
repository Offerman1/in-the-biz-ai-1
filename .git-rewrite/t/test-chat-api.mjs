// Test script to verify the chat API is working
import https from 'https';

const SUPABASE_URL = 'https://bokdjidrybwxbomemmrg.supabase.co/functions/v1';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJva2RqaWRyeWJ3eGJvbWVtbXJnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY2Mjc1MzcsImV4cCI6MjA4MjIwMzUzN30.SVdK-fKrQklp76pGozuaDyNsgp2vkwWfNYtdmDRjChs';

async function testChatAPI() {
  console.log('🧪 Testing Chat API...\n');

  const testMessage = 'Hello, how much did I make last week?';
  
  const data = JSON.stringify({
    message: testMessage,
    history: []
  });

  const options = {
    hostname: 'bokdjidrybwxbomemmrg.supabase.co',
    port: 443,
    path: '/functions/v1/chat',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${ANON_KEY}`,
      'Content-Length': data.length
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let body = '';

      res.on('data', (chunk) => {
        body += chunk;
      });

      res.on('end', () => {
        console.log(`Status Code: ${res.statusCode}`);
        console.log(`Response Headers:`, res.headers);
        console.log(`Response Body: ${body}\n`);

        if (res.statusCode === 200) {
          try {
            const parsed = JSON.parse(body);
            if (parsed.success) {
              console.log('✅ Chat API is working!');
              console.log(`AI Response: "${parsed.reply}"\n`);
              resolve(true);
            } else {
              console.log('❌ Chat API returned error:', parsed.error);
              resolve(false);
            }
          } catch (e) {
            console.log('❌ Failed to parse response:', e.message);
            resolve(false);
          }
        } else {
          console.log('❌ Chat API returned non-200 status');
          resolve(false);
        }
      });
    });

    req.on('error', (error) => {
      console.error('❌ Network Error:', error.message);
      reject(error);
    });

    req.write(data);
    req.end();
  });
}

// Run the test
testChatAPI()
  .then(() => {
    console.log('Test complete!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Test failed:', error);
    process.exit(1);
  });
