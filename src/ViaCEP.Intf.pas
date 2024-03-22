unit ViaCEP.Intf;

interface

uses
  ViaCEP.Model, ViaCEP.Itens, Pkg.Json.DTO, FireDAC.Comp.Client;

type
  IViaCEP = interface
    ['{202D4AB9-6B89-4CFF-A080-9DBC09D66737}']
    // Consuma a API do viacep.com.br para obter os dados referentes a um determinado CEP.
    function GetJSON(const ACep: string): TViaCEPClass;
    function GetXml(const ACep: string): TViaCEPClass;
    function GetLogradouroJSON(const ACep: string): TFDMemTable;
    function GetLogradouroXML(const ACep: string): TFDMemTable;

    function Validate(const ACep: string): Boolean;
  end;

implementation

end.
