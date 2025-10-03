const didService = require('./services/didService');

async function testDIDService() {
  try {
    console.log('🧪 Testing D-ID Service Integration...');
    
    // Test 1: Check credits
    console.log('\n1️⃣ Checking D-ID Credits...');
    const credits = await didService.getCredits();
    console.log('Credits result:', credits);
    
    if (credits.success) {
      console.log(`✅ Credits: ${credits.remaining}/${credits.total} remaining`);
    } else {
      console.log('❌ Credits check failed:', credits.error);
    }
    
    // Test 2: Test aspect ratio conversion
    console.log('\n2️⃣ Testing aspect ratio conversion...');
    const service = didService;
    const ratios = ['9:16', '16:9', '1:1', '4:3', '3:4'];
    ratios.forEach(ratio => {
      const converted = service.convertAspectRatio(ratio);
      console.log(`${ratio} -> D-ID config:`, JSON.stringify(converted, null, 2));
    });
    
    console.log('\n✅ D-ID Service test completed!');
    
  } catch (error) {
    console.error('❌ D-ID Service test failed:', error);
  }
}

// Run the test
testDIDService();