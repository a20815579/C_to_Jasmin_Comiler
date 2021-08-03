/*	Definition section */
%{
    #include "common.h" //Extern variables that communicate with lex
    #include "stdint.h"
    #include "string.h"
    // #define YYDEBUG 1
    // int yydebug = 1;

    #define codegen(...) \
        do { \
            for (int i = 0; i < INDENT; i++) { \
                fprintf(fout, "\t"); \
            } \
            fprintf(fout, __VA_ARGS__); \
        } while (0)
    #define is_int(x) !strcmp((x), "int")
    #define is_float(x) !strcmp((x), "float")
    #define is_string(x) !strcmp((x), "string")
    #define is_bool(x) !strcmp((x), "bool")

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    /* Other global variables */
    FILE *fout = NULL;
    bool HAS_ERROR = false;
    int INDENT = 1;

    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    int scope = 0, indexNum = 0, lastAddr = 0, addrNum = 0, labelcnt = 0;
    int idx_scope[5] = {0};

    struct {
      int   index;
      char* name;
      char* type;
      int   lineno;
      char* element;
      int   scope;
      int   valid;
    } symbols[100];    

    /* Symbol table function - you can add new function if needed. */
    static void create_symbol();
    static void insert_symbol(val_info* this_val);
    static void lookup_symbol(val_info* this_val);
    static void dump_symbol();
    static void gen_instr(char* type, char* op, int8_t is_arr, int second_arg);
    static void gen_print(char* type);
    static void load_val(val_info* this_val);
%}

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union { 
    // val_info structure is defined in common.h
    val_info val;
}

/* Token without return */
%token LPAREN RPAREN LBRACK RBRACK LBRACE RBRACE SEMICOLON COMMA
%token PRINT IF ELSE RETURN BREAK CONTINUE
%token INT FLOAT BOOL STRING VOID

/* Token with return, which need to sepcify type */
%token <val> INT_LIT FLOAT_LIT STRING_LIT BOOL_LIT ID 
%token <val> ADD SUB MUL QUO REM INC DEC
%token <val> OR AND NOT FOR WHILE 
%token <val> GTR LSS GEQ LEQ EQL NEQ
%token <val> ASSIGN ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN QUO_ASSIGN REM_ASSIGN

/* Nonterminal with return, which need to sepcify type */
%type <val> Condition ForClause InitStmt
%type <val> Type Literal Expr AndExpr CompExpr AddExpr MulExpr UnaryExpr 
%type <val> ConvertExpr IndexExpr PrimaryExpr IncDecExpr AssignExpr 
%type <val> Operand AssignOp CmpOp IncDecOp UnaryOp MulOp AddOp


/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    : StatementList     { dump_symbol();  }
;

StatementList
    : StatementList Statement
    | Statement                   
;

Statement
    : DeclareStmt
    | AssignStmt
    | IncDecStmt
    | Block
    | IfStmt
    | WhileStmt
    | ForStmt
    | PrintStmt
    | Expr SEMICOLON
;

DeclareStmt
    : Type ID SEMICOLON                     { 
        $2.type = $1.type;
        $2.is_arr = 0;
        insert_symbol(&$2); 
        lookup_symbol(&$2); // get addr        
        if(is_string($1.type)){
            codegen("ldc \"\"\n");
            codegen("astore %d\n", $2.addr);
        }
        else{
            gen_instr($1.type, "const_0", 0, -1);
            gen_instr($1.type, "store", 0, $2.addr);
        }
    }
    | Type ID ASSIGN Expr SEMICOLON         { 
        $2.type = $1.type;
        $2.is_arr = 0;
        insert_symbol(&$2);
        lookup_symbol(&$2); // get addr
        load_val(&$4);
        gen_instr($1.type, "store", 0, $2.addr);
    }
    | Type ID LBRACK Expr RBRACK SEMICOLON  { 
        $2.type = $1.type;
        $2.is_arr = 1;
        insert_symbol(&$2); 
        lookup_symbol(&$2); // get addr
        load_val(&$4);
        codegen("newarray %s\n", $<val>1.type);
        codegen("astore %d\n", $2.addr);
    }
;

AssignStmt
    : AssignExpr SEMICOLON
;

IncDecStmt
    : IncDecExpr SEMICOLON
;

Block
    : LBRACE { create_symbol(); } StatementList RBRACE { dump_symbol(); }
;

IfStmt
    : IF LPAREN Condition { 
        $3.varval.i_val = labelcnt;
        labelcnt += 2;
        codegen("ifeq L_if_%d\n", $3.varval.i_val);  
    }
      RPAREN Block {
        codegen("goto L_if_%d\n", $3.varval.i_val+1); // rest
        INDENT--; 
        codegen("L_if_%d:\n", $3.varval.i_val); // else part
        INDENT++;
      }
      ElseStmt { 
        INDENT--;
        codegen("L_if_%d:\n", $3.varval.i_val+1);
        INDENT++;
    }
;

ElseStmt
    : ELSE IfStmt   
    | ELSE Block  
    | 
;

Condition
    :  Expr    {
        if(strcmp($1.type, "bool"))
            printf("error:%d: non-bool (type %s) used as for condition\n", yylineno+1, $1.type);
    }
;

WhileStmt
    : WHILE {
        $1.varval.i_val = labelcnt;
        labelcnt += 2;
        INDENT--;
        codegen("L_for_%d:\n", $1.varval.i_val);
        INDENT++;
    }
      LPAREN Condition { codegen("ifeq L_for_%d\n", $1.varval.i_val+1); }
      RPAREN Block {
        codegen("goto L_for_%d\n", $1.varval.i_val);
        INDENT--;
        codegen("L_for_%d:\n", $1.varval.i_val+1);
        INDENT++;
    }
;

ForStmt
    : FOR { 
        $1.varval.i_val = labelcnt;
        labelcnt++;
    }
      LPAREN ForClause RPAREN Block {
        codegen("goto L_for_%d\n", $4.varval.i_val);
        INDENT--;
        codegen("L_for_%d:\n", $1.varval.i_val);
        INDENT++;
      }
;

ForClause
    : InitStmt SEMICOLON {
        $1.varval.i_val = labelcnt;
        labelcnt += 3;
        INDENT--;
        codegen("L_for_%d:\n", $1.varval.i_val+1);
        INDENT++;
    }
      Condition SEMICOLON {
        codegen("ifeq L_for_%d\n", $1.varval.i_val-1);
        codegen("goto L_for_%d\n", $1.varval.i_val+2);
        INDENT--;
        codegen("L_for_%d:\n", $1.varval.i_val);
        INDENT++;
    }
      PostStmt {
        codegen("goto L_for_%d\n", $1.varval.i_val+1);
        INDENT--;
        codegen("L_for_%d:\n", $1.varval.i_val+2);
        INDENT++;
        $$.varval.i_val = $1.varval.i_val;
    }
    
;

InitStmt
    : SimpleExpr
;

PostStmt
    : SimpleExpr
;

SimpleExpr
    : AssignExpr 
    | Expr
    | IncDecExpr
;

PrintStmt
    : PRINT LPAREN Expr RPAREN SEMICOLON    { 
        load_val(&$3);               
        gen_print($3.type);
    }
;

Expr
    : AndExpr               { $$ = $1; }
    | Expr OR { load_val(&$1); }
      AndExpr       {        
        if(!is_bool($1.type)){
            printf("error:%d: invalid operation: (operator LOR not defined on %s)\n", yylineno, $1.type);
            HAS_ERROR = true;
        }
        else if(!is_bool($4.type)){
            printf("error:%d: invalid operation: (operator LOR not defined on %s)\n", yylineno, $4.type);
            HAS_ERROR = true;
        }
        else {            
            load_val(&$4);
            codegen("ior\n");
        }
        $$.type = "bool";     
        $$.addr = -2; 
    }     
;

AndExpr
    : CompExpr                 { $$ = $1; }
    | AndExpr AND { load_val(&$1); }
      CompExpr     {
        if(strcmp($1.type, "bool")) {
            printf("error:%d: invalid operation: (operator AND not defined on %s)\n", yylineno, $1.type);
            HAS_ERROR = true;
        }
        else if(strcmp($4.type, "bool")) {
            printf("error:%d: invalid operation: (operator AND not defined on %s)\n", yylineno, $4.type);
            HAS_ERROR = true;
        }
        else {            
            load_val(&$4);
            codegen("iand\n");
        }
        $$.type = "bool"; 
        $$.addr = -2;
    }     
;

CompExpr
    : AddExpr                       { $$ = $1; }
    | CompExpr CmpOp { load_val(&$1); }
      AddExpr        {               
        load_val(&$4);
        if(!strcmp($2.op, "GTR")){
            if(is_int($1.type)){
                codegen("if_icmpgt L_cmp_%d\n", labelcnt);
            }
            else{
                codegen("fcmpl\n");
                codegen("ifgt L_cmp_%d\n", labelcnt);
            }
        }
        else if(!strcmp($2.op, "LSS")){
            if(is_int($1.type)){
                codegen("if_icmplt L_cmp_%d\n", labelcnt);
            }
            else{
                codegen("fcmpl\n");
                codegen("iflt L_cmp_%d\n", labelcnt);
            }
        }
        else if(!strcmp($2.op, "GEQ")){
            if(is_int($1.type)){
                codegen("if_icmplt L_cmp_%d\n", labelcnt);
            }
            else{
                codegen("fcmpl\n");
                codegen("iflt L_cmp_%d\n", labelcnt);
            }
        }
        else if(!strcmp($2.op, "LEQ")){
            if(is_int($1.type)){
                codegen("if_icmpgt L_cmp_%d\n", labelcnt);
            }
            else{
                codegen("fcmpl\n");
                codegen("ifgt L_cmp_%d\n", labelcnt);
            }
        }
        else if(!strcmp($2.op, "EQL")){
            if(is_int($1.type)){
                codegen("if_icmpeq L_cmp_%d\n", labelcnt);
            }
            else{
                codegen("fcmpl\n");
                codegen("ifeq L_cmp_%d\n", labelcnt);
            }
        }
        else if(!strcmp($2.op, "NEQ")){
            if(is_int($1.type)){
                codegen("if_icmpeq L_cmp_%d\n", labelcnt);
            }
            else{
                codegen("fcmpl\n");
                codegen("ifeq L_cmp_%d\n", labelcnt);
            }
        }
        int first, second;
        if((!strcmp($2.op, "GEQ")||!strcmp($2.op, "LEQ")||!strcmp($2.op, "NEQ"))){
            first = 1;
            second = 0;
        }
        else{
            first = 0;
            second = 1;
        }
        codegen("iconst_%d\n", first);
        codegen("goto L_cmp_%d\n",labelcnt+1);
        INDENT--;
        codegen("L_cmp_%d:\n", labelcnt);
        INDENT++;
        codegen("iconst_%d\n", second);
        INDENT--;
        codegen("L_cmp_%d:\n", labelcnt+1);
        INDENT++;
        labelcnt += 2;
        $$.type = "bool"; 
        $$.addr = -2;
    }
;

AddExpr
    : MulExpr                    { $$ = $1; }
    | AddExpr AddOp { load_val(&$1);}
      MulExpr      {        
        if(!strcmp($1.type, $4.type)) {               
            load_val(&$4);         
            if(!strcmp($2.op, "ADD"))
                gen_instr($1.type, "add", 0, -1);
            else
                gen_instr($1.type, "sub", 0, -1);
        }
        else{
            printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n", 
                yylineno, $2.op, $1.type, $4.type);
            HAS_ERROR = true;
        }
        $$.type = $1.type;
        $$.addr = -2;
    }  
;

MulExpr
    : UnaryExpr                 { $$ = $1; }
    | MulExpr MulOp { load_val(&$1); }
      UnaryExpr   {        
        load_val(&$4);
        if(!strcmp($2.op, "MUL"))
            gen_instr($1.type, "mul", 0, -1);
        else if(!strcmp($2.op, "QUO"))
            gen_instr($1.type, "div", 0, -1);
        else if(!strcmp($2.op, "REM") && 
            !(is_float($1.type) || is_float($4.type)))
            codegen("irem\n");
        else{
            printf("error:%d: invalid operation: (operator REM not defined on float32)\n", 
                yylineno);
            HAS_ERROR = true;
        }
        $$.type = $1.type;
        $$.addr = -2; 
    }
;

UnaryExpr
    : PrimaryExpr           { $$ = $1; }
    | UnaryOp UnaryExpr     { 
        load_val(&$2);
        if(!strcmp($1.op, "NEG") && (is_int($2.type) || is_float($2.type))){
            gen_instr($2.type, "neg", 0, -1);
        }
        else if(!strcmp($1.op, "POS") && (is_int($2.type) || is_float($2.type))){
          // valid but nothing to do
        }
        else if(!strcmp($1.op, "NOT") && is_bool($2.type)){
            codegen("iconst_1\n");
            codegen("ixor\n");
        }
        else{
            printf("error:%d: can't make operation %s for %s type\n", 
                yylineno, $1.op, $2.type);
            HAS_ERROR = true;
        }
        $$.type = $2.type;
        $$.addr = -2;
    }
;

PrimaryExpr
    : Operand               { $$ = $1; }
    | IndexExpr             { $$ = $1; }
    | ConvertExpr           { $$ = $1; }
;

IndexExpr
    : PrimaryExpr LBRACK { codegen("aload %d\n", $1.addr); }
      Expr RBRACK    {               
        load_val(&$4);
        $$ = $1;         
        $$.is_arr = 1;
    }
;

ConvertExpr
    : LPAREN Type RPAREN Expr  {
        load_val(&$4);
        if(strcmp($<val>2.type, $<val>4.type))
            codegen("%s\n", is_int($<val>2.type) ? "f2i" : "i2f");
        $$.type = $2.type; 
        $$.addr = -2;
    }
;

IncDecExpr 
    : Expr IncDecOp     { 
        load_val(&$1);
        gen_instr($1.type, "const_1", 0, -1);
        if(!strcmp($2.op, "INC"))
            gen_instr($1.type, "add", 0, -1);
        else
            gen_instr($1.type, "sub", 0, -1);
        gen_instr($1.type, "store", 0, $1.addr);
    }
;

AssignExpr 
    : Expr AssignOp Expr   { 
        if(strcmp($1.type, $3.type)) {
            printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n"
                , yylineno, $2.op, $1.type, $3.type);
        }
        else if($1.addr == -1){
            printf("error:%d: cannot assign to %s\n", yylineno, $1.type);
        }
        else {            
            if(!strcmp($2.op, "ASSIGN")){    
                load_val(&$3);            
                gen_instr($1.type, "store", $1.is_arr, $1.addr);
            }
            else { // do arithmetic operation first
                load_val(&$1);
                load_val(&$3);
                if(!strcmp($2.op, "ADD_ASSIGN"))
                    gen_instr($1.type, "add", 0, -1);
                else if(!strcmp($2.op, "SUB_ASSIGN"))
                    gen_instr($1.type, "sub", 0, -1);
                else if(!strcmp($2.op, "MUL_ASSIGN"))
                    gen_instr($1.type, "mul", 0, -1);
                else if(!strcmp($2.op, "QUO_ASSIGN"))
                    gen_instr($1.type, "div", 0, -1);
                else if(!strcmp($2.op, "REM_ASSIGN"))
                    gen_instr($1.type, "rem", 0, -1);
                gen_instr($1.type, "store", 0, $1.addr);
            }
        } 
    }
;

Operand
    : Literal       { $$ = $1; $$.addr = -1;}
    | ID            { 
        lookup_symbol(&$1);
        $$ = $1;
        $$.is_arr = 0;
    }         
    | LPAREN Expr RPAREN  { $$ = $2;}
;

Literal
    : INT_LIT     { $$.type = "int"; }
    | FLOAT_LIT   { $$.type = "float"; }
    | STRING_LIT  { $$.type = "string"; }
    | BOOL_LIT    { $$.type = "bool"; }
;

Type
    : INT           { $$.type = "int"; }
    | FLOAT         { $$.type = "float"; }
    | STRING        { $$.type = "string"; }
    | BOOL          { $$.type = "bool"; }
;

CmpOp
    : GTR       { $$.op = "GTR"; }
    | LSS       { $$.op = "LSS"; }
    | GEQ       { $$.op = "GEQ"; }
    | LEQ       { $$.op = "LEQ"; }
    | EQL       { $$.op = "EQL"; }
    | NEQ       { $$.op = "NEQ"; }
;

AddOp
    : ADD       { $$.op = "ADD"; }
    | SUB       { $$.op = "SUB"; }
;

MulOp
    : MUL       { $$.op = "MUL"; }
    | QUO       { $$.op = "QUO"; }
    | REM       { $$.op = "REM"; }
;

UnaryOp
    : ADD       { $$.op = "POS"; }
    | SUB       { $$.op = "NEG"; }
    | NOT       { $$.op = "NOT"; }
;

AssignOp 
    : ASSIGN        { $$.op = "ASSIGN"; }
    | ADD_ASSIGN    { $$.op = "ADD_ASSIGN"; }
    | SUB_ASSIGN    { $$.op = "SUB_ASSIGN"; }
    | MUL_ASSIGN    { $$.op = "MUL_ASSIGN"; }
    | QUO_ASSIGN    { $$.op = "QUO_ASSIGN"; }
    | REM_ASSIGN    { $$.op = "REM_ASSIGN"; }
;

IncDecOp
    : INC       { $$.op = "INC"; }
    | DEC       { $$.op = "DEC"; }
;


%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }

    /* Codegen output init */
    char *bytecode_filename = "hw3.j";
    fout = fopen(bytecode_filename, "w");
    codegen(".source hw3.j\n");
    codegen(".class public Main\n");
    codegen(".super java/lang/Object\n");
    codegen(".method public static main([Ljava/lang/String;)V\n");
    codegen(".limit stack 100\n");
    codegen(".limit locals 100\n");
    INDENT++;

    yyparse();

    /* Codegen end */
    codegen("return\n");
    INDENT--;
    codegen(".end method\n");
    fclose(fout);
    fclose(yyin);

    if (HAS_ERROR) {
        remove(bytecode_filename);
    }

    return 0;
}

static void create_symbol() {
    scope++;
}

static void insert_symbol(val_info* this_val) {
    for(int i = addrNum - 1; i >= 0; i --){
        if(!strcmp(this_val->id, symbols[i].name) && symbols[i].valid 
            && symbols[i].scope == scope){
            printf("error:%d: %s redeclared in this block. previous declaration at line %d\n"
                ,yylineno, this_val->id, symbols[i].lineno);
            return;
        }
    }
    //printf("> Insert {%s} into symbol table (scope level: %d)\n", this_val->id, scope);
    symbols[addrNum].index = idx_scope[scope];
    symbols[addrNum].name = this_val->id;
    symbols[addrNum].lineno = yylineno;
    symbols[addrNum].scope = scope;
    symbols[addrNum].valid = 1;
    if(this_val->is_arr){
        symbols[addrNum].type = "array";
        symbols[addrNum].element = this_val->type;
    } else {
        symbols[addrNum].type = this_val->type;
        symbols[addrNum].element = "-";
    }
    addrNum++;
    idx_scope[scope]++;
}

static void lookup_symbol(val_info* this_val) {
    for(int i = addrNum - 1; i >= 0; i --){
        if(!strcmp(this_val->id, symbols[i].name) && symbols[i].valid == 1){
            this_val->addr = i;
            this_val->type = (strcmp(symbols[i].type, "array")) ? symbols[i].type : symbols[i].element;
            return;
        }
    }
    printf("error:%d: undefined: %s\n", yylineno, this_val->id);
    HAS_ERROR = true;
}

static void dump_symbol() {
    idx_scope[scope] = 0;
    for(int i = 0; i < addrNum; i++){
        if(symbols[i].scope == scope && symbols[i].valid == 1){
            symbols[i].valid = 0;
        }
    }
    scope--;
}

static void gen_instr(char* type, char* op, int8_t is_arr, int second_arg) {
    char complete[20];
    char *head;
    memset(complete, '\0', 20);
    if(is_int(type)||is_bool(type))
        if(!is_arr)
            head = "i";
        else {            
            head = "ia";
            second_arg = -1;
        }
    else if(is_float(type))
        if(!is_arr)
            head = "f";
        else {
            head = "fa";
            second_arg = -1;
        }
    else if(is_string(type))
        head = "a";        
    strcat(complete, head);
    strcat(complete, op);
    if(second_arg == -1) { //no second argument
        codegen("%s\n", complete);
    }
    else {
        codegen("%s %d\n", complete, second_arg);
    }
}

static void gen_print(char* type) {
    if(is_bool(type)){    
        codegen("ifne L_cmp_%d\n", labelcnt);
        codegen("ldc \"false\"\n");
        codegen("goto L_cmp_%d\n", labelcnt+1);
        INDENT--;
        codegen("L_cmp_%d:\n", labelcnt);
        INDENT++;
        codegen("ldc \"true\"\n");
        INDENT--;
        codegen("L_cmp_%d:\n", labelcnt+1);
        INDENT++;
        labelcnt += 2;
    }

    char *tail;
    if(is_int(type))
        tail = "I";
    else if(is_float(type))
        tail = "F";
    else
        tail = "Ljava/lang/String;";
    codegen("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
    codegen("swap\n");
    codegen("invokevirtual java/io/PrintStream/print(%s)V\n", tail);
}

static void load_val(val_info* this_val) {
    if(this_val->addr > -1){ //load identifier
        gen_instr(this_val->type, "load", this_val->is_arr, this_val->addr);                          
    }
    else if(this_val->addr == -1){ // load literal
        if(is_int(this_val->type))
            codegen("ldc %d\n", this_val->varval.i_val);
        else if(is_float(this_val->type))
            codegen("ldc %#f\n", this_val->varval.f_val);
        else if(is_string(this_val->type))
            codegen("ldc \"%s\"\n", this_val->varval.s_val);
        else if(is_bool(this_val->type))
            codegen("iconst_%d\n", (!strcmp(this_val->varval.s_val, "TRUE"))? 1 : 0);
    }
    // if addr == -2, it means the value is already at the stack, so no need to load it
}