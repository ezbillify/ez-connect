# API Integration Reference

## Base URL

```
https://<your-project>.supabase.co/functions/v1/integration-tickets
```

Replace `<your-project>` with your Supabase project reference.

## Authentication

All API requests must include a Bearer token in the Authorization header:

```http
Authorization: Bearer stk_your_integration_token_here
```

Tokens are issued via the admin UI under Settings → Integration Tokens.

## Error Responses

All error responses follow this format:

```json
{
  "error": "error_code",
  "message": "Human-readable error message",
  "details": "Additional error details (optional)"
}
```

### Common Error Codes

| Code | HTTP Status | Description |
| ---- | ----------- | ----------- |
| `missing_token` | 401 | No Authorization header provided |
| `invalid_token` | 401 | Token is invalid, disabled, or revoked |
| `rate_limit_exceeded` | 429 | Hourly rate limit reached |
| `validation_failed` | 500 | Token validation encountered an error |
| `not_found` | 404 | Requested resource does not exist |
| `missing_required_field` | 400 | Required field is missing from request |
| `internal_error` | 500 | Server-side error occurred |

## Rate Limiting

Each token has a configurable rate limit (default: 1000 requests/hour). When the limit is exceeded, the API returns:

```http
HTTP/1.1 429 Too Many Requests
```

```json
{
  "error": "rate_limit_exceeded",
  "message": "Rate limit exceeded"
}
```

Rate limits reset at the top of each hour.

## API Endpoints

### Health Check

Check API availability and discover available endpoints.

**Request:**

```http
GET /
Authorization: Bearer {token}
```

**Response:**

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

---

### Create Ticket

Create a new support ticket.

**Request:**

```http
POST /tickets
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "title": "Issue with API integration",
  "description": "Detailed description of the issue",
  "priority": "high",
  "category": "Technical Support",
  "metadata": {
    "customer_id": "CUST-123",
    "reference_id": "EXT-456"
  }
}
```

**Request Fields:**

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `title` | string | Yes | Ticket title (max 500 chars) |
| `description` | string | No | Detailed description |
| `priority` | string | No | Priority level: `low`, `medium` (default), `high`, `urgent` |
| `category` | string | No | Ticket category |
| `metadata` | object | No | Custom metadata (JSON object) |

**Response:**

```http
HTTP/1.1 201 Created
```

```json
{
  "ticket": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Issue with API integration",
    "description": "Detailed description of the issue",
    "status": "open",
    "priority": "high",
    "category": "Technical Support",
    "metadata": {
      "customer_id": "CUST-123",
      "reference_id": "EXT-456"
    },
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

**Error Responses:**

- `400` – Missing required `title` field
- `401` – Invalid or disabled token
- `429` – Rate limit exceeded
- `500` – Server error creating ticket

---

### Get Ticket

Retrieve details for a specific ticket.

**Request:**

```http
GET /tickets/{ticket_id}
Authorization: Bearer {token}
```

**Path Parameters:**

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `ticket_id` | UUID | Ticket identifier |

**Response:**

```http
HTTP/1.1 200 OK
```

```json
{
  "ticket": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Issue with API integration",
    "description": "Detailed description of the issue",
    "status": "in_progress",
    "priority": "high",
    "category": "Technical Support",
    "metadata": {
      "customer_id": "CUST-123",
      "reference_id": "EXT-456"
    },
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T11:45:00Z"
  }
}
```

**Error Responses:**

- `400` – Missing or invalid `ticket_id`
- `401` – Invalid or disabled token
- `404` – Ticket not found or not owned by token
- `429` – Rate limit exceeded
- `500` – Server error fetching ticket

**Note:** You can only retrieve tickets created by your integration token.

---

### Add Comment

Add a comment to an existing ticket.

**Request:**

```http
POST /tickets/{ticket_id}/comments
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "content": "We have received additional information from the customer.",
  "is_internal": false
}
```

**Path Parameters:**

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `ticket_id` | UUID | Ticket identifier |

**Request Fields:**

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `content` | string | Yes | Comment text |
| `is_internal` | boolean | No | Whether comment is internal (default: `false`) |

**Response:**

```http
HTTP/1.1 201 Created
```

```json
{
  "comment_id": "660e8400-e29b-41d4-a716-446655440111"
}
```

**Error Responses:**

- `400` – Missing required `content` field
- `401` – Invalid or disabled token, or not authorized for this ticket
- `404` – Ticket not found
- `429` – Rate limit exceeded
- `500` – Server error creating comment

---

### Update Ticket Status

Update the status of an existing ticket.

**Request:**

```http
PATCH /tickets/{ticket_id}/status
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "status": "resolved"
}
```

**Path Parameters:**

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `ticket_id` | UUID | Ticket identifier |

**Request Fields:**

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `status` | string | Yes | New status: `open`, `in_progress`, `waiting`, `resolved`, `closed` |

**Response:**

```http
HTTP/1.1 200 OK
```

```json
{
  "success": true,
  "ticket": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "resolved",
    "updated_at": "2024-01-15T14:20:00Z"
  }
}
```

**Error Responses:**

- `400` – Missing or invalid `status` field
- `401` – Invalid or disabled token, or not authorized for this ticket
- `404` – Ticket not found
- `429` – Rate limit exceeded
- `500` – Server error updating ticket

---

## Webhook Support (Future)

Webhook support for ticket updates is planned for a future release. When available, you will be able to register webhook URLs to receive notifications when ticket status changes.

## Best Practices

### Security

1. **Protect your token**: Never expose integration tokens in client-side code or public repositories
2. **Use HTTPS**: Always use HTTPS when making API requests
3. **Rotate tokens**: Regularly regenerate tokens (recommended: quarterly)
4. **Set expiration**: Configure token expiration dates for enhanced security
5. **Monitor usage**: Regularly review usage logs in the admin UI

### Performance

1. **Implement retries**: Use exponential backoff for failed requests
2. **Handle rate limits**: Implement rate limit detection and backoff strategies
3. **Cache responses**: Cache ticket data when appropriate
4. **Batch operations**: Group related operations to reduce API calls

### Error Handling

1. **Check status codes**: Always check HTTP status codes
2. **Parse error responses**: Extract error codes and messages from responses
3. **Log errors**: Log all API errors for debugging
4. **Implement fallbacks**: Have fallback strategies for critical operations

## Example Request Flows

### Creating and Tracking a Ticket

```javascript
// 1. Create ticket
const createResponse = await fetch(`${baseUrl}/tickets`, {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    title: 'Order processing issue',
    description: 'Customer order #12345 is stuck in processing',
    priority: 'high',
    metadata: { order_id: '12345' }
  })
});

const { ticket } = await createResponse.json();
const ticketId = ticket.id;

// 2. Add a comment
await fetch(`${baseUrl}/tickets/${ticketId}/comments`, {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    content: 'Customer has been contacted and we are investigating the issue'
  })
});

// 3. Update status
await fetch(`${baseUrl}/tickets/${ticketId}/status`, {
  method: 'PATCH',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    status: 'in_progress'
  })
});

// 4. Check ticket status later
const statusResponse = await fetch(`${baseUrl}/tickets/${ticketId}`, {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});

const ticketData = await statusResponse.json();
console.log('Current status:', ticketData.ticket.status);
```

## Testing

### Using curl

Test the API using the example scripts in `examples/integration_examples.sh`:

```bash
export TOKEN="your_token_here"
export BASE_URL="https://your-project.supabase.co/functions/v1/integration-tickets"
bash examples/integration_examples.sh
```

### Using Postman

Import the following environment variables:

- `base_url`: Your Edge Function URL
- `token`: Your integration token

Then use Postman collections to test each endpoint.

## Support

For issues related to:

- **Token management**: Use the admin UI or contact your system administrator
- **API errors**: Check the [Troubleshooting section](./EXTERNAL_INTEGRATIONS.md#troubleshooting)
- **Feature requests**: Submit via your project's issue tracker
