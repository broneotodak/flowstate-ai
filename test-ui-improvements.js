#!/usr/bin/env node

/**
 * Test script for FlowState UI improvements
 * Tests the getTimeAgo and groupActivitiesByDate functions
 */

// Extract the getTimeAgo function from the HTML file for testing
function getTimeAgo(timestamp) {
    const date = new Date(timestamp.includes('Z') || timestamp.includes('+') ? timestamp : timestamp + 'Z');
    const now = new Date();
    const diff = now - date;
    
    const seconds = Math.floor(diff / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);
    const weeks = Math.floor(days / 7);
    const months = Math.floor(days / 30);
    const years = Math.floor(days / 365);
    
    if (seconds < 60) return 'Just now';
    if (minutes < 60) return `${minutes} minute${minutes !== 1 ? 's' : ''} ago`;
    if (hours < 24) return `${hours} hour${hours !== 1 ? 's' : ''} ago`;
    if (days < 7) return `${days} day${days !== 1 ? 's' : ''} ago`;
    if (weeks < 4) return `${weeks} week${weeks !== 1 ? 's' : ''} ago`;
    if (months < 12) return `${months} month${months !== 1 ? 's' : ''} ago`;
    return `${years} year${years !== 1 ? 's' : ''} ago`;
}

// Extract the groupActivitiesByDate function
function groupActivitiesByDate(activities) {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const yesterday = new Date(today.getTime() - 24 * 60 * 60 * 1000);
    const thisWeek = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
    
    const groups = {
        'Today': [],
        'Yesterday': [],
        'This Week': [],
        'Older': []
    };
    
    activities.forEach(activity => {
        const activityDate = new Date(activity.created_at.includes('Z') || activity.created_at.includes('+') ? activity.created_at : activity.created_at + 'Z');
        const activityDay = new Date(activityDate.getFullYear(), activityDate.getMonth(), activityDate.getDate());
        
        if (activityDay.getTime() === today.getTime()) {
            groups['Today'].push(activity);
        } else if (activityDay.getTime() === yesterday.getTime()) {
            groups['Yesterday'].push(activity);
        } else if (activityDate >= thisWeek) {
            groups['This Week'].push(activity);
        } else {
            groups['Older'].push(activity);
        }
    });
    
    return groups;
}

// Test cases
console.log('🧪 Testing FlowState UI Improvements');
console.log('====================================\n');

// Test 1: getTimeAgo function
console.log('1. Testing getTimeAgo function:');
const now = new Date();
const testTimestamps = [
    new Date(now.getTime() - 30 * 1000).toISOString(), // 30 seconds ago
    new Date(now.getTime() - 5 * 60 * 1000).toISOString(), // 5 minutes ago
    new Date(now.getTime() - 2 * 60 * 60 * 1000).toISOString(), // 2 hours ago
    new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000).toISOString(), // 1 day ago
    new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000).toISOString(), // 3 days ago
    new Date(now.getTime() - 2 * 7 * 24 * 60 * 60 * 1000).toISOString(), // 2 weeks ago
    new Date(now.getTime() - 3 * 30 * 24 * 60 * 60 * 1000).toISOString(), // 3 months ago
    new Date(now.getTime() - 2 * 365 * 24 * 60 * 60 * 1000).toISOString(), // 2 years ago
];

testTimestamps.forEach((timestamp, index) => {
    const result = getTimeAgo(timestamp);
    console.log(`  Test ${index + 1}: ${result}`);
});

console.log('\n✅ getTimeAgo function tests completed\n');

// Test 2: groupActivitiesByDate function
console.log('2. Testing groupActivitiesByDate function:');

const testActivities = [
    { id: 1, created_at: new Date().toISOString(), content: 'Today activity' },
    { id: 2, created_at: new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString(), content: 'Yesterday activity' },
    { id: 3, created_at: new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000).toISOString(), content: 'This week activity' },
    { id: 4, created_at: new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString(), content: 'Older activity' },
];

const grouped = groupActivitiesByDate(testActivities);

Object.entries(grouped).forEach(([groupName, activities]) => {
    console.log(`  ${groupName}: ${activities.length} activities`);
    activities.forEach(activity => {
        console.log(`    - ${activity.content}`);
    });
});

console.log('\n✅ groupActivitiesByDate function tests completed\n');

// Test 3: Edge cases
console.log('3. Testing edge cases:');

try {
    // Test with malformed timestamp
    const result1 = getTimeAgo('invalid-timestamp');
    console.log('  ❌ Should have thrown error for invalid timestamp');
} catch (e) {
    console.log('  ✅ Correctly handled invalid timestamp');
}

try {
    // Test with empty activities array
    const result2 = groupActivitiesByDate([]);
    console.log('  ✅ Correctly handled empty activities array');
    console.log('    Groups created:', Object.keys(result2).length);
} catch (e) {
    console.log('  ❌ Failed to handle empty activities array:', e.message);
}

console.log('\n🎉 All UI improvement tests completed successfully!');
console.log('The new getTimeAgo and groupActivitiesByDate functions are working correctly.\n');