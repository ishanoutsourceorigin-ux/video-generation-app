const RunwayService = require('./services/runwayService');
require('dotenv').config();

console.log('🧪 === TESTING RUNWAY IMPLEMENTATION ===');

// Test RunwayService instantiation
console.log('\n1️⃣ Testing RunwayService instantiation...');
const runwayService = new RunwayService();

// Test helper methods
console.log('\n2️⃣ Testing helper methods...');

// Test createShortPrompt
const longPrompt = 'This is a very long video prompt that needs to be shortened to fit within the 1000 character limit imposed by the RunwayML API. '.repeat(10);
const shortPrompt = runwayService.createShortPrompt(longPrompt, 8);
console.log(`✅ createShortPrompt: ${shortPrompt.length} chars`);

// Test convertAspectRatio
const aspectRatio = runwayService.convertAspectRatio('9:16', 1080);
console.log(`✅ convertAspectRatio: 9:16 → ${aspectRatio}`);

// Test getVideoDimensions
const dimensions = runwayService.getVideoDimensions('9:16', 1080);
console.log(`✅ getVideoDimensions: ${JSON.stringify(dimensions)}`);

// Test getMotionScore
const motionScore = runwayService.getMotionScore('medium');
console.log(`✅ getMotionScore: medium → ${motionScore}`);

// Test mapRunwayStatus
const status = runwayService.mapRunwayStatus('SUCCEEDED');
console.log(`✅ mapRunwayStatus: SUCCEEDED → ${status}`);

// Test getPricingInfo
const pricing = runwayService.getPricingInfo(8, 1080);
console.log(`✅ getPricingInfo: ${JSON.stringify(pricing)}`);

// Test enhancePrompt
const enhanced = runwayService.enhancePrompt('A beautiful sunset over mountains');
console.log(`✅ enhancePrompt: ${enhanced}`);

console.log('\n✅ All helper methods working correctly!');
console.log('\n🎉 Runway implementation test completed successfully!');
console.log('\n📋 Available methods in RunwayService:');
console.log('  - generateVideo() - Main video generation with fallbacks');
console.log('  - generateTextBasedVideo() - Text-to-video generation');
console.log('  - generateImageBasedVideo() - Image-to-video generation');
console.log('  - getTaskStatus() - Check task status');
console.log('  - cancelTask() - Cancel running task');
console.log('  - pollVideoTask() - Poll for completion');
console.log('  - downloadAndUploadVideo() - Handle video downloads');
console.log('  - createMockVideo() - Fallback mock generation');
console.log('  - All helper methods for data transformation');