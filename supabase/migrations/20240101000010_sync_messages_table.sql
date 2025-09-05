-- Migration: Sync messages table with current Supabase schema
-- Add missing conversation_id field to messages table

-- Add the missing conversation_id field
ALTER TABLE messages ADD COLUMN IF NOT EXISTS conversation_id uuid;

-- Add foreign key constraint
ALTER TABLE messages ADD CONSTRAINT messages_conversation_id_fkey 
FOREIGN KEY (conversation_id) REFERENCES public.conversations(id);

-- Add comment to describe the new column
COMMENT ON COLUMN messages.conversation_id IS 'Reference to the conversation this message belongs to';

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);

-- Verify the migration
SELECT 
    'Messages table sync completed successfully' as status,
    COUNT(*) as total_messages,
    COUNT(CASE WHEN conversation_id IS NOT NULL THEN 1 END) as messages_with_conversation
FROM messages;
