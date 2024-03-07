%option noyywrap
%{
    #include<iostream>
    #include<stdlib.h>
    #include<string.h>
    #include "SymbolInfo.h"
    #include"y.tab.h"
    using namespace std;
    
int line_count=1;
extern FILE *logout;
extern SymbolTable *table;
extern YYSTYPE yylval;

%}

digit [0-9]
letter [a-zA-Z]
delim [ \t\r\f\v]
newline \n
ws [delim]+
id (_|{letter})(_|{letter}|{digit})*
integer {digit}+
number {digit}*(\.{digit}+)?(E[+-]?{digit}+)?
ADDOP [+-] 
MULOP [*/%]

%%

"if" {
    SymbolInfo *s=new SymbolInfo(yytext,"IF");
    yylval.sym=s;
    s->setStartLine(line_count);
    s->setEndLine(line_count);
    return IF;}
"else" {
    SymbolInfo *s=new SymbolInfo(yytext,"ELSE");
    yylval.sym=s;
    s->setStartLine(line_count);
    s->setEndLine(line_count);
    return ELSE;}
"for" {
    SymbolInfo *s=new SymbolInfo(yytext,"FOR");
    yylval.sym=s;
    s->setStartLine(line_count);
    s->setEndLine(line_count);
    return FOR;}
"while" {
    SymbolInfo *s=new SymbolInfo(yytext,"WHILE");
    yylval.sym=s;
    s->setStartLine(line_count);
    s->setEndLine(line_count);
    return WHILE;}
"int" {
    fprintf(logout,"Line# %d: Token <INT> Lexeme int found\n",line_count); 
    SymbolInfo *s=new SymbolInfo(yytext,"INT");
    s->setStartLine(line_count);
    s->setEndLine(line_count);
    yylval.sym=s;
    return INT;
    }
"float" {
    fprintf(logout,"Line# %d: Token <FLOAT> Lexeme float found\n",line_count); 
    SymbolInfo *s=new SymbolInfo(yytext,"FLOAT");
    s->setStartLine(line_count);
    s->setEndLine(line_count);
    yylval.sym=s;
    return FLOAT;}
"return" {
    fprintf(logout,"Line# %d: Token <RETURN> Lexeme return found\n",line_count); 
    SymbolInfo *s=new SymbolInfo(yytext,"RETURN");
    s->setStartLine(line_count);
    s->setEndLine(line_count);
    yylval.sym=s;
    return RETURN;}
"void" {
    fprintf(logout,"Line# %d: Token <VOID> Lexeme void found\n",line_count); 
    SymbolInfo *s=new SymbolInfo(yytext,"VOID");
    s->setStartLine(line_count);
    s->setEndLine(line_count);
    yylval.sym=s;
    return VOID;}
"println"	{
    fprintf(logout,"Line# %d: Token <VOID> Lexeme void found\n",line_count); 
    SymbolInfo *s=new SymbolInfo(yytext,"PRINTLN");
    yylval.sym=s;
    return PRINTLN;}

{ADDOP} {
     fprintf(logout,"Line# %d: Token <ADDOP> Lexeme %s found\n",line_count,yytext); 
     SymbolInfo *s=new SymbolInfo(yytext,"ADDOP");
     s->setStartLine(line_count);
     s->setEndLine(line_count);
     yylval.sym=s;
     return ADDOP;
}
{MULOP} {
     fprintf(logout,"Line# %d: Token <MULOP> Lexeme %s found\n",line_count,yytext); 
     SymbolInfo *s=new SymbolInfo(yytext,"MULOP");
     s->setStartLine(line_count);
     s->setEndLine(line_count);
     yylval.sym=s;
     return MULOP;
}
"=" 	{
     fprintf(logout,"Line# %d: Token <ASSIGNOP> Lexeme %s found\n",line_count,yytext); 
     SymbolInfo *s=new SymbolInfo(yytext,"ASSIGNOP");
     yylval.sym=s;
     s->setStartLine(line_count);
    s->setEndLine(line_count);
    return ASSIGNOP;}

">" |
"<" |
">=" |
"<=" |
"==" |
"!=" {
		SymbolInfo *s= new  SymbolInfo(yytext,"RELOP");
		yylval.sym =s;
        s->setStartLine(line_count);
        s->setEndLine(line_count);
        fprintf(logout,"Line# %d: Token <RELOP> Lexeme %s found\n",line_count,yytext); 
		return RELOP;

	}

"&&"	|
"||"	{
			SymbolInfo *s= new  SymbolInfo(yytext,"LOGICOP");
			yylval.sym =s;
            s->setStartLine(line_count);
            s->setEndLine(line_count);
            fprintf(logout,"Line# %d: Token <LOGICOP> Lexeme %s found\n",line_count,yytext); 
			return LOGICOP;
		}
"!"		{	
     fprintf(logout,"Line# %d: Token <NOT> Lexeme %s found\n",line_count,yytext); 
     SymbolInfo *s=new SymbolInfo(yytext,"NOT");
     s->setStartLine(line_count);
     s->setEndLine(line_count);
     yylval.sym=s;
    return NOT; }


";" 	{ 
    { fprintf(logout,"Line# %d: Token <SEMICOLON> Lexeme %s found\n",line_count,yytext); }
    SymbolInfo *s=new SymbolInfo(yytext,"SEMICOLON");
    s->setStartLine(line_count);
    s->setEndLine(line_count);
    yylval.sym=s;
    return SEMICOLON;}
"," 	{
    { fprintf(logout,"Line# %d: Token <COMMA> Lexeme %s found\n",line_count,yytext); }
    SymbolInfo *s=new SymbolInfo(yytext,"COMMA");
    s->setStartLine(line_count);
    s->setEndLine(line_count);
    yylval.sym=s;
    return COMMA;}
"(" 	{
    { fprintf(logout,"Line# %d: Token <LPAREN> Lexeme %s found\n",line_count,yytext); }
    SymbolInfo *s=new SymbolInfo(yytext,"LPAREN");
    s->setStartLine(line_count);
    s->setEndLine(line_count);
    yylval.sym=s;
    return LPAREN;}
")" 	{
    { fprintf(logout,"Line# %d: Token <RPAREN> Lexeme %s found\n",line_count,yytext); }
    SymbolInfo *s=new SymbolInfo(yytext,"RPAREN");
    s->setStartLine(line_count);
    s->setEndLine(line_count);
    yylval.sym=s;
    return RPAREN;}
"{" 	{
    { fprintf(logout,"Line# %d: Token <LCURL> Lexeme %s found\n",line_count,yytext); }
    SymbolInfo *s=new SymbolInfo(yytext,"LCURL");
    s->setStartLine(line_count);
    s->setEndLine(line_count);
    table->enterScope();
     yylval.sym=s;
    return LCURL;}
"}" 	{
    fprintf(logout,"Line# %d: Token <RCURL> Lexeme %s found\n",line_count,yytext);
    SymbolInfo *s=new SymbolInfo(yytext,"RCURL");
    s->setStartLine(line_count);
    s->setEndLine(line_count);
    yylval.sym=s;
    
    
    return RCURL;}
"[" 	{
    { fprintf(logout,"Line# %d: Token <LSQUARE> Lexeme %s found\n",line_count,yytext); }
    SymbolInfo *s=new SymbolInfo(yytext,"LSQUARE");
    s->setStartLine(line_count);
    s->setEndLine(line_count);
    yylval.sym=s;
    return LTHIRD;}
"]" 	{
    { fprintf(logout,"Line# %d: Token <RSQUARE> Lexeme %s found\n",line_count,yytext); }
    SymbolInfo *s=new SymbolInfo(yytext,"RSQUARE");
    s->setStartLine(line_count);
    s->setEndLine(line_count);
    yylval.sym=s;
    return RTHIRD;}
"++" 	{
     fprintf(logout,"Line# %d: Token <INCOP> Lexeme %s found\n",line_count,yytext); 
     SymbolInfo *s=new SymbolInfo(yytext,"INCOP");
     s->setStartLine(line_count);
     s->setEndLine(line_count);
     yylval.sym=s;
    return INCOP;}
"--" 	{
     fprintf(logout,"Line# %d: Token <DECOP> Lexeme %s found\n",line_count,yytext); 
     SymbolInfo *s=new SymbolInfo(yytext,"DECOP");
     s->setStartLine(line_count);
     s->setEndLine(line_count);
     yylval.sym=s;
    return DECOP;}

{integer}	{
				SymbolInfo *s= new  SymbolInfo(yytext,"CONST_INT");
				yylval.sym = s;
                s->setStartLine(line_count);
                s->setEndLine(line_count);
                fprintf(logout,"Line# %d: Token <CONST_INT> Lexeme %s found\n",line_count,yytext); 
				return CONST_INT;
			}
{number} 	{	
				SymbolInfo *s= new  SymbolInfo(yytext,"CONST_FLOAT");
				yylval.sym =s;
                s->setStartLine(line_count);
                s->setEndLine(line_count);
                fprintf(logout,"Line# %d: Token <CONST_FLOAT> Lexeme %s found\n",line_count,yytext); 
				return CONST_FLOAT; 

			}
{id} 		{	
   
     fprintf(logout,"Line# %d: Token <ID> Lexeme %s found\n",line_count,yytext); 
     
				
				SymbolInfo *s= table->lookUp(yytext);
				if(s==NULL)
				{	
                    s= new SymbolInfo(yytext, (char *)"ID");
				}
				yylval.sym =s;
                s->setStartLine(line_count);
                s->setEndLine(line_count);
				return ID;
			}

{newline} {line_count++;}
{ws}	{}
	
%%



