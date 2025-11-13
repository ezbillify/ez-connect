-- Initial schema setup for CRM application
-- Create enum types first

-- Ticket priority levels
CREATE TYPE ticket_priority AS ENUM (
    'low',
    'medium', 
    'high',
    'urgent'
);

-- Ticket status
CREATE TYPE ticket_status AS ENUM (
    'open',
    'in_progress',
    'pending_customer',
    'resolved',
    'closed',
    'reopened'
);

-- Customer acquisition stages
CREATE TYPE acquisition_stage_enum AS ENUM (
    'lead',
    'qualified',
    'proposal',
    'negotiation',
    'closed_won',
    'closed_lost'
);

-- Interaction channels
CREATE TYPE interaction_channel AS ENUM (
    'phone',
    'email',
    'meeting',
    'chat',
    'other'
);

-- User roles
CREATE TYPE user_role AS ENUM (
    'agent',
    'admin'
);

-- Create extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Explicitly ensure the function exists
CREATE OR REPLACE FUNCTION uuid_generate_v4()
RETURNS uuid AS 'uuid-ossp', 'uuid_generate_v4'
LANGUAGE c IMMUTABLE STRICT;

-- Create profiles table (extends auth.users)
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    full_name TEXT,
    avatar_url TEXT,
    role user_role DEFAULT 'agent' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create products table with max 3 active constraint
-- Note: The max 3 active products constraint is enforced via trigger in migration 20240101000005
CREATE TABLE products (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT DEFAULT '',
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create acquisition stages table
CREATE TABLE acquisition_stages (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    order_index INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    
    CONSTRAINT unique_order UNIQUE (order_index)
);

-- Create customers table
CREATE TABLE customers (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    status acquisition_stage_enum DEFAULT 'lead' NOT NULL,
    acquisition_source TEXT,
    owner UUID REFERENCES profiles(id) ON DELETE SET NULL,
    is_archived BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create customer interactions table
CREATE TABLE customer_interactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    channel interaction_channel NOT NULL,
    note TEXT NOT NULL,
    follow_up_date TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create tickets table
CREATE TABLE tickets (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    priority ticket_priority DEFAULT 'medium' NOT NULL,
    status ticket_status DEFAULT 'open' NOT NULL,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    assigned_to UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    resolved_at TIMESTAMP WITH TIME ZONE,
    closed_at TIMESTAMP WITH TIME ZONE
);

-- Create ticket workflow history table
CREATE TABLE ticket_workflow_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    from_status ticket_status,
    to_status ticket_status NOT NULL,
    changed_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create ticket assignees table (for multiple assignees support)
CREATE TABLE ticket_assignees (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    assigned_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    CONSTRAINT unique_ticket_assignee UNIQUE (ticket_id, user_id)
);

-- Create ticket comments table
CREATE TABLE ticket_comments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_internal BOOLEAN DEFAULT false NOT NULL,
    created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create integration tokens table
CREATE TABLE integration_tokens (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    token_hash TEXT NOT NULL UNIQUE,
    permissions TEXT[] NOT NULL DEFAULT '{}',
    is_active BOOLEAN DEFAULT true NOT NULL,
    last_used_at TIMESTAMP WITH TIME ZONE,
    created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE
);

-- Create audit history table
CREATE TABLE audit_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    table_name TEXT NOT NULL,
    record_id UUID NOT NULL,
    action TEXT NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    old_values JSONB,
    new_values JSONB,
    changed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    integration_token_id UUID REFERENCES integration_tokens(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create indexes for better performance
CREATE INDEX idx_customers_status ON customers(status);
CREATE INDEX idx_customers_owner ON customers(owner);
CREATE INDEX idx_customers_product_id ON customers(product_id);
CREATE INDEX idx_customer_interactions_customer_id ON customer_interactions(customer_id);
CREATE INDEX idx_customer_interactions_created_at ON customer_interactions(created_at);
CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_tickets_priority ON tickets(priority);
CREATE INDEX idx_tickets_customer_id ON tickets(customer_id);
CREATE INDEX idx_tickets_assigned_to ON tickets(assigned_to);
CREATE INDEX idx_tickets_created_at ON tickets(created_at);
CREATE INDEX idx_ticket_workflow_history_ticket_id ON ticket_workflow_history(ticket_id);
CREATE INDEX idx_ticket_comments_ticket_id ON ticket_comments(ticket_id);
CREATE INDEX idx_audit_history_table_record ON audit_history(table_name, record_id);
CREATE INDEX idx_audit_history_created_at ON audit_history(created_at);