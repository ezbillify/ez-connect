# External Integration Setup Guide

This guide walks you through setting up and deploying the external integration layer for your Flutter CRM/Ticketing application.

## Prerequisites

Before you begin, ensure you have:

- Supabase project created
- Supabase CLI installed (`npm install -g supabase`)
- Flutter development environment set up
- Admin access to your application

## Step 1: Database Setup

### 1.1 Connect to Your Supabase Project

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

### 1.2 Apply the Integration Schema

Apply the SQL migration that creates all necessary tables, functions, and policies:

```bash
supabase db push --file supabase/sql/integration_tokens.sql
```

This creates:
- `integration_tokens` table
- `integration_token_usage` table
- `tickets` and `ticket_comments` tables (if not exists)
- Security-definer functions for token validation and operations
- Row Level Security (RLS) policies
- Helper views for statistics

### 1.3 Verify Database Setup

Check that the tables were created:

```bash
supabase db remote ls
```

You should see:
- `integration_tokens`
- `integration_token_usage`
- `tickets`
- `ticket_comments`

## Step 2: Edge Function Deployment

### 2.1 Create Environment File

Create `supabase/functions/.env` with your Supabase credentials:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

> ⚠️ **Security Warning**: Never commit this file to version control. Add it to `.gitignore`.

### 2.2 Deploy the Edge Function

```bash
supabase functions deploy integration-tickets
```

### 2.3 Test the Edge Function

Get your Edge Function URL:

```bash
supabase functions list
```

Test with a health check:

```bash
curl https://your-project.supabase.co/functions/v1/integration-tickets \
  -H "Authorization: Bearer test-token"
```

Expected response (will fail authentication but show the function is deployed):

```json
{
  "error": "invalid_token"
}
```

## Step 3: Flutter Application Setup

### 3.1 Install Dependencies

Run from the project root:

```bash
flutter pub get
```

This installs required packages:
- `crypto` - For token hashing
- `intl` - For date formatting

### 3.2 Configure Environment

Ensure your `.env` file has the correct Supabase credentials:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
APP_ENVIRONMENT=production
```

### 3.3 Build and Run

```bash
flutter run -d chrome  # For web
flutter run            # For mobile
```

## Step 4: Create Your First Integration Token

### 4.1 Sign In as Admin

1. Launch the application
2. Sign in with an admin account
3. Navigate to **Settings**

### 4.2 Access Integration Tokens

If you have the `admin` role, you'll see:

**Administration**
- Integration Tokens → Manage API tokens for external integrations

Click on **Integration Tokens**.

### 4.3 Create a Token

1. Click **Create Token**
2. Fill in the details:
   - **Name**: e.g., "Production API Token"
   - **Description**: e.g., "Token for our external CRM system"
   - **Rate Limit**: e.g., 1000 requests/hour
   - **Expiration** (optional): Set an expiry date
3. Click **Create**

### 4.4 Save the Token

**IMPORTANT**: Copy the token immediately! It will only be shown once.

The token format is: `stk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

Store it securely (e.g., in a password manager or secrets management system).

## Step 5: Test the Integration

### 5.1 Set Environment Variables

```bash
export INTEGRATION_TOKEN="stk_your_token_here"
export INTEGRATION_URL="https://your-project.supabase.co/functions/v1/integration-tickets"
```

### 5.2 Run Example Scripts

**Using Bash:**

```bash
bash examples/integration_examples.sh
```

**Using Node.js:**

```bash
cd examples
npm install node-fetch
node integration_client.js
```

**Using Python:**

```bash
python3 examples/integration_client.py
```

### 5.3 Verify in Admin UI

1. Go back to **Settings → Integration Tokens**
2. Click on your token
3. Click **View Usage**
4. You should see your test requests listed

## Step 6: Integrate with Your System

### 6.1 Choose Your Client Library

Based on your system's programming language, use the appropriate example:

- **Shell/curl**: `examples/integration_examples.sh`
- **JavaScript/Node.js**: `examples/integration_client.js`
- **Python**: `examples/integration_client.py`

### 6.2 Implement Error Handling

Ensure your integration handles:

- **401 Unauthorized**: Token is invalid or expired
- **429 Too Many Requests**: Rate limit exceeded
- **500 Internal Server Error**: Retry with exponential backoff

Example with retry logic (JavaScript):

```javascript
async function createTicketWithRetry(data, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch(`${baseUrl}/tickets`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
      });

      if (response.status === 429) {
        // Rate limited - wait and retry
        await new Promise(resolve => setTimeout(resolve, 5000 * (i + 1)));
        continue;
      }

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${await response.text()}`);
      }

      return await response.json();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
    }
  }
}
```

### 6.3 Monitor Usage

Regularly check the admin UI:

1. **Settings → Integration Tokens**
2. Select your token
3. Click **View Usage**

Monitor:
- Total requests
- Hourly usage (ensure it's below the limit)
- Error count (investigate if high)
- Response times

## Step 7: Production Best Practices

### 7.1 Security

- ✅ Store tokens in environment variables or secret managers
- ✅ Never commit tokens to source control
- ✅ Rotate tokens every 90 days
- ✅ Set expiration dates on tokens
- ✅ Use HTTPS only
- ✅ Implement IP whitelisting (if needed)

### 7.2 Rate Limiting

- ✅ Monitor your hourly usage
- ✅ Implement client-side rate limiting
- ✅ Use exponential backoff for retries
- ✅ Cache responses when appropriate

### 7.3 Error Handling

- ✅ Log all API errors
- ✅ Implement retry logic with backoff
- ✅ Set up alerts for high error rates
- ✅ Have fallback mechanisms

### 7.4 Monitoring

- ✅ Review usage logs weekly
- ✅ Set up alerts for unusual patterns
- ✅ Monitor token expiration dates
- ✅ Track error rates and response times

## Troubleshooting

### Token Not Working

**Symptoms**: Receiving 401 "Invalid token" errors

**Solutions**:
1. Verify token is active (check status in admin UI)
2. Ensure token hasn't expired
3. Check if token was regenerated (old token will stop working)
4. Verify `Authorization: Bearer` header format is correct

### Rate Limit Exceeded

**Symptoms**: Receiving 429 "Rate limit exceeded" errors

**Solutions**:
1. Increase rate limit in token settings
2. Implement request throttling in your client
3. Distribute requests over time
4. Consider creating multiple tokens for different services

### Edge Function Errors

**Symptoms**: Receiving 500 errors or timeouts

**Solutions**:
1. Check Edge Function logs: `supabase functions logs integration-tickets`
2. Verify environment variables are set correctly
3. Ensure service role key has proper permissions
4. Check Supabase project status

### Tickets Not Visible

**Symptoms**: Created tickets don't appear in the app

**Solutions**:
1. Verify RLS policies allow viewing
2. Check if tickets are assigned to the correct user
3. Ensure `integration_source` field is set correctly
4. Review database logs for permission errors

## Next Steps

- **Webhooks**: Set up webhooks for real-time ticket updates (coming soon)
- **Advanced Monitoring**: Integrate with your APM tool
- **Load Testing**: Test your integration under load
- **Documentation**: Document your integration for your team

## Support

For issues or questions:

1. Check the [External Integrations Guide](docs/EXTERNAL_INTEGRATIONS.md)
2. Review the [API Integration Reference](docs/API_INTEGRATION.md)
3. Check Supabase Edge Function logs
4. Contact your system administrator

## Additional Resources

- [Supabase Edge Functions Documentation](https://supabase.com/docs/guides/functions)
- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [Flutter Documentation](https://docs.flutter.dev/)
