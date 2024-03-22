unit ViaCEP.Model;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Json,
  System.Rtti,
  Xml.xmldom,
  Xml.XMLIntf,
  Xml.XMLDoc,
  REST.Json.Types;

type
  /// <summary>
  /// Class representing the data returned by the ViaCEP API.
  /// </summary>
  TViaCEPClass = class
  private
    FLogradouro: string;
    [JSONNameAttribute('ibge')]
    FIBGE: string;
    FBairro: string;
    [JSONNameAttribute('uf')]
    FUF: string;
    [JSONNameAttribute('cep')]
    FCEP: string;
    FLocalidade: string;
    FComplemento: string;
    [JSONNameAttribute('gia')]
    FGIA: string;
    [JSONNameAttribute('ddd')]
    FDDD: string;
    procedure SetBairro(const Value: string);
    procedure SetCEP(const Value: string);
    procedure SetComplemento(const Value: string);
    procedure SetGIA(const Value: string);
    procedure SetIBGE(const Value: string);
    procedure SetLocalidade(const Value: string);
    procedure SetLogradouro(const Value: string);
    procedure SetUF(const Value: string);
    procedure SetDDD(const Value: string);
  public
    property CEP: string read FCEP write SetCEP;
    property Logradouro: string read FLogradouro write SetLogradouro;
    property Complemento: string read FComplemento write SetComplemento;
    property Bairro: string read FBairro write SetBairro;
    property Localidade: string read FLocalidade write SetLocalidade;
    property UF: string read FUF write SetUF;
    property IBGE: string read FIBGE write SetIBGE;
    property GIA: string read FGIA write SetGIA;
    property DDD: string read FDDD write SetDDD;
    /// <summary>
    /// Converts the current instance of the TCEPClass class to a JSON in the string format.
    /// </summary>
    /// <returns>
    /// Returns a JSONObject in string format.
    /// </returns>
    function ToJSONString: string;
    function ToXMLString: string;
    /// <summary>
    /// Instance an object of class TCEPClass with the data of a JSON in the string format.
    /// </summary>
    /// <param name="AJSONString">
    /// JSON containing the data of class TCEPClass in the string format.
    /// </param>
    /// <returns>
    /// Returns an instance of the TCEPClass class.
    /// </returns>
    class function FromJSONString(const AJSONString: string): TViaCEPClass;
    class function FromXMLString(const XMLString: string): TViaCEPClass;
  end;

implementation

uses REST.Json;

{ TViaCEPClass }

class function TViaCEPClass.FromJSONString(const AJSONString: string)
  : TViaCEPClass;
begin
  Result := TJson.JsonToObject<TViaCEPClass>(AJSONString);
end;

class function TViaCEPClass.FromXMLString(const XMLString: string)
  : TViaCEPClass;
var
  XMLDoc: TXmlDocument;
  RootNode: IXMLNode;
  Context: TRttiContext;
  Prop: TRttiProperty;
  XMLValue: string;
begin
  Result := TViaCEPClass.Create;
  XMLDoc := TXmlDocument.Create(nil);

  try
    XMLDoc.LoadFromXML(XMLString);
    RootNode := XMLDoc.DocumentElement;

    // Itera sobre as propriedades da classe
    Context := TRttiContext.Create;
    try
      for Prop in Context.GetType(TViaCEPClass).GetProperties do
      begin
        XMLValue := RootNode.ChildValues[Prop.Name];
        if XMLValue <> '' then
          Prop.SetValue(Result, XMLValue);
      end;
    finally
      Context.Free;
    end;
  finally
    XMLDoc.Free;
  end;
end;

procedure TViaCEPClass.SetBairro(const Value: string);
begin
  FBairro := Value;
end;

procedure TViaCEPClass.SetCEP(const Value: string);
begin
  FCEP := Value;
end;

procedure TViaCEPClass.SetComplemento(const Value: string);
begin
  FComplemento := Value;
end;

procedure TViaCEPClass.SetDDD(const Value: string);
begin
  FDDD := Value;
end;

procedure TViaCEPClass.SetGIA(const Value: string);
begin
  FGIA := Value;
end;

procedure TViaCEPClass.SetIBGE(const Value: string);
begin
  FIBGE := Value;
end;

procedure TViaCEPClass.SetLocalidade(const Value: string);
begin
  FLocalidade := Value;
end;

procedure TViaCEPClass.SetLogradouro(const Value: string);
begin
  FLogradouro := Value;
end;

procedure TViaCEPClass.SetUF(const Value: string);
begin
  FUF := Value;
end;

function TViaCEPClass.ToJSONString: string;
begin
  Result := TJson.ObjectToJsonString(Self, [joIgnoreEmptyStrings]);
end;

function TViaCEPClass.ToXMLString: string;
begin
  Result := '<?xml version="1.0"?>' + #13 + '<xmlcep>' + #13 + '    <cep>' + CEP
    + '</cep>' + #13 + '    <logradouro>' + Logradouro + '</logradouro>' + #13 +
    '   <complemento>' + Complemento + '</complemento>' + #13 + '   <bairro>' +
    Bairro + '</bairro>' + #13 + '   <localidade>' + Localidade +
    '</localidade>' + #13 + '    <UF>' + UF + '</UF>' + #13 + '   <ibge>' + IBGE
    + '</ibge>' + #13 + '   <gia>' + GIA + '</gia>' + #13 + '   <ddd>' + DDD +
    '</ddd>' + #13 + '</xmlcep>';
end;

end.
