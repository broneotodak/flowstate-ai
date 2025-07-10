# FlowState Deployment Guide

## Netlify Environment Variables

This app requires the following environment variables to be set in Netlify:

1. `NEXT_PUBLIC_SUPABASE_URL` - Your Supabase project URL
2. `NEXT_PUBLIC_SUPABASE_ANON_KEY` - Your Supabase anon (public) key

These are PUBLIC environment variables that are safe to expose in the browser. The `NEXT_PUBLIC_` prefix tells Netlify that these are intentionally public.

## Setting Environment Variables in Netlify

1. Go to your Netlify dashboard
2. Select your FlowState site
3. Go to Site settings → Environment variables
4. Add the two variables listed above
5. Trigger a redeploy

The build script will automatically inject these values into the app during build time.