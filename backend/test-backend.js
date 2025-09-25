const axios = require('axios');

async function testBackend() {
  const baseUrl = 'http://localhost:5000';
  
  console.log('🧪 Testing Backend Configuration...\n');
  
  try {
    // Test health endpoint
    console.log('1️⃣ Testing Health Endpoint...');
    const healthResponse = await axios.get(`${baseUrl}/health`);
    console.log('✅ Health Check:', healthResponse.data.status);
    console.log('🔧 Configuration:', healthResponse.data.configuration);
    
    // Test API status
    console.log('\n2️⃣ Testing API Status...');
    const apiResponse = await axios.get(`${baseUrl}/api`);
    console.log('✅ API Status:', apiResponse.data.name);
    
    // Test user profile (should work in development mode)
    console.log('\n3️⃣ Testing User Profile...');
    try {
      const profileResponse = await axios.get(`${baseUrl}/api/user/profile`);
      console.log('✅ Profile Access:', 'Success');
      console.log('👤 Mock User:', profileResponse.data.user.name);
    } catch (error) {
      if (error.response?.status === 401) {
        console.log('⚠️  Authentication required (Production mode)');
      } else {
        console.log('❌ Profile Error:', error.message);
      }
    }
    
    console.log('\n🎉 Backend is running successfully!');
    
  } catch (error) {
    console.log('❌ Backend Test Failed:', error.message);
    console.log('💡 Make sure the backend is running: npm run dev');
  }
}

// Run the test if this file is executed directly
if (require.main === module) {
  testBackend();
}

module.exports = testBackend;