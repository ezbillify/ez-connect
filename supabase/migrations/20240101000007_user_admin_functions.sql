-- User management admin functions and audit view
-- This migration adds SQL helper functions for admin user management operations
-- All functions write to audit_history and respect RLS policies

-- ===========================================
-- 1. Helper function to check if caller is admin
-- ===========================================

CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (
        auth.jwt() ->> 'role' = 'admin' OR
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- 2. Create user invitation
-- ===========================================

CREATE OR REPLACE FUNCTION create_user_invitation(
    p_email TEXT,
    p_role user_role DEFAULT 'agent',
    p_invited_by UUID DEFAULT auth.uid()
)
RETURNS JSON AS $$
DECLARE
    v_invitation_id UUID;
    v_invitation_code TEXT;
    v_result JSON;
BEGIN
    -- Check if caller is admin
    IF NOT is_admin() THEN
        RAISE EXCEPTION 'Only admins can create user invitations';
    END IF;

    -- Validate email
    IF p_email IS NULL OR p_email = '' THEN
        RAISE EXCEPTION 'Email is required';
    END IF;

    -- Check if user already exists
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) THEN
        RAISE EXCEPTION 'User with this email already exists';
    END IF;

    -- Check if there's an active invitation for this email
    IF EXISTS (
        SELECT 1 FROM auth.users 
        WHERE email = p_email 
        AND confirmation_token IS NOT NULL
        AND confirmation_sent_at > NOW() - INTERVAL '24 hours'
    ) THEN
        RAISE EXCEPTION 'An active invitation already exists for this email';
    END IF;

    -- Generate invitation code
    v_invitation_code := encode(gen_random_bytes(16), 'hex');
    
    -- Create invitation record (using auth.users table with unconfirmed status)
    -- The invitation will be stored as an unconfirmed user
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        raw_user_meta_data,
        is_super_admin,
        created_at,
        updated_at,
        confirmation_token,
        confirmation_sent_at
    )
    VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        p_email,
        jsonb_build_object(
            'invited_by', p_invited_by,
            'invited_role', p_role::text,
            'invitation_code', v_invitation_code
        ),
        false,
        NOW(),
        NOW(),
        v_invitation_code,
        NOW()
    )
    RETURNING id INTO v_invitation_id;

    -- Create profile with pending status
    INSERT INTO profiles (id, email, role, full_name, created_at, updated_at)
    VALUES (
        v_invitation_id,
        p_email,
        p_role,
        p_email,
        NOW(),
        NOW()
    );

    -- Write to audit history
    INSERT INTO audit_history (
        table_name,
        record_id,
        action,
        new_values,
        changed_by,
        created_at
    ) VALUES (
        'user_invitations',
        v_invitation_id,
        'CREATE_INVITATION',
        jsonb_build_object(
            'email', p_email,
            'role', p_role::text,
            'invited_by', p_invited_by,
            'invitation_code', v_invitation_code
        ),
        p_invited_by,
        NOW()
    );

    v_result := json_build_object(
        'invitation_id', v_invitation_id,
        'email', p_email,
        'role', p_role,
        'invitation_code', v_invitation_code,
        'created_at', NOW()
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- 3. Resend user invitation
-- ===========================================

CREATE OR REPLACE FUNCTION resend_user_invitation(
    p_invitation_id UUID,
    p_resent_by UUID DEFAULT auth.uid()
)
RETURNS JSON AS $$
DECLARE
    v_email TEXT;
    v_role TEXT;
    v_new_code TEXT;
    v_result JSON;
BEGIN
    -- Check if caller is admin
    IF NOT is_admin() THEN
        RAISE EXCEPTION 'Only admins can resend invitations';
    END IF;

    -- Get invitation details
    SELECT email, raw_user_meta_data->>'invited_role'
    INTO v_email, v_role
    FROM auth.users
    WHERE id = p_invitation_id
    AND email_confirmed_at IS NULL;

    IF v_email IS NULL THEN
        RAISE EXCEPTION 'Invitation not found or already accepted';
    END IF;

    -- Generate new invitation code
    v_new_code := encode(gen_random_bytes(16), 'hex');

    -- Update invitation with new code and timestamp
    UPDATE auth.users
    SET 
        confirmation_token = v_new_code,
        confirmation_sent_at = NOW(),
        updated_at = NOW(),
        raw_user_meta_data = raw_user_meta_data || jsonb_build_object('invitation_code', v_new_code)
    WHERE id = p_invitation_id;

    -- Write to audit history
    INSERT INTO audit_history (
        table_name,
        record_id,
        action,
        new_values,
        changed_by,
        created_at
    ) VALUES (
        'user_invitations',
        p_invitation_id,
        'RESEND_INVITATION',
        jsonb_build_object(
            'email', v_email,
            'role', v_role,
            'resent_by', p_resent_by,
            'new_invitation_code', v_new_code
        ),
        p_resent_by,
        NOW()
    );

    v_result := json_build_object(
        'invitation_id', p_invitation_id,
        'email', v_email,
        'invitation_code', v_new_code,
        'resent_at', NOW()
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- 4. Bulk update user roles
-- ===========================================

CREATE OR REPLACE FUNCTION bulk_update_user_roles(
    p_user_ids UUID[],
    p_new_role user_role,
    p_updated_by UUID DEFAULT auth.uid()
)
RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_old_role user_role;
    v_updated_count INTEGER := 0;
    v_results JSON[];
BEGIN
    -- Check if caller is admin
    IF NOT is_admin() THEN
        RAISE EXCEPTION 'Only admins can update user roles';
    END IF;

    -- Validate input
    IF p_user_ids IS NULL OR array_length(p_user_ids, 1) = 0 THEN
        RAISE EXCEPTION 'User IDs array cannot be empty';
    END IF;

    -- Process each user
    FOREACH v_user_id IN ARRAY p_user_ids
    LOOP
        -- Get current role
        SELECT role INTO v_old_role
        FROM profiles
        WHERE id = v_user_id;

        IF v_old_role IS NULL THEN
            CONTINUE; -- Skip if user not found
        END IF;

        -- Prevent updating own role
        IF v_user_id = p_updated_by THEN
            CONTINUE; -- Skip self
        END IF;

        -- Update role
        UPDATE profiles
        SET role = p_new_role, updated_at = NOW()
        WHERE id = v_user_id;

        -- Write to audit history
        INSERT INTO audit_history (
            table_name,
            record_id,
            action,
            old_values,
            new_values,
            changed_by,
            created_at
        ) VALUES (
            'profiles',
            v_user_id,
            'BULK_UPDATE_ROLE',
            jsonb_build_object('role', v_old_role::text),
            jsonb_build_object('role', p_new_role::text),
            p_updated_by,
            NOW()
        );

        v_updated_count := v_updated_count + 1;
        v_results := array_append(
            v_results,
            json_build_object(
                'user_id', v_user_id,
                'old_role', v_old_role,
                'new_role', p_new_role
            )
        );
    END LOOP;

    RETURN json_build_object(
        'updated_count', v_updated_count,
        'updates', array_to_json(v_results)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- 5. Toggle user status
-- ===========================================

CREATE OR REPLACE FUNCTION toggle_user_status(
    p_user_id UUID,
    p_is_active BOOLEAN,
    p_toggled_by UUID DEFAULT auth.uid()
)
RETURNS JSON AS $$
DECLARE
    v_email TEXT;
    v_old_status TEXT;
    v_new_status TEXT;
    v_result JSON;
BEGIN
    -- Check if caller is admin
    IF NOT is_admin() THEN
        RAISE EXCEPTION 'Only admins can toggle user status';
    END IF;

    -- Prevent toggling own status
    IF p_user_id = p_toggled_by THEN
        RAISE EXCEPTION 'Cannot toggle your own status';
    END IF;

    -- Get user email and current status
    SELECT email INTO v_email
    FROM profiles
    WHERE id = p_user_id;

    IF v_email IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    -- Determine current and new status
    SELECT 
        CASE 
            WHEN banned_until IS NOT NULL AND banned_until > NOW() THEN 'banned'
            WHEN email_confirmed_at IS NULL THEN 'unconfirmed'
            ELSE 'active'
        END
    INTO v_old_status
    FROM auth.users
    WHERE id = p_user_id;

    v_new_status := CASE WHEN p_is_active THEN 'active' ELSE 'banned' END;

    -- Update user status in auth.users
    IF p_is_active THEN
        -- Activate user (remove ban)
        UPDATE auth.users
        SET 
            banned_until = NULL,
            updated_at = NOW()
        WHERE id = p_user_id;
    ELSE
        -- Deactivate user (ban indefinitely)
        UPDATE auth.users
        SET 
            banned_until = '2099-12-31'::timestamp,
            updated_at = NOW()
        WHERE id = p_user_id;
    END IF;

    -- Write to audit history
    INSERT INTO audit_history (
        table_name,
        record_id,
        action,
        old_values,
        new_values,
        changed_by,
        created_at
    ) VALUES (
        'profiles',
        p_user_id,
        'TOGGLE_STATUS',
        jsonb_build_object('status', v_old_status),
        jsonb_build_object('status', v_new_status),
        p_toggled_by,
        NOW()
    );

    v_result := json_build_object(
        'user_id', p_user_id,
        'email', v_email,
        'old_status', v_old_status,
        'new_status', v_new_status,
        'toggled_at', NOW()
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- 6. Reset user password
-- ===========================================

CREATE OR REPLACE FUNCTION reset_user_password(
    p_user_id UUID,
    p_new_password TEXT,
    p_reset_by UUID DEFAULT auth.uid()
)
RETURNS JSON AS $$
DECLARE
    v_email TEXT;
    v_result JSON;
BEGIN
    -- Check if caller is admin
    IF NOT is_admin() THEN
        RAISE EXCEPTION 'Only admins can reset user passwords';
    END IF;

    -- Get user email
    SELECT email INTO v_email
    FROM profiles
    WHERE id = p_user_id;

    IF v_email IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    -- Validate password
    IF p_new_password IS NULL OR length(p_new_password) < 6 THEN
        RAISE EXCEPTION 'Password must be at least 6 characters long';
    END IF;

    -- Update password in auth.users
    -- Note: In production, this would use Supabase Auth API
    -- For local development, we update the encrypted password directly
    UPDATE auth.users
    SET 
        encrypted_password = crypt(p_new_password, gen_salt('bf')),
        updated_at = NOW()
    WHERE id = p_user_id;

    -- Write to audit history (don't store the actual password)
    INSERT INTO audit_history (
        table_name,
        record_id,
        action,
        new_values,
        changed_by,
        created_at
    ) VALUES (
        'profiles',
        p_user_id,
        'RESET_PASSWORD',
        jsonb_build_object(
            'email', v_email,
            'reset_by', p_reset_by
        ),
        p_reset_by,
        NOW()
    );

    v_result := json_build_object(
        'user_id', p_user_id,
        'email', v_email,
        'reset_at', NOW()
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- 7. User activity log view
-- ===========================================

CREATE OR REPLACE VIEW user_activity_log AS
SELECT 
    ah.id,
    ah.table_name AS entity_type,
    ah.action,
    ah.record_id AS entity_id,
    ah.created_at,
    -- Actor information
    ah.changed_by AS actor_id,
    p.email AS actor_email,
    p.full_name AS actor_name,
    p.role AS actor_role,
    -- Change details
    CASE 
        WHEN ah.action IN ('CREATE_INVITATION', 'RESEND_INVITATION') THEN
            ah.new_values->>'email'
        WHEN ah.action IN ('BULK_UPDATE_ROLE', 'TOGGLE_STATUS', 'RESET_PASSWORD') THEN
            (SELECT email FROM profiles WHERE id = ah.record_id)
        ELSE
            NULL
    END AS target_email,
    -- Specific action details
    CASE 
        WHEN ah.action = 'CREATE_INVITATION' THEN
            json_build_object(
                'email', ah.new_values->>'email',
                'role', ah.new_values->>'role',
                'invitation_code', ah.new_values->>'invitation_code'
            )
        WHEN ah.action = 'RESEND_INVITATION' THEN
            json_build_object(
                'email', ah.new_values->>'email',
                'role', ah.new_values->>'role'
            )
        WHEN ah.action = 'BULK_UPDATE_ROLE' THEN
            json_build_object(
                'old_role', ah.old_values->>'role',
                'new_role', ah.new_values->>'role'
            )
        WHEN ah.action = 'TOGGLE_STATUS' THEN
            json_build_object(
                'old_status', ah.old_values->>'status',
                'new_status', ah.new_values->>'status'
            )
        WHEN ah.action = 'RESET_PASSWORD' THEN
            json_build_object(
                'email', ah.new_values->>'email'
            )
        ELSE
            json_build_object(
                'old_values', ah.old_values,
                'new_values', ah.new_values
            )
    END AS details
FROM audit_history ah
LEFT JOIN profiles p ON p.id = ah.changed_by
WHERE ah.table_name IN ('user_invitations', 'profiles')
   OR ah.action IN ('CREATE_INVITATION', 'RESEND_INVITATION', 'BULK_UPDATE_ROLE', 'TOGGLE_STATUS', 'RESET_PASSWORD')
ORDER BY ah.created_at DESC;

-- Grant access to user_activity_log view (admins only)
-- RLS will be enforced through policies
ALTER VIEW user_activity_log OWNER TO postgres;

-- Create RLS policy for user_activity_log
-- Note: Views don't directly support RLS, but we can control access through functions

-- ===========================================
-- 8. Helper function to get user activity log (with RLS)
-- ===========================================

CREATE OR REPLACE FUNCTION get_user_activity_log(
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    entity_type TEXT,
    action TEXT,
    entity_id UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    actor_id UUID,
    actor_email TEXT,
    actor_name TEXT,
    actor_role user_role,
    target_email TEXT,
    details JSON
) AS $$
BEGIN
    -- Check if caller is admin
    IF NOT is_admin() THEN
        RAISE EXCEPTION 'Only admins can view user activity log';
    END IF;

    RETURN QUERY
    SELECT 
        ual.id,
        ual.entity_type,
        ual.action,
        ual.entity_id,
        ual.created_at,
        ual.actor_id,
        ual.actor_email,
        ual.actor_name,
        ual.actor_role,
        ual.target_email,
        ual.details
    FROM user_activity_log ual
    ORDER BY ual.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- 9. Create indexes for better performance
-- ===========================================

CREATE INDEX IF NOT EXISTS idx_audit_history_action ON audit_history(action);
CREATE INDEX IF NOT EXISTS idx_audit_history_changed_by ON audit_history(changed_by);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- ===========================================
-- Comments
-- ===========================================

COMMENT ON FUNCTION create_user_invitation IS 'Creates a user invitation and logs to audit_history. Admin only.';
COMMENT ON FUNCTION resend_user_invitation IS 'Resends a user invitation with new code and logs to audit_history. Admin only.';
COMMENT ON FUNCTION bulk_update_user_roles IS 'Updates roles for multiple users atomically and logs to audit_history. Admin only.';
COMMENT ON FUNCTION toggle_user_status IS 'Activates or deactivates a user and logs to audit_history. Admin only.';
COMMENT ON FUNCTION reset_user_password IS 'Resets a user password and logs to audit_history. Admin only.';
COMMENT ON FUNCTION get_user_activity_log IS 'Returns user activity log with admin-only access control.';
COMMENT ON VIEW user_activity_log IS 'Flattened view of user-related audit_history entries. Access via get_user_activity_log function.';
