# Update FlowState Logging Tools for Proper Machine Detection

## Browser Extension Fix
Update the browser extension to detect hostname:
```javascript
// In browser extension logger
const hostname = window.location.hostname || 'Browser';
const machineName = `${hostname}-Browser`;
```

## System Monitor Fix  
Update flowstate-daemon.js to use actual hostname:
```javascript
const os = require('os');
const machineName = os.hostname();
```

## For Office PC
Ensure the logger uses:
```javascript
const machineName = require('os').hostname(); // Should return actual PC name
```

## Universal Logger Update
When logging activities, always include machine:
```javascript
{
  machine: os.hostname(),
  source: 'tool-name',
  tool: 'specific-tool'
}
```

This ensures all future activities are properly attributed to the correct machine!