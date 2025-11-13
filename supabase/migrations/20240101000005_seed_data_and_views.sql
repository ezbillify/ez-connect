-- Seed data for the CRM application

-- Insert default acquisition stages
INSERT INTO acquisition_stages (id, name, order_index) VALUES
('lead', 'Lead', 1),
('qualified', 'Qualified', 2),
('proposal', 'Proposal', 3),
('negotiation', 'Negotiation', 4),
('closed_won', 'Closed Won', 5),
('closed_lost', 'Closed Lost', 6)
ON CONFLICT (id) DO NOTHING;

-- Insert sample products (up to 3 active)
INSERT INTO products (id, name, description, is_active) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'CRM Pro', 'Professional CRM solution for small to medium businesses', true),
('550e8400-e29b-41d4-a716-446655440002', 'CRM Enterprise', 'Advanced CRM with custom workflows and integrations', true),
('550e8400-e29b-41d4-a716-446655440003', 'CRM Starter', 'Basic CRM for startups and freelancers', true),
('550e8400-e29b-41d4-a716-446655440004', 'CRM Analytics', 'Add-on for advanced reporting and analytics', false)
ON CONFLICT (id) DO NOTHING;

-- Create a function to reset seed data (useful for testing)
CREATE OR REPLACE FUNCTION reset_seed_data()
RETURNS VOID AS $$
BEGIN
    -- Clear existing seed data
    DELETE FROM acquisition_stages;
    DELETE FROM products WHERE id LIKE '550e8400-e29b-41d4-a716-44665544%';
    
    -- Re-insert acquisition stages
    INSERT INTO acquisition_stages (id, name, order_index) VALUES
    ('lead', 'Lead', 1),
    ('qualified', 'Qualified', 2),
    ('proposal', 'Proposal', 3),
    ('negotiation', 'Negotiation', 4),
    ('closed_won', 'Closed Won', 5),
    ('closed_lost', 'Closed Lost', 6);
    
    -- Re-insert sample products
    INSERT INTO products (id, name, description, is_active) VALUES
    ('550e8400-e29b-41d4-a716-446655440001', 'CRM Pro', 'Professional CRM solution for small to medium businesses', true),
    ('550e8400-e29b-41d4-a716-446655440002', 'CRM Enterprise', 'Advanced CRM with custom workflows and integrations', true),
    ('550e8400-e29b-41d4-a716-446655440003', 'CRM Starter', 'Basic CRM for startups and freelancers', true),
    ('550e8400-e29b-41d4-a716-446655440004', 'CRM Analytics', 'Add-on for advanced reporting and analytics', false);
    
    RAISE NOTICE 'Seed data has been reset';
END;
$$ language 'plpgsql';

-- Create views for common queries
CREATE VIEW customer_summary AS
SELECT 
    c.id,
    c.name,
    c.email,
    c.phone,
    c.status,
    c.acquisition_source,
    c.is_archived,
    c.created_at,
    c.updated_at,
    p.name as product_name,
    u.full_name as owner_name,
    u.email as owner_email,
    -- Count interactions
    (SELECT COUNT(*) FROM customer_interactions ci WHERE ci.customer_id = c.id) as interaction_count,
    -- Last interaction date
    (SELECT MAX(ci.created_at) FROM customer_interactions ci WHERE ci.customer_id = c.id) as last_interaction_date,
    -- Count tickets
    (SELECT COUNT(*) FROM tickets t WHERE t.customer_id = c.id) as ticket_count
FROM customers c
LEFT JOIN products p ON c.product_id = p.id
LEFT JOIN profiles u ON c.owner = u.id;

CREATE VIEW ticket_summary AS
SELECT 
    t.id,
    t.title,
    t.priority,
    t.status,
    t.created_at,
    t.updated_at,
    t.resolved_at,
    t.closed_at,
    c.name as customer_name,
    owner.full_name as created_by_name,
    assigned.full_name as assigned_to_name,
    -- Count comments
    (SELECT COUNT(*) FROM ticket_comments tc WHERE tc.ticket_id = t.id) as comment_count,
    -- Count attachments
    (SELECT COUNT(*) FROM ticket_attachments ta WHERE ta.ticket_id = t.id) as attachment_count,
    -- Last activity
    GREATEST(
        t.updated_at,
        (SELECT MAX(created_at) FROM ticket_comments tc WHERE tc.ticket_id = t.id),
        (SELECT MAX(uploaded_at) FROM ticket_attachments ta WHERE ta.ticket_id = t.id)
    ) as last_activity_date
FROM tickets t
LEFT JOIN customers c ON t.customer_id = c.id
LEFT JOIN profiles owner ON t.created_by = owner.id
LEFT JOIN profiles assigned ON t.assigned_to = assigned.id;

CREATE VIEW user_workload AS
SELECT 
    p.id as user_id,
    p.full_name,
    p.email,
    p.role,
    -- Ticket counts by status
    (SELECT COUNT(*) FROM tickets t WHERE t.assigned_to = p.id AND t.status = 'open') as open_tickets,
    (SELECT COUNT(*) FROM tickets t WHERE t.assigned_to = p.id AND t.status = 'in_progress') as in_progress_tickets,
    (SELECT COUNT(*) FROM tickets t WHERE t.assigned_to = p.id AND t.status = 'resolved') as resolved_tickets,
    (SELECT COUNT(*) FROM tickets t WHERE t.assigned_to = p.id AND t.status = 'closed') as closed_tickets,
    -- Customer counts
    (SELECT COUNT(*) FROM customers c WHERE c.owner = p.id AND c.is_archived = false) as active_customers,
    (SELECT COUNT(*) FROM customers c WHERE c.owner = p.id AND c.is_archived = true) as archived_customers,
    -- Recent activity
    (SELECT COUNT(*) FROM tickets t WHERE t.assigned_to = p.id AND t.updated_at >= NOW() - INTERVAL '7 days') as recent_ticket_activity,
    (SELECT COUNT(*) FROM customer_interactions ci 
     JOIN customers c ON ci.customer_id = c.id 
     WHERE c.owner = p.id AND ci.created_at >= NOW() - INTERVAL '7 days') as recent_interaction_activity
FROM profiles p
WHERE p.role IN ('agent', 'admin');

-- Grant usage of views to authenticated users
GRANT SELECT ON customer_summary TO authenticated;
GRANT SELECT ON ticket_summary TO authenticated;
GRANT SELECT ON user_workload TO authenticated;

-- Note: Views inherit RLS policies from their underlying tables automatically
-- No need to create explicit RLS policies on views

-- Create a function to get dashboard data
CREATE OR REPLACE FUNCTION get_dashboard_data(p_user_id UUID DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'customer_stats', get_customer_stats(p_user_id),
        'ticket_stats', get_ticket_stats(p_user_id),
        'recent_activities', (
            SELECT json_agg(
                json_build_object(
                    'type', 'ticket',
                    'id', t.id,
                    'title', t.title,
                    'status', t.status,
                    'priority', t.priority,
                    'updated_at', t.updated_at,
                    'customer_name', c.name
                )
            )
            FROM tickets t
            LEFT JOIN customers c ON t.customer_id = c.id
            WHERE (p_user_id IS NULL OR t.assigned_to = p_user_id OR t.created_by = p_user_id)
            AND t.status NOT IN ('resolved', 'closed')
            ORDER BY t.updated_at DESC
            LIMIT 5
        ),
        'upcoming_followups', (
            SELECT json_agg(
                json_build_object(
                    'type', 'interaction',
                    'id', ci.id,
                    'customer_name', c.name,
                    'note', ci.note,
                    'follow_up_date', ci.follow_up_date,
                    'channel', ci.channel
                )
            )
            FROM customer_interactions ci
            JOIN customers c ON ci.customer_id = c.id
            WHERE ci.follow_up_date IS NOT NULL
            AND ci.follow_up_date <= NOW() + INTERVAL '7 days'
            AND (p_user_id IS NULL OR c.owner = p_user_id)
            ORDER BY ci.follow_up_date ASC
            LIMIT 5
        )
    ) INTO result;
    
    RETURN result;
END;
$$ language 'plpgsql';

-- Create a function to validate product constraint before insertion
CREATE OR REPLACE FUNCTION validate_product_active_count()
RETURNS TRIGGER AS $
DECLARE
    active_count INTEGER;
BEGIN
    IF NEW.is_active = true THEN
        -- Count active products excluding the current one being updated
        SELECT COUNT(*) INTO active_count 
        FROM products 
        WHERE is_active = true 
        AND id != NEW.id;
        
        IF active_count >= 3 THEN
            RAISE EXCEPTION 'Maximum of 3 active products allowed. Currently have % active products.', active_count;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply the product constraint trigger
CREATE TRIGGER validate_product_active_count_trigger
    BEFORE INSERT OR UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION validate_product_active_count();