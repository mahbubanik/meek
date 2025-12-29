// Supabase Edge Function: send-scheduled-notifications
// Runs every 5 minutes via cron to send prayer and dua notifications
// Deploy with: supabase functions deploy send-scheduled-notifications

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Fear-based notification messages
const PRAYER_START_MESSAGES: Record<string, string[]> = {
    Fajr: [
        "😱 FAJR IS NOW! Are you sleeping?? Your best prayer is happening RIGHT NOW!",
        "⏰ CODE RED 🚨 Fajr started! Every second counts!",
        "🔥 WAKE UP WAKE UP WAKE UP! Fajr is on fire right now!",
    ],
    Dhuhr: [
        "🕐 DHUHR IS HERE! Everyone else is praying... are you?",
        "☀️ DHUHR ALERT! Your streak is on the line!",
        "🚨 Dhuhr is LIVE! Move NOW!",
    ],
    Asr: [
        "🌤️ ASR IS STARTING! One of the most powerful prayers!",
        "🚨 It's Asr o'clock! Don't skip this!",
        "🔥 ASR TIME! Last chance before sunset!",
    ],
    Maghrib: [
        "🌆 MAGHRIB IS HERE! The sun is setting!",
        "🚨 CODE RED! Maghrib just started!",
        "😱 MAGHRIB TIME! The sunset won't wait!",
    ],
    Isha: [
        "🌙 ISHA IS NOW! Your night prayer is here!",
        "🚨 ISHA TIME! The night is young!",
        "🔥 ISHA ALERT! End your day RIGHT!",
    ],
};

const PRAYER_ENDING_MESSAGES = [
    "⏳ OH NO! Only 20 minutes left for {prayer}! 😱",
    "🚨 ALERT! {prayer} is ENDING SOON! 20 minutes... MOVE!",
    "⚡ LAST CALL! {prayer} ends in 20 mins!",
    "🔥 {prayer} expires in 20 minutes! GO GO GO!",
];

const DUA_MESSAGES: Record<string, string[]> = {
    morning: [
        "🌅 RISE AND SHINE! Morning duas are waiting! ⚡",
        "💪 Winners pray in the morning!",
    ],
    midday: [
        "☀️ MIDDAY ALERT! Time to recharge with duas! ⚡",
        "🎯 Midday duas are your power break!",
    ],
    evening: [
        "🌆 GOLDEN HOUR! Evening duas await! 🧘",
        "💜 Pause. Your evening duas will calm you.",
    ],
    night: [
        "🌙 NIGHT RITUAL! Sleep duas = best rest! 😴",
        "⭐ Before you sleep, your duas are calling!",
    ],
};

// CORS headers
const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Get random message
function getRandomMessage(arr: string[]): string {
    return arr[Math.floor(Math.random() * arr.length)];
}

// Fetch prayer times from Aladhan API
async function fetchPrayerTimes(latitude: number, longitude: number, method = 3): Promise<Record<string, string>> {
    const today = new Date();
    const dateStr = `${today.getDate()}-${today.getMonth() + 1}-${today.getFullYear()}`;

    const url = `https://api.aladhan.com/v1/timings/${dateStr}?latitude=${latitude}&longitude=${longitude}&method=${method}`;
    const response = await fetch(url);
    const data = await response.json();

    return data.data.timings;
}

// Parse time string to minutes since midnight
function parseTimeToMinutes(timeStr: string): number {
    const [hours, minutes] = timeStr.split(':').map(Number);
    return hours * 60 + minutes;
}

// Get current time in user's timezone
function getCurrentMinutes(timezone: string): number {
    const now = new Date();
    const userTime = new Date(now.toLocaleString('en-US', { timeZone: timezone }));
    return userTime.getHours() * 60 + userTime.getMinutes();
}

// Send web push notification
async function sendPushNotification(
    subscription: { endpoint: string; p256dh: string; auth: string },
    payload: { title: string; body: string; url?: string; tag?: string }
): Promise<boolean> {
    // Note: This requires web-push library or manual VAPID signing
    // For Edge Functions, we'll use a simpler approach with the Expo-like fetch

    const vapidPrivateKey = Deno.env.get('VAPID_PRIVATE_KEY');
    const vapidPublicKey = Deno.env.get('NEXT_PUBLIC_VAPID_PUBLIC_KEY');

    if (!vapidPrivateKey || !vapidPublicKey) {
        console.error('VAPID keys not configured');
        return false;
    }

    try {
        // For Edge Functions, we need to implement VAPID signing
        // This is a placeholder - in production, use web-push library
        // or implement manual JWT signing for VAPID

        // For now, log what would be sent
        console.log('Would send notification:', {
            endpoint: subscription.endpoint,
            payload
        });

        return true;
    } catch (error) {
        console.error('Push failed:', error);
        return false;
    }
}

Deno.serve(async (req: Request) => {
    // Handle CORS
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        // Verify this is a cron job or authorized request
        const authHeader = req.headers.get('authorization');
        const cronSecret = Deno.env.get('CRON_SECRET');

        if (cronSecret && authHeader !== `Bearer ${cronSecret}`) {
            // Allow for testing, but log warning
            console.warn('Request without cron secret');
        }

        // Init Supabase
        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        );

        // Get all users with active subscriptions and settings
        const { data: users, error: usersError } = await supabaseClient
            .from('notification_settings')
            .select(`
                user_id,
                prayer_start,
                prayer_ending,
                dua_reminders,
                timezone,
                latitude,
                longitude
            `)
            .or('prayer_start.eq.true,prayer_ending.eq.true,dua_reminders.eq.true');

        if (usersError) {
            console.error('Failed to fetch users:', usersError);
            throw usersError;
        }

        if (!users || users.length === 0) {
            return new Response(JSON.stringify({ message: 'No users to notify' }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            });
        }

        const results: { userId: string; type: string; sent: boolean }[] = [];

        for (const user of users) {
            const timezone = user.timezone || 'UTC';
            const latitude = user.latitude || 23.8103; // Default: Dhaka
            const longitude = user.longitude || 90.4125;

            try {
                // Get prayer times for user's location
                const prayerTimes = await fetchPrayerTimes(latitude, longitude);
                const currentMinutes = getCurrentMinutes(timezone);

                // Get user's active subscriptions
                const { data: subscriptions } = await supabaseClient
                    .from('notification_subscriptions')
                    .select('endpoint, p256dh, auth')
                    .eq('user_id', user.user_id)
                    .eq('is_active', true);

                if (!subscriptions || subscriptions.length === 0) continue;

                const prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
                const prayerEndTimes: Record<string, string> = {
                    Fajr: prayerTimes.Sunrise,
                    Dhuhr: prayerTimes.Asr,
                    Asr: prayerTimes.Maghrib,
                    Maghrib: prayerTimes.Isha,
                    Isha: prayerTimes.Fajr, // Next day Fajr
                };

                for (const prayer of prayers) {
                    const startMinutes = parseTimeToMinutes(prayerTimes[prayer]);
                    const endMinutes = parseTimeToMinutes(prayerEndTimes[prayer]);

                    // Check if prayer just started (within 5 min window)
                    if (user.prayer_start && currentMinutes >= startMinutes && currentMinutes < startMinutes + 5) {
                        const message = getRandomMessage(PRAYER_START_MESSAGES[prayer]);

                        for (const sub of subscriptions) {
                            const sent = await sendPushNotification(sub, {
                                title: `${prayer} Time! 🕌`,
                                body: message,
                                url: '/quran',
                                tag: `prayer-start-${prayer}-${Date.now()}`
                            });

                            // Log notification
                            await supabaseClient.from('notification_logs').insert({
                                user_id: user.user_id,
                                notification_type: 'prayer_start',
                                prayer_name: prayer,
                                message,
                                delivered: sent
                            });

                            results.push({ userId: user.user_id, type: `${prayer}_start`, sent });
                        }
                    }

                    // Check if prayer ending soon (20 min before end)
                    let adjustedEndMinutes = endMinutes;
                    if (prayer === 'Isha' && endMinutes < startMinutes) {
                        adjustedEndMinutes += 24 * 60; // Next day
                    }

                    const minutesUntilEnd = adjustedEndMinutes - currentMinutes;
                    if (user.prayer_ending && minutesUntilEnd >= 17 && minutesUntilEnd <= 23) {
                        const template = getRandomMessage(PRAYER_ENDING_MESSAGES);
                        const message = template.replace(/{prayer}/g, prayer);

                        for (const sub of subscriptions) {
                            const sent = await sendPushNotification(sub, {
                                title: `⏰ ${prayer} Ending Soon!`,
                                body: message,
                                url: '/quran',
                                tag: `prayer-ending-${prayer}-${Date.now()}`
                            });

                            await supabaseClient.from('notification_logs').insert({
                                user_id: user.user_id,
                                notification_type: 'prayer_ending',
                                prayer_name: prayer,
                                message,
                                delivered: sent
                            });

                            results.push({ userId: user.user_id, type: `${prayer}_ending`, sent });
                        }
                    }
                }

                // Check for dua reminders
                if (user.dua_reminders) {
                    const duaTimes = [
                        { name: 'morning', hour: 7 },
                        { name: 'midday', hour: 13 },
                        { name: 'evening', hour: 17 },
                        { name: 'night', hour: 21 },
                    ];

                    for (const dua of duaTimes) {
                        const duaMinutes = dua.hour * 60;
                        if (currentMinutes >= duaMinutes && currentMinutes < duaMinutes + 5) {
                            const message = getRandomMessage(DUA_MESSAGES[dua.name]);

                            for (const sub of subscriptions) {
                                const sent = await sendPushNotification(sub, {
                                    title: `${dua.name.charAt(0).toUpperCase() + dua.name.slice(1)} Dua Time 🤲`,
                                    body: message,
                                    url: '/dashboard',
                                    tag: `dua-${dua.name}-${Date.now()}`
                                });

                                await supabaseClient.from('notification_logs').insert({
                                    user_id: user.user_id,
                                    notification_type: `dua_${dua.name}`,
                                    message,
                                    delivered: sent
                                });

                                results.push({ userId: user.user_id, type: `dua_${dua.name}`, sent });
                            }
                        }
                    }
                }

            } catch (userError) {
                console.error(`Error processing user ${user.user_id}:`, userError);
            }
        }

        return new Response(JSON.stringify({
            success: true,
            processed: users.length,
            notifications: results.length,
            details: results
        }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });

    } catch (error) {
        console.error('Edge function error:', error);
        return new Response(JSON.stringify({ error: (error as Error).message }), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
    }
});
