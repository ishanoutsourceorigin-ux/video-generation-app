#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🚀 Setting up Video Generation Backend...\n');

// Check if .env exists
const envPath = path.join(__dirname, '.env');
const envExamplePath = path.join(__dirname, '.env.example');

if (!fs.existsSync(envPath)) {
  if (fs.existsSync(envExamplePath)) {
    console.log('📝 Creating .env file from .env.example...');
    fs.copyFileSync(envExamplePath, envPath);
    console.log('✅ .env file created. Please update it with your actual credentials.\n');
  } else {
    console.log('❌ .env.example file not found. Please create .env manually.\n');
  }
} else {
  console.log('✅ .env file already exists.\n');
}

// Check Node.js version
console.log('🔍 Checking Node.js version...');
try {
  const nodeVersion = execSync('node --version', { encoding: 'utf8' }).trim();
  console.log(`✅ Node.js version: ${nodeVersion}\n`);
} catch (error) {
  console.log('❌ Node.js not found. Please install Node.js 16 or higher.\n');
  process.exit(1);
}

// Install dependencies
console.log('📦 Installing dependencies...');
try {
  execSync('npm install', { stdio: 'inherit' });
  console.log('✅ Dependencies installed successfully.\n');
} catch (error) {
  console.log('❌ Failed to install dependencies.\n');
  process.exit(1);
}

// Create uploads directory
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  console.log('📁 Creating uploads directory...');
  fs.mkdirSync(uploadsDir, { recursive: true });
  console.log('✅ Uploads directory created.\n');
}

// Check environment variables
console.log('🔧 Checking environment configuration...');
require('dotenv').config();

const requiredEnvVars = [
  'MONGODB_URI',
  'CLOUDINARY_CLOUD_NAME',
  'CLOUDINARY_API_KEY',
  'CLOUDINARY_API_SECRET'
];

const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);

if (missingVars.length > 0) {
  console.log('⚠️  Missing required environment variables:');
  missingVars.forEach(varName => {
    console.log(`   - ${varName}`);
  });
  console.log('\nPlease update your .env file with the missing variables.\n');
}

const optionalVars = [
  'RUNWAY_API_KEY',
  'ELEVENLABS_API_KEY',
  'DID_API_KEY'
];

const missingOptionalVars = optionalVars.filter(varName => !process.env[varName]);

if (missingOptionalVars.length > 0) {
  console.log('ℹ️  Optional environment variables (for full functionality):');
  missingOptionalVars.forEach(varName => {
    console.log(`   - ${varName}`);
  });
  console.log('\nThese can be added later for AI service integration.\n');
}

// Test database connection
console.log('🔌 Testing database connection...');
const mongoose = require('mongoose');

if (process.env.MONGODB_URI) {
  mongoose.connect(process.env.MONGODB_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => {
    console.log('✅ Database connection successful.\n');
    mongoose.disconnect();
    
    console.log('🎉 Setup complete! You can now start the server with:');
    console.log('   npm start      (production mode)');
    console.log('   npm run dev    (development mode with auto-reload)\n');
    
    console.log('📚 Next steps:');
    console.log('   1. Update .env with your actual API credentials');
    console.log('   2. Configure Firebase Admin SDK');
    console.log('   3. Set up Cloudinary account');
    console.log('   4. Add RunwayML API key for video generation');
    console.log('   5. Start the server and test the endpoints\n');
    
  })
  .catch((error) => {
    console.log('❌ Database connection failed:');
    console.log(`   ${error.message}\n`);
    console.log('Please check your MONGODB_URI in .env file.\n');
  });
} else {
  console.log('⚠️  MONGODB_URI not set. Please configure database connection.\n');
  
  console.log('🎉 Basic setup complete! Please:');
  console.log('   1. Update .env with your MongoDB URI');
  console.log('   2. Add other required environment variables');
  console.log('   3. Run this setup script again\n');
}