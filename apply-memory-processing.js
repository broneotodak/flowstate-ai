const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();
const fs = require('fs');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  {
    db: {
      schema: 'public'
    }
  }
);

async function applyMemoryProcessing() {
  try {
    // For now, let's create a view that FlowState can use
    console.log('Creating FlowState-friendly view of memories...');
    
    // Check recent memories to understand structure
    const { data: memories, error } = await supabase
      .from('claude_desktop_memory')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(10);
    
    if (error) throw error;
    
    console.log(`Found ${memories.length} recent memories`);
    
    // Analyze memory patterns
    const patterns = {
      git_activities: 0,
      browser_activities: 0,
      coding_activities: 0,
      other: 0
    };
    
    memories.forEach(m => {
      if (m.content?.toLowerCase().includes('git') || m.category === 'git_commit') {
        patterns.git_activities++;
      } else if (m.tool === 'Browser') {
        patterns.browser_activities++;
      } else if (m.memory_type === 'technical_solution' || m.category === 'code_review') {
        patterns.coding_activities++;
      } else {
        patterns.other++;
      }
    });
    
    console.log('\nMemory patterns:');
    console.log(patterns);
    
    // Update memories with enriched metadata
    for (const memory of memories) {
      const updates = {};
      
      // Determine activity type
      let activityType = 'note';
      if (memory.content?.toLowerCase().includes('git commit')) activityType = 'git_commit';
      else if (memory.content?.toLowerCase().includes('git push')) activityType = 'git_push';
      else if (memory.tool === 'Browser') activityType = 'browser_activity';
      else if (memory.memory_type === 'technical_solution') activityType = 'coding';
      
      // Extract project
      let project = memory.metadata?.project || memory.category || 'General';
      if (memory.content?.toLowerCase().includes('flowstate')) project = 'FlowState';
      else if (memory.content?.toLowerCase().includes('ctk') || memory.content?.toLowerCase().includes('claude-tools-kit')) project = 'CTK';
      
      // Update metadata
      const newMetadata = {
        ...memory.metadata,
        activity_type: activityType,
        project: project,
        flowstate_processed: true
      };
      
      const { error: updateError } = await supabase
        .from('claude_desktop_memory')
        .update({ metadata: newMetadata })
        .eq('id', memory.id);
      
      if (updateError) {
        console.error(`Failed to update memory ${memory.id}:`, updateError);
      }
    }
    
    console.log('\n✅ Memory enrichment complete');
    console.log('FlowState should now display activities with proper types and projects');
    
  } catch (error) {
    console.error('Error:', error);
  }
}

applyMemoryProcessing();