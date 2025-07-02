import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify GitHub webhook signature (optional but recommended)
    const signature = req.headers.get('x-hub-signature-256')
    const event = req.headers.get('x-github-event')
    
    if (!event) {
      throw new Error('Missing GitHub event header')
    }

    const payload = await req.json()
    
    // Initialize Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Extract common info
    const repository = payload.repository?.name || 'Unknown'
    const user = payload.sender?.login || 'neo_todak'
    const timestamp = new Date().toISOString()

    let activityType = 'github_activity'
    let description = ''
    let currentTask = ''

    // Handle different GitHub events
    switch (event) {
      case 'push':
        const branch = payload.ref?.replace('refs/heads/', '') || 'main'
        const commitCount = payload.commits?.length || 0
        const lastCommit = payload.commits?.[commitCount - 1]
        activityType = 'git_push'
        description = `Pushed ${commitCount} commit(s) to ${branch}`
        currentTask = lastCommit?.message || 'Code updates'
        break

      case 'pull_request':
        const action = payload.action
        const prTitle = payload.pull_request?.title
        activityType = 'pull_request'
        description = `${action} PR: ${prTitle}`
        currentTask = `Working on PR: ${prTitle}`
        break

      case 'issues':
        const issueAction = payload.action
        const issueTitle = payload.issue?.title
        activityType = 'issue_management'
        description = `${issueAction} issue: ${issueTitle}`
        currentTask = `Managing issue: ${issueTitle}`
        break

      case 'create':
        const refType = payload.ref_type
        const refName = payload.ref
        activityType = 'git_create'
        description = `Created ${refType}: ${refName}`
        currentTask = `Setting up ${refType}: ${refName}`
        break

      case 'delete':
        const delRefType = payload.ref_type
        const delRefName = payload.ref
        activityType = 'git_delete'
        description = `Deleted ${delRefType}: ${delRefName}`
        currentTask = `Cleaning up ${delRefType}`
        break

      default:
        description = `GitHub ${event} event`
        currentTask = `GitHub activity: ${event}`
    }

    // Log activity
    const { error: activityError } = await supabase
      .from('activities')
      .insert({
        user_id: 'neo_todak',
        activity_type: activityType,
        description: description,
        project_name: repository,
        created_at: timestamp,
        metadata: {
          github_event: event,
          github_user: user,
          payload_summary: {
            repository: payload.repository?.full_name,
            branch: payload.ref,
            action: payload.action
          }
        }
      })

    if (activityError) {
      console.error('Error inserting activity:', activityError)
    }

    // Update current context
    const { error: contextError } = await supabase
      .from('current_context')
      .upsert({
        user_id: 'neo_todak',
        project_name: repository,
        current_task: currentTask,
        current_phase: 'Development',
        last_updated: timestamp
      }, {
        onConflict: 'user_id'
      })

    if (contextError) {
      console.error('Error updating context:', contextError)
    }

    // If it's a commit with AI-related keywords, create embeddings
    if (event === 'push' && payload.commits) {
      for (const commit of payload.commits) {
        const message = commit.message.toLowerCase()
        if (message.includes('ai') || message.includes('embed') || message.includes('context')) {
          // Generate embedding for this commit
          await fetch(`${supabaseUrl}/functions/v1/generate-embeddings`, {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${supabaseServiceKey}`,
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({
              text: `${repository}: ${commit.message}`,
              type: 'activities',
              name: commit.message.substring(0, 100),
              parent_name: repository
            })
          })
        }
      }
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        event: event,
        repository: repository,
        activity_logged: true 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )
  } catch (error) {
    console.error('Webhook error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      }
    )
  }
})