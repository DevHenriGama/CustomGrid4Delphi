unit CustomGrid.Row;

interface

uses
  System.Generics.Collections, Vcl.Forms, Vcl.ExtCtrls, System.Classes;

type
  TItemProps = record
    MarginLeft, MarginRight: Integer;
  end;

  TRow = class
  private
    FItems: TList<TFrame>;
    FRow: TPanel;
    FContainer: TScrollBox;
    FHeight: Integer;
    FWasAutoSized: Boolean;
    FItemProps: TItemProps;

  const
    MinMargin: Integer = 5;

    procedure Debug;
    procedure Initialize;
    function ItemWidth(AItem: TFrame;
      const AWithMargins: Boolean = False): Integer;
    function MinItemWidth: Integer;
    function hasInRow(AItem: TFrame): Boolean;
    procedure RenderRow;
  public
    constructor Create(AContainer: TScrollBox; AHeight: Integer);
    destructor Destroy; override;
    function Row: TPanel;
    function AddItem(AItem: TFrame): Boolean; overload;
    function AddItem(AItem: TFrame; AProps: TItemProps): Boolean; overload;
    function CanAddItem(AItem: TFrame): Boolean; overload;
    function CanAddItem: Boolean; overload;
    function SizeAvailable: Integer;
    function isEmpty: Boolean;
    procedure AutoSize();
    procedure Clear;
    property WasAutoSized: Boolean read FWasAutoSized write FWasAutoSized;
    property ItemProps: TItemProps read FItemProps write FItemProps;

  end;

implementation

uses
  Vcl.Controls, System.SysUtils, Math, Vcl.Dialogs;

{ TRow }

function TRow.AddItem(AItem: TFrame): Boolean;
begin
  Result := False;

  if not CanAddItem(AItem) then
    Exit;

  FItems.Add(AItem);
  AItem.Parent := FRow;
  Result := True;

end;

function TRow.AddItem(AItem: TFrame; AProps: TItemProps): Boolean;
begin
  Result := AddItem(AItem);

  if Result and not WasAutoSized then
  begin
    FItemProps := AProps;
    AItem.Margins.Left := AProps.MarginLeft;
    AItem.Margins.Right := AProps.MarginRight;
  end;

end;

procedure TRow.AutoSize;
var
  I, FMargin: Integer;
  FMarginForEach, FMarginSide: Double;
begin
  if FItems.Count = 0 then
    Exit;

  if FWasAutoSized then
    Exit;

  for I := 0 to FItems.Count - 1 do
  begin
    FItems[I].Margins.Left := 0;
    FItems[I].Margins.Right := 0;
  end;

  FMarginForEach := SizeAvailable / FItems.Count;

  FMarginSide := (FMarginForEach / 2);
  FMargin := Floor(FMarginSide);

  for I := 0 to FItems.Count - 1 do
  begin
    FItems[I].Margins.Left := FMargin;
    FItems[I].Margins.Right := FMargin;
  end;

  FWasAutoSized := True;
end;

function TRow.CanAddItem(AItem: TFrame): Boolean;
begin
  Result := False;

  if hasInRow(AItem) then
    Exit;

  Result := SizeAvailable > ItemWidth(AItem);

end;

function TRow.CanAddItem: Boolean;
begin
  Result := True;

  if FItems.Count > 0 then
    Result := SizeAvailable > ItemWidth(FItems[0], True);
end;

procedure TRow.Clear;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
  begin
    if Assigned(FItems[I]) then
      FItems[I].Parent := nil;
  end;

  FItems.Clear;
end;

constructor TRow.Create(AContainer: TScrollBox; AHeight: Integer);
begin
  FRow := TPanel.Create(nil);
  FRow.Height := AHeight;

  FItems := TList<TFrame>.Create;
  FContainer := AContainer;

  Initialize;
end;

procedure TRow.Debug;
begin

end;

destructor TRow.Destroy;
begin
  Clear;
  FItems.Free;
  FRow.Free;
  inherited;
end;

function TRow.hasInRow(AItem: TFrame): Boolean;
begin
  Result := FItems.Contains(AItem);
end;

procedure TRow.Initialize;
begin
  with FRow do
  begin
    Align := alTop;
    Margins.Top := 10;
    Margins.Bottom := 10;
    BevelOuter := bvNone;
    ParentBackground := True;
    FullRepaint := False;
  end;
  FWasAutoSized := False;
end;

function TRow.isEmpty: Boolean;
begin
  Result := SizeAvailable = FContainer.Width;
end;

function TRow.ItemWidth(AItem: TFrame;
  const AWithMargins: Boolean = False): Integer;
begin
  Result := AItem.Width;

  if AWithMargins then
    Result := Result + +AItem.Margins.Right + AItem.Margins.Left;
end;

function TRow.MinItemWidth: Integer;
var
  FMinMargin: Integer;
  FMarginItem: Integer;
  FFinalMargin: Integer;
begin
  FMarginItem := FItems[0].Margins.Left + FItems[0].Margins.Right;
  FMinMargin := Floor(FMarginItem / 4);

  if FMinMargin > MinMargin then
    FFinalMargin := MinMargin
  else
    FFinalMargin := FMinMargin;

  Result := ItemWidth(FItems[0]) + (FFinalMargin * 2);
end;

procedure TRow.RenderRow;
var
  I: Integer;
begin
  for I := FItems.Count - 1 downto 0 do
    FItems[I].Parent := FRow;
end;

function TRow.Row: TPanel;
begin
  Result := FRow;
end;

function TRow.SizeAvailable: Integer;
begin
  Result := FRow.Width;

  if FItems.Count = 0 then
    Exit;

  Result := FRow.Width - (ItemWidth(FItems[0], True) * FItems.Count);
end;

end.
