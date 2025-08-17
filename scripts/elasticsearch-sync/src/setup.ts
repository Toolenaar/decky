#!/usr/bin/env node

/**
 * Setup script for Decky development environment
 * 
 * This script helps configure the development environment
 * and validates that everything is working correctly.
 */

import * as fs from 'fs';
import * as path from 'path';
// Import will be done dynamically after checking if library is built

async function setup() {
  console.log('🚀 Setting up Decky development environment...\n');

  // Check if .env files exist
  const projectEnv = path.resolve(__dirname, '../../../.env');
  const functionsEnv = path.resolve(__dirname, '../../../packages/backend/functions/.env');

  console.log('📋 Checking configuration files...');
  
  if (!fs.existsSync(projectEnv)) {
    console.log('❌ Project .env file not found at:', projectEnv);
    console.log('   Please copy .env.example to .env and configure your settings');
    process.exit(1);
  } else {
    console.log('✅ Project .env file found');
  }

  if (!fs.existsSync(functionsEnv)) {
    console.log('❌ Functions .env file not found at:', functionsEnv);
    console.log('   Please copy .env.example to packages/backend/functions/.env');
    process.exit(1);
  } else {
    console.log('✅ Functions .env file found');
  }

  // Check if elasticsearch library is built
  const libPath = path.resolve(__dirname, '../../../packages/elasticsearch-lib/dist');
  console.log('\n📦 Checking if elasticsearch library is built...');
  
  if (!fs.existsSync(libPath)) {
    console.log('❌ Elasticsearch library not built');
    console.log('   Run: npm run build:elasticsearch-lib');
    console.log('   Or:  npm run install:all');
    process.exit(1);
  } else {
    console.log('✅ Elasticsearch library is built');
  }

  // Validate Elasticsearch configuration
  console.log('\n🔌 Validating Elasticsearch configuration...');
  try {
    const { validateElasticsearchConfig } = await import('@decky/elasticsearch-lib');
    validateElasticsearchConfig();
    console.log('✅ Elasticsearch configuration is valid');
  } catch (error) {
    console.log('❌ Elasticsearch configuration error:', (error as Error).message);
    console.log('\n💡 Common fixes:');
    console.log('   - Make sure ELASTICSEARCH_URL is set in your .env');
    console.log('   - For local Docker: http://localhost:9200');
    console.log('   - For Elastic Cloud: https://your-deployment.es.region.cloud:443');
    console.log('   - Add authentication (API key or username/password)');
    process.exit(1);
  }

  // Test Elasticsearch connection
  console.log('\n🔗 Testing Elasticsearch connection...');
  try {
    const { CardSearchService } = await import('@decky/elasticsearch-lib');
    const searchService = new CardSearchService();
    
    // Simple health check - just try to create the service
    console.log('✅ Elasticsearch client created successfully');
    console.log('   Note: Run "npm run sync:elasticsearch" to create the index and sync data');
  } catch (error) {
    console.log('❌ Failed to connect to Elasticsearch:', (error as Error).message);
    console.log('\n💡 Troubleshooting:');
    console.log('   - Make sure Elasticsearch is running');
    console.log('   - Check your ELASTICSEARCH_URL');
    console.log('   - Verify authentication credentials');
    process.exit(1);
  }

  // Check Firebase configuration
  console.log('\n🔥 Checking Firebase configuration...');
  let serviceAccountKey = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  
  // Check for service account in scripts/data folder if not set in env
  if (!serviceAccountKey) {
    const localServiceAccount = path.resolve(__dirname, '../../data/dev-service-account.json');
    if (fs.existsSync(localServiceAccount)) {
      serviceAccountKey = localServiceAccount;
      console.log('✅ Found service account in scripts/data folder');
      console.log(`   Using: ${localServiceAccount}`);
      console.log('   💡 Tip: You can set GOOGLE_APPLICATION_CREDENTIALS in .env to use a different path');
    } else {
      console.log('⚠️  GOOGLE_APPLICATION_CREDENTIALS not set');
      console.log('   No service account found at scripts/data/dev-service-account.json');
      console.log('   Download your service account key and either:');
      console.log('   - Place it at scripts/data/dev-service-account.json');
      console.log('   - Set GOOGLE_APPLICATION_CREDENTIALS path in .env');
    }
  } else if (!fs.existsSync(serviceAccountKey)) {
    console.log('❌ Service account key file not found:', serviceAccountKey);
    console.log('   Please check the path in GOOGLE_APPLICATION_CREDENTIALS');
  } else {
    console.log('✅ Firebase service account key found');
    console.log(`   Using: ${serviceAccountKey}`);
  }

  console.log('\n' + '='.repeat(60));
  console.log('🎉 SETUP COMPLETE!');
  console.log('='.repeat(60));
  console.log('\nNext steps:');
  console.log('1. 📦 Install dependencies: npm run install:all');
  console.log('2. 🔧 Build libraries: npm run build');
  console.log('3. 🔄 Sync data: npm run sync:elasticsearch:clean');
  console.log('4. 🚀 Deploy functions: npm run functions:deploy');
  console.log('\nFor local functions development:');
  console.log('   npm run functions:serve');
  console.log('\nFor help: Check PROJECT_README.md');
  console.log('='.repeat(60));
}

// Handle errors gracefully
setup().catch(error => {
  console.error('\n💥 Setup failed:', error.message);
  process.exit(1);
});