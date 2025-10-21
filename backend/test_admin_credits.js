const axios = require('axios');

// Test admin credit update functionality
const testAdminCreditUpdate = async () => {
  try {
    console.log('🔧 Testing Admin Credit Update Functionality');
    console.log('===============================================\n');

    const baseUrl = 'http://localhost:5000/api';
    
    // Step 1: Test admin login (you'll need to replace with actual admin token)
    console.log('1. Testing admin authentication...');
    
    // For this test, you'll need to get an actual admin token from Firebase
    // const adminToken = 'your-admin-token-here';
    
    // Mock admin token for testing structure
    const adminToken = 'test-admin-token';
    
    const headers = {
      'Authorization': `Bearer ${adminToken}`,
      'Content-Type': 'application/json'
    };

    // Step 2: Test getting users list
    console.log('2. Testing users list endpoint...');
    try {
      const usersResponse = await axios.get(`${baseUrl}/admin/users`, { headers });
      console.log('✅ Users endpoint accessible');
      console.log(`📊 Found ${usersResponse.data.users?.length || 0} users`);
      
      if (usersResponse.data.users && usersResponse.data.users.length > 0) {
        const testUser = usersResponse.data.users[0];
        console.log(`👤 Test user: ${testUser.email} (Credits: ${testUser.credits})`);
        
        // Step 3: Test credit update
        console.log('\n3. Testing credit update...');
        const newCredits = 1000;
        
        try {
          const updateResponse = await axios.put(
            `${baseUrl}/admin/users/${testUser.uid}/credits`,
            { credits: newCredits },
            { headers }
          );
          
          console.log('✅ Credit update successful');
          console.log('📋 Response:', updateResponse.data);
          
        } catch (updateError) {
          console.log('❌ Credit update failed:', updateError.response?.data || updateError.message);
        }
      } else {
        console.log('⚠️ No users found for testing');
      }
      
    } catch (usersError) {
      console.log('❌ Users endpoint failed:', usersError.response?.data || usersError.message);
    }

    // Step 4: Test MongoDB User model structure
    console.log('\n4. Testing MongoDB connection...');
    
    // This would require MongoDB connection setup
    console.log('ℹ️ MongoDB connection test requires backend server to be running');

  } catch (error) {
    console.error('💥 Test failed:', error.message);
  }
};

// Additional test for credit field consistency
const testCreditFieldConsistency = () => {
  console.log('\n5. Credit Field Consistency Check');
  console.log('==================================');
  
  console.log('✅ Expected behavior:');
  console.log('- Admin updates should set both `credits` and `availableCredits`');
  console.log('- Frontend should read from `availableCredits` primarily');
  console.log('- Legacy `credits` field maintained for backward compatibility');
  console.log('- User credit history should be tracked in `creditHistory` array');
  
  console.log('\n📋 API Endpoints to test:');
  console.log('- GET  /api/admin/users (should show current credits)');
  console.log('- PUT  /api/admin/users/:id/credits (should update both fields)');
  console.log('- GET  /api/user/credits (should return availableCredits)');
  console.log('- POST /api/payments/verify-purchase (should add to availableCredits)');
};

// Run tests
if (require.main === module) {
  console.log('🚀 Starting Admin Credit System Tests\n');
  testAdminCreditUpdate().then(() => {
    testCreditFieldConsistency();
    console.log('\n✅ Test execution completed');
    console.log('\nℹ️  To run full tests:');
    console.log('1. Start backend server: npm start');
    console.log('2. Get admin token from Firebase');
    console.log('3. Replace adminToken in this script');
    console.log('4. Run: node test_admin_credits.js');
  });
}

module.exports = { testAdminCreditUpdate, testCreditFieldConsistency };