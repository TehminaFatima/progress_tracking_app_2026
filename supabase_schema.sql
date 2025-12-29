-- ============================================
-- SUPABASE DATABASE SCHEMA
-- Progress_Tracking_App 2026 - Categories Table
-- ============================================

-- Create categories table
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT categories_name_not_empty CHECK (char_length(trim(name)) >= 2),
    CONSTRAINT categories_unique_user_name UNIQUE (user_id, name)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_categories_user_id ON categories(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_created_at ON categories(created_at);

-- Enable Row Level Security (RLS)
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only see their own categories
CREATE POLICY "Users can view own categories"
    ON categories FOR SELECT
    USING (auth.uid() = user_id);

-- RLS Policy: Users can insert their own categories
CREATE POLICY "Users can insert own categories"
    ON categories FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can update their own categories
CREATE POLICY "Users can update own categories"
    ON categories FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can delete their own categories
CREATE POLICY "Users can delete own categories"
    ON categories FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- EXAMPLE QUERIES
-- ============================================

-- Insert a sample category
-- INSERT INTO categories (user_id, name)
-- VALUES (
--     'your-user-id-here',
--     'Self-Care'
-- );

-- Fetch all categories for a user
-- SELECT * FROM categories 
-- WHERE user_id = 'your-user-id-here'
-- ORDER BY created_at ASC;

-- Update a category
-- UPDATE categories 
-- SET name = 'Updated Name',
--     updated_at = NOW()
-- WHERE id = 'category-id-here' 
-- AND user_id = 'your-user-id-here';

-- Delete a category
-- DELETE FROM categories 
-- WHERE id = 'category-id-here' 
-- AND user_id = 'your-user-id-here';

-- ============================================
-- NOTES
-- ============================================
-- 1. All categories are user-scoped via RLS
-- 2. ON DELETE CASCADE ensures orphaned data cleanup
-- 3. Category names must be unique per user
-- 4. All categories display the default category icon (Icons.category)
-- 5. All categories use the app theme (primary color) for styling

-- ============================================
-- CHALLENGES TABLE (STEP 3)
-- ============================================

-- Create challenges table
CREATE TABLE IF NOT EXISTS challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    type TEXT CHECK (type IN ('daily','weekly','monthly','yearly','custom')),
    start_date DATE,
    end_date DATE,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_challenges_user_id ON challenges(user_id);
CREATE INDEX IF NOT EXISTS idx_challenges_category_id ON challenges(category_id);
CREATE INDEX IF NOT EXISTS idx_challenges_created_at ON challenges(created_at);

-- Enable Row Level Security (RLS)
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;

-- Single policy covering all operations scoped to user
CREATE POLICY "User own challenges only"
    ON challenges FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- EXAMPLE QUERIES (CHALLENGES)
-- ============================================

-- Insert a sample challenge
-- INSERT INTO challenges (user_id, category_id, title, type, start_date, end_date)
-- VALUES (
--   'your-user-id-here',
--   'your-category-id-here',
--   '30-Day Deen Revival',
--   'daily',
--   '2026-01-01',
--   '2026-01-30'
-- );

-- Fetch all challenges for a category
-- SELECT * FROM challenges
-- WHERE user_id = 'your-user-id-here'
--   AND category_id = 'your-category-id-here'
-- ORDER BY created_at DESC;

-- Update a challenge
-- UPDATE challenges
-- SET title = 'Updated Title', type = 'weekly', start_date = '2026-02-01', end_date = '2026-03-01'
-- WHERE id = 'challenge-id-here' AND user_id = 'your-user-id-here';

-- Delete a challenge
-- DELETE FROM challenges WHERE id = 'challenge-id-here' AND user_id = 'your-user-id-here';

-- ============================================
-- TASKS TABLE (STEP 4)
-- ============================================

-- Create tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    target_count INT DEFAULT 1,
    current_count INT DEFAULT 0,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT tasks_name_not_empty CHECK (char_length(trim(name)) >= 2),
    CONSTRAINT tasks_target_count_positive CHECK (target_count > 0),
    CONSTRAINT tasks_current_count_non_negative CHECK (current_count >= 0),
    CONSTRAINT tasks_current_count_not_exceed_target CHECK (current_count <= target_count)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_tasks_challenge_id ON tasks(challenge_id);
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at);

-- Enable Row Level Security (RLS)
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access tasks in their own challenges
CREATE POLICY "User own tasks only"
    ON tasks FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM challenges
            WHERE challenges.id = tasks.challenge_id
            AND challenges.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM challenges
            WHERE challenges.id = tasks.challenge_id
            AND challenges.user_id = auth.uid()
        )
    );

-- ============================================
-- EXAMPLE QUERIES (TASKS)
-- ============================================

-- Insert a sample task
-- INSERT INTO tasks (challenge_id, name, target_count)
-- VALUES (
--   'your-challenge-id-here',
--   'Morning Prayer',
--   5
-- );

-- Fetch all tasks for a challenge
-- SELECT * FROM tasks
-- WHERE challenge_id = 'your-challenge-id-here'
-- ORDER BY created_at DESC;

-- Update task progress (increment counter)
-- UPDATE tasks
-- SET current_count = current_count + 1
-- WHERE id = 'task-id-here'
-- AND current_count < target_count;

-- Toggle task completion (for single-count tasks)
-- UPDATE tasks
-- SET is_completed = NOT is_completed,
--     completed_at = CASE WHEN is_completed THEN NULL ELSE NOW() END
-- WHERE id = 'task-id-here';

-- Mark task as completed
-- UPDATE tasks
-- SET is_completed = true, completed_at = NOW()
-- WHERE id = 'task-id-here';

-- Reset task progress
-- UPDATE tasks
-- SET current_count = 0, is_completed = false, completed_at = NULL
-- WHERE id = 'task-id-here';

-- Get task completion percentage
-- SELECT id, name, current_count, target_count, 
--        ROUND((current_count::DECIMAL / target_count) * 100, 2) as percentage
-- FROM tasks
-- WHERE challenge_id = 'your-challenge-id-here';

-- Delete a task
-- DELETE FROM tasks WHERE id = 'task-id-here';
