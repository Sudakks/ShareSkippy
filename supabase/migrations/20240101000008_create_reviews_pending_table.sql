-- Migration: Create reviews_pending table to match Supabase schema
-- This table tracks pending reviews that need to be completed

CREATE TABLE IF NOT EXISTS public.reviews_pending (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  conversation_id uuid NOT NULL,
  other_participant_id uuid NOT NULL,
  availability_id uuid,
  role text NOT NULL CHECK (role = ANY (ARRAY['owner'::text, 'walker'::text])),
  other_role text NOT NULL CHECK (other_role = ANY (ARRAY['owner'::text, 'walker'::text])),
  days_since_last_message integer NOT NULL,
  is_notified boolean DEFAULT false,
  notification_sent_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT reviews_pending_pkey PRIMARY KEY (id),
  CONSTRAINT reviews_pending_other_participant_id_fkey FOREIGN KEY (other_participant_id) REFERENCES public.profiles(id),
  CONSTRAINT reviews_pending_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT reviews_pending_availability_id_fkey FOREIGN KEY (availability_id) REFERENCES public.availability(id),
  CONSTRAINT reviews_pending_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_reviews_pending_user_id ON reviews_pending(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_pending_conversation_id ON reviews_pending(conversation_id);
CREATE INDEX IF NOT EXISTS idx_reviews_pending_other_participant_id ON reviews_pending(other_participant_id);
CREATE INDEX IF NOT EXISTS idx_reviews_pending_availability_id ON reviews_pending(availability_id);
CREATE INDEX IF NOT EXISTS idx_reviews_pending_is_notified ON reviews_pending(is_notified);
CREATE INDEX IF NOT EXISTS idx_reviews_pending_created_at ON reviews_pending(created_at);

-- Enable Row Level Security
ALTER TABLE reviews_pending ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for reviews_pending table
CREATE POLICY "Users can view their own pending reviews" ON reviews_pending
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create pending reviews for themselves" ON reviews_pending
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own pending reviews" ON reviews_pending
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own pending reviews" ON reviews_pending
  FOR DELETE USING (auth.uid() = user_id);

-- Add comments to describe the table and columns
COMMENT ON TABLE reviews_pending IS 'Tracks pending reviews that users need to complete';
COMMENT ON COLUMN reviews_pending.user_id IS 'User who needs to complete the review';
COMMENT ON COLUMN reviews_pending.conversation_id IS 'Conversation this pending review is related to';
COMMENT ON COLUMN reviews_pending.other_participant_id IS 'Other participant in the conversation';
COMMENT ON COLUMN reviews_pending.availability_id IS 'Availability post this review is related to';
COMMENT ON COLUMN reviews_pending.role IS 'Role of the user (owner, walker)';
COMMENT ON COLUMN reviews_pending.other_role IS 'Role of the other participant (owner, walker)';
COMMENT ON COLUMN reviews_pending.days_since_last_message IS 'Number of days since the last message in the conversation';
COMMENT ON COLUMN reviews_pending.is_notified IS 'Whether the user has been notified about the pending review';
COMMENT ON COLUMN reviews_pending.notification_sent_at IS 'When the notification was sent';

-- Verify the migration
SELECT 
    'Reviews pending table created successfully' as status,
    COUNT(*) as total_pending_reviews
FROM reviews_pending;
