#!/bin/bash

# Test script for re-engagement API endpoint
# This script provides curl commands to test the API functionality

echo "🔍 Testing Re-engagement API Endpoint with curl..."
echo ""

# Test the re-engagement API endpoint
echo "1. Testing re-engagement API endpoint..."
echo "   Command: curl -X POST http://localhost:3000/api/admin/re-engage-inactive-users"
echo ""

curl -X POST \
  -H "Content-Type: application/json" \
  -w "\n\nHTTP Status: %{http_code}\nResponse Time: %{time_total}s\n" \
  http://localhost:3000/api/admin/re-engage-inactive-users

echo ""
echo "2. Testing 3-day follow-up API endpoint..."
echo "   Command: curl -X GET http://localhost:3000/api/cron/send-3day-follow-up-emails"
echo ""

curl -X GET \
  -H "Content-Type: application/json" \
  -w "\n\nHTTP Status: %{http_code}\nResponse Time: %{time_total}s\n" \
  http://localhost:3000/api/cron/send-3day-follow-up-emails

echo ""
echo "✅ Test completed!"
echo ""
echo "💡 Expected responses:"
echo "   - 200 OK: API is working correctly"
echo "   - 500 Error: Check database connection and environment variables"
echo "   - 404 Error: API endpoint not found (check route file exists)"
echo ""
echo "🔍 To analyze the results:"
echo "   - Look for 'emailsSent' count to see if emails were sent"
echo "   - Check 'usersProcessed' to see how many users were found"
echo "   - Review 'skippedUsers' to see why users were skipped"
echo "   - Check 'errors' array for any issues"
