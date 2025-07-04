// FlowState Browser Extension - Background Service Worker (Debug Version)

const SUPABASE_URL = 'https://uzamamymfzhelvkwpvgt.supabase.co';
const CHECK_INTERVAL = 30000; // Check every 30 seconds
const ACTIVITY_INTERVAL = 300000; // Log activity every 5 minutes
const DEBUG = true; // Enable debug logging

// Enhanced logging function
const log = (...args) => {
    if (DEBUG) {
        console.log('[FlowState]', new Date().toISOString(), ...args);
    }
};

let lastActivity = {};
let currentContext = {
  project: null,
  task: null,
  confidence: 0
};

// Project detection patterns
const PROJECT_PATTERNS = {
  'FlowState': [
    /flowstate/i,
    /flow-state/i,
    /todak-ai/i,
    /embeddings/i,
    /context detection/i
  ],
  'ClaudeN': [
    /clauden/i,
    /claude\.ai.*dashboard/i,
    /anthropic.*dashboard/i
  ]
};

// Task detection patterns based on URLs and titles
const TASK_PATTERNS = {
  'github.com': {
    '/issues/': 'Managing issues',
    '/pull/': 'Reviewing pull requests',
    '/commit/': 'Reviewing commits',
    '/tree/': 'Browsing code',
    '/blob/': 'Reading code',
    '/edit/': 'Editing code',
    '/new/': 'Creating new file'
  },
  'claude.ai': {
    'FlowState': 'AI conversation about FlowState',
    'embedding': 'Working on embeddings',
    'context': 'Improving context detection',
    'tracking': 'Implementing activity tracking'
  },
  'localhost': {
    ':3000': 'Local development',
    ':8080': 'Testing application',
    ':5173': 'Vite development'
  }
};

// Initialize extension
chrome.runtime.onInstalled.addListener(() => {
  log('Extension installed/updated');
  
  // Set up alarms for periodic checks
  chrome.alarms.create('checkContext', { periodInMinutes: 0.5 });
  chrome.alarms.create('logActivity', { periodInMinutes: 5 });
  
  // Load and validate saved configuration
  chrome.storage.local.get(['serviceKey', 'enabled'], (data) => {
    log('Loaded configuration:', { 
      hasServiceKey: !!data.serviceKey, 
      enabled: data.enabled,
      keyPrefix: data.serviceKey ? data.serviceKey.substring(0, 10) + '...' : 'none'
    });
    
    if (!data.serviceKey) {
      log('WARNING: Service key not configured');
      // Show notification
      chrome.notifications.create({
        type: 'basic',
        iconUrl: 'icon48.png',
        title: 'FlowState Setup Required',
        message: 'Please configure your Supabase service key in the extension settings.'
      });
    } else {
      // Test the service key
      testServiceKey(data.serviceKey);
    }
  });
});

// Test service key validity
async function testServiceKey(serviceKey) {
  log('Testing service key...');
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/activities?limit=1`, {
      method: 'GET',
      headers: {
        'apikey': serviceKey,
        'Authorization': `Bearer ${serviceKey}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (response.ok) {
      log('Service key is valid!');
    } else {
      log('Service key test failed:', response.status, response.statusText);
      const errorText = await response.text();
      log('Error details:', errorText);
    }
  } catch (error) {
    log('Service key test error:', error);
  }
}

// Listen for alarm events
chrome.alarms.onAlarm.addListener((alarm) => {
  log(`Alarm triggered: ${alarm.name}`);
  if (alarm.name === 'checkContext') {
    checkCurrentContext();
  } else if (alarm.name === 'logActivity') {
    logCurrentActivity();
  }
});

// Listen for tab updates
chrome.tabs.onActivated.addListener((activeInfo) => {
  log('Tab activated:', activeInfo);
  checkCurrentContext();
});

chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === 'complete') {
    log('Tab updated:', tab.url);
    checkCurrentContext();
  }
});

// Main context detection function
async function checkCurrentContext() {
  try {
    // Get all tabs
    const tabs = await chrome.tabs.query({});
    log(`Checking context across ${tabs.length} tabs`);
    
    // Analyze active tabs
    const activeTab = tabs.find(tab => tab.active);
    const recentTabs = tabs.filter(tab => tab.lastAccessed && 
      (Date.now() - tab.lastAccessed < 600000)); // Last 10 minutes
    
    // Detect project from tabs
    let detectedProject = null;
    let confidence = 0;
    let taskDescription = '';
    
    // Check active tab first
    if (activeTab) {
      log('Active tab:', activeTab.url, activeTab.title);
      const detection = detectProjectFromTab(activeTab);
      if (detection.project) {
        detectedProject = detection.project;
        confidence = detection.confidence;
        taskDescription = detection.task;
        log('Detected from active tab:', detection);
      }
    }
    
    // Check recent tabs if no strong match
    if (confidence < 0.8) {
      for (const tab of recentTabs) {
        const detection = detectProjectFromTab(tab);
        if (detection.confidence > confidence) {
          detectedProject = detection.project;
          confidence = detection.confidence;
          taskDescription = detection.task;
          log('Better match from recent tab:', detection);
        }
      }
    }
    
    // Update context if changed significantly
    if (detectedProject && (
      detectedProject !== currentContext.project ||
      Math.abs(confidence - currentContext.confidence) > 0.2
    )) {
      currentContext = {
        project: detectedProject,
        task: taskDescription,
        confidence: confidence,
        timestamp: new Date().toISOString()
      };
      
      log('Context updated:', currentContext);
      
      // Update badge to show current project
      updateBadge(detectedProject);
      
      // Store in local storage
      chrome.storage.local.set({ currentContext });
    } else if (!detectedProject) {
      log('No project detected from current tabs');
    }
    
  } catch (error) {
    log('ERROR checking context:', error);
  }
}

// Detect project from a single tab
function detectProjectFromTab(tab) {
  if (!tab.url || !tab.title) {
    return { project: null, confidence: 0, task: '' };
  }
  
  let project = null;
  let confidence = 0;
  let task = '';
  
  try {
    // Check URL patterns
    const url = new URL(tab.url);
    
    // GitHub repository detection
    if (url.hostname === 'github.com') {
      const pathParts = url.pathname.split('/');
      if (pathParts.length >= 3) {
        const repoName = pathParts[2];
        
        // Check if it's a known project
        if (repoName.toLowerCase().includes('flowstate')) {
          project = 'FlowState';
          confidence = 0.9;
        } else if (repoName.toLowerCase().includes('clauden')) {
          project = 'ClaudeN';
          confidence = 0.9;
        }
        
        // Detect task from GitHub URL
        for (const [pattern, taskName] of Object.entries(TASK_PATTERNS['github.com'])) {
          if (url.pathname.includes(pattern)) {
            task = taskName;
            break;
          }
        }
      }
    }
    
    // Claude.ai detection
    if (url.hostname === 'claude.ai') {
      // Check conversation content from title
      const lowerTitle = tab.title.toLowerCase();
      
      for (const [keyword, taskName] of Object.entries(TASK_PATTERNS['claude.ai'])) {
        if (lowerTitle.includes(keyword.toLowerCase())) {
          task = taskName;
          
          // Check which project based on patterns
          for (const [projName, patterns] of Object.entries(PROJECT_PATTERNS)) {
            if (patterns.some(pattern => pattern.test(lowerTitle))) {
              project = projName;
              confidence = 0.8;
              break;
            }
          }
          break;
        }
      }
    }
    
    // If no specific project detected, check title patterns
    if (!project) {
      const combinedText = `${tab.title} ${tab.url}`.toLowerCase();
      
      for (const [projName, patterns] of Object.entries(PROJECT_PATTERNS)) {
        const matches = patterns.filter(pattern => pattern.test(combinedText)).length;
        if (matches > 0) {
          project = projName;
          confidence = Math.min(0.7, matches * 0.2);
          task = `Working on ${projName}`;
          break;
        }
      }
    }
  } catch (error) {
    log('Error detecting project from tab:', error);
  }
  
  return { project, confidence, task };
}

// Log activity to Supabase
async function logCurrentActivity() {
  log('Attempting to log activity...');
  
  if (!currentContext.project) {
    log('No project context to log');
    return;
  }
  
  chrome.storage.local.get(['serviceKey', 'enabled'], async (data) => {
    if (!data.serviceKey) {
      log('Cannot log: Service key not configured');
      return;
    }
    
    if (data.enabled === false) {
      log('Cannot log: Extension is disabled');
      return;
    }
    
    try {
      // Log activity
      const activityData = {
        user_id: 'neo_todak',
        activity_type: 'browser_activity',
        description: currentContext.task || `Working on ${currentContext.project}`,
        project_name: currentContext.project,
        created_at: new Date().toISOString(),
        metadata: {
          confidence: currentContext.confidence,
          source: 'browser_extension'
        }
      };
      
      log('Posting activity:', activityData);
      
      const activityResponse = await fetch(`${SUPABASE_URL}/rest/v1/activities`, {
        method: 'POST',
        headers: {
          'apikey': data.serviceKey,
          'Authorization': `Bearer ${data.serviceKey}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal'
        },
        body: JSON.stringify(activityData)
      });
      
      log('Activity response:', activityResponse.status, activityResponse.statusText);
      
      if (!activityResponse.ok) {
        const errorText = await activityResponse.text();
        log('Activity post error:', errorText);
      }
      
      // Update current context
      const contextData = {
        user_id: 'neo_todak',
        project_name: currentContext.project,
        current_task: currentContext.task,
        current_phase: 'Development',
        last_updated: new Date().toISOString(),
        metadata: {
          confidence: currentContext.confidence,
          detected_by: 'browser_extension'
        }
      };
      
      log('Updating context:', contextData);
      
      const contextResponse = await fetch(
        `${SUPABASE_URL}/rest/v1/current_context?on_conflict=user_id`,
        {
          method: 'POST',
          headers: {
            'apikey': data.serviceKey,
            'Authorization': `Bearer ${data.serviceKey}`,
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal,resolution=merge-duplicates'
          },
          body: JSON.stringify(contextData)
        }
      );
      
      log('Context response:', contextResponse.status, contextResponse.statusText);
      
      if (!contextResponse.ok) {
        const errorText = await contextResponse.text();
        log('Context update error:', errorText);
      }
      
      if (activityResponse.ok && contextResponse.ok) {
        log('SUCCESS: Activity logged successfully');
        // Update last activity time
        lastActivity[currentContext.project] = Date.now();
      }
      
    } catch (error) {
      log('ERROR logging activity:', error);
    }
  });
}

// Update extension badge
function updateBadge(project) {
  if (!project) {
    chrome.action.setBadgeText({ text: '' });
    return;
  }
  
  // Show abbreviated project name
  const badge = project.substring(0, 2).toUpperCase();
  chrome.action.setBadgeText({ text: badge });
  chrome.action.setBadgeBackgroundColor({ color: '#2196F3' });
  log('Badge updated:', badge);
}

// Message handler for popup
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  log('Received message:', request.action);
  
  if (request.action === 'getContext') {
    sendResponse(currentContext);
  } else if (request.action === 'forceCheck') {
    checkCurrentContext().then(() => {
      sendResponse(currentContext);
    });
    return true; // Keep channel open for async response
  } else if (request.action === 'logActivity') {
    logCurrentActivity().then(() => {
      sendResponse({ success: true });
    }).catch(error => {
      log('Error in logActivity message handler:', error);
      sendResponse({ success: false, error: error.message });
    });
    return true;
  } else if (request.action === 'getDebugInfo') {
    chrome.storage.local.get(['serviceKey', 'enabled', 'currentContext'], (data) => {
      sendResponse({
        hasServiceKey: !!data.serviceKey,
        enabled: data.enabled,
        currentContext: data.currentContext,
        lastActivity: lastActivity
      });
    });
    return true;
  }
});