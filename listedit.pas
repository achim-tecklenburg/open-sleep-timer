unit listedit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, RTTICtrls, Forms, Controls,
  Graphics, Dialogs, DBGrids, DbCtrls, StdCtrls, Buttons, Menus, func, Grids;

type

  { TfListEdit }

  TfListEdit = class(TForm)
    btnAdd: TButton;
    btnDeleteRow: TButton;
    btnChoose: TButton;
    StringGrid1: TStringGrid;
    procedure btnAddClick(Sender: TObject);
    procedure btnChooseClick(Sender: TObject);
    procedure btnDeleteRowClick(Sender: TObject);
    procedure StringGrid1KeyUp(Sender: TObject);
    procedure ToggleChooseBtn;
    procedure FormClose(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fListEdit: TfListEdit;
  TEditSelect: TEdit; //Holds edSelectedScript / edSelectedWebsite from Optionsform
  sConfigListPath: String; //e.g. 'www.youtube.com' or 'programfiles/vlc/vlc.exe'
  sConfigSelectedItem: String; //e.g. 'youtube' or 'vlc'
  sListFilename: String; //e.g. 'ListOfWebsites.csv' or 'ListOfPrograms.csv'

implementation

uses
  optionsform;

{$R *.lfm}

{ TfListEdit }

//Form Show
//******************************************************************************
procedure TfListEdit.FormShow(Sender: TObject);
begin
//Todo: complete this
  if StringGrid1.ColCount = 0 then
  begin
    StringGrid1.Columns.Add;
    StringGrid1.Columns.Add;
    StringGrid1.Cols[0].Text := 'Name';
  end;
  if StringGrid1.FixedRows <= StringGrid1.RowCount - 1 then //If only 1 Row left
    btnDeleteRow.Enabled := False;
end;

//Add-Button
//******************************************************************************
procedure TfListEdit.btnAddClick(Sender: TObject);
begin
  if not btnDeleteRow.Enabled then
    btnDeleteRow.Enabled := True;
  StringGrid1.InsertColRow(false, 1);
end;

//Choose-Button
//******************************************************************************
procedure TfListEdit.btnChooseClick(Sender: TObject);
var
  sLinkName: String;
  sLinkPath: String;
begin
  sLinkName := StringGrid1.Cells[0, StringGrid1.Row];
  sLinkPath := StringGrid1.Cells[1, StringGrid1.Row];

  //update edit field optionsform
  TEditSelect.Text := sLinkName;
  //Save settings to config
  func.writeConfig('options', sConfigSelectedItem, sLinkName);
  //save path to config
  func.writeConfig('options', sConfigListPath, sLinkPath);

  fListEdit.Close;
end;

//Delete-Button
//******************************************************************************
procedure TfListEdit.btnDeleteRowClick(Sender: TObject);
begin
  if StringGrid1.FixedRows <= StringGrid1.RowCount - 1 then //If only 1 Row left
  begin
    StringGrid1.DeleteRow(StringGrid1.Row);
  end
  else begin
    btnDeleteRow.Enabled := False;
  end;
end;

//Key Up Event
//******************************************************************************
procedure TfListEdit.StringGrid1KeyUp(Sender: TObject);
begin
    ToggleChooseBtn;
end;

//ToogleChoose Button - Deaktivate Choose Button if Path = ''
//******************************************************************************
procedure TfListEdit.ToggleChooseBtn;
begin
  if StringGrid1.Cells[1, StringGrid1.Row] = '' then
  begin
    btnChoose.Enabled := False;
  end
  else begin
    btnChoose.Enabled := True;
  end;
end;

//Form Close
//******************************************************************************
procedure TfListEdit.FormClose(Sender: TObject);
begin
  StringGrid1.SaveToCSVFile(func.GetOsConfigPath(sListFilename), ',', false);
end;


end.

