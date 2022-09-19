unit BrowseFolders;

interface

uses
  // VCL
  Windows, Messages, SysUtils, Classes, Consts, Controls, Forms,
  ShellAPI, ShlObj, ComObj, ActiveX, FileCtrl;

function BrowseFolder(AParentWnd: HWND; var ComputerName: string;
  const DlgText: string; AHelpContext: THelpContext): Boolean;

implementation

function RemoveBackSlash(const DirName: string): string;
begin
  Result := DirName;
  if (Length(Result) > 1) and
    (Result[Length(Result)] = '\') then
  begin
    if not ((Length(Result) = 3) and (UpCase(Result[1]) in ['A'..'Z']) and
      (Result[2] = ':')) then
      Delete(Result, Length(Result), 1);
  end;
end;

function DirExists(Name: string): Boolean;
var
  Code: Integer;
begin
  Code := GetFileAttributes(PChar(Name));
  Result := (Code <> -1) and (FILE_ATTRIBUTE_DIRECTORY and Code <> 0);
end;

procedure FitRectToScreen(var Rect: TRect);
var
  X, Y, Delta: Integer;
begin
  X := GetSystemMetrics(SM_CXSCREEN);
  Y := GetSystemMetrics(SM_CYSCREEN);
  with Rect do begin
    if Right > X then begin
      Delta := Right - Left;
      Right := X;
      Left := Right - Delta;
    end;
    if Left < 0 then begin
      Delta := Right - Left;
      Left := 0;
      Right := Left + Delta;
    end;
    if Bottom > Y then begin
      Delta := Bottom - Top;
      Bottom := Y;
      Top := Bottom - Delta;
    end;
    if Top < 0 then begin
      Delta := Bottom - Top;
      Top := 0;
      Bottom := Top + Delta;
    end;
  end;
end;

procedure CenterWindow(Wnd: HWnd);
var
  R: TRect;
begin
  GetWindowRect(Wnd, R);
  R := Rect((GetSystemMetrics(SM_CXSCREEN) - R.Right + R.Left) div 2,
    (GetSystemMetrics(SM_CYSCREEN) - R.Bottom + R.Top) div 2,
    R.Right - R.Left, R.Bottom - R.Top);
  FitRectToScreen(R);
  SetWindowPos(Wnd, 0, R.Left, R.Top, 0, 0, SWP_NOACTIVATE or
    SWP_NOSIZE or SWP_NOZORDER);
end;

{ TBrowseFolderDlg }

type
  TBrowseKind = (bfFolders, bfComputers);
  TDialogPosition = (dpDefault, dpScreenCenter);

  TBrowseFolderDlg = class(TComponent)
  private
    FHandle: HWnd;
    FText: string;
    FParentWnd: HWND;
    FFolderName: string;
    FImageIndex: Integer;
    FDisplayName: string;
    FSelectedName: string;
    FDefWndProc: Pointer;
    FDesktopRoot: Boolean;
    FObjectInstance: Pointer;
    FBrowseKind: TBrowseKind;
    FPosition: TDialogPosition;
    FHelpContext: THelpContext;
    FOnInitialized: TNotifyEvent;
    FOnSelChanged: TNotifyEvent;
    procedure DoInitialized;
    procedure SetOkEnable(Value: Boolean);
    procedure SetSelPath(const Path: string);
    procedure DoSelChanged(Param: PItemIDList);
    procedure WMCommand(var Message: TMessage); message WM_COMMAND;
    procedure WMNCDestroy(var Message: TWMNCDestroy); message WM_NCDESTROY;
  protected
    procedure DefaultHandler(var Message); override;
    procedure WndProc(var Message: TMessage); virtual;
    function TaskModalDialog(var Info: TBrowseInfo): PItemIDList;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Execute: Boolean;
    property Handle: HWnd read FHandle;
    property DisplayName: string read FDisplayName;
    property SelectedName: string read FSelectedName write FSelectedName;
    property ImageIndex: Integer read FImageIndex;
  published
    property BrowseKind: TBrowseKind read FBrowseKind write FBrowseKind default bfFolders;
    property DesktopRoot: Boolean read FDesktopRoot write FDesktopRoot default True;
    property DialogText: string read FText write FText;
    property FolderName: string read FFolderName write FFolderName;
    property HelpContext: THelpContext read FHelpContext write FHelpContext default 0;
    property Position: TDialogPosition read FPosition write FPosition default dpScreenCenter;
    property OnInitialized: TNotifyEvent read FOnInitialized write FOnInitialized;
    property OnSelChanged: TNotifyEvent read FOnSelChanged write FOnSelChanged;
  end;

function ExplorerHook(Wnd: HWnd; Msg: UINT; LParam: LPARAM; Data: LPARAM): Integer; stdcall;
begin
  Result := 0;
  if Msg = BFFM_INITIALIZED then begin
    if TBrowseFolderDlg(Data).Position = dpScreenCenter then
      CenterWindow(Wnd);
    TBrowseFolderDlg(Data).FHandle := Wnd;
    TBrowseFolderDlg(Data).FDefWndProc := Pointer(SetWindowLong(Wnd, GWL_WNDPROC,
      Longint(TBrowseFolderDlg(Data).FObjectInstance)));
    TBrowseFolderDlg(Data).DoInitialized;
  end
  else if Msg = BFFM_SELCHANGED then begin
    TBrowseFolderDlg(Data).FHandle := Wnd;
    TBrowseFolderDlg(Data).DoSelChanged(PItemIDList(LParam));
  end;
end;

const
  HelpButtonId = $FFFF;

constructor TBrowseFolderDlg.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FObjectInstance := MakeObjectInstance(WndProc);
  FDesktopRoot := True;
  FBrowseKind := bfFolders;
  FPosition := dpScreenCenter;
  SetLength(FDisplayName, MAX_PATH);
end;

destructor TBrowseFolderDlg.Destroy;
begin
  if FObjectInstance <> nil then FreeObjectInstance(FObjectInstance);
  inherited Destroy;
end;

procedure TBrowseFolderDlg.DoInitialized;
const
  SBtn = 'BUTTON';
var
  BtnHandle, HelpBtn, BtnFont: THandle;
  BtnSize: TRect;
begin
  if (FBrowseKind = bfComputers) or DirExists(FFolderName) then
    SetSelPath(FFolderName);
  if FHelpContext <> 0 then begin
    BtnHandle := FindWindowEx(FHandle, 0, SBtn, nil);
    if (BtnHandle <> 0) then begin
      GetWindowRect(BtnHandle, BtnSize);
      ScreenToClient(FHandle, BtnSize.TopLeft);
      ScreenToClient(FHandle, BtnSize.BottomRight);
      BtnFont := SendMessage(FHandle, WM_GETFONT, 0, 0);
      HelpBtn := CreateWindow(SBtn, PChar(SHelpButton),
        WS_CHILD or WS_CLIPSIBLINGS or WS_VISIBLE or BS_PUSHBUTTON or WS_TABSTOP,
        12, BtnSize.Top, BtnSize.Right - BtnSize.Left, BtnSize.Bottom - BtnSize.Top,
        FHandle, HelpButtonId, HInstance, nil);
      if BtnFont <> 0 then
        SendMessage(HelpBtn, WM_SETFONT, BtnFont, MakeLParam(1, 0));
      UpdateWindow(FHandle);
    end;
  end;
  if Assigned(FOnInitialized) then FOnInitialized(Self);
end;

procedure TBrowseFolderDlg.DoSelChanged(Param: PItemIDList);
var
  Temp: array[0..MAX_PATH] of Char;
begin
  if (FBrowseKind = bfComputers) then begin
    FSelectedName := DisplayName;
  end
  else begin
    if SHGetPathFromIDList(Param, Temp) then begin
      FSelectedName := StrPas(Temp);
      SetOkEnable(DirExists(FSelectedName));
    end
    else begin
      FSelectedName := '';
      SetOkEnable(False);
    end;
  end;
  if Assigned(FOnSelChanged) then FOnSelChanged(Self);
end;

procedure TBrowseFolderDlg.SetSelPath(const Path: string);
begin
  if FHandle <> 0 then
    SendMessage(FHandle, BFFM_SETSELECTION, 1, Longint(PChar(Path)));
end;

procedure TBrowseFolderDlg.SetOkEnable(Value: Boolean);
begin
  if FHandle <> 0 then SendMessage(FHandle, BFFM_ENABLEOK, 0, Ord(Value));
end;

procedure TBrowseFolderDlg.DefaultHandler(var Message);
begin
  if FHandle <> 0 then
    with TMessage(Message) do
      Result := CallWindowProc(FDefWndProc, FHandle, Msg, WParam, LParam)
  else inherited DefaultHandler(Message);
end;

procedure TBrowseFolderDlg.WndProc(var Message: TMessage);
begin
  Dispatch(Message);
end;

procedure TBrowseFolderDlg.WMCommand(var Message: TMessage);
begin
  if (Message.wParam = HelpButtonId) and (LongRec(Message.lParam).Hi =
    BN_CLICKED) and (FHelpContext <> 0) then
  begin
    Application.HelpContext(FHelpContext);
  end
  else inherited;
end;

procedure TBrowseFolderDlg.WMNCDestroy(var Message: TWMNCDestroy);
begin
  inherited;
  FHandle := 0;
end;

function TBrowseFolderDlg.Execute: Boolean;
var
  BrowseInfo: TBrowseInfo;
  ItemIDList: PItemIDList;
  Temp: array[0..MAX_PATH] of Char;
begin
  if FDesktopRoot and (FBrowseKind = bfFolders) then
    BrowseInfo.pidlRoot := nil
  else begin
    if FBrowseKind = bfComputers then { root - Network }
      OleCheck(SHGetSpecialFolderLocation(0, CSIDL_NETWORK,
        BrowseInfo.pidlRoot))
    else { root - MyComputer }
      OleCheck(SHGetSpecialFolderLocation(0, CSIDL_DRIVES,
        BrowseInfo.pidlRoot));
  end;
  try
    SetLength(FDisplayName, MAX_PATH);
    with BrowseInfo do begin
      pszDisplayName := PChar(DisplayName);
      if DialogText <> '' then lpszTitle := PChar(DialogText)
      else lpszTitle := nil;
      if FBrowseKind = bfComputers then
        ulFlags := BIF_BROWSEFORCOMPUTER
      else
        ulFlags := BIF_RETURNONLYFSDIRS or BIF_RETURNFSANCESTORS;
      lpfn := ExplorerHook;
      lParam := Longint(Self);
      hWndOwner := FParentWnd;
      iImage := 0;
    end;
    ItemIDList := TaskModalDialog(BrowseInfo);
    Result := ItemIDList <> nil;
    if Result then
    try
      if FBrowseKind = bfFolders then begin
        Win32Check(SHGetPathFromIDList(ItemIDList, Temp));
        FFolderName := RemoveBackSlash(StrPas(Temp));
      end
      else begin
        FFolderName := DisplayName;
      end;
      FSelectedName := FFolderName;
      FImageIndex := BrowseInfo.iImage;
    finally
      CoTaskMemFree(ItemIDList);
    end;
  finally
    if BrowseInfo.pidlRoot <> nil then CoTaskMemFree(BrowseInfo.pidlRoot);
  end;
end;

function TBrowseFolderDlg.TaskModalDialog(var Info: TBrowseInfo): PItemIDList;
begin
  try
    Result := SHBrowseForFolder(Info);
  finally
    FHandle := 0;
    FDefWndProc := nil;
  end;
end;

function BrowseFolder(AParentWnd: HWND; var ComputerName: string;
  const DlgText: string; AHelpContext: THelpContext): Boolean;
begin
  with TBrowseFolderDlg.Create(Application) do
  try
    BrowseKind := bfFolders;
    DialogText := DlgText;
    FolderName := ComputerName;
    HelpContext := AHelpContext;
    FParentWnd := AParentWnd;
    Result := Execute;
    if Result then ComputerName := FolderName;
  finally
    Free;
  end;
end;

end.
