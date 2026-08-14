# Arquitetura e Modernização

Este diretório contém a documentação arquitetural oficial da modernização do servidor New World/WYD.

## Objetivo

Evoluir o servidor legado para uma plataforma moderna de MMO preservando compatibilidade com o cliente WYD existente durante a migração.

## Princípios

- Compatibilidade antes de inovação.
- Migração incremental usando Strangler Pattern.
- Modular monolith antes de microserviços.
- Protocolo WYD isolado por adapter.
- Conteúdo progressivamente data-driven.
- Segurança por padrão.
- Observabilidade como requisito.
- Build reproduzível.
- Lógica de domínio testável sem infraestrutura externa.
- Mudanças pequenas e reversíveis.

## Governança

Mudanças arquiteturais relevantes devem possuir ADR antes da implementação.
