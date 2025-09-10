-- Enable Row Level Security on all user data tables

-- Enable RLS on profiles table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access their own profile
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Enable RLS on log_entries table
ALTER TABLE log_entries ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access their own log entries
CREATE POLICY "Users can view own log entries" ON log_entries
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own log entries" ON log_entries
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own log entries" ON log_entries
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own log entries" ON log_entries
  FOR DELETE USING (auth.uid() = user_id);

-- Enable RLS on peak_flow_readings table
ALTER TABLE peak_flow_readings ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access peak flow readings from their own log entries
CREATE POLICY "Users can view own peak flow readings" ON peak_flow_readings
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM log_entries 
      WHERE log_entries.id = peak_flow_readings.log_entry_id 
      AND log_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create own peak flow readings" ON peak_flow_readings
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM log_entries 
      WHERE log_entries.id = peak_flow_readings.log_entry_id 
      AND log_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own peak flow readings" ON peak_flow_readings
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM log_entries 
      WHERE log_entries.id = peak_flow_readings.log_entry_id 
      AND log_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own peak flow readings" ON peak_flow_readings
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM log_entries 
      WHERE log_entries.id = peak_flow_readings.log_entry_id 
      AND log_entries.user_id = auth.uid()
    )
  );

-- Enable RLS on log_symptoms table
ALTER TABLE log_symptoms ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access symptoms from their own log entries
CREATE POLICY "Users can view own log symptoms" ON log_symptoms
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM log_entries 
      WHERE log_entries.id = log_symptoms.log_entry_id 
      AND log_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create own log symptoms" ON log_symptoms
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM log_entries 
      WHERE log_entries.id = log_symptoms.log_entry_id 
      AND log_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own log symptoms" ON log_symptoms
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM log_entries 
      WHERE log_entries.id = log_symptoms.log_entry_id 
      AND log_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own log symptoms" ON log_symptoms
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM log_entries 
      WHERE log_entries.id = log_symptoms.log_entry_id 
      AND log_entries.user_id = auth.uid()
    )
  );

-- Enable RLS on user_medications table
ALTER TABLE user_medications ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access their own medications
CREATE POLICY "Users can view own medications" ON user_medications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own medications" ON user_medications
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own medications" ON user_medications
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own medications" ON user_medications
  FOR DELETE USING (auth.uid() = user_id);

-- Enable RLS on log_medications table
ALTER TABLE log_medications ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access medication logs from their own log entries
CREATE POLICY "Users can view own log medications" ON log_medications
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM log_entries 
      WHERE log_entries.id = log_medications.log_entry_id 
      AND log_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create own log medications" ON log_medications
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM log_entries 
      WHERE log_entries.id = log_medications.log_entry_id 
      AND log_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own log medications" ON log_medications
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM log_entries 
      WHERE log_entries.id = log_medications.log_entry_id 
      AND log_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own log medications" ON log_medications
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM log_entries 
      WHERE log_entries.id = log_medications.log_entry_id 
      AND log_entries.user_id = auth.uid()
    )
  );

-- Enable RLS on log_triggers table
ALTER TABLE log_triggers ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access trigger logs from their own log entries
CREATE POLICY "Users can view own log triggers" ON log_triggers
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM log_entries 
      WHERE log_entries.id = log_triggers.log_entry_id 
      AND log_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create own log triggers" ON log_triggers
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM log_entries 
      WHERE log_entries.id = log_triggers.log_entry_id 
      AND log_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own log triggers" ON log_triggers
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM log_entries 
      WHERE log_entries.id = log_triggers.log_entry_id 
      AND log_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own log triggers" ON log_triggers
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM log_entries 
      WHERE log_entries.id = log_triggers.log_entry_id 
      AND log_entries.user_id = auth.uid()
    )
  );

-- Enable RLS on action_plans table
ALTER TABLE action_plans ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access their own action plan
CREATE POLICY "Users can view own action plan" ON action_plans
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own action plan" ON action_plans
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own action plan" ON action_plans
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own action plan" ON action_plans
  FOR DELETE USING (auth.uid() = user_id);

-- Reference tables (symptoms, triggers) are public read-only
-- No RLS needed as they contain no user-specific data

-- Policy: Allow read access to symptoms for authenticated users
ALTER TABLE symptoms ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can view symptoms" ON symptoms
  FOR SELECT USING (auth.role() = 'authenticated');

-- Policy: Allow read access to triggers for authenticated users
ALTER TABLE triggers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can view triggers" ON triggers
  FOR SELECT USING (auth.role() = 'authenticated');

-- Create indexes for better performance with RLS
CREATE INDEX IF NOT EXISTS idx_log_entries_user_id ON log_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_user_medications_user_id ON user_medications(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_id ON profiles(id);
CREATE INDEX IF NOT EXISTS idx_log_entries_logged_at ON log_entries(logged_at);
CREATE INDEX IF NOT EXISTS idx_peak_flow_readings_log_entry_id ON peak_flow_readings(log_entry_id);