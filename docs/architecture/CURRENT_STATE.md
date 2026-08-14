# Estado Atual do Servidor — Baseline Arquitetural Atualizado

**Status:** foundation de modernização ativa  
**Atualizado em:** 2026-08-14  
**Escopo:** `Source/Code/TMSrv`, `Source/Code/DBSrv`, `Source/Code/CPSock.*`, `Source/Modern`, `Server/`, CI e tooling de build.

## 1. Visão geral

O servidor continua sendo um sistema C/C++ Win32 orientado ao protocolo legado do WYD, mas agora possui uma camada de foundation verificável ao redor do legado.

Componentes principais:

- **TMSrv** — world/game server: sessões, world state, combate, movimento, inventário, itens, quests, eventos, guildas, comércio e integração com DBSrv/MySQL.
- **DBSrv** — persistência e coordenação de contas/personagens/guildas, combinando FileDB legado com MySQL.
- **CPSock** — transporte TCP/protocolo legado baseado em Winsock e `WSAAsyncSelect`/mensagens de janela.
- **Source/Modern** — componentes novos isolados do legado, atualmente usados para configuração e contratos verificáveis.
- **Tooling/CI** — CMake moderno, MSBuild wrapper, compile gate Win32, safety gates e telemetria de warnings.

## 2. Fluxo principal

```text
Cliente WYD
    |
    | protocolo TCP legado
    v
TMSrv
    |-- ProcessClientMessage -> Exec_MSG_*
    |-- World state global
    |-- Timers / gameplay
    |
    +---- protocolo interno ----> DBSrv
    |                              |
    |                              +-- FileDB
    |                              +-- MySQL
    |
    +---- SQL direto ------------> MySQL
```

A topologia de runtime ainda é essencialmente a original. A modernização atual protege e mede esse comportamento antes de extrair responsabilidades.

## 3. Estado global e acoplamento

O TMSrv ainda mantém grandes estruturas globais de usuários, mobs, itens, grids, guildas e estados de eventos. Regras de mundo/gameplay acessam essas estruturas diretamente.

Riscos restantes:

- forte acoplamento entre infraestrutura e domínio;
- baixa testabilidade de regras de gameplay;
- alterações locais podem produzir regressões sistêmicas;
- concorrência futura exige uma fronteira de estado explícita;
- escalabilidade continua dependente de processo stateful.

Nenhuma tentativa de remover esses globals deve preceder testes comportamentais e um `GameContext`/adapter equivalente.

## 4. Protocolo

`ProcessClientMessage` continua atuando como dispatcher central por `std->Type`, chamando handlers `Exec_MSG_*`.

Melhorias já presentes:

- contratos compile-time de ABI para o header `_MSG` e variantes padrão;
- proteção de tamanhos/offsets do pacote `MSG_AccountLogin` no alvo Win32;
- IDs/flags básicos do protocolo protegidos pelo compile gate;
- contratos são adicionados apenas em CI com `WYD_ENABLE_PROTOCOL_CONTRACTS=true`, sem alterar binários normais.

Riscos restantes:

- validação de pacotes distribuída;
- transporte, protocolo e gameplay acoplados;
- ausência de testes comportamentais de encode/decode/checksum;
- estruturas fora de regiões `pack(1)` ainda dependem do ABI/alinhamento do compilador.

## 5. Rede

`CPSock` ainda depende diretamente de Winsock, HWND, `WSAAsyncSelect`, eventos `FD_ACCEPT`/`FD_READ`/`FD_CLOSE` e buffers manuais.

O protocolo e a transformação/checksum existentes continuam sendo requisitos de compatibilidade. A extração da camada de rede deve preservar esses contratos por adapter antes de qualquer troca de transporte.

### Risco conhecido

O parser legado pode sinalizar divergência de checksum separadamente do retorno do pacote. Este contrato ainda precisa ser coberto por teste comportamental antes de endurecimento.

## 6. Timers e game loop

`ProcessSecTimer` permanece concentrando shutdown, bloqueios de IP, persistência periódica, flush de sockets, processamento de jogadores, regras de mapas/quests e eventos.

A foundation atual não modifica timing de gameplay. A decomposição desse loop continua sendo uma etapa posterior e de alto risco.

## 7. Persistência

Persistem dois mecanismos simultâneos:

1. **FileDB legado** com estruturas binárias de conta/personagem.
2. **MySQL** para contas, ranking, configuração, logs e sistemas adicionais.

As implementações MySQL de TMSrv e DBSrv continuam duplicadas, mas vários defeitos de infraestrutura já foram removidos.

### Melhorias já presentes

- timeout de conexão usa o tipo esperado pela MySQL C API;
- `wInfo` não retorna mais ponteiro para buffer de stack;
- ownership de `MYSQL_RES*`/`MYSQL*` foi tornado explícito no helper legado;
- fechamentos duplicados identificados foram removidos;
- configuração compartilhada usa `WYD_DB_*` com valores próprios em `std::string`;
- `WYD_DB_REQUIRE_ENV=1` permite exigir host/user/password/database externos;
- falha de inicialização/conexão MySQL retorna `NULL` de forma controlada e não segue para `mysql_query` com handle inválido;
- MySQL Safety Baseline protege essas invariantes.

### Riscos restantes

- conexão ainda é aberta/fechada por consulta;
- SQL ainda é montado amplamente com `sprintf`/strings;
- buffers globais de query ainda existem;
- ausência de prepared statements e transaction boundary explícita em muitos fluxos;
- FileDB e MySQL permanecem misturados no domínio legado;
- compatibilidade ainda permite defaults legados quando strict mode não está ativado.

## 8. Segurança e configuração

A situação não é mais equivalente ao baseline inicial.

Controles atuais:

- configuração moderna de banco via ambiente;
- strict mode opt-in para deployments controlados;
- CI impede introdução de senha MySQL hardcoded não vazia nos headers legados;
- provider moderno e wiring de conexão fazem parte do MySQL Safety Gate;
- `.env`/segredos locais são ignorados pelo Git.

Riscos restantes:

- defaults de compatibilidade ainda usam host/user legados quando strict mode está desligado;
- SQL dinâmico continua sendo a principal superfície de segurança da persistência;
- autenticação/admin/database ainda possuem baixa separação de responsabilidades;
- qualquer segredo real fora do repositório deve ser gerenciado/rotacionado pelo deployment.

## 9. Build e CI

A foundation de build mudou substancialmente.

### Disponível hoje

- CMake para componentes modernos;
- testes modernos em Linux e Windows;
- wrapper `Build-Legacy.ps1` para MSBuild;
- compile-only Release/Win32 de TMSrv e DBSrv em runner Windows limpo;
- `Directory.Build.targets` compartilhado para C++17, include MySQL e caminhos portáveis;
- headers MySQL versionados no repositório;
- contrato de dependência em `config/build-dependencies.json`;
- baseline esperado: MySQL Connector/C 6.1.11, headers 5.7.16, Win32;
- warning telemetry não bloqueante no Job Summary;
- preflight para assumptions legados e dependência MySQL.

### Limites atuais

- `libmysql.lib` continua externamente provisionada;
- full link reproduzível com origem/checksum auditados ainda não foi estabelecido;
- alguns `.vcxproj` mantêm paths históricos, embora o policy compartilhado sobrescreva os settings relevantes;
- labels x64 da solution não significam que o legado já tenha ABI x64 suportado;
- CRT/configuração Release/Debug ainda requer auditoria antes de mudança.

## 10. Testes

A afirmação antiga de que os testes eram praticamente ausentes já não é precisa.

Cobertura atual inclui:

- testes CMake/sanity da foundation moderna;
- testes do `DatabaseConfig` em Linux/Windows;
- MySQL safety invariants;
- compile-only integral de TMSrv/DBSrv em Win32;
- contratos compile-time de protocolo;
- preflight de dependências/build;
- telemetria estruturada de warnings.

Ainda faltam os testes que mais reduzem risco de gameplay:

- login/save/logout com runtime real;
- encode/decode/checksum;
- persistência FileDB/MySQL com fixtures;
- inventário/item movement;
- combate/drops;
- integração TMSrv↔DBSrv↔cliente.

## 11. Encoding legado

Parte dos fontes antigos contém encoding misto e não pode ser transcodificada em massa.

O CI não usa `/utf-8` global. Para um label não semântico de `#pragma region` incompatível com o runner atual, o wrapper produz uma cópia temporária byte-preserving de `Server.cpp` e remove o arquivo após o build.

Regra: alterações em arquivos mixed-encoding devem preservar bytes não relacionados.

## 12. Observabilidade

Logs de runtime ainda são majoritariamente `printf`/arquivos e não constituem observabilidade moderna.

Entretanto, o pipeline agora publica telemetria de warnings por código e por arquivo, sem transformar o backlog histórico inteiro em erro.

Próximos passos aqui:

- correlação de logs por sessão/operação;
- níveis/estrutura de log;
- métricas de conexão, save, tick e fila;
- só depois, alertas operacionais.

## 13. Prioridades técnicas atuais

| Área | Estado atual | Prioridade |
|---|---|---|
| Full link reproduzível | compile reproduzível; link externo | alta |
| Testes comportamentais | foundation existe; runtime ainda sem cobertura | crítica |
| Persistência MySQL | invariantes melhores; SQL/duplicação ainda frágeis | crítica |
| FileDB/persistence boundary | legado acoplado | crítica |
| Protocolo | ABI-base protegido; lógica ainda acoplada | alta |
| Network core | Win32 legado | alta |
| GameContext/state | globals massivos | alta |
| Observabilidade runtime | logs ad hoc; CI medido | alta |
| Conteúdo data-driven | parcial | alta |
| Novos sistemas | somente após reduzir risco estrutural | posterior |

## 14. Regra de preservação

Continuam sendo componentes de **alto risco**:

- layout binário/IDs/tamanhos do protocolo;
- transformação/checksum;
- `STRUCT_MOB`, `STRUCT_ITEM`, `STRUCT_ACCOUNTFILE`;
- serialização FileDB;
- timing de login/save/logout;
- cálculo de combate e drops;
- configuração CRT/ABI Win32.

Nenhuma refatoração estética justifica mudança nesses pontos sem teste/contrato de regressão correspondente.

## 15. Critério de honestidade do estado

O repositório está significativamente mais verificável do que no baseline inicial, mas ainda **não deve ser descrito como build/deployment totalmente reproduzível nem como modernização concluída**.

Os maiores bloqueadores restantes são behavioral coverage, fronteira de persistência, SQL seguro, full-link provenance e desacoplamento gradual de protocolo/network/state.
