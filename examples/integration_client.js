import fetch from 'node-fetch';

const TOKEN = process.env.INTEGRATION_TOKEN;
const BASE_URL = process.env.INTEGRATION_URL;

if (!TOKEN || !BASE_URL) {
  console.error('Please set INTEGRATION_TOKEN and INTEGRATION_URL environment variables');
  process.exit(1);
}

async function callIntegrationAPI(path, options = {}) {
  const response = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: {
      Authorization: `Bearer ${TOKEN}`,
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Request failed with ${response.status}: ${errorText}`);
  }

  return response.json();
}

async function createTicket() {
  return callIntegrationAPI('/tickets', {
    method: 'POST',
    body: JSON.stringify({
      title: 'Integration Ticket from Node.js',
      description: 'Created via the external integration API',
      priority: 'high',
      metadata: {
        requester: 'node-script',
        payloadHash: Math.random().toString(36).substring(2),
      },
    }),
  });
}

async function getTicket(ticketId) {
  return callIntegrationAPI(`/tickets/${ticketId}`);
}

async function addComment(ticketId, content) {
  return callIntegrationAPI(`/tickets/${ticketId}/comments`, {
    method: 'POST',
    body: JSON.stringify({
      content,
      is_internal: false,
    }),
  });
}

async function updateStatus(ticketId, status) {
  return callIntegrationAPI(`/tickets/${ticketId}/status`, {
    method: 'PATCH',
    body: JSON.stringify({ status }),
  });
}

async function runDemo() {
  try {
    console.log('Creating ticket...');
    const createResponse = await createTicket();
    console.log('Ticket created:', createResponse);

    const ticketId = createResponse.ticket?.id;
    if (!ticketId) {
      throw new Error('Ticket ID not found in response');
    }

    console.log('\nFetching ticket...');
    const ticket = await getTicket(ticketId);
    console.log('Ticket details:', ticket);

    console.log('\nAdding comment...');
    const comment = await addComment(ticketId, 'Hello from Node.js client!');
    console.log('Comment created:', comment);

    console.log('\nUpdating status...');
    const statusUpdate = await updateStatus(ticketId, 'in_progress');
    console.log('Status update response:', statusUpdate);

    console.log('\nIntegration demo completed successfully.');
  } catch (error) {
    console.error('Integration demo failed:', error.message);
    process.exit(1);
  }
}

runDemo();
