-- Seed admin user for initial access
-- This migration creates an admin user with credentials:
-- Email: admin@ezbillify.com
-- Password: admin123

-- Ensure pgcrypto extension is enabled (required for password hashing)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create a function to seed the admin user
-- This uses the service role context to create a user in auth.users
CREATE OR REPLACE FUNCTION seed_admin_user()
RETURNS void AS $$
DECLARE
    admin_user_id UUID;
    admin_exists BOOLEAN;
BEGIN
    -- Check if admin user already exists
    SELECT EXISTS (
        SELECT 1 FROM auth.users WHERE email = 'admin@ezbillify.com'
    ) INTO admin_exists;
    
    IF admin_exists THEN
        RAISE NOTICE 'Admin user already exists, skipping creation';
        
        -- Make sure the profile exists with admin role
        INSERT INTO public.profiles (id, email, full_name, role, status, last_active_at)
        SELECT id, email, 'System Administrator', 'admin', 'active', NOW()
        FROM auth.users
        WHERE email = 'admin@ezbillify.com'
        ON CONFLICT (id) DO UPDATE SET 
            role = 'admin',
            status = 'active',
            last_active_at = NOW();
        
        RETURN;
    END IF;
    
    -- Generate a UUID for the admin user
    admin_user_id := gen_random_uuid();
    
    -- Insert into auth.users
    -- Note: In production, this should be done via Supabase API or CLI
    -- For development/testing, we insert directly
    INSERT INTO auth.users (
        id,
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,
        created_at,
        updated_at,
        raw_app_meta_data,
        raw_user_meta_data,
        is_super_admin,
        role,
        aud,
        confirmation_token,
        email_change_token_new,
        recovery_token
    ) VALUES (
        admin_user_id,
        '00000000-0000-0000-0000-000000000000',
        'admin@ezbillify.com',
        -- Password hash for 'admin123' using bcrypt
        -- This is generated with: SELECT crypt('admin123', gen_salt('bf'))
        crypt('admin123', gen_salt('bf')),
        NOW(),
        NOW(),
        NOW(),
        jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
        jsonb_build_object('full_name', 'System Administrator'),
        false,
        'authenticated',
        'authenticated',
        '',
        '',
        ''
    )
    ON CONFLICT (id) DO NOTHING;
    
    -- Create profile for admin user (this should be automatic via trigger, but we ensure it here)
    INSERT INTO public.profiles (id, email, full_name, role, status, last_active_at)
    VALUES (
        admin_user_id,
        'admin@ezbillify.com',
        'System Administrator',
        'admin',
        'active',
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET 
        role = 'admin',
        status = 'active',
        last_active_at = NOW();
    
    RAISE NOTICE 'Admin user created successfully: admin@ezbillify.com';
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- Execute the function to create the admin user
SELECT seed_admin_user();

-- Drop the function after use (optional, but keeps the schema clean)
DROP FUNCTION seed_admin_user();

-- Create a helper function to reset admin password (useful for development)
CREATE OR REPLACE FUNCTION reset_admin_password(new_password TEXT DEFAULT 'admin123')
RETURNS void AS $$
BEGIN
    UPDATE auth.users
    SET encrypted_password = crypt(new_password, gen_salt('bf')),
        updated_at = NOW()
    WHERE email = 'admin@ezbillify.com';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Admin user not found';
    END IF;
    
    RAISE NOTICE 'Admin password reset successfully';
END;
$$ language 'plpgsql' SECURITY DEFINER;
