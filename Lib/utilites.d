import std.json, std.stdio, std.array;

enum MDASHCOUNT = 50;
enum SPACING = 20;
enum FILENAME = "./settings/works.json";
enum RED = "\x1B[1;31m";
enum BLUE = "\x1B[1;34m";
enum RESET = "\x1B[0m";

string makeRed(string s)
{
    return RED ~ s ~ RESET;
}

string makeBlue(string s)
{
    return BLUE ~ s ~ RESET;
}
// this funcion calculates the number of spaces needed to print before the string
string printSpaces(string s, int spacing = 0)
{
    import std.array: replicate;
    if (!spacing) return replicate(" ", SPACING - s.length);
    return replicate(" ", spacing - s.length);
    
}

void printSeperator()
{
    version(Windows)
    {
        foreach(_; 0 .. MDASHCOUNT)
            write("\u2500");
        writeln;
    }
    version(Posix)
    {
        writeln(replicate("\&mdash;",MDASHCOUNT));
    }
}

enum VARIABLE_CHECKER
{
    INT,
    INTEGER,
    FLOAT
}

bool checkVariable(string var, VARIABLE_CHECKER check, bool silent = false)
{
    import std.conv: to;
    try
    {
        switch (check)
        {
            case VARIABLE_CHECKER.INT, VARIABLE_CHECKER.INTEGER:
                to!int(var);
                return true;
                break;
            case VARIABLE_CHECKER.FLOAT:
                to!float(var);
                return true;
                break;
            default:
                return true;
        }
    }
    catch (Exception)
    {
        if (!silent)
            writeln("\x1B[1;31msorry could not convert ", var, " to ", check, "\x1B[0m");
        return false;
    }
}

string prettify(in int s)
{
    char[] s2;

    import std.conv: to;

       s2 = to!string(s).dup(); 
       auto l = s2.length;
       while(l > 3)
       {
           s2 = s2[0..l-3] ~ "," ~ s2[l-3 .. $];
           l -= 3;
       }
    return s2.idup();
}

void printTimeHelp() // used in calculateWork function
{
    writeln("please enter one the following formats for time");
    writeln("\"hours\":\"minutes\":\"seconds\"");
    writeln("\"hours\" \"minutes\" \"seconds\"");
    writeln("\"hours\"h");
    writeln("\"minutes\"m");
}

import std.regex: ctRegex, matchFirst;
auto fullTimeReg = ctRegex!(`\d+:\d+:\d+`);
auto fullTimeReg2 = ctRegex!(`\d+ \d+ \d+`);
auto hourReg = ctRegex!(`\d+h`);
auto minReg = ctRegex!(`\d+m`);

ulong calcTime(uint timePrice)
{
    import std.string: strip;
    import std.conv: to;
    // finding the time format
    writeln(replicate("\&mdash;",MDASHCOUNT)); 
    printTimeHelp();
    write("time: ");
    string duration = strip(readln());
    ulong minutes = 0;

    auto ftr = matchFirst(duration, fullTimeReg);
    auto ftr2 = matchFirst(duration, fullTimeReg2);
    auto hr = matchFirst(duration, hourReg);
    auto mr = matchFirst(duration, minReg);
    if (!ftr.empty) 
    {
        auto times = ftr[0].split(":");
        auto h = to!ulong(times[0]);
        auto m = to!ulong(times[1]);
        auto s = to!ulong(times[2]);
        if (s >= 60)
            m += s / 60; 
        minutes += m + h * 60;
    }
    else if (!ftr2.empty) 
    {
        import std.array: split;
        import std.conv: to;
        auto times = ftr2[0].split();
        auto h = to!ulong(times[0]);
        auto m = to!ulong(times[1]);
        auto s = to!ulong(times[2]);
        if (s >= 60)
            m += s / 60; 
        minutes += m + h * 60;
    }
    else if (!hr.empty)
    {
        import std.array: split;
        import std.conv: to;
        auto times = hr[0].split("h");
        auto h = to!ulong(times[0]);
        minutes += h * 60;
    }
    else if (!mr.empty)
    {
        import std.array: split;
        import std.conv: to;
        auto times = mr[0].split("m");
        minutes = to!ulong(times[0]);
    }

    return minutes * timePrice;
}
