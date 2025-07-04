#!/usr/bin/env node

// Fix and standardize the memory system for all AI tools

const https = require('https');
const SUPABASE_URL = 'https://uzamamymfzhelvkwpvgt.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

// Create a critical memory about how memories should be stored
const memoryStandard = {
  type: 'critical_standard',
  name: 'Universal Memory Storage Standard - MUST FOLLOW',
  parent_name: 'todak-ai-system',
  text: `
# CRITICAL: Universal Memory Storage Standard

## The Problem
The claude_desktop_memory table is a mess because all AI tools are:
- Using "claude_desktop" as source regardless of actual tool
- Leaving owner field null
- Not identifying themselves properly

## THE CORRECT WAY TO STORE MEMORIES

### 1. When Storing to claude_desktop_memory:
\`\`\`javascript
{
  user_id: 'neo_todak',           // Always neo_todak
  owner: 'neo_todak',              // NOT NULL - always set this!
  source: 'actual_tool_name',      // CRITICAL - use real tool name!
  memory_type: 'appropriate_type',
  content: 'memory content',
  metadata: {
    tool_version: '1.0',
    machine: 'hostname',
    project: 'current_project'
  }
}
\`\`\`

### 2. Source Values MUST BE:
- 'claude_code' - When using Claude Code (in terminal)
- 'claude_desktop' - ONLY when using Claude Desktop app
- 'cursor' - When using Cursor AI
- 'vscode' - When using VSCode with Claude
- 'browser_extension' - When from browser
- 'n8n' - When from n8n workflows
- 'github_copilot' - When using Copilot

### 3. Better Alternative - Use context_embeddings:
Instead of claude_desktop_memory, consider using context_embeddings table:
\`\`\`javascript
{
  type: 'conversation',
  name: 'Short description',
  parent_name: 'project_name',
  text: 'Full content',
  metadata: {
    source: 'claude_code',  // Tool that created it
    user: 'neo_todak',
    timestamp: new Date().toISOString()
  }
}
\`\`\`

### 4. For Activity Tracking - Use activity_log:
\`\`\`javascript
{
  user_id: 'neo_todak',
  activity_type: 'ai_conversation',
  activity_description: 'What was discussed',
  project_name: 'current_project',
  metadata: {
    tool: 'claude_code',    // Which AI tool
    machine_name: 'hostname',
    source: 'ai_tool'
  }
}
\`\`\`

## RULES FOR ALL AI TOOLS:

1. **IDENTIFY YOURSELF** - Never use "claude_desktop" unless you ARE Claude Desktop
2. **SET OWNER** - Always set owner to 'neo_todak', never leave null
3. **USE METADATA** - Include tool version, machine, project in metadata
4. **CONSIDER ALTERNATIVES** - Maybe claude_desktop_memory isn't the right table

## Example for Each Tool:

### Claude Code:
\`\`\`javascript
source: 'claude_code',
owner: 'neo_todak',
metadata: { tool: 'claude_code', version: 'cli' }
\`\`\`

### Cursor:
\`\`\`javascript
source: 'cursor',
owner: 'neo_todak',
metadata: { tool: 'cursor', ide: 'cursor' }
\`\`\`

### VSCode:
\`\`\`javascript
source: 'vscode',
owner: 'neo_todak',
metadata: { tool: 'vscode', extension: 'claude' }
\`\`\`

## Current State Analysis:
- 1700+ memories with source='claude_desktop' but most are NOT from Claude Desktop
- Most have owner=null which breaks queries
- No way to filter by actual tool that created the memory

## Migration Script Available:
Run fix-claude-memory-sources.sql to:
1. Set all null owners to 'neo_todak'
2. Attempt to fix sources based on content patterns
3. Add metadata about the fix

This standard MUST be followed by all AI tools to maintain data quality.
`,
  metadata: {
    importance: 'critical',
    type: 'standard',
    affects: ['claude_code', 'cursor', 'vscode', 'claude_desktop', 'all_ai_tools'],
    created_by: 'claude_code',
    timestamp: new Date().toISOString()
  }
};

// Helper to fix existing memories based on content
const fixQueries = `
-- Fix null owners
UPDATE claude_desktop_memory 
SET owner = 'neo_todak' 
WHERE owner IS NULL;

-- Fix sources based on content patterns
UPDATE claude_desktop_memory
SET source = CASE
  WHEN content ILIKE '%claude code%' THEN 'claude_code'
  WHEN content ILIKE '%cursor%' AND source = 'claude_desktop' THEN 'cursor'
  WHEN content ILIKE '%vscode%' AND source = 'claude_desktop' THEN 'vscode'
  WHEN content ILIKE '%n8n%' AND source = 'claude_desktop' THEN 'n8n'
  ELSE source
END,
metadata = jsonb_set(
  COALESCE(metadata, '{}'),
  '{fixed_at}',
  to_jsonb(NOW()::text)
)
WHERE source = 'claude_desktop' 
  AND (content ILIKE '%claude code%' 
    OR content ILIKE '%cursor%' 
    OR content ILIKE '%vscode%'
    OR content ILIKE '%n8n%');

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_claude_memory_source ON claude_desktop_memory(source);
CREATE INDEX IF NOT EXISTS idx_claude_memory_owner ON claude_desktop_memory(owner);
`;

// Create embedding
async function createStandard() {
  return new Promise((resolve, reject) => {
    const url = new URL(`${SUPABASE_URL}/functions/v1/generate-embeddings`);
    
    const req = https.request({
      hostname: url.hostname,
      path: url.pathname,
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          console.log('✅ Memory standard embedded successfully');
          resolve();
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });
    
    req.on('error', reject);
    req.write(JSON.stringify(memoryStandard));
    req.end();
  });
}

// Save fix queries
const fs = require('fs');
const path = require('path');

fs.writeFileSync(
  path.join(__dirname, 'sql', 'fix-claude-memory-sources.sql'),
  `-- Fix claude_desktop_memory source and owner issues\n${fixQueries}`,
  'utf8'
);

// Execute
if (!SERVICE_KEY) {
  console.error('❌ Please set FLOWSTATE_SERVICE_KEY');
  process.exit(1);
}

console.log('🚨 Creating memory storage standard...');
createStandard().then(() => {
  console.log('✅ Standard created in pgvector!');
  console.log('✅ Fix queries saved to sql/fix-claude-memory-sources.sql');
  console.log('\nAll AI tools will now know:');
  console.log('- Use correct source names');
  console.log('- Always set owner field');
  console.log('- Consider using context_embeddings instead');
}).catch(err => {
  console.error('❌ Failed:', err.message);
});