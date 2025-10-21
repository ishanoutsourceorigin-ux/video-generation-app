// Test script for purchase verification endpoints
const axios = require('axios');

const BASE_URL = 'http://localhost:3000'; // Update with your server URL

async function testPurchaseEndpoints() {
  console.log('🧪 Testing Purchase Verification Endpoints...\n');

  // You'll need a valid Firebase ID token for testing
  const testToken = 'YOUR_FIREBASE_ID_TOKEN_HERE';
  
  const headers = {
    'Authorization': `Bearer ${testToken}`,
    'Content-Type': 'application/json'
  };

  try {
    // Test 1: Get user credits
    console.log('1️⃣ Testing GET /api/user/credits');
    try {
      const response = await axios.get(`${BASE_URL}/api/user/credits`, { headers });
      console.log('✅ Credits endpoint working:', response.data);
    } catch (error) {
      console.log('❌ Credits endpoint failed:', error.response?.data || error.message);
    }

    // Test 2: Verify purchase
    console.log('\n2️⃣ Testing POST /api/payments/verify-purchase');
    const testPurchase = {
      purchaseToken: 'test_purchase_token_12345',
      productId: 'basic_credits_500',
      transactionId: `test_txn_${Date.now()}`,
      planId: 'basic',
      credits: 500
    };
    
    try {
      const response = await axios.post(`${BASE_URL}/api/payments/verify-purchase`, testPurchase, { headers });
      console.log('✅ Purchase verification working:', response.data);
    } catch (error) {
      console.log('❌ Purchase verification failed:', error.response?.data || error.message);
    }

    // Test 3: Get payment history
    console.log('\n3️⃣ Testing GET /api/payments/history');
    try {
      const response = await axios.get(`${BASE_URL}/api/payments/history`, { headers });
      console.log('✅ Payment history working:', response.data);
    } catch (error) {
      console.log('❌ Payment history failed:', error.response?.data || error.message);
    }

    // Test 4: Get credit history
    console.log('\n4️⃣ Testing GET /api/user/credit-history');
    try {
      const response = await axios.get(`${BASE_URL}/api/user/credit-history`, { headers });
      console.log('✅ Credit history working:', response.data);
    } catch (error) {
      console.log('❌ Credit history failed:', error.response?.data || error.message);
    }

  } catch (error) {
    console.error('🚨 Test failed:', error.message);
  }
}

// Run tests
if (require.main === module) {
  console.log('⚠️  Before running this test:');
  console.log('1. Update BASE_URL to match your server');
  console.log('2. Replace testToken with a valid Firebase ID token');
  console.log('3. Make sure your server is running');
  console.log('4. Install axios: npm install axios\n');
  
  // testPurchaseEndpoints();
}

module.exports = { testPurchaseEndpoints };