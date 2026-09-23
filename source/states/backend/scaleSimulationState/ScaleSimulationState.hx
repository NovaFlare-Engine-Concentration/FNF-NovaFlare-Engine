package states.backend.scaleSimulationState;

import games.objects.StrumNote;

import states.titleState.TitleState;

class ScaleSimulationState extends MusicBeatState {
    public var infoText:FlxText;

    public var keyMin:Int = ExtraKeysHandler.instance.data.minKeys;
    public var keyMax:Int = ExtraKeysHandler.instance.data.maxKeys;

    var strumLineNotes:FlxTypedGroup<StrumNote>;
	var opponentStrums:FlxTypedGroup<StrumNote>;
	var playerStrums:FlxTypedGroup<StrumNote>;

    var started:Bool = false;
    var pixelStarted:Bool = false;

    var resultsPixel:Array<Float> = [];
    var results:Array<Float> = [];

    var completed:Bool = false;

    override public function create():Void
    {
        super.create();

        strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
        opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

        trace('Running scale simulation test...');

        infoText = new FlxText(0, FlxG.height-22, FlxG.width, 'Running scale simulation test...', 16);
        infoText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 16, FlxColor.WHITE, CENTER);
        add(infoText);

        doScaleSimTest(true);
        new FlxTimer().start(1.0, function(_) {
            doScaleSimTest(false);
            new FlxTimer().start(1.0, function(_) {
                onComplete();
            });
        });
    }

    private function generateStaticArrows(player:Int):Void
    {
        var strumLineX:Float = ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X;
        var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
        for (i in 0...PlayState.SONG.mania + 1)
        {
            // FlxG.log.add(i);
            var targetAlpha:Float = 1;
            if (player < 1)
            {
                if(!ClientPrefs.data.opponentStrums) targetAlpha = 0;
                else if(ClientPrefs.data.middleScroll) targetAlpha = 0.35;
            }

            var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
            babyArrow.downScroll = ClientPrefs.data.downScroll;
            babyArrow.alpha = targetAlpha;

            if (player == 1)
                playerStrums.add(babyArrow);
            else
            {
                // if(ClientPrefs.data.middleScroll)
                // {
                //     babyArrow.x += 310;
                //     if(i > 1) { //Up and Right
                //         babyArrow.x += FlxG.width / 2 + 25;
                //     }
                // }
                opponentStrums.add(babyArrow);
            }

            strumLineNotes.add(babyArrow);
            babyArrow.postAddedToGroup();
        }

        adaptStrumline(opponentStrums);
        adaptStrumline(playerStrums);
    }

    public function adaptStrumline(strumline:FlxTypedGroup<StrumNote>) {
		var strumLineWidth:Float = 0;
		var strumLineIsBig:Bool = false;

		for (note in strumline.members) strumLineWidth += note.width;
		strumLineIsBig = strumLineWidth > StrumBoundaries.getBoundaryWidth().x;

		while (strumLineIsBig) {
			strumLineWidth = 0;
			for (note in strumline.members) {
				note.retryBound();
				strumLineWidth += note.width;
			}
			trace('Strumline is too big! Shrinking and retrying.');
			strumLineIsBig = strumLineWidth > StrumBoundaries.getBoundaryWidth().x;
		}
	}

    public function doScaleSimTest(pixel:Bool = false)
    {
        if (pixel) {
            PlayState.stageUI = 'pixel';
        }
        else {
            PlayState.stageUI = 'normal';
        }

        for (i in keyMin...keyMax+1) {
            strumLineNotes.clear();
            playerStrums.clear();
            opponentStrums.clear();

            PlayState.SONG = {
				song: 'DUMMY',
				notes: [],
				events: [],
				bpm: 1,
				mania: i,
				needsVoices: true,
				player1: 'bf',
				player2: 'bf',
				gfVersion: 'bf',
				speed: 1,
				stage: 'stage',
                format: 'na',
			};

            generateStaticArrows(0);
            generateStaticArrows(1);

            if (pixel) { 
                resultsPixel.push(strumLineNotes.members[0].trackedScale);
            }
            else {
                results.push(strumLineNotes.members[0].trackedScale);
            }
        }

        trace('Done');

        if (pixel) trace(resultsPixel);
        else trace(results);
    }

    public function onComplete() {
        var pathToSave = Paths.getPath('data/extrakeys.json', TEXT);

        ExtraKeysHandler.instance.data.scales = results;
        ExtraKeysHandler.instance.data.pixelScales = resultsPixel;
        
        var writer = new json2object.JsonWriter<ExtraKeysData>();
        var content = writer.write(ExtraKeysHandler.instance.data, '');
        File.saveContent(pathToSave, content);

        trace('Scale simulation complete.');

        ExtraKeysHandler.instance.reloadExtraKeys();

        PlayState.SONG = null;

        MusicBeatState.switchState(new TitleState());
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}
