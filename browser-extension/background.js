// FlowState Browser Extension - Background Service Worker

const SUPABASE_URL = 'https://uzamamymfzhelvkwpvgt.supabase.co';
const CHECK_INTERVAL = 30000; // Check every 30 seconds
const ACTIVITY_INTERVAL = 300000; // Log activity every 5 minutes

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
  ],
  // Auto-detect any GitHub project
  'GitHub': [
    /github\.com/i
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
  console.log('FlowState Context Tracker installed');
  
  // Set up alarms for periodic checks
  chrome.alarms.create('checkContext', { periodInMinutes: 0.5 });
  chrome.alarms.create('logActivity', { periodInMinutes: 5 });
  
  // Load saved configuration
  chrome.storage.local.get(['serviceKey', 'enabled'], (data) => {
    if (!data.serviceKey) {
      console.log('Service key not configured');
    }
  });
});

// Listen for alarm events
chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === 'checkContext') {
    checkCurrentContext();
  } else if (alarm.name === 'logActivity') {
    logCurrentActivity();
  }
});

// Listen for tab updates
chrome.tabs.onActivated.addListener(() => {
  checkCurrentContext();
});

chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === 'complete') {
    checkCurrentContext();
  }
});

// Main context detection function
async function checkCurrentContext() {
  try {
    // Get all tabs
    const tabs = await chrome.tabs.query({});
    
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
      const detection = detectProjectFromTab(activeTab);
      if (detection.project) {
        detectedProject = detection.project;
        confidence = detection.confidence;
        taskDescription = detection.task;
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
      
      // Update badge to show current project
      updateBadge(detectedProject);
      
      // Store in local storage
      chrome.storage.local.set({ currentContext });
    }
    
  } catch (error) {
    console.error('Error checking context:', error);
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
      } else if (repoName) {
        // Use the repository name as the project
        project = repoName;
        confidence = 0.8;
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
  
  return { project, confidence, task };
}

// Log activity to Supabase
async function logCurrentActivity() {
  if (!currentContext.project) return;
  
  chrome.storage.local.get(['serviceKey', 'enabled'], async (data) => {
    if (!data.serviceKey || data.enabled === false) return;
    
    try {
      // Log activity
      // Get or create machine ID
      let machineId = await chrome.storage.local.get('machineId');
      if (!machineId.machineId) {
        machineId = { machineId: `browser_${Date.now()}_${Math.random().toString(36).substr(2, 9)}` };
        await chrome.storage.local.set(machineId);
      }
      
      const activityData = {
        user_id: 'neo_todak',
        activity_type: 'browser_activity',
        activity_description: currentContext.task || `Working on ${currentContext.project}`,
        project_name: currentContext.project,
        created_at: new Date().toISOString(),
        metadata: {
          confidence: currentContext.confidence,
          source: 'browser_extension',
          machine_id: machineId.machineId,
          machine_name: 'Browser Extension'
        }
      };
      
      const activityResponse = await fetch(`${SUPABASE_URL}/rest/v1/activity_log`, {
        method: 'POST',
        headers: {
          'apikey': data.serviceKey,
          'Authorization': `Bearer ${data.serviceKey}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal'
        },
        body: JSON.stringify(activityData)
      });
      
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
      
      console.log('Activity logged successfully');
      
    } catch (error) {
      console.error('Error logging activity:', error);
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
}

// Message handler for popup
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
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
    });
    return true;
  }
});