# ServerViaCEP - Consulta de CEP de todo o Brasil
![Delphi Supported Versions](https://img.shields.io/badge/Delphi%20Supported%20Versions-10.2%20and%20ever-blue.svg)
![Platforms](https://img.shields.io/badge/Platforms-Win32%20and%20Win64-red.svg)
![Compatibility](https://img.shields.io/badge/Compatibility-VCL,%20Firemonkey%20DataSnap%20and%20uniGUI-brightgreen.svg)


## Instalação e configuração
 * Instalar o **Firebird 2.5** localizado na pasta **Dados** do projeto.
 * Possuir as dlls **libeay32.dll** e **ssleay32.dll** na pasta do projeto junto ao executável.
 * Configurar o caminho do banco de dados no arquivo **Caminho.ini** na pasta do projeto junto ao executável.
 * Para extrair o executável basta descompactar o arquivo **ViaCEP.rar** localizado na pasta **Release** do projeto.
```	
...ServerViaCEP\samples\Win32\Release
``` 

### Validando um CEP
Quando consultado um CEP de formato inválido, por exemplo: `950100100` (9 dígitos), `95010A10` (alfanumérico), `95 01010` (espaço), o retorno será `nil`. 

O método de validar se é um CEP válido ou não, apenas certifica-se de que o CEP informado possui `8` dígitos e que todos sejam numéricos, podendo ser acessado antes de consultar o webservice por meio da interface `IViaCEP`, utilizando o método `Validate`.

Quando consultado um CEP de formato válido, porém inexistente, por exemplo: `99999999`, o retorno também será `nil`. Isso significa que o CEP consultado não foi encontrado na base de dados.

Exemplo:
```pascal
var
  ViaCEP: IViaCEP;
begin
  ViaCEP := TViaCEP.Create;
  if ViaCEP.Validate('01001000') then
    ShowMessage('CEP válido')
  else
    ShowMessage('CEP inválido');
end;
```

Vale lembrar que no método acima, não é necessário destruir a instância criada da classe `TViaCEP`, pelo fato de estar utilizando uma `Interface`.


### Consultando um CEP
```pascal
var
  ViaCEP: IViaCEP;
  CEP: TViaCEPClass;
begin
  ViaCEP := TViaCEP.Create;
  // Aqui você pode chamar a rotina para validar se é um CEP válido.
  CEP := ViaCEP.Get(edtCEPConsultar.Text);
  if not Assigned(CEP) then
    Exit; // Aqui você pode exibir uma mensagem para o usuário falando que o CEP não foi encontrado.
  try
    edtJSON.Lines.Text := CEP.ToJSONString;
    edtCEP.Text := CEP.CEP;
    edtLogradouro.Text := CEP.Logradouro;
    edtComplemento.Text := CEP.Complemento;
    edtBairro.Text := CEP.Bairro;
    edtLocalidade.Text := CEP.Localidade;
    edtUF.Text := CEP.UF;
    edtDDD.Text := CEP.DDD;
    edtIBGE.Text := CEP.IBGE;
    edtGIA.Text := CEP.GIA;
  finally
    CEP.Free;
  end;
end;
```


### Retorno da consulta no formato JSON
Após realizar a consulta do CEP, você pode pegar o conteúdo retornado no formato JSON utilizando a método **.ToJSONString** disponível na classe `TViaCEPClass`. Veja o exemplo abaixo, onde é populado um `TMemo` com o conteúdo da consulta:
```pascal
var
  CEP: TViaCEPClass;
begin
  Memo.Lines.Text := CEP.ToJSONString;
end;
```  
```
{
  "cep": "01001-000",
  "logradouro": "Praça da Sé",
  "complemento": "lado ímpar",
  "bairro": "Sé",
  "localidade": "São Paulo",
  "uf": "SP",
  "ddd": "",
  "ibge": "3550308",
  "gia": "1004"
}
```


### Retorno da consulta no formato XML
Após realizar a consulta do CEP, você pode pegar o conteúdo retornado no formato XML utilizando a método **.ToXMLString** disponível na classe `TViaCEPClass`. Veja o exemplo abaixo, onde é populado um `TMemo` com o conteúdo da consulta:
```pascal
var
  CEP: TViaCEPClass;
begin
  Memo.Lines.Text := CEP.ToXMLString;
end;
```  
```
<?xml version="1.0"?>
<xmlcep>
    <cep>15800-010</cep>
    <logradouro>Rua Treze de Maio</logradouro>
   <complemento></complemento>
   <bairro>Centro</bairro>
   <localidade>Catanduva</localidade>
    <UF>SP</UF>
   <ibge>3511102</ibge>
   <gia>2604</gia>
   <ddd>17</ddd>
</xmlcep>
```


### Consultando um Endereço

Para consultar um endereço é necessário informar **UF**, **Endereço** e **Logradouro** com valores válidos, por exemplo: 
**UF** (2 dígitos), **Cidade** (maior que 3 dígitos) e **Logradouro** (maior que 3 dígitos).

Vale lembrar que a consulta por endereço pode retornar mais de um registro, por exemplo: 
UF='SP', Cidade='CATANDUVA' e Logradouro='PARA'. 

Nesses casos, será exibida uma grade com todos os registros encontrados.


### Informações gerais

É possível efetuar consultas tanto por **CEP** quanto por **Endereço**.

O retorno pode ser obtido no formatado **Json** ou **Xml**, basta informar ao efetuar uma consulta.

Após efetuar uma consulta todos os registros retornados são armazenados no banco de dados **Dados.fdb**.

Na aba **Armazenados** é possível consultar os registros já armazenados no banco de dados e navegar entre eles.

Ao efetuar uma consulta, caso o endereço já tenha sido armazenado no banco de dados é possível visualizá-lo ou até mesmo atualizá-lo após uma nova consulta.


## Links úteis
Origem código IBGE dos municípios: [**Acessar Site**](https://cidades.ibge.gov.br/) 

Origem código GIA/ICMS (apenas SP disponível): [**Visualizar PDF (Pág.137)**](https://portal.fazenda.sp.gov.br/servicos/gia/Downloads/pre_formatado_ngia_v0210_gia0801.pdf)

ViaCEP - Webservice CEP e IBGE gratuito: [**Acessar Site**](https://viacep.com.br/) 


![ServerViaCEP](img/Screenshot_1.png) 
