CREATE OR REPLACE TRIGGER trg_audit_<TABELA>
AFTER INSERT OR UPDATE OR DELETE ON <OWNER_DADOS>.<TABELA>
FOR EACH ROW
DECLARE
  v_db_user    VARCHAR2(128) := SYS_CONTEXT('USERENV','SESSION_USER');
  v_os_user    VARCHAR2(128) := SYS_CONTEXT('USERENV','OS_USER');
  v_host       VARCHAR2(128) := SYS_CONTEXT('USERENV','HOST');
  v_ip         VARCHAR2(64)  := SYS_CONTEXT('USERENV','IP_ADDRESS');
  v_app_user   VARCHAR2(128) := SYS_CONTEXT('USERENV','CLIENT_IDENTIFIER');
  v_pk         VARCHAR2(4000);
  v_op         VARCHAR2(10);
  v_changed    VARCHAR2(4000);
  v_old        CLOB;
  v_new        CLOB;

  PROCEDURE add_changed(p_col VARCHAR2, p_old VARCHAR2, p_new VARCHAR2) IS
  BEGIN
    IF v_changed IS NULL THEN
      v_changed := p_col;
    ELSE
      v_changed := v_changed || ',' || p_col;
    END IF;

    IF v_old IS NULL THEN
      v_old := p_col || '=' || NVL(p_old,'<NULL>');
    ELSE
      v_old := v_old || '; ' || p_col || '=' || NVL(p_old,'<NULL>');
    END IF;

    IF v_new IS NULL THEN
      v_new := p_col || '=' || NVL(p_new,'<NULL>');
    ELSE
      v_new := v_new || '; ' || p_col || '=' || NVL(p_new,'<NULL>');
    END IF;
  END;
BEGIN
  IF INSERTING THEN
    v_op := 'INSERT';
    v_pk := '<PK_COL>=' || TO_CHAR(:NEW.<PK_COL>);
    add_changed('<COL_A>', NULL, :NEW.<COL_A>);
    add_changed('<COL_B>', NULL, :NEW.<COL_B>);
  ELSIF UPDATING THEN
    v_op := 'UPDATE';
    v_pk := '<PK_COL>=' || TO_CHAR(:OLD.<PK_COL>);
    IF NVL(:OLD.<COL_A>, '§') <> NVL(:NEW.<COL_A>, '§') THEN
      add_changed('<COL_A>', :OLD.<COL_A>, :NEW.<COL_A>);
    END IF;
    IF NVL(:OLD.<COL_B>, '§') <> NVL(:NEW.<COL_B>, '§') THEN
      add_changed('<COL_B>', :OLD.<COL_B>, :NEW.<COL_B>);
    END IF;
  ELSIF DELETING THEN
    v_op := 'DELETE';
    v_pk := '<PK_COL>=' || TO_CHAR(:OLD.<PK_COL>);
    add_changed('<COL_A>', :OLD.<COL_A>, NULL);
    add_changed('<COL_B>', :OLD.<COL_B>, NULL);
  END IF;

  INSERT INTO audit_log (
    event_ts, db_user, os_user, host, ip_addr, app_user,
    table_owner, table_name, pk_values, operation, changed_columns,
    old_values, new_values
  ) VALUES (
    SYSTIMESTAMP, v_db_user, v_os_user, v_host, v_ip, v_app_user,
    '<OWNER_DADOS>', '<TABELA>', v_pk, v_op, v_changed, v_old, v_new
  );
END;
/
