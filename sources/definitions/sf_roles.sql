-- ============================================================================
-- ACCESS ROLES — per-schema READ and WRITE
-- ============================================================================

-- RAW schema access roles
DEFINE ROLE AR_{{ env }}_SF_RAW_READ;
DEFINE ROLE AR_{{ env }}_SF_RAW_WRITE;

-- TRANSFORM schema access roles
DEFINE ROLE AR_{{ env }}_SF_TRANSFORM_READ;
DEFINE ROLE AR_{{ env }}_SF_TRANSFORM_WRITE;

-- REPORTING schema access roles
DEFINE ROLE AR_{{ env }}_SF_REPORTING_READ;
DEFINE ROLE AR_{{ env }}_SF_REPORTING_WRITE;

-- ============================================================================
-- FUNCTIONAL ROLES — business function, inherit from access roles
-- ============================================================================

DEFINE ROLE FR_{{ env }}_SF_INGEST;
DEFINE ROLE FR_{{ env }}_SF_TRANSFORM;
DEFINE ROLE FR_{{ env }}_SF_REPORTING;
