unit ViaCEP.Core;

interface

uses
  IdHTTP,
  IdSSLOpenSSL,
  ViaCEP.Intf,
  ViaCEP.Model,
  Xml.xmldom,
  Xml.XMLIntf,
  Xml.XMLDoc,
  System.Json,
  Data.DB,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.Stan.ExprFuncs,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.Phys.FB,
  FireDAC.Phys.FBDef,
  FireDAC.Stan.Param,
  FireDAC.DatS,
  FireDAC.DApt.Intf,
  FireDAC.DApt,
  FireDAC.VCLUI.Error,
  FireDAC.VCLUI.Wait,
  FireDAC.Phys.IBWrapper,
  FireDAC.Comp.ScriptCommands,
  FireDAC.Stan.Util,
  FireDAC.Comp.Script,
  FireDAC.Moni.Base,
  FireDAC.Moni.FlatFile,
  FireDAC.Phys.IBBase,
  FireDAC.Comp.UI,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,

  ViaCEP.Itens;

type
  TViaCEP = class(TInterfacedObject, IViaCEP)

  private
    FIdHTTP: TIdHTTP;
    FIdSSLIOHandlerSocketOpenSSL: TIdSSLIOHandlerSocketOpenSSL;
    FMsg: string;

    function GetJSON(const ACep: string): TViaCEPClass;
    function GetXML(const ACep: string): TViaCEPClass;
    function GetLogradouroJSON(const ACep: string): TFDMemTable;
    function GetLogradouroXML(const ACep: string): TFDMemTable;
    function Validate(const ACep: string): Boolean;

    procedure CriarDataSetLogradouros(var aDataSet: TFDMemTable);
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

function TViaCEP.GetJSON(const ACep: string): TViaCEPClass;
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

function TViaCEP.GetXML(const ACep: string): TViaCEPClass;
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

function TViaCEP.GetLogradouroJSON(const ACep: string): TFDMemTable;
const
  URL = 'https://viacep.com.br/ws/%s/json';
  INVALID_CEP = '{'#$A'  "erro": true'#$A'}';
var
  LResponse: TStringStream;
  LJson: string;
  LJSONObject: TJSONObject;
  LViaCEPRoot: TViaCEPRootDTO;
  I, FIdSeq: integer;
  LocalArq: string;
  LArqStr: TstringList;
begin
  Result := nil;
  CriarDataSetLogradouros(Result);
  LResponse := TStringStream.Create;

  try
    FIdHTTP.Get(Format(URL, [ACep.Trim]), LResponse);

    if (FIdHTTP.ResponseCode = 200) and
      (not(LResponse.DataString).Equals(INVALID_CEP)) then
    begin
      LJson := UTF8ToString(PAnsiChar(AnsiString(LResponse.DataString)));
      LJson := StringReplace(LJson, #10, ' ', [rfReplaceAll, rfIgnoreCase]);

      LocalArq := ExtractFilePath(ParamStr(0)) + 'LogradouroJSON.txt';
      if (FileExists(LocalArq)) then
        DeleteFile(LocalArq);

      try
        LArqStr := TstringList.Create;
        LArqStr.Text := LJson;
        LArqStr.SaveToFile(LocalArq);
      finally
        LArqStr.Free;
      end;

      LJSONObject := TJSONObject(TJSONObject.ParseJSONValue(Trim(LJson)));
      if (LJSONObject <> nil) then
      begin
        LViaCEPRoot := TViaCEPRootDTO.Create;
        LViaCEPRoot.AsJson := LJSONObject.ToJSON;

        if (Assigned(LViaCEPRoot)) and (LViaCEPRoot.Items.Count > 0) then
        begin
          FIdSeq := 0;
          for I := 0 to LViaCEPRoot.Items.Count - 1 do
          begin
            Inc(FIdSeq, 1);
            Result.Append;
            Result.FieldByName('ID_SEQ').AsInteger := FIdSeq;
            Result.FieldByName('Bairro').AsString := LViaCEPRoot.Items
              [I].Bairro;
            Result.FieldByName('Cep').AsString := LViaCEPRoot.Items[I].CEP;
            Result.FieldByName('Complemento').AsString := LViaCEPRoot.Items[I]
              .Complemento;
            Result.FieldByName('Ddd').AsString := LViaCEPRoot.Items[I].DDD;
            Result.FieldByName('Gia').AsString := LViaCEPRoot.Items[I].GIA;
            Result.FieldByName('Ibge').AsString := LViaCEPRoot.Items[I].IBGE;
            Result.FieldByName('Localidade').AsString := LViaCEPRoot.Items[I]
              .Localidade;
            Result.FieldByName('Logradouro').AsString := LViaCEPRoot.Items[I]
              .Logradouro;
            Result.FieldByName('Siafi').AsString := LViaCEPRoot.Items[I].Siafi;
            Result.FieldByName('Uf').AsString := LViaCEPRoot.Items[I].UF;
            Result.Post;
          end;
        end;
      end;
    end;
  finally
    LResponse.Free;
    LJSONObject.Free;
    if (Assigned(LViaCEPRoot)) then
      FreeAndNil(LViaCEPRoot);
  end;
end;

function TViaCEP.GetLogradouroXML(const ACep: string): TFDMemTable;
const
  URL = 'https://viacep.com.br/ws/%s/xml';
  INVALID_CEP = '{'#$A'  "erro": true'#$A'}';
var
  LResponse: TStringStream;
  XMLDoc: IXMLDocument;
  NodeEnderecos, NodeEnd: IXMLNode;
  FIdSeq, I: integer;
begin
  Result := nil;
  CriarDataSetLogradouros(Result);
  LResponse := TStringStream.Create;

  try
    // Realiza a requisição HTTP para obter o XML
    FIdHTTP.Get(Format(URL, [ACep.Trim]), LResponse);

    // Verifica se a resposta é válida
    if (FIdHTTP.ResponseCode = 200) and
      (not(LResponse.DataString).Equals(INVALID_CEP)) then
    begin
      try
        XMLDoc := TXMLDocument.Create(nil); // Não precisa destruir o compomente
        XMLDoc.Active := False;
        XMLDoc.Xml.Add(LResponse.DataString);
        XMLDoc.Active := True;
        XMLDoc.SaveToFile(ExtractFilePath(ParamStr(0)) + 'LogradouroXML.txt');
      except
        on E: Exception do
        begin
          if Pos('ERRO AO', AnsiUpperCase(E.Message)) = 0 then
            FMsg := 'Erro ao executar o comando ' + Self.ClassName +
              '.LerRetorno-Carregar XML:' + #13#10 + E.Message
          else
            FMsg := E.Message;
          raise Exception.Create(FMsg);
        end;
      end;

      FIdSeq := 0;
      if (XMLDoc.ChildNodes.FindNode('xmlcep') <> nil) then
      begin
        if (XMLDoc.ChildNodes.FindNode('xmlcep').ChildNodes.FindNode
          ('enderecos') <> nil) then
        begin
          NodeEnderecos := XMLDoc.ChildNodes.FindNode('xmlcep')
            .ChildNodes.FindNode('enderecos');

          for I := 0 to NodeEnderecos.ChildNodes.Count - 1 do
          begin
            if (NodeEnderecos.ChildNodes[I].NodeName = 'endereco') then
            begin
              NodeEnd := NodeEnderecos.ChildNodes[I];
              if (NodeEnd <> nil) then
              begin
                Inc(FIdSeq, 1);
                Result.Append;
                Result.FieldByName('ID_SEQ').AsInteger := FIdSeq;
                if (NodeEnd.ChildNodes.FindNode('bairro') <> nil) then
                  Result.FieldByName('Bairro').AsString :=
                    NodeEnd.ChildNodes.FindNode('bairro').Text;
                if (NodeEnd.ChildNodes.FindNode('cep') <> nil) then
                  Result.FieldByName('Cep').AsString :=
                    NodeEnd.ChildNodes.FindNode('cep').Text;
                if (NodeEnd.ChildNodes.FindNode('complemento') <> nil) then
                  Result.FieldByName('Complemento').AsString :=
                    NodeEnd.ChildNodes.FindNode('complemento').Text;
                if (NodeEnd.ChildNodes.FindNode('ddd') <> nil) then
                  Result.FieldByName('Ddd').AsString :=
                    NodeEnd.ChildNodes.FindNode('ddd').Text;
                if (NodeEnd.ChildNodes.FindNode('gia') <> nil) then
                  Result.FieldByName('Gia').AsString :=
                    NodeEnd.ChildNodes.FindNode('gia').Text;
                if (NodeEnd.ChildNodes.FindNode('ibge') <> nil) then
                  Result.FieldByName('Ibge').AsString :=
                    NodeEnd.ChildNodes.FindNode('ibge').Text;
                if (NodeEnd.ChildNodes.FindNode('localidade') <> nil) then
                  Result.FieldByName('Localidade').AsString :=
                    NodeEnd.ChildNodes.FindNode('localidade').Text;
                if (NodeEnd.ChildNodes.FindNode('logradouro') <> nil) then
                  Result.FieldByName('Logradouro').AsString :=
                    NodeEnd.ChildNodes.FindNode('logradouro').Text;
                if (NodeEnd.ChildNodes.FindNode('siafi') <> nil) then
                  Result.FieldByName('Siafi').AsString :=
                    NodeEnd.ChildNodes.FindNode('siafi').Text;
                if (NodeEnd.ChildNodes.FindNode('uf') <> nil) then
                  Result.FieldByName('Uf').AsString :=
                    NodeEnd.ChildNodes.FindNode('uf').Text;
                Result.Post;
              end;
            end;
          end;
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

procedure TViaCEP.CriarDataSetLogradouros(var aDataSet: TFDMemTable);
begin
  try
    try
      if not Assigned(aDataSet) then
        aDataSet := TFDMemTable.Create(nil)
      else
      begin
        FreeAndNil(aDataSet);
        aDataSet := TFDMemTable.Create(nil);
      end;
      aDataSet.FieldDefs.Clear;
      aDataSet.FieldDefs.Add('ID_SEQ', ftInteger);
      aDataSet.FieldDefs.Add('Cep', ftString, 20);
      aDataSet.FieldDefs.Add('Logradouro', ftString, 80);
      aDataSet.FieldDefs.Add('Complemento', ftString, 40);
      aDataSet.FieldDefs.Add('Bairro', ftString, 60);
      aDataSet.FieldDefs.Add('Localidade', ftString, 60);
      aDataSet.FieldDefs.Add('Uf', ftString, 5);
      aDataSet.FieldDefs.Add('Ddd', ftString, 10);
      aDataSet.FieldDefs.Add('Gia', ftString, 10);
      aDataSet.FieldDefs.Add('Ibge', ftString, 10);
      aDataSet.FieldDefs.Add('Siafi', ftString, 10);
      aDataSet.CreateDataSet;

      aDataSet.FieldByName('ID_SEQ').DisplayLabel := 'ID';
    except
      on E: Exception do
      begin
        if Pos('ERRO AO', AnsiUpperCase(E.Message)) = 0 then
          FMsg := 'Erro ao executar o comando ' + Self.ClassName +
            '.CriarDataSetRetorno:' + #13#10 + E.Message
        else
          FMsg := E.Message;
        raise Exception.Create(FMsg);
      end;
    end;
  finally
  end;
end;

destructor TViaCEP.Destroy;
begin
  FIdSSLIOHandlerSocketOpenSSL.Free;
  FIdHTTP.Free;
  inherited;
end;

end.
