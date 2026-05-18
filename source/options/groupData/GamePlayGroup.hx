package options.groupData;

class GamePlayGroup extends OptionCata
{
    public function new(X:Float, Y:Float, width:Float, height:Float)
	{
        super(X, Y, width, height);

        var option:Option = new Option(this, 'GamePlay', TITLE);
        addOption(option);

        var option:Option = new Option(this, 'downScroll', BOOL);
        addOption(option);

        var option:Option = new Option(this, 'middleScroll', BOOL);
        addOption(option);

        var option:Option = new Option(this, 'flipChart', BOOL);
        addOption(option);

        var option:Option = new Option(this, 'ghostTapping', BOOL);
        addOption(option);

        var option:Option = new Option(this, 'guitarHeroSustains', BOOL);
        addOption(option);

        var option:Option = new Option(this, 'noReset', BOOL);
        addOption(option);

        var option:Option = new Option(this, 'showKeybinds', BOOL);
        addOption(option);
        
        var option:Option = new Option(this, 'NoteOffsetState', STATE); //NoteOffsetState
        option.onChange = function() { changeState(1); };
		addOption(option);

        /////--Opponent--\\\\\

        var option:Option = new Option(this, 'Opponent', TEXT);
		addOption(option);

        var option:Option = new Option(this, 'playOpponent', BOOL);
        addOption(option);
        
        var option:Option = new Option(this, 'opponentCodeFix', BOOL);
        addOption(option);
        
        var option:Option = new Option(this, 'botOpponentFix', BOOL);
        addOption(option);

        var option:Option = new Option(this, 'HealthDrainOPPO', BOOL);
        addOption(option);

        var option:Option = new Option(this, 'HealthDrainOPPOMult', FLOAT, [0, 5, 1]);
        addOption(option);

         /////--Judgement--\\\\\
        var option:Option = new Option(this, 'judgement', TEXT);
		addOption(option);

        var option:Option = new Option(this, 'marvelousRating', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'marvelousSprite', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'ratingOffset', INT, [-1000, 1000, 'MS']);
		addOption(option);

		var option:Option = new Option(this, 'safeFrames', FLOAT, [0, 10, 1]);
		addOption(option);

		var option:Option = new Option(this, 'marvelousWindow', INT, [0, 166, 'MS']);
		addOption(option);

	    var option:Option = new Option(this, 'sickWindow', INT, [0, 166, 'MS']);
		addOption(option);

	    var option:Option = new Option(this, 'goodWindow', INT, [0, 166, 'MS']);
		addOption(option);

	    var option:Option = new Option(this, 'badWindow', INT, [0, 166, 'MS']);
		addOption(option);
		
	    /////--Gameplaybackend--\\\\\

        var option:Option = new Option(this, 'Gameplaybackend', TEXT);
		addOption(option);

        var option:Option = new Option(this, 'fixLNL', BOOL);
        addOption(option);

        var group:Array<String> = ['Score', 'Accuracy', 'Misses', 'highestCombo'];
        var option:Option = new Option(this, 'saveScoreBase', STRING, group);
        addOption(option);

        #if android
		var option:Option = new Option(this, 'gameOverVibration', BOOL);
		addOption(option);
		#end

        changeHeight(0); //初始化真正的height
    }
    
    function changeState(type:Int) {
		OptionsState.instance.moveState(type);
	}
}
