package originfunkin.macro;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
/** Restore Lime's historical typed-array transfer helper for compiled Origin mods. */
class OriginLimeArrayBufferCompat {
 public static macro function build():Array<Field> {
  var fields=Context.getBuildFields();
  for (field in fields) if (field.name == "transferElement") return fields;
  var pos=Context.currentPos();
  var body=Context.parse("{\n\t\tvar fromValue:Dynamic = null;\n\t\tvar fromPos = fromView.byteOffset + (fromIndex * fromView.bytesPerElement);\n\t\tswitch (fromView.type)\n\t\t{\n\t\t\tcase Int8:\n\t\t\t\tfromValue = ArrayBufferIO.getInt8(fromView.buffer, fromPos);\n\t\t\tcase Int16:\n\t\t\t\tfromValue = ArrayBufferIO.getInt16(fromView.buffer, fromPos);\n\t\t\tcase Int32:\n\t\t\t\tfromValue = ArrayBufferIO.getInt32(fromView.buffer, fromPos);\n\t\t\tcase Uint8:\n\t\t\t\tfromValue = ArrayBufferIO.getUint8(fromView.buffer, fromPos);\n\t\t\tcase Uint16:\n\t\t\t\tfromValue = ArrayBufferIO.getUint16(fromView.buffer, fromPos);\n\t\t\tcase Uint32:\n\t\t\t\tfromValue = ArrayBufferIO.getUint32(fromView.buffer, fromPos);\n\t\t\tcase Uint8Clamped:\n\t\t\t\tfromValue = ArrayBufferIO.getUint8(fromView.buffer, fromPos);\n\t\t\tcase Float32:\n\t\t\t\tfromValue = ArrayBufferIO.getFloat32(fromView.buffer, fromPos);\n\t\t\tcase Float64:\n\t\t\t\tfromValue = ArrayBufferIO.getFloat64(fromView.buffer, fromPos);\n\t\t\tcase None:\n\t\t\t\tthrow \"transferElement on a base type ArrayBuffer\";\n\t\t}\n\n\t\tvar toPos = toView.byteOffset + (toIndex * toView.bytesPerElement);\n\t\tswitch (toView.type)\n\t\t{\n\t\t\tcase Int8:\n\t\t\t\tArrayBufferIO.setInt8(toView.buffer, toPos, fromValue);\n\t\t\tcase Int16:\n\t\t\t\tArrayBufferIO.setInt16(toView.buffer, toPos, fromValue);\n\t\t\tcase Int32:\n\t\t\t\tArrayBufferIO.setInt32(toView.buffer, toPos, fromValue);\n\t\t\tcase Uint8:\n\t\t\t\tArrayBufferIO.setUint8(toView.buffer, toPos, fromValue);\n\t\t\tcase Uint16:\n\t\t\t\tArrayBufferIO.setUint16(toView.buffer, toPos, fromValue);\n\t\t\tcase Uint32:\n\t\t\t\tArrayBufferIO.setUint32(toView.buffer, toPos, fromValue);\n\t\t\tcase Uint8Clamped:\n\t\t\t\tArrayBufferIO.setUint8Clamped(toView.buffer, toPos, fromValue);\n\t\t\tcase Float32:\n\t\t\t\tArrayBufferIO.setFloat32(toView.buffer, toPos, fromValue);\n\t\t\tcase Float64:\n\t\t\t\tArrayBufferIO.setFloat64(toView.buffer, toPos, fromValue);\n\t\t\tcase None:\n\t\t\t\tthrow \"transferElement on a base type ArrayBuffer\";\n\t\t}\n\t}", pos);
  fields.push({name:"transferElement", pos:pos, access:[APublic,AStatic], meta:[{name:":keep",pos:pos}],
   kind:FFun({args:[{name:"fromView",type:macro:lime.utils.ArrayBufferView},{name:"fromIndex",type:macro:Int},{name:"toView",type:macro:lime.utils.ArrayBufferView},{name:"toIndex",type:macro:Int}],ret:macro:Void,expr:body})});
  return fields;
 }
}
#end
