# Security Policy

## Escopo

Este repositório contém código legado de servidor, cliente e ferramentas de desenvolvimento. Durante a modernização, segurança deve ser tratada como requisito de arquitetura e não como etapa final.

## Segredos

Nunca commitar:

- senhas reais;
- tokens de API;
- chaves privadas;
- credenciais de banco;
- credenciais de painel/admin;
- secrets de launcher/CDN;
- dumps contendo dados reais de usuários.

Use variáveis de ambiente ou secret stores do ambiente de deployment.

## Banco de dados

- aplicações não devem conectar usando `root` em produção;
- criar usuários separados por responsabilidade;
- aplicar least privilege;
- novas queries que utilizem dados externos devem usar parâmetros/prepared statements;
- migrations devem ser versionadas e revisadas;
- backups devem ser criptografados e testados para restore.

## Dados legados

O repositório possui material histórico de desenvolvimento. Antes de qualquer publicação/deployment:

1. tratar credenciais existentes como comprometidas;
2. rotacionar secrets;
3. remover dados reais caso sejam identificados;
4. revisar histórico Git se houver informação sensível que exija expurgo.

## Autenticação

A modernização deve caminhar para:

- hash de senha resistente e com salt;
- separação entre identidade e sessão de jogo;
- tokens/sessões revogáveis;
- rate limit de autenticação;
- auditoria de ações administrativas;
- banimentos/sanções persistentes e auditáveis.

## Vulnerabilidades

Falhas encontradas durante o trabalho devem ser corrigidas em branch dedicada e descritas sem publicar instruções de exploração contra servidores de terceiros.
