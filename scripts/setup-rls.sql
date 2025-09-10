-- Setup script for Row Level Security
-- Run this against your Supabase database after creating the tables

-- This file can be run via Supabase dashboard > SQL Editor
-- or via psql command line

-- Note: Ensure your database has the auth schema and auth.uid() function available
-- This is automatically available in Supabase projects

\echo 'Setting up Row Level Security policies...'

-- Source the RLS migration
\i prisma/migrations/001_enable_rls.sql

\echo 'Row Level Security policies have been successfully applied!'
\echo 'All user data is now protected by RLS policies.'
\echo ''
\echo 'Summary of protections:'
\echo '- Users can only access their own profiles'
\echo '- Users can only access their own log entries and related data'
\echo '- Users can only access their own medications'
\echo '- Users can only access their own action plans'
\echo '- Reference data (symptoms, triggers) is read-only for authenticated users'
\echo ''
\echo 'Next steps:'
\echo '1. Test authentication flow'
\echo '2. Verify RLS policies work as expected'
\echo '3. Run seed data script if needed'