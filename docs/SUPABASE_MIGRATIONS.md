# Supabase Migration Guide

## Quick Start

### Prerequisites
- Install Supabase CLI: `npm install -g supabase`
- Docker installed and running
- Supabase account (for cloud deployment)

### Local Development Setup

1. **Initialize Supabase Project**
   ```bash
   cd /home/engine/project
   supabase init
   ```

2. **Start Local Development**
   ```bash
   supabase start
   ```
   This will start:
   - PostgreSQL database (port 54322)
   - Supabase Studio (port 54323)
   - Auth service (port 54321)
   - Storage service (port 54324)

3. **Apply Migrations**
   ```bash
   supabase db reset
   ```
   This applies all migrations and seeds the database.

### Accessing Local Services

- **Supabase Studio**: http://localhost:54323
- **Database URL**: postgresql://postgres:postgres@localhost:54322/postgres
- **Anon Key**: Found in `supabase/.env` or Studio settings
- **Service Role Key**: Found in `supabase/.env` or Studio settings

## Migration Management

### Creating New Migrations

```bash
# Create a new migration file
supabase migration new add_new_feature

# This creates a new file in supabase/migrations/
# Format: YYYYMMDDHHMMSS_description.sql
```

### Migration Best Practices

1. **One Feature Per Migration**
   - Keep migrations focused and atomic
   - Each migration should be independently testable

2. **Use Descriptive Names**
   ```
   Good: 20240101000001_initial_schema.sql
   Bad: migration_1.sql
   ```

3. **Write Reversible SQL**
   ```sql
   -- Use IF NOT EXISTS for creates
   CREATE TABLE IF NOT EXISTS users (...);
   
   -- Use ON CONFLICT for inserts
   INSERT INTO users (id, name) VALUES (1, 'test')
   ON CONFLICT (id) DO NOTHING;
   ```

### Applying Migrations

```bash
# Apply all pending migrations
supabase db push

# Apply specific migration
supabase migration up 20240101000001_initial_schema.sql

# Reset database (development only)
supabase db reset

# Generate types for TypeScript
supabase gen types typescript --local > types/supabase.ts
```

### Migration Status

```bash
# Check migration status
supabase migration list

# View migration history
supabase db diff --schema public
```

## Environment Configuration

### Local Environment (.env.local)
```bash
# Add to your Flutter environment
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your_local_anon_key
```

### Production Environment
```bash
# Link to your Supabase project
supabase link --project-ref your-project-ref

# Push to production
supabase db push
```

## Database Operations

### Connecting to Database
```bash
# Connect via psql
psql 'postgresql://postgres:postgres@localhost:54322/postgres'

# Connect via Supabase CLI
supabase db shell
```

### Common Database Tasks
```sql
-- View all tables
\dt

-- View table structure
\d customers

-- View RLS policies
SELECT * FROM pg_policies WHERE tablename = 'customers';

-- View functions
\df

-- View triggers
SELECT * FROM pg_trigger WHERE tgrelid = 'customers'::regclass;
```

## Testing Migrations

### Local Testing Workflow
1. Reset database: `supabase db reset`
2. Apply migrations: `supabase db push`
3. Test changes in Studio or psql
4. Verify RLS policies work correctly
5. Test with your Flutter app

### Testing RLS Policies
```sql
-- Test as anonymous user
SET request.jwt = '{"role":"anon"}';
SELECT * FROM customers;

-- Test as authenticated user
SET request.jwt = '{"role":"authenticated","aud":"authenticated","exp":1234567890,"sub":"user-id"}';
SELECT * FROM customers;

-- Test as admin
SET request.jwt = '{"role":"authenticated","aud":"authenticated","exp":1234567890,"sub":"admin-id","role":"admin"}';
SELECT * FROM customers;
```

## Schema Management

### Viewing Schema
```bash
# Generate schema diagram
supabase db diff --schema public > schema.sql

# View specific table
supabase db diff --table customers
```

### Schema Changes
```sql
-- Add column
ALTER TABLE customers ADD COLUMN new_column TEXT;

-- Rename column
ALTER TABLE customers RENAME COLUMN old_name TO new_name;

-- Drop column
ALTER TABLE customers DROP COLUMN old_column;

-- Add constraint
ALTER TABLE customers ADD CONSTRAINT unique_email UNIQUE (email);
```

## Backup and Recovery

### Local Backups
```bash
# Backup local database
pg_dump 'postgresql://postgres:postgres@localhost:54322/postgres' > backup.sql

# Restore from backup
psql 'postgresql://postgres:postgres@localhost:54322/postgres' < backup.sql
```

### Production Backups
- Use Supabase dashboard for automated backups
- Manual backups via Supabase CLI
- Point-in-time recovery available on paid plans

## Troubleshooting

### Common Issues

1. **Migration Conflicts**
   ```bash
   # Reset and reapply
   supabase db reset
   ```

2. **RLS Policy Issues**
   ```sql
   -- Check if RLS is enabled
   SELECT relname, relrowsecurity FROM pg_class WHERE relname = 'customers';
   
   -- Check specific policies
   SELECT * FROM pg_policies WHERE tablename = 'customers';
   ```

3. **Permission Errors**
   ```sql
   -- Check user permissions
   SELECT * FROM pg_roles WHERE rolname = 'authenticated';
   
   -- Grant necessary permissions
   GRANT USAGE ON SCHEMA public TO authenticated;
   GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;
   ```

### Debug Mode
```bash
# Start with debug logging
supabase start --debug

# View logs
supabase logs db
```

## Performance Optimization

### Index Management
```sql
-- View indexes
SELECT * FROM pg_indexes WHERE tablename = 'customers';

-- Add index
CREATE INDEX idx_customers_email ON customers(email);

-- Analyze query performance
EXPLAIN ANALYZE SELECT * FROM customers WHERE email = 'test@example.com';
```

### Connection Pooling
- Configure connection pool in `supabase/config.toml`
- Monitor connection usage in Studio
- Use prepared statements in your application

## Deployment

### Pre-deployment Checklist
1. [ ] All migrations tested locally
2. [ ] RLS policies verified
3. [ ] Performance queries optimized
4. [ ] Backup strategy confirmed
5. [ ] Rollback plan prepared

### Deployment Steps
```bash
# Link to production project
supabase link --project-ref your-production-project

# Review changes
supabase db diff

# Deploy changes
supabase db push

# Verify deployment
supabase migration list
```

### Production Monitoring
- Monitor database performance in Supabase dashboard
- Set up alerts for slow queries
- Regular backup verification
- User activity monitoring

## Integration with Flutter

### Environment Setup
```dart
// lib/core/supabase_client.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClient {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }
}
```

### Type Generation
```bash
# Generate TypeScript types (for reference)
supabase gen types typescript --local > lib/types/supabase.ts

# Generate Dart types (manual or use code generator)
# Consider using dart_json_generator or similar
```

### Real-time Subscriptions
```dart
// Example real-time subscription
final subscription = supabase
    .from('customers')
    .on(SupabaseEventTypes.all, (payload) {
      // Handle real-time updates
    })
    .subscribe();
```

## Security Best Practices

### API Keys
- Never expose service role key in client code
- Use row level security for all data access
- Implement proper JWT validation
- Regular key rotation for production

### Data Privacy
- Encrypt sensitive data at rest
- Use HTTPS for all communications
- Implement proper data retention policies
- Regular security audits

### Access Control
- Principle of least privilege
- Regular permission reviews
- Audit trail for all data changes
- Integration token management

## Resources

### Documentation
- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)

### Tools
- [Supabase CLI](https://supabase.com/docs/reference/cli)
- [PostgreSQL Tools](https://www.postgresql.org/docs/current/app-psql.html)
- [Database Diagram Tools](https://draw.io/)

### Community
- [Supabase Discord](https://discord.supabase.com)
- [GitHub Issues](https://github.com/supabase/supabase/issues)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/supabase)