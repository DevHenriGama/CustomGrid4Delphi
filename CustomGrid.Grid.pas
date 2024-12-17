unit CustomGrid.Grid;

interface

uses
  System.Generics.Collections, Vcl.Forms, CustomGrid.Row;

type
  TListItens = TList<TFrame>;

  TGrid = class
  private
    FCount: Integer;
    FItens: TListItens;
    FRows: TList<TRow>;
    FContainer: TScrollBox;
    FRowHeight: Integer;
    FAutoSize: Boolean;
    FItensProps: TItemProps;
    FhasItemPropsLoad: Boolean;
    FLazyLoading: Boolean;
    FLoadingScreen: TForm;
    FSettingUpLoading: Boolean;
    function ItensPerRow: Integer;
    function RownsNeeded: Integer;
    function GetNextRowAvailable: TRow;
    procedure ClearItens;
    procedure ClearRows;
    procedure ClearInvalidItens;

    function GetNewRow: TRow;
    procedure CreateNescessariesRows;
    procedure OrganizeContainer;
    procedure ClearEmptyRows;
    procedure LoadItemProps;
    procedure StartLoading;
    procedure StopLoading;
    function GetVisbile: Boolean;
    procedure SetVisible(const Value: Boolean);
  public
    constructor Create(AContainer: TScrollBox);
    destructor Destroy; override;
    procedure AddItem(AItem: TFrame);
    procedure AddListItem(AList: TListItens);
    procedure Render;
    property AutoSize: Boolean read FAutoSize write FAutoSize;
    property LazyLoading: Boolean read FLazyLoading write FLazyLoading;
    property Visible: Boolean read GetVisbile write SetVisible;
    property LoadingScreen: TForm read FLoadingScreen write FLoadingScreen;
  end;

implementation

uses
  System.Math, System.SysUtils, Vcl.Controls;

{ TGrid }

procedure TGrid.AddItem(AItem: TFrame);
begin
  FItens.Add(AItem);
end;

procedure TGrid.AddListItem(AList: TListItens);
begin
  FItens := AList;
end;

procedure TGrid.ClearEmptyRows;
var
  I: Integer;
  FEmptyRow: TRow;
begin
  if FRows.Count = 0 then
    Exit;

  for I := 0 to FRows.Count - 1 do
  begin
    if FRows[I].isEmpty then
    begin
      FEmptyRow := FRows[I];
      FRows.Remove(FEmptyRow);
      FEmptyRow.Free;
    end;

  end;

end;

procedure TGrid.ClearInvalidItens;
var
  I: Integer;
begin
  for I := 0 to FItens.Count - 1 do
  begin
    if not Assigned(FItens[I]) then
      FItens.Remove(FItens[I]);
  end;
end;

procedure TGrid.ClearItens;
var
  I: Integer;
begin
  for I := 0 to FItens.Count - 1 do
  begin
    if Assigned(FItens[I]) then
      FItens[I].Free
  end;

  FItens.Clear;
end;

procedure TGrid.ClearRows;
var
  I: Integer;
begin

  if FRows.Count = 0 then
    Exit;

  for I := 0 to FRows.Count - 1 do
  begin
    if Assigned(FRows[I]) then
    BEGIN
      FRows[I].Free;
    END;
  end;

  FRows.Clear;

end;

constructor TGrid.Create(AContainer: TScrollBox);
begin
  FContainer := AContainer;
  FItens := TListItens.Create;
  FRows := TList<TRow>.Create;

  FAutoSize := False;
  FLazyLoading := False;
  FhasItemPropsLoad := False;
  FLoadingScreen := nil;
end;

procedure TGrid.CreateNescessariesRows;
var
  RowsToAdd, I: Integer;
  FRow: TRow;
begin
  if FRows.Count < RownsNeeded then
  begin
    RowsToAdd := RownsNeeded - FRows.Count;
    for I := 1 to RowsToAdd do
    begin
      FRow := GetNewRow;

      FRows.Add(FRow);

      FContainer.InsertControl(FRow.Row);

      if not LazyLoading then
        OrganizeContainer;

    end;
  end;
end;

destructor TGrid.Destroy;
begin
  inherited;
  ClearItens;
  ClearRows;
  FItens.Free;
  FRows.Free;

  if Assigned(FLoadingScreen) then
    FLoadingScreen.Free;
end;

function TGrid.GetNextRowAvailable: TRow;
var
  I: Integer;
begin
  if not AutoSize then
  begin
    Result := FRows.Last;
  end
  else
  begin
    for I := 0 to FRows.Count - 1 do
    begin
      if FRows[I].CanAddItem(FItens.Last) then

        Result := FRows[I]
      else
        FRows[I].AutoSize;
    end;
  end;
end;

function TGrid.GetVisbile: Boolean;
begin
  Result := FContainer.Visible;
end;

function TGrid.GetNewRow: TRow;
begin
  if FRowHeight = 0 then
    FRowHeight := FItens[0].Height;

  Result := TRow.Create(FContainer, FRowHeight);
end;

function TGrid.ItensPerRow: Integer;
var
  FItemSize, FQuant: Integer;
begin
  FItemSize := FItens[0].Width + FItens[0].Margins.Right + FItens[0]
    .Margins.Left;

  Result := Floor(FContainer.Width / FItemSize);

end;

procedure TGrid.StartLoading;
begin
  if not Assigned(FLoadingScreen) then
    Exit;

  if not FSettingUpLoading then
  begin
    with FLoadingScreen do
    begin
      BorderStyle := bsNone;
      Caption := 'Loading...';
      Left := FContainer.Left;
      Top := FContainer.Top;
      Width := FContainer.Width;
      Height := FContainer.Height;
    end;

    FSettingUpLoading := True;
  end;

  FLoadingScreen.Show;
end;

procedure TGrid.StopLoading;
begin
  if Assigned(FLoadingScreen) then
    FLoadingScreen.Close;
end;

procedure TGrid.LoadItemProps;
var
  NescessarieWidth, AvailableSize, MarginForItem, MarginForSide,
    NumItens: Integer;
begin

  if AutoSize and FhasItemPropsLoad then
    Exit;

  NumItens := ItensPerRow;

  NescessarieWidth := Floor(FItens[0].Width * NumItens);
  AvailableSize := FContainer.Width - NescessarieWidth;
  MarginForItem := Floor(AvailableSize / NumItens);
  MarginForSide := Floor(MarginForItem / 2);
  FItensProps.MarginLeft := MarginForSide;
  FItensProps.MarginRight := MarginForSide;

  FhasItemPropsLoad := True;
end;

procedure TGrid.OrganizeContainer;
var
  I: Integer;

begin
  if FRows.Count = 1 then
    Exit;

  for I := 0 to FRows.Count - 1 do
  begin
    FRows[I].Row.Visible := False;
    FRows[I].Row.Align := alNone;
  end;

  for I := FRows.Count - 1 downto 0 do
  begin
    FRows[I].Row.Visible := True;
    FRows[I].Row.Align := alTop;
  end;

end;

procedure TGrid.Render;
var
  I, StartIndex, EndIndex, NumItens, TotalItems: Integer;
  X: Integer;
begin
  StartLoading;
  Application.ProcessMessages;
  Visible := False;

  ClearInvalidItens;
  ClearRows;
  CreateNescessariesRows;
  LoadItemProps;

  NumItens := ItensPerRow;
  TotalItems := FItens.Count;

  for I := 0 to FRows.Count - 1 do
  begin
    StartIndex := I * NumItens; // �ndice inicial da parte
    EndIndex := StartIndex + NumItens - 1; // �ndice final da parte

    // Ajusta o EndIndex se ultrapassar o n�mero total de itens
    if EndIndex >= TotalItems then
      EndIndex := TotalItems - 1;

    // Se o �ndice inicial for maior que o n�mero total de itens, interrompe
    if StartIndex >= TotalItems then
      Break;

    // Extrai a parte dos itens para a linha atual
    for X := StartIndex to EndIndex do
    begin
      FRows[I].AddItem(FItens[X], FItensProps);
    end;
  end;

  Visible := True;
  Application.ProcessMessages;
  StopLoading;
end;

function TGrid.RownsNeeded: Integer;
begin
  Result := Ceil(FItens.Count / ItensPerRow);
end;

procedure TGrid.SetVisible(const Value: Boolean);
begin
  FContainer.Visible := Value;
end;

end.
