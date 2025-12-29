-- MEEK Flutter App - Complete Database Setup
-- For fresh Supabase project

-- =============================================
-- 1. PROFILES TABLE
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
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles viewable" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- =============================================
-- 2. QURAN PROGRESS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.quran_verse_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  surah INT NOT NULL,
  ayah INT NOT NULL,
  status TEXT DEFAULT 'in_progress',
  best_score INT DEFAULT 0,
  attempts INT DEFAULT 0,
  last_practice_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, surah, ayah)
);

ALTER TABLE public.quran_verse_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "View own progress" ON quran_verse_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Insert own progress" ON quran_verse_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Update own progress" ON quran_verse_progress FOR UPDATE USING (auth.uid() = user_id);

-- =============================================
-- 3. PRACTICE SESSIONS TABLE
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

ALTER TABLE public.quran_practice_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "View own sessions" ON quran_practice_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Insert own sessions" ON quran_practice_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- =============================================
-- 4. FIQH QUESTIONS TABLE
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

ALTER TABLE public.fiqh_questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "View own questions" ON fiqh_questions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Insert own questions" ON fiqh_questions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Update own questions" ON fiqh_questions FOR UPDATE USING (auth.uid() = user_id);

-- =============================================
-- 5. USER STREAKS TABLE
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

ALTER TABLE public.user_streaks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "View own streaks" ON user_streaks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Insert own streaks" ON user_streaks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Update own streaks" ON user_streaks FOR UPDATE USING (auth.uid() = user_id);

-- =============================================
-- 6. AUTO-CREATE PROFILE ON SIGNUP
-- =============================================
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url, email, madhab)
  VALUES (
    NEW.id, 
    NEW.raw_user_meta_data->>'full_name', 
    NEW.raw_user_meta_data->>'avatar_url',
    NEW.email,
    'Hanafi'
  )
  ON CONFLICT (id) DO NOTHING;
  
  INSERT INTO public.user_streaks (user_id) VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================
-- 7. INDEXES
-- =============================================
CREATE INDEX IF NOT EXISTS idx_progress_user ON quran_verse_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON quran_practice_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_fiqh_user ON fiqh_questions(user_id);

-- DONE! All tables created.
