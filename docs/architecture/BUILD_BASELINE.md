# Build Baseline

## Estado

O repositório possui duas trilhas de build durante a modernização.

### 1. Legado — Visual Studio / MSBuild

Fonte principal:

- `Source/The New World.sln`
- `Source/Code/TMSrv/TMSrv.vcxproj`
- `Source/Code/DBSrv/DBSrv.vcxproj`

Esta trilha ainda **não é reproduzível em máquina limpa**.

Bloqueadores conhecidos:

1. caminhos absolutos em `.vcxproj`;
2. dependência de MySQL Connector C/libmysql instalada externamente;
3. `libmysql.lib` não está versionada no repositório;
4. algumas configurações da solution nomeadas `x64` apontam para projetos Win32;
5. runtime DLLs e artefatos de deploy estão misturados com dados do servidor;
6. warning level inconsistente entre configurações.

Até esses itens serem resolvidos, CI do legado será introduzido como **preflight/audit** e não será classificado falsamente como build reproduzível.

### 2. Modern — CMake

O CMake na raiz compila exclusivamente componentes novos e isolados de dependências legadas.

Objetivos:

- fornecer um ponto de entrada limpo para código moderno;
- manter C++20+ e warnings altos;
- permitir testes Windows/Linux;
- receber progressivamente módulos extraídos do legado.

Comandos:

```bash
cmake -S . -B out/build -DWYD_BUILD_MODERN_TESTS=ON
cmake --build out/build --config Debug --parallel
ctest --test-dir out/build -C Debug --output-on-failure
```

Ou usando presets:

```bash
cmake --preset modern-debug
cmake --build --preset modern-debug
ctest --preset modern-debug
```

## Próximos passos do build legado

1. inventariar include/library paths dos projetos;
2. declarar MySQL Connector de forma reproduzível;
3. remover `C:\Users\...` e demais paths locais;
4. criar configuração `LegacyRelease|Win32` determinística;
5. ativar warnings sem transformar todos os warnings históricos em bloqueadores de uma vez;
6. compilar TMSrv e DBSrv em runner Windows;
7. armazenar artefatos de CI sem commitar executáveis/DLLs gerados;
8. somente depois iniciar migração desses targets para CMake.

## Política

O build moderno não deve copiar ou linkar binários desconhecidos do diretório `Server/`. Dependências devem ser declaradas e verificáveis.
