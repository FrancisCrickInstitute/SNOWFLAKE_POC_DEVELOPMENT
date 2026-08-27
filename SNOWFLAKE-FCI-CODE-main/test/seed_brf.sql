-- =============================================================================
-- BRF Domain: Seed Data
-- =============================================================================
-- Jinja variable: {{db}} (passed via -D "db=<DATABASE_NAME>")
-- =============================================================================

use database {{db}};

-- Cost Centers
insert into {{db}}.RAW.COST_CENTERS_RAW (
    RAW_ROW_ID, COST_CENTER_ID, COST_CENTER_NAME, DEPARTMENT_CODE, DIVISION,
    MANAGER_NAME, BUDGET_OWNER, ACTIVE_FLAG, SRC_UPDATED_AT, LOAD_TS
)
values
    ('CC-001', 'CC-100', 'Engineering - Platform', 'ENG', 'Technology', 'Sarah Chen', 'Sarah Chen', true, current_timestamp(), current_timestamp()),
    ('CC-002', 'CC-101', 'Engineering - Data', 'ENG', 'Technology', 'James Wilson', 'James Wilson', true, current_timestamp(), current_timestamp()),
    ('CC-003', 'CC-200', 'Sales - Enterprise', 'SALES', 'Revenue', 'Michael Torres', 'Michael Torres', true, current_timestamp(), current_timestamp()),
    ('CC-004', 'CC-201', 'Sales - SMB', 'SALES', 'Revenue', 'Lisa Park', 'Lisa Park', true, current_timestamp(), current_timestamp()),
    ('CC-005', 'CC-300', 'Marketing - Brand', 'MKT', 'Revenue', 'Emma Davis', 'Emma Davis', true, current_timestamp(), current_timestamp()),
    ('CC-006', 'CC-400', 'People Operations', 'HR', 'Corporate', 'David Kim', 'David Kim', true, current_timestamp(), current_timestamp()),
    ('CC-007', 'CC-500', 'Finance', 'FIN', 'Corporate', 'Rachel Green', 'Rachel Green', true, current_timestamp(), current_timestamp()),
    ('CC-008', 'CC-600', 'Facilities', 'OPS', 'Corporate', 'Tom Baker', 'Tom Baker', false, current_timestamp(), current_timestamp());

-- GL Accounts
insert into {{db}}.RAW.GL_ACCOUNTS_RAW (
    RAW_ROW_ID, ACCOUNT_ID, ACCOUNT_NAME, ACCOUNT_TYPE, ACCOUNT_CATEGORY,
    PARENT_ACCOUNT_ID, NORMAL_BALANCE, ACTIVE_FLAG, SRC_UPDATED_AT, LOAD_TS
)
values
    ('GL-001', '5000', 'Salaries & Wages', 'EXPENSE', 'Personnel', null, 'DEBIT', true, current_timestamp(), current_timestamp()),
    ('GL-002', '5100', 'Employee Benefits', 'EXPENSE', 'Personnel', '5000', 'DEBIT', true, current_timestamp(), current_timestamp()),
    ('GL-003', '5200', 'Contractor Fees', 'EXPENSE', 'Personnel', null, 'DEBIT', true, current_timestamp(), current_timestamp()),
    ('GL-004', '6000', 'Software & Licenses', 'EXPENSE', 'Technology', null, 'DEBIT', true, current_timestamp(), current_timestamp()),
    ('GL-005', '6100', 'Cloud Infrastructure', 'EXPENSE', 'Technology', '6000', 'DEBIT', true, current_timestamp(), current_timestamp()),
    ('GL-006', '6200', 'Hardware', 'EXPENSE', 'Technology', '6000', 'DEBIT', true, current_timestamp(), current_timestamp()),
    ('GL-007', '7000', 'Travel & Entertainment', 'EXPENSE', 'Operations', null, 'DEBIT', true, current_timestamp(), current_timestamp()),
    ('GL-008', '7100', 'Office Supplies', 'EXPENSE', 'Operations', null, 'DEBIT', true, current_timestamp(), current_timestamp()),
    ('GL-009', '8000', 'Marketing Spend', 'EXPENSE', 'Marketing', null, 'DEBIT', true, current_timestamp(), current_timestamp()),
    ('GL-010', '8100', 'Events & Sponsorships', 'EXPENSE', 'Marketing', '8000', 'DEBIT', true, current_timestamp(), current_timestamp());

-- Budget Items (FY2026 Q1-Q4, various cost centers and accounts)
insert into {{db}}.RAW.BUDGET_ITEMS_RAW (
    RAW_ROW_ID, BUDGET_ID, FISCAL_YEAR, FISCAL_QUARTER, COST_CENTER_ID,
    ACCOUNT_ID, BUDGET_AMOUNT, ACTUAL_AMOUNT, CURRENCY_CODE, BUDGET_VERSION,
    APPROVED_BY, APPROVED_DATE, SRC_UPDATED_AT, LOAD_TS
)
values
    -- Engineering Platform - Salaries
    ('BI-001', 'BUD-2026-001', 2026, 1, 'CC-100', '5000', 450000.00, 462000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp()),
    ('BI-002', 'BUD-2026-002', 2026, 2, 'CC-100', '5000', 450000.00, 448000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp()),
    ('BI-003', 'BUD-2026-003', 2026, 3, 'CC-100', '5000', 475000.00, 480000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp()),
    -- Engineering Platform - Cloud
    ('BI-004', 'BUD-2026-004', 2026, 1, 'CC-100', '6100', 120000.00, 135000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp()),
    ('BI-005', 'BUD-2026-005', 2026, 2, 'CC-100', '6100', 120000.00, 142000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp()),
    -- Engineering Data - Salaries
    ('BI-006', 'BUD-2026-006', 2026, 1, 'CC-101', '5000', 320000.00, 315000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp()),
    ('BI-007', 'BUD-2026-007', 2026, 2, 'CC-101', '5000', 320000.00, 325000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp()),
    -- Sales Enterprise
    ('BI-008', 'BUD-2026-008', 2026, 1, 'CC-200', '5000', 380000.00, 395000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp()),
    ('BI-009', 'BUD-2026-009', 2026, 1, 'CC-200', '7000', 45000.00, 52000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp()),
    ('BI-010', 'BUD-2026-010', 2026, 2, 'CC-200', '5000', 380000.00, 372000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp()),
    -- Sales SMB
    ('BI-011', 'BUD-2026-011', 2026, 1, 'CC-201', '5000', 220000.00, 218000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp()),
    ('BI-012', 'BUD-2026-012', 2026, 2, 'CC-201', '5000', 220000.00, 226000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp()),
    -- Marketing
    ('BI-013', 'BUD-2026-013', 2026, 1, 'CC-300', '8000', 150000.00, 168000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp()),
    ('BI-014', 'BUD-2026-014', 2026, 2, 'CC-300', '8000', 175000.00, 172000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp()),
    ('BI-015', 'BUD-2026-015', 2026, 1, 'CC-300', '8100', 80000.00, 92000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp()),
    -- People Ops
    ('BI-016', 'BUD-2026-016', 2026, 1, 'CC-400', '5000', 180000.00, 178000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp()),
    ('BI-017', 'BUD-2026-017', 2026, 1, 'CC-400', '5100', 45000.00, 47000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp()),
    -- Finance
    ('BI-018', 'BUD-2026-018', 2026, 1, 'CC-500', '5000', 250000.00, 248000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp()),
    ('BI-019', 'BUD-2026-019', 2026, 1, 'CC-500', '6000', 35000.00, 38000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp()),
    ('BI-020', 'BUD-2026-020', 2026, 2, 'CC-500', '5000', 250000.00, 252000.00, 'USD', 'V1', 'CFO', '2025-12-01', current_timestamp(), current_timestamp());
