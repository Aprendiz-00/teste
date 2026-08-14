# MySQL Safety Baseline

## Escopo deste PR

Somente correções de lifetime/ownership na implementação legada duplicada de TMSrv e DBSrv.

## Defeitos corrigidos

1. `MYSQL_OPT_CONNECT_TIMEOUT` recebia string literal em vez de ponteiro para `unsigned int`.
2. `wInfo` devolvia ponteiro para array local, causando undefined behavior após o retorno.
3. `memset(res, 0, sizeof(char))` zerava apenas um byte do buffer de retorno.
4. `strcpy` poderia ultrapassar o buffer de compatibilidade.
5. wrappers fechavam `MYSQL*` novamente após `wRes` já ter fechado a conexão.

## Preservado intencionalmente

Este PR **não**:

- altera schema;
- altera queries de negócio;
- altera login/gameplay;
- altera FileDB;
- altera protocolo;
- remove macros de configuração hardcoded ainda;
- cria pool de conexões;
- introduz prepared statements.

Esses itens serão tratados separadamente para manter o diff auditável.

## Contrato temporário

`wRes` fecha a conexão e devolve um resultado buffered. O chamador libera somente `MYSQL_RES*`.

Ver ADR-0003.

## Validação

`tools/ci/Validate-MySqlSafety.ps1` impede regressão dos quatro padrões críticos corrigidos neste baseline.

## Próximo passo

Criar configuração externa de banco sem interromper o modo legado e, em seguida, introduzir a primeira abstração RAII/Repository para novos fluxos.
