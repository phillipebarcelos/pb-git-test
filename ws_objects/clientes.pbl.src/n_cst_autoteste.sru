$PBExportHeader$n_cst_autoteste.sru
$PBExportComments$Roteiro de testes da tela de clientes (executado com: app_clientes.exe /autoteste)
forward
global type n_cst_autoteste from nonvisualobject
end type
end forward

global type n_cst_autoteste from nonvisualobject
end type
global n_cst_autoteste n_cst_autoteste

type variables
private:
integer ii_arquivo
integer ii_testes
integer ii_falhas
end variables

forward prototypes
public function integer of_executar (string as_log)
private subroutine of_log (string as_texto)
private subroutine of_verificar (boolean ab_condicao, string as_descricao)
private function long of_total (w_cliente aw_tela)
end prototypes

public function integer of_executar (string as_log);// Executa o roteiro e grava o resultado em as_log. Retorna a quantidade de falhas.
w_cliente lw
long ll_ativos, ll_total_inicial, ll_linhas, ll_id_pf, ll_id_pj
string ls_nome, ls_palavra, ls_doc

ii_arquivo = FileOpen(as_log, LineMode!, Write!, LockWrite!, Replace!, EncodingUTF8!)

of_log("Autoteste pb-clientes - " + String(Today(), "dd/mm/yyyy") + " " + String(Now(), "hh:mm:ss"))
of_log("Modo: " + gnv_dados.of_modo() + "  |  Arquivo: " + gnv_dados.of_arquivo_mock())
of_log("")

// 1. Abertura da tela
Open(w_cliente)
lw = w_cliente
of_verificar(IsValid(lw), "Tela w_cliente abre")
if not IsValid(lw) then goto fim

ll_ativos = lw.dw_lista.RowCount()
of_verificar(ll_ativos > 0, "Lista carrega clientes ativos do JSON (" + String(ll_ativos) + ")")
of_verificar(lw.dw_detalhe.RowCount() = 1, "Formulário carrega o cliente selecionado")
if lw.dw_detalhe.RowCount() = 1 then
	ls_nome = lw.dw_detalhe.GetItemString(1, "nome")
	of_verificar(not IsNull(ls_nome) and ls_nome <> "", "Nome do cliente carregado (" + ls_nome + ")")
	of_verificar(not IsNull(lw.dw_detalhe.GetItemDate(1, "data_nascimento")), "Data (date) importada do JSON")
	of_verificar(not IsNull(lw.dw_detalhe.GetItemDateTime(1, "data_cadastro")), "Data/hora (datetime) importada do JSON")
	of_verificar(lw.dw_detalhe.GetItemStatus(1, 0, Primary!) = NotModified!, "Cliente carregado sem alterações pendentes")
end if

// 2. Mostrar inativos
lw.cbx_inativos.checked = true
ll_total_inicial = lw.wf_pesquisar(0)
of_verificar(ll_total_inicial >= ll_ativos, "Mostrar inativos lista todos (" + String(ll_total_inicial) + ")")

// 3. Pesquisa por parte do nome
ls_palavra = Lower(Left(ls_nome, Pos(ls_nome + " ", " ") - 1))
lw.sle_filtro.text = ls_palavra
ll_linhas = lw.wf_pesquisar(0)
of_verificar(ll_linhas >= 1, "Pesquisa por nome ~"" + ls_palavra + "~" encontra " + String(ll_linhas))
if ll_linhas >= 1 then
	of_verificar(Pos(Lower(lw.dw_lista.GetItemString(1, "nome")), ls_palavra) > 0, "Resultado da pesquisa contém o texto")

	// 4. Pesquisa pelo início do CPF/CNPJ digitado com pontuação
	ls_doc = lw.dw_lista.GetItemString(1, "cpf_cnpj")
	lw.sle_filtro.text = Left(ls_doc, 3) + "." + Mid(ls_doc, 4, 3)
	ll_linhas = lw.wf_pesquisar(0)
	of_verificar(ll_linhas >= 1, "Pesquisa por documento ~"" + lw.sle_filtro.text + "~" encontra " + String(ll_linhas))
end if

lw.sle_filtro.text = ""
lw.wf_pesquisar(0)

// 5. Inclusão com CPF inválido
lw.event ue_novo()
of_verificar(lw.dw_detalhe.RowCount() = 1, "Novo cria um formulário em branco")
of_verificar(lw.dw_detalhe.GetItemString(1, "tipo_pessoa") = "F" and lw.dw_detalhe.GetItemString(1, "ativo") = "S", &
	"Novo cliente nasce como Pessoa Física e ativo")
lw.dw_detalhe.SetItem(1, "nome", "Cliente Autoteste PF")
lw.dw_detalhe.SetItem(1, "cpf_cnpj", "12345678900")
of_verificar(lw.wf_salvar() = -1 and Pos(gnv_dados.of_ultima_mensagem(), "CPF inválido") > 0, "Rejeita CPF inválido")

// 6. Outras validações
lw.dw_detalhe.SetItem(1, "cpf_cnpj", "52998224725")
lw.dw_detalhe.SetItem(1, "email", "invalido@")
of_verificar(lw.wf_salvar() = -1 and Pos(gnv_dados.of_ultima_mensagem(), "E-mail inválido") > 0, "Rejeita e-mail inválido")
lw.dw_detalhe.SetItem(1, "email", "autoteste@exemplo.com.br")
lw.dw_detalhe.SetItem(1, "telefone", "123")
of_verificar(lw.wf_salvar() = -1 and Pos(gnv_dados.of_ultima_mensagem(), "Telefone") > 0, "Rejeita telefone incompleto")
lw.dw_detalhe.SetItem(1, "telefone", "1133334444")
lw.dw_detalhe.SetItem(1, "data_nascimento", RelativeDate(Today(), 10))
of_verificar(lw.wf_salvar() = -1 and Pos(gnv_dados.of_ultima_mensagem(), "futura") > 0, "Rejeita data futura")

// 7. Inclusão válida (PF)
lw.dw_detalhe.SetItem(1, "data_nascimento", Date(1990, 5, 20))
lw.dw_detalhe.SetItem(1, "celular", "11999998888")
lw.dw_detalhe.SetItem(1, "cep", "01001000")
lw.dw_detalhe.SetItem(1, "logradouro", "Praça da Sé")
lw.dw_detalhe.SetItem(1, "numero", "100")
lw.dw_detalhe.SetItem(1, "cidade", "São Paulo")
lw.dw_detalhe.SetItem(1, "uf", "SP")
of_verificar(lw.wf_salvar() = 1, "Salva cliente PF válido")
ll_id_pf = lw.dw_detalhe.GetItemNumber(1, "id_cliente")
of_verificar(not IsNull(ll_id_pf) and ll_id_pf > 0, "Cliente novo recebe código (" + String(ll_id_pf) + ")")
of_verificar(of_total(lw) = ll_total_inicial + 1, "Inclusão gravada no arquivo JSON")

// 8. CPF duplicado
lw.event ue_novo()
lw.dw_detalhe.SetItem(1, "nome", "Cliente Duplicado")
lw.dw_detalhe.SetItem(1, "cpf_cnpj", "52998224725")
of_verificar(lw.wf_salvar() = -1 and Pos(gnv_dados.of_ultima_mensagem(), "Já existe") > 0, "Rejeita CPF já cadastrado")
lw.event ue_cancelar()

// 9. Alteração
lw.wf_pesquisar(ll_id_pf)
of_verificar(lw.dw_detalhe.GetItemNumber(1, "id_cliente") = ll_id_pf, "Pesquisa posiciona no cliente incluído")
lw.dw_detalhe.SetItem(1, "nome", "Cliente Autoteste PF Alterado")
of_verificar(lw.wf_salvar() = 1, "Salva alteração")
of_verificar(not IsNull(lw.dw_detalhe.GetItemDateTime(1, "data_alteracao")), "Alteração registra data_alteracao")
gnv_dados.of_recarregar()
lw.wf_carregar(ll_id_pf)
of_verificar(lw.dw_detalhe.GetItemString(1, "nome") = "Cliente Autoteste PF Alterado", "Alteração persistida no JSON")

// 10. Pessoa jurídica
lw.event ue_novo()
lw.dw_detalhe.SetItem(1, "tipo_pessoa", "J")
lw.event ue_ajusta_tipo()
of_verificar(lw.dw_detalhe.Describe("cpf_cnpj_t.Text") = "CNPJ:" and lw.dw_detalhe.Describe("nome_t.Text") = "Razão social:", &
	"PJ troca rótulos para CNPJ / Razão social")
lw.dw_detalhe.SetItem(1, "nome", "Empresa Autoteste Ltda")
lw.dw_detalhe.SetItem(1, "cpf_cnpj", "11222333000180")
of_verificar(lw.wf_salvar() = -1 and Pos(gnv_dados.of_ultima_mensagem(), "CNPJ inválido") > 0, "Rejeita CNPJ inválido")
lw.dw_detalhe.SetItem(1, "cpf_cnpj", "11222333000181")
of_verificar(lw.wf_salvar() = 1, "Salva cliente PJ válido")
ll_id_pj = lw.dw_detalhe.GetItemNumber(1, "id_cliente")

// 11. Exclusão dos clientes de teste
lw.wf_pesquisar(ll_id_pj)
lw.event ue_excluir()
lw.wf_pesquisar(ll_id_pf)
lw.event ue_excluir()
of_verificar(of_total(lw) = ll_total_inicial, "Exclusões gravadas no JSON (total volta a " + String(ll_total_inicial) + ")")
of_verificar(lw.dw_lista.Find("id_cliente = " + String(ll_id_pf) + " or id_cliente = " + String(ll_id_pj), 1, lw.dw_lista.RowCount()) = 0, &
	"Clientes de teste não aparecem mais na lista")

Close(lw)

fim:
of_log("")
of_log("RESULTADO: " + String(ii_testes) + " verificações, " + String(ii_falhas) + " falha(s)")
if ii_arquivo > 0 then FileClose(ii_arquivo)
return ii_falhas
end function

private subroutine of_log (string as_texto);if ii_arquivo > 0 then FileWrite(ii_arquivo, as_texto)
end subroutine

private subroutine of_verificar (boolean ab_condicao, string as_descricao);ii_testes++
if IsNull(ab_condicao) then ab_condicao = false
if ab_condicao then
	of_log("[OK]    " + as_descricao)
else
	ii_falhas++
	of_log("[FALHA] " + as_descricao + "   (última mensagem: " + gnv_dados.of_ultima_mensagem() + ")")
end if
end subroutine

private function long of_total (w_cliente aw_tela);// Relê o arquivo e conta todos os clientes (ativos e inativos)
aw_tela.sle_filtro.text = ""
aw_tela.cbx_inativos.checked = true
gnv_dados.of_recarregar()
return aw_tela.wf_pesquisar(0)
end function

on n_cst_autoteste.create
call super::create
TriggerEvent( this, "constructor" )
end on

on n_cst_autoteste.destroy
TriggerEvent( this, "destructor" )
call super::destroy
end on
