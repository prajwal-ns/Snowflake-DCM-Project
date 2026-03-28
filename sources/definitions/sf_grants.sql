-- ============================================================================
-- ACCESS ROLE GRANTS — wire READ/WRITE roles to schema privileges
-- ============================================================================

-- ---------- RAW READ ----------
GRANT USAGE ON DATABASE {{ sf_db }} TO ROLE AR_{{ env }}_SF_RAW_READ;
GRANT USAGE ON SCHEMA {{ sf_db }}.RAW TO ROLE AR_{{ env }}_SF_RAW_READ;
GRANT SELECT ON ALL TABLES IN SCHEMA {{ sf_db }}.RAW TO ROLE AR_{{ env }}_SF_RAW_READ;

-- ---------- RAW WRITE (inherits READ) ----------
GRANT ROLE AR_{{ env }}_SF_RAW_READ TO ROLE AR_{{ env }}_SF_RAW_WRITE;
GRANT CREATE TABLE ON SCHEMA {{ sf_db }}.RAW TO ROLE AR_{{ env }}_SF_RAW_WRITE;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA {{ sf_db }}.RAW TO ROLE AR_{{ env }}_SF_RAW_WRITE;

-- ---------- TRANSFORM READ ----------
GRANT USAGE ON DATABASE {{ sf_db }} TO ROLE AR_{{ env }}_SF_TRANSFORM_READ;
GRANT USAGE ON SCHEMA {{ sf_db }}.TRANSFORM TO ROLE AR_{{ env }}_SF_TRANSFORM_READ;
GRANT SELECT ON ALL TABLES IN SCHEMA {{ sf_db }}.TRANSFORM TO ROLE AR_{{ env }}_SF_TRANSFORM_READ;

-- ---------- TRANSFORM WRITE (inherits READ) ----------
GRANT ROLE AR_{{ env }}_SF_TRANSFORM_READ TO ROLE AR_{{ env }}_SF_TRANSFORM_WRITE;
GRANT CREATE TABLE, CREATE VIEW ON SCHEMA {{ sf_db }}.TRANSFORM TO ROLE AR_{{ env }}_SF_TRANSFORM_WRITE;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA {{ sf_db }}.TRANSFORM TO ROLE AR_{{ env }}_SF_TRANSFORM_WRITE;

-- ---------- REPORTING READ ----------
GRANT USAGE ON DATABASE {{ sf_db }} TO ROLE AR_{{ env }}_SF_REPORTING_READ;
GRANT USAGE ON SCHEMA {{ sf_db }}.REPORTING TO ROLE AR_{{ env }}_SF_REPORTING_READ;
GRANT SELECT ON ALL TABLES IN SCHEMA {{ sf_db }}.REPORTING TO ROLE AR_{{ env }}_SF_REPORTING_READ;

-- ---------- REPORTING WRITE (inherits READ) ----------
GRANT ROLE AR_{{ env }}_SF_REPORTING_READ TO ROLE AR_{{ env }}_SF_REPORTING_WRITE;
GRANT CREATE TABLE, CREATE VIEW ON SCHEMA {{ sf_db }}.REPORTING TO ROLE AR_{{ env }}_SF_REPORTING_WRITE;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA {{ sf_db }}.REPORTING TO ROLE AR_{{ env }}_SF_REPORTING_WRITE;


-- ============================================================================
-- FUNCTIONAL ROLE GRANTS — wire functional roles to access roles
-- ============================================================================

-- FR_INGEST: writes to RAW, reads TRANSFORM (to check dependencies)
GRANT ROLE AR_{{ env }}_SF_RAW_WRITE       TO ROLE FR_{{ env }}_SF_INGEST;
GRANT ROLE AR_{{ env }}_SF_TRANSFORM_READ  TO ROLE FR_{{ env }}_SF_INGEST;

-- FR_TRANSFORM: reads RAW, writes to TRANSFORM
GRANT ROLE AR_{{ env }}_SF_RAW_READ            TO ROLE FR_{{ env }}_SF_TRANSFORM;
GRANT ROLE AR_{{ env }}_SF_TRANSFORM_WRITE     TO ROLE FR_{{ env }}_SF_TRANSFORM;

-- FR_REPORTING: reads TRANSFORM, writes to REPORTING
GRANT ROLE AR_{{ env }}_SF_TRANSFORM_READ      TO ROLE FR_{{ env }}_SF_REPORTING;
GRANT ROLE AR_{{ env }}_SF_REPORTING_WRITE     TO ROLE FR_{{ env }}_SF_REPORTING;


-- ============================================================================
-- FUNCTIONAL ROLES → PROJECT OWNER (so DCM_ADMIN retains control)
-- ============================================================================

GRANT ROLE FR_{{ env }}_SF_INGEST    TO ROLE DCM_ADMIN;
GRANT ROLE FR_{{ env }}_SF_TRANSFORM TO ROLE DCM_ADMIN;
GRANT ROLE FR_{{ env }}_SF_REPORTING TO ROLE DCM_ADMIN;
