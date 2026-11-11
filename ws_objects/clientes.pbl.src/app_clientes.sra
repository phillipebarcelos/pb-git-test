$PBExportHeader$app_clientes.sra
$PBExportComments$Aplicação: cadastro de clientes (SQL Server ou mock JSON, conforme clientes.ini)
forward
global type app_clientes from application
end type
global transaction sqlca
global dynamicdescriptionarea sqlda
global dynamicstagingarea sqlsa
global error error
global message message
end forward

global variables
// Acesso aos dados (SQL Server ou mock JSON) - criado no open da aplicação
n_cst_cliente_dados gnv_dados
end variables

global type app_clientes from application
string appname = "app_clientes"
string appruntimeversion = "25.0.0.3726"
end type
global app_clientes app_clientes

on app_clientes.create
appname = "app_clientes"
message = create message
sqlca = create transaction
sqlda = create dynamicdescriptionarea
sqlsa = create dynamicstagingarea
error = create error
end on

on app_clientes.destroy
destroy( sqlca )
destroy( sqlda )
destroy( sqlsa )
destroy( error )
destroy( message )
end on

event open;// Parâmetros de linha de comando:
//   /autoteste   executa o roteiro de testes da tela e grava autoteste.log ao lado do .ini
string ls_ini, ls_parametros
integer li_falhas
n_cst_autoteste lnv_teste

ls_ini = GetCurrentDirectory() + "\clientes.ini"
ls_parametros = Lower(CommandParm())

if not FileExists(ls_ini) then
	MessageBox("Configuração", "Arquivo de configuração não encontrado:~r~n" + ls_ini + &
		"~r~n~r~nCopie config\clientes.ini.exemplo para essa pasta com o nome clientes.ini.", StopSign!)
	return
end if

gnv_dados = create n_cst_cliente_dados

if Pos(ls_parametros, "/autoteste") > 0 then gnv_dados.of_set_silencioso(true)

if gnv_dados.of_inicializar(ls_ini) <> 1 then
	MessageBox("Cadastro de Clientes", gnv_dados.of_ultimo_erro(), StopSign!)
	return
end if

if Pos(ls_parametros, "/autoteste") > 0 then
	lnv_teste = create n_cst_autoteste
	li_falhas = lnv_teste.of_executar(GetCurrentDirectory() + "\autoteste.log")
	destroy lnv_teste
	return
end if

Open(w_cliente)
end event

event close;if IsValid(gnv_dados) then
	gnv_dados.of_finalizar()
	destroy gnv_dados
end if
end event
