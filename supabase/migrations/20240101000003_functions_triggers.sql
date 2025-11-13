-- Database functions and triggers

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers to relevant tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tickets_updated_at BEFORE UPDATE ON tickets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ticket_comments_updated_at BEFORE UPDATE ON ticket_comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to log ticket status changes
CREATE OR REPLACE FUNCTION log_ticket_status_change()
RETURNS TRIGGER AS $$
DECLARE
    changed_by_user UUID;
BEGIN
    -- Get current user from auth context
    changed_by_user = auth.uid();
    
    -- Only log if status actually changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO ticket_workflow_history (
            ticket_id,
            from_status,
            to_status,
            changed_by,
            note
        ) VALUES (
            NEW.id,
            OLD.status,
            NEW.status,
            changed_by_user,
            'Status changed from ' || COALESCE(OLD.status::text, 'NULL') || ' to ' || NEW.status::text
        );
    END IF;
    
    -- Update resolved_at and closed_at timestamps
    IF NEW.status = 'resolved' AND (OLD.status IS NULL OR OLD.status != 'resolved') THEN
        NEW.resolved_at = NOW();
    ELSIF NEW.status != 'resolved' AND OLD.status = 'resolved' THEN
        NEW.resolved_at = NULL;
    END IF;
    
    IF NEW.status = 'closed' AND (OLD.status IS NULL OR OLD.status != 'closed') THEN
        NEW.closed_at = NOW();
    ELSIF NEW.status != 'closed' AND OLD.status = 'closed' THEN
        NEW.closed_at = NULL;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER log_ticket_status_trigger BEFORE UPDATE ON tickets
    FOR EACH ROW EXECUTE FUNCTION log_ticket_status_change();

-- Function to create audit history entries
CREATE OR REPLACE FUNCTION create_audit_history()
RETURNS TRIGGER AS $$
DECLARE
    user_id UUID;
    integration_token UUID;
BEGIN
    -- Try to get user ID from auth context
    user_id = auth.uid();
    
    -- Try to get integration token from JWT
    BEGIN
        integration_token = (auth.jwt() ->> 'integration_token_id')::UUID;
    EXCEPTION WHEN OTHERS THEN
        integration_token = NULL;
    END;
    
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_history (
            table_name,
            record_id,
            action,
            new_values,
            changed_by,
            integration_token_id
        ) VALUES (
            TG_TABLE_NAME,
            NEW.id,
            TG_OP,
            row_to_json(NEW),
            user_id,
            integration_token
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_history (
            table_name,
            record_id,
            action,
            old_values,
            new_values,
            changed_by,
            integration_token_id
        ) VALUES (
            TG_TABLE_NAME,
            NEW.id,
            TG_OP,
            row_to_json(OLD),
            row_to_json(NEW),
            user_id,
            integration_token
        );
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_history (
            table_name,
            record_id,
            action,
            old_values,
            changed_by,
            integration_token_id
        ) VALUES (
            TG_TABLE_NAME,
            OLD.id,
            TG_OP,
            row_to_json(OLD),
            user_id,
            integration_token
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

-- Apply audit triggers to important tables
CREATE TRIGGER audit_profiles_trigger
    AFTER INSERT OR UPDATE OR DELETE ON profiles
    FOR EACH ROW EXECUTE FUNCTION create_audit_history();

CREATE TRIGGER audit_products_trigger
    AFTER INSERT OR UPDATE OR DELETE ON products
    FOR EACH ROW EXECUTE FUNCTION create_audit_history();

CREATE TRIGGER audit_customers_trigger
    AFTER INSERT OR UPDATE OR DELETE ON customers
    FOR EACH ROW EXECUTE FUNCTION create_audit_history();

CREATE TRIGGER audit_tickets_trigger
    AFTER INSERT OR UPDATE OR DELETE ON tickets
    FOR EACH ROW EXECUTE FUNCTION create_audit_history();

CREATE TRIGGER audit_ticket_comments_trigger
    AFTER INSERT OR UPDATE OR DELETE ON ticket_comments
    FOR EACH ROW EXECUTE FUNCTION create_audit_history();

-- Function to validate integration token permissions
CREATE OR REPLACE FUNCTION validate_integration_token_permissions(
    p_token_hash TEXT,
    p_required_permission TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    token_record RECORD;
BEGIN
    SELECT * INTO token_record 
    FROM integration_tokens 
    WHERE token_hash = p_token_hash 
    AND is_active = true 
    AND (expires_at IS NULL OR expires_at > NOW());
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Update last used timestamp
    UPDATE integration_tokens 
    SET last_used_at = NOW() 
    WHERE id = token_record.id;
    
    -- Check if token has the required permission
    IF p_required_permission = 'any' THEN
        RETURN TRUE;
    END IF;
    
    RETURN p_required_permission = ANY(token_record.permissions);
END;
$$ language 'plpgsql';

-- Function to get user profile from auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- Trigger to create profile on user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to get customer statistics
CREATE OR REPLACE FUNCTION get_customer_stats(
    p_user_id UUID DEFAULT NULL
) RETURNS JSON AS $
DECLARE
    result JSON;
    user_role_val user_role;
BEGIN
    -- Get user role if p_user_id is provided
    IF p_user_id IS NOT NULL THEN
        SELECT role INTO user_role_val FROM profiles WHERE id = p_user_id;
        
        -- Return empty dataset for guests
        IF user_role_val = 'guest' THEN
            RETURN json_build_object(
                'total_customers', 0,
                'by_status', '{}'::json,
                'by_product', '{}'::json,
                'recent_acquisitions', 0
            );
        END IF;
    END IF;
    
    SELECT json_build_object(
        'total_customers', COUNT(*),
        'by_status', (
            SELECT json_object_agg(status, count) 
            FROM (
                SELECT status, COUNT(*) as count 
                FROM customers 
                WHERE (p_user_id IS NULL OR 
                       (user_role_val = 'admin') OR
                       (user_role_val IN ('agent', 'admin') AND owner = p_user_id))
                AND is_archived = false
                GROUP BY status
            ) status_counts
        ),
        'by_product', (
            SELECT json_object_agg(
                COALESCE(products.name, 'No Product'), 
                count
            ) 
            FROM (
                SELECT 
                    COALESCE(p.name, 'No Product') as name,
                    COUNT(*) as count 
                FROM customers c
                LEFT JOIN products p ON c.product_id = p.id
                WHERE (p_user_id IS NULL OR 
                       (user_role_val = 'admin') OR
                       (user_role_val IN ('agent', 'admin') AND c.owner = p_user_id))
                AND c.is_archived = false
                GROUP BY p.name
            ) product_counts
        ),
        'recent_acquisitions', (
            SELECT COUNT(*) 
            FROM customers 
            WHERE (p_user_id IS NULL OR 
                   (user_role_val = 'admin') OR
                   (user_role_val IN ('agent', 'admin') AND owner = p_user_id))
            AND is_archived = false 
            AND created_at >= NOW() - INTERVAL '30 days'
        )
    ) INTO result
    FROM customers 
    WHERE (p_user_id IS NULL OR 
           (user_role_val = 'admin') OR
           (user_role_val IN ('agent', 'admin') AND owner = p_user_id))
    AND is_archived = false;
    
    RETURN result;
END;
$ language 'plpgsql';

-- Function to get ticket statistics
CREATE OR REPLACE FUNCTION get_ticket_stats(
    p_user_id UUID DEFAULT NULL
) RETURNS JSON AS $
DECLARE
    result JSON;
    user_role_val user_role;
    user_email_val TEXT;
BEGIN
    -- Get user role if p_user_id is provided
    IF p_user_id IS NOT NULL THEN
        SELECT role, email INTO user_role_val, user_email_val FROM profiles WHERE id = p_user_id;
        
        -- Return empty dataset for guests
        IF user_role_val = 'guest' THEN
            RETURN json_build_object(
                'total_tickets', 0,
                'by_status', '{}'::json,
                'by_priority', '{}'::json,
                'overdue_count', 0,
                'avg_resolution_time', 0
            );
        END IF;
    END IF;
    
    SELECT json_build_object(
        'total_tickets', COUNT(*),
        'by_status', (
            SELECT json_object_agg(status, count) 
            FROM (
                SELECT status, COUNT(*) as count 
                FROM tickets 
                WHERE (p_user_id IS NULL OR 
                       (user_role_val = 'admin') OR
                       (user_role_val IN ('agent', 'admin') AND (created_by = p_user_id OR assigned_to = p_user_id)) OR
                       (user_role_val = 'customer' AND EXISTS (
                           SELECT 1 FROM customers 
                           WHERE customers.id = tickets.customer_id 
                           AND customers.email = user_email_val
                       )))
                GROUP BY status
            ) status_counts
        ),
        'by_priority', (
            SELECT json_object_agg(priority, count) 
            FROM (
                SELECT priority, COUNT(*) as count 
                FROM tickets 
                WHERE (p_user_id IS NULL OR 
                       (user_role_val = 'admin') OR
                       (user_role_val IN ('agent', 'admin') AND (created_by = p_user_id OR assigned_to = p_user_id)) OR
                       (user_role_val = 'customer' AND EXISTS (
                           SELECT 1 FROM customers 
                           WHERE customers.id = tickets.customer_id 
                           AND customers.email = user_email_val
                       )))
                GROUP BY priority
            ) priority_counts
        ),
        'overdue_count', (
            SELECT COUNT(*) 
            FROM tickets 
            WHERE (p_user_id IS NULL OR 
                   (user_role_val = 'admin') OR
                   (user_role_val IN ('agent', 'admin') AND (created_by = p_user_id OR assigned_to = p_user_id)) OR
                   (user_role_val = 'customer' AND EXISTS (
                       SELECT 1 FROM customers 
                       WHERE customers.id = tickets.customer_id 
                       AND customers.email = user_email_val
                   )))
            AND status NOT IN ('resolved', 'closed')
            AND created_at < NOW() - INTERVAL '7 days'
        ),
        'avg_resolution_time', (
            SELECT EXTRACT(EPOCH FROM AVG(resolved_at - created_at))/3600 
            FROM tickets 
            WHERE (p_user_id IS NULL OR 
                   (user_role_val = 'admin') OR
                   (user_role_val IN ('agent', 'admin') AND (created_by = p_user_id OR assigned_to = p_user_id)) OR
                   (user_role_val = 'customer' AND EXISTS (
                       SELECT 1 FROM customers 
                       WHERE customers.id = tickets.customer_id 
                       AND customers.email = user_email_val
                   )))
            AND resolved_at IS NOT NULL
        )
    ) INTO result
    FROM tickets 
    WHERE (p_user_id IS NULL OR 
           (user_role_val = 'admin') OR
           (user_role_val IN ('agent', 'admin') AND (created_by = p_user_id OR assigned_to = p_user_id)) OR
           (user_role_val = 'customer' AND EXISTS (
               SELECT 1 FROM customers 
               WHERE customers.id = tickets.customer_id 
               AND customers.email = user_email_val
           )));
    
    RETURN result;
END;
$ language 'plpgsql';