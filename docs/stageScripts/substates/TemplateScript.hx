//以下是HScriptSubstate的所有调用函数
//由于存在部分缺陷，如果需要获得更好的体验（例如颠覆）可以在`stageScripts/modules/`使用脚本类继承`ScriptedSubstate`

//Here are all the calling functions of `HScriptSubstate`.
//Due to some defects, if you need a better experience (such as override), you can use the script class inheritance in ` stageScript/modules/` to extend `ScriptdSubstate`.

/**
 * 当自定义子界面调用create时
 * When the custom substate calls `create`
 */
function onCreate() {}

/**
 * 当自定义子界面调用create后
 * After the custom substate calls `create`
 */
function onCreatePost() {}

/**
 * 脚本可随游戏更新或实际绘制。帧率上限大于零时限制回调频率，elapsed 包含跳过的游戏时间。
 * Follows updates or drawing. A positive rate caps callbacks, and elapsed includes skipped game time.
 * @param elapsed 当前更新经过的游戏秒数，已计入时间倍率 - Scaled game seconds for this update
 */
function onUpdate(elapsed:Float) {}

/**
 * 在同一次脚本更新后调用。
 * Runs after the matching script update.
 */
function onUpdatePost() {}

/**
 * 当自定义子界面调用draw时
 * When the custom substate calls `draw`
 */
function onDraw() {}

/**
 * 当自定义子界面调用draw后
 * After the custom substate calls `draw`
 */
function onDrawPost() {}

/**
 * 当自定义子界面调用onFocusLost时
 * When the custom substate calls `onFocusLost`
 */
function onFocusLost() {}

/**
 * 当自定义子界面调用onFocus时
 * When the custom substate calls `onFocus`
 */
function onFocus() {}

/**
 * 当自定义子界面调用openSubState时
 * When the custom substate calls `openSubState`
 * @param subState 所需打开的子界面 - The substate you need to open
 */
function onOpenSubState(subState:FlxState) {}

/**
 * 当自定义子界面调用openSubState后
 * After the custom substate calls `openSubState`
 * @param subState 所需打开的子界面 - The substate you need to open
 */
function onOpenSubStatePost(subState:FlxState) {}

/**
 * 当自定义子界面调用closeSubState时
 * When the custom substate calls `closeSubState`
 */
function onCloseSubState() {}

/**
 * 当自定义子界面调用closeSubState后
 * After the custom substate calls `closeSubState`
 */
function onCloseSubStatePost() {}

/**
 * 当自定义子界面调用close时
 * When the custom substate calls `close`
 */
function onClose() {}

/**
 * 当自定义子界面调用close后
 * After the custom substate calls `close`
 */
function onClosePost() {}

/**
 * 当自定义子界面调用onResize时
 * When the custom substate calls `onResize`
 * @param width 窗口被调整后的宽度 - Width of the window resized
 * @param height 窗口被调整后的高度 - Height of the window resized
 */
function onResize(width:Int, height:Int) {}

/**
 * 当自定义子界面调用stepHit时
 * When the custom substate calls `stepHit`
 */
function onStepHit() {}

/**
 * 当自定义子界面调用beatHit时
 * When the custom substate calls `beatHit`
 */
function onBeatHit() {}

/**
 * 当自定义子界面调用sectionHit时
 * When the custom substate calls `sectionHit`
 */
function onSectionHit() {}

/**
 * 当自定义子界面调用destroy时
 * When the custom substate calls `destroy`
 */
function onDestroy() {}
