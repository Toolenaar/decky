#!/usr/bin/env node

/**
 * Full Elasticsearch Sync Script
 * 
 * Usage (from project root):
 *   npm run sync:elasticsearch -- --clean   # Delete and recreate index
 *   npm run sync:elasticsearch               # Sync without recreating index
 *   npm run sync:elasticsearch -- --batch-size 1000  # Custom batch size
 */

import * as admin from 'firebase-admin';
import { ElasticsearchSyncService } from '@decky/elasticsearch-lib';
import * as dotenv from 'dotenv';
import * as path from 'path';

// Load environment variables from project root
dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

// Parse command line arguments
const args = process.argv.slice(2);
const cleanSync = args.includes('--clean');
const batchSizeArg = args.find(arg => arg.startsWith('--batch-size'));
const batchSize = batchSizeArg 
  ? parseInt(batchSizeArg.split('=')[1] || '500') 
  : 500;

// Initialize Firebase Admin
if (!admin.apps.length) {
  // Check if service account is available in local scripts/data folder
  const localServiceAccount = path.resolve(__dirname, '../../data/dev-service-account.json');
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS && require('fs').existsSync(localServiceAccount)) {
    console.log('🔧 Using local service account from scripts/data folder');
    process.env.GOOGLE_APPLICATION_CREDENTIALS = localServiceAccount;
  }
  
  admin.initializeApp();
}

const db = admin.firestore();

interface SyncStats {
  total: number;
  successful: number;
  failed: number;
  startTime: Date;
  endTime?: Date;
}

class FullSyncRunner {
  private syncService: ElasticsearchSyncService;
  private stats: SyncStats;

  constructor() {
    this.syncService = new ElasticsearchSyncService();
    this.stats = {
      total: 0,
      successful: 0,
      failed: 0,
      startTime: new Date()
    };
  }

  async run(): Promise<void> {
    console.log('🚀 Starting Elasticsearch sync...');
    console.log(`   Clean sync: ${cleanSync}`);
    console.log(`   Batch size: ${batchSize}`);
    console.log('');

    try {
      // Initialize or recreate index
      if (cleanSync) {
        console.log('🗑️  Recreating index...');
        await this.syncService.recreateIndex();
        console.log('✅ Index recreated');
      } else {
        console.log('📋 Ensuring index exists...');
        await this.syncService.initializeIndex();
        console.log('✅ Index ready');
      }

      // Get total count
      const countSnapshot = await db.collection('cards').count().get();
      this.stats.total = countSnapshot.data().count;
      console.log(`📊 Total cards to sync: ${this.stats.total}`);
      console.log('');

      // Process in batches
      await this.processBatches();

      // Final stats
      this.stats.endTime = new Date();
      this.printFinalStats();

    } catch (error) {
      console.error('❌ Sync failed:', error);
      process.exit(1);
    }
  }

  private async processBatches(): Promise<void> {
    let lastDoc: admin.firestore.DocumentSnapshot | undefined;
    let batchNumber = 0;

    while (true) {
      batchNumber++;
      
      // Build query
      let query = db.collection('cards')
        .orderBy('name')
        .limit(batchSize);
      
      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      // Fetch batch
      const snapshot = await query.get();
      
      if (snapshot.empty) {
        break;
      }

      // Process batch
      console.log(`📦 Processing batch ${batchNumber} (${snapshot.size} cards)...`);
      
      const cards = snapshot.docs.map(doc => ({
        data: doc.data(),
        id: doc.id
      }));

      try {
        await this.syncService.bulkSyncCards(cards);
        this.stats.successful += cards.length;
        console.log(`   ✅ Batch ${batchNumber} synced successfully`);
      } catch (error) {
        console.error(`   ❌ Batch ${batchNumber} failed:`, error);
        this.stats.failed += cards.length;
      }

      // Update progress
      const progress = Math.round((this.stats.successful + this.stats.failed) / this.stats.total * 100);
      console.log(`   Progress: ${progress}% (${this.stats.successful + this.stats.failed}/${this.stats.total})`);
      console.log('');

      // Update last doc for pagination
      lastDoc = snapshot.docs[snapshot.docs.length - 1];
    }
  }

  private printFinalStats(): void {
    const duration = this.stats.endTime 
      ? (this.stats.endTime.getTime() - this.stats.startTime.getTime()) / 1000 
      : 0;

    console.log('');
    console.log('='.repeat(50));
    console.log('📊 SYNC COMPLETE');
    console.log('='.repeat(50));
    console.log(`Total cards:     ${this.stats.total}`);
    console.log(`Successful:      ${this.stats.successful} ✅`);
    console.log(`Failed:          ${this.stats.failed} ❌`);
    console.log(`Duration:        ${duration.toFixed(2)} seconds`);
    console.log(`Cards/second:    ${(this.stats.successful / duration).toFixed(2)}`);
    console.log('='.repeat(50));

    if (this.stats.failed > 0) {
      console.log('⚠️  Some cards failed to sync. Check logs for details.');
      process.exit(1);
    } else {
      console.log('✅ All cards synced successfully!');
    }
  }
}

// Run the sync
async function main() {
  const runner = new FullSyncRunner();
  await runner.run();
}

main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});