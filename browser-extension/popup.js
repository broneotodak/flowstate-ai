// FlowState Browser Extension - Popup Script

document.addEventListener('DOMContentLoaded', async () => {
    // Load saved settings
    const settings = await chrome.storage.local.get(['serviceKey', 'enabled']);
    
    if (settings.serviceKey) {
        // Hide service key input and show configured state
        document.getElementById('serviceKey').style.display = 'none';
        const saveBtn = document.getElementById('saveBtn');
        saveBtn.textContent = 'Reconfigure';
        saveBtn.addEventListener('click', () => {
            document.getElementById('serviceKey').style.display = 'block';
            document.getElementById('serviceKey').value = '';
            saveBtn.textContent = 'Save Settings';
        });
    }
    
    if (settings.enabled !== undefined) {
        document.getElementById('enableToggle').checked = settings.enabled;
    }
    
    // Initial display
    displayFlowState();
    
    // Button handlers
    document.getElementById('refreshBtn').addEventListener('click', async () => {
        const btn = document.getElementById('refreshBtn');
        btn.classList.add('spinning');
        
        chrome.runtime.sendMessage({ action: 'refresh' }, (response) => {
            displayFlowState();
            setTimeout(() => btn.classList.remove('spinning'), 500);
        });
    });
    
    const saveBtnHandler = async () => {
        const serviceKey = document.getElementById('serviceKey').value.trim();
        const enabled = document.getElementById('enableToggle').checked;
        
        if (!serviceKey) {
            showError('Please enter a service key');
            return;
        }
        
        // Test the connection first
        showStatus('Testing connection...');
        chrome.runtime.sendMessage({ 
            action: 'testConnection', 
            serviceKey: serviceKey 
        }, async (result) => {
            if (result.success) {
                // Save settings
                await chrome.storage.local.set({ serviceKey, enabled });
                showStatus('Settings saved!');
                
                // Hide the service key field
                document.getElementById('serviceKey').style.display = 'none';
                const saveBtn = document.getElementById('saveBtn');
                saveBtn.textContent = 'Reconfigure';
                
                // Remove old handler and add new one
                saveBtn.removeEventListener('click', saveBtnHandler);
                saveBtn.addEventListener('click', () => {
                    document.getElementById('serviceKey').style.display = 'block';
                    document.getElementById('serviceKey').value = '';
                    saveBtn.textContent = 'Save Settings';
                    saveBtn.removeEventListener('click', arguments.callee);
                    saveBtn.addEventListener('click', saveBtnHandler);
                });
                
                // Trigger refresh
                chrome.runtime.sendMessage({ action: 'refresh' }, () => {
                    displayFlowState();
                });
            } else {
                showError(result.message);
            }
        });
    };
    
    document.getElementById('saveBtn').addEventListener('click', saveBtnHandler);
    
    document.getElementById('enableToggle').addEventListener('change', async (e) => {
        await chrome.storage.local.set({ enabled: e.target.checked });
        if (e.target.checked) {
            chrome.runtime.sendMessage({ action: 'refresh' });
        }
    });
    
    document.getElementById('dashboardBtn').addEventListener('click', () => {
        chrome.runtime.sendMessage({ action: 'openDashboard' });
    });
});

function displayFlowState() {
    chrome.runtime.sendMessage({ action: 'getFlowState' }, (flowState) => {
        const content = document.getElementById('mainContent');
        
        // Handle errors
        if (flowState && flowState.error) {
            content.innerHTML = `
                <div class="error">
                    <strong>Error:</strong> ${escapeHtml(flowState.error)}
                    <div style="margin-top: 10px; font-size: 12px;">
                        <a href="#" id="consoleLink" style="color: inherit;">View console for details</a>
                    </div>
                </div>
            `;
            return;
        }
        
        if (!flowState || !flowState.activities || flowState.activities.length === 0) {
            content.innerHTML = `
                <div class="no-activities">
                    <p>No recent activities</p>
                    <p style="font-size: 12px; margin-top: 10px;">
                        ${flowState ? 'No activities in the last 2 hours' : 'Configure your service key below'}
                    </p>
                </div>
            `;
            return;
        }
        
        const currentActivity = flowState.activities[0];
        const timeAgo = getTimeAgo(new Date(currentActivity.created_at));
        
        let html = `
            <div class="current-status">
                <div class="project-name">${escapeHtml(currentActivity.project_name || 'Unknown Project')}</div>
                <div class="status-meta">
                    Active ${timeAgo} on ${escapeHtml(formatMachine(currentActivity.machine))}
                </div>
            </div>
            
            <h3 style="margin: 0 0 10px 0; font-size: 14px; color: #666;">Recent Activities</h3>
            <div class="activities">
        `;
        
        flowState.activities.forEach(activity => {
            const activityTime = getTimeAgo(new Date(activity.created_at));
            const machineIcon = getMachineIcon(activity.machine);
            
            html += `
                <div class="activity-item">
                    <div class="activity-header">
                        <span class="activity-project">${escapeHtml(activity.project_name || 'Unknown')}</span>
                        <span class="activity-time">${activityTime}</span>
                    </div>
                    <div class="activity-description">${escapeHtml(activity.activity_description)}</div>
                    <div class="activity-machine">
                        <span class="machine-icon">${machineIcon}</span>
                        <span>${escapeHtml(formatMachine(activity.machine))}</span>
                    </div>
                </div>
            `;
        });
        
        html += '</div>';
        
        // Add last updated time
        if (flowState.lastUpdated) {
            const lastUpdated = new Date(flowState.lastUpdated);
            html += `<div style="text-align: center; font-size: 11px; color: #999; margin-top: 10px;">
                Last updated: ${lastUpdated.toLocaleTimeString()}
            </div>`;
        }
        
        content.innerHTML = html;
        
        // Add event listener for console link if it exists
        const consoleLink = document.getElementById('consoleLink');
        if (consoleLink) {
            consoleLink.addEventListener('click', (e) => {
                e.preventDefault();
                chrome.runtime.openOptionsPage();
            });
        }
    });
}

function getTimeAgo(date) {
    const seconds = Math.floor((new Date() - date) / 1000);
    
    if (seconds < 60) return 'just now';
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
    if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
    return `${Math.floor(seconds / 86400)}d ago`;
}

function formatMachine(machine) {
    if (!machine) return 'Unknown';
    
    // Simplify machine names
    if (machine.includes('MacBook')) return 'MacBook';
    if (machine.includes('Chrome Extension')) return 'Browser';
    if (machine.includes('claude-cli')) return 'Claude CLI';
    if (machine.includes('Docker')) return 'Docker';
    
    return machine;
}

function getMachineIcon(machine) {
    if (!machine) return '💻';
    
    if (machine.includes('MacBook')) return '💻';
    if (machine.includes('Chrome Extension')) return '🌐';
    if (machine.includes('claude-cli')) return '🤖';
    if (machine.includes('Docker')) return '🐳';
    if (machine.includes('GitHub Actions')) return '⚙️';
    
    return '💻';
}

function showStatus(message) {
    const btn = document.getElementById('saveBtn');
    const originalText = btn.textContent;
    btn.textContent = message;
    setTimeout(() => {
        btn.textContent = originalText;
    }, 2000);
}

function showError(message) {
    const content = document.getElementById('mainContent');
    content.innerHTML = `<div class="error">${escapeHtml(message)}</div>` + content.innerHTML;
    setTimeout(() => {
        // Remove error message
        const error = content.querySelector('.error');
        if (error) error.remove();
    }, 5000);
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

