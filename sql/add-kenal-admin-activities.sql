-- Add kenal-admin project activities from Office PC

INSERT INTO activity_log (user_id, project_name, activity_type, activity_description, metadata, created_at) VALUES
-- Current work session
('neo_todak', 'kenal-admin', 'development', 'Working on admin dashboard features in Cursor', 
 '{"source": "Cursor", "machine": "Office PC", "tool": "Cursor AI", "location": "office"}'::JSONB, 
 NOW() - INTERVAL '5 minutes'),

('neo_todak', 'kenal-admin', 'development', 'Implementing user management module', 
 '{"source": "Cursor", "machine": "Office PC", "tool": "Cursor AI", "location": "office"}'::JSONB, 
 NOW() - INTERVAL '25 minutes'),

('neo_todak', 'kenal-admin', 'debugging', 'Fixing authentication issues in admin panel', 
 '{"source": "Cursor", "machine": "Office PC", "tool": "Cursor AI", "location": "office"}'::JSONB, 
 NOW() - INTERVAL '1 hour'),

('neo_todak', 'kenal-admin', 'development', 'Setting up role-based access control', 
 '{"source": "Cursor", "machine": "Office PC", "tool": "Cursor AI", "location": "office"}'::JSONB, 
 NOW() - INTERVAL '2 hours');

-- Update machine last active time
UPDATE user_machines 
SET last_active = NOW() 
WHERE machine_name = 'Office PC';

-- Show results
SELECT 
    project_name,
    activity_type,
    activity_description,
    metadata->>'machine' as machine,
    created_at
FROM activity_log 
WHERE project_name = 'kenal-admin'
ORDER BY created_at DESC;