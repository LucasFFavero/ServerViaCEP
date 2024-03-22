program ViaCEP;

uses
  Vcl.Forms,
  ViaCEP.Core in '..\src\ViaCEP.Core.pas',
  ViaCEP.Intf in '..\src\ViaCEP.Intf.pas',
  ViaCEP.Model in '..\src\ViaCEP.Model.pas',
  ViaCEP.Samples in 'src\ViaCEP.Samples.pas' {FrmMain},
  FirebirdConnection in '..\src\FirebirdConnection.pas',
  FirebirdDataManager in '..\src\FirebirdDataManager.pas',
  Pkg.Json.DTO in '..\src\Pkg.Json.DTO.pas',
  ViaCEP.Itens in '..\src\ViaCEP.Itens.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;

end.
