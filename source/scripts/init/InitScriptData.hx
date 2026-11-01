package scripts.init;

import crowplexus.iris.Iris;

import scripts.lua.*;

//hxcodec
import vlc.MP4Handler; //2.5.0-2.5.1
import VideoHandler; //2.6.0-2.6.1
import hxcodec.flixel.FlxVideo; //3.0.0-3.0.1

class InitScriptData {
    public static function init() {
        
        //psychlua
        Iris.proxyImports.set("psychlua.CallbackHandler", scripts.lua.CallbackHandler);
        Iris.proxyImports.set("psychlua.CustomSubstate", scripts.lua.CustomSubstate);
        Iris.proxyImports.set("psychlua.DebugLuaText", scripts.lua.DebugLuaText);
        Iris.proxyImports.set("psychlua.DeprecatedFunctions", scripts.lua.DeprecatedFunctions);
        Iris.proxyImports.set("psychlua.ExtraFunctions", scripts.lua.ExtraFunctions);
        Iris.proxyImports.set("psychlua.FlxAnimateFunctions", scripts.lua.FlxAnimateFunctions);
        Iris.proxyImports.set("psychlua.FunkinLua", scripts.lua.FunkinLua);
        Iris.proxyImports.set("psychlua.LuaUtils", scripts.lua.LuaUtils);
        Iris.proxyImports.set("psychlua.ModchartAnimateSprite", scripts.lua.ModchartAnimateSprite);
        Iris.proxyImports.set("psychlua.ModchartSprite", scripts.lua.ModchartSprite);
        Iris.proxyImports.set("psychlua.ReflectionFunctions", scripts.lua.ReflectionFunctions);
        Iris.proxyImports.set("psychlua.ShaderFunctions", scripts.lua.ShaderFunctions);
        Iris.proxyImports.set("psychlua.TextFunctions", scripts.lua.TextFunctions);


        //hxcodec
        Iris.proxyImports.set("vlc.MP4Handler", MP4Handler);
        Iris.proxyImports.set("VideoHandler", VideoHandler);
        Iris.proxyImports.set("hxcodec.VideoHandler", VideoHandler);
        Iris.proxyImports.set("hxcodec.flixel.FlxVideo", FlxVideo);


        //-------------------- PSYCH v0.7.3? --------------------\\
        //backend
        Iris.proxyImports.set("backend.animation.PsychAnimationController", general.backend.animation.PsychAnimationController);  //animation
        Iris.proxyImports.set("backend.Achievements", general.backend.Achievements);
        Iris.proxyImports.set("backend.ClientPrefs", general.backend.ClientPrefs);
        Iris.proxyImports.set("backend.Conductor", general.backend.Conductor);
        Iris.proxyImports.set("backend.Controls", general.backend.Controls);
        Iris.proxyImports.set("backend.CoolUtil", general.backend.CoolUtil);
        Iris.proxyImports.set("backend.CustomFadeTransition", general.backend.CustomFadeTransition);
        Iris.proxyImports.set("backend.InputFormatter", general.backend.InputFormatter);
        Iris.proxyImports.set("backend.Mods", general.backend.Mods);
        Iris.proxyImports.set("backend.MusicBeatState", general.backend.MusicBeatState);
        Iris.proxyImports.set("backend.MusicBeatSubstate", general.backend.MusicBeatSubstate);
        Iris.proxyImports.set("backend.Paths", general.backend.Paths);
        Iris.proxyImports.set("backend.PsychCamera", general.backend.PsychCamera);

        //Iris.proxyImports.set("backend.Discord", general.backend.Discord);    //Psych 073有这个，但编译出错)

        Iris.proxyImports.set("backend.BaseStage", games.stages.base.BaseStage);
        Iris.proxyImports.set("backend.Difficulty", games.backend.Difficulty);
        Iris.proxyImports.set("backend.Highscore", games.backend.Highscore);
        Iris.proxyImports.set("backend.NoteTypesConfig", games.backend.NoteTypesConfig);
        Iris.proxyImports.set("backend.Rating", games.backend.Rating);
        Iris.proxyImports.set("backend.Section", games.backend.Section);
        Iris.proxyImports.set("backend.Song", games.backend.Song);
        Iris.proxyImports.set("backend.StageData", games.backend.StageData);
        Iris.proxyImports.set("backend.WeekData", games.backend.WeekData);

        //cutscenes
        Iris.proxyImports.set("cutscenes.CutsceneHandler", games.cutscenes.CutsceneHandler);
        Iris.proxyImports.set("cutscenes.DialogueBox", games.cutscenes.DialogueBox);
        Iris.proxyImports.set("cutscenes.DialogueBoxPsych", games.cutscenes.DialogueBoxPsych);
        Iris.proxyImports.set("cutscenes.DialogueCharacter", games.cutscenes.DialogueCharacter);

        //debug
        Iris.proxyImports.set("debug.FPSCounter", developer.display.FPSCounter);

        //objects
        Iris.proxyImports.set("objects.AchievementPopup", general.objects.AchievementPopup);
        Iris.proxyImports.set("objects.Alphabet", general.objects.Alphabet);
        Iris.proxyImports.set("objects.AttachedSprite", general.objects.AttachedSprite);
        Iris.proxyImports.set("objects.AttachedText", general.objects.AttachedText);
        Iris.proxyImports.set("objects.BGSprite", general.objects.BGSprite);
        Iris.proxyImports.set("objects.CheckboxThingie", general.objects.CheckboxThingie);
        Iris.proxyImports.set("objects.MenuCharacter", general.objects.MenuCharacter);
        Iris.proxyImports.set("objects.MenuItem", general.objects.MenuItem);
        Iris.proxyImports.set("objects.TypedAlphabet", general.objects.TypedAlphabet);
        Iris.proxyImports.set("objects.Bar", games.objects.Bar);
        Iris.proxyImports.set("objects.Character", games.objects.Character);
        Iris.proxyImports.set("objects.HealthIcon", games.objects.HealthIcon);
        Iris.proxyImports.set("objects.Note", games.objects.Note);
        Iris.proxyImports.set("objects.NoteSplash", games.objects.NoteSplash);
        Iris.proxyImports.set("objects.StrumNote", games.objects.StrumNote);

        //options
        Iris.proxyImports.set("options.BaseOptionsMenu", options.base.BaseOptionsMenu);
        Iris.proxyImports.set("options.ControlsSubState", options.base.ControlsSubState);
        Iris.proxyImports.set("options.ModSettingsSubState", options.base.ModSettingsSubState);
        Iris.proxyImports.set("options.NoteOffsetState", options.base.NoteOffsetState);
        Iris.proxyImports.set("options.NotesSubState", options.base.NotesSubState);
        Iris.proxyImports.set("options.Option", options.base.OptionBase);
        Iris.proxyImports.set("options.OptionsMenu", options.base.BaseOptionsMenu);
        Iris.proxyImports.set("options.OptionsState", options.OptionsState);
        //0.7.3特有，当前项目不存在或已迁移
        //Iris.proxyImports.set("options.GameplaySettingsSubState", null);
        //Iris.proxyImports.set("options.GraphicsSettingsSubState", null);
        //Iris.proxyImports.set("options.VisualsUISubState", null);

        //shaders
        Iris.proxyImports.set("shaders.BlendModeEffect", general.shaders.BlendModeEffect);
        Iris.proxyImports.set("shaders.ColorSwap", general.shaders.ColorSwap);
        Iris.proxyImports.set("shaders.OverlayShader", general.shaders.OverlayShader);
        Iris.proxyImports.set("shaders.RGBPalette", general.shaders.RGBPalette);
        Iris.proxyImports.set("shaders.WiggleEffect", general.shaders.WiggleEffect);

        //states
        Iris.proxyImports.set("states.AchievementsMenuState", states.achievementsMenuState.AchievementsMenuState);
        Iris.proxyImports.set("states.CreditsState", states.creditsState.CreditsState);
        Iris.proxyImports.set("states.FlashingState", states.backend.flashingState.FlashingState);

        //Iris.proxyImports.set("states.FreeplayState", states.freeplayState.FreeplayState); 为啥要加注释啊 ——dmmchh

        Iris.proxyImports.set("states.LoadingState", states.loadingState.LoadingState);
        Iris.proxyImports.set("states.MainMenuState", states.mainMenuState.MainMenuState);
        Iris.proxyImports.set("states.ModsMenuState", states.modsMenuState.ModsMenuState);
        Iris.proxyImports.set("states.OutdatedState", states.backend.outdatedState.OutdatedState);
        Iris.proxyImports.set("states.ScaleSimulationState", states.backend.scaleSimulationState.ScaleSimulationState);
        Iris.proxyImports.set("states.StoryMenuState", states.storyMenuState.StoryMenuState);
        Iris.proxyImports.set("states.TitleState", states.titleState.TitleState);
        Iris.proxyImports.set("states.PlayState", games.PlayState);

        //states.editors
        Iris.proxyImports.set("editors.CharacterEditorState", developer.editors.CharacterEditorState);
        Iris.proxyImports.set("editors.ChartingState", developer.editors.ChartingState);
        Iris.proxyImports.set("editors.DialogueCharacterEditorState", developer.editors.DialogueCharacterEditorState);
        Iris.proxyImports.set("editors.DialogueEditorState", developer.editors.DialogueEditorState);
        Iris.proxyImports.set("editors.EditorPlayState", developer.editors.EditorPlayState);
        Iris.proxyImports.set("editors.MasterEditorMenu", developer.editors.MasterEditorMenu);
        Iris.proxyImports.set("editors.MenuCharacterEditorState", developer.editors.MenuCharacterEditorState);
        Iris.proxyImports.set("editors.NoteSplashEditorState", developer.editors.NoteSplashEditorState);
        Iris.proxyImports.set("editors.WeekEditorState", developer.editors.WeekEditorState);
    
        //states.stages            //呃呃我不知道这个应不应该加上————牢喵233
        Iris.proxyImports.set("stages.Limo", games.stages.Limo);
        Iris.proxyImports.set("stages.Mall", games.stages.Mall);
        Iris.proxyImports.set("stages.MallEvil", games.stages.MallEvil);
        Iris.proxyImports.set("stages.Philly", games.stages.Philly);
        Iris.proxyImports.set("stages.School", games.stages.School);
        Iris.proxyImports.set("stages.SchoolEvil", games.stages.SchoolEvil);
        Iris.proxyImports.set("stages.Spooky", games.stages.Spooky);
        Iris.proxyImports.set("stages.StageWeek1", games.stages.StageWeek1);
        Iris.proxyImports.set("stages.Tank", games.stages.Tank);
        //Iris.proxyImports.set("stages.Template", games.stages.Template); //加上这个会提示找不到"Note"，报错指向Template第137行
        //games.stages.objects
        Iris.proxyImports.set("stages.objects.BackgroundDancer", games.stages.objects.BackgroundDancer);
        Iris.proxyImports.set("stages.objects.BackgroundGirls", games.stages.objects.BackgroundGirls);
        Iris.proxyImports.set("stages.objects.BackgroundTank", games.stages.objects.BackgroundTank);
        Iris.proxyImports.set("stages.objects.DadBattleFog", games.stages.objects.DadBattleFog);
        Iris.proxyImports.set("stages.objects.MallCrowd", games.stages.objects.MallCrowd);
        Iris.proxyImports.set("stages.objects.PhillyGlowGradient", games.stages.objects.PhillyGlowGradient);
        Iris.proxyImports.set("stages.objects.PhillyGlowParticle", games.stages.objects.PhillyGlowParticle);
        Iris.proxyImports.set("stages.objects.PhillyTrain", games.stages.objects.PhillyTrain);
        Iris.proxyImports.set("stages.objects.TankmenBG", games.stages.objects.TankmenBG);


        //substates
        Iris.proxyImports.set("substates.GameOverSubstate", substates.GameOverSubstate);
        Iris.proxyImports.set("substates.GameplayChangersSubstate", substates.GameplayChangersSubstate);
        Iris.proxyImports.set("substates.PauseSubState", substates.PauseSubState);
        Iris.proxyImports.set("substates.Prompt", substates.Prompt);
        Iris.proxyImports.set("substates.ResetScoreSubState", substates.ResetScoreSubState);

        //-------------------- PSYCH v0.6.3? --------------------\\
        //backend
        Iris.proxyImports.set("Achievements", general.backend.Achievements);
        Iris.proxyImports.set("ClientPrefs", general.backend.ClientPrefs);
        Iris.proxyImports.set("Conductor", general.backend.Conductor);
        Iris.proxyImports.set("Controls", general.backend.Controls);
        Iris.proxyImports.set("CoolUtil", general.backend.CoolUtil);
        Iris.proxyImports.set("CustomFadeTransition", general.backend.CustomFadeTransition);
        Iris.proxyImports.set("InputFormatter", general.backend.InputFormatter);
        Iris.proxyImports.set("MusicBeatState", general.backend.MusicBeatState);
        Iris.proxyImports.set("MusicBeatSubstate", general.backend.MusicBeatSubstate);
        Iris.proxyImports.set("Paths", general.backend.Paths);
        Iris.proxyImports.set("PlayerSettings", general.backend.ClientPrefs);  // PlayerSettings可能合并到ClientPrefs
        Iris.proxyImports.set("Highscore", games.backend.Highscore);
        Iris.proxyImports.set("Section", games.backend.Section);
        Iris.proxyImports.set("Song", games.backend.Song);
        Iris.proxyImports.set("StageData", games.backend.StageData);
        Iris.proxyImports.set("WeekData", games.backend.WeekData);
        //new (会出错吗，应该不会吧。 --dmmchh
        Iris.proxyImports.set("Mods", general.backend.Mods);

        //cutscenes
        Iris.proxyImports.set("CutsceneHandler", games.cutscenes.CutsceneHandler);
        Iris.proxyImports.set("DialogueBox", games.cutscenes.DialogueBox);
        Iris.proxyImports.set("DialogueBoxPsych", games.cutscenes.DialogueBoxPsych);

        //objects
        Iris.proxyImports.set("Alphabet", general.objects.Alphabet);
        Iris.proxyImports.set("AttachedSprite", general.objects.AttachedSprite);
        Iris.proxyImports.set("AttachedText", general.objects.AttachedText);
        Iris.proxyImports.set("BGSprite", general.objects.BGSprite);
        

        Iris.proxyImports.set("CheckboxThingie", general.objects.CheckboxThingie);
        Iris.proxyImports.set("MenuCharacter", general.objects.MenuCharacter);
        Iris.proxyImports.set("MenuItem", general.objects.MenuItem);
        Iris.proxyImports.set("TypedAlphabet", general.objects.TypedAlphabet);
        Iris.proxyImports.set("Boyfriend", games.objects.Character);  // Boyfriend在0.6.3独立，现在合并到Character
        Iris.proxyImports.set("Character", games.objects.Character);
        Iris.proxyImports.set("HealthIcon", games.objects.HealthIcon);
        Iris.proxyImports.set("Note", games.objects.Note);
        Iris.proxyImports.set("NoteSplash", games.objects.NoteSplash);
        Iris.proxyImports.set("StrumNote", games.objects.StrumNote);
        Iris.proxyImports.set("TankmenBG", games.stages.objects.TankmenBG);
        Iris.proxyImports.set("BackgroundDancer", games.stages.objects.BackgroundDancer);
        Iris.proxyImports.set("BackgroundGirls", games.stages.objects.BackgroundGirls);

        //options
        Iris.proxyImports.set("BaseOptionsMenu", options.base.BaseOptionsMenu);
        Iris.proxyImports.set("ControlsSubState", options.base.ControlsSubState);
        //Iris.proxyImports.set("GameplaySettingsSubState", substates.GameplayChangersSubstate);  // 0.6.3特有
        //Iris.proxyImports.set("GraphicsSettingsSubState", options.groupData.GraphicsGroup);  // 0.6.3特有
        Iris.proxyImports.set("LatencyState", options.base.NoteOffsetState);  // LatencyState可能合并到NoteOffsetState
        Iris.proxyImports.set("NoteOffsetState", options.base.NoteOffsetState);
        Iris.proxyImports.set("NotesSubState", options.base.NotesSubState);
        Iris.proxyImports.set("Option", options.base.OptionBase);
        Iris.proxyImports.set("OptionsState", options.OptionsState);
        //Iris.proxyImports.set("VisualsUISubState", options.OptionsState);  // 0.6.3特有，当前项目不存在

        //shaders
        Iris.proxyImports.set("BlendModeEffect", general.shaders.BlendModeEffect);
        Iris.proxyImports.set("ColorSwap", general.shaders.ColorSwap);
        Iris.proxyImports.set("OverlayShader", general.shaders.OverlayShader);
        Iris.proxyImports.set("PhillyGlow", general.shaders.BlendModeEffect);  // PhillyGlow可能合并到Philly
        Iris.proxyImports.set("WiggleEffect", general.shaders.WiggleEffect);

        //states
        Iris.proxyImports.set("AchievementsMenuState", states.achievementsMenuState.AchievementsMenuState);
        Iris.proxyImports.set("CreditsState", states.creditsState.CreditsState);
        Iris.proxyImports.set("FlashingState", states.backend.flashingState.FlashingState);
        Iris.proxyImports.set("FreeplayState", states.freeplayState.FreeplayState);
        Iris.proxyImports.set("LoadingState", states.loadingState.LoadingState);
        Iris.proxyImports.set("MainMenuState", states.mainMenuState.MainMenuState);
        Iris.proxyImports.set("ModsMenuState", states.modsMenuState.ModsMenuState);
        Iris.proxyImports.set("OutdatedState", states.backend.outdatedState.OutdatedState);
        Iris.proxyImports.set("StoryMenuState", states.storyMenuState.StoryMenuState);
        Iris.proxyImports.set("TitleState", states.titleState.TitleState);
        Iris.proxyImports.set("PlayState", games.PlayState);

        //states.editors
        Iris.proxyImports.set("editors.CharacterEditorState", developer.editors.CharacterEditorState);
        Iris.proxyImports.set("editors.ChartingState", developer.editors.ChartingState);
        Iris.proxyImports.set("editors.DialogueCharacterEditorState", developer.editors.DialogueCharacterEditorState);
        Iris.proxyImports.set("editors.DialogueEditorState", developer.editors.DialogueEditorState);
        Iris.proxyImports.set("editors.EditorLua", scripts.lua.FunkinLua);  // EditorLua合并到FunkinLua
        Iris.proxyImports.set("editors.EditorPlayState", developer.editors.EditorPlayState);
        Iris.proxyImports.set("editors.MasterEditorMenu", developer.editors.MasterEditorMenu);
        Iris.proxyImports.set("editors.MenuCharacterEditorState", developer.editors.MenuCharacterEditorState);
        Iris.proxyImports.set("editors.WeekEditorState", developer.editors.WeekEditorState);

        //substates
        Iris.proxyImports.set("GameOverSubstate", substates.GameOverSubstate);
        Iris.proxyImports.set("GameplayChangersSubstate", substates.GameplayChangersSubstate);
        Iris.proxyImports.set("GitarooPause", substates.PauseSubState);  // GitarooPause用PauseSubState代替
        Iris.proxyImports.set("PauseSubState", substates.PauseSubState);
        Iris.proxyImports.set("Prompt", substates.Prompt);
        Iris.proxyImports.set("ResetScoreSubState", substates.ResetScoreSubState);

        //animateatlas (0.6.3特有，当前项目无)
        //Iris.proxyImports.set("animateatlas.AtlasFrameMaker", animateatlas.AtlasFrameMaker);
        //Iris.proxyImports.set("animateatlas.HelperEnums", animateatlas.HelperEnums);
        //Iris.proxyImports.set("animateatlas.JSONData", animateatlas.JSONData);
        //Iris.proxyImports.set("animateatlas.JSONData2020", animateatlas.JSONData2020);
        //Iris.proxyImports.set("animateatlas.Main", animateatlas.Main);
        //Iris.proxyImports.set("animateatlas.displayobject.SpriteAnimationLibrary", animateatlas.displayobject.SpriteAnimationLibrary);
        //Iris.proxyImports.set("animateatlas.displayobject.SpriteMovieClip", animateatlas.displayobject.SpriteMovieClip);
        //Iris.proxyImports.set("animateatlas.displayobject.SpriteSymbol", animateatlas.displayobject.SpriteSymbol);
        //Iris.proxyImports.set("animateatlas.tilecontainer.TileAnimationLibrary", animateatlas.tilecontainer.TileAnimationLibrary);
        //Iris.proxyImports.set("animateatlas.tilecontainer.TileContainerMovieClip", animateatlas.tilecontainer.TileContainerMovieClip);
        //Iris.proxyImports.set("animateatlas.tilecontainer.TileContainerSymbol", animateatlas.tilecontainer.TileContainerSymbol);


    }
}
