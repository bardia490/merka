import std.stdio; 
import std.json;
import utilites;

class DataBaseManager
{
    JSONValue db;
    string dataBasePath = "./settings/works.json";
    
    this()
    {
        import std.file: readText, exists;
        if (exists(dataBasePath))
        {
            string contents = readText(dataBasePath);
            db = parseJSON(contents);
        }
        else
        {
            printSeperator();
            writeln(makeRed("there was no work file"));
            writeln(makeRed("using work template"));
            string contents = readText("settings/work_template.json");
            db = parseJSON(contents);
        }
        printSeperator();
    }
    void reload()
    {
        import std.file: readText, exists;
        string contents;
        if (exists(dataBasePath))
        {
            contents = readText(dataBasePath);
        }
        else
        {
            contents = readText("settings/work_template.json");
        }
        db = parseJSON(contents);
        printSeperator();
    }

    bool isDataBaseEmpty() // checks to see if the data base is empty or not
    {
        if("works" !in db)
            return true;
        if(db["works"] == JSONValue.emptyObject)
            return true;
        return false;
    }

    void printAll(bool complete = true)
    {
        if (isDataBaseEmpty)
        {
            writeln(makeRed("could not print the name of the works, the data base was empty"));
            printSeperator();
            return;
        }
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
            const float defaultPrice = db["codes"].object()["default"].get!float;
            foreach(monjog; work.object()["monjogs"].object.keys)
            {
                if (monjog in db["codes"]){
                    string monjogCount = to!string(work.object["monjogs"].object[monjog].integer);
                    float monjogPrice = db["codes"][monjog].get!float;
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
                    string materialCode = prettify!float(db["other_materials"][material].get!float);
                    writeln(material, printSpaces(material), materialCount,
                            printSpaces(materialCount),materialCode);
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

        if(isDataBaseEmpty)
        {
            writeln(makeRed("there was no work in the data base"));
            printSeperator();
            return false;
        }

        writeln("this is the list of all works");
        printAll(false); // only print the names of the works
        write("please enter the number for the work: ");

        auto workName = strip(readln());
        string[] workNames = db["works"].object.keys;

        if(checkVariable(workName, VARIABLE_CHECKER.INT, true)) // check if it is entered as number
        {
            workName = workNames[to!int(workName) - 1]; // convert to name
        }
        auto currentWorkRef = workName in db["works"];
        if (!currentWorkRef)
             return false;
        auto currentWork = *currentWorkRef;
        float monResults = 0; // price for monjogs
        float matResults = 0; // price for materials
        float tResults = 0; // the price for time
        float addResults = 0; // the price for additional costs
        float results = 0; // the final results
        float mulResults = 0; // the final results after multiplier

        if ("monjogs" in currentWork)
        {
            printMonjog(currentWork);
            float defaultPrice = db["codes"].object()["default"].get!float;
            foreach(name_, count_; currentWork["monjogs"].object)
            {
                float ucount_ = count_.get!float; 
                float temp = db["codes"].object[name_].get!float;
                float price;
                if (temp == -1.)
                    price = defaultPrice;
                else
                    price = temp;
                monResults += price * ucount_/175;
            }
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
                float price = db["other_materials"].object[name_].get!float;
                matResults += price * ucount_;
            }
        }

        if ("additional_costs" in db)
        {
            addResults = db["additional_costs"].object["price"].get!float;
            writeln(printSpaces("addition", SPACING), "\x1b[3;31mADDITIONAL COSTS\x1b[23;0m");
            writeln("price",printSpaces("price"), prettify!float(addResults));
        }

        // calculating the time
        float timePrice = db["time"].object["price"].get!float;
        tResults = calcTime(timePrice);

        // finalizing the reults
        results = monResults + matResults + tResults + addResults;

        // checking for discount
        printSeperator();
        write("do you want to increase (or decrease) the results by a % (if not you can enter 0 or ENTER, e.g. 25 or 125): ");
        uint multValue; // the multiplier
DISCOUNT:
        try
        {
            string choice = strip(readln());
            if(choice.length != 0)
            {
                multValue = to!uint(choice);
                if (multValue <= 100)
                    mulResults = (100-multValue) * results / 100;
                else
                    mulResults = multValue * results / 100;
            }
            else
            {
                mulResults = results;
            }
        }
        catch(Exception)
        {
            writeln("please enter a number!");
            goto DISCOUNT;
        }

        printSeperator();
        writeln("\x1b[38;5;146mthe final price for monjogs was: ", prettify!float(monResults));
        writeln("\x1b[38;5;225mthe final price for materials was: ", prettify!float(matResults));
        writeln("\x1b[38;5;225mthe final price for additional costs was: ", prettify!float(addResults));
        writeln("\x1b[38;5;225mthe final price for time was: ", prettify!float(tResults));
        writeln("\x1b[38;5;225mthe discount value was: ", multValue);
        writeln("\x1b[38;5;134mthe price (whithout discount) is: ", prettify!float(results), "\x1b[0m");
        writeln("\x1b[38;5;134mthe final price (after discount) is: ", prettify!float(mulResults), "\x1b[0m");
        printSeperator();
        return true;
    }

    void addWork()
    {
        import std.string;
        import std.conv: to;
        printSeperator();

        string workName = "";
        while(true) // get the name
        {
            write("please enter the name of the work: ");
            workName = strip(readln());
            if (workName.length != 0)
                break;
            writeln("work name cannot be empty");
        }

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
                        db["codes"][code] = to!float(price);
                    writeln("-------------------------");
                }
            }
        }
        printSeperator();
        write("do you want to add new materials (such as aviz) to work ", workName, " (y/n): ");
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
                        while(true)
                        {
                            write("please enter the ", makeRed("price")," for ", material, ": ");
                            auto price = strip(readln());
                            if (checkVariable(price, VARIABLE_CHECKER.INT) || checkVariable(price, VARIABLE_CHECKER.FLOAT))
                            {
                                db["other_materials"][material] = to!float(price);
                                break;
                            }
                        }
                    }
                }
            }
        }
        import std.file: write;
        write("settings/works.json",db.toPrettyString());
        printSeperator();
    }

    void removeWork()
    {
        import std.string: strip;
        import std.conv: to;

        printSeperator();
        if(isDataBaseEmpty)
        {
            writeln(makeRed("there was no work in the data base"));
            printSeperator();
            return;
        }

        printAll(false);
        write("please enter the name of the work that you want to ", makeRed("remove"), ": ");
        string workName = strip(readln());
        string[] workNames = db["works"].object().keys();

        if(checkVariable(workName, VARIABLE_CHECKER.INT, true)) // check if it is entered as number
            workName = workNames[to!int(workName) - 1]; // convert to name

        if (workName in db["works"])
        {
            db["works"].object().remove(workName);
            writeln("[INFO]: WORK WAS REMOVED SUCCESSFULLY");
            import std.file: write;
            write("settings/works.json",db.toPrettyString());
            writeln("[INFO]: WORKS.JSON FILE WAS UPDATED SUCCESSFULLY");
            printSeperator();
        }
        else
        {
            writeln("sorry ", makeRed(workName), " wasn't found in the data base");
            printSeperator();
        }
    }
    void edit()
    {
        import std.conv: to;
        import std.string: strip;

        JSONValue item = db;
        JSONValue previousItem = null;
        int previousKey;
        bool workNameFlag = false;
        string choice;
        printSeperator();
        while(true)
        {
            writeln("available options: ");
            auto options = item.object;
            foreach(i, v; options.keys)
                writeln(i+1, ": ", v);
            write("what do you want to edit (press ENTER for exit): ");
            choice = strip(readln());
            if (choice.length == 0)
            {
                printSeperator;
                return;
            }
            if (checkVariable(choice,VARIABLE_CHECKER.INTEGER, true))
            {
                previousItem = item;
                previousKey = to!int(choice)-1;
                item = options[options.keys[previousKey]];
                if (options.keys[to!int(choice)-1] == "works")
                {
                    write("do you want to change the name of one the " ~ makeBlue("works") ~ " (y/n): ");
                    choice = strip(readln());
                    if (choice == "y" || choice == "Y")
                    {
                        workNameFlag = true;
                        break; // going to change the name of one the works
                    }
                }
            }
            else
            {
                if (choice !in options)
                {
                    writeln(makeRed(choice ~ " was not found in the database"));
                    printSeperator;
                    continue;
                }
                previousItem = item;
                item = options[choice];
                if (choice == "works")
                {
                    write("do you want to change the name of one the " ~ makeBlue("works") ~ " (y/n): ");
                    auto dummyChoice = strip(readln());
                    if (dummyChoice == "y" || dummyChoice == "Y")
                    {
                        workNameFlag = true;
                        break; // going to change the name of one the works
                    }
                }
            }
            if (item.type == JSONType.object)
            {
                writeln("it is an object");
                if (item.object.keys.length == 0)
                {
                    if (checkVariable(choice,VARIABLE_CHECKER.INTEGER, true))
                        write(makeRed(options.keys[to!int(choice)-1]));
                    else
                        write(makeRed(choice));
                    writeln(" was empty");
                    printSeperator();
                    previousItem = null;
                    item = db;
                    continue;
                }
                else if (item.object.keys.length == 1 && item.object.keys[0] != "monjogs") // only break if the item only had one value and its not monjogs
                break;
            }
            else 
            {
                break;
            }
        }
        if (workNameFlag == true)
        {
            if (db["works"] == JSONValue.emptyObject || "works" !in db)
            {
                writeln(makeRed("there was no work in the data base"));
                printSeperator;
                return;
            }
            while (true)
            {
                writeln("these are the name of the works:");
                printAll(false);
                writeln("which name do you want to change:");
                choice = strip(readln());
                auto workNames = db["works"].object;
                if (checkVariable(choice,VARIABLE_CHECKER.INTEGER, true))
                    choice = workNames.keys[to!int(choice)-1];
                else
                {
                    if (choice !in workNames)
                    {
                        writeln(makeRed(choice ~ " was not found in the database"));
                        printSeperator;
                        continue;
                    }
                }
                break;
            }
            write("what do you want to change " ~ makeBlue(choice) ~ " to: ");
            string previousName = choice;
            choice = strip(readln());
            db["works"][choice] = db["works"][previousName];
            db["works"].object.remove(previousName);
            import std.file: write;
            write("settings/works.json",db.toPrettyString());
            printSeperator();
            return;
        }
        else if (item.type == JSONType.object)
        {
            string key = item.object.keys[0];
            writeln("the value for ", makeBlue(key), " is: ", item[key]);
            while(true)
            {
                write("what do you want to change it to: ");
                choice = strip(readln);
                if (checkVariable (choice, VARIABLE_CHECKER.INTEGER))
                {
                    item[key] = to!int (choice);
                    writeln ("value changed successfully");
                    printSeperator();
                    break;
                }
            }
        }
        else
        {
            writeln(previousKey);
            writeln("the value for ", makeBlue(previousItem.object.keys[previousKey]), " is: ", previousItem[previousItem.object.keys[previousKey]]);
            while(true)
            {
                write("what do you want to change it to: ");
                choice = strip(readln);
                if (checkVariable (choice, VARIABLE_CHECKER.INTEGER))
                {
                    previousItem[previousItem.object.keys[previousKey]] = to!int (choice);
                    writeln ("value changed successfully");
                    printSeperator();
                    break;
                }
            }
        }
        import std.file: write;
        write("settings/works.json",db.toPrettyString());
    }
}
