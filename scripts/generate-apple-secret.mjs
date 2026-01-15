import jwt from 'jsonwebtoken';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ============================================
// APPLE SIGN IN - JWT SECRET GENERATOR
// ============================================
// This script generates the client secret (JWT token)
// needed for Apple Sign In with Supabase
// ============================================

console.log('\n========================================');
console.log('  APPLE SIGN IN - SECRET GENERATOR');
console.log('========================================\n');

// Step 1: Get your credentials
console.log('Enter your Apple Developer credentials:\n');

const teamId = '7SS37WKWSD'; // Your Team ID from the user's message
let keyId = '';
let p8FilePath = '';

// Prompt for Key ID
process.stdout.write('Key ID (10 characters, e.g., ABC123DEFG): ');
process.stdin.once('data', (data) => {
  keyId = data.toString().trim();
  
  // Prompt for .p8 file path
  process.stdout.write('\nPath to .p8 key file (e.g., C:\\Users\\Brandon 2021\\Desktop\\apple-key.p8): ');
  process.stdin.once('data', (data) => {
    p8FilePath = data.toString().trim();
    
    generateSecret(teamId, keyId, p8FilePath);
  });
});

function generateSecret(teamId, keyId, p8FilePath) {
  try {
    console.log('\n========================================');
    console.log('Generating JWT token...');
    console.log('========================================\n');
    
    // Read the .p8 private key file
    if (!fs.existsSync(p8FilePath)) {
      console.error('❌ ERROR: .p8 file not found at:', p8FilePath);
      console.error('\nMake sure you downloaded the key from Apple Developer and saved it.');
      process.exit(1);
    }
    
    const privateKey = fs.readFileSync(p8FilePath, 'utf8');
    
    // JWT payload
    const payload = {
      iss: teamId,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 15777000, // 6 months (Apple recommends max 6 months)
      aud: 'https://appleid.apple.com',
      sub: 'com.inthebiz.app.auth' // Your Services ID
    };
    
    // Generate JWT
    const token = jwt.sign(payload, privateKey, {
      algorithm: 'ES256',
      keyid: keyId
    });
    
    console.log('✅ SUCCESS! Your client secret (JWT token):\n');
    console.log('========================================');
    console.log(token);
    console.log('========================================\n');
    
    console.log('📋 Copy this token and paste it into Supabase:');
    console.log('   Go to: https://app.supabase.com/project/bokdjidrybwxbomemmrg/auth/providers');
    console.log('   Find "Apple" → paste into "Secret Key (for OAuth)" field\n');
    
    console.log('⚠️  NOTE: This token expires in 6 months.');
    console.log('   You\'ll need to regenerate it before:', new Date(Date.now() + 15777000000).toLocaleDateString());
    console.log('\n========================================\n');
    
    process.exit(0);
    
  } catch (error) {
    console.error('\n❌ ERROR:', error.message);
    console.error('\nMake sure:');
    console.error('1. The .p8 file path is correct');
    console.error('2. The Key ID is correct');
    console.error('3. The Team ID is correct');
    console.error('4. The jsonwebtoken package is installed (npm install jsonwebtoken)\n');
    process.exit(1);
  }
}
