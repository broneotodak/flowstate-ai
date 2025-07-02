#!/bin/bash

# Update service key in git hooks
echo "🔧 FlowState Service Key Updater"
echo "================================"

# Check if service key is provided as argument
if [ -z "$1" ]; then
    echo "Usage: ./update-service-key.sh YOUR_SERVICE_KEY"
    echo ""
    echo "Example:"
    echo "./update-service-key.sh eyJhbGc..."
    exit 1
fi

SERVICE_KEY=$1
HOOK_FILE=".git/hooks/flowstate-track.sh"

# Check if hook file exists
if [ ! -f "$HOOK_FILE" ]; then
    echo "❌ Git hooks not installed. Run install-flowstate-git-hooks.sh first."
    exit 1
fi

# Update the service key
sed -i '' "s|SUPABASE_SERVICE_KEY=\"YOUR_SERVICE_KEY_HERE\"|SUPABASE_SERVICE_KEY=\"$SERVICE_KEY\"|g" "$HOOK_FILE"

echo "✅ Service key updated in git hooks!"
echo ""
echo "🧪 Testing the connection..."

# Test the connection
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X GET "https://uzamamymfzhelvkwpvgt.supabase.co/rest/v1/current_context?user_id=eq.neo_todak" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY")

if [ "$RESPONSE" = "200" ]; then
    echo "✅ Connection successful!"
    echo ""
    echo "📝 Next step: Make a test commit"
    echo "   git add ."
    echo "   git commit -m 'Test automated tracking'"
else
    echo "❌ Connection failed (HTTP $RESPONSE)"
    echo "   Please check your service key"
fi