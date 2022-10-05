Const
  szKey = 64;

Type
  TKey = array[0..szKey-1] of byte;

  TDecryptNameProc = Procedure (Var aData: array of ansichar; szData, Num: integer);
  TDecryptSizeProc = Procedure (Var aData: cardinal; Num: integer);

Const
  AN1Key: TKey = (
    $68, $3c, $61, $37, $4c, $6c, $c4, $4f, $6f, $72, $78, $48, $33, $4a, $2b, $78,
    $dc, $df, $61, $62, $4b, $6e, $29, $6a, $73, $6c, $6e, $44, $6f, $4a, $44, $66,
    $68, $44, $33, $37, $66, $55, $67, $4f, $6f, $d6, $78, $48, $33, $58, $32, $78,
    $35, $41, $61, $35, $51, $37, $6e, $2a, $f6, $6c, $2b, $fc, $6f, $4a, $23, $40);

  AN2Key: TKey = (
    $68, $3c, $61, $37, $4c, $6c, $c4, $4f, $6f, $72, $78, $48, $33, $4a, $2b, $78,
    $dc, $df, $61, $62, $4b, $6e, $29, $6a, $73, $6c, $6e, $44, $6f, $4a, $44, $66,
    $68, $44, $33, $37, $66, $55, $67, $4f, $6f, $d6, $78, $48, $33, $58, $32, $78,
    $35, $41, $61, $35, $51, $37, $6e, $2a, $f6, $6c, $2b, $fc, $6f, $4a, $23, $40);

  AM3Key: TKey = (
    $70, $4a, $4b, $6a, $33, $77, $34, $44, {07}
    $6f, $4d, $3b, $27, $44, $27, $53, $44, {15}
    $36, $64, $6b, $6e, $6c, $3d, $36, $63, {23}
    $41, $4a, $20, $53, $58, $63, $49, $41, {31}
    $21, $59, $33, $34, $35, $53, $6f, $67, {39}
    $24, $a3, $25, $53, $4e, $64, $36, $40, {47}
    $20, $58, $30, $39, $38, $61, $73, $37, {55}
    $78, $63, $41, $2a, $28, $53, $44, $7b);{63}

Procedure AN1DecryptName(Var aData: array of ansichar; szData, Num: integer);
Var k: byte;
begin
  for k:=0 to szData-1 do begin
    aData[k]:=AnsiChar(Ord(aData[k])-AN1Key[($00+Num+k) mod szKey]);
  end;
end;

Procedure AN1DecryptSize(Var aData: cardinal; Num: integer);
Var pCardinal: ^cardinal;
begin
  pCardinal:=@AN1Key[($00+Num) mod (szKey-4)];
  aData:=aData-pCardinal^;
end;

Procedure AN2DecryptName(Var aData: array of ansichar; szData, Num: integer);
Var k: byte;
begin
  for k:=0 to szData-1 do begin
    aData[k]:=AnsiChar(Ord(aData[k])-AN2Key[($3d+Num+k) mod szKey]);
  end;
end;

Procedure AN2DecryptSize(Var aData: cardinal; Num: integer);
Var pCardinal: ^cardinal;
begin
  pCardinal:=@AN2Key[($29+Num) mod (szKey-4)];
  aData:=aData-pCardinal^;
end;

// fixed by Axsis 2009.12.22
Procedure AM3DecryptName(Var aData: array of ansichar; szData, Num: integer);
Var
    InitVal: integer;
          k: byte;
begin
  InitVal:=((integer($FFFFFFE3) - ($1F * Num)) xor integer($FFFFFFE5)) and $3F;
  for k:=0 to szData-1 do
    aData[k]:=AnsiChar(Ord(aData[k])-AM3Key[(InitVal+k) mod szKey]);
end;

// fixed by Axsis 2009.12.21
Procedure AM3DecryptSize(Var aData: cardinal; Num: integer);
Var pCardinal: ^cardinal;
begin
  pCardinal:=@AM3Key[(($41+(Num*$0D)) xor $1B74) mod (szKey-4)];
  aData:=aData-pCardinal^;
end;
