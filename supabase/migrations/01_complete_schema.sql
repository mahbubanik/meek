-- MEEK Flutter App - Complete Database Schema
-- Run this FIRST before other migrations
-- Execute in Supabase SQL Editor

-- =============================================
-- 1. PROFILES TABLE (Core user data)
-- =============================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
  username TEXT,
  full_name TEXT,
  email TEXT,
  avatar_url TEXT,
  madhab TEXT DEFAULT 'Hanafi',
  arabic_level TEXT DEFAULT 'beginner',
  onboarding_completed BOOLEAN DEFAULT false,
  notifications_enabled BOOLEAN DEFAULT true,
  expo_push_token TEXT,
  streak_count INT DEFAULT 0,
  last_active_at TIMESTAMPTZ DEFAULT now(),
  preferred_language TEXT DEFAULT 'English',
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS for profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone."
  ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile."
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile."
  ON profiles FOR UPDATE USING (auth.uid() = id);

-- =============================================
-- 2. QURAN VERSE PROGRESS (Tracking learning)
-- =============================================
CREATE TABLE IF NOT EXISTS public.quran_verse_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  surah INT NOT NULL,
  ayah INT NOT NULL,
  status TEXT DEFAULT 'in_progress', -- 'in_progress', 'completed', 'mastered'
  best_score INT DEFAULT 0,
  attempts INT DEFAULT 0,
  last_practice_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, surah, ayah)
);

-- RLS for quran progress
ALTER TABLE public.quran_verse_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own progress"
  ON quran_verse_progress FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress"
  ON quran_verse_progress FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own progress"
  ON quran_verse_progress FOR UPDATE USING (auth.uid() = user_id);

-- Index for fast progress queries
CREATE INDEX IF NOT EXISTS idx_quran_progress_user ON quran_verse_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_quran_progress_surah ON quran_verse_progress(surah, ayah);

-- =============================================
-- 3. QURAN PRACTICE SESSIONS (Detailed records)
-- =============================================
CREATE TABLE IF NOT EXISTS public.quran_practice_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  surah INT NOT NULL,
  ayah INT NOT NULL,
  score INT,
  duration_seconds INT,
  feedback_positives TEXT[],
  feedback_improvements TEXT[],
  feedback_details TEXT,
  audio_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE public.quran_practice_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own sessions"
  ON quran_practice_sessions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions"
  ON quran_practice_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Index
CREATE INDEX IF NOT EXISTS idx_practice_user ON quran_practice_sessions(user_id);

-- =============================================
-- 4. FIQH QUESTIONS (Q&A History)
-- =============================================
CREATE TABLE IF NOT EXISTS public.fiqh_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  question TEXT NOT NULL,
  answer TEXT,
  madhab TEXT DEFAULT 'Hanafi',
  sources TEXT[],
  helpful BOOLEAN,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE public.fiqh_questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own questions"
  ON fiqh_questions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own questions"
  ON fiqh_questions FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own questions"
  ON fiqh_questions FOR UPDATE USING (auth.uid() = user_id);

-- Index
CREATE INDEX IF NOT EXISTS idx_fiqh_user ON fiqh_questions(user_id);

-- =============================================
-- 5. USER STREAKS (Gamification)
-- =============================================
CREATE TABLE IF NOT EXISTS public.user_streaks (
  user_id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  current_streak INT DEFAULT 0,
  longest_streak INT DEFAULT 0,
  last_practice_date DATE,
  total_practice_days INT DEFAULT 0,
  total_verses_completed INT DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE public.user_streaks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own streaks"
  ON user_streaks FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can upsert own streaks"
  ON user_streaks FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own streaks"
  ON user_streaks FOR UPDATE USING (auth.uid() = user_id);

-- =============================================
-- 6. AUTO-CREATE PROFILE ON SIGNUP (Trigger)
-- =============================================
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url, email, onboarding_completed, madhab)
  VALUES (
    NEW.id, 
    NEW.raw_user_meta_data->>'full_name', 
    NEW.raw_user_meta_data->>'avatar_url',
    NEW.email,
    false,
    'Hanafi'
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = COALESCE(profiles.full_name, EXCLUDED.full_name);
  
  -- Also create initial streak record
  INSERT INTO public.user_streaks (user_id) VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================
-- 7. UPDATE STREAK FUNCTION
-- =============================================
CREATE OR REPLACE FUNCTION public.update_user_streak(p_user_id UUID)
RETURNS void AS $$
DECLARE
  v_last_date DATE;
  v_today DATE := CURRENT_DATE;
BEGIN
  SELECT last_practice_date INTO v_last_date
  FROM user_streaks WHERE user_id = p_user_id;
  
  IF v_last_date IS NULL THEN
    -- First ever practice
    UPDATE user_streaks SET
      current_streak = 1,
      longest_streak = 1,
      last_practice_date = v_today,
      total_practice_days = 1
    WHERE user_id = p_user_id;
  ELSIF v_last_date = v_today THEN
    -- Already practiced today, no change
    NULL;
  ELSIF v_last_date = v_today - 1 THEN
    -- Consecutive day
    UPDATE user_streaks SET
      current_streak = current_streak + 1,
      longest_streak = GREATEST(longest_streak, current_streak + 1),
      last_practice_date = v_today,
      total_practice_days = total_practice_days + 1
    WHERE user_id = p_user_id;
  ELSE
    -- Streak broken
    UPDATE user_streaks SET
      current_streak = 1,
      last_practice_date = v_today,
      total_practice_days = total_practice_days + 1
    WHERE user_id = p_user_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
