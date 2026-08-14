# Estado Atual do Servidor — Baseline Arquitetural

**Status:** baseline inicial  
**Escopo:** `Source/Code/TMSrv`, `Source/Code/DBSrv`, `Source/Code/CPSock.*`, `Server/` e `Server/banco.sql`.

## 1. Visão geral

O servidor atual é um sistema C/C++ Win32 orientado ao protocolo legado do WYD. A solução é composta principalmente por:

- **TMSrv** — world/game server: sessões, world state, combate, movimento, inventário, itens, quests, eventos, guildas, comércio e integração com DBSrv/MySQL.
- **DBSrv** — persistência e coordenação de contas/personagens/guildas, combinando FileDB legado com MySQL.
- **CPSock** — transporte TCP/protocolo legado baseado em Winsock e `WSAAsyncSelect`/mensagens de janela.
- **Common/Runtime data** — mapas, drops, configs, guild data, bases de mobs/summons e demais conteúdo carregado de arquivos.

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

## 3. Estado global e acoplamento

O TMSrv mantém grandes estruturas globais, entre elas usuários, mobs, itens, grids, guildas e estados de eventos. Regras de mundo e gameplay acessam diretamente essas estruturas.

Impactos:

- forte acoplamento entre infraestrutura e domínio;
- dificuldade para testes unitários;
- alterações locais podem produzir regressões sistêmicas;
- concorrência futura é difícil de introduzir com segurança;
- escalabilidade depende principalmente de um único processo stateful.

## 4. Processamento de pacotes

`ProcessClientMessage` atua como dispatcher central por `switch` de `std->Type`, chamando handlers `Exec_MSG_*`.

Pontos positivos:

- comportamento explícito;
- protocolo existente é conhecido pelo servidor;
- handlers já possuem alguma separação por arquivo.

Limitações:

- validação de pacotes está distribuída;
- transporte, protocolo e gameplay permanecem acoplados;
- o dispatcher cresce continuamente;
- handlers dependem de globals e funções do TMSrv.

## 5. Rede

`CPSock` depende diretamente de:

- Winsock;
- HWND;
- `WSAAsyncSelect`;
- eventos `FD_ACCEPT`, `FD_READ`, `FD_CLOSE`;
- buffers manuais alocados por `malloc/free`.

O protocolo usa `HEADER` legado e transformação/checksum próprios. Esta compatibilidade é um ativo e deverá ser preservada por um adapter.

### Risco conhecido

O parser pode devolver um pacote mesmo quando o checksum diverge, sinalizando o erro por parâmetros separados. Isso exige disciplina de todos os chamadores e deverá ser endurecido quando a camada de protocolo for extraída.

## 6. Timers e game loop

`ProcessSecTimer` concentra múltiplas responsabilidades:

- shutdown;
- billing;
- bloqueios de IP;
- persistência periódica;
- flush de sockets;
- processamento por jogador;
- regras de mapas e quests;
- teleporte/restrições;
- lógica de eventos.

O custo aumenta com a quantidade de jogadores e com cada regra nova adicionada ao loop.

## 7. Persistência

Existem dois mecanismos simultâneos:

1. **FileDB legado** com estruturas binárias de conta/personagem.
2. **MySQL** para contas, ranking, configuração, logs e sistemas adicionais.

Há implementações MySQL duplicadas em TMSrv e DBSrv.

### Riscos concretos identificados

- conexão aberta/fechada por consulta;
- SQL montado com `sprintf`;
- buffers de query globais;
- credenciais hardcoded;
- ausência de prepared statements;
- retorno de ponteiro para buffer local em `wInfo`, causando undefined behavior;
- ownership/lifetime de `MYSQL*` e `MYSQL_RES*` pouco claro;
- possibilidade de fechamento duplicado de conexão em alguns fluxos.

## 8. Segurança

Baseline atual apresenta:

- configuração de banco dentro de headers;
- usuário `root` no código;
- dump SQL contendo dados de desenvolvimento;
- autenticação e banimentos parcialmente baseados em arquivos;
- ausência de secret provider;
- baixa separação entre responsabilidades de game/admin/database.

Todo segredo real deverá ser rotacionado antes de qualquer deployment público derivado desta árvore.

## 9. Build

A solução usa Visual Studio/MSBuild e toolset moderno em parte da árvore, porém ainda contém:

- caminhos absolutos de máquinas de desenvolvedor;
- configurações Win32 mesmo quando a solução oferece nomes x64;
- warning level inconsistente;
- dependências MySQL não declaradas de forma reproduzível;
- runtime DLLs versionadas junto ao servidor.

## 10. Conteúdo

O projeto possui uma quantidade relevante de conteúdo externo ao C++:

- mapas/attributes;
- drops;
- bases de mobs/summons;
- configs;
- quests/rates;
- guild data;
- eventos e quizzes.

Isto é uma vantagem para a futura Content Engine. Entretanto, ainda há muitas coordenadas, IDs, chances e regras hardcoded no código.

## 11. Prioridades técnicas

Classificação inicial:

| Área | Estado | Prioridade |
|---|---|---|
| Build reproduzível | insuficiente | crítica |
| Testes de regressão | praticamente ausentes | crítica |
| Segurança/segredos | insuficiente | crítica |
| Persistência MySQL | frágil/duplicada | crítica |
| Protocolo | valioso, mas acoplado | alta |
| Network core | Win32 legado | alta |
| GameContext/state | globals massivos | alta |
| Conteúdo data-driven | parcial | alta |
| Observabilidade | logs ad hoc | alta |
| Novos sistemas | possíveis após fundação | posterior |

## 12. Regra de preservação

Até que existam testes de compatibilidade, qualquer mudança nos seguintes componentes deve ser tratada como **alto risco**:

- layout binário de structs de protocolo;
- IDs/tamanhos dos pacotes;
- transformação/checksum;
- `STRUCT_MOB`, `STRUCT_ITEM`, `STRUCT_ACCOUNTFILE`;
- serialização FileDB;
- timing de login/save/logout;
- cálculo de combate e drops.

Nenhuma refatoração estética justifica alteração de comportamento nesses pontos sem cobertura de regressão.
