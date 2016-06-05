unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, FileUtil, RTTICtrls, TAGraph, {TASources,} TASeries,
  Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, Spin, Menus, ComCtrls,
  VolumeControl, PopUp, optionsform, Math, IniFiles;

type

  { TfMainform }

  TfMainform = class(TForm)
    btnStop: TButton;
    btnStart: TButton;
    Chart1: TChart;
    Chart1LineSeries1: TLineSeries;
    chkStandby: TCheckBox;
    edMinutesUntilStart: TSpinEdit;
    lblCurrentVolume: TLabel;
    lblShowCurrentVolume: TLabel;
    lblShowTargetVolume: TLabel;
    lblTargetVolume: TLabel;
    lblMinutesUntilStop: TLabel;
    edMinutesUntilStop: TSpinEdit;
    lblMinutesUntilStart: TLabel;
    MenuItem2: TMenuItem;
    mnMainMenu: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem4: TMenuItem;
    miAbout: TMenuItem;
    tbTargetVolume: TTrackBar;
    tbCurrentVolume: TTrackBar;
    tmrCountDown: TTimer;
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure edMinutesUntilStartChange(Sender: TObject);
    procedure edMinutesUntilStopChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure AdjustVolume(iMinutesUntilStop: Integer; iTargetVolume: Integer);
    procedure MenuItem2Click(Sender: TObject);
    procedure miAboutClick(Sender: TObject);
    procedure tbTargetVolumeChange(Sender: TObject);
    procedure tbCurrentVolumeChange(Sender: TObject);
    procedure tmrCountDownTimer(Sender: TObject);
    procedure UpdateButtons;
    procedure StopCountDown(Sender: TObject);
    procedure UpdateShowCurrentVolumeLabel;
    procedure parseConfigFile;
    procedure saveSettings;
    procedure updateDiagram;

  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fMainform: TfMainform;
  bIsStopped: Boolean = False;
  iDurationDefault: Integer;
  iDurationSetByUser: Integer;
  dVolumeLevelAtStart: Double;
  bTestMode: Boolean;
  //TODO: Define default values as constants


implementation

{$R *.lfm}

{ TfMainform }

//Form Show
//*****************************************
procedure TfMainform.FormShow(Sender: TObject);
var
  iniConfigFile: TINIFile; //TODO: Move config.ini access to func
  bStartCountdownAutomatically: Boolean;
begin
  //tbTargetVolume.Min := 0;
  //tbTargetVolume.Max := 100;
  //tbTargetVolume.PageSize := 5;

  parseConfigFile;
  tbTargetVolumeChange(NIL); //Update lblShowTargetVolume.Caption
  //TODO: move trackbar change to form show?
  UpdateShowCurrentVolumeLabel;

  //Check if Countdown should start immedately
  iniConfigFile := TINIFile.Create('config.ini'); //TODO: Move config.ini access to func
  bStartCountdownAutomatically := iniConfigFile.ReadBool('options', 'StartCountdownAutomatically', False);
  if bStartCountdownAutomatically then
    btnStartClick(Application);

  //Style Settings for Diagram
  Chart1.BackColor:=clWhite;
  Chart1.Extent.UseYMin:=True;
  Chart1.Extent.YMin:=0;
  Chart1.Extent.UseYMax:=True;
  Chart1.Extent.YMax:=100;
  //Chart1.LeftAxis.Range.UseMin:=True;
  //Chart1.LeftAxis.Range.Min:=0;
  //Chart1.LeftAxis.Range.UseMax:=True;
  //Chart1.LeftAxis.Range.Max:=100;
end;

//Update Diagram
//******************************************
procedure TfMainform.updateDiagram;
var
  i: Integer;
  dSteigung: Double;
  dYAbschnitt: Double;
  iDuration: Integer;
  iDelayedStart: Integer;
  iTargetVolume: Integer;
  iCurrentVolume: Integer;

begin
  iDelayedStart := edMinutesUntilStart.Value;
  iTargetVolume := tbTargetVolume.Position;
  iCurrentVolume := tbCurrentVolume.Position;
  iDuration := edMinutesUntilStop.Value;


  dSteigung := (iTargetVolume - iCurrentVolume) / (55 - 15);
  dYAbschnitt := dSteigung *-1 * iDelayedStart + iCurrentVolume;

  for i:=0 to iDelayedStart do begin
    Chart1LineSeries1.AddXY(i, iCurrentVolume);
  end;
  for i:=iDelayedStart to iDuration do begin
    Chart1LineSeries1.AddXY(i, i * dSteigung + dYAbschnitt);
  end;
end;

//Parse Config File
//******************************************
procedure TfMainform.parseConfigFile;
var
  iniConfigFile: TINIFile;
begin
   iniConfigFile := TINIFile.Create('config.ini');
  try
    bTestMode := iniConfigFile.ReadBool('development', 'TestMode', false);
    edMinutesUntilStop.Value := iniConfigFile.ReadInteger('main', 'DurationDefault', 75);
    edMinutesUntilStop.Increment := iniConfigFile.ReadInteger('main', 'MinutesIncrement', 15);
    edMinutesUntilStart.Value := iniConfigFile.ReadInteger('main', 'DelayDefault', 20);
    edMinutesUntilStart.Increment:= iniConfigFile.ReadInteger('main', 'MinutesIncrement', 15);
    tbTargetVolume.Position := iniConfigFile.ReadInteger('main', 'TargetVolume', 10);
    tbCurrentVolume.Position := iniConfigFile.ReadInteger('main', 'DefaultVolume', 30);
    chkStandby.Checked := iniConfigfile.Readbool('main', 'GoToStandby', False);
    fMainform.Left := iniConfigFile.ReadInteger('main', 'MainformLeft', 300);
    fMainform.Top := iniConfigFile.ReadInteger('main', 'MainformTop', 200);
    fPopUp.Left := iniConfigFile.ReadInteger('main', 'PopUpLeft', 330);
    fPopUp.Top := iniConfigFile.ReadInteger('main', 'PopUpTop', 270);

    //TODO: Put in config file
    Form1.Left := 300;
    Form1.Top := 200;
  finally
  end;
end;

//Save Settings
//*****************************************
procedure TfMainform.saveSettings;
var
  iniConfigFile: TINIFile;
begin
  iniConfigFile := TINIFile.Create('config.ini');
  iniConfigFile.WriteInteger('main', 'TargetVolume', tbTargetVolume.Position);
  iniConfigFile.WriteInteger('main', 'DefaultVolume', tbCurrentVolume.Position);
  iniConfigFile.WriteInteger('main', 'DurationDefault', edMinutesUntilStop.Value);
  iniConfigFile.WriteInteger('main', 'MainformLeft', fMainform.Left);
  iniConfigFile.WriteInteger('main', 'MainformTop', fMainform.Top);
  iniConfigFile.WriteInteger('main', 'DelayDefault', edMinutesUntilStart.Value);
  iniConfigfile.Writebool('main', 'GoToStandby', chkStandby.Checked);
end;

//Start Button
//******************************************
procedure TfMainform.btnStartClick(Sender: TObject);
begin
  UpdateButtons; //enable/disable start/stop-buttons
  dVolumeLevelAtStart := VolumeControl.GetMasterVolume(); //Save current volume for later
  iDurationSetByUser := edMinutesUntilStop.Value; //Keep initial Duration in Mind

  //if testmode -> faster contdown
  if bTestMode = true then
    tmrCountDown.Interval := 1000;

  //start count down
  tmrCountDown.Enabled := True;

end;


//Stop Button
//***************************************
procedure TfMainform.btnStopClick(Sender: TObject);
begin
  //StopCountDown;
  //fPopUp.lblQuestion.Caption := 'Stopped. Restore volume level?';
  StopCountDown(Sender);
end;

procedure TfMainform.edMinutesUntilStartChange(Sender: TObject);
begin
  Chart1LineSeries1.Clear;
  UpdateDiagram;
end;

//edMinutesUntilStop Change - On Change of Duration Field
//*****************************************************
procedure TfMainform.edMinutesUntilStopChange(Sender: TObject);
begin
  if edMinutesUntilStart.Value > edMinutesUntilStop.Value then
    edMinutesUntilStart.Value := edMinutesUntilStop.Value;

  edMinutesUntilStart.MaxValue := edMinutesUntilStop.Value;

  Chart1LineSeries1.Clear;
  UpdateDiagram;
end;


//OnClose
//***************************************
procedure TfMainform.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  saveSettings;
end;


//Update Buttons
//***************************************
procedure TfMainform.UpdateButtons;
begin
    btnStart.Enabled := not btnStart.Enabled;
    btnStop.Enabled := not btnStop.Enabled;
end;


//Adjust Volume
//****************************************
procedure TfMainform.AdjustVolume(iMinutesUntilStop: Integer; iTargetVolume: Integer);
var
  dCurrentVolume: Double;
  dVolumeStepSize: Double;
  dNewVolumeLevel: Double;
  dVolumeStepsTotal: Double;
begin

  //read current audio volume from system
  dCurrentVolume := VolumeControl.GetMasterVolume();

  //calculate new volume level
  if iMinutesUntilStop > 0 then
  begin
    dVolumeStepsTotal := dCurrentVolume * 100 - iTargetVolume;
    dVolumeStepSize := (dVolumeStepsTotal / iMinutesUntilStop) / 100;
  end;
  dNewVolumeLevel := max((dCurrentVolume - dVolumeStepSize), 0);

  //Set new Volume
  tbCurrentVolume.Position := Round(dNewVolumeLevel * 100);

  //Update Label
  UpdateShowCurrentVolumeLabel;
end;

procedure TfMainform.MenuItem2Click(Sender: TObject);
begin
  Form1.Show;
end;


//Menu Procedures
//********************************************
procedure TfMainform.miAboutClick(Sender: TObject);
begin
  showmessage('Open Sleep Timer - https://github.com/achim-tecklenburg/open-sleep-timer');
end;



//tbTargetVolumeChange - Update Display of Target Volume near Slider
//****************************************************
procedure TfMainform.tbTargetVolumeChange(Sender: TObject);
begin
  lblShowTargetVolume.Caption := IntToStr(tbTargetVolume.Position) + '%';
  Chart1LineSeries1.Clear;
  UpdateDiagram;
end;


//Current Volume Trackbar OnChange
//****************************************************
procedure TfMainform.tbCurrentVolumeChange(Sender: TObject);
var
  dNewVolumeLevel: Double;
  iNewVolumeLevel: Integer;
begin
  iNewVolumeLevel := tbCurrentVolume.Position;
  dNewVolumeLevel := Double(iNewVolumeLevel);
  VolumeControl.SetMasterVolume(dNewVolumeLevel / 100);
  UpdateShowCurrentVolumeLabel;
  Chart1LineSeries1.Clear;
  UpdateDiagram;
end;

//Timer CountDown (default = 1 minute)
//***********************************
procedure TfMainform.tmrCountDownTimer(Sender: TObject);
var
  iMinutesLapsed: Integer = 0;
  bTimeIsUp: Boolean;
  bTargetVolumeReached: Boolean;
  iCurrentVolume: Integer;
begin
  //TODO: calculate remaining minutes beforehand, then make timer interval shorter (for responsiveness)
  edMinutesUntilStop.Value := edMinutesUntilStop.Value - 1; //Count Minutes until stop
  iMinutesLapsed := iMinutesLapsed + 1; //Count Minutes since start

  if iMinutesLapsed > edMinutesUntilStart.Value then // if Start of vol red. reached)
  begin
    AdjustVolume(edMinutesUntilStop.Value, tbTargetVolume.Position);
  end;

  //check current parameters
  bTimeIsUp := edMinutesUntilStop.Value <= 0;
  iCurrentVolume := Trunc(VolumeControl.GetMasterVolume() * 100); //Get current Volume
  bTargetVolumeReached := iCurrentVolume <= tbTargetVolume.Position;

  //Stop if time is up or target volume reached
  if bTimeIsUp or bTargetVolumeReached then
    StopCountDown(Self);
end;


//Stop CountDown
//*************************************
procedure TfMainform.StopCountDown(Sender: TObject);
var
  s: String;
begin
  fPopUp.lblQuestion.Caption := 'Stopped. Restore volume level?';
  //tmrWaitForStop.Enabled := False; TODO: Remove
  tmrCountDown.Enabled := False;
  fPopUp.Show;
  UpdateButtons;

  //Go to Standby at the end (if checked)
  if (chkStandby.Checked) AND (Sender <> btnStop) then //Standby option / Stop Buttton NOT pressed
    process.RunCommand('rundll32.exe powrprof.dll,SetSuspendState Standby', s);
end;


//Update ShowCurrentVolumeLabel
procedure TfMainform.UpdateShowCurrentVolumeLabel;
begin
  fMainform.lblShowCurrentVolume.Caption := IntToStr(tbCurrentVolume.Position) + '%';
end;

end.

