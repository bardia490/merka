import std.json, std.stdio, std.array;

enum MDASHCOUNT = 50;
enum SPACING = 20;
enum FILENAME = "./settings/settings.json";

// this funcion calculates the number of spaces needed to print before the string
string printSpaces(string s, int spacing = 0)
{
    import std.array: replicate;
    if (!spacing) return replicate(" ", SPACING - s.length);
    return replicate(" ", spacing - s.length);
    
}

void print_all(JSONValue settings, bool complete = true)
{
    if (!complete)
    {
            write("\x1b[38;5;166m");
            writeln(replicate("<>", MDASHCOUNT/2));
            write("\x1b[38;5;231m");
        foreach (index_, work; settings["works"].object.keys)
        {
            writeln(index_+1,": \x1b[1m",work, "\x1b[22m");
        }
            write("\x1b[38;5;166m");
            writeln(replicate("<>", MDASHCOUNT/2));
            write("\x1b[0m");
            return;
    }
    auto works = settings["works"].object; 
    foreach (work; works.keys)
    {
        write("\x1b[0;34m");
        writeln(replicate("<>", MDASHCOUNT/2));
        write("\x1b[0m");
        writeln("\x1b[1m",work, "\x1b[22m");
        write("\x1b[0;34m");
        writeln(replicate("<>", MDASHCOUNT/2));
        write("\x1b[0;34m");
        import std.conv: to;
        if ("monjogs" in works[work])
        {
            writeln(replicate("\&mdash;",MDASHCOUNT)); 
            writeln(printSpaces("mon", SPACING), "\x1b[3;31mMONJOGS\x1b[23;0m");
            writeln("monjog",printSpaces("monjog"),"count", printSpaces("count"), "price");
            foreach(monjog; works[work]["monjogs"].object.keys) 
            {
                if (monjog in settings["codes"]){
                    string monjogCount = to!string(works[work]["monjogs"].object[monjog].integer);
                    string monjogCode = to!string(settings["codes"][monjog].integer);
                    writeln(monjog,printSpaces(monjog),monjogCount,printSpaces(monjogCount) ,monjogCode);
                }
                else 
                    writeln("\x1b[39;31m", monjog, " \x1b[39m is not part of the \"codes\" group in the \"",FILENAME,"\" file");
            }
        }
        if ("materials" in works[work])
        {
            writeln(replicate("\&mdash;",MDASHCOUNT)); 
            writeln(printSpaces("mate", SPACING), "\x1b[3;31mMATERIALS\x1b[23;0m");
            writeln("material",printSpaces("material"),"count",printSpaces("count"),"price");
            foreach(material; works[work]["materials"].object.keys)
            {
                if (material in settings["other_materials"]) 
                {
                    auto materialCount = to!string (works[work]["materials"].object[material].integer);
                    auto materialCode = to!string(settings["other_materials"][material].integer);
                    writeln(material, printSpaces(material), materialCount,printSpaces(materialCount),materialCode);
                }
                else writeln("\x1b[39;31m", material, " \x1b[39m is not part of the \"other_materials\" group in the \"settings/settings.json\" file");

            }
        }
    }
    writeln(replicate("\&mdash;",MDASHCOUNT));

}
