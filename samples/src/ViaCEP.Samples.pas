unit ViaCEP.Samples;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  dxGDIPlusClasses,
  Vcl.ExtCtrls,
  FirebirdConnection,
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
  FirebirdDataManager,
  Data.DB,
  Vcl.Grids,
  Vcl.DBGrids,
  Vcl.ComCtrls, Xml.xmldom, Xml.XMLIntf, Xml.XMLDoc;

type
  TFrmMain = class(TForm)
    Panel1: TPanel;
    Image1: TImage;
    pgcViaCEP: TPageControl;
    tbsConsultar: TTabSheet;
    tbsArmazenados: TTabSheet;
    pnlConsultar: TPanel;
    GroupBox1: TGroupBox;
    edtCEPValidate: TEdit;
    btnValidar: TButton;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lblTipo: TLabel;
    edtCEPConsultar: TEdit;
    btnConsultar: TButton;
    edtCEP: TEdit;
    edtLogradouro: TEdit;
    edtComplemento: TEdit;
    edtBairro: TEdit;
    edtLocalidade: TEdit;
    edtUF: TEdit;
    edtDDD: TEdit;
    edtIBGE: TEdit;
    edtGIA: TEdit;
    edtJSON_Xml: TMemo;
    edtEnderecoConsultar: TEdit;
    rbJson: TRadioButton;
    rbXml: TRadioButton;
    pnlArmazenadosTop: TPanel;
    btnBuscar: TButton;
    pnlArmazenados: TPanel;
    dbgArmazenados: TDBGrid;
    dtsArmazenados: TDataSource;
    Panel2: TPanel;
    rbCEP: TRadioButton;
    rbEndereco: TRadioButton;
    edtUFConsultar: TEdit;
    edtCidadeConsultar: TEdit;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnValidarClick(Sender: TObject);
    procedure btnConsultarClick(Sender: TObject);
    procedure rbJsonClick(Sender: TObject);
    procedure rbXmlClick(Sender: TObject);
    procedure TipoRetorno;
    procedure TipoConsulta;
    procedure EfetuarConsulta;
    procedure InserirRegistro;
    procedure VisualizarEnderecoArmazenado(Codigo: Integer);
    procedure AtualizarRegistro(Codigo: Integer);
    procedure FormShow(Sender: TObject);
    procedure btnBuscarClick(Sender: TObject);
    procedure rbCEPClick(Sender: TObject);
    procedure rbEnderecoClick(Sender: TObject);
    procedure dbgArmazenadosDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
  private
    FMemCeps: TFDMemTable;
  public
    FirebirdConn: TFirebirdConnection;

  end;

var
  FrmMain: TFrmMain;

implementation

uses ViaCEP.Intf, ViaCEP.Core, ViaCEP.Model;

{$R *.dfm}

function RemoverMascaraCEP(const CEP: string): string;
var
  I: Integer;
begin
  Result := '';

  for I := 1 to Length(CEP) do
  begin
    if CEP[I] in ['0' .. '9'] then
      Result := Result + CEP[I];
  end;
end;

procedure TFrmMain.btnValidarClick(Sender: TObject);
var
  ViaCEP: IViaCEP;
begin
  ViaCEP := TViaCEP.Create;

  if ViaCEP.Validate(edtCEPValidate.Text) then
    ShowMessage('CEP válido.')
  else
    ShowMessage('CEP inválido.');
end;

procedure TFrmMain.dbgArmazenadosDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  if gdSelected in State then
  begin
    with dbgArmazenados.Canvas do
    begin
      Brush.Color := $002CAE00;
      FillRect(Rect);
      Font.Style := [fsBold]
    end;
  end;
  dbgArmazenados.DefaultDrawDataCell(Rect, dbgArmazenados.columns[DataCol]
    .Field, State);
end;

procedure TFrmMain.btnBuscarClick(Sender: TObject);
var
  FDQuery: TFDQuery;
begin
  if (not Assigned(FMemCeps)) then
    FMemCeps := TFDMemTable.Create(nil);

  dbgArmazenados.DataSource := nil;
  dtsArmazenados.DataSet := nil;

  FDQuery := TFDQuery.Create(nil);
  try
    FDQuery.Connection := FirebirdConn.FConnection;

    FDQuery.SQL.Text := 'SELECT * FROM VIACEP';
    FDQuery.Open;

    FMemCeps.CopyDataSet(FDQuery, [coStructure, coRestart, coAppend]);

    if (Assigned(FMemCeps)) then
    begin
      FMemCeps.First;
      dtsArmazenados.DataSet := FMemCeps;
      dbgArmazenados.DataSource := dtsArmazenados;
    end;

  finally
    FDQuery.Free;
  end;
end;

procedure TFrmMain.EfetuarConsulta;
var
  ViaCEP: IViaCEP;
  CEP: TViaCEPClass;
  strConsultar: String;
begin
  ViaCEP := TViaCEP.Create;

  // Tipo da Consulta
  if rbCEP.Checked then
    strConsultar := edtCEPConsultar.Text
  else
    strConsultar := edtUFConsultar.Text + '/' + edtCidadeConsultar.Text + '/' +
      edtEnderecoConsultar.Text;

  // Tipo retorno
  if (rbJson.Checked) then
    CEP := ViaCEP.Get(strConsultar)
  else
    CEP := ViaCEP.GetXml(strConsultar);

  if not Assigned(CEP) then
  begin
    ShowMessage('Endereço não localizado.');
    Exit;
  end;

  try
    if (rbJson.Checked) then
      edtJSON_Xml.Lines.Text := CEP.ToJSONString
    else
      edtJSON_Xml.Lines.Text := CEP.ToXMLString;

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

procedure TFrmMain.btnConsultarClick(Sender: TObject);
var
  DataManager: TFirebirdDataManager;
  FDQuery: TFDQuery;
begin
  if rbCEP.Checked and (edtCEPConsultar.Text = '') then
  begin
    ShowMessage('Informe um CEP para consultar.');
    Exit;
  end;

  if rbEndereco.Checked then
  begin
    if (Length(edtUFConsultar.Text) <> 2) or
      (Length(edtCidadeConsultar.Text) <= 3) or
      (Length(edtEnderecoConsultar.Text) <= 3) then
    begin
      ShowMessage('Informe um Endereço válido para consultar.');
      Exit;
    end;
  end;

  try
    DataManager := TFirebirdDataManager.Create(FirebirdConn.Connection);
    DataManager.ExecuteQuery
      ('SELECT VIACEP.CODIGO FROM VIACEP WHERE VIACEP.CEP = ' +
      quotedstr(RemoverMascaraCEP(edtCEPConsultar.Text)));

    if not DataManager.IsEmpty then
    begin
      if MessageDlg('Endereço já armazenado.' + #13 +
        'Deseja visualizar os dados do endereço armazenado?', mtConfirmation,
        mbYesNo, 0) = mrYes then
      begin
        VisualizarEnderecoArmazenado(DataManager.GetFieldValue('CODIGO'));
        Exit;
      end
      else
      begin
        if MessageDlg('Efetuar nova consulta e atualizar as informações?',
          mtConfirmation, mbYesNo, 0) = mrYes then
        begin
          EfetuarConsulta;

          AtualizarRegistro(DataManager.GetFieldValue('CODIGO'));
        end;
      end;
    end
    else
    begin
      EfetuarConsulta;

      InserirRegistro;
    end;
  finally
    DataManager.Free;
  end;
end;

procedure TFrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;

  if (Assigned(FMemCeps)) then
    FreeAndNil(FMemCeps);

  try
    FirebirdConn.Disconnect;
    FirebirdConn.Free;
  finally
  end;
end;

procedure TFrmMain.FormShow(Sender: TObject);
var
  FArquivo: TextFile;
  Caminho, servidor, usuario, senha: string;
begin
  // Configurações do banco de dados
  AssignFile(FArquivo, ExtractFilePath(paramstr(0)) + 'Caminho.ini');
  Reset(FArquivo);
  Readln(FArquivo, servidor);
  Readln(FArquivo, Caminho);
  Readln(FArquivo, usuario);
  Readln(FArquivo, senha);
  closeFile(FArquivo);

  FirebirdConn := TFirebirdConnection.Create(servidor, Caminho, usuario, senha);
  FirebirdConn.Connect;
end;

procedure TFrmMain.rbCEPClick(Sender: TObject);
begin
  TipoConsulta;
end;

procedure TFrmMain.rbEnderecoClick(Sender: TObject);
begin
  TipoConsulta;
end;

procedure TFrmMain.rbJsonClick(Sender: TObject);
begin
  TipoRetorno;
end;

procedure TFrmMain.rbXmlClick(Sender: TObject);
begin
  TipoRetorno;
end;

procedure TFrmMain.TipoRetorno;
begin
  if rbJson.Checked then
    lblTipo.Caption := 'JSON'
  else
    lblTipo.Caption := 'Xml';

  // Limpa campos
  edtCEP.Clear;
  edtLogradouro.Clear;
  edtComplemento.Clear;
  edtBairro.Clear;
  edtLocalidade.Clear;
  edtUF.Clear;
  edtDDD.Clear;
  edtIBGE.Clear;
  edtGIA.Clear;
  edtJSON_Xml.Clear;
end;

procedure TFrmMain.VisualizarEnderecoArmazenado(Codigo: Integer);
begin
  tbsArmazenados.Show;
  btnBuscarClick(self);
  FMemCeps.Locate('CODIGO', Codigo, []);
end;

procedure TFrmMain.TipoConsulta;
begin
  // Limpa campos consultar
  edtCEPConsultar.Clear;
  edtUFConsultar.Clear;
  edtCidadeConsultar.Clear;
  edtEnderecoConsultar.Clear;

  // Limpa campos
  edtCEP.Clear;
  edtLogradouro.Clear;
  edtComplemento.Clear;
  edtBairro.Clear;
  edtLocalidade.Clear;
  edtUF.Clear;
  edtDDD.Clear;
  edtIBGE.Clear;
  edtGIA.Clear;
  edtJSON_Xml.Clear;
end;

procedure TFrmMain.InserirRegistro;
var
  FDQuery: TFDQuery;
begin
  FDQuery := TFDQuery.Create(nil);

  try
    FDQuery.Connection := FirebirdConn.FConnection;

    FDQuery.SQL.Text :=
      'INSERT INTO VIACEP (CEP, LOGRADOURO, COMPLEMENTO, BAIRRO, LOCALIDADE, UF) VALUES (:CEP, :LOGRADOURO, :COMPLEMENTO, :BAIRRO, :LOCALIDADE, :UF)';
    FDQuery.ParamByName('CEP').Value := RemoverMascaraCEP(edtCEP.Text);
    FDQuery.ParamByName('LOGRADOURO').Value := edtLogradouro.Text;
    FDQuery.ParamByName('COMPLEMENTO').Value := edtComplemento.Text;
    FDQuery.ParamByName('BAIRRO').Value := edtBairro.Text;
    FDQuery.ParamByName('LOCALIDADE').Value := edtLocalidade.Text;
    FDQuery.ParamByName('UF').Value := edtUF.Text;

    FDQuery.ExecSQL;
  finally
    FDQuery.Free;
  end;
end;

procedure TFrmMain.AtualizarRegistro(Codigo: Integer);
var
  FDQuery: TFDQuery;
begin
  FDQuery := TFDQuery.Create(nil);

  try
    FDQuery.Connection := FirebirdConn.FConnection;

    FDQuery.SQL.Text := 'UPDATE VIACEP SET CEP = ' +
      quotedstr(RemoverMascaraCEP(edtCEP.Text)) + ', LOGRADOURO = ' +
      quotedstr(edtLogradouro.Text) + ', COMPLEMENTO = ' +
      quotedstr(edtComplemento.Text) + ', BAIRRO = ' + quotedstr(edtBairro.Text)
      + ', LOCALIDADE = ' + quotedstr(edtLocalidade.Text) + ', UF = ' +
      quotedstr(edtUF.Text) + ' WHERE CODIGO = ' + InttoStr(Codigo);

    FDQuery.ExecSQL;

    ShowMessage('Atualização efetuada com sucesso.');
  finally
    FDQuery.Free;
  end;
end;

end.
