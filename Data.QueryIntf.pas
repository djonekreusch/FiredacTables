{***************************************************************************}
{                                                                           }
{                                                                           }
{           Copyright (C) Amarildo Lacerda                                  }
{                                                                           }
{           https://github.com/amarildolacerda                              }
{                                                                           }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}


{
  Altera��es:
      25/03/16 - Primeira vers�o publicada - Constru��o
}

unit Data.QueryIntf;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  System.Rtti, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Stan.ExprFuncs,
  {FireDAC.Phys.SQLiteDef,} FireDAC.Comp.UI,
  FireDAC.Phys.SQLite, Data.DB, FireDAC.Comp.Client;

type

  IQuery = interface;
  TQueryIntf = class;

  TDataStorageRec = record
    class function NewQuery(const Conn:TFDCustomConnection): IQuery; overload; static;
    class function NewQuery(): IQuery; overload; static;
    class function NewQuery(const ATable: string; const AFields: String = '*';
      const AWhere: String = ''; const AOrderBy: string = '';
      const AJoin: String = ''): IQuery; overload; static;
    class function SqlBuilder(const ATable: string; const AFields: String = '*';
      const AWhere: String = ''; const AOrderBy: string = '';
      const AJoin: String = ''): string; overload; static;
  end;


  IDataset = interface
    ['{AED88905-4241-4BBD-9035-1112C882CF05}']
    function IOpen: IQuery;
    function IClose:IQuery;
    procedure Next;
    procedure Prior;
    procedure Last;
    procedure First;
    function eof: boolean;
    function bof: boolean;
    procedure insert;
    procedure post;
    procedure edit;
    procedure delete;
    function IStartTransaction:IQuery;
    function ICommit:IQuery;
    function IRollback:IQuery;
    function RowsAffected: integer;
    function GetFields: TFields;
    property Fields: TFields read GetFields;
    function RecordCountInt:integer;
    property RecordCount:integer read RecordCountInt;
    function GetActiveQuery: boolean;
    procedure SetActiveQuery(const Value: boolean);
    property Active:boolean read GetActiveQuery Write SetActiveQuery;

  end;


  IQuery = Interface(IDataset)
    ['{4C9E016E-41A2-42D1-899E-D820FE4FA9C4}']
    function IExecSql(const AScript: string):IQuery;
    procedure SetCommand(const ACommand: string);
    function GetCommand: string;
    procedure SetConnectionIntf(const AConn: TFDCustomConnection);
    function GetConnectionIntf: TFDCustomConnection;
    property Command: string read GetCommand write SetCommand;
    property Connection: TFDCustomConnection read GetConnectionIntf
      write SetConnectionIntf;
    function GetParams: TFDParams;
    property Params: TFDParams read GetParams;


    // Enumerator
    function GetEnumerator: IQuery;
    function GetCurrent: TFields;
    property Current:TFields read GetCurrent;
    function MoveNext: boolean;
    procedure Reset;

    // Open
    function IOpen(const AProc:TProc<TFDParams> ): IQuery;overload;
    function IDoLoop( const AProc:TProc<TDataset> ):IQuery;
    function IDoQuery( const AProc:TProc<TDataset>):IQuery;
    function IClone:IQuery;

    // Filters
    function ConnectName(texto:String):IQuery;
    function Where(const texto:string):IQuery;
    function Table(const texto:string):IQuery;
    function Join(const texto:string):IQuery;
    function OrderBy( const Texto:string):IQuery;
    function AndWhere( const texto:string):IQuery;
    function OrWhere( const texto:string):IQuery;
    function FilterResult( const texto:string):IQuery;
    function FieldNames(const texto:string):IQuery;
    function paramValue(const nome:string; valor:variant):IQuery;
    function fieldValue(const nome:string; valor:variant):IQuery;

    function GetCmdFields: string;
    function GetCmdJoin: string;
    function GetCmdOrderBy: string;
    function GetCmdTable: string;
    function GetCmdWhere: string;
    procedure SetCmdWhere(const Value: string);
    procedure SetCmdFiedls(const Value: string);
    procedure SetCmdJoin(const Value: string);
    procedure SetCmdOrderBy(const Value: string);
    procedure SetCmdTable(const Value: string);
    property CmdWhere:string read GetCmdWhere write SetCmdWhere;
    property CmdTable:string read GetCmdTable write SetCmdTable;
    property CmdFields:string read GetCmdFields write SetCmdFiedls;
    property CmdJoin:string read GetCmdJoin write SetCmdJoin;
    property CmdOrderBy:string read GetCmdOrderBy write SetCmdOrderBy;
  End;

  IDatabase = interface
    ['{09A79486-12B6-4944-9F4C-8CF841D901E5}']
    function IOpen:IDatabase;
    function IClose:IDatabase;
    function ParamValue(sParam:string;value:variant):IDatabase;
    function Driver(ADriver:string):IDatabase;
    function ConnectName(ADBname:string):IDatabase;
    function LoginParam(AUser:string;APass:String):IDatabase;
  end;

  TDatabaseIntf = class(TFDCustomConnection,IDatabase)
    public
      class function new:IDatabase;
      function IOpen:IDatabase;virtual;
      function IClose:IDatabase;virtual;
      function ParamValue(sParam:string;value:variant):IDatabase;
      function Driver(ADriver:string):IDatabase;
      function ConnectName(ADBname:string):IDatabase;
      function LoginParam(AUser:string;APass:String):IDatabase;
  end;

  TQueryIntf = class({$ifdef BPL} TFDCustomQuery {$else}TFDQuery{$endif}, IQuery{, IDataset})
  private
    FScrollRow:Integer;
    FWhere:string;
    FJoin:string;
    FTable:string;
    FFieldNames:string;
    FOrderBy:string;
    procedure SetFieldByName(const AField: string; const AValue: variant);
    function GetActiveQuery: boolean;
    procedure SetActiveQuery(const Value: boolean);
    function GetCmdFields: string;
    function GetCmdJoin: string;
    function GetCmdOrderBy: string;
    function GetCmdTable: string;
    function GetCmdWhere: string;
    procedure SetCmdWhere(const Value: string);
    procedure SetCmdFiedls(const Value: string);
    procedure SetCmdJoin(const Value: string);
    procedure SetCmdOrderBy(const Value: string);
    procedure SetCmdTable(const Value: string);
  public
    class function New:IQuery;overload;
    class function New(const AConnection: TFDCustomConnection): IQuery;overload;
    function IClose:IQuery;virtual;
    function ConnectName(texto:String):IQuery;virtual;

    function RowsAffected: integer;
    function eof: boolean;
    function bof: boolean;
    function GetCurrent: TFields;
    function MoveNext: boolean;
    procedure Reset;
    function IExecSql(const AScript: string):IQuery; virtual;
    function GetCommand: string;
    procedure SetCommand(const ACommand: string);
    procedure SetConnectionIntf(const AConn: TFDCustomConnection);
    function GetConnectionIntf: TFDCustomConnection;
    function IStartTransaction:IQuery;
    function ICommit:IQuery;
    function IRollback:IQuery;
    function IOpen: IQuery;overload;virtual;
    function IOpen(const AProc:TProc<TFDParams> ): IQuery;overload;virtual;
    procedure InternalFirst;override;
    procedure InternalDelete; override;
    procedure InternalLast; override;
    function MoveBy(Distance: Integer): Integer; override;
    function IDoLoop(const AProc:TProc<TDataset> ):IQuery;
    function IDoQuery( const AProc:TProc<TDataset>):IQuery;


    function GetFields: TFields;
    function GetEnumerator:IQuery;
    function GetParams: TFDParams;
    function paramValue(const nome:string; valor:variant):IQuery;
    function fieldValue(const nome:string; valor:variant):IQuery;
    function NewQuery(const ATable: string=''; const AFields: String = '*';
      const AWhere: String = ''; const AOrderBy: string = '';
      const AJoin: String = ''): IQuery;
    constructor create(AOwner:TComponent);override;
    destructor Destroy;override;
    function IClone:IQuery;
    function RebuildSql:IQuery;
    function Where(const texto:string):IQuery;virtual;
    function Table(const texto:string):IQuery;virtual;
    function FieldNames(const texto:string):IQuery;virtual;
    function Join(const texto:string):IQuery;virtual;
    function OrderBy( const Texto:string):IQuery;virtual;
    function AndWhere( const texto:string):IQuery;virtual;
    function OrWhere( const texto:string):IQuery;virtual;
    function FilterResult( const texto:string):IQuery;
    function RecordCountInt:integer;

    property CmdWhere:string read GetCmdWhere write SetCmdWhere;
    property CmdTable:string read GetCmdTable write SetCmdTable;
    property CmdFields:string read GetCmdFields write SetCmdFiedls;
    property CmdJoin:string read GetCmdJoin write SetCmdJoin;
    property CmdOrderBy:string read GetCmdOrderBy write SetCmdOrderBy;



  end;

implementation

{ TQueyIntf }

function TQueryIntf.RowsAffected: integer;
begin
  result := inherited RowsAffected;
end;

function TQueryIntf.AndWhere(const texto: string):IQuery;
begin
   result := self;
   if FWhere <>'' then
      FWhere := FWhere + ' and ';
   FWhere := FWhere + texto;
   RebuildSql;
end;

function TQueryIntf.bof: boolean;
begin
  result := inherited bof;
end;

function TQueryIntf.IClone: IQuery;
begin
   result := TQueryIntf.Create(nil);
   result.Command := self.GetCommand;
   result.Connection := self.GetConnectionIntf;
end;

function TQueryIntf.IClose: IQuery;
begin
   result := self;
   inherited close;
end;

function TQueryIntf.ICommit:IQuery;
begin
  result := self;
  Connection.Commit;
end;

function TQueryIntf.ConnectName(texto: String): IQuery;
begin
  result := self;
  ConnectionName := texto;
end;

constructor TQueryIntf.create(AOwner: TComponent);
begin
  inherited;
  FFieldNames:='*';
  FScrollRow := -1;

end;

destructor TQueryIntf.Destroy;
begin
  inherited;
end;


function TQueryIntf.IDoLoop(const AProc: TProc<TDataset>):IQuery;
var
    book:TBookmark;
begin
  result := self;
  DisableControls;
  try
    book := GetBookmark;
    try
       first;
       while not eof do
       begin
          try
          AProc(self);
          next;
          except
            break;
          end;
       end;

    finally
      GotoBookmark(book);
      FreeBookmark(book);
    end;
  finally
    EnableControls;
  end;
end;

function TQueryIntf.IDoQuery(const AProc: TProc<TDataset>): IQuery;
begin
   result := self;
   AProc(self);
end;

function TQueryIntf.eof: boolean;
begin
  result := inherited eof;
end;

function TQueryIntf.IExecSql(const AScript: string):IQuery;
begin
  result := self;
  sql.Text := AScript;
  inherited Execute();
end;

function TQueryIntf.FieldNames(const texto: string): IQuery;
begin
   result := self;
   FFieldNames := texto;
   RebuildSql;
end;

function TQueryIntf.fieldValue(const nome: string; valor: variant): IQuery;
var fld:TField;
begin
   result := self;
   fld := FindField(nome);
   if fld<>nil then
      fld.Value := valor;
end;

function TQueryIntf.FilterResult(const texto: string):IQuery;
begin
  result := self;
  inherited Filter:= texto;
  inherited Filtered := texto<>'';
end;


procedure TQueryIntf.InternalDelete;
begin
  inherited;
  if bof then
     FScrollRow := -1;
end;

procedure TQueryIntf.InternalFirst;
begin
  inherited;
  FScrollRow := -1;
end;

procedure TQueryIntf.InternalLast;
begin
  inherited;
  if bof then
     FScrollRow := -1;

end;

function TQueryIntf.Join(const texto: string): IQuery;
begin
   result := self;
   FJoin := texto;
   RebuildSql;
end;

function TQueryIntf.GetActiveQuery: boolean;
begin
  result := inherited Active;
end;

function TQueryIntf.GetCommand: string;
begin
  result := sql.Text;
end;

function TQueryIntf.GetConnectionIntf: TFDCustomConnection;
begin
  result := inherited Connection;
end;

function TQueryIntf.GetCurrent:TFields;
begin
  result := self.Fields;
end;

function TQueryIntf.GetEnumerator:IQuery;
begin
  result := self as IQuery;
end;

function TQueryIntf.GetFields: TFields;
begin
  result := inherited Fields;
end;

function TQueryIntf.GetParams: TFDParams;
begin
  result := inherited Params;
end;

function TQueryIntf.GetCmdFields: string;
begin
   result := FFieldNames;
end;

function TQueryIntf.GetCmdJoin: string;
begin
   result := FJoin;
end;

function TQueryIntf.GetCmdOrderBy: string;
begin
   result := FOrderBy;
end;

function TQueryIntf.GetCmdTable: string;
begin
   result := FTable;
end;

function TQueryIntf.GetCmdWhere: string;
begin
   result := FWhere;
end;

function TQueryIntf.MoveBy(Distance: Integer): Integer;
begin
    result := inherited MoveBy(Distance);
    if eof then
      FScrollRow := -1;
end;

function TQueryIntf.MoveNext: boolean;
begin
  if FScrollRow>=0 then
     Next;
  inc(FScrollRow);
  result := not eof;
end;

class function TQueryIntf.New: IQuery;
begin
   result := TDataStorageRec.NewQuery();
end;


class function TQueryIntf.New(
  const AConnection: TFDCustomConnection): IQuery;
begin
  result := TDataStorageRec.newQuery();
  result.SetConnectionIntf(AConnection);

end;


function TQueryIntf.NewQuery(const ATable, AFields, AWhere, AOrderBy,
  AJoin: String): IQuery;
begin
  result := TDataStorageRec.NewQuery(ATable, AFields, AWhere,
    AOrderBy, AJoin);
  result.Connection := self.Connection;
end;

function TQueryIntf.IOpen(const AProc: TProc<TFDParams>): IQuery;
begin
     AProc(GetParams);
     result := self;
     inherited open;
end;

function TQueryIntf.OrderBy(const Texto: string): IQuery;
begin
   result := self;
   FOrderBy := texto;
   RebuildSql;
end;

function TQueryIntf.OrWhere(const texto: string):IQuery;
begin
   result := self;
   if FWhere <>'' then
      FWhere := FWhere + ' or ';
   FWhere := FWhere + texto;
   RebuildSql;

end;

function TQueryIntf.paramValue(const nome: string; valor: variant): IQuery;
var prm:TFDParam;
begin
   result := self;
   prm := FindParam(nome);
   if prm<>nil then
     prm.Value := valor;
end;

function TQueryIntf.RebuildSql:IQuery;
begin
   result := self;
   SetCommand( TDataStorageRec.SqlBuilder(FTable,FFieldNames,FWhere,FOrderBy,FJoin ));
end;

function TQueryIntf.RecordCountInt: integer;
begin
  result := inherited RecordCount;
end;

function TQueryIntf.IOpen: IQuery;
begin
  inherited Open;
  FScrollRow := -1;
  result := self as IQuery;
end;

procedure TQueryIntf.reset;
begin
  InternalFirst;
end;

function TQueryIntf.IRollback:IQuery;
begin
  result := self;
  Connection.Rollback;
end;

procedure TQueryIntf.SetActiveQuery(const Value: boolean);
begin
   inherited active := Value;
end;

procedure TQueryIntf.SetCommand(const ACommand: string);
begin
  sql.Text := ACommand;
end;

procedure TQueryIntf.SetConnectionIntf(const AConn: TFDCustomConnection);
begin
  inherited Connection := AConn;
end;

procedure TQueryIntf.SetFieldByName(const AField: string;
  const AValue: variant);
begin
  inherited fieldByName(AField).Value := AValue;
end;

procedure TQueryIntf.SetCmdWhere(const Value: string);
begin
   FWhere := Value;
   RebuildSql;
end;

procedure TQueryIntf.SetCmdFiedls(const Value: string);
begin
  FFieldNames := Value;
  RebuildSql;
end;

procedure TQueryIntf.SetCmdJoin(const Value: string);
begin
  FJoin := Value;
  RebuildSql;
end;

procedure TQueryIntf.SetCmdOrderBy(const Value: string);
begin
  FOrderBy := Value;
  RebuildSql;
end;

procedure TQueryIntf.SetCmdTable(const Value: string);
begin
  FTable := Value;
  RebuildSql;
end;

function TQueryIntf.IStartTransaction:IQuery;
begin
  result := self;
  Connection.StartTransaction;
end;

function TQueryIntf.Table(const texto: string): IQuery;
begin
   result := self;
   FTable := texto;
   RebuildSql;
end;

function TQueryIntf.Where(const texto: string):IQuery;
begin
   result := self;
   FWhere := texto;
   RebuildSql;
end;

{ TStoreDataStorage }

class function TDataStorageRec.NewQuery: IQuery;
begin
  result := TQueryIntf.Create(nil) as IQuery;
end;



class function TDataStorageRec.NewQuery(const Conn:TFDCustomConnection): IQuery;
begin
   result :=  TDataStorageRec.NewQuery();
   result.Connection := Conn;
end;

class function TDataStorageRec.NewQuery(const ATable, AFields, AWhere,
  AOrderBy, AJoin: String): IQuery;
begin
    result := NewQuery();
    result.Table(ATable)
          .where(AWhere)
          .OrderBy(AOrderBy)
          .Join(AJoin)
          .FieldNames(AFields);
end;


class function TDataStorageRec.SqlBuilder(const ATable, AFields, AWhere,
  AOrderBy, AJoin: String): string;
var
  sql: TStringBuilder;
begin
  sql := TStringBuilder.Create;
  try
    if ATable<>'' then
      sql.Append('select ' + AFields + ' from ' + ATable);
    if AJoin <> '' then
      sql.Append(' ' + AJoin);
    if AWhere <> '' then
      sql.Append(' where ' + AWhere);
    if AOrderBy <> '' then
      sql.Append(' order by ' + AOrderBy);
    result := sql.ToString;
  finally
    sql.Free;
  end;
end;

{ TDatabaseIntf }


function TDatabaseIntf.IClose: IDatabase;
begin
   result := self;
   inherited Close;
end;

function TDatabaseIntf.ConnectName(ADBname: string): IDatabase;
begin
   result := self;
   inherited ConnectionName:=ADBname;
end;

function TDatabaseIntf.Driver(ADriver: string): IDatabase;
begin
    result := self;
    inherited driverName := ADriver;
end;

function TDatabaseIntf.LoginParam(AUser, APass: String): IDatabase;
begin
   result := self
   .ParamValue('USER_NAME',AUser)
   .ParamValue('Password',APass);
end;

class function TDatabaseIntf.new: IDatabase;
begin

    result := TDatabaseIntf.Create(nil) as IDatabase;
end;

function TDatabaseIntf.IOpen: IDatabase;
begin
    result := self;
    inherited Open;
end;

function TDatabaseIntf.ParamValue(sParam: string; value: variant): IDatabase;
begin
    result := self;
    Params.Values[sParam] := value;
end;

end.
