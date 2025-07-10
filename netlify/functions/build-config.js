// Netlify build plugin to inject environment variables
const fs = require('fs');
const path = require('path');

exports.onPreBuild = async ({ inputs, utils }) => {
    const configPath = path.join(process.cwd(), 'config.js');
    
    const configContent = `// Auto-generated during build
window.FLOWSTATE_CONFIG = {
    SUPABASE_URL: '${process.env.SUPABASE_URL || ''}',
    SUPABASE_ANON_KEY: '${process.env.SUPABASE_ANON_KEY || ''}'
};`;
    
    fs.writeFileSync(configPath, configContent);
    console.log('Config file generated with environment variables');
};