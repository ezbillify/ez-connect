-- Supabase Storage setup for ticket attachments

-- Create storage bucket for ticket attachments
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'ticket-attachments',
    'ticket-attachments',
    false, -- private bucket
    52428800, -- 50MB file size limit
    ARRAY[
        'image/jpeg',
        'image/png', 
        'image/gif',
        'application/pdf',
        'text/plain',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    ]
) ON CONFLICT (id) DO NOTHING;

-- Create ticket_attachments table to track file metadata
CREATE TABLE ticket_attachments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type TEXT NOT NULL,
    uploaded_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Enable RLS on ticket_attachments
ALTER TABLE ticket_attachments ENABLE ROW LEVEL SECURITY;

-- Policies for ticket_attachments
-- Users can view attachments for tickets they can see
CREATE POLICY "Users can view ticket attachments" ON ticket_attachments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM tickets 
            WHERE tickets.id = ticket_attachments.ticket_id 
            AND (tickets.created_by = auth.uid() OR 
                 tickets.assigned_to = auth.uid() OR
                 (auth.jwt() ->> 'role' = 'admin') OR
                 (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin')
        )
    );

-- Users can upload attachments to tickets they can see
CREATE POLICY "Users can upload ticket attachments" ON ticket_attachments
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM tickets 
            WHERE tickets.id = ticket_attachments.ticket_id 
            AND (tickets.created_by = auth.uid() OR 
                 tickets.assigned_to = auth.uid() OR
                 (auth.jwt() ->> 'role' = 'admin') OR
                 (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin')
        ) AND
        uploaded_by = auth.uid()
    );

-- Users can delete their own attachments (or admins can delete any)
CREATE POLICY "Users can delete own attachments" ON ticket_attachments
    FOR DELETE USING (
        uploaded_by = auth.uid() OR
        (auth.jwt() ->> 'role' = 'admin') OR
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );

-- Storage policies for ticket-attachments bucket
-- Users can upload files to tickets they have access to
CREATE POLICY "Users can upload ticket attachments" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'ticket-attachments' AND
        auth.role() = 'authenticated' AND
        -- Extract ticket_id from path (format: ticket_id/filename)
        EXISTS (
            SELECT 1 FROM tickets 
            WHERE tickets.id::text = SPLIT_PART(name, '/', 1)
            AND (tickets.created_by = auth.uid() OR 
                 tickets.assigned_to = auth.uid() OR
                 (auth.jwt() ->> 'role' = 'admin') OR
                 (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin')
        )
    );

-- Users can view files from tickets they have access to
CREATE POLICY "Users can view ticket attachments" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'ticket-attachments' AND
        EXISTS (
            SELECT 1 FROM tickets 
            WHERE tickets.id::text = SPLIT_PART(name, '/', 1)
            AND (tickets.created_by = auth.uid() OR 
                 tickets.assigned_to = auth.uid() OR
                 (auth.jwt() ->> 'role' = 'admin') OR
                 (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin')
        )
    );

-- Users can update their own uploaded files
CREATE POLICY "Users can update own attachments" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'ticket-attachments' AND
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM ticket_attachments 
            WHERE ticket_attachments.file_path = storage.objects.name
            AND ticket_attachments.uploaded_by = auth.uid()
        )
    );

-- Users can delete their own uploaded files (or admins)
CREATE POLICY "Users can delete own attachments" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'ticket-attachments' AND
        (
            (SELECT uploaded_by FROM ticket_attachments 
             WHERE ticket_attachments.file_path = storage.objects.name) = auth.uid()
            OR
            (auth.jwt() ->> 'role' = 'admin')
            OR
            (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
        )
    );

-- Create index for better performance
CREATE INDEX idx_ticket_attachments_ticket_id ON ticket_attachments(ticket_id);
CREATE INDEX idx_ticket_attachments_uploaded_by ON ticket_attachments(uploaded_by);

-- Function to get ticket attachment path for client-side signed URL generation
CREATE OR REPLACE FUNCTION get_ticket_attachment_path(
    p_attachment_id UUID
) RETURNS TEXT AS $$
DECLARE
    attachment_path TEXT;
BEGIN
    -- Get attachment path and verify access
    SELECT ta.file_path INTO attachment_path
    FROM ticket_attachments ta
    JOIN tickets t ON ta.ticket_id = t.id
    WHERE ta.id = p_attachment_id
    AND (
        t.created_by = auth.uid() OR 
        t.assigned_to = auth.uid() OR
        (auth.jwt() ->> 'role' = 'admin') OR
        (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
    );
    
    IF attachment_path IS NULL THEN
        RAISE EXCEPTION 'Attachment not found or access denied';
    END IF;
    
    RETURN attachment_path;
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- Function to clean up orphaned attachment records
CREATE OR REPLACE FUNCTION cleanup_orphaned_attachments()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Delete attachment records where the file no longer exists in storage
    DELETE FROM ticket_attachments 
    WHERE NOT EXISTS (
        SELECT 1 FROM storage.objects 
        WHERE storage.objects.name = ticket_attachments.file_path
        AND storage.objects.bucket_id = 'ticket-attachments'
    );
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ language 'plpgsql';

-- Create audit trigger for ticket_attachments
CREATE TRIGGER audit_ticket_attachments_trigger
    AFTER INSERT OR UPDATE OR DELETE ON ticket_attachments
    FOR EACH ROW EXECUTE FUNCTION create_audit_history();