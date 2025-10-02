CREATE OR REPLACE VIEW vw_audit_log AS
SELECT
  id,
  event_ts,
  table_owner || '.' || table_name AS objeto,
  operation,
  pk_values,
  db_user,
  os_user,
  host,
  ip_addr,
  app_user,
  changed_columns,
  old_values,
  new_values
FROM audit_log
ORDER BY event_ts DESC;
