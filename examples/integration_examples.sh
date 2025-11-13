#!/bin/bash

# Integration API Examples
# Replace YOUR_TOKEN with your actual integration token
# Replace YOUR_FUNCTION_URL with your Supabase Edge Function URL

TOKEN="YOUR_TOKEN"
BASE_URL="YOUR_FUNCTION_URL"

# 1. Create a new ticket
echo "=== Creating a new ticket ==="
curl -X POST "$BASE_URL/tickets" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "API Integration Test Ticket",
    "description": "This ticket was created via the integration API",
    "priority": "medium",
    "category": "API",
    "metadata": {
      "source": "external_system",
      "reference_id": "EXT-12345"
    }
  }'

echo -e "\n\n"

# 2. Get ticket details
# Replace TICKET_ID with the actual ticket ID from step 1
TICKET_ID="00000000-0000-0000-0000-000000000000"

echo "=== Getting ticket details ==="
curl -X GET "$BASE_URL/tickets/$TICKET_ID" \
  -H "Authorization: Bearer $TOKEN"

echo -e "\n\n"

# 3. Add a comment to the ticket
echo "=== Adding a comment to the ticket ==="
curl -X POST "$BASE_URL/tickets/$TICKET_ID/comments" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "This is a comment added via the integration API",
    "is_internal": false
  }'

echo -e "\n\n"

# 4. Update ticket status
echo "=== Updating ticket status ==="
curl -X PATCH "$BASE_URL/tickets/$TICKET_ID/status" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "in_progress"
  }'

echo -e "\n\n"

# 5. Health check
echo "=== Health check ==="
curl -X GET "$BASE_URL/" \
  -H "Authorization: Bearer $TOKEN"

echo -e "\n\n"
