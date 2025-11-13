# CRM Workflows and User Guide

## Table of Contents
1. [Product Management Workflow](#product-management-workflow)
2. [Customer Management Workflow](#customer-management-workflow)
3. [Acquisition Pipeline Workflow](#acquisition-pipeline-workflow)
4. [Interaction Logging Workflow](#interaction-logging-workflow)
5. [Common Scenarios](#common-scenarios)

## Product Management Workflow

### Creating a New Product

1. Navigate to the **Products** tab
2. Tap the **+** (floating action button)
3. Fill in the product details:
   - **Product Name** (required)
   - **Description** (optional)
   - **Active Status** (toggle)
4. Tap **Create Product**

**Note**: You can only have a maximum of 3 active products. If you try to activate a 4th product, you'll receive an error message. Deactivate an existing product first.

### Editing a Product

1. Navigate to the **Products** tab
2. Tap on the product you want to edit
3. Tap the **edit** icon in the app bar
4. Make your changes
5. Tap **Update Product**

**Optimistic Update**: The UI updates immediately. If the backend operation fails, the change will be reverted.

### Deactivating/Activating a Product

1. Open the product detail or edit screen
2. Toggle the **Active** switch
3. Save changes

**Use Case**: Deactivate products that are no longer being sold but keep them in the system for historical reference.

### Deleting a Product

1. Open the product detail screen
2. Tap the **delete** icon
3. Confirm the deletion

**Warning**: This permanently removes the product. Consider deactivating instead.

---

## Customer Management Workflow

### Adding a New Customer

1. Navigate to the **Customers** tab
2. Tap the **+** (floating action button)
3. Fill in customer details:
   - **Name** (required)
   - **Email** (optional, must be valid)
   - **Phone** (optional)
   - **Product** (select from active products)
   - **Status** (defaults to "Lead")
   - **Acquisition Source** (e.g., Website, Referral)
   - **Owner** (sales rep name)
4. Tap **Create Customer**

### Searching for Customers

1. Navigate to the **Customers** tab
2. Use the search bar at the top
3. Search by:
   - Customer name
   - Email address
   - Phone number

**Real-time**: Results update as you type.

### Filtering Customers

1. Navigate to the **Customers** tab
2. Tap the **filter** icon
3. Select a filter:
   - **All Customers**
   - **Leads**
   - **Qualified**
   - **Closed Won**

### Viewing Customer Details

1. Tap on any customer in the list
2. View comprehensive information:
   - Contact details
   - Associated product
   - Acquisition source and owner
   - Status and created date
3. Tap **View Interactions** to see communication history

### Editing Customer Information

1. Open customer detail screen
2. Tap the **edit** icon
3. Update fields as needed
4. Tap **Update Customer**

### Archiving a Customer

1. Open customer detail screen
2. Tap the **⋮** (menu) icon
3. Select **Archive**
4. Confirm the action

**Note**: Archived customers are hidden from the main list but not permanently deleted. They can be restored if needed.

### Deleting a Customer

1. Open customer detail screen
2. Tap the **⋮** (menu) icon
3. Select **Delete**
4. Confirm the action

**Warning**: This permanently removes the customer and all associated interactions.

---

## Acquisition Pipeline Workflow

### Understanding the Pipeline

The acquisition pipeline consists of 6 stages:
1. **Lead**: Initial contact, not yet qualified
2. **Qualified**: Meets criteria, potential opportunity
3. **Proposal**: Proposal sent, awaiting response
4. **Negotiation**: Actively negotiating terms
5. **Closed Won**: Successfully acquired customer
6. **Closed Lost**: Opportunity lost

### Viewing the Pipeline

1. Navigate to the **Pipeline** tab
2. Choose your view:
   - **Kanban View** (default): Visual columns with drag-and-drop
   - **List View**: Expandable sections by stage

**Toggle View**: Tap the view icon in the app bar.

### Moving Customers Through Stages (Kanban View)

1. Long-press on a customer card
2. Drag to the desired stage column
3. Release to drop

**Confirmation**: A snackbar confirms the stage change.

### Moving Customers Through Stages (List View)

1. Tap on a customer to open details
2. Tap **Edit**
3. Change the **Status** dropdown
4. Save changes

### Monitoring Pipeline Health

- Each stage shows the **count** of customers
- Visualize bottlenecks (stages with many customers)
- Identify stages needing attention

### Best Practices

- **Update regularly**: Move customers as soon as their status changes
- **Use acquisition source**: Track which channels bring the most leads
- **Assign owners**: Ensure accountability for each customer
- **Review closed lost**: Learn from unsuccessful opportunities

---

## Interaction Logging Workflow

### Adding an Interaction

1. Navigate to customer detail screen
2. Tap **View Interactions**
3. Tap the **Add Interaction** button
4. Fill in interaction details:
   - **Interaction Type** (e.g., "Initial Call", "Follow-up Email")
   - **Channel** (Phone, Email, Meeting, Chat, Other)
   - **Notes** (required, detailed description)
   - **Follow-up Date** (optional, for scheduling next action)
5. Tap **Save Interaction**

### Interaction Channels

- **Phone**: Telephone conversations
- **Email**: Email correspondence
- **Meeting**: In-person or video meetings
- **Chat**: Instant messaging (Slack, WhatsApp, etc.)
- **Other**: Any other communication method

### Viewing Interaction History

1. Navigate to customer detail screen
2. Tap **View Interactions**
3. View chronological list of all interactions
4. Most recent interactions appear first

### Interaction Details

Each interaction card shows:
- **Channel icon** and name
- **Interaction type**
- **Timestamp** of when it was logged
- **Detailed notes**
- **Follow-up date** (if scheduled)

### Scheduling Follow-ups

1. When adding/editing an interaction
2. Tap the **calendar** icon
3. Select a future date
4. Save the interaction

**Use Case**: Set reminders for when to contact the customer again.

### Best Practices

- **Log immediately**: Record interactions while details are fresh
- **Be specific**: Include key points discussed and outcomes
- **Set follow-ups**: Never let a lead go cold
- **Use appropriate channels**: Select the correct communication method

---

## Common Scenarios

### Scenario 1: Onboarding a New Lead

1. **Create Customer**
   - Add contact information
   - Set status to "Lead"
   - Record acquisition source (e.g., "Website Form")
   - Assign to sales rep

2. **Log Initial Contact**
   - Add interaction with channel "Email"
   - Note: "Sent welcome email with product information"
   - Schedule follow-up in 3 days

3. **Monitor Pipeline**
   - Check pipeline view to see new lead
   - Ensure lead doesn't stagnate

### Scenario 2: Managing Active Products Limit

1. **Current Situation**: 3 active products, need to add a 4th
2. **Review existing products**
   - Identify discontinued or low-performing product
3. **Deactivate old product**
   - Edit the product
   - Toggle "Active" to off
4. **Add new product**
   - Create new product with Active status

### Scenario 3: Qualifying a Lead

1. **Initial Contact Made**
   - Log interaction after first call
   - Record prospect's needs and budget

2. **Assess Qualification**
   - Does prospect meet criteria?
   - Budget available?
   - Timeline defined?

3. **Move to Qualified**
   - Open customer in pipeline
   - Drag to "Qualified" column
   - Or edit customer, change status to "Qualified"

4. **Schedule Proposal Meeting**
   - Add interaction
   - Type: "Qualification Call Complete"
   - Follow-up: Date of proposal presentation

### Scenario 4: Closing a Deal

1. **Final Negotiation**
   - Log all negotiation interactions
   - Document agreed terms

2. **Mark as Closed Won**
   - Move customer to "Closed Won" in pipeline
   - Add final interaction: "Deal Closed - Contract Signed"

3. **Associate with Product**
   - Ensure customer is linked to purchased product
   - Update any additional details

### Scenario 5: Handling Lost Opportunity

1. **Determine Outcome**
   - Prospect chose competitor
   - Budget constraints
   - Timeline changed

2. **Move to Closed Lost**
   - Drag to "Closed Lost" in pipeline

3. **Document Reason**
   - Add interaction explaining why deal was lost
   - Include: "Lost to competitor - pricing concerns"
   - This data helps improve future sales

4. **Archive or Keep**
   - Archive if no future opportunity
   - Keep active if re-engagement possible later

### Scenario 6: Team Handoff

1. **Sales Rep Change**
   - Edit customer record
   - Change "Owner" field to new rep

2. **Document Handoff**
   - Add interaction: "Customer transferred to [New Rep]"
   - Summarize current status and next steps

3. **Brief New Owner**
   - New rep reviews interaction history
   - Understands customer journey
   - Continues from current stage

### Scenario 7: Re-engaging Cold Lead

1. **Identify Cold Lead**
   - Review interaction history
   - Last contact was months ago

2. **Add Re-engagement Interaction**
   - Channel: Email or Phone
   - Type: "Re-engagement Attempt"
   - Note: Reason for reaching out

3. **Update Status if Responsive**
   - If interested, move back to appropriate stage
   - If not, consider archiving

### Scenario 8: Bulk Customer Search

1. **Filter by Product**
   - Use filter menu
   - Select specific product
   - See all customers for that product

2. **Search by Name**
   - Use search bar
   - Type partial name
   - Results update in real-time

3. **Combine Filters**
   - Apply product filter
   - Then add status filter
   - Narrow down to exact segment needed

---

## Tips for Maximum Efficiency

### For Sales Managers

- **Review pipeline daily**: Check for bottlenecks
- **Monitor team activity**: Ensure owners are logging interactions
- **Analyze closed lost**: Identify patterns to improve win rate
- **Balance product focus**: Ensure all active products have leads

### For Sales Reps

- **Log all interactions**: Maintain complete history
- **Update status promptly**: Keep pipeline accurate
- **Set follow-up reminders**: Never miss a touchpoint
- **Add detailed notes**: Help future you and your team

### For Customer Success

- **Track won customers**: Monitor post-sale engagement
- **Schedule check-ins**: Regular customer interactions
- **Link to products**: Ensure product association is correct
- **Document feedback**: Log customer suggestions and issues

---

## Troubleshooting

### "Maximum of 3 active products allowed"
**Solution**: Deactivate an existing product before activating a new one.

### Customer not appearing in search
**Possible causes**:
- Customer is archived (check filter settings)
- Typo in search query
- Customer doesn't match search criteria

### Can't move customer in pipeline
**Possible causes**:
- Network connection issue
- Try refreshing the screen
- Check if customer still exists

### Interaction not showing up
**Solution**:
- Pull to refresh
- Check network connection
- Verify customer wasn't deleted

---

## Data Relationships

```
Product
  ↓ (one-to-many)
Customer
  ↓ (one-to-many)
CustomerInteraction
```

- One product can have multiple customers
- One customer can have multiple interactions
- Customer can have zero or one product
- Deleting a customer deletes all their interactions
- Deleting a product doesn't delete customers (foreign key set to null)

---

## Keyboard Shortcuts & Gestures

- **Pull to refresh**: Swipe down on any list
- **Long press**: Hold to start dragging in Kanban view
- **Tap**: Open detail view
- **Swipe back**: Navigate back (iOS)

---

## Offline Behavior

- **Read operations**: Show cached data with offline indicator
- **Write operations**: Queue for sync, show pending indicator
- **Sync on reconnect**: Automatically sync when online
- **Conflict resolution**: Last write wins (optimistic updates)
