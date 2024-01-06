state("TheLostCrown") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Prince of Persia: The Lost Crown";
    vars.Helper.LoadSceneManager = true;
    // vars.Helper.Settings.CreateFromXml("Components/TEMPLATE.Settings.xml");

    vars.Watch = (Action<IDictionary<string, object>, IDictionary<string, object>, string>)((oldLookup, currentLookup, key) => 
    {
        var oldValue = oldLookup[key];
        var currentValue = currentLookup[key];
        if (!oldValue.Equals(currentValue))
            vars.Log(key + ": " + oldValue + " -> " + currentValue);
    });

    vars.CompletedSplits = new HashSet<string>();
    
    // vars.Helper.AlertLoadless();
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        // asl-help has this issue where sometimes offsets resolve to 0x10 less than what they are meant to be
        // this is a fix to that...
        var PAD = 0x10;

        var PM = mono["Alkawa.Gameplay", "PauseManager"];
        vars.Helper["isPaused"] = PM.Make<bool>("m_paused"); // good

        var PC = mono["Alkawa.Gameplay", "PlayerComponent"];
        var PHSC = mono["Alkawa.Gameplay", "PlayerHealthSubComponent"];
        var PHSI = mono["Alkawa.Gameplay", "PlayerHealthStateInfo", 1];
        
        vars.Helper["health"] = PM.Make<int>(
            "m_PlayerComponent",
            PC["PlayerHealth"] + PAD,
            PHSC["m_playerHealthStateInfo"] + PAD,
            PHSI["m_internalCurrentHP"] + PAD
        ); 
        
        var LM = mono["Alkawa.Gameplay", "LootManager", 1];
        var LI = mono["Alkawa.Engine", "LevelInstance"];
        var LD = mono["Alkawa.Engine", "LevelData", 1];

        vars.Helper["level"] = LM.MakeString(
            "m_instance",
            LM["m_currentLevelInstance"] + PAD,
            LI["m_levelData"] + PAD,
            LD["m_prettyName"] + PAD
        );

        // testing

        // var GSM = mono["Alkawa.Gameplay", "GameStatsManager"];
        // var WI = mono["Alkawa.Engine", "WorldInstance"];
        // var WD = mono["Alkawa.Engine", "WorldData", 1];

        // vars.Helper["a"] = GSM.Make<long>("s_currentWorld");
        // vars.Helper["b"] = GSM.Make<long>("s_currentWorld", WI["m_worldData"]);
        // vars.Helper["c"] = GSM.MakeString("s_currentWorld", WI["m_worldData"] + 0x10, WD["m_labelName"] + 0x10);

        return true;
    });

    // this function is a helper for checking splits that may or may not exist in settings,
    // and if we want to do them only once
    vars.CheckSplit = (Func<string, bool>)(key => {
        // if the split doesn't exist, or it's off, or we've done it already
        if (!settings.ContainsKey(key)
          || !settings[key]
          || !vars.CompletedSplits.Add(key)
        ) {
            return false;
        }

        vars.Log("Completed: " + key);
        return true;
    });
}

update
{
    // Assets/_Game/Scenes    
    current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;

    vars.Watch(old, current, "activeScene");
    vars.Watch(old, current, "loadingScene");
    vars.Watch(old, current, "level");
}

onStart
{
    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();

    // goods
    vars.Log(current.isPaused);
    vars.Log(current.health);
    vars.Log(current.level);
    
    // tests
    // vars.Log(current.a.ToString("X"));

    vars.Log("active: " + vars.Helper.Scenes.Active.Address.ToString("X"));
    vars.Log(vars.Helper.Scenes.Active.Name);
    vars.Log(vars.Helper.Scenes.Active.Path);

    vars.Log("Loaded: " + vars.Helper.Scenes.Loaded.Count);

    foreach (var scene in vars.Helper.Scenes.Loaded) {
        vars.Log(scene.Address.ToString("X"));
        vars.Log(scene.Name);
        vars.Log(scene.Path);
    }
}