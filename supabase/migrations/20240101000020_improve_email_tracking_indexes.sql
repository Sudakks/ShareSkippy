-- Improve email tracking indexes for better performance
-- This migration adds composite indexes for efficient querying

-- Add composite index for re-engagement email queries
CREATE INDEX IF NOT EXISTS idx_user_settings_re_engagement_composite 
ON user_settings (re_engagement_email_sent, re_engagement_email_sent_at, user_id);

-- Add composite index for 3-day follow-up email queries  
CREATE INDEX IF NOT EXISTS idx_user_settings_3day_composite 
ON user_settings (follow_up_3day_sent, follow_up_3day_sent_at, user_id);

-- Add index for time-based queries on user_settings
CREATE INDEX IF NOT EXISTS idx_user_settings_time_queries 
ON user_settings (re_engagement_email_sent_at, follow_up_3day_sent_at);

-- Add index for profiles table to support inactive user queries
CREATE INDEX IF NOT EXISTS idx_profiles_updated_at_email 
ON profiles (updated_at, email) WHERE email IS NOT NULL AND email != '';

-- Add index for profiles table to support auth.users joins
CREATE INDEX IF NOT EXISTS idx_profiles_id_email 
ON profiles (id, email) WHERE email IS NOT NULL AND email != '';

-- Add partial index for active users (those who haven't been sent re-engagement emails)
CREATE INDEX IF NOT EXISTS idx_user_settings_not_re_engaged 
ON user_settings (user_id) WHERE re_engagement_email_sent = false;

-- Add partial index for users who haven't received 3-day follow-up
CREATE INDEX IF NOT EXISTS idx_user_settings_not_3day_followup 
ON user_settings (user_id) WHERE follow_up_3day_sent = false;

-- Add comments for documentation
COMMENT ON INDEX idx_user_settings_re_engagement_composite IS 'Composite index for efficient re-engagement email queries';
COMMENT ON INDEX idx_user_settings_3day_composite IS 'Composite index for efficient 3-day follow-up email queries';
COMMENT ON INDEX idx_user_settings_time_queries IS 'Index for time-based email tracking queries';
COMMENT ON INDEX idx_profiles_updated_at_email IS 'Index for inactive user queries based on updated_at';
COMMENT ON INDEX idx_profiles_id_email IS 'Index for profiles table joins with auth.users';
COMMENT ON INDEX idx_user_settings_not_re_engaged IS 'Partial index for users not yet sent re-engagement emails';
COMMENT ON INDEX idx_user_settings_not_3day_followup IS 'Partial index for users not yet sent 3-day follow-up emails';
