-- DANGER: Explicitly grant SELECT permission to the authenticated role for core tables. 
-- This bypasses the blanket REVOKE and is necessary to make the app functional.
GRANT SELECT ON public.profiles TO authenticated;
GRANT SELECT ON public.dogs TO authenticated;
GRANT SELECT ON public.availability TO authenticated;
GRANT SELECT ON public.user_activity TO authenticated; -- ADDED FIX FOR CURRENT ERROR

-- Now, ensure RLS is correctly enforcing public access to community data.

-- PROFILES RLS Fix (Allows reading of ALL profiles for the community)
DROP POLICY IF EXISTS "Allow authenticated users to read all profiles" ON profiles;
CREATE POLICY "Allow authenticated users to read all profiles" ON profiles
  FOR SELECT TO authenticated USING (TRUE);

-- DOGS RLS Fix (Allows reading of ALL dogs for matchmaking/community view)
DROP POLICY IF EXISTS "Allow authenticated users to read all dogs" ON dogs;
CREATE POLICY "Allow authenticated users to read all dogs" ON dogs
  FOR SELECT TO authenticated USING (TRUE);

-- AVAILABILITY RLS Fix (Allows reading of active availability posts)
DROP POLICY IF EXISTS "Allow authenticated users to read active availability" ON availability;
CREATE POLICY "Allow authenticated users to read active availability" ON availability
  FOR SELECT TO authenticated USING (status = 'active');

-- Add RLS for User Activity (If users should only see their own activity, use this)
DROP POLICY IF EXISTS "Users can view their own activity" ON user_activity;
CREATE POLICY "Users can view their own activity" ON user_activity
  FOR SELECT TO authenticated USING (auth.uid() = user_id);
