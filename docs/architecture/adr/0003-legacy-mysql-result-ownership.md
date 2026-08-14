# ADR-0003 — Ownership temporário da camada MySQL legada

- **Status:** Accepted
- **Data:** 2026-08-13

## Contexto

A API legada `cSQL::wRes` executa a query, chama `mysql_store_result` e fecha a conexão antes de devolver `MYSQL_RES*`. Os wrappers `Cont`, `iInfo`, `lInfo` e `wInfo` também fechavam o mesmo `MYSQL*`, produzindo fechamento duplicado.

Modificar imediatamente toda a API para RAII exigiria auditorar todos os consumidores e ampliaria o risco deste primeiro PR de persistência.

## Decisão

Manter temporariamente o contrato existente de `wRes`:

- `wRes` é dono do `MYSQL*` recebido e o fecha;
- o chamador recebe ownership apenas do `MYSQL_RES*` buffered;
- o chamador deve executar `mysql_free_result` e **não** fechar novamente o `MYSQL*` usado por `wRes`.

Este contrato é transitório e existe apenas para tornar o legado determinístico antes da criação da camada moderna de conexão/resultado com RAII.

## Correções associadas

- `MYSQL_OPT_CONNECT_TIMEOUT` recebe `unsigned int*`, conforme contrato da C API;
- `wInfo` não devolve mais ponteiro para buffer local destruído;
- cópia do primeiro campo retornado é limitada ao buffer de compatibilidade;
- resultado NULL mantém o comportamento lógico de retorno equivalente a `"0"`.

## Consequências

### Positivas

- elimina undefined behavior conhecido sem mudar assinaturas;
- reduz blast radius;
- cria regra verificável por CI.

### Negativas

- ownership continua não idiomático;
- conexão ainda é criada por operação;
- `char*` continua como API legada;
- prepared statements ainda não foram introduzidos.

## Próxima decisão

A camada moderna deverá substituir esse contrato por handles RAII, configuração externa e queries parametrizadas. Este ADR poderá então ser marcado como Superseded.
