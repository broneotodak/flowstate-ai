#!/bin/bash

# Generate config.js with PUBLIC variables only (safe for client-side)
# Using NEXT_PUBLIC_ prefix which Netlify recognizes as intentionally public
cat > config.js << EOF
// Auto-generated during build - PUBLIC configuration only
// These are client-safe values protected by Row Level Security
window.FLOWSTATE_CONFIG = {
    SUPABASE_URL: '${NEXT_PUBLIC_SUPABASE_URL:-${SUPABASE_URL}}',
    SUPABASE_ANON_KEY: '${NEXT_PUBLIC_SUPABASE_ANON_KEY:-${SUPABASE_ANON_KEY}}'
};
EOF

echo "Config generated with PUBLIC environment variables only"