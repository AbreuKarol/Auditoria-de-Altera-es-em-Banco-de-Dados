IF OBJECT_ID('<SCHEMA>.trg_audit_<TABELA>') IS NOT NULL
  DROP TRIGGER <SCHEMA>.trg_audit_<TABELA>;
GO

CREATE TRIGGER <SCHEMA>.trg_audit_<TABELA>
ON <SCHEMA>.<TABELA>
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @app_name NVARCHAR(256) = APP_NAME();
  DECLARE @host_name NVARCHAR(128) = HOST_NAME();
  DECLARE @db_user SYSNAME = ORIGINAL_LOGIN();

  INSERT INTO dbo.audit_log (event_ts, server_user, db_user, host_name, app_name,
                             table_name, pk_values, operation, changed_columns,
                             old_values, new_values)
  SELECT
    SYSUTCDATETIME(), SUSER_SNAME(), @db_user, @host_name, @app_name,
    '<SCHEMA>.<TABELA>',
    CONCAT('<PK_COL>=', CAST(i.<PK_COL> AS NVARCHAR(4000))),
    'INSERT',
    STRING_AGG(c.col, ',') WITHIN GROUP (ORDER BY c.col),
    NULL,
    STRING_AGG(CONCAT(c.col,'=',c.newv), '; ') WITHIN GROUP (ORDER BY c.col)
  FROM inserted i
  CROSS APPLY (VALUES
      ('<COL_A>', TRY_CAST(i.<COL_A> AS NVARCHAR(4000))),
      ('<COL_B>', TRY_CAST(i.<COL_B> AS NVARCHAR(4000)))
  ) c(col, newv)
  GROUP BY i.<PK_COL>
  HAVING COUNT(*) > 0;

  INSERT INTO dbo.audit_log (event_ts, server_user, db_user, host_name, app_name,
                             table_name, pk_values, operation, changed_columns,
                             old_values, new_values)
  SELECT
    SYSUTCDATETIME(), SUSER_SNAME(), @db_user, @host_name, @app_name,
    '<SCHEMA>.<TABELA>',
    CONCAT('<PK_COL>=', CAST(d.<PK_COL> AS NVARCHAR(4000))),
    'DELETE',
    STRING_AGG(c.col, ',') WITHIN GROUP (ORDER BY c.col),
    STRING_AGG(CONCAT(c.col,'=',c.oldv), '; ') WITHIN GROUP (ORDER BY c.col),
    NULL
  FROM deleted d
  CROSS APPLY (VALUES
      ('<COL_A>', TRY_CAST(d.<COL_A> AS NVARCHAR(4000))),
      ('<COL_B>', TRY_CAST(d.<COL_B> AS NVARCHAR(4000)))
  ) c(col, oldv)
  GROUP BY d.<PK_COL>
  HAVING COUNT(*) > 0;

  INSERT INTO dbo.audit_log (event_ts, server_user, db_user, host_name, app_name,
                             table_name, pk_values, operation, changed_columns,
                             old_values, new_values)
  SELECT
    SYSUTCDATETIME(), SUSER_SNAME(), @db_user, @host_name, @app_name,
    '<SCHEMA>.<TABELA>',
    CONCAT('<PK_COL>=', CAST(i.<PK_COL> AS NVARCHAR(4000))),
    'UPDATE',
    STRING_AGG(ch.col, ',') WITHIN GROUP (ORDER BY ch.col),
    STRING_AGG(CONCAT(ch.col,'=',ch.oldv), '; ') WITHIN GROUP (ORDER BY ch.col),
    STRING_AGG(CONCAT(ch.col,'=',ch.newv), '; ') WITHIN GROUP (ORDER BY ch.col)
  FROM inserted i
  JOIN deleted d ON d.<PK_COL> = i.<PK_COL>
  CROSS APPLY (VALUES
      ('<COL_A>', TRY_CAST(d.<COL_A> AS NVARCHAR(4000)), TRY_CAST(i.<COL_A> AS NVARCHAR(4000))),
      ('<COL_B>', TRY_CAST(d.<COL_B> AS NVARCHAR(4000)), TRY_CAST(i.<COL_B> AS NVARCHAR(4000)))
  ) ch(col, oldv, newv)
  WHERE ISNULL(ch.oldv,'§') <> ISNULL(ch.newv,'§')
  GROUP BY i.<PK_COL>;
END
GO
