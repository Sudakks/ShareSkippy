-- Migration: Sync conversations table with current Supabase schema
-- Add missing availability_post_id field to conversations table

-- Add the missing availability_post_id field
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS availability_post_id uuid;

-- Add foreign key constraint
ALTER TABLE conversations ADD CONSTRAINT conversations_availability_post_id_fkey 
FOREIGN KEY (availability_post_id) REFERENCES public.availability(id);

-- Add comment to describe the new column
COMMENT ON COLUMN conversations.availability_post_id IS 'Reference to the availability post this conversation is about';

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_conversations_availability_post_id ON conversations(availability_post_id);

-- Verify the migration
SELECT 
    'Conversations table sync completed successfully' as status,
    COUNT(*) as total_conversations,
    COUNT(CASE WHEN availability_post_id IS NOT NULL THEN 1 END) as conversations_with_availability_post
FROM conversations;
