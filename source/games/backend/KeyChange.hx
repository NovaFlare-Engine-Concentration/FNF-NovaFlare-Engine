package games.backend;

/**
	谱面事件 KeyChange (MoreKey) 的引擎侧支持。

	事件格式（Psych 事件行）：
		[time, [[ "KeyChange", value1, value2 ]] ]
	value1 = 目标键数（1 ~ 10，如 4 = 4K、6 = 6K；也接受 "7K"/"07" 这类写法）
	value2 = 过渡时间（秒，如 0.1 = 在 0.1 秒内把原本的 strum/note 重新渲染成 value1 键；<=0 或留空使用默认值）

	事件名兼容多种写法："KeyChange"、"Key change(more key)"、"Key change (more key)"、
	"Keychange" 等（不区分大小写、忽略空格/括号/下划线/连字符）。

	谱面数据规则（分段编码）：
	含 KeyChange 事件的谱面，音符的 lane 以「段」为单位书写——从歌曲开始到第一个
	KeyChange 事件前为第一段（使用谱面 json 的 mania 字段），每个事件之后进入新段，
	每段内玩家侧 lane 0..keys-1、对手侧 lane keys..keys*2-1（与 NovaFlare 现有多键位
	解析一致，只是键数在事件处切换）。该规则同时被 PlayState.generateSong（游戏内
	解析）、ChartingState（编辑器渲染/编辑）使用。
**/

class KeyChange
{
	public static function isKeyChangeName(name:String):Bool
	{
		if (name == null || name.length < 1)
			return false;
		var clean:String = name.toLowerCase()
			.split(' ').join('')
			.split('(').join('')
			.split(')').join('')
			.split('_').join('')
			.split('-').join('');
		return clean == 'keychange' || clean == 'keychangemorekey';
	}

	/** 解析 value1：接受 "4"、"4K"、"04" 等，返回显示键数；无效时返回 fallback */
	public static function parseKeyCount(value1:String, ?fallback:Int = 4):Int
	{
		var raw:String = value1 == null ? '' : StringTools.trim(value1);
		if (raw.length < 1)
			return fallback;
		if (raw.charAt(raw.length - 1).toLowerCase() == 'k')
			raw = raw.substr(0, raw.length - 1);
		var val:Null<Int> = Std.parseInt(raw);
		if (val == null || Math.isNaN(val))
			return fallback;
		return val;
	}

	/**
	 * 解析 value2（过渡秒）：
	 * 留空/非数字 → 返回默认值（有渐显）；
	 * 显式 0 或负数 → 返回 0（立即切换，跳过 strum/note 渐显动画）；
	 * 正数 → 原样（上限 10 秒）。
	 */
	public static function parseTransition(value2:String, ?defaultTime:Float = 0.5):Float
	{
		var raw:String = value2 == null ? '' : StringTools.trim(value2);
		if (raw.length < 1)
			return defaultTime;
		var time:Float = Std.parseFloat(raw);
		if (Math.isNaN(time))
			return defaultTime;
		if (time <= 0)
			return 0; // 0：直接切换，不播渐显
		if (time > 10)
			time = 10;
		return time;
	}

	/** 显示键数 -> mania（每侧键数 - 1，4K -> 3） */
	public static inline function maniaFromKeys(keys:Int):Int
	{
		return keys - 1;
	}

	/** 把键数约束到引擎实际支持的范围（extrakeys.json；兜底 1..10） */
	public static function clampKeys(keys:Int):Int
	{
		if (keys < 1)
			keys = 1;
		var maxK:Int = 10;
		if (ExtraKeysHandler.instance != null && ExtraKeysHandler.instance.data != null)
		{
			var ek = ExtraKeysHandler.instance.data;
			if (ek.keys != null && ek.keys.length > 0)
				maxK = ek.keys.length; // keys 表长度 = 支持的 mania 数（10 项 => 10K）
			else if (ek.maxKeys > 0)
				maxK = ek.maxKeys + 1; // maxKeys 本身是 mania 值（过期字段语义）
		}
		if (keys > maxK)
			keys = maxK;
		return keys;
	}

	/**
		从原始事件数组（_song.events / events chart 的 events 字段，形如
		[time, [[name, value1, value2], ...]]）扫描出所有 KeyChange 点。
		timeOffset 用于与 Note.strumTime 对齐（传 ClientPrefs.data.noteOffset）。
		返回按时间升序排列的点。
	**/
	public static function scanEvents(events:Array<Dynamic>, timeOffset:Float):Array<KeyChangePoint>
	{
		var points:Array<KeyChangePoint> = [];
		if (events == null)
			return points;

		for (ev in events)
		{
			if (ev == null || !Std.isOfType(ev, Array))
				continue;
			var evArr:Array<Dynamic> = cast ev;
			if (evArr.length < 2 || evArr[1] == null || !Std.isOfType(evArr[1], Array))
				continue;
			var rawTime:Float = Std.parseFloat(Std.string(evArr[0]));
			if (Math.isNaN(rawTime))
				continue;

			var subs:Array<Dynamic> = cast evArr[1];
			for (sub in subs)
			{
				if (sub == null || !Std.isOfType(sub, Array))
					continue;
				var subArr:Array<Dynamic> = cast sub;
				if (subArr.length < 1 || subArr[0] == null)
					continue;
				if (!isKeyChangeName(Std.string(subArr[0])))
					continue;
				var keys:Int = parseKeyCount(subArr.length > 1 && subArr[1] != null ? Std.string(subArr[1]) : null, 4);
				var trans:Float = parseTransition(subArr.length > 2 && subArr[2] != null ? Std.string(subArr[2]) : null);
				points.push({time: rawTime + timeOffset, keys: clampKeys(keys), trans: trans});
			}
		}

		points.sort(function(a:KeyChangePoint, b:KeyChangePoint):Int
		{
			if (a.time < b.time)
				return -1;
			if (a.time > b.time)
				return 1;
			return 0;
		});
		return points;
	}

	/** 就地按时间升序排序（用于合并多个事件源扫出的点） */
	public static function sortPoints(points:Array<KeyChangePoint>):Array<KeyChangePoint>
	{
		if (points == null)
			return points;
		points.sort(function(a:KeyChangePoint, b:KeyChangePoint):Int
		{
			if (a.time < b.time)
				return -1;
			if (a.time > b.time)
				return 1;
			return 0;
		});
		return points;
	}

	/**
		查询 time 时刻生效的 mania（points 需按时间升序）。
		时间 >= 事件时间即视为已切换到该事件的目标键数。
	**/
	public static function maniaAt(time:Float, points:Array<KeyChangePoint>, fallbackMania:Int):Int
	{
		var curMania:Int = fallbackMania;
		if (points != null)
		{
			for (p in points)
			{
				if (time >= p.time)
					curMania = maniaFromKeys(p.keys);
				else
					break;
			}
		}
		return curMania;
	}
}
