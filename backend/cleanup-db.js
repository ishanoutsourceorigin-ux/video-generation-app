const mongoose = require('mongoose');
require('dotenv').config();

async function cleanupDatabase() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Get the avatars collection
    const db = mongoose.connection.db;
    const collection = db.collection('avatars');

    // Drop the problematic index if it exists
    try {
      await collection.dropIndex('id_1');
      console.log('✅ Dropped problematic id_1 index');
    } catch (error) {
      console.log('ℹ️  Index id_1 does not exist or already dropped');
    }

    // Clean up any documents with null id
    const deleteResult = await collection.deleteMany({ id: null });
    console.log(`✅ Deleted ${deleteResult.deletedCount} documents with null id`);

    // List current indexes
    const indexes = await collection.indexes();
    console.log('Current indexes:', indexes.map(idx => idx.name));

    console.log('✅ Database cleanup completed');
  } catch (error) {
    console.error('❌ Cleanup error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

cleanupDatabase();