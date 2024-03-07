%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<vector>
#include "SymbolInfo.h"
using namespace std;
int yyparse(void);
int yylex(void);
extern FILE *yyin;
FILE *logout,*input,*parseTree,*errorFp;
SymbolTable *table;
string type="";
vector<SymbolInfo*> variableList;
extern int line_count;

SymbolInfo* createNode(string label) {
	string str="Grammar";
    SymbolInfo* node = new SymbolInfo(label,str);
    return node;
}

SymbolInfo* addChild(SymbolInfo* parent,SymbolInfo *child) {
    parent->getChildren().push_back(child);
}

void printParseTree(SymbolInfo* node, int depth) {
    if (node == nullptr) {
        return;
    }
    for (int i = 0; i < depth; i++) {
        fprintf(parseTree, " ");
    }
	if(node->getType()=="Grammar"){
    	fprintf(parseTree, "%s	", node->getName().c_str());
		
	}else{
		fprintf(parseTree, "%s : %s		", node->getType().c_str(),node->getName().c_str());
	}
	if(node->getStartLine()==node->getEndLine()&& node->getType()!="Grammar")
	{
		fprintf(parseTree, "<Line: %d>\n",node->getStartLine());
	}else{
		fprintf(parseTree, "<Line: %d-%d>\n",node->getStartLine(),node->getEndLine());
	}
    for (SymbolInfo* child : node->getChildren()) {
        printParseTree(child, depth + 1);
    }
}

//dollar kore jeytya pacchi sheta yyval
%}

%union {
	SymbolInfo* sym;
}

%token<sym> IF ELSE FOR WHILE ID LPAREN RPAREN SEMICOLON LCURL RCURL COMMA INT FLOAT VOID LTHIRD CONST_INT RTHIRD PRINTLN RETURN ASSIGNOP LOGICOP RELOP ADDOP MULOP CONST_FLOAT NOT INCOP DECOP
%type<sym>  start program unit func_declaration func_definition parameter_list compound_statement var_declaration type_specifier declaration_list statements statement expression_statement variable expression logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments 

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%left 
%right
%%


start : program
	{
		fprintf(logout,"start : program\n");
    	
		$$ = createNode("start: program");
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		addChild($$, $1);
    	printParseTree($$, 0);
	}
	;

program : program unit 
	{
		fprintf(logout,"program : program unit  \n");

		$$ = createNode("program : program unit ");
		addChild($$, $1);
		addChild($$, $2);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($2->getEndLine());
	}
	| unit  
	{
		fprintf(logout,"program : unit  \n");

		$$ = createNode("program : unit");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
	}
	;
	
unit : var_declaration
	{
		fprintf(logout,"unit : var_declaration  \n");

		$$ = createNode("unit : var_declaration");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
	}
    | func_declaration 
	{
		fprintf(logout,"unit : func_declaration  \n");

		$$ = createNode("unit : func_declaration");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		

	}
    | func_definition  
	{
		fprintf(logout,"unit : func_definition  \n");
		$$ = createNode("unit : func_definition");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
	}
    ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON 
	{
		fprintf(logout,"func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON \n");
		$$ = createNode("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON");
		addChild($$, $1);
    	addChild($$, $2);
    	addChild($$, $3);
    	addChild($$, $4);
    	addChild($$, $5);
    	addChild($$, $6);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($6->getEndLine());

		if(table->lookUp($2->getName().c_str()))
		{
			fprintf(errorFp,"Line# %d:Redefinition of parameter %s\n",$1->getStartLine()),$3->getName();
		}
		


		SymbolInfo *s=new SymbolInfo($2->getName(),$1->getType());
		s->setIsFunc();
		table->insert(s);
		for(int i=0;i<variableList.size();i++)
		{
			s->addParam(variableList[i]);
		}
		variableList.clear();
	}
	| type_specifier ID LPAREN RPAREN SEMICOLON 
	{
		fprintf(logout,"func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON \n");
		$$ = createNode("func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON");
		addChild($$, $1);
    	addChild($$, $2);
    	addChild($$, $3);
    	addChild($$, $4);
    	addChild($$, $5);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($5->getEndLine());
		SymbolInfo *s=new SymbolInfo($2->getName(),$1->getType());
		s->setIsFunc();
		table->insert(s);
		for(int i=0;i<variableList.size();i++)
		{
			s->addParam(variableList[i]);
		}
		variableList.clear();
	}
	;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
	{
		fprintf(logout,"func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement \n");
		$$ = createNode("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement");
		addChild($$, $1);
    	addChild($$, $2);
    	addChild($$, $3);
    	addChild($$, $4);
    	addChild($$, $5);
    	addChild($$, $6);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($6->getEndLine());
		SymbolInfo *s=new SymbolInfo($2->getName(),$1->getType());
		s->setDefine();
		s->setIsFunc();
		table->insert(s);
		for(int i=0;i<variableList.size();i++)
		{
			s->addParam(variableList[i]);
		}
		variableList.clear();
	}
	| type_specifier ID LPAREN RPAREN compound_statement 
	{
		fprintf(logout,"func_definition : type_specifier ID LPAREN RPAREN compound_statement \n");
		$$ = createNode("func_definition : type_specifier ID LPAREN RPAREN compound_statement");
    	addChild($$, $1);
    	addChild($$, $2);
    	addChild($$, $3);
    	addChild($$, $4);
    	addChild($$, $5);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($5->getEndLine());
		SymbolInfo *s=new SymbolInfo($2->getName(),$1->getType());
		s->setIsFunc();
		s->setDefine();
		table->insert(s);
		for(int i=0;i<variableList.size();i++)
		{
			s->addParam(variableList[i]);
		}
		variableList.clear();
	}
 	;				


parameter_list  : parameter_list COMMA type_specifier ID 
	{
		fprintf(logout,"parameter_list  : parameter_list COMMA type_specifier ID  \n");
		$$ = createNode("parameter_list  : parameter_list COMMA type_specifier ID");
		addChild($$, $1);
    	addChild($$, $2);
    	addChild($$, $3);
    	addChild($$, $4);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($4->getEndLine());


		SymbolInfo *s=new SymbolInfo($4->getName(),type);
		variableList.push_back(s);
		
		
	}
	| parameter_list COMMA type_specifier 
	{
		fprintf(logout,"parameter_list  : parameter_list COMMA type_specifier  \n");
		$$ = createNode("parameter_list  : parameter_list COMMA type_specifier");
		addChild($$, $1);
    	addChild($$, $2);
    	addChild($$, $3);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($3->getEndLine());
		
	}
 	| type_specifier ID 
	{
		fprintf(logout,"parameter_list  : type_specifier ID  \n");
		$$ = createNode("parameter_list  : type_specifier ID");
		addChild($$, $1);
		addChild($$, $2);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($2->getEndLine());

		SymbolInfo *s=new SymbolInfo($2->getName(),type);
		variableList.push_back(s);
	}
	| type_specifier
	{
		fprintf(logout,"parameter_list  : type_specifier  \n");
		$$ = createNode("parameter_list  : type_specifier");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
	}
 	;

 		
compound_statement : LCURL{
	

								for(int i=0;i<variableList.size();i++)
									{
										if(!table->insert(variableList[i])){
											fprintf(errorFp,"Line# %d:Redefinition of parameter %s\n",$1->getStartLine(),variableList[i]->getName().c_str());
										}
									}
								variableList.clear();

							} statements RCURL 
	{
		fprintf(logout,"compound_statement : LCURL statements RCURL \n");
		$$ = createNode("compound_statement : LCURL statements RCURL");
		addChild($$, $1);
		addChild($$, $2);
		addChild($$, $3);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($4->getEndLine());
		table->printAllScopeTable();
		table->exitScope();

	}
 	| LCURL RCURL 
	{
		fprintf(logout,"compound_statement : LCURL RCURL \n");
		$$ = createNode("compound_statement : LCURL RCURL");
		addChild($$, $1);
		addChild($$, $2);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($2->getEndLine());
		table->printAllScopeTable();
		table->exitScope();
			
	}
 	;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
	{
		fprintf(logout,"var_declaration : type_specifier declaration_list SEMICOLON  \n");
		$$ = createNode("var_declaration : type_specifier declaration_list SEMICOLON");
    	addChild($$, $1);
    	addChild($$, $2);
    	addChild($$, $3);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($3->getEndLine());
		
	}

 	;
 		 
type_specifier	: INT 
	{
		fprintf(logout,"type_specifier	: INT \n");
        $$= createNode("type_specifier	: INT");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		type="INT"; 
		$$->setType("INT");


	}
 	| FLOAT 
	{
		fprintf(logout,"type_specifier	: FLOAT \n");
		$$ = createNode("type_specifier	: FLOAT");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		type="FLOAT";
		$$->setType("FLOAT");
	}
 	| VOID 
	{
		fprintf(logout,"type_specifier	: VOID\n");
		$$ = createNode("type_specifier	: VOID");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		type="VOID";
		$$->setType("VOID");
	}
 	;
 		
declaration_list : declaration_list COMMA ID  
	{
		fprintf(logout,"declaration_list : declaration_list COMMA ID  \n");
		$$ = createNode("declaration_list : declaration_list COMMA ID");
		addChild($$, $1);
		addChild($$, $2);
		addChild($$, $3);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($3->getEndLine());

		if(type!="VOID"){
			SymbolInfo *s=new SymbolInfo($3->getName(),type);
		//variableList.push_back(new SymbolInfo("ID",type));
		table->insert(s);
		}
		else{
			fprintf(errorFp,"Line# %d:Redefinition of parameter %s\n",$1->getStartLine()),$3->getName();

		}
		


	}
 	| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD 
	{
		fprintf(logout,"declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE \n");
		$$ = createNode("declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE");
		addChild($$, $1);
		addChild($$, $2);
		addChild($$, $3);
		addChild($$, $4);
		addChild($$, $5);
		addChild($$, $6);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($6->getEndLine());
		SymbolInfo *s=new SymbolInfo($3->getName(),"ARRAY");
		
		//variableList.push_back(new SymbolInfo("ID",type));
		table->insert(s);
	}
 	| ID
	{
		fprintf(logout,"declaration_list : ID \n");
        $$ = createNode("declaration_list : ID");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		type="ID";
		$$->setType("ID");
		SymbolInfo *s=new SymbolInfo($1->getName(),type);
;		//variableList.push_back(new SymbolInfo("ID",type));
		table->insert(s);
	}
 	| ID LTHIRD CONST_INT RTHIRD
	{
		fprintf(logout,"declaration_list : ID LSQUARE CONST_INT RSQUARE \n");
		$$ = createNode("declaration_list : ID LSQUARE CONST_INT RSQUARE");
		addChild($$, $1);
		addChild($$, $2);
		addChild($$, $3);
		addChild($$, $4);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($4->getEndLine());
		SymbolInfo *s=new SymbolInfo($1->getName(),"ARRAY");
		
		//variableList.push_back(new SymbolInfo("ID",type));
		table->insert(s);
	}
 	;
 		  
statements : statement 
	{
		fprintf(logout,"statements : statement \n");
		$$ = createNode("statements : statement");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
	}
	| statements statement 
	{
		fprintf(logout,"statements : statements statement \n");
		$$ = createNode("statements : statements statement");
		addChild($$, $1);
		addChild($$, $2);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($2->getEndLine());
	}
	;
	   
statement : var_declaration 
	{
		fprintf(logout,"statement :  var_declaration \n");
		$$ = createNode("statement :  var_declaration");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
	}
	| expression_statement 
	{
		fprintf(logout,"statement :  expression_statement \n");
		$$ = createNode("statement :  expression_statement");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
	}
	| compound_statement 
	{
		fprintf(logout,"statement : compound_statement \n");
		$$ = createNode("statement : compound_statement");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
	}
	| FOR LPAREN expression_statement expression_statement expression RPAREN statement 
	{
		fprintf(logout,"statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement \n");
		$$ = createNode("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement");
		addChild($$, $1);
		addChild($$, $2);
		addChild($$, $3);
		addChild($$, $4);
		addChild($$, $5);
		addChild($$, $6);
		addChild($$, $7);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($7->getEndLine());
	}
	| IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	{
		fprintf(logout,"statement : IF LPAREN expression RPAREN statement \n");
		$$ = createNode("statement : IF LPAREN expression RPAREN statement");
		addChild($$, $1);
		addChild($$, $2);
		addChild($$, $3);
		addChild($$, $4);
		addChild($$, $5);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($5->getEndLine());
	}
	| IF LPAREN expression RPAREN statement ELSE statement 
	{
		fprintf(logout,"statement : IF LPAREN expression RPAREN statement ELSE statement \n");
		$$ = createNode("statement : IF LPAREN expression RPAREN statement ELSE statement");
		addChild($$, $1);
		addChild($$, $2);
		addChild($$, $3);
		addChild($$, $4);
		addChild($$, $5);
		addChild($$, $6);
		addChild($$, $7);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($7->getEndLine());
	}
	| WHILE LPAREN expression RPAREN statement 
	{
		fprintf(logout,"statement : WHILE LPAREN expression RPAREN statement \n");
		$$ = createNode("statement : WHILE LPAREN expression RPAREN statement");
		addChild($$, $1);
		addChild($$, $2);
		addChild($$, $3);
		addChild($$, $4);
		addChild($$, $5);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($5->getEndLine());
	}
	| PRINTLN LPAREN ID RPAREN SEMICOLON 
	{
		fprintf(logout,"statement : PRINTLN LPAREN ID RPAREN SEMICOLON \n");
		$$ = createNode("statement : PRINTLN LPAREN ID RPAREN SEMICOLON");
		addChild($$, $1);
		addChild($$, $2);
		addChild($$, $3);
		addChild($$, $4);
		addChild($$, $5);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($5->getEndLine());
	}
	| RETURN expression SEMICOLON 
	{
		fprintf(logout,"statement : RETURN expression SEMICOLON \n");
		$$ = createNode("statement : RETURN expression SEMICOLON");
		addChild($$, $1);
		addChild($$, $2);
		addChild($$, $3);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($3->getEndLine());
	}
	;
	  
expression_statement 	: SEMICOLON		 
	{
		fprintf(logout,"expression_statement :SEMICOLON \n");
		$$ = createNode("expression_statement :SEMICOLON");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
	}	
	| expression SEMICOLON  
	{
		fprintf(logout,"expression_statement :expression SEMICOLON \n");
		$$ = createNode("expression_statement :expression SEMICOLON");
		addChild($$, $1);
		addChild($$, $2);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($2->getEndLine());
	}
	;
	  
variable : ID 		 
	{
		fprintf(logout,"variable : ID  \n");
		$$ = createNode("variable : ID");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
	}
	| ID LTHIRD expression RTHIRD  
	{
		fprintf(logout,"variable : ID LSQUARE expression RSQUARE \n");
		$$ = createNode("variable : ID LSQUARE expression RSQUARE");
		addChild($$, $1);
		addChild($$, $2);
		addChild($$, $3);
		addChild($$, $4);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($4->getEndLine());
	}
	;
	 
 expression : logic_expression	 
 	{
		fprintf(logout,"expression : logic_expression \n");
		$$ = createNode("expression : logic_expression");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
	}
	| variable ASSIGNOP logic_expression 	
	{
		fprintf(logout,"expression : variable ASSIGNOP logic_expression \n");
		$$ = createNode("expression : variable ASSIGNOP logic_expression");
		addChild($$, $1);
		addChild($$, $2);
		addChild($$, $3);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($3->getEndLine());
	}
	;
			
logic_expression : rel_expression 	 
	{
		fprintf(logout,"logic_expression : rel_expression \n");
		$$ = createNode("logic_expression : rel_expression");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
	}
	| rel_expression LOGICOP rel_expression 	
	{
		fprintf(logout,"logic_expression : rel_expression LOGICOP rel_expression \n");
		$$ = createNode("logic_expression : rel_expression LOGICOP rel_expression");
		addChild($$, $1);
		addChild($$, $2);
		addChild($$, $3);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($3->getEndLine());
		
	}
	;
			
rel_expression	: simple_expression  
	{
		fprintf(logout,"rel_expression	: simple_expression \n");
		$$ = createNode("rel_expression	: simple_expression");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());

	}
	| simple_expression RELOP simple_expression	 
	{
		fprintf(logout,"rel_expression	: simple_expression RELOP simple_expression \n");
		$$ = createNode("rel_expression	: simple_expression RELOP simple_expression");
		addChild($$, $1);
		addChild($$, $2);
		addChild($$, $3);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($3->getEndLine());
	}
	;
				
simple_expression : term  
	{
		fprintf(logout,"simple_expression : term  \n");
		$$ = createNode("simple_expression : term");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
	}
	| simple_expression ADDOP term  
	{
		fprintf(logout,"simple_expression : simple_expression ADDOP term  \n");
		$$ = createNode("simple_expression : simple_expression ADDOP term");
		addChild($$, $1);
		addChild($$, $2);
		addChild($$, $3);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($3->getEndLine());
	}
	;
					
term :	unary_expression 
	{
		fprintf(logout,"term :	unary_expression \n");
		$$ = createNode("term :	unary_expression");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
	}
    |  term MULOP unary_expression 
	{
		fprintf(logout,"term : term MULOP unary_expression \n");
		$$ = createNode("term : term MULOP unary_expression");
		addChild($$, $1);
		addChild($$, $2);
		addChild($$, $3);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($3->getEndLine());
	}
    ;

unary_expression : ADDOP unary_expression  
	{ 	
		fprintf(logout,"unary_expression : ADDOP unary_expression \n");
		$$ = createNode("unary_expression : ADDOP unary_expression");
		addChild($$, $1);
		addChild($$, $2);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($2->getEndLine());
	}
	| NOT unary_expression  
	{
		fprintf(logout,"unary_expression : NOT unary_expression \n");
		$$ = createNode("unary_expression : NOT unary_expression");
		addChild($$, $1);
		addChild($$, $2);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($2->getEndLine());
	}
	| factor 
	{
		fprintf(logout,"unary_expression : factor \n");
		$$ = createNode("unary_expression : factor");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
	}
	;
	
factor	: variable 
	{
		fprintf(logout,"factor	: variable \n");
		$$ = createNode("factor	: variable");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
	}
	| ID LPAREN argument_list RPAREN 
	{
		fprintf(logout,"factor	: ID LPAREN argument_list RPAREN \n");
		$$ = createNode("factor	: ID LPAREN argument_list RPAREN");
		addChild($$, $1);
		addChild($$, $2);
		addChild($$, $3);
		addChild($$, $4);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($4->getEndLine());
	}
	| LPAREN expression RPAREN 
	{
		fprintf(logout,"factor : LPAREN expression RPAREN \n");
		$$ = createNode("factor : LPAREN expression RPAREN");
		addChild($$, $1);
		addChild($$, $2);
		addChild($$, $3);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($3->getEndLine());
	}
	| CONST_INT 
	{
		fprintf(logout,"factor : CONST_INT \n");
		$$ = createNode("factor : CONST_INT");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());

	}
	| CONST_FLOAT 
	{
		fprintf(logout,"factor : CONST_FLOAT \n");
		$$ = createNode("factor : CONST_FLOAT");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());

	}
	| variable INCOP  
	{
		fprintf(logout,"factor : variable INCOP \n");
		$$ = createNode("factor : variable INCOP");
		addChild($$, $1);
		addChild($$, $2);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($2->getEndLine());

	}
	| variable DECOP 
	{
		fprintf(logout,"factor : variable DECOP \n");
		$$ = createNode("factor : variable DECOP");
		addChild($$, $1);
		addChild($$, $2);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($2->getEndLine());

	}
	;
	
argument_list : arguments 
	{
		fprintf(logout,"argument_list : arguments \n");
		$$ = createNode("argument_list : arguments");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());

	}
	| {
		fprintf(logout,"argument_list : \n");
		$$ = createNode("argument_list : ");
	}
	;
	
arguments : arguments COMMA logic_expression 
	{
		fprintf(logout,"arguments : arguments COMMA logic_expression \n");
		$$ = createNode("arguments : arguments COMMA logic_expression");
		addChild($$, $1);
		addChild($$, $2);
		addChild($$, $3);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($3->getEndLine());
	}
	| logic_expression 
	{
		fprintf(logout,"arguments : logic_expression  \n");
		$$ = createNode("arguments : logic_expression");
		addChild($$, $1);
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
	}
	;
 

%%

void yyerror(char *s)
{
    fprintf(stderr,"error: %s\n",s);
}

int main(int argc,char *argv[])
{
    if((input=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}
    table=new SymbolTable(11);



    logout= fopen("log.txt","w");
	parseTree=fopen("parsetree.txt","w");
	errorFp=fopen("error.txt","w");
    yyin=input;
    yyparse();
	fprintf(logout,"Total Lines: %d",line_count);
	fclose(logout);
	fclose(errorFp);
    fclose(input);
   

    
    printf("\nParsing finished\n");
    return 0;
}