# Integration API Examples

This directory contains example client implementations for integrating with the External Integration API.

## Prerequisites

Before running these examples, ensure you have:

1. **Integration Token**: Create one via Settings → Integration Tokens in the admin UI
2. **Edge Function URL**: Your Supabase Edge Function URL (format: `https://your-project.supabase.co/functions/v1/integration-tickets`)

## Available Examples

### 1. Shell/Bash Scripts (`integration_examples.sh`)

Simple curl-based examples demonstrating all API endpoints.

**Usage:**

```bash
export TOKEN="stk_your_token_here"
export BASE_URL="https://your-project.supabase.co/functions/v1/integration-tickets"
bash integration_examples.sh
```

**Features:**
- Create ticket
- Get ticket details
- Add comment
- Update status
- Health check

### 2. Node.js Client (`integration_client.js`)

Complete Node.js client with error handling and retry logic.

**Setup:**

```bash
npm install node-fetch
```

**Usage:**

```bash
export INTEGRATION_TOKEN="stk_your_token_here"
export INTEGRATION_URL="https://your-project.supabase.co/functions/v1/integration-tickets"
node integration_client.js
```

**Features:**
- Full CRUD operations
- Error handling
- Request/response logging
- Demonstrates complete workflow

### 3. Python Client (`integration_client.py`)

Object-oriented Python client with clean API.

**Setup:**

```bash
pip install requests
```

**Usage:**

```bash
export INTEGRATION_TOKEN="stk_your_token_here"
export INTEGRATION_URL="https://your-project.supabase.co/functions/v1/integration-tickets"
python integration_client.py
```

**Features:**
- Class-based API client
- Type hints
- Comprehensive error handling
- JSON pretty-printing

## Environment Variables

All examples require these environment variables:

| Variable | Description | Example |
| -------- | ----------- | ------- |
| `INTEGRATION_TOKEN` or `TOKEN` | Your integration token from admin UI | `stk_abc123...` |
| `INTEGRATION_URL` or `BASE_URL` | Your Edge Function URL | `https://xyz.supabase.co/functions/v1/integration-tickets` |

## Example Workflows

### Create and Track a Ticket

1. **Create ticket** with details
2. **Add comment** with updates
3. **Update status** to track progress
4. **Get ticket** to verify changes

### Bulk Import Tickets

```python
import os
import json
from integration_client import IntegrationClient

client = IntegrationClient(
    os.environ['INTEGRATION_URL'],
    os.environ['INTEGRATION_TOKEN']
)

# Read from your data source
tickets_data = [
    {"title": "Issue 1", "priority": "high"},
    {"title": "Issue 2", "priority": "medium"},
    # ... more tickets
]

for ticket_data in tickets_data:
    try:
        result = client.create_ticket(**ticket_data)
        print(f"Created: {result['ticket']['id']}")
    except Exception as e:
        print(f"Failed: {ticket_data['title']} - {e}")
```

### Monitor Ticket Status

```javascript
const { IntegrationClient } = require('./integration_client');

const client = new IntegrationClient(
  process.env.INTEGRATION_URL,
  process.env.INTEGRATION_TOKEN
);

async function pollTicket(ticketId) {
  const ticket = await client.getTicket(ticketId);
  console.log(`Status: ${ticket.ticket.status}`);
  
  if (ticket.ticket.status === 'resolved') {
    console.log('Ticket resolved!');
  } else {
    // Poll again in 5 minutes
    setTimeout(() => pollTicket(ticketId), 5 * 60 * 1000);
  }
}

pollTicket('ticket-id-here');
```

## Error Handling

All examples demonstrate proper error handling for common scenarios:

- **401 Unauthorized**: Invalid or expired token
- **429 Rate Limited**: Too many requests
- **500 Server Error**: Server-side issue

### Retry Logic Example

```javascript
async function withRetry(fn, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (error.status === 429) {
        // Rate limited - exponential backoff
        await sleep(Math.pow(2, i) * 1000);
        continue;
      }
      throw error;
    }
  }
}
```

## Security Best Practices

✅ **DO:**
- Store tokens in environment variables
- Use HTTPS only
- Implement rate limiting in your client
- Log API errors for monitoring
- Rotate tokens regularly

❌ **DON'T:**
- Commit tokens to version control
- Hardcode tokens in source code
- Share tokens across multiple systems
- Disable SSL verification

## Testing

### Quick Test

Test your token and connection:

```bash
curl https://your-project.supabase.co/functions/v1/integration-tickets \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Expected response:

```json
{
  "status": "ok",
  "endpoints": [
    "POST /tickets",
    "GET /tickets/:id",
    "POST /tickets/:id/comments",
    "PATCH /tickets/:id/status"
  ]
}
```

### Load Testing

Use tools like `wrk` or `ab` to test under load:

```bash
# Install wrk (macOS)
brew install wrk

# Run load test
wrk -t4 -c10 -d30s \
  -H "Authorization: Bearer YOUR_TOKEN" \
  https://your-project.supabase.co/functions/v1/integration-tickets
```

## Troubleshooting

### Token Not Working

```bash
# Check token format (should start with 'stk_')
echo $INTEGRATION_TOKEN

# Test health endpoint
curl -i https://your-url/functions/v1/integration-tickets \
  -H "Authorization: Bearer $INTEGRATION_TOKEN"
```

### Connection Issues

```bash
# Test DNS resolution
nslookup your-project.supabase.co

# Test HTTPS connectivity
curl -I https://your-project.supabase.co
```

### Rate Limits

Check your current usage in the admin UI:

1. Go to Settings → Integration Tokens
2. Find your token
3. Click "View Usage"
4. Check "This Hour" counter

## Additional Resources

- [External Integrations Guide](../docs/EXTERNAL_INTEGRATIONS.md)
- [API Integration Reference](../docs/API_INTEGRATION.md)
- [Integration Setup Guide](../INTEGRATION_SETUP.md)

## Support

For issues:

1. Check the documentation
2. Review Edge Function logs: `supabase functions logs integration-tickets`
3. Contact your system administrator
