-- Migration: Push Notification System Tables
-- Run this in Supabase SQL Editor

-- 1. Push Subscriptions - Store the "phone number" to contact users
CREATE TABLE IF NOT EXISTS public.notification_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users ON DELETE CASCADE,
  endpoint TEXT NOT NULL,
  p256dh TEXT NOT NULL,
  auth TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  last_used_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(endpoint)
);

-- 2. User Notification Preferences
CREATE TABLE IF NOT EXISTS public.notification_settings (
  user_id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  prayer_start BOOLEAN DEFAULT true,
  prayer_ending BOOLEAN DEFAULT true,
  dua_reminders BOOLEAN DEFAULT true,
  timezone TEXT DEFAULT 'UTC',
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Notification Delivery Logs (for debugging and analytics)
CREATE TABLE IF NOT EXISTS public.notification_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users ON DELETE SET NULL,
  notification_type TEXT NOT NULL, -- 'prayer_start', 'prayer_ending', 'dua_morning', etc.
  prayer_name TEXT, -- 'Fajr', 'Dhuhr', etc.
  message TEXT NOT NULL,
  delivered BOOLEAN DEFAULT false,
  error TEXT,
  sent_at TIMESTAMPTZ DEFAULT now()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON notification_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_active ON notification_subscriptions(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_logs_user ON notification_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_logs_sent_at ON notification_logs(sent_at);

-- Enable RLS
ALTER TABLE notification_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for subscriptions
CREATE POLICY "Users can view own subscriptions"
  ON notification_subscriptions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscriptions"
  ON notification_subscriptions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own subscriptions"
  ON notification_subscriptions FOR DELETE
  USING (auth.uid() = user_id);

-- RLS Policies for settings
CREATE POLICY "Users can view own settings"
  ON notification_settings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own settings"
  ON notification_settings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own settings"
  ON notification_settings FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS Policies for logs (users can view their own)
CREATE POLICY "Users can view own logs"
  ON notification_logs FOR SELECT
  USING (auth.uid() = user_id);

-- Service role can do everything (for Edge Functions)
CREATE POLICY "Service role full access subscriptions"
  ON notification_subscriptions FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "Service role full access settings"
  ON notification_settings FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY "Service role full access logs"
  ON notification_logs FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role');
