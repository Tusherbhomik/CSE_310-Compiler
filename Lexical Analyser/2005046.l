%option noyywrap
%x STRING_STATE
%x SINGLE_LINE_COMMENT_STATE
%x MULTI_LINE_COMMENT_STATE

%{
#include<bits/stdc++.h>
using namespace std;
FILE *logout;
FILE *tokenout;
int line_count=1;
int tempLine=0;
int errorCnt=0;
int warningCnt=0;

#define ull unsigned long long
unsigned long long sdbm(string str)
{
    unsigned long long hash = 0;
    for (unsigned long long i = 0; i < str.length(); i++)
    {
        hash = str[i] + (hash << 6) + (hash << 16) - hash;
    }
    return hash;
}
class SymbolInfo
{
private:
    string name;
    string type;
    SymbolInfo *next;

public:
    SymbolInfo(string name, string type)
    {
        this->name = name;
        this->type = type;
        next = nullptr;
    }
    void setNext(SymbolInfo *next)
    {
        this->next = next;
    }
    SymbolInfo *getNext()
    {
        return next;
    }
    string getName()
    {
        return name;
    }
    void setName(string name)
    {
        this->name = name;
    }
    string getType()
    {
        return type;
    }
    void setType(string type)
    {
        this->type = type;
    }
    ~SymbolInfo() {}
};

class ScopeTable
{
private:
    SymbolInfo **symbolInfos;
    ScopeTable *parentScope;
    ull bucketSize;
    ull id;
    string scopeId;
    ofstream outputFile;

public:
    ScopeTable(ull n, ScopeTable *parentScope)
    {
        this->id = 0;
        bucketSize = n;
        this->parentScope = parentScope;
        symbolInfos = new SymbolInfo *[bucketSize];
        

        for (ull i = 0; i < bucketSize; i++)
        {
            symbolInfos[i] = nullptr;
        }

        stringstream ss;

        if (parentScope == nullptr)
        {
            scopeId = "1";
            //ss << "\tScopeTable# " << scopeId << " created" << endl;
        }
        else
        {
            parentScope->id++;
            ss<<parentScope->scopeId<<"."<<parentScope->id;
            scopeId = ss.str();
            ss.str("");//clear the stringsteam for reuse
            //ss << "\tScopeTable# " << scopeId << " created" << endl;
        }
		//fprintf(logout,"%s",scopeId.c_str());
        //cout<<ss.str();
    }
    ~ScopeTable()
    {
        for (ull i = 0; i < bucketSize; i++)
        {
            SymbolInfo *temp = symbolInfos[i];
            while (temp != nullptr)
            {
                SymbolInfo *tempInfo = temp->getNext();
                delete temp;
                temp = tempInfo;
            }
        }
        //cout << "\tScopeTable# " << scopeId << " deleted" << endl;
        delete[] symbolInfos;
    }
    ScopeTable *getParentScope()
    {
        return this->parentScope;
    }
    void setParentScope(ScopeTable *parentScope)
    {
        this->parentScope = parentScope;
    }
    void setId(string id)
    {
        this->scopeId = id;
    }
    string getId()
    {
        return scopeId;
    }

    
    void printCurrentScopeTable()
    {
        //stringstream output;
		
		fprintf(logout, "\tScopeTable# %s\n", scopeId.c_str());
        //output << "\tScopeTable# " << scopeId << endl;
        for (ull i = 0; i < bucketSize; i++)
        {
            //output << "\t" << i + 1;
			fprintf(logout, "\t%llu", i + 1);
            SymbolInfo *symbol = symbolInfos[i];
            while (symbol != nullptr)
            {
                //output << " --> (";
				fprintf(logout," --> (");
                //output << symbol->getName() << "," << symbol->getType();
				fprintf(logout, "%s,%s", symbol->getName().c_str(), symbol->getType().c_str());
                symbol = symbol->getNext();
                // output << ")";
				fprintf(logout,")");
            }
            // output << endl;
			fprintf(logout,"\n");
        }
        // cout<<output.str();
    }
    bool insert(string name, string type)
    {

        ull hashValue = sdbm(name) % bucketSize;

        if (symbolInfos[hashValue] == nullptr)
        {
            symbolInfos[hashValue] = new SymbolInfo(name, type);
            //cout << "\tInserted  at position <" << hashValue + 1 << ", 1> of ScopeTable# " << scopeId << endl;
            return true;
        }

        SymbolInfo *currentInfo = symbolInfos[hashValue];
        SymbolInfo *previousInfo = nullptr;
        ull count = 0;

        while (currentInfo != nullptr)
        {
            if (currentInfo->getName() == name)
            {
                //'<=' already exists in the current ScopeTable# 1.1
                // cout << "\t'" << name << "'"
                    //  << " already exists in the current ScopeTable# " << scopeId << endl;
					fprintf(logout, "\t%s already exists in the current ScopeTable\n", name.c_str());
                return false;
            }
            count++;
            previousInfo = currentInfo;
            currentInfo = currentInfo->getNext();
        }
        SymbolInfo *s = new SymbolInfo(name, type);
        previousInfo->setNext(s);
        //cout << "\tInserted  at position <" << hashValue + 1 << ", " << count + 1
        //     << "> of ScopeTable# " << scopeId << endl;
        return true;
    }
    SymbolInfo *lookUp(string name)
    {
        ull hashValue = sdbm(name) % bucketSize;
        SymbolInfo *s = symbolInfos[hashValue];
        ull count = 0;

        while (s != nullptr && s->getName() != name)
        {
            count++;
            s = s->getNext();
        }
        if (s != nullptr)
        {
            //'i' found at position <1, 1> of ScopeTable# 1
            //cout << "\t'" << name << "'"
            //     << " found at position <" << hashValue + 1 << ", " << count + 1 << "> of ScopeTable# " << scopeId << endl;
        }
        return s;
    }
    bool deleteFromScopeTable(string str)
    {
        ull hashValue = sdbm(str) % bucketSize;
        SymbolInfo *currentInfo = symbolInfos[hashValue];
        SymbolInfo *previousInfo = nullptr;
        ull count = 0;

        while (currentInfo != nullptr && currentInfo->getName() != str)
        {
            count++;
            previousInfo = currentInfo;
            currentInfo = currentInfo->getNext();
        }
        if (currentInfo != nullptr)
        {
            {
                //cout << "\tDeleted '" << str << "' "
                //      << "from position "
                //     << "<" << hashValue + 1 << ", " << count + 1 << "> of ScopeTable# " << scopeId << endl;
            }

            if (previousInfo == nullptr)
            {
                symbolInfos[hashValue] = currentInfo->getNext();
            }
            else
            {
                previousInfo->setNext(currentInfo->getNext());
            }

            delete currentInfo;
            return true;
        }
        // Not found in the current ScopeTable# 1
        //cout << "\tNot found in the current ScopeTable# " << scopeId << endl;
        return false;
    }
};

class SymbolTable
{
private:
    ull n;
    ScopeTable *currentScope;
    

public:
    SymbolTable(ull n)
    {
        this->n = n;
       
        currentScope = new ScopeTable(n, nullptr);
    }

    ~SymbolTable()
    {
        ScopeTable *temp = currentScope;
        while (temp != nullptr)
        {
            currentScope = currentScope->getParentScope();
            delete temp;
            temp = currentScope;
        }
    }

    void enterScope()
    {
        currentScope = new ScopeTable(n, currentScope);
    }
    void exitScope()
    {

        if (currentScope->getId() == "1")
        {
            //cout << "\tScopeTable# 1 cannot be deleted" << endl;
        }
        else
        {
            ScopeTable *temp = currentScope;
            currentScope = currentScope->getParentScope();
            delete temp;
        }
    }
    bool insert(string name, string type)
    {
        if (currentScope == nullptr)
        {
            currentScope = new ScopeTable(n, nullptr);
        }
        return currentScope->insert(name, type);
    }
    bool remove(string str)
    {
        if (currentScope == nullptr)
        {
            return false;
        }
        return currentScope->deleteFromScopeTable(str);
    }
    SymbolInfo *lookUp(string str)
    {
        if (currentScope == nullptr)
        {
            return nullptr;
        }

        SymbolInfo *symbolInfo = currentScope->lookUp(str);
        if (symbolInfo != nullptr)
        {
            return symbolInfo;
        }

        ScopeTable *parentScope = currentScope->getParentScope();

        while (parentScope != nullptr)
        {
            symbolInfo = parentScope->lookUp(str);
            if (symbolInfo != nullptr)
            {
                return symbolInfo;
            }
            parentScope = parentScope->getParentScope();
        }

        cout << "\t'" << str << "' not found in any of the ScopeTables" << endl;
        return nullptr;
    }
    void printCurrentScopeTable()
    {
        if (currentScope != nullptr)
            currentScope->printCurrentScopeTable();
    }
    void printAllScopeTable()
    {
        ScopeTable *temp = currentScope;
        while (temp != nullptr)
        {
            temp->printCurrentScopeTable();
            temp = temp->getParentScope();
        }
    }
};

string comment,tokenStr,logStr,lexemeType,logComment,commentLexemeType;
SymbolTable symboltable(10);

	const char* capitalize(const char* a) {
    size_t length = strlen(a);
    char* capitalized = new char[length + 1];

    for (size_t i = 0; i < length; ++i) {
        capitalized[i] = std::toupper(a[i]); 
    }
    capitalized[length] = '\0'; 
    return capitalized; 
	}
	void printInToken(const char  *a,const char *b)
	{
		fprintf(tokenout,"<%s, %s>\n",a,b);
	}
	void printInLog(const char  *a,const char *b)
	{
		fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,a,b);
	}
	void keyWordPrint(const char  *a)
	{
		printInToken(capitalize(a),a);
		printInLog(capitalize(a),a);
	}
	void actionForOperator(const char  *a,const char *b)
	{	
		printInToken(a,b);
		printInLog(a,b);
		if(*b=='{'){
		symboltable.enterScope();
		//cout<<"Hae hoise "<<endl;
		}
		else if(*b=='}')
		{symboltable.exitScope();
		
		}
		

	}
	void actionForIdentifier(const char *a)
	{
		printInToken("ID",a);
		printInLog("ID",a);
		if(symboltable.insert(a,"ID"))
		{
			symboltable.printAllScopeTable();
		}
	}


%}

WHITESPACE [ \t\f\r\v]+
NEWLINE (\r)?\n
LETTER  [a-zA-Z]
EMPTY_CHAR "''"
UNFINISHED_CHAR  \'(.|\\\')?[^\'\r\n]*
ESCAPE_CHAR "'\\"[ntafrbv0\\"\""]"'"
UNFINISHED_ESCAPE_CHAR (\'(\\)\')
SINGLE_CHAR "'"."'"
MULTI_CHAR "'"[^"'"\n]+"'"

DIGIT [0-9]
INTEGER{DIGIT}+
ALPHABET {LETTER}|_
ALPHANUMERIC {ALPHABET}|{DIGIT}
IDENTIFIERS (_|{LETTER})(_|{LETTER}|{DIGIT})*
INVALID_IDENTIFIER {ALPHABET}({ALPHANUMERIC})*
EXPONENT([Ee][+-]?{INTEGER})
FLOATNUM {INTEGER}?(\.)?{INTEGER}{EXPONENT}?


KEYWORD (if|else|for|while|do|break|int|char|float|double|void|return|switch|case|default|continue)
STRING_START (\")
SINGLE_LINE_COMMENT (\/\/)
MULTI_LINE_COMMENT_START (\/\*)
TOO_MANY_DECIMAL {INTEGER}?((\.{DIGIT}*){2,}){EXPONENT}?
ILL_NUM {FLOATNUM}+
INVALID_PRE_SUFF {FLOATNUM}+{IDENTIFIERS}+

%%
{WHITESPACE} {}
{NEWLINE} {line_count++;}
{KEYWORD} {keyWordPrint(yytext);}

"++"|"--" {actionForOperator("INCOP",yytext);}
[+-] {actionForOperator("ADDOP",yytext);}
[*/%] {actionForOperator("MULOP",yytext);}
\<|"<="|\>|">="|"=="|"!=" {actionForOperator("RELOP",yytext);}
\= {actionForOperator("ASSIGNOP",yytext);}
"&&"|"||" {actionForOperator("LOGICOP",yytext);}
\&|(\|)|(\^)|"<<"|">>"  { actionForOperator("BITOP", yytext); }
\! {actionForOperator("NOT",yytext);}
\( {actionForOperator("LPAREN",yytext);}
\) {actionForOperator("RPAREN",yytext);}
\{ {actionForOperator("LCURL",yytext);}
\}	{actionForOperator("RCURL",yytext);}
\[ {actionForOperator("LSQUARE",yytext);}
\] {actionForOperator("RSQUARE",yytext);}
\, {actionForOperator("COMMA",yytext);}
\; {actionForOperator("SEMICOLON",yytext);}

{UNFINISHED_ESCAPE_CHAR} {
            errorCnt++;
            fprintf(logout,"Error at line# %d: UNFINISHED_CONST_CHAR %s\n", line_count ,yytext);
        }
{SINGLE_CHAR} {
            string character="";
            character+=yytext[1];
			fprintf(tokenout,"<CONST_CHAR, %s>\n",character.c_str());
			fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme %s found\n",line_count,character.c_str());
		}
{ESCAPE_CHAR} {
            string character="";
            if( yytext[2] =='n') character = '\n';
			else if( yytext[2] =='t') character = '\t';
			else if( yytext[2] =='a') character = '\a';
			else if( yytext[2] =='f') character = '\f';
			else if( yytext[2] =='r') character = '\r';
			else if( yytext[2] =='b') character = '\b';
			else if( yytext[2] =='v') character = '\v';
			else if( yytext[2] =='0') character = '\0';
			else if( yytext[2] =='\\') character = '\\';
			else character = '\"';
			fprintf(tokenout,"<CONST_CHAR, %s>\n",character.c_str());
			fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme %s found\n",line_count,character.c_str());
		}
{IDENTIFIERS} {actionForIdentifier(yytext);}

{INTEGER} 	{
				fprintf(tokenout,"<CONST_INT, %s>\n",yytext);
				fprintf(logout,"Line# %d: Token <CONST_INT> Lexeme %s found\n",line_count,yytext);
			}
{FLOATNUM} {
				fprintf(tokenout,"<CONST_FLOAT, %s>\n",yytext);
				fprintf(logout,"Line# %d: Token <CONST_FLOAT> Lexeme %s found\n",line_count,yytext);
}		
{INVALID_IDENTIFIER} {
		fprintf(logout,"Error at line# INVALID_IDENTIFIER %d:  %s\n", line_count ,yytext);
}
{EMPTY_CHAR} {
	errorCnt++;
	fprintf(logout,"Error at line# %d: EMPTY_CONST_CHAR %s\n", line_count ,yytext);
}
{UNFINISHED_CHAR}  {
            errorCnt++;
            fprintf(logout,"Error at line# %d: UNFINISHED_CONST_CHAR %s\n", line_count ,yytext);
}
{MULTI_CHAR} {
	errorCnt++;
		fprintf(logout,"Error at line# %d: MULTICHAR_CONST_CHAR %s\n", line_count ,yytext);
}
{STRING_START} {
	tokenStr="";
	logStr="\"";
	tempLine=0;
	BEGIN STRING_STATE;

}

<STRING_STATE>\\n {
           logStr+="\\n";
           tokenStr+="\n";
        }
<STRING_STATE>\\t {
            logStr+="\\t";
            tokenStr+="\t";
        }
<STRING_STATE>\\\\ {
            logStr+="\\\\";
            tokenStr+="\\";
        }
<STRING_STATE>\\\' {
            logStr+="\\\'";
            tokenStr+="\'";
        }
<STRING_STATE>\\\" {
            logStr+="\\\"";
            tokenStr+="\"";
        }
<STRING_STATE>\\a {
            logStr+="\\a";
            tokenStr+="\a";
        }
<STRING_STATE>\\f {
            logStr+="\\f";
            tokenStr+="\f";
        }
<STRING_STATE>\\r {
            logStr+="\\r";
            tokenStr+="\r";
        }
<STRING_STATE>\\b {
            logStr+="\\b";
            tokenStr+="\b";
        }
<STRING_STATE>\\v {
            logStr+="\\v";
            tokenStr+="\v";
        }
<STRING_STATE>\\0 {
            logStr+="\\0";
            tokenStr+="\0";
        }
<STRING_STATE>\\[\r]?[\n] {
            
            tempLine++;
            string aux(yytext);
            logStr+=aux;
        }
<STRING_STATE>[\r]?[\n] {
            tempLine++;
            errorCnt++;
            fprintf(logout,"Error at line# %d: UNFINISHED_STRING %s\n", line_count ,logStr.c_str());
            line_count+=tempLine;
            tempLine=0;
            logStr="";
            tokenStr="";
            BEGIN INITIAL;
        }
<STRING_STATE>\" {
            if(logStr.find("\n")!=string::npos){
                lexemeType="MULTI LINE STRING";
            }
            else{
                lexemeType="SINGLE LINE STRING";
            }
            logStr+="\"";
            fprintf(tokenout,"<%s, %s>\n",lexemeType.c_str(),tokenStr.c_str());
            fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_count,lexemeType.c_str(),logStr.c_str());
            line_count+=tempLine;
            tempLine=0;
            logStr="";
            tokenStr="";
            BEGIN INITIAL;
        }
<STRING_STATE>. {
            logStr+=yytext;
            tokenStr+=yytext;
        }
{SINGLE_LINE_COMMENT} {
	
	comment="//";
	tempLine=0;
	BEGIN SINGLE_LINE_COMMENT_STATE ;
}
<SINGLE_LINE_COMMENT_STATE>\\[\r]?[\n] { 
        ++tempLine;
		comment += std::string(yytext);
        }
<SINGLE_LINE_COMMENT_STATE>[\r]?[\n] {
           
    ++tempLine;
	fprintf(logout, "Line# %d: Token <SINGLE LINE COMMENT> Lexeme %s found\n", line_count, comment.c_str());
	line_count += tempLine;
	comment.clear();
	tempLine = 0;
	BEGIN(INITIAL);
}
<SINGLE_LINE_COMMENT_STATE>. {
            comment+=yytext;
        }

{MULTI_LINE_COMMENT_START} {
            comment="/*";
            tempLine=0;
            BEGIN (MULTI_LINE_COMMENT_STATE);
        }
<MULTI_LINE_COMMENT_STATE>[^\n] {
            string aux(yytext);
            comment+=aux;
        }
<MULTI_LINE_COMMENT_STATE>[\r]?[\n] {
           
            string aux(yytext);
            comment+=aux;
            tempLine++;
        }
<MULTI_LINE_COMMENT_STATE>\*\/ {
           
            string aux(yytext);
            comment+=aux;
            fprintf(logout,"Line# %d: Token <MULTI LINE COMMENT> Lexeme %s found\n",line_count,comment.c_str());
            line_count+=tempLine;
            comment.clear();
            tempLine=0;
            BEGIN (INITIAL);
        }
<MULTI_LINE_COMMENT_STATE><<EOF>> {
            errorCnt++;
            tempLine++;
            line_count+=tempLine;
            fprintf(logout,"Error at line# %d: UNFINISHED_COMMENT %s\n", line_count ,comment.c_str());
            comment.clear();
			tempLine=0;
            BEGIN (INITIAL);
        }

{TOO_MANY_DECIMAL} {
	errorCnt++;
	fprintf(logout,"Error at line# %d: TOO_MANY_DECIMAL_POINTS %s\n", line_count ,yytext);
}
{ILL_NUM} {
	errorCnt++;
	fprintf(logout,"Error at line# %d: ILLFORMED_NUMBER %s\n", line_count ,yytext);
}
{INVALID_PRE_SUFF} {
            errorCnt++;
            fprintf(logout,"Error at line# %d: INVALID_ID_SUFFIX_NUM_PREFIX %s\n", line_count ,yytext);
        }


. {fprintf(logout,"Error at line# %d: UNRECOGNIZED_CHAR %s\n", line_count ,yytext);}
	
			
%%

int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	logout= fopen("log.txt","w");
	tokenout= fopen("token.txt","w");

	yyin= fin;
	yylex();
	fclose(yyin);
	symboltable.printAllScopeTable();
	fprintf(logout,"Total lines: %d\n",line_count);
	fprintf(logout,"Total errors: %d\n",errorCnt);
	fprintf(logout,"Total warnings: %d\n",warningCnt);
	fclose(tokenout);
	fclose(logout);
	return 0;
}
