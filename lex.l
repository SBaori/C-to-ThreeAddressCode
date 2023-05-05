%{
typedef struct B {
    int t;
    int f;
}B;
#include "y.tab.h"
%}
%option header-file="myLexHeader.h"

%%

"#include"					return INCLUDE;
"<"[a-zA-Z]+\.h">"				return INCL_FILE;
"#define" 					{strcpy(yylval.string,yytext); return MACRO;}
(int|char|float)				return TYPE;
"if"						return IF;
"else"						return ELSE;
"for"						return FOR;
"while"						return WHILE;
"main"						return MAIN;
"return"                    			return RETURN;
(<|>|>=|<=|==)					{strcpy(yylval.string,yytext); return LOGIC_OPRTR;}
"&&"						return AND;
"||"						return OR;
(\+=|\-=|\*=|\/=)				return OPRTR_ASSGN;
(\+\+|\-\-)					return UNARY;
([_|a-z]+[0-9]*)*				{strcpy(yylval.string,yytext); return VARIABLE;}
[0-9]*						{strcpy(yylval.string,yytext); return CONSTANT;}
\/\/(.*)					return S_COMMENT;
\/\*(.*\n*)*\*\/				return M_COMMENT;
[\n\r]						{yylineno++;}
[-;+*/=(),{}]					{return yytext[0];}			
[ \t]+						;
. 						return ERROR;

%%

int yywrap(void)
{
	return 1;
}
