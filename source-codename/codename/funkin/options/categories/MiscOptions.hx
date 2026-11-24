package codename.funkin.options.categories;

import codename.funkin.savedata.FunkinSave;

class MiscOptions extends TreeMenuScreen {
	public function new() {
		super('optionsTree.miscellaneous-name', 'optionsTree.miscellaneous-desc', 'MiscOptions.');

		add(new Checkbox(getNameID('devMode'), getDescID('devMode'), 'devMode', Options.applyDeveloperMode));
		add(new Checkbox(getNameID('allowConfigWarning'), getDescID('allowConfigWarning'), 'allowConfigWarning'));
		#if UPDATE_CHECKING
		add(new Checkbox(getNameID('betaUpdates'), getDescID('betaUpdates'), 'betaUpdates'));
		add(new TextOption(getNameID('checkForUpdates'), getDescID('checkForUpdates'), () -> {
			var report = codename.funkin.backend.system.updating.UpdateUtil.checkForUpdates(true);
			if (report.newUpdate) FlxG.switchState(new codename.funkin.backend.system.updating.UpdateAvailableScreen(report));
			else {
				CoolUtil.playMenuSFX(CANCEL);
				//updateDescText(translate('checkForUpdates-noUpdateFound'));
			}
		}));
		#end

		add(new Separator());
		add(new TextOption(getNameID('resetSaveData'), getDescID('resetSaveData'), () -> {
			FunkinSave.save.erase();
			FunkinSave.highscores.clear();
			FunkinSave.flush();
		}));
	}
}
