import std.stdio;
import core.stdc.stdlib: exit;
import utilites: printSeperator, makeRed;

// a class for managaing different app states
class APPManager
{
    this()
    {}

    enum UPDATE_STATUS
    {
        SUCCESS,
        FAILED,
        GIT_FAILED,
        AHEAD,
        NO_UPDATE,
    }

    // uses git fetch to check for updates in the main repo 
    // and if it is behined it will pull the latest changes and rebuilds the app
    // returns SUCCESS if update was succesfull
    // returns FALIED if something went wrong with the build sysyem
    // returns GIT_FALIED if something went wrong with GIT
    // returns NO_UPDATE if there was no update
    // returns AHEAD if the the branch was ahead
    UPDATE_STATUS update()
    {
        import std.process: executeShell, execute;
        writeln("checking for updates ...");

        printSeperator();

        auto fetchStatus = executeShell("git fetch");
        if(fetchStatus.status != 0)
            return UPDATE_STATUS.GIT_FAILED;

        auto commitBehind = executeShell("git rev-list --count HEAD..origin/main");
        auto commitAhead = executeShell("git rev-list --count origin/main..HEAD");

        if(commitBehind.status != 0 || commitAhead.status != 0)
            return UPDATE_STATUS.GIT_FAILED;

        if(commitBehind.output != "0\n")
        {
            writeln("new updates are available");
            writeln("downloading new updates");
            auto pullStatus = executeShell("git pull");
            if (pullStatus.status != 0)
                return UPDATE_STATUS.GIT_FAILED;
            writeln("download complete");
            writeln("rebuilding the app");
            auto buildOutput = executeShell("dub build");
            if (buildOutput.status != 0)
                return UPDATE_STATUS.FAILED;
        }

        if(commitAhead.output != "0\n")
            return UPDATE_STATUS.AHEAD;
        if(commitAhead.output == "0\n" && commitBehind.output == "0\n")
            return UPDATE_STATUS.NO_UPDATE; 
        return UPDATE_STATUS.SUCCESS;
    }
}

void reportUpdate(APPManager.UPDATE_STATUS us)
{
    final switch (us)
    {
        case APPManager.UPDATE_STATUS.SUCCESS:
            writeln("app built succesfully");
            writeln("update complete!");
            writeln("please close and open the app again for newer version");
            break;
        case APPManager.UPDATE_STATUS.FAILED:
            writeln("Compilation failed");
            writeln("update failed!");
            break;
        case APPManager.UPDATE_STATUS.GIT_FAILED:
            writeln("something went wrong with git");
            break;
        case APPManager.UPDATE_STATUS.AHEAD:
            writeln("ahead of the main branch please push to the main repository!");
            break;
        case APPManager.UPDATE_STATUS.NO_UPDATE:
            writeln("everything is up to date");
            break;
    }
}
