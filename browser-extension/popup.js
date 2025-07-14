// FlowState Browser Extension - Enhanced Popup Script

document.addEventListener('DOMContentLoaded', async () => {
    // Load saved settings
    const settings = await chrome.storage.local.get(['serviceKey', 'enabled']);
    
    if (settings.serviceKey) {
        // Hide service key input and save button, show reconfigure button
        document.getElementById('serviceKey').style.display = 'none';
        document.getElementById('saveBtn').style.display = 'none';
        document.getElementById('reconfigureBtn').style.display = 'block';
        
        document.getElementById('reconfigureBtn').addEventListener('click', () => {
            document.getElementById('serviceKey').style.display = 'block';
            document.getElementById('serviceKey').value = '';
            document.getElementById('saveBtn').style.display = 'block';
            document.getElementById('reconfigureBtn').style.display = 'none';
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
        btn.classList.add('loading');
        
        chrome.runtime.sendMessage({ action: 'refresh' }, (response) => {
            displayFlowState();
            setTimeout(() => btn.classList.remove('loading'), 800);
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
                
                // Hide the service key field and save button, show reconfigure
                document.getElementById('serviceKey').style.display = 'none';
                document.getElementById('saveBtn').style.display = 'none';
                document.getElementById('reconfigureBtn').style.display = 'block';
                
                // Add reconfigure handler
                document.getElementById('reconfigureBtn').addEventListener('click', () => {
                    document.getElementById('serviceKey').style.display = 'block';
                    document.getElementById('serviceKey').value = '';
                    document.getElementById('saveBtn').style.display = 'block';
                    document.getElementById('reconfigureBtn').style.display = 'none';
                });
                
                // Trigger refresh
                chrome.runtime.sendMessage({ action: 'refresh' }, () => {
                    displayFlowState();
                });
            } else {
                showError(result.message || 'Connection failed');
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
                    <strong>Connection Error:</strong> ${escapeHtml(flowState.error)}
                    <div style="margin-top: 8px; font-size: 12px; opacity: 0.8;">
                        Check your service key configuration
                    </div>
                </div>
            `;
            return;
        }
        
        if (!flowState || !flowState.activities || flowState.activities.length === 0) {
            content.innerHTML = `
                <div class="no-activities">
                    <p>No recent activities</p>
                    <p style="font-size: 12px; margin-top: 8px; opacity: 0.7;">
                        ${flowState ? 'No activities in the last 2 hours' : 'Configure your service key below'}
                    </p>
                </div>
            `;
            return;
        }
        
        // Limit to 5 activities and get unique projects
        const recentActivities = flowState.activities.slice(0, 5);
        const activeProjects = getUniqueProjects(recentActivities);
        const mostRecentActivity = recentActivities[0];
        const timeAgo = getTimeAgo(new Date(mostRecentActivity.created_at));
        const recentMachine = mostRecentActivity.metadata?.machine || mostRecentActivity.machine || 'Unknown';
        
        let html = `
            <div class="status-overview">
                <div class="active-projects">
                    ${activeProjects.map(project => 
                        `<div class="project-chip">${escapeHtml(project)}</div>`
                    ).join('')}
                </div>
                <div class="status-meta">
                    <span>🕒 Last activity ${timeAgo}</span>
                    <span>•</span>
                    <span>${getMachineIcon(recentMachine)} ${escapeHtml(formatMachine(recentMachine))}</span>
                </div>
            </div>
            
            <h3 class="section-title">
                <span><span>📋</span> Recent Activities</span>
                ${recentActivities.length > 1 ? '<span class="scroll-hint">scroll for more</span>' : ''}
            </h3>
            <div class="activities">
        `;
        
        recentActivities.forEach((activity, index) => {
            const activityTime = getTimeAgo(new Date(activity.created_at));
            const machine = activity.metadata?.machine || activity.machine || 'Unknown';
            const machineIcon = getMachineIcon(machine);
            
            html += `
                <div class="activity-item">
                    <div class="activity-header">
                        <span class="activity-project">${escapeHtml(activity.project_name || 'Unknown Project')}</span>
                        <span class="activity-time">${activityTime}</span>
                    </div>
                    <div class="activity-description">${escapeHtml(truncateText(activity.activity_description, 80))}</div>
                    <div class="activity-machine">
                        <span class="machine-icon">${machineIcon}</span>
                        <span>${escapeHtml(formatMachine(machine))}</span>
                    </div>
                </div>
            `;
        });
        
        html += '</div>';
        
        // Add scroll indicator if there are more than 1 activity
        if (recentActivities.length > 1) {
            // Will be applied after content is set
            setTimeout(() => {
                const activitiesDiv = document.querySelector('.activities');
                if (activitiesDiv) {
                    activitiesDiv.classList.add('has-more');
                }
            }, 10);
        }
        
        // Add last updated time
        if (flowState.lastUpdated) {
            const lastUpdated = new Date(flowState.lastUpdated);
            html += `<div class="last-updated">
                Last updated: ${lastUpdated.toLocaleTimeString()}
            </div>`;
        }
        
        content.innerHTML = html;
    });
}

function getUniqueProjects(activities) {
    const projects = new Set();
    activities.forEach(activity => {
        const projectName = activity.project_name || 'Unknown Project';
        if (projectName !== 'Unknown Project') {
            projects.add(projectName);
        }
    });
    
    // If no known projects, add the unknown project
    if (projects.size === 0) {
        projects.add('Unknown Project');
    }
    
    return Array.from(projects).slice(0, 4); // Limit to 4 project chips
}

function truncateText(text, maxLength) {
    if (!text) return '';
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
}

function getTimeAgo(date) {
    const seconds = Math.floor((new Date() - date) / 1000);
    
    if (seconds < 60) return 'just now';
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
    if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
    return `${Math.floor(seconds / 86400)}d ago`;
}

function formatMachine(machine) {
    if (!machine || machine === 'Unknown') return 'Unknown';
    
    // Improved machine name formatting
    if (machine.includes('MacBook')) return 'MacBook Pro';
    if (machine.includes('Chrome Extension') || machine.includes('Browser')) return 'Browser';
    if (machine.includes('claude-cli') || machine.includes('Claude Code')) return 'Claude CLI';
    if (machine.includes('Docker')) return 'Docker';
    if (machine.includes('VS Code') || machine.includes('VSCode')) return 'VS Code';
    if (machine.includes('Cursor')) return 'Cursor';
    if (machine.includes('Windows')) return 'Windows PC';
    
    // Truncate long machine names
    return truncateText(machine, 20);
}

function getMachineIcon(machine) {
    if (!machine) return '💻';
    
    if (machine.includes('MacBook')) return '💻';
    if (machine.includes('Chrome Extension') || machine.includes('Browser')) return '🌐';
    if (machine.includes('claude-cli') || machine.includes('Claude Code')) return '🤖';
    if (machine.includes('Docker')) return '🐳';
    if (machine.includes('GitHub Actions')) return '⚙️';
    if (machine.includes('VS Code') || machine.includes('VSCode')) return '📝';
    if (machine.includes('Cursor')) return '✏️';
    if (machine.includes('Windows')) return '🖥️';
    
    return '💻';
}

function showStatus(message) {
    const btn = document.getElementById('saveBtn');
    const originalText = btn.textContent;
    const originalClass = btn.className;
    
    btn.textContent = message;
    btn.className = 'btn btn-primary';
    btn.style.opacity = '0.7';
    
    setTimeout(() => {
        btn.textContent = originalText;
        btn.className = originalClass;
        btn.style.opacity = '1';
    }, 2000);
}

function showError(message) {
    const content = document.getElementById('mainContent');
    const errorHtml = `<div class="error">${escapeHtml(message)}</div>`;
    
    // If there's existing content, prepend error, otherwise replace
    if (content.innerHTML.includes('no-activities') || content.innerHTML.includes('loading')) {
        content.innerHTML = errorHtml;
    } else {
        content.innerHTML = errorHtml + content.innerHTML;
    }
    
    // Auto-remove error after 5 seconds
    setTimeout(() => {
        const error = content.querySelector('.error');
        if (error) {
            error.style.opacity = '0';
            error.style.transform = 'translateY(-10px)';
            setTimeout(() => error.remove(), 300);
        }
    }, 5000);
}

function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
