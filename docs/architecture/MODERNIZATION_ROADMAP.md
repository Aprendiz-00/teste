# Roadmap Oficial de Modernização

Este documento define a ordem técnica obrigatória para evolução do servidor. A prioridade é reduzir risco antes de aumentar escopo de gameplay.

## Política de execução

Cada fase deve:

1. possuir branch própria quando envolver código;
2. ter critérios de aceite objetivos;
3. incluir rollback simples;
4. preservar compatibilidade legada salvo decisão arquitetural explícita;
5. evitar alterações de gameplay junto com alterações de infraestrutura;
6. ser revisada por diff antes de merge.

---

## Fase 1 — Foundation / Baseline

### Objetivo

Tornar o projeto compreensível, auditável e reproduzível antes de refatorações funcionais.

### Entregas

- documentação de arquitetura atual;
- ADRs iniciais;
- inventário de dependências;
- baseline de build;
- CI inicial;
- política de secrets;
- convenções de branch/commit/PR;
- testes de layout de protocolo e structs críticas.

### Critérios de aceite

- não alterar gameplay;
- `main` preservada durante desenvolvimento;
- build/validação executável de forma documentada;
- decisões arquiteturais rastreáveis.

### Rollback

Remoção dos arquivos de foundation; nenhuma alteração de dados persistentes.

---

## Fase 2 — Segurança e Persistência

### Objetivo

Eliminar riscos básicos da camada MySQL sem mudar regras do jogo.

### Entregas

- configuração externa para DB/secrets;
- remover usuário/senha hardcoded do caminho moderno;
- criar abstração de conexão com RAII;
- ownership explícito de `MYSQL_RES`;
- corrigir `wInfo` e retornos inválidos;
- prepared statements para novos fluxos;
- pool de conexões ou connection factory controlada;
- repositories para novos módulos;
- plano de migração FileDB -> SQL.

### Critérios de aceite

- login/save/reconnect preservados;
- nenhuma query nova por concatenação de input do cliente;
- testes para lifecycle de conexão;
- sem ponteiros retornados para memória local destruída.

---

## Fase 3 — Protocol Layer

### Objetivo

Separar serialização WYD de transporte e gameplay.

### Entregas

- biblioteca `wyd-protocol`;
- `PacketHeader`/types isolados;
- encoder/decoder;
- packet registry;
- testes byte-for-byte de pacotes conhecidos;
- validação centralizada de tamanho/checksum/tipo.

### Critérios de aceite

- cliente legado conecta sem mudança de bytes esperados;
- handlers de domínio não precisam conhecer `CPSock`;
- protocolo pode ser testado sem socket real.

---

## Fase 4 — Network Core

### Objetivo

Remover dependência de janela Win32 do núcleo de networking.

### Entregas

- abstração `IConnection`/`IServerTransport`;
- event loop assíncrono moderno;
- adapter do protocolo legado;
- backpressure e limites de buffer;
- timeouts explícitos;
- métricas de conexão/pacote/latência.

### Critérios de aceite

- compatibilidade com cliente preservada;
- TMSrv pode executar headless;
- gameplay não depende de HWND/WSA messages.

---

## Fase 5 — GameContext / State Ownership

### Objetivo

Eliminar acesso global irrestrito ao world state.

### Entregas

- `GameContext`;
- registries de players/mobs/items;
- world/grid service;
- clock/timer abstraction;
- acesso controlado a estado de guild/event/economy.

### Critérios de aceite

- novos módulos não introduzem novos globals;
- state ownership documentado;
- testes conseguem instanciar contexto isolado.

---

## Fase 6 — Extração de Domínios

### Ordem recomendada

1. Items/Inventory;
2. Movement/World;
3. Combat/Skills/Effects;
4. Loot/Drop;
5. Party/Guild;
6. Quest;
7. Events;
8. Economy/Trade/Marketplace.

### Padrão

```text
Packet -> Command -> Application Handler -> Domain -> Domain Event -> Replication
```

### Critérios de aceite

Cada domínio deve possuir API explícita e testes unitários independentes do socket e do banco real.

---

## Fase 7 — Content Engine

### Objetivo

Transformar conteúdo hardcoded em dados versionados.

### Entregas

- schemas de item/mob/drop/quest/event/crafting;
- validator;
- content compiler;
- versionamento;
- feature flags;
- hot reload somente onde atomicidade e segurança forem garantidas.

### Critérios de aceite

- conteúdo inválido é rejeitado antes de chegar ao world server;
- IDs e referências cruzadas são validados;
- alterações de conteúdo comuns não exigem recompilar o core.

---

## Fase 8 — Platform Services

### Serviços candidatos

- Auth/API;
- Admin/GM API;
- Ranking API;
- Launcher/Patcher;
- Website integration;
- Telemetry/Analytics.

### Princípio

Não extrair um serviço apenas para "usar microserviços". Extração exige motivo operacional, de escala, segurança ou ownership.

---

## Fase 9 — Observabilidade e Operação Avançada

### Entregas

- structured logging;
- métricas Prometheus/OpenTelemetry;
- dashboards;
- health/readiness checks;
- alertas;
- crash diagnostics;
- profiling de tick;
- auditoria GM/economia.

Esta capacidade inicia nas fases anteriores e amadurece aqui.

---

## Fase 10 — Escalabilidade

Somente após profiling real:

- channels/world partitions;
- instâncias isoladas;
- cache Redis quando necessário;
- message bus para integrações assíncronas;
- separação de ranking/chat/marketplace conforme métricas.

---

## Fase 11 — WYD do Futuro

Com a fundação estabilizada, evoluir produto e gameplay:

- temporadas;
- achievements;
- account progression;
- world bosses;
- dungeons/instances;
- matchmaking PvP;
- eventos live administráveis;
- marketplace moderno;
- collection systems;
- battle/season pass quando adequado ao design;
- painel GM completo;
- ranking web em tempo quase real;
- telemetria de economia e anti-abuso;
- launcher moderno com atualização diferencial.

---

# Ordem técnica oficial

```text
BUILD / BASELINE
       |
       v
TESTES DE COMPATIBILIDADE
       |
       v
SEGURANÇA + DATABASE
       |
       v
PROTOCOL
       |
       v
NETWORK
       |
       v
GAME CONTEXT
       |
       v
DOMÍNIOS
       |
       v
CONTENT ENGINE
       |
       v
PLATFORM SERVICES
       |
       v
ESCALABILIDADE
       |
       v
NOVOS SISTEMAS
```

A equipe não deve inverter essa ordem sem ADR justificando risco, benefício e plano de rollback.
