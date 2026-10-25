package moonchart.backend;

import haxe.ds.StringMap;

class Resolver<F, T>
{
	var _to:StringMap<T>;
	var defToBasic:T;

	var _from:StringMap<F>;
	var defFromBasic:F;

	public function new(defToBasic:T, defFromBasic:F)
	{
		_to = new StringMap<T>();
		_from = new StringMap<F>();
		this.defToBasic = defToBasic;
		this.defFromBasic = defFromBasic;
	}

	public function register(from:F, to:T):Void
	{
		_to.set(Std.string(from), to);
		_from.set(Std.string(to), from);
	}

	public function toBasic(?ID:F):T
	{
		if (ID == null)
			return defToBasic;

		var ID:String = Std.string(ID);
		if (!_to.exists(ID))
			return defToBasic;

		return _to.get(ID);
	}

	public function fromBasic(?ID:T):F
	{
		if (ID == null)
			return defFromBasic;

		var ID:String = Std.string(ID);
		if (!_from.exists(ID))
			return defFromBasic;

		return _from.get(ID);
	}
}
