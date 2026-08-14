# ADR-0002 — Compatibilidade Legada como Contrato de Migração

- **Status:** Accepted
- **Data:** 2026-08-13

## Contexto

O servidor e o cliente compartilham estruturas binárias, IDs de pacotes, regras de serialização e comportamento histórico que não possuem suíte de regressão abrangente. Uma reescrita direta dessas áreas pode produzir incompatibilidades difíceis de diagnosticar.

## Decisão

Durante a modernização, o comportamento legado será tratado como contrato até existir decisão explícita para alterá-lo.

Isso implica:

- preservar layouts binários antes de testes byte-for-byte;
- encapsular protocolo antes de substituí-lo;
- manter adapters para FileDB enquanto dados forem migrados;
- introduzir APIs modernas ao lado do legado e migrar consumidores progressivamente;
- não misturar refatoração de infraestrutura com rebalanceamento de gameplay.

## Estratégia

Adotar Strangler Pattern:

```text
legacy entry point
      |
      +---- legacy implementation
      |
      +---- modern adapter/module
                 |
                 v
          migrated behavior
```

Consumidores são movidos gradualmente para a implementação moderna. O componente legado somente é removido depois de paridade, testes e observabilidade suficientes.

## Consequências

### Positivas

- rollback simples;
- menor blast radius;
- paridade pode ser validada por comportamento;
- entregas menores e frequentes.

### Negativas

- coexistência temporária de dois caminhos;
- necessidade de adapters;
- dívida transitória precisa ser acompanhada.

## Regra de remoção

Nenhum caminho legado crítico será removido apenas porque existe implementação moderna. A remoção exige:

1. todos os consumidores conhecidos migrados;
2. cobertura de regressão relevante;
3. métricas/logs sem divergências relevantes;
4. rollback documentado;
5. revisão do impacto em dados persistidos.
