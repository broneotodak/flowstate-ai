# FlowState Deployment Guide

## Security Model

FlowState is a **client-side application** that runs entirely in the browser. This means:

- ✅ **SUPABASE_ANON_KEY**: Safe to expose - designed for client-side use
- ❌ **SUPABASE_SERVICE_ROLE_KEY**: NEVER expose - server-side only

The anon key is protected by:
1. Row Level Security (RLS) policies in your Supabase database
2. Limited permissions (read-only for public data)

## Netlify Environment Variables

You can use either naming convention:

### Option 1: NEXT_PUBLIC_ prefix (Recommended)
- `NEXT_PUBLIC_SUPABASE_URL` - Your Supabase project URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` - Your Supabase anon (public) key

### Option 2: Standard names (requires marking as non-secret)
- `SUPABASE_URL` - Your Supabase project URL  
- `SUPABASE_ANON_KEY` - Your Supabase anon (public) key

The build script supports both. The NEXT_PUBLIC_ prefix tells Netlify these are intentionally public.

## Important Security Notes

1. **Never** add SUPABASE_SERVICE_ROLE_KEY to client-side apps
2. The anon key is **meant to be public** - security comes from RLS policies
3. Keep your service role key in server-side functions only

## Setting Environment Variables in Netlify

1. Go to your Netlify dashboard
2. Select your FlowState site
3. Go to Site settings → Environment variables
4. Add the variables (either naming convention)
5. If using standard names, you may need to mark them as "non-secret"
6. Trigger a redeploy

The build script will automatically inject these PUBLIC values into the app during build time.