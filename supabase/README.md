# MEEK Flutter App - Supabase Setup

## Quick Start

1. **Run the migrations in order:**
   - Go to Supabase Dashboard → SQL Editor
   - Execute each file in `migrations/` folder in numerical order:
     1. `01_complete_schema.sql` - Core tables and triggers
     2. `02_push_notifications.sql` - Push notification fields
     3. `03_notifications.sql` - Notification system tables
     4. `04_auth_profile_triggers.sql` - Auth triggers update

2. **Deploy Edge Functions:**
   ```bash
   supabase login
   supabase link --project-ref lwqajokojdrktzkptzrt
   supabase functions deploy send-daily-nudge
   supabase functions deploy send-scheduled-notifications
   ```

3. **Set Edge Function Secrets:**
   ```bash
   supabase secrets set OPENAI_API_KEY=your_key
   supabase secrets set VAPID_PRIVATE_KEY=your_key
   supabase secrets set NEXT_PUBLIC_VAPID_PUBLIC_KEY=your_key
   supabase secrets set CRON_SECRET=your_cron_secret
   ```

## Database Tables

| Table | Purpose |
|-------|---------|
| `profiles` | User profiles, madhab, onboarding |
| `quran_verse_progress` | Per-verse learning progress |
| `quran_practice_sessions` | Detailed practice records |
| `fiqh_questions` | Q&A history |
| `user_streaks` | Gamification streaks |
| `notification_subscriptions` | Push notification tokens |
| `notification_settings` | User notification preferences |
| `notification_logs` | Delivery logs |

## Edge Functions

| Function | Schedule | Purpose |
|----------|----------|---------|
| `send-daily-nudge` | Manual/Cron | Reminder for inactive users |
| `send-scheduled-notifications` | Every 5 min | Prayer time alerts |
