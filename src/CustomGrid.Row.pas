unit CustomGrid.Row;

interface

uses
  System.Generics.Collections, Vcl.Forms, Vcl.ExtCtrls, System.Classes,
  CustomGrid.Types;

type
  TItemProps = record
    MarginLeft, MarginRight: Integer;
  end;

  TRow = class
  private
    FRow: TPanel;
    procedure Initialize;
  public
    constructor Create(AContainer: TScrollBox; AHeight: Integer);
    destructor Destroy; override;
    function Row: TPanel;
    function AddItem(AItem: TFrame; AProps: TItemProps): Boolean;
  end;

implementation

uses
  Vcl.Controls, System.SysUtils, Math, Vcl.Dialogs;

{ TRow }

function TRow.AddItem(AItem: TFrame; AProps: TItemProps): Boolean;
begin
  AItem.Margins.Left := AProps.MarginLeft;
  AItem.Margins.Right := AProps.MarginRight;

  AItem.Parent := FRow;
end;

constructor TRow.Create(AContainer: TScrollBox; AHeight: Integer);
begin
  FRow := TPanel.Create(nil);
  FRow.Height := AHeight;
  Initialize;
end;

destructor TRow.Destroy;
begin
  inherited;
  FRow.Free;
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
end;

function TRow.Row: TPanel;
begin
  Result := FRow;
end;

end.
