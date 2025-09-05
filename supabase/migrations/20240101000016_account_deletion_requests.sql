-- Create account_deletion_requests table
CREATE TABLE IF NOT EXISTS account_deletion_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  scheduled_deletion_date TIMESTAMP WITH TIME ZONE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'cancelled', 'processing', 'completed')) NOT NULL,
  reason TEXT,
  admin_notes TEXT,
  processed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure only one active deletion request per user
  CONSTRAINT unique_active_deletion_request UNIQUE (user_id, status) DEFERRABLE INITIALLY DEFERRED
);

-- Add index for efficient queries
CREATE INDEX IF NOT EXISTS idx_account_deletion_requests_user_id ON account_deletion_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_account_deletion_requests_status ON account_deletion_requests(status);
CREATE INDEX IF NOT EXISTS idx_account_deletion_requests_scheduled_date ON account_deletion_requests(scheduled_deletion_date);
CREATE INDEX IF NOT EXISTS idx_account_deletion_requests_requested_at ON account_deletion_requests(requested_at);

-- Enable Row Level Security
ALTER TABLE account_deletion_requests ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own deletion requests" ON account_deletion_requests
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own deletion requests" ON account_deletion_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own pending deletion requests" ON account_deletion_requests
  FOR UPDATE USING (auth.uid() = user_id AND status = 'pending');

-- Create function to automatically set scheduled_deletion_date to 30 days from now
CREATE OR REPLACE FUNCTION set_deletion_schedule_date()
RETURNS TRIGGER AS $$
BEGIN
  -- Set scheduled deletion date to 30 days from now
  NEW.scheduled_deletion_date = NOW() + INTERVAL '30 days';
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically set scheduled deletion date
CREATE OR REPLACE TRIGGER on_deletion_request_insert
  BEFORE INSERT ON account_deletion_requests
  FOR EACH ROW EXECUTE FUNCTION set_deletion_schedule_date();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_deletion_request_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE OR REPLACE TRIGGER on_deletion_request_update
  BEFORE UPDATE ON account_deletion_requests
  FOR EACH ROW EXECUTE FUNCTION update_deletion_request_updated_at();

-- Create function to get deletion request status for a user
CREATE OR REPLACE FUNCTION get_user_deletion_status(user_id UUID)
RETURNS TABLE (
  has_pending_request BOOLEAN,
  scheduled_deletion_date TIMESTAMP WITH TIME ZONE,
  days_remaining INTEGER,
  status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    CASE WHEN adr.id IS NOT NULL THEN true ELSE false END as has_pending_request,
    adr.scheduled_deletion_date,
    CASE 
      WHEN adr.scheduled_deletion_date IS NOT NULL 
      THEN EXTRACT(DAY FROM (adr.scheduled_deletion_date - NOW()))::INTEGER
      ELSE NULL 
    END as days_remaining,
    adr.status
  FROM account_deletion_requests adr
  WHERE adr.user_id = $1 
    AND adr.status IN ('pending', 'processing')
  ORDER BY adr.created_at DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;
