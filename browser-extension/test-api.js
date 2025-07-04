// Test script to verify Supabase API connection and service key

const SUPABASE_URL = 'https://uzamamymfzhelvkwpvgt.supabase.co';

async function testAPIConnection(serviceKey) {
    console.log('Testing API connection with service key...');
    
    // Test 1: Check if we can read from activities table
    console.log('\n1. Testing READ access to activities table:');
    try {
        const response = await fetch(`${SUPABASE_URL}/rest/v1/activities?limit=1`, {
            method: 'GET',
            headers: {
                'apikey': serviceKey,
                'Authorization': `Bearer ${serviceKey}`,
                'Content-Type': 'application/json'
            }
        });
        
        console.log('Response status:', response.status);
        console.log('Response headers:', Object.fromEntries(response.headers.entries()));
        
        if (!response.ok) {
            const errorText = await response.text();
            console.error('Error response:', errorText);
        } else {
            const data = await response.json();
            console.log('Success! Data:', data);
        }
    } catch (error) {
        console.error('Fetch error:', error);
    }
    
    // Test 2: Test posting an activity
    console.log('\n2. Testing WRITE access (posting activity):');
    try {
        const activityData = {
            user_id: 'neo_todak',
            activity_type: 'browser_activity',
            description: 'Test activity from browser extension debug',
            project_name: 'FlowState',
            created_at: new Date().toISOString(),
            metadata: {
                confidence: 1.0,
                source: 'browser_extension_test'
            }
        };
        
        const response = await fetch(`${SUPABASE_URL}/rest/v1/activities`, {
            method: 'POST',
            headers: {
                'apikey': serviceKey,
                'Authorization': `Bearer ${serviceKey}`,
                'Content-Type': 'application/json',
                'Prefer': 'return=minimal'
            },
            body: JSON.stringify(activityData)
        });
        
        console.log('Response status:', response.status);
        
        if (!response.ok) {
            const errorText = await response.text();
            console.error('Error response:', errorText);
        } else {
            console.log('Success! Activity posted.');
        }
    } catch (error) {
        console.error('Fetch error:', error);
    }
    
    // Test 3: Test updating current context
    console.log('\n3. Testing current_context update:');
    try {
        const contextData = {
            user_id: 'neo_todak',
            project_name: 'FlowState',
            current_task: 'Debugging browser extension',
            current_phase: 'Development',
            last_updated: new Date().toISOString(),
            metadata: {
                confidence: 1.0,
                detected_by: 'browser_extension_test'
            }
        };
        
        const response = await fetch(
            `${SUPABASE_URL}/rest/v1/current_context?on_conflict=user_id`,
            {
                method: 'POST',
                headers: {
                    'apikey': serviceKey,
                    'Authorization': `Bearer ${serviceKey}`,
                    'Content-Type': 'application/json',
                    'Prefer': 'return=minimal,resolution=merge-duplicates'
                },
                body: JSON.stringify(contextData)
            }
        );
        
        console.log('Response status:', response.status);
        
        if (!response.ok) {
            const errorText = await response.text();
            console.error('Error response:', errorText);
        } else {
            console.log('Success! Context updated.');
        }
    } catch (error) {
        console.error('Fetch error:', error);
    }
}

// Instructions for running this test
console.log(`
To test the API connection:

1. Open Chrome DevTools Console (F12)
2. Navigate to any tab (e.g., github.com)
3. Copy and paste this entire script
4. Call the function with your service key:
   testAPIConnection('your-service-key-here')

This will test:
- Reading from the activities table
- Writing a new activity
- Updating the current context
`);

// Make the function available globally
window.testAPIConnection = testAPIConnection;