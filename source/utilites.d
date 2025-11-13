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

void printSeperator()
{
    version(Windows)
    {
        foreach(_; 0 .. MDASHCOUNT)
            write("\u2500");
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

bool checkVariable(string var, VARIABLE_CHECKER check)
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
        writeln("\x1B[1;31msorry could not convert ", var, "to ", check, "\x1B[0m");
        return false;
    }
}

void printAll(JSONValue settings, bool complete = true)
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
            printSeperator();
            writeln;
            writeln(printSpaces("mon", SPACING), "\x1b[3;31mMONJOGS\x1b[23;0m");
            writeln("monjog",printSpaces("monjog"),"count", printSpaces("count"), "price");
            string defaultPrice = to!string(settings["codes"].object()["default"].integer);
            foreach(monjog; works[work]["monjogs"].object.keys)
            {
                if (monjog in settings["codes"]){
                    string monjogCount = to!string(works[work]["monjogs"].object[monjog].integer);
                    string monjogPrice = to!string(settings["codes"][monjog].integer);
                    if (monjogPrice == "-1")
                        monjogPrice = defaultPrice;
                    writeln(monjog,printSpaces(monjog),monjogCount,printSpaces(monjogCount) ,monjogPrice);
                }
                else 
                    writeln("\x1b[39;31m", monjog, " \x1b[39m is not part of the \"codes\" group in the \"",FILENAME,"\" file");
            }
        }
        if ("materials" in works[work])
        {
            printSeperator(); 
            writeln;
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
                else 
                    writeln("\x1b[39;31m", material, " \x1b[39m is not part of the \"other_materials\" group in the \"settings/settings.json\" file");

            }
        }
    }
    printSeperator();
    writeln;
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

bool calculateWork(in JSONValue settings)
{
    import std.array: split;
    import std.conv: to;
    import std.string: strip;

    writeln("this is the list of all works");
    printAll(settings, false); // only print the names of the works
    write("please enter the number for the work: ");

    auto choice_ = to!int(strip(readln()));
    auto works = settings["works"].object.keys; 
    auto currentWork = settings["works"].object[works[choice_-1]];
    writeln("the work is: ",works[choice_-1]);

    ulong monResults = 0; // price for monjogs
    ulong matResults = 0; // price for materials
    ulong tResults = 0; // the price for time
    uint addResults = 0; // the price for additional costs
    ulong results = 0; // the final results
    ulong mulResults = 0; // the final results after multiplier

    if ("monjogs" in currentWork)
    {
        writeln(replicate("\&mdash;",MDASHCOUNT)); 
        writeln(printSpaces("mon", SPACING), "\x1b[3;31mMONJOGS\x1b[23;0m");
        writeln("monjog",printSpaces("monjog"),"count", printSpaces("count"), "price");
        float defaultPrice = to!float(settings["codes"].object()["default"].integer);
        foreach(name_, count_; currentWork["monjogs"].object)
        {
            float ucount_ = to!float(count_.get!int); 
            float temp = to!float(settings["codes"].object[name_].get!int);
            float price;
            if (temp == -1)
                price = defaultPrice;
            else
                price = temp;
            writeln(name_,printSpaces(name_),ucount_,printSpaces(to!string(ucount_)) ,price);
            monResults += to!uint(price * ucount_/175);
        }
    }
    else 
        return false;
    if ("materials" in currentWork)
    {
        writeln(replicate("\&mdash;",MDASHCOUNT)); 
        writeln(printSpaces("mat", SPACING), "\x1b[3;31mMATERIALS\x1b[23;0m");
        writeln("material",printSpaces("material"),"count", printSpaces("count"), "price");
        foreach(name_, count_; currentWork["materials"].object)
        {
            uint ucount_ = count_.get!int; 
            uint price = settings["other_materials"].object[name_].get!int;
            writeln(name_,printSpaces(name_),ucount_,printSpaces(to!string(ucount_)) ,price);
            matResults += price * ucount_/175;
        }
    }

    if ("additional_costs" in settings)
    {
        addResults = settings["additional_costs"].object["price"].get!int;
        writeln(replicate("\&mdash;",MDASHCOUNT)); 
        writeln(printSpaces("addition", SPACING), "\x1b[3;31mADDITIONAL COSTS\x1b[23;0m");
        writeln("price",printSpaces("price"), addResults);
    }

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
    uint timePrice = settings["time"].object["price"].get!int;
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

    tResults = minutes * timePrice;
    // finalizing the reults
    results = monResults + matResults + tResults + addResults;
    // checking for discount
    writeln(replicate("\&mdash;",MDASHCOUNT));
    writeln("do you want to increase (or decrease) the results by a % (if not you can enter 0, e.g. 25 or 125): ");
    uint multValue; // the multiplier
DISCOUNT:
    try
    {
        multValue = to!uint(strip(readln()));
        if (multValue <= 100)
            mulResults = (100-multValue) * results / 100;
        else
            mulResults = multValue * results / 100;
    }
    catch(Exception)
    {
        writeln("please enter a number!");
        goto DISCOUNT;
    }

    writeln(replicate("\&mdash;",MDASHCOUNT));
    writeln("\x1b[38;5;146mthe final price for monjogs was: ", monResults);
    writeln("\x1b[38;5;225mthe final price for materials was: ", matResults);
    writeln("\x1b[38;5;225mthe final price for additional costs was: ", addResults);
    writeln("\x1b[38;5;225mthe final price for time was: ", tResults);
    writeln("\x1b[38;5;225mthe discount value was: ", multValue);
    writeln("\x1b[38;5;134mthe price (whithout discount) is: ", results, "\x1b[0m");
    writeln("\x1b[38;5;134mthe final price (after discount) is: ", mulResults, "\x1b[0m");
    writeln(replicate("\&mdash;",MDASHCOUNT)); 
    return true;
}

void addWork(ref JSONValue settings)
{
    import std.string;
    import std.conv: to;
    writeln(replicate("\&mdash;",MDASHCOUNT));
    write("please enter the name of the work: ");
    string workName = strip(readln());
    settings["works"].object()[workName] = JSONValue.emptyObject;
    settings["works"].object()[workName].object()["monjogs"] = JSONValue.emptyObject;
    auto currentWorkMonjogs = "monjogs" in settings["works"].object()[workName].object();
    string[] monjogCodes = [];
    while(true)
    {
        write("please enter the (next) monjog code(s) or press Enter to finish adding monjogs: ");

        import std.array: split;
        auto codes = split(strip(readln()));

        if (!codes.length) break;
        monjogCodes ~= codes;

        foreach(code; codes)
        {
            write("please enter the \x1B[1;31mnumber\x1B[0m of monjogs for code ", code, ": ");
            while(true)
            {
                auto codeCountStr = strip(readln());
                int codeCount = 0;
                if (checkVariable(codeCountStr, VARIABLE_CHECKER.INT))
                {
                    codeCount = to!int(codeCountStr);
                    (*currentWorkMonjogs)[code] = codeCount;
                    break;
                }
                write("please enter the \x1B[1;31mnumber\x1B[0m of monjogs for code ", code, ": ");
            }
            writeln("-------------------------");
            if (code !in settings["codes"])
            {
                write("please enter the \x1B[1;31mprice\x1B[0m for ", code ," monjog (press Enter for default): ");
                auto price = strip(readln());
                if (!price.length) 
                    settings["codes"][code] = -1;
                else
                    settings["codes"][code] = to!int(price);
            writeln("-------------------------");
            }
        }
    }
    printSeperator();
    write("do you want to add new materials (such as aviz) to work: ", workName, ":(y/n) ");
    auto answer = strip(readln());
    if (answer == "y" || answer == "yes")
    {
        settings["works"].object()[workName].object()["materials"] = JSONValue.emptyObject;
        auto currentWorkMaterials = "materials" in settings["works"].object()[workName].object(); // for storing the new materials

        while(true)
        {
            write("please enter the material name(s) or press Enter to finish adding materials: ");

            import std.array: split;
            auto materialNames = split(strip(readln()));

            if (!materialNames.length) break;

            foreach(material; materialNames)
            {
                write("please enter the \x1B[1;31mnumber\x1B[0m of ", material, ": ");
                while(true)
                {
                    auto materialCountStr = strip(readln());
                    int materialCount = 0;
                    if (checkVariable(materialCountStr, VARIABLE_CHECKER.INT))
                    {
                        materialCount = to!int(materialCountStr);
                        (*currentWorkMaterials)[material] = materialCount;
                        break;
                    }
                    write("please enter the \x1B[1;31mnumber\x1B[0m of monjogs for material ", material, ": ");
                }
                if (material !in settings["other_materials"])
                {
                    write("please enter the \x1B[1;31mprice\x1B[0m for ", material ," (press Enter for default): ");
                    auto price = strip(readln());
                    if (!price.length)
                        settings["other_materials"][material] = -1;
                    else
                        settings["other_materials"][material] = to!int(price);
                }
            }
        }
    }
    import std.file: write;
    write("settings/settings.json",settings.toPrettyString());
}
