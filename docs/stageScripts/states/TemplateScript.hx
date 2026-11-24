//以下是HScriptState的所有调用函数
//由于存在部分缺陷，如果需要获得更好的体验（例如颠覆）可以在`stageScripts/modules/`使用脚本类继承`ScriptedState`

//Here are all the calling functions of `HScriptState`.
//Due to some defects, if you need a better experience (such as override), you can use the script class inheritance in ` stageScript/modules/` to extend `ScriptdState`.

/**
 * 当自定义界面调用create时
 * When the custom state calls `create`
 */
function onCreate() {}

/**
 * 当自定义界面调用create后
 * After the custom state calls `create`
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
 * 当自定义界面调用draw时
 * When the custom state calls `draw`
 */
function onDraw() {}

/**
 * 当自定义界面调用draw后
 * After the custom state calls `draw`
 */
function onDrawPost() {}

/**
 * 当自定义界面调用onFocusLost时
 * When the custom state calls `onFocusLost`
 */
function onFocusLost() {}

/**
 * 当自定义界面调用onFocus时
 * When the custom state calls `onFocus`
 */
function onFocus() {}

/**
 * 当自定义界面调用openSubState时
 * When the custom state calls `openSubState`
 * @param subState 所需打开的子界面 - The substate you need to open
 */
function onOpenSubState(subState:FlxState) {}

/**
 * 当自定义界面调用openSubState后
 * After the custom state calls `openSubState`
 * @param subState 所需打开的子界面 - The substate you need to open
 */
function onOpenSubStatePost(subState:FlxState) {}

/**
 * 当自定义界面调用closeSubState时
 * When the custom state calls `closeSubState`
 */
function onCloseSubState() {}

/**
 * 当自定义界面调用closeSubState后
 * After the custom state calls `closeSubState`
 */
function onCloseSubStatePost() {}

/**
 * 当自定义界面调用startOutro时
 * When the custom state calls `startOutro`
 * @param onOutroComplete 当结尾完成时会被调用 - Called when the outro is complete.
 */
function onOutroStart(onOutroComplete:Void->Void) {}

/**
 * 当自定义界面调用onResize时
 * When the custom state calls `onResize`
 * @param width 窗口被调整后的宽度 - Width of the window resized
 * @param height 窗口被调整后的高度 - Height of the window resized
 */
function onResize(width:Int, height:Int) {}

/**
 * 当自定义界面调用stepHit时
 * When the custom state calls `stepHit`
 */
function onStepHit() {}

/**
 * 当自定义界面调用beatHit时
 * When the custom state calls `beatHit`
 */
function onBeatHit() {}

/**
 * 当自定义界面调用sectionHit时
 * When the custom state calls `sectionHit`
 */
function onSectionHit() {}

/**
 * 当自定义界面调用destroy时
 * When the custom state calls `destroy`
 */
function onDestroy() {}
