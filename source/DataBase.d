import std.stdio; 
import std.json;
import utilites;

class DataBaseManager
{
    JSONValue db;
    string dataBasePath = "./settings/works.json";
    
    this()
    {
        import std.file: readText;
        string contents = readText(dataBasePath);
        db = parseJSON(contents);
    }
    void reload()
    {
        import std.file: readText;
        string contents = readText(dataBasePath);
        db = parseJSON(contents);
    }
    void printAll(bool complete = true)
    {
        import std.array: replicate;
        if (!complete)
        {
            write("\x1b[38;5;166m");
            writeln(replicate("<>", MDASHCOUNT/2));
            write("\x1b[38;5;231m");
            foreach (index_, work; db["works"].object.keys)
            {
                writeln(index_+1,": \x1b[1m",work, "\x1b[22m");
            }
            writeln("\x1b[38;5;166m",replicate("<>", MDASHCOUNT/2), "\x1b[0m");
            return;
        }
        auto works = db["works"].object.keys(); 
        foreach (work; works)
            printWork(work);
    }
    void printWork(string workName)
    {
        import std.array: replicate;
        JSONValue work = db["works"][workName];
        writeln("\x1b[0;34m", replicate("<>", MDASHCOUNT/2), "\x1b[0m");
        writeln("\x1b[1m",workName, "\x1b[22m");
        writeln("\x1b[0;34m",replicate("<>", MDASHCOUNT/2), "\x1b[0;34m");
        printMonjog(work);
        printMaterials(work);
    }
    void printMonjog(in JSONValue work)
    {
        import std.conv: to;
        if ("monjogs" in work)
        {
            printSeperator();
            writeln(printSpaces("mon", SPACING), "\x1b[3;31mMONJOGS\x1b[23;0m");
            writeln("monjog",printSpaces("monjog"),"count", printSpaces("count"), "price");
            const int defaultPrice = to!int(db["codes"].object()["default"].integer);
            foreach(monjog; work.object()["monjogs"].object.keys)
            {
                if (monjog in db["codes"]){
                    string monjogCount = to!string(work.object["monjogs"].object[monjog].integer);
                    int monjogPrice = to!int(db["codes"][monjog].integer);
                    if (monjogPrice == -1)
                        monjogPrice = defaultPrice;
                    writeln(monjog,printSpaces(monjog),monjogCount,printSpaces(monjogCount) ,prettify(monjogPrice));
                }
                else 
                    writeln("\x1b[39;31m", monjog, " \x1b[39m is not part of the \"codes\" group 
                    in the \"",dataBasePath,"\" file");
            }
        }
    }
    void printMaterials(in JSONValue work)
    {
        import std.conv: to;
        if ("materials" in work)
        {
            printSeperator(); 
            writeln(printSpaces("mate", SPACING), "\x1b[3;31mMATERIALS\x1b[23;0m");
            writeln("material",printSpaces("material"),"count",printSpaces("count"),"price");
            foreach(material; work.object["materials"].object.keys)
            {
                if (material in db["other_materials"]) 
                {
                    auto materialCount = to!string (work["materials"].object[material].integer);
                    const int materialCode = to!int(db["other_materials"][material].integer);
                    writeln(material, printSpaces(material), materialCount,
                            printSpaces(materialCount),prettify(materialCode));
                }
                else 
                    writeln("\x1b[39;31m", material, " \x1b[39m is not part of the \"other_materials\"
                            group in the ", dataBasePath," file");

            }
        }
        printSeperator();
    }

    bool calculateWork()
    {
        import std.array: split, replicate;
        import std.conv: to;
        import std.string: strip;

        writeln("this is the list of all works");
        printAll(false); // only print the names of the works
        write("please enter the number for the work: ");

        auto choice_ = to!int(strip(readln()));
        auto works = db["works"].object.keys; 
        auto currentWork = db["works"].object[works[choice_-1]];
        // writeln("the work is: ",works[choice_-1]);

        ulong monResults = 0; // price for monjogs
        ulong matResults = 0; // price for materials
        ulong tResults = 0; // the price for time
        uint addResults = 0; // the price for additional costs
        ulong results = 0; // the final results
        ulong mulResults = 0; // the final results after multiplier

        if ("monjogs" in currentWork)
        {
            printMonjog(currentWork);
            float defaultPrice = to!float(db["codes"].object()["default"].integer);
            float tempResults = 0;
            foreach(name_, count_; currentWork["monjogs"].object)
            {
                float ucount_ = to!float(count_.get!int); 
                float temp = to!float(db["codes"].object[name_].get!int);
                float price;
                if (temp == -1)
                    price = defaultPrice;
                else
                    price = temp;
                tempResults += price * ucount_/175;
            }
            monResults = to!uint(tempResults);
        }
        else 
            return false;
        if ("materials" in currentWork)
        {
            printMaterials(currentWork);
            // float defaultPrice = to!float(db["codes"].object()["default"].integer);
            foreach(name_, count_; currentWork["materials"].object)
            {
                uint ucount_ = count_.get!int; 
                uint price = db["other_materials"].object[name_].get!int;
                matResults += price * ucount_;
            }
        }

        if ("additional_costs" in db)
        {
            addResults = db["additional_costs"].object["price"].get!int;
            writeln(printSpaces("addition", SPACING), "\x1b[3;31mADDITIONAL COSTS\x1b[23;0m");
            writeln("price",printSpaces("price"), prettify(to!int(addResults)));
        }

        // calculating the time
        uint timePrice = db["time"].object["price"].get!int;
        tResults = calcTime(timePrice);

        // finalizing the reults
        results = monResults + matResults + tResults + addResults;
        // checking for discount
        writeln(replicate("\&mdash;",MDASHCOUNT));
        write("do you want to increase (or decrease) the results by a % (if not you can enter 0, e.g. 25 or 125): ");
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
        writeln("\x1b[38;5;146mthe final price for monjogs was: ", prettify(to!int(monResults)));
        writeln("\x1b[38;5;225mthe final price for materials was: ", prettify(to!int(matResults)));
        writeln("\x1b[38;5;225mthe final price for additional costs was: ", prettify(to!int(addResults)));
        writeln("\x1b[38;5;225mthe final price for time was: ", prettify(to!int(tResults)));
        writeln("\x1b[38;5;225mthe discount value was: ", multValue);
        writeln("\x1b[38;5;134mthe price (whithout discount) is: ", prettify(to!int(results)), "\x1b[0m");
        writeln("\x1b[38;5;134mthe final price (after discount) is: ", prettify(to!int(mulResults)), "\x1b[0m");
        writeln(replicate("\&mdash;",MDASHCOUNT)); 
        return true;
    }

    void addWork()
    {
        import std.string;
        import std.conv: to;
        printSeperator();
        write("please enter the name of the work: ");
        string workName = strip(readln());
        db["works"].object()[workName] = JSONValue.emptyObject;
        db["works"].object()[workName].object()["monjogs"] = JSONValue.emptyObject;
        auto currentWorkMonjogs = "monjogs" in db["works"].object()[workName].object();
        while(true)
        {
            write("please enter the (next) monjog code(s) or press Enter to finish adding monjogs: ");

            import std.array: split;
            auto codes = split(strip(readln()));

            if (!codes.length) break;

            foreach(code; codes)
            {
                write("please enter the ",makeRed("number")," of monjogs for code ", code, ": ");
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
                    write("please enter the ", makeRed("number"), " of monjogs for code ", code, ": ");
                }
                writeln("-------------------------");
                if (code !in db["codes"])
                {
                    write("please enter the ", makeRed("price"), " for ", code ," monjog (press Enter for default): ");
                    auto price = strip(readln());
                    if (!price.length) 
                        db["codes"][code] = -1;
                    else
                        db["codes"][code] = to!int(price);
                    writeln("-------------------------");
                }
            }
        }
        printSeperator();
        write("do you want to add new materials (such as aviz) to work: ", workName, ":(y/n) ");
        auto answer = strip(readln());
        if (answer == "y" || answer == "yes")
        {
            db["works"].object()[workName].object()["materials"] = JSONValue.emptyObject;
            auto currentWorkMaterials = "materials" in db["works"].object()[workName].object(); // for storing the new materials

            while(true)
            {
                write("please enter the material name(s) or press Enter to finish adding materials: ");

                import std.array: split;
                auto materialNames = split(strip(readln()));

                if (!materialNames.length) break;

                foreach(material; materialNames)
                {
                    write("please enter the ", makeRed("number"), " of ", material, ": ");
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
                        write("please enter the ", makeRed("amount"), " of material for ", material, ": ");
                    }
                    if (material !in db["other_materials"])
                    {
                        write("please enter the ", makeRed("price")," for ", material);
                        auto price = strip(readln());
                        //if (!price.length)
                        //    db["other_materials"][material] = -1;
                        //else
                        checkVariable(price, VARIABLE_CHECKER.INT);
                        db["other_materials"][material] = to!int(price);
                    }
                }
            }
        }
        import std.file: write;
        write("settings/works.json",db.toPrettyString());
    }
}
