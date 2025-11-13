#!/usr/bin/env python3
"""
External Integration API Client Example (Python)
Usage:
  export INTEGRATION_TOKEN="your_token_here"
  export INTEGRATION_URL="your_edge_function_url"
  python integration_client.py
"""

import os
import sys
import json
import requests

TOKEN = os.environ.get("INTEGRATION_TOKEN")
BASE_URL = os.environ.get("INTEGRATION_URL")

if not TOKEN or not BASE_URL:
    print("Error: Please set INTEGRATION_TOKEN and INTEGRATION_URL environment variables")
    sys.exit(1)


class IntegrationClient:
    def __init__(self, base_url, token):
        self.base_url = base_url.rstrip("/")
        self.token = token
        self.session = requests.Session()
        self.session.headers.update({
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        })

    def _request(self, method, path, **kwargs):
        url = f"{self.base_url}{path}"
        response = self.session.request(method, url, **kwargs)
        response.raise_for_status()
        return response.json()

    def create_ticket(self, title, description=None, priority="medium", category=None, metadata=None):
        """Create a new ticket"""
        payload = {
            "title": title,
            "description": description,
            "priority": priority,
            "category": category,
            "metadata": metadata or {},
        }
        return self._request("POST", "/tickets", json=payload)

    def get_ticket(self, ticket_id):
        """Get ticket details"""
        return self._request("GET", f"/tickets/{ticket_id}")

    def add_comment(self, ticket_id, content, is_internal=False):
        """Add a comment to a ticket"""
        payload = {
            "content": content,
            "is_internal": is_internal,
        }
        return self._request("POST", f"/tickets/{ticket_id}/comments", json=payload)

    def update_status(self, ticket_id, status):
        """Update ticket status
        
        Valid statuses: 'open', 'in_progress', 'waiting', 'resolved', 'closed'
        """
        payload = {"status": status}
        return self._request("PATCH", f"/tickets/{ticket_id}/status", json=payload)

    def health_check(self):
        """Health check endpoint"""
        return self._request("GET", "/")


def main():
    client = IntegrationClient(BASE_URL, TOKEN)

    try:
        print("=== Creating ticket ===")
        create_response = client.create_ticket(
            title="Python Integration Test Ticket",
            description="This ticket was created via the Python integration client",
            priority="high",
            category="Integration",
            metadata={
                "source": "python-script",
                "version": "1.0",
            }
        )
        print(json.dumps(create_response, indent=2))

        ticket_id = create_response.get("ticket", {}).get("id")
        if not ticket_id:
            print("Error: Could not extract ticket ID from response")
            sys.exit(1)

        print(f"\n=== Getting ticket {ticket_id} ===")
        ticket = client.get_ticket(ticket_id)
        print(json.dumps(ticket, indent=2))

        print(f"\n=== Adding comment to ticket {ticket_id} ===")
        comment_response = client.add_comment(
            ticket_id,
            "Hello from Python! This comment was added via the integration API."
        )
        print(json.dumps(comment_response, indent=2))

        print(f"\n=== Updating status of ticket {ticket_id} ===")
        status_response = client.update_status(ticket_id, "in_progress")
        print(json.dumps(status_response, indent=2))

        print("\n=== Integration demo completed successfully ===")

    except requests.HTTPError as e:
        print(f"HTTP Error: {e}")
        print(f"Response: {e.response.text}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
