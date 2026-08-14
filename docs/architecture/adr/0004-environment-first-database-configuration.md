# ADR-0004 — Configuração de banco environment-first com fallback legado

- **Status:** Accepted
- **Data:** 2026-08-13

## Contexto

TMSrv e DBSrv historicamente usam macros compiladas para host, usuário, senha, porta e database. Remover imediatamente esses defaults quebraria instalações existentes antes de existir um mecanismo de deployment/configuração consolidado.

Ao mesmo tempo, um servidor moderno não pode depender de credenciais compiladas no binário.

## Decisão

Introduzir um provider compartilhado em:

`Source/Modern/Platform/Configuration/DatabaseConfig.h`

Os dois servidores passam a carregar primeiro:

- `WYD_DB_HOST`
- `WYD_DB_USER`
- `WYD_DB_PASSWORD`
- `WYD_DB_NAME`
- `WYD_DB_PORT`
- `WYD_DB_CONNECT_TIMEOUT_SECONDS`

Quando uma variável não existir ou estiver vazia, o provider utiliza temporariamente o valor legado recebido como fallback.

Porta e timeout são validados como inteiros positivos dentro dos limites aceitos. Valores inválidos não são repassados ao MySQL; o fallback é usado.

Strings de configuração são copiadas para `std::string`, garantindo ownership/lifetime estáveis durante a operação de conexão.

## Compatibilidade

A existência do fallback mantém o comportamento atual para servidores que ainda não configuraram variáveis de ambiente.

Ambientes novos e produção devem definir todas as variáveis `WYD_DB_*`, especialmente usuário e senha.

## Direção de dependência

O provider vive na árvore moderna. Um pequeno shim em `Source/Code/LegacyDatabaseConfig.h` mantém o include legado enquanto TMSrv/DBSrv são migrados. A implementação não é duplicada no legado.

## Consequências positivas

- deployments podem remover credenciais do binário;
- configuração de TMSrv e DBSrv passa a ser consistente;
- parsing de porta/timeout é centralizado e testável;
- cria uma fronteira moderna de configuração sem breaking change.

## Consequências negativas

- defaults inseguros continuam existindo temporariamente para compatibilidade;
- variáveis de ambiente ainda não são um secret store completo;
- não há fail-fast obrigatório quando produção esquece uma variável.

## Próxima etapa

Após os deployments existentes migrarem para `WYD_DB_*`, introduzir modo estrito de produção e remover credenciais/defaults sensíveis dos headers legados. Secret stores do ambiente de produção poderão alimentar as mesmas variáveis/abstração sem acoplar o game server ao provedor de secrets.
