// FlowState Browser Extension - Status Viewer
// Shows your current FlowState activities from all machines

const SUPABASE_URL = 'https://YOUR_PROJECT_ID.supabase.co';
const REFRESH_INTERVAL = 30000; // Refresh every 30 seconds

let currentFlowState = {
  activities: [],
  machines: [],
  currentProject: null,
  lastUpdated: null,
  error: null
};

// Initialize extension
chrome.runtime.onInstalled.addListener(() => {
  console.log('FlowState Status Viewer installed');
  
  // Set up periodic refresh
  chrome.alarms.create('refreshFlowState', { periodInMinutes: 0.5 });
  
  // Initial state
  chrome.storage.local.set({ 
    currentFlowState: {
      ...currentFlowState,
      error: 'Extension just installed. Please configure your service key.'
    }
  });
  
  // Load saved configuration
  chrome.storage.local.get(['serviceKey', 'enabled'], (data) => {
    if (!data.serviceKey) {
      console.log('Service key not configured');
      updateBadge('!');
    } else {
      // Initial fetch
      fetchFlowState();
    }
  });
});

// Listen for alarm events
chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === 'refreshFlowState') {
    chrome.storage.local.get(['enabled'], (data) => {
      if (data.enabled !== false) {
        fetchFlowState();
      }
    });
  }
});

// Main function to fetch FlowState data
async function fetchFlowState() {
  console.log('Fetching FlowState data...');
  
  try {
    const data = await chrome.storage.local.get(['serviceKey', 'enabled']);
    
    if (!data.serviceKey) {
      currentFlowState = {
        ...currentFlowState,
        error: 'No service key configured',
        lastUpdated: new Date().toISOString()
      };
      chrome.storage.local.set({ currentFlowState });
      updateBadge('!');
      return;
    }
    
    if (data.enabled === false) {
      console.log('Extension is disabled');
      return;
    }
    
    // Fetch recent activities (last 2 hours)
    const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString();
    
    console.log('Fetching from:', `${SUPABASE_URL}/rest/v1/flowstate_activities`);
    
    // Get activities using the view
    const activitiesResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/flowstate_activities?created_at=gte.${twoHoursAgo}&order=created_at.desc&limit=20`,
      {
        method: 'GET',
        headers: {
          'apikey': data.serviceKey,
          'Authorization': `Bearer ${data.serviceKey}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=representation'
        }
      }
    );
    
    console.log('Response status:', activitiesResponse.status);
    
    if (!activitiesResponse.ok) {
      const errorText = await activitiesResponse.text();
      console.error('API Error:', errorText);
      throw new Error(`API Error (${activitiesResponse.status}): ${errorText}`);
    }
    
    const activities = await activitiesResponse.json();
    console.log('Fetched activities:', activities.length);
    
    // Get unique machines from recent activities
    const machineNames = [...new Set(activities.map(a => a.machine).filter(Boolean))];
    
    // Determine current project (most recent activity)
    const currentProject = activities.length > 0 ? activities[0].project_name : null;
    
    // Update state
    currentFlowState = {
      activities: activities.slice(0, 10), // Keep last 10 activities
      machines: machineNames,
      currentProject: currentProject,
      lastUpdated: new Date().toISOString(),
      error: null
    };
    
    // Update badge
    updateBadge(currentProject);
    
    // Store in local storage for popup
    chrome.storage.local.set({ currentFlowState });
    
    console.log('FlowState updated successfully');
    
  } catch (error) {
    console.error('Error fetching FlowState:', error);
    currentFlowState = {
      ...currentFlowState,
      error: error.message,
      lastUpdated: new Date().toISOString()
    };
    chrome.storage.local.set({ currentFlowState });
    updateBadge('!');
  }
}

// Update extension badge
function updateBadge(project) {
  if (!project) {
    chrome.action.setBadgeText({ text: '' });
    return;
  }
  
  if (project === '!') {
    // Error state
    chrome.action.setBadgeText({ text: '!' });
    chrome.action.setBadgeBackgroundColor({ color: '#F44336' });
    return;
  }
  
  // Show abbreviated project name
  const badge = project.substring(0, 2).toUpperCase();
  chrome.action.setBadgeText({ text: badge });
  chrome.action.setBadgeBackgroundColor({ color: '#2196F3' });
}

// Message handler for popup
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  console.log('Received message:', request.action);
  
  if (request.action === 'getFlowState') {
    chrome.storage.local.get(['currentFlowState'], (data) => {
      sendResponse(data.currentFlowState || currentFlowState);
    });
    return true;
  } else if (request.action === 'refresh') {
    fetchFlowState().then(() => {
      chrome.storage.local.get(['currentFlowState'], (data) => {
        sendResponse(data.currentFlowState || currentFlowState);
      });
    });
    return true; // Keep channel open for async response
  } else if (request.action === 'openDashboard') {
    chrome.tabs.create({ url: 'https://flowstate.neotodak.com' });
  } else if (request.action === 'testConnection') {
    // Test the service key
    testServiceKey(request.serviceKey).then(result => {
      sendResponse(result);
    });
    return true;
  }
});

// Test service key function
async function testServiceKey(serviceKey) {
  try {
    const response = await fetch(
      `${SUPABASE_URL}/rest/v1/flowstate_activities?limit=1`,
      {
        method: 'GET',
        headers: {
          'apikey': serviceKey,
          'Authorization': `Bearer ${serviceKey}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    if (response.ok) {
      return { success: true, message: 'Connection successful!' };
    } else {
      const error = await response.text();
      return { success: false, message: `Error ${response.status}: ${error}` };
    }
  } catch (error) {
    return { success: false, message: `Connection failed: ${error.message}` };
  }
}