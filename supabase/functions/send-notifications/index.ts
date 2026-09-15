import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { create } from 'https://deno.land/x/djwt@v2.8/mod.ts'

// Interface for Firebase Service Account JSON
interface ServiceAccount {
    type: string
    project_id: string
    private_key_id: string
    private_key: string
    client_email: string
    client_id: string
    auth_uri: string
    token_uri: string
    auth_provider_x509_cert_url: string
    client_x509_cert_url: string
}

// Interface for Notification payload
interface NotificationPayload {
    token: string
    title: string
    body: string
    data?: Record<string, string>
}

// Authenticate and get Google Access Token using Service Account
async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
    const iat = Math.floor(Date.now() / 1000)
    const exp = iat + 3600 // 1 hour expiration

    // 1. Clean up the key: Remove headers & newlines to get pure Base64
    const pem = serviceAccount.private_key
        .replace(/-----BEGIN PRIVATE KEY-----/g, '')
        .replace(/-----END PRIVATE KEY-----/g, '')
        .replace(/\s/g, '') // remove all whitespace (newlines, spaces)

    // 2. Import Key using Web Crypto API
    // RS256 requires RSA-PSS or RSASSA-PKCS1-v1_5. Google usually uses RSASSA-PKCS1-v1_5.
    const binaryKey = Uint8Array.from(atob(pem), c => c.charCodeAt(0))

    const cryptoKey = await crypto.subtle.importKey(
        'pkcs8',
        binaryKey,
        {
            name: 'RSASSA-PKCS1-v1_5',
            hash: 'SHA-256',
        },
        false,
        ['sign']
    )

    // 3. Create JWT using the CryptoKey
    const jwt = await create(
        { alg: 'RS256', typ: 'JWT' },
        {
            iss: serviceAccount.client_email,
            scope: 'https://www.googleapis.com/auth/firebase.messaging',
            aud: 'https://oauth2.googleapis.com/token',
            iat,
            exp,
        },
        cryptoKey
    )

    const params = new URLSearchParams()
    params.append('grant_type', 'urn:ietf:params:oauth:grant-type:jwt-bearer')
    params.append('assertion', jwt)

    const res = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params,
    })

    if (!res.ok) {
        const text = await res.text()
        throw new Error(`Failed to get access token: ${text}`)
    }

    const data = await res.json()
    return data.access_token
}

// Send notification via FCM v1 API
async function sendFCMNotification(
    accessToken: string,
    projectId: string,
    payload: NotificationPayload
) {
    const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

    const message = {
        message: {
            token: payload.token,
            notification: {
                title: payload.title,
                body: payload.body,
            },
            data: payload.data || {},
        },
    }

    // Deno/Edge functions debugging
    console.log(`Sending to ${payload.token}: ${JSON.stringify(message.message.notification)}`)

    const res = await fetch(url, {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(message),
    })

    console.log(`FCM Response Status: ${res.status}`)

    if (!res.ok) {
        const errorText = await res.text()
        console.error(`FCM Error: ${errorText}`)
        return false
    }

    return true
}

Deno.serve(async (req) => {
    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
        return new Response('ok', {
            headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
            }
        })
    }

    try {
        // 1. Check Auth Header (for manual invocation security)
        const authHeader = req.headers.get('Authorization')
        if (!authHeader) {
            return new Response(JSON.stringify({ error: 'Unauthorized' }), {
                status: 401,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                },
            })
        }

        // 2. Parse Request
        const { type } = await req.json()
        console.log(`🚀 Starting notification job. Type: ${type}`)

        // 3. Get Secrets
        const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
        const supabase = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        // 1. Rate Limit Checker
        async function checkRateLimit(userId: string): Promise<boolean> {
            const { data, error } = await supabase
                .from('user_profiles')
                .select('daily_notification_count')
                .eq('user_id', userId)
                .single()

            if (error || !data) return false; // Default deny if error (fail closed)
            return data.daily_notification_count < 2; // Limit: 2 per day
        }

        async function incrementRateLimit(userId: string) {
            // Logic to do this update via RPC or direct update if RLS allows specific columns
            // For simplicity, using direct update (ensure RLS allows service role)
            const { data } = await supabase.from('user_profiles').select('daily_notification_count').eq('user_id', userId).single();
            if (data) {
                await supabase.from('user_profiles').update({ daily_notification_count: (data.daily_notification_count || 0) + 1 }).eq('user_id', userId);
            } else {
                // If user profile doesn't exist, create it or handle error
                await supabase.from('user_profiles').insert({ user_id: userId, daily_notification_count: 1 });
            }
        }

        // 2. AI Generator (Groq)
        async function generateAIContent(systemPrompt: string, userPrompt: string): Promise<string | null> {
            const apiKey = Deno.env.get('GROQ_API_KEY');
            if (!apiKey) {
                console.error('⚠️ GROQ_API_KEY missing');
                return null;
            }

            try {
                const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${apiKey}`,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        model: 'llama-3.3-70b-versatile', // Fast & Good
                        messages: [
                            { role: 'system', content: systemPrompt },
                            { role: 'user', content: userPrompt }
                        ]
                    })
                });
                const json = await res.json();
                return json.choices?.[0]?.message?.content || null;
            } catch (e) {
                console.error('Error calling Groq:', e);
                return null;
            }
        }

        if (!serviceAccountJson || !Deno.env.get('SUPABASE_URL') || !Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')) {
            throw new Error('Missing configuration secrets (FIREBASE_SERVICE_ACCOUNT, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)')
        }

        const serviceAccount: ServiceAccount = JSON.parse(serviceAccountJson)

        // 5. Logic Branching
        let processedCount = 0
        let sentCount = 0

        // Helpers defined above (lines 150-202) are accessible here.


        if (type === 'streak-risk') {
            const accessToken = await getAccessToken(serviceAccount)
            console.log('🛡️ Checking for streaks at risk...')
            // Logic: Users with current streak > 0 but not completed today
            const { data: habits } = await supabase
                .from('habits')
                .select('id, name, streak, user_id, completion_dates, reminder_enabled, fcm_tokens!inner(token)')
                .gt('streak', 0)
                .eq('reminder_enabled', true)

            if (habits && habits.length > 0) {
                const todayStr = new Date().toISOString().split('T')[0];
                // Filter strictly for risk (not completed today)
                const risks = habits.filter((h: any) => {
                    const dates = h.completion_dates || [];
                    return !dates.includes(todayStr); // If today is NOT in completion dates, it's at risk
                });

                // Group by user
                const userHabits: Record<string, any[]> = {};
                risks.forEach((h: any) => {
                    if (!userHabits[h.user_id]) userHabits[h.user_id] = [];
                    userHabits[h.user_id].push(h);
                });

                for (const userId of Object.keys(userHabits)) {
                    const list = userHabits[userId];
                    const uniqueTokens = [...new Set(list.flatMap((h: any) => h.fcm_tokens).map((t: any) => t.token))];
                    const title = "🔥 Keep the Streak Alive!";
                    const body = `You have ${list.length} habits waiting for you. Don't break the chain!`;

                    await Promise.all(uniqueTokens.map(async (token: any) => {
                        const success = await sendFCMNotification(accessToken, serviceAccount.project_id, {
                            token: token, title, body, data: { type: 'streak_reminder' }
                        });
                        if (success) sentCount++;
                    }));
                    processedCount++;
                    await incrementRateLimit(userId);
                }
            }
        }
        else if (type === 'ai-coach') {
            console.log('🤖 Processing AI Coach...');
            const accessToken = await getAccessToken(serviceAccount);
            const { data: users } = await supabase.from('user_profiles').select('user_id, last_ai_notification_at, daily_notification_count');

            const now = Date.now();
            const eligible = (users || []).filter((u: any) => {
                const countOk = (u.daily_notification_count || 0) < 2;
                const timeOk = !u.last_ai_notification_at || (now - new Date(u.last_ai_notification_at).getTime() > 24 * 60 * 60 * 1000);
                return countOk && timeOk;
            });

            for (const user of eligible) {
                const { data: userHabits } = await supabase.from('habits').select('name, streak').eq('user_id', user.user_id);
                const summary = (userHabits || []).map((h: any) => `${h.name}: ${h.streak}d`).join(', ');
                const msg = await generateAIContent(
                    "You are a supportive habit coach. Concisely motivate this user based on their habits. Max 20 words.",
                    `Habits: ${summary}`
                );

                if (msg) {
                    const { data: tokens } = await supabase.from('fcm_tokens').select('token').eq('user_id', user.user_id);
                    if (tokens && tokens.length > 0) {
                        for (const t of tokens) {
                            await sendFCMNotification(accessToken, serviceAccount.project_id, {
                                token: t.token, title: 'Coach Wind 🍃', body: msg, data: { type: 'ai_coach' }
                            });
                            sentCount++;
                        }
                        await supabase.from('user_profiles').update({ last_ai_notification_at: new Date().toISOString(), daily_notification_count: (user.daily_notification_count || 0) + 1 }).eq('user_id', user.user_id);
                        processedCount++;
                    }
                }
            }
        }
        else if (type === 'check-inactivity') {
            console.log('💤 Inactivity check placeholder (requires last_active_at)');
        }
        else if (type === 'morning-quote') {
            console.log('☀️ Processing Morning Quote...');
            const accessToken = await getAccessToken(serviceAccount);
            const today = new Date().toISOString().split('T')[0];
            let { data: quote } = await supabase.from('daily_quotes').select('*').eq('used_on_date', today).maybeSingle();

            if (!quote) {
                const content = await generateAIContent("Generate a short motivational quote. No attribution.", "Quote for today") || "Keep going!";
                const { data: newQ } = await supabase.from('daily_quotes').insert({ content, used_on_date: today, author: 'AI' }).select().single();
                quote = newQ;
            }

            if (quote) {
                const { data: users } = await supabase.from('user_profiles').select('user_id, daily_notification_count').lt('daily_notification_count', 2);
                if (users) {
                    for (const user of users) {
                        const { data: tokens } = await supabase.from('fcm_tokens').select('token').eq('user_id', user.user_id);
                        if (tokens) {
                            for (const t of tokens) {
                                await sendFCMNotification(accessToken, serviceAccount.project_id, {
                                    token: t.token, title: 'Discovery 💡', body: quote.content, data: { type: 'quote' }
                                });
                                sentCount++;
                            }
                            await incrementRateLimit(user.user_id);
                        }
                    }
                }
            }
        }
        else if (type === 'weekly-summary') {
            const accessToken = await getAccessToken(serviceAccount);
            console.log('📊 Weekly Summary...');
            const { data: tokens } = await supabase.from('fcm_tokens').select('token');
            if (tokens) {
                // Simplified: Send generic summary to all (since computing individual stats is heavy)
                await Promise.all(tokens.map(async (t: any) => {
                    const success = await sendFCMNotification(accessToken, serviceAccount.project_id, {
                        token: t.token, title: 'Weekly Recap', body: 'Check your progress in the app!', data: { type: 'weekly_summary' }
                    });
                    if (success) sentCount++;
                }));
                processedCount += tokens.length;
            }
        }
        else if (type === 'test') {
            const accessToken = await getAccessToken(serviceAccount);
            console.log('🧪 Sending TEST...');
            const { data: tokens } = await supabase.from('fcm_tokens').select('token');
            if (tokens) {
                await Promise.all(tokens.map(async (t: any) => {
                    const success = await sendFCMNotification(accessToken, serviceAccount.project_id, {
                        token: t.token, title: 'Test', body: 'Server notification working!', data: { type: 'test' }
                    });
                    if (success) { sentCount++; processedCount++; }
                }));
            }
        }

        return new Response(
            JSON.stringify({
                success: true,
                message: `Processed ${processedCount}, Sent ${sentCount}`,
                processed: processedCount,
                sent: sentCount
            }),
            {
                status: 200,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                }
            }
        )

    } catch (error) {
        console.error('❌ Error:', (error as Error).message)
        return new Response(
            JSON.stringify({
                error: (error as Error).message || 'Internal server error',
            }),
            {
                status: 500,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                }
            }
        )
    }
})

