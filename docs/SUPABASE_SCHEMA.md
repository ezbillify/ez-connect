# Supabase Schema Documentation

## Overview

This CRM application uses Supabase as its backend database with PostgreSQL. The schema is designed to support customer relationship management, ticket tracking, and team collaboration with proper security and audit trails.

## Entity Relationship Diagram (ERD)

```
┌─────────────┐    ┌──────────────────┐    ┌──────────────────────┐
│   profiles  │    │     products     │    │  acquisition_stages  │
├─────────────┤    ├──────────────────┤    ├──────────────────────┤
│ id (PK)     │    │ id (PK)          │    │ id (PK)              │
│ email       │    │ name             │    │ name                 │
│ full_name   │    │ description      │    │ order_index          │
│ avatar_url  │    │ is_active        │    │ created_at           │
│ role        │    │ created_at       │    └──────────────────────┘
│ created_at  │    │ updated_at       │
│ updated_at  │    └──────────────────┘
└─────────────┘             │
        │                   │
        │                   │
        ▼                   ▼
┌─────────────┐    ┌──────────────────┐
│  customers  │    │ integration_tokens│
├─────────────┤    ├──────────────────┤
│ id (PK)     │    │ id (PK)          │
│ name        │    │ name             │
│ email       │    │ token_hash       │
│ phone       │    │ permissions      │
│ product_id  │◄───┤ is_active        │
│ status      │    │ last_used_at     │
│ acquisition │    │ created_by       │
│ owner       │◄───┤ created_at       │
│ is_archived │    │ expires_at       │
│ created_at  │    └──────────────────┘
│ updated_at  │
└─────────────┘             │
        │                   │
        │                   │
        ▼                   ▼
┌─────────────────────┐    ┌──────────────────────┐
│customer_interactions│    │     audit_history     │
├─────────────────────┤    ├──────────────────────┤
│ id (PK)             │    │ id (PK)              │
│ customer_id         │◄───│ table_name           │
│ type                │    │ record_id            │
│ channel             │    │ action               │
│ note                │    │ old_values           │
│ follow_up_date      │    │ new_values           │
│ created_by          │    │ changed_by           │
│ created_at          │    │ integration_token_id │
└─────────────────────┘    │ created_at           │
        │                  └──────────────────────┘
        │
        ▼
┌─────────────┐    ┌─────────────────────┐    ┌──────────────────┐
│   tickets   │    │ticket_workflow_hist │    │ticket_assignees │
├─────────────┤    ├─────────────────────┤    ├──────────────────┤
│ id (PK)     │    │ id (PK)             │    │ id (PK)          │
│ title       │    │ ticket_id           │◄───│ ticket_id        │
│ description │    │ from_status         │    │ user_id          │
│ priority    │    │ to_status           │    │ assigned_at      │
│ status      │    │ changed_by          │    │ assigned_by      │
│ customer_id │◄───│ note                │    └──────────────────┘
│ assigned_to │    │ created_at          │             │
│ created_by  │    └─────────────────────┘             │
│ created_at  │               │                        │
│ updated_at  │               │                        │
│ resolved_at │               ▼                        │
│ closed_at   │    ┌─────────────────────┐             │
└─────────────┘    │  ticket_comments   │             │
        │          ├─────────────────────┤             │
        │          │ id (PK)             │             │
        │          │ ticket_id           │◄────────────┘
        │          │ content             │
        │          │ is_internal         │
        ▼          │ created_by          │
┌─────────────────────┐ │ created_at          │
│ticket_attachments   │ │ updated_at          │
├─────────────────────┤ └─────────────────────┘
│ id (PK)             │             │
│ ticket_id           │◄────────────┘
│ file_name           │
│ file_path           │
│ file_size           │
│ mime_type           │
│ uploaded_by         │
│ uploaded_at         │
└─────────────────────┘
```

## Table Descriptions

### Core Tables

#### profiles
Extends Supabase auth.users with additional user information.
- **Purpose**: Store user profile data and roles
- **Key Features**: Role-based access (agent/admin), user metadata
- **Security**: Users can only view/update their own profile, admins can manage all

#### products
Stores product information with a maximum of 3 active products.
- **Purpose**: Product catalog management
- **Key Features**: Active/inactive status, max 3 active constraint
- **Security**: All authenticated users can view, only admins can manage

#### acquisition_stages
Defines the customer acquisition pipeline stages.
- **Purpose**: Standardize customer journey stages
- **Key Features**: Ordered stages, predefined pipeline
- **Security**: All authenticated users can view, only admins can manage

### Customer Management

#### customers
Central customer information and relationship management.
- **Purpose**: Store customer data and track acquisition progress
- **Key Features**: Status tracking, product association, ownership assignment
- **Security**: Users can view/manage customers they own, admins have full access

#### customer_interactions
Logs all customer communications and interactions.
- **Purpose**: Track customer communication history
- **Key Features**: Multiple channels, follow-up scheduling, interaction typing
- **Security**: Users can view interactions for customers they own

### Ticket System

#### tickets
Main ticket management system for customer support and issues.
- **Purpose**: Track support tickets and customer issues
- **Key Features**: Priority levels, status workflow, assignment management
- **Security**: Users can view tickets they created or are assigned to

#### ticket_workflow_history
Audit trail for ticket status changes.
- **Purpose**: Track ticket workflow transitions
- **Key Features**: Status change history, transition notes
- **Security**: Inherited from ticket access, automatic population

#### ticket_assignees
Supports multiple assignees per ticket.
- **Purpose**: Flexible ticket assignment
- **Key Features**: Multiple agents per ticket, assignment tracking
- **Security**: Users can manage assignees for tickets they can access

#### ticket_comments
Internal and external ticket communications.
- **Purpose**: Ticket discussion and resolution tracking
- **Key Features**: Internal/external comments, rich text support
- **Security**: Comment visibility based on ticket access and internal flag

### File Management

#### ticket_attachments
Tracks file attachments for tickets.
- **Purpose**: File management for ticket resolution
- **Key Features**: File metadata, size limits, type restrictions
- **Security**: Access based on ticket permissions

#### Storage Bucket: ticket-attachments
Supabase Storage bucket for actual file storage.
- **Purpose**: Secure file storage with access controls
- **Key Features**: 50MB file limit, MIME type restrictions, signed URLs
- **Security**: Row-level security based on ticket access

### Integration & Security

#### integration_tokens
API tokens for external integrations.
- **Purpose**: Secure API access for third-party integrations
- **Key Features**: Permission-based access, token expiration, usage tracking
- **Security**: Users can manage their own tokens, token validation

#### audit_history
Comprehensive audit trail for all data changes.
- **Purpose**: Track all modifications for compliance and debugging
- **Key Features**: Complete change tracking, user attribution, integration tracking
- **Security**: Admins can view all, users can view their own changes

## Enums & Data Types

### ticket_priority
- `low`: Low priority issues
- `medium`: Standard priority (default)
- `high`: High priority issues
- `urgent`: Critical issues requiring immediate attention

### ticket_status
- `open`: New ticket created
- `in_progress`: Work being performed
- `pending_customer`: Waiting for customer response
- `resolved`: Issue resolved, pending confirmation
- `closed`: Ticket completed
- `reopened`: Previously closed ticket reopened

### acquisition_stage_enum
- `lead`: Initial contact
- `qualified`: Qualified prospect
- `proposal`: Proposal sent
- `negotiation`: In negotiation
- `closed_won`: Deal won
- `closed_lost`: Deal lost

### interaction_channel
- `phone`: Phone calls
- `email`: Email communications
- `meeting`: In-person/virtual meetings
- `chat`: Chat/messaging platforms
- `other`: Other communication methods

### user_role
- `agent`: Standard user role
- `admin`: Administrative user with full access

## Security Model

### Row Level Security (RLS)

The schema implements comprehensive RLS policies:

#### Access Patterns
1. **Authenticated Users**: Can view data relevant to their role
2. **Agents**: Can view/manage customers they own, tickets assigned to them
3. **Admins**: Full access to all data
4. **Integration Tokens**: Limited access based on granted permissions

#### Policy Types
- **SELECT Policies**: Control data visibility
- **INSERT Policies**: Control data creation
- **UPDATE Policies**: Control data modification
- **DELETE Policies**: Control data removal

#### Key Security Features
- Users can only access their own profile data
- Customer and ticket access is ownership-based
- Integration tokens have scoped permissions
- All data changes are audited
- File access is controlled through ticket permissions

### Database Functions

#### Core Functions
- `update_updated_at_column()`: Automatic timestamp updates
- `create_audit_history()`: Comprehensive audit logging
- `log_ticket_status_change()`: Ticket workflow tracking
- `validate_integration_token_permissions()`: Token validation

#### Utility Functions
- `get_customer_stats()`: Customer analytics
- `get_ticket_stats()`: Ticket analytics
- `get_dashboard_data()`: Combined dashboard metrics
- `get_ticket_attachment_url()`: Secure file access

## Triggers

### Automated Triggers
1. **Timestamp Updates**: Automatic `updated_at` maintenance
2. **Audit Logging**: Complete change tracking
3. **Workflow History**: Ticket status transition logging
4. **Profile Creation**: Auto-create profile on user signup
5. **Product Validation**: Enforce max 3 active products constraint

## Views

### Summary Views
- `customer_summary`: Customer data with interaction/ticket counts
- `ticket_summary`: Ticket data with activity metrics
- `user_workload`: User performance and workload metrics

### Benefits
- Simplified common queries
- Pre-computed metrics
- Consistent data access patterns
- Performance optimization

## Storage Configuration

### Bucket: ticket-attachments
- **Access**: Private (authenticated users only)
- **File Size Limit**: 50MB
- **Allowed Types**: Images, PDFs, Office documents
- **Path Structure**: `{ticket_id}/{filename}`
- **Security**: RLS policies based on ticket access

## Migration Usage

### Running Migrations
```bash
# Apply all migrations
supabase db push

# Apply specific migration
supabase migration up 20240101000001_initial_schema.sql

# Reset database (development only)
supabase db reset
```

### Migration Order
1. `20240101000001_initial_schema.sql`: Base tables and enums
2. `20240101000002_rls_policies.sql`: Security policies
3. `20240101000003_functions_triggers.sql`: Database logic
4. `20240101000004_storage_setup.sql`: File storage
5. `20240101000005_seed_data_and_views.sql`: Seed data and views

### Development Workflow
1. Create new migration: `supabase migration new new_feature`
2. Write SQL changes
3. Test locally: `supabase start`
4. Apply: `supabase db push`
5. Review changes in Supabase Studio

## Performance Considerations

### Indexes
- Foreign key indexes for join performance
- Status and priority indexes for filtering
- Timestamp indexes for date-based queries
- Composite indexes for common query patterns

### Query Optimization
- Views pre-calculate common metrics
- Partitioning may be needed for large datasets
- Regular cleanup of old audit records
- Storage cleanup for orphaned files

## Best Practices

### Security
1. Always use RLS policies
2. Validate inputs in functions
3. Use parameterized queries
4. Regular security audits
5. Token rotation for integrations

### Performance
1. Monitor slow queries
2. Use appropriate indexes
3. Regular VACUUM and ANALYZE
4. Archive old audit data
5. Optimize storage usage

### Maintenance
1. Regular backups
2. Monitor storage usage
3. Update statistics
4. Review security policies
5. Test disaster recovery

## API Integration

### Authentication
- JWT tokens for user authentication
- Integration tokens for API access
- Role-based permission checking

### Rate Limiting
- Consider API rate limiting
- Monitor integration token usage
- Implement caching where appropriate

### Error Handling
- Use consistent error responses
- Log errors for debugging
- Provide meaningful error messages
- Handle edge cases gracefully