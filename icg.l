%{
#include <stdio.h>
#include <string.h>
#include "y.tab.h"

char c;

%}

%option yylineno
DIGIT  [0-9]+
ID [a-zA-Z_][0-9a-zA-Z_]*
FLOAT [0-9]+[.][0-9]*

ARITHMETIC_OPERATORS ['+' '\-' '*' '/' '^' '%' '@']
OTHER_CHARACTERS ['=' ':' ';' '(' ')' '{' '}' ',']
BITWISE_OPERATORS ['|' '&' '^' ]
TYPES ["int" "unsigned_int" "double"]

%%
[ \t] ;
[\n] ;


"if" 								{ return (IF); }
"else" 								{ return (ELSE); }
"for"								{return (FOR);}
"break"								{return (BREAK);}
"while"								{ return (WHILE); }
"unsigned_int" 						{return (TYPES);}
"boolean" 							{return (TYPES);}
"int"								{ return (TYPES); }
"float"								{ return (TYPES); }
"long"								{ return (TYPES); }
"char"								{ return (TYPES); }
"double"							{ return (TYPES); }
"++"								{yylval.string_val = strdup(yytext); return INCR;}
"--" 								{yylval.string_val=strdup(yytext); return DECR;}
"+="								{yylval.string_val=strdup(yytext); return PE;}
"-="								{yylval.string_val=strdup(yytext); return ME;}
">"									{yylval.string_val = strdup(yytext);
									return (REL_OPT);}
"<"									{yylval.string_val = strdup(yytext);
									return (REL_OPT);}
">="								{yylval.string_val = strdup(yytext);
									return (REL_OPT);}
"<="								{yylval.string_val = strdup(yytext);
									return (REL_OPT);}
"!="								{yylval.string_val = strdup(yytext);
									return (REL_OPT);}
"=="								{yylval.string_val = strdup(yytext);
									return (REL_OPT);}
	
"||"								{yylval.string_val = strdup(yytext);
									return (OR);}
"&&"								{yylval.string_val = strdup(yytext);
									return (AND);}
"!"									{yylval.string_val = strdup(yytext);
									return (NOT);}
"true"								{yylval.string_val = strdup(yytext);
									return (TRUE);}
"false"								{yylval.string_val = strdup(yytext);
									return (FALSE);}

{DIGIT}  							{ yylval.int_val = atoi(yytext);
	   								return DIGIT; }

{FLOAT}  							{ yylval.float_val = atof(yytext);
	   								return FLOAT; }

{ID} 								{yylval.string_val = strdup(yytext);return ID; }
{ARITHMETIC_OPERATORS}   			{c = yytext[0];return(c);}
{BITWISE_OPERATORS}					{c=yytext[0]; return (c);}
{OTHER_CHARACTERS}   				{c = yytext[0];return(c);}

%%