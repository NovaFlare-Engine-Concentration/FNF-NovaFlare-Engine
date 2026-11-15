package originfunkin.macro;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import sys.io.File;
import sys.FileSystem;

/** Keep native pointer callbacks out of CPPIA's Dynamic argument bridge. */
class OriginCppiaNativeWrappers {
 static function bodyEnd(s:String, start:Int):Int {
  var depth=0;
  for(i in start...s.length) switch(s.charAt(i)) {
   case "{": depth++;
   case "}": depth--; if(depth==0) return i;
   default:
  }
  throw "Unclosed generated function body";
 }
 static function patch(path:String, className:String, methods:Array<String>, withOverrides:Bool, inherited:Bool = false):Void {
  var code=File.getContent(path);
  for(name in methods) {
   if (!inherited) {
    var marker='static void CPPIA_CALL __s_'+name+'(';
    var pos=code.indexOf(marker);
    if(pos<0 || code.indexOf(marker,pos+marker.length)>=0) throw 'Unexpected wrapper '+name+' in '+path;
    var start=code.indexOf('{',pos), end=bodyEnd(code,start);
    code=code.substr(0,start+1)+'\n  ::hx::Throw(HX_CSTRING("Native pointer callbacks cannot be invoked from CPPIA"));\n'+code.substr(end);
   }
   if(withOverrides) {
    var section=code.indexOf('class '+className+'_obj__scriptable');
    if(section<0) throw 'Missing scriptable subclass in '+path;
    var tail=code.substr(section);
    var rx=new EReg('(^|\\n)[ \\t]*([^\\n]*?)\\b'+name+'[ \\t]*\\(([^\\n]*)\\)[ \\t]*\\{','m');
    if(!rx.match(tail)) throw 'Missing native override '+name+' in '+path;
    var ret=StringTools.trim(rx.matched(2)); var args=StringTools.trim(rx.matched(3));
    var posInfo=rx.matchedPos(); var brace=section+posInfo.pos+posInfo.len-1;
    var argNames:Array<String>=[];
    if(args.length>0) for(arg in args.split(',')) {
     var a=StringTools.trim(arg); var ar=~/([A-Za-z_][A-Za-z0-9_]*)$/;
     if(!ar.match(a)) throw 'Unexpected argument '+a+' in '+path;
     argNames.push(ar.matched(1));
    }
    var call=className+'_obj::'+name+'('+argNames.join(',')+');';
    var text='\n  '+(ret=='void' ? '' : 'return ')+call+'\n';
    code=code.substr(0,brace+1)+text+code.substr(bodyEnd(code,brace));
   }
  }
  File.saveContent(path,code);
 }
 public static function configure():Void {
  if (!Context.defined('cpp') || !Context.defined('windows') || !Context.defined('scriptable')) return;
  if (!Context.defined('no-compilation') && !Context.defined('no_compilation'))
   Context.error('CPPIA Windows builds must use Lime so native callback wrappers are fixed before C++ compilation.', Context.currentPos());
  var out=Compiler.getOutput();
  Context.onAfterGenerate(function() {
   var buildPath=out+'/Build.xml';
   if (!FileSystem.exists(buildPath)) throw 'Missing hxcpp Build.xml for native callback validation';
   var build=File.getContent(buildPath);
   function apply(rel:String, cls:String, methods:Array<String>, overrides:Bool, inherited:Bool = false):Void {
    if (build.indexOf('name="src/'+rel+'"')<0) return;
    var path=out+'/src/'+rel;
    if (!FileSystem.exists(path)) throw 'Missing generated native callback file '+path;
    patch(path,cls,methods,overrides,inherited);
   }
   var video=['audioPlay','audioSetup','eventManagerCallbacks','mediaOpen','mediaRead','retainNativeCallbackPin','videoDisplay','videoFormatSetup','videoLock','videoUnlock'];
   var audio=['audioPlay','audioSetup','eventManagerCallbacks','mediaOpen','mediaRead','retainNativeCallbackPin'];
   apply('hxvlc/openfl/Video.cpp','Video',video,true);
   apply('hxvlc/openfl/VideoFix.cpp','VideoFix',video,true);
   apply('hxvlc/openfl/Audio.cpp','Audio',audio,true);
   apply('hxcodec/flixel/FlxVideo.cpp','FlxVideo',video,true,true);
   apply('hxvlc/flixel/FlxVideo.cpp','FlxVideo',video,true,true);
   apply('hxvlc/flixel/FlxInternalVideo.cpp','FlxInternalVideo',video,true,true);
   apply('vlc/MP4Handler.cpp','MP4Handler',video,true,true);
   apply('VideoHandler.cpp','VideoHandler',video,true,true);
   // Haxe emits a non-nullable abstract stub although Acquirable and concrete
   // implementations use an optional nullable argument. Keep the vtable aligned.
   if (build.indexOf('name="src/hx/concurrent/lock/AbstractAcquirable.cpp"') >= 0) {
    var header=out+'/include/hx/concurrent/lock/AbstractAcquirable.h';
    var text=File.getContent(header);
    var from='virtual bool tryAcquire(int timeoutMS) { return 0; }';
    var to='virtual bool tryAcquire(::hx::Null< int > timeoutMS) { return 0; }';
    var index=text.indexOf(from);
    var patched=text.indexOf(to);
    if (index >= 0 && patched < 0 && text.indexOf(from,index+from.length) < 0)
     File.saveContent(header,text.substr(0,index)+to+text.substr(index+from.length));
    else if (index >= 0 || patched < 0 || text.indexOf(to,patched+to.length) >= 0)
     throw 'Unexpected AbstractAcquirable stub in '+header;
   }
   apply('codename/funkin/backend/utils/DiscordUtil.cpp','DiscordUtil',['fixString','toString'],false);
  });
 }
}
#end
