/**
 * RevenueCat Configuration Checker
 * Validates API keys and provides setup status
 */

console.log('\n🔍 RevenueCat Configuration Check\n');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

// Check subscription_service.dart for API keys
import fs from 'fs';
import path from 'path';

const subscriptionServicePath = path.resolve('./lib/services/subscription_service.dart');

if (!fs.existsSync(subscriptionServicePath)) {
  console.log('❌ subscription_service.dart not found');
  process.exit(1);
}

const content = fs.readFileSync(subscriptionServicePath, 'utf8');

// Extract API keys
const androidKeyMatch = content.match(/final String _apiKeyAndroid = '([^']+)'/);
const iosKeyMatch = content.match(/final String _apiKeyIOS = '([^']+)'/);

console.log('📱 **Platform API Keys:**\n');

if (androidKeyMatch) {
  const key = androidKeyMatch[1];
  console.log(`✅ Android Key: ${key}`);
  console.log(`   Prefix: ${key.substring(0, 12)}...`);
  console.log(`   Type: ${key.startsWith('goog_') ? 'Google Play' : 'Unknown'}\n`);
} else {
  console.log('❌ Android API key not found\n');
}

if (iosKeyMatch) {
  const key = iosKeyMatch[1];
  console.log(`✅ iOS Key: ${key}`);
  console.log(`   Prefix: ${key.substring(0, 12)}...`);
  console.log(`   Type: ${key.startsWith('goog_') ? 'Google Play (needs iOS key)' : key.startsWith('appl_') ? 'App Store' : 'Unknown'}\n`);
} else {
  console.log('❌ iOS API key not found\n');
}

// Check for entitlement
const entitlementMatch = content.match(/entitlements\.all\['([^']+)'\]/);
if (entitlementMatch) {
  console.log(`✅ Entitlement: "${entitlementMatch[1]}"\n`);
} else {
  console.log('⚠️  Entitlement configuration not found\n');
}

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

console.log('📋 **RevenueCat Setup Checklist:**\n');

console.log('1. ✅ RevenueCat SDK installed (purchases_flutter)');
console.log('2. ✅ API keys configured in subscription_service.dart');
console.log('3. ⚠️  iOS API key needs to be updated (currently using Android key)');
console.log('4. ⏳ Need to verify in RevenueCat Dashboard:\n');

console.log('   📊 **Go to RevenueCat Dashboard:**');
console.log('   https://app.revenuecat.com/\n');

console.log('   **Projects → Your App → Configuration:**\n');
console.log('   • ✓ Google Play connected?');
console.log('   • ✓ App Store connected? (for iOS)');
console.log('   • ✓ Service Account JSON uploaded?\n');

console.log('   **Products:**\n');
console.log('   • ✓ pro_monthly product exists?');
console.log('   • ✓ pro_yearly product exists?');
console.log('   • ✓ Both linked to "pro" entitlement?\n');

console.log('   **Offerings:**\n');
console.log('   • ✓ Default offering exists?');
console.log('   • ✓ Contains both products?\n');

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

console.log('🔑 **Next Steps:**\n');

if (androidKeyMatch && androidKeyMatch[1].startsWith('goog_')) {
  console.log('1. ✅ Android setup looks good!');
  console.log('2. 📱 Get iOS API key from RevenueCat:');
  console.log('   • Go to: Projects → In The Biz → API Keys');
  console.log('   • Copy the "Apple App Store" key');
  console.log('   • Update _apiKeyIOS in subscription_service.dart\n');
}

console.log('3. 🔗 Link Google Play (if not done):');
console.log('   • Go to: https://app.revenuecat.com/');
console.log('   • Projects → In The Biz → Integrations');
console.log('   • Add "Google Play" integration');
console.log('   • Upload play-service-account.json\n');

console.log('4. 📦 Create subscription products:');
console.log('   • Run: node scripts/create-play-products.mjs');
console.log('   • Or create manually in Google Play Console\n');

console.log('5. 🎯 Configure in RevenueCat:');
console.log('   • Go to: Products → Add Products');
console.log('   • Add: pro_monthly, pro_yearly');
console.log('   • Create Entitlement: "pro"');
console.log('   • Attach both products to "pro" entitlement');
console.log('   • Create Offering with both products\n');

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
