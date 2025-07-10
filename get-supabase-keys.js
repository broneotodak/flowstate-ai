#!/usr/bin/env node

// Help find the right Supabase keys

console.log('🔑 Supabase Keys for Netlify Environment Variables:\n');

console.log('1. NEXT_PUBLIC_SUPABASE_URL:');
console.log('   https://uzamamymfzhelvkwpvgt.supabase.co');

console.log('\n2. NEXT_PUBLIC_SUPABASE_ANON_KEY:');
console.log('   You need the "anon" or "public" key from your Supabase project');
console.log('   Find it at: https://app.supabase.com/project/uzamamymfzhelvkwpvgt/settings/api');
console.log('   It usually starts with "eyJ..."');

console.log('\n3. SUPABASE_SERVICE_ROLE_KEY (optional):');
console.log('   This is your current FLOWSTATE_SERVICE_KEY');
console.log('   Current value:', process.env.FLOWSTATE_SERVICE_KEY ? 
  `${process.env.FLOWSTATE_SERVICE_KEY.substring(0, 20)}...` : 
  'Not set - run: source ~/.flowstate/config');

console.log('\n📝 Note:');
console.log('   - NEXT_PUBLIC_* variables are exposed to the browser (safe for anon key)');
console.log('   - Service role key should NEVER be in NEXT_PUBLIC_* variables');
console.log('   - The dashboard should use the anon key for client-side queries');