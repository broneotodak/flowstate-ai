#!/usr/bin/env node

// FlowState AI - Batch Embedding Generator (Node.js version)
// Run with: node generate-embeddings.js

const SUPABASE_URL = 'https://uzamamymfzhelvkwpvgt.supabase.co';
const EDGE_FUNCTION_URL = `${SUPABASE_URL}/functions/v1/generate-embeddings`;

// IMPORTANT: Set your service role key here
const SERVICE_ROLE_KEY = 'YOUR_SERVICE_ROLE_KEY_HERE';

async function generateEmbedding(type, name, parentName, text, metadata = {}) {
    try {
        const response = await fetch(EDGE_FUNCTION_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${SERVICE_ROLE_KEY}`
            },
            body: JSON.stringify({
                text,
                type,
                name,
                parent_name: parentName,
                metadata
            })
        });
        
        if (!response.ok) {
            const error = await response.text();
            console.error(`❌ Failed for ${type}/${name}:`, error);
            return false;
        }
        
        console.log(`✅ Generated embedding for ${type}: ${name}`);
        return true;
    } catch (error) {
        console.error(`❌ Error for ${type}/${name}:`, error.message);
        return false;
    }
}

async function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
    console.log('🌊 FlowState AI - Batch Embedding Generator\n');
    
    if (SERVICE_ROLE_KEY === 'YOUR_SERVICE_ROLE_KEY_HERE') {
        console.error('❌ Please set your SERVICE_ROLE_KEY in this file first!');
        process.exit(1);
    }
    
    // First, let's test with a simple example
    console.log('Testing Edge Function...');
    const testSuccess = await generateEmbedding(
        'test',
        'Test Item',
        'FlowState AI',
        'This is a test embedding generation',
        { test: true }
    );
    
    if (!testSuccess) {
        console.error('\n❌ Edge Function test failed. Please check:');
        console.error('1. Your service role key is correct');
        console.error('2. The Edge Function is deployed');
        console.error('3. Your OpenAI API key is set in Supabase');
        process.exit(1);
    }
    
    console.log('\n✅ Edge Function is working! Starting batch generation...\n');
    
    // Import Supabase client
    const { createClient } = await import('@supabase/supabase-js');
    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
    
    // Generate embeddings for project phases
    console.log('📋 Processing project phases...');
    const { data: phases, error: phasesError } = await supabase
        .from('project_phases')
        .select('*');
    
    if (phasesError) {
        console.error('Error fetching phases:', phasesError);
    } else {
        console.log(`Found ${phases.length} project phases`);
        
        for (const phase of phases) {
            const text = `${phase.name || ''} Status: ${phase.status || ''}`;
            await generateEmbedding(
                'phase',
                phase.name || `Phase ${phase.id}`,
                'FlowState AI',
                text,
                { phase_id: phase.id, status: phase.status }
            );
            await sleep(300); // Rate limiting
        }
    }
    
    // Generate embeddings for tasks
    console.log('\n📋 Processing tasks...');
    const { data: tasks, error: tasksError } = await supabase
        .from('tasks')
        .select('*');
    
    if (tasksError) {
        console.error('Error fetching tasks:', tasksError);
    } else {
        console.log(`Found ${tasks.length} tasks`);
        
        for (const task of tasks) {
            const text = `${task.title || ''} ${task.description || ''} Priority: ${task.priority || ''}`;
            await generateEmbedding(
                'task',
                task.title || `Task ${task.id}`,
                task.phase_id || 'FlowState AI',
                text,
                { 
                    task_id: task.id, 
                    priority: task.priority,
                    status: task.status,
                    phase_id: task.phase_id
                }
            );
            await sleep(300); // Rate limiting
        }
    }
    
    console.log('\n✨ Batch generation complete!');
    console.log('Refresh your dashboard and try the semantic search (Cmd/Ctrl + K)');
}

// Check if we have the required dependencies
try {
    require('@supabase/supabase-js');
} catch (error) {
    console.error('❌ Missing dependency. Please run:');
    console.error('npm install @supabase/supabase-js');
    process.exit(1);
}

// Run the main function
main().catch(console.error);