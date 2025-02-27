unit CustomGrid.Grid;

interface

uses
  System.Generics.Collections, Vcl.Forms, CustomGrid.Row, CustomGrid.Types,
  Winapi.Windows, System.Classes;

type

  TCustomGrid = class
  private
    FItens: TListItens;
    FRows: TObjectList<TRow>;
    FContainer: TScrollBox;
    FRowHeight: Integer;
    FItensProps: TItemProps;
    FhasItemPropsLoad: Boolean;
    FLoadingScreen: TForm;
    FSettingUpLoading: Boolean;
    FEnable: Boolean;
    FLargeItens: Boolean;
    FGridRowStyle: TGridRowStyle;
    FShowScrollBars: Boolean;
    FAutoReleaseItens: Boolean;
    procedure ContainerMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
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
    procedure RenderColumMode;
    procedure RenderInLineMode;
    procedure CreateInColumRows;
    procedure CreateInLineRows;
    procedure ConfigureScrollBars;
    function RowWidth: Integer;
    function RowHeigth: Integer;
    procedure InitializeComponent;
  public
    constructor Create(AContainer: TScrollBox); overload;
    constructor Create(AContainer: TScrollBox;
      AutoReleaseItens: Boolean); overload;
    destructor Destroy; override;
    procedure AddItem(AItem: TFrame);
    procedure RemoveItem(AItem: TFrame);
    procedure Close;
    procedure Clear;
    procedure Render;
    function Itens: TListItens;
    property Visible: Boolean read GetVisbile write SetVisible;
    property LoadingScreen: TForm read FLoadingScreen write FLoadingScreen;
    property Count: Integer read GetCount;
    property Enable: Boolean read FEnable write FEnable;
    property LargeItens: Boolean read FLargeItens write FLargeItens;
    property GridRowStyle: TGridRowStyle read FGridRowStyle write FGridRowStyle;
    property ShowScrollBars: Boolean read FShowScrollBars write FShowScrollBars;
    property AutoReleaseItens: Boolean read FAutoReleaseItens
      write FAutoReleaseItens;
  end;

implementation

uses
  System.Math, System.SysUtils, Vcl.Controls;

{ TGrid }

procedure TCustomGrid.AddItem(AItem: TFrame);
begin
  if LargeItens then
    AItem.Width := FContainer.Width;

  FItens.Add(AItem);
end;

procedure TCustomGrid.Clear;
begin
  if FItens.Count = 0 then
    Exit;

  StartLoading;
  Application.ProcessMessages;

  ClearRows;
  FItens.Clear;

  Application.ProcessMessages;
  StopLoading;
end;

procedure TCustomGrid.ClearRows;
begin
  RemoverItensParents;
  FRows.Clear;
end;

procedure TCustomGrid.Close;
begin
  Enable := False;
end;

procedure TCustomGrid.ConfigureScrollBars;
begin

  // Controlar visibilidade das barras
  if not ShowScrollBars then
  begin
    FContainer.HorzScrollBar.Visible := False;
    FContainer.VertScrollBar.Visible := False;
  end
  else
  begin
    FContainer.HorzScrollBar.Visible := RowWidth > FContainer.ClientWidth;
    FContainer.VertScrollBar.Visible := RowHeigth > FContainer.ClientHeight;
  end;

  // Configurar os ranges das barras de rolagem
  if FGridRowStyle = gsInLine then
    FContainer.HorzScrollBar.Range := RowWidth
  else
    FContainer.VertScrollBar.Range := RowHeigth;
end;

procedure TCustomGrid.ContainerMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  // Shift pressionado = scroll horizontal
  if FGridRowStyle = gsInLine then
  begin
    if WheelDelta > 0 then
      FContainer.HorzScrollBar.Position :=
        FContainer.HorzScrollBar.Position - 20
    else
      FContainer.HorzScrollBar.Position :=
        FContainer.HorzScrollBar.Position + 20;
  end
  else // Sem Shift = scroll vertical
  begin
    if WheelDelta > 0 then
      FContainer.VertScrollBar.Position :=
        FContainer.VertScrollBar.Position - 20
    else
      FContainer.VertScrollBar.Position :=
        FContainer.VertScrollBar.Position + 20;
  end;

  Handled := True; // Indica que o evento foi tratado
end;

constructor TCustomGrid.Create(AContainer: TScrollBox);
begin
  FContainer := AContainer;
  FContainer.OnMouseWheel := ContainerMouseWheel;

  FItens := TListItens.Create(True);
  FRows := TObjectList<TRow>.Create(True);

  InitializeComponent;
end;

procedure TCustomGrid.CreateInLineRows;
begin
  FRows.Add(GetNewRow);
  FContainer.InsertControl(FRows.First.Row);
end;

procedure TCustomGrid.CreateNescessariesRows;
begin
  case FGridRowStyle of
    gsInLine:
      CreateInLineRows;
    gsInColum:
      CreateInColumRows;
  end;
end;

constructor TCustomGrid.Create(AContainer: TScrollBox;
  AutoReleaseItens: Boolean);
begin
  FContainer := AContainer;
  FContainer.OnMouseWheel := ContainerMouseWheel;

  FItens := TListItens.Create(AutoReleaseItens);
  FRows := TObjectList<TRow>.Create(True);

  FAutoReleaseItens := AutoReleaseItens;
  InitializeComponent;
end;

procedure TCustomGrid.CreateInColumRows;
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

destructor TCustomGrid.Destroy;
begin
  inherited;

  ClearRows;

  FItens.Free;
  FRows.Free;

  if Assigned(FLoadingScreen) then
    FLoadingScreen.Free;
end;

function TCustomGrid.GetCount: Integer;
begin
  Result := FItens.Count;
end;

function TCustomGrid.GetVisbile: Boolean;
begin
  Result := FContainer.Visible;
end;

function TCustomGrid.GetNewRow: TRow;
begin
  if FRowHeight = 0 then
    FRowHeight := FItens[0].Height;

  Result := TRow.Create(FContainer, FRowHeight);
end;

function TCustomGrid.RowWidth: Integer;
begin
  with FItens.First do
  begin
    Result := FItens.Count * (Width + Margins.Left + Margins.Right);
  end;
end;

procedure TCustomGrid.InitializeComponent;
begin
  FhasItemPropsLoad := False;
  FLoadingScreen := nil;
  FEnable := True;
  FLargeItens := False;
  FGridRowStyle := gsInColum;
  FShowScrollBars := True;
end;

function TCustomGrid.Itens: TListItens;
begin
  Result := FItens;
end;

function TCustomGrid.ItensPerRow: Integer;
var
  FItemSize, FQuant: Integer;
begin
  FItemSize := FItens[0].Width + FItens[0].Margins.Right + FItens[0]
    .Margins.Left;

  // BUG HERE -- Aqui possui um bug de quando o item tem o size maior que o container
  Result := Floor(FContainer.Width / FItemSize);

end;

procedure TCustomGrid.StartLoading;
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
      WindowState := wsMaximized;
    end;
    FSettingUpLoading := True;
  end;

  FLoadingScreen.Show;
end;

procedure TCustomGrid.StopLoading;
begin
  Visible := True;

  if Assigned(FLoadingScreen) then
    FLoadingScreen.Close;
end;

procedure TCustomGrid.LoadItemProps;
var
  NescessarieWidth, AvailableSize, MarginForItem, MarginForSide,
    NumItens: Integer;
begin

  if FhasItemPropsLoad then
    Exit;

  if not LargeItens then
  begin
    NumItens := ItensPerRow;

    NescessarieWidth := Floor(FItens[0].Width * NumItens);
    AvailableSize := FContainer.Width - NescessarieWidth;
    MarginForItem := Floor(AvailableSize / NumItens);
    MarginForSide := Floor(MarginForItem / 2);

    FItensProps.MarginLeft := MarginForSide;
    FItensProps.MarginRight := MarginForSide;
  end
  else
  begin
    FItensProps.MarginLeft := FItens[0].Margins.Left;
    FItensProps.MarginRight := FItens[0].Margins.Right;
  end;

  FhasItemPropsLoad := True;
end;

procedure TCustomGrid.OrganizeContainer;
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

procedure TCustomGrid.RemoveItem(AItem: TFrame);
begin
  if FItens.Contains(AItem) then
    FItens.Remove(AItem);
end;

procedure TCustomGrid.RemoverItensParents;
var
  I: Integer;
begin
  for I := 0 to FItens.Count - 1 do
    FItens[I].Parent := nil;
end;

procedure TCustomGrid.Render;

begin

  if not(Enable) or (FItens.Count = 0) then
    Exit;

  StartLoading;
  Application.ProcessMessages;

  ClearRows;
  CreateNescessariesRows;
  LoadItemProps;

  case FGridRowStyle of
    gsInLine:
      RenderInLineMode;

    gsInColum:
      RenderColumMode;
  end;

  ConfigureScrollBars;

  Application.ProcessMessages;
  StopLoading;
end;

procedure TCustomGrid.RenderInLineMode;
var
  I: Integer;
begin
  for I := 0 to FItens.Count - 1 do
  begin
    FRows.First.AddItem(FItens[I], FItensProps);
  end;
end;

procedure TCustomGrid.RenderColumMode;
var
  I, StartIndex, EndIndex, NumItens, TotalItems: Integer;
  X: Integer;
begin
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
end;

function TCustomGrid.RowHeigth: Integer;
begin
  With FRows.First.Row do
  begin
    Result := FRows.Count * Height;
  end;
end;

function TCustomGrid.RownsNeeded: Integer;
begin
  Result := Ceil(FItens.Count / ItensPerRow);
end;

procedure TCustomGrid.SetVisible(const Value: Boolean);
begin
  FContainer.Visible := Value;
end;

end.
