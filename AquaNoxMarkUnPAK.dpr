{===============================================================================
                           AquaNox PAK Archives Extractor
                                  Version  1.0
                           [20.05.2005 -- 10.02.2006]
                Copyright (c) 2005 jTommy,  E-mail: jTommy@by.ru
             Supported: AquaNox, AquaNox 2 - Revelation, [AquaMark]
================================================================================
                           AquaNox PAK Archives Extractor
                                  Version  1.1
                    AquaNox / AquaMark PAK Archives Extractor
            Copyright (c) 2009 CTPAX-X Team,  http://www.CTPAX-X.ru/
             Supported: AquaNox, AquaNox 2 - Revelation, AquaMark 3
                 Fixes: AquaMark 3 support, small code cleanup.
================================================================================
                           AquaNox PAK Archives Extractor
                                  Version  1.2
                    AquaNox / AquaMark PAK Archives Extractor
            Updated by PyroChiliarh https://github.com/PyroChiliarch/
             Supported: AquaNox, AquaNox 2 - Revelation, AquaMark 3
           Fixes:
            - Updated source to build in Delphi 10.4 Community IDE
            - Removed broken comments
================================================================================}
Program AquaNoxMarkUnPAK;
{$APPTYPE CONSOLE}
Uses SysUtils, Windows;

{$I UTables.pas}

Const
  stSignature = 'MASSIVEFILE';//#0;

Type
  TPAKHeader = packed record
    Signature  : array[0..11] of AnsiChar; // Signature (always "MASSIVEFILE#0")
    Version    : cardinal;                 // Archive version
    NumItems   : cardinal;                 // Number of items in the archive
    Description: array[0..59] of AnsiChar; // Description (always "Copyright by Massive Development GmbH. All rights reserved.#0")
    Unknown    : array[0..03] of AnsiChar; // Unknown (always "LPT#0")
  end;

  TPAKItem = packed record
    ItemName: array[0..127] of AnsiChar;
    ItemSize: cardinal;
  end;

Var
  hPAK, hItem, hFind, RdC, WrC, n: cardinal;
  PAKHeader : TPAKHeader;
  PAKItems  : array of TPAKItem;
  PAKOffsets: array of cardinal;
  Buffer    : pointer;
  FindData  : TWin32FindData;
  AppName, RootDir: string;
  DecryptNameProc: TDecryptNameProc;
  DecryptSizeProc: TDecryptSizeProc;
          FileDir: PAnsiChar;

begin
  // Show title
  WriteLn('AquaNox / AquaMark PAK Archives Extractor v1.2');
  WriteLn('Supported: AquaNox, AquaNox 2 - Revelation, AquaMark 3');
  WriteLn('Updated by PyroChiliarch, details in repository below');
  WriteLn('https://github.com/PyroChiliarch/AquaNoxMarkUnPAK-v1.2');
  WriteLn;
  if ParamCount<1 then begin
    WriteLn('Usage: AquaNoxMarkUnPAK.exe <filename or filemask> - extract all files');
    Exit;
  end;
  //
  hFind:=FindFirstFile(PChar(ParamStr(1)), FindData);
  if hFind<>INVALID_HANDLE_VALUE then begin
    repeat
      RootDir:=ChangeFileExt(FindData.cFileName, '\');    
      // Open PAK file
      hPAK:=CreateFile(FindData.cFileName, GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
      if hPAK=INVALID_HANDLE_VALUE then begin
        WriteLn('Error open file "' + FindData.cFileName + '"');
        Continue;
      end;
      // Read PAK header
      ReadFile(hPAK, PAKHeader, SizeOf(PAKHeader), RdC, nil);
      // Check signature
      if PAKHeader.Signature<>stSignature then begin
        WriteLn('File "' + FindData.cFileName + '" not Aqua PAK archive.');
        CloseHandle(hPAK);
        Continue;
      end;
      // Check archive version
      if (PAKHeader.Version<>$00000003) and (PAKHeader.Version<>$00020003) and (PAKHeader.Version<>$00030003) then begin
        WriteLn('Unsupported archive version (' + IntToStr(LoWord(PAKHeader.Version)) + '.' + IntToStr(HiWord(PAKHeader.Version)) + ')');
        CloseHandle(hPAK);
        Continue;
      end;
      case PAKHeader.Version of
        $00000003: begin
          AppName:='AquaNox';
          DecryptNameProc:=AN1DecryptName;
          DecryptSizeProc:=AN1DecryptSize;
        end;
        $00020003: begin
          AppName:='AquaNox 2 - Revelation';
          DecryptNameProc:=AN2DecryptName;
          DecryptSizeProc:=AN2DecryptSize;
        end;
        $00030003: begin
          AppName:='AquaMark 3';
          DecryptNameProc:=AM3DecryptName;
          DecryptSizeProc:=AM3DecryptSize;
        end;
        else begin
          AppName:='Unknown';
          DecryptNameProc:=nil;
          DecryptSizeProc:=nil;
        end;
      end;
      // Show archive info
      WriteLn(
        'File: ' + FindData.cFileName + #13#10+
        'Archive info:'#13#10+
        '  Signature    : ' + PAKHeader.Signature + #13#10+
        '  Version      : ' + IntToStr(LoWord(PAKHeader.Version)) + '.' + IntToStr(HiWord(PAKHeader.Version)) + ' (' + AppName + ')' + #13#10+
        '  Num. of files: ' + IntToStr(PAKHeader.NumItems) + #13#10+
        '  Description  : ' + PAKHeader.Description + #13#10+
        '  Unknown      : ' + PAKHeader.Unknown
      );
      // If archive not contains files...
      if PAKHeader.NumItems=0 then begin
        CloseHandle(hPAK);
        Continue;
      end;
      // Read item table
      SetLength(PAKItems, PAKHeader.NumItems);
      ReadFile(hPAK, Pointer(PAKItems)^, PAKHeader.NumItems*SizeOf(TPAKItem), RdC, nil);
      // Decrypt names & sizes. Calc items data offset
      SetLength(PAKOffsets, PAKHeader.NumItems);
      PAKOffsets[0]:=SizeOf(PAKHeader)+PAKHeader.NumItems*SizeOf(TPAKItem);
      for n:=0 to PAKHeader.NumItems-1 do begin
        // Decrypt
        DecryptNameProc(PAKItems[n].ItemName, Length(String(PAKItems[n].ItemName)), n);
        DecryptSizeProc(PAKItems[n].ItemSize, n);
        // Calc offset
        if n<>0 then PAKOffsets[n]:=PAKOffsets[n-1]+PAKItems[n-1].ItemSize;
      end;
      // Process items
      for n:=0 to PAKHeader.NumItems-1 do begin
        // Extract
        Write('[' + IntToStr(n+1) + '/' + IntToStr(PAKHeader.NumItems) + '] ' + PAKItems[n].ItemName + '...');
        // Create path
        CreateDirectory(PChar(RootDir), nil);
        FileDir:=PAKItems[n].ItemName;
        while FileDir[0] <> #0 do begin
          if FileDir[0] in ['/', '\'] then begin
            FileDir[0]:=#0;
            CreateDirectory(PChar(RootDir+PAKItems[n].ItemName), nil);
            FileDir[0]:='\';
          end;
          inc(FileDir);
        end;
        // Create output file
        hItem:=CreateFile(PChar(RootDir+String(PAKItems[n].ItemName)), GENERIC_WRITE, FILE_SHARE_READ, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
        if hItem <> INVALID_HANDLE_VALUE then begin
          // Seek to item data
          SetFilePointer(hPAK, PAKOffsets[n], nil, FILE_BEGIN);
          // Create Buffer
          GetMem(Buffer, PAKItems[n].ItemSize);
          // Read and Write item data
          ReadFile(hPAK, Pointer(Buffer)^, PAKItems[n].ItemSize, RdC, nil);
          WriteFile(hItem, Pointer(Buffer)^, PAKItems[n].ItemSize, WrC, nil);
          // Close file
          CloseHandle(hItem);
          FreeMem(Buffer, PAKItems[n].ItemSize);
          WriteLn('Done');
        end else
          WriteLn('Error create file.');
      end;
      SetLength(PAKOffsets, 0);
      SetLength(PAKItems, 0);
      // Close PAK file
      CloseHandle(hPAK);
    until not FindNextFile(hFind, FindData);
    FindClose(hFind);
  end else
    WriteLn('0 files found');
end.
