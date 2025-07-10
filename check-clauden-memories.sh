#!/bin/bash

# Quick script to check ClaudeN memories
source ~/.flowstate/config

echo "🔍 Checking ClaudeN memories..."

# Fetch recent memories
MEMORIES=$(curl -s -X GET \
  "https://uzamamymfzhelvkwpvgt.supabase.co/rest/v1/claude_desktop_memory?user_id=eq.neo_todak&order=created_at.desc&limit=5" \
  -H "apikey: $FLOWSTATE_SERVICE_KEY" \
  -H "Authorization: Bearer $FLOWSTATE_SERVICE_KEY")

# Count total
TOTAL=$(curl -s -X GET \
  "https://uzamamymfzhelvkwpvgt.supabase.co/rest/v1/claude_desktop_memory?user_id=eq.neo_todak&select=count" \
  -H "apikey: $FLOWSTATE_SERVICE_KEY" \
  -H "Authorization: Bearer $FLOWSTATE_SERVICE_KEY" \
  -H "Prefer: count=exact" | python3 -c "import json, sys; print(json.load(sys.stdin)[0]['count'])")

echo "📊 Total memories: $TOTAL"
echo ""
echo "📝 Recent 5 memories:"
echo "$MEMORIES" | python3 -c "
import json, sys
memories = json.load(sys.stdin)
for i, mem in enumerate(memories):
    print(f\"{i+1}. [{mem.get('category', 'uncategorized')}] {mem.get('content', '')[:100]}...\")
    print(f\"   Created: {mem.get('created_at', 'unknown')}\")
    print()
"