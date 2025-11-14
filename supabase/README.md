# Supabase Database Setup

This directory contains the complete Supabase schema and migrations for the CRM Flutter application.

## 📁 Directory Structure

```
supabase/
├── config.toml                 # Supabase configuration
├── migrations/                 # Database migration files
│   ├── 20240101000001_initial_schema.sql
│   ├── 20240101000002_rls_policies.sql
│   ├── 20240101000003_functions_triggers.sql
│   ├── 20240101000004_storage_setup.sql
│   ├── 20240101000005_seed_data_and_views.sql
│   └── 20240101000006_seed_admin_user.sql
├── sql/                        # SQL utilities and tests
│   └── test_migrations.sql     # Comprehensive test suite
└── README.md                   # This file
```

## 🚀 Quick Start

### 1. Install Prerequisites

```bash
# Install Supabase CLI
npm install -g supabase

# Ensure Docker is installed and running
docker --version
```

### 2. Initialize Local Development

```bash
# From project root
./supabase_dev.sh init
./supabase_dev.sh start
```

This will:
- Start PostgreSQL database (port 54322)
- Start Supabase Studio (port 54323)
- Start Auth and Storage services
- Apply all migrations automatically

### 3. Access Your Local Instance

- **Supabase Studio**: http://localhost:54323
- **Database Connection**: `postgresql://postgres:postgres@localhost:54322/postgres`

### 4. Configure Flutter App

Add to your `.env.local` file:
```bash
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your_local_anon_key
```

## 📊 Schema Overview

### Core Entities

| Entity | Purpose | Key Features |
|--------|---------|--------------|
| **Profiles** | User management | Roles (agent/admin), auth integration |
| **Products** | Product catalog | Max 3 active products constraint |
| **Customers** | Customer management | Acquisition pipeline, ownership |
| **Tickets** | Support tracking | Priority levels, workflow states |
| **Interactions** | Communication log | Multiple channels, follow-ups |
| **Attachments** | File management | Secure storage, access control |

### Security Features

- **Row Level Security (RLS)** on all tables
- **Role-based access control** (agent/admin)
- **Integration tokens** for API access
- **Comprehensive audit logging**
- **Secure file storage** with permissions

## 🔧 Development Workflow

### Creating New Migrations

```bash
# Create a new migration
./supabase_dev.sh create add_new_feature

# Edit the generated migration file
# Apply the migration
./supabase_dev.sh migrate
```

### Common Development Tasks

```bash
# Reset database (development only)
./supabase_dev.sh reset

# Check migration status
./supabase_dev.sh status

# Open database shell
./supabase_dev.sh shell

# Generate TypeScript types
./supabase_dev.sh types
```

## 📋 Migration Details

### 1. Initial Schema (`20240101000001_initial_schema.sql`)
- Creates all base tables
- Defines enums and data types
- Sets up basic constraints and indexes
- Enables UUID generation

### 2. RLS Policies (`20240101000002_rls_policies.sql`)
- Implements comprehensive security policies
- Role-based access control
- Integration token permissions
- Data visibility rules

### 3. Functions & Triggers (`20240101000003_functions_triggers.sql`)
- Audit logging functionality
- Automatic timestamp updates
- Ticket workflow tracking
- Profile creation on signup

### 4. Storage Setup (`20240101000004_storage_setup.sql`)
- File storage configuration
- Attachment metadata tracking
- Secure file access policies
- Storage bucket creation

### 5. Seed Data & Views (`20240101000005_seed_data_and_views.sql`)
- Default acquisition stages
- Sample products
- Summary views for common queries
- Dashboard functions

### 6. Admin User Setup (`20240101000006_seed_admin_user.sql`)
- Creates initial admin/superadmin user
- Email: `admin@ezbillify.com`
- Password: `admin123`
- Helper function to reset admin password

## 🔐 Admin Access

An admin user is automatically created during migration:

**Credentials:**
- **Email**: `admin@ezbillify.com`
- **Password**: `admin123`

**Important**: Change the admin password immediately after first login in production!

### Resetting Admin Password

If you need to reset the admin password:

```sql
-- Via Supabase Studio SQL editor or psql
SELECT reset_admin_password('new_password_here');
```

Or for development (reset to default):

```sql
SELECT reset_admin_password(); -- resets to 'admin123'
```

## 🔒 Security Model

### Access Patterns

| Role | Capabilities |
|------|--------------|
| **Anonymous** | No access (authentication required) |
| **Agent** | View/manage own customers and assigned tickets |
| **Admin** | Full access to all data and configuration |
| **Integration Token** | Limited access based on permissions |

### Key Security Features

1. **Row Level Security**: All tables have RLS enabled
2. **Data Isolation**: Users only see data they're authorized to access
3. **Audit Trail**: Complete logging of all data changes
4. **Secure Storage**: File access controlled through ticket permissions
5. **Token Security**: Integration tokens with scoped permissions

## 📈 Performance Optimizations

### Indexes
- Foreign key relationships
- Status and priority columns
- Timestamp columns for date queries
- Composite indexes for common patterns

### Views
- Pre-computed summary data
- Simplified common queries
- Performance optimization for dashboards

### Functions
- Server-side data processing
- Reduced client-side complexity
- Consistent business logic

## 🧪 Testing

### Local Testing

```bash
# Reset and apply all migrations
./supabase_dev.sh reset

# Test RLS policies
./supabase_dev.sh shell
# Then run the test queries from docs/SUPABASE_MIGRATIONS.md
```

### Testing RLS Policies

```sql
-- Test as different user roles
SET request.jwt = '{"role":"authenticated","sub":"user-id","role":"agent"}';
SELECT * FROM customers;

SET request.jwt = '{"role":"authenticated","sub":"admin-id","role":"admin"}';
SELECT * FROM customers;
```

## 🚀 Deployment

### Production Setup

1. **Create Supabase Project**
   ```bash
   supabase projects create
   ```

2. **Link to Project**
   ```bash
   supabase link --project-ref your-project-ref
   ```

3. **Deploy Migrations**
   ```bash
   supabase db push
   ```

4. **Deploy Edge Functions**
   ```bash
   # Deploy integration-tickets function
   supabase functions deploy integration-tickets
   
   # Deploy user-admin function
   supabase functions deploy user-admin
   
   # Set environment variables for Edge Functions
   supabase secrets set SMTP_FROM=noreply@yourdomain.com
   ```

### Environment Variables

For production, update your environment:
```bash
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your_production_anon_key
```

### Edge Functions

The project includes two Supabase Edge Functions:

#### 1. integration-tickets

Location: `supabase/functions/integration-tickets/`

Purpose: REST API for external ticket management integrations

Deploy:
```bash
supabase functions deploy integration-tickets
```

#### 2. user-admin

Location: `supabase/functions/user-admin/`

Purpose: User management APIs for administrators (invitations, role updates, password resets)

Deploy:
```bash
supabase functions deploy user-admin

# Configure SMTP for email notifications
supabase secrets set SMTP_FROM=noreply@yourdomain.com
```

**Required Secrets:**
- `SMTP_FROM` - Email address for outbound notifications

**Endpoints:**
- `POST /invitations` - Create user invitation
- `POST /invitations/:id/resend` - Resend invitation
- `POST /users/roles/bulk` - Bulk update user roles
- `PATCH /users/:id/status` - Toggle user status
- `PATCH /users/:id/password` - Reset user password
- `GET /activity-log` - Get user activity log

See `docs/AUTHENTICATION.md` for complete API documentation.

### Deploying All Components

To deploy everything at once:

```bash
# Deploy database migrations
supabase db push

# Deploy all Edge Functions
supabase functions deploy integration-tickets
supabase functions deploy user-admin

# Set required secrets
supabase secrets set SMTP_FROM=noreply@yourdomain.com
```

## 📚 Documentation

- **[Schema Documentation](../docs/SUPABASE_SCHEMA.md)**: Complete ERD and table descriptions
- **[Migration Guide](../docs/SUPABASE_MIGRATIONS.md)**: Detailed migration instructions
- **[Supabase Docs](https://supabase.com/docs)**: Official Supabase documentation

## 🔍 Troubleshooting

### Common Issues

1. **Port Conflicts**
   ```bash
   # Check what's using the ports
   lsof -i :54322
   lsof -i :54323
   ```

2. **Migration Conflicts**
   ```bash
   # Reset and reapply
   ./supabase_dev.sh reset
   ```

3. **Permission Errors**
   ```sql
   -- Check RLS policies
   SELECT * FROM pg_policies WHERE tablename = 'customers';
   ```

### Getting Help

- Check the [migration guide](../docs/SUPABASE_MIGRATIONS.md)
- Review [Supabase documentation](https://supabase.com/docs)
- Check [GitHub issues](https://github.com/supabase/supabase/issues)

### Admin Login Issues

If you cannot login with the admin credentials:

1. **Verify user exists:**
   ```sql
   SELECT id, email, email_confirmed_at FROM auth.users WHERE email = 'admin@ezbillify.com';
   ```

2. **Check profile:**
   ```sql
   SELECT * FROM profiles WHERE email = 'admin@ezbillify.com';
   ```

3. **Reset password:**
   ```sql
   SELECT reset_admin_password('admin123');
   ```

4. **Re-create admin user:**
   ```bash
   ./supabase_dev.sh shell
   # Then run the seed_admin_user function from migration 20240101000006
   ```

### RLS Policy Issues

If you're getting permission errors:

1. **Check RLS is enabled:**
   ```sql
   SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';
   ```

2. **View policies for a table:**
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'your_table_name';
   ```

3. **Test as admin:**
   ```sql
   -- Set session to simulate admin user
   SET request.jwt.claims TO '{"sub": "admin-user-id", "role": "authenticated"}';
   ```

### Migration Errors

If migrations fail:

1. **Check current migration status:**
   ```bash
   ./supabase_dev.sh status
   ```

2. **View migration history:**
   ```sql
   SELECT * FROM supabase_migrations.schema_migrations ORDER BY version;
   ```

3. **Reset and retry (development only):**
   ```bash
   ./supabase_dev.sh reset
   ```

4. **Manual migration repair:**
   ```bash
   # Mark a migration as applied manually
   ./supabase_dev.sh shell
   # INSERT INTO supabase_migrations.schema_migrations (version) VALUES ('20240101000006');
   ```

## 🛠️ Scripts

### `supabase_dev.sh`

A helper script for common development tasks:

```bash
./supabase_dev.sh help
```

Available commands:
- `init` - Initialize Supabase project
- `start` - Start local services
- `stop` - Stop local services
- `reset` - Reset database
- `migrate` - Apply migrations
- `create <name>` - Create new migration
- `status` - Show migration status
- `types` - Generate TypeScript types
- `shell` - Open database shell

### `scripts/bootstrap_supabase_ci.sh`

Used by CI and local test automation to:
- Stop any running Supabase containers and restart the lightweight stack.
- Wait for services to become available.
- Apply all migrations and seed data via `supabase db reset`.

This script is invoked automatically from `scripts/run_flutter_tests.sh` and the GitHub Actions workflow.

## 🔄 Maintenance

### Regular Tasks

1. **Database Backups**
   ```bash
   pg_dump 'postgresql://postgres:postgres@localhost:54322/postgres' > backup.sql
   ```

2. **Performance Monitoring**
   - Check slow queries in Supabase Studio
   - Monitor connection usage
   - Review index effectiveness

3. **Security Reviews**
   - Audit RLS policies quarterly
   - Review integration tokens
   - Check user access patterns

### Cleanup

```sql
-- Clean up old audit history (older than 1 year)
DELETE FROM audit_history WHERE created_at < NOW() - INTERVAL '1 year';

-- Clean up orphaned attachments
SELECT cleanup_orphaned_attachments();
```

## 📞 Support

For issues related to:
- **Schema Design**: Check the [schema documentation](../docs/SUPABASE_SCHEMA.md)
- **Migration Issues**: See [migration guide](../docs/SUPABASE_MIGRATIONS.md)
- **Supabase Platform**: Visit [Supabase support](https://supabase.com/docs/support)

---

**Note**: This setup is designed for development and production use. Always test migrations thoroughly before applying to production databases.