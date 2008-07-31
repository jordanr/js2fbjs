/* vim: set filetype=racc : */

class Js2Fbjs::GeneratedParser

/* Literals */
token NULL TRUE FALSE

/* keywords */
token BREAK CASE CATCH CONST CONTINUE DEBUGGER DEFAULT DELETE DO ELSE ENUM
token FINALLY FOR FUNCTION IF IN INSTANCEOF NEW RETURN SWITCH THIS THROW TRY
token TYPEOF VAR VOID WHILE WITH

/* punctuators */
token EQEQ NE                     /* == and != */
token STREQ STRNEQ                /* === and !== */
token LE GE                       /* < and > */
token OR AND                      /* || and && */
token PLUSPLUS MINUSMINUS         /* ++ and --  */
token LSHIFT                      /* << */
token RSHIFT URSHIFT              /* >> and >>> */
token PLUSEQUAL MINUSEQUAL        /* += and -= */
token MULTEQUAL DIVEQUAL          /* *= and /= */
token LSHIFTEQUAL                 /* <<= */
token RSHIFTEQUAL URSHIFTEQUAL    /* >>= and >>>= */
token ANDEQUAL MODEQUAL           /* &= and %= */
token XOREQUAL OREQUAL            /* ^= and |= */

/* Terminal types */
token REGEXP
token NUMBER
token STRING
token IDENT

token AUTOPLUSPLUS AUTOMINUSMINUS IF_WITHOUT_ELSE

prechigh
  nonassoc ELSE
  nonassoc IF_WITHOUT_ELSE
preclow

rule
  SourceElements:
    /* nothing */		    { result = s(:SourceElements, nil) }
  | SourceElementList		    { result = combine(:SourceElements, flatten_unless_sexp(val) ) }
  ;

  SourceElementList:
    SourceElement		   
  | SourceElementList SourceElement { result = flatten_unless_sexp(val) }
  ;

  SourceElement:
    FunctionDeclaration
  | Statement
  ;

  Statement:
    Block
  | VariableStatement
  | ConstStatement
  | EmptyStatement
  | ExprStatement
  | IfStatement
  | IterationStatement
  | ContinueStatement
  | BreakStatement
  | ReturnStatement
  | WithStatement
  | SwitchStatement
  | LabelledStatement
  | ThrowStatement
  | TryStatement
  | DebuggerStatement
  ;

  Literal:
    NULL    { result = s(:Null, val.first) }
  | TRUE    { result = s(:True, val.first) }
  | FALSE   { result = s(:False, val.first) }
  | NUMBER  { result = s(:Number, val.first) }
  | STRING  { result = s(:String, val.first) }
  | REGEXP  { result = s(:Regexp, val.first) }
  ;

  Property:
    IDENT ':' AssignmentExpr  { result = s(:Property, val[0], val[2]) }
  | STRING ':' AssignmentExpr { result = s(:Property, val.first, val.last) }
  | NUMBER ':' AssignmentExpr { result = s(:Property, val.first, val.last) }
  | IDENT IDENT '(' FormalParameters ')' '{' FunctionBody '}' {
      klass = property_class_for(val.first)
      raise ParseError, "expected keyword 'get' or 'set' but saw #{val.first}" unless klass
      result = s(klass, val[1], s(:FunctionExpr, nil, val[3], val[6]))
    }
  ;

  PropertyList:
    Property                    { result = val }
  | PropertyList ',' Property   { result = flatten_unless_sexp([val.first, val.last]) }
  ;

  PrimaryExpr:
    PrimaryExprNoBrace
  | '{' '}'                   { result = s(:ObjectLiteral, nil) }
  | '{' PropertyList '}'      { result = combine(:ObjectLiteral, val[1]) }
  | '{' PropertyList ',' '}'  { result = combine(:ObjectLiteral, val[1]) }
  ;

  PrimaryExprNoBrace:
    THIS          { result = s(:This, val.first) }
  | Literal
  | ArrayLiteral
  | IDENT         { result = s(:Resolve, val.first) }
  | '(' Expr ')'  { result = val[1] }
  ;

  ArrayLiteral:
    '[' ElisionOpt ']'           	{ result = combine(:Array, [nil] * val[1]) }
  | '[' ElementList ']'                 { result = combine(:Array, val[1]) }
  | '[' ElementList ',' ElisionOpt ']'  { result = combine(:Array, val[1] + [nil] * val[3]) }
  ;

  ElementList:
    ElisionOpt AssignmentExpr {
      result = [nil] * val[0] + [s(:Element, val[1])]
    }
  | ElementList ',' ElisionOpt AssignmentExpr {
      result = flatten_unless_sexp([val[0], [nil] * val[2], s(:Element, val[3])])
    }
  ;

  ElisionOpt:
    /* nothing */ { result = 0 }
  | Elision
  ;

  Elision:
    ',' { result = 1 }
  | Elision ',' { result = val.first + 1 }
  ;

  MemberExpr:
    PrimaryExpr
  | FunctionExpr
  | MemberExpr '[' Expr ']' { result = s(:BracketAccessor, val[0], val[2]) }
  | MemberExpr '.' IDENT    { result = s(:DotAccessor, val[0], val[2]) }
  | NEW MemberExpr Arguments { result = s(:NewExpr, val[1], val[2]) }
  ;

  MemberExprNoBF:
    PrimaryExprNoBrace
  | MemberExprNoBF '[' Expr ']' {
      result = s(:BracketAccessor, val[0], val[2])
    }
  | MemberExprNoBF '.' IDENT    { result = s(:DotAccessor, val[0], val[2]) }
  | NEW MemberExpr Arguments    { result = s(:NewExpr, val[1], val[2]) }
  ;

  NewExpr:
    MemberExpr
  | NEW NewExpr { result = s(:NewExpr, val[1], s(:Arguments, nil)) }
  ;

  NewExprNoBF:
    MemberExprNoBF
  | NEW NewExpr { result = s(:NewExpr, val[1], s(:Arguments, nil)) }
  ;

  CallExpr:
    MemberExpr Arguments  { result = s(:FunctionCall, val[0], val[1]) }
  | CallExpr Arguments    { result = s(:FunctionCall, val[0], val[1]) }
  | CallExpr '[' Expr ']' { result = s(:BracketAccessor, val[0], val[2]) }
  | CallExpr '.' IDENT    { result = s(:DotAccessor, val[0], val[2]) }
  ;

  CallExprNoBF:
    MemberExprNoBF Arguments  { result = s(:FunctionCall, val[0], val[1]) }
  | CallExprNoBF Arguments    { result = s(:FunctionCall, val[0], val[1]) }
  | CallExprNoBF '[' Expr ']' { result = s(:BracketAccessor, val[0], val[2]) }
  | CallExprNoBF '.' IDENT    { result = s(:DotAccessor, val[0], val[2]) }
  ;

  Arguments:
    '(' ')'               { result = s(:Arguments, nil) }
  | '(' ArgumentList ')'  { result = combine(:Arguments, val[1]) }
  ;

  ArgumentList:
    AssignmentExpr                      { result = val }
  | ArgumentList ',' AssignmentExpr     { result = flatten_unless_sexp([val.first, val.last]) }
  ;

  LeftHandSideExpr:
    NewExpr
  | CallExpr
  ;

  LeftHandSideExprNoBF:
    NewExprNoBF
  | CallExprNoBF
  ;

  PostfixExpr:
    LeftHandSideExpr
  | LeftHandSideExpr PLUSPLUS   { result = s(:Postfix, val[0], '++') }
  | LeftHandSideExpr MINUSMINUS { result = s(:Postfix, val[0], '--') }
  ;

  PostfixExprNoBF:
    LeftHandSideExprNoBF
  | LeftHandSideExprNoBF PLUSPLUS   { result = s(:Postfix, val[0], '++') }
  | LeftHandSideExprNoBF MINUSMINUS { result = s(:Postfix, val[0], '--') }
  ;

  UnaryExprCommon:
    DELETE UnaryExpr     { result = s(:Delete, val[1]) }
  | VOID UnaryExpr       { result = s(:Void, val[1]) }
  | TYPEOF UnaryExpr          { result = s(:TypeOf, val[1]) }
  | PLUSPLUS UnaryExpr        { result = s(:Prefix, '++', val[1]) }
  /* FIXME: Not sure when this can ever happen
  | AUTOPLUSPLUS UnaryExpr    { result = makePrefixNode($2, OpPlusPlus); } */
  | MINUSMINUS UnaryExpr      { result = s(:Prefix, '--', val[1]) }
  /* FIXME: Not sure when this can ever happen
  | AUTOMINUSMINUS UnaryExpr  { result = makePrefixNode($2, OpMinusMinus); } */
  | '+' UnaryExpr             { result = s(:UnaryPlus, val[1]) }
  | '-' UnaryExpr             { result = s(:UnaryMinus, val[1]) }
  | '~' UnaryExpr             { result = s(:BitwiseNot, val[1]) }
  | '!' UnaryExpr             { result = s(:LogicalNot, val[1]) }
  ;

  UnaryExpr:
    PostfixExpr
  | UnaryExprCommon
  ;

  UnaryExprNoBF:
    PostfixExprNoBF
  | UnaryExprCommon
  ;

  MultiplicativeExpr:
    UnaryExpr
  | MultiplicativeExpr '*' UnaryExpr { result = s(:Multiply, val[0],val[2])}
  | MultiplicativeExpr '/' UnaryExpr { result = s(:Divide, val[0], val[2]) }
  | MultiplicativeExpr '%' UnaryExpr { result = s(:Modulus, val[0], val[2])}
  ;

  MultiplicativeExprNoBF:
    UnaryExprNoBF
  | MultiplicativeExprNoBF '*' UnaryExpr { result = s(:Multiply, val[0], val[2]) }
  | MultiplicativeExprNoBF '/' UnaryExpr { result = s(:Divide, val[0],val[2]) }
  | MultiplicativeExprNoBF '%' UnaryExpr { result = s(:Modulus, val[0], val[2]) }
  ;

  AdditiveExpr:
    MultiplicativeExpr
  | AdditiveExpr '+' MultiplicativeExpr { result = s(:Add, val[0], val[2]) }
  | AdditiveExpr '-' MultiplicativeExpr { result = s(:Subtract, val[0], val[2]) }
  ;

  AdditiveExprNoBF:
    MultiplicativeExprNoBF
  | AdditiveExprNoBF '+' MultiplicativeExpr { result = s(:Add, val[0], val[2]) }
  | AdditiveExprNoBF '-' MultiplicativeExpr { result = s(:Subtract, val[0], val[2]) }
  ;

  ShiftExpr:
    AdditiveExpr
  | ShiftExpr LSHIFT AdditiveExpr   { result = s(:LeftShift, val[0], val[2]) }
  | ShiftExpr RSHIFT AdditiveExpr   { result = s(:RightShift, val[0], val[2]) }
  | ShiftExpr URSHIFT AdditiveExpr  { result = s(:UnsignedRightShift, val[0], val[2]) }
  ;

  ShiftExprNoBF:
    AdditiveExprNoBF
  | ShiftExprNoBF LSHIFT AdditiveExpr   { result = s(:LeftShift, val[0], val[2]) }
  | ShiftExprNoBF RSHIFT AdditiveExpr   { result = s(:RightShift, val[0], val[2]) }
  | ShiftExprNoBF URSHIFT AdditiveExpr  { result = s(:UnsignedRightShift, val[0], val[2]) }
  ;

  RelationalExpr:
    ShiftExpr
  | RelationalExpr '<' ShiftExpr        { result = s(:Less, val[0], val[2])}
  | RelationalExpr '>' ShiftExpr        { result = s(:Greater, val[0], val[2]) }
  | RelationalExpr LE ShiftExpr         { result = s(:LessOrEqual, val[0], val[2]) }
  | RelationalExpr GE ShiftExpr         { result = s(:GreaterOrEqual, val[0], val[2]) }
  | RelationalExpr INSTANCEOF ShiftExpr { result = s(:InstanceOf, val[0], val[2]) }
  | RelationalExpr IN ShiftExpr    	{ result = s(:In, val[0], val[2]) }
  ;

  RelationalExprNoIn:
    ShiftExpr
  | RelationalExprNoIn '<' ShiftExpr    { result = s(:Less, val[0], val[2])}
  | RelationalExprNoIn '>' ShiftExpr    { result = s(:Greater, val[0], val[2]) }
  | RelationalExprNoIn LE ShiftExpr     { result = s(:LessOrEqual, val[0], val[2]) }
  | RelationalExprNoIn GE ShiftExpr     { result = s(:GreaterOrEqual, val[0], val[2]) }
  | RelationalExprNoIn INSTANCEOF ShiftExpr
                                        { result = s(:InstanceOf, val[0], val[2]) }
  ;

  RelationalExprNoBF:
    ShiftExprNoBF
  | RelationalExprNoBF '<' ShiftExpr    { result = s(:Less, val[0], val[2]) }
  | RelationalExprNoBF '>' ShiftExpr    { result = s(:Greater, val[0], val[2]) }
  | RelationalExprNoBF LE ShiftExpr     { result = s(:LessOrEqual, val[0], val[2]) }
  | RelationalExprNoBF GE ShiftExpr     { result = s(:GreaterOrEqual, val[0], val[2]) }
  | RelationalExprNoBF INSTANCEOF ShiftExpr
                                        { result = s(:InstanceOf, val[0], val[2]) }
  | RelationalExprNoBF IN ShiftExpr     { result = s(:In, val[0], val[2]) }
  ;

  EqualityExpr:
    RelationalExpr
  | EqualityExpr EQEQ RelationalExpr    { result = s(:Equal, val[0], val[2]) }
  | EqualityExpr NE RelationalExpr      { result = s(:NotEqual, val[0], val[2]) }
  | EqualityExpr STREQ RelationalExpr   { result = s(:StrictEqual, val[0], val[2]) }
  | EqualityExpr STRNEQ RelationalExpr  { result = s(:NotStrictEqual, val[0], val[2]) }
  ;

  EqualityExprNoIn:
    RelationalExprNoIn
  | EqualityExprNoIn EQEQ RelationalExprNoIn
                                        { result = s(:Equal, val[0], val[2]) }
  | EqualityExprNoIn NE RelationalExprNoIn
                                        { result = s(:NotEqual, val[0], val[2]) }
  | EqualityExprNoIn STREQ RelationalExprNoIn
                                        { result = s(:StrictEqual, val[0], val[2]) }
  | EqualityExprNoIn STRNEQ RelationalExprNoIn
                                        { result = s(:NotStrictEqual, val[0], val[2]) }
  ;

  EqualityExprNoBF:
    RelationalExprNoBF
  | EqualityExprNoBF EQEQ RelationalExpr
                                        { result = s(:Equal, val[0], val[2]) }
  | EqualityExprNoBF NE RelationalExpr  { result = s(:NotEqual, val[0], val[2]) }
  | EqualityExprNoBF STREQ RelationalExpr
                                        { result = s(:StrictEqual, val[0], val[2]) }
  | EqualityExprNoBF STRNEQ RelationalExpr
                                        { result = s(:NotStrictEqual, val[0], val[2]) }
  ;

  BitwiseANDExpr:
    EqualityExpr
  | BitwiseANDExpr '&' EqualityExpr     { result = s(:BitAnd, val[0], val[2]) }
  ;

  BitwiseANDExprNoIn:
    EqualityExprNoIn
  | BitwiseANDExprNoIn '&' EqualityExprNoIn
                                        { result = s(:BitAnd, val[0], val[2]) }
  ;

  BitwiseANDExprNoBF:
    EqualityExprNoBF
  | BitwiseANDExprNoBF '&' EqualityExpr { result = s(:BitAnd, val[0], val[2]) }
  ;

  BitwiseXORExpr:
    BitwiseANDExpr
  | BitwiseXORExpr '^' BitwiseANDExpr   { result = s(:BitXOr, val[0], val[2]) }
  ;

  BitwiseXORExprNoIn:
    BitwiseANDExprNoIn
  | BitwiseXORExprNoIn '^' BitwiseANDExprNoIn
                                        { result = s(:BitXOr, val[0], val[2]) }
  ;

  BitwiseXORExprNoBF:
    BitwiseANDExprNoBF
  | BitwiseXORExprNoBF '^' BitwiseANDExpr
                                        { result = s(:BitXOr, val[0], val[2]) }
  ;

  BitwiseORExpr:
    BitwiseXORExpr
  | BitwiseORExpr '|' BitwiseXORExpr    { result = s(:BitOr, val[0], val[2]) }
  ;

  BitwiseORExprNoIn:
    BitwiseXORExprNoIn
  | BitwiseORExprNoIn '|' BitwiseXORExprNoIn
                                        { result = s(:BitOr, val[0], val[2]) }
  ;

  BitwiseORExprNoBF:
    BitwiseXORExprNoBF
  | BitwiseORExprNoBF '|' BitwiseXORExpr
                                        { result = s(:BitOr, val[0], val[2]) }
  ;

  LogicalANDExpr:
    BitwiseORExpr
  | LogicalANDExpr AND BitwiseORExpr    { result = s(:LogicalAnd, val[0], val[2]) }
  ;

  LogicalANDExprNoIn:
    BitwiseORExprNoIn
  | LogicalANDExprNoIn AND BitwiseORExprNoIn
                                        { result = s(:LogicalAnd, val[0], val[2]) }
  ;

  LogicalANDExprNoBF:
    BitwiseORExprNoBF
  | LogicalANDExprNoBF AND BitwiseORExpr
                                        { result = s(:LogicalAnd, val[0], val[2]) }
  ;

  LogicalORExpr:
    LogicalANDExpr
  | LogicalORExpr OR LogicalANDExpr     { result = s(:LogicalOr, val[0], val[2]) }
  ;

  LogicalORExprNoIn:
    LogicalANDExprNoIn
  | LogicalORExprNoIn OR LogicalANDExprNoIn
                                        { result = s(:LogicalOr, val[0], val[2]) }
  ;

  LogicalORExprNoBF:
    LogicalANDExprNoBF
  | LogicalORExprNoBF OR LogicalANDExpr { result = s(:LogicalOr, val[0], val[2]) }
  ;

  ConditionalExpr:
    LogicalORExpr
  | LogicalORExpr '?' AssignmentExpr ':' AssignmentExpr {
      result = s(:Conditional, val[0], val[2], val[4])
    }
  ;

  ConditionalExprNoIn:
    LogicalORExprNoIn
  | LogicalORExprNoIn '?' AssignmentExprNoIn ':' AssignmentExprNoIn {
      result = s(:Conditional, val[0], val[2], val[4])
    }
  ;

  ConditionalExprNoBF:
    LogicalORExprNoBF
  | LogicalORExprNoBF '?' AssignmentExpr ':' AssignmentExpr {
      result = s(:Conditional, val[0], val[2], val[4])
    }
  ;

  AssignmentExpr:
    ConditionalExpr
  | LeftHandSideExpr AssignmentOperator AssignmentExpr {
      result = s(val[1], val.first, val.last)
    }
  ;

  AssignmentExprNoIn:
    ConditionalExprNoIn
  | LeftHandSideExpr AssignmentOperator AssignmentExprNoIn {
      result = s(val[1], val.first, val.last)
    }
  ;

  AssignmentExprNoBF:
    ConditionalExprNoBF
  | LeftHandSideExprNoBF AssignmentOperator AssignmentExpr {
      result = s(val[1], val.first, val.last)
    }
  ;

  AssignmentOperator:
    '='                                 { result = :OpEqual }
  | PLUSEQUAL                           { result = :OpPlusEqual }
  | MINUSEQUAL                          { result = :OpMinusEqual }
  | MULTEQUAL                           { result = :OpMultiplyEqual }
  | DIVEQUAL                            { result = :OpDivideEqual }
  | LSHIFTEQUAL                         { result = :OpLShiftEqual }
  | RSHIFTEQUAL                         { result = :OpRShiftEqual }
  | URSHIFTEQUAL                        { result = :OpURShiftEqual }
  | ANDEQUAL                            { result = :OpAndEqual }
  | XOREQUAL                            { result = :OpXOrEqual }
  | OREQUAL                             { result = :OpOrEqual }
  | MODEQUAL                            { result = :OpModEqual }
  ;

  Expr:
    AssignmentExpr
  | Expr ',' AssignmentExpr             { result = s(:Comma,val[0], val[2]) }
  ;

  ExprNoIn:
    AssignmentExprNoIn
  | ExprNoIn ',' AssignmentExprNoIn     { result = s(:Comma, val[0], val[2]) }
  ;

  ExprNoBF:
    AssignmentExprNoBF
  | ExprNoBF ',' AssignmentExpr       { result = s(:Comma, val[0], val[2]) }
  ;


  Block:
    '{' SourceElements '}' {
      result = s(:Block, val[1])
      debug(result)
    }
  ;

  VariableStatement:
    VAR VariableDeclarationList ';' {
      result = combine(:VarStatement, val[1])
      debug(result)
    }
  | VAR VariableDeclarationList error {
      result = combine(:VarStatement, val[1])
      debug(result)
      raise ParseError, "bad variable statement, #{val.to_s}" unless allow_auto_semi?(val.last)
    }
  ;

  VariableDeclarationList:
    VariableDeclaration                 { result = val }
  | VariableDeclarationList ',' VariableDeclaration {
      result = flatten_unless_sexp([val.first, val.last])
    }
  ;

  VariableDeclarationListNoIn:
    VariableDeclarationNoIn             { result = val }
  | VariableDeclarationListNoIn ',' VariableDeclarationNoIn {
      result = flatten_unless_sexp([val.first, val.last])
    }
  ;

  VariableDeclaration:
    IDENT             { result = s(:VarDecl, val.first, nil) }
  | IDENT Initializer { result = s(:VarDecl, val.first, val[1]) }
  ;

  VariableDeclarationNoIn:
    IDENT                               { result = s(:VarDecl, val[0], nil) }
  | IDENT InitializerNoIn               { result = s(:VarDecl, val[0], val[1]) }
  ;

  ConstStatement:
    CONST ConstDeclarationList ';' {
      result = combine(:ConstStatement, val[1])
      debug(result)
    }
  | CONST ConstDeclarationList error {
      result = combine(:ConstStatement, val[1])
      debug(result)
      raise ParseError, "bad const statement, #{val.to_s}" unless allow_auto_semi?(val.last)
    }
  ;

  ConstDeclarationList:
    ConstDeclaration                    { result = val }
  | ConstDeclarationList ',' ConstDeclaration {
      result = flatten_unless_sexp([val.first, val.last])
    }
  ;

  ConstDeclaration:
    IDENT             { result = s(:VarDecl, val[0], nil) } # true) }
  | IDENT Initializer { result = s(:VarDecl, val[0], val[1]) } # true) }
  ;

  Initializer:
    '=' AssignmentExpr                  { result = s(:AssignExpr, val[1]) }
  ;

  InitializerNoIn:
    '=' AssignmentExprNoIn              { result = s(:AssignExpr, val[1]) }
  ;

  EmptyStatement:
    ';' { result = s(:EmptyStatement, val[0]) }
  ;

  ExprStatement:
    ExprNoBF ';' {
      result = s(:ExpressionStatement, val.first)
      debug(result)
    }
  | ExprNoBF error {
      result = s(:ExpressionStatement, val.first)
      debug(result)
      raise ParseError, "bad expr statement, #{val.to_s}" unless allow_auto_semi?(val.last)
    }
  ;

  IfStatement:
    IF '(' Expr ')' Statement =IF_WITHOUT_ELSE {
      result = s(:If, val[2], val[4])
      debug(result)
    }
  | IF '(' Expr ')' Statement ELSE Statement {
      result = s(:If, val[2], val[4], val[6])
      debug(result)
    }
  ;

  IterationStatement:
    DO Statement WHILE '(' Expr ')' ';' {
      result = s(:DoWhile, val[1], val[4])
      debug(result)
    }
  | DO Statement WHILE '(' Expr ')' error {
      result = s(:DoWhile, val[1], val[4])
      debug(result)
    } /* Always performs automatic semicolon insertion. */
  | WHILE '(' Expr ')' Statement {
      result = s(:While, val[2], val[4])
      debug(result)
    }
  | FOR '(' ExprNoInOpt ';' ExprOpt ';' ExprOpt ')' Statement {
      result = s(:For, val[2], val[4], val[6], val[8])
      debug(result)
    }
  | FOR '(' VAR VariableDeclarationListNoIn ';' ExprOpt ';' ExprOpt ')' Statement
    {
      result = s(:For, s(:VarStatement, val[3]), val[5], val[7], val[9])
      debug(result)
    }
  | FOR '(' LeftHandSideExpr IN Expr ')' Statement {
      result = s(:ForIn, val[2], val[4], val[6])
      debug(result);
    }
  | FOR '(' VAR IDENT IN Expr ')' Statement {
      result = s(:ForIn, s(:VarDecl, val[3], nil), val[5], val[7])
      debug(result)
    }
  | FOR '(' VAR IDENT InitializerNoIn IN Expr ')' Statement {
      result = s(:ForIn, s(:VarDecl, val[3], val[4]), val[6], val[8])
      debug(result)
    }
  ;

  ExprOpt:
    /* nothing */                       { result = nil }
  | Expr
  ;

  ExprNoInOpt:
    /* nothing */                       { result = nil }
  | ExprNoIn
  ;

  ContinueStatement:
    CONTINUE ';' {
      result = s(:Continue, nil)
      debug(result)
    }
  | CONTINUE error {
      result = s(:Continue, nil)
      debug(result)
      raise ParseError, "bad continue statement, #{val.to_s}" unless allow_auto_semi?(val.last)
    }
  | CONTINUE IDENT ';' {
      result = s(:Continue, val[1])
      debug(result)
    }
  | CONTINUE IDENT error {
      result = s(:Continue, val[1])
      debug(result)
      raise ParseError, "bad continue statement, #{val.to_s}" unless allow_auto_semi?(val.last)
    }
  ;

  BreakStatement:
    BREAK ';' {
      result = s(:Break, nil)
      debug(result)
    }
  | BREAK error {
      result = s(:Break, nil)
      debug(result)
      raise ParseError, "bad break statement, #{val.to_s}" unless allow_auto_semi?(val.last)
    }
  | BREAK IDENT ';' {
      result = s(:Break, val[1])
      debug(result)
    }
  | BREAK IDENT error {
      result = s(:Break, val[1])
      debug(result)
      raise ParseError, "bad break statement, #{val.to_s}" unless allow_auto_semi?(val.last)
    }
  ;

  ReturnStatement:
    RETURN ';' {
      result = s(:Return, nil)
      debug(result)
    }
  | RETURN error {
      result = s(:Return, nil)
      debug(result)
      raise ParseError, "bad return statement, #{val.to_s}" unless allow_auto_semi?(val.last)
    }
  | RETURN Expr ';' {
      result = s(:Return, val[1])
      debug(result)
    }
  | RETURN Expr error {
      result = s(:Return, val[1])
      debug(result)
      raise ParseError, "bad return statement, #{val.to_s}" unless allow_auto_semi?(val.last)
    }
  ;

  WithStatement:
    WITH '(' Expr ')' Statement {
      result = s(:With, val[2], val[4])
      debug(result)
    }
  ;

  SwitchStatement:
    SWITCH '(' Expr ')' CaseBlock {
      result = s(:Switch, val[2], val[4])
      debug(result)
    }
  ;

  CaseBlock:
    '{' CaseClausesOpt '}'              { result = combine(:CaseBlock, flatten_unless_sexp([val[1]]) ) }
  | '{' CaseClausesOpt DefaultClause CaseClausesOpt '}' { result = combine(:CaseBlock, flatten_unless_sexp([val[1], val[2], val[3]]) ) }
  ;

  CaseClausesOpt:
    /* nothing */                       { result = nil }
  | CaseClauses
  ;

  CaseClauses:
    CaseClause                          { result = val }
  | CaseClauses CaseClause              { result = flatten_unless_sexp(val) }
  ;

  CaseClause:
    CASE Expr ':' SourceElements        
					{ result = s(:CaseClause, val[1], val[3] ) }
  ;

  DefaultClause:
    DEFAULT ':' SourceElements          {
      result = s(:CaseClause, nil, val[2])
    }
  ;

  LabelledStatement:
    IDENT ':' Statement { result = s(:Label, val[0], val[2]) }
  ;

  ThrowStatement:
    THROW Expr ';' {
      result = s(:Throw, val[1])
      debug(result)
    }
  | THROW Expr error {
      result = s(:Throw, val[1])
      debug(result)
      raise ParseError, "bad throw statement, #{val.to_s}" unless allow_auto_semi?(val.last)
    }
  ;

  TryStatement:
    TRY Block FINALLY Block {
      result = s(:Try, val[1], nil, nil, val[3])
      debug(result)
    }
  | TRY Block CATCH '(' IDENT ')' Block {
      result = s(:Try, val[1], val[4], val[6])
      debug(result)
    }
  | TRY Block CATCH '(' IDENT ')' Block FINALLY Block {
      result = s(:Try, val[1], val[4], val[6], val[8])
      debug(result)
    }
  ;

  DebuggerStatement:
    DEBUGGER ';' {
      result = s(:EmptyStatement, val[0])
      debug(result)
    }
  | DEBUGGER error {
      result = s(:EmptyStatement, val[0])
      debug(result)
      raise ParseError, "bad debugger statement, #{val.to_s}" unless allow_auto_semi?(val.last)
    }
  ;

  FunctionDeclaration:
    FUNCTION IDENT '(' FormalParameters ')' '{' FunctionBody '}' {
      result = s(:FunctionDecl, val[1], val[6], val[3])
      debug(val[6])
    }
  ;

  FunctionExpr:
    FUNCTION '(' FormalParameters ')' '{' FunctionBody '}' {
      result = s(:FunctionExpr, val[0], val[2], val[5])
      debug(val[5])
    }
  | FUNCTION IDENT '(' FormalParameters ')' '{' FunctionBody '}' {
      result = s(:FunctionExpr, val[1], val[3], val[6])
      debug(val[6])
    }
  ;

  FormalParameters:
    /* nothing */			{ result = s(:Parameters, nil) }
  | FormalParameterList			{ result = combine(:Parameters, flatten_unless_sexp(val)) }

  FormalParameterList:
    IDENT                               { result = val[0] }
  | FormalParameterList ',' IDENT       {
      					  result = flatten_unless_sexp([val.first, val.last])
    					}
  ;

  FunctionBody:
    SourceElements             		{ result = s(:FunctionBody, val[0]) }
  ;
end

---- header
  require "js2fbjs/sexp"
---- inner
  include SexpUtility
  def allow_auto_semi?(error_token)
    error_token == false || error_token == '}' || @terminator
  end

  def property_class_for(ident)
    case ident
    when 'get'
      :GetterProperty
    when 'set'
      :SetterProperty
    else
      nil
    end
  end

  def debug(*args)
    logger.debug(*args) if logger
  end

  def flatten_unless_sexp(ary)
    return ary unless ary.is_a?(Array) && !ary.is_a?(Sexp)
    flattened = []
    ary.each { |ar| 
 	sub = flatten_unless_sexp(ar)
	if(sub.is_a?(Array) && !sub.is_a?(Sexp) )
	  flattened += sub
	else
	  flattened.push(sub)
	end
    }    
    flattened
  end

  def combine(sym, array_or_sexp)
    if(!array_or_sexp.is_a?(Array))
	raise ParseError, "tried to make an s-expression with a non array"
    elsif(array_or_sexp.is_a?(Sexp))
	s(sym, array_or_sexp)
    else
        Sexp.from_array([sym]+array_or_sexp)
    end
  end
