# Cadastro de Clientes (PowerBuilder)

Aplicação desktop em PowerBuilder 2022 para cadastro de clientes (pessoa física e jurídica). Ela grava num banco SQL Server ou num arquivo JSON local (modo mock), conforme o `clientes.ini`. O modo mock serve para desenvolver e testar sem banco de dados.

## Funcionalidades

- Lista de clientes com pesquisa por parte do nome, pelo início do CPF/CNPJ (com ou sem pontuação) ou pela cidade.
- Opção para mostrar também os clientes inativos.
- Inclusão, alteração, exclusão e cancelamento de edição no formulário de detalhe.
- Rótulos e máscaras que mudam conforme o tipo de pessoa (CPF/Nome ou CNPJ/Razão social).
- Aviso de alterações não salvas ao trocar de cliente, pesquisar ou fechar a tela.
- Validações antes de gravar:
  - nome obrigatório;
  - CPF ou CNPJ com dígito verificador válido e sem duplicidade;
  - data de nascimento ou fundação que não seja futura;
  - e-mail em formato válido (é opcional);
  - telefone com 10 dígitos, celular com 11 e CEP com 8 (todos opcionais, gravados só com dígitos);
  - UF obrigatória quando a cidade é informada.
- Auditoria simples com `data_cadastro` e `data_alteracao`.
- Roteiro de autoteste executável pela linha de comando (`/autoteste`).

## Requisitos

- PowerBuilder 2022 (os objetos foram exportados com `release 22`).
- Para o modo `sqlserver`: SQL Server acessível e o driver **Microsoft OLE DB Driver for SQL Server** (MSOLEDBSQL).
- Para o modo `mock`: nenhum requisito além do arquivo [dados/clientes.json](dados/clientes.json).

## Estrutura do repositório

| Arquivo | Descrição |
|---|---|
| [clientes.pbw](clientes.pbw) | Workspace |
| [clientes.pbt](clientes.pbt) | Target (`app_clientes`, biblioteca `clientes.pbl`) |
| [clientes.pbg](clientes.pbg) | Lista de objetos da biblioteca |
| [clientes.ini](clientes.ini) | Configuração: modo de acesso e conexão |
| [app_clientes.sra](app_clientes.sra) | Objeto aplicação: lê o `.ini`, inicializa o acesso a dados e abre a tela ou o autoteste |
| [w_cliente.srw](w_cliente.srw) | Janela principal (lista, filtro, formulário e botões) e regras de validação |
| [d_cliente_lista.srd](d_cliente_lista.srd) | DataWindow da lista (argumentos `as_filtro`, `as_inativos`) |
| [d_cliente_detalhe.srd](d_cliente_detalhe.srd) | DataWindow do formulário; atualiza a tabela `cliente` |
| [n_cst_cliente_dados.sru](n_cst_cliente_dados.sru) | Camada de acesso a dados: abstrai SQL Server e mock JSON |
| [n_cst_validacao.sru](n_cst_validacao.sru) | Validação de CPF, CNPJ (módulo 11) e e-mail |
| [n_cst_autoteste.sru](n_cst_autoteste.sru) | Roteiro de testes automatizados da tela |
| [dados/clientes.json](dados/clientes.json) | Massa de dados do modo mock |
| [ws_objects/clientes.pbl.src/](ws_objects/clientes.pbl.src/) | Os mesmos objetos em UTF-8, no formato de controle de versão do PowerBuilder |

Os arquivos `.sr*` da raiz estão em UTF-16. Os de `ws_objects/` estão em UTF-8 e são os mais fáceis de comparar em diffs.

## Arquitetura

```
app_clientes (open)
   │  lê clientes.ini
   ▼
n_cst_cliente_dados (gnv_dados, global)
   ├── Modo=sqlserver → SQLCA + DataWindows (Retrieve / Update, commit/rollback)
   └── Modo=mock      → DataStore em memória ⇄ dados/clientes.json (ImportJsonByKey / ExportJson)
   ▲
w_cliente  ── usa n_cst_validacao para validar antes de gravar
```

A janela só conversa com `gnv_dados` (`of_listar`, `of_carregar`, `of_salvar`, `of_excluir`, `of_documento_em_uso`), sem saber qual modo está ativo. No modo mock, cada gravação ou exclusão reescreve o arquivo JSON inteiro, ordenado por `id_cliente`. O próximo código é o maior `id_cliente` mais um.

## Configuração

O aplicativo procura o `clientes.ini` no diretório corrente: a pasta do target, quando roda pela IDE, ou a pasta do executável.

```ini
[App]
Modo=mock                       ; mock | sqlserver
ArquivoMock=dados\clientes.json ; relativo à pasta do .ini, ou absoluto

[Database]                      ; usado só com Modo=sqlserver
DBMS=MSOLEDBSQL SQL Server
ServerName=localhost
Database=pb_clientes
LogId=
LogPass=
DBParm=TrustedConnection=1      ; autenticação do Windows
```

Para usar a autenticação do SQL Server, preencha `LogId` e `LogPass` e deixe `DBParm` vazio. Se a conexão falhar, crie um Database Profile no Database Painter, teste a conexão e copie os valores da aba *Preview* para o `.ini`.

> **Atenção:** o `clientes.ini` pode conter senha. Não faça commit dele com credenciais reais.

## Banco de dados (modo `sqlserver`)

O repositório não traz script de criação do banco. A tabela abaixo foi derivada das colunas das DataWindows e serve de ponto de partida:

```sql
CREATE TABLE cliente (
    id_cliente      INT IDENTITY(1,1) PRIMARY KEY,
    tipo_pessoa     CHAR(1)       NOT NULL DEFAULT 'F',   -- F = física, J = jurídica
    nome            VARCHAR(100)  NOT NULL,
    nome_fantasia   VARCHAR(100)  NULL,
    cpf_cnpj        VARCHAR(14)   NOT NULL UNIQUE,         -- somente dígitos
    rg_ie           VARCHAR(20)   NULL,
    data_nascimento DATE          NULL,
    email           VARCHAR(120)  NULL,
    telefone        VARCHAR(15)   NULL,
    celular         VARCHAR(15)   NULL,
    cep             VARCHAR(8)    NULL,
    logradouro      VARCHAR(100)  NULL,
    numero          VARCHAR(10)   NULL,
    complemento     VARCHAR(50)   NULL,
    bairro          VARCHAR(60)   NULL,
    cidade          VARCHAR(60)   NULL,
    uf              CHAR(2)       NULL,
    observacao      VARCHAR(500)  NULL,
    ativo           CHAR(1)       NOT NULL DEFAULT 'S',
    data_cadastro   DATETIME      NOT NULL DEFAULT GETDATE(),
    data_alteracao  DATETIME      NULL
);
```

`data_cadastro` não é atualizável pela DataWindow, por isso precisa do `DEFAULT` no banco. A tela já trata os erros 2627 e 2601 (chave duplicada) e 547 (restrição de integridade) do SQL Server.

## Como executar

1. Abra o `clientes.pbw` no PowerBuilder 2022.
2. Confira o `clientes.ini` na pasta do target. Para começar sem banco, use `Modo=mock`.
3. Execute o target `app_clientes`.

Para distribuir, gere o executável e coloque o `clientes.ini` e a pasta `dados/` (se usar o modo mock) ao lado do `.exe`.

## Autoteste

```
app_clientes.exe /autoteste
```

O parâmetro abre a tela sem caixas de diálogo (as perguntas são respondidas com "Sim") e executa o roteiro de [n_cst_autoteste.sru](n_cst_autoteste.sru):

1. abertura da tela e carga do JSON (datas e data/hora inclusive);
2. filtro de inativos;
3. pesquisa por nome e pelo início do CPF/CNPJ pontuado;
4. rejeição de CPF, CNPJ, e-mail, telefone e data futura inválidos;
5. inclusão de cliente PF válido e rejeição de CPF duplicado;
6. alteração, gravação de `data_alteracao` e persistência no JSON;
7. inclusão de cliente PJ, com troca dos rótulos para CNPJ e Razão social;
8. exclusão dos clientes de teste e conferência do total.

O resultado vai para `autoteste.log`, na pasta do `.ini`, com o total de verificações e falhas. O roteiro foi escrito para o modo **mock**: ele inclui e depois exclui clientes de teste no `dados/clientes.json`, deixando o arquivo com o mesmo total de registros do início.

## Convenções de nomenclatura

| Prefixo | Tipo |
|---|---|
| `w_` | janela |
| `d_` | DataWindow |
| `n_cst_` | objeto não visual (serviço) |
| `of_` / `wf_` | função de objeto / de janela |
| `ue_` | evento de usuário |
| `ls_`, `ll_`, `li_`, `lb_` | variáveis locais (string, long, integer, boolean) |
| `is_`, `ib_`, `ids_`, `inv_` | variáveis de instância |
| `gnv_` | variável global |
