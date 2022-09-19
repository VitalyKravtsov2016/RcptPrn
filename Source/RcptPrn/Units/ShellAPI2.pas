unit ShellAPI2;

interface

uses
  // VCL
  Windows;

// Minimum operating systems: Windows 2000 !!!
function SHCreateDirectory(Wnd: HWND; Path: PWideChar): Integer;
function SHCreateDirectoryExA(Wnd: HWND; Path: PAnsiChar; psa: PSecurityAttributes): Integer;
function SHCreateDirectoryExW(Wnd: HWND; Path: PWideChar; psa: PSecurityAttributes): Integer;

implementation

const
  shell32 = 'shell32.dll';

function SHCreateDirectory; external shell32 name 'SHCreateDirectory';
function SHCreateDirectoryExA; external shell32 name 'SHCreateDirectoryExA';
function SHCreateDirectoryExW; external shell32 name 'SHCreateDirectoryExW';

end.
