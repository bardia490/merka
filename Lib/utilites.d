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
    UINT,
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

union Results(T)
{
    ubyte status; // returns a number on failure
    T result; // returns the value with type T
}

// on failure returns 0
Results!(T) checkVariable(T)(string var, bool silent = false)
{
    import std.conv: to;
    Results!(T) r;
    try
    {
        r.results = to!T(var);
        return r;
    }
    catch (Exception)
    {
        if (!silent)
            writeln("\x1B[1;31msorry could not convert ", var, " to ", "TODO...", "\x1B[0m");
        return r.status = 0;
    }
}

T getAnswer(T)(string question = "", bool function(T t) condition = {return true;})
{
    import std.string: strip, readln;
    writeln(question);
    string answer = strip(readln());
    while(true)
    {
        if (answer != "")
        {
            Results!T r = checkVariable!T(answer, true);
            if (r.status)
                if (condition(r.result))
                    return r.result;
        }
    }
}

string prettify(T)(in T s)
{
    void prettifyAux(ref char[] s)
    {
        auto l = s.length;
        while(l > 3)
        {
            s = s[0..l-3] ~ "," ~ s[l-3 .. $];
            l -= 3;
        }
    }
    char[] s2;

    import std.conv: to;
    import std.string: indexOfAny;
    import std.array: split;

    s2 = to!string(s).dup(); 
    if (indexOfAny(s2, ".") != -1)
    {
        auto parts = split(s2, ".");
        prettifyAux(parts[0]);
        prettifyAux(parts[1]);
        s2 = parts[0] ~ "." ~ parts[1];
    }
    else
        prettifyAux(s2);
    return s2.idup();
}

void printTimeHelp() // used in calculateWork function
{
    writeln("please enter one the following formats for ", makeBlue("time"));
    writeln("\"hours\":\"minutes\"");
    writeln("\"hours\" \"minutes\"");
    writeln("\"hours\"h");
    writeln("\"minutes\"m");
    writeln("\"minutes\"");
}

import std.regex: ctRegex, matchFirst;
auto fullTimeReg = ctRegex!(`\d+:\d+`);
auto fullTimeReg2 = ctRegex!(`\d+ \d+`);
auto hourReg = ctRegex!(`\d+h`);
auto minReg = ctRegex!(`\d+m`);
auto default_ = ctRegex!(`\d+`); // default value -> minutes

float getTime(bool help = true, string _duration = "")
{
    import std.string: strip;
    import std.conv: to;
    // finding the time format
    string duration;
START:
    if (help)
        printTimeHelp();
    if (_duration != "")
        duration = _duration;
    else
    {
        write("time: ");
        duration = strip(readln());
    }
    float hours = 0;

    auto ftr = matchFirst(duration, fullTimeReg);
    auto ftr2 = matchFirst(duration, fullTimeReg2);
    auto hr = matchFirst(duration, hourReg);
    auto mr = matchFirst(duration, minReg);
    auto df = matchFirst(duration, default_);
    if (!ftr.empty) 
    {
        auto times = ftr[0].split(":");
        auto h = to!float(times[0]);
        auto m = to!float(times[1]);
        hours += m / 60 + h;
    }
    else if (!ftr2.empty) 
    {
        import std.array: split;
        import std.conv: to;
        auto times = ftr2[0].split();
        auto h = to!float(times[0]);
        auto m = to!float(times[1]);
        hours += m / 60 + h;
    }
    else if (!hr.empty)
    {
        import std.array: split;
        import std.conv: to;
        auto times = hr[0].split("h");
        hours = to!float(times[0]);
    }
    else if (!mr.empty)
    {
        import std.array: split;
        import std.conv: to;
        auto times = mr[0].split("m");
        hours = to!float(times[0]) / 60;
    }

    else if (!df.empty)
    {
        // import std.array: split;
        import std.conv: to;
        auto times = df[0];
        hours = to!float(times) / 60;
    }
    else 
    {
        writeln(makeRed("what you entered does not match any of the time formats!\nplease try again"));
        printSeperator;
        goto START;
    }
    return hours;
}

float calcTime(float timePrice)
{
    return getTime() * timePrice;
}
