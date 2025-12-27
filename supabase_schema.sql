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
