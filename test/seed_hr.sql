-- ============================================================================
-- HR Domain Test Data (seed_data.sql)
-- ============================================================================
-- Inserts comprehensive test data to exercise SCD2 history logic:
--   - Multiple records per employee (name changes, status changes, terminations)
--   - Department transfers
--   - Promotion chains with salary increases
--   - Active and terminated employees
--
-- Usage (with Jinja variable for database):
--   snow sql -f test/seed_data.sql -c DEVACC --role DEV_HR_DEVELOPER
--       --warehouse HR_DEV_WH -D "db='WIP_2_HR_CORE_DB'"
-- ============================================================================

use database {{db}};

-- ─────────────────────────────────────────────────────────────────────────────
-- JOBS (10 roles across 3 job families)
-- ─────────────────────────────────────────────────────────────────────────────
insert into RAW.JOBS_RAW (RAW_SK, RAW_ROW_ID, JOB_ID, JOB_TITLE, JOB_FAMILY, JOB_LEVEL, EXEMPT_FLAG, GRADE_BAND, FTE_STANDARD_HOURS, SRC_UPDATED_AT, LOAD_TS) values
(1,  'J01', 'JOB-100', 'Junior Engineer',          'Engineering', 'IC1', true,  'G4', 40,   '2022-01-01', '2022-01-01 00:00:00'),
(2,  'J02', 'JOB-101', 'Software Engineer',        'Engineering', 'IC2', true,  'G5', 40,   '2022-01-01', '2022-01-01 00:00:00'),
(3,  'J03', 'JOB-102', 'Senior Engineer',          'Engineering', 'IC3', true,  'G6', 40,   '2022-01-01', '2022-01-01 00:00:00'),
(4,  'J04', 'JOB-103', 'Staff Engineer',           'Engineering', 'IC4', true,  'G7', 40,   '2022-01-01', '2022-01-01 00:00:00'),
(5,  'J05', 'JOB-104', 'Engineering Manager',      'Engineering', 'M1',  true,  'G7', 40,   '2022-01-01', '2022-01-01 00:00:00'),
(6,  'J06', 'JOB-200', 'Data Analyst',             'Analytics',   'IC2', true,  'G5', 37.5, '2022-01-01', '2022-01-01 00:00:00'),
(7,  'J07', 'JOB-201', 'Senior Data Analyst',      'Analytics',   'IC3', true,  'G6', 37.5, '2022-01-01', '2022-01-01 00:00:00'),
(8,  'J08', 'JOB-202', 'Analytics Manager',        'Analytics',   'M1',  true,  'G7', 37.5, '2022-01-01', '2022-01-01 00:00:00'),
(9,  'J09', 'JOB-300', 'HR Coordinator',           'People',      'IC1', false, 'G3', 37.5, '2022-01-01', '2022-01-01 00:00:00'),
(10, 'J10', 'JOB-301', 'HR Business Partner',      'People',      'IC3', true,  'G6', 37.5, '2022-01-01', '2022-01-01 00:00:00');

-- ─────────────────────────────────────────────────────────────────────────────
-- DEPARTMENTS (5 departments, 1 deactivated)
-- ─────────────────────────────────────────────────────────────────────────────
insert into RAW.DEPARTMENTS_RAW (RAW_SK, RAW_ROW_ID, DEPARTMENT_ID, DEPARTMENT_NAME, COST_CENTER, BUSINESS_UNIT, MANAGER_EMPLOYEE_ID, ACTIVE_FLAG, SRC_UPDATED_AT, LOAD_TS) values
(1,  'D01', 'DEPT-10', 'Platform Engineering', 'CC-100', 'Technology',  'EMP-005', true,  '2022-01-01', '2022-01-01 00:00:00'),
(2,  'D02', 'DEPT-20', 'Data Engineering',     'CC-200', 'Technology',  'EMP-010', true,  '2022-01-01', '2022-01-01 00:00:00'),
(3,  'D03', 'DEPT-30', 'Analytics',            'CC-300', 'Technology',  'EMP-012', true,  '2022-01-01', '2022-01-01 00:00:00'),
(4,  'D04', 'DEPT-40', 'People Operations',    'CC-400', 'Corporate',   'EMP-015', true,  '2022-01-01', '2022-01-01 00:00:00'),
(5,  'D05', 'DEPT-50', 'Legacy Systems',       'CC-500', 'Technology',  'EMP-005', true,  '2022-01-01', '2022-01-01 00:00:00'),
-- Department deactivated in 2024 (team merged into Platform Engineering)
(6,  'D05b','DEPT-50', 'Legacy Systems',       'CC-500', 'Technology',  'EMP-005', false, '2024-03-01', '2024-03-01 00:00:00');

-- ─────────────────────────────────────────────────────────────────────────────
-- EMPLOYEES (15 employees with history changes)
-- Multiple rows per employee test SCD2 change detection:
--   - EMP-001: hired, then name change (marriage)
--   - EMP-003: hired active, later terminated
--   - EMP-008: hired, email change, then terminated
-- ─────────────────────────────────────────────────────────────────────────────
insert into RAW.EMPLOYEES_RAW (RAW_SK, RAW_ROW_ID, EMPLOYEE_ID, FIRST_NAME, LAST_NAME, GENDER, ETHNICITY, DATE_OF_BIRTH, HIRE_DATE, TERMINATION_DATE, EMPLOYMENT_STATUS, EMPLOYMENT_TYPE, EMAIL, SRC_UPDATED_AT, LOAD_TS) values
-- EMP-001: Alice Smith → Alice Johnson (name change 2024-02)
(1,  'E01a', 'EMP-001', 'Alice',   'Smith',    'F', 'White',    '1990-03-15', '2021-06-01', null,         'Active',     'Full-Time', 'alice.smith@fci.com',   '2021-06-01', '2021-06-01 00:00:00'),
(2,  'E01b', 'EMP-001', 'Alice',   'Johnson',  'F', 'White',    '1990-03-15', '2021-06-01', null,         'Active',     'Full-Time', 'alice.johnson@fci.com', '2024-02-01', '2024-02-01 00:00:00'),
-- EMP-002: Bob (no changes)
(3,  'E02',  'EMP-002', 'Bob',     'Williams', 'M', 'Black',    '1985-07-22', '2020-01-15', null,         'Active',     'Full-Time', 'bob.williams@fci.com',  '2020-01-15', '2020-01-15 00:00:00'),
-- EMP-003: Charlie (terminated 2024-06)
(4,  'E03a', 'EMP-003', 'Charlie', 'Brown',    'M', 'White',    '1988-11-08', '2019-03-01', null,         'Active',     'Full-Time', 'charlie.brown@fci.com', '2019-03-01', '2019-03-01 00:00:00'),
(5,  'E03b', 'EMP-003', 'Charlie', 'Brown',    'M', 'White',    '1988-11-08', '2019-03-01', '2024-06-30', 'Terminated', 'Full-Time', 'charlie.brown@fci.com', '2024-07-01', '2024-07-01 00:00:00'),
-- EMP-004: Diana (no changes)
(6,  'E04',  'EMP-004', 'Diana',   'Garcia',   'F', 'Hispanic', '1992-05-30', '2022-09-15', null,         'Active',     'Full-Time', 'diana.garcia@fci.com',  '2022-09-15', '2022-09-15 00:00:00'),
-- EMP-005: Edward (engineering manager, no changes)
(7,  'E05',  'EMP-005', 'Edward',  'Chen',     'M', 'Asian',    '1982-01-12', '2018-11-01', null,         'Active',     'Full-Time', 'edward.chen@fci.com',   '2018-11-01', '2018-11-01 00:00:00'),
-- EMP-006: Fatima (no changes)
(8,  'E06',  'EMP-006', 'Fatima',  'Hassan',   'F', 'Asian',    '1995-09-25', '2023-03-01', null,         'Active',     'Full-Time', 'fatima.hassan@fci.com', '2023-03-01', '2023-03-01 00:00:00'),
-- EMP-007: George (part-time)
(9,  'E07',  'EMP-007', 'George',  'Taylor',   'M', 'White',    '1978-04-18', '2021-01-10', null,         'Active',     'Part-Time', 'george.taylor@fci.com', '2021-01-10', '2021-01-10 00:00:00'),
-- EMP-008: Hannah (hired, email change, then terminated)
(10, 'E08a', 'EMP-008', 'Hannah',  'Lee',      'F', 'Asian',    '1993-12-03', '2020-08-01', null,         'Active',     'Full-Time', 'hannah.lee@fci.com',    '2020-08-01', '2020-08-01 00:00:00'),
(11, 'E08b', 'EMP-008', 'Hannah',  'Lee',      'F', 'Asian',    '1993-12-03', '2020-08-01', null,         'Active',     'Full-Time', 'h.lee@fci.com',         '2023-01-15', '2023-01-15 00:00:00'),
(12, 'E08c', 'EMP-008', 'Hannah',  'Lee',      'F', 'Asian',    '1993-12-03', '2020-08-01', '2024-09-15', 'Terminated', 'Full-Time', 'h.lee@fci.com',         '2024-09-16', '2024-09-16 00:00:00'),
-- EMP-009: Ivan (no changes)
(13, 'E09',  'EMP-009', 'Ivan',    'Petrov',   'M', 'White',    '1987-06-20', '2022-04-01', null,         'Active',     'Full-Time', 'ivan.petrov@fci.com',   '2022-04-01', '2022-04-01 00:00:00'),
-- EMP-010: Julia (data eng manager)
(14, 'E10',  'EMP-010', 'Julia',   'Martinez', 'F', 'Hispanic', '1984-02-14', '2019-07-01', null,         'Active',     'Full-Time', 'julia.martinez@fci.com','2019-07-01', '2019-07-01 00:00:00'),
-- EMP-011: Kevin (no changes)
(15, 'E11',  'EMP-011', 'Kevin',   'O''Brien', 'M', 'White',    '1991-08-09', '2023-06-01', null,         'Active',     'Full-Time', 'kevin.obrien@fci.com',  '2023-06-01', '2023-06-01 00:00:00'),
-- EMP-012: Lena (analytics manager)
(16, 'E12',  'EMP-012', 'Lena',    'Johansson','F', 'White',    '1986-10-30', '2020-02-01', null,         'Active',     'Full-Time', 'lena.johansson@fci.com','2020-02-01', '2020-02-01 00:00:00'),
-- EMP-013: Marcus (no changes)
(17, 'E13',  'EMP-013', 'Marcus',  'Wright',   'M', 'Black',    '1994-03-17', '2023-09-01', null,         'Active',     'Full-Time', 'marcus.wright@fci.com', '2023-09-01', '2023-09-01 00:00:00'),
-- EMP-014: Nadia (no changes)
(18, 'E14',  'EMP-014', 'Nadia',   'Kowalski', 'F', 'White',    '1989-07-22', '2022-11-01', null,         'Active',     'Full-Time', 'nadia.kowalski@fci.com','2022-11-01', '2022-11-01 00:00:00'),
-- EMP-015: Omar (HR manager)
(19, 'E15',  'EMP-015', 'Omar',    'Abdallah', 'M', 'Asian',    '1980-05-05', '2017-09-01', null,         'Active',     'Full-Time', 'omar.abdallah@fci.com', '2017-09-01', '2017-09-01 00:00:00');

-- ─────────────────────────────────────────────────────────────────────────────
-- EMPLOYEE JOB EVENTS (includes promotions and department transfers)
--   - EMP-001: hired IC1, promoted IC2, promoted IC3
--   - EMP-002: hired IC3, promoted to Staff IC4
--   - EMP-003: hired, transferred dept, then left
--   - EMP-008: hired DEPT-20, transferred to DEPT-10, then left
-- ─────────────────────────────────────────────────────────────────────────────
insert into RAW.EMPLOYEE_JOB_EVENTS_RAW (RAW_SK, RAW_ROW_ID, EMPLOYEE_ID, EFFECTIVE_DATE, JOB_ID, DEPARTMENT_ID, MANAGER_EMPLOYEE_ID, LOCATION_CODE, EVENT_TYPE, SRC_UPDATED_AT, LOAD_TS) values
-- EMP-001: 3 events (hire → promo → promo)
(1,  'EJ01', 'EMP-001', '2021-06-01', 'JOB-100', 'DEPT-10', 'EMP-005', 'LON', 'HIRE',      '2021-06-01', '2021-06-01 00:00:00'),
(2,  'EJ02', 'EMP-001', '2022-06-01', 'JOB-101', 'DEPT-10', 'EMP-005', 'LON', 'PROMOTION', '2022-06-01', '2022-06-01 00:00:00'),
(3,  'EJ03', 'EMP-001', '2024-01-01', 'JOB-102', 'DEPT-10', 'EMP-005', 'LON', 'PROMOTION', '2024-01-01', '2024-01-01 00:00:00'),
-- EMP-002: 2 events (hire → promo)
(4,  'EJ04', 'EMP-002', '2020-01-15', 'JOB-102', 'DEPT-10', 'EMP-005', 'LON', 'HIRE',      '2020-01-15', '2020-01-15 00:00:00'),
(5,  'EJ05', 'EMP-002', '2023-07-01', 'JOB-103', 'DEPT-10', 'EMP-005', 'LON', 'PROMOTION', '2023-07-01', '2023-07-01 00:00:00'),
-- EMP-003: 2 events (hire in DEPT-50 → transfer to DEPT-10 before termination)
(6,  'EJ06', 'EMP-003', '2019-03-01', 'JOB-101', 'DEPT-50', 'EMP-005', 'MAN', 'HIRE',      '2019-03-01', '2019-03-01 00:00:00'),
(7,  'EJ07', 'EMP-003', '2023-01-01', 'JOB-101', 'DEPT-10', 'EMP-005', 'LON', 'TRANSFER',  '2023-01-01', '2023-01-01 00:00:00'),
-- EMP-004: 1 event
(8,  'EJ08', 'EMP-004', '2022-09-15', 'JOB-200', 'DEPT-30', 'EMP-012', 'LON', 'HIRE',      '2022-09-15', '2022-09-15 00:00:00'),
-- EMP-005: 1 event (manager)
(9,  'EJ09', 'EMP-005', '2018-11-01', 'JOB-104', 'DEPT-10', null,      'LON', 'HIRE',      '2018-11-01', '2018-11-01 00:00:00'),
-- EMP-006: 1 event
(10, 'EJ10', 'EMP-006', '2023-03-01', 'JOB-100', 'DEPT-10', 'EMP-005', 'EDI', 'HIRE',      '2023-03-01', '2023-03-01 00:00:00'),
-- EMP-007: 1 event
(11, 'EJ11', 'EMP-007', '2021-01-10', 'JOB-300', 'DEPT-40', 'EMP-015', 'LON', 'HIRE',      '2021-01-10', '2021-01-10 00:00:00'),
-- EMP-008: 2 events (hire DEPT-20 → transfer DEPT-10)
(12, 'EJ12', 'EMP-008', '2020-08-01', 'JOB-101', 'DEPT-20', 'EMP-010', 'LON', 'HIRE',      '2020-08-01', '2020-08-01 00:00:00'),
(13, 'EJ13', 'EMP-008', '2022-04-01', 'JOB-102', 'DEPT-10', 'EMP-005', 'LON', 'TRANSFER',  '2022-04-01', '2022-04-01 00:00:00'),
-- EMP-009: 1 event
(14, 'EJ14', 'EMP-009', '2022-04-01', 'JOB-101', 'DEPT-20', 'EMP-010', 'MAN', 'HIRE',      '2022-04-01', '2022-04-01 00:00:00'),
-- EMP-010: 1 event (manager)
(15, 'EJ15', 'EMP-010', '2019-07-01', 'JOB-104', 'DEPT-20', null,      'LON', 'HIRE',      '2019-07-01', '2019-07-01 00:00:00'),
-- EMP-011: 1 event
(16, 'EJ16', 'EMP-011', '2023-06-01', 'JOB-100', 'DEPT-10', 'EMP-005', 'LON', 'HIRE',      '2023-06-01', '2023-06-01 00:00:00'),
-- EMP-012: 1 event (analytics manager)
(17, 'EJ17', 'EMP-012', '2020-02-01', 'JOB-202', 'DEPT-30', null,      'LON', 'HIRE',      '2020-02-01', '2020-02-01 00:00:00'),
-- EMP-013: 1 event
(18, 'EJ18', 'EMP-013', '2023-09-01', 'JOB-200', 'DEPT-30', 'EMP-012', 'EDI', 'HIRE',      '2023-09-01', '2023-09-01 00:00:00'),
-- EMP-014: 2 events (hire → promo)
(19, 'EJ19', 'EMP-014', '2022-11-01', 'JOB-200', 'DEPT-30', 'EMP-012', 'LON', 'HIRE',      '2022-11-01', '2022-11-01 00:00:00'),
(20, 'EJ20', 'EMP-014', '2024-04-01', 'JOB-201', 'DEPT-30', 'EMP-012', 'LON', 'PROMOTION', '2024-04-01', '2024-04-01 00:00:00'),
-- EMP-015: 1 event (HR manager)
(21, 'EJ21', 'EMP-015', '2017-09-01', 'JOB-301', 'DEPT-40', null,      'LON', 'HIRE',      '2017-09-01', '2017-09-01 00:00:00');

-- ─────────────────────────────────────────────────────────────────────────────
-- COMPENSATION EVENTS (multiple per employee for raises/promotions)
-- ─────────────────────────────────────────────────────────────────────────────
insert into RAW.COMPENSATION_EVENTS_RAW (RAW_SK, RAW_ROW_ID, EMPLOYEE_ID, EFFECTIVE_DATE, SALARY_AMOUNT, BONUS_TARGET_PCT, CURRENCY_CODE, CHANGE_REASON, SRC_UPDATED_AT, LOAD_TS) values
-- EMP-001: 3 comp events (hire → annual → promo)
(1,  'C01', 'EMP-001', '2021-06-01', 42000,  8,  'GBP', 'New Hire',        '2021-06-01', '2021-06-01 00:00:00'),
(2,  'C02', 'EMP-001', '2022-06-01', 52000,  10, 'GBP', 'Promotion',       '2022-06-01', '2022-06-01 00:00:00'),
(3,  'C03', 'EMP-001', '2024-01-01', 68000,  15, 'GBP', 'Promotion',       '2024-01-01', '2024-01-01 00:00:00'),
-- EMP-002: 3 comp events
(4,  'C04', 'EMP-002', '2020-01-15', 65000,  12, 'GBP', 'New Hire',        '2020-01-15', '2020-01-15 00:00:00'),
(5,  'C05', 'EMP-002', '2022-01-01', 72000,  12, 'GBP', 'Annual Review',   '2022-01-01', '2022-01-01 00:00:00'),
(6,  'C06', 'EMP-002', '2023-07-01', 88000,  18, 'GBP', 'Promotion',       '2023-07-01', '2023-07-01 00:00:00'),
-- EMP-003: 2 comp events
(7,  'C07', 'EMP-003', '2019-03-01', 55000,  10, 'GBP', 'New Hire',        '2019-03-01', '2019-03-01 00:00:00'),
(8,  'C08', 'EMP-003', '2022-04-01', 60000,  10, 'GBP', 'Annual Review',   '2022-04-01', '2022-04-01 00:00:00'),
-- EMP-004: 1 comp event
(9,  'C09', 'EMP-004', '2022-09-15', 48000,  10, 'GBP', 'New Hire',        '2022-09-15', '2022-09-15 00:00:00'),
-- EMP-005: 2 comp events
(10, 'C10', 'EMP-005', '2018-11-01', 95000,  20, 'GBP', 'New Hire',        '2018-11-01', '2018-11-01 00:00:00'),
(11, 'C11', 'EMP-005', '2023-01-01', 105000, 22, 'GBP', 'Annual Review',   '2023-01-01', '2023-01-01 00:00:00'),
-- EMP-006: 1 comp event
(12, 'C12', 'EMP-006', '2023-03-01', 40000,  8,  'GBP', 'New Hire',        '2023-03-01', '2023-03-01 00:00:00'),
-- EMP-007: 1 comp event
(13, 'C13', 'EMP-007', '2021-01-10', 28000,  5,  'GBP', 'New Hire',        '2021-01-10', '2021-01-10 00:00:00'),
-- EMP-008: 2 comp events
(14, 'C14', 'EMP-008', '2020-08-01', 55000,  10, 'GBP', 'New Hire',        '2020-08-01', '2020-08-01 00:00:00'),
(15, 'C15', 'EMP-008', '2022-04-01', 68000,  15, 'GBP', 'Promotion',       '2022-04-01', '2022-04-01 00:00:00'),
-- EMP-009: 1 comp event
(16, 'C16', 'EMP-009', '2022-04-01', 52000,  10, 'GBP', 'New Hire',        '2022-04-01', '2022-04-01 00:00:00'),
-- EMP-010: 2 comp events
(17, 'C17', 'EMP-010', '2019-07-01', 90000,  20, 'GBP', 'New Hire',        '2019-07-01', '2019-07-01 00:00:00'),
(18, 'C18', 'EMP-010', '2023-01-01', 98000,  20, 'GBP', 'Annual Review',   '2023-01-01', '2023-01-01 00:00:00'),
-- EMP-011: 1 comp event
(19, 'C19', 'EMP-011', '2023-06-01', 40000,  8,  'GBP', 'New Hire',        '2023-06-01', '2023-06-01 00:00:00'),
-- EMP-012: 2 comp events
(20, 'C20', 'EMP-012', '2020-02-01', 82000,  18, 'GBP', 'New Hire',        '2020-02-01', '2020-02-01 00:00:00'),
(21, 'C21', 'EMP-012', '2024-01-01', 92000,  20, 'GBP', 'Annual Review',   '2024-01-01', '2024-01-01 00:00:00'),
-- EMP-013: 1 comp event
(22, 'C22', 'EMP-013', '2023-09-01', 45000,  10, 'GBP', 'New Hire',        '2023-09-01', '2023-09-01 00:00:00'),
-- EMP-014: 2 comp events
(23, 'C23', 'EMP-014', '2022-11-01', 48000,  10, 'GBP', 'New Hire',        '2022-11-01', '2022-11-01 00:00:00'),
(24, 'C24', 'EMP-014', '2024-04-01', 58000,  12, 'GBP', 'Promotion',       '2024-04-01', '2024-04-01 00:00:00'),
-- EMP-015: 2 comp events
(25, 'C25', 'EMP-015', '2017-09-01', 72000,  15, 'GBP', 'New Hire',        '2017-09-01', '2017-09-01 00:00:00'),
(26, 'C26', 'EMP-015', '2023-01-01', 85000,  18, 'GBP', 'Annual Review',   '2023-01-01', '2023-01-01 00:00:00');

select 'Seed data loaded: 10 jobs, 6 dept records (5 depts), 19 employee records (15 employees), 21 job events, 26 comp events' as STATUS;
