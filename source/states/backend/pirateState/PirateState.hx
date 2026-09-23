package states.backend.pirateState;

import lime.app.Application;

import openfl.Lib;

import flixel.FlxSubState;
import flixel.effects.FlxFlicker;

class PirateState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var warnText:FlxText;

	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		var guh:String = "
		This is pirate version
		You are banned from entering the game
		please use the legitimate version\n
        此版本为盗版
        你已被禁止进入游戏
        请使用正版进行游玩\n
        ";
		warnText = new FlxText(0, 0, FlxG.width, guh, 32);
		warnText.setFormat(Paths.font("Lang-ZH.ttf"), 32, FlxColor.RED, CENTER);
		warnText.screenCenter(Y);
		add(warnText);

		addVirtualPad(NONE, A);
	}

	override function update(elapsed:Float)
	{
		if (controls.ACCEPT)
			CoolUtil.browserLoad('https://github.com/D-C-LushiFu/NovaFlare-Engine-LushiFuFixedsss/releases');

		super.update(elapsed);
	}
}
