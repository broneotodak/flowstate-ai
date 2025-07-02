// FlowState Browser Extension - Popup Script

document.addEventListener('DOMContentLoaded', async () => {
    // Load saved settings
    const settings = await chrome.storage.local.get(['serviceKey', 'enabled']);
    
    if (settings.serviceKey) {
        document.getElementById('serviceKey').value = settings.serviceKey;
    }
    
    if (settings.enabled !== undefined) {
        document.getElementById('enableToggle').checked = settings.enabled;
    }
    
    // Get current context
    updateContextDisplay();
    
    // Button handlers
    document.getElementById('refreshBtn').addEventListener('click', async () => {
        const btn = document.getElementById('refreshBtn');
        btn.disabled = true;
        btn.textContent = 'Refreshing...';
        
        chrome.runtime.sendMessage({ action: 'forceCheck' }, (response) => {
            updateContextDisplay();
            btn.disabled = false;
            btn.textContent = 'Refresh Context';
        });
    });
    
    document.getElementById('logBtn').addEventListener('click', async () => {
        const btn = document.getElementById('logBtn');
        btn.disabled = true;
        btn.textContent = 'Logging...';
        
        chrome.runtime.sendMessage({ action: 'logActivity' }, (response) => {
            btn.disabled = false;
            btn.textContent = 'Log Activity Now';
            
            if (response && response.success) {
                showStatus('Activity logged!');
            }
        });
    });
    
    document.getElementById('saveBtn').addEventListener('click', async () => {
        const serviceKey = document.getElementById('serviceKey').value;
        const enabled = document.getElementById('enableToggle').checked;
        
        await chrome.storage.local.set({ serviceKey, enabled });
        showStatus('Settings saved!');
    });
    
    document.getElementById('enableToggle').addEventListener('change', async (e) => {
        await chrome.storage.local.set({ enabled: e.target.checked });
    });
});

function updateContextDisplay() {
    chrome.runtime.sendMessage({ action: 'getContext' }, (context) => {
        const display = document.getElementById('contextDisplay');
        
        if (!context || !context.project) {
            display.innerHTML = '<div class="no-context">No active project detected</div>';
            display.classList.remove('active');
            return;
        }
        
        display.classList.add('active');
        display.innerHTML = `
            <div class="project-name">${context.project}</div>
            <div class="task">${context.task || 'General work'}</div>
            <div class="confidence">
                Confidence: ${Math.round(context.confidence * 100)}%
            </div>
            <div class="confidence-bar">
                <div class="confidence-fill" style="width: ${context.confidence * 100}%"></div>
            </div>
        `;
    });
}

function showStatus(message) {
    const btn = document.getElementById('saveBtn');
    const originalText = btn.textContent;
    btn.textContent = message;
    setTimeout(() => {
        btn.textContent = originalText;
    }, 2000);
}