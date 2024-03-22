unit ViaCEP.Connection;

interface

uses
  System.SysUtils, FireDAC.Comp.Client, FireDAC.Phys.FB, FireDAC.Stan.Def;

type
  TFirebirdConnection = class
  private
    FConnection: TFDConnection;
  public
    constructor Create(const Server, Database, UserName, Password: string);
    destructor Destroy; override;
    procedure Connect;
    procedure Disconnect;
    property Connection: TFDConnection read FConnection;
  end;

implementation

constructor TFirebirdConnection.Create(const Server, Database, UserName,
  Password: string);
begin
  FConnection := TFDConnection.Create(nil);
  FConnection.Params.Clear;
  FConnection.Params.Add('DriverID=FB');
  FConnection.Params.Add('Server=' + Server);
  FConnection.Params.Add('Database=' + Database);
  FConnection.Params.Add('User_Name=' + UserName);
  FConnection.Params.Add('Password=' + Password);
end;

destructor TFirebirdConnection.Destroy;
begin
  FConnection.Free;
  inherited;
end;

procedure TFirebirdConnection.Connect;
begin
  try
    FConnection.Connected := True;
    ShowMessage('Conexão estabelecida com sucesso!');
  except
    on E: Exception do
      ShowMessage('Erro ao conectar ao banco de dados: ' + E.Message);
  end;
end;

procedure TFirebirdConnection.Disconnect;
begin
  FConnection.Connected := False;
end;

end.
