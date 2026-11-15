package funkin.play.character;
import animate.FlxAnimateFrames;
@:access(animate.FlxAnimateFrames)
@:access(animate.FlxAnimateFrames.FlxAnimateSpritemapCollection)
@:access(flixel.graphics.frames.FlxAtlasFrames)
class BorrowedAnimateFrames extends FlxAnimateFrames {
 var released:Bool = false;
 var sourceFrames:FlxAnimateFrames;
 public function new(source:FlxAnimateFrames) {
  super(source.parent); sourceFrames=source; path="__novaflare_borrowed_no_cache__"; while (FlxAnimateFrames._cachedAtlases.exists(path)) path += "_"; _isInlined=false; _libraryList=[];
  timeline=source.timeline; stageRect=flixel.math.FlxRect.get(source.stageRect.x,source.stageRect.y,source.stageRect.width,source.stageRect.height);stageColor=source.stageColor;matrix=new flixel.math.FlxMatrix();matrix.copyFrom(source.matrix);frameRate=source.frameRate;graphicScale=source.graphicScale;
  dictionary=source.dictionary;
  var owned:animate.FlxAnimateFrames.FlxAnimateSpritemapCollection=cast source.parent;
  for(frame in source.frames) if(owned.spritemaps.contains(frame.parent)) pushFrame(frame);
 }
 static function hasOwnSymbol(frames:FlxAnimateFrames, name:String):Bool {
  if (frames == null) return false;
  if (frames.dictionary != null && frames.dictionary.exists(name)) return true;
  if (frames._isInlined) {
   var symbols = frames._symbolDictionary;
   if (symbols != null) for (i in 0...symbols.length)
    if (symbols[i].SN == name) return true;
  } else if (frames._libraryList != null && frames._libraryList.contains(name)) {
   return true;
  }
  return false;
 }
 override public function existsSymbol(name:String):Bool {
  if (hasOwnSymbol(sourceFrames, name)) return true;
  if (addedCollections != null) for (collection in addedCollections)
   if (hasOwnSymbol(collection, name)) return true;
  return super.existsSymbol(name);
 }
 override public function getSymbol(name:String):Null<animate.internal.SymbolItem> {
  // Resolve lazy symbols on their source owners so shared dictionaries never
  // receive timelines owned by this temporary frame collection.
  if (hasOwnSymbol(sourceFrames, name)) return sourceFrames.getSymbol(name);
  if (addedCollections != null) for (collection in addedCollections)
   if (hasOwnSymbol(collection, name)) return collection.getSymbol(name);
  return super.getSymbol(name);
 }
 override public function destroy():Void {
  if (released) return;
  released = true;
  sourceFrames = null;
  if (frames != null) frames.resize(0);
  dictionary=null;
  timeline=null;
  if (addedCollections != null) addedCollections.resize(0);
  while (FlxAnimateFrames._cachedAtlases.exists(path)) path += "_";
  super.destroy();
 }
}

