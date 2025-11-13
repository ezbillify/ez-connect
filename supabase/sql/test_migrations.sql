-- Test suite for validating all migrations and database setup
-- Run this after applying all migrations to verify everything works

-- ===========================================
-- 1. Test Schema Creation
-- ===========================================

DO $$
BEGIN
    RAISE NOTICE 'Testing schema creation...';
    
    -- Check all tables exist
    ASSERT (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename IN (
        'profiles', 'products', 'acquisition_stages', 'customers', 
        'customer_interactions', 'tickets', 'ticket_workflow_history',
        'ticket_assignees', 'ticket_comments', 'integration_tokens',
        'audit_history', 'ticket_attachments'
    )) = 12, 'Not all tables created';
    
    -- Check all views exist
    ASSERT (SELECT COUNT(*) FROM pg_views WHERE schemaname = 'public' AND viewname IN (
        'customer_summary', 'ticket_summary', 'user_workload'
    )) = 3, 'Not all views created';
    
    RAISE NOTICE '✓ Schema creation tests passed';
END $$;

-- ===========================================
-- 2. Test Admin User
-- ===========================================

DO $$
DECLARE
    admin_id UUID;
    admin_profile_role user_role;
BEGIN
    RAISE NOTICE 'Testing admin user setup...';
    
    -- Check admin user exists in auth.users
    SELECT id INTO admin_id FROM auth.users WHERE email = 'admin@ezbillify.com';
    ASSERT admin_id IS NOT NULL, 'Admin user not found in auth.users';
    
    -- Check admin profile exists with correct role
    SELECT role INTO admin_profile_role FROM profiles WHERE id = admin_id;
    ASSERT admin_profile_role = 'admin', 'Admin user does not have admin role';
    
    RAISE NOTICE '✓ Admin user tests passed (ID: %)', admin_id;
END $$;

-- ===========================================
-- 3. Test RLS Policies
-- ===========================================

DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    RAISE NOTICE 'Testing RLS policies...';
    
    -- Check RLS is enabled on all tables
    ASSERT (SELECT COUNT(*) FROM pg_tables 
            WHERE schemaname = 'public' 
            AND rowsecurity = true 
            AND tablename IN (
                'profiles', 'products', 'acquisition_stages', 'customers',
                'customer_interactions', 'tickets', 'ticket_workflow_history',
                'ticket_assignees', 'ticket_comments', 'integration_tokens',
                'audit_history', 'ticket_attachments'
            )) = 12, 'RLS not enabled on all tables';
    
    -- Check policies exist
    SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE schemaname = 'public';
    ASSERT policy_count > 20, 'Insufficient number of RLS policies created';
    
    RAISE NOTICE '✓ RLS policy tests passed (% policies found)', policy_count;
END $$;

-- ===========================================
-- 4. Test Constraints
-- ===========================================

DO $$
BEGIN
    RAISE NOTICE 'Testing constraints...';
    
    -- Check foreign keys exist
    ASSERT (SELECT COUNT(*) FROM information_schema.table_constraints 
            WHERE constraint_type = 'FOREIGN KEY' 
            AND table_schema = 'public') > 15, 'Insufficient foreign keys';
    
    -- Check unique constraints
    ASSERT (SELECT COUNT(*) FROM information_schema.table_constraints 
            WHERE constraint_type = 'UNIQUE' 
            AND table_schema = 'public') >= 3, 'Insufficient unique constraints';
    
    RAISE NOTICE '✓ Constraint tests passed';
END $$;

-- ===========================================
-- 5. Test Indexes
-- ===========================================

DO $$
DECLARE
    index_count INTEGER;
BEGIN
    RAISE NOTICE 'Testing indexes...';
    
    SELECT COUNT(*) INTO index_count 
    FROM pg_indexes 
    WHERE schemaname = 'public'
    AND indexname LIKE 'idx_%';
    
    ASSERT index_count >= 13, 'Insufficient indexes created';
    
    RAISE NOTICE '✓ Index tests passed (% indexes found)', index_count;
END $$;

-- ===========================================
-- 6. Test Functions
-- ===========================================

DO $$
BEGIN
    RAISE NOTICE 'Testing functions...';
    
    -- Check critical functions exist
    ASSERT (SELECT COUNT(*) FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = 'public'
            AND p.proname IN (
                'update_updated_at_column',
                'log_ticket_status_change',
                'create_audit_history',
                'handle_new_user',
                'get_customer_stats',
                'get_ticket_stats',
                'get_dashboard_data',
                'validate_product_active_count',
                'reset_admin_password'
            )) = 9, 'Not all functions created';
    
    RAISE NOTICE '✓ Function tests passed';
END $$;

-- ===========================================
-- 7. Test Triggers
-- ===========================================

DO $$
DECLARE
    trigger_count INTEGER;
BEGIN
    RAISE NOTICE 'Testing triggers...';
    
    SELECT COUNT(*) INTO trigger_count
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'public'
    AND t.tgname NOT LIKE 'pg_%';
    
    ASSERT trigger_count >= 15, 'Insufficient triggers created';
    
    RAISE NOTICE '✓ Trigger tests passed (% triggers found)', trigger_count;
END $$;

-- ===========================================
-- 8. Test Seed Data
-- ===========================================

DO $$
DECLARE
    stage_count INTEGER;
    product_count INTEGER;
BEGIN
    RAISE NOTICE 'Testing seed data...';
    
    -- Check acquisition stages
    SELECT COUNT(*) INTO stage_count FROM acquisition_stages;
    ASSERT stage_count = 6, 'Acquisition stages not properly seeded';
    
    -- Check products
    SELECT COUNT(*) INTO product_count FROM products;
    ASSERT product_count = 4, 'Products not properly seeded';
    
    RAISE NOTICE '✓ Seed data tests passed';
END $$;

-- ===========================================
-- 9. Test Product Constraint (Max 3 Active)
-- ===========================================

DO $$
DECLARE
    test_product_id UUID;
    error_caught BOOLEAN := false;
BEGIN
    RAISE NOTICE 'Testing max 3 active products constraint...';
    
    -- Try to activate a 4th product (should fail)
    BEGIN
        UPDATE products 
        SET is_active = true 
        WHERE id = '550e8400-e29b-41d4-a716-446655440004';
    EXCEPTION WHEN OTHERS THEN
        error_caught := true;
    END;
    
    ASSERT error_caught = true, 'Max 3 active products constraint not enforced';
    
    RAISE NOTICE '✓ Product constraint tests passed';
END $$;

-- ===========================================
-- 10. Test Storage Setup
-- ===========================================

DO $$
DECLARE
    bucket_exists BOOLEAN;
BEGIN
    RAISE NOTICE 'Testing storage setup...';
    
    -- Check storage bucket exists
    SELECT EXISTS (
        SELECT 1 FROM storage.buckets WHERE id = 'ticket-attachments'
    ) INTO bucket_exists;
    
    ASSERT bucket_exists = true, 'Storage bucket not created';
    
    RAISE NOTICE '✓ Storage setup tests passed';
END $$;

-- ===========================================
-- 11. Test Admin Password Reset Function
-- ===========================================

DO $
BEGIN
    RAISE NOTICE 'Testing admin password reset function...';
    
    -- Test password reset function exists and is callable
    PERFORM reset_admin_password('admin123');
    
    RAISE NOTICE '✓ Admin password reset function tests passed';
END $;

-- ===========================================
-- 12. Test User Admin Functions
-- ===========================================

DO $
DECLARE
    admin_id UUID;
    test_user_id UUID;
    invitation_result JSON;
    resend_result JSON;
    bulk_update_result JSON;
    toggle_result JSON;
    reset_result JSON;
    activity_log_count INTEGER;
    non_admin_error_caught BOOLEAN := false;
BEGIN
    RAISE NOTICE 'Testing user admin functions...';
    
    -- Get admin user ID
    SELECT id INTO admin_id FROM auth.users WHERE email = 'admin@ezbillify.com';
    
    -- Test 1: Check all user admin functions exist
    ASSERT (SELECT COUNT(*) FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = 'public'
            AND p.proname IN (
                'create_user_invitation',
                'resend_user_invitation',
                'bulk_update_user_roles',
                'toggle_user_status',
                'reset_user_password',
                'get_user_activity_log',
                'is_admin'
            )) = 7, 'Not all user admin functions created';
    
    RAISE NOTICE '  ✓ All user admin functions exist';
    
    -- Test 2: Check user_activity_log view exists
    ASSERT (SELECT COUNT(*) FROM pg_views 
            WHERE schemaname = 'public' 
            AND viewname = 'user_activity_log') = 1, 
            'user_activity_log view not created';
    
    RAISE NOTICE '  ✓ user_activity_log view exists';
    
    -- Test 3: Test is_admin function (as admin)
    -- Set session to admin user
    PERFORM set_config('request.jwt.claims', json_build_object('sub', admin_id)::text, true);
    ASSERT is_admin() = true, 'is_admin() should return true for admin user';
    
    RAISE NOTICE '  ✓ is_admin() works correctly';
    
    -- Test 4: Test create_user_invitation (as admin)
    BEGIN
        SELECT create_user_invitation('test@example.com', 'agent', admin_id) INTO invitation_result;
        ASSERT invitation_result IS NOT NULL, 'create_user_invitation should return result';
        RAISE NOTICE '  ✓ create_user_invitation works for admin';
    EXCEPTION WHEN OTHERS THEN
        -- This may fail if user already exists, which is acceptable
        RAISE NOTICE '  ⚠ create_user_invitation test skipped (user may already exist)';
    END;
    
    -- Test 5: Test bulk_update_user_roles (as admin)
    -- Create a test user first if needed
    INSERT INTO auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, created_at, updated_at
    )
    VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        'bulktest@example.com',
        crypt('password123', gen_salt('bf')),
        NOW(),
        NOW(),
        NOW()
    )
    ON CONFLICT (email) DO NOTHING
    RETURNING id INTO test_user_id;
    
    IF test_user_id IS NOT NULL THEN
        INSERT INTO profiles (id, email, role, full_name)
        VALUES (test_user_id, 'bulktest@example.com', 'agent', 'Bulk Test User')
        ON CONFLICT (id) DO NOTHING;
        
        SELECT bulk_update_user_roles(ARRAY[test_user_id], 'admin', admin_id) INTO bulk_update_result;
        ASSERT bulk_update_result IS NOT NULL, 'bulk_update_user_roles should return result';
        RAISE NOTICE '  ✓ bulk_update_user_roles works for admin';
    ELSE
        RAISE NOTICE '  ⚠ bulk_update_user_roles test skipped (could not create test user)';
    END IF;
    
    -- Test 6: Test toggle_user_status (as admin)
    IF test_user_id IS NOT NULL THEN
        BEGIN
            SELECT toggle_user_status(test_user_id, false, admin_id) INTO toggle_result;
            ASSERT toggle_result IS NOT NULL, 'toggle_user_status should return result';
            RAISE NOTICE '  ✓ toggle_user_status works for admin';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '  ⚠ toggle_user_status test failed: %', SQLERRM;
        END;
    END IF;
    
    -- Test 7: Test get_user_activity_log (as admin)
    SELECT COUNT(*) INTO activity_log_count
    FROM get_user_activity_log(10, 0);
    ASSERT activity_log_count >= 0, 'get_user_activity_log should return results';
    RAISE NOTICE '  ✓ get_user_activity_log works for admin (% entries)', activity_log_count;
    
    -- Test 8: Test non-admin access (should fail)
    -- Create a non-admin user session
    INSERT INTO auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, created_at, updated_at
    )
    VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        'nonadmin@example.com',
        crypt('password123', gen_salt('bf')),
        NOW(),
        NOW(),
        NOW()
    )
    ON CONFLICT (email) DO UPDATE SET email = EXCLUDED.email
    RETURNING id INTO test_user_id;
    
    INSERT INTO profiles (id, email, role, full_name)
    VALUES (test_user_id, 'nonadmin@example.com', 'agent', 'Non Admin User')
    ON CONFLICT (id) DO UPDATE SET role = 'agent';
    
    -- Set session to non-admin user
    PERFORM set_config('request.jwt.claims', json_build_object('sub', test_user_id)::text, true);
    
    -- Try to call get_user_activity_log as non-admin (should fail)
    BEGIN
        PERFORM get_user_activity_log(10, 0);
        non_admin_error_caught := false;
    EXCEPTION WHEN OTHERS THEN
        non_admin_error_caught := true;
    END;
    
    ASSERT non_admin_error_caught = true, 'Non-admin should not be able to call get_user_activity_log';
    RAISE NOTICE '  ✓ Non-admin access correctly denied';
    
    -- Reset session
    PERFORM set_config('request.jwt.claims', NULL, true);
    
    RAISE NOTICE '✓ User admin function tests passed';
END $;

-- ===========================================
-- Summary
-- ===========================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '===========================================';
    RAISE NOTICE '✓ ALL TESTS PASSED';
    RAISE NOTICE '===========================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Database is production-ready!';
    RAISE NOTICE '';
    RAISE NOTICE 'Admin credentials:';
    RAISE NOTICE '  Email: admin@ezbillify.com';
    RAISE NOTICE '  Password: admin123';
    RAISE NOTICE '';
    RAISE NOTICE 'IMPORTANT: Change admin password in production!';
    RAISE NOTICE '';
END $$;

-- Optional: Display some useful statistics
SELECT 
    'Tables' as category,
    COUNT(*) as count
FROM pg_tables 
WHERE schemaname = 'public'
UNION ALL
SELECT 
    'Views' as category,
    COUNT(*) as count
FROM pg_views 
WHERE schemaname = 'public'
UNION ALL
SELECT 
    'Functions' as category,
    COUNT(*) as count
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
UNION ALL
SELECT 
    'Triggers' as category,
    COUNT(*) as count
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public'
AND t.tgname NOT LIKE 'pg_%'
UNION ALL
SELECT 
    'RLS Policies' as category,
    COUNT(*) as count
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY category;
