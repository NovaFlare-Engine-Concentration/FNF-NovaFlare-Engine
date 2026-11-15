package codename.funkin.editors;

import codename.funkin.backend.assets.ModsFolderLibrary;
import flixel.FlxState;

class ModConfigWarning extends UIState {
	public static var hadPopup:Bool = false;

	var library:ModsFolderLibrary = null;
	var goToState:Class<FlxState>;
	var useAPIWarning:Bool = false;

	public static var defaultModConfigText = 
'[Common] # This section applies the \'MOD_\' prefix to the flags so you don\'t have to.
NAME="YOUR MOD NAME HERE"
DESCRIPTION="YOUR MOD DESCRIPTION HERE"
AUTHOR="YOU/YOUR TEAM HERE"
VERSION="YOUR MOD\'S VERSION HERE"

# DO NOT EDIT!! this is used to check for version compatibility!
API_VERSION=${Flags.CURRENT_API_VERSION}

DOWNLOAD_LINK="YOUR MOD PAGE LINK HERE"

# Icons to display as the game window icon. (NOTE: Small icons like 16x16 only shows up in Windows)
;ICONS=images/icon.png,images/icon64.png,images/icon32.png,images/icon16.png
;ICONS=icon,icon64,icon32,icon16

[Flags] # This section doesn\'t apply any prefix.
# Set this to false if you want to bring back the warning state (prior to 1.0.0)
# NOTE: Beta warning state has been renamed from BetaWarningState.hx to WarningState.hx
DISABLE_WARNING_SCREEN=true

# Some people might not translate their mods, but if you do then you may set this to false
DISABLE_LANGUAGES=true

[Discord] # This section applies the \'MOD_DISCORD_\' prefix to the flags so you don\'t have to.
CLIENT_ID=""
LOGO_KEY=""
LOGO_TEXT=""

[StateRedirects] # This section is used for state redirecting, see examples below.
;StoryMenuState="codename.funkin.menus.FreeplayState"
;FreeplayState="scriptedFreeplayState"

[StateRedirects.force] # Use this if you want to override redirects set by subsequent addons/mods
';

	public function new(library:ModsFolderLibrary, ?goToState:Class<FlxState>, ?useAPIWarning:Bool = false) {
		super();
		this.library = library;
		this.goToState = goToState != null ? goToState : codename.funkin.menus.TitleState;
		this.useAPIWarning = useAPIWarning;
	}

	public function goBack() {
		MusicBeatState.skipTransOut = MusicBeatState.skipTransIn = false;
		FlxG.switchState(cast Type.createInstance(goToState, []));
	}

	override function createPost() {
		super.createPost();
		hadPopup = true;

		// Older external asset packs may not contain the API warning translations.
		var substate = useAPIWarning ? new UIWarningSubstate(
			TU.translate("modApiWarning.warningTitle", [Flags.MOD_API_VERSION != null ? Std.string(Flags.MOD_API_VERSION) : "???", Flags.CURRENT_API_VERSION], "Outdated API Version! (v{0} < v{1})"),
			TU.translate("modApiWarning.warningDesc", null, "Your mod's config runs on an outdated API Version! This WILL cause compatibility and code issues!\n\nIt is recommended that you make changes to your mod and its config file to fit the new version.\n\nMeanwhile, the game will try its best to make your mod compatible, but you should still update your mod.\n\n(PS: If this is not your mod please disable Developer mode, and notify the mod developers if needed.)"), [
			{
				label: TU.translate("editor.ok", null, "OK"),
				color: 0x969533,
				onClick: function (_) {
					goBack();
				}
			}
		], false) : new UIWarningSubstate(TU.translate("modConfigWarning.warningTitle"), TU.translate("modConfigWarning.warningDesc"), [
			{
				label: TU.translate("editor.notNow"),
				color: 0x969533,
				onClick: function (_) {
					goBack();
				}
			},
			{
				label: TU.translate("editor.yes"),
				onClick: function(_) {
					var path = '${library.folderPath}/data/config/modpack.ini';
					CoolUtil.safeSaveFile(path, defaultModConfigText);
					openSubState(new UIWarningSubstate(TU.translate("modConfigWarning.createdTitle"), TU.translate("modConfigWarning.createdDesc", [path]), [
						{
							label: TU.translate("editor.ok"),
							onClick: function (_) {
								goBack();
							}
						},
					], false));
				}
			}
		], false);
		openSubState(substate);
	}
}
