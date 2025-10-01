-- Add re-engagement email tracking fields to user_settings table
ALTER TABLE user_settings 
ADD COLUMN IF NOT EXISTS re_engagement_email_sent BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS re_engagement_email_sent_at TIMESTAMP WITH TIME ZONE;

-- Add index for efficient querying
CREATE INDEX IF NOT EXISTS idx_user_settings_re_engagement 
ON user_settings (re_engagement_email_sent, re_engagement_email_sent_at);

-- Add comment for documentation
COMMENT ON COLUMN user_settings.re_engagement_email_sent IS 'Tracks if re-engagement email has been sent to user';
COMMENT ON COLUMN user_settings.re_engagement_email_sent_at IS 'Timestamp when re-engagement email was sent';
