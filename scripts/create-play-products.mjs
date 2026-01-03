/**
 * Create Google Play subscription products via API
 * Requires: Service account JSON from RevenueCat setup
 */

import { google } from 'googleapis';
import fs from 'fs';
import path from 'path';

// Configuration
const PACKAGE_NAME = 'com.inthebiz.app';
const SERVICE_ACCOUNT_PATH = './play-service-account.json'; // You'll create this file

// Subscription products to create - MUST match RevenueCat format
const PRODUCTS = [
  {
    productId: 'pro_monthly',
    basePlanId: 'monthly-plan', // Must match RevenueCat: pro_monthly:monthly-plan
    price: {
      priceMicros: '4990000', // $4.99 in micros
      currency: 'USD',
    },
    billingPeriod: 'P1M', // ISO 8601 duration: 1 month
    title: 'Pro Monthly',
    description: 'Unlimited shifts & AI features',
  },
  {
    productId: 'pro_yearly',
    basePlanId: 'yearly-plan', // Must match RevenueCat: pro_yearly:yearly-plan
    price: {
      priceMicros: '49990000', // $49.99 in micros
      currency: 'USD',
    },
    billingPeriod: 'P1Y', // ISO 8601 duration: 1 year
    title: 'Pro Yearly',
    description: 'Unlimited shifts & AI. Save $10!',
  },
];

async function createSubscriptionProducts() {
  try {
    // Load service account credentials
    const serviceAccountPath = path.resolve(SERVICE_ACCOUNT_PATH);
    if (!fs.existsSync(serviceAccountPath)) {
      console.error(`❌ Service account file not found: ${serviceAccountPath}`);
      console.log('\n📝 Create a file named "play-service-account.json" with your service account JSON');
      console.log('   (The same JSON you uploaded to RevenueCat)');
      process.exit(1);
    }

    const credentials = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));

    // Initialize Google Play Developer API client
    const auth = new google.auth.GoogleAuth({
      credentials,
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });

    const androidPublisher = google.androidpublisher({
      version: 'v3',
      auth,
    });

    console.log('🚀 Creating subscription products in Google Play...\n');

    for (const product of PRODUCTS) {
      try {
        console.log(`Creating: ${product.title} (${product.productId})...`);

        // Create subscription
        const response = await androidPublisher.monetization.subscriptions.create({
          packageName: PACKAGE_NAME,
          productId: product.productId,
          'regionsVersion.version': '2022/02',
          requestBody: {
            packageName: PACKAGE_NAME,
            productId: product.productId,
            listings: [
              {
                languageCode: 'en-US',
                title: product.title,
                benefits: [product.description],
              },
            ],
            basePlans: [
              {
                basePlanId: product.basePlanId,
                state: 'ACTIVE',
                autoRenewingBasePlanType: {
                  billingPeriodDuration: product.billingPeriod,
                },
                regionalConfigs: [
                  {
                    regionCode: 'US',
                    newSubscriberAvailability: true,
                    price: {
                      units: product.price.priceMicros.slice(0, -6),
                      nanos: parseInt(product.price.priceMicros.slice(-6)) * 1000,
                      currencyCode: product.price.currency,
                    },
                  },
                ],
              },
            ],
          },
        });

        console.log(`✅ Created: ${product.title}`);
        console.log(`   Product ID: ${response.data.productId}`);
        console.log(`   Base Plan ID: ${response.data.basePlans[0].basePlanId}\n`);
      } catch (error) {
        if (error.code === 409) {
          console.log(`⚠️  Already exists: ${product.title}\n`);
        } else {
          console.error(`❌ Failed to create ${product.title}:`, error.message);
        }
      }
    }

    console.log('\n✅ Done! Subscription products created in Google Play Console.');
    console.log('\n📝 Next steps:');
    console.log('1. Go to https://play.google.com/console/');
    console.log('2. Navigate to Monetization → Subscriptions');
    console.log('3. Verify your products are listed');
    console.log('4. Link them in RevenueCat dashboard (Projects → Products)');
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

createSubscriptionProducts();
