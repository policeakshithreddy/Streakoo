# Supabase Edge Functions for Streakoo

This directory contains Supabase Edge Functions for server-side processing.

## Functions

### `generate-year-in-review`
Generates Year in Review statistics for a user by:
1. Fetching user's habits from the database
2. Calculating statistics (completions, streaks, etc.)
3. Storing results in the `year_in_review` table

**Endpoint**: `https://<project-ref>.supabase.co/functions/v1/generate-year-in-review`

**Request**:
```json
{
  "year": 2025
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "total_completions": 180,
    "longest_streak": 45,
    ...
  }
}
```

## Setup

### Prerequisites
1. Install Supabase CLI: `npm install -g supabase`
2. Login: `supabase login`
3. Link project: `supabase link --project-ref <your-project-ref>`

### Deploy Functions
```bash
# Deploy all functions
supabase functions deploy

# Deploy specific function
supabase functions deploy generate-year-in-review
```

### Test Locally
```bash
# Serve functions locally
supabase functions serve

# Test with curl
curl -i --location --request POST 'http://localhost:54321/functions/v1/generate-year-in-review' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"year":2025}'
```

## Environment Variables

Edge Functions have access to:
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Public anon key
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key (for privileged operations)

## Notes

- Edge Functions run on Deno (secure TypeScript runtime)
- Free tier: 500,000 invocations/month
- Auto-scales based on traffic
- Global edge network for low latency
