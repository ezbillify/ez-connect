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
│   └── 20240101000005_seed_data_and_views.sql
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

### Environment Variables

For production, update your environment:
```bash
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your_production_anon_key
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