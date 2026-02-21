module source.DataBase;

import std.stdio; 
import std.json;
import Lib.utilites.d;
import std.conv: to;
import std.string: strip;

class DataBaseManager
{
    JSONValue db;
    string dataBasePath = "./settings/works.json";
    bool autoUpdate = false;
    
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
        if ("auto-update" in db) autoUpdate = db["auto-update"].get!string != "off";
        else db["auto-update"] = "off";
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

    void updateDataBase(){
        import std.file: write;
        write("settings/works.json",db.toPrettyString());
        writeln("WORK ADDED SUCCESFULLY");
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

    void printAll(bool complete = true, string fileName = "")
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
        bool printToFile = fileName.length != 0;
        if (printToFile) {
            import std.format;
            string buf = "";
            float multValue = get_natural_default_answer!float("do you want to multiply the results by a value (if not you can press 1 or ENTER, e.g. 1.25 or 0.75):", 1., "THE VALUE MUST BE POSITIVE");
            buf ~= format("%=20s %=40s\n", "Name", "Price");
            foreach (work; works)
                createBuffer(work, buf, multValue);
            import std.file: write;
            import std.format;
            write!string(fileName, buf);
            printSeperator();
        } else {
            foreach (work; works)
                printWork(work);
        }
    }

    // creates a buffer for writing all the information about the works in a file called fileName
    void createBuffer(string workName, ref string buf, float multValue){
        import std.array: replicate;
        import std.format;
        // buf ~= replicate("<>", MDASHCOUNT/2) ~ workName ~ replicate("<>", MDASHCOUNT/2);
        float workPrice = calculateWork(workName, false, false, true, multValue, false);
        // buf ~= format("%s %=20s\n", workName, prettify(to!int(workPrice)));
        buf ~= format("%=20s %=40s\n", workName, workPrice);
    }

    void printWork(string workName = "")
    {
        if (isDataBaseEmpty())
        {
            writeln("no work was found in the database");
            printSeperator();
            return;
        }
        if (workName == "")
        {
            string[] workNames = db["works"].object.keys;
            workNames ~= "back";
            workName = choseOption(workNames, "please choose one of the below works", true);
            if (workName == "back")
            {
                printSeperator();
                return;
            }
        }
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

    // calculates the price for the works, if something goes wrong, return -1
    float calculateWork(string workName = "", bool complete = false,
            bool ignore_time = false, bool defaultMultiply = false,
            float defaultMultiplyValue = 1.3,
            bool printResults = true)
    {
        import std.array: split, replicate;

        if(isDataBaseEmpty)
        {
            writeln(makeRed("there was no work in the data base"));
            printSeperator();
            return -1;
        }

        if (workName == "")
        {
            writeln("this is the list of all the works");

            string[] workNames = db["works"].object.keys;
            workName = choseOption(workNames, "Please choose on of the works below", true); // returns the work name as string
        }

        auto currentWorkRef = workName in db["works"];
        if (!currentWorkRef)
             return -1;
        auto currentWork = *currentWorkRef;
        float monResults = 0; // price for monjogs
        float matResults = 0; // price for materials
        float tResults = 0; // the price for time
        float addResults = 0; // the price for additional costs
        float results = 0; // the final results
        float mulResults = 0; // the final results after multiplier

        if ("monjogs" in currentWork)
        {
            if (complete && printResults)
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
            return -1;
        if ("materials" in currentWork)
        {
            if (complete && printResults)
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
            if (complete && printResults)
            {
                writeln(printSpaces("addition", SPACING), "\x1b[3;31mADDITIONAL COSTS\x1b[23;0m");
                writeln("price",printSpaces("price"), prettify!float(addResults));
                printSeperator();
            }
        }

        // calculating the time
        float timePrice = db["time"].object["price"].get!float;
        if ("time" in currentWork) // if time is already set
        {
            if (complete && printResults)
                printWorkTime(currentWork);
            tResults = currentWork["time"].get!float * timePrice;
        }
        else
            if (!ignore_time){
                float duration = getTime();
                //tResults = calcTime(timePrice);
                // if the time wasn't set, set it now
                db["works"].object()[workName].object()["time"] = duration;
                tResults = duration * timePrice;
                if (autoUpdate) updateDataBase;
            }

        // finalizing the reults
        results = monResults + matResults + tResults + addResults;

        float multValue = 1; // the multiplier
        // checking for discount
        if (!defaultMultiply)
            multValue = get_natural_default_answer!float("do you want to multiply the results by a value (if not you can press 1 or ENTER, e.g. 1.25 or 0.75):", 1., "THE VALUE MUST BE POSITIVE");
        else
            multValue = defaultMultiplyValue;
        mulResults = multValue * results;
        if (complete && printResults)
        {
            printSeperator();
            writeln("\x1b[38;5;146mthe final price for monjogs was: ", prettify(to!uint(monResults)));
            writeln("\x1b[38;5;225mthe final price for materials was: ", prettify(to!int(matResults)));
            writeln("\x1b[38;5;225mthe final price for additional costs was: ", prettify(to!int(addResults)));
            writeln("\x1b[38;5;225mthe final price for time was: ", prettify(to!int(tResults)));
            writeln("\x1b[38;5;225mthe discount value was: ", multValue);
            writeln("\x1b[38;5;134mthe price (without discount) is: ", prettify(to!int(results)), "\x1b[0m");
            writeln("\x1b[38;5;134mthe final price (after discount) is: ", prettify(to!int(mulResults)), "\x1b[0m");
            printSeperator();
        }
        else if (printResults)
            writeln(mulResults);
        return mulResults;
    }

    void calculateAllWorkPrices(bool complete = false)
    {
        import std.array: replicate;

        if(isDataBaseEmpty)
        {
            writeln(makeRed("there was no work in the data base"));
            printSeperator();
        }

        import std.algorithm: sort;
        import std.algorithm.mutation: SwapStrategy;
        string[] workNames = db["works"].object.keys;
        workNames.sort!("a < b", SwapStrategy.stable);
        float multValue = get_natural_default_answer!float("do you want to multiply the results by a value (if not you can press 1 or ENTER, e.g. 1.25 or 0.75):", 1., "THE VALUE MUST BE POSITIVE");
        foreach(workName; workNames)
        {
            write("\x1b[38;5;166m");
            writeln(replicate("<>", MDASHCOUNT/2));
            write("\x1b[38;5;231m");
            write(workName, printSpaces(workName, 40));
            calculateWork(workName, complete, true, true, multValue);
            printSeperator();
        }
    }

    // adds new Monjogs to previously defined work, the caller needs to make sure the field materials exists in work
    void addMonjog(string workName)
    {
        if ("monjogs" !in db["works"][workName])
            db["works"][workName]["monjogs"] = JSONValue.emptyObject;
        bool entered_code = false;
        while(true)
        {
            write("please enter the (next) monjog code(s) or press Enter to finish adding monjogs: ");

            import std.array: split;
            auto codes = split(strip(readln()));

            if (!codes.length)
            {
                if (entered_code)
                    break;
                else
                {
                    writeln(makeRed("MONJOGS CANNOT BE EMPTY"));
                    continue;
                }
            }

            foreach(code; codes)
            {
                db["works"][workName]["monjogs"][code] = get_non_empty_positive_answer!uint("please enter the " ~
                                                                                            makeBlue("number")~
                                                                                            " of monjogs for code "~
                                                                                            code~":",
                                                                                            "NUMBER OF MONJOGS NEEDS TO BE POSITIVE");

                printSeperator();
                if (code !in db["codes"])
                {
                    db["codes"][code] = get_positive_default_answer!float("please enter the " ~
                                                                          makeBlue("price")~
                                                                          " for " ~
                                                                          code ~
                                                                          " monjog (press Enter for default):",
                                                                          -1.,
                                                                          "THE PRICE FOR MONJOGS CANNOT BE NEGATIVE");
                     
                    printSeperator();
                }
            }
            entered_code = true;
        }
    }

    // adds new Materials to previously defined work, the caller needs to make sure the field materials exists in work
    void addMaterial(string workName)
    {
        if ("materials" !in db["works"][workName])
            db["works"][workName]["materials"] = JSONValue.emptyObject;
        while(true)
        {
            write("please enter the material name(s) or press Enter to finish adding materials: ");

            import std.array: split;
            auto materialNames = split(strip(readln()));

            if (!materialNames.length) break;

            foreach(material; materialNames)
            {
                db["works"][workName]["materials"][material] = get_non_empty_positive_answer!uint("please enter the " ~
                                                                                                  makeBlue("number")~
                                                                                                  " of materials for "~
                                                                                                  makeBlue(material)~
                                                                                                  ":",
                                                                                                  "NUMBER OF MATERIALS NEEDS TO BE POSITIVE");

                if (material !in db["other_materials"])
                {
                    db["other_materials"][material] = get_non_empty_positive_answer!float("please enter the "~
                                                                                          makeRed("price")~" for " ~
                                                                                          makeBlue(material),
                                                                                          "THE PRICE FOR MATERIALS CANNOT BE NEGATIVE");
                    
                }
            }
        }
    }

    void addWork()
    {
        import std.string;

        string workName = getAnswer!string("please enter the " ~ makeBlue("name")~ 
                " of the work (can also press back):",
                (string s) {return s!="";}, (_) {return true;},
                "WORK NAME CANNOT BE EMPTY", true);

        if (workName == "back")
        {
            printSeperator();
            return;
        }
        db["works"][workName] = JSONValue.emptyObject;

        // adding monjogs
        db["works"][workName]["monjogs"] = JSONValue.emptyObject;
        addMonjog(workName);
        printSeperator();

        // adding materials
        db["works"].object()[workName].object()["materials"] = JSONValue.emptyObject;
        addMaterial(workName);
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

        string[] workNames = db["works"].object.keys;
        workNames ~= "back";
        string workName = choseOption(workNames,
                "please enter the name of the work that you want to " ~
                makeRed("remove") ~ ": ", true);
        if (workName == "back")
        {
            printSeperator();
            return;
        }
        db["works"].object().remove(workName);
        writeln(makeBlue("WORK WAS REMOVED SUCCESSFULLY"));
        import std.file: write;
        write("settings/works.json",db.toPrettyString());
        writeln(makeBlue("WORKS.JSON FILE WAS UPDATED SUCCESSFULLY"));
        printSeperator();
    }

    void updateJSONValue(ref JSONValue jsonval, in float defaultValue = 0)
    {
        if (defaultValue != 0)
               jsonval = get_positive_default_answer!float("what do you want to change it to (ENTER for default): ",
               defaultValue, makeRed("PLEASE ENTER A POSITIVE NUMBER"));
        else
               jsonval = get_non_empty_positive_answer!float("what do you want to change it to:",
                       makeRed("PLEASE ENTER A POSITIVE NUMBER"));
    }

    string changeJSONObjectName(ref JSONValue jsonval, string previousName)
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
                return choice;
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
                            "addMaterials",
                            "changeMaterial",
                            "addMonjogs",
                            "changeMonjogs",
                            "back"];
        string[] longOptions = ["change the price for each hour",
                                "change the additional costs",
                                "change the price for a monjog",
                                "change the price of some material",
                                "change the name of a work",
                                "add new materials to some work",
                                "change something about materials in a work",
                                "add new monjogs to some work",
                                "change something about monjogs in a work",
                                "step back from this function"];
        string option = options[choseOptionIndex(longOptions)];

        final switch (option)
        {
            case "time", "additional_costs", "codes", "other_materials":
                if (!changePriceSettins(option))
                    return;
                break;
            case "workName", "changeMaterial", "changeMonjogs", "addMaterials", "addMonjogs":
                if (!changeWorkSettins(option))
                    return;
                break;
            case "back":
                return;
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
                writeln("the current ", makeBlue("price") ,
                        " set for ",s ," is: ",
                        makeBlue(prettify!float(db[s]["price"].get!float)));
                break;
            case "codes", "other_materials":
                printSeperator();
                option = choseOption(db[s].object.keys, "please chose one of the below items");
                writeln("the current ", makeBlue("price") ,
                        " set for ", makeBlue(option) ,
                        " is: ", makeBlue(prettify!float(db[s][option].get!float)));
                break;
        }
        if (s == "codes")
            defaultValue = db["codes"]["default"].get!float;
        updateJSONValue(db[s][option], defaultValue);
        return true;
    }

    bool changeWorkSettins(string s) // s has to either be either workName or changeMaterial or changeMonjogs or addMonjogs or addMaterials
    {
        if (s != "workName" && s != "changeMaterial" && s != "changeMonjogs" && s != "addMonjogs" && s != "addMaterials")
        {
            writeln(makeRed("not the right argument for the work function"));
            writeln("aborting operation");
            printSeperator();
            return false;
        }
        
        printSeperator();
        string option = choseOption(db["works"].object.keys, "please chose a work", true);
        final switch(s)
        {
            case "workName":
                changeJSONObjectName(db["works"], option);
                break;
            case "addMaterials":
                addMaterial(option);
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
                string name = choseOption(db["works"][option]["materials"].object.keys, "which material:", true);
                if (name == "")
                {
                    writeln("sorry no materials were found in this work");
                    break;
                }
                if (newOption == "materialCount")
                {
                    writeln("the previous value is: ",
                            makeBlue(prettify!float(db["works"][option]["materials"][name].get!float)));
                    updateJSONValue(db["works"][option]["materials"][name]);
                }
                if (newOption == "materialName")
                {
                    string newName = changeJSONObjectName(db["works"][option]["materials"], name);
                    if (newName !in db["other_materials"])
                        db["other_materials"][newName] = get_non_empty_positive_answer!float("please enter a price for this material: ",
                                makeRed("price cannot be empty or negative"));
                }
                break;
            case "addMonjogs":
                addMonjog(option);
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
                {
                    string newName = changeJSONObjectName(db["works"][option]["monjogs"], name);
                    if (newName !in db["codes"])
                        db["codes"][newName] = get_positive_default_answer!float("please enter a price for this monjog (ENTER for default): ", db["codes"]["default"].get!float, makeRed("PLEASE ENTER A NON EMPTY, POSITIVE ANSWER, FOR DEFAULT JUST PRESS ENTER"));
                }
                break;
        }
        return true;
    }
}
