package games.objects;

/*
	it optimized better than just use a FlxText to display
 */
class JudgementCounter extends FlxSpriteGroup
{
	var game = PlayState.instance;
	var isExtend:Bool = ClientPrefs.data.marvelousRating;

	public var mainTeam:Array<FlxText> = [];
	public var judgeTeam:Array<FlxText> = [];

	public function new(x:Float, y:Float)
	{
		super(x, y);

		var judgeName:Array<String> = ['Sicks', 'Goods', 'Bads', 'Shits'];
		if (isExtend)
			judgeName.unshift('Marvelous');

		var runTime:Int = isExtend ? 4 : 3;
		for (num in 0...runTime + 1)
		{
			var numText = new FlxText(0, 0, 0, "0", 20);
			numText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			numText.scrollFactor.set();
			numText.borderSize = 1.25;
			numText.text = judgeName[num] + ': ';
			add(numText);
			mainTeam.push(numText);
			numText.y = 20 * num;
		}

		for (num in 0...runTime + 1)
		{
			var numText = new FlxText(0, 0, 0, "0", 20);
			numText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			numText.scrollFactor.set();
			numText.borderSize = 1.25;
			add(numText);
			judgeTeam.push(numText);
			numText.x = mainTeam[num].width;
			numText.y = 20 * num;
		}
	}

	public function updateScore(name:String)
	{
		var dataFix:Int = isExtend ? 1 : 0;
		switch (name)
		{
			case 'marvelous':
				judgeTeam[0].text = Std.string(game.ratingsData[4].hits);
			case 'sick':
				judgeTeam[0 + dataFix].text = Std.string(game.ratingsData[0].hits);
			case 'good':
				judgeTeam[1 + dataFix].text = Std.string(game.ratingsData[1].hits);
			case 'bad':
				judgeTeam[2 + dataFix].text = Std.string(game.ratingsData[2].hits);
			case 'shit':
				judgeTeam[3 + dataFix].text = Std.string(game.ratingsData[3].hits);
		}
	}
}
