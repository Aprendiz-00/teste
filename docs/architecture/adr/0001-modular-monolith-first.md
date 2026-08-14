# ADR-0001 — Modular Monolith antes de Microserviços

- **Status:** Accepted
- **Data:** 2026-08-13
- **Decisão:** adotar um modular monolith como arquitetura intermediária e extrair serviços somente mediante necessidade comprovada.

## Contexto

O TMSrv atual é um processo stateful que concentra praticamente todo o world state e gameplay. Dividir imediatamente esse estado em múltiplos serviços introduziria consistência distribuída, latência entre processos, observabilidade adicional e falhas parciais antes de existirem fronteiras de domínio claras.

Ao mesmo tempo, manter o monólito atual sem modularização perpetua o acoplamento global e impede testes adequados.

## Decisão

Modernizar primeiro dentro de um único world-server, estabelecendo módulos explícitos para:

- network/protocol;
- accounts/sessions;
- characters;
- world/movement;
- combat/skills/effects;
- items/inventory;
- loot;
- party/guild;
- quests/events;
- economy/trade;
- persistence;
- observability.

Cada módulo deve expor contratos claros e reduzir acesso direto a globals.

Serviços externos são permitidos desde o início quando possuem fronteira natural e não participam do hot path do world tick, por exemplo:

- Auth/Web API;
- Admin/GM API;
- Launcher/Patcher;
- Ranking read model;
- Telemetry.

## Consequências positivas

- migração incremental;
- menor risco de regressão de gameplay;
- testes podem ser introduzidos por domínio;
- preserva latência baixa no hot path;
- prepara extração futura sem obrigá-la.

## Consequências negativas

- o processo principal continuará grande durante parte da migração;
- disciplina de fronteiras internas será necessária;
- alguns ganhos de isolamento operacional chegarão mais tarde.

## Critério para extrair um microserviço

Um módulo somente será extraído quando ao menos um dos motivos abaixo existir e estiver mensurado/documentado:

1. escala independente;
2. isolamento de segurança;
3. disponibilidade independente;
4. ownership/equipe independente;
5. workload incompatível com o world server;
6. necessidade de tecnologia/persistência distinta;
7. redução comprovável de gargalo operacional.

"Modernidade" por si só não é justificativa.

## Alternativas rejeitadas

### Rewrite total

Rejeitado pelo risco de perder comportamento implícito de protocolo/gameplay e pelo longo período até paridade funcional.

### Microserviços imediatos

Rejeitado por introduzir complexidade distribuída antes de existirem boundaries estáveis.

### Manter arquitetura atual

Rejeitado porque o acoplamento global limita testabilidade, segurança e evolução.
