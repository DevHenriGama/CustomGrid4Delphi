unit CustomGrid.Grid;

interface

uses
  System.Generics.Collections, Vcl.Forms, CustomGrid.Row, CustomGrid.Types;

type

  TGrid = class
  private
    FItens: TListItens;
    FRows: TObjectList<TRow>;
    FContainer: TScrollBox;
    FRowHeight: Integer;
    FAutoSize: Boolean;
    FItensProps: TItemProps;
    FhasItemPropsLoad: Boolean;
    FLazyLoading: Boolean;
    FLoadingScreen: TForm;
    FSettingUpLoading: Boolean;
    FEnable: Boolean;
    function ItensPerRow: Integer;
    function RownsNeeded: Integer;
    function GetNewRow: TRow;
    procedure CreateNescessariesRows;
    procedure OrganizeContainer;
    procedure LoadItemProps;
    procedure StartLoading;
    procedure StopLoading;
    function GetVisbile: Boolean;
    procedure SetVisible(const Value: Boolean);
    function GetCount: Integer;
    procedure RemoverItensParents;
    procedure ClearRows;
  public
    constructor Create(AContainer: TScrollBox);
    destructor Destroy; override;
    procedure AddItem(AItem: TFrame);
    procedure Clear;
    procedure Render;
    property Visible: Boolean read GetVisbile write SetVisible;
    property LoadingScreen: TForm read FLoadingScreen write FLoadingScreen;
    property Count: Integer read GetCount;
    property Enable: Boolean read FEnable write FEnable;
    procedure Close;

  end;

implementation

uses
  System.Math, System.SysUtils, Vcl.Controls;

{ TGrid }

procedure TGrid.AddItem(AItem: TFrame);
begin
  FItens.Add(AItem);
end;

procedure TGrid.Clear;
begin
  StartLoading;
  Application.ProcessMessages;

  ClearRows;
  FItens.Clear;

  Application.ProcessMessages;
  StopLoading;
end;

procedure TGrid.ClearRows;
begin
  RemoverItensParents;
  FRows.Clear;
end;

procedure TGrid.Close;
begin
  Enable := False;
end;

constructor TGrid.Create(AContainer: TScrollBox);
begin
  FContainer := AContainer;

  FItens := TListItens.Create(True);
  FRows := TObjectList<TRow>.Create(True);

  FhasItemPropsLoad := False;
  FLoadingScreen := nil;
  FEnable := True;
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

    end;

    OrganizeContainer;
  end;
end;

destructor TGrid.Destroy;
begin
  inherited;

  ClearRows;

  FItens.Free;
  FRows.Free;

  if Assigned(FLoadingScreen) then
    FLoadingScreen.Free;
end;

function TGrid.GetCount: Integer;
begin
  Result := FItens.Count;
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
  // Desabilita o Container
  Visible := False;

  if not Assigned(FLoadingScreen) then
    Exit;

  // Configura o LoadingScreen
  if not FSettingUpLoading then
  begin
    with FLoadingScreen do
    begin
      BorderStyle := bsNone;
      Caption := 'Loading...';
    end;
    FSettingUpLoading := True;
  end;

  with FLoadingScreen do
  begin
    Left := FContainer.Left;
    Top := FContainer.Top;
    Width := FContainer.Width;
    Height := FContainer.Height;
  end;

  FLoadingScreen.Show;
end;

procedure TGrid.StopLoading;
begin
  Visible := True;

  if Assigned(FLoadingScreen) then
    FLoadingScreen.Close;
end;

procedure TGrid.LoadItemProps;
var
  NescessarieWidth, AvailableSize, MarginForItem, MarginForSide,
    NumItens: Integer;
begin

  if FhasItemPropsLoad then
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

procedure TGrid.RemoverItensParents;
var
  I: Integer;
begin
  for I := 0 to FItens.Count - 1 do
    FItens[I].Parent := nil;
end;

procedure TGrid.Render;
var
  I, StartIndex, EndIndex, NumItens, TotalItems: Integer;
  X: Integer;
begin

  if not Enable then
    Exit;

  StartLoading;
  Application.ProcessMessages;

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
