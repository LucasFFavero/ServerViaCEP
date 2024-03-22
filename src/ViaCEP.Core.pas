unit ViaCEP.Core;

interface

uses
  IdHTTP,
  IdSSLOpenSSL,
  ViaCEP.Intf,
  ViaCEP.Model,
  Xml.xmldom,
  Xml.XMLIntf,
  Xml.XMLDoc;

type
  TViaCEP = class(TInterfacedObject, IViaCEP)

  private
    FIdHTTP: TIdHTTP;
    FIdSSLIOHandlerSocketOpenSSL: TIdSSLIOHandlerSocketOpenSSL;
    /// <summary>
    /// Consuma a API do viacep.com.br para obter os dados referentes a um determinado CEP.
    /// </summary>
    /// <param name="ACep">
    /// Refers to the CEP that will be consulted.
    /// </param>
    /// <returns>
    /// Returns an instance of the TCEPClass class.
    /// </returns>
    function Get(const ACep: string): TViaCEPClass;
    function GetxML(const ACep: string): TViaCEPClass;
    /// <summary>
    /// Checks if CEP is valid.
    /// </summary>
    /// <param name="ACep">
    /// Refers to the CEP that will be consulted.
    /// </param>
    /// <returns>
    /// Returns True if successful.
    /// </returns>
    function Validate(const ACep: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TViaCEP }

uses System.Classes, REST.Json, System.SysUtils;

constructor TViaCEP.Create;
begin
  FIdHTTP := TIdHTTP.Create;
  FIdSSLIOHandlerSocketOpenSSL := TIdSSLIOHandlerSocketOpenSSL.Create;
  FIdHTTP.IOHandler := FIdSSLIOHandlerSocketOpenSSL;
  FIdSSLIOHandlerSocketOpenSSL.SSLOptions.SSLVersions :=
    [sslvTLSv1, sslvTLSv1_1, sslvTLSv1_2];
end;

function TViaCEP.Get(const ACep: string): TViaCEPClass;
const
  URL = 'https://viacep.com.br/ws/%s/json';
  INVALID_CEP = '{'#$A'  "erro": true'#$A'}';
var
  LResponse: TStringStream;
begin
  Result := nil;
  LResponse := TStringStream.Create;

  try
    FIdHTTP.Get(Format(URL, [ACep.Trim]), LResponse);

    if (FIdHTTP.ResponseCode = 200) and
      (not(LResponse.DataString).Equals(INVALID_CEP)) then
      Result := TJson.JsonToObject<TViaCEPClass>
        (UTF8ToString(PAnsiChar(AnsiString(LResponse.DataString))));
  finally
    LResponse.Free;
  end;
end;

function TViaCEP.GetxML(const ACep: string): TViaCEPClass;
const
  URL = 'https://viacep.com.br/ws/%s/xml';
  INVALID_CEP = '{'#$A'  "erro": true'#$A'}';
var
  LResponse: TStringStream;
  XMLDoc: IXMLDocument;
  Node: IXMLNode;
begin
  Result := nil;
  LResponse := TStringStream.Create;
  XMLDoc := TXMLDocument.Create(nil);

  try
    // Realiza a requisição HTTP para obter o XML
    FIdHTTP.Get(Format(URL, [ACep.Trim]), LResponse);

    // Carrega o XML da resposta da requisição
    XMLDoc.LoadFromXML(LResponse.DataString);
    // XMLDoc.Savetofile('C:\Desenvolvimento\Projetos\ServerCEP\Endereco.xml');
    // XMLDoc.Savetofile('C:\Desenvolvimento\Projetos\ServerCEP\CEP.xml');

    // Verifica se a resposta é válida
    if (FIdHTTP.ResponseCode = 200) and
      (not(LResponse.DataString).Equals(INVALID_CEP)) then
    begin
      // Obtém o nó raiz do XML
      Node := XMLDoc.DocumentElement;

      // Cria uma instância de TViaCEPClass e preenche os dados com base no XML
      Result := TViaCEPClass.Create;

      if Node.HasChildNodes then
      begin
        // Iterar pelos nós filhos para encontrar os dados desejados
        Node := Node.ChildNodes.First;

        while Assigned(Node) do
        begin
          if Node.NodeName = 'cep' then
            Result.CEP := Node.Text
          else if Node.NodeName = 'logradouro' then
            Result.Logradouro := Node.Text
          else if Node.NodeName = 'complemento' then
            Result.Complemento := Node.Text
          else if Node.NodeName = 'bairro' then
            Result.Bairro := Node.Text
          else if Node.NodeName = 'localidade' then
            Result.Localidade := Node.Text
          else if Node.NodeName = 'uf' then
            Result.UF := Node.Text
          else if Node.NodeName = 'ibge' then
            Result.IBGE := Node.Text
          else if Node.NodeName = 'gia' then
            Result.GIA := Node.Text
          else if Node.NodeName = 'ddd' then
            Result.DDD := Node.Text;

          Node := Node.NextSibling;
        end;
      end;
    end;
  finally
    LResponse.Free;
  end;
end;

function TViaCEP.Validate(const ACep: string): Boolean;
const
  INVALID_CHARACTER = -1;
begin
  Result := True;

  if ACep.Trim.Length <> 8 then
    Exit(False);
  if StrToIntDef(ACep, INVALID_CHARACTER) = INVALID_CHARACTER then
    Exit(False);
end;

destructor TViaCEP.Destroy;
begin
  FIdSSLIOHandlerSocketOpenSSL.Free;
  FIdHTTP.Free;
  inherited;
end;

end.
