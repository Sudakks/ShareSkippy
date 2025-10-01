-- Create email system tables for centralized email management
-- This migration creates the core tables for the new email system

-- Email catalog table - defines all email types
CREATE TABLE IF NOT EXISTS email_catalog (
  id TEXT PRIMARY KEY,
  description TEXT NOT NULL,
  enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Email events table - tracks all email sending events
CREATE TABLE IF NOT EXISTS email_events (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  email_type TEXT NOT NULL REFERENCES email_catalog(id),
  status TEXT NOT NULL CHECK (status IN ('queued', 'sent', 'failed', 'skipped')),
  external_message_id TEXT,
  error TEXT,
  to_email TEXT NOT NULL,
  subject TEXT,
  payload JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Scheduled emails table - for queuing emails to be sent later
CREATE TABLE IF NOT EXISTS scheduled_emails (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  email_type TEXT NOT NULL REFERENCES email_catalog(id),
  run_after TIMESTAMP WITH TIME ZONE NOT NULL,
  payload JSONB DEFAULT '{}'::jsonb,
  picked_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User activity table - tracks user actions for re-engagement logic
CREATE TABLE IF NOT EXISTS user_activity (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  event TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert email types into catalog
INSERT INTO email_catalog (id, description, enabled) VALUES
  ('welcome', 'Welcome email sent on first successful sign-in', TRUE),
  ('nurture_day3', '3-day nurture email sent 3 days after first sign-in', TRUE),
  ('meeting_reminder', 'Meeting reminder sent 1 day before scheduled meeting', TRUE),
  ('reengage', 'Re-engagement email for inactive users', TRUE),
  ('new_message', 'New message notification email', TRUE)
ON CONFLICT (id) DO NOTHING;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_email_events_user_id ON email_events(user_id);
CREATE INDEX IF NOT EXISTS idx_email_events_email_type ON email_events(email_type);
CREATE INDEX IF NOT EXISTS idx_email_events_status ON email_events(status);
CREATE INDEX IF NOT EXISTS idx_email_events_created_at ON email_events(created_at);
CREATE INDEX IF NOT EXISTS idx_email_events_user_type ON email_events(user_id, email_type);

-- Unique constraint for single-shot emails (welcome, nurture_day3)
CREATE UNIQUE INDEX IF NOT EXISTS idx_email_events_single_shot 
ON email_events(user_id, email_type) 
WHERE email_type IN ('welcome', 'nurture_day3');

-- Scheduled emails indexes
CREATE INDEX IF NOT EXISTS idx_scheduled_emails_run_after ON scheduled_emails(run_after) WHERE picked_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_scheduled_emails_user_id ON scheduled_emails(user_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_emails_email_type ON scheduled_emails(email_type);

-- User activity indexes
CREATE INDEX IF NOT EXISTS idx_user_activity_user_id ON user_activity(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_event ON user_activity(event);
CREATE INDEX IF NOT EXISTS idx_user_activity_at ON user_activity(at);
CREATE INDEX IF NOT EXISTS idx_user_activity_user_event ON user_activity(user_id, event);

-- Enable RLS
ALTER TABLE email_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_emails ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activity ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Email catalog - readable by all authenticated users
CREATE POLICY "Anyone can view email catalog" ON email_catalog FOR SELECT USING (true);

-- Email events - users can view their own events, admins can view all
CREATE POLICY "Users can view their own email events" ON email_events
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all email events" ON email_events
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Scheduled emails - users can view their own, admins can view all
CREATE POLICY "Users can view their own scheduled emails" ON scheduled_emails
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all scheduled emails" ON scheduled_emails
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- User activity - users can view their own activity
CREATE POLICY "Users can view their own activity" ON user_activity
  FOR SELECT USING (auth.uid() = user_id);

-- Service role can manage all email system tables
CREATE POLICY "Service role can manage email system" ON email_events
  FOR ALL USING (true);

CREATE POLICY "Service role can manage scheduled emails" ON scheduled_emails
  FOR ALL USING (true);

CREATE POLICY "Service role can manage user activity" ON user_activity
  FOR ALL USING (true);

-- Add comments for documentation
COMMENT ON TABLE email_catalog IS 'Catalog of all email types supported by the system';
COMMENT ON TABLE email_events IS 'Tracks all email sending events with status and external message IDs';
COMMENT ON TABLE scheduled_emails IS 'Queue for emails to be sent at specific times';
COMMENT ON TABLE user_activity IS 'Tracks user actions for re-engagement and analytics';
