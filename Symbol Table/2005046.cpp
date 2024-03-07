#include <bits/stdc++.h>
using namespace std;
#define ull unsigned long long
void splitLine(string &line, string *arr)
{
    const char delimiter = ' ';
    ull startIndex = 0;
    ull arrIndex = 0;

    for (ull i = 0; i < line.length(); ++i)
    {
        if (line[i] == delimiter)
        {
            arr[arrIndex++] = line.substr(startIndex, i - startIndex);
            startIndex = i + 1;
        }
    }

    if (startIndex < line.length())
    {
        arr[arrIndex++] = line.substr(startIndex, line.length() - startIndex);
    }
}
ull countWords(const std::string &input)
{
    ull wordCount = 0;
    bool inWord = false;

    for (char character : input)
    {
        if (character != ' ')
        {
            if (!inWord)
            {
                inWord = true;
                wordCount++;
            }
        }
        else
        {
            inWord = false;
        }
    }

    return wordCount;
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
            ss << "\tScopeTable# " << scopeId << " created" << endl;
        }
        else
        {
            parentScope->id++;
            ss<<parentScope->scopeId<<"."<<parentScope->id;
            scopeId = ss.str();
            ss.str("");//clear the stringsteam for reuse
            ss << "\tScopeTable# " << scopeId << " created" << endl;
        }
        cout<<ss.str();
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
        cout << "\tScopeTable# " << scopeId << " deleted" << endl;
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
        stringstream output;
        output << "\tScopeTable# " << scopeId << endl;
        for (ull i = 0; i < bucketSize; i++)
        {
            output << "\t" << i + 1;
            SymbolInfo *symbol = symbolInfos[i];
            while (symbol != nullptr)
            {
                output << " --> (";
                output << symbol->getName() << "," << symbol->getType();
                symbol = symbol->getNext();
                output << ")";
            }
            output << endl;
        }
        cout << output.str();
    }
    bool insert(string name, string type)
    {

        ull hashValue = sdbm(name) % bucketSize;

        if (symbolInfos[hashValue] == nullptr)
        {
            symbolInfos[hashValue] = new SymbolInfo(name, type);
            cout << "\tInserted  at position <" << hashValue + 1 << ", 1> of ScopeTable# " << scopeId << endl;
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
                cout << "\t'" << name << "'"
                     << " already exists in the current ScopeTable# " << scopeId << endl;
                return false;
            }
            count++;
            previousInfo = currentInfo;
            currentInfo = currentInfo->getNext();
        }
        SymbolInfo *s = new SymbolInfo(name, type);
        previousInfo->setNext(s);
        cout << "\tInserted  at position <" << hashValue + 1 << ", " << count + 1
             << "> of ScopeTable# " << scopeId << endl;
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
            cout << "\t'" << name << "'"
                 << " found at position <" << hashValue + 1 << ", " << count + 1 << "> of ScopeTable# " << scopeId << endl;
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
                cout << "\tDeleted '" << str << "' "
                     << "from position "
                     << "<" << hashValue + 1 << ", " << count + 1 << "> of ScopeTable# " << scopeId << endl;
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
        cout << "\tNot found in the current ScopeTable# " << scopeId << endl;
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
            cout << "\tScopeTable# 1 cannot be deleted" << endl;
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

int main()
{
    freopen("output.txt", "w", stdout);
    freopen("input.txt", "r+", stdin);

    ull n;
    cin >> n;
    SymbolTable symbolTable(n);
    ull count = 0;
    cin.ignore();
    string str;
    string words[3];

    while (getline(cin, str))
    {
        splitLine(str, words);
        ull numberOfWords = countWords(str);
        cout << "Cmd " << ++count << ": " << str << endl;

        if (numberOfWords == 3)
        {
            if (words[0] == "I")
            {
                symbolTable.insert(words[1], words[2]);
            }
            else{
                cout << "\tWrong number of arugments for the command " << words[0] << endl;
            }
        }
        else if (numberOfWords == 2)
        {
            if (words[0] == "L")
            {
                symbolTable.lookUp(words[1]);
            }
            else if (words[0] == "D")
            {
                symbolTable.remove(words[1]);
            }
            else if (words[0] == "P")
            {
                if (words[1] == "A")
                {
                    symbolTable.printAllScopeTable();
                }
                else if (words[1] == "C")
                {
                    symbolTable.printCurrentScopeTable();
                }
                else
                {
                    cout << "\tInvalid argument for the command P" << endl;
                }
            }
            else{
                 cout << "\tWrong number of arugments for the command " << words[0] << endl;
            }
        }
        else if(numberOfWords==1)
        {
            if(words[0]=="S") symbolTable.enterScope();
            else if(words[0]=="E")symbolTable.exitScope();
            else if(words[0]=="Q") return 0;
            else{
                cout << "\tWrong number of arugments for the command " << words[0] << endl;
            }

        }
        else{
            cout << "\tWrong number of arugments for the command " << str << endl;
        }

    }

    return 0;
}