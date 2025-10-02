IF OBJECT_ID('dbo.vw_audit_log') IS NOT NULL
  DROP VIEW dbo.vw_audit_log;
GO
CREATE VIEW dbo.vw_audit_log AS
SELECT
  id,
  event_ts,
  table_name AS objeto,
  operation,
  pk_values,
  server_user,
  db_user,
  host_name,
  app_name,
  changed_columns,
  old_values,
  new_values
FROM dbo.audit_log
ORDER BY event_ts DESC;
GO
