unit FirebirdDataManager;

interface

uses
  System.SysUtils,
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
  FireDAC.Comp.Client;

type
  TFirebirdDataManager = class
  private
    FConnection: TFDConnection;
    FQuery: TFDQuery;
  public
    constructor Create(const Connection: TFDConnection);
    destructor Destroy; override;
    procedure ExecuteQuery(const SQL: string);
    function IsEmpty: Boolean;
    function GetFieldValue(const FieldName: string): integer;
    procedure ApplyUpdates;
  end;

implementation

constructor TFirebirdDataManager.Create(const Connection: TFDConnection);
begin
  FConnection := Connection;
  FQuery := TFDQuery.Create(nil);
  FQuery.Connection := FConnection;
end;

destructor TFirebirdDataManager.Destroy;
begin
  FQuery.Free;
  inherited;
end;

procedure TFirebirdDataManager.ExecuteQuery(const SQL: string);
begin
  FQuery.Close;
  FQuery.SQL.Clear;
  FQuery.SQL.Add(SQL);
  FQuery.Open;
end;

function TFirebirdDataManager.IsEmpty: Boolean;
begin
  Result := FQuery.IsEmpty;
end;

function TFirebirdDataManager.GetFieldValue(const FieldName: string): integer;
begin
  Result := FQuery.FieldByName(FieldName).asinteger;
end;

procedure TFirebirdDataManager.ApplyUpdates;
begin
  FQuery.ApplyUpdates;
  FConnection.Commit;
end;

end.
