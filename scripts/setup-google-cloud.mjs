/**
 * Interactive Google Cloud Service Account Setup
 * Creates a service account and downloads the key for Google Play API access
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import readline from 'readline';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(prompt) {
  return new Promise((resolve) => {
    rl.question(prompt, resolve);
  });
}

function executeCommand(command, errorMessage) {
  try {
    const result = execSync(command, { encoding: 'utf8', stdio: 'pipe' });
    return result.trim();
  } catch (error) {
    console.error(`❌ ${errorMessage}`);
    console.error(`Error: ${error.message}`);
    return null;
  }
}

async function main() {
  console.log('\n🚀 Google Cloud Service Account Setup\n');
  console.log('This script will:');
  console.log('  1. Check if gcloud CLI is installed');
  console.log('  2. Create a service account for Google Play API');
  console.log('  3. Grant necessary permissions');
  console.log('  4. Download the service account key\n');

  // Check if gcloud is installed
  console.log('📦 Checking for Google Cloud CLI...');
  const gcloudVersion = executeCommand('gcloud --version', 'gcloud CLI not found');
  
  if (!gcloudVersion) {
    console.log('\n❌ Google Cloud CLI is not installed.');
    console.log('\n📥 Install it from: https://cloud.google.com/sdk/docs/install');
    console.log('   After installation, run: gcloud init');
    process.exit(1);
  }
  
  console.log('✅ Google Cloud CLI found\n');

  // Get current project
  const currentProject = executeCommand('gcloud config get-value project', 'Could not get current project');
  
  if (!currentProject || currentProject === '(unset)') {
    console.log('❌ No Google Cloud project is set.');
    console.log('\n🔧 Set a project with: gcloud config set project YOUR_PROJECT_ID');
    console.log('   Or create a new project at: https://console.cloud.google.com/projectcreate');
    process.exit(1);
  }

  console.log(`📁 Current project: ${currentProject}`);
  const confirmProject = await question(`\nUse this project? (y/n): `);
  
  if (confirmProject.toLowerCase() !== 'y') {
    console.log('\n🔧 Set a different project with: gcloud config set project YOUR_PROJECT_ID');
    process.exit(0);
  }

  // Service account details
  const serviceAccountName = 'play-console-api';
  const serviceAccountEmail = `${serviceAccountName}@${currentProject}.iam.gserviceaccount.com`;
  const keyFilePath = path.resolve('./play-service-account.json');

  console.log('\n📝 Creating service account...');
  
  // Check if service account already exists
  const existingAccount = executeCommand(
    `gcloud iam service-accounts describe ${serviceAccountEmail} 2>&1`,
    null
  );

  if (existingAccount && !existingAccount.includes('ERROR')) {
    console.log('⚠️  Service account already exists');
    const recreate = await question('Delete and recreate? (y/n): ');
    
    if (recreate.toLowerCase() === 'y') {
      console.log('🗑️  Deleting existing service account...');
      executeCommand(
        `gcloud iam service-accounts delete ${serviceAccountEmail} --quiet`,
        'Failed to delete service account'
      );
    } else {
      console.log('✅ Using existing service account');
    }
  }

  // Create service account if it doesn't exist
  if (!existingAccount || existingAccount.includes('ERROR')) {
    const createResult = executeCommand(
      `gcloud iam service-accounts create ${serviceAccountName} --display-name="Google Play Console API" --description="Service account for accessing Google Play Console API"`,
      'Failed to create service account'
    );

    if (createResult !== null) {
      console.log('✅ Service account created');
    }
  }

  // Enable required APIs
  console.log('\n🔌 Enabling required APIs...');
  const apis = [
    'androidpublisher.googleapis.com',
    'iam.googleapis.com'
  ];

  for (const api of apis) {
    console.log(`  - Enabling ${api}...`);
    executeCommand(
      `gcloud services enable ${api} --project=${currentProject}`,
      `Failed to enable ${api}`
    );
  }
  console.log('✅ APIs enabled');

  // Delete existing key file if it exists
  if (fs.existsSync(keyFilePath)) {
    console.log('\n⚠️  Existing key file found');
    const deleteKey = await question('Delete and create new key? (y/n): ');
    
    if (deleteKey.toLowerCase() === 'y') {
      fs.unlinkSync(keyFilePath);
      console.log('🗑️  Old key deleted');
    } else {
      console.log('\n✅ Setup complete! Using existing key file.');
      rl.close();
      return;
    }
  }

  // Create and download key
  console.log('\n🔑 Creating service account key...');
  const keyResult = executeCommand(
    `gcloud iam service-accounts keys create ${keyFilePath} --iam-account=${serviceAccountEmail}`,
    'Failed to create service account key'
  );

  if (keyResult !== null && fs.existsSync(keyFilePath)) {
    console.log('✅ Service account key created');
    console.log(`📁 Saved to: ${keyFilePath}`);
  } else {
    console.log('❌ Failed to create key file');
    process.exit(1);
  }

  // Verify .gitignore
  const gitignorePath = path.resolve('./.gitignore');
  if (fs.existsSync(gitignorePath)) {
    const gitignoreContent = fs.readFileSync(gitignorePath, 'utf8');
    if (!gitignoreContent.includes('play-service-account.json')) {
      console.log('\n⚠️  Warning: play-service-account.json not in .gitignore');
      console.log('   (This should already be added)');
    }
  }

  console.log('\n✅ Setup complete!');
  console.log('\n📋 Next steps:');
  console.log('   1. Go to Google Play Console: https://play.google.com/console');
  console.log('   2. Go to: Setup > API access');
  console.log(`   3. Link this service account: ${serviceAccountEmail}`);
  console.log('   4. Grant "Admin (all permissions)" access');
  console.log('   5. Run: node scripts/create-play-products.mjs');
  console.log('\n🔒 Security reminder:');
  console.log('   - NEVER commit play-service-account.json to Git');
  console.log('   - Keep this file secure and private');
  console.log('   - Rotate keys regularly (every 90 days recommended)\n');

  rl.close();
}

main().catch(error => {
  console.error('\n❌ Error:', error.message);
  rl.close();
  process.exit(1);
});
