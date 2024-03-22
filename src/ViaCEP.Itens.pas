unit ViaCEP.Itens;

interface

uses
  Pkg.Json.DTO,
  System.Generics.Collections,
  REST.Json.Types;

{$M+}

type
  TItemsDTO = class
  private
    [JSONName('bairro')]
    FBairro: string;
    [JSONName('cep')]
    FCep: string;
    [JSONName('complemento')]
    FComplemento: string;
    [JSONName('ddd')]
    FDdd: string;
    [JSONName('gia')]
    FGia: string;
    [JSONName('ibge')]
    FIbge: string;
    [JSONName('localidade')]
    FLocalidade: string;
    [JSONName('logradouro')]
    FLogradouro: string;
    [JSONName('siafi')]
    FSiafi: string;
    [JSONName('uf')]
    FUf: string;
  published
    property Bairro: string read FBairro write FBairro;
    property Cep: string read FCep write FCep;
    property Complemento: string read FComplemento write FComplemento;
    property Ddd: string read FDdd write FDdd;
    property Gia: string read FGia write FGia;
    property Ibge: string read FIbge write FIbge;
    property Localidade: string read FLocalidade write FLocalidade;
    property Logradouro: string read FLogradouro write FLogradouro;
    property Siafi: string read FSiafi write FSiafi;
    property Uf: string read FUf write FUf;
  end;

  TViaCEPRootDTO = class(TJsonDTO)
  private
    [JSONName('Items'), JSONMarshalled(False)]
    FItemsArray: TArray<TItemsDTO>;
    [GenericListReflect]
    FItems: TObjectList<TItemsDTO>;
    function GetItems: TObjectList<TItemsDTO>;
  protected
    function GetAsJson: string; override;
  published
    property Items: TObjectList<TItemsDTO> read GetItems;
  public
    destructor Destroy; override;
  end;

implementation

{ TViaCEPRootDTO }

destructor TViaCEPRootDTO.Destroy;
begin
  GetItems.Free;
  inherited;
end;

function TViaCEPRootDTO.GetItems: TObjectList<TItemsDTO>;
begin
  Result := ObjectList<TItemsDTO>(FItems, FItemsArray);
end;

function TViaCEPRootDTO.GetAsJson: string;
begin
  RefreshArray<TItemsDTO>(FItems, FItemsArray);
  Result := inherited;
end;

end.

