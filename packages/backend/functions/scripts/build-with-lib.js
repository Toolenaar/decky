#!/usr/bin/env node

const fs = require('fs-extra');
const path = require('path');
const { execSync } = require('child_process');

const ELASTICSEARCH_LIB_PATH = path.resolve(__dirname, '../../../elasticsearch-lib');
const FUNCTIONS_LIB_PATH = path.resolve(__dirname, '../src/lib');

async function buildWithLib() {
  console.log('🔨 Building Elasticsearch library...');
  
  try {
    // Build the elasticsearch library
    execSync('npm run build', { 
      cwd: ELASTICSEARCH_LIB_PATH, 
      stdio: 'inherit' 
    });
    
    console.log('📦 Copying library to functions...');
    
    // Ensure the lib directory exists in functions/src
    await fs.ensureDir(FUNCTIONS_LIB_PATH);
    
    // Copy the built library
    await fs.copy(
      path.join(ELASTICSEARCH_LIB_PATH, 'dist'),
      path.join(FUNCTIONS_LIB_PATH, 'elasticsearch-lib')
    );
    
    // Copy package.json for dependency info
    await fs.copy(
      path.join(ELASTICSEARCH_LIB_PATH, 'package.json'),
      path.join(FUNCTIONS_LIB_PATH, 'elasticsearch-lib', 'package.json')
    );
    
    console.log('✅ Library copied successfully');
    
    // Now build the functions
    console.log('🔨 Building functions...');
    execSync('tsc', { stdio: 'inherit' });
    
    // Copy the library to the compiled lib directory as well
    console.log('📦 Copying library to compiled lib...');
    const COMPILED_LIB_PATH = path.resolve(__dirname, '../lib/lib');
    await fs.ensureDir(COMPILED_LIB_PATH);
    await fs.copy(
      path.join(ELASTICSEARCH_LIB_PATH, 'dist'),
      path.join(COMPILED_LIB_PATH, 'elasticsearch-lib')
    );
    await fs.copy(
      path.join(ELASTICSEARCH_LIB_PATH, 'package.json'),
      path.join(COMPILED_LIB_PATH, 'elasticsearch-lib', 'package.json')
    );
    
    console.log('✅ Build complete!');
    
  } catch (error) {
    console.error('❌ Build failed:', error.message);
    process.exit(1);
  }
}

buildWithLib();