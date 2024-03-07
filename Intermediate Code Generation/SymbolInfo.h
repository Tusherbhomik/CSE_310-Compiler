#ifndef SYMBOLINFO_H
#define SYMBOLINFO_H
#include <bits/stdc++.h>
using namespace std;

#define ull unsigned long long
extern FILE *logout;
class SymbolInfo
{
    
private:

    string name;
    string type;
    SymbolInfo *next;
    vector<SymbolInfo*> nextChilds;
    int startLine ;
    int endLine;
   
    bool isFunc=false;
    bool define=false;

public:
    vector<SymbolInfo*> paramList;
    SymbolInfo *symbol=nullptr;
    bool global=false;
    bool isArray=false;
    int funstartOffset=0;
    string nextlevel="tanim";
    string truelevel="akash";
    string falselevel="tushar";
    int arraySize=0;
    bool isCond=false;
    void setDefine(){
        define=true;
    }
    bool getDefine()
    {
        return define;
    }
    void setIsFunc(){
        isFunc=true;
    }
    bool getIsFunc()
    {
        return isFunc;
    }
    
    void setStartLine(int a){
        startLine=a;
    }
    void setEndLine(int a){
        endLine=a;
    }
    int getStartLine()
    {
        return startLine;
    }
    int getEndLine()
    {
        return endLine;
    }
    SymbolInfo(string name, string type)
    {
        this->name = name;
        this->type = type;
        next = nullptr;
    }
    void addChild(SymbolInfo *child)
    {
        nextChilds.push_back(child);
    }
    vector<SymbolInfo*>& getChildren()
    {
        return nextChilds;
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
    vector<SymbolInfo*>& getParamLists()
    {
        return paramList;
    }
    void addParam(SymbolInfo *child)
    {
        paramList.push_back(child);
    }
    // ~SymbolInfo() {}
};

class ScopeTable
{
private:
    SymbolInfo **symbolInfos;
    ScopeTable *parentScope;
    ull bucketSize;
    

public:
    ull id; 
    ScopeTable(ull id , ull n, ScopeTable *parentScope)
    {
        
        this->id = id;
        bucketSize = n;
        this->parentScope = parentScope;
        symbolInfos = new SymbolInfo *[bucketSize];

        for (ull i = 0; i < bucketSize; i++)
        {
            symbolInfos[i] = nullptr;
        }
        // cout<<id<<endl;
    }
    
    unsigned long long sdbm(string str)
    {
        unsigned long long hash = 0;
        for (unsigned long long i = 0; i < str.length(); i++)
        {
            hash = str[i] + (hash << 6) + (hash << 16) - hash;
        }
        return hash;
    }
    // ~ScopeTable()
    // {
    //     for (ull i = 0; i < bucketSize; i++)
    //     {
    //         SymbolInfo *temp = symbolInfos[i];
    //         while (temp != nullptr)
    //         {
    //             SymbolInfo *tempInfo = temp->getNext();
    //             delete temp;
    //             temp = tempInfo;
    //         }
    //     }
    //     delete[] symbolInfos;
    // }
    ScopeTable *getParentScope()
    {
        return this->parentScope;
    }
    void setParentScope(ScopeTable *parentScope)
    {
        this->parentScope = parentScope;
    }

    void printCurrentScopeTable()
    {
        bool flag=false;
        fprintf(logout, "\tScopeTable# %llu\n", id);
        for (ull i = 0; i < bucketSize; i++)
        {

            SymbolInfo *symbol = symbolInfos[i];
            if (symbol != nullptr)
            {
                fprintf(logout,"\t%d-->",i+1);
            }
            
           
            while (symbol != nullptr)
            {
                flag=true;
                
                if(symbol->getIsFunc())
                { 
                     fprintf(logout, " <%s, FUNCTION ,%s>", symbol->getName().c_str(), symbol->getType().c_str());

                }else{
               
                fprintf(logout, "<%s,%s>", symbol->getName().c_str(), symbol->getType().c_str());
                
                }
                symbol = symbol->getNext();
               
            }
            if(flag){
                fprintf(logout,"\n");
                flag=false;
            }
        }
    }
    bool insert(SymbolInfo *s)
    {

        ull hashValue = sdbm(s->getName()) % bucketSize;

        if (symbolInfos[hashValue] == nullptr)
        {
            symbolInfos[hashValue] = s;
            return true;
        }

        SymbolInfo *currentInfo = symbolInfos[hashValue];
        SymbolInfo *previousInfo = nullptr;
        ull count = 0;

        while (currentInfo != nullptr)
        {
            if (currentInfo->getName() == s->getName())
            {
                //'<=' already exists in the current ScopeTable# 1.1
                // cout << "\t'" << name << "'"
                //  << " already exists in the current ScopeTable# " << scopeId << endl;
                // fprintf(logout, "\t%s already exists in the current ScopeTable\n", name.c_str());
                return false;
            }
            count++;
            previousInfo = currentInfo;
            currentInfo = currentInfo->getNext();
        }

        //SymbolInfo *s = new SymbolInfo(name, type);
        previousInfo->setNext(s);
        // cout << "\tInserted  at position <" << hashValue + 1 << ", " << count + 1
        //      << "> of ScopeTable# " << scopeId << endl;
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
        // if (s != nullptr)
        // {
        //     //'i' found at position <1, 1> of ScopeTable# 1
        //     // cout << "\t'" << name << "'"
        //     //     << " found at position <" << hashValue + 1 << ", " << count + 1 << "> of ScopeTable# " << scopeId << endl;
        // }
        return s;
    }

};

class SymbolTable
{
private:
    ull n;
    ScopeTable *currentScope;
    ull noOfScope;

public:
    SymbolTable(ull n)
    {
        this->n = n;
        noOfScope=1;
        currentScope = new ScopeTable(1,n, nullptr);

    }

    // ~SymbolTable()
    // {
    //     ScopeTable *temp = currentScope;
    //     while (temp != nullptr)
    //     {
    //         currentScope = currentScope->getParentScope();
    //         delete temp;
    //         temp = currentScope;
    //     }
    // }

    void enterScope()
    {
        noOfScope++;
        currentScope = new ScopeTable(noOfScope,n, currentScope);
    }
    void exitScope()
    {
        ScopeTable *temp = currentScope;
        currentScope = currentScope->getParentScope();
        // delete temp;
    }
    bool insert(SymbolInfo *s)
    {
        // if (currentScope == nullptr)
        // {
        //     currentScope = new ScopeTable(noOfScope+1,n, nullptr);
        // }
        return currentScope->insert(s);
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

        //cout << "\t'" << str << "' not found in any of the ScopeTables" << endl;
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
    ull getId(){
        return currentScope->id;
    }
};
#endif