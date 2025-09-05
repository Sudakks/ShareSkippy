-- Fix review role constraints to use owner/walker instead of requester/recipient
-- This migration fixes the constraint mismatch between database schema and API code

-- Drop the existing constraint that uses requester/recipient
ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_reviewed_role_check;

-- Add the correct constraint that uses owner/walker
ALTER TABLE reviews ADD CONSTRAINT reviews_reviewed_role_check 
CHECK (reviewed_role = ANY (ARRAY['owner'::text, 'walker'::text]));

-- Also ensure reviewer_role constraint is correct
ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_reviewer_role_check;
ALTER TABLE reviews ADD CONSTRAINT reviews_reviewer_role_check 
CHECK (reviewer_role = ANY (ARRAY['owner'::text, 'walker'::text]));

-- Update any existing records that might have invalid values
-- This is a best-effort mapping - adjust based on your actual data
UPDATE reviews SET 
    reviewer_role = CASE 
        WHEN reviewer_role = 'requester' THEN 'owner'
        WHEN reviewer_role = 'recipient' THEN 'walker'
        ELSE reviewer_role
    END,
    reviewed_role = CASE 
        WHEN reviewed_role = 'requester' THEN 'walker'
        WHEN reviewed_role = 'recipient' THEN 'owner'
        ELSE reviewed_role
    END
WHERE reviewer_role IN ('requester', 'recipient') 
   OR reviewed_role IN ('requester', 'recipient');

-- Verify the migration
SELECT 
    'Review role constraints fixed successfully' as status,
    COUNT(*) as total_reviews,
    COUNT(CASE WHEN reviewer_role IN ('owner', 'walker') THEN 1 END) as valid_reviewer_roles,
    COUNT(CASE WHEN reviewed_role IN ('owner', 'walker') THEN 1 END) as valid_reviewed_roles
FROM reviews;
