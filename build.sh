#!/bin/bash

# Generate config.js with environment variables
cat > config.js << EOF
// Auto-generated during build
window.FLOWSTATE_CONFIG = {
    SUPABASE_URL: '${SUPABASE_URL}',
    SUPABASE_ANON_KEY: '${SUPABASE_ANON_KEY}'
};
EOF

echo "Config generated with environment variables"