// EncryptUtil.hx
package server.util;

import haxe.crypto.Base64;
import haxe.crypto.mode.Mode;
import haxe.crypto.padding.PKCS7;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.crypto.Aes;
import haxe.crypto.Md5;

#if windows
import trandom.Native;
#end

class EncryptUtil {
    
    static final BLOCK_SIZE:Int = 16;
    static final AES_KEY:String = "c138265b0f77cccd86192a7173668090";
    static final AES_KEY_BYTES:Bytes = Bytes.ofString(AES_KEY);
    
    /**
     * AES-256-CBC 加密整个请求
     */
    public static function encryptRequest(data:Dynamic):String {
        var jsonStr = haxe.Json.stringify(data);
        return aesEncrypt(jsonStr);
    }
    
    /**
     * AES-256-CBC 解密响应
     */
    public static function decryptResponse(encryptedBase64:String):Dynamic {
        var jsonStr = aesDecrypt(encryptedBase64);
        return haxe.Json.parse(jsonStr);
    }
    
    /**
     * AES-256-CBC 加密
     */
    public static function aesEncrypt(data:String):String {
        var iv:Bytes = generateRandomIV();

        // 原为 trace("iv: " + iv.toString())：调试残留，会把加密材料刷进控制台/日志。
        // （IV 本身随密文一起传输，不是密钥，但不应进日志。）

        var dataBytes:Bytes = Bytes.ofString(data);
        var paddedData:Bytes = PKCS7.pad(dataBytes, BLOCK_SIZE);
        
        var aes:Aes = new Aes(AES_KEY_BYTES, iv);
        var encryptedBytes:Bytes = aes.encrypt(Mode.CBC, paddedData);
        
        var combined = new BytesBuffer();
        combined.add(iv);
        combined.add(encryptedBytes);
        var combinedBytes = combined.getBytes();
        
        return Base64.encode(combinedBytes);
    }
    
    /**
     * AES-256-CBC 解密
     */
    public static function aesDecrypt(encryptedBase64:String):String {
        var encryptedBytes:Bytes = Base64.decode(encryptedBase64);
        
        if (encryptedBytes.length < BLOCK_SIZE) {
            throw "加密数据长度不足";
        }
        
        var iv:Bytes = encryptedBytes.sub(0, BLOCK_SIZE);
        var cipherText:Bytes = encryptedBytes.sub(BLOCK_SIZE, encryptedBytes.length - BLOCK_SIZE);
        
        var aes:Aes = new Aes(AES_KEY_BYTES, iv);
        var decryptedBytes:Bytes = aes.decrypt(Mode.CBC, cipherText);
        var unpaddedBytes:Bytes = PKCS7.unpad(decryptedBytes);
        
        return unpaddedBytes.toString();
    }
    
    /**
     * 生成随机 IV
     */
    private static function generateRandomIV():Bytes {
        #if windows
        var iv = Bytes.alloc(BLOCK_SIZE);
        for (i in 0...Std.int(BLOCK_SIZE / 4)) {
            iv.setInt32(i * 4, Native.get());
        }
        var remaining = BLOCK_SIZE % 4;
        if (remaining > 0) {
            var lastChunk = Native.get();
            for (i in 0...remaining) {
                iv.set((BLOCK_SIZE - remaining) + i, (lastChunk >> (8 * i)) & 0xFF);
            }
        }
        return iv;
        #else
        var iv = Bytes.alloc(BLOCK_SIZE);
        for (i in 0...BLOCK_SIZE) {
            iv.set(i, Std.random(256));
        }
        return iv;
        #end
    }

    /////////////// MD5校验 \\\\\\\\\\\\\\\\
    public static function md5Encrypt(data:String):String {
        return Md5.encode(data);
    }
}