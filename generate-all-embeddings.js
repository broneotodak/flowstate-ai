// FlowState AI - Batch Embedding Generation Script
// This script generates AI embeddings for all existing data in your database

const SUPABASE_URL = 'https://YOUR_PROJECT_ID.supabase.co';
const SUPABASE_SERVICE_KEY = 'YOUR_SERVICE_ROLE_KEY'; // Replace with your service role key
const EDGE_FUNCTION_URL = `${SUPABASE_URL}/functions/v1/generate-embeddings`;

// Initialize Supabase client
const { createClient } = window.supabase;
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

async function generateEmbeddingsForTable(tableName, textExtractor) {
    console.log(`\n🔄 Processing ${tableName}...`);
    
    // Fetch all records from the table
    const { data: records, error } = await supabase
        .from(tableName)
        .select('*');
    
    if (error) {
        console.error(`Error fetching ${tableName}:`, error);
        return;
    }
    
    console.log(`Found ${records.length} records in ${tableName}`);
    
    // Generate embeddings for each record
    for (const record of records) {
        const text = textExtractor(record);
        
        if (!text || text.trim() === '') {
            console.log(`⏭️  Skipping empty record: ${record.id}`);
            continue;
        }
        
        try {
            const response = await fetch(EDGE_FUNCTION_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`
                },
                body: JSON.stringify({
                    text: text,
                    table: tableName,
                    id: record.id
                })
            });
            
            if (response.ok) {
                console.log(`✅ Generated embedding for ${tableName}:${record.id}`);
            } else {
                const error = await response.text();
                console.error(`❌ Failed for ${tableName}:${record.id}:`, error);
            }
            
            // Small delay to avoid rate limiting
            await new Promise(resolve => setTimeout(resolve, 500));
            
        } catch (error) {
            console.error(`❌ Error processing ${tableName}:${record.id}:`, error);
        }
    }
}

async function generateAllEmbeddings() {
    console.log('🚀 Starting batch embedding generation for FlowState AI...');
    console.log('\n📚 What are embeddings?');
    console.log('Embeddings are AI-generated numerical representations of your text data.');
    console.log('They allow the AI to understand semantic meaning and relationships.\n');
    
    console.log('🎯 What this enables:');
    console.log('1. Semantic Search - Find related content by meaning, not just keywords');
    console.log('2. AI Context - Better understanding when Claude assists with your projects');
    console.log('3. Similar Task Detection - Find tasks similar to what you\'re working on');
    console.log('4. Smart Grouping - Group related activities and insights\n');
    
    // Generate embeddings for each table
    await generateEmbeddingsForTable('projects', (record) => 
        `${record.name || ''} ${record.description || ''}`
    );
    
    await generateEmbeddingsForTable('project_phases', (record) => 
        `${record.name || ''} Status: ${record.status || ''}`
    );
    
    await generateEmbeddingsForTable('tasks', (record) => 
        `${record.title || ''} ${record.description || ''} Priority: ${record.priority || ''}`
    );
    
    await generateEmbeddingsForTable('activities', (record) => 
        `${record.description || ''} Type: ${record.activity_type || ''}`
    );
    
    console.log('\n✨ Batch generation complete!');
    console.log('Refresh your dashboard to see the semantic search in action.');
}

// Usage instructions
console.log('📋 How to use this script:\n');
console.log('1. First, get your service role key from Supabase Dashboard');
console.log('2. Replace YOUR_SERVICE_ROLE_KEY in this script');
console.log('3. Run in browser console: copy/paste this entire script');
console.log('4. Or save as HTML file and open in browser\n');
console.log('To start generation, run: generateAllEmbeddings()');

// Uncomment to auto-run:
// generateAllEmbeddings();