import general.shaders.ColorblindFilter; import general.shaders.FlxG; import general.shaders.ClientPrefs; import openfl.filters.BitmapFilter; import openfl.filters.ColorMatrixFilter;
class Main { static function check(v:Bool,msg:String) if(!v) throw msg; static function main() {
 var custom=new BitmapFilter(); var second=new BitmapFilter(); FlxG.game.setFilters([custom,second]); ColorblindFilter.UpdateColors();
 var f=FlxG.game._filters; check(f.length==3 && f[0]==custom && f[1]==second && Std.isOfType(f[2],ColorMatrixFilter),'custom filters were not preserved'); var old=f[2];
 ClientPrefs.data.colorblindMode='Protanopia'; ColorblindFilter.UpdateColors(); f=FlxG.game._filters; check(f.length==3 && f[0]==custom && f[1]==second && f[2]!=old,'repeated refresh duplicated or lost filters');
 var replacement=new BitmapFilter(); FlxG.game.setFilters([replacement]); ColorblindFilter.UpdateColors(); f=FlxG.game._filters; check(f.length==2 && f[0]==replacement,'replacement was overwritten');
 var external:Array<BitmapFilter>=[]; ColorblindFilter.UpdateColors(external); check(external.length==1 && FlxG.game._filters==f,'input path mutated game filters');
 FlxG.game.setFilters([]); ColorblindFilter.UpdateColors(); check(FlxG.game._filters.length==1,'clear/refresh did not restore only color filter');
 Sys.println('PASS game filters preserved across state and preference refresh'); }}