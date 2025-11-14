-- Row Level Security policies for all tables

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE acquisition_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_workflow_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_assignees ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE integration_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_history ENABLE ROW LEVEL SECURITY;

-- Profiles policies
-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile (if not disabled)
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (
        auth.uid() = id AND
        (SELECT status FROM profiles WHERE id = auth.uid()) != 'disabled'
    );

-- Admins can view all profiles
CREATE POLICY "Admins can view all profiles" ON profiles
    FOR SELECT USING (
        auth.jwt() ->> 'role' = 'admin' OR
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

-- Admins can insert profiles
CREATE POLICY "Admins can insert profiles" ON profiles
    FOR INSERT WITH CHECK (
        auth.jwt() ->> 'role' = 'admin' OR
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

-- Admins can update all profiles (even if disabled)
CREATE POLICY "Admins can update all profiles" ON profiles
    FOR UPDATE USING (
        auth.jwt() ->> 'role' = 'admin' OR
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

-- Products policies
-- All authenticated users can view active products
CREATE POLICY "Authenticated users can view products" ON products
    FOR SELECT USING (auth.role() = 'authenticated');

-- Admins can manage products
CREATE POLICY "Admins can manage products" ON products
    FOR ALL USING (
        auth.jwt() ->> 'role' = 'admin' OR
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

-- Acquisition stages policies
-- All authenticated users can view acquisition stages
CREATE POLICY "Authenticated users can view acquisition stages" ON acquisition_stages
    FOR SELECT USING (auth.role() = 'authenticated');

-- Admins can manage acquisition stages
CREATE POLICY "Admins can manage acquisition stages" ON acquisition_stages
    FOR ALL USING (
        auth.jwt() ->> 'role' = 'admin' OR
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

-- Customers policies
-- Admins can view all customers
-- Agents can view customers they own
-- Customers can view their own customer record (if linked)
-- Guests have no access to customers
CREATE POLICY "Users can view assigned customers" ON customers
    FOR SELECT USING (
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin' OR
        (owner = auth.uid() AND (SELECT role FROM profiles WHERE id = auth.uid()) IN ('agent', 'admin')) OR
        ((SELECT role FROM profiles WHERE id = auth.uid()) = 'customer' AND 
         EXISTS (SELECT 1 FROM customers WHERE id = customers.id AND email = (SELECT email FROM profiles WHERE id = auth.uid())))
    );

-- Agents and admins can insert customers (if not disabled)
CREATE POLICY "Agents can insert customers" ON customers
    FOR INSERT WITH CHECK (
        (SELECT role FROM profiles WHERE id = auth.uid()) IN ('agent', 'admin') AND
        (SELECT status FROM profiles WHERE id = auth.uid()) != 'disabled'
    );

-- Agents can update customers they own, admins can update all (if not disabled)
CREATE POLICY "Users can update assigned customers" ON customers
    FOR UPDATE USING (
        ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin' OR
         (owner = auth.uid() AND (SELECT role FROM profiles WHERE id = auth.uid()) = 'agent')) AND
        (SELECT status FROM profiles WHERE id = auth.uid()) != 'disabled'
    );

-- Customer interactions policies
-- Admins can view all interactions, agents can view interactions for their customers
CREATE POLICY "Users can view customer interactions" ON customer_interactions
    FOR SELECT USING (
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin' OR
        EXISTS (
            SELECT 1 FROM customers 
            WHERE customers.id = customer_interactions.customer_id 
            AND customers.owner = auth.uid()
            AND (SELECT role FROM profiles WHERE id = auth.uid()) IN ('agent', 'admin')
        )
    );

-- Agents and admins can insert interactions (if not disabled)
CREATE POLICY "Agents can insert customer interactions" ON customer_interactions
    FOR INSERT WITH CHECK (
        (SELECT status FROM profiles WHERE id = auth.uid()) != 'disabled' AND
        ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin' OR
         (EXISTS (
            SELECT 1 FROM customers 
            WHERE customers.id = customer_interactions.customer_id 
            AND customers.owner = auth.uid()
            AND (SELECT role FROM profiles WHERE id = auth.uid()) = 'agent'
        )))
    );

-- Tickets policies
-- Admins can view all tickets
-- Agents can view tickets they created or are assigned to
-- Customers can view tickets linked to their customer record
CREATE POLICY "Users can view assigned tickets" ON tickets
    FOR SELECT USING (
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin' OR
        (created_by = auth.uid() AND (SELECT role FROM profiles WHERE id = auth.uid()) IN ('agent', 'admin')) OR
        (assigned_to = auth.uid() AND (SELECT role FROM profiles WHERE id = auth.uid()) IN ('agent', 'admin')) OR
        ((SELECT role FROM profiles WHERE id = auth.uid()) = 'customer' AND
         EXISTS (SELECT 1 FROM customers 
                 WHERE customers.id = tickets.customer_id 
                 AND customers.email = (SELECT email FROM profiles WHERE id = auth.uid())))
    );

-- Authenticated users can insert tickets (if not disabled)
CREATE POLICY "Users can insert tickets" ON tickets
    FOR INSERT WITH CHECK (
        auth.role() = 'authenticated' AND
        created_by = auth.uid() AND
        (SELECT status FROM profiles WHERE id = auth.uid()) != 'disabled'
    );

-- Users can update tickets they created or are assigned to (if not disabled)
CREATE POLICY "Users can update assigned tickets" ON tickets
    FOR UPDATE USING (
        (SELECT status FROM profiles WHERE id = auth.uid()) != 'disabled' AND
        ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin' OR
         created_by = auth.uid() OR
         assigned_to = auth.uid())
    );

-- Ticket workflow history policies
-- Users can view workflow history for tickets they can see
CREATE POLICY "Users can view ticket workflow history" ON ticket_workflow_history
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM tickets 
            WHERE tickets.id = ticket_workflow_history.ticket_id 
            AND (tickets.created_by = auth.uid() OR 
                 tickets.assigned_to = auth.uid() OR
                 (auth.jwt() ->> 'role' = 'admin') OR
                 (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin')
        )
    );

-- System policy for inserting workflow history (trigger-based)
CREATE POLICY "System can insert workflow history" ON ticket_workflow_history
    FOR INSERT WITH CHECK (true);

-- Ticket assignees policies
-- Users can view assignees for tickets they can see
CREATE POLICY "Users can view ticket assignees" ON ticket_assignees
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM tickets 
            WHERE tickets.id = ticket_assignees.ticket_id 
            AND (tickets.created_by = auth.uid() OR 
                 tickets.assigned_to = auth.uid() OR
                 ticket_assignees.user_id = auth.uid() OR
                 (auth.jwt() ->> 'role' = 'admin') OR
                 (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin')
        )
    );

-- Users can manage assignees for tickets they can manage
CREATE POLICY "Users can manage ticket assignees" ON ticket_assignees
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM tickets 
            WHERE tickets.id = ticket_assignees.ticket_id 
            AND (tickets.created_by = auth.uid() OR 
                 tickets.assigned_to = auth.uid() OR
                 (auth.jwt() ->> 'role' = 'admin') OR
                 (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin')
        )
    );

-- Ticket comments policies
-- Users can view comments for tickets they can see (respects ticket access rules)
CREATE POLICY "Users can view ticket comments" ON ticket_comments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM tickets 
            WHERE tickets.id = ticket_comments.ticket_id 
            AND ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin' OR
                 tickets.created_by = auth.uid() OR 
                 tickets.assigned_to = auth.uid() OR
                 ((SELECT role FROM profiles WHERE id = auth.uid()) = 'customer' AND
                  EXISTS (SELECT 1 FROM customers 
                          WHERE customers.id = tickets.customer_id 
                          AND customers.email = (SELECT email FROM profiles WHERE id = auth.uid()))))
        )
    );

-- Users can insert comments for tickets they can access (if not disabled)
CREATE POLICY "Users can insert ticket comments" ON ticket_comments
    FOR INSERT WITH CHECK (
        (SELECT status FROM profiles WHERE id = auth.uid()) != 'disabled' AND
        created_by = auth.uid() AND
        EXISTS (
            SELECT 1 FROM tickets 
            WHERE tickets.id = ticket_comments.ticket_id 
            AND ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin' OR
                 tickets.created_by = auth.uid() OR 
                 tickets.assigned_to = auth.uid() OR
                 ((SELECT role FROM profiles WHERE id = auth.uid()) = 'customer' AND
                  EXISTS (SELECT 1 FROM customers 
                          WHERE customers.id = tickets.customer_id 
                          AND customers.email = (SELECT email FROM profiles WHERE id = auth.uid()))))
        )
    );

-- Users can update their own comments (if not disabled)
CREATE POLICY "Users can update own comments" ON ticket_comments
    FOR UPDATE USING (
        created_by = auth.uid() AND
        (SELECT status FROM profiles WHERE id = auth.uid()) != 'disabled'
    );

-- Integration tokens policies
-- Users can view their own integration tokens
CREATE POLICY "Users can view own integration tokens" ON integration_tokens
    FOR SELECT USING (created_by = auth.uid());

-- Users can manage their own integration tokens (if not disabled)
CREATE POLICY "Users can manage own integration tokens" ON integration_tokens
    FOR ALL USING (
        created_by = auth.uid() AND
        (SELECT status FROM profiles WHERE id = auth.uid()) != 'disabled'
    );

-- Admins can view all integration tokens
CREATE POLICY "Admins can view all integration tokens" ON integration_tokens
    FOR SELECT USING (
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

-- Audit history policies
-- Admins can view all audit history
CREATE POLICY "Admins can view audit history" ON audit_history
    FOR SELECT USING (
        auth.jwt() ->> 'role' = 'admin' OR
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

-- Users can view audit history for records they own
CREATE POLICY "Users can view own audit history" ON audit_history
    FOR SELECT USING (
        changed_by = auth.uid() OR
        (table_name = 'customers' AND 
         EXISTS (SELECT 1 FROM customers WHERE customers.id = audit_history.record_id AND customers.owner = auth.uid())) OR
        (table_name = 'tickets' AND 
         EXISTS (SELECT 1 FROM tickets WHERE tickets.id = audit_history.record_id AND (tickets.created_by = auth.uid() OR tickets.assigned_to = auth.uid())))
    );

-- System policy for inserting audit history (trigger-based)
CREATE POLICY "System can insert audit history" ON audit_history
    FOR INSERT WITH CHECK (true);