const mongoose = require('mongoose');
const Avatar = require('./models/Avatar');
require('dotenv').config();

async function checkAvatars() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const avatars = await Avatar.find({}).sort({ createdAt: -1 }).limit(5);
    console.log(`Found ${avatars.length} avatars:`);
    
    avatars.forEach((avatar, index) => {
      console.log(`\n${index + 1}. Avatar:`);
      console.log(`   ID: ${avatar._id}`);
      console.log(`   Name: ${avatar.name}`);
      console.log(`   Profession: ${avatar.profession}`);
      console.log(`   Status: ${avatar.status}`);
      console.log(`   User ID: ${avatar.userId}`);
      console.log(`   Created: ${avatar.createdAt}`);
      console.log(`   Image URL: ${avatar.imageUrl}`);
      console.log(`   Voice ID: ${avatar.voiceId || 'Not set'}`);
    });

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

checkAvatars();