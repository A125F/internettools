unit xquery__parse;

{
Copyright (C) 2008 - 2012 Benito van der Zander (BeniBela)
                          benito@benibela.de
                          www.benibela.de

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, xquery;

type
 TXQSequenceTypeFlag = (xqstAllowValidationTypes, xqstIsCast, xqstResolveNow);
 TXQSequenceTypeFlags = set of TXQSequenceTypeFlag;
 TXQTermPendingEQNameTokenPending = (xqptUnknown, xqptVariable);
 TXQTermPendingEQNameToken = class(TXQTermEQNameToken )
   mode: TXQNamespaceMode;
   data: integer;
   pending: TXQTermPendingEQNameTokenPending;
   constructor create;
   constructor create(anamespaceurl, aprefix, alocalpart: string; amode: TXQNamespaceMode; somedata: integer = 0);
   constructor create(anamespaceurl, aprefix, alocalpart: string; amode: TXQNamespaceMode; realterm: TXQTermPendingEQNameTokenPending);
   function resolveURI(const staticContext: TXQStaticContext; kind: TXQDefaultNamespaceKind = xqdnkUnknown): string;
   function resolveAndFree(const staticContext: TXQStaticContext): TXQTerm;
   function clone: TXQTerm; override;
 end;

 TXQEQNameUnresolved = class(TXQEQNameWithPrefix)
   function resolveURI(const staticContext: TXQStaticContext; kind: TXQDefaultNamespaceKind = xqdnkUnknown): string;
   function resolveAndFreeToEQName(const staticContext: TXQStaticContext; kind: TXQDefaultNamespaceKind = xqdnkUnknown): TXQEQName;
   function resolveAndFreeToEQNameWithPrefix(const staticContext: TXQStaticContext; kind: TXQDefaultNamespaceKind = xqdnkUnknown): TXQEQNameWithPrefix;
   function freeToEQName: TXQEQName;

   class function makeEQName(const url, prefix, local: string; mode: TXQNamespaceMode): TXQEQName;
   class function makeEQNameWithPrefix(const url, prefix, local: string; mode: TXQNamespaceMode): TXQEQNameWithPrefix;
 end;


TXQParsingContext = class(TXQAbstractParsingContext)
protected
  procedure raiseParsingError(errcode, s: string);
  procedure raiseSyntaxError(s: string);
  procedure raiseInvalidModel(s: string);

  procedure requireXQuery(s: string = '');
  procedure require3(s: string = '');
  procedure requireXQuery3(s: string = '');
  function isModel3: boolean;

  procedure skipWhitespace();
  procedure skipComment();
  procedure skipWhitespaceAndComment();
  procedure expect(c: char);
  procedure expect(s: string);
  function nextToken(lookahead: boolean=false): string;
  function nextTokenNCName(): string; inline; //returns a NCName
  // $foo       -> ('', '', 'foo',    xqnmPrefix)
  // $*:foo     -> ('', '*', 'foo',   xqnmNone)
  // $prf:foo   -> ('', 'prf', 'foo', xqnmPrefix)
  // $Q{}foo    -> ('', 'Q', 'foo',   xqnmURL)
  // $Q{ns}foo  -> ('ns', 'Q', 'foo', xqnmURL)
  function nextTokenEQName(out url, prefix, localpart: string; allowWildcards: boolean=false): TXQNamespaceMode; //returns a splitted EQName
  function parsePendingEQName(pending: TXQTermPendingEQNameTokenPending = xqptUnknown): TXQTermPendingEQNameToken;
  function parseEQName: TXQEQName;
  function parseEQNameWithPrefix: TXQEQNameWithPrefix;


  function normalizeLineEnding(const s: string): string;

  function parseSequenceLike(target: TXQTermWithChildren; closingChar: char = ')'; allowPartialApplication: boolean = false): TXQTermWithChildren;
  function parseFunctionCall(target: TXQTermWithChildren): TXQTermWithChildren;
  function parseSequenceType(flags: TXQSequenceTypeFlags): TXQTermSequenceType;
  function parseSequenceTypeUnion(): TXQTermSequenceType;
  function parsePatternMatcher(): TXQTermPatternMatcher;
  function replaceEntitiesAlways(s: string): string;
  function replaceEntitiesIfNeeded(const s: string): string; inline;
  function parseString: string;
  function parseString(const w: string): string;
  function parseXString(nullTerminatedString: boolean = false): TXQTerm; //**< parses an extended string like @code(x"foo""bar"), @code(x"foo{$varref}ba{1+2+3}r")
  function parseJSONLikeObjectConstructor(): TXQTermWithChildren; //**< parses an json object constructor { "name": value, .. } or {| ... |}
  function parseJSONLikeArray(): TXQTermJSONArray;


  function parseFlower(akind: string): TXQTermFlower;
  function parseSomeEvery(const akind: string): TXQTermSomeEvery;
  function parseTypeSwitch: TXQTermTypeSwitch;
  function parseSwitch: TXQTermSwitch;
  function parseDirectConstructor(): TXQTermConstructor;
  function parseComputedConstructor(name: string): TXQTermConstructor;
  function parseExtension: TXQTerm;
  function parseVariable: TXQTermPendingEQNameToken;
  function splitVariableForDotNotation(t: TXQTerm): TXQTerm;
  function parseDefineVariable: TXQTermDefineVariable;
  function parseAnnotations: TXQAnnotations;
  function parseFunctionDeclaration(annotations: TXQAnnotations; anonymous: boolean = false): TXQTermDefineFunction;
  function parseTryCatch: TXQTermTryCatch;

  //**Parses the next complete value@br
  //**i.e. it will parse from the left, until it obtains a value that can be evaluated.
  //**e.g. from @code(1 + 2) it will parse @code(1) (since @code(1) is complete), from @code(function(1,2,3)) it will parse everything (since @code(function) can not be evaluated without its parameters))@br
  //**(observation: that kind of looks like it parses everything except binary operators)
  function parseValue: TXQTerm;        //left most token of an ExprSingle
  function parseOrExpr: TXQTerm;       //OrExpr
  function parse: TXQTerm;             //ExprSingle
  function parsePrimaryLevel: TXQTerm; //Expr
  function parseModuleInternal(): TXQTerm;


  function parseModule: TXQTerm; override;
  class function finalResolving(term: TXQTerm; sc: TXQStaticContext; const opts: TXQParsingOptions): TXQTerm;
  function parseXStringOnly(nullTerminatedString: boolean = false): TXQTerm; override;
  procedure parseFunctionTypeInfo(info: TXQAbstractFunctionInfo; const typeChecking: array of string); override;
end;

implementation
uses bbutils, simplehtmltreeparser, strutils, math;

type

 { TJSONLiteralReplaceVisitor }

 TJSONLiteralReplaceVisitor = class(TXQTerm_Visitor)
   function visit(t: PXQTerm): TXQTerm_VisitAction; override;
 end;
 TFlowerVariableChecker = class(TXQTerm_Visitor)
   knownVars: TXQVariableChangeLog;
   procedure undeclare(v: PXQTermVariable); override;
   constructor create;
   destructor Destroy; override;
 end;

 TFinalNamespaceResolving = class(TXQTerm_Visitor)
   staticContext: TXQStaticContext;
   changedDefaultsTypeNamespaces: TInterfaceList;
   implicitNamespaceCounts: TLongintArray;
   implicitNamespaceCountsLength: integer;
   checker: TFlowerVariableChecker;
   procedure declare(v: PXQTermVariable); override;
   function visit(t: PXQTerm): TXQTerm_VisitAction; override;
   function leave(t: PXQTerm): TXQTerm_VisitAction; override;
   procedure raiseParsingError(a, b: string);
   procedure raiseSyntaxError(m: string);

   constructor Create;
   destructor Destroy; override;
 end;

 TXQueryBreaker = class(TXQuery) end;
 TXQueryEngineBreaker = class(TXQueryEngine) end;

function addNamespacesToStaticContext(ns: TNamespaceList; sc: TXQStaticContext): integer;
var
  i: Integer;
begin
  if sc.namespaces = nil then sc.namespaces := TNamespaceList.Create;
  result := sc.namespaces.Count;
  for i := 0 to ns.Count - 1 do begin
    sc.namespaces.add(ns.namespaces[i]);
    if ns.namespaces[i].getPrefix = '' then
      sc.defaultElementTypeNamespace := ns.namespaces[i];
  end;
end;

const PARSING_MODEL_XQUERY = [xqpmXQuery1, xqpmXQuery3];
      PARSING_MODEL3 = [xqpmXPath3, xqpmXQuery3];

procedure TFlowerVariableChecker.undeclare(v: PXQTermVariable);
begin
  knownVars.add(v^, nil);
end;

constructor TFlowerVariableChecker.create;
begin
  knownVars := TXQVariableChangeLog.create();
end;

destructor TFlowerVariableChecker.Destroy;
begin
  knownVars.free;
  inherited Destroy;
end;

constructor TXQTermPendingEQNameToken.create;
begin

end;

constructor TXQTermPendingEQNameToken.create(anamespaceurl, aprefix, alocalpart: string; amode: TXQNamespaceMode; somedata: integer);
begin
  namespaceurl := anamespaceurl;
  namespaceprefix := aprefix;
  localpart := alocalpart;
  mode := amode;
  data := somedata;
end;

constructor TXQTermPendingEQNameToken.create(anamespaceurl, aprefix, alocalpart: string; amode: TXQNamespaceMode;
  realterm: TXQTermPendingEQNameTokenPending);
begin
  namespaceurl := anamespaceurl;
  namespaceprefix := aprefix;
  localpart := alocalpart;
  pending := realterm;
  mode := amode;
end;

function TXQTermPendingEQNameToken.resolveURI(const staticContext: TXQStaticContext; kind: TXQDefaultNamespaceKind): string;
begin
  if mode = xqnmPrefix then begin
    namespaceurl := staticContext.findNamespaceURLMandatory(namespaceprefix, kind);
  end;
  result := namespaceurl;
end;

function TXQTermPendingEQNameToken.resolveAndFree(const staticContext: TXQStaticContext): TXQTerm;
begin
  case pending of
    xqptVariable: begin
      result := TXQTermVariable.create(localpart, resolveURI(staticContext, xqdnkUnknown));;
      free;
    end;
    xqptUnknown: raise EXQParsingException.create('XPST0003', 'Internal error 20160101181238');
  end;
end;

function TXQTermPendingEQNameToken.clone: TXQTerm;
begin
  Result:=inherited clone;
  TXQTermPendingEQNameToken(result).mode := mode;
  TXQTermPendingEQNameToken(result).data := data;
  TXQTermPendingEQNameToken(result).pending := pending;
end;


function TXQEQNameUnresolved.resolveURI(const staticContext: TXQStaticContext; kind: TXQDefaultNamespaceKind): string;
begin
  namespaceurl := staticContext.findNamespaceURLMandatory(namespaceprefix, kind);
  result := namespaceurl;
end;

function TXQEQNameUnresolved.resolveAndFreeToEQName(const staticContext: TXQStaticContext; kind: TXQDefaultNamespaceKind): TXQEQName;
begin
  resolveURI(staticContext, kind);
  result := freeToEQName;
end;

function TXQEQNameUnresolved.resolveAndFreeToEQNameWithPrefix(const staticContext: TXQStaticContext; kind: TXQDefaultNamespaceKind
  ): TXQEQNameWithPrefix;
begin
  resolveURI(staticContext, kind);
  result := TXQEQNameWithPrefix.create(namespaceURL, namespacePrefix, localname);
  free;
end;

function TXQEQNameUnresolved.freeToEQName: TXQEQName;
begin
  result := TXQEQName.create(namespaceURL, localname);
  free;
end;

class function TXQEQNameUnresolved.makeEQName(const url, prefix, local: string; mode: TXQNamespaceMode): TXQEQName;
begin
  if mode = xqnmPrefix then begin
    result := TXQEQNameUnresolved.Create;
    result.localname := local;
    TXQEQNameUnresolved(result).namespacePrefix := prefix;
  end else begin
    result := TXQEQName.Create;
    result.namespaceURL := url;
    result.localname := local;
  end;
end;

class function TXQEQNameUnresolved.makeEQNameWithPrefix(const url, prefix, local: string; mode: TXQNamespaceMode): TXQEQNameWithPrefix;
begin
  if mode = xqnmPrefix then begin
    result := TXQEQNameUnresolved.Create;
    result.localname := local;
    TXQEQNameUnresolved(result).namespacePrefix := prefix;
  end else begin
    result := TXQEQNameWithPrefix.Create;
    result.namespaceURL := url;
    result.localname := local;
    result.namespacePrefix := 'prf';
  end;
end;


procedure TXQParsingContext.raiseParsingError(errcode, s: string);
begin
  if (pos < @str[1]) then pos := @str[1]; //make sure pos points to str
  if (pos > @str[length(str)]) then pos := @str[length(str)];
  raise EXQParsingException.Create(errcode, s+#13#10'in: '+strslice(@str[1],pos-1)+' [<- error occurs before here] '+strslice(pos,@str[length(str)]));
end;

procedure TXQParsingContext.raiseSyntaxError(s: string);
begin
  raiseParsingError('XPST0003', s);
end;

procedure TXQParsingContext.raiseInvalidModel(s: string);
begin
  raiseSyntaxError('This language feature is not available in the selected language. '+s);
end;

procedure TXQParsingContext.requireXQuery(s: string);
begin
  if (parsingModel <> xqpmXQuery1) and (parsingModel <> xqpmXQuery3) then raiseInvalidModel('XQuery is required '+s);
end;

procedure TXQParsingContext.require3(s: string);
begin
  if (parsingModel <> xqpmXPath3) and (parsingModel <> xqpmXQuery3) then raiseInvalidModel('At least XQuery/XPath version 3.0 is required '+s);
end;

procedure TXQParsingContext.requireXQuery3(s: string);
begin
  if (parsingModel <> xqpmXQuery3) then raiseInvalidModel('XQuery version 3.0 is required '+s);
end;

function TXQParsingContext.isModel3: boolean;
begin
  result := parsingModel in PARSING_MODEL3;
end;

procedure TXQParsingContext.skipWhitespace;
begin
  while pos^ in WHITE_SPACE do pos += 1;
end;

procedure TXQParsingContext.skipComment;
var nestene: integer;
begin
  nestene:=0;
  while pos^ <> #0 do begin
    if (pos^ = ':') and ((pos+1)^ = ')') then begin
      pos+=2;
      nestene-=1;
      if nestene=0 then exit;
    end else if (pos^ = '(') and ((pos+1)^ = ':') then begin
      pos+=2;
      nestene+=1;
    end else pos+=1;
  end;
  raiseSyntaxError('Never ending comment')
end;

procedure TXQParsingContext.skipWhitespaceAndComment;
begin
  while (pos^ in WHITE_SPACE) or ((pos^ = '(') and ((pos+1)^ = ':')) do begin
    while pos^ in WHITE_SPACE do pos+=1;
    if (pos^ = '(') and ((pos+1)^ = ':') then
      skipComment();
  end;
end;

procedure TXQParsingContext.expect(c: char);
begin
  skipWhitespaceAndComment;
    if pos^ <> c then
      raiseSyntaxError('"'+c+'"'+' expected, but "'+nextToken()+'" found');
    pos+=1;
end;

procedure TXQParsingContext.expect(s: string);
var
   i: Integer;
begin
  skipWhitespaceAndComment;
  for i:=1 to length(s) do begin
    if pos^ <> s[i] then
      raiseSyntaxError('"'+ s+'" expected, but "'+nextToken()+'" found');
    pos+=1;
  end;
end;

//read the next token ('string', number: (-?[0-9]+|[0-9]*.[0-9]+|[0-9]+.[0-9]*)([eE][+-]?[0-9]+)?, symbol, identifier)
const SYMBOLS = ['''','"', '(','=','!','<','>',')',',','[',']','/','|','+','*','{','}', '?', '#', ';', ':', '@', '$', '%'];
const START_SYMBOLS = ['-'];
function TXQParsingContext.nextToken(lookahead: boolean=false): string;
var start:pchar;
   numberE, numberPoint: boolean;
   tempOp: TXQOperatorInfo;
begin
  skipWhitespaceAndComment;
  if pos^ = #0 then exit('');
  start:=pos;
  case pos^ of
    '''', '"': begin
      repeat
        pos+=1;
        if (pos^ = start^) then
          if ((pos+1)^ <> start^) then break
          else pos+=1;
      until pos^ in [#0];
      if pos^ = #0 then raiseSyntaxError('Unclosed string');
      pos+=1;
    end;
    '(','=','!','<','>',')',',','[',']','/','|','+','*','{','}', '?', '#', ';', '@', '$', '%', '-': begin//SYMBOLS+START_SYMBOLS - [:-]
      tempOp := TXQueryEngine.findOperator(pos);
      if tempOp <> nil then result := tempOp.name
      else result := pos^;

      if lookahead then exit(result)
      else begin
        pos+=length(result);
        exit(result);
      end;
    end;
    ':': begin
      inc(pos);
      if pos^ in [':','='] then inc(pos);
    end;
    '0'..'9','.': begin
      numberPoint:=pos^ = '.';
      if numberPoint and not ((pos+1)^ in ['0'..'9']) then begin
        pos += 1; //not a number
        if pos^ = '.' then pos += 1; //..
      end else begin
        numberE:=false;
        repeat
          pos+=1;
          if pos^ = '.' then begin
            if numberPoint then raiseSyntaxError('Double . in number');
            numberPoint:=true;
            pos+=1;
          end;
          if pos^ in ['e','E'] then begin
            if numberE then raiseSyntaxError('Double e in number');
            pos+=1;
            numberE:=true;
            if not (pos^ in ['0'..'9','+','-']) then raiseSyntaxError('Invalid character after e in number')
            else pos+=1;
          end;
        until not (pos^ in ['0'..'9']);
        if (pos^ in ['a'..'z','A'..'Z']) then raiseSyntaxError('Space needed between number and non-symbolic operator');
      end;
    end;
    else begin
      repeat
        pos+=1;
      until (pos^ in SYMBOLS + WHITE_SPACE + [#0]) {deprecated? or ((pos^ = ':') and ((pos+1)^='='))};
    end;
  end;
  assert(start<pos);
  result:=strslice(start,pos-1);
  if lookahead then pos:=start;
end;

function TXQParsingContext.nextTokenNCName(): string;
begin
  result := nextToken(false);
  if not baseSchema.isValidNCName(result) then
    raiseSyntaxError('Invalid NCName: '''+result+'''');
end;

function TXQParsingContext.nextTokenEQName(out url, prefix, localpart: string; allowWildcards: boolean): TXQNamespaceMode;
const NONCNAME = (SYMBOLS + START_SYMBOLS + WHITE_SPACE - ['*']);
var
  marker: PChar;
begin
  skipWhitespaceAndComment();
  if pos^ <> '*' then localpart:=nextTokenNCName()
  else localpart := nextToken();
  result := xqnmPrefix;
  if (localpart = 'Q') and (pos^ = '{') then begin
    if ((pos-1)^ <> 'Q') then raiseSyntaxError('Q{ must not be separated by whitespace');
    require3('Q{..} namespace urls');
    prefix := localpart;
    inc(pos);
    marker := pos;
    while not (pos^ in ['}', #0]) do inc(pos);
    url := normalizeLineEnding(strFromPchar(marker, pos - marker));
    url := xmlStrWhitespaceCollapse(replaceEntitiesIfNeeded(url));
    inc(pos);
    if pos^ = '*' then begin
      inc(pos);
      localpart := '*';
    end else begin
      if (pos^ in WHITE_SPACE + SYMBOLS - ['*']) then raiseParsingError('err:XPST0003', 'Q{..}localname must not be separated by whitespace');
      localpart := nextTokenNCName();
    end;
    result := xqnmURL;
  end else if (pos^ = ':') and not ((pos+1)^ in NONCNAME) then begin //same check in parseValue for matchers
    expect(':');
    prefix := localpart;
    if pos^ <> '*' then localpart := nextTokenNCName()
    else localpart := nextToken();
    if prefix = '*' then
      result := xqnmNone;
  end else begin
    url := '';
    if allowWildcards and (localpart = '*') then result := xqnmNone;
  end;
  if (not allowWildcards) and ((result = xqnmNone) or (localpart = '*')) then raiseParsingError('XPST0003', 'Expected QName, got wildcards: '+prefix+':'+localpart);
end;

function TXQParsingContext.parsePendingEQName(pending: TXQTermPendingEQNameTokenPending): TXQTermPendingEQNameToken;
begin
  result := TXQTermPendingEQNameToken.create();
  try
    result.mode := nextTokenEQName(result.namespaceurl, Result.namespaceprefix, result.localpart);
    result.pending := pending;
  except
    result.free;
    raise;
  end;
end;


function TXQParsingContext.parseEQName: TXQEQName;
var
  namespaceUrl: string;
  namespacePrefix: string;
  local: string;
  mode: TXQNamespaceMode;
begin
  mode := nextTokenEQName(namespaceUrl, namespacePrefix, local);
  result := TXQEQNameUnresolved.makeEQName(namespaceUrl, namespacePrefix, local, mode);
end;

function TXQParsingContext.parseEQNameWithPrefix: TXQEQNameWithPrefix;
var
  namespaceUrl: string;
  namespacePrefix: string;
  local: string;
  mode: TXQNamespaceMode;
begin
  mode := nextTokenEQName(namespaceUrl, namespacePrefix, local);
  result := TXQEQNameUnresolved.makeEQNameWithPrefix(namespaceUrl, namespacePrefix, local, mode);
end;

function TXQParsingContext.normalizeLineEnding(const s: string): string;
begin
  case options.LineEndingNormalization of
    xqlenNone:  result := s;
    xqlenXML1:  result := strNormalizeLineEndings(s);
    xqlenXML11: result := strNormalizeLineEndingsUTF8(s);
  end;
end;

function TXQParsingContext.parseSequenceLike(target: TXQTermWithChildren; closingChar: char; allowPartialApplication: boolean  ): TXQTermWithChildren;
var partialApplications: integer;
  procedure nextValue;
  begin
    if allowPartialApplication then begin;
      skipWhitespaceAndComment();
      if pos^ = '?' then begin
        inc(pos);
        inc(partialApplications);
        result.push(TXQTermVariable.create(inttostr(partialApplications)+'.', XMLNamespace_MyExtensions));
        exit;
      end;
    end;
    result.push(parse());
  end;

var
  t: String;
  df: TXQTermDefineFunction;
begin
  partialApplications := 0;
  result := target;
  skipWhitespaceAndComment();
  if pos^ = closingChar then begin expect(closingChar); exit(); end;
  nextValue;
  t := nextToken();
  while t = ',' do begin
    nextValue;
    t := nextToken();
  end;
  if t <> closingChar then raiseParsingError('XPST0003', 'Expected closing parenthesis: '+ closingChar);
  if partialApplications > 0 then begin
    df := TXQTermDefineFunction.create;
    if result is TXQTermNamedFunction then df.kind := xqtdfStaticPartialApplication
    else df.kind := xqtdfDynamicPartialApplication;
    df.parameterCount := partialApplications;
    {for i := 1 to partialApplications do
      df.push(TXQTermDefineVariable.create(inttostr(i)+'.', XMLNamespace_MyExtensions));}
    df.push(result);
    result := df;
  end;
end;

function TXQParsingContext.parseFunctionCall(target: TXQTermWithChildren): TXQTermWithChildren;
begin
  result := parseSequenceLike(target, ')', parsingModel in [xqpmXPath3, xqpmXQuery3]);
end;

function isKindTestFunction(const word: string): boolean;  //Lookahead to recognize KindTest of the XPath-EBNF
begin
  result := (word = 'text') or (word = 'node') or (word = 'comment') or (word = 'processing-instruction')
            or (word = 'element') or (word = 'document-node') or (word = 'schema-element') or (word = 'attribute') or (word = 'schema-attribute');
end;

function TXQParsingContext.parseSequenceType(flags: TXQSequenceTypeFlags): TXQTermSequenceType;
var word: string;
  parens: Integer;
  nsurl, nsprefix: string;

  schema: TXSSchema;
  namespaceMode: TXQNamespaceMode;
  hadNoNamespace: Boolean;
begin
  skipWhitespaceAndComment();
  parens := 0;
  while pos^ = '(' do begin
    inc(pos);
    skipWhitespaceAndComment();
    parens += 1;
  end;
  if parens > 0 then require3('for parentheses around types');
  if pos^ <> '%' then begin
    namespaceMode := nextTokenEQName(nsurl, nsprefix, word);
    hadNoNamespace := (nsprefix = '') and (namespaceMode <> xqnmURL);
  end else begin
    word := '%';
    inc(pos)
  end;


  result := TXQTermSequenceType.Create();
  try
    result.allowNone:=false;
    result.allowMultiple:=false;

    result.name:=word;
    if hadNoNamespace and ((isKindTestFunction(word)) or (word = 'empty-sequence') or (word = 'item')) then begin
      expect('(');

      skipWhitespaceAndComment();
      if pos^ = ')' then expect(')')
      else begin
        result.push(parse());
        if nextToken() = ',' then begin
          result.push(parseSequenceType([xqstAllowValidationTypes]));
          expect(')');
        end;
      end;

      if (word = 'empty-sequence') then begin
        result.kind:=tikNone;
        if (length(result.children) <> 0) or (parens > 0) then raiseParsingError('XPST0003', 'invalid sequence type');
        exit
      end else if word = 'item' then begin
        result.kind:=tikAny;
        if length(result.children) <> 0 then raiseParsingError('XPST0003', 'invalid sequence type');
      end else begin
         result.kind:=tikElementTest;
         result.nodeMatching := convertElementTestToPathMatchingStep(word, result.children);
      end;
    end else if options.AllowJSON and hadNoNamespace and ((word = 'array') or (word = 'object') or (word = 'json-item') or (word = 'structured-item')) then begin
      expect('('); expect(')');
      case word of
        'json-item': begin Result.kind:=tikAtomic; result.atomicTypeInfo := baseJSONiqSchema.jsonItem; end;
        'structured-item': begin Result.kind:=tikAtomic; result.atomicTypeInfo := baseSchema.structuredItem; end;
        'array': begin Result.kind:=tikAtomic; result.atomicTypeInfo := baseJSONiqSchema.array_; end;
        'object': begin Result.kind:=tikAtomic; result.atomicTypeInfo := baseJSONiqSchema.object_; end;
        else raiseParsingError('XPST0003', 'WTF??');
      end;
    end else if hadNoNamespace and (word = 'function') or (word = '%') then begin
      require3('function test');
      if word = '%' then begin
        freeAnnotations(parseAnnotations); //we do not need this nonsense
        expect('function');
      end;
      result.kind:=tikFunctionTest;
      expect('(');
      skipWhitespaceAndComment();
      if pos^ = '*' then begin
        expect('*');
        expect(')');
      end else begin
        while pos^ <> ')' do begin
          SetLength(result.arguments, length(result.arguments) + 1);
          result.arguments[high(result.arguments)] := parseSequenceType(flags);
          skipWhitespaceAndComment();
          if pos^ <> ')' then expect(',');
        end;
        expect(')');
        expect('as');
        SetLength(result.arguments, length(result.arguments) + 1);
        result.arguments[high(result.arguments)] := parseSequenceType(flags);
      end;
    end else begin
      result.kind:=tikAtomic;
      if not (xqstResolveNow in flags) then
        result.push(TXQTermPendingEQNameToken.Create(nsurl, nsprefix, word, namespaceMode, integer(flags)) )
       else begin
         if namespaceMode = xqnmPrefix then nsurl := staticContext.findNamespaceURLMandatory(nsprefix, xqdnkType);
         schema := staticContext.findSchema(nsurl);
         result.atomicTypeInfo := nil;
         if schema <> nil then result.atomicTypeInfo := schema.findType(word);
         if result.atomicTypeInfo = nil then raiseParsingError('XPST0051', 'Unknown type: '+word);
       end;
    end;

    while parens > 0 do begin expect(')'); parens -= 1; end;

    word := nextToken(true);
    if (length(word) = 1) and (word[1] in ['?', '*', '+']) then begin
      case word[1] of
        '?': result.allowNone:=true;
        '+': result.allowMultiple:=true;
        '*': begin result.allowNone:=true; result.allowMultiple:=true; end;
      end;
      pos+=1;
    end;
  except
    result.free;
    raise;
  end;
end;

function TXQParsingContext.parseSequenceTypeUnion: TXQTermSequenceType;
var
  temp: TXQTermSequenceType;
begin
  result := parseSequenceType([]);
  if isModel3 and (nextToken(true) = '|') then begin
    temp := result;
    result := TXQTermSequenceType.create();
    try
      result.kind := tikUnion;
      result.push(temp);
      while nextToken(true) = '|' do begin
        expect('|');
        result.push(parseSequenceType([]));
      end;
    except
      result.free;
      raise;
    end;
  end;
end;

function TXQParsingContext.parsePatternMatcher: TXQTermPatternMatcher;
var
  curpos: PChar;
  temp: TXQTermConstructor;
begin
  if patternMatcherParse = nil then raiseParsingError('pxp:PATT0', 'No pattern matcher loaded ()');
  curpos := pos;
  expect('<');
  temp := parseDirectConstructor;
  temp.free;
  case pos^ of
    '+', '*', '?': inc(pos);
    '{': begin
      while not (pos^ in ['}', #0]) do inc(pos);
      expect('}');
    end;
  end;
  //result := TXQTermTemporaryNode.create();
  //result.node := (patternMatcherParse(strFromPchar(curpos, pos-curpos)));
  Result := patternMatcherParse(staticContext, strFromPchar(curpos, pos-curpos));
end;

function TXQParsingContext.parseFlower(akind: string): TXQTermFlower;


  function parseFlowerVariable: TXQTermVariable;
  begin
    result := TXQTermVariable(txqterm(parseVariable));
  end;

var token: String;
  procedure parseInitialClauseAndNextToken;
    procedure parseWindow;
      procedure parseWindowVars(out vars: TXQTermFlowerWindowVarsAndCondition);
      begin
        skipWhitespaceAndComment();
        if pos^ = '$' then vars.currentItem := parseFlowerVariable;
        if nextToken(true) = 'at' then begin
          expect('at');
          vars.positionVar := parseFlowerVariable;
        end;
        if nextToken(true) = 'previous' then begin
          expect('previous');
          vars.previousItem := parseFlowerVariable;
        end;
        if nextToken(true) = 'next' then begin
          expect('next');
          vars.nextItem := parseFlowerVariable;
        end;
        expect('when');
        vars.when := parse;
      end;

    var flags: TXQTermFlowerWindowFlags;
      window: TXQTermFlowerWindow;
    begin
      token := nextToken();
      case token of
        'tumbling': flags := [];
        'sliding': flags := [xqtfwSliding];
        else raiseSyntaxError('Expected variable, sliding/tumbling window or pattern in flowr expression, but got: '+token);
      end;
      requireXQuery3();
      expect('window');
      window := TXQTermFlowerWindow.Create;
      result.push(window);
      window.flags := flags;
      window.loopvar := parseFlowerVariable;
      if nextToken(true) = 'as' then begin
        expect('as');
        window.sequenceTyp := parseSequenceType([]);
      end;
      expect('in');
      window.expr := parse();
      expect('start');
      parseWindowVars(window.startCondition);
      if nextToken(true) = 'only' then begin
        expect('only');
        Include(window.flags, xqtfwEndOnlyWhen);
      end;
      if ( xqtfwSliding in window.flags ) or (nextToken(true) = 'end')  then begin
        expect('end');
        parseWindowVars(window.endCondition);
      end;
    end;

  var temp: string;
    clause: TXQTermFlowerLet;
    patternclause: TXQTermFlowerLetPattern;
    isfor: boolean;
  begin
    case token of
      'let': begin
         isfor:=false;
         if (parsingModel = xqpmXPath2) then raiseInvalidModel('let is not supported in XPath 2.0');
      end;
      'for': isfor:=true;
      else raiseParsingError('XPST0003', 'Invalid flower: '+token);
    end;
    skipWhitespaceAndComment();
    if pos^ in ['s', 't'] then begin
      parseWindow;
      token := nextToken();
      exit;
    end;
    repeat
      if pos^ <> '<' then begin
        if isfor then result.push(TXQTermFlowerFor.Create)
        else result.push(TXQTermFlowerLet.Create);
        clause := TXQTermFlowerLet(result.children[high(result.children)]);
        with clause do begin
          loopvar := parseFlowerVariable;

          temp := nextToken;
          if temp = 'as' then begin
            requireXQuery;
            sequenceTyp := parseSequenceType([]);
            temp := nextToken;
          end else sequenceTyp := nil;

          if kind = xqtfcFor then begin

            if temp = 'allowing' then begin
              requireXQuery3;
              expect('empty');
              TXQTermFlowerFor(clause).allowingEmpty := true;
              temp := nextToken;
            end;

            if temp = 'at' then begin
              requireXQuery;
              TXQTermFlowerFor(clause).positionvar := parseFlowerVariable;
              temp := nextToken;
            end;

            if temp <> 'in' then raiseSyntaxError('Expected "in".')
          end else
            if temp <> ':=' then raiseSyntaxError('Expected ":=".');

          expr := parse();
        end;
      end else begin
        if isfor then patternclause := TXQTermFlowerForPattern.Create
        else patternclause := TXQTermFlowerLetPattern.Create;
        result.push(patternclause);
        with patternclause do begin
          patternclause.pattern := parsePatternMatcher;
          temp := nextToken;
          if temp = 'as' then begin
            requireXQuery;
            sequenceTyp := parseSequenceType([]);
            temp := nextToken;
          end else sequenceTyp := nil;
          case kind of
            xqtfcLetPattern: if temp <> ':=' then raiseSyntaxError('Expected ":=".');
            xqtfcForPattern: if temp <> 'in' then raiseSyntaxError('Expected "in".');
          end;
          expr := parse();
        end;
      end;
      token := nextToken();
      skipWhitespaceAndComment();
    until token <> ',';
  end;

  procedure parseGroupClauseAndNextToken;
  var
    group: TXQTermFlowerGroup;

    procedure parseSpec;
    var
      let: TXQTermFlowerLet;
    begin
      SetLength(group.vars, length(group.vars) + 1);
      SetLength(group.seqtypes, length(group.seqtypes) + 1);
      group.vars[high(group.vars)] := parseFlowerVariable;
      skipWhitespaceAndComment();
      if pos^ in ['a', ':'] then begin
        let := TXQTermFlowerLet.Create;
        let.loopvar := TXQTermVariable(txqterm(group.vars[high(group.vars)]).clone);
        if pos^ = 'a' then begin
          expect('as');
          //let.sequenceTyp := parseSequenceType([]);
          group.seqtypes[high(group.seqtypes)] := parseSequenceType([]); //need to test the atomized value, let would test the original
        end;
        expect(':=');
        let.expr := parse;
        SetLength(result.children, length(result.children) + 1);
        result.children[high(result.children) - 1] := let;
        result.children[high(result.children)] := group;
      end;
    end;

  begin
    expect('by');

    group := TXQTermFlowerGroup.Create;
    result.push(group);
    parseSpec;
    while pos^ = ',' do begin
      inc(pos);
      parseSpec;
    end;
    token := nextToken();
    if token = 'collation' then begin
      group.collation := parseString;
      token := nextToken();
    end;
  end;

var
  hadOrder: boolean;
  hadWhere: Boolean;
  procedure parseOrderClauseAndNextToken;
  var
    clause: TXQTermFlowerOrder;
    temp: TXQTerm;
    i, j: Integer;
  begin
    if token = 'stable' then expect('order'); //always be stable
    expect('by');
    i := length(Result.children);
    repeat
      clause := TXQTermFlowerOrder.Create;
      result.push(clause);
      with clause do begin
        expr := parse();
        token := nextToken;

        if (token = 'ascending') or (token = 'descending') then begin
          descending := token = 'descending';
          token := nextToken;
        end;

        emptyOrder := xqeoStatic;
        if token = 'empty' then begin
          token := nextToken;
          if token = 'greatest' then emptyOrder := xqeoEmptyGreatest
          else if token = 'least' then emptyOrder := xqeoEmptyLeast
          else raiseSyntaxError('Expected "greatest" or "least"');
          token := nextToken;
        end;

        if token = 'collation' then begin
          collation := nextToken;
          if (collation = '') or not (collation[1] in ['''', '"']) or (collation[1] <> collation[length(collation)]) then raiseParsingError('XPST0003', 'Invalid collation');
          collation := copy(collation, 2, length(collation) - 2);
          token := nextToken;
        end
      end;
    until token <> ',';
    //reverse order sub clauses
    j := high(result.children);
    while j > i do begin
      temp := result.children[i];
      result.children[i] := result.children[j] ;
      result.children[j] := temp;
      inc(i); dec(j);
    end;
  end;
begin
  result := TXQTermFlower.Create;
  hadOrder := false;
  hadWhere := false;
  try
    token := akind;
    while token <> 'return' do begin
      case token of
        'let', 'for': begin
          if Length(Result.children) > 0 then requireXQuery();
          parseInitialClauseAndNextToken;
        end;
        'where': begin
          if hadOrder or hadWhere then requireXQuery3()
          else requireXQuery();
          hadWhere := true;
          result.push(TXQTermFlowerWhere.Create);
          TXQTermFlowerWhere(result.children[high(result.children)]).test := parse;
          token := nextToken();
        end;
        'stable', 'order': begin
          if hadOrder then requireXQuery3()
          else requireXQuery();
          hadOrder := true;
          parseOrderClauseAndNextToken;
        end;
        'count': begin
          requireXQuery3();
          result.push(TXQTermFlowerCount.Create);
          TXQTermFlowerCount(result.children[high(result.children)]).countvar := parseFlowerVariable;

          token := nextToken();
        end;
        'group': begin
          requireXQuery3();
          parseGroupClauseAndNextToken;
        end;
        'return': exit;
        else raiseSyntaxError('Expected return ');
      end;
    end;
    result.push(parse);
  except
    on EXQParsingException do begin result.free; raise; end;
  end;
end;

function TXQParsingContext.parseSomeEvery(const akind: string): TXQTermSomeEvery;
var
  word: String;
begin
  result := TXQTermSomeEvery.Create(akind = 'every');
  try
    result.push(parseVariable);
    skipWhitespaceAndComment();
    if pos^ = 'a' then begin expect('as'); result.push(parseSequenceType([])); end;
    expect('in'); result.push(parse());
    word := nextToken();
    while word = ',' do begin
      result.push(parseVariable);
      skipWhitespaceAndComment();
      if pos^ = 'a' then begin expect('as'); result.push(parseSequenceType([])); end;
      expect('in'); result.push(parse());
      word := nextToken();
    end;
    Assert(word = 'satisfies');
    result.push(parse());
  except
    result.free;
    raise;
  end;
end;

function TXQParsingContext.parseTypeSwitch: TXQTermTypeSwitch;
var
  word: String;
  tempSeq: TXQTermSequence;
begin
  requireXQuery('for typeswitch statement');
  result := TXQTermTypeSwitch.Create;
  try
    expect('(');
    result.push(parsePrimaryLevel());
    expect(')');

    word := nextToken();
    while word = 'case' do begin
      skipWhitespaceAndComment();
      tempSeq := TXQTermSequence.Create;
      result.push(tempSeq);
      if pos^ = '<' then begin
        tempSeq.push(parsePatternMatcher());
      end else begin
        if pos^ = '$' then begin tempSeq.push(parseVariable); expect('as'); end;
        tempSeq.push(parseSequenceTypeUnion());
      end;
      expect('return');
      tempSeq.push(parse());
      word := nextToken();
    end;
    if word <> 'default' then raiseParsingError('XPST0003', 'expected "default" clause');
    skipWhitespaceAndComment();
    tempSeq := TXQTermSequence.Create;
    result.push(tempSeq);
    if pos^ = '$' then tempSeq.push(parseVariable);
    expect('return');
    tempSeq.push(parse());
  except
    result.free;
    raise;
  end;
end;

function TXQParsingContext.parseSwitch: TXQTermSwitch;
var
  word: String;
  tempSeq: TXQTermSequence;
begin
  requireXQuery3('for switch statement');
  expect('(');
  result := TXQTermSwitch.Create;
  result.push(parsePrimaryLevel());
  expect(')');

  word := nextToken();
  if word <> 'case' then raiseSyntaxError('Need at least one case');
  while word = 'case' do begin
    skipWhitespaceAndComment();
    tempSeq := TXQTermSequence.Create;
    result.push(tempSeq);
    while word = 'case' do begin
      tempSeq.push(parse());
      word := nextToken();
    end;
    if word <> 'return' then raiseSyntaxError('expected return');
    tempSeq.push(parse());
    word := nextToken();
  end;
  if word <> 'default' then raiseSyntaxError('expected "default" clause');
  expect('return');
  result.push(parse());
end;

function TXQParsingContext.parseDirectConstructor(): TXQTermConstructor;
  procedure parseCommonContent(parent: TXQTermConstructor; border: char; atBoundary: boolean; mustBeLiteral: boolean = false);
    procedure pushElementContent(s: string);
    begin
      if length(s) = 0 then exit;
      if (length(parent.children) > 0)
         and (parent.children[high(parent.children)] is TXQTermConstant)
         and (TXQTermConstant(parent.children[high(parent.children)]).value is TXQValueString) then
        (TXQTermConstant(parent.children[high(parent.children)]).value as TXQValueString).str += s
      else
        parent.push(TXQTermConstant.create(xqvalue(s)));
    end;
    function strIsWhitespace(p: pchar; l: longint): boolean;
    begin
      if l = 0 then exit(true);
      strlTrimRight(p, l, WHITE_SPACE);
      result := l = 0;
    end;

  var marker: PChar;
    temp: TXQTerm;
  begin
    atBoundary := atBoundary and staticContext.stripBoundarySpace;
    while pos^ <> #0 do begin
      marker := pos;
      while not (pos^ in [#0, '{', '}', '&', '<']) and (pos^ <> border) and ((border = '<') or not (pos^ in [#9, #10, #13])) do pos+=1;

      if pos^ in [#9, #10, #13] then begin //whitespace normalization #9, #10, #13 => space
        pushElementContent(strFromPchar(marker, pos - marker));  //todo: multi byte whitespace
        if ((pos-1)^ <> #13) or (pos^ <> #10) then
          pushElementContent(' ');
        pos+=1;
        continue;
      end;

      if pos^ = #0 then raiseSyntaxError('Unexpected end');

      if not atBoundary or (pos^ in ['}', '&']) or strBeginsWith(pos, '<![') or not strIsWhitespace(marker, pos - marker) then begin
        pushElementContent(normalizeLineEnding(strFromPchar(marker, pos - marker)));
        atBoundary := false;
      end;

      if pos^ = border then begin
        if (pos^ in ['''', '"']) and ((pos+1)^ = border) then begin
          pushElementContent(border);
          pos+=2;
          continue;
        end else exit;
      end;

      case pos^ of
        '{': if (pos+1)^ <> '{' then begin
          if mustBeLiteral then raiseParsingError('XQST0022', 'Enclosed expression not allowed') ;
          pos += 1;
          temp := parsePrimaryLevel;
          if temp is TXQTermConstructor then parent.push(TXQTermSequence.Create().push([temp]))
          else parent.push(temp);
          expect('}');
          atBoundary := (border = '<') and staticContext.stripBoundarySpace;
        end else begin
          pushElementContent('{');
          pos+=2;
        end;
        '}': begin
          if (pos+1)^ <> '}' then raiseSyntaxError('Invalid closing parenthesis');
          pushElementContent('}');
          atBoundary:=false;
          pos += 2;
        end;
        '&': begin
          marker := pos;
          while not (pos^ in [#0, ';']) do pos += 1;
          if pos^ = #0 then raiseSyntaxError('Unexpected end');
          pos += 1;
          pushElementContent(replaceEntitiesAlways(strFromPchar(marker, pos - marker)));
          atBoundary:=false;
        end;
        '<': raiseSyntaxError('Unexpected <');
      end;
    end;
  end;

  function parsePIConstructor: TXQTermConstructor;
  var marker: PChar;
    name: String;
  begin
    expect('?');
    if pos^ in WHITE_SPACE then raiseSyntaxError('Unexpected space');
    name := nextTokenNCName();
    if striEqual(name, 'XML') or not (pos^ in (WHITE_SPACE + ['?'])) then raiseSyntaxError('Invalid PI name');
    result := TXQTermConstructor.create(tetProcessingInstruction, TXQTermConstant.create(xqvalue(name)));
    skipWhitespace();
    marker := pos;
    while (pos^ <> #0) and ((pos^ <> '?') or ((pos+1)^ <> '>')) do pos+=1;
    result.push(TXQTermConstant.create(xqvalue(strFromPchar(marker, pos - marker))));
    if pos^ = #0 then raiseSyntaxError('Unexpected end');
    expect('?>');
  end;

  function parseCommentConstructor: TXQTermConstructor;
  var marker: PChar;
  begin
    expect('!');
    expect('--');
    marker := pos;
    while (pos^ <> #0) and ((pos^ <> '-') or ((pos+1)^ <> '-')) do pos+=1;
    if pos^ = #0 then raiseSyntaxError('Unexpected end');
    result := TXQTermConstructor.create(tetComment, TXQTermConstant.create(strFromPchar(marker, pos - marker)));
    expect('-->');
  end;

  function nextTokenQName: string;
  var  namespaceUrl: string;
       namespacePrefix: string;
       name: string;
  begin
    if nextTokenEQName(namespaceUrl, namespacePrefix, name) = xqnmURL then
      raiseSyntaxError('Cannot use Q{} notation for direct constructors');
    if namespacePrefix = '' then result := name
    else result := namespacePrefix + ':' + name;
  end;

  procedure qnameToEQname(var vqname: IXQValue);
  var
    qname: String;
    prefix: String;
    namespace: INamespace;
  begin
    qname := vqname.toString;
    prefix := '';
    if system.pos(':', qname) > 0 then prefix := strSplitGet(':', qname);
    if (result.implicitNamespaces <> nil) and (Result.implicitNamespaces.hasNamespacePrefix(prefix)) then begin
      namespace := Result.implicitNamespaces.namespaces[prefix];
      if namespace.getURL = '' then namespace := nil;
    end else
      namespace := staticContext.findNamespace(prefix, xqdnkUnknown); //todo?
    if namespace <> nil then vqname := TXQValueQName.create(namespace.getURL, prefix, qname)
    else if prefix <> '' then raiseParsingError('XPST0081', 'Unknown namespace: '+vqname.toString)
    else vqname := TXQValueQName.create('', prefix, qname)
  end;

  procedure checkForDuplicatedAttributes;
  var
    i, j: Integer;
  begin
    for i := 0 to high(Result.children) do qnameToEQname(TXQTermConstant(TXQTermConstructor(result.children[i]).nameValue).value);
    for i := 0 to high(Result.children) do
      for j := 0 to high(Result.children) do
        if (i <> j)
           and (staticContext.compareAtomic(TXQTermConstant(TXQTermConstructor(result.children[i]).nameValue).value, TXQTermConstant(TXQTermConstructor(result.children[j]).nameValue).value, nil) = 0) then
           raiseParsingError('XQST0040', 'Duplicated attribute: '+TXQTermConstant(TXQTermConstructor(result.children[i]).nameValue).value.toString);
  end;

var
  token: String;
  marker: PChar;
  attribute: TXQTermConstructor;
  lastWasCData: Boolean;
  oldDefaultElementTypeNamespace: INamespace;
  prefix: String;
  isNamespaceNode: Boolean;
  oldNamespaceCount: Integer;
begin
  case pos^ of
    '!': exit(parseCommentConstructor);
    '?': exit(parsePIConstructor);
    #9,#10,#13,' ': raiseSyntaxError('Invalid whitespace in constructor');
  end;
  result := TXQTermConstructor.create(tetOpen, TXQTermConstant.create(nextTokenQName));
  try
    skipWhitespace();
    while not (pos^ in ['>', '/', #0]) do begin
      token := nextTokenQName;
      attribute := TXQTermConstructor.create(tetAttribute, TXQTermConstant.create(token));
      expect('=');
      skipWhitespace();
      if not (pos^ in ['''', '"']) then raiseSyntaxError('Expected attribute value');
      marker := pos;
      pos+=1;
      isNamespaceNode := strBeginsWith(token, 'xmlns:') or (token = 'xmlns');
      parseCommonContent(attribute, marker^, false, isNamespaceNode);
      expect(marker^);

      if isNamespaceNode then begin
        if token = 'xmlns' then prefix := ''
        else prefix := strCopyFrom(token, length('xmlns:')+1);
        if result.implicitNamespaces = nil then result.implicitNamespaces := TNamespaceList.Create
        else if result.implicitNamespaces.hasNamespacePrefix(prefix) then raiseParsingError('XQST0071', 'Duplicate namespace declaration');
        token := '';
        if length(attribute.children) > 0 then token := (attribute.children[0] as TXQTermConstant).value.toString;
        if ((prefix = 'xml') <> (token = XMLNamespaceUrl_XML)) or (prefix = 'xmlns') or (token = XMLNamespaceUrl_XMLNS) then
          raiseParsingError('XQST0070', 'Invalid namespace declaration');
        result.implicitNamespaces.add(TNamespace.create(xmlStrWhitespaceCollapse(token), prefix));
        attribute.Free;
      end else result.push(attribute);
      skipWhitespace();
    end;
    checkForDuplicatedAttributes;
    if pos^ = #0 then raiseSyntaxError('Attribute expected');
    if pos^ = '/' then begin
      expect('/');
      if pos^ <> '>' then raiseSyntaxError('Need >');
      inc(pos);
      exit;
    end;
    expect('>');

    oldDefaultElementTypeNamespace := staticContext.defaultElementTypeNamespace;
    if Result.implicitNamespaces <> nil then
      oldNamespaceCount := addNamespacesToStaticContext(result.implicitNamespaces, staticContext);

    lastWasCData := false;
    while pos^ <> #0 do begin
      parseCommonContent(result, '<', not lastWasCData);
      lastWasCData := false;

      if pos^ = #0 then raiseParsingError('XPST0003', 'Unexpected end');
      if pos^ = '<' then begin
        pos += 1;
        case pos^ of
          '/': begin
            pos += 1;
            if nextTokenQName() <> (result.nameValue as TXQTermConstant).value.toString then
              raiseParsingError('XQST0118', 'Expected matching closing tag');
            expect('>');
            staticContext.defaultElementTypeNamespace := oldDefaultElementTypeNamespace;
            if result.implicitNamespaces <> nil then
              staticContext.namespaces.deleteFrom(oldNamespaceCount);

            exit;
          end;
          '!': if strBeginsWith(pos, '![CDATA[') then begin
            lastWasCData := true;
            pos += length('![CDATA[');
            marker := pos;
            while (pos^ <> #0) and not strBeginsWith(pos, ']]>') do pos+=1;
            if pos^ = #0 then raiseParsingError('XPST0003', 'Unexpected end');
            result.push(TXQTermConstant.create(strFromPchar(marker, pos - marker)));
            pos+=3;
          end else if strBeginsWith(pos, '!--') then result.push(parseCommentConstructor)
          else raiseParsingError('XPST0003', 'Invalid character combination after <!');
          '?': result.push(parsePIConstructor);
          else result.push(parseDirectConstructor());
        end;
      end;
    end;
    raiseParsingError('XPST0003', 'Unexpected end (probably missing closing tag for <'+(result.nameValue as TXQTermConstant).value.toString +'>');

  except
    result.free;
    raise;
  end;
end;

function TXQParsingContext.parseComputedConstructor(name: string): TXQTermConstructor;
var
  token: String;
  tempSeq: TXQTerm;
  onlyConstructors: Boolean;
  i: Integer;
  expectName: Boolean;
  namespaceUrl: string;
  namespacePrefix: string;
  namespaceMode: TXQNamespaceMode;
begin
  token := name;
  if (token = 'element') then result := TXQTermConstructor.create(tetOpen)
  else if (token = 'document') then result := TXQTermConstructor.create(tetDocument)
  else if (token = 'attribute') then result := TXQTermConstructor.create(tetAttribute)
  else if (token = 'text') then result := TXQTermConstructor.create(tetText)
  else if (token = 'processing-instruction') then result := TXQTermConstructor.create(tetProcessingInstruction)
  else if (token = 'comment') then result := TXQTermConstructor.create(tetComment)
  else raiseParsingError('XPST0003', 'Unknown constructor name');
  try
    expectName := (result.typ in [tetOpen, tetProcessingInstruction, tetAttribute]) ;
    if expectName then begin
      skipWhitespaceAndComment();
      if pos^ = '{' then begin
        pos += 1;
        result.nameValue := parsePrimaryLevel;
        expect('}');
      end else begin
        namespaceMode := nextTokenEQName(namespaceUrl, namespacePrefix, token);
        if result.typ = tetProcessingInstruction then
          if (namespaceMode <> xqnmPrefix) or (namespacePrefix <> '') then
            raiseSyntaxError('Cannot use namespace for processing instructions');
        case namespaceMode of
          xqnmPrefix:
            if namespacePrefix = '' then result.nameValue := TXQTermConstant.create(token)
            else result.nameValue := TXQTermConstant.create(namespacePrefix + ':' + token);
          xqnmURL:
            result.nameValue := TXQTermConstant.create(TXQValueQName.create(namespaceUrl, namespacePrefix, token)); //is this even valid?
        end;
      end;
    end;
    expect('{');
    skipWhitespaceAndComment();
    if pos^ <> '}' then begin
      if result.typ in [tetDocument, tetOpen, tetProcessingInstruction, tetAttribute] then begin
        tempSeq := parsePrimaryLevel;
        if tempSeq is TXQTermSequence then begin
          onlyConstructors := true;
          for i:= 0 to high(TXQTermSequence(tempseq).children) do
            if not (TXQTermSequence(tempSeq).children[i] is TXQTermConstructor) then begin
              onlyConstructors:=false;
              break;
            end;
          if onlyConstructors then begin
            result.children := TXQTermSequence(tempseq).children;
            TXQTermSequence(tempseq).children := nil;
            tempSeq.free;
          end else result.push(tempSeq); //that's really slow for nodes because it makes a deep copy of them if they are taken from a subsequence. But if it's mixing atomic/nodes flattening the sequences makes the separator spaces wrong
        end else result.push(tempSeq);
      end else result.nameValue := parsePrimaryLevel;
    end else if not expectName then
      raiseParsingError('XPST0003', 'This type of node must not be empty ');
    expect('}');
  except
    result.free;
    raise;
  end;
end;

function TXQParsingContext.parseExtension: TXQTerm;
var
  pragma: String;
  url: string;
  prefix: string;
begin
  requireXQuery('for extensions');
  expect('#');
  if nextTokenEQName(url, prefix, pragma) = xqnmPrefix then
    if prefix = '' then raiseParsingError('XPST0003', 'Extension name requires namespace');
  //just ignore it
  while (pos^ <> #0) and ((pos^ <> '#') or ((pos+1)^ <> ')')) do
    pos += 1;
  if pos^ = #0 then raiseParsingError('XPST0003', 'Unexpected end');
  pos += 2;
  skipWhitespaceAndComment();
  if (pos^ = '(') and ((pos+1)^ = '#') then begin
    expect('(');
    exit(parseExtension());
  end;
  expect('{'); result := parsePrimaryLevel; expect('}');
end;

function TXQParsingContext.parseVariable: TXQTermPendingEQNameToken;
begin
  expect('$');
  Result := parsePendingEQName(xqptVariable);
end;

function TXQParsingContext.splitVariableForDotNotation(t: TXQTerm): TXQTerm;
var
  name: String;
  prop: String;
  pname: PAnsiString;
begin
  if t is TXQTermVariable then pname := @TXQTermVariable(t).value
  else if t is TXQTermPendingEQNameToken then pname := @TXQTermPendingEQNameToken(t).localpart
  else raiseSyntaxError('Internal error 201601102252');
  if not strContains(pname^, '.') then exit(t);
  name := pname^;
  pname^ := strSplitGet('.', name);
  result := t;
  for prop in strSplit(name, '.') do
    result := TXQTermReadObjectProperty.create(prop).push([result]);
end;

function TXQParsingContext.parseDefineVariable: TXQTermDefineVariable;
begin
  result := TXQTermDefineVariable.create(parseVariable);
  try
    if nextToken(true) = 'as' then begin
      expect('as');
      result.push(parseSequenceType([]));
    end;
  except
    result.free;
    raise;
  end;
end;


function TXQParsingContext.parseAnnotations: TXQAnnotations;
var
  namespaceUrl: string;
  namespacePrefix: string;
  local: string;
  mode: TXQNamespaceMode;
begin
  requireXQuery3('Annotations need XQuery 3');
  try
    setlength(result, 1);
    while true do begin
      with result[high(result)] do begin
        mode := nextTokenEQName(namespaceUrl, namespacePrefix, local);
        if (mode = xqnmPrefix) and (namespacePrefix = '') then begin
          namespaceUrl := XMLNamespaceURL_XQuery;
          mode := xqnmURL;
        end;
        name := TXQEQNameUnresolved.makeEQName(namespaceUrl, namespacePrefix, local, mode);
        SetLength(params, 0);
        if nextToken(true) = '(' then begin
          expect('(');
          while true do begin
            SetLength(params, length(params) + 1);
            params[high(params)] := parseValue;
            if not (params[high(params)] is TXQTermConstant) then raiseParsingError('XPST0003', 'Only literals allowed as annotation arguments');
            if nextToken(true) <> ',' then break;
            expect(',');
          end;
          expect(')')
        end;
      end;
      if nextToken(true) <> '%' then break;
      expect('%');
      setlength(result, length(result)+1);
    end;
  except
    freeAnnotations(result);
    raise;
  end;
end;

function TXQParsingContext.parseFunctionDeclaration(annotations: TXQAnnotations; anonymous: boolean): TXQTermDefineFunction;
var
  tempVar: TXQTermDefineVariable;
  i: Integer;
begin
  try
    result := TXQTermDefineFunction.create();
    result.annotations := annotations;
    if not anonymous then begin
      result.name := parseEQNameWithPrefix;
      //since functions can only be defined in the module declarations, all static namespaces are known here
      if result.name is TXQEQNameUnresolved then
        result.name := TXQEQNameUnresolved(result.name).resolveAndFreeToEQNameWithPrefix(staticContext, xqdnkFunction);
      if result.name.namespaceURL = '' then raiseParsingError('XQST0060', 'No namespace for declared function: '+result.name.ToString);
      case result.name.namespaceURL of
        XMLNamespaceUrl_XML, XMLNamespaceURL_XMLSchema, XMLNamespaceURL_XMLSchemaInstance, XMLNamespaceURL_XPathFunctions:
          raiseParsingError('XQST0045', 'Invalid namespace for function declaration: '+result.name.ToString);
        XMLNamespaceURL_XPathFunctionsMath, XMLNamespaceURL_XQuery:
          if parsingModel = xqpmXQuery3 then
            raiseParsingError('XQST0045', 'Invalid namespace for function declaration: '+result.name.ToString);
      end;
      expect('(');
    end else require3('Anonymous functions need XPath/XQuery 3');
    skipWhitespaceAndComment();
    while nextToken(true) <> ')' do begin
      tempVar := parseDefineVariable;
      if not (tempVar.variable is TXQTermVariable) then
        tempVar.variable := (tempVar.variable as TXQTermPendingEQNameToken).resolveAndFree(staticContext) as TXQTermVariable;
      result.push(tempVar);
      for i := 0 to high(Result.children) - 1 do
        if TXQTermVariable(TXQTermDefineVariable(Result.children[i]).variable).equalsVariable(TXQTermVariable(tempVar.variable)) then
          raiseParsingError('XQST0039', 'Duplicate variable name: '+tempVar.ToString);
      skipWhitespaceAndComment();
      if not (pos^ in [',', ')']) then raiseParsingError('XPST0003', 'Missing , or )');
      if pos^ = ',' then pos+=1;
    end;
    pos+=1;
    result.parameterCount:=length(result.children);
    if nextToken(true) = 'as' then begin
      expect('as');
      result.push(parseSequenceType([]));
    end;
    case nextToken() of
      '{': begin
        result.push(parsePrimaryLevel);
        expect('}');
      end;
      'external': if anonymous then raiseSyntaxError('Anonymous function cannot be external');
      else raiseSyntaxError('Function body { } or external expected');
    end;
  except
    result.free;
    raise;
  end;
end;

function TXQParsingContext.parseTryCatch: TXQTermTryCatch;
var
  kind: TXQNamespaceMode;
  token: String;
  namespaceUrl: string;
  namespacePrefix: string;
  local: string;
begin
  expect('{');
  result := TXQTermTryCatch.Create(parsePrimaryLevel);
  try
    expect('}');
    token := nextToken(true);
    while token = 'catch' do begin
      expect('catch');
      SetLength(result.catches, length(result.catches) + 1);
      repeat
        SetLength(result.catches[high(result.catches)].tests, length(result.catches[high(result.catches)].tests) + 1);
        kind := nextTokenEQName(namespaceUrl, namespacePrefix, local, true);
        result.catches[high(result.catches)].tests[high(result.catches[high(result.catches)].tests)].ignoreNamespace := kind = xqnmNone;
        if kind = xqnmNone then
          result.catches[high(result.catches)].tests[high(result.catches[high(result.catches)].tests)].name := TXQEQName.create('', local)
         else
          result.catches[high(result.catches)].tests[high(result.catches[high(result.catches)].tests)].name := TXQEQNameUnresolved.makeEQName(namespaceUrl, namespacePrefix, local, kind);
        token := nextToken();
      until token <> '|';
      if token <> '{' then raiseSyntaxError('{ expected');
      result.catches[high(result.catches)].expr := parsePrimaryLevel;
      expect('}');
      token := nextToken(true);
    end;
  except
    result.free;
    raise;
  end;
end;


function TXQParsingContext.replaceEntitiesAlways(s: string): string;
var
  n, p: Integer;
  temp: string;
  code: Integer;
begin
  result := '';
  p := 1;
  n := strIndexOf(s, '&');
  while n > 0 do begin
    result += copy(s, p, n - p);
    p := n + 1;
    n := strIndexOf(s, ';', p);
    temp := copy(s, p, n - p);
    case temp of
      'lt': result += '<';
      'gt': result += '>';
      'amp': result += '&';
      'quot': result += '"';
      'apos': result += '''';
      else begin
        if (temp = '') or (temp[1] <> '#')  then raiseSyntaxError('Invalid entity');
        delete(temp,1,1);
        code := -1;
        if temp <> '' then
          case temp[1] of
            'x': code := StrToIntDef('$'+strcopyfrom(temp,2), -1);
            'X': ; //strToInt does hex with x
            else code := StrToIntDef(temp, -1);
          end;
        if code < 0 then raiseSyntaxError('Invalid entity');
        if code = 0 then raiseParsingError('XQST0090', '0 is not allowed in strings');
        result += strGetUnicodeCharacter(code, staticContext.stringEncoding)
      end;
    end;
    p := n + 1;
    n := strIndexOf(s, '&', n);
  end;
  result += strcopyfrom(s, p);
end;

function TXQParsingContext.replaceEntitiesIfNeeded(const s: string): string;
begin
  result := s;
  if ((parsingModel in [xqpmXQuery1,xqpmXQuery3]) and (options.StringEntities = xqseDefault)) or (options.StringEntities = xqseResolveLikeXQuery) then
    Result := replaceEntitiesAlways(Result);
end;


function TXQParsingContext.parseString(const w: string): string;
begin
  result := replaceEntitiesIfNeeded(normalizeLineEnding(StringReplace(copy(w,2,length(w)-2), w[1]+w[1], w[1], [rfReplaceAll])));
end;

function TXQParsingContext.parseString: string;
begin
  skipWhitespaceAndComment();
  if not (pos^ in ['''', '"']) then raiseParsingError('XPST0003', 'Expected string');
  result := parseString(nextToken());
end;

function TXQParsingContext.parseXString(nullTerminatedString: boolean): TXQTerm;
  function functionIsConcat(nf: TXQTermNamedFunction): boolean;
  begin
    result := (nf.func <> nil) and (nf.func is TXQBasicFunctionInfo) and (TXQBasicFunctionInfo(nf.func).func = @xqFunctionConcat);
  end;

  procedure pushTerm(t: TXQTerm);
  begin
    if not (t is TXQTermConstant) then
      t := TXQTermNamedFunction.create(XMLNamespaceUrl_MyExtensions, 'join', [t]);
    if (result = nil) and (t is TXQTermConstant) then
      result := t
    else if result = nil then
      result := t//TXQTermNamedFunction.create(XMLNamespaceUrl_XPathFunctions, 'concat', [t])
    else if (result is TXQTermNamedFunction) and functionIsConcat(TXQTermNamedFunction(result)) then
      TXQTermNamedFunction(result).push(t)
    else
     result := TXQTermNamedFunction.create(XMLNamespaceUrl_XPathFunctions, 'concat', [result, t]);
  end;

  procedure pushRaw(from, too: pchar);
  var
    v: String;
  begin
    if too < from then exit;
    v := replaceEntitiesIfNeeded(normalizeLineEnding(strFromPchar(from, too - from + 1)));
    if result <> nil then begin
      if (result is TXQTermConstant) and (TXQTermConstant(result).value is TXQValueString) then
        (TXQTermConstant(result).value as TXQValueString).str += v
      else if (result is TXQTermNamedFunction) and functionIsConcat(TXQTermNamedFunction(result))
              and (TXQTermNamedFunction(result).children[high(TXQTermNamedFunction(result).children)] is TXQTermConstant)
              and (TXQTermConstant(TXQTermNamedFunction(result).children[high(TXQTermNamedFunction(result).children)]).value is TXQValueString )
              then
        (TXQTermConstant(TXQTermNamedFunction(result).children[high(TXQTermNamedFunction(result).children)]).value as TXQValueString).str += v
      else pushTerm(TXQTermConstant.create(v));
    end else pushTerm(TXQTermConstant.create(v));
  end;
var
  strsymb: Char;
  mark: PChar;
begin
  result := nil;
  if nullterminatedString then strsymb := #0
  else begin
    strsymb := pos^;
    pos+=1;
    if not (strsymb in ['''', '"']) then raiseParsingError('pxp:XPST0003', 'Expected string start');
  end;
  mark := pos;
  try
    while pos^ <> #0 do begin
      while (pos^ <> strsymb) and not (pos^ in [#0, '{', '}']) do pos+=1;
      pushRaw(mark, pos - 1);
      if pos^ = #0 then begin mark := pos; break; end;
      if pos^ = (pos+1)^ then begin //escaped like {{, '', "", }}
        pos+=1;
        mark := pos;
        pos+=1;
      end else case pos^ of
        '}': raiseParsingError('pxp:XPST0003',  'Single closing } not allowed in extended strings (use }})');
        '{': begin
          pos+=1;
          pushTerm(parsePrimaryLevel);
          expect('}');
          mark := pos;
        end;
        else begin //string closed
          expect(strsymb);
          break;
        end;
      end;
    end;
    if nullterminatedString then pushRaw(mark, pos - 1);
  except
    on EXQParsingException do begin result.free; raise; end;
  end;
  if result = nil then result := TXQTermConstant.create('')
  else if (result is TXQTermConstant) and not (TXQTermConstant(result).value is TXQValueString) then
    result := TXQTermNamedFunction.create(XMLNamespaceUrl_XPathFunctions, 'string', [result]);
end;

function TXQParsingContext.parseJSONLikeObjectConstructor: TXQTermWithChildren;
var
  token: String;
  jn: TXQNativeModule;
begin
  //expect('{'); parsed by caller
  if pos^ = '|' then begin
    expect('|');
    jn := TXQueryEngine.findNativeModule('http://jsoniq.org/functions');
    if jn = nil then raiseParsingError('pxp:JSONIQ', 'The {| .. |} syntax can only be used, if the json unit is loaded.');
    result := TXQTermNamedFunction.create();
    TXQTermNamedFunction(result).kind := xqfkBasic;
    TXQTermNamedFunction(result).func := jn.findBasicFunction('object', 1, xqpmXPath2);
    result := parseSequenceLike(result, '|');
    expect('}');
    exit;
  end;
  result := TXQTermJSONObjectConstructor.create();
  try
    skipWhitespaceAndComment();
    if pos^ = '}' then begin expect('}'); exit;end;
    repeat
      result.push(parse);
      expect(':');
      //if not (result.children[high(result.children)] is TXQTermString) then raiseParsingError('pxp:OBJ','Expected simple string, got: '+result.children[high(result.children)].ToString); //removed as json-iq allows variables there
      skipWhitespaceAndComment();
      result.push(parse);
      token := nextToken();
    until (token <> ',');
    if token <> '}' then raiseParsingError('pxp:OBJ', 'Expected "}" or ",", but got '+token);
  except
    FreeAndNil(result);
    raise
  end;
end;

function TXQParsingContext.parseJSONLikeArray: TXQTermJSONArray;
begin
  //expect('['); parsed by caller
  result := parseSequenceLike(TXQTermJSONArray.Create, ']') as TXQTermJSONArray;
end;

function createDynamicErrorTerm(const code, msg: string): TXQTermNamedFunction;
begin
  result := TXQTermNamedFunction.create(XMLNamespaceURL_XPathFunctions, 'error', [
                TXQTermConstant.create(TXQValueQName.create(XMLNamespaceURL_XQTErrors, 'err', code)),
                TXQTermConstant.create(msg)]);
end;

function staticallyCastQNameAndNotation(term: TXQTermWithChildren; typ: TXSType; staticContext: TXQStaticContext; castable: boolean = false): txqterm;
  function castFail(code: string): txqterm;
  begin
    if castable then result := TXQTermConstant.create(xqvalueFalse)
    else result := createDynamicErrorTerm(code, 'Invalid cast to QName/NOTATION');
  end;

var
  name: String;
  namespace: INamespace;
begin
  result := term;
  if typ.storage = TXQValueQName then begin
    if typ = baseSchema.NOTATION then result := castFail('XPST0080')
    else if (term.children[0] is TXQTermConstant) then begin
      case TXQTermConstant(term.children[0]).value.kind of
        pvkQName: exit; {begin
          if castable then result := TXQTermConstant.create(xqvalueTrue)
          else begin
            result := term.children[0];
            term.children[0] := nil;
          end;
        end;}
        pvkString: begin
          name := trim(TXQTermConstant(term.children[0]).value.toString);
          if not (baseSchema.isValidQName(name)) then result := castFail('FORG0001')
          else if castable then result := TXQTermConstant.create(xqvalueTrue)
          else if (staticContext.model in [xqpmXPath3, xqpmXQuery3]) then exit
          else begin
            //see  TXQTermSequenceType.staticQNameCast
            if pos(':', name) > 0 then begin
              namespace := staticContext.findNamespace(strSplitGet(':', name), xqdnkElementType);
              if namespace = nil then result := createDynamicErrorTerm('FONS0004', 'Failed to find namespace of: '+TXQTermConstant(term.children[0]).value.toString)
              else result := TXQTermConstant.Create(TXQValueQName.create(typ, namespace, name));
            end else result := TXQTermConstant.Create(TXQValueQName.create(typ, staticContext.findNamespace('', xqdnkElementType), name));
          end;
        end
        else result := castFail('XPTY0004')
      end;
    end;
    if result <> term then term.free;
  end;
end;

function StrToIntWithError(const s: string): integer;
var
  i: Integer;
begin
  result := StrToIntDef(s, -1);
  if result = -1 then begin
    for i := 1 to length(s) do if not (s[i] in ['0'..'9']) then raise EXQEvaluationException.create('XPST0003', 'Invalid number: '+s);
    raise EXQEvaluationException.create('FOAR0002', 'Invalid number: '+s);
  end;
end;

function TXQParsingContext.parseValue: TXQTerm;
var
  word: String;
  wordlookahead: String;
  temp: PChar;
  constr: Boolean;
  annotations: TXQAnnotations;
  namespaceURL: String;
  namespacePrefix: String;
  axis: String;
  namespaceMode: TXQNamespaceMode;
  marker: PChar;



  function parseVariableWithDotNotation: TXQTerm;
  var
    operatorMode: Boolean;
    propertyAccess: Boolean;
    v: TXQTermPendingEQNameToken;
  begin
    v := parseVariable;
    result := v;
    operatorMode := false;
    if (options.AllowPropertyDotNotation = xqpdnAllowFullDotNotation) and strContains(v.localpart, '.') then begin
      propertyAccess := true;
      operatorMode := strEndsWith(v.localpart, '.');
      if operatorMode then begin
        delete(v.localpart, length(v.localpart), 1);
        propertyAccess := strContains(v.localpart, '.');
      end;
      if propertyAccess then
        result := splitVariableForDotNotation(result);
    end else if (options.AllowPropertyDotNotation = xqpdnAllowUnambiguousDotNotation) and strEndsWith(v.localpart, '.') then begin
      skipWhitespaceAndComment();
      operatorMode := pos^ in ['"', '''', '$'];
      if operatorMode then
        delete(v.localpart, length(v.localpart), 1);
    end;
    if operatorMode then begin
      result := TXQTermDynamicFunctionCall.create(result, parseValue());
      if TXQTermDynamicFunctionCall(result).children[1] is TXQTermNodeMatcher then begin
        result.free;
        raiseParsingError('pxp:XPST0003', 'A node matching step is not allowed directly after a property dot operator');
      end;
    end;
  end;

begin
  result := nil;
  skipWhitespaceAndComment();
  if pos^ = #0 then exit();
  case pos^ of
    '''', '"':  exit(TXQTermConstant.create(parseString()));
    '$': exit(parseVariableWithDotNotation());
    '-', '+': begin
      word := nextToken() + 'u';
      exit(TXQTermBinaryOp.create(word, TXQTermConstant.create(xqvalue()), parseValue()));
    end;
    '(': begin
      inc(pos);
      if pos^ = '#' then exit(parseExtension);
      result := TXQTermSequence.Create;
      try
        exit(parseSequenceLike(TXQTermWithChildren(result))); //only sequence or priority brackets
      except
        result.free;
        raise;
      end;
    end;


    '/': begin
      word := nextToken();
      if pos^ = '/' then begin expect('/'); word+='/';end;
      skipWhitespaceAndComment();
      if (pos^ in [#0,',',')',']','}','=','!','>','[','|','+',';']) or ((pos^ = '<') and (parsingModel in [xqpmXPath2, xqpmXPath3])) then
        exit(TXQTermNodeMatcher.Create('/')) //leading lone slash (see standard#parse-note-leading-lone-slash)
      else exit(TXQTermBinaryOp.Create(word, TXQTermNodeMatcher.Create('/'), parseValue()));
    end;

    '0'..'9': exit(TXQTermConstant.createNumber(nextToken()));
    '.': begin
      word := nextToken();
      if (word = '.') or (word = '..') then exit(TXQTermNodeMatcher.Create(word))
      else if word[2] in ['0'..'9', 'e', 'E'] then exit(TXQTermConstant.createNumber(word))
      else raiseParsingError('XPST0003', 'Unknown term: '+word);
    end;

    '<': begin
      requireXQuery('to use constructors (this error can also mean an invalid < )');
      inc(pos);
      exit(parseDirectConstructor());
    end;

    '{': begin
      if not options.AllowJSON then raiseParsingError('XPST0003', 'Unexpected {. (Enable json extension (e.g. by including xquery_json), to create a json like object) ');
      inc(pos);
      exit(parseJSONLikeObjectConstructor);
    end;
    '[': begin
      if not options.AllowJSON then raiseParsingError('XPST0003', 'Unexpected [. (Enable json extension (e.g. by including xquery_json), to create a json like array) ');
      inc(pos);
      exit(parseJSONLikeArray());
    end;
    '%': begin
      inc(pos);
      annotations := parseAnnotations;
      expect('function'); expect('(');
      exit(parseFunctionDeclaration(annotations, true));
    end;
    'x': if ((pos+1)^ in ['"', '''']) then begin
      if not options.AllowExtendedStrings then raiseParsingError('err:XPST0003', 'Extended string syntax was disabled');
      inc(pos);
      exit(parseXString());
    end;
  end;

  try
    axis := '';
    namespaceURL := '';
    namespacePrefix := '';
    marker := pos;
    word := nextToken();
    if word = '@' then axis := 'attribute'
    else if nextToken(true) = '::' then begin
      axis := word;
      expect('::');
    end else pos := marker; //roll back
    namespaceMode := nextTokenEQName(namespaceURL, namespacePrefix, word, true);

    skipWhitespaceAndComment();
    case pos^ of
      '(': begin
        expect('(');
        if namespacePrefix = '' then begin
          case word of
            'function': if parsingModel in [xqpmXQuery3, xqpmXPath3] then exit(parseFunctionDeclaration(nil, true));
          end;

          if isKindTestFunction(word) then begin
            result := TXQTermNodeMatcher.Create(word, true);
            TXQTermNodeMatcher(result).namespaceCheck := xqnmNone;
            if strContains(word, 'attribute') and (axis = '') then axis := 'attribute';
            TXQTermNodeMatcher(result).axis:=axis;
            skipWhitespaceAndComment();
            if pos^ <> ')' then begin
              with TXQTermNodeMatcher(result) do begin
                case word of
                  'processing-instruction': begin
                    skipWhitespaceAndComment();
                    if pos^ in ['"', ''''] then push(TXQTermConstant.create(parseString()))
                    else push(TXQTermConstant.create(nextTokenNCName()))
                  end;
                  'element', 'schema-element', 'attribute', 'schema-attribute', 'document-node': begin
                    push(parseValue());
                    if (not (children[0] is TXQTermNodeMatcher)) or
                       ((word <> 'document-node') and (length(TXQTermNodeMatcher(children[0]).children) > 0)) then
                         raiseSyntaxError('Invalid test');
                  end;
                  else raiseSyntaxError('No option allowed for matching test: '+word);
                end;
              end;
              skipWhitespaceAndComment();
              if pos^ = ',' then begin
                if (word <> 'element') and (word <> 'attribute') then
                  raiseParsingError('XPST0003', 'Only one parameter is allowed for matching test '+word);
                expect(',');
                TXQTermNodeMatcher(result).push(parseSequenceType([xqstAllowValidationTypes]));
              end;
            end;
            expect(')');
            if (word <> 'node') and (axis <> 'self') and ( (axis = 'attribute') <> (strContains(word, 'attribute')) ) then begin
              result.free;
              result := TXQTermSequence.create();
            end;
            exit;
          end;
          if axis <> '' then raiseParsingError('XPST0003', 'Not an kind/node test');
        end;


        if namespaceURL = '' then
          namespaceURL := staticContext.findNamespaceURL(namespacePrefix, xqdnkFunction);
        if namespaceURL = '' then raiseParsingError('XPST0017', 'No namespace given for function '+word);
        //result := TXQTermNamedFunction.createIfExists(namespaceURL, namespa word, parsingModel);

        result := TXQTermNamedFunction.create();
        TXQTermNamedFunction(result).name := TXQEQNameUnresolved.makeEQName(namespaceURL, namespacePrefix, word, namespaceMode);
        result := parseFunctionCall(TXQTermNamedFunction(result));
        exit();
      end;
      '{': case word of
        'unordered', 'ordered': begin //TODO: actually use that
           requireXQuery();
           expect('{'); result := parse(); expect('}');
           exit;
         end;
      end;
      '#': begin
        require3('Named Function Reference');
        expect('#');
        result := TXQTermNamedFunction.create();
        TXQTermNamedFunction(result).name := TXQEQNameUnresolved.makeEQName(namespaceURL, namespacePrefix, word, namespaceMode);
        result := TXQTermDefineFunction.CreateReference(TXQTermNamedFunction(result), StrToIntWithError(nextToken()));
        TXQTermDefineFunction(result).name := TXQEQNameUnresolved.makeEQNameWithPrefix(namespaceURL, namespacePrefix, word, namespaceMode);
        exit(result);
      end;
    end;

    if (namespaceMode = xqnmPrefix) and (namespacePrefix = '') then
      case word of
        'element', 'attribute', 'document', 'text', 'processing-instruction', 'comment': begin
          skipWhitespaceAndComment();
          constr := nextToken(true) = '{';
          if (not constr) and (pos^ <> #0) and not (pos^ in SYMBOLS) then begin //look for name (this will allow something like text name {...} here, but that's going to raise an error later anyways)
            temp := pos;
            nextTokenEQName(namespaceURL, namespacePrefix, wordlookahead, true);
            if nextToken() = '{' then constr := true;
            pos := temp;
          end;
          if constr then begin
            requireXQuery('to use constructors');
            exit(parseComputedConstructor(word));
          end;
        end;
        'validate': case nextToken(true) of
          'lax', 'strict', '{': begin
            requireXQuery('for schema validation');
            if pos^ <> '{' then
              nextToken();
            expect('{');
            raiseParsingError('XQST0075', 'Schema validation is not supported');
          end;
        end;
      end;

    if (word = '') or (word[1] in [',', ';', ':', ')', ']', '}']) then //todo: check if valid xml node name
      raiseParsingError('XPST0003', 'Unexpected character: ' + word);

    //if (not staticContext.useLocalNamespaces) and (namespacePrefix <> '*') and ((namespacePrefix <> '') or (word <> '*'))  then
    //  namespaceURL := staticContext.findNamespaceURL(namespacePrefix, xqdnkElementType);
    result := TXQTermNodeMatcher.Create();
    TXQTermNodeMatcher(result).select := word;
    if namespaceMode = xqnmPrefix then namespaceURL := namespacePrefix;

    TXQTermNodeMatcher(result).namespaceCheck := namespaceMode;
    TXQTermNodeMatcher(result).namespaceURLOrPrefix := namespaceURL;
    TXQTermNodeMatcher(result).axis:=axis;
  except
    result.free;
    raise;
  end;
end;

function TXQParsingContext.parse: TXQTerm;
  function checkForPatternMatching: boolean; //i really abused the grammar there
  var
    submarker: PChar;
  begin
    submarker := pos;
    result := false;
    if nextToken() = '<' then begin
      nextToken();
      result := nextToken() = '>';
    end;
    pos := submarker;
  end;

var
  marker: PChar;
  token: String;
begin
  skipWhitespaceAndComment();
  marker := pos;
  token := nextToken(false);
  case token of
    'for': case nextToken(true) of
      '$','tumbling', 'sliding': exit(parseFlower(token));
      '<': if checkForPatternMatching then exit(parseFlower(token));
    end;
    'let': if (parsingModel in [xqpmXPath3, xqpmXQuery1, xqpmXQuery3] ) then
      case nextToken(true) of
        '$': exit(parseFlower(token));
        '<': if checkForPatternMatching then exit(parseFlower(token));
      end;
    'some', 'every': if nextToken(true) = '$' then
      exit(parseSomeEvery(token));
    'switch': if (parsingModel = xqpmXQuery3) and (nextToken(true) = '(') then
      exit(parseSwitch);
    'typeswitch': if parsingModel in PARSING_MODEL_XQUERY then
      exit(parseTypeSwitch);
    'if': if nextToken(true) = '(' then begin
      expect('(');
      result := TXQTermIf.Create();
      with TXQTermIf(result) do begin
        push(parsePrimaryLevel);
        expect(')'); expect('then');
        push(parse());
        expect('else');
        push(parse());
      end;
      exit;
    end;
    'try': if (parsingModel = xqpmXQuery3) and (nextToken(true) = '{') then
      exit(parseTryCatch);
  end;
  pos := marker;
  result := parseOrExpr;
end;




function TXQParsingContext.parseOrExpr: TXQTerm;
  //searchs the term to split
  //e.g.
  //          to                          to
  //        1     +        * 4      =>  1     +
  //            2    3                      2    3 <- * 4
  //takes a pointer to a txqterm, since it sets the variable that should be changed
  //(parentheses can be ignored since they are stored as sequence terms in the tree)
  function ripBinOpApart(term: pxqterm; const prio: integer): PXQTerm;
  var
    binOp: TXQTermBinaryOp;
  begin
    if not (term^ is TXQTermBinaryOp) then exit(term);
    binOp := TXQTermBinaryOp(term^);
    if binOp.op.priority > prio then exit(term);
    if (binOp.op.priority = prio) then begin
      if (xqofAssociativeSyntax in binOp.op.flags) then exit(term);
      raiseSyntaxError('Operator requires parenthesis '+ binOp.op.name);
    end;
    result := ripBinOpApart(@binOp.children[1], prio);
  end;
var astroot: TXQTerm;

  function parseSomething: TXQTerm;
  begin
    result := parse();
    if result = nil then raiseParsingError('XPST0003', 'Unexpected query end');
  end;


  procedure pushBinaryOp(const opinfo: TXQOperatorInfo);
  var res: TXQTermBinaryOp;
      replace: PXQTerm;
    procedure handleCastStrangeness;
    var
      st: TXQTermSequenceType;
      isCast: Boolean;
    begin
      expect(res.op.followedBy); //assume we read instance of/cast/castable/treat as
      isCast := ((res.op.func = @xqvalueCastAs) or (res.op.func = @xqvalueCastableAs));
      if isCast then st := parseSequenceType([xqstIsCast])
      else st := parseSequenceType([]);
      res.push(st);
    end;

  begin
    expect(opinfo.name);
    if (opinfo.name[1] in ['a'..'z','A'..'Z']) and (pos^ in ['a'..'z','A'..'Z','0'..'9','.','-'])  then
      raiseSyntaxError('Need whitespace after operator');

    if opinfo.require3 then require3();

    replace := ripBinOpApart(@astroot, opinfo.priority);

    res := TXQTermBinaryOp.Create(opinfo);
    res.push(replace^);
    replace^ := res;

    if res.op.followedBy <> '' then handleCastStrangeness
    else begin
      res.push(parseValue());
      if res.children[high(res.children)] = nil then raiseParsingError('XPST0003', 'Unexpected query end');
    end;
  end;

  var word: string;
    replace: PXQTerm;

  procedure parseDotOperator;
  var prop: string;
    needDynamicCall: Boolean;
  begin
    replace := ripBinOpApart(@astroot, 10000);
    if (replace^ is TXQTermFilterSequence) or (replace^ is TXQTermSequence) or (replace^ is TXQTermVariable)  or ((replace^ is TXQTermPendingEQNameToken) and (TXQTermPendingEQNameToken(replace^).pending = xqptVariable))
       or (replace^ is TXQTermNamedFunction) or (replace^ is TXQTermJSONObjectConstructor) or (replace^ is TXQTermDynamicFunctionCall) then begin
         if pos^ in SYMBOLS + WHITE_SPACE then needDynamicCall:=true
         else begin
           word := nextToken();
           for prop in strSplit(word, '.') do begin
             if prop = '' then raiseParsingError('XPST0003', 'Unexpected ..');
             replace^ := TXQTermReadObjectProperty.Create(prop).push([replace^]);
           end;
           needDynamicCall:=strEndsWith(word, '.');
         end;
         if needDynamicCall then begin
           replace^ := TXQTermDynamicFunctionCall.Create(replace^, parseValue);
           if TXQTermDynamicFunctionCall(replace^).children[1] is TXQTermNodeMatcher then
             raiseParsingError('pxp:XPST0003', 'A node matching step is not allowed directly after a property dot operator');
         end;
     end else begin
       raiseParsingError('XPST0003', 'Unexpected .');
     end;
  end;
var
  op: TXQOperatorInfo;
begin
  astroot := parseValue();
  try
    while true do begin
      word := nextToken(true);
      case word of
        '', ',', ';', ':', ')', ']', '}', 'else', 'return', 'satisfies', 'for', 'let', 'order', 'where', 'stable', 'end', 'only', 'ascending', 'descending', 'start', 'empty', 'group', 'collation', 'case', 'default', 'count':
          exit(astroot);
        '[': begin
          expect('[');
          skipWhitespaceAndComment();
          replace := ripBinOpApart(@astroot, 10000);
          if pos^ <> ']' then replace^ := TXQTermFilterSequence.Create(replace^, parsePrimaryLevel())
          else                replace^ := TXQTermFilterSequence.Create(replace^); //stupid hack to allow $var [] :=
          expect(']');
        end;
        '(': begin
          expect('('); skipWhitespaceAndComment();
          replace := ripBinOpApart(@astroot, 10000); //TODO: check
          replace^ := TXQTermDynamicFunctionCall.Create(replace^);
          replace^ := parseFunctionCall(TXQTermDynamicFunctionCall(replace^))
        end;
        ':=': begin
          expect(':=');
          result := astroot;
          if result is TXQTermNodeMatcher then begin
            case TXQTermNodeMatcher(astroot).namespaceCheck of
              xqnmNone: result := TXQTermVariable.create(TXQTermNodeMatcher(astroot).select);
              xqnmURL: result := TXQTermVariable.create(TXQTermNodeMatcher(astroot).select, TXQTermNodeMatcher(astroot).namespaceURLOrPrefix);
              xqnmPrefix: result := TXQTermPendingEQNameToken.create('', TXQTermNodeMatcher(astroot).namespaceURLOrPrefix, TXQTermNodeMatcher(astroot).select, xqnmPrefix, xqptVariable);
            end;
            FreeAndNil(astroot);
            astroot := result; //only astroot should contain allocated objects that need to be freed in case of a subsequent parsing error
            if (options.AllowPropertyDotNotation = xqpdnAllowFullDotNotation) then
              astroot := splitVariableForDotNotation(astroot);
          end;
          result := TXQTermDefineVariable.Create(astroot, parseSomething());
          //staticContext.splitRawQName(TXQTermDefineVariable(result).namespace, TXQTermDefineVariable(result).variablename, xqdnkUnknown);
          exit;
        end;
        '|': if options.AllowJSON and ((pos+1)^ = '}') then exit(astroot) // {| .. |} object merging syntax
             else pushBinaryOp(TXQueryEngine.findOperator(pos)); //| operator
        else begin
          op := TXQueryEngine.findOperator(pos);
          if op <> nil then pushBinaryOp(op)
          else if (word = '.') and (options.AllowPropertyDotNotation <> xqpdnDisallowDotNotation) then begin
            expect(word);
            parseDotOperator;
          end else
            raiseParsingError('XPST0003', 'Unknown or unexpected operator: '+word);
        end;
      end;
    end;
  except
    astroot.free;
    raise;
  end;
  result := astroot;
end;


{type


TParseFinalizer = class(TXQTerm_Visitor)
  sc: TXQStaticContext;
  function visit(var term: TXQTerm): TXQTerm_VisitAction; override;
end;
 function TParseFinalizer.visit(var term: TXQTerm): TXQTerm_VisitAction;
var
  bop: TXQTermBinaryOp;
  name: String;
  namespace: INamespace;
  nf: TXQTermNamedFunction;
begin
  if term is TXQTermBinaryOp then begin
    bop := TXQTermBinaryOp(term);
    if ((bop.op.func = @xqvalueCastAs) or (res.op.func = @xqvalueCastableAs))
       and (term.children[0] is TXQTermString)
       and ((term.children[1] as TXQTermSequenceType).atomicTypeInfo.derivedFrom([baseSchema.QName, baseSchema.NOTATION])) then begin
       name := TXQTermString(term.children[0]).value;
       sc.splitRawQName(namespace, name, xqdnkElementType);
       term := TXQTermNumber.create(TXQValueQName.create((term.children[1] as TXQTermSequenceType).atomicTypeInfo, ns, name));
       exit(xqtvaDeleteWithChildren);
    end;
  end else if term is TXQTermNamedFunction then begin
    nf := TXQTermNamedFunction(term);
    if (nf.kind = xqfkTypeConstructor)
       and (TXSType(nf.func).derivedFrom([baseSchema.QName, baseSchema.NOTATION]))
       and (length(nf.children) = 0) then begin

    end;
  end;
end;        }

function TXQParsingContext.parsePrimaryLevel: TXQTerm;
var
  temp: TXQTerm;
begin
  result := parse;
  try
    if nextToken(true) = ',' then begin
      result := TXQTermSequence.Create.push([result]);
      while nextToken(true) = ',' do begin
        expect(',');
        temp := parse();
        if temp = nil then raiseSyntaxError('Expression missing');
        TXQTermSequence(result).push(temp);
      end;
    end;
  except
    result.free;
    raise;
  end;
end;

procedure initializeFunctions(module: TXQTermModule; const context: TXQEvaluationContext);
var
  i: Integer;
  functions: array of TXQValueFunction;
  functionCount: Integer;
  children: array of TXQTerm;
  staticContext: TXQStaticContext;
  truechildrenhigh: integer;
  oldFunctionCount: Integer;
begin
  children := module.children;
  functionCount := 0;
  staticContext := context.staticContext;
  truechildrenhigh := high(children) -  ifthen(staticContext.moduleNamespace = nil, 1,0);
  for i:=0 to truechildrenhigh do
    if children[i] is TXQTermDefineFunction then
      functionCount += 1;
  oldFunctionCount := length(staticContext.functions);
  setlength(staticContext.functions, oldFunctionCount + functionCount);
  functions := staticContext.functions;
  functionCount := oldFunctionCount;
  for i:=0 to truechildrenhigh do
    if children[i] is TXQTermDefineFunction then begin
      functions[functionCount] := TXQTermDefineFunction(children[i]).define(context, true);
      if functions[functionCount].body = nil then begin
        if not assigned(staticContext.sender.OnDeclareExternalFunction) then raise EXQParsingException.create('XPDY0002', 'External function declared, but no callback registered to OnDeclareExternalFunction.');
        staticContext.sender.OnDeclareExternalFunction(staticContext.sender, staticContext, TXQTermDefineFunction(children[i]).name.namespaceURL, TXQTermDefineFunction(children[i]).name.localname, functions[functionCount]);
        if functions[functionCount].body = nil then raise EXQParsingException.create('XPDY0002','No function for external function ' + TXQTermDefineFunction(children[i]).name.localname + ' given.');
      end;
      functionCount+=1;
    end;
end;

procedure finalizeFunctionsEvenMore(module: TXQTermModule; sc: TXQStaticContext; cloneTerms: boolean);
var
  i: Integer;
  children: array of TXQTerm;
  functionCount: Integer;
  overriden: Integer;
  truechildrenhigh: integer;
  j: Integer;
begin
  children := module.children;

  truechildrenhigh := high(children) -  ifthen(sc.moduleNamespace = nil, 1,0);
  functionCount := 0;
  for i:=truechildrenhigh downto 0 do
    if children[i] is TXQTermDefineFunction then begin
      if cloneTerms then
        sc.functions[high(sc.functions) - functionCount].assignCopiedTerms(sc.functions[high(sc.functions) - functionCount]);
      functionCount += 1;
    end;

  for i := high(sc.functions) downto high(sc.functions) - functionCount + 1 do begin
    overriden := -1;
    for j := i - 1 downto 0 do
      if equalNamespaces(sc.functions[i].namespaceURL, sc.functions[j].namespaceURL) and (sc.functions[i].name = sc.functions[j].name) then begin
        overriden := j;
        break;
      end;
    if overriden >= 0 then begin
      sc.functions[overriden].free;
      sc.functions[overriden] := sc.functions[i];
      sc.functions[i] := sc.functions[high(sc.functions)];
      SetLength(sc.functions, high(sc.functions));
    end;
  end;
end;

function TXQParsingContext.parseModule: TXQTerm;
var
  pendings: TInterfaceList;
  otherQuery: TXQueryBreaker;
  i: Integer;
  hadPending: Boolean;
  shared: Boolean;
begin
  pendings := TXQueryEngineBreaker(staticContext.sender).FPendingModules;
  hadPending := pendings.Count > 0;
  result := parseModuleInternal();
  if result = nil then exit;
  if nextToken() <> '' then begin
    result.free;
    raiseSyntaxError('Unexpected characters after end of expression (possibly an additional closing bracket)');
  end;
  if result is TXQTermModule then begin
    initializeFunctions(result as TXQTermModule, staticContext.sender.getEvaluationContext(staticContext));
  end;
  if Assigned(resultquery) then TXQueryBreaker(resultquery).setTerm(result); //after this point, the caller is responsible to free result on exceptions

  if hadPending then exit; //we cannot do anything, until the pending modules have been parsed

  for i := pendings.Count - 1 downto 0 do begin
    otherQuery := TXQueryBreaker( IXQuery(pendings[i]) as txquery);
    if otherQuery.getTerm = result then continue;
    finalResolving(otherQuery.getTerm, otherQuery.staticContext, options);
    finalizeFunctionsEvenMore(otherQuery.getTerm as TXQTermModule, otherQuery.staticContext, otherQuery.staticContextShared);
  end;
  result := finalResolving(result, staticContext, options); //can we do it twice?
  if result is TXQTermModule then begin
    shared := false; if resultquery <> nil then shared := TXQueryBreaker(resultquery).staticContextShared;
    finalizeFunctionsEvenMore(TXQTermModule(result), staticContext, shared);
  end;

  for i := 0 to pendings.Count - 1 do
    TXQueryEngineBreaker(staticContext.sender).fmodules.Add(pendings[i]);
  pendings.Clear;
end;

class function TXQParsingContext.finalResolving(term: TXQTerm; sc: TXQStaticContext; const opts: TXQParsingOptions): TXQTerm;
var truechildrenhigh: integer;
  visitor: TFinalNamespaceResolving;
  procedure initializeFunctionsAfterResolving();
  var
    i: Integer;
    children: array of TXQTerm;
    f: TXQTermDefineFunction;
    module: TXQTermModule;
    p: Integer;
  begin
    module := result as TXQTermModule;
    children := module.children;
    p := high(sc.functions);
    truechildrenhigh := high(TXQTermModule(result).children) -  ifthen(sc.moduleNamespace = nil, 1,0);
    for i:=truechildrenhigh downto 0 do
      if children[i] is TXQTermDefineFunction then begin
        f := TXQTermDefineFunction(children[i]);
        if (length(f.children) > f.parameterCount) and not (f.children[high(f.children)] is TXQTermSequenceType) then
          sc.functions[p].body := f.children[high(f.children)]; //we need to update body or it blows up, when the resolving visitor has changed the first term of it
        p-=1;
      end;
  end;
begin
  result := term;
  try
    visitor := TFinalNamespaceResolving.Create();
    visitor.staticContext := sc;
    visitor.simpleTermVisit(@result, nil);
  finally
    visitor.free;
  end;

  if (result is TXQTermModule) then
    initializeFunctionsAfterResolving();


  if opts.AllowJSONLiterals then
    TJSONLiteralReplaceVisitor.startVisiting(@result);
end;


function TXQParsingContext.parseModuleInternal(): TXQTerm;
  procedure parseEncoding;
  var
    encname: String;
  begin
    encname := parseString;
    encoding := strEncodingFromName(encname);
    if encoding = eUnknown then raiseParsingError('XQST0087', 'Unknown encoding: ' + encname);
    if (encoding <> eUTF8) and (options.LineEndingNormalization = xqlenXML11) then
      options.LineEndingNormalization := xqlenXML1; //need unicode to understand 85, 2023 line breaks
    expect(';');
  end;

  procedure requireModule;
  begin
    if result <> nil then exit;
    requireXQuery();
    result := TXQTermModule.Create;
  end;

  procedure importSchema; //has read import schema
  var
    prefix, url: String;
  begin
    requireModule;
    prefix := '';
    url := nextToken();
    case url of
      'default': begin
        expect('element');
        expect('namespace');
        url := parseString();
      end;
      'namespace': begin
        prefix := nextTokenNCName();
        expect('=');
        url := parseString();
      end
      else begin
        if (url = '') or not (url[1] in ['''', '"']) then raiseParsingError('XPST0003', 'Invalid schema import');
        url := '';
        prefix:=':::'; //no prefix given
      end;
    end;
    if staticContext.importedSchemas = nil then staticContext.importedSchemas := TNamespaceList.Create;
    staticContext.importedSchemas.add(TNamespace.Create(XMLNamespaceURL_XMLSchema, prefix)); //treat all schemas as equivalent to the default schema
    if nextToken(true) = 'at' then begin
      //discard schema addresses
      parseString;
      while nextToken(true) = ',' do begin expect(','); parseString(); end;
    end;
  end;
  procedure importModule; //has read import module
  var
    moduleName: String;
    moduleURL: String;
    at: array of string;
    module: TXQuery;
    nativeModule: TXQNativeModule;
  begin
    requireModule;
    skipWhitespaceAndComment();
    moduleName := '';
    if pos^ = 'n' then begin
      expect('namespace'); moduleName:=nextTokenNCName(); expect('=');
    end;
    moduleURL := parseString;
    at := nil;
    if nextToken(true) = 'at' then begin
      expect('at');
      arrayAdd(at, parseString);
      while nextToken(true) = ',' do begin expect(','); arrayAdd(at, parseString); end;
    end;

    module := engine.findModule(moduleURL);
    if module = nil then begin
      if assigned(engine.OnImportModule) then engine.onImportModule(engine, moduleURL, at);
      module := engine.findModule(moduleURL);
      if module = nil then begin
        nativeModule := engine.findNativeModule(moduleURL);
        if nativeModule = nil then raiseParsingError('XQST0059', 'Unknown module: '+moduleURL);
        if moduleName <> '' then begin
          if staticContext.namespaces = nil then staticContext.namespaces := TNamespaceList.Create;
          staticContext.namespaces.add(TNamespace.create(nativeModule.namespace.getURL, moduleName));
        end;
        exit;
      end;
    end;
    if staticContext.importedModules = nil then
      staticContext.importedModules := TStringList.Create;
    if moduleName = '' then moduleName := TXQueryBreaker(module).staticContext.moduleNamespace.getPrefix;
    staticContext.importedModules.AddObject(moduleName, module);
  end;

  procedure declareVariable(annotations: TXQAnnotations);
  var vari: TXQTermDefineVariable;
  begin
    requireModule;
    vari := parseDefineVariable;
    vari.annotations := annotations;
    TXQTermModule(result).push(vari);
    case nextToken() of
      ':=': vari.push(parse());
      'external': if nextToken(true) = ':=' then begin
        requireXQuery3('default value');
        expect(':=');
        vari.push(parse());
        SetLength(vari.annotations, length(vari.annotations)+1);
        vari.annotations[high(vari.annotations)].name := TXQEQName.create(XMLNamespaceURL_MyExtensions, 'external');
      end;
      else raiseParsingError('XPST0003', 'Invalid variable declaration');
    end;
  end;

  procedure readBoolean(var b: boolean; const v: string);
  begin
    case v of
      'on':  b := true;
      'off': b := false;
      'toggle': b := not b;
      else raiseParsingError('pxp:XPST0003', 'Invalid option value. Expected on/off/toggle');
    end;
  end;

var
  token: String;
  nameSpaceName: String;
  nameSpaceURL: String;
  temp: String;
  annotations: TXQAnnotations;
  marker: PChar;



  oldNamespaceCount: Integer;
begin
  result := nil;
  oldNamespaceCount := 0;
  if staticContext.namespaces <> nil then oldNamespaceCount := staticContext.namespaces.Count;
  try
    token := nextToken(true);
    marker := pos;
    if token = 'xquery' then begin
      expect(token);
      case nextToken() of
        'version': begin
          requireXQuery();
          temp := parseString();
          if temp = '1.0' then parsingModel := xqpmXQuery1
          else if (temp <> '3.0') or not isModel3 then
            raiseParsingError('XQST0031', 'Invalid xquery version, need 1.0 or 3.0');
          token := nextToken(true);
          if token = 'encoding' then begin
            expect(token);
            parseEncoding;
            token := nextToken(true);
          end else if token = ';' then begin expect(token); token := nextToken(true); end
          else raiseSyntaxError('expected encoding or ;');
        end;
        'encoding': begin
          requireXQuery3();
          parseEncoding;
        end
        else pos := marker;
      end;
    end;

    if token = 'module' then begin
      expect(token);
      case nextToken() of
        '': pos := marker;
        'namespace': begin
          requireModule;
          staticContext.moduleNamespace := TNamespace.create('', nextTokenNCName());
          expect('=');
          (staticContext.moduleNamespace as TNamespace).url := parseString;
          expect(';');
          token := nextToken(true);
          if staticContext.importedModules = nil then staticContext.importedModules := TStringList.Create;
          staticContext.importedModules.AddObject(staticContext.moduleNamespace.getPrefix, resultquery); //every module import itself so it can lazy initialize its variables
          if staticContext.sender.AutomaticallyRegisterParsedModules and (resultquery <> nil) then
            TXQueryEngineBreaker(staticContext.sender).FPendingModules.Add(IXQuery(resultquery));
        end;
        else expect('namespace');
      end;
    end;

    while ((token = 'declare') or (token = 'import')) do begin
      marker := pos;
      expect(token);
      if token = 'import' then begin
        case nextToken() of
          'schema': importSchema;
          'module': importModule;
          else begin
            pos := marker;
            break;
          end;
        end;
      end else case nextToken() of //declare ...
        'boundary-space':
          case nextToken() of
            'preserve': staticContext.StripBoundarySpace:=false;
            'strip': staticContext.StripBoundarySpace:=true;
            else raiseParsingError('XPST0003', 'unknown boundary-space declaration');
          end;
        'default': begin
          token := nextToken();
          case token of
            'collation': staticContext.collation := staticContext.sender.getCollation(parseString, staticContext.baseURI);
            'order': begin
              expect('empty');
              case nextToken() of
                'greatest': staticContext.emptyOrderSpec:=xqeoEmptyGreatest;
                'least': staticContext.emptyOrderSpec:=xqeoEmptyLeast;
              end;
            end;
            'element', 'function': begin
              expect('namespace');
              if token = 'element' then staticContext.defaultElementTypeNamespace:=TNamespace.Create(xmlStrWhitespaceCollapse(parseString), '')
              else staticContext.defaultFunctionNamespace := TNamespace.Create(xmlStrWhitespaceCollapse(parseString), '')
            end;
            else raiseParsingError('XPST0003', 'Unknown default value');
          end;
        end;
        'base-uri': staticContext.baseUri := parseString;
        'construction':
          case nextToken() of
            'strip': staticContext.constructionPreserve := false;
            'preserve': staticContext.constructionPreserve := true
            else raiseParsingError('XPST0003', 'invalid construction declaration');
          end;
        'ordering':
          case nextToken() of
            'unordered': staticContext.ordering:=false;
            'ordered': staticContext.ordering:=true;
            else raiseParsingError('XPST0003', 'invalid ordering mode');
          end;
        'copy-namespaces': begin
           case nextToken() of
             'preserve': staticContext.copyNamespacePreserve:=true;
             'no-preserve': staticContext.copyNamespacePreserve:=false;
             else raiseParsingError('XPST0003', 'Invalid copy-namespace');
           end;
           expect(',');
           case nextToken() of
             'inherit': staticContext.copyNamespaceInherit:=true;
             'no-inherit': staticContext.copyNamespaceInherit:=false;
             else raiseParsingError('XPST0003', 'Invalid copy-namespace');
           end;
         end;
        'namespace': begin
           nameSpaceName := nextTokenNCName();
           expect('=');
           nameSpaceURL := xmlStrWhitespaceCollapse(parseString);
           if (nameSpaceName = 'xml') or (nameSpaceName = 'xmlns')
              or (nameSpaceURL = XMLNamespaceUrl_XML) or (nameSpaceURL = XMLNamespaceUrl_XMLNS) then
                raiseParsingError('XQST0070', 'Undeclarable namespace');
           if staticContext.namespaces = nil then staticContext.namespaces := TNamespaceList.Create
           else if staticContext.namespaces.lastIndexOfNamespacePrefix(nameSpaceName) >= oldNamespaceCount then
             raiseParsingError('XQST0033', 'Duplicated namespace declaration');
           staticContext.namespaces.Add(TNamespace.create(nameSpaceURL, nameSpaceName));
        end;
        else begin
          pos := marker;
          token := 'declare';
          break;
        end;
      end;
      expect(';');
      token := nextToken(true);
    end;

    while (token = 'declare') do begin
      marker := pos;
      expect(token);
      case nextToken() of
        'variable': declareVariable(nil);
        'function': begin
          requireModule;
          TXQTermModule(result).push(parseFunctionDeclaration(nil));
        end;
        '%': begin
          annotations := parseAnnotations;
          case nextToken() of
            'variable': declareVariable(annotations);
            'function': begin
              requireModule;
              TXQTermModule(result).push(parseFunctionDeclaration(annotations));
            end;
            else raiseParsingError('XPST0003', 'Only variables and functions can have annotations');
          end;
        end;
        'option': begin
          if nextTokenEQName(nameSpaceURL, nameSpaceName, token) = xqnmPrefix then
            if nameSpaceName = '' then nameSpaceURL := XMLNamespaceUrl_XQuery
            else nameSpaceURL := staticContext.findNamespaceURL(nameSpaceName, xqdnkUnknown);
          temp := parseString;
          if nameSpaceURL = XMLNamespaceURL_MyExtensions then begin
            case token of
              'default-node-collation': staticContext.nodeCollation := staticContext.sender.getCollation(temp, staticContext.baseURI);
              'extended-strings': readBoolean(options.AllowExtendedStrings, temp);
              'json': readBoolean(options.AllowJSON, temp);
              'property-dot-notation': //readBoolean(AllowPropertyDotNotation, temp);
                case temp of
                  'on':  options.AllowPropertyDotNotation:=xqpdnAllowFullDotNotation;
                  'off': options.AllowPropertyDotNotation:=xqpdnDisallowDotNotation;
                  'unambiguous': options.AllowPropertyDotNotation:=xqpdnAllowUnambiguousDotNotation;
                  'toggle': raiseParsingError('pxp:XPST0003', 'The "toggle" value has been removed for the property-dot-notation option.');
                  else raiseParsingError('pxp:XPST0003', 'Invalid option value. Expected on/off/unambiguous');
                end;
              'strict-type-checking': readBoolean(staticContext.strictTypeChecking, temp);
              'use-local-namespaces': readBoolean(staticContext.useLocalNamespaces, temp);
              'pure-json-objects': readBoolean(staticContext.objectsRestrictedToJSONTypes, temp);
              'extended-json': readBoolean(staticContext.jsonPXPExtensions, temp);
              'string-entities':
                case temp of
                  'off': options.StringEntities:=xqseIgnoreLikeXPath;
                  'on': options.StringEntities:=xqseResolveLikeXQuery;
                  'default': options.StringEntities:=xqseDefault;
                  else raiseParsingError('pxp:XPST0003', 'Invalid option value. Expected on/off/default');
                end;
            end;
          end else if nameSpaceURL = 'http://jsoniq.org/functions' then
            case token of
              'jsoniq-boolean-and-null-literals':
                case temp of
                  'yes': options.AllowJSONLiterals:=true;
                  'no': options.AllowJSONLiterals:=false;
                  else raiseParsingError('XQST0013', 'Unknown option value: '+temp+' for '+token+' (allowed is yes/no)');
                end;
            end;
        end;
        '': begin
          pos := marker;
          break;
        end;
      end;
      expect(';');
      token := nextToken(true);
    end;



    if result = nil then result := parsePrimaryLevel()
    else if staticContext.moduleNamespace = nil then begin //main module
        TXQTermModule(result).push(parsePrimaryLevel);
        if TXQTermModule(result).children[high(TXQTermModule(result).children)] = nil then //huh? module only, no main expression
          raiseParsingError('XPST0003', 'A main module must have a query body, it cannot only declare functions/variables (add ; ())');
    end else if nextToken() <> '' then raiseSyntaxError('Module should have ended, but input query did not');
  except
    result.free;
    if staticContext.sender.AutomaticallyRegisterParsedModules and (resultquery <> nil) then begin
      TXQueryBreaker(resultquery)._AddRef; //increase ref, so we can remove it from FModules without freeing. Cannot free it here, since the caller still has a reference to the object (but not the interface)
      TXQueryEngineBreaker(staticContext.sender).FPendingModules.Remove(IXQuery(resultquery));
    end;
    raise;
  end;
  if result = nil then exit;

end;

function TXQParsingContext.parseXStringOnly(nullTerminatedString: boolean): TXQTerm;
begin
  Result:=parseXString(nullTerminatedString);
  if nextToken() <> '' then begin
    result.free;
    raiseSyntaxError('Unexpected characters after end of expression (possibly an additional closing bracket)');
  end;
end;

procedure TXQParsingContext.parseFunctionTypeInfo(info: TXQAbstractFunctionInfo; const typeChecking: array of string);
var i, j: integer;
begin
  SetLength(info.versions, length(typeChecking));
  for i:= 0 to high(typeChecking) do begin
    //AllowJSON:=AllowJSONDefaultInternal; //todo: improve json modularization?
    str:=typeChecking[i];
    pos:=@str[1];
    skipWhitespaceAndComment();
    if pos^ <> '(' then info.versions[i].name:=nextTokenNCName();
    expect('(');
    skipWhitespaceAndComment();
    if pos^ <> ')' then begin
      SetLength(info.versions[i].types, strCount(str, ',') + 1); //guess for parameter count (does not work for function types)
      for j := 0 to high(info.versions[i].types) do begin
        skipWhitespaceAndComment();
        case pos^ of
          ')': begin
            SetLength(info.versions[i].types, j);
            break;
          end;
          ',': expect(',');
        end;
        expect('$'); nextTokenNCName(); expect('as');
        info.versions[i].types[j] := parseSequenceType([xqstResolveNow]);
      end;
    end;
    expect(')');
     //if nextToken() = 'as' then
    expect('as');
    skipWhitespaceAndComment();
    if not ((pos^ = 'n') and strlEqual(pos, 'none', 4)) then
      info.versions[i].returnType := parseSequenceType([xqstResolveNow]);
  end;
end;


{ TJSONLiteralReplaceVisitor }

function TJSONLiteralReplaceVisitor.visit(t: PXQTerm): TXQTerm_VisitAction;
var
  i: Integer;
begin
  result := xqtvaContinue;
  if (t^ is TXQTermNodeMatcher) and (length(TXQTermNodeMatcher(t^).children) = 0)
     and ((TXQTermNodeMatcher(t^).namespaceCheck <> xqnmNone {this would be *:true}) and (TXQTermNodeMatcher(t^).namespaceURLOrPrefix = '')) then begin
    case TXQTermNodeMatcher(t^).select of
      'true': begin t^.free; t^ := TXQTermNamedFunction.create(XMLNamespaceURL_XPathFunctions, 'true', 0); end;
      'false': begin t^.free; t^ := TXQTermNamedFunction.create(XMLNamespaceURL_XPathFunctions, 'false', 0); end;
      'null': if GlobalStaticNamespaces.namespaces['jn'] <> nil then begin t^.free; t^ := TXQTermNamedFunction.create(GlobalStaticNamespaces.namespaces['jn'].getURL, 'null', 0); end;
    end;
    exit(xqtvaNoRecursion);
  end;
  if t^ is TXQTermBinaryOp then begin
    if (TXQTermBinaryOp(t^).op.name = '/') or (TXQTermBinaryOp(t^).op.name = '//') then begin
      for i := 0 to high(TXQTermNodeMatcher(t^).children) do
        if not (TXQTermNodeMatcher(t^).children[i] is TXQTermNodeMatcher) then self.simpleTermVisit(@TXQTermNodeMatcher(t^).children[i], t^);
      exit(xqtvaNoRecursion);
    end;
  end;
end;


procedure TFinalNamespaceResolving.declare(v: PXQTermVariable);
var
  t: TXQTerm;
  pending: TXQTermPendingEQNameToken;
begin
  t := txqterm(v^);
  if t is TXQTermPendingEQNameToken then begin
    pending := TXQTermPendingEQNameToken(t);
    if pending.pending <> xqptVariable then raiseParsingError('XPST0003', 'Internal error 20160101181238b');
    v^ := TXQTermVariable(pending.resolveAndFree(staticContext));
  end;
end;

function TFinalNamespaceResolving.visit(t: PXQTerm): TXQTerm_VisitAction;


  procedure visitSequenceType(st: TXQTermSequenceType);
  var
    schema: TXSSchema;
    pending: TXQTermPendingEQNameToken;
    flags: TXQSequenceTypeFlags;
  begin
    if (length(st.children) > 0) and (st.children[0] is TXQTermPendingEQNameToken) then begin
      pending := TXQTermPendingEQNameToken(st.children[0]);
      flags := TXQSequenceTypeFlags(pending.data);
      schema := staticContext.findSchema(pending.resolveURI(staticContext, xqdnkType));
      if schema <> nil then st.atomicTypeInfo := schema.findType(pending.localpart)
      else if pending.namespaceprefix <> '' then raiseParsingError('XPST0081', 'Unknown schema: '+pending.namespaceUrl)
      else st.atomicTypeInfo := nil;
      if (st.atomicTypeInfo = nil)
         or (not (xqstAllowValidationTypes in flags) and baseSchema.isValidationOnlyType(st.atomicTypeInfo)) then
        raiseParsingError(ifthen((xqstIsCast in flags) and (staticContext.model in PARSING_MODEL3), 'XQST0052', 'XPST0051'), 'Unknown type: Q{'+pending.namespaceurl+'}'+pending.localpart);
      pending.free;
      SetLength(st.children, 0);
    end;
  end;


  procedure lookupNamedFunction(f: TXQTermNamedFunction);
    function findFunction(const anamespace, alocalname: string; const argcount: integer): boolean;
    var
      module: TXQNativeModule;
      t: TXSType;
      model: TXQParsingModel;
      schema: TXSSchema;
      i: Integer;
      otherModuleStaticContext: TXQStaticContext;
    begin
      module := TXQueryEngine.findNativeModule(anamespace);

      if staticContext <> nil then model := staticContext.model
      else model := xqpmXQuery3;

      if (module <> nil) then begin
        f.func := module.findBasicFunction(alocalname, argcount, model);
        if f.func <> nil then begin
          f.kind:=xqfkBasic;
          exit(true);
        end;

        f.func := module.findComplexFunction(alocalname, argcount, model);
        if f.func <> nil then begin
          f.kind:=xqfkComplex;
          exit(true);
        end;

        f.func := module.findInterpretedFunction(alocalname, argcount, model);
        if f.func <> nil then begin
          f.kind:=xqfkNativeInterpreted;
          if TXQInterpretedFunctionInfo(f.func).func = nil then
              TXQInterpretedFunctionInfo(f.func).initialize();
          f.interpretedFunction :=  TXQInterpretedFunctionInfo(f.func).func;
          f.functionStaticContext := staticContext;  //todo??
          exit(true);
        end;

        if argcount = 2 then begin
          f.func := module.findBinaryOp(alocalname, model);
          if f.func <> nil then begin
            f.kind:=xqfkWrappedOperator;
            exit(true);
          end;
        end;
      end;

      otherModuleStaticContext := staticContext.findModuleStaticContext(anamespace);
      if (otherModuleStaticContext <> nil) then begin
        f.interpretedFunction := otherModuleStaticContext.findFunction(anamespace,alocalname,argcount);
        if f.interpretedFunction <> nil then begin
          f.kind := xqfkUnknown;
          f.functionStaticContext := otherModuleStaticContext;
          if f.functionStaticContext <> staticContext {not equalNamespaces(vfunc.namespace, context.staticContext.moduleNamespace)} then
            for i := 0 to high(f.interpretedFunction.annotations) do
              if f.interpretedFunction.annotations[i].name.isEqual(XMLNamespaceUrl_XQuery, 'private') then
                raiseParsingError('XPST0017', f.interpretedFunction.name + ' is private');
          exit(true);
        end;
      end;

      if argcount = 1 then begin
        if anamespace = baseSchema.url then schema := baseSchema
        else if staticContext <> nil then schema := staticContext.findSchema(anamespace)
        else schema := nil;
        if schema <> nil then begin
          t := schema.findType(alocalname);
          if (t <> nil) and not (baseSchema.isAbstractType(t)) and not (baseSchema.isValidationOnlyType(t)) then begin
            f.kind:=xqfkTypeConstructor;
            f.func := TXQAbstractFunctionInfo(TObject(t));
            exit(true)
          end;
        end;
      end;

      exit(false);
    end;


  var
    unresolved: boolean;
    name: String;
  begin
    if f.name = nil then exit; //already parsed
    unresolved := f.name is TXQEQNameUnresolved;
    if unresolved then TXQEQNameUnresolved(f.name).resolveURI(staticContext, xqdnkFunction);

    if findFunction(f.name.namespaceURL, f.name.localname, length(f.children)) then
      exit();

    if unresolved then
      with TXQEQNameUnresolved(f.name) do
        if (namespacePrefix = '') then begin
          if staticContext.defaultElementTypeNamespace <> nil then namespaceURL := staticContext.defaultElementTypeNamespace.getURL
          else if staticContext.defaultTypeNamespace <> nil then namespaceURL  := staticContext.defaultTypeNamespace.getURL;
          if findFunction(namespaceURL, localname, length(f.children)) then
            exit();
        end;
    if not unresolved then name := 'Q{'+f.name.namespaceURL+'}'
    else if TXQEQNameUnresolved(f.name).namespacePrefix = '' then name := ''
    else name := TXQEQNameUnresolved(f.name).namespacePrefix + ':' ;
    name += f.name.localname;
    raiseParsingError('XPST0017', 'unknown function: ' + name);
  end;

  function visitNamedFunction(f: TXQTermNamedFunction): TXQTerm;
  begin
    result := f;
    lookupNamedFunction(f);
    with f do
      if (kind = xqfkTypeConstructor) and (length(children) = 1) then
        result := staticallyCastQNameAndNotation(TXQTermNamedFunction(result), TXSType(TObject(func)), staticContext);
  end;

  procedure visitAnnotations(var ans: TXQAnnotations; isFunction: boolean; isAnonymousFunction: boolean = false);
  var
    i: Integer;
    hasPrivatePublic: Boolean;
  begin
    hasPrivatePublic := false;
    for i := 0 to high(ans) do begin
      if ans[i].name is TXQEQNameUnresolved then ans[i].name := TXQEQNameUnresolved(ans[i].name).resolveAndFreeToEQName(staticContext);

      case ans[i].name.namespaceURL of
        XMLNamespaceUrl_XQuery: begin
          case ans[i].name.localname of
            'private', 'public': ; //ok
            else raiseParsingError('XQST0045', 'Only private/public annotations are allowed in namespace '+XMLNamespaceUrl_XQuery);
          end;
          if hasPrivatePublic then
            raiseParsingError(ifthen(isFunction, 'XQST0106', 'XQST0116'), '%private/%public has to be unique');
          hasPrivatePublic := true;
          if isAnonymousFunction then raiseParsingError('XQST0125', 'anonymous functions cannot be public or private');
        end;
        XMLNamespaceUrl_XML, XMLNamespaceURL_XMLSchema, XMLNamespaceURL_XMLSchemaInstance,
        XMLNamespaceURL_XPathFunctions, XMLNamespaceURL_XPathFunctionsMath: raiseParsingError('XQST0045', 'No annotations are allowed in namespace '+ans[i].name.namespaceURL);
      end;
    end;
  end;

  procedure visitDefineFunction(f: TXQTermDefineFunction);

  begin
    if f.name is TXQEQNameUnresolved then f.name := TXQEQNameUnresolved(f.name).resolveAndFreeToEQNameWithPrefix(staticContext, xqdnkFunction);
    visitAnnotations(f.annotations, true, f.name = nil);
   // if f.kind <> xqtdfUserDefined then
   //   lookupNamedFunction(f.children[high(f.children)] as TXQTermNamedFunction);
  end;

  procedure visitDefineVariable(f: TXQTermDefineVariable);

  begin
    visitAnnotations(f.annotations, false);
  end;

  function visitBinaryOp(b: TXQTermBinaryOp): TXQTerm;
  var
    st: TXQTermSequenceType;
  begin
    if (b.op.func = @xqvalueCastAs) or (b.op.func = @xqvalueCastableAs) then begin
      st := b.children[1] as TXQTermSequenceType;
      visitSequenceType(st);
      if not (st.isSingleType()) then
        raiseSyntaxError('Need single typ for cast')
      else if baseSchema.isAbstractType(st.atomicTypeInfo) then
        raiseParsingError(ifthen((staticContext.model in PARSING_MODEL3) or (st.atomicTypeInfo <> baseSchema.anySimpleType), 'XPST0080', 'XPST0051'), 'Invalid type for cast')
      else if (st.atomicTypeInfo is TXSSimpleType) and not (TXSSimpleType(st.atomicTypeInfo).variety in [xsvAbsent, xsvAtomic]) then
        raiseParsingError('XQST0052', 'Expected simple type');
      result := staticallyCastQNameAndNotation(b, st.atomicTypeInfo, staticContext, b.op.func = @xqvalueCastableAs);
    end else result := b;
  end;

  procedure visitFlower(f: TXQTermFlower);
  var
    i: Integer;
  begin
    for i := 0 to high(f.children) - 1 do
      case TXQTermFlowerSubClause(f.children[i]).kind of
        xqtfcLet: ;
        xqtfcFor: ;
        xqtfcWindow: ;
        xqtfcForPattern, xqtfcLetPattern: ;
        xqtfcWhere: ;
        xqtfcOrder: ;
        xqtfcCount: ;
        xqtfcGroup: ;
      end;
  end;

  procedure visitNodeMatcher(n: TXQTermNodeMatcher);
  begin
    if not staticContext.useLocalNamespaces and (n.namespaceCheck = xqnmPrefix) then begin
      n.namespaceCheck := xqnmURL;
      n.namespaceURLOrPrefix := staticContext.findNamespaceURL(n.namespaceURLOrPrefix, xqdnkElementType);
    end;
  end;

  procedure visitConstructor(c: TXQTermConstructor);
  begin
    if c.implicitNamespaces <> nil then begin
      changedDefaultsTypeNamespaces.Add(staticContext.defaultElementTypeNamespace);
      arrayAddFast(implicitNamespaceCounts, implicitNamespaceCountsLength, addNamespacesToStaticContext(c.implicitNamespaces, staticContext));
    end;
  end;

  procedure visitTryCatch(t: TXQTermTryCatch);
  var
    i: Integer;
    j: Integer;
  begin
    for i := 0 to high(t.catches) do
      for j := 0 to high(t.catches[i].tests) do
        if t.catches[i].tests[j].name is TXQEQNameUnresolved then
          t.catches[i].tests[j].name := TXQEQNameUnresolved(t.catches[i].tests[j].name).resolveAndFreeToEQName(staticContext);
  end;

begin
  if t^ is TXQTermPendingEQNameToken then begin
    t^ := TXQTermPendingEQNameToken(t^).resolveAndFree(staticContext)
  end else if t^ is TXQTermSequenceType then visitSequenceType(TXQTermSequenceType(t^))
  else if t^ is TXQTermNamedFunction then t^ := visitNamedFunction(TXQTermNamedFunction(t^))
  else if t^ is TXQTermDefineFunction then visitDefineFunction(TXQTermDefineFunction(t^))
  else if t^ is TXQTermBinaryOp then t^ := visitBinaryOp(TXQTermBinaryOp(t^))
  else if t^ is TXQTermFlower then visitFlower(TXQTermFlower(t^))
  else if t^ is TXQTermNodeMatcher then visitNodeMatcher(TXQTermNodeMatcher(t^))
  else if t^ is TXQTermConstructor then visitConstructor(TXQTermConstructor(t^))
  else if t^ is TXQTermDefineVariable then visitDefineVariable(TXQTermDefineVariable(t^))
  else if t^ is TXQTermTryCatch then visitTryCatch(TXQTermTryCatch(t^))

  ;result := xqtvaContinue;
end;

function TFinalNamespaceResolving.leave(t: PXQTerm): TXQTerm_VisitAction;
  procedure visitConstructor(c: TXQTermConstructor);
  begin
    if c.implicitNamespaces <> nil then begin
      staticContext.defaultElementTypeNamespace := INamespace(changedDefaultsTypeNamespaces.Last);
      changedDefaultsTypeNamespaces.Delete(changedDefaultsTypeNamespaces.Count - 1);

      implicitNamespaceCountsLength -= 1;
      staticContext.namespaces.deleteFrom(implicitNamespaceCounts[implicitNamespaceCountsLength]);
    end;
  end;


  procedure visitFlower(f: TXQTermFlower);
  var
    i: Integer;
    localVars: TFPList;
    duplicate: TXQTermVariable;
    j: Integer;
  begin
    if checker = nil then checker := TFlowerVariableChecker.create;
    checker.knownVars.clear;
    for i := 0 to high(f.children) - 1 do begin
      if TXQTermFlowerSubClause(f.children[i]).kind = xqtfcGroup then
        with TXQTermFlowerGroup(f.children[i]) do
          for j := 0 to high(vars) do
            if not checker.knownVars.hasVariable(vars[j]) then
              raiseParsingError('XQST0094', 'Variable unknown: '+vars[j].ToString);
      TXQTermFlowerSubClause(f.children[i]).visitchildrenToUndeclare(checker);
    end;
  end;


begin
  if t^ is TXQTermConstructor then visitConstructor(TXQTermConstructor(t^))
  else if t^ is TXQTermFlower then visitFlower(TXQTermFlower(t^))
  ;result := xqtvaContinue;
end;

procedure TFinalNamespaceResolving.raiseParsingError(a, b: string);
begin
  raise EXQParsingException.create(a,b);
end;

procedure TFinalNamespaceResolving.raiseSyntaxError(m: string);
begin
  raiseParsingError('XPST0003', m);
end;

constructor TFinalNamespaceResolving.Create;
begin
  changedDefaultsTypeNamespaces := TNamespaceList.Create;
end;

destructor TFinalNamespaceResolving.Destroy;
begin
  changedDefaultsTypeNamespaces.free;
  checker.free;
  inherited Destroy;
end;


end.
