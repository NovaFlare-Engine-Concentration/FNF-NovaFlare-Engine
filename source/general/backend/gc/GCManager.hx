package general.backend.gc;

import cpp.RawPointer;
import cpp.Pointer;

extern class GCManager {
      /**
       直接替代了NativeGC，接入自己改的hxcpp的内容
       底下的注释都是ai写的，凑合看吧
       --by 北狐
      */


      /**
       获取 GC 内存信息。
       @param inWhatInfo 信息类别标识（由 hxcpp 定义）
       @return 返回对应的数值信息（如字节、比例等）
      */
      @:native("__hxcpp_gc_mem_info")
	static function memInfo(inWhatInfo:Int):Float;

	/**
	 在 GC 堆上为指定类分配对象（扩展分配）。
	 @param cls 目标类
	 @param size 额外分配的字节大小
	 @return 新创建的对象实例
	*/
	@:native("_hx_allocate_extended") @:templatedCall
	static function allocateExtended<T>(cls:Class<T>, size:Int):T;

	/**
	 为对象注册终结器（finalize）。
	 @param instance 提供 finalize() 方法的对象
	 @param inPin 是否固定对象以避免移动（影响回收时机）
	*/
	@:native("_hx_add_finalizable")
	static function addFinalizable(instance:{function finalize():Void;}, inPin:Bool):Void;

	/**
	 直接在 GC 堆上分配原始字节块。
	 @param inBytes 分配字节数
	 @param isContainer 是否作为容器（包含指针）
	 @return 原始指针（RawPointer）
	*/
	@:native("::hx::InternalNew")
	static function allocGcBytesRaw(inBytes:Int, isContainer:Bool):RawPointer<cpp.Void>;

	/**
	 在 GC 堆上分配字节并返回安全指针。
	 @param inBytes 分配字节数
	 @return 指向已分配内存的 Pointer
	*/
	inline static function allocGcBytes(inBytes:Int):Pointer<cpp.Void> {
		return Pointer.fromRaw(allocGcBytesRaw(inBytes, false));
	}

	/**
	 启用/禁用 GC。
	 @param inEnable true 启用，false 禁用
	*/
	@:native("__hxcpp_enable") extern static function enable(inEnable:Bool):Void;

	/**
	 触发一次垃圾回收。
	 @param major 是否执行主（Major）收集
	*/
	@:native("__hxcpp_collect") extern static function run(major:Bool):Void;

	#if (cpp && NOVAFLARE_GC_GENERATIONAL_PREFERENCE && !hxcpp_zgc)
	@:native("__hxcpp_novaflare_configure_generational_gc") extern public static function configureGenerationalGC(enabled:Bool):Void;
	#end

	@:native("__hxcpp_gc_last_pause_ms") extern public static function lastPauseMs():Float;
	@:native("__hxcpp_gc_gameplay_max_pause_ms") extern public static function gameplayMaxPauseMs():Float;
	@:native("__hxcpp_gc_gameplay_deferred_full_count") extern public static function gameplayDeferredFullCount():Int;
	@:native("__hxcpp_gc_gameplay_emergency_full_count") extern public static function gameplayEmergencyFullCount():Int;

	/**
	 Queues a concurrent full collection without making the UI thread wait.
	 Repeated requests are coalesced by the native collector thread.
	*/
	@:native("__hxcpp_gc_request_full") extern static function requestFull():Void;

	/**
	 紧凑化堆，减少碎片。
	*/
	@:native("__hxcpp_gc_compact") extern static function compact():Void;

	/**
	 跟踪并可选打印指定类型的 GC 对象信息。
	 @param sought 目标类型
	 @param printInstances 是否打印实例信息
	 @return 匹配对象的数量
	*/
	@:native("__hxcpp_gc_trace") extern static function nativeTrace(sought:Class<Dynamic>, printInstances:Bool):Int;

	/**
	 标记对象为不可回收（临时保活）。
	 @param inObject 需要保活的对象
	*/
	@:native("__hxcpp_gc_do_not_kill") extern static function doNotKill(inObject:Dynamic):Void;

	/**
	 获取下一个已被标记回收的“僵尸”对象。
	 @return 僵尸对象（可能为 null）
	*/
	@:native("__hxcpp_get_next_zombie") extern static function getNextZombie():Dynamic;

	/**
	 插入 GC 安全点，便于线程协调回收。
	*/
	@:native("__hxcpp_gc_safe_point") extern static function safePoint():Void;

	/**
	 进入 GC 免干扰区（禁用某些检查，需谨慎使用）。
	*/
	@:native("__hxcpp_enter_gc_free_zone") extern static function enterGCFreeZone():Void;

	/**
	 退出 GC 免干扰区，恢复正常检查。
	*/
	@:native("__hxcpp_exit_gc_free_zone") extern static function exitGCFreeZone():Void;

	/**
	 设置最小空闲空间阈值。
	 @param inBytes 字节数
	*/
	@:native("__hxcpp_set_minimum_free_space") extern static function setMinimumFreeSpace(inBytes:Int):Void;

	/**
	 设置目标空闲空间百分比。
	 @param inPercentage 百分比（0-100）
	*/
	@:native("__hxcpp_set_target_free_space_percentage") extern static function setTargetFreeSpacePercentage(inPercentage:Int):Void;

	/**
	 设置最小工作内存大小。
	 @param inBytes 字节数
	*/
	@:native("__hxcpp_set_minimum_working_memory") extern static function setMinimumWorkingMemory(inBytes:Int):Void;

      
      //@:native("__hxcpp_gc_start_concurrent_mark") extern static function concurrentGC():Void;

      
      /*
      @:native("__hxcpp_gc_inc_mark") extern static function incMark(timeoutSeconds:Float):Bool;

      @:native("__hxcpp_gc_finish_inc_mark") extern static function finishMark():Void;

      @:native("__hxcpp_gc_start_inc_sweep") extern static function startSweep():Void;

      @:native("__hxcpp_gc_inc_sweep") extern static function incSweep(timeoutSeconds:Float):Bool;

      @:native("__hxcpp_gc_finish_inc_sweep") extern static function finishSweep():Void;
      */
}

class LegacyGCManager {
      /**
       触发一次 Minor GC（增量回收）。
      */
      @:native("__hxcpp_gc_minor") extern public static function gc_minor():Void;
      
      /**
       更新 GC 状态/参数（供内部同步）。
      */
      @:native("__hxcpp_gc_update") extern public static function gc_update():Void;

      /**
       获取 Minor 基础 Delta 字节数。
       @return 字节数
      */
      @:native("__hxcpp_get_minor_base_delta_bytes") extern static function getMinorBaseDeltaBytes():Int;

      /**
       设置 Minor 基础 Delta 字节数。
       @param inBytes 字节数
      */
      @:native("__hxcpp_set_minor_base_delta_bytes") extern static function setMinorBaseDeltaBytes(inBytes:Int):Void;

      /**
       设置 Minor 最低频繁触发的时间（毫秒）。
       @param inMs 毫秒数
      */
      @:native("__hxcpp_set_minor_gate_ms") extern static function setMinorGateMs(inMs:Int):Void;

      /**
       设置 Minor 起始触发字节数。
       @param inBytes 字节数
      */
      @:native("__hxcpp_set_minor_start_bytes") extern static function setMinorStartBytes(inBytes:Int):Void;

      /**
       启用/禁用大对象处理机制。
       @param inEnable 0 关闭，1 开启
      */
      @:native("__hxcpp_gc_large_refresh_enable") extern static function gcLargeRefreshEnable(inEnable:Int):Void;

      /**
       获取 Minor 最低频繁触发的时间（毫秒）。
       @return 毫秒数
      */
      @:native("__hxcpp_get_minor_gate_ms") extern static function getMinorGateMs():Int;

      /**
       获取 Minor 起始触发字节数。
       @return 字节数
      */
      @:native("__hxcpp_get_minor_start_bytes") extern static function getMinorStartBytes():Int;

      /**
       查询大对象处理机制是否启用。
       @return 0 未启用，1 已启用
      */
      @:native("__hxcpp_gc_get_large_refresh_enabled") extern static function gcGetLargeRefreshEnabled():Int;

      /**
       配置 GC 并行与细化线程数。
       @param parallelThreads 并行标记/处理线程数
       @param refineThreads 细化处理线程数
      */
      @:native("__hxcpp_gc_set_threads") extern static function gcSetThreads(parallelThreads:Int, refineThreads:Int):Void;

      /**
       设置 GC 理论最大暂停时间（毫秒）。
       @param inMs 毫秒数
      */
      @:native("__hxcpp_gc_set_max_pause_ms") extern static function gcSetMaxPauseMs(inMs:Int):Void;

      /**
       开启/关闭激进的 safepoint 策略。
       @param inEnable 0 关闭，1 开启
      */
      @:native("__hxcpp_gc_aggressive_safepoint") extern static function gcAggressiveSafepoint(inEnable:Int):Void;

      /**
       启用/禁用并行引用处理。
       @param inEnable 0 关闭，1 开启
      */
      @:native("__hxcpp_gc_enable_parallel_ref_proc") extern static function gcEnableParallelRefProc(inEnable:Int):Void;

      /**
       获取并行 GC 线程数。
       @return 线程数
      */
      @:native("__hxcpp_gc_get_parallel_threads") extern static function gcGetParallelThreads():Int;

      /**
       获取细化处理线程数。
       @return 线程数
      */
      @:native("__hxcpp_gc_get_refine_threads") extern static function gcGetRefineThreads():Int;

      /**
       获取 GC 最大暂停时间（毫秒）。
       @return 毫秒数
      */
      @:native("__hxcpp_gc_get_max_pause_ms") extern static function gcGetMaxPauseMs():Int;

      /**
       查询激进 safepoint 是否启用。
       @return 0 未启用，1 已启用
      */
      @:native("__hxcpp_gc_get_aggressive_safepoint") extern static function gcGetAggressiveSafepoint():Int;

      /**
       查询并行引用处理是否启用。
       @return 0 未启用，1 已启用
      */
      @:native("__hxcpp_gc_get_parallel_ref_proc_enabled") extern static function gcGetParallelRefProcEnabled():Int;
}
