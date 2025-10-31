import std.stdio; 

class WorksDataBase
{
    string[] names; 
    string[] codes; 
    float[] prices; 

    void print()
    {
        writeln(this.names, this.codes, this.prices);
    }

    void add(string name,string code, float price) {
       this.names  ~= name;
       this.codes  ~= code;
       this.prices ~= price;
    }
}

