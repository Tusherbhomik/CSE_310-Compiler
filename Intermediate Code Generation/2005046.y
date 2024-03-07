%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<vector>
#include "SymbolInfo.h"
using namespace std;
string workWithCompoundStatement(SymbolInfo *root);
string workWithCompoundStatement(SymbolInfo *root);
string workWithStatements(SymbolInfo *root);
string workWithStatement(SymbolInfo *root);
string workWithExpression(SymbolInfo *root);
string workWithExpressionStatement(SymbolInfo *root);
string workWithLogicExpression(SymbolInfo *root);
string workWithDeclarationList(SymbolInfo *root);
string workWithVarDeclaration(SymbolInfo *root);
string workWithVariable(SymbolInfo *root);
string workWithRel(SymbolInfo *root);
int yyparse(void);
int yylex(void);

extern FILE *yyin;

FILE *logout,*input,*parseTree,*assembly;
SymbolTable *table;
int offsetCount=0;
int levelCount=0;

string newLineProc = "NEWLINE PROC\n\tPUSH AX\n\tPUSH DX\n\tMOV AH,2\n\tMOV DL,CR\n\tINT 21H\n\tMOV AH,2\n\tMOV DL,LF\n\tINT 21H\n\tPOP DX\n\tPOP AX\n\tRET\nNEWLINE ENDP\n";

string printOutputProc = "PRINTNUMBER PROC  ;PRINT WHAT IS IN AX\n\tPUSH AX\n\tPUSH BX\n\tPUSH CX\n\tPUSH DX\n\tPUSH SI\n\tLEA SI,NUMBER\n\tMOV BX,10\n\tADD SI,4\n\tCMP AX,0\n\tJNGE NEGATE\n\tPRINT:\n\tXOR DX,DX\n\tDIV BX\n\tMOV [SI],DL\n\tADD [SI],'0'\n\tDEC SI\n\tCMP AX,0\n\tJNE PRINT\n\tINC SI\n\tLEA DX,SI\n\tMOV AH,9\n\tINT 21H\n\tPOP SI\n\tPOP DX\n\tPOP CX\n\tPOP BX\n\tPOP AX\n\tRET\n\tNEGATE:\n\tPUSH AX\n\tMOV AH,2\n\tMOV DL,'-'\n\tINT 21H\n\tPOP AX\n\tNEG AX\n\tJMP PRINT\nPRINTNUMBER ENDP\n";

string opCode(string code){
	string opcode="";
	if(code=="<")opcode="JL";
	else if(code=="<=") opcode="JLE";
	else if(code==">") opcode="JG";
	else if(code==">=") opcode="JGE";
	else if(code=="!=") opcode="JNE";
	else if(code=="==") opcode="JE";	
	return opcode;
}

string header = ";-------\n;\n;-------\n.MODEL SMALL\n.STACK 1000H\n.DATA\n\tCR EQU 0DH\n\tLF EQU 0AH\n\tNUMBER DB \"00000$\"\n";

int createOffset(){
	return offsetCount+=2;
}
string type="";
vector<SymbolInfo*> variableList;

vector<SymbolInfo*> declaredButNotInserted;
vector<SymbolInfo*> funcDefVarList;
map<string,int> dummySymbolTable;
extern int line_count;
void printMap(const std::map<std::string, int>& symbolTable) {
    std::cout << "Symbol Table:\n";
    
    for (const auto& entry : symbolTable) {
        std::cout << entry.first << " : " << entry.second << '\n';
    }
}
SymbolInfo *createNode(string type, string value)
{
	SymbolInfo *node = new SymbolInfo(value, type);
	return node;
}

SymbolInfo *addChild(SymbolInfo *parent, SymbolInfo *child)
{
	parent->getChildren().push_back(child);
}
SymbolInfo *rootOfPareseTree;
void printParseTree(SymbolInfo *node, int depth)
{
	if (node == nullptr)
	{
		return;
	}
	for (int i = 0; i < depth; i++)
	{
		fprintf(parseTree, " ");
	} // indentation

	if (node->getType() == "rule")
	{
		// fprintf(parseTree,"Yes");
		fprintf(parseTree, "%s  ", node->getName().c_str());
	}
	else
	{
		fprintf(parseTree, "%s : %s    ", node->getType().c_str(), node->getName().c_str());
	}
	if (node->getType() != "rule")
	{
		fprintf(parseTree, "<Line: %d>\n", node->getStartLine());
	}
	else
	{
		fprintf(parseTree, "<Line: %d-%d>\n", node->getStartLine(), node->getEndLine());
	}
	for (SymbolInfo *child : node->getChildren())
	{
		printParseTree(child, depth + 1);
	}
}
void getUnits(SymbolInfo *root, vector<SymbolInfo *> &v)
{
	if (root->getName() == "program : unit")
	{
		v.push_back(root->getChildren()[0]);
	}
	else if (root->getName() == "program : program unit")
	{
		getUnits(root->getChildren()[0], v);
		v.push_back(root->getChildren()[1]);
	}
}
string analyzeList(SymbolInfo *root)
{
	vector<SymbolInfo *> children = root->getChildren();
	if (root->getName() == "declaration_list : declaration_list COMMA ID")
	{
		string temp = analyzeList(children[0]);
		return temp + '\t' + children[2]->getName() + " DW 1 DUP (0000H)\n";
	}
	if (root->getName() == "declaration_list : ID")
	{
		return '\t' + children[0]->getName() + " DW 1 DUP (0000H)\n";
	}
	if (root->getName() == "declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE")
	{
		string temp = analyzeList(children[0]);
		return temp + '\t' + children[2]->getName() + " DW " + children[4]->getName() + " DUP (0000H)\n";
	}
	if (root->getName() == "declaration_list : ID LSQUARE CONST_INT RSQUARE")
	{
		return '\t' + children[0]->getName() + " DW " + children[2]->getName() + " DUP (0000H)\n";
	}
	return "";
}
string declareVar(SymbolInfo *root)
{
	return analyzeList(root->getChildren()[1]);
}
string workWithVariable(SymbolInfo *root){
	if(root->getName()=="variable : ID"){
		return "";

	}else if(root->getName()=="variable : ID LSQUARE expression RSQUARE"){
		string s= workWithExpression(root->getChildren()[2]);
		s+="\tPUSH AX\n";
		return s;
	}
	
}

string workWithFactor(SymbolInfo *root){

	if(root->getName()=="factor : CONST_INT"){
		return "\tMOV AX, "+root->getChildren()[0]->getName()+"\n";
	}
	else if(root->getName()=="factor  : variable"){
		//SymbolInfo *temp=table->lookUp(root->getChildren()[0]->getChildren()[0]->getName());
		if(root->getChildren()[0]->getChildren()[0]->symbol->global){
			if(root->getChildren()[0]->getChildren().size()==1){
			return "\t MOV AX,"+root->getChildren()[0]->getChildren()[0]->getName()+"\n";
			}
			else{
				cout<<root->getChildren()[0]->getName()<<endl;
				// string temp1="";
				string temp1=workWithVariable(root->getChildren()[0]);
				//temp1+="\tPUSH DX\n";
				temp1+="\tPOP BX\n";
				temp1+="\tMOV AX,2\n";
				temp1+="\tMUL BX\n";
				temp1+="\tMOV BX,AX\n";
				//temp1+="\tPOP AX\n";
				temp1+="\tMOV AX,"+root->getChildren()[0]->getChildren()[0]->getName()+"[BX]\n";
				return  temp1;
			}
		}
		else{
			if(root->getChildren()[0]->getChildren().size()==1){
			return "\t MOV AX,[BP"+to_string(dummySymbolTable[root->getChildren()[0]->getChildren()[0]->getName()])+"]\n";
			}
			else{
				string temp1=workWithVariable(root->getChildren()[0]);
							temp1+="\tPOP BX\n";
							temp1+="\tPUSH AX\n";
							temp1+="\tMOV AX,2\n";
							temp1+="\tMUL BX\n";
							temp1+="\tPUSH AX\n";
							temp1+="\tMOV AX,BX\n";
							temp1+="\tMOV AX, -"+to_string(-1*dummySymbolTable[root->getChildren()[0]->getChildren()[0]->getName()])+"\n";
							temp1+="\tPOP BX\n";
							temp1+="\tADD AX, BX \n";
							temp1+="\tMOV BX,AX\n";
							temp1+="\tPOP AX\n";
							temp1+="\tMOV SI,BX\n";
							temp1+="\tMOV [BP+SI], AX\n";
							return temp1;
			}
		}
		
	}
	else if(root->getName()=="factor : variable INCOP"){
		string temp1="";
		if(root->getChildren()[0]->getChildren()[0]->symbol->global){
			temp1+= "\t MOV AX,"+root->getChildren()[0]->getChildren()[0]->getName()+"\n";
		}else{
			temp1+= "\t MOV AX,[BP"+to_string(dummySymbolTable[root->getChildren()[0]->getChildren()[0]->getName()])+"]\n";
		} 

		temp1+="\tINC AX\n";
		if(root->getChildren()[0]->getChildren()[0]->symbol->global){
			temp1+= "\t MOV "+root->getChildren()[0]->getChildren()[0]->getName()+",AX \n";
		}else{
			temp1+= "\t MOV [BP"+to_string(dummySymbolTable[root->getChildren()[0]->getChildren()[0]->getName()])+"],AX\n";
		} 
		return temp1;
	}
	else if(root->getName()=="factor : variable DECOP"){
		string temp1="";
		if(root->getChildren()[0]->getChildren()[0]->symbol->global){
			temp1+= "\t MOV AX,"+root->getChildren()[0]->getChildren()[0]->getName()+"\n";
		}else{
			temp1+= "\t MOV AX,[BP"+to_string(dummySymbolTable[root->getChildren()[0]->getChildren()[0]->getName()])+"]\n";
		} 

		temp1+="\tDEC AX\n";
		if(root->getChildren()[0]->getChildren()[0]->symbol->global){
			temp1+= "\t MOV "+root->getChildren()[0]->getChildren()[0]->getName()+",AX \n";
		}else{
			temp1+= "\t MOV [BP"+to_string(dummySymbolTable[root->getChildren()[0]->getChildren()[0]->getName()])+"],AX\n";
		} 
		return temp1;
	}

	else if(root->getName()=="factor : LPAREN expression RPAREN"){
		string temp=workWithExpression(root->getChildren()[1]);
		return temp;
	}

}
string workWithUnaryExpression(SymbolInfo *root){
	if(root->getName()=="unary_expression : factor"){
		return workWithFactor(root->getChildren()[0]);
	}

}
string workWithTerm(SymbolInfo * root){
	if(root->getName()=="term :  unary_expression"){
		return workWithUnaryExpression(root->getChildren()[0]);
	}
	else if(root->getName()=="term : term MULOP unary_expression"){
		string temp1=workWithUnaryExpression(root->getChildren()[2]);
		temp1+="\tPUSH AX\n";
		string temp2=workWithTerm(root->getChildren()[0]);
		temp2+="\tPOP CX\n";
		if(root->getChildren()[1]->getName()=="*"){
			temp2+="\tCWD\n";
			temp2+="\tMUL CX\n";
		}
		else if(root->getChildren()[1]->getName()=="/"){
			temp2+="\tCWD\n";
			temp2+="\tDIV CX\n\tMOV CX,AX\n";

		}
		else if(root->getChildren()[1]->getName()=="%"){
			temp2+="\tCWD\n";
			temp2+="\tDIV CX\n\tPUSH DX\n\tPOP AX\n";
		}
		return temp1+temp2;
	}
	else {
		return "";
	}

}
string workWithSimpleExpression(SymbolInfo *root){
	if(root->getName()=="simple_expression : term"){
		return workWithTerm(root->getChildren()[0]);
	}
	else if(root->getName()=="simple_expression : simple_expression ADDOP term"){
		string temp1=workWithTerm(root->getChildren()[2]);
		temp1+="\tPUSH AX\n";
		string temp2=workWithSimpleExpression(root->getChildren()[0]);
		if(root->getChildren()[1]->getName()=="+"){
			temp2+="\tPOP DX\n\tADD AX ,DX\n";
		}else {
			temp2+="\tPOP DX\n\tSUB AX ,DX\n";
		}
		return temp1+temp2;
	}
}
string workWithRel(SymbolInfo *root){
	if(root->getName()=="rel_expression  : simple_expression"){
		return workWithSimpleExpression(root->getChildren()[0]);
	}else if(root->getName()=="rel_expression  : simple_expression RELOP simple_expression"){

		if(root->isCond){
			string temp1=workWithSimpleExpression(root->getChildren()[2]);
			temp1+="\tPUSH AX\n";
			string temp2=workWithSimpleExpression(root->getChildren()[0]);
			temp2+="\tPOP DX\n";

			string op=opCode(root->getChildren()[1]->getName());
			temp2+="\tCMP AX,DX\n";
			//temp2+="\tCMP AX,DX\n";
			temp2+="\t"+op+" "+root->truelevel+"\n";
			temp2+="\tJMP "+root->falselevel+"\n";
			temp2+=root->truelevel+":\n";
			return temp1+temp2;
		}


	else{
		string levelone="L"+to_string(levelCount++);
		string levelzero="L"+to_string(levelCount++);
		
		string nextLevel="L"+to_string(levelCount++);
		root->nextlevel=nextLevel;
		//cout<<root->nextlevel<<endl;
		
		string temp1=workWithSimpleExpression(root->getChildren()[2]);
		temp1+="\tPUSH AX\n";
		string temp2=workWithSimpleExpression(root->getChildren()[0]);
			temp2+="\tPOP DX\n";
		string op=opCode(root->getChildren()[1]->getName());
		temp2+="\tCMP AX,DX\n";
		temp2+="\t"+op+" "+levelone+"\n";
		temp2+="\tJMP "+levelzero+"\n";
		temp2+=levelone+":\n"+"\tMOV AX,1\n\tJMP "+nextLevel+"\n";
		temp2+=levelzero+":\n"+"\tMOV AX,0\n"+nextLevel+":\n";
		return temp1+temp2;
	}
	}

}
string workWithLogicExpression(SymbolInfo *root){
	
	if(root->getName()=="logic_expression     : rel_expression"){
		root->getChildren()[0]->isCond=root->isCond;
		root->getChildren()[0]->truelevel=root->truelevel;
		root->getChildren()[0]->falselevel=root->falselevel;
		root->getChildren()[0]->nextlevel=root->nextlevel;
		return workWithRel(root->getChildren()[0]);
	}else if(root->getName()=="logic_expression : rel_expression LOGICOP rel_expression"){

	
		if(root->isCond){
			cout<<"yes i am in"<<endl;
		
			string temp1= workWithRel(root->getChildren()[0]);
			temp1+="\tCMP AX,0\n";

			if(root->getChildren()[1]->getName()=="||"){
			
			
			string temp2= workWithRel(root->getChildren()[2]);
			temp1+="\tJE "+root->truelevel+"\n";
			temp1+="\tJMP "+root->getChildren()[2]->nextlevel+"\n";
			temp1+=root->truelevel+":\n";
			string a="L"+to_string(levelCount++);
			temp1+="\tCMP AX, 0\n";
			temp1+="\tJNE "+a+"\n";
			temp1+="\tJMP "+root->falselevel+"\n";
			temp1+=a+":\n";

			return temp1+temp2;
			
			}
			if(root->getChildren()[1]->getName()=="&&"){

				string temp2= workWithRel(root->getChildren()[2]);
			temp1+="\tJNE "+root->truelevel+"\n";
			temp1+="\tJMP "+root->getChildren()[2]->nextlevel+"\n";
			temp1+=root->truelevel+":\n";
			string a="L"+to_string(levelCount++);
			string p="L"+to_string(levelCount++);
			temp1+="\tCMP AX, 0\n";
			temp1+="\tJNE "+a+"\n";
			temp1+="\tJMP "+root->falselevel+"\n";
			temp1+=a+":\n";
			temp2+="\tCMP AX,1\n";
			temp2+="\tJE "+p+"\n";
			temp2+="\tJMP "+root->falselevel+"\n";
			temp2+=p+":\n";

			
			
			return temp1+temp2;



			}


		}




	else{

		string trueLevel="L"+to_string(levelCount++);
		string falseLevel="L"+to_string(levelCount++);
		string levelOne="L"+to_string(levelCount++);
		string levelZero="L"+to_string(levelCount++);

		string temp1=workWithRel(root->getChildren()[0]);
		temp1+="\tCMP AX ,0\n";
		if(root->getChildren()[1]->getName()=="||"){
			temp1+="\tJNE "+levelOne+"\n";
			temp1+="\tJMP "+falseLevel+"\n";
			temp1+=levelOne+":\n\tMOV AX,1\n\tJMP "+trueLevel+"\n";
			temp1+=falseLevel+":\n";
			string temp2=workWithRel(root->getChildren()[2]);
			temp2+="\tCMP AX ,0\n";
			temp2+="\tJNE "+levelOne+"\n";
			temp2+="\tJMP "+levelZero+"\n";
			temp2+=levelZero+":\n\tMOV AX,0\n\tJMP "+trueLevel+"\n";
			temp2+=trueLevel+":\n";
			return temp1+temp2;
		}
		else if(root->getChildren()[1]->getName()=="&&")
		{
			temp1+="\tJE "+levelZero+"\n";
			temp1+="\tJMP "+trueLevel+"\n";
			temp1+=trueLevel+":\n";
			string temp2=workWithRel(root->getChildren()[2]);
			temp2+="\tCMP AX,0\n";
			temp2+="\tJE "+levelZero+"\n";
			temp2+="\tJMP "+levelOne+"\n";
			temp2+=levelOne+":\n";
			temp2+="\tMOV AX,1\n";
			temp2+="\tJMP "+falseLevel+"\n";
			temp2+=levelZero+":\n";
			temp2+="\tMOV AX,0\n";
			temp2+=falseLevel+":\n";
			return temp1+temp2;
		}
	}
		
	}else {
		return "";
	}
}
string workWithExpression(SymbolInfo *root){
	if(root->getName()=="expression : variable ASSIGNOP logic_expression"){
		string temp1=workWithLogicExpression(root->getChildren()[2]);
		temp1+="\tPUSH AX\n";
		// SymbolInfo *temp=table->lookUp(root->getChildren()[0]->getChildren()[0]->getName());
		// if(temp==nullptr)cout<<"NULL Paisi"<<endl;
		if(root->getChildren()[0]->getChildren()[0]->symbol->global){
				cout<<root->getChildren()[0]->getChildren().size()<<endl;
				if(root->getChildren()[0]->getChildren().size()==1){
						temp1+="\tPOP DX\n";
					temp1+="\tMOV "+root->getChildren()[0]->getChildren()[0]->getName()+" ,DX\n";
				}
				else{
					temp1+=workWithVariable(root->getChildren()[0]);
					temp1+="\tPOP BX\n";
					//temp1+="\tPUSH AX\n";
					temp1+="\tMOV AX,2\n";
					temp1+="\tMUL BX\n";
					temp1+="\tMOV BX,AX\n";
					temp1+="\tPOP AX\n";
					temp1+="\tMOV "+root->getChildren()[0]->getChildren()[0]->getName()+"[BX], AX\n";
				}
		}
		else{
			if(root->getChildren()[0]->getChildren().size()==1){
			temp1+="\tPOP DX\n";
			temp1+="\tMOV [BP-"+to_string(-1*dummySymbolTable[root->getChildren()[0]->getChildren()[0]->getName()])+"] ,DX\n";
			}
			else{
					temp1+="\tPOP BX\n";
					temp1+="\tPUSH AX\n";
					temp1+="\tMOV AX,2\n";
					temp1+="\tMUL BX\n";
					temp1+="\tPUSH AX\n";
					temp1+="\tMOV AX,BX\n";
					temp1+="\tMOV AX, -"+to_string(-1*dummySymbolTable[root->getChildren()[0]->getChildren()[0]->getName()])+"\n";
					temp1+="\tPOP BX\n";
					temp1+="\tADD AX, BX\n";
					temp1+="\tMOV BX,AX\n";
					temp1+="\tPOP AX\n";
					temp1+="\tMOV SI,BX\n";
					temp1+="\tMOV [BP+SI], AX\n";
			}
		}
		return temp1;
	}
	else if(root->getName()=="expression : logic_expression"){
		root->getChildren()[0]->isCond=root->isCond;
		root->getChildren()[0]->truelevel=root->truelevel;
		root->getChildren()[0]->falselevel=root->falselevel;
		root->getChildren()[0]->nextlevel=root->nextlevel;
		return workWithLogicExpression(root->getChildren()[0]);
	}else {
		return "";
	}
	
}
string workWithExpressionStatement(SymbolInfo *root){
	return workWithExpression(root->getChildren()[0]);
}
string workWithDeclarationList(SymbolInfo *root){
	if(root->getName()=="declaration_list : ID LSQUARE CONST_INT RSQUARE"){
		
		offsetCount=offsetCount-stoi(root->getChildren()[2]->getName());
		dummySymbolTable[root->getChildren()[0]->getName()]=offsetCount;
		return "\tSUB SP,"+ to_string(stoi(root->getChildren()[2]->getName())*2)+"\n";
	}
	else if(root->getName()=="declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD"){
		string temp=workWithDeclarationList(root->getChildren()[0]);
		offsetCount=offsetCount-stoi(root->getChildren()[4]->getName());
		
		dummySymbolTable[root->getChildren()[2]->getName()]=offsetCount;
		return temp+"\tSUB SP,"+ to_string(stoi(root->getChildren()[2]->getName())*2)+"\n";

	}
	else if(root->getName()=="declaration_list : ID"){

		offsetCount=offsetCount-2;
		dummySymbolTable[root->getChildren()[0]->getName()]=offsetCount;
		return "\tSUB SP,2\n";
	}
	else if(root->getName()=="declaration_list : declaration_list COMMA ID"){
		string temp= workWithDeclarationList(root->getChildren()[0]);
		offsetCount=offsetCount-2;

		dummySymbolTable[root->getChildren()[2]->getName()]=offsetCount;
		return temp+"\tSUB SP,2\n";
		// return "";
	}
	
	else {
		return "";
	}
	

	
}
string workWithVarDeclaration(SymbolInfo *root){
	return workWithDeclarationList(root->getChildren()[1]);
}
string workWithStatement(SymbolInfo *root){
	
	if(root->getName()=="statement :  var_declaration"){
		return workWithVarDeclaration(root->getChildren()[0]);

	}else if(root->getName()=="statement :  expression_statement"){
		return workWithExpressionStatement(root->getChildren()[0]);
	}else if(root->getName()=="statement : compound_statement"){
		return workWithCompoundStatement(root->getChildren()[0]);
	}else if(root->getName()=="statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement"){
		string s="L"+to_string(levelCount++);
		string mainlevel="L"+to_string(levelCount++);

		string temp1=workWithExpressionStatement(root->getChildren()[2]);
		temp1+=s+":\n";
		string temp2=workWithExpressionStatement(root->getChildren()[3]);
			string s2="L"+to_string(levelCount++);
		temp2+=s2+":\n";
		temp2+="\tCMP AX,0\n";
		temp2+="\tJE "+mainlevel+"\n";

		//temp2+=root->getChildren()[3]->truelevel+"yes:\n";
		string temp3=workWithStatement(root->getChildren()[6]);
	
		string temp4=workWithExpression(root->getChildren()[4]);
		temp4+="\tJMP "+s+"\n";
		temp4+=mainlevel+":\n";

		return temp1+temp2+temp3+temp4;

		
	}else if(root->getName()=="statement : IF LPAREN expression RPAREN statement"){
		string truelevel="L"+to_string(levelCount++);
		string falselevel=root->nextlevel;
		root->getChildren()[2]->isCond=true;
		root->getChildren()[2]->truelevel=truelevel;
		root->getChildren()[2]->falselevel=falselevel;
		root->getChildren()[2]->nextlevel=truelevel;
		string temp=workWithExpression(root->getChildren()[2]);

		string temp2=workWithStatement(root->getChildren()[4]);
		temp2+=root->nextlevel+":\n";
		return temp+temp2;

	}else if(root->getName()=="statement : IF LPAREN expression RPAREN statement ELSE statement"){
		cout<<root->getName()<<endl;

		string truelevel="L"+to_string(levelCount++);
		string falselevel=root->nextlevel;
		root->getChildren()[2]->isCond=true;
		root->getChildren()[2]->truelevel=truelevel;
		root->getChildren()[2]->falselevel=falselevel;
		root->getChildren()[2]->nextlevel=truelevel;
		string temp=workWithExpression(root->getChildren()[2]);
		root->getChildren()[4]->nextlevel=truelevel;
		string temp2=workWithStatement(root->getChildren()[4]);
		string newLevel="L"+to_string(levelCount++);
		temp2+="\tJMP "+newLevel+"\n";
		temp2+=root->nextlevel+":\n";
		root->getChildren()[2]->nextlevel=newLevel;
		string temp3=workWithStatement(root->getChildren()[6]);
		temp3+=newLevel+":\n";
		return temp+temp2+temp3;	
	}
	else if(root->getName()=="statement : WHILE LPAREN expression RPAREN statement"){
		string k="L"+to_string(levelCount++);
		string s2="L"+to_string(levelCount++);
		string mainlevel="L"+to_string(levelCount++);
		string s=k+":\n";
		s+=workWithExpression(root->getChildren()[2]);
		s+=s2+":\n";
		s+="\tCMP AX,0\n";
		s+="\tJE "+mainlevel+"\n";
		string p=workWithStatement(root->getChildren()[4]);
		p+="\tJMP "+k+"\n";
		p+=mainlevel+":\n";
		return s+p;
	}
	else if(root->getName()=="statement : PRINTLN LPAREN ID RPAREN SEMICOLON"){
		if(root->getChildren()[2]->symbol->global){
			return "\t MOV AX,"+root->getChildren()[2]->getName()+"\n"+"\tCALL PRINTNUMBER\n\tCALL NEWLINE\n";
		}else{
			return "\t MOV AX,[BP"+to_string(dummySymbolTable[root->getChildren()[2]->getName()])+"]\n"+"\tCALL PRINTNUMBER\n\tCALL NEWLINE\n";
		}
	}
	else if(root->getName()=="statement : RETURN expression SEMICOLON"){
		return workWithExpression(root->getChildren()[1]);
	}
	else {
		return "";
	}
}
string workWithStatements(SymbolInfo *root){
	
	if(root->getName()=="statements : statements statement"){
		string nextLevel1="L"+to_string(levelCount++);
		string nextLevel2="L"+to_string(levelCount++);
		root->getChildren()[0]->nextlevel=nextLevel1;
		string temp1=workWithStatements(root->getChildren()[0]);
		root->getChildren()[1]->nextlevel=nextLevel2;
		string temp2=workWithStatement(root->getChildren()[1]);
		return temp1+temp2;
	}else{
		string nextLevel="L"+to_string(levelCount++);
		root->getChildren()[0]->nextlevel=nextLevel;


		return workWithStatement(root->getChildren()[0]);
	}
}
string workWithCompoundStatement(SymbolInfo *root){
	return workWithStatements(root->getChildren()[1]);
}

string workWithFuncDefinition(SymbolInfo * root){

	if(root->getName()=="func_definition : type_specifier ID LPAREN RPAREN compound_statement"){
		return workWithCompoundStatement(root->getChildren()[4]);
	}else if(root->getName()=="func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement"){
		return workWithCompoundStatement(root->getChildren()[5]);
	}else{
		return "";
	}
	
}
string traverseParseTree(SymbolInfo *root)
{
	bool codePrinted=false;
	string result = "";
	vector<SymbolInfo *> v;
	getUnits(root, v);	//saved in the v
	for (auto x : v)
	{
		if (x->getName() == "unit : var_declaration")
		{	
			result += declareVar(x->getChildren()[0]);
		}
	}
	result+=".CODE\n";
	//for func definition
	for (auto x : v)
	{
		if(x->getName()=="unit : func_definition"){
			result+=x->getChildren()[0]->getChildren()[1]->getName()+" PROC\n";
			if(x->getChildren()[0]->getChildren()[1]->getName()=="main"){
				result+="\tMOV AX, @DATA\n"
				"\tMOV DS, AX\n";
			}
			result+="\tPUSH BP\n\tMOV BP, SP\n";
			result+=workWithFuncDefinition(x->getChildren()[0]);
			//DO STUFF
			//result+="\tMara Kha\n";
			result+="\tPOP BP\n\tMOV AX,4CH\n\tINT 21H\n";
			result+=x->getChildren()[0]->getChildren()[1]->getName()+" ENDP\n";
			result+=newLineProc+printOutputProc;
		}
	}
	return result;
}
void workWithAssembly()
{
	fprintf(assembly, ".MODEL SMALL\n.STACK 1000H\n.Data\n\tCR EQU 0DH\n\tLF EQU 0AH\n\tnumber DB \"00000$\"\n");
	fprintf(assembly, "%s", traverseParseTree(rootOfPareseTree->getChildren()[0]).c_str());
}
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
    $$ = createNode("rule","start: program");
    rootOfPareseTree=$$;
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
    addChild($$, $1);
	table->printAllScopeTable();
    printParseTree($$, 0);
    workWithAssembly();
}
;

program : program unit 
{
    fprintf(logout,"program : program unit  \n");
    $$ = createNode("rule","program : program unit");
    addChild($$, $1);
    addChild($$, $2);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($2->getEndLine());

}
  | unit // 
{
    fprintf(logout,"program : unit  \n");
    $$ = createNode("rule","program : unit");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
}
;
unit : var_declaration
{
    fprintf(logout,"unit : var_declaration  \n");
    $$ = createNode("rule","unit : var_declaration");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
}
    | func_declaration 
{
    fprintf(logout,"unit : func_declaration \n");
    $$ = createNode("rule","unit : func_declaration");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
}
    | func_definition  
{
    fprintf(logout,"unit : func_definition  \n");
    $$ = createNode("rule","unit : func_definition");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
}
    ;
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON 
{
    fprintf(logout,"func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n");
    $$ = createNode("rule","func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON");
    addChild($$, $1);
    addChild($$, $2);
    addChild($$, $3);
    addChild($$, $4);
    addChild($$, $5);
    addChild($$, $6);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($6->getEndLine());

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
    $$ = createNode("rule","func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON");
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
func_definition : 
type_specifier ID LPAREN parameter_list RPAREN compound_statement
{
    fprintf(logout,"func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement \n");
    $$ = createNode("rule","func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement");
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
    table->insert(s);//function name inserted in the symbol table
    for(int i=0;i<variableList.size();i++)
    {
		s->addParam(variableList[i]);
    }
    variableList.clear();
	}
  | type_specifier ID LPAREN RPAREN compound_statement // no arguments in the function 
{
    fprintf(logout,"func_definition : type_specifier ID LPAREN RPAREN compound_statement \n");
    $$ = createNode("rule","func_definition : type_specifier ID LPAREN RPAREN compound_statement");
    addChild($$, $1);
    addChild($$, $2);
    addChild($$, $3);
    addChild($$, $4);
    addChild($$, $5);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($5->getEndLine());

    SymbolInfo *s=new SymbolInfo($2->getName(),$1->getType());//function name
    s->setIsFunc();
    s->setDefine();
    table->insert(s);
    // for(int i=0;i<variableList.size();i++)
    // {
    //   s->addParam(variableList[i]);
    //   cout<<"length"<<variableList.size()<<endl;
    // }
    variableList.clear();
};        


parameter_list  : parameter_list COMMA type_specifier ID 
{
    fprintf(logout,"parameter_list  : parameter_list COMMA type_specifier ID \n");
    $$ = createNode("rule","parameter_list  : parameter_list COMMA type_specifier ID");
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
    $$ = createNode("rule","parameter_list  : parameter_list COMMA type_specifier");
    addChild($$, $1);
    addChild($$, $2);
    addChild($$, $3);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($3->getEndLine());
    
}
| type_specifier ID 
{
    fprintf(logout,"parameter_list  : type_specifier ID \n");
    $$ = createNode("rule","parameter_list  : type_specifier ID");
    addChild($$, $1);
    addChild($$, $2);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($2->getEndLine());
    variableList.push_back($2);
	}
	| type_specifier
	{
    fprintf(logout,"parameter_list  : type_specifier  \n");
    $$ = createNode("rule","parameter_list  : type_specifier");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
	};

compound_statement : LCURL{table->enterScope();} statements RCURL 
{
    fprintf(logout,"compound_statement : LCURL statements RCURL \n");
    $$ = createNode("rule","compound_statement : LCURL statements RCURL");
    addChild($$, $1);
    addChild($$, $3);
    addChild($$, $4);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($4->getEndLine());
    table->printAllScopeTable();
    table->exitScope();
}
| LCURL{table->enterScope();} RCURL 
{
    fprintf(logout,"compound_statement : LCURL RCURL \n");
    $$ = createNode("rule","compound_statement : LCURL RCURL");
    addChild($$, $1);
    addChild($$, $3);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($3->getEndLine());
    table->printAllScopeTable();
    table->exitScope();
};
var_declaration : type_specifier declaration_list SEMICOLON
{
    fprintf(logout,"var_declaration : type_specifier declaration_list SEMICOLON  \n");
    $$ = createNode("rule","var_declaration : type_specifier declaration_list SEMICOLON");
    addChild($$, $1);
    addChild($$, $2);
    addChild($$, $3);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($3->getEndLine());
};
type_specifier  :INT 
{
    fprintf(logout,"type_specifier  : INT \n");
        $$= createNode("rule","type_specifier  : INT");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
}
| FLOAT 
{
    fprintf(logout,"type_specifier  : FLOAT \n");
    $$ = createNode("rule","type_specifier  : FLOAT");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
}
| VOID 
{
    fprintf(logout,"type_specifier  : VOID\n");
    $$ = createNode("rule","type_specifier  : VOID");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
};
declaration_list : declaration_list COMMA ID  
{
    fprintf(logout,"declaration_list : declaration_list COMMA ID  \n");
    $$ = createNode("rule","declaration_list : declaration_list COMMA ID");
    addChild($$, $1);
    addChild($$, $2);
    addChild($$, $3);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($3->getEndLine());

    SymbolInfo* symbolInfoPtr = table->lookUp($1->getName());
    if(symbolInfoPtr==nullptr){
		if(table->getId()==1){
			$3->global=true;
			cout<<"Mara Khacche "<<endl;
		}
		
		table->insert($3);
		
    }//changed

}
| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD 
{
    fprintf(logout,"declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE \n");
    $$ = createNode("rule","declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE");
    addChild($$, $1);
    addChild($$, $2);
    addChild($$, $3);
    addChild($$, $4);
    addChild($$, $5);
    addChild($$, $6);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($6->getEndLine());

    SymbolInfo* symbolInfoPtr = table->lookUp($3->getName());
    if(symbolInfoPtr==nullptr){
		if(table->getId()==1){
			$3->global=true;
			
		}
		$1->arraySize=stoi($3->getName());
		$1->isArray=true;
    table->insert($3);
	
    }//changed
}
| ID
{
	
    fprintf(logout,"declaration_list : ID \n");
        $$ = createNode("rule","declaration_list : ID");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
	
    SymbolInfo* symbolInfoPtr = table->lookUp($1->getName());
    if(symbolInfoPtr==nullptr){
		if(table->getId()==1){
			$1->global=true;
			cout<<"Mara Khacche "<<endl;
		}
		
		table->insert($1);
		
    }//changed
}
| ID LTHIRD CONST_INT RTHIRD
{
    fprintf(logout,"declaration_list : ID LSQUARE CONST_INT RSQUARE \n");
    $$ = createNode("rule","declaration_list : ID LSQUARE CONST_INT RSQUARE");
    addChild($$, $1);
    addChild($$, $2);
    addChild($$, $3);
    addChild($$, $4);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($4->getEndLine());


    SymbolInfo* symbolInfoPtr = table->lookUp($1->getName());
    if(symbolInfoPtr==nullptr){
		if(table->getId()==1){
			$1->global=true;

		}
		$1->arraySize=stoi($3->getName());
		$1->isArray=true;
    table->insert($1);
    }//changed
	
	};
statements : statement 
				{
					fprintf(logout,"statements : statement  \n");
					$$ = createNode("rule","statements : statement");
					addChild($$, $1);
					$$->setStartLine($1->getStartLine());
					$$->setEndLine($1->getEndLine());
				}
				| statements statement 
				{
					fprintf(logout,"statements : statements statement \n");
					$$ = createNode("rule","statements : statements statement");
					addChild($$, $1);
					addChild($$, $2);
					$$->setStartLine($1->getStartLine());
					$$->setEndLine($2->getEndLine());
				};
statement : var_declaration 
				{
					fprintf(logout,"statement :  var_declaration \n");
					$$ = createNode("rule","statement :  var_declaration");
					addChild($$, $1);
					$$->setStartLine($1->getStartLine());
					$$->setEndLine($1->getEndLine());
				}
				| expression_statement 
				{
					fprintf(logout,"statement :  expression_statement \n");
					$$ = createNode("rule","statement :  expression_statement");
					addChild($$, $1);
					$$->setStartLine($1->getStartLine());
					$$->setEndLine($1->getEndLine());
				}
				| compound_statement 
				{
					fprintf(logout,"statement : compound_statement \n");
					$$ = createNode("rule","statement : compound_statement");
					addChild($$, $1);
					$$->setStartLine($1->getStartLine());
					$$->setEndLine($1->getEndLine());
				}
				| FOR LPAREN expression_statement expression_statement expression RPAREN statement 
				{
					fprintf(logout,"statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement \n");
					$$ = createNode("rule","statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement");
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
					fprintf(logout,"statement : IF LPAREN expression RPAREN statement \n");$$ = createNode("rule","statement : IF LPAREN expression RPAREN statement");
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
					$$ = createNode("rule","statement : IF LPAREN expression RPAREN statement ELSE statement");
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
					$$ = createNode("rule","statement : WHILE LPAREN expression RPAREN statement");
					addChild($$, $1);
					addChild($$, $2);
					addChild($$, $3);
					addChild($$, $4);
					addChild($$, $5);
					$$->setStartLine($1->getStartLine());
					$$->setEndLine($5->getEndLine());
					}
				| PRINTLN LPAREN ID RPAREN SEMICOLON 
				{//Id niye kaj kora lagbe
					fprintf(logout,"statement : PRINTLN LPAREN ID RPAREN SEMICOLON \n");
					$$ = createNode("rule","statement : PRINTLN LPAREN ID RPAREN SEMICOLON");addChild($$, $1);
					addChild($$, $2);
					addChild($$, $3);
					addChild($$, $4);
					addChild($$, $5);
					$$->setStartLine($1->getStartLine());
					$$->setEndLine($5->getEndLine());
					SymbolInfo *temp=table->lookUp($3->getName());
					$3->symbol=temp;
				}
				| RETURN expression SEMICOLON 
				{
					fprintf(logout,"statement : RETURN expression SEMICOLON \n");
					$$ = createNode("rule","statement : RETURN expression SEMICOLON");
					addChild($$, $1);
					addChild($$, $2);
					addChild($$, $3);
					$$->setStartLine($1->getStartLine());
					$$->setEndLine($3->getEndLine());
				};
				expression_statement   : SEMICOLON   
				{
					fprintf(logout,"expression_statement :SEMICOLON \n");
					$$ = createNode("rule","expression_statement :SEMICOLON");
					addChild($$, $1);
					$$->setStartLine($1->getStartLine());
					$$->setEndLine($1->getEndLine());
				}  
				| expression SEMICOLON  
				{
					fprintf(logout,"expression_statement :expression SEMICOLON \n");
					$$ = createNode("rule","expression_statement :expression SEMICOLON");
					addChild($$, $1);
					addChild($$, $2);
					$$->setStartLine($1->getStartLine());
					$$->setEndLine($2->getEndLine());
				};
variable : ID      
{
    // if(table->lookUp($1)==NULL){
    //   table->insert($1);
    // }//changed
    fprintf(logout,"variable : ID  \n");
    $$ = createNode("rule","variable : ID");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
	SymbolInfo *symbol=table->lookUp($1->getName());
	$1->symbol=symbol;

}
| ID LTHIRD expression RTHIRD  
{
    // if(table->lookUp($1)==NULL){
    //   table->insert($1);
    // }//changed

    fprintf(logout,"variable : ID LSQUARE expression RSQUARE \n");
    $$ = createNode("rule","variable : ID LSQUARE expression RSQUARE");
    addChild($$, $1);
    addChild($$, $2);
    addChild($$, $3);
    addChild($$, $4);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($4->getEndLine());
	SymbolInfo *symbol=table->lookUp($1->getName());
	$1->symbol=symbol;
};

expression : 
logic_expression   
{
    fprintf(logout,"expression : logic_expression \n");
    $$ = createNode("rule","expression : logic_expression");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
}
| variable ASSIGNOP logic_expression   
{
    fprintf(logout,"expression : variable ASSIGNOP logic_expression \n");
    $$ = createNode("rule","expression : variable ASSIGNOP logic_expression");
    addChild($$, $1);
    addChild($$, $2);
    addChild($$, $3);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($3->getEndLine());
};
logic_expression : rel_expression    
{
    fprintf(logout,"logic_expression : rel_expression     \n");
    $$ = createNode("rule","logic_expression     : rel_expression");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
}
| rel_expression LOGICOP rel_expression   
{
    fprintf(logout,"logic_expression : rel_expression LOGICOP rel_expression \n");
    $$ = createNode("rule","logic_expression : rel_expression LOGICOP rel_expression");
    addChild($$, $1);
    addChild($$, $2);
    addChild($$, $3);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($3->getEndLine());
};
rel_expression  : simple_expression  
{
    fprintf(logout,"rel_expression  : simple_expression \n");
    $$ = createNode("rule","rel_expression  : simple_expression");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
}
| simple_expression RELOP simple_expression   
{
    fprintf(logout,"rel_expression  : simple_expression RELOP simple_expression \n");
    $$ = createNode("rule","rel_expression  : simple_expression RELOP simple_expression");
    addChild($$, $1);
    addChild($$, $2);
    addChild($$, $3);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($3->getEndLine());
};

simple_expression : term  
{
    fprintf(logout,"simple_expression : term  \n");
    $$ = createNode("rule","simple_expression : term");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
}
| simple_expression ADDOP term  
{
    fprintf(logout,"simple_expression : simple_expression ADDOP term  \n");
    $$ = createNode("rule","simple_expression : simple_expression ADDOP term");
    addChild($$, $1);
    addChild($$, $2);
    addChild($$, $3);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($3->getEndLine());
};
term :  unary_expression 
{
    fprintf(logout,"term :  unary_expression \n");
    $$ = createNode("rule","term :  unary_expression");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
}

    |  term MULOP unary_expression {
    fprintf(logout,"term : term MULOP unary_expression \n");
    $$ = createNode("rule","term : term MULOP unary_expression");
    addChild($$, $1);
    addChild($$, $2);
    addChild($$, $3);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($3->getEndLine());}
    ;

unary_expression : ADDOP unary_expression  
{   
    fprintf(logout,"unary_expression : ADDOP unary_expression \n");
    $$ = createNode("rule","unary_expression : ADDOP unary_expression");
    addChild($$, $1);
    addChild($$, $2);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($2->getEndLine());
}
| NOT unary_expression  
{
    fprintf(logout,"unary_expression : NOT unary_expression \n");
    $$ = createNode("rule","unary_expression : NOT unary_expression");
    addChild($$, $1);
    addChild($$, $2);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($2->getEndLine());
}
| factor 
{
    fprintf(logout,"unary_expression : factor \n");
    $$ = createNode("rule","unary_expression : factor");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
};
factor  : variable 
{
    fprintf(logout,"factor  : variable \n");
    $$ = createNode("rule","factor  : variable");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
}
| ID LPAREN argument_list RPAREN 
{
    fprintf(logout,"factor  : ID LPAREN argument_list RPAREN \n");
    $$ = createNode("rule","factor  : ID LPAREN argument_list RPAREN");
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
    $$ = createNode("rule","factor : LPAREN expression RPAREN");
    addChild($$, $1);
    addChild($$, $2);
    addChild($$, $3);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($3->getEndLine());
}
| CONST_INT 
{
    fprintf(logout,"factor : CONST_INT \n");
    $$ = createNode("rule","factor : CONST_INT");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());

}
| CONST_FLOAT 
{
    fprintf(logout,"factor : CONST_FLOAT \n");
    $$ = createNode("rule","factor : CONST_FLOAT");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());

}
| variable INCOP  
{
    fprintf(logout,"factor : variable INCOP \n");
    $$ = createNode("rule","factor : variable INCOP");
    addChild($$, $1);
    addChild($$, $2);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($2->getEndLine());

}
| variable DECOP 
{
    fprintf(logout,"factor : variable DECOP \n");
    $$ = createNode("rule","factor : variable DECOP");
    addChild($$, $1);
    addChild($$, $2);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($2->getEndLine());
};
argument_list : arguments 
{
    fprintf(logout,"argument_list : arguments \n");
    $$ = createNode("rule","argument_list : arguments");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
}
| {
    fprintf(logout,"argument_list : \n");
    $$ = createNode("rule","argument_list : ");
};

arguments : arguments COMMA logic_expression 
{
    fprintf(logout,"arguments : arguments COMMA logic_expression \n");
    $$ = createNode("rule","arguments : arguments COMMA logic_expression");
    addChild($$, $1);
    addChild($$, $2);
    addChild($$, $3);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($3->getEndLine());
}
| logic_expression 
{
    fprintf(logout,"arguments : logic_expression  \n");
    $$ = createNode("rule","arguments : logic_expression");
    addChild($$, $1);
    $$->setStartLine($1->getStartLine());
    $$->setEndLine($1->getEndLine());
	};
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
    logout= fopen(argv[2],"w");
	parseTree=fopen(argv[3],"w");
	assembly=fopen(argv[4],"w");
	
    yyin=input;
    yyparse();

	fprintf(logout,"Total Lines: %d",line_count);
	fclose(logout);
	fclose(parseTree);
    fclose(input);
    printf("\nParsing finished\n");
    return 0;
}
