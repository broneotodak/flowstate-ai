// Debug script for FlowState extension

const output = document.getElementById('output');

function log(message, type = 'info') {
    const pre = document.createElement('pre');
    pre.className = type;
    pre.textContent = `[${new Date().toLocaleTimeString()}] ${message}`;
    output.appendChild(pre);
}

async function runDiagnostics() {
    log('Starting FlowState Extension Diagnostics...', 'success');
    
    // Check storage
    try {
        const storage = await chrome.storage.local.get(['serviceKey', 'enabled', 'currentFlowState']);
        log('Storage contents: ' + JSON.stringify(storage, null, 2));
        
        if (!storage.serviceKey) {
            log('WARNING: No service key configured', 'error');
        }
    } catch (e) {
        log('Error reading storage: ' + e.message, 'error');
    }
    
    // Check alarms
    try {
        const alarms = await chrome.alarms.getAll();
        log('Active alarms: ' + JSON.stringify(alarms, null, 2));
    } catch (e) {
        log('Error reading alarms: ' + e.message, 'error');
    }
    
    // Test API connection
    try {
        const storage = await chrome.storage.local.get(['serviceKey']);
        if (storage.serviceKey) {
            log('Testing Supabase connection...');
            const response = await fetch(
                'https://YOUR_PROJECT_ID.supabase.co/rest/v1/flowstate_activities?limit=1',
                {
                    headers: {
                        'apikey': storage.serviceKey,
                        'Authorization': `Bearer ${storage.serviceKey}`
                    }
                }
            );
            log(`API Response: ${response.status} ${response.statusText}`, 
                response.ok ? 'success' : 'error');
            
            if (!response.ok) {
                const error = await response.text();
                log('API Error: ' + error, 'error');
            } else {
                const data = await response.json();
                log('Successfully fetched ' + data.length + ' activities', 'success');
            }
        }
    } catch (e) {
        log('Connection test failed: ' + e.message, 'error');
    }
    
    // Check for CSP violations
    log('\nChecking for CSP issues...');
    log('Current document CSP: ' + (document.querySelector('meta[http-equiv="Content-Security-Policy"]')?.content || 'None set'));
}

// Run diagnostics when page loads
runDiagnostics();

// Listen for messages from extension
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    log('Received message: ' + JSON.stringify(request));
});