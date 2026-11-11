$PBExportHeader$n_cst_validacao.sru
$PBExportComments$Validações de CPF, CNPJ e e-mail
forward
global type n_cst_validacao from nonvisualobject
end type
end forward

global type n_cst_validacao from nonvisualobject
end type
global n_cst_validacao n_cst_validacao

forward prototypes
public function string of_somente_digitos (string as_texto)
public function boolean of_e_documento (string as_texto)
public function boolean of_cpf_valido (string as_cpf)
public function boolean of_cnpj_valido (string as_cnpj)
public function boolean of_email_valido (string as_email)
private function integer of_digito (string as_base, boolean ab_cnpj)
end prototypes

public function string of_somente_digitos (string as_texto);// Retorna apenas os dígitos do texto (ex.: "123.456.789-09" -> "12345678909")
string ls_retorno, ls_char
long ll_i, ll_tamanho

if IsNull(as_texto) then return ""

ll_tamanho = Len(as_texto)
for ll_i = 1 to ll_tamanho
	ls_char = Mid(as_texto, ll_i, 1)
	if Pos("0123456789", ls_char) > 0 then ls_retorno += ls_char
next

return ls_retorno
end function

public function boolean of_e_documento (string as_texto);// True quando o texto parece um CPF/CNPJ digitado (só dígitos, pontos, traço e barra)
string ls_char
long ll_i, ll_tamanho
boolean lb_tem_digito

if IsNull(as_texto) then return false

ll_tamanho = Len(as_texto)
if ll_tamanho = 0 then return false

for ll_i = 1 to ll_tamanho
	ls_char = Mid(as_texto, ll_i, 1)
	if Pos("0123456789", ls_char) > 0 then
		lb_tem_digito = true
	elseif Pos(".-/", ls_char) = 0 then
		return false
	end if
next

return lb_tem_digito
end function

public function boolean of_cpf_valido (string as_cpf);string ls_cpf, ls_calculado

ls_cpf = of_somente_digitos(as_cpf)
if Len(ls_cpf) <> 11 then return false
if ls_cpf = Fill(Left(ls_cpf, 1), 11) then return false

ls_calculado = Left(ls_cpf, 9)
ls_calculado += String(of_digito(ls_calculado, false))
ls_calculado += String(of_digito(ls_calculado, false))

return ls_calculado = ls_cpf
end function

public function boolean of_cnpj_valido (string as_cnpj);string ls_cnpj, ls_calculado

ls_cnpj = of_somente_digitos(as_cnpj)
if Len(ls_cnpj) <> 14 then return false
if ls_cnpj = Fill(Left(ls_cnpj, 1), 14) then return false

ls_calculado = Left(ls_cnpj, 12)
ls_calculado += String(of_digito(ls_calculado, true))
ls_calculado += String(of_digito(ls_calculado, true))

return ls_calculado = ls_cnpj
end function

public function boolean of_email_valido (string as_email);// E-mail é opcional: vazio é considerado válido
long ll_arroba, ll_ponto

if IsNull(as_email) then return true
as_email = Trim(as_email)
if as_email = "" then return true

if Pos(as_email, " ") > 0 then return false

ll_arroba = Pos(as_email, "@")
if ll_arroba < 2 then return false
if Pos(as_email, "@", ll_arroba + 1) > 0 then return false

ll_ponto = LastPos(as_email, ".")
if ll_ponto < ll_arroba + 2 then return false
if ll_ponto = Len(as_email) then return false

return true
end function

private function integer of_digito (string as_base, boolean ab_cnpj);// Dígito verificador (módulo 11)
// CPF : pesos decrescentes até 2 (10..2 / 11..2)
// CNPJ: pesos cíclicos 2..9 da direita para a esquerda
long ll_i, ll_tamanho, ll_soma, ll_peso, ll_resto

ll_tamanho = Len(as_base)
for ll_i = 1 to ll_tamanho
	if ab_cnpj then
		ll_peso = Mod(ll_tamanho - ll_i, 8) + 2
	else
		ll_peso = ll_tamanho - ll_i + 2
	end if
	ll_soma += Integer(Mid(as_base, ll_i, 1)) * ll_peso
next

ll_resto = Mod(ll_soma, 11)
if ll_resto < 2 then return 0
return 11 - ll_resto
end function

on n_cst_validacao.create
call super::create
TriggerEvent( this, "constructor" )
end on

on n_cst_validacao.destroy
TriggerEvent( this, "destructor" )
call super::destroy
end on
