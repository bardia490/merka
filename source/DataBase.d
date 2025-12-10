import std.stdio; 
import std.json;
import utilites;
import std.conv: to;
import std.string: strip;

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

    void printWork() // for print_work option in main
    {
        string[] workNames = db["works"].object.keys;
        printWork(choseOption(workNames));
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
        printWorkTime(work);
    }

    void printMonjog(in JSONValue work)
    {
        if ("monjogs" in work)
        {
            printSeperator();
            writeln(printSpaces("mon", SPACING), "\x1b[3;31mMONJOGS\x1b[23;0m");
            writeln("monjog",printSpaces("monjog"),"count", printSpaces("count"), "price");
            const float defaultPrice = db["codes"].object()["default"].get!float;
            foreach(monjog; work.object()["monjogs"].object.keys)
            {
                if (monjog in db["codes"]){
                    string monjogCount = prettify!int(to!uint(work.object["monjogs"].object[monjog].get!float));
                    float monjogPrice = db["codes"][monjog].get!float;
                    if (monjogPrice == -1)
                        monjogPrice = defaultPrice;
                    writeln(monjog,printSpaces(monjog),monjogCount,printSpaces(monjogCount) ,prettify(to!uint(monjogPrice)));
                }
                else 
                    writeln("\x1b[39;31m", monjog, " \x1b[39m is not part of the \"codes\" group 
                    in the \"",dataBasePath,"\" file");
            }
            printSeperator(); 
        }
    }

    void printMaterials(in JSONValue work)
    {
        if ("materials" in work)
        {
            writeln(printSpaces("mate", SPACING), "\x1b[3;31mMATERIALS\x1b[23;0m");
            writeln("material",printSpaces("material"),"count",printSpaces("count"),"price");
            foreach(material; work.object["materials"].object.keys)
            {
                if (material in db["other_materials"]) 
                {
                    auto materialCount = prettify!int (to!uint(work["materials"].object[material].get!float));
                    string materialPrice = prettify!float(to!uint(db["other_materials"][material].get!float));
                    writeln(material, printSpaces(material), materialCount,
                            printSpaces(materialCount),materialPrice);
                }
                else 
                    writeln("\x1b[39;31m", material, " \x1b[39m is not part of the \"other_materials\"
                            group in the ", dataBasePath," file");

            }
            printSeperator();
        }
    }

    void printWorkTime(in JSONValue work)
    {
        if ("time" in work)
        {
            writeln(printSpaces("ti", SPACING), "\x1b[3;31mTime\x1b[23;0m");
            writeln("minutes",printSpaces("minutes"),"hours",printSpaces("hours"),"price");
            auto hours = work["time"].get!float;
            auto stringHours = prettify!float(hours);
            auto stringMinutes = prettify!int(to!uint(hours*60));
            string timePrice = prettify!float(to!uint(db["time"]["price"].get!float * hours));
            writeln(stringMinutes, printSpaces(stringMinutes), stringHours,
                    printSpaces(stringHours), timePrice);
            printSeperator();
        }
    }

    bool calculateWork()
    {
        import std.array: split, replicate;

        if(isDataBaseEmpty)
        {
            writeln(makeRed("there was no work in the data base"));
            printSeperator();
            return false;
        }

        writeln("this is the list of all the works");

        string[] workNames = db["works"].object.keys;
        auto workName = choseOption(workNames, "Please choose on of the works below"); // returns the work name as string

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
            foreach(name_, count_; currentWork["materials"].object)
            {
                float ucount_ = count_.get!float;
                float price = db["other_materials"].object[name_].get!float;
                matResults += price * ucount_;
            }
        }

        if ("additional_costs" in db)
        {
            addResults = db["additional_costs"].object["price"].get!float;
            writeln(printSpaces("addition", SPACING), "\x1b[3;31mADDITIONAL COSTS\x1b[23;0m");
            writeln("price",printSpaces("price"), prettify!float(addResults));
            printSeperator();
        }

        // calculating the time
        float timePrice = db["time"].object["price"].get!float;
        if ("time" in currentWork) // if time is already set
        {
            printWorkTime(currentWork);
            tResults = currentWork["time"].get!float * timePrice;
        }
        else
            tResults = calcTime(timePrice);

        // finalizing the reults
        results = monResults + matResults + tResults + addResults;

        // checking for discount
        write("do you want to multiply the results by a value
                (if not you can enter 0 or ENTER, e.g. 1.25 or 0.75): ");
        string choice = strip(readln());
        uint multValue;
        if(choice.length != 0)
        {
            if (checkVariable(choice, VARIABLE_CHECKER.INT))
                multValue = to!uint(choice);
            mulResults = multValue * results;
        }
        else
        {
            mulResults = results;
        }

        printSeperator();
        writeln("\x1b[38;5;146mthe final price for monjogs was: ", prettify(to!uint(monResults)));
        writeln("\x1b[38;5;225mthe final price for materials was: ", prettify(to!int(matResults)));
        writeln("\x1b[38;5;225mthe final price for additional costs was: ", prettify(to!int(addResults)));
        writeln("\x1b[38;5;225mthe final price for time was: ", prettify(to!int(tResults)));
        writeln("\x1b[38;5;225mthe discount value was: ", multValue);
        writeln("\x1b[38;5;134mthe price (without discount) is: ", prettify(to!int(results)), "\x1b[0m");
        writeln("\x1b[38;5;134mthe final price (after discount) is: ", prettify(to!int(mulResults)), "\x1b[0m");
        printSeperator();
        return true;
    }


    void addWork()
    {
        import std.string;
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

        db["works"][workName] = JSONValue.emptyObject;
        db["works"][workName]["monjogs"] = JSONValue.emptyObject;
        auto currentWorkMonjogs = "monjogs" in db["works"][workName].object();
        while(true)
        {
            write("please enter the (next) monjog code(s) or press Enter to finish adding monjogs: ");

            import std.array: split;
            auto codes = split(strip(readln()));

            if (!codes.length) break;

            foreach(code; codes)
            {
                write("please enter the ",makeBlue("number")," of monjogs for code ", code, ": ");
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
                    write("please enter the ", makeBlue("number"), " of monjogs for code ", code, ": ");
                }
                writeln("-------------------------");
                if (code !in db["codes"])
                {
                    write("please enter the ", makeBlue("price"), " for ", code ," monjog (press Enter for default): ");
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
        printSeperator();
        write("do you want to set time for ", workName, " (ENTER for NO, h to also see time help): ");
        string answer = strip(readln());
        if (answer == "h" || answer == "help")
        {
            db["works"].object()[workName].object()["time"] = getTime(); // stores time as hour (float)
        }
        else if (answer != "")
        {
            db["works"].object()[workName].object()["time"] = getTime(false, answer); // stores time as hour (float)
        }
        import std.file: write;
        write("settings/works.json",db.toPrettyString());
        writeln("WORK ADDED SUCCESFULLY");
        printSeperator();
    }

    void removeWork()
    {

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
    string choseOption(string[] options, string question = "")
     // for chosing the options, it can use indexes and values and doesn't stop until you enter the right value, question is what you want to be asked before asking for a option
     // returns the value in the list
    {
        import std.array: replicate;

        import std.algorithm.searching: canFind;
        while (true)
        {
            write("\x1b[38;5;166m");
            writeln(replicate("<>", MDASHCOUNT/2));
            write("\x1b[38;5;231m");
            writeln(question);
            foreach(index, option; options)
                writeln(index+1, ": ", option);
            write("> ");
            string choice = strip(readln());
            if (checkVariable(choice,VARIABLE_CHECKER.INTEGER, true))
            {
                auto key = to!int(choice);
                if (key-1 >= 0 && key -1 < options.length)
                {
                    write("\x1b[38;5;166m");
                    writeln(replicate("<>", MDASHCOUNT/2));
                    write("\x1b[38;5;231m");
                    return options[key - 1];
                }
            }
            if (canFind(options, choice))
                return choice;
            writeln(makeRed("please enter a valid option inside this range:"));
        }
    }

    long choseOptionIndex(string[] options) 
     // for chosing the options, it can use indexes and values and doesn't stop until you enter the right value
     // returns the index of the option in the list
    {
        import std.algorithm.searching: countUntil;
        while (true)
        {
            foreach(index, option; options)
                writeln(index+1, ": ", option);
            write("> ");
            string choice = strip(readln());
            if (checkVariable(choice,VARIABLE_CHECKER.INTEGER, true))
            {
                auto key = to!long(choice);
                if (key-1 >= 0 && key -1 < options.length)
                    return key - 1;
            }
            auto step = countUntil(options, choice);
            if (step)
                return step;
            writeln(makeRed("please enter a valid option inside this range:"));
        }
    }
    void updateJSONValue(ref JSONValue jsonval, in float defaultValue = 0)
    {
        while(true)
        {
            write("what do you want to change it to: (ENTER for default)");
            string choice = strip(readln());
            if (choice == "")
            {
                if (defaultValue != 0)
                {
                    jsonval = defaultValue;
                    break;
                }
                else
                    continue;
            }
            if (checkVariable (choice, VARIABLE_CHECKER.INTEGER, true) || checkVariable (choice, VARIABLE_CHECKER.FLOAT, true))
            {
               jsonval = to!float(choice);
               break;
            }
            writeln(makeRed("please enter a Number"));
        }
    }
    void changeJSONObjectName(ref JSONValue jsonval, string previousName) // , string lastName, string newName
    {
        while(true)
        {
            write("what do you want to change it to: ");
            string choice = strip(readln());
            if (choice != "")
            {
                JSONValue dummyVar = jsonval[previousName];
                jsonval.object.remove(previousName);
                jsonval[choice] = dummyVar;
                break;
            }
            writeln(makeRed("please enter something"));
        }
    }
    void edit()
    {
        writeln("what do you want to change:");
        string[] options = ["time",
                            "additional_costs",
                            "codes",
                            "other_materials",
                            "workName",
                            "changeMaterial",
                            "changeMonjogs"];
        string[] longOptions = ["change the price for each hour",
                                "change the additional costs",
                                "change the price for a monjog",
                                "change the price of some material",
                                "change the name of a work",
                                "change something about materials in a work",
                                "change something about monjogs in a work"];
        string option = options[choseOptionIndex(longOptions)];

        final switch (option)
        {
            case "time", "additional_costs", "codes", "other_materials":
                if (!changePriceSettins(option))
                    return;
                break;
            case "workName", "changeMaterial", "changeMonjogs":
                if (!changeWorkSettins(option))
                    return;
                break;
        }
        import std.file: write;
        write("settings/works.json",db.toPrettyString());
        writeln("operation was succesfull");
        printSeperator();
    }
    bool changePriceSettins(string s) // s has to either be time or additional_costs
    {
        if (s != "time" && s != "additional_costs" && s != "codes" && s != "other_materials")
        {
            writeln(makeRed("not the right argument for price function"));
            writeln("aborting operation");
            printSeperator();
            return false;
        }
        string option;
        float defaultValue = 0;
        final switch(s)
        {
            case "time", "additional_costs":
                option = "price";
                writeln("the current ", makeBlue("price") ," set for ",s ," is: ", makeBlue(prettify!float(db[s]["price"].get!float)));
                break;
            case "codes", "other_materials":
                printSeperator();
                option = choseOption(db[s].object.keys, "please chose one of the below items");
                writeln("the current ", makeBlue("price") ," set for ", makeBlue(option) ," is: ", makeBlue(prettify!float(db[s][option].get!float)));
                break;
        }
        if (s == "codes")
            defaultValue = db["codes"]["default"].get!float ;
        updateJSONValue(db[s][option]);
        return true;
    }
    bool changeWorkSettins(string s) // s has to either be either workName or changeMaterial or changeMonjogs
    {
        if (s != "workName" && s != "changeMaterial" && s != "changeMonjogs")
        {
            writeln(makeRed("not the right argument for the work function"));
            writeln("aborting operation");
            printSeperator();
            return false;
        }
        
        printSeperator();
        string option = choseOption(db["works"].object.keys, "please chose a work");
        final switch(s)
        {
            case "workName":
                changeJSONObjectName(db["works"], option);
                break;
            case "changeMaterial":
                if ("materials" !in db["works"][option])
                {
                    writeln("sorry this work doesn't have any materials");
                    printSeperator();
                    return false;
                }
                printSeperator();
                writeln("please chose one of the below options");
                string[2] options = ["materialCount", "materialName"];
                string[2] longOptions = ["change the number of some material in this work",
                                         "change the name of some material in this work"];
                string newOption = options[choseOptionIndex(longOptions)];
                string name = choseOption(db["works"][option]["materials"].object.keys, "which material:");
                if (newOption == "materialCount")
                {
                    writeln("the previous value is: ", makeBlue(prettify!float(db["works"][option]["materials"][name].get!float)));
                    updateJSONValue(db["works"][option]["materials"][name]);
                }
                if (newOption == "materialName")
                    changeJSONObjectName(db["works"][option]["materials"], name);
                break;
            case "changeMonjogs":
                printSeperator();
                writeln("please chose one of the below options");
                string[2] options = ["monjogCount", "monjogName"];
                string[2] longOptions = ["change the number of some monjog in this work",
                                         "change the name of some monjog in this work"];
                string newOption = options[choseOptionIndex(longOptions)];
                string name = choseOption(db["works"][option]["monjogs"].object.keys, "which monjog:");
                if (newOption == "monjogCount")
                {
                    writeln("the previous value is: ", makeBlue(prettify!float(db["works"][option]["monjogs"][name].get!float)));
                    updateJSONValue(db["works"][option]["monjogs"][name]);
                }
                if (newOption == "monjogName")
                    changeJSONObjectName(db["works"][option]["materials"], name);
                break;
        }
        return true;
    }
}
