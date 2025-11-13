-- RBAC Extensions: Enhanced roles, user status, and invitations
-- This migration extends the existing RBAC schema to support:
-- - Extended user roles (admin, agent, customer, guest)
-- - User status tracking (active, disabled, invited, pending)
-- - User invitations system

-- ============================================
-- 1. Extend user_role enum
-- ============================================

-- Add new roles to the existing user_role enum
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'customer';
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'guest';

-- ============================================
-- 2. Create user_status enum
-- ============================================

CREATE TYPE user_status AS ENUM (
    'active',
    'disabled', 
    'invited',
    'pending'
);

-- ============================================
-- 3. Extend profiles table
-- ============================================

-- Add status tracking columns
ALTER TABLE profiles 
    ADD COLUMN IF NOT EXISTS status user_status DEFAULT 'active' NOT NULL,
    ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS disabled_at TIMESTAMP WITH TIME ZONE;

-- Create index for status queries
CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles(status);
CREATE INDEX IF NOT EXISTS idx_profiles_role_status ON profiles(role, status);

-- ============================================
-- 4. Create user_invitations table
-- ============================================

CREATE TABLE IF NOT EXISTS user_invitations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    role user_role DEFAULT 'agent' NOT NULL,
    invited_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'accepted', 'expired', 'cancelled')),
    used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Enable RLS on user_invitations
ALTER TABLE user_invitations ENABLE ROW LEVEL SECURITY;

-- Create indexes for user_invitations
CREATE INDEX IF NOT EXISTS idx_user_invitations_code ON user_invitations(code);
CREATE INDEX IF NOT EXISTS idx_user_invitations_email ON user_invitations(email);
CREATE INDEX IF NOT EXISTS idx_user_invitations_status ON user_invitations(status);
CREATE INDEX IF NOT EXISTS idx_user_invitations_expires_at ON user_invitations(expires_at);
CREATE INDEX IF NOT EXISTS idx_user_invitations_invited_by ON user_invitations(invited_by);

-- ============================================
-- 5. RLS Policies for user_invitations
-- ============================================

-- Admins can view all invitations
CREATE POLICY "Admins can view all invitations" ON user_invitations
    FOR SELECT USING (
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

-- Users can view invitations they created
CREATE POLICY "Users can view own invitations" ON user_invitations
    FOR SELECT USING (
        invited_by = auth.uid()
    );

-- Anyone can validate invitation codes (for sign-up flow)
CREATE POLICY "Anyone can validate invitation codes" ON user_invitations
    FOR SELECT USING (
        status = 'pending' AND
        expires_at > NOW()
    );

-- Admins can create invitations
CREATE POLICY "Admins can create invitations" ON user_invitations
    FOR INSERT WITH CHECK (
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

-- Admins can update invitations
CREATE POLICY "Admins can update invitations" ON user_invitations
    FOR UPDATE USING (
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

-- System can update invitations (for auto-expiry and acceptance)
CREATE POLICY "System can update invitations" ON user_invitations
    FOR UPDATE USING (true);

-- ============================================
-- 6. Functions for invitation management
-- ============================================

-- Function to generate invitation code
CREATE OR REPLACE FUNCTION generate_invitation_code()
RETURNS TEXT AS $$
BEGIN
    RETURN upper(substr(md5(random()::text || clock_timestamp()::text), 1, 12));
END;
$$ language 'plpgsql';

-- Function to create invitation
CREATE OR REPLACE FUNCTION create_invitation(
    p_email TEXT,
    p_role user_role DEFAULT 'agent',
    p_expires_in_days INTEGER DEFAULT 7
) RETURNS UUID AS $$
DECLARE
    invitation_id UUID;
    invitation_code TEXT;
BEGIN
    -- Generate unique code
    invitation_code := generate_invitation_code();
    
    -- Create invitation
    INSERT INTO user_invitations (
        code,
        email,
        role,
        invited_by,
        expires_at,
        status
    ) VALUES (
        invitation_code,
        p_email,
        p_role,
        auth.uid(),
        NOW() + (p_expires_in_days || ' days')::INTERVAL,
        'pending'
    ) RETURNING id INTO invitation_id;
    
    RETURN invitation_id;
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- Function to validate and accept invitation
CREATE OR REPLACE FUNCTION accept_invitation(
    p_code TEXT
) RETURNS JSONB AS $$
DECLARE
    invitation_record RECORD;
BEGIN
    -- Get invitation
    SELECT * INTO invitation_record
    FROM user_invitations
    WHERE code = p_code
    AND status = 'pending'
    AND expires_at > NOW();
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'valid', false,
            'error', 'Invalid or expired invitation code'
        );
    END IF;
    
    -- Mark as accepted
    UPDATE user_invitations
    SET status = 'accepted',
        used_at = NOW()
    WHERE id = invitation_record.id;
    
    RETURN jsonb_build_object(
        'valid', true,
        'email', invitation_record.email,
        'role', invitation_record.role
    );
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- Function to expire old invitations
CREATE OR REPLACE FUNCTION expire_old_invitations()
RETURNS INTEGER AS $$
DECLARE
    expired_count INTEGER;
BEGIN
    UPDATE user_invitations
    SET status = 'expired'
    WHERE status = 'pending'
    AND expires_at <= NOW();
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    
    RETURN expired_count;
END;
$$ language 'plpgsql';

-- ============================================
-- 7. Triggers for user_invitations
-- ============================================

-- Trigger to update updated_at
CREATE TRIGGER update_user_invitations_updated_at 
    BEFORE UPDATE ON user_invitations
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for audit trail
CREATE TRIGGER audit_user_invitations_trigger
    AFTER INSERT OR UPDATE OR DELETE ON user_invitations
    FOR EACH ROW 
    EXECUTE FUNCTION create_audit_history();

-- ============================================
-- 8. Update handle_new_user function to support invitations
-- ============================================

-- Drop and recreate the handle_new_user function with invitation support
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    user_role_val user_role := 'agent';
    user_status_val user_status := 'active';
    invitation_record RECORD;
BEGIN
    -- Check if there's a pending invitation for this email
    SELECT * INTO invitation_record
    FROM user_invitations
    WHERE email = NEW.email
    AND status = 'pending'
    AND expires_at > NOW()
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- If invitation exists, use its role and mark as accepted
    IF FOUND THEN
        user_role_val := invitation_record.role;
        user_status_val := 'active';
        
        UPDATE user_invitations
        SET status = 'accepted',
            used_at = NOW()
        WHERE id = invitation_record.id;
    END IF;
    
    -- Insert into profiles
    INSERT INTO public.profiles (id, email, full_name, avatar_url, role, status)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'avatar_url',
        user_role_val,
        user_status_val
    )
    ON CONFLICT (id) DO UPDATE 
    SET role = EXCLUDED.role,
        status = EXCLUDED.status;
    
    RETURN NEW;
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- Recreate trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW 
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- 9. Function to update last_active_at
-- ============================================

CREATE OR REPLACE FUNCTION update_last_active()
RETURNS void AS $$
BEGIN
    UPDATE profiles
    SET last_active_at = NOW()
    WHERE id = auth.uid()
    AND status = 'active';
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- ============================================
-- 10. Seed sample invitations
-- ============================================

-- Insert sample invitations for testing
INSERT INTO user_invitations (code, email, role, invited_by, expires_at, status) 
VALUES
    ('AGENT001TEST', 'agent1@test.com', 'agent', (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1), NOW() + INTERVAL '30 days', 'pending'),
    ('AGENT002TEST', 'agent2@test.com', 'agent', (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1), NOW() + INTERVAL '30 days', 'pending'),
    ('CUST001TEST', 'customer1@test.com', 'customer', (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1), NOW() + INTERVAL '30 days', 'pending'),
    ('CUST002TEST', 'customer2@test.com', 'customer', (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1), NOW() + INTERVAL '30 days', 'pending')
ON CONFLICT (code) DO NOTHING;

-- ============================================
-- 11. Update existing profiles with active status
-- ============================================

-- Set all existing profiles to active if status is not set
UPDATE profiles 
SET status = 'active'
WHERE status IS NULL;

RAISE NOTICE 'RBAC extensions applied successfully';
RAISE NOTICE '- Extended user_role enum with customer and guest';
RAISE NOTICE '- Created user_status enum';
RAISE NOTICE '- Added status tracking to profiles';
RAISE NOTICE '- Created user_invitations table';
RAISE NOTICE '- Added sample test invitations';
