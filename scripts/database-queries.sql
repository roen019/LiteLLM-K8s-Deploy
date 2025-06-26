-- LiteLLM Database Analysis Queries

-- 1. USERS: Alle User anzeigen
SELECT 
    user_id, 
    user_email, 
    user_role, 
    user_alias,
    created_at, 
    updated_at 
FROM "LiteLLM_UserTable" 
ORDER BY created_at DESC;

-- 2. USER DETAILS: Vollständige User-Informationen
\d+ "LiteLLM_UserTable"

-- 3. CREDENTIALS: API Keys und Tokens
SELECT 
    token as api_key,
    user_id,
    key_alias,
    key_name,
    created_at,
    expires,
    spend,
    max_budget
FROM "LiteLLM_VerificationToken" 
ORDER BY created_at DESC;

-- 4. TEAMS: Team-Zugehörigkeiten
SELECT 
    t.team_id,
    t.team_alias,
    tm.user_id,
    u.user_email,
    tm.role as team_role
FROM "LiteLLM_TeamTable" t
LEFT JOIN "LiteLLM_TeamMembership" tm ON t.team_id = tm.team_id
LEFT JOIN "LiteLLM_UserTable" u ON tm.user_id = u.user_id;

-- 5. SPENDING: User-Ausgaben verfolgen
SELECT 
    u.user_email,
    s.spend,
    s.model,
    s.api_key,
    s.startTime,
    s.endTime
FROM "LiteLLM_SpendLogs" s
LEFT JOIN "LiteLLM_UserTable" u ON s.user = u.user_id
ORDER BY s.startTime DESC
LIMIT 10;

-- 6. DAILY SPEND: Tägliche User-Ausgaben
SELECT 
    date,
    user_id,
    spend,
    user_email
FROM "LiteLLM_DailyUserSpend"
ORDER BY date DESC;

-- 7. BUDGETS: User-Budgets und Limits
SELECT 
    budget_id,
    created_by_user_id,
    max_budget,
    soft_budget,
    created_at
FROM "LiteLLM_BudgetTable";

-- 8. MODELS: Verfügbare Modelle
SELECT 
    model_name,
    litellm_params,
    created_at
FROM "LiteLLM_ModelTable";

-- 9. AUDIT LOG: User-Aktivitäten verfolgen
SELECT 
    id,
    user_id,
    user_email,
    action,
    table_name,
    updated_values,
    updated_at
FROM "LiteLLM_AuditLog"
ORDER BY updated_at DESC
LIMIT 10;

-- 10. USER + API KEYS: Kombinierte Ansicht
SELECT 
    u.user_email,
    u.user_role,
    v.token as api_key,
    v.key_alias,
    v.max_budget,
    v.spend,
    v.created_at as key_created
FROM "LiteLLM_UserTable" u
LEFT JOIN "LiteLLM_VerificationToken" v ON u.user_id = v.user_id
ORDER BY u.created_at DESC;

-- 11. LIVE MONITORING: User-Erstellung verfolgen (mit \watch 5)
SELECT 
    user_email, 
    user_role, 
    created_at,
    user_id
FROM "LiteLLM_UserTable" 
ORDER BY created_at DESC 
LIMIT 5;

-- 12. PASSWORD DETAILS: Wie Passwords gespeichert werden
SELECT 
    user_email,
    password,
    length(password) as password_length,
    user_role
FROM "LiteLLM_UserTable"
WHERE password IS NOT NULL;
