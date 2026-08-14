# Foundation Acceptance Checklist

A Fase 1 pode ser considerada concluída quando os itens abaixo estiverem atendidos.

- [x] Arquitetura atual documentada.
- [x] Roadmap técnico versionado.
- [x] Estratégia modular monolith registrada em ADR.
- [x] Estratégia de compatibilidade incremental registrada em ADR.
- [x] Política de segurança adicionada.
- [x] Convenções de contribuição/PR adicionadas.
- [x] `.gitignore` de builds e secrets adicionada.
- [x] Trilha CMake moderna criada sem acoplar o legado.
- [x] Teste executável mínimo criado para validar toolchain moderna.
- [x] CI Windows/Linux criado para componentes modernos.
- [x] Preflight Windows do legado criado.
- [x] Dependência externa `libmysql.lib` registrada como bloqueador do build legado reproduzível.
- [ ] Build integral TMSrv/DBSrv em máquina limpa — transferido para a fase de build/dependency hardening, pois a dependência MySQL ainda não é provisionada pelo repositório.

## Interpretação

O item pendente não invalida a Foundation: ele é precisamente um resultado da baseline. A fase seguinte deve transformar esse bloqueador conhecido em dependência declarada e reproduzível antes de qualquer refatoração ampla do TMSrv/DBSrv.
