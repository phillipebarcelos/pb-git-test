$PBExportHeader$w_cliente.srw
$PBExportComments$Cadastro de clientes: pesquisa (lista) + formulário (CRUD)
forward
global type w_cliente from window
end type
type st_filtro from statictext within w_cliente
end type
type sle_filtro from singlelineedit within w_cliente
end type
type cb_pesquisar from commandbutton within w_cliente
end type
type cbx_inativos from checkbox within w_cliente
end type
type st_total from statictext within w_cliente
end type
type dw_lista from datawindow within w_cliente
end type
type dw_detalhe from datawindow within w_cliente
end type
type cb_novo from commandbutton within w_cliente
end type
type cb_salvar from commandbutton within w_cliente
end type
type cb_excluir from commandbutton within w_cliente
end type
type cb_cancelar from commandbutton within w_cliente
end type
type cb_fechar from commandbutton within w_cliente
end type
end forward

global type w_cliente from window
integer width = 4114
integer height = 2800
boolean titlebar = true
string title = "Cadastro de Clientes"
boolean controlmenu = true
boolean minbox = true
boolean maxbox = true
boolean resizable = true
long backcolor = 67108864
string icon = "AppIcon!"
boolean center = true
event ue_novo ( )
event ue_salvar ( )
event ue_excluir ( )
event ue_cancelar ( )
event ue_pesquisar ( )
event ue_ajusta_tipo ( )
event ue_atualiza_lista ( long al_id )
st_filtro st_filtro
sle_filtro sle_filtro
cb_pesquisar cb_pesquisar
cbx_inativos cbx_inativos
st_total st_total
dw_lista dw_lista
dw_detalhe dw_detalhe
cb_novo cb_novo
cb_salvar cb_salvar
cb_excluir cb_excluir
cb_cancelar cb_cancelar
cb_fechar cb_fechar
end type
global w_cliente w_cliente

type variables
n_cst_validacao inv_valida

// true enquanto a tela troca de linha por código (evita perguntas e recargas em cascata)
boolean ib_carregando

// true quando o cliente foi salvo durante a troca de linha e a lista precisa ser relida
boolean ib_lista_desatualizada
end variables

forward prototypes
public function long wf_pesquisar (long al_id)
public subroutine wf_carregar (long al_id)
public function integer wf_salvar ()
public function integer wf_pendencias ()
public subroutine wf_erro (string as_mensagem, string as_coluna)
end prototypes

public function long wf_pesquisar (long al_id);// Relê a lista e posiciona no cliente al_id (0 = primeira linha)
string ls_filtro, ls_inativos
long ll_linhas, ll_linha

if IsNull(al_id) then al_id = 0
ib_lista_desatualizada = false

ls_filtro = Trim(sle_filtro.text)
if inv_valida.of_e_documento(ls_filtro) then ls_filtro = inv_valida.of_somente_digitos(ls_filtro)

if cbx_inativos.checked then
	ls_inativos = "S"
else
	ls_inativos = "N"
end if

ib_carregando = true
ll_linhas = gnv_dados.of_listar(dw_lista, ls_filtro, ls_inativos)
ib_carregando = false

if ll_linhas < 0 then ll_linhas = 0
st_total.text = String(ll_linhas) + " cliente(s) encontrado(s)"

if al_id > 0 and ll_linhas > 0 then
	ll_linha = dw_lista.Find("id_cliente = " + String(al_id), 1, ll_linhas)
end if

// Cliente salvo que não aparece no filtro atual: mostra no formulário mesmo assim
if al_id > 0 and ll_linha < 1 then
	dw_lista.SelectRow(0, false)
	wf_carregar(al_id)
	return ll_linhas
end if

if ll_linhas = 0 then
	dw_detalhe.Reset()
	return 0
end if

if ll_linha < 1 then ll_linha = 1

ib_carregando = true
dw_lista.SetRow(ll_linha)
dw_lista.ScrollToRow(ll_linha)
ib_carregando = false

dw_lista.SelectRow(0, false)
dw_lista.SelectRow(ll_linha, true)
wf_carregar(dw_lista.GetItemNumber(ll_linha, "id_cliente"))

return ll_linhas
end function

public subroutine wf_carregar (long al_id);gnv_dados.of_carregar(dw_detalhe, al_id)
this.event ue_ajusta_tipo()
end subroutine

public function integer wf_salvar ();// Valida e grava o cliente do formulário.
// Retorno: 1 = gravado (ou nada a gravar) | -1 = erro/validação
string ls_tipo, ls_nome, ls_doc, ls_email, ls_aux
long ll_id
integer li_em_uso
date ld_data

if dw_detalhe.RowCount() < 1 then return 1
if dw_detalhe.AcceptText() = -1 then return -1
if dw_detalhe.GetItemStatus(1, 0, Primary!) = NotModified! then return 1

// Nome / razão social
ls_nome = Trim(dw_detalhe.GetItemString(1, "nome"))
if IsNull(ls_nome) or ls_nome = "" then
	wf_erro("Informe o nome do cliente.", "nome")
	return -1
end if
dw_detalhe.SetItem(1, "nome", ls_nome)

// CPF / CNPJ
ls_tipo = dw_detalhe.GetItemString(1, "tipo_pessoa")
ls_doc = inv_valida.of_somente_digitos(dw_detalhe.GetItemString(1, "cpf_cnpj"))
if ls_tipo = "J" then
	if not inv_valida.of_cnpj_valido(ls_doc) then
		wf_erro("CNPJ inválido.", "cpf_cnpj")
		return -1
	end if
else
	if not inv_valida.of_cpf_valido(ls_doc) then
		wf_erro("CPF inválido.", "cpf_cnpj")
		return -1
	end if
end if
dw_detalhe.SetItem(1, "cpf_cnpj", ls_doc)

ll_id = dw_detalhe.GetItemNumber(1, "id_cliente")
if IsNull(ll_id) then ll_id = 0

li_em_uso = gnv_dados.of_documento_em_uso(ls_doc, ll_id)
if li_em_uso = -1 then
	gnv_dados.of_mensagem("Erro no banco de dados", gnv_dados.of_ultimo_erro(), StopSign!)
	return -1
end if
if li_em_uso = 1 then
	wf_erro("Já existe um cliente cadastrado com este CPF/CNPJ.", "cpf_cnpj")
	return -1
end if

// Data de nascimento / fundação
ld_data = dw_detalhe.GetItemDate(1, "data_nascimento")
if not IsNull(ld_data) then
	if ld_data > Today() then
		wf_erro("A data não pode ser futura.", "data_nascimento")
		return -1
	end if
end if

// E-mail
ls_email = Trim(dw_detalhe.GetItemString(1, "email"))
if not inv_valida.of_email_valido(ls_email) then
	wf_erro("E-mail inválido.", "email")
	return -1
end if

// Telefones e CEP (gravados só com dígitos)
ls_aux = inv_valida.of_somente_digitos(dw_detalhe.GetItemString(1, "telefone"))
if ls_aux <> "" and Len(ls_aux) <> 10 then
	wf_erro("Telefone deve ter DDD + 8 dígitos.", "telefone")
	return -1
end if

ls_aux = inv_valida.of_somente_digitos(dw_detalhe.GetItemString(1, "celular"))
if ls_aux <> "" and Len(ls_aux) <> 11 then
	wf_erro("Celular deve ter DDD + 9 dígitos.", "celular")
	return -1
end if

ls_aux = inv_valida.of_somente_digitos(dw_detalhe.GetItemString(1, "cep"))
if ls_aux <> "" and Len(ls_aux) <> 8 then
	wf_erro("CEP deve ter 8 dígitos.", "cep")
	return -1
end if

// Cidade exige UF
ls_aux = Trim(dw_detalhe.GetItemString(1, "cidade"))
if not IsNull(ls_aux) and ls_aux <> "" then
	if IsNull(dw_detalhe.GetItemString(1, "uf")) then
		wf_erro("Informe a UF da cidade.", "uf")
		return -1
	end if
end if

// Auditoria simples
if dw_detalhe.GetItemStatus(1, 0, Primary!) = DataModified! then
	dw_detalhe.SetItem(1, "data_alteracao", DateTime(Today(), Now()))
end if

return gnv_dados.of_salvar(dw_detalhe)
end function

public function integer wf_pendencias ();// Pergunta o que fazer com alterações não salvas.
// Retorno: 1 = pode continuar | 0 = interromper a ação
integer li_resposta

if dw_detalhe.RowCount() < 1 then return 1
if dw_detalhe.AcceptText() = -1 then return 0
if dw_detalhe.ModifiedCount() + dw_detalhe.DeletedCount() = 0 then return 1

li_resposta = gnv_dados.of_perguntar("Alterações não salvas", &
	"O cliente foi alterado. Deseja salvar antes de continuar?", YesNoCancel!, 1)

choose case li_resposta
	case 1
		if wf_salvar() = 1 then
			ib_lista_desatualizada = true
			return 1
		end if
		return 0
	case 2
		return 1
end choose

return 0
end function

public subroutine wf_erro (string as_mensagem, string as_coluna);gnv_dados.of_mensagem("Atenção", as_mensagem, Exclamation!)
dw_detalhe.SetFocus()
if as_coluna <> "" then dw_detalhe.SetColumn(as_coluna)
end subroutine

on w_cliente.create
this.st_filtro=create st_filtro
this.sle_filtro=create sle_filtro
this.cb_pesquisar=create cb_pesquisar
this.cbx_inativos=create cbx_inativos
this.st_total=create st_total
this.dw_lista=create dw_lista
this.dw_detalhe=create dw_detalhe
this.cb_novo=create cb_novo
this.cb_salvar=create cb_salvar
this.cb_excluir=create cb_excluir
this.cb_cancelar=create cb_cancelar
this.cb_fechar=create cb_fechar
this.Control[]={this.st_filtro,&
this.sle_filtro,&
this.cb_pesquisar,&
this.cbx_inativos,&
this.st_total,&
this.dw_lista,&
this.dw_detalhe,&
this.cb_novo,&
this.cb_salvar,&
this.cb_excluir,&
this.cb_cancelar,&
this.cb_fechar}
end on

on w_cliente.destroy
destroy(this.st_filtro)
destroy(this.sle_filtro)
destroy(this.cb_pesquisar)
destroy(this.cbx_inativos)
destroy(this.st_total)
destroy(this.dw_lista)
destroy(this.dw_detalhe)
destroy(this.cb_novo)
destroy(this.cb_salvar)
destroy(this.cb_excluir)
destroy(this.cb_cancelar)
destroy(this.cb_fechar)
end on

event open;inv_valida = create n_cst_validacao

if gnv_dados.of_modo() = "mock" then
	this.title = "Cadastro de Clientes  [MOCK: " + gnv_dados.of_arquivo_mock() + "]"
else
	dw_lista.SetTransObject(SQLCA)
	dw_detalhe.SetTransObject(SQLCA)
end if

wf_pesquisar(0)
sle_filtro.SetFocus()
end event

event closequery;if wf_pendencias() = 0 then return 1
return 0
end event

event close;if IsValid(inv_valida) then destroy inv_valida
end event

event resize;integer li_y_botoes, li_altura_lista

if sizetype = 1 then return   // minimizada

dw_lista.width = newwidth - 74
dw_detalhe.width = newwidth - 74
st_total.x = newwidth - 37 - st_total.width

li_y_botoes = newheight - 132
cb_novo.y = li_y_botoes
cb_salvar.y = li_y_botoes
cb_excluir.y = li_y_botoes
cb_cancelar.y = li_y_botoes
cb_fechar.y = li_y_botoes
cb_fechar.x = newwidth - 37 - cb_fechar.width

dw_detalhe.y = li_y_botoes - 32 - dw_detalhe.height

li_altura_lista = dw_detalhe.y - 20 - dw_lista.y
if li_altura_lista < 300 then li_altura_lista = 300
dw_lista.height = li_altura_lista
end event

event ue_novo();long ll_linha

if wf_pendencias() = 0 then return
if ib_lista_desatualizada then wf_pesquisar(0)

dw_lista.SelectRow(0, false)
dw_detalhe.Reset()
ll_linha = dw_detalhe.InsertRow(0)
dw_detalhe.ScrollToRow(ll_linha)
this.event ue_ajusta_tipo()

dw_detalhe.SetFocus()
dw_detalhe.SetColumn("nome")
end event

event ue_salvar();long ll_id

if dw_detalhe.RowCount() < 1 then return
if wf_salvar() <> 1 then return

ll_id = dw_detalhe.GetItemNumber(1, "id_cliente")
if IsNull(ll_id) then ll_id = 0

wf_pesquisar(ll_id)
gnv_dados.of_mensagem("Cadastro de Clientes", "Cliente salvo com sucesso.", Information!)
end event

event ue_excluir();long ll_id
string ls_nome
dwItemStatus le_status

if dw_detalhe.RowCount() < 1 then return

// Registro novo ainda não gravado: basta descartar
le_status = dw_detalhe.GetItemStatus(1, 0, Primary!)
if le_status = New! or le_status = NewModified! then
	this.event ue_cancelar()
	return
end if

ll_id = dw_detalhe.GetItemNumber(1, "id_cliente")
ls_nome = dw_detalhe.GetItemString(1, "nome")

if gnv_dados.of_perguntar("Excluir cliente", "Confirma a exclusão do cliente~r~n~r~n" + &
	String(ll_id) + " - " + ls_nome + " ?", YesNo!, 2) <> 1 then return

if gnv_dados.of_excluir(dw_detalhe) = 1 then
	wf_pesquisar(0)
else
	wf_carregar(ll_id)
end if
end event

event ue_cancelar();// Descarta as alterações e recarrega o cliente selecionado na lista
long ll_linha

ll_linha = dw_lista.GetRow()
if ll_linha > 0 then
	dw_lista.SelectRow(0, false)
	dw_lista.SelectRow(ll_linha, true)
	wf_carregar(dw_lista.GetItemNumber(ll_linha, "id_cliente"))
else
	dw_detalhe.Reset()
end if
end event

event ue_pesquisar();if wf_pendencias() = 0 then return
wf_pesquisar(0)
end event

event ue_ajusta_tipo();// Ajusta máscara e rótulos conforme pessoa física (F) ou jurídica (J)
string ls_tipo

if dw_detalhe.RowCount() < 1 then return

ls_tipo = dw_detalhe.GetItemString(1, "tipo_pessoa")
if ls_tipo = "J" then
	dw_detalhe.Modify("cpf_cnpj.EditMask.Mask='##.###.###/####-##' cpf_cnpj_t.Text='CNPJ:' " + &
		"nome_t.Text='Razão social:' rg_ie_t.Text='Inscr. estadual:' " + &
		"data_nascimento_t.Text='Data de fundação:'")
else
	dw_detalhe.Modify("cpf_cnpj.EditMask.Mask='###.###.###-##' cpf_cnpj_t.Text='CPF:' " + &
		"nome_t.Text='Nome:' rg_ie_t.Text='RG:' " + &
		"data_nascimento_t.Text='Data de nascimento:'")
end if
end event

event ue_atualiza_lista(long al_id);wf_pesquisar(al_id)
end event

type st_filtro from statictext within w_cliente
integer x = 37
integer y = 40
integer width = 1600
integer height = 64
integer textsize = -10
integer weight = 400
fontcharset fontcharset = ansi!
fontpitch fontpitch = variable!
fontfamily fontfamily = swiss!
string facename = "Tahoma"
long textcolor = 33554432
long backcolor = 67108864
string text = "Pesquisar (nome, CPF/CNPJ ou cidade):"
boolean focusrectangle = false
end type

type sle_filtro from singlelineedit within w_cliente
integer x = 37
integer y = 112
integer width = 1600
integer height = 92
integer taborder = 10
integer textsize = -10
integer weight = 400
fontcharset fontcharset = ansi!
fontpitch fontpitch = variable!
fontfamily fontfamily = swiss!
string facename = "Tahoma"
long textcolor = 33554432
borderstyle borderstyle = stylelowered!
end type

event modified;parent.event ue_pesquisar()
end event

type cb_pesquisar from commandbutton within w_cliente
integer x = 1673
integer y = 108
integer width = 402
integer height = 100
integer taborder = 20
integer textsize = -10
integer weight = 400
fontcharset fontcharset = ansi!
fontpitch fontpitch = variable!
fontfamily fontfamily = swiss!
string facename = "Tahoma"
string text = "&Pesquisar"
end type

event clicked;parent.event ue_pesquisar()
end event

type cbx_inativos from checkbox within w_cliente
integer x = 2120
integer y = 120
integer width = 640
integer height = 76
integer taborder = 30
integer textsize = -10
integer weight = 400
fontcharset fontcharset = ansi!
fontpitch fontpitch = variable!
fontfamily fontfamily = swiss!
string facename = "Tahoma"
long textcolor = 33554432
long backcolor = 67108864
string text = "Mostrar inativos"
end type

event clicked;parent.event ue_pesquisar()
end event

type st_total from statictext within w_cliente
integer x = 2823
integer y = 128
integer width = 1200
integer height = 64
integer textsize = -10
integer weight = 400
fontcharset fontcharset = ansi!
fontpitch fontpitch = variable!
fontfamily fontfamily = swiss!
string facename = "Tahoma"
long textcolor = 8421504
long backcolor = 67108864
alignment alignment = right!
boolean focusrectangle = false
end type

type dw_lista from datawindow within w_cliente
integer x = 37
integer y = 236
integer width = 3986
integer height = 1080
integer taborder = 40
string title = "none"
string dataobject = "d_cliente_lista"
boolean hscrollbar = true
boolean vscrollbar = true
boolean livescroll = true
borderstyle borderstyle = stylelowered!
end type

event rowfocuschanging;// Antes de trocar de cliente, trata alterações pendentes no formulário
if parent.ib_carregando then return 0
if parent.wf_pendencias() = 0 then return 1
return 0
end event

event rowfocuschanged;long ll_id

if parent.ib_carregando then return
if currentrow < 1 then return

this.SelectRow(0, false)
this.SelectRow(currentrow, true)

ll_id = this.GetItemNumber(currentrow, "id_cliente")
parent.wf_carregar(ll_id)

// O cliente anterior foi salvo durante a troca: relê a lista mantendo esta seleção
if parent.ib_lista_desatualizada then parent.event post ue_atualiza_lista(ll_id)
end event

event doubleclicked;if row > 0 then parent.dw_detalhe.SetFocus()
end event

event dberror;gnv_dados.of_mensagem("Erro no banco de dados", sqlerrtext + "~r~n~r~n(código " + String(sqldbcode) + ")", StopSign!)
return 1
end event

type dw_detalhe from datawindow within w_cliente
integer x = 37
integer y = 1336
integer width = 3986
integer height = 1150
integer taborder = 50
string title = "none"
string dataobject = "d_cliente_detalhe"
borderstyle borderstyle = stylelowered!
end type

event itemchanged;if dwo.name = "tipo_pessoa" then parent.event post ue_ajusta_tipo()
end event

event dberror;string ls_mensagem

choose case sqldbcode
	case 2627, 2601
		ls_mensagem = "Já existe um cliente cadastrado com este CPF/CNPJ."
	case 547
		ls_mensagem = "Operação não permitida: o cliente viola uma regra do banco " + &
			"ou está sendo usado em outra tabela."
	case else
		ls_mensagem = sqlerrtext
end choose

gnv_dados.of_mensagem("Erro no banco de dados", ls_mensagem + "~r~n~r~n(código " + String(sqldbcode) + ")", StopSign!)
return 1
end event

type cb_novo from commandbutton within w_cliente
integer x = 37
integer y = 2536
integer width = 402
integer height = 100
integer taborder = 60
integer textsize = -10
integer weight = 400
fontcharset fontcharset = ansi!
fontpitch fontpitch = variable!
fontfamily fontfamily = swiss!
string facename = "Tahoma"
string text = "&Novo"
end type

event clicked;parent.event ue_novo()
end event

type cb_salvar from commandbutton within w_cliente
integer x = 457
integer y = 2536
integer width = 402
integer height = 100
integer taborder = 70
integer textsize = -10
integer weight = 400
fontcharset fontcharset = ansi!
fontpitch fontpitch = variable!
fontfamily fontfamily = swiss!
string facename = "Tahoma"
string text = "&Salvar"
end type

event clicked;parent.event ue_salvar()
end event

type cb_excluir from commandbutton within w_cliente
integer x = 877
integer y = 2536
integer width = 402
integer height = 100
integer taborder = 80
integer textsize = -10
integer weight = 400
fontcharset fontcharset = ansi!
fontpitch fontpitch = variable!
fontfamily fontfamily = swiss!
string facename = "Tahoma"
string text = "&Excluir"
end type

event clicked;parent.event ue_excluir()
end event

type cb_cancelar from commandbutton within w_cliente
integer x = 1297
integer y = 2536
integer width = 402
integer height = 100
integer taborder = 90
integer textsize = -10
integer weight = 400
fontcharset fontcharset = ansi!
fontpitch fontpitch = variable!
fontfamily fontfamily = swiss!
string facename = "Tahoma"
string text = "&Cancelar"
end type

event clicked;parent.event ue_cancelar()
end event

type cb_fechar from commandbutton within w_cliente
integer x = 3621
integer y = 2536
integer width = 402
integer height = 100
integer taborder = 100
integer textsize = -10
integer weight = 400
fontcharset fontcharset = ansi!
fontpitch fontpitch = variable!
fontfamily fontfamily = swiss!
string facename = "Tahoma"
string text = "&Fechar"
end type

event clicked;Close(parent)
end event
