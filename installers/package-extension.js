#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('Packaging FlowState Browser Extension...\n');

// Files to include in the package
const extensionFiles = [
  'manifest.json',
  'background.js',
  'popup.html',
  'popup.js',
  'icon16.png',
  'icon48.png',
  'icon128.png'
];

// Read installer templates
const batTemplate = fs.readFileSync(path.join(__dirname, 'install-flowstate-extension.bat'), 'utf8');
const shTemplate = fs.readFileSync(path.join(__dirname, 'install-flowstate-extension.sh'), 'utf8');

// Function to create self-extracting installer
function createWindowsInstaller() {
  console.log('Creating Windows installer...');
  
  let batContent = batTemplate;
  let extractFunction = ':ExtractFiles\n';
  
  // Add each file to the batch script
  extensionFiles.forEach(file => {
    const filePath = path.join(__dirname, '..', 'browser-extension', file);
    if (fs.existsSync(filePath)) {
      const content = fs.readFileSync(filePath);
      const base64 = content.toString('base64');
      
      // Split base64 into chunks for batch file compatibility
      const chunks = base64.match(/.{1,1000}/g) || [];
      
      extractFunction += `echo Creating ${file}...\n`;
      extractFunction += `(\n`;
      chunks.forEach(chunk => {
        extractFunction += `echo ${chunk}\n`;
      });
      extractFunction += `) > "%EXTENSION_DIR%\\${file}.b64"\n`;
      extractFunction += `certutil -decode "%EXTENSION_DIR%\\${file}.b64" "%EXTENSION_DIR%\\${file}" >nul\n`;
      extractFunction += `del "%EXTENSION_DIR%\\${file}.b64"\n\n`;
    }
  });
  
  extractFunction += 'exit /b';
  
  // Replace the placeholder with actual extraction code
  batContent = batContent.replace(':ExtractFiles\n:: This section will be replaced by the packager script\n:: with the actual base64 encoded files\nexit /b', extractFunction);
  
  // Write the final installer
  fs.writeFileSync(path.join(__dirname, 'FlowState-Extension-Installer-Windows.bat'), batContent);
  console.log('✓ Created: FlowState-Extension-Installer-Windows.bat');
}

// Function to create Mac installer
function createMacInstaller() {
  console.log('Creating Mac installer...');
  
  let shContent = shTemplate;
  let extractFunction = 'extract_files() {\n';
  
  // Add each file to the shell script
  extensionFiles.forEach(file => {
    const filePath = path.join(__dirname, '..', 'browser-extension', file);
    if (fs.existsSync(filePath)) {
      const content = fs.readFileSync(filePath);
      const base64 = content.toString('base64');
      
      extractFunction += `    echo "Creating ${file}..."\n`;
      extractFunction += `    cat << 'EOF' | base64 -d > "$EXTENSION_DIR/${file}"\n`;
      extractFunction += `${base64}\n`;
      extractFunction += `EOF\n\n`;
    }
  });
  
  extractFunction += '    echo "Files extracted successfully"\n}\n';
  
  // Replace the placeholder
  shContent = shContent.replace(
    'extract_files() {\n    # This function will be replaced by the packager\n    # with the actual base64 encoded files\n    echo "Files extracted successfully"\n}',
    extractFunction
  );
  
  // Write the final installer
  fs.writeFileSync(path.join(__dirname, 'FlowState-Extension-Installer-Mac.sh'), shContent);
  execSync(`chmod +x ${path.join(__dirname, 'FlowState-Extension-Installer-Mac.sh')}`);
  console.log('✓ Created: FlowState-Extension-Installer-Mac.sh');
}

// Create both installers
createWindowsInstaller();
createMacInstaller();

// Create a simple ZIP for manual installation
console.log('\nCreating ZIP package...');
execSync(`cd ${path.join(__dirname, '..')} && zip -r installers/flowstate-browser-extension.zip browser-extension -x "*.DS_Store" "*/.*"`);
console.log('✓ Created: flowstate-browser-extension.zip');

console.log('\n✅ Packaging complete!');
console.log('\nInstallers created in:', path.join(__dirname));
console.log('\nTo use:');
console.log('- Windows: Run FlowState-Extension-Installer-Windows.bat as Administrator');
console.log('- Mac: Run ./FlowState-Extension-Installer-Mac.sh');
console.log('- Manual: Extract flowstate-browser-extension.zip and load in browser');