-- ============================================================================
-- Integration Tokens System
-- ============================================================================
-- This migration creates the infrastructure for external API integrations
-- including token management, usage logging, and rate limiting.
-- ============================================================================

-- ============================================================================
-- 1. INTEGRATION TOKENS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS integration_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  token_hash TEXT NOT NULL UNIQUE,
  token_prefix VARCHAR(16) NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'disabled', 'revoked')),
  rate_limit_per_hour INTEGER NOT NULL DEFAULT 1000,
  allowed_endpoints JSONB DEFAULT '["*"]'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_used_at TIMESTAMP WITH TIME ZONE,
  expires_at TIMESTAMP WITH TIME ZONE,
  metadata JSONB DEFAULT '{}'::jsonb
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_integration_tokens_user_id ON integration_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_integration_tokens_token_hash ON integration_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_integration_tokens_status ON integration_tokens(status);
CREATE INDEX IF NOT EXISTS idx_integration_tokens_expires_at ON integration_tokens(expires_at);

-- Add comments
COMMENT ON TABLE integration_tokens IS 'Stores API tokens for external integrations';
COMMENT ON COLUMN integration_tokens.token_hash IS 'SHA-256 hash of the actual token';
COMMENT ON COLUMN integration_tokens.token_prefix IS 'First 8 chars of token for display';
COMMENT ON COLUMN integration_tokens.allowed_endpoints IS 'Array of allowed endpoint patterns';

-- ============================================================================
-- 2. TOKEN USAGE LOGS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS integration_token_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  token_id UUID NOT NULL REFERENCES integration_tokens(id) ON DELETE CASCADE,
  endpoint VARCHAR(255) NOT NULL,
  method VARCHAR(10) NOT NULL,
  status_code INTEGER NOT NULL,
  response_time_ms INTEGER,
  ip_address INET,
  user_agent TEXT,
  request_payload JSONB,
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_integration_token_usage_token_id ON integration_token_usage(token_id);
CREATE INDEX IF NOT EXISTS idx_integration_token_usage_created_at ON integration_token_usage(created_at);
CREATE INDEX IF NOT EXISTS idx_integration_token_usage_token_created ON integration_token_usage(token_id, created_at);

-- Add comments
COMMENT ON TABLE integration_token_usage IS 'Logs all API requests made with integration tokens';

-- ============================================================================
-- 3. TICKETS TABLE (if not exists)
-- ============================================================================

CREATE TABLE IF NOT EXISTS tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(500) NOT NULL,
  description TEXT,
  status VARCHAR(50) NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'waiting', 'resolved', 'closed')),
  priority VARCHAR(20) NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  category VARCHAR(100),
  assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  integration_source UUID REFERENCES integration_tokens(id) ON DELETE SET NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  resolved_at TIMESTAMP WITH TIME ZONE,
  closed_at TIMESTAMP WITH TIME ZONE
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status);
CREATE INDEX IF NOT EXISTS idx_tickets_created_by ON tickets(created_by);
CREATE INDEX IF NOT EXISTS idx_tickets_assigned_to ON tickets(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tickets_integration_source ON tickets(integration_source);
CREATE INDEX IF NOT EXISTS idx_tickets_created_at ON tickets(created_at);

-- Add comments
COMMENT ON TABLE tickets IS 'Support tickets created by users or external integrations';
COMMENT ON COLUMN tickets.integration_source IS 'Token ID if created via external integration';

-- ============================================================================
-- 4. TICKET COMMENTS TABLE (if not exists)
-- ============================================================================

CREATE TABLE IF NOT EXISTS ticket_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  integration_source UUID REFERENCES integration_tokens(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  is_internal BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_ticket_comments_ticket_id ON ticket_comments(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_comments_created_at ON ticket_comments(created_at);

-- Add comments
COMMENT ON TABLE ticket_comments IS 'Comments on support tickets';
COMMENT ON COLUMN ticket_comments.is_internal IS 'Whether comment is visible to external integrations';

-- ============================================================================
-- 5. UPDATED_AT TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for integration_tokens
DROP TRIGGER IF EXISTS update_integration_tokens_updated_at ON integration_tokens;
CREATE TRIGGER update_integration_tokens_updated_at
  BEFORE UPDATE ON integration_tokens
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for tickets
DROP TRIGGER IF EXISTS update_tickets_updated_at ON tickets;
CREATE TRIGGER update_tickets_updated_at
  BEFORE UPDATE ON tickets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for ticket_comments
DROP TRIGGER IF EXISTS update_ticket_comments_updated_at ON ticket_comments;
CREATE TRIGGER update_ticket_comments_updated_at
  BEFORE UPDATE ON ticket_comments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE integration_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE integration_token_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_comments ENABLE ROW LEVEL SECURITY;

-- Integration Tokens Policies
-- Users can view their own tokens
CREATE POLICY integration_tokens_select_own ON integration_tokens
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own tokens
CREATE POLICY integration_tokens_insert_own ON integration_tokens
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own tokens
CREATE POLICY integration_tokens_update_own ON integration_tokens
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own tokens
CREATE POLICY integration_tokens_delete_own ON integration_tokens
  FOR DELETE
  USING (auth.uid() = user_id);

-- Token Usage Policies
-- Users can view usage of their own tokens
CREATE POLICY integration_token_usage_select_own ON integration_token_usage
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM integration_tokens
      WHERE integration_tokens.id = integration_token_usage.token_id
      AND integration_tokens.user_id = auth.uid()
    )
  );

-- Tickets Policies
-- Users can view tickets they created or are assigned to
CREATE POLICY tickets_select_own ON tickets
  FOR SELECT
  USING (
    auth.uid() = created_by OR
    auth.uid() = assigned_to OR
    EXISTS (
      SELECT 1 FROM integration_tokens
      WHERE integration_tokens.id = tickets.integration_source
      AND integration_tokens.user_id = auth.uid()
    )
  );

-- Users can insert tickets
CREATE POLICY tickets_insert ON tickets
  FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Users can update tickets they created or are assigned to
CREATE POLICY tickets_update_own ON tickets
  FOR UPDATE
  USING (auth.uid() = created_by OR auth.uid() = assigned_to);

-- Ticket Comments Policies
-- Users can view comments on tickets they have access to
CREATE POLICY ticket_comments_select ON ticket_comments
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM tickets
      WHERE tickets.id = ticket_comments.ticket_id
      AND (
        tickets.created_by = auth.uid() OR
        tickets.assigned_to = auth.uid() OR
        EXISTS (
          SELECT 1 FROM integration_tokens
          WHERE integration_tokens.id = tickets.integration_source
          AND integration_tokens.user_id = auth.uid()
        )
      )
    )
  );

-- Users can insert comments on tickets they have access to
CREATE POLICY ticket_comments_insert ON ticket_comments
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM tickets
      WHERE tickets.id = ticket_comments.ticket_id
      AND (tickets.created_by = auth.uid() OR tickets.assigned_to = auth.uid())
    )
  );

-- ============================================================================
-- 7. SECURITY DEFINER FUNCTIONS
-- ============================================================================

-- Function to validate integration token and log usage
CREATE OR REPLACE FUNCTION validate_integration_token(
  p_token TEXT,
  p_endpoint TEXT DEFAULT NULL,
  p_method TEXT DEFAULT 'GET',
  p_ip_address INET DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL
)
RETURNS TABLE(
  valid BOOLEAN,
  token_id UUID,
  user_id UUID,
  rate_limit_exceeded BOOLEAN,
  error_message TEXT
) AS $$
DECLARE
  v_token_hash TEXT;
  v_token_record RECORD;
  v_hour_start TIMESTAMP WITH TIME ZONE;
  v_usage_count INTEGER;
BEGIN
  -- Hash the provided token
  v_token_hash := encode(digest(p_token, 'sha256'), 'hex');
  
  -- Find the token
  SELECT * INTO v_token_record
  FROM integration_tokens
  WHERE token_hash = v_token_hash;
  
  -- Check if token exists
  IF v_token_record.id IS NULL THEN
    RETURN QUERY SELECT false, NULL::UUID, NULL::UUID, false, 'Invalid token'::TEXT;
    RETURN;
  END IF;
  
  -- Check if token is active
  IF v_token_record.status != 'active' THEN
    RETURN QUERY SELECT false, v_token_record.id, v_token_record.user_id, false, 
      ('Token is ' || v_token_record.status)::TEXT;
    RETURN;
  END IF;
  
  -- Check if token is expired
  IF v_token_record.expires_at IS NOT NULL AND v_token_record.expires_at < NOW() THEN
    RETURN QUERY SELECT false, v_token_record.id, v_token_record.user_id, false, 'Token has expired'::TEXT;
    RETURN;
  END IF;
  
  -- Check rate limit
  v_hour_start := date_trunc('hour', NOW());
  SELECT COUNT(*) INTO v_usage_count
  FROM integration_token_usage
  WHERE token_id = v_token_record.id
  AND created_at >= v_hour_start;
  
  IF v_usage_count >= v_token_record.rate_limit_per_hour THEN
    RETURN QUERY SELECT false, v_token_record.id, v_token_record.user_id, true, 'Rate limit exceeded'::TEXT;
    RETURN;
  END IF;
  
  -- Update last_used_at
  UPDATE integration_tokens
  SET last_used_at = NOW()
  WHERE id = v_token_record.id;
  
  -- Return success
  RETURN QUERY SELECT true, v_token_record.id, v_token_record.user_id, false, NULL::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to log token usage
CREATE OR REPLACE FUNCTION log_integration_token_usage(
  p_token_id UUID,
  p_endpoint TEXT,
  p_method TEXT,
  p_status_code INTEGER,
  p_response_time_ms INTEGER DEFAULT NULL,
  p_ip_address INET DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL,
  p_request_payload JSONB DEFAULT NULL,
  p_error_message TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO integration_token_usage (
    token_id,
    endpoint,
    method,
    status_code,
    response_time_ms,
    ip_address,
    user_agent,
    request_payload,
    error_message
  ) VALUES (
    p_token_id,
    p_endpoint,
    p_method,
    p_status_code,
    p_response_time_ms,
    p_ip_address,
    p_user_agent,
    p_request_payload,
    p_error_message
  )
  RETURNING id INTO v_log_id;
  
  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create ticket via integration
CREATE OR REPLACE FUNCTION create_ticket_via_integration(
  p_token_id UUID,
  p_user_id UUID,
  p_title TEXT,
  p_description TEXT DEFAULT NULL,
  p_priority TEXT DEFAULT 'medium',
  p_category TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
  v_ticket_id UUID;
BEGIN
  -- Validate priority
  IF p_priority NOT IN ('low', 'medium', 'high', 'urgent') THEN
    RAISE EXCEPTION 'Invalid priority: %', p_priority;
  END IF;
  
  -- Create ticket
  INSERT INTO tickets (
    title,
    description,
    status,
    priority,
    category,
    created_by,
    integration_source,
    metadata
  ) VALUES (
    p_title,
    p_description,
    'open',
    p_priority,
    p_category,
    p_user_id,
    p_token_id,
    p_metadata
  )
  RETURNING id INTO v_ticket_id;
  
  RETURN v_ticket_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add comment via integration
CREATE OR REPLACE FUNCTION add_ticket_comment_via_integration(
  p_token_id UUID,
  p_user_id UUID,
  p_ticket_id UUID,
  p_content TEXT,
  p_is_internal BOOLEAN DEFAULT false
)
RETURNS UUID AS $$
DECLARE
  v_comment_id UUID;
  v_ticket_owner UUID;
BEGIN
  -- Check if ticket exists and get owner
  SELECT created_by INTO v_ticket_owner
  FROM tickets
  WHERE id = p_ticket_id;
  
  IF v_ticket_owner IS NULL THEN
    RAISE EXCEPTION 'Ticket not found: %', p_ticket_id;
  END IF;
  
  -- Verify token owner matches ticket owner
  IF v_ticket_owner != p_user_id THEN
    RAISE EXCEPTION 'Not authorized to comment on this ticket';
  END IF;
  
  -- Create comment
  INSERT INTO ticket_comments (
    ticket_id,
    user_id,
    integration_source,
    content,
    is_internal
  ) VALUES (
    p_ticket_id,
    p_user_id,
    p_token_id,
    p_content,
    p_is_internal
  )
  RETURNING id INTO v_comment_id;
  
  RETURN v_comment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update ticket status via integration
CREATE OR REPLACE FUNCTION update_ticket_status_via_integration(
  p_token_id UUID,
  p_user_id UUID,
  p_ticket_id UUID,
  p_status TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_ticket_owner UUID;
BEGIN
  -- Validate status
  IF p_status NOT IN ('open', 'in_progress', 'waiting', 'resolved', 'closed') THEN
    RAISE EXCEPTION 'Invalid status: %', p_status;
  END IF;
  
  -- Check if ticket exists and get owner
  SELECT created_by INTO v_ticket_owner
  FROM tickets
  WHERE id = p_ticket_id;
  
  IF v_ticket_owner IS NULL THEN
    RAISE EXCEPTION 'Ticket not found: %', p_ticket_id;
  END IF;
  
  -- Verify token owner matches ticket owner
  IF v_ticket_owner != p_user_id THEN
    RAISE EXCEPTION 'Not authorized to update this ticket';
  END IF;
  
  -- Update ticket
  UPDATE tickets
  SET 
    status = p_status,
    resolved_at = CASE WHEN p_status = 'resolved' THEN NOW() ELSE resolved_at END,
    closed_at = CASE WHEN p_status = 'closed' THEN NOW() ELSE closed_at END
  WHERE id = p_ticket_id;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 8. HELPER VIEWS
-- ============================================================================

-- View for token statistics
CREATE OR REPLACE VIEW integration_token_stats AS
SELECT
  t.id AS token_id,
  t.name AS token_name,
  t.status,
  t.created_at,
  t.last_used_at,
  COUNT(u.id) AS total_requests,
  COUNT(CASE WHEN u.created_at >= date_trunc('hour', NOW()) THEN 1 END) AS requests_this_hour,
  COUNT(CASE WHEN u.created_at >= date_trunc('day', NOW()) THEN 1 END) AS requests_today,
  COUNT(CASE WHEN u.status_code >= 400 THEN 1 END) AS error_count,
  AVG(u.response_time_ms) AS avg_response_time_ms
FROM integration_tokens t
LEFT JOIN integration_token_usage u ON u.token_id = t.id
GROUP BY t.id, t.name, t.status, t.created_at, t.last_used_at;

-- View for recent token usage
CREATE OR REPLACE VIEW recent_token_usage AS
SELECT
  u.id,
  u.token_id,
  t.name AS token_name,
  u.endpoint,
  u.method,
  u.status_code,
  u.response_time_ms,
  u.ip_address,
  u.error_message,
  u.created_at
FROM integration_token_usage u
JOIN integration_tokens t ON t.id = u.token_id
ORDER BY u.created_at DESC
LIMIT 1000;

-- Grant access to views
GRANT SELECT ON integration_token_stats TO authenticated;
GRANT SELECT ON recent_token_usage TO authenticated;

-- ============================================================================
-- 9. GRANT PERMISSIONS
-- ============================================================================

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION validate_integration_token TO anon, authenticated;
GRANT EXECUTE ON FUNCTION log_integration_token_usage TO anon, authenticated;
GRANT EXECUTE ON FUNCTION create_ticket_via_integration TO anon, authenticated;
GRANT EXECUTE ON FUNCTION add_ticket_comment_via_integration TO anon, authenticated;
GRANT EXECUTE ON FUNCTION update_ticket_status_via_integration TO anon, authenticated;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================

-- Add helpful comments
COMMENT ON FUNCTION validate_integration_token IS 'Validates an integration token and checks rate limits';
COMMENT ON FUNCTION log_integration_token_usage IS 'Logs API usage for monitoring and auditing';
COMMENT ON FUNCTION create_ticket_via_integration IS 'Creates a ticket on behalf of an external integration';
COMMENT ON FUNCTION add_ticket_comment_via_integration IS 'Adds a comment to a ticket via integration';
COMMENT ON FUNCTION update_ticket_status_via_integration IS 'Updates ticket status via integration';
