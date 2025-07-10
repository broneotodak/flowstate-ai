#!/bin/bash

# Generate config.js with environment variables
cat > config.js << EOF
// Auto-generated during build
window.FLOWSTATE_CONFIG = {
    SUPABASE_URL: '${NEXT_PUBLIC_SUPABASE_URL}',
    SUPABASE_ANON_KEY: '${NEXT_PUBLIC_SUPABASE_ANON_KEY}'
};
EOF

echo "Config generated with environment variables"