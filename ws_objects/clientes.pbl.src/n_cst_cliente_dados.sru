$PBExportHeader$n_cst_cliente_dados.sru
$PBExportComments$Acesso aos dados de clientes: SQL Server (Modo=sqlserver) ou arquivo JSON (Modo=mock)
forward
global type n_cst_cliente_dados from nonvisualobject
end type
end forward

global type n_cst_cliente_dados from nonvisualobject
end type
global n_cst_cliente_dados n_cst_cliente_dados

type variables
private:
string is_modo = "sqlserver"
string is_arquivo_mock
string is_erro
string is_ultima_mensagem
boolean ib_silencioso
datastore ids_mock
end variables

forward prototypes
public function integer of_inicializar (string as_ini)
public subroutine of_finalizar ()
public function string of_modo ()
public function string of_ultimo_erro ()
public function string of_ultima_mensagem ()
public function string of_arquivo_mock ()
public subroutine of_set_silencioso (boolean ab_silencioso)
public subroutine of_mensagem (string as_titulo, string as_texto, icon ae_icone)
public function integer of_perguntar (string as_titulo, string as_texto, button ae_botoes, integer ai_padrao)
public function long of_listar (datawindow adw_lista, string as_filtro, string as_inativos)
public function long of_carregar (datawindow adw_detalhe, long al_id)
public function integer of_documento_em_uso (string as_documento, long al_id)
public function integer of_salvar (datawindow adw_detalhe)
public function integer of_excluir (datawindow adw_detalhe)
public function integer of_recarregar ()
private function string of_pasta (string as_arquivo)
private function string of_sem_aspas (string as_texto)
private function integer of_mock_ler ()
private function integer of_mock_gravar ()
private function long of_mock_linha (long al_id)
private function long of_mock_proximo_id ()
end prototypes

public function integer of_inicializar (string as_ini);// Lê o modo de acesso do .ini e prepara a conexão (SQL Server) ou o arquivo (mock JSON)
string ls_arquivo

is_modo = Lower(Trim(ProfileString(as_ini, "App", "Modo", "sqlserver")))

if is_modo = "mock" then
	ls_arquivo = ProfileString(as_ini, "App", "ArquivoMock", "dados\clientes.json")
	if Pos(ls_arquivo, ":") = 0 and Left(ls_arquivo, 2) <> "\\" then
		ls_arquivo = of_pasta(as_ini) + ls_arquivo
	end if
	is_arquivo_mock = ls_arquivo

	ids_mock = create datastore
	ids_mock.dataobject = "d_cliente_detalhe"
	return of_mock_ler()
end if

is_modo = "sqlserver"
SQLCA.DBMS       = ProfileString(as_ini, "Database", "DBMS", "MSOLEDBSQL SQL Server")
SQLCA.ServerName = ProfileString(as_ini, "Database", "ServerName", "localhost")
SQLCA.Database   = ProfileString(as_ini, "Database", "Database", "pb_clientes")
SQLCA.LogId      = ProfileString(as_ini, "Database", "LogId", "")
SQLCA.LogPass    = ProfileString(as_ini, "Database", "LogPass", "")
SQLCA.DBParm     = ProfileString(as_ini, "Database", "DBParm", "")
SQLCA.AutoCommit = false

connect using SQLCA;

if SQLCA.SQLCode <> 0 then
	is_erro = "Não foi possível conectar ao banco de dados.~r~n~r~n" + &
		"Servidor: " + SQLCA.ServerName + "~r~nBanco: " + SQLCA.Database + "~r~n~r~n" + SQLCA.SQLErrText
	return -1
end if

return 1
end function

public subroutine of_finalizar ();if is_modo = "mock" then
	if IsValid(ids_mock) then destroy ids_mock
else
	disconnect using SQLCA;
end if
end subroutine

public function string of_modo ();return is_modo
end function

public function string of_ultimo_erro ();return is_erro
end function

public function string of_ultima_mensagem ();return is_ultima_mensagem
end function

public function string of_arquivo_mock ();return is_arquivo_mock
end function

public subroutine of_set_silencioso (boolean ab_silencioso);// Modo silencioso (autoteste): mensagens não abrem caixa de diálogo e perguntas respondem "Sim"
ib_silencioso = ab_silencioso
end subroutine

public subroutine of_mensagem (string as_titulo, string as_texto, icon ae_icone);is_ultima_mensagem = as_texto
if ib_silencioso then return
MessageBox(as_titulo, as_texto, ae_icone)
end subroutine

public function integer of_perguntar (string as_titulo, string as_texto, button ae_botoes, integer ai_padrao);is_ultima_mensagem = as_texto
if ib_silencioso then return 1
return MessageBox(as_titulo, as_texto, Question!, ae_botoes, ai_padrao)
end function

public function long of_listar (datawindow adw_lista, string as_filtro, string as_inativos);// Preenche a lista de clientes. Retorna a quantidade de linhas (ou -1 em erro).
string ls_filtro, ls_expressao, ls_json, ls_erro

if is_modo <> "mock" then return adw_lista.Retrieve(as_filtro, as_inativos)

ls_filtro = Lower(of_sem_aspas(as_filtro))

if as_inativos <> "S" then ls_expressao = "ativo = 'S'"
if ls_filtro <> "" then
	if ls_expressao <> "" then ls_expressao += " and "
	ls_expressao += "(pos(lower(nome), '" + ls_filtro + "') > 0" + &
		" or pos(cpf_cnpj, '" + ls_filtro + "') = 1" + &
		" or pos(lower(if(isnull(cidade), '', cidade)), '" + ls_filtro + "') > 0)"
end if

ids_mock.SetFilter(ls_expressao)
ids_mock.Filter()
ids_mock.SetSort("nome A")
ids_mock.Sort()

adw_lista.SetRedraw(false)
adw_lista.Reset()
if ids_mock.RowCount() > 0 then
	ls_json = ids_mock.ExportJson()
	adw_lista.ImportJsonByKey(ls_json, ls_erro)
end if
adw_lista.ResetUpdate()
adw_lista.SetRedraw(true)

ids_mock.SetFilter("")
ids_mock.Filter()

return adw_lista.RowCount()
end function

public function long of_carregar (datawindow adw_detalhe, long al_id);// Carrega um cliente no formulário. Retorna 1 (achou), 0 (não achou) ou -1 (erro).
long ll_linha

if is_modo <> "mock" then return adw_detalhe.Retrieve(al_id)

adw_detalhe.Reset()
ll_linha = of_mock_linha(al_id)
if ll_linha < 1 then return 0

ids_mock.RowsCopy(ll_linha, ll_linha, Primary!, adw_detalhe, 1, Primary!)
adw_detalhe.ResetUpdate()
return 1
end function

public function integer of_documento_em_uso (string as_documento, long al_id);// 1 = CPF/CNPJ já usado por outro cliente | 0 = livre | -1 = erro
long ll_qtd, ll_linha

if IsNull(al_id) then al_id = 0

if is_modo = "mock" then
	if ids_mock.RowCount() = 0 then return 0
	ll_linha = ids_mock.Find("cpf_cnpj = '" + of_sem_aspas(as_documento) + "' and id_cliente <> " + String(al_id), &
		1, ids_mock.RowCount())
	if ll_linha < 0 then return -1
	if ll_linha > 0 then return 1
	return 0
end if

SELECT COUNT(*)
  INTO :ll_qtd
  FROM cliente
 WHERE cpf_cnpj = :as_documento
   AND id_cliente <> :al_id
 USING SQLCA;

if SQLCA.SQLCode = -1 then
	is_erro = SQLCA.SQLErrText
	rollback using SQLCA;
	return -1
end if

if ll_qtd > 0 then return 1
return 0
end function

public function integer of_salvar (datawindow adw_detalhe);// Grava o cliente do formulário (linha 1). Retorna 1 = ok | -1 = erro
long ll_id, ll_linha

if adw_detalhe.RowCount() < 1 then return 1

if is_modo <> "mock" then
	if adw_detalhe.Update() <> 1 then
		rollback using SQLCA;
		return -1
	end if
	commit using SQLCA;
	if SQLCA.SQLCode <> 0 then
		is_erro = SQLCA.SQLErrText
		of_mensagem("Erro no banco de dados", "Falha ao confirmar a gravação:~r~n" + is_erro, StopSign!)
		rollback using SQLCA;
		return -1
	end if
	return 1
end if

// Mock: substitui (ou inclui) a linha no datastore e regrava o arquivo JSON
ll_id = adw_detalhe.GetItemNumber(1, "id_cliente")
if IsNull(ll_id) or ll_id = 0 then
	ll_id = of_mock_proximo_id()
	adw_detalhe.SetItem(1, "id_cliente", ll_id)
	adw_detalhe.SetItem(1, "data_cadastro", DateTime(Today(), Now()))
else
	ll_linha = of_mock_linha(ll_id)
	if ll_linha > 0 then ids_mock.RowsDiscard(ll_linha, ll_linha, Primary!)
end if

adw_detalhe.RowsCopy(1, 1, Primary!, ids_mock, ids_mock.RowCount() + 1, Primary!)

if of_mock_gravar() <> 1 then
	of_mensagem("Erro no mock", is_erro, StopSign!)
	of_mock_ler()
	return -1
end if

adw_detalhe.ResetUpdate()
return 1
end function

public function integer of_excluir (datawindow adw_detalhe);// Exclui o cliente do formulário (linha 1). Retorna 1 = ok | -1 = erro
long ll_id, ll_linha

if adw_detalhe.RowCount() < 1 then return 1

if is_modo <> "mock" then
	adw_detalhe.DeleteRow(1)
	if adw_detalhe.Update() = 1 then
		commit using SQLCA;
		return 1
	end if
	rollback using SQLCA;
	return -1
end if

ll_id = adw_detalhe.GetItemNumber(1, "id_cliente")
ll_linha = of_mock_linha(ll_id)
if ll_linha > 0 then ids_mock.RowsDiscard(ll_linha, ll_linha, Primary!)

if of_mock_gravar() <> 1 then
	of_mensagem("Erro no mock", is_erro, StopSign!)
	of_mock_ler()
	return -1
end if

adw_detalhe.Reset()
return 1
end function

public function integer of_recarregar ();// Relê o arquivo JSON (mock). No SQL Server não há o que fazer.
if is_modo <> "mock" then return 1
return of_mock_ler()
end function

private function string of_pasta (string as_arquivo);long ll_pos
ll_pos = LastPos(as_arquivo, "\")
if ll_pos = 0 then return ""
return Left(as_arquivo, ll_pos)
end function

private function string of_sem_aspas (string as_texto);// Remove aspas e til para montar expressões de Filter/Find com segurança
string ls_retorno, ls_char
long ll_i, ll_tamanho

if IsNull(as_texto) then return ""
ll_tamanho = Len(as_texto)
for ll_i = 1 to ll_tamanho
	ls_char = Mid(as_texto, ll_i, 1)
	if ls_char <> "'" and ls_char <> "~"" and ls_char <> "~~" then ls_retorno += ls_char
next
return Trim(ls_retorno)
end function

private function integer of_mock_ler ();integer li_arquivo
long ll_bytes, ll_inicio, ll_linhas
blob lblb_dados
string ls_json, ls_erro

ids_mock.Reset()

if not FileExists(is_arquivo_mock) then
	is_erro = "Arquivo do mock não encontrado:~r~n" + is_arquivo_mock
	return -1
end if

li_arquivo = FileOpen(is_arquivo_mock, StreamMode!, Read!, Shared!)
if li_arquivo < 0 then
	is_erro = "Não foi possível abrir o arquivo do mock:~r~n" + is_arquivo_mock
	return -1
end if
ll_bytes = FileReadEx(li_arquivo, lblb_dados)
FileClose(li_arquivo)

if ll_bytes <= 0 then return 1   // arquivo vazio = nenhum cliente

ls_json = String(lblb_dados, EncodingUTF8!)
ll_inicio = Pos(ls_json, "[")    // ignora BOM ou espaços antes do array
if ll_inicio = 0 then
	is_erro = "O arquivo do mock não contém um array JSON:~r~n" + is_arquivo_mock
	return -1
end if
ls_json = Mid(ls_json, ll_inicio)

ll_linhas = ids_mock.ImportJsonByKey(ls_json, ls_erro)
if ll_linhas < 0 and ll_linhas <> -2 then
	is_erro = "Erro ao importar o JSON do mock (código " + String(ll_linhas) + "):~r~n" + ls_erro
	return -1
end if

ids_mock.ResetUpdate()
return 1
end function

private function integer of_mock_gravar ();integer li_arquivo
string ls_json
blob lblb_dados

ids_mock.SetSort("id_cliente A")
ids_mock.Sort()

if ids_mock.RowCount() = 0 then
	ls_json = "[]"
else
	ls_json = ids_mock.ExportJson()
	if IsNull(ls_json) or ls_json = "" then
		is_erro = "Falha ao gerar o JSON do mock."
		return -1
	end if
end if

lblb_dados = Blob(ls_json, EncodingUTF8!)

li_arquivo = FileOpen(is_arquivo_mock, StreamMode!, Write!, LockWrite!, Replace!)
if li_arquivo < 0 then
	is_erro = "Não foi possível gravar o arquivo do mock:~r~n" + is_arquivo_mock
	return -1
end if

if FileWriteEx(li_arquivo, lblb_dados) < 0 then
	FileClose(li_arquivo)
	is_erro = "Falha ao escrever no arquivo do mock:~r~n" + is_arquivo_mock
	return -1
end if
FileClose(li_arquivo)

ids_mock.ResetUpdate()
return 1
end function

private function long of_mock_linha (long al_id);if IsNull(al_id) or ids_mock.RowCount() = 0 then return 0
return ids_mock.Find("id_cliente = " + String(al_id), 1, ids_mock.RowCount())
end function

private function long of_mock_proximo_id ();long ll_i, ll_max, ll_id

for ll_i = 1 to ids_mock.RowCount()
	ll_id = ids_mock.GetItemNumber(ll_i, "id_cliente")
	if not IsNull(ll_id) and ll_id > ll_max then ll_max = ll_id
next

return ll_max + 1
end function

on n_cst_cliente_dados.create
call super::create
TriggerEvent( this, "constructor" )
end on

on n_cst_cliente_dados.destroy
TriggerEvent( this, "destructor" )
call super::destroy
end on
