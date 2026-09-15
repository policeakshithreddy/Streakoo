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

// Authenticate and get Google Access Token using Service Account
async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
    const iat = Math.floor(Date.now() / 1000)
    const exp = iat + 3600 // 1 hour expiration

    const pem = serviceAccount.private_key
        .replace(/-----BEGIN PRIVATE KEY-----/g, '')
        .replace(/-----END PRIVATE KEY-----/g, '')
        .replace(/\s/g, '')

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
    token: string,
    title: string,
    body: string,
    data?: Record<string, string>
): Promise<boolean> {
    const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

    const message = {
        message: {
            token: token,
            notification: {
                title: title,
                body: body,
            },
            data: {
                ...data,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
                priority: 'high',
                ttl: '86400s', // 24 hours
                notification: {
                    sound: 'default',
                    channel_id: 'high_importance_channel', // Match Flutter channel
                    notification_priority: 'PRIORITY_HIGH',
                    visibility: 'PUBLIC',
                    default_sound: true,
                    default_vibrate_timings: true,
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                }
            },
            apns: {
                headers: {
                    'apns-priority': '10', // Immediate delivery
                },
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                        'content-available': 1,
                    }
                }
            }
        },
    }

    console.log(`Sending nudge notification to token: ${token.substring(0, 20)}...`)

    const res = await fetch(url, {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(message),
    })

    if (!res.ok) {
        const errorText = await res.text()
        console.error(`FCM Error: ${errorText}`)
        return false
    }

    console.log('✅ Nudge notification sent successfully')
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
        // Parse request body
        const { to_user_id, from_user_name, message } = await req.json()

        const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
        if (!to_user_id || !uuidRegex.test(to_user_id)) {
            return new Response(
                JSON.stringify({ error: 'Invalid or missing to_user_id (must be a valid UUID)' }),
                {
                    status: 400,
                    headers: {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*',
                    }
                }
            )
        }

        console.log(`🔔 Partner nudge: ${from_user_name} -> ${to_user_id}`)

        // Get secrets
        const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
        const supabaseUrl = Deno.env.get('SUPABASE_URL')
        const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

        if (!serviceAccountJson || !supabaseUrl || !supabaseKey) {
            throw new Error('Missing configuration secrets')
        }

        const serviceAccount: ServiceAccount = JSON.parse(serviceAccountJson)
        const supabase = createClient(supabaseUrl, supabaseKey)

        // Get FCM tokens for the target user
        const { data: tokens, error: tokenError } = await supabase
            .from('fcm_tokens')
            .select('token')
            .eq('user_id', to_user_id)

        if (tokenError) {
            console.error('Error fetching FCM tokens:', tokenError)
            throw new Error('Failed to fetch user tokens')
        }

        if (!tokens || tokens.length === 0) {
            console.log('⚠️ No FCM tokens found for user')
            return new Response(
                JSON.stringify({ success: false, message: 'User has no registered devices' }),
                { status: 200, headers: { 'Content-Type': 'application/json' } }
            )
        }

        // Get access token for FCM
        const accessToken = await getAccessToken(serviceAccount)

        // Send notification to all user's devices
        const title = `📲 ${from_user_name} is checking on you!`
        const body = message || "Your partner wants to know how you're doing!"

        let successCount = 0
        for (const t of tokens) {
            const success = await sendFCMNotification(
                accessToken,
                serviceAccount.project_id,
                t.token,
                title,
                body,
                { type: 'partner_nudge', from_user: from_user_name }
            )
            if (success) successCount++
        }

        return new Response(
            JSON.stringify({
                success: true,
                message: `Sent to ${successCount}/${tokens.length} devices`
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
            JSON.stringify({ error: (error as Error).message }),
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
