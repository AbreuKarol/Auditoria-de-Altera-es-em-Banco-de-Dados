IF OBJECT_ID('dbo.audit_log') IS NULL
BEGIN
  CREATE TABLE dbo.audit_log (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    event_ts         DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    server_user      SYSNAME      NOT NULL DEFAULT SUSER_SNAME(),
    db_user          SYSNAME      NULL,
    host_name        NVARCHAR(128) NULL,
    app_name         NVARCHAR(256) NULL,
    table_name       SYSNAME      NOT NULL,
    pk_values        NVARCHAR(4000) NULL,
    operation        VARCHAR(10)  NOT NULL,
    changed_columns  NVARCHAR(4000) NULL,
    old_values       NVARCHAR(MAX) NULL,
    new_values       NVARCHAR(MAX) NULL
  );
END;
