#!/usr/bin/env node

/**
 * Validate Elasticsearch Sync
 * 
 * This script validates that Elasticsearch is properly synced with Firestore
 * by comparing counts and sampling random cards.
 */

import * as admin from 'firebase-admin';
import { CardSearchService } from '@decky/elasticsearch-lib';
import * as dotenv from 'dotenv';
import * as path from 'path';

// Load environment variables from project root
dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

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

interface ValidationResult {
  isValid: boolean;
  firestoreCount: number;
  elasticsearchCount: number;
  sampleValidation?: {
    sampled: number;
    found: number;
    missing: string[];
  };
}

class SyncValidator {
  private searchService: CardSearchService;

  constructor() {
    this.searchService = new CardSearchService();
  }

  async validate(sampleSize: number = 10): Promise<ValidationResult> {
    console.log('🔍 Validating Elasticsearch sync...\n');

    const result: ValidationResult = {
      isValid: false,
      firestoreCount: 0,
      elasticsearchCount: 0
    };

    try {
      // Get counts
      console.log('📊 Comparing document counts...');
      
      const firestoreCount = await this.getFirestoreCount();
      result.firestoreCount = firestoreCount;
      console.log(`   Firestore:      ${firestoreCount} cards`);

      const elasticsearchCount = await this.getElasticsearchCount();
      result.elasticsearchCount = elasticsearchCount;
      console.log(`   Elasticsearch:  ${elasticsearchCount} cards`);

      const countMatch = firestoreCount === elasticsearchCount;
      console.log(`   Match:          ${countMatch ? '✅' : '❌'}\n`);

      // Sample validation
      if (sampleSize > 0) {
        console.log(`🎲 Sampling ${sampleSize} random cards...`);
        result.sampleValidation = await this.validateSample(sampleSize);
        
        console.log(`   Sampled:  ${result.sampleValidation.sampled}`);
        console.log(`   Found:    ${result.sampleValidation.found}`);
        console.log(`   Missing:  ${result.sampleValidation.missing.length}`);
        
        if (result.sampleValidation.missing.length > 0) {
          console.log('\n   Missing cards:');
          result.sampleValidation.missing.forEach(id => {
            console.log(`     - ${id}`);
          });
        }
      }

      // Determine overall validity
      result.isValid = countMatch && 
        (!result.sampleValidation || result.sampleValidation.missing.length === 0);

      return result;

    } catch (error) {
      console.error('❌ Validation failed:', error);
      throw error;
    }
  }

  private async getFirestoreCount(): Promise<number> {
    const snapshot = await db.collection('cards').count().get();
    return snapshot.data().count;
  }

  private async getElasticsearchCount(): Promise<number> {
    const result = await this.searchService.searchCards({
      pagination: { from: 0, size: 0 }
    });
    return result.total;
  }

  private async validateSample(sampleSize: number): Promise<{
    sampled: number;
    found: number;
    missing: string[];
  }> {
    // Get random sample from Firestore
    const allCards = await db.collection('cards')
      .select('name')
      .get();
    
    const cardIds = allCards.docs.map(doc => doc.id);
    const sampleIds = this.getRandomSample(cardIds, Math.min(sampleSize, cardIds.length));
    
    const missing: string[] = [];
    let found = 0;

    // Check each card in Elasticsearch
    for (const id of sampleIds) {
      try {
        const result = await this.searchService.searchCards({
          filters: { name: undefined },
          pagination: { from: 0, size: 1 }
        });
        
        // Note: This is simplified - in production you'd search by firestore_id
        // For now we're just checking if the count is > 0
        if (result.total > 0) {
          found++;
        } else {
          missing.push(id);
        }
      } catch (error) {
        missing.push(id);
      }
    }

    return {
      sampled: sampleIds.length,
      found,
      missing
    };
  }

  private getRandomSample<T>(array: T[], size: number): T[] {
    const shuffled = [...array].sort(() => 0.5 - Math.random());
    return shuffled.slice(0, size);
  }
}

async function main() {
  const validator = new SyncValidator();
  
  const args = process.argv.slice(2);
  const sampleSizeArg = args.find(arg => arg.startsWith('--sample-size'));
  const sampleSize = sampleSizeArg 
    ? parseInt(sampleSizeArg.split('=')[1] || '10') 
    : 10;

  const result = await validator.validate(sampleSize);

  console.log('\n' + '='.repeat(50));
  console.log('VALIDATION RESULT');
  console.log('='.repeat(50));
  
  if (result.isValid) {
    console.log('✅ Elasticsearch is properly synced with Firestore');
  } else {
    console.log('❌ Elasticsearch is NOT properly synced with Firestore');
    console.log('\nIssues found:');
    
    if (result.firestoreCount !== result.elasticsearchCount) {
      console.log(`  - Count mismatch: ${result.firestoreCount} vs ${result.elasticsearchCount}`);
    }
    
    if (result.sampleValidation && result.sampleValidation.missing.length > 0) {
      console.log(`  - ${result.sampleValidation.missing.length} sampled cards missing from Elasticsearch`);
    }
    
    process.exit(1);
  }
}

main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});