#!/usr/bin/env node

// Debug dashboard connection and data fetching
const https = require('https');

const SUPABASE_URL = process.env.FLOWSTATE_SUPABASE_URL || 'https://uzamamymfzhelvkwpvgt.supabase.co';
const SERVICE_KEY = process.env.FLOWSTATE_SERVICE_KEY;

async function debugDashboard() {
  console.log('🔍 Debugging Dashboard Data Fetching\n');
  
  // Test the exact queries the dashboard uses
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  console.log('Testing with SERVICE KEY:', SERVICE_KEY ? '✅ Present' : '❌ Missing');
  console.log('Supabase URL:', SUPABASE_URL);
  console.log('Today\'s date for query:', today.toISOString());
  
  try {
    // 1. Today's Activities
    console.log('\n📊 Testing Today\'s Activities Query:');
    const todayResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/flowstate_activities?select=*&created_at=gte.${today.toISOString()}`,
      {
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'count=exact'
        }
      }
    );
    
    console.log('Response status:', todayResponse.status);
    console.log('Response headers:', Object.fromEntries(todayResponse.headers.entries()));
    const todayData = await todayResponse.json();
    console.log('Number of records returned:', todayData.length);
    console.log('First record:', todayData[0]);
    
    // 2. Total Commits
    console.log('\n💾 Testing Total Commits Query:');
    const commitResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/flowstate_activities?select=*&activity_type=eq.git_commit`,
      {
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'count=exact'
        }
      }
    );
    
    const commitData = await commitResponse.json();
    console.log('Git commits found:', commitData.length);
    if (commitData.length > 0) {
      console.log('Sample commit:', commitData[0]);
    }
    
    // 3. Active Projects (last 7 days)
    console.log('\n📁 Testing Active Projects Query:');
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    
    const projectResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/flowstate_activities?select=project_name&created_at=gte.${sevenDaysAgo.toISOString()}`,
      {
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    const projectData = await projectResponse.json();
    const uniqueProjects = [...new Set(projectData.map(p => p.project_name))];
    console.log('Active projects:', uniqueProjects.length);
    console.log('Projects:', uniqueProjects);
    
    // 4. Connected Machines
    console.log('\n💻 Testing Connected Machines Query:');
    const machineResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/user_machines?select=*&is_active=eq.true`,
      {
        headers: {
          'apikey': SERVICE_KEY,
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    const machineData = await machineResponse.json();
    console.log('Active machines:', machineData.length);
    machineData.forEach(m => {
      console.log(`  - ${m.machine_name} (${m.os}) - Last active: ${m.last_active}`);
    });
    
  } catch (error) {
    console.error('Error:', error);
  }
}

debugDashboard();