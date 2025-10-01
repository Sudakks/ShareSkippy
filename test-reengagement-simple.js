#!/usr/bin/env node

/**
 * Simple test script to verify re-engagement functionality
 * This script can be run to test the API endpoint when the dev server is running
 */

async function testReengagementAPI() {
  console.log('🔍 Testing Re-engagement API Endpoint...\n');

  const baseUrl = process.env.API_URL || 'http://localhost:3000';
  const endpoint = `${baseUrl}/api/admin/re-engage-inactive-users`;

  try {
    console.log(`1. Testing API endpoint: ${endpoint}`);
    
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    console.log(`   Response status: ${response.status} ${response.statusText}`);

    if (!response.ok) {
      console.error('❌ API request failed');
      const errorText = await response.text();
      console.error('   Error details:', errorText);
      
      if (response.status === 500) {
        console.log('\n💡 Common causes of 500 errors:');
        console.log('   1. Database connection issues');
        console.log('   2. Missing environment variables');
        console.log('   3. Database migrations not applied');
        console.log('   4. Supabase service role key issues');
      }
      
      return;
    }

    const result = await response.json();
    console.log('✅ API request successful');
    
    // Display results in a readable format
    console.log('\n📊 Results:');
    console.log(`   Success: ${result.success}`);
    console.log(`   Message: ${result.message}`);
    console.log(`   Users processed: ${result.usersProcessed || 0}`);
    console.log(`   Emails sent: ${result.emailsSent || 0}`);
    console.log(`   Users skipped: ${result.skippedUsers?.length || 0}`);
    console.log(`   Errors: ${result.errors?.length || 0}`);

    if (result.summary) {
      console.log('\n📈 Summary:');
      console.log(`   Total users: ${result.summary.totalUsers}`);
      console.log(`   Emails sent: ${result.summary.emailsSent}`);
      console.log(`   Skipped: ${result.summary.skipped}`);
      console.log(`   Errors: ${result.summary.errors}`);
    }

    if (result.skippedUsers && result.skippedUsers.length > 0) {
      console.log('\n⏭️  Skipped users (first 3):');
      result.skippedUsers.slice(0, 3).forEach((user, index) => {
        console.log(`   ${index + 1}. ${user.email} - ${user.reason}`);
        if (user.sentAt) console.log(`      Sent at: ${user.sentAt}`);
        if (user.daysSinceFollowUp) console.log(`      Days since follow-up: ${user.daysSinceFollowUp}`);
        if (user.daysSinceReEngagement) console.log(`      Days since re-engagement: ${user.daysSinceReEngagement}`);
      });
    }

    if (result.errors && result.errors.length > 0) {
      console.log('\n❌ Errors (first 3):');
      result.errors.slice(0, 3).forEach((error, index) => {
        console.log(`   ${index + 1}. ${error.email} - ${error.error}`);
      });
    }

    // Analysis
    console.log('\n🔍 Analysis:');
    
    if (result.usersProcessed === 0) {
      console.log('   ⚠️  No users were processed. This could mean:');
      console.log('      - No inactive users found in the database');
      console.log('      - All users are active (signed in recently)');
      console.log('      - Database query issues');
    } else if (result.emailsSent === 0) {
      console.log('   ⚠️  No emails were sent. This could mean:');
      console.log('      - All users already received re-engagement emails recently');
      console.log('      - All users received 3-day follow-up emails recently');
      console.log('      - Email sending issues');
    } else {
      console.log('   ✅ System is working correctly');
      console.log(`      - Found ${result.usersProcessed} potentially inactive users`);
      console.log(`      - Sent ${result.emailsSent} re-engagement emails`);
      console.log(`      - Skipped ${result.skippedUsers?.length || 0} users (already contacted recently)`);
    }

    if (result.errors && result.errors.length > 0) {
      console.log(`   ⚠️  ${result.errors.length} errors occurred during processing`);
    }

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.log('\n💡 Troubleshooting:');
    console.log('   1. Make sure the development server is running:');
    console.log('      npm run dev');
    console.log('   2. Check that the API endpoint exists:');
    console.log('      curl -X POST http://localhost:3000/api/admin/re-engage-inactive-users');
    console.log('   3. Verify environment variables are set in .env.local');
    console.log('   4. Check that database migrations have been applied');
    console.log('   5. Ensure Supabase service role key has proper permissions');
  }
}

// Run the test
testReengagementAPI().catch(console.error);
