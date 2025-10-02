#  Auditoria de Alterações em Banco de Dados

## Objetivo
Este projeto implementa uma auditoria simples de acessos e alterações em tabelas já existentes, sem necessidade de modelar um banco do zero.  
A solução registra operações de `INSERT`, `UPDATE` e `DELETE` em tabelas críticas, guardando informações sobre usuário, host, valores antigos e novos.

---

## Estrutura dos Scripts
Os arquivos estão separados para **Oracle** e **SQL Server** (os códigos já estão em pastas separadas e não são repetidos aqui).

- `audit_log.sql`  
  Cria a tabela genérica de auditoria onde os registros serão armazenados.

- `trg_audit_MODEL.sql`  
  Modelo de trigger para ser adaptado em cada tabela a auditar.  
  Substituir:
  - `<OWNER_DADOS>` ou `<SCHEMA>`: schema da tabela
  - `<TABELA>`: nome da tabela
  - `<PK_COL>`: coluna de chave primária
  - `<COL_A>, <COL_B>`: colunas que devem ser monitoradas

- `vw_audit_log.sql`  
  Cria uma view de relatório para facilitar a consulta dos eventos.

- `rollback_trg_audit.sql`  
  Remove a trigger de auditoria de uma tabela específica.

---

## Funcionamento
1. **Tabela de Log**  
   Centraliza os eventos de auditoria.  
   Principais campos:
   - `event_ts`: data e hora do evento  
   - `db_user` / `server_user`: usuário que executou a operação  
   - `host_name` / `ip_addr`: origem da sessão  
   - `operation`: tipo da operação (INSERT, UPDATE, DELETE)  
   - `pk_values`: chave primária da linha afetada  
   - `changed_columns`: lista de colunas alteradas  
   - `old_values` / `new_values`: valores antes e depois da alteração  

2. **Trigger por Tabela**  
   Cada tabela crítica recebe sua trigger, adaptada a partir do modelo.  
   - `INSERT`: registra valores novos  
   - `UPDATE`: compara colunas e registra apenas as que mudaram  
   - `DELETE`: registra valores antigos  

3. **View de Relatório**  
   Consolida as informações da tabela de log e permite consultas rápidas, como filtrar por tabela, usuário, operação ou período.

4. **Rollback**  
   Permite remover facilmente a auditoria de uma tabela, eliminando apenas a trigger correspondente.

---

## Como Usar

### Passo a passo rápido
1. Executar `audit_log.sql` para criar a tabela de auditoria.  
2. Adaptar e executar `trg_audit_MODEL.sql` para cada tabela que deseja monitorar.  
3. Executar `vw_audit_log.sql` para criar a view de consulta.  
4. Validar os registros consultando `vw_audit_log`.  
5. Se necessário, remover a trigger com `rollback_trg_audit.sql`.

---

## Teste Prático

### Oracle
```sql
INSERT INTO RNSCOPA.USUARIO (USUA_SQ_USUARIO, USUA_NM_LOGIN_USUARIO)
VALUES (1001, 'teste_auditoria');

UPDATE RNSCOPA.USUARIO
   SET USUA_NM_LOGIN_USUARIO = 'teste_auditoria2'
 WHERE USUA_SQ_USUARIO = 1001;

DELETE FROM RNSCOPA.USUARIO WHERE USUA_SQ_USUARIO = 1001;

SELECT * FROM vw_audit_log WHERE objeto = 'RNSCOPA.USUARIO';
```

### SQL Server
```sql
INSERT INTO dbo.Usuario (UsuarioId, Nome) VALUES (1001, 'teste_auditoria');

UPDATE dbo.Usuario SET Nome = 'teste_auditoria2' WHERE UsuarioId = 1001;

DELETE FROM dbo.Usuario WHERE UsuarioId = 1001;

SELECT TOP (20) * FROM dbo.vw_audit_log WHERE objeto = 'dbo.Usuario' ORDER BY event_ts DESC;
```

---

## Boas Práticas
- Auditar apenas tabelas críticas para reduzir impacto de performance.  
- Evitar colunas muito grandes (BLOB, CLOB) no log.  
- Definir política de retenção (ex.: manter apenas 180 dias).  
- Considerar mascarar ou truncar valores sensíveis (ex.: dados pessoais).  
- Usar nomenclatura padronizada nas triggers para facilitar manutenção.  

---

## Limitações
- É necessário definir manualmente as colunas a monitorar.  
- Os valores são armazenados em formato texto (`coluna=valor; coluna=valor`).  
- Não há mecanismo de notificação em tempo real (apenas consulta posterior).  

---

## Próximos Passos
- Automatizar a geração de triggers a partir do dicionário de dados.  
- Criar relatórios em Power BI ou Grafana consumindo a view de auditoria.  
- Implementar limpeza automática do log via `DBMS_SCHEDULER` (Oracle) ou `SQL Server Agent`.  
- Evoluir os campos `old_values` e `new_values` para JSON estruturado.  

---

## Checklist de Implantação
- [ ] Executar `audit_log.sql` no banco escolhido.  
- [ ] Criar triggers adaptadas com `trg_audit_MODEL.sql`.  
- [ ] Criar a view `vw_audit_log.sql`.  
- [ ] Validar auditoria com inserts, updates e deletes.  
- [ ] Configurar política de retenção de logs.  
- [ ] Documentar tabelas e colunas auditadas.
