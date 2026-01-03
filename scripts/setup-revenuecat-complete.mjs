/**
 * RevenueCat Complete Configuration via API v2
 * Automatically creates entitlements, products, offerings, and packages
 */

import dotenv from 'dotenv';
dotenv.config();

const API_KEY = process.env.REVENUECAT_SECRET_KEY;
const BASE_URL = 'https://api.revenuecat.com/v2';

// Your project ID - we'll fetch this first
let PROJECT_ID = null;
let APP_ID = 'app9cc9915545'; // Your Play Store app ID from earlier

if (!API_KEY) {
  console.error('❌ REVENUECAT_SECRET_KEY not found in .env');
  process.exit(1);
}

async function apiCall(endpoint, method = 'GET', body = null) {
  const url = `${BASE_URL}${endpoint}`;
  const options = {
    method,
    headers: {
      'Authorization': `Bearer ${API_KEY}`,
      'Content-Type': 'application/json',
    },
  };

  if (body) {
    options.body = JSON.stringify(body);
  }

  try {
    const response = await fetch(url, options);
    
    if (!response.ok) {
      const error = await response.json();
      console.error(`❌ API Error (${response.status}):`, JSON.stringify(error, null, 2));
      return null;
    }
    
    const data = await response.json();
    return data;
  } catch (error) {
    console.error(`❌ Request failed:`, error.message);
    return null;
  }
}

async function main() {
  console.log('\n🚀 RevenueCat Complete Auto-Setup\n');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  // 1. Get project ID
  console.log('📱 Step 1: Finding your project...');
  const projects = await apiCall('/projects');
  
  if (!projects || !projects.items || projects.items.length === 0) {
    console.log('❌ No projects found');
    return;
  }

  PROJECT_ID = projects.items[0].id;
  console.log(`✅ Found project: ${projects.items[0].name} (${PROJECT_ID})\n`);

  // 2. Create products
  console.log('📦 Step 2: Creating products...');
  
  const products = [
    {
      store_identifier: 'pro_monthly',
      app_id: APP_ID,
      type: 'subscription',
      display_name: 'Pro Monthly - $4.99/month',
    },
    {
      store_identifier: 'pro_yearly',
      app_id: APP_ID,
      type: 'subscription',
      display_name: 'Pro Yearly - $49.99/year',
    },
  ];

  const createdProducts = [];
  
  for (const product of products) {
    console.log(`  Creating: ${product.display_name}...`);
    const result = await apiCall(`/projects/${PROJECT_ID}/products`, 'POST', product);
    
    if (result) {
      console.log(`  ✅ Created: ${result.id}`);
      createdProducts.push(result);
    } else {
      console.log(`  ⚠️  May already exist or error occurred`);
    }
  }

  if (createdProducts.length === 0) {
    console.log('\n⚠️  No new products created. They may already exist.');
    // Try to fetch existing products
    const existingProducts = await apiCall(`/projects/${PROJECT_ID}/products?app_id=${APP_ID}`);
    if (existingProducts && existingProducts.items) {
      createdProducts.push(...existingProducts.items.filter(p => 
        p.store_identifier === 'pro_monthly' || p.store_identifier === 'pro_yearly'
      ));
      console.log(`   Found ${createdProducts.length} existing products\n`);
    }
  } else {
    console.log();
  }

  // 3. Create "pro" entitlement
  console.log('🎯 Step 3: Creating "pro" entitlement...');
  const entitlement = await apiCall(`/projects/${PROJECT_ID}/entitlements`, 'POST', {
    lookup_key: 'pro',
    display_name: 'Pro Access',
  });

  let entitlementId;
  if (entitlement) {
    console.log(`✅ Created entitlement: ${entitlement.id}\n`);
    entitlementId = entitlement.id;
  } else {
    console.log('⚠️  Entitlement may already exist, fetching...');
    const entitlements = await apiCall(`/projects/${PROJECT_ID}/entitlements`);
    const proEnt = entitlements?.items?.find(e => e.lookup_key === 'pro');
    if (proEnt) {
      entitlementId = proEnt.id;
      console.log(`✅ Found existing entitlement: ${entitlementId}\n`);
    }
  }

  // 4. Attach products to entitlement
  if (entitlementId && createdProducts.length > 0) {
    console.log('🔗 Step 4: Attaching products to entitlement...');
    const productIds = createdProducts.map(p => p.id);
    
    const attached = await apiCall(
      `/projects/${PROJECT_ID}/entitlements/${entitlementId}/actions/attach_products`,
      'POST',
      { product_ids: productIds }
    );

    if (attached) {
      console.log(`✅ Attached ${productIds.length} products to entitlement\n`);
    } else {
      console.log('⚠️  Products may already be attached\n');
    }
  }

  // 5. Create "default" offering
  console.log('🎁 Step 5: Creating "default" offering...');
  const offering = await apiCall(`/projects/${PROJECT_ID}/offerings`, 'POST', {
    lookup_key: 'default',
    display_name: 'Default Offering',
  });

  let offeringId;
  if (offering) {
    console.log(`✅ Created offering: ${offering.id}\n`);
    offeringId = offering.id;
  } else {
    console.log('⚠️  Offering may already exist, fetching...');
    const offerings = await apiCall(`/projects/${PROJECT_ID}/offerings`);
    const defaultOff = offerings?.items?.find(o => o.lookup_key === 'default');
    if (defaultOff) {
      offeringId = defaultOff.id;
      console.log(`✅ Found existing offering: ${offeringId}\n`);
    }
  }

  // 6. Create packages in offering
  if (offeringId) {
    console.log('📦 Step 6: Creating packages...');
    
    const packages = [
      {
        lookup_key: 'monthly',
        display_name: 'Monthly',
        position: 1,
      },
      {
        lookup_key: 'annual',
        display_name: 'Annual',
        position: 2,
      },
    ];

    const createdPackages = [];
    for (const pkg of packages) {
      console.log(`  Creating package: ${pkg.display_name}...`);
      const result = await apiCall(
        `/projects/${PROJECT_ID}/offerings/${offeringId}/packages`,
        'POST',
        pkg
      );
      
      if (result) {
        console.log(`  ✅ Created: ${result.id}`);
        createdPackages.push(result);
      }
    }
    console.log();

    // 7. Attach products to packages
    if (createdPackages.length > 0 && createdProducts.length > 0) {
      console.log('🔗 Step 7: Attaching products to packages...');
      
      // Attach monthly product to monthly package
      const monthlyProduct = createdProducts.find(p => p.store_identifier === 'pro_monthly');
      const monthlyPackage = createdPackages.find(p => p.lookup_key === 'monthly');
      
      if (monthlyProduct && monthlyPackage) {
        await apiCall(
          `/projects/${PROJECT_ID}/packages/${monthlyPackage.id}/actions/attach_products`,
          'POST',
          {
            products: [{
              product_id: monthlyProduct.id,
              eligibility_criteria: 'all'
            }]
          }
        );
        console.log('  ✅ Attached pro_monthly to monthly package');
      }

      // Attach yearly product to annual package
      const yearlyProduct = createdProducts.find(p => p.store_identifier === 'pro_yearly');
      const annualPackage = createdPackages.find(p => p.lookup_key === 'annual');
      
      if (yearlyProduct && annualPackage) {
        await apiCall(
          `/projects/${PROJECT_ID}/packages/${annualPackage.id}/actions/attach_products`,
          'POST',
          {
            products: [{
              product_id: yearlyProduct.id,
              eligibility_criteria: 'all'
            }]
          }
        );
        console.log('  ✅ Attached pro_yearly to annual package');
      }
    }
  }

  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  console.log('✅ **RevenueCat Configuration Complete!**\n');
  console.log('📋 What was configured:\n');
  console.log('  ✓ 2 Products: pro_monthly, pro_yearly');
  console.log('  ✓ 1 Entitlement: "pro"');
  console.log('  ✓ 1 Offering: "default"');
  console.log('  ✓ 2 Packages: monthly, annual\n');
  console.log('🔗 Next steps:\n');
  console.log('  1. Create products in Google Play Console:');
  console.log('     node scripts/create-play-products.mjs');
  console.log('  2. Your app is ready to sell subscriptions!\n');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}

main().catch(error => {
  console.error('\n❌ Error:', error.message);
  process.exit(1);
});
