// Supabase Edge Function: send-daily-nudge
// Deploy with: supabase functions deploy send-daily-nudge

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { Configuration, OpenAIApi } from 'https://esm.sh/openai@3.2.1'

// CORS headers
const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
    // Handle CORS
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        // 1. Init Supabase Client
        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        // 2. Fetch Inactive Users (active < 24h ago)
        // Note: logic inverted? "Haven't been active in last 24h"
        // active < now - 24h
        const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

        const { data: users, error: dbError } = await supabaseClient
            .from('profiles')
            .select('username, streak_count, preferred_language, expo_push_token')
            .lt('last_active_at', twentyFourHoursAgo)
            .not('expo_push_token', 'is', null);

        if (dbError) throw dbError;

        if (!users || users.length === 0) {
            return new Response(JSON.stringify({ message: 'No inactive users found' }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
        }

        // 3. Init OpenAI
        const configuration = new Configuration({ apiKey: Deno.env.get('OPENAI_API_KEY') })
        const openai = new OpenAIApi(configuration)

        const results = [];

        // 4. Process each user
        for (const user of users) {
            if (!user.expo_push_token) continue;

            // Generate Message
            const prompt = `You are a persistent, slightly dramatic language coach. Your goal is to guilt-trip the user into doing their lesson. Keep it under 100 characters.
User Data: Name: ${user.username}, Streak: ${user.streak_count}, Language: ${user.preferred_language}.
Example Output: 'Hey ${user.username}, your ${user.streak_count} day streak looks lonely. ${user.preferred_language} won't learn itself! 🦉'`;

            let messageBody = `Time for your daily lesson!`; // Fallback

            try {
                const completion = await openai.createChatCompletion({
                    model: "gpt-4o-mini",
                    messages: [{ role: "system", content: prompt }],
                    max_tokens: 60,
                });
                messageBody = completion.data.choices[0].message?.content?.trim() || messageBody;
                // Remove quotes if present
                messageBody = messageBody.replace(/^"|"$/g, '');
            } catch (aiError) {
                console.error('AI Gen Error:', aiError);
            }

            // Send to Expo
            const expoMessage = {
                to: user.expo_push_token,
                sound: 'default',
                title: 'Meek Reminder 🔔',
                body: messageBody,
                data: { url: '/dashboard' },
            };

            const expoResponse = await fetch('https://exp.host/--/api/v2/push/send', {
                method: 'POST',
                headers: {
                    'Accept': 'application/json',
                    'Accept-encoding': 'gzip, deflate',
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(expoMessage),
            });

            const expoResult = await expoResponse.json();
            results.push({ username: user.username, status: expoResult.data?.status || 'error' });
        }

        return new Response(JSON.stringify({ success: true, processed: results.length, details: results }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })

    } catch (error) {
        return new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
    }
})
