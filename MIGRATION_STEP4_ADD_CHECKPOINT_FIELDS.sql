-- ============================================
-- SUPABASE DATABASE MIGRATION
-- Add checkpoint/counter fields to tasks table
-- Run this on Supabase when ready to enable full Step-4 features
-- ============================================

-- Add new columns to tasks table
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS current_count INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE;

-- Add constraints to ensure data integrity
ALTER TABLE tasks 
ADD CONSTRAINT tasks_current_count_non_negative CHECK (current_count >= 0),
ADD CONSTRAINT tasks_current_count_not_exceed_target CHECK (current_count <= target_count);

-- Create index for faster queries on completion status
CREATE INDEX IF NOT EXISTS idx_tasks_is_completed ON tasks(is_completed);
CREATE INDEX IF NOT EXISTS idx_tasks_completed_at ON tasks(completed_at);

-- ============================================
-- ROLLBACK (if needed)
-- ============================================
-- ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_current_count_non_negative;
-- ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_current_count_not_exceed_target;
-- DROP INDEX IF EXISTS idx_tasks_is_completed;
-- DROP INDEX IF EXISTS idx_tasks_completed_at;
-- ALTER TABLE tasks DROP COLUMN IF EXISTS completed_at;
-- ALTER TABLE tasks DROP COLUMN IF EXISTS is_completed;
-- ALTER TABLE tasks DROP COLUMN IF EXISTS current_count;
