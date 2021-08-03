/* A Bison parser, made by GNU Bison 3.5.1.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2020 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Undocumented macros, especially those whose name start with YY_,
   are private implementation details.  Do not rely on them.  */

#ifndef YY_YY_Y_TAB_H_INCLUDED
# define YY_YY_Y_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    LPAREN = 258,
    RPAREN = 259,
    LBRACK = 260,
    RBRACK = 261,
    LBRACE = 262,
    RBRACE = 263,
    SEMICOLON = 264,
    COMMA = 265,
    PRINT = 266,
    IF = 267,
    ELSE = 268,
    FOR = 269,
    WHILE = 270,
    RETURN = 271,
    BREAK = 272,
    CONTINUE = 273,
    INT = 274,
    FLOAT = 275,
    BOOL = 276,
    STRING = 277,
    VOID = 278,
    INT_LIT = 279,
    FLOAT_LIT = 280,
    STRING_LIT = 281,
    BOOL_LIT = 282,
    ID = 283,
    ADD = 284,
    SUB = 285,
    MUL = 286,
    QUO = 287,
    REM = 288,
    INC = 289,
    DEC = 290,
    OR = 291,
    AND = 292,
    NOT = 293,
    POS = 294,
    NEG = 295,
    GTR = 296,
    LSS = 297,
    GEQ = 298,
    LEQ = 299,
    EQL = 300,
    NEQ = 301,
    ASSIGN = 302,
    ADD_ASSIGN = 303,
    SUB_ASSIGN = 304,
    MUL_ASSIGN = 305,
    QUO_ASSIGN = 306,
    REM_ASSIGN = 307
  };
#endif
/* Tokens.  */
#define LPAREN 258
#define RPAREN 259
#define LBRACK 260
#define RBRACK 261
#define LBRACE 262
#define RBRACE 263
#define SEMICOLON 264
#define COMMA 265
#define PRINT 266
#define IF 267
#define ELSE 268
#define FOR 269
#define WHILE 270
#define RETURN 271
#define BREAK 272
#define CONTINUE 273
#define INT 274
#define FLOAT 275
#define BOOL 276
#define STRING 277
#define VOID 278
#define INT_LIT 279
#define FLOAT_LIT 280
#define STRING_LIT 281
#define BOOL_LIT 282
#define ID 283
#define ADD 284
#define SUB 285
#define MUL 286
#define QUO 287
#define REM 288
#define INC 289
#define DEC 290
#define OR 291
#define AND 292
#define NOT 293
#define POS 294
#define NEG 295
#define GTR 296
#define LSS 297
#define GEQ 298
#define LEQ 299
#define EQL 300
#define NEQ 301
#define ASSIGN 302
#define ADD_ASSIGN 303
#define SUB_ASSIGN 304
#define MUL_ASSIGN 305
#define QUO_ASSIGN 306
#define REM_ASSIGN 307

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 65 "compiler_hw3.y"
 
    //struct val_info_s val;
    val_info val;

#line 166 "y.tab.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_Y_TAB_H_INCLUDED  */
