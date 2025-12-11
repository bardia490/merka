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

struct Results(T)
{
    ubyte status = 1; // returns 0 number on failure
    T result; // returns the value with type T
}

// checks to see if the variable can be converted to the desired type (T)
// on success the Results(T) union holds the final value
// on failure returns 0
Results!(T) checkVariable(T)(string var, bool silent = false)
{
    import std.conv: to;
    Results!(T) r;
    try
        r.result = to!T(var);
    catch (Exception)
    {
        if (!silent)
            writeln("\x1B[1;31msorry could not convert ", var, " to ", "TODO...", "\x1B[0m");
        r.status = 0;
    }
    return r;
}

// get the answer based on the condition
// the question is the question that will be asked before waiting for input
// the q_condition is a function that takes the parameter of the type string (the same type as question)
// and is checked together with the final value condition
// the condition is a function that takes the parameter of the same type as the return value (T)
// and returns true if it meets its criteria
// if error_message is set to a non empty string it prints the error_message after every wrong input
// if error_message is set to a empty string it prints the default error message
// if print_sep is set to true it prints the seperator before the question every time
T getAnswer(T)(string question, bool function(string s) q_condition, bool function(T t) condition, string error_message = "", bool print_sep = false)
{
    import std.string: strip;
    while(true)
    {
        if (print_sep)
            printSeperator;
        writeln(question);
        write("> ");
        string answer = strip(readln());

        Results!T r = checkVariable!T(answer, true);
        if (q_condition(answer) && r.status != 0 && condition(r.result))
            return r.result;

        if (error_message != "")
            writeln(makeRed(error_message));
        else
            writeln(makeRed("WRONG INPUT"));
    }
}

// same as getAnswer but the q_condition is that it cannot be empty
T get_non_empty_answer(T)(string question = "", bool function(T t) condition, string error_message = "", bool print_sep = false)
{
    return getAnswer!T(question, (string s) {return s != "";}, condition, error_message, print_sep);
}

// prompts the user until it gets a non empty and natural (answer must be a number) answer and returns it 
T get_non_empty_natural_answer(T)(string question = "", string error_message = "", bool print_sep = false)
{
    return getAnswer!T(question, (string s) {return s != "";}, (T n) {return n >= 0;}, error_message, print_sep);
}

// prompts the user until it gets a non empty and positive (answer must be a number) answer and returns it 
T get_non_empty_positive_answer(T)(string question = "", string error_message = "", bool print_sep = false)
{
    return getAnswer!T(question, (string s) {return s != "";}, (T n) {return n > 0;}, error_message, print_sep);
}
// like getAnswer but if the answer is empty it returns the default value
// the default value and question are mandatory in this function
T getAnswer_with_default(T)(string question, bool function(T t) condition, T default_, string error_message = "", bool print_sep = false)
{
    import std.string: strip;

    Results!T r;
    while(true)
    {
        if (print_sep)
            printSeperator;
        writeln(question);
        write("> ");
        string answer = strip(readln());


        if (answer == "")
            return default_;

        r = checkVariable!T(answer, true);
        if (r.status != 0 && condition(r.result))
            return r.result;

        if (error_message != "")
            writeln(makeRed(error_message));
        else
            writeln(makeRed("WRONG INPUT"));
    }
}

T get_positive_default_answer(T)(string question, T default_, string error_message = "", bool print_sep = false)
{
   return getAnswer_with_default!T(question, (T n) {return n > 0;}, default_, error_message, print_sep); 
}

T get_natural_default_answer(T)(string question, T default_, string error_message = "", bool print_sep = false)
{
   return getAnswer_with_default!T(question, (T n) {return n >= 0;}, default_, error_message, print_sep); 
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
        duration = getAnswer!string(makeBlue("time:"), (s) {return s!= "";}, (_) {return true;}, "PLEASE ENTER SOMETHING" ,true); // make sure the string is not empty the rest is handled true regexes
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
