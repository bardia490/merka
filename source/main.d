import std.stdio;
import std.string;
import std.process;
import std.json;
import std.file;
import utilites;

import std.regex: ctRegex, matchFirst;
auto fullTimeReg = ctRegex!(`\d+:\d+:\d+`);
auto fullTimeReg2 = ctRegex!(`\d+ \d+ \d+`);
auto hourReg = ctRegex!(`\d+h`);
auto minReg = ctRegex!(`\d+m`);

void printHelp(){
    writeln("application help:");
    writeln("type q or quit anytime to quit the app");
    writeln("type h anytime to see the help");
    //writeln("type a or all to see all the reports so far");
    writeln("type cl or clear to clear the screen");
    writeln("type ca or \"calculate\" to calculate the price for a work");
    writeln("type pa or print_all to print all the works");
    writeln("type re or \"reload\" to reload the contents of the settings file");
    //writeln("type \'add\' to add a new work");
}

void printTimeHelp()
{
    writeln("please enter one the following formats for time");
    writeln("\"hours\":\"minutes\":\"seconds\"");
    writeln("\"hours\" \"minutes\" \"seconds\"");
    writeln("\"hours\"h");
    writeln("\"minutes\"m");
}

// use this to initalize (or reload) the settings file
void loadSettings(ref JSONValue settings)
{
    string contents = readText(FILENAME);
    settings = parseJSON(contents);
}

void main(){
    JSONValue settings;
    loadSettings(settings);
    
    printHelp();
    outer:
    while (true){
        writef("please enter what you want to do: ");
        string user_input = std.string.strip(readln());

        import std.array: replicate;
        switch (user_input) {
            case "q", "quit":
                writeln(replicate("\&mdash;",MDASHCOUNT));
                break outer;
            case "h", "help":
                printHelp();
                writeln(replicate("\&mdash;",MDASHCOUNT));
				break;
            case "cl", "clear":
                write("\x1b[2J\x1b[H");
                stdout.flush();
                break;
            case "ca" , "calculate":
                writeln("this is the list of all works");
                print_all(settings, false); // only print the names of the works
                write("please enter the number for the work: ");

                import std.conv: to;
                auto choice_ = to!int(std.string.strip(readln()));
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
                    foreach(name_, count_; currentWork["monjogs"].object)
                    {
                        uint ucount_ = count_.get!int; 
                        uint price = settings["codes"].object[name_].get!int;
                        writeln(name_,printSpaces(name_),ucount_,printSpaces(to!string(ucount_)) ,price);
                        monResults += price * ucount_/175;
                    }
                }
                else 
                    goto monjog_error;
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
                    import std.array: split;
                    import std.conv: to;
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
                break;
            case "pa", "print_all":
                print_all(settings);
                break;
            case "re", "reload":
                loadSettings(settings); 
                writeln("new settings loaded");
                writeln(replicate("\&mdash;",MDASHCOUNT));
                break;
            monjog_error:
            case "monjog-error":
                writeln("all works must have monjogs");
            default:
                writeln("what you entered is not valid: ", user_input);
                writeln(replicate("\&mdash;",MDASHCOUNT));
                break;
        }
    }
}
