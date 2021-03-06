unit uMetodos;

interface

uses System.SysUtils, System.Classes, System.Json,
  DataSnap.DSProviderDataModuleAdapter,
  DataSnap.DSServer, DataSnap.DSAuth, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, uSensores, Rtti, System.Json.Writers,
  System.Json.Types, System.Variants, System.StrUtils, IdThreadComponent,
  Data.DBXPlatform;

type
  TMetodos = class(TDSServerModule)
    IdTCPClient: TIdTCPClient;
    IdThreadAcionar: TIdThreadComponent;
    IdThreadLer: TIdThreadComponent;
    procedure IdThreadAcionarRun(Sender: TIdThreadComponent);
    procedure IdThreadLerRun(Sender: TIdThreadComponent);
  private
    { Private declarations }
  public
    { Public declarations }

    // Metodos Exemplos
    function EchoString(Value: string): string;
    function ReverseString(Value: string): string;
    function Maiuscula(Value: string): string;

    // Metodos Testes
    function LeituraTeste: Boolean;
    function SensoresTeste: string;
    function UpdateSensoresTeste(Objeto: TJSONObject): TJSONObject;
    function updateAcionamentoTeste(Objeto: TJSONObject): TJSONObject;

    // Metodos Automa??o
    // Conex?o
    function Conectar(sIP, sPorta: string): Boolean;
    function Desconectar: Boolean;
    procedure Acionar;

    // Leitura
    procedure Falha;
    function Leitura: Boolean;
    // function Sensores(Sensores: TSensores): TJsonValue;
    function updateSensores(Objeto: TJSONObject): TJSONObject;
    function updateAcionamento(Objeto: TJSONObject): TJSONObject;

  var
    RetornoXY, RetornoEd, RetornoErro: string;

    Comando: string;
    Modelo: string;
    Funcao: string;
    E1, E2, E3, E4: string;
    Valor1, status: string;
    bS1, bN1, bN2, bN3, bN4: Variant;

    Finalizado: Boolean;

    stAnt, stAtual: string;
    a, l, l2: TDateTime;

  end;

implementation

{$R *.dfm}

procedure TMetodos.Acionar;
begin
  IdTCPClient.IOHandler.Write(Comando);
end;

function TMetodos.Conectar(sIP, sPorta: string): Boolean;
begin

  IdTCPClient.Host := sIP;
  IdTCPClient.Port := StrToInt(sPorta);
  IdTCPClient.ConnectTimeout := 1000;

  try
    IdTCPClient.Connect;
    Result := True;
  except
    Result := False;
  end;
end;

function TMetodos.Desconectar: Boolean;
begin
  try
    IdTCPClient.Disconnect;
    IdTCPClient.IOHandler.InputBuffer.Clear;
    IdTCPClient.Socket.Close;
    Result := True;
  except
    Result := False;
  end;
end;

function TMetodos.EchoString(Value: string): string;
begin
  Result := Value;

end;

procedure TMetodos.Falha;
begin
  bN1 := Null;
  bN2 := Null;
  bN3 := Null;
  bN4 := Null;
  bS1 := Null;
  Valor1 := '';
  status := 'error';
end;

procedure TMetodos.IdThreadAcionarRun(Sender: TIdThreadComponent);
begin

  if IdTCPClient.Connected then
    begin
      sleep(5000);
      Acionar;
      a := now;
      IdThreadAcionar.Active := False;
      IdThreadLer.Active := True;
      IdThreadLer.Start;
    end
  else
    IdThreadAcionar.Active := False;
end;

procedure TMetodos.IdThreadLerRun(Sender: TIdThreadComponent);
begin
  Finalizado := True;
  IdThreadLer.Active := False;
end;

function TMetodos.Leitura: Boolean;
var
  ComandoRst, Modelo: string;
  RetornoRx: string;
  i, j: Integer;
  Byte_buffer: byte;
  Retorno: array [1 .. 25] of byte;
  Auxiliar: array [1 .. 21] of Char;

begin
  Falha;

  try
    if IdTCPClient.IOHandler.CheckForDataOnSource(100) then
    begin
      Byte_buffer := IdTCPClient.Socket.ReadByte();
      if Byte_buffer = Ord('<') then
      Begin
        for j := 1 to 25 do
          Retorno[j] := 0;
        j := 1;
        Retorno[j] := Byte_buffer;
      End
      else
        exit;
      repeat
      Begin
        j := j + 1;
        Retorno[j] := IdTCPClient.Socket.ReadByte();
      End;
      until (j > 18) and (Retorno[j] = Ord('>'));
    end
    else
    Begin
      IdTCPClient.IOHandler.InputBuffer.Clear;
      exit;
    End;

  except
    on e: Exception do
    Begin
      //IdTCPClient.Disconnect;
      IdTCPClient.Disconnect;
      IdTCPClient.IOHandler.InputBuffer.Clear;
      IdTCPClient.Socket.Close;
      exit;
    End;
  end;

  i := 1;
  while i <= j do
  Begin
    if (i <> 13) and (i <> 15) then
      Auxiliar[i] := Chr(Retorno[i]);
    if (i = 13) then
    Begin
      RetornoXY := 'X=' + IntToStr(Retorno[i]) + '  ';
      Auxiliar[i] := 'X';
    End;
    if (i = 15) then
    Begin
      RetornoXY := RetornoXY + 'Y=' + IntToStr(Retorno[i]);
      Auxiliar[i] := 'Y';
    End;
    i := i + 1;
  End;

  RetornoEd := Trim(String(Auxiliar));

  RetornoRx := String(Chr(Retorno[16]) + Chr(Retorno[17]) + Chr(Retorno[18]) +
    Chr(Retorno[19]) + Chr(Retorno[20]));

  // ANALIZAR BYTES NO RETORNO DE ERRO
  if RetornoRx = '99999' then
    RetornoErro := 'ERRO NO N?MERO DE S?RIE ENVIADO'
  else if RetornoRx = '00000' then
    RetornoErro := 'AGUARDANDO COMANDO COM N?MERO DE S?RIE CORRETO'
  else
    RetornoErro := '';

  Modelo := Chr(Retorno[9]) + Chr(Retorno[10]) + Chr(Retorno[11]);

  if (Modelo = '010') or (Modelo = '012') or (Modelo = '014') then
  Begin
    // ANALISANDO O STATUS DAS ENTRADAS
    if (Retorno[13] and $01) = $01 then
      // E1 := 'Ligado'
      bN1 := True
    else
      // E1 := 'Desligado';
      bN1 := False;

    if (Retorno[13] and $02) = $02 then
      // E2 := 'Ligado'
      bN2 := True
    else
      // E2 := 'Desligado';
      bN2 := False;

    if (Retorno[13] and $04) = $04 then
      // E3 := 'Ligado'
      bN3 := True
    else
      // E3 := 'Desligado';
      bN3 := False;

    if (Retorno[13] and $08) = $08 then
      // E4 := 'Ligado'
      bN4 := True
    else
      // E4 := 'Desligado';
      bN4 := False;

    // ANALISANDO O STATUS DAS SAIDAS
    if (Retorno[15] and $01) = 1 then
    Begin
      bS1 := True;
      Valor1 := '1';
    End
    else
    Begin
      bS1 := False;
      Valor1 := '0';
    End;

    status := 'success';
  End;

end;

function TMetodos.LeituraTeste: Boolean;
var
  i: Integer;
begin

  i := Random(5);

  if (i mod 2) = 0 then
    bS1 := False
  else
    bS1 := True;

  if i = 0 then
  begin
    E1 := 'Desligado';
    E2 := 'Desligado';
    E3 := 'Desligado';
    E4 := 'Desligado';

    bN1 := False;
    bN2 := False;
    bN3 := False;
    bN4 := False;
  end;

  if i = 1 then
  begin
    E1 := 'Ligado';
    E2 := 'Desligado';
    E3 := 'Desligado';
    E4 := 'Desligado';

    bN1 := True;
    bN2 := False;
    bN3 := False;
    bN4 := False;
  end;

  if i = 2 then
  begin
    E1 := 'Ligado';
    E2 := 'Ligado';
    E3 := 'Desligado';
    E4 := 'Desligado';

    bN1 := True;
    bN2 := True;
    bN3 := False;
    bN4 := False;
  end;

  if i = 3 then
  begin
    E1 := 'Ligado';
    E2 := 'Ligado';
    E3 := 'Ligado';
    E4 := 'Desligado';

    bN1 := True;
    bN2 := True;
    bN3 := True;
    bN4 := False;
  end;

  if i = 4 then
  begin
    E1 := 'Ligado';
    E2 := 'Ligado';
    E3 := 'Ligado';
    E4 := 'Ligado';

    bN1 := True;
    bN2 := True;
    bN3 := True;
    bN4 := True;
  end;

end;

function TMetodos.Maiuscula(Value: string): string;
begin
  Result := UpperCase(Value);
end;

function TMetodos.ReverseString(Value: string): string;
begin
  Result := System.StrUtils.ReverseString(Value);
end;

function TMetodos.SensoresTeste: string;
begin
  LeituraTeste;
  Result := '1:' + E1 + ';' + '2:' + E2 + ';' + '3:' + E3 + ';' + '4:'
    + E4 + ';';
end;

{
  function TMetodos.updateSensores(Objeto: TJSONObject): TJSONObject;
  begin
  Result := Objeto;
  end;
}

{
  function TMetodos.Sensores(Sensores: TSensores): TJsonValue;
  var
  Obj: TJSONObject;
  Ctx: TRttiContext;
  &Type: TRttiType;
  Prop: TRttiProperty;
  begin
  Obj := TJSONObject.Create(TJSONPair.Create('OP','Alterar'));
  Ctx := TRttiContext.Create;
  &Type := Ctx.GetType(Sensores.ClassType);

  for Prop in &Type.GetProperties do
  begin
  Obj.AddPair(Prop.Name, Prop.GetValue(Sensores).AsString)
  end;
  Result := Obj;
  end;
}

function TMetodos.updateAcionamento(Objeto: TJSONObject): TJSONObject;
var
  rsComando: Boolean;
  ID, IP, Porta, Serie, Acao: String;
  jsObj, jsRstObj, jsStObj: TJSONObject;
  jsResult: TJSONValue;
  jsArray, jsRstArray, jsStArray: TJSONArray;
  jsSub: TJSONPair;
  j, w: Integer;
begin


  //jsObj := TJSONObject.ParseJSONValue(jsArray.Get(0).ToString) as TJSONObject;

  for j := 0 to Objeto.Size - 1 do
  begin

    jsSub := Objeto.Get(j);

    if jsSub.JsonString.Value = 'board_id' then
      ID := jsSub.JsonValue.Value;

    if jsSub.JsonString.Value = 'dns_address' then
      IP := jsSub.JsonValue.Value;

    if jsSub.JsonString.Value = 'port' then
      Porta := jsSub.JsonValue.Value;

    if jsSub.JsonString.Value = 'serie' then
      Serie := jsSub.JsonValue.Value;

    if jsSub.JsonString.Value = 'pump_on' then
      begin
        if jssub.JsonValue.Value = 'true' then
          Acao := '1'
        else if jsSub.JsonValue.Value = 'false' then
          Acao := '0';
      end;
  end;

  // FORMA??O DA STRING DE COMANDO '<MTCPNSE'+Modelo+Funcao+Valor+Saida1+Saida2+Saida3+Saida4+Num_serie+'>';
  Comando := '<MTCPNSE' + // Bytes 0 a 7
    '014' + // Bytes 8, 9 e 10
    '20' + // Bytes 11 e 12
    Acao + // Byte 13
    '1' + // Byte 14
    '0' + // Byte 15
    '0' + // Byte 16
    '0' + // Byte 17
    Serie + // Bytes 18, 19, 20, 21, 22
    '>'; // Byte 23

  // ***************************
  // USANDO O COMPONENTE TCPIP
  // ***************************

  a := 0;
  l := 0;
  l := 0;

  try

    if Conectar(IP, Porta) then
    begin

      IdThreadAcionar.Active := True;
      IdThreadAcionar.Start;

      Finalizado := False;
      w := 0;
      while not Finalizado do
        begin
          rsComando := False;
          inc(w);
        end;

      rsComando := True;
      Desconectar;
    end
    else
    begin
      Falha;
      rsComando := False;
    end;
  except
    Falha;
    rsComando := False;
  end;

  sleep(5000);
  if Conectar(IP, Porta) then
    begin
      Leitura;
      Desconectar;
    end
  else
      Falha;

  Result := TJSONObject.Create;
  jsRstObj := TJSONObject.Create;
  jsRstObj.AddPair('board_id', TJSONNumber.Create(StrToInt(ID)));

  if bN1 = Null then
    jsRstObj.AddPair('level_1', '')
  else
    jsRstObj.AddPair('level_1', TJSONBool.Create(bN1));

  if bN2 = Null then
    jsRstObj.AddPair('level_2', '')
  else
    jsRstObj.AddPair('level_2', TJSONBool.Create(bN2));

  if bN3 = Null then
    jsRstObj.AddPair('level_3', '')
  else
    jsRstObj.AddPair('level_3', TJSONBool.Create(bN3));

  if bN4 = Null then
    jsRstObj.AddPair('level_4', '')
  else
    jsRstObj.AddPair('level_4', TJSONBool.Create(bN4));

  if bS1 = Null then
    jsRstObj.AddPair('pump_on', '')
  else
    jsRstObj.AddPair('pump_on', TJSONBool.Create(bS1));

  jsRstObj.AddPair('status', status);
  Result := jsRstObj;


end;

function TMetodos.updateAcionamentoTeste(Objeto: TJSONObject): TJSONObject;
var
  rsComando: Boolean;
  ID, IP, Porta, Serie, Acao: String;
  jsRstObj: TJSONObject;
  jsResult: TJSONValue;
  jsArray, jsRstArray, jsStArray: TJSONArray;
  jsSub: TJSONPair;
  j, w: Integer;
begin

  for j := 0 to Objeto.Size - 1 do
  begin

    jsSub := Objeto.Get(j);

    if jsSub.JsonString.Value = 'board_id' then
      ID := jsSub.JsonValue.Value;

    if jsSub.JsonString.Value = 'dns_address' then
      IP := jsSub.JsonValue.Value;

    if jsSub.JsonString.Value = 'port' then
      Porta := jsSub.JsonValue.Value;

    if jsSub.JsonString.Value = 'serie' then
      Serie := jsSub.JsonValue.Value;

    if jsSub.JsonString.Value = 'pump_on' then
      Acao := jsSub.JsonValue.Value;
  end;

  LeituraTeste;
  if Acao = 'true' then
    bS1 := True
  else
    bS1 := False;


  Result := TJSONObject.Create;

  jsRstObj := TJSONObject.Create;
  jsRstObj.AddPair('board_id', TJSONNumber.Create(StrToInt(ID)));

  if bN1 = Null then
    jsRstObj.AddPair('level_1', '')
  else
    jsRstObj.AddPair('level_1', TJSONBool.Create(bN1));

  if bN2 = Null then
    jsRstObj.AddPair('level_2', '')
  else
    jsRstObj.AddPair('level_2', TJSONBool.Create(bN2));

  if bN3 = Null then
    jsRstObj.AddPair('level_3', '')
  else
    jsRstObj.AddPair('level_3', TJSONBool.Create(bN3));

  if bN4 = Null then
    jsRstObj.AddPair('level_4', '')
  else
    jsRstObj.AddPair('level_4', TJSONBool.Create(bN4));

  if bS1 = Null then
    jsRstObj.AddPair('pump_on', '')
  else
    jsRstObj.AddPair('pump_on', TJSONBool.Create(bS1));

  jsRstObj.AddPair('status', status);
  Result := jsRstObj;

end;

function TMetodos.updateSensores(Objeto: TJSONObject): TJSONObject;
var
  jsObj, jsRstObj: TJSONObject;
  jsSub: TJSONPair;
  ID, IP, Porta: String;

  i, j: Integer;

begin

  Result := TJSONObject.Create;

  for j := 0 to Objeto.Size - 1 do
  begin

    jsSub := Objeto.Get(j);

    if jsSub.JsonString.Value = 'board_id' then
      ID := jsSub.JsonValue.Value;

    if jsSub.JsonString.Value = 'dns_address' then
      IP := jsSub.JsonValue.Value;

    if jsSub.JsonString.Value = 'port' then
      Porta := jsSub.JsonValue.Value;

  end;

  if Conectar(IP, Porta) then
  begin
    Leitura;
    Desconectar;
  end
  else
    Falha;

  jsRstObj := TJSONObject.Create;
  jsRstObj.AddPair('board_id', TJSONNumber.Create(StrToInt(ID)));

  if bN1 = Null then
    jsRstObj.AddPair('level_1', '')
  else
    jsRstObj.AddPair('level_1', TJSONBool.Create(bN1));

  if bN2 = Null then
    jsRstObj.AddPair('level_2', '')
  else
    jsRstObj.AddPair('level_2', TJSONBool.Create(bN2));

  if bN3 = Null then
    jsRstObj.AddPair('level_3', '')
  else
    jsRstObj.AddPair('level_3', TJSONBool.Create(bN3));

  if bN4 = Null then
    jsRstObj.AddPair('level_4', '')
  else
    jsRstObj.AddPair('level_4', TJSONBool.Create(bN4));

  if bS1 = Null then
    jsRstObj.AddPair('pump_on', '')
  else
    jsRstObj.AddPair('pump_on', TJSONBool.Create(bS1));

  jsRstObj.AddPair('status', status);
  Result := jsRstObj;

end;

function TMetodos.UpdateSensoresTeste(Objeto: TJSONObject): TJSONObject;
var
  jsRstObj: TJSONObject;
  jsResult: TJSONValue;
  jsSub: TJSONPair;
  ID, IP, Porta: String;
  i, j: Integer;

begin

  Result := TJSONObject.Create;

  for j := 0 to Objeto.Size - 1 do
  begin

    jsSub := Objeto.Get(j);

    if jsSub.JsonString.Value = 'board_id' then
      ID := jsSub.JsonValue.Value;

    if jsSub.JsonString.Value = 'dns_address' then
      IP := jsSub.JsonValue.Value;

    if jsSub.JsonString.Value = 'port' then
      Porta := jsSub.JsonValue.Value;

  end;

  LeituraTeste;

  jsRstObj := TJSONObject.Create;
  jsRstObj.AddPair('board_id', TJSONNumber.Create(StrToInt(ID)));

  if bN1 = Null then
    jsRstObj.AddPair('level_1', '')
  else
    jsRstObj.AddPair('level_1', TJSONBool.Create(bN1));

  if bN2 = Null then
    jsRstObj.AddPair('level_2', '')
  else
    jsRstObj.AddPair('level_2', TJSONBool.Create(bN2));

  if bN3 = Null then
    jsRstObj.AddPair('level_3', '')
  else
    jsRstObj.AddPair('level_3', TJSONBool.Create(bN3));

  if bN4 = Null then
    jsRstObj.AddPair('level_4', '')
  else
    jsRstObj.AddPair('level_4', TJSONBool.Create(bN4));

  if bS1 = Null then
    jsRstObj.AddPair('pump_on', '')
  else
    jsRstObj.AddPair('pump_on', TJSONBool.Create(bS1));

  jsRstObj.AddPair('status', status);
  Result := jsRstObj;

end;

end.
