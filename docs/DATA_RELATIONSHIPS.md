# CRM Data Relationships and Architecture

## Overview

This document describes the data model, relationships, and architectural decisions for the CRM application.

## Entity Relationship Diagram

```
┌─────────────────┐
│    Product      │
│─────────────────│
│ id (PK)         │
│ name            │
│ description     │
│ is_active       │
│ created_at      │
│ updated_at      │
└─────────────────┘
        │
        │ 1:N (optional)
        ▼
┌─────────────────┐
│    Customer     │
│─────────────────│
│ id (PK)         │
│ name            │
│ email           │
│ phone           │
│ product_id (FK) │◄────┐
│ status          │     │
│ acq_source      │     │ References (nullable)
│ owner           │     │
│ is_archived     │     │
│ created_at      │     │
│ updated_at      │     │
└─────────────────┘     │
        │               │
        │ 1:N           │
        ▼               │
┌─────────────────┐     │
│ Interaction     │     │
│─────────────────│     │
│ id (PK)         │     │
│ customer_id (FK)├─────┘
│ type            │
│ channel         │
│ note            │
│ follow_up_date  │
│ created_at      │
└─────────────────┘
```

## Entities

### Product

**Purpose**: Represents products or services offered by the company.

**Fields**:
- `id` (UUID, Primary Key): Unique identifier
- `name` (String, Required): Product name
- `description` (String, Optional): Detailed product description
- `is_active` (Boolean, Default: true): Whether product is currently offered
- `created_at` (Timestamp): Record creation time
- `updated_at` (Timestamp): Last modification time

**Constraints**:
- Maximum 3 products can have `is_active = true` at any time
- Enforced by database trigger and application logic

**Indexes**:
- Primary key index on `id`
- Index on `is_active` for filtering

### Customer

**Purpose**: Represents potential or actual customers in the CRM system.

**Fields**:
- `id` (UUID, Primary Key): Unique identifier
- `name` (String, Required): Customer full name or company name
- `email` (String, Optional): Email address
- `phone` (String, Optional): Phone number
- `product_id` (UUID, Foreign Key, Optional): Associated product
- `status` (String, Default: 'lead'): Current stage in acquisition pipeline
- `acquisition_source` (String, Optional): How customer was acquired
- `owner` (String, Optional): Sales representative responsible
- `is_archived` (Boolean, Default: false): Soft deletion flag
- `created_at` (Timestamp): Record creation time
- `updated_at` (Timestamp): Last modification time

**Relationships**:
- Many-to-One with Product (optional)
- One-to-Many with CustomerInteraction

**Valid Status Values**:
- `lead`: Initial contact
- `qualified`: Meets qualification criteria
- `proposal`: Proposal sent
- `negotiation`: Actively negotiating
- `closed_won`: Successfully acquired
- `closed_lost`: Opportunity lost

**Indexes**:
- Primary key index on `id`
- Index on `status` (for pipeline queries)
- Index on `product_id` (for product filtering)
- Index on `is_archived` (for filtering active customers)

### CustomerInteraction

**Purpose**: Logs all interactions and communications with customers.

**Fields**:
- `id` (UUID, Primary Key): Unique identifier
- `customer_id` (UUID, Foreign Key, Required): Associated customer
- `type` (String, Required): Type of interaction (e.g., "Initial Call")
- `channel` (Enum, Required): Communication channel used
- `note` (String, Required): Detailed interaction notes
- `follow_up_date` (Timestamp, Optional): Scheduled follow-up date
- `created_at` (Timestamp): When interaction occurred/was logged

**Relationships**:
- Many-to-One with Customer (required, cascading delete)

**Valid Channel Values**:
- `phone`: Telephone conversation
- `email`: Email correspondence
- `meeting`: In-person or video meeting
- `chat`: Instant messaging
- `other`: Any other channel

**Indexes**:
- Primary key index on `id`
- Index on `customer_id` (for querying customer's history)
- Index on `created_at` (for chronological sorting)

## Relationships

### Product → Customer (One-to-Many, Optional)

**Nature**: A product can be associated with multiple customers, but customers don't require a product.

**Foreign Key**: `customers.product_id` → `products.id`

**Cascade Behavior**:
- **On Delete**: SET NULL (customer remains, product_id becomes null)
- **On Update**: CASCADE (product id changes propagate)

**Use Cases**:
- Track which product each customer is interested in
- Filter customers by product
- Generate product-specific reports

**Business Rules**:
- Customer can exist without a product (prospect phase)
- Customer can only be linked to one product at a time
- Product can be deleted without affecting customers

### Customer → CustomerInteraction (One-to-Many)

**Nature**: A customer can have multiple interactions recorded.

**Foreign Key**: `customer_interactions.customer_id` → `customers.id`

**Cascade Behavior**:
- **On Delete**: CASCADE (deleting customer deletes all interactions)
- **On Update**: CASCADE (customer id changes propagate)

**Use Cases**:
- View complete customer communication history
- Track touchpoints and engagement
- Schedule and monitor follow-ups
- Audit trail of customer relationship

**Business Rules**:
- Interaction must belong to a customer
- Deleting customer removes all interaction history
- Interactions are immutable once created (audit trail)

## Data Integrity Rules

### Product Integrity

1. **Active Product Limit**:
   ```sql
   COUNT(products WHERE is_active = true) <= 3
   ```
   - Enforced by database trigger
   - Enforced by repository layer
   - User notified in UI before attempt

2. **Name Uniqueness** (Recommended):
   - While not enforced, product names should be unique
   - Consider adding unique constraint in production

### Customer Integrity

1. **Email Validation**:
   - Format validated in UI
   - Optional field, but must be valid if provided

2. **Status Values**:
   - Should be one of the predefined acquisition stages
   - Consider CHECK constraint in database

3. **Archive State**:
   - Archived customers excluded from default queries
   - Can be restored by setting `is_archived = false`

### Interaction Integrity

1. **Customer Reference**:
   - Must reference valid, existing customer
   - Enforced by foreign key constraint

2. **Immutability**:
   - Once created, interactions should not be edited
   - Provides accurate audit trail
   - Consider removing update operations in production

## Query Patterns

### Common Queries

1. **Get Active Products**:
```sql
SELECT * FROM products WHERE is_active = true ORDER BY name;
```

2. **Get Customers in Pipeline Stage**:
```sql
SELECT * FROM customers 
WHERE status = 'qualified' AND is_archived = false
ORDER BY created_at DESC;
```

3. **Get Customer with Product Info**:
```sql
SELECT c.*, p.name as product_name
FROM customers c
LEFT JOIN products p ON c.product_id = p.id
WHERE c.id = ?;
```

4. **Get Customer Interaction History**:
```sql
SELECT * FROM customer_interactions
WHERE customer_id = ?
ORDER BY created_at DESC;
```

5. **Search Customers**:
```sql
SELECT * FROM customers
WHERE (name ILIKE '%search%' 
   OR email ILIKE '%search%' 
   OR phone ILIKE '%search%')
AND is_archived = false;
```

### Performance Considerations

1. **Indexes**: All foreign keys and frequently queried fields are indexed
2. **Pagination**: Implement for large customer lists
3. **Selective Fields**: Use `select()` to fetch only needed columns
4. **Caching**: Cache product list (small, rarely changes)

## Real-time Subscriptions

### Product Changes
```dart
supabase
  .from('products')
  .stream(primaryKey: ['id'])
  .listen((data) => updateUI(data));
```

**Use Cases**:
- Update product list when products added/edited
- Reflect active status changes immediately
- Multi-user synchronization

### Customer Changes
```dart
supabase
  .from('customers')
  .stream(primaryKey: ['id'])
  .eq('is_archived', false)
  .listen((data) => updateUI(data));
```

**Use Cases**:
- Update customer list in real-time
- Reflect pipeline movements immediately
- Collaborative team environment

### Interaction Changes
```dart
supabase
  .from('customer_interactions')
  .stream(primaryKey: ['id'])
  .eq('customer_id', customerId)
  .listen((data) => updateUI(data));
```

**Use Cases**:
- Show new interactions as they're added
- Team members see each other's notes
- Immediate follow-up notifications

## Data Migration Strategy

### Adding New Fields

1. Add column to Supabase table (with default value)
2. Update Dart model with new field
3. Update `fromJson` and `toJson` methods
4. Update UI forms if field is user-editable
5. Deploy and test

### Changing Relationships

1. Create new foreign key column (nullable)
2. Migrate existing data
3. Add constraint after migration
4. Update application code
5. Remove old column (if applicable)

### Schema Versioning

Consider adding a `schema_version` table to track migrations:
```sql
CREATE TABLE schema_version (
  version INTEGER PRIMARY KEY,
  applied_at TIMESTAMP DEFAULT NOW(),
  description TEXT
);
```

## Backup and Recovery

### Supabase Automatic Backups
- Daily backups (retained based on plan)
- Point-in-time recovery available

### Export Strategy
```sql
-- Export all data
COPY products TO '/tmp/products.csv' CSV HEADER;
COPY customers TO '/tmp/customers.csv' CSV HEADER;
COPY customer_interactions TO '/tmp/interactions.csv' CSV HEADER;
```

### Data Archival
- Periodically archive old `closed_lost` customers
- Archive interactions older than X years
- Maintain separate archive database

## Security Considerations

### Row Level Security (RLS)

Example policies for Supabase:

```sql
-- Products: Read for authenticated users
CREATE POLICY "Allow read for authenticated users" ON products
  FOR SELECT TO authenticated USING (true);

-- Products: Insert/Update for authenticated users
CREATE POLICY "Allow write for authenticated users" ON products
  FOR ALL TO authenticated USING (true);

-- Customers: Users see only their organization's data
CREATE POLICY "Users see own org customers" ON customers
  FOR SELECT TO authenticated 
  USING (auth.jwt()->>'org_id' = organization_id);
```

### Field-Level Security

- **Email/Phone**: Consider hashing or encrypting
- **Notes**: May contain sensitive information
- **Owner**: Restrict updates to managers

### Audit Trail

Consider adding audit table:
```sql
CREATE TABLE audit_log (
  id UUID PRIMARY KEY,
  table_name TEXT,
  record_id UUID,
  action TEXT,
  old_values JSONB,
  new_values JSONB,
  user_id UUID,
  created_at TIMESTAMP DEFAULT NOW()
);
```

## Testing Data Relationships

### Unit Tests

```dart
test('customer maintains relationship after product deletion', () async {
  final product = await createTestProduct();
  final customer = await createTestCustomer(productId: product.id);
  
  await deleteProduct(product.id);
  
  final fetchedCustomer = await getCustomer(customer.id);
  expect(fetchedCustomer.productId, null);
  expect(fetchedCustomer.id, customer.id);
});
```

### Integration Tests

```dart
test('deleting customer cascades to interactions', () async {
  final customer = await createTestCustomer();
  final interaction = await createTestInteraction(customer.id);
  
  await deleteCustomer(customer.id);
  
  final interactions = await getInteractions(customer.id);
  expect(interactions, isEmpty);
});
```

## Future Enhancements

### Potential Schema Changes

1. **Products**:
   - Add pricing information
   - Add product categories
   - Support product variants

2. **Customers**:
   - Add company information (separate entity)
   - Support multiple contacts per customer
   - Add tags/labels

3. **Interactions**:
   - Support attachments (files, images)
   - Add interaction outcomes
   - Link interactions to products

4. **New Entities**:
   - **Deals**: Separate entity for opportunities
   - **Tasks**: Action items assigned to users
   - **Documents**: Proposals, contracts, etc.
   - **Organizations**: Group customers by company

### Many-to-Many Relationships

Future: Customers interested in multiple products
```sql
CREATE TABLE customer_products (
  customer_id UUID REFERENCES customers(id),
  product_id UUID REFERENCES products(id),
  PRIMARY KEY (customer_id, product_id)
);
```

## Conclusion

The current data model provides a solid foundation for CRM functionality while maintaining simplicity and flexibility. The relationships are designed to support the core workflows while allowing for future expansion.

Key principles:
- **Referential Integrity**: Enforced by foreign keys
- **Soft Deletion**: Archives instead of hard deletes
- **Audit Trail**: Immutable interaction logs
- **Real-time Sync**: Supabase subscriptions keep data current
- **Scalability**: Indexed for performance as data grows
