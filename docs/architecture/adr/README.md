# Architecture Decision Records

ADRs registram decisões arquiteturais que possuem impacto duradouro no servidor.

## Convenção

- arquivo: `NNNN-titulo-curto.md`;
- status: Proposed, Accepted, Superseded ou Deprecated;
- contexto;
- decisão;
- consequências;
- alternativas quando relevantes.

## Índice

- `0001-modular-monolith-first.md` — modular monolith antes de microserviços.
- `0002-incremental-legacy-compatibility.md` — compatibilidade legada e Strangler Pattern.
- `0003-legacy-mysql-result-ownership.md` — ownership temporário de conexão/resultado na camada MySQL legada.
- `0004-environment-first-database-configuration.md` — configuração de banco environment-first com fallback de compatibilidade.
