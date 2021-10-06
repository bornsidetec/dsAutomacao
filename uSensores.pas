unit uSensores;

interface

Type
  TSensores = class
  private
    FID: integer;
    FSerie: string;
    FPorta: string;
    FIP: string;

    procedure SetID(const Value: integer);
    procedure SetIP(const Value: string);
    procedure SetPorta(const Value: string);
    procedure SetSerie(const Value: string);
  published
    property ID: integer read FID write SetID;
    property IP: string read FIP write SetIP;
    property Porta: string read FPorta write SetPorta;
    property Serie: string read FSerie write SetSerie;
  end;

implementation

{ TSensores }

procedure TSensores.SetID(const Value: integer);
begin
  FID := Value;
end;

procedure TSensores.SetIP(const Value: string);
begin
  FIP := Value;
end;

procedure TSensores.SetPorta(const Value: string);
begin
  FPorta := Value;
end;

procedure TSensores.SetSerie(const Value: string);
begin
  FSerie := Value;
end;

end.
