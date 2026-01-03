/**
 * Upload app bundle to Google Play Console and create a release
 */

import { google } from 'googleapis';
import fs from 'fs';
import path from 'path';

const PACKAGE_NAME = 'com.inthebiz.app';
const SERVICE_ACCOUNT_PATH = './play-service-account.json';
const AAB_PATH = './build/app/outputs/bundle/release/app-release.aab';
const TRACK = 'internal'; // internal, alpha, beta, or production

async function uploadRelease() {
  try {
    console.log('🚀 Uploading app bundle to Google Play...\n');

    // Check if AAB file exists
    if (!fs.existsSync(AAB_PATH)) {
      console.error(`❌ App bundle not found at: ${AAB_PATH}`);
      console.error('   Run: flutter build appbundle --release');
      return;
    }

    const credentials = JSON.parse(fs.readFileSync(SERVICE_ACCOUNT_PATH, 'utf8'));
    
    const auth = new google.auth.GoogleAuth({
      credentials,
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });

    const authClient = await auth.getClient();
    const androidPublisher = google.androidpublisher({
      version: 'v3',
      auth: authClient,
    });

    // Step 1: Create a new edit
    console.log('📝 Creating edit...');
    const editResponse = await androidPublisher.edits.insert({
      packageName: PACKAGE_NAME,
    });
    const editId = editResponse.data.id;
    console.log(`✅ Edit created: ${editId}\n`);

    // Step 2: Upload the bundle
    console.log('📤 Uploading app bundle...');
    const uploadResponse = await androidPublisher.edits.bundles.upload({
      packageName: PACKAGE_NAME,
      editId,
      media: {
        mimeType: 'application/octet-stream',
        body: fs.createReadStream(AAB_PATH),
      },
    });
    
    const versionCode = uploadResponse.data.versionCode;
    console.log(`✅ Bundle uploaded successfully!`);
    console.log(`   Version code: ${versionCode}\n`);

    // Step 3: Assign to track
    console.log(`🎯 Assigning to ${TRACK} track...`);
    await androidPublisher.edits.tracks.update({
      packageName: PACKAGE_NAME,
      editId,
      track: TRACK,
      requestBody: {
        track: TRACK,
        releases: [{
          versionCodes: [versionCode.toString()],
          status: 'draft', // Use 'draft' for apps not yet published
          releaseNotes: [{
            language: 'en-US',
            text: 'Bug fixes and performance improvements',
          }],
        }],
      },
    });
    console.log(`✅ Assigned to ${TRACK} track\n`);

    // Step 4: Commit the edit
    console.log('💾 Committing changes...');
    await androidPublisher.edits.commit({
      packageName: PACKAGE_NAME,
      editId,
    });
    console.log('✅ Changes committed successfully!\n');

    console.log('🎉 Release created successfully!');
    console.log(`📱 App bundle version ${versionCode} is now live on ${TRACK} track`);
    console.log(`🔗 View in Play Console: https://play.google.com/console/\n`);

  } catch (error) {
    console.error('\n❌ Upload failed:');
    console.error(`   ${error.message}`);
    
    if (error.message.includes('conflicts with another edit')) {
      console.error('\n💡 Solution: Close any open edits in Play Console first');
    }
  }
}

uploadRelease();
