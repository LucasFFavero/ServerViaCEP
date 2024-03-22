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
    dbgRetornados: TDBGrid;
    dtsRetornados: TDataSource;
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
    procedure dbgRetornadosDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
  private
    FMemCeps: TFDMemTable;
    FMemLogradouros: TFDMemTable;
  public
    FirebirdConn: TFirebirdConnection;
  end;

var
  FrmMain: TFrmMain;

implementation

uses ViaCEP.Intf, ViaCEP.Core, ViaCEP.Model;

{$R *.dfm}

function RemoverAcentos(const Str: string): string;
const
  ComAcentos = '·‡„‚ÈÍÌÛÙı˙¸Á¡¿√¬… Õ”‘’⁄‹«';
  SemAcentos = 'aaaaeeiooouucAAAAEEIOOOUUC';
var
  I: Integer;
begin
  Result := Str;
  for I := 1 to Length(ComAcentos) do
    Result := StringReplace(Result, ComAcentos[I], SemAcentos[I],
      [rfReplaceAll]);
end;

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
    ShowMessage('CEP v·lido.')
  else
    ShowMessage('CEP inv·lido.');
end;

procedure TFrmMain.dbgArmazenadosDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  if not FMemCeps.IsEmpty then
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
end;

procedure TFrmMain.dbgRetornadosDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  if not FMemLogradouros.IsEmpty then
  begin
    if gdSelected in State then
    begin
      with dbgRetornados.Canvas do
      begin
        Brush.Color := $002CAE00;
        FillRect(Rect);
        Font.Style := [fsBold]
      end;
    end;
    dbgRetornados.DefaultDrawDataCell(Rect, dbgRetornados.columns[DataCol]
      .Field, State);
  end;
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
  FIdSeq, I: Integer;
begin
  try
    ViaCEP := TViaCEP.Create;

    if rbCEP.Checked then
    begin
      strConsultar := edtCEPConsultar.Text;

      // Tipo retorno
      if (rbJson.Checked) then
        CEP := ViaCEP.GetJSON(strConsultar)
      else
        CEP := ViaCEP.GetXml(strConsultar);

      if not Assigned(CEP) then
      begin
        ShowMessage('EndereÁo n„o localizado.');
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
    end
    else
    begin
      dbgRetornados.DataSource := nil;
      dtsRetornados.DataSet := nil;

      strConsultar := edtUFConsultar.Text + '/' + edtCidadeConsultar.Text + '/'
        + edtEnderecoConsultar.Text;

      if (rbJson.Checked) then
      begin
        FMemLogradouros := ViaCEP.GetLogradouroJSON(strConsultar);
        edtJSON_Xml.Lines.loadfromfile(ExtractFilePath(ParamStr(0)) +
          'LogradouroJSON.txt');
      end
      else
      begin
        FMemLogradouros := ViaCEP.GetLogradouroXML(strConsultar);
        edtJSON_Xml.Lines.loadfromfile(ExtractFilePath(ParamStr(0)) +
          'LogradouroXML.txt');
      end;

      if (Assigned(FMemLogradouros)) and (not FMemLogradouros.IsEmpty) then
      begin
        dtsRetornados.DataSet := FMemLogradouros;
        dbgRetornados.DataSource := dtsRetornados;
        FMemLogradouros.First;
      end;
    end;
  finally
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
      ShowMessage('Informe um EndereÁo v·lido para consultar.');
      Exit;
    end;
  end;

  try
    DataManager := TFirebirdDataManager.Create(FirebirdConn.Connection);

    // Verifica se o endereÁo est· armazenado
    if rbCEP.Checked then
      DataManager.ExecuteQuery
        ('SELECT VIACEP.CODIGO FROM VIACEP WHERE VIACEP.CEP = ' +
        quotedstr(RemoverMascaraCEP(edtCEPConsultar.Text)))
    else
      DataManager.ExecuteQuery
        ('SELECT VIACEP.CODIGO FROM VIACEP WHERE VIACEP.UF = ' +
        quotedstr(edtUFConsultar.Text) + ' AND VIACEP.LOCALIDADE = ' +
        quotedstr(edtCidadeConsultar.Text) + ' AND VIACEP.LOGRADOURO LIKE ' +
        quotedstr('%' + edtEnderecoConsultar.Text + '%'));

    if not DataManager.IsEmpty then
    begin
      if MessageDlg('EndereÁo j· armazenado.' + #13 +
        'Deseja visualizar os dados do endereÁo armazenado?', mtConfirmation,
        mbYesNo, 0) = mrYes then
      begin
        VisualizarEnderecoArmazenado(DataManager.GetFieldValue('CODIGO'));
        Exit;
      end
      else
      begin
        if MessageDlg('Efetuar nova consulta e atualizar as informaÁıes?',
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

  if (Assigned(FMemLogradouros)) then
    FreeAndNil(FMemLogradouros);

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
  // ConfiguraÁıes do banco de dados
  AssignFile(FArquivo, ExtractFilePath(ParamStr(0)) + 'Caminho.ini');
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

  if Assigned(FMemLogradouros) then
    FMemLogradouros.EmptyDataSet;

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
  if rbCEP.Checked then
    dbgRetornados.Visible := false
  else
    dbgRetornados.Visible := true;

  if Assigned(FMemLogradouros) then
    FMemLogradouros.EmptyDataSet;

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

    if rbCEP.Checked then
    begin
      FDQuery.SQL.Text :=
        'INSERT INTO VIACEP (CEP, LOGRADOURO, COMPLEMENTO, BAIRRO, LOCALIDADE, UF) VALUES (:CEP, :LOGRADOURO, :COMPLEMENTO, :BAIRRO, :LOCALIDADE, :UF)';
      FDQuery.ParamByName('CEP').Value :=
        RemoverMascaraCEP(UpperCase(RemoverAcentos(edtCEP.Text)));
      FDQuery.ParamByName('LOGRADOURO').Value :=
        UpperCase(RemoverAcentos(edtLogradouro.Text));
      FDQuery.ParamByName('COMPLEMENTO').Value :=
        UpperCase(RemoverAcentos(edtComplemento.Text));
      FDQuery.ParamByName('BAIRRO').Value :=
        UpperCase(RemoverAcentos(edtBairro.Text));
      FDQuery.ParamByName('LOCALIDADE').Value :=
        UpperCase(RemoverAcentos(edtLocalidade.Text));
      FDQuery.ParamByName('UF').Value := UpperCase(RemoverAcentos(edtUF.Text));
      FDQuery.ExecSQL;
    end
    else
    begin
      FMemLogradouros.First;
      while not FMemLogradouros.Eof do
      begin
        FDQuery.SQL.Text :=
          'INSERT INTO VIACEP (CEP, LOGRADOURO, COMPLEMENTO, BAIRRO, LOCALIDADE, UF) VALUES (:CEP, :LOGRADOURO, :COMPLEMENTO, :BAIRRO, :LOCALIDADE, :UF)';
        FDQuery.ParamByName('CEP').Value :=
          UpperCase(RemoverAcentos(RemoverMascaraCEP(FMemLogradouros.FieldByName
          ('CEP').Value)));
        FDQuery.ParamByName('LOGRADOURO').Value :=
          UpperCase(RemoverAcentos(FMemLogradouros.FieldByName
          ('LOGRADOURO').Value));
        FDQuery.ParamByName('COMPLEMENTO').Value :=
          UpperCase(RemoverAcentos(FMemLogradouros.FieldByName
          ('COMPLEMENTO').Value));
        FDQuery.ParamByName('BAIRRO').Value :=
          UpperCase(RemoverAcentos(FMemLogradouros.FieldByName
          ('BAIRRO').Value));
        FDQuery.ParamByName('LOCALIDADE').Value :=
          UpperCase(RemoverAcentos(FMemLogradouros.FieldByName
          ('LOCALIDADE').Value));
        FDQuery.ParamByName('UF').Value :=
          UpperCase(RemoverAcentos(FMemLogradouros.FieldByName('UF').Value));
        FDQuery.ExecSQL;

        FMemLogradouros.Next;
      end;

      FMemLogradouros.First;
    end;
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

    if rbCEP.Checked then
    begin
      FDQuery.SQL.Text := 'UPDATE VIACEP SET CEP = ' +
        quotedstr(RemoverMascaraCEP(UpperCase(RemoverAcentos(edtCEP.Text)))) +
        ', LOGRADOURO = ' +
        quotedstr(UpperCase(RemoverAcentos(edtLogradouro.Text))) +
        ', COMPLEMENTO = ' +
        quotedstr(UpperCase(RemoverAcentos(edtComplemento.Text))) +
        ', BAIRRO = ' + quotedstr(UpperCase(RemoverAcentos(edtBairro.Text))) +
        ', LOCALIDADE = ' +
        quotedstr(UpperCase(RemoverAcentos(edtLocalidade.Text))) + ', UF = ' +
        quotedstr(RemoverAcentos(edtUF.Text)) + ' WHERE CODIGO = ' +
        InttoStr(Codigo);
      FDQuery.ExecSQL;
    end
    else
    begin
      if (Assigned(FMemLogradouros)) and (not FMemLogradouros.IsEmpty) then
      begin
        FMemLogradouros.First;
        while not FMemLogradouros.Eof do
        begin
          FDQuery.SQL.Text := 'UPDATE VIACEP SET CEP = ' +
            quotedstr(RemoverMascaraCEP
            (UpperCase(RemoverAcentos(RemoverMascaraCEP
            (FMemLogradouros.FieldByName('CEP').Value))))) + ', LOGRADOURO = ' +
            quotedstr(UpperCase(RemoverAcentos(FMemLogradouros.FieldByName
            ('LOGRADOURO').Value))) + ', COMPLEMENTO = ' +
            quotedstr(UpperCase(RemoverAcentos(FMemLogradouros.FieldByName
            ('COMPLEMENTO').Value))) + ', BAIRRO = ' +
            quotedstr(UpperCase(RemoverAcentos(FMemLogradouros.FieldByName
            ('BAIRRO').Value))) + ', LOCALIDADE = ' +
            quotedstr(UpperCase(RemoverAcentos(FMemLogradouros.FieldByName
            ('LOCALIDADE').Value))) + ', UF = ' +
            quotedstr(UpperCase(RemoverAcentos(FMemLogradouros.FieldByName('UF')
            .Value))) + ' WHERE CEP = ' +
            UpperCase(RemoverAcentos
            (RemoverMascaraCEP(FMemLogradouros.FieldByName('CEP').Value)));
          FDQuery.ExecSQL;

          FMemLogradouros.Next;
        end;

        FMemLogradouros.First;
      end;
    end;

    ShowMessage('AtualizaÁ„o efetuada com sucesso.');
  finally
    FDQuery.Free;
  end;
end;

end.
