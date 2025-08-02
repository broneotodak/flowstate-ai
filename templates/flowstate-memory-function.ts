import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface MemoryRequest {
  content: string
  project?: string
  tool?: string
  user_id?: string
  memory_type?: string
  importance?: number
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )
    
    const openaiKey = Deno.env.get('OPENAI_API_KEY')!
    
    if (!openaiKey) {
      throw new Error('OpenAI API key not configured')
    }

    const { 
      content, 
      project, 
      tool = 'unknown', 
      user_id = 'user', 
      memory_type = 'note',
      importance = 5
    }: MemoryRequest = await req.json()

    if (!content) {
      throw new Error('Content is required')
    }

    // Step 1: Generate embedding using OpenAI
    const embeddingResponse = await fetch('https://api.openai.com/v1/embeddings', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'text-embedding-3-small',
        input: content,
        dimensions: 1536
      }),
    })

    if (!embeddingResponse.ok) {
      throw new Error(`OpenAI API error: ${embeddingResponse.statusText}`)
    }

    const embeddingData = await embeddingResponse.json()
    const embedding = embeddingData.data[0].embedding

    // Step 2: Auto-detect project if not provided
    const detectedProject = project || detectProjectFromContent(content)

    // Step 3: Save memory with embedding (trigger will handle FlowState sync)
    const { data: memory, error: memoryError } = await supabase
      .from('user_memories')
      .insert({
        user_id,
        content,
        project_name: detectedProject,
        tool_source: tool,
        memory_type,
        importance,
        embedding,
        metadata: {
          detected_project: !project, // Flag if auto-detected
          content_length: content.length,
          timestamp: new Date().toISOString(),
          openai_model: 'text-embedding-3-small'
        }
      })
      .select()
      .single()

    if (memoryError) {
      throw memoryError
    }

    return new Response(
      JSON.stringify({
        success: true,
        memory_id: memory.id,
        project: detectedProject,
        embedding_generated: true,
        message: 'Memory saved successfully with semantic embedding'
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('FlowState Memory Error:', error)
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      }
    )
  }
})

// Helper function to detect project from content
function detectProjectFromContent(content: string): string {
  const patterns = {
    'FlowState': /flowstate|flow.state|activity.tracking|dashboard/i,
    'Claude Integration': /claude|anthropic|ai.assistant/i,
    'Database Project': /supabase|postgresql|database|sql/i,
    'Web Development': /react|nextjs|javascript|typescript|html|css/i,
    'Mobile Development': /ios|android|swift|kotlin|flutter|react.native/i,
    'DevOps': /docker|kubernetes|deployment|ci.cd|github.actions/i,
    'Data Science': /python|jupyter|pandas|numpy|machine.learning|ml/i,
  }

  for (const [project, pattern] of Object.entries(patterns)) {
    if (pattern.test(content)) {
      return project
    }
  }

  // Try to extract from file paths
  const pathMatch = content.match(/\/([^\/\s]+)\//g)
  if (pathMatch && pathMatch[0]) {
    return pathMatch[0].replace(/\//g, '') || 'Unknown Project'
  }

  return 'General Development'
}
