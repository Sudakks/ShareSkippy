#!/usr/bin/env node

/**
 * Test script to verify the re-engagement API endpoint
 * This script makes HTTP requests to test the actual API functionality
 */

async function testReengagementAPI() {
  console.log('🔍 Testing Re-engagement API Endpoint...\n');

  try {
    // Test the re-engagement API endpoint
    console.log('1. Testing re-engagement API endpoint...');
    
    const response = await fetch('http://localhost:3000/api/admin/re-engage-inactive-users', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      console.error('❌ API request failed:', response.status, response.statusText);
      const errorText = await response.text();
      console.error('   Error details:', errorText);
      return;
    }

    const result = await response.json();
    console.log('✅ API request successful');
    console.log('   Response:', JSON.stringify(result, null, 2));

    // Analyze the results
    if (result.success) {
      console.log('\n📊 Analysis:');
      console.log(`   - Total users processed: ${result.usersProcessed || 0}`);
      console.log(`   - Emails sent: ${result.emailsSent || 0}`);
      console.log(`   - Users skipped: ${result.skippedUsers?.length || 0}`);
      console.log(`   - Errors: ${result.errors?.length || 0}`);
      
      if (result.skippedUsers && result.skippedUsers.length > 0) {
        console.log('\n   Skipped users:');
        result.skippedUsers.slice(0, 3).forEach((user, index) => {
          console.log(`   ${index + 1}. ${user.email} - ${user.reason}`);
        });
      }
      
      if (result.errors && result.errors.length > 0) {
        console.log('\n   Errors:');
        result.errors.slice(0, 3).forEach((error, index) => {
          console.log(`   ${index + 1}. ${error.email} - ${error.error}`);
        });
      }
      
      if (result.summary) {
        console.log('\n   Summary:');
        console.log(`   - Total users: ${result.summary.totalUsers}`);
        console.log(`   - Emails sent: ${result.summary.emailsSent}`);
        console.log(`   - Skipped: ${result.summary.skipped}`);
        console.log(`   - Errors: ${result.summary.errors}`);
      }
    } else {
      console.log('❌ API returned error:', result.error);
    }

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.log('\n💡 Troubleshooting:');
    console.log('   1. Make sure the development server is running (npm run dev)');
    console.log('   2. Check that the API endpoint exists at /api/admin/re-engage-inactive-users');
    console.log('   3. Verify environment variables are set correctly');
    console.log('   4. Check that database migrations have been applied');
  }
}

// Run the test
testReengagementAPI().catch(console.error);
