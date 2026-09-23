package mobile.server;

/**
 * 外部按键编辑器页面（HTML/JS/CSS 内嵌常量）。
 * 源文件：mobile-key-editor.html —— 修改后用 tools/gen-editor-key-page.ps1 重新生成本文件。
 *
 * 说明：整页 HTML 体积超过 MSVC 单字符串字面量上限，故拆成多段常量后在
 * 运行时拼接（CHUNKS.join("")），不要改回单个字面量。
 */
class EditorKeyPage
{
	static var CHUNKS:Array<String> = [
'<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>移动端 Editor 按键编辑器 — 外部窗口</title>
<style>
  :root{
    --bg:#12141A; --card:#1C1F28; --card2:#232733; --border:rgba(255,255,255,.09);
    --txt:#F2F3F5; --txt2:#C9CDD4; --dim:#9aa3b2;
    --accent:#8B5CF6; --accent2:#6366F1; --ok:#22C55E; --warn:#F59E0B; --danger:#EF4444;
    --hover:rgba(139,92,246,.16);
  }
  *{margin:0;padding:0;box-sizing:border-box}
  body{background:var(--bg);color:var(--txt);font-family:"Segoe UI","Microsoft YaHei","PingFang SC",sans-serif;font-size:14px;height:100vh;display:flex;flex-direction:column;overflow:hidden}
  ::-webkit-scrollbar{width:12px;height:12px}
  ::-webkit-scrollbar-thumb{background:#3a3f4d;border-radius:6px}
  input,select,button{font-family:inherit}
  button{user-select:none}

  /* ===== 顶栏 ===== */
  header{display:flex;align-items:center;gap:10px;padding:10px 14px;background:var(--card);border-bottom:1px solid var(--border);flex-wrap:wrap;flex:none}
  header .app{font-weight:700;font-size:15px;display:flex;align-items:center;gap:9px}
  header .app .dot{width:10px;height:10px;border-radius:50%;background:var(--ok);box-shadow:0 0 8px var(--ok)}
  header .sep{width:1px;height:24px;background:var(--border)}
  header label{color:var(--dim);font-size:13px}
  header select,header input,header button{background:var(--card2);color:var(--txt);border:1px solid var(--border);border-radius:6px;padding:7px 10px;font-size:14px}
  header select:focus{outline:1px solid var(--accent)}
  .btn{cursor:pointer;transition:filter .12s;white-space:nowrap}
  .btn:hover{filter:brightness(1.25)}
  .btn.primary{background:linear-gradient(135deg,var(--accent2),var(--accent));border:none;font-weight:600}
  .btn.ghost{background:transparent}
  .btn:disabled{opacity:.4;cursor:not-allowed}
  header .file{color:var(--warn);font-family:Consolas,monospace;font-size:13px}
  header .spacer{flex:1}

  /* ===== 主体 ===== */
  main{flex:1;display:flex;min-height:0}
  section.panel{overflow:auto}

  /* --- 左：画布（加大） --- */
  #canvasPanel{flex:0 0 56%;min-width:560px;border-right:1px solid var(--border);display:flex;flex-direction:column;background:var(--bg)}
  .panelHead{display:flex;align-items:center;gap:10px;padding:9px 12px;color:var(--dim);font-size:13px;border-bottom:1px solid var(--border);background:var(--card);flex:none}
  .panelHead b{color:var(--txt2);font-size:14px}
  .panelHead .spacer{flex:1}
  .canvasTools{display:flex;align-items:center;gap:6px;padding:8px 12px;border-bottom:1px solid var(--border);background:var(--card);flex-wrap:wrap;flex:none}
  .canvasTools .grp{display:flex;align-items:center;gap:4px;padding:0 8px;border-right:1px solid var(--border)}
  .canvasTools .grp:last-child{border-right:none}
  .canvasTools label{display:flex;align-items:center;gap:5px;color:var(--dim);font-size:12px}
  .canvasTools input[type=checkbox]{width:16px;height:16px;accent-color:var(--accent)}
  .canvasTools input[type=number]{width:56px;background:#14161d;border:1px solid var(--border);border-radius:5px;color:var(--txt);padding:4px 6px;font-size:13px}
  .toolBtn{min-width:34px;height:30px;border-radius:6px;border:1px solid var(--border);background:var(--card2);color:var(--txt2);cursor:pointer;font-size:14px;padding:0 8px}
  .toolBtn:hover{color:#fff;border-color:var(--accent);background:var(--hover)}
  .canvasTools input[type=range]{width:110px;accent-color:var(--accent)}
  .canvasTools .v{font-family:Consolas,monospace;font-size:12px;color:var(--dim);width:44px}
  .canvasTools .tip{font-size:11px;color:var(--dim);max-width:200px;line-height:1.3}
  .canvasWrap{flex:1;display:flex;align-items:center;justify-content:center;position:relative;overflow:auto;padding:12px;min-height:0}
  #phone{position:relative;background:#0b0d12;border:1px solid #000;box-shadow:0 0 40px rgba(0,0,0,.75);flex:none;background-image:
      linear-gradient(rgba(255,255,255,.04) 1px,transparent 1px),linear-gradient(90deg,rgba(255,255,255,.04) 1px,transparent 1px);
      user-select:none;touch-action:none}
  #phone .bgimg{position:absolute;left:0;top:0;width:100%;height:100%;object-fit:cover;pointer-events:none;z-index:0}
  #phone .tl{position:absolute;left:2px;top:0;color:#5b6472;font-size:11px;pointer-events:none;font-family:Consolas,monospace;z-index:1}
  #phone .sizeTag{position:absolute;right:2px;bottom:0;color:#5b6472;font-size:11px;pointer-events:none;font-family:Consolas,monospace;z-index:1}
  .vbtn{position:absolute;border-radius:12px;display:flex;flex-direction:column;align-items:center;justify-content:center;cursor:move;border:2px solid rgba(255,255,255,.6);color:#fff;text-shadow:0 1px 3px #000;font-weight:700;overflow:hidden;transition:box-shadow .08s}
  .vbtn .bname{line-height:1.15;white-space:nowrap}
  .vbtn .bbind{font-weight:400;opacity:.95;font-family:Consolas,monospace;text-align:center;line-height:1.1;padding:0 2px;white-space:nowrap}
  .vbtn.sel{outline:3px solid #fff;box-shadow:0 0 0 5px var(--accent),0 0 22px var(--accent);z-index:5}
  .vbtn.father{border-style:dashed;border-width:3px}
  .vbtn .fmark{position:absolute;top:3px;right:6px;font-size:10px;opacity:.95}
  .vbtn .badge-s{position:absolute;top:3px;left:6px;font-size:9px;opacity:.85;font-family:Consolas,monospace}
  .hintLine{position:absolute;bottom:6px;left:0;right:0;text-align:center;color:var(--dim);font-size:12px;pointer-events:none;background:linear-gradient(transparent,rgba(0,0,0,.5));padding:6px 0 2px}

  /* --- 右：列表（向下创建/展开） --- */
  #listPanel{flex:1;display:flex;flex-direction:column;min-width:520px}
  #rows{flex:1;overflow:auto;padding:10px}
  .row{background:var(--card);border:1px solid var(--border);border-radius:10px;margin-bottom:8px}
  .row.sel{border-color:var(--accent);box-shadow:0 0 0 1px var(--accent)}
  .rowMain{display:flex;align-items:center;gap:10px;padding:9px 12px;cursor:pointer}
',
'  .rowMain .swatch{width:38px;height:38px;border-radius:8px;border:1px solid rgba(255,255,255,.45);flex:none;display:flex;align-items:center;justify-content:center;font-weight:800;font-size:15px;color:#fff;text-shadow:0 1px 2px #000}
  .rowMain .meta{flex:1;min-width:0}
  .rowMain .meta .t1{display:flex;gap:8px;align-items:center}
  .rowMain .meta .t1 .name{font-weight:700;font-size:16px}
  .rowMain .meta .t1 .tag{font-size:11px;padding:2px 8px;border-radius:5px;background:var(--hover);color:#c4b5fd}
  .rowMain .meta .t1 .tag.f{background:rgba(245,158,11,.16);color:#fbbf24}
  .rowMain .meta .bind{font-family:Consolas,monospace;color:#c4b5fd;font-size:13px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;margin-top:2px}
  .rowMain .meta .bindDesc{color:var(--dim);font-size:12px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;margin-top:1px}
  .rowMain .xy{font-family:Consolas,monospace;color:var(--dim);font-size:13px;flex:none}
  .rowMain .rbtn{flex:none;width:30px;height:30px;border-radius:7px;border:1px solid var(--border);background:var(--card2);color:var(--txt2);cursor:pointer;font-size:13px}
  .rowMain .rbtn:hover{color:#fff}
  .rowMain .rbtn.del:hover{background:var(--danger);color:#fff;border-color:var(--danger)}
  /* 属性编辑区（向下展开，固定 2 列：左=名称/位置/父键开关，右=绑定/颜色） */
  .props{border-top:1px solid var(--border);padding:14px 16px 16px;background:var(--card2);display:grid;grid-template-columns:1fr 1fr;gap:12px 20px}
  .pcol{display:flex;flex-direction:column;gap:12px;min-width:0}
  .props .full{grid-column:1/-1}
  .props label{display:flex;flex-direction:column;gap:5px;color:var(--dim);font-size:12.5px}
  .props label b{color:var(--txt2);font-weight:600;font-size:13px}
  .props label b .hint{color:var(--dim);font-weight:400;font-size:12px}
  .props input[type=text],.props input[type=number]{background:#14161d;border:1px solid var(--border);border-radius:6px;color:var(--txt);padding:7px 9px;font-size:14px;width:100%;min-height:32px}
  .props input[type=text]:focus,.props input[type=number]:focus{outline:1px solid var(--accent)}
  .props input[type=color]{width:100%;height:34px;border:none;border-radius:6px;background:transparent;cursor:pointer;padding:0}
  .props .cb{flex-direction:row;align-items:center;gap:9px;cursor:pointer;padding-top:4px}
  .props .cb input{accent-color:var(--accent);width:17px;height:17px}
  .keychips{display:flex;flex-wrap:wrap;gap:5px;margin-top:6px}
  .chip{font-family:Consolas,monospace;font-size:12px;padding:4px 10px;border-radius:5px;background:#14161d;border:1px solid var(--border);cursor:pointer;color:var(--txt2);line-height:1.4}
  .chip:hover{border-color:var(--accent);color:#fff}
  .chip.used{background:rgba(139,92,246,.24);border-color:var(--accent);color:#c4b5fd}
  .chip.sw{width:22px;height:22px;padding:0;border-radius:5px;flex:none}
  .subsec{border-top:1px dashed rgba(255,255,255,.14);margin-top:12px;padding-top:12px}
  .subsec .ttl{color:var(--txt2);font-weight:600;font-size:13.5px;margin-bottom:8px;display:flex;align-items:center;gap:7px;flex-wrap:wrap}
  .subsec .ttl .h{color:var(--dim);font-weight:400;font-size:12px}
  .swrow{display:flex;gap:8px;align-items:center;margin-bottom:7px;flex-wrap:wrap}
  .swrow select,.swrow input[type=text]{background:#14161d;border:1px solid var(--border);border-radius:6px;color:var(--txt);padding:6px 8px;font-size:13px;min-height:30px}
  .swrow .arrow{color:var(--dim);font-size:16px;padding:0 2px}
  .swrow .miniDel{width:28px;height:28px;border-radius:6px;border:1px solid var(--border);background:transparent;color:var(--dim);cursor:pointer;font-size:12px}
  .swrow .miniDel:hover{color:#fff;background:var(--danger);border-color:var(--danger)}
  .swAdd{font-size:13px;padding:5px 12px;background:var(--card2);border:1px solid var(--border);color:var(--txt2);border-radius:6px;cursor:pointer}
  .swAdd:hover{color:#fff;border-color:var(--accent)}
  .props .note{color:var(--dim);font-size:12.5px;line-height:1.7}
  .props .note code{background:#14161d;border:1px solid var(--border);border-radius:4px;padding:1px 5px;color:#c4b5fd;font-family:Consolas,monospace;font-size:12px}
  .btnJson{background:var(--card2);border:1px solid var(--border);color:var(--txt2);border-radius:6px;cursor:pointer;padding:5px 12px;font-size:12.5px}
  .btnJson:hover{color:#fff;border-color:var(--accent)}
  /* 绑定组合键录制 */
  .capBar{display:flex;align-items:center;gap:8px;flex-wrap:wrap;margin-top:8px}
  .capPreview{font-family:Consolas,monospace;font-size:13px;color:var(--accent);min-height:26px;display:flex;gap:4px;align-items:center;flex-wrap:wrap;padding:2px 4px;border:1px dashed rgba(139,92,246,.5);border-radius:6px;flex:1;min-width:120px}
  .recOn{outline:2px solid var(--danger);animation:pulse 1s infinite}
  @keyframes pulse{50%{outline-color:var(--warn)}}
  .jsonBox{background:#0b0d12;border:1px solid var(--border);border-radius:6px;padding:10px 12px;font-family:Consolas,monospace;font-size:12px;color:#d6e2ff;line-height:1.55;white-space:pre-wrap;margin-top:6px;max-height:240px;overflow:auto}
  .empty{color:var(--dim);text-align:center;padding:44px 12px;font-size:13.5px;line-height:2}
  .empty b{color:var(--accent)}

  /* ===== 底栏 ===== */
  footer{background:var(--card);border-top:1px solid var(--border);padding:7px 14px;display:flex;gap:18px;align-items:center;font-size:12.5px;color:var(--dim);flex-wrap:wrap;flex:none}
  footer .path{font-family:Consolas,monospace;color:var(--txt2)}
  footer .msg{margin-left:auto;font-size:13px;font-weight:600}

  /* JSON 弹层 */
  #modal{position:fixed;inset:0;background:rgba(0,0,0,.6);display:none;align-items:center;justify-content:center;z-index:50}
  #modal.show{display:flex}
  #modal .box{background:var(--card);border:1px solid var(--border);border-radius:12px;width:min(780px,94vw);max-height:88vh;display:flex;flex-direction:column}
  #modal .mhead{display:flex;align-items:center;gap:10px;padding:12px 16px;border-bottom:1px solid var(--border)}
  #modal .mhead b{font-size:15px}
',
'  #modal .mhead .spacer{flex:1}
  #modal pre{flex:1;overflow:auto;margin:0;padding:14px 16px;background:#0b0d12;font-family:Consolas,monospace;font-size:13px;color:#d6e2ff;line-height:1.55;white-space:pre}
  #modal .mfoot{display:flex;gap:8px;justify-content:flex-end;padding:10px 14px;border-top:1px solid var(--border)}
</style>
</head>
<body>

<header>
  <div class="app"><span class="dot" id="connDot"></span> 移动端 Editor 按键编辑器 <span style="color:var(--dim);font-weight:400;font-size:13px">(外部窗口 — 连接 NovaFlare 内嵌服务后读取/保存当前 Editor)</span></div>
  <div class="sep"></div>
  <label>当前 Editor</label>
  <select id="edSel"></select>
  <span class="file" id="fileHint"></span>
  <div class="spacer"></div>
  <button class="btn" id="btnTemplate" title="以该 Editor 默认虚拟按键为基础生成，再自行修改">从默认键位生成</button>
  <button class="btn" id="btnImport" title="从本地选择之前保存的 JSON 文件导入到当前 Editor（导入后需点 💾 保存才写盘）">📂 导入文件</button>
  <select id="impSrc" title="把另一个 Editor 已保存的布局复制到当前 Editor（不切换 Editor）"><option value="">复制其它 Editor…</option></select>
  <button class="btn" id="btnCopyFrom" title="把上面选中的 Editor 布局复制到当前 Editor 工作区">复制到当前</button>
  <button class="btn primary" id="btnNew">＋ 新建按键</button>
  <button class="btn" id="btnPreview">JSON 预览</button>
  <button class="btn primary" id="btnSave">💾 保存</button>
</header>

<main>
  <!-- 左：手机屏画布 -->
  <section id="canvasPanel">
    <div class="panelHead"><b>画布预览</b><span>1280 × 720 · 左上角 [0,0]</span>
      <span class="spacer"></span>
      <span>拖动 = 移动 · 单击 = 选中 · Ctrl+单击 = 加选</span>
    </div>
    <div class="canvasTools">
      <div class="grp">
        <label title="拖动结束后吸附到网格"><input type="checkbox" id="snapOn" checked> 吸附</label>
        <input type="number" id="snapSize" value="20" min="4" max="120" step="4" title="吸附间距(px)">
      </div>
      <div class="grp">
        <label>缩放</label>
        <input type="range" id="zoomR" min="40" max="160" value="100" step="5">
        <span class="v" id="zoomV">100%</span>
      </div>
      <div class="grp">
        <label title="用该 Editor 的真实界面截图作为摆放背景（游戏从 FuckYouNFEMobile/bg/ 读取）"><input type="checkbox" id="bgOn" checked> 背景</label>
        <input type="range" id="bgAlpha" min="10" max="100" value="55" title="背景不透明度">
        <span class="v" id="bgAlphaV">55%</span>
      </div>
      <div class="grp">
        <label title="把 X/Y 偏移量一次性加到全部按钮（Ctrl 多选 ≥2 个时只作用于选中）">整体偏移</label>
        <input type="number" id="offX" value="0" title="X 偏移量（可为负）">
        <input type="number" id="offY" value="0" title="Y 偏移量（可为负）">
        <button class="toolBtn" id="applyOff" title="应用偏移到（选中≥2 或 全部）按钮">⇨ 应用</button>
      </div>
      <div class="grp">
        <label title="把全部（或选中）按钮的宽/高改成统一值；留空的维度保持不变">整体尺寸</label>
        <input type="number" id="setW" value="120" min="20" title="统一宽 W（留空=不变）">
        <input type="number" id="setH" value="120" min="20" title="统一高 H（留空=不变）">
        <button class="toolBtn" id="applySize" title="应用尺寸到（选中≥2 或 全部）按钮">⇨ 应用</button>
      </div>
      <div class="grp" title="作用于：当前选中（≥2 个时），否则全部按键">
        <button class="toolBtn" id="alLeft" title="左对齐">⇤左</button>
        <button class="toolBtn" id="alHC" title="水平居中">⇹中</button>
        <button class="toolBtn" id="alRight" title="右对齐">右⇥</button>
        <button class="toolBtn" id="alTop" title="顶对齐">⇧顶</button>
        <button class="toolBtn" id="alVC" title="垂直居中">⥥中</button>
        <button class="toolBtn" id="alBottom" title="底对齐">底⇩</button>
        <button class="toolBtn" id="alHDist" title="水平间距均布">⇔均布</button>
        <button class="toolBtn" id="alVDist" title="垂直间距均布">⇕均布</button>
      </div>
      <div class="grp"><span class="tip" id="selHint">未选中：对齐将作用于全部按键</span></div>
    </div>
    <div class="canvasWrap"><div id="phone"></div>
      <div class="hintLine">拖动按键移动 · 松手自动吸附网格</div>
    </div>
  </section>

  <!-- 右：按键列表 -->
  <section id="listPanel">
    <div class="panelHead"><b>按键列表（当前 Editor）</b>&nbsp;共 <span id="cnt" style="color:var(--accent);font-weight:700">0</span> 个
      <span class="spacer"></span>
      <span>新建 = 列表底部追加一行，属性在该行下方向下展开编辑</span>
    </div>
    <div id="rows"></div>
  </section>
</main>

<footer>
  <span>保存目录：<span class="path" id="footFolder">FuckYouNFEMobile/</span></span>
  <span>文件名：<span class="path" id="footFile"></span></span>
  <span class="msg" id="footStatus">点「保存」写入 JSON；游戏内约 1 秒自动热重载生效</span>
</footer>

<div id="modal"><div class="box">
  <div class="mhead"><b>JSON 预览（标准 JSON · 按键 = 模拟组合键）</b><span class="spacer"></span><button class="btn primary" onclick="closeModal()">关闭</button></div>
  <pre id="jsonOut"></pre>
  <div class="mfoot"><button class="btn" onclick="copyJson()">复制</button></div>
</div></div>

<script>
"use strict";
/* =========================================================
   文档结构（标准 JSON，即最终保存格式）：
   {
     "editor": "ChartEditor",
     "screenW": 1280, "screenH": 720,
     "buttons": [ {
        "name": "A",            // 按键唯一名（“Button.click” 里的 Button）
        "click": ["ENTER"],     // Button.click = 绑定组合键数组；多个 = 同时按下
        "x": 1148, "y": 585,    // 左上角 [0,0] 基准
        "w": 120, "h": 120,
        "color": "#FF0000",
        "isFather": true,       // 仅父键
        "FuckItKey": ["A","B"], // 仅父键：子键名列表
        "CanSwitch": true,      // 仅父键；T=父键不输出 click，只切换子键
        "SwitchNum": 1,         // CanSwitch=T 时默认 1、最小 1：按 1 次开，再按 N 次关
        "Switch": { "A": { "ENTER": ["SHIFT","ENTER"] } }
     } ]
   }
   省略规则：非父键不写 isFather 之后字段；CanSwitch=F 不写 SwitchNum/Switch。
   ========================================================= */

const SCREEN_W = 1280, SCREEN_H = 720;
const EDITORS = [
  {id:"ChartEditor", name:"编谱器 ChartEditor"},
  {id:"CharacterEditor", name:"角色编辑器 CharacterEditor"},
  {id:"StageEditor", name:"舞台编辑器 StageEditor"},
  {id:"WeekEditor", name:"周目编辑器 WeekEditor"},
  {id:"DialogueEditor", name:"对话编辑器 DialogueEditor"},
  {id:"DialogueCharacterEditor", name:"对话立绘编辑器 DialogueCharacterEditor"},
  {id:"MenuCharacterEditor", name:"菜单角色编辑器 MenuCharacterEditor"},
',
'  {id:"NoteSplashEditor", name:"NoteSplash 编辑器 NoteSplashEditor"},
  {id:"NoteSplashDebug", name:"NoteSplash 调试 NoteSplashDebug"},
];
const COMMON_KEYS = ["UP","DOWN","LEFT","RIGHT","W","A","S","D","ENTER","ESCAPE","TAB","SPACE","BACKSPACE","SHIFT","CONTROL","ALT","Q","E","Z","X","C","V","B","L","1","2","3","4","5","6","7","8","9","0","-","=","[","]","\\\\",";","\'",",",".","/","F1","F2","F5","DELETE","INSERT","HOME","END","PAGEUP","PAGEDOWN","NUMPAD0"];
const PALETTE = ["#12FA05","#00FFFF","#C24B99","#F9393F","#FF0000","#CB00FF","#FFCB00","#44FF00","#49A9B2","#0078FF","#99062D","#4A35B9","#CCB98E","#05FF27","#FF7D00","#EA00FF","#FF009D","#F59E0B","#8B5CF6","#FFFFFF"];

let curEditor = "ChartEditor";
let selSet = new Set();    // 画布/列表选中集合（Ctrl 加选）
let expanded = new Set();  // 属性展开的行
let buttons = [];
let dirty = false;
let drag = null;
let zoom = 1;

/* ---------- 默认数据（编谱器 1280x720 示例） ---------- */
function B(name,click,x,y,color,extra){
  return Object.assign({name,click,x,y,w:120,h:120,color,isFather:false,FuckItKey:[],CanSwitch:false,SwitchNum:1,Switch:{}}, extra||{});
}
function defaultButtons(){
  const h = SCREEN_H;
  const arr = [
    B("UP",   ["W"],            0,      h-255, "#12FA05"),
    B("LEFT", ["A"],            132,    h-255, "#C24B99"),
    B("RIGHT",["D"],            132,    h-135, "#F9393F"),
    B("DOWN", ["S"],            0,      h-135, "#00FFFF"),
    B("K",    [],               0,      h-385, "#05FF27"),
    B("L",    [],               132,    h-385, "#05FF27"),
    B("S",    ["L"],            SCREEN_W-132, h-375, "#49A9B2"),
    B("G",    ["TAB"],          SCREEN_W-258, 25,    "#49A9B2"),
    B("P",    ["Q"],            SCREEN_W-636, h-255, "#49A9B2"),
    B("E",    ["E"],            SCREEN_W-636, h-135, "#49A9B2"),
    B("V",    ["CONTROL","Z"],  SCREEN_W-510, h-255, "#49A9B2"),
    B("D",    ["X"],            SCREEN_W-510, h-135, "#0078FF"),
    B("X",    ["SPACE"],        SCREEN_W-384, h-255, "#99062D"),
    B("C",    ["ESCAPE"],       SCREEN_W-384, h-135, "#44FF00"),
    B("Y",    ["SHIFT"],        SCREEN_W-258, h-255, "#4A35B9"),
    B("B",    ["BACKSPACE"],    SCREEN_W-258, h-135, "#FFCB00"),
    B("Z",    ["Z"],            SCREEN_W-132, h-255, "#CCB98E"),
    B("A",    ["ENTER"],        SCREEN_W-132, h-135, "#FF0000"),
  ];
  arr.push({
    name:"FN", click:[], x:SCREEN_W-132, y:25, w:120, h:120, color:"#F59E0B",
    isFather:true, FuckItKey:["A","B","Z"], CanSwitch:true, SwitchNum:2,
    Switch:{
      "A": [["SHIFT","ENTER"],["CONTROL","A"]],   // 档1：A=SHIFT+ENTER；档2：A=CONTROL+A
      "B": [["CONTROL","S"]],                      // 只配 1 档：档2 时保持原输出
      "Z": [["CONTROL","Z"]]
    },
    desc:"演示父键：短按一次切一档（◉1/◉2），共 2 档，再按回到原输出；按住 = 临时档1"
  });
  return arr;
}
buttons = defaultButtons(); // 连接前先展示示例布局；boot() 连接服务后会按 Editor 实际 JSON 刷新

/* ---------- 工具 ---------- */
function clamp(v,a,c){ return Math.max(a, Math.min(c,v)); }
function btnColor(hex){ const n=parseInt(hex.replace("#",""),16); return {r:(n>>16)&255,g:(n>>8)&255,b:n&255}; }
function textColor(hex){ const {r,g,b}=btnColor(hex); return (r*0.299+g*0.587+b*0.114)>150?"#111":"#fff"; }
function bindText(b){
  if(b.click && b.click.length) return b.click.join(" + ");
  if(b.desc) return b.desc; // 模板里未绑定但有含义说明（如"原版未使用"）
  return b.isFather ? (b.CanSwitch?"切换子键(不输出)":"未绑定") : "未绑定";
}
function find(n){ return buttons.find(b=>b.name===n); }
function setDirty(msg){ dirty = true; if(msg) setFoot(msg,"warn"); }

/* ---------- 画布 ---------- */
const phone = document.getElementById("phone");
function layoutPhone(){
  const wrap = phone.parentElement;
  const fit = Math.min((wrap.clientWidth-40)/SCREEN_W, (wrap.clientHeight-56)/SCREEN_H, 1);
  setZoomPx(zoom * fit);
}
function setZoomPx(s){
  phone._scale = s;
  phone.style.width = (SCREEN_W*s)+"px";
  phone.style.height = (SCREEN_H*s)+"px";
  renderCanvas();
}
/* ---- 画布背景：当前 Editor 的真实界面截图（游戏端 /api/bg 提供） ---- */
let bgEl = null;
function bgImg(){
  if(!bgEl){
    bgEl = document.createElement("img");
    bgEl.className = "bgimg";
    bgEl.alt = "";
  }
  return bgEl;
}
function applyBg(){
  const img = bgImg();
  const on = apiConnected && document.getElementById("bgOn").checked;
  if(!on){ img.style.display = "none"; return; }
  if(img.dataset.ed !== curEditor){
    img.dataset.ed = curEditor;
    img.src = "/api/bg?id=" + encodeURIComponent(curEditor);
    img.onerror = () => { img.style.display = "none"; };
  }
  img.style.opacity = (parseInt(document.getElementById("bgAlpha").value,10) || 55) / 100;
  img.style.display = "block";
}

function renderCanvas(){
  phone.innerHTML = "";
  // 背景图放最底层（renderCanvas 负责挂载，避免拖动时重建导致闪烁）
  if(apiConnected && document.getElementById("bgOn").checked)
    phone.appendChild(bgImg());
  const s = phone._scale || 1;
  const tl = document.createElement("div"); tl.className="tl"; tl.textContent="[0,0]"; phone.appendChild(tl);
  const st = document.createElement("div"); st.className="sizeTag"; st.textContent="1280×720"; phone.appendChild(st);
  const sorted = [...buttons].sort((a,c)=>(a.y*10000+a.x)-(c.y*10000+c.x));
  for(const b of sorted){
    const el = document.createElement("div");
    el.className = "vbtn" + (selSet.has(b.name)?" sel":"") + (b.isFather?" father":"");
    el.style.left = (b.x*s)+"px"; el.style.top = (b.y*s)+"px";
    el.style.width = (b.w*s)+"px"; el.style.height = (b.h*s)+"px";
    if(b.isFather && b.CanSwitch){
      el.style.background = "repeating-linear-gradient(45deg,"+b.color+" 0,"+b.color+" 10px,#00000040 10px,#00000040 13px)";
    } else {
      el.style.background = b.color;
    }
    el.style.color = /^#[0-9a-fA-F]{6}$/.test(b.textColor||"") ? b.textColor : "#FFFFFF"; // 文字颜色，默认白
    const nm = document.createElement("div"); nm.className="bname"; nm.style.fontSize=Math.max(9,14*s)+"px"; nm.textContent=b.name; el.appendChild(nm);
    const bd = document.createElement("div"); bd.className="bbind"; bd.style.fontSize=Math.max(6,9*s)+"px"; bd.textContent=bindText(b); el.appendChild(bd);
',
'    if(b.isFather){ const fm=document.createElement("div"); fm.className="fmark"; fm.style.fontSize=Math.max(7,10*s)+"px"; fm.textContent = b.CanSwitch?("⛶切换"+(b.SwitchNum>1?("×"+b.SwitchNum):"")):"⛶父"; el.appendChild(fm); }
    if(b.FuckItKey && b.FuckItKey.length && !b.CanSwitch){ const bs=document.createElement("div"); bs.className="badge-s"; bs.textContent="子:"+b.FuckItKey.join(","); el.appendChild(bs); }
    el.addEventListener("mousedown", (ev)=>{
      ev.preventDefault(); ev.stopPropagation();
      if(ev.ctrlKey || ev.metaKey){ selSet.has(b.name)?selSet.delete(b.name):selSet.add(b.name); }
      else { selSet = new Set([b.name]); }
      renderCanvas(); renderList();
      startDrag(b.name, ev);
    });
    phone.appendChild(el);
  }
  document.getElementById("selHint").textContent = selSet.size>=2 ? ("已选 "+selSet.size+" 个：对齐/均布作用于选中") : "未选中或仅 1 个：对齐将作用于全部按键";
}
function startDrag(name, ev){
  const b = find(name); if(!b) return;
  drag = {name, startX:b.x, startY:b.y, px:ev.clientX, py:ev.clientY};
}
window.addEventListener("mousemove", (ev)=>{
  if(!drag) return;
  const s = phone._scale || 1;
  const b = find(drag.name); if(!b) return;
  b.x = clamp(Math.round(drag.startX + (ev.clientX-drag.px)/s), 0, SCREEN_W-b.w);
  b.y = clamp(Math.round(drag.startY + (ev.clientY-drag.py)/s), 0, SCREEN_H-b.h);
  renderCanvas(); renderList(); setDirty("位置已更新（拖动），记得保存");
});
window.addEventListener("mouseup", (ev)=>{
  if(!drag) return;
  const snapOn = document.getElementById("snapOn").checked;
  const snap = +document.getElementById("snapSize").value || 20;
  if(snapOn){
    const b = find(drag.name);
    if(b){
      b.x = clamp(Math.round(b.x/snap)*snap, 0, SCREEN_W-b.w);
      b.y = clamp(Math.round(b.y/snap)*snap, 0, SCREEN_H-b.h);
    }
    renderCanvas(); renderList(); setDirty();
  }
  drag = null;
});

/* ---------- 对齐 / 均布 ---------- */
function targets(){
  if(selSet.size>=2) return buttons.filter(b=>selSet.has(b.name));
  return buttons.slice();
}
function align(mode){
  const t = targets();
  if(!t.length) return;
  if(t.length<2) setFoot("只有 1 个按键，按全部处理也无效——请多选（Ctrl+单击）","warn");
  if(mode==="left"||mode==="right"||mode==="top"||mode==="bottom"){
    const ex = (mode==="left"||mode==="right") ? "x" : "y";
    const wh = (mode==="left"||mode==="right") ? "w" : "h";
    let v = (mode==="left"||mode==="top") ? Infinity : -Infinity;
    for(const b of t) v = (mode==="left"||mode==="top") ? Math.min(v,b[ex]) : Math.max(v,b[ex]+b[wh]);
    for(const b of t) b[ex] = (mode==="left"||mode==="top") ? v : v-b[wh];
  } else if(mode==="hc"||mode==="vc"){
    const ex = mode==="hc"?"x":"y", wh = mode==="hc"?"w":"h";
    let min=Infinity, max=-Infinity;
    for(const b of t){ min=Math.min(min,b[ex]); max=Math.max(max,b[ex]+b[wh]); }
    const c = (min+max)/2;
    for(const b of t) b[ex] = Math.round(c - b[wh]/2);
  } else if(mode==="hdist"||mode==="vdist"){
    const ex = mode==="hdist"?"x":"y", wh = mode==="hdist"?"w":"h";
    const sorted = t.slice().sort((a,c)=>a[ex]-c[ex]);
    const first = sorted[0], last = sorted[sorted.length-1];
    const span = (last[ex]+last[wh]) - first[ex];
    const total = sorted.reduce((s,b)=>s+b[wh],0);
    const gap = (span-total)/(sorted.length-1);
    let cur = first[ex];
    for(const b of sorted){ b[ex] = Math.round(cur); cur += b[wh]+gap; }
  }
  for(const b of t){
    b.x = clamp(b.x,0,SCREEN_W-b.w);
    b.y = clamp(b.y,0,SCREEN_H-b.h);
  }
  renderCanvas(); renderList(); setDirty("已执行对齐/均布");
}
["alLeft","alHC","alRight","alTop","alVC","alBottom","alHDist","alVDist"].forEach(id=>{
  document.getElementById(id).onclick = ()=>{
    const map = {alLeft:"left",alHC:"hc",alRight:"right",alTop:"top",alVC:"vc",alBottom:"bottom",alHDist:"hdist",alVDist:"vdist"};
    align(map[id]);
  };
});

/* ---------- 一键整体偏移全部/选中按钮的 X/Y ---------- */
function applyOffset(){
  const dx = Math.round(parseFloat(document.getElementById("offX").value)||0);
  const dy = Math.round(parseFloat(document.getElementById("offY").value)||0);
  if(!dx && !dy){ setFoot("偏移量为 0，没有变化（填 X/Y 偏移，可为负）","warn"); return; }
  const t = targets(); // ≥2 个选中 → 只移选中；否则全部
  if(!t.length) return;
  for(const b of t){
    b.x = clamp(Math.round(b.x + dx), 0, SCREEN_W - b.w);
    b.y = clamp(Math.round(b.y + dy), 0, SCREEN_H - b.h);
  }
  renderCanvas(); renderList();
  setDirty("已整体偏移 "+(selSet.size>=2 ? "选中的 "+t.length+" 个按钮" : "全部 "+t.length+" 个按钮")+"：X"+(dx>=0?"+":"")+dx+"  Y"+(dy>=0?"+":"")+dy);
}
document.getElementById("applyOff").onclick = applyOffset;
document.getElementById("offX").addEventListener("keydown", (e)=>{ if(e.key === "Enter") applyOffset(); });
document.getElementById("offY").addEventListener("keydown", (e)=>{ if(e.key === "Enter") applyOffset(); });

/* ---------- 一键统一全部/选中按钮的宽高 ---------- */
function applySize(){
  const wRaw = document.getElementById("setW").value.trim();
  const hRaw = document.getElementById("setH").value.trim();
  const nw = wRaw !== "" ? Math.max(20, Math.round(parseFloat(wRaw)||0)) : null;
  const nh = hRaw !== "" ? Math.max(20, Math.round(parseFloat(hRaw)||0)) : null;
  if(nw === null && nh === null){ setFoot("宽和高都留空，没有变化","warn"); return; }
  const t = targets(); // ≥2 个选中 → 只改选中；否则全部
  if(!t.length) return;
  for(const b of t){
    if(nw !== null) b.w = Math.min(nw, SCREEN_W);
    if(nh !== null) b.h = Math.min(nh, SCREEN_H);
  }
  renderCanvas(); renderList();
  setDirty("已统一 "+(selSet.size>=2 ? "选中 "+t.length+" 个按钮" : "全部 "+t.length+" 个按钮")+" 的尺寸："+(nw!==null?"W="+nw:"")+(nw!==null&&nh!==null?"  ":"")+(nh!==null?"H="+nh:""));
}
document.getElementById("applySize").onclick = applySize;
document.getElementById("setW").addEventListener("keydown", (e)=>{ if(e.key === "Enter") applySize(); });
document.getElementById("setH").addEventListener("keydown", (e)=>{ if(e.key === "Enter") applySize(); });

const zoomR = document.getElementById("zoomR"), zoomV = document.getElementById("zoomV");
',
'zoomR.oninput = ()=>{ zoom = +zoomR.value/100; zoomV.textContent = zoomR.value+"%"; layoutPhone(); };

/* ---------- 列表 ---------- */
function rowEl(b){
  const row = document.createElement("div");
  row.className = "row" + (selSet.has(b.name)?" sel":"");
  const main = document.createElement("div"); main.className="rowMain";
  main.onclick = (ev)=>{
    if(ev.ctrlKey || ev.metaKey){ selSet.has(b.name)?selSet.delete(b.name):selSet.add(b.name); }
    else { selSet = new Set([b.name]); if(!expanded.has(b.name)){ expanded.add(b.name); } }
    renderCanvas(); renderList();
  };
  const sw = document.createElement("div"); sw.className="swatch"; sw.style.background=b.color; sw.style.color=/^#[0-9a-fA-F]{6}$/.test(b.textColor||"")?b.textColor:"#FFFFFF"; sw.style.textShadow="0 1px 2px rgba(0,0,0,.7)"; sw.textContent=b.name;
  const meta = document.createElement("div"); meta.className="meta";
  const t1 = document.createElement("div"); t1.className="t1";
  const nm = document.createElement("span"); nm.className="name"; nm.textContent=b.name;
  const tag = document.createElement("span"); tag.className="tag"+(b.isFather?" f":"");
  tag.textContent = !b.isFather ? "普通" : (b.CanSwitch ? ("父键·切换×"+b.SwitchNum) : "父键");
  t1.appendChild(nm); t1.appendChild(tag);
  // 第一行元信息：绑定键（或未绑定时直接给含义）…
  const bd = document.createElement("div"); bd.className="bind";
  bd.textContent = bindText(b);
  meta.appendChild(t1); meta.appendChild(bd);
  // …含义单独一行小字（灰色），不跟绑定混在一起
  const descLine = document.createElement("div"); descLine.className="bindDesc";
  if(b.desc) descLine.textContent = b.desc;
  if(b.FuckItKey && b.FuckItKey.length){
    descLine.textContent += (descLine.textContent ? "　|　" : "") + "子键:" + b.FuckItKey.join("、");
  }
  if(descLine.textContent) meta.appendChild(descLine);
  const xy = document.createElement("div"); xy.className="xy"; xy.textContent = Math.round(b.x)+", "+Math.round(b.y);
  const expBtn = document.createElement("button"); expBtn.className="rbtn"; expBtn.textContent = expanded.has(b.name)?"▲":"▼"; expBtn.title="展开/收起属性（向下）";
  expBtn.onclick = (ev)=>{ ev.stopPropagation(); expanded.has(b.name)?expanded.delete(b.name):expanded.add(b.name); renderList(); };
  const delBtn = document.createElement("button"); delBtn.className="rbtn del"; delBtn.textContent="✕"; delBtn.title="删除该按键";
  delBtn.onclick = (ev)=>{ ev.stopPropagation(); if(!confirm("删除按键 "+b.name+" ？")) return; removeButton(b.name); };
  main.appendChild(sw); main.appendChild(meta); main.appendChild(xy); main.appendChild(expBtn); main.appendChild(delBtn);
  row.appendChild(main);
  if(expanded.has(b.name)) row.appendChild(propForm(b));
  return row;
}
function renderList(){
  const box = document.getElementById("rows"); box.innerHTML="";
  document.getElementById("cnt").textContent = buttons.length;
  if(!buttons.length){
    const e=document.createElement("div"); e.className="empty";
    e.innerHTML = "该 Editor 还没有自定义按键。<br>点上方 <b>「＋ 新建按键」</b> 在列表底部向下追加一行并就地编辑属性，<br>或 <b>「从默认键位生成」</b> 载入该 Editor 的默认键位（每个键都标注等价键值对与含义）。";
    box.appendChild(e); return;
  }
  for(const b of buttons) box.appendChild(rowEl(b));
}

/* ---------- 新建 / 删除（向下） ---------- */
function addButton(){
  let i=1, name="BTN"+i;
  while(find(name)){ i++; name="BTN"+i; }
  const base = B(name, [], 60, 60, "#8B5CF6");
  base.click = [];
  buttons.push(base);
  selSet = new Set([name]); expanded.add(name);
  renderCanvas(); renderList();
  const rows = document.getElementById("rows");
  if(rows.lastElementChild) rows.lastElementChild.scrollIntoView({behavior:"smooth", block:"nearest"});
  setDirty("已新建 "+name+" —— 属性在该行下方展开，编辑完记得保存");
}
function removeButton(name){
  buttons = buttons.filter(b=>b.name!==name);
  for(const b of buttons){
    b.FuckItKey = (b.FuckItKey||[]).filter(c=>c!==name);
    if(b.Switch) delete b.Switch[name];
  }
  selSet.delete(name); expanded.delete(name);
  renderCanvas(); renderList(); setDirty("已删除 "+name);
}

/* ---------- 属性表单（行下方向下展开） ---------- */
function fieldL(label, hint){
  const l = document.createElement("label");
  l.innerHTML = "<b>"+label+" <span class=\'hint\'>"+hint+"</span></b>";
  return l;
}
/* ================= 绑定组合键：录制（按键盘）→ 鼠标确认 ================= */
const CAPTURE_ORDER = ["CONTROL","SHIFT","ALT"];
let activeCapture = null; // { keydown, keyup }

function capKeyName(code){
  if(/^Key[A-Z]$/.test(code)) return code.slice(3);
  if(/^Digit[0-9]$/.test(code)) return code.slice(5);
  if(/^Numpad[0-9]$/.test(code)) return "NUMPAD" + code.slice(6);
  if(/^F([1-9]|1[0-2])$/.test(code)) return code;
  const m = {
    Space:"SPACE", Enter:"ENTER", Tab:"TAB", Backspace:"BACKSPACE", Delete:"DELETE",
    Insert:"INSERT", Home:"HOME", End:"END", PageUp:"PAGEUP", PageDown:"PAGEDOWN",
    ArrowUp:"UP", ArrowDown:"DOWN", ArrowLeft:"LEFT", ArrowRight:"RIGHT",
    ShiftLeft:"SHIFT", ShiftRight:"SHIFT", ControlLeft:"CONTROL", ControlRight:"CONTROL",
    AltLeft:"ALT", AltRight:"ALT",
    Minus:"-", Equal:"=", BracketLeft:"[", BracketRight:"]", Backslash:"\\\\",
    Semicolon:";", Quote:"\'", Comma:",", Period:".", Slash:"/", Backquote:"`"
  };
  return m[code] || null;
}
function stopCapture(){
  if(activeCapture){
    window.removeEventListener("keydown", activeCapture.keydown);
    window.removeEventListener("keyup", activeCapture.keyup);
    activeCapture = null;
  }
}
function startCapture(b, ui){
  stopCapture();
  let captured = [];
  const sortKeys = (a)=> a.slice().sort((x,y)=> (CAPTURE_ORDER.indexOf(x)-CAPTURE_ORDER.indexOf(y)) || (x<y?-1:1));
  const render = ()=>{
    ui.preview.innerHTML = "";
    const list = sortKeys(captured);
    for(const k of list){
      const c = document.createElement("span"); c.className="chip used"; c.textContent = k;
      ui.preview.appendChild(c);
    }
    if(!list.length){ ui.preview.textContent = "等待按键…（Ctrl/Shift/Alt + 主键，Esc 取消）"; }
    ui.okBtn.disabled = list.length === 0 || list.every(k=>CAPTURE_ORDER.includes(k));
  };
  const keydown = (e)=>{
    e.preventDefault(); e.stopPropagation();
',
'    if(e.repeat) return;
    if(e.key === "Escape"){ stopCapture(); if(ui.onDone) ui.onDone(); return; }
    if(e.key === "Enter" && captured.length){ confirmCap(); return; }
    const n = capKeyName(e.code);
    if(n && !captured.includes(n)){ captured.push(n); render(); }
  };
  const keyup = (e)=>{
    e.preventDefault(); e.stopPropagation();
    // 不删除已捕获键；用户松开后看预览用鼠标确认
  };
  const confirmCap = ()=>{
    const list = sortKeys(captured);
    if(!list.length || list.every(k=>CAPTURE_ORDER.includes(k))){ return; }
    b.click = list;
    stopCapture();
    if(ui.onDone) ui.onDone();
    if(ui.apply) ui.apply(list); // 由 propForm 提供：刷新绑定 chips/画布/列表
  };
  ui.okBtn.onclick = confirmCap;
  ui.clrBtn.onclick = ()=>{ captured = []; render(); }; // 录制中：清空已按的键，继续录
  activeCapture = { keydown, keyup };
  window.addEventListener("keydown", keydown);
  window.addEventListener("keyup", keyup);
  render();
}

function propForm(b){
  const p = document.createElement("div"); p.className="props";
  const mark = ()=>{ renderCanvas(); renderList(); setDirty(); };
  const leftCol = document.createElement("div"); leftCol.className="pcol";
  const rightCol = document.createElement("div"); rightCol.className="pcol";

  /* ===== 左列 ===== */
  // 名称
  const fName = fieldL("名称 (name)","唯一标识；Button.click 里的 Button");
  const inName = document.createElement("input"); inName.type="text"; inName.value=b.name;
  inName.onchange = ()=>{
    const v = inName.value.trim();
    const ok = nameOk(v);
    if(!ok || buttons.some(o=>o.name===v && o!==b)){
      alert(!ok ? "名称不规范："+(v||"(空)")+"\\n允许中文/字母/数字/空格与 + - . ( ) 等，最长 24 个字符；不能含引号/反斜杠/逗号/花括号。" : "名称重复："+v);
      inName.value = b.name; return;
    }
    const old = b.name;
    if(expanded.has(old)){ expanded.delete(old); expanded.add(v); }
    if(selSet.has(old)){ selSet.delete(old); selSet.add(v); }
    buttons.forEach(o=>{ o.FuckItKey = (o.FuckItKey||[]).map(c=>c===old?v:c); if(o.Switch && o.Switch[old]){ o.Switch[v]=o.Switch[old]; delete o.Switch[old]; } });
    b.name = v; mark();
  };
  fName.appendChild(inName); leftCol.appendChild(fName);

  // x / y / w / h
  const fX = fieldL("x","左边界(px)，0.."+(SCREEN_W-b.w));
  const inX = document.createElement("input"); inX.type="number"; inX.value=Math.round(b.x);
  inX.onchange = ()=>{ b.x = clamp(+inX.value||0,0,SCREEN_W-b.w); mark(); };
  fX.appendChild(inX); leftCol.appendChild(fX);
  const fY = fieldL("y","上边界(px)，0.."+(SCREEN_H-b.h));
  const inY = document.createElement("input"); inY.type="number"; inY.value=Math.round(b.y);
  inY.onchange = ()=>{ b.y = clamp(+inY.value||0,0,SCREEN_H-b.h); mark(); };
  fY.appendChild(inY); leftCol.appendChild(fY);
  const fW = fieldL("w","宽(px)");
  const inW = document.createElement("input"); inW.type="number"; inW.min=20; inW.value=Math.round(b.w);
  inW.onchange = ()=>{ b.w=Math.max(20,+inW.value||120); mark(); };
  fW.appendChild(inW); leftCol.appendChild(fW);
  const fH = fieldL("h","高(px)");
  const inH = document.createElement("input"); inH.type="number"; inH.min=20; inH.value=Math.round(b.h);
  inH.onchange = ()=>{ b.h=Math.max(20,+inH.value||120); mark(); };
  fH.appendChild(inH); leftCol.appendChild(fH);

  // 父键 / CanSwitch / SwitchNum
  const fFath = fieldL("父键 (isFather)","勾选后可挂子键/切换规则");
  const cbF = document.createElement("label"); cbF.className="cb";
  const chF = document.createElement("input"); chF.type="checkbox"; chF.checked=!!b.isFather;
  chF.onchange = ()=>{
    b.isFather = chF.checked;
    if(!b.isFather){ b.CanSwitch=false; }
    renderList(); renderCanvas(); setDirty();
  };
  cbF.appendChild(chF); cbF.appendChild(document.createTextNode("是父键"));
  fFath.appendChild(cbF); leftCol.appendChild(fFath);

  const fCS = fieldL("CanSwitch","T=父键不再输出 click，只切换子键键值对");
  const cbCS = document.createElement("label"); cbCS.className="cb";
  const chCS = document.createElement("input"); chCS.type="checkbox"; chCS.disabled=!b.isFather; chCS.checked=!!b.CanSwitch;
  chCS.onchange = ()=>{
    b.CanSwitch = chCS.checked;
    if(b.CanSwitch && (!b.SwitchNum || b.SwitchNum<1)) b.SwitchNum = 1; // CanSwitch=T：默认 1 且不小于 1
    renderList(); renderCanvas(); setDirty();
  };
  cbCS.appendChild(chCS); cbCS.appendChild(document.createTextNode("允许父键更改子键键值对"));
  fCS.appendChild(cbCS); leftCol.appendChild(fCS);

  const fSN = fieldL("SwitchNum (档数)","≥1。每按一次父键切到下一档，共 N 档，最后一档后再按一次回到原输出（1 = 按一下开、再按一下回；2 = 两档轮换）");
  const inSN = document.createElement("input"); inSN.type="number"; inSN.min=1; inSN.disabled=!(b.isFather&&b.CanSwitch); inSN.value = b.isFather&&b.CanSwitch ? Math.max(1,b.SwitchNum||1) : b.SwitchNum||1;
  inSN.onchange = ()=>{
    b.SwitchNum = Math.max(1, Math.round(+inSN.value||1));
    // 联动：每个子键的档列表补齐/截断到 SwitchNum 档
    for(const c of (b.FuckItKey||[])){
      const arr = b.Switch[c] || (b.Switch[c] = []);
      while(arr.length < b.SwitchNum) arr.push({keys:[],NameChinese:"",NameEnglish:""});
      if(arr.length > b.SwitchNum) arr.length = b.SwitchNum;
    }
    renderList(); setDirty();
  };
  fSN.appendChild(inSN); leftCol.appendChild(fSN);

  /* ===== 右列 ===== */
  // 绑定组合键（录制 → 鼠标确认）
  const fBind = fieldL("绑定组合键 (click)","点「录制」后直接按键盘组合（可带 Ctrl/Shift/Alt），松开后鼠标点确认");
  const bindChips = document.createElement("div"); bindChips.className="keychips";
  const capBar = document.createElement("div"); capBar.className="capBar";
  const recBtn = document.createElement("button"); recBtn.className="swAdd"; recBtn.textContent = "🎯 录制组合键";
  const preview = document.createElement("span"); preview.className="capPreview";
  const okBtn = document.createElement("button"); okBtn.className="swAdd"; okBtn.textContent = "✓ 确认";
  okBtn.style.color = "var(--ok)"; okBtn.disabled = true;
  const clrBtn = document.createElement("button"); clrBtn.className="swAdd"; clrBtn.textContent = "✕ 重录";
  capBar.appendChild(recBtn); capBar.appendChild(preview); capBar.appendChild(okBtn); capBar.appendChild(clrBtn);
  const renderBindChips = ()=>{
    bindChips.innerHTML = "";
',
'    if(!b.click.length){ bindChips.innerHTML = "<span class=\'note\' style=\'margin:0\'>未绑定（或父键 CanSwitch=T 时不输出）</span>"; return; }
    for(const k of b.click){
      const c = document.createElement("span"); c.className="chip used"; c.textContent = k;
      c.title = "点此从组合中移除该键";
      c.onclick = ()=>{ b.click = b.click.filter(x=>x!==k); renderBindChips(); renderCanvas(); renderList(); setDirty(); };
      bindChips.appendChild(c);
    }
    const clearAll = document.createElement("span"); clearAll.className="chip"; clearAll.textContent = "✕ 清空";
    clearAll.onclick = ()=>{ b.click = []; renderBindChips(); renderCanvas(); renderList(); setDirty(); };
    bindChips.appendChild(clearAll);
  };
  const clearBind = ()=>{ if(activeCapture) return; b.click = []; renderBindChips(); renderCanvas(); renderList(); setDirty(); };
  clrBtn.onclick = clearBind;
  const resetRec = ()=>{
    recBtn.classList.remove("recOn");
    recBtn.textContent = "🎯 录制组合键";
    okBtn.disabled = true;
    clrBtn.disabled = false;
    clrBtn.textContent = "✕ 重录";
    clrBtn.onclick = clearBind;
  };
  recBtn.onclick = ()=>{
    if(activeCapture){ stopCapture(); resetRec(); return; } // 再次点击 = 停止录制
    recBtn.classList.add("recOn");
    recBtn.textContent = "⏺ 录制中…（按组合键，Esc 取消）";
    okBtn.disabled = true;
    clrBtn.disabled = false;
    clrBtn.textContent = "✕ 清空已按";
    renderBindChips();
    startCapture(b, {
      preview, okBtn, clrBtn, recBtn, onDone: resetRec,
      apply: (list)=>{ b.click = list; renderBindChips(); renderCanvas(); renderList(); setDirty("绑定已更新："+bindText(b)); }
    });
  };
  okBtn.onclick = ()=>{ /* 由 startCapture 接管（确认在录制态有效） */ };
  renderBindChips();
  fBind.appendChild(bindChips); fBind.appendChild(capBar); rightCol.appendChild(fBind);

  // 颜色
  const fCol = fieldL("颜色 (color)","#RRGGBB");
  const inCol = document.createElement("input"); inCol.type="color"; inCol.value = /^#[0-9a-fA-F]{6}$/.test(b.color)?b.color:"#8B5CF6";
  inCol.onchange = ()=>{ b.color = inCol.value.toUpperCase(); mark(); };
  fCol.appendChild(inCol);
  const pal = document.createElement("div"); pal.className="keychips";
  for(const c of PALETTE){
    const sw = document.createElement("span"); sw.className="chip sw"; sw.style.background=c; sw.title=c;
    sw.onclick = ()=>{ b.color=c; inCol.value=c; mark(); };
    pal.appendChild(sw);
  }
  fCol.appendChild(pal); rightCol.appendChild(fCol);

  // 文字颜色（默认白 #FFFFFF；老文件没有该字段时同样按白处理）
  const fTCol = fieldL("文字颜色 (textColor)","按键上文字的显示颜色；默认 #FFFFFF（白色，为默认值时不写入文件）");
  const inTCol = document.createElement("input"); inTCol.type="color";
  inTCol.value = /^#[0-9a-fA-F]{6}$/.test(b.textColor||"") ? b.textColor : "#FFFFFF";
  inTCol.onchange = ()=>{ b.textColor = inTCol.value.toUpperCase(); mark(); };
  fTCol.appendChild(inTCol);
  const tpal = document.createElement("div"); tpal.className="keychips";
  for(const c of ["#FFFFFF","#000000","#F2F3F5","#FFE066","#FF6B6B","#7CFF7C","#66D9FF","#D6B3FF","#FFB86C","#FF8FD8"]){
    const sw = document.createElement("span"); sw.className="chip sw"; sw.style.background=c; sw.title=c + (c==="#FFFFFF"?"（默认白）":"");
    sw.onclick = ()=>{ b.textColor = c; inTCol.value = c; mark(); };
    tpal.appendChild(sw);
  }
  fTCol.appendChild(tpal); rightCol.appendChild(fTCol);

  p.appendChild(leftCol);
  p.appendChild(rightCol);

  // 子键 + Switch（仅父键，全宽）——档位模型：每按一次父键切到下一档，
  // 共 SwitchNum 档，最后一档后再按一次回到原输出（SwitchNum=1：按一下开、再按一下回）。
  if(b.isFather){
    const sub = document.createElement("div"); sub.className="subsec full";
    const t1 = document.createElement("div"); t1.className="ttl";
    t1.innerHTML = "子键 (FuckItKey) <span class=\'h\'>— 勾选本文件里哪些按键属于该父键；父键生效时它们的输出被切换</span>";
    sub.appendChild(t1);
    const others = buttons.filter(o=>o.name!==b.name);
    const chipBox = document.createElement("div"); chipBox.className="keychips";
    if(!others.length){ const n=document.createElement("span"); n.className="note"; n.textContent="（暂无其它按键，先新建几个普通按键）"; chipBox.appendChild(n); }
    for(const o of others){
      const c = document.createElement("span"); c.className="chip"+(b.FuckItKey.includes(o.name)?" used":"");
      c.textContent = o.name + " → " + bindText(o);
      c.onclick = ()=>{
        const arr = b.FuckItKey.slice(); const i = arr.indexOf(o.name);
        i>=0 ? arr.splice(i,1) : arr.push(o.name);
        b.FuckItKey = arr;
        if(!b.Switch[o.name]) b.Switch[o.name] = [];
        renderList(); renderCanvas(); setDirty();
      };
      chipBox.appendChild(c);
    }
    sub.appendChild(chipBox);

    const t2 = document.createElement("div"); t2.className="ttl"; t2.style.marginTop="14px";
    t2.innerHTML = "切换档位 (Switch) <span class=\'h\'>— 每个子键可配 N 档（N=左列 SwitchNum）。短按一次父键切到下一档：原输出 → 档1 → 档2 … → 最后一档后再按一次回到原输出；按住父键期间临时用档1。每档可填输出键 + 显示名（切到该档时子键按钮文字变成该名，中文/English 按游戏语言取用；留空名字=保持原按钮名）</span>";
    sub.appendChild(t2);
    const kids = buttons.filter(o=>b.FuckItKey.includes(o.name));
    if(!kids.length){
      const n=document.createElement("div"); n.className="note"; n.textContent="先在「子键 (FuckItKey)」里勾选子键，再为它们配置各档输出。";
      sub.appendChild(n);
    }
    for(const k of kids){
      const seg = document.createElement("div"); seg.className="subsec";
      const ttl = document.createElement("div"); ttl.className="ttl";
      ttl.textContent = "子键 "+k.name+"（原输出："+bindText(k)+"）";
      seg.appendChild(ttl);
      const rawStages = b.Switch[k.name];
      const stages = (Array.isArray(rawStages) ? rawStages : (b.Switch[k.name] = []));
      // 统一为对象档（兼容离线演示/旧格式的纯键数组档）
      const normStages = normalizeStages(stages);
      stages.length = 0;
      for(const s of normStages) stages.push(s);
      const targetCount = Math.max(1, b.SwitchNum||1);
      while(stages.length < targetCount) stages.push({keys:[],NameChinese:"",NameEnglish:""});
      if(stages.length > targetCount) stages.length = targetCount;
      for(let si=0; si<stages.length; si++){
        const st = stages[si];
',
'        if(!st || typeof st !== "object" || !Array.isArray(st.keys)) { stages[si] = {keys:[],NameChinese:"",NameEnglish:""}; continue; }
        const box = document.createElement("div"); box.className="subsec";
        const head = document.createElement("div"); head.className="swrow";
        const lab = document.createElement("span"); lab.className="arrow"; lab.textContent = "档 "+(si+1);
        lab.style.minWidth = "34px";
        const kIn = document.createElement("input"); kIn.type="text";
        kIn.value = st.keys.join(",");
        kIn.placeholder = "该档输出键，如 I 或 SHIFT,ENTER（留空=该档不切换）";
        kIn.onchange = ()=>{
          const v = kIn.value.trim();
          st.keys = v ? v.split(",").map(x=>x.trim().toUpperCase()).filter(Boolean) : [];
          renderList(); setDirty();
        };
        const del = document.createElement("button"); del.className="miniDel"; del.title="清空此档（保持原输出）"; del.textContent="✕";
        del.onclick = ()=>{ st.keys=[]; st.NameChinese=""; st.NameEnglish=""; renderList(); setDirty(); };
        head.appendChild(lab); head.appendChild(kIn); head.appendChild(del);
        box.appendChild(head);
        // 显示名（切到该档时子键按钮上显示的名字，按游戏语言取中文/English）
        const nrow = document.createElement("div"); nrow.className="swrow";
        const nlab = document.createElement("span"); nlab.className="arrow"; nlab.textContent = "名称";
        nlab.style.minWidth = "34px";
        const zhIn = document.createElement("input"); zhIn.type="text";
        zhIn.value = st.NameChinese || "";
        zhIn.placeholder = "中文名，如：摄像机上移";
        zhIn.onchange = ()=>{ st.NameChinese = zhIn.value.trim(); renderList(); setDirty(); };
        const enIn = document.createElement("input"); enIn.type="text";
        enIn.value = st.NameEnglish || "";
        enIn.placeholder = "English，如：Camera Up";
        enIn.onchange = ()=>{ st.NameEnglish = enIn.value.trim(); renderList(); setDirty(); };
        nrow.appendChild(nlab); nrow.appendChild(zhIn); nrow.appendChild(enIn);
        box.appendChild(nrow);
        seg.appendChild(box);
      }
      const addBtn = document.createElement("button"); addBtn.className="swAdd";
      addBtn.textContent = "＋ 添加一条切换（"+k.name+"，SwitchNum → "+(targetCount+1)+"）";
      addBtn.onclick = ()=>{
        b.SwitchNum = targetCount + 1;
        if(inSN) inSN.value = b.SwitchNum;
        stages.push({keys:[],NameChinese:"",NameEnglish:""});
        renderList(); setDirty();
      };
      seg.appendChild(addBtn);
      sub.appendChild(seg);
    }
    p.appendChild(sub);
  }

  // 该按键的 JSON 段预览
  const jsonWrap = document.createElement("div"); jsonWrap.className="full";
  const jb = document.createElement("button"); jb.className="btnJson"; jb.textContent = "该按键的 JSON（点此展开/收起）";
  const jpre = document.createElement("pre"); jpre.className="jsonBox"; jpre.style.display="none";
  jpre.textContent = JSON.stringify(cleanButton(b), null, 2);
  jb.onclick = ()=>{ jpre.style.display = jpre.style.display==="none"?"block":"none"; };
  jsonWrap.appendChild(jb); jsonWrap.appendChild(jpre); p.appendChild(jsonWrap);

  const note = document.createElement("div"); note.className="note full";
  note.innerHTML = "字段映射：<code>Button.click</code> = click（绑定组合键数组） · <code>x/y</code>（左上角[0,0]基准） · <code>color</code> · <code>textColor</code>(文字色，默认白 #FFFFFF，默认值不写盘) · <code>isFather</code> · <code>FuckItKey</code>(子键) · <code>CanSwitch</code> · <code>SwitchNum</code>(档数) · <code>Switch.&lt;子键&gt; = [档1, 档2, …]</code>，档可为纯键数组或 <code>{keys, NameChinese, NameEnglish}</code>。保存为严格 JSON。";
  p.appendChild(note);
  return p;
}

function parseKeys(str){
  return (str||"").split(/[,+]/).map(s=>s.trim().toUpperCase()).filter(Boolean);
}

/* 按键名规则：可读的自然命名都允许（中文/字母/数字/空格与 + - . ( ) [ ] / 等），
   只禁止引号、反斜杠、逗号、分号、花括号等容易混淆 JSON/显示的字符，最长 24 */
function nameOk(n){
  if(typeof n !== "string") return false;
  n = n.trim();
  if(!n || n.length > 24) return false;
  return !/[\\\\"\'`,;{}[\\]\\n\\r]/.test(n);
}
function normalizeStages(v){
  // Switch.<子键> 档数据：统一为 [{keys:[], NameChinese:\'\', NameEnglish:\'\'}, ...]
  // 兼容：纯键数组 ["I"]、["I","J"]、旧对象 { "原绑定":[目标..] }
  const mk = (keys, o)=>{
    const st = { keys: Array.isArray(keys) ? keys.slice() : [], NameChinese: "", NameEnglish: "" };
    if(o && typeof o === "object"){
      if(typeof o.NameChinese === "string") st.NameChinese = o.NameChinese;
      if(typeof o.NameEnglish === "string") st.NameEnglish = o.NameEnglish;
    }
    return st;
  };
  if(Array.isArray(v)){
    if(!v.length) return [];
    const isStageList = v.length && (Array.isArray(v[0]) || (v[0] && typeof v[0] === "object"));
    if(isStageList){
      return v.map(item=>{
        if(Array.isArray(item)) return mk(item);
        if(item && typeof item === "object"){
          const k = Array.isArray(item.keys) ? item.keys : (Array.isArray(item.click) ? item.click : []);
          return mk(k, item);
        }
        return mk([]);
      }).filter(s=>s.keys.length || s.NameChinese || s.NameEnglish);
    }
    return [mk(v)]; // ["A","B"] 简写 = 单档
  }
  if(v && typeof v === "object"){
    // 旧格式 { "原绑定": [目标..] } → 每个目标当一档
    const out = [];
    for(const k of Object.keys(v)){ const to = v[k]; if(Array.isArray(to) && to.length) out.push(mk(to)); }
    return out;
  }
  return [];
}
function normalizeButton(o){
  if(!o || typeof o !== "object") o = {};
  const sw = {};
  if(o.Switch && typeof o.Switch === "object"){
    for(const c of Object.keys(o.Switch)) sw[c] = normalizeStages(o.Switch[c]);
  }
  return {
    name: o.name || "",
    click: Array.isArray(o.click) ? o.click.slice() : [],
    x: typeof o.x === "number" ? o.x : 0,
    y: typeof o.y === "number" ? o.y : 0,
    w: typeof o.w === "number" ? o.w : 120,
    h: typeof o.h === "number" ? o.h : 120,
    color: typeof o.color === "string" && o.color ? o.color : "#8B5CF6",
    textColor: typeof o.textColor === "string" && /^#[0-9a-fA-F]{6}$/.test(o.textColor) ? o.textColor : "#FFFFFF",
    desc: typeof o.desc === "string" ? o.desc : "",
',
'    isFather: !!o.isFather,
    FuckItKey: Array.isArray(o.FuckItKey) ? o.FuckItKey.slice() : [],
    CanSwitch: !!o.CanSwitch,
    SwitchNum: typeof o.SwitchNum === "number" ? o.SwitchNum : 1,
    Switch: sw
  };
}

/* ---------- 序列化（按省略规则生成干净 JSON） ---------- */
function cleanButton(b){
  const o = {name:b.name, click:(b.click||[]).slice(), x:Math.round(b.x), y:Math.round(b.y), w:Math.round(b.w), h:Math.round(b.h), color:b.color};
  if(b.desc) o.desc = b.desc; // 含义注释（模板/编辑提示），引擎读取时忽略
  // 文字颜色：默认白 #FFFFFF 时不写盘（老文件没有该字段 = 白色，向前兼容）
  if(b.textColor && String(b.textColor).toUpperCase() !== "#FFFFFF") o.textColor = String(b.textColor).toUpperCase();
  if(b.isFather){
    o.isFather = true;
    o.FuckItKey = (b.FuckItKey||[]).slice();
    o.CanSwitch = !!b.CanSwitch;
    if(b.CanSwitch){
      o.SwitchNum = Math.max(1, b.SwitchNum||1);
      // Switch.<子键名> = [档1, 档2, …]；档无显示名时保持纯键数组，有名字时输出 {keys, NameChinese, NameEnglish}
      const sw = {};
      for(const c of (b.FuckItKey||[])){
        const stages = (b.Switch||{})[c] || [];
        const outStages = [];
        for(const s of stages){
          if(Array.isArray(s)){ if(s.length) outStages.push(s.slice()); continue; } // 纯键数组档（旧格式）
          if(!s || !Array.isArray(s.keys) || !s.keys.length) continue;
          if((s.NameChinese||"") || (s.NameEnglish||"")){
            const so = {keys: s.keys.slice()};
            if(s.NameChinese) so.NameChinese = s.NameChinese;
            if(s.NameEnglish) so.NameEnglish = s.NameEnglish;
            outStages.push(so);
          } else {
            outStages.push(s.keys.slice());
          }
        }
        if(outStages.length) sw[c] = outStages;
      }
      if(Object.keys(sw).length) o.Switch = sw;
    }
  }
  return o;
}
function docJson(){
  const doc = {editor:curEditor, screenW:SCREEN_W, screenH:SCREEN_H, buttons:buttons.map(cleanButton)};
  const err = validateDoc(doc);
  return {text: JSON.stringify(doc, null, 2), err};
}
function validateDoc(doc){
  const names = new Set();
  for(const b of doc.buttons){
    if(!nameOk(b.name)) return "按键名非法："+(b.name||"(空)")+"（允许中文/字母/数字/空格与 + - . ( ) 等，最长 24，不能含引号/反斜杠/逗号/花括号）";
    if(names.has(b.name)) return "按键名重复："+b.name;
    names.add(b.name);
    const fk = b.FuckItKey || [];
    if(!b.click.length && !b.isFather && !b.desc) return "按键 "+b.name+" 未绑定任何键，且不是父键";
    if(b.isFather && b.CanSwitch){
      if(b.SwitchNum < 1) return "父键 "+b.name+"：CanSwitch=T 时 SwitchNum 必须 ≥1";
      if(!fk.length) return "父键 "+b.name+" 开了 CanSwitch 但没有子键";
    }
    for(const c of fk) if(!names.has(c) && !doc.buttons.some(o=>o.name===c)) return "父键 "+b.name+" 的子键不存在："+c;
    for(const c of Object.keys(b.Switch||{})) if(!fk.includes(c)) return "父键 "+b.name+" 的 Switch 里含非子键："+c;
  }
  return null;
}

/* ---------- 顶栏 ---------- */
const edSel = document.getElementById("edSel");
EDITORS.forEach(e=>{ const o=document.createElement("option"); o.value=e.id; o.textContent=e.name; edSel.appendChild(o); });
edSel.value = curEditor;
edSel.onchange = ()=>{
  if(dirty && !confirm("切换 Editor 会丢弃未保存的修改，继续？")){ edSel.value = curEditor; return; }
  curEditor = edSel.value;
  try{ localStorage.setItem("emkEditor", curEditor); }catch(e){}
  dirty = false;
  buttons = [];
  expanded.clear(); selSet.clear();
  refreshHead(); renderCanvas(); renderList();
  if(apiConnected) loadEditor(curEditor);
  else {
    // 离线演示：所有 Editor 暂时都展示同一份编谱器示例布局
    buttons = defaultButtons();
    expanded.clear(); selSet.clear();
    refreshHead(); renderCanvas(); renderList();
    setFoot("离线演示：所有 Editor 暂时显示编谱器示例布局；请先在游戏 维护设置 开启开关连接后，即可看到各 Editor 真实的默认键位","err");
  }
};
document.getElementById("btnNew").onclick = addButton;
document.getElementById("bgOn").onchange = () => { renderCanvas(); applyBg(); };
document.getElementById("bgAlpha").oninput = () => {
  document.getElementById("bgAlphaV").textContent = document.getElementById("bgAlpha").value + "%";
  applyBg();
};
document.getElementById("btnTemplate").onclick = async ()=>{
  if(!confirm("用该 Editor 的默认虚拟按键覆盖当前列表？")) return;
  if(apiConnected){
    const r = await apiJson("/api/template?id="+encodeURIComponent(curEditor));
    if(r && r.ok && r.text){ try{ const doc = JSON.parse(r.text); buttons = (doc.buttons||[]).map(normalizeButton); }catch(e){ setFoot("模板解析失败："+e, "err"); return; } }
  } else {
    buttons = defaultButtons();
    setFoot("离线演示：所有 Editor 暂时显示编谱器示例布局；请先在游戏 维护设置 开启开关连接后，即可看到各 Editor 真实的默认键位","err");
  }
  selSet.clear(); expanded.clear();
  renderCanvas(); renderList();
  if(apiConnected) setDirty("已载入该 Editor 的默认键位模板（含键值对与含义），可在此基础上修改");
};
document.getElementById("btnPreview").onclick = ()=>{
  const r = docJson(); document.getElementById("jsonOut").textContent = r.err ? ("【校验失败】"+r.err+"\\n\\n"+r.text) : r.text;
  document.getElementById("modal").classList.add("show");
};
document.getElementById("btnSave").onclick = save;

/* ---------- 导入本地 JSON / 从其它 Editor 复制 ---------- */
let importInput = null;
document.getElementById("btnImport").onclick = ()=>{
  if(!importInput){
    importInput = document.createElement("input");
    importInput.type = "file";
    importInput.accept = ".json,application/json";
    importInput.style.display = "none";
    document.body.appendChild(importInput);
    importInput.onchange = ()=>{
      const f = importInput.files && importInput.files[0];
      importInput.value = "";
      if(!f) return;
      const rd = new FileReader();
      rd.onload = ()=>{
        try { importJsonText(String(rd.result||""), f.name); }
        catch(e){ setFoot("导入失败："+e, "err"); }
      };
      rd.readAsText(f);
    };
  }
  importInput.click();
};
function importJsonText(text, fname){
  const doc = JSON.parse(text);
  let list = null;
  let srcEditor = "";
  if(doc && Array.isArray(doc.buttons)){ list = doc.buttons; if(typeof doc.editor === "string") srcEditor = doc.editor; }
  else if(Array.isArray(doc)) list = doc;
  else if(doc && typeof doc === "object") list = [doc];
',
'  if(!list || !list.length){ setFoot("文件里没有按键数据："+(fname||""), "err"); return; }
  const nb = list.map(normalizeButton).filter(b=>b.name);
  if(!nb.length){ setFoot("导入的按键都无效（缺少 name）", "err"); return; }
  if(dirty && !confirm("当前编辑内容未保存，导入会覆盖它，继续？")) return;
  buttons = nb;
  expanded.clear(); selSet.clear();
  renderCanvas(); renderList(); applyBg();
  dirty = true;
  setFoot("已从「"+(fname||"本地文件")+"」导入 "+nb.length+" 个按键"
    + (srcEditor && srcEditor !== curEditor ? "（原文件属于 "+srcEditor+"，保存会写入当前 "+curEditor+"）" : "")
    + " —— 记得点 💾 保存","warn");
}
async function refreshImportSrc(){
  const sel = document.getElementById("impSrc");
  if(!sel) return;
  sel.innerHTML = "";
  const o0 = document.createElement("option"); o0.value = ""; o0.textContent = "复制其它 Editor…"; sel.appendChild(o0);
  const st = await apiJson("/api/status");
  if(!st || !st.editors) return;
  for(const e of st.editors){
    if(e.id === curEditor || !e.exists) continue;
    const o = document.createElement("option");
    o.value = e.id;
    o.textContent = ((e.displayName && e.displayName !== e.id) ? e.displayName + " " : "") + e.id;
    sel.appendChild(o);
  }
}
document.getElementById("btnCopyFrom").onclick = async ()=>{
  const sel = document.getElementById("impSrc");
  const id = sel ? sel.value : "";
  if(!id){ setFoot("先在左侧下拉里选择要复制的 Editor（需已保存过）","warn"); return; }
  const r = await apiJson("/api/load?id="+encodeURIComponent(id));
  if(!r || !r.ok || !r.exists || !r.text){ setFoot("读取 "+id+" 失败或该文件为空","err"); return; }
  try{
    const doc = JSON.parse(r.text);
    const nb = (doc.buttons||[]).map(normalizeButton).filter(b=>b.name);
    if(!nb.length){ setFoot(id+" 里没有按键","err"); return; }
    if(dirty && !confirm("当前编辑内容未保存，复制 "+id+" 布局会覆盖它，继续？")) return;
    buttons = nb;
    expanded.clear(); selSet.clear();
    renderCanvas(); renderList(); applyBg();
    dirty = true;
    setFoot("已把 "+id+" 的 "+nb.length+" 个按键复制到当前 "+curEditor+" —— 记得点 💾 保存","warn");
  }catch(e){ setFoot("复制失败："+e,"err"); }
};

function refreshHead(){
  document.getElementById("fileHint").textContent = "→ " + curEditor + "NewFuckingButtonMobile.json";
  document.getElementById("footFile").textContent = (knownFolder||"FuckYouNFEMobile/") + curEditor + "NewFuckingButtonMobile.json";
  const ff = document.getElementById("footFolder");
  if(ff) ff.textContent = knownFolder || "FuckYouNFEMobile/";
}
function setFoot(msg, cls){
  const f = document.getElementById("footStatus");
  f.textContent = msg;
  f.style.color = cls==="ok" ? "var(--ok)" : cls==="err" ? "var(--danger)" : "var(--warn)";
}
function save(){
  const r = docJson();
  if(r.err){ setFoot("保存失败："+r.err, "err"); return; }
  const btn = document.getElementById("btnSave");
  const oldLabel = btn.textContent;
  btn.textContent = "保存中…";
  btn.disabled = true;
  const finish = (msg, cls)=>{ btn.textContent = oldLabel; btn.disabled = false; setFoot(msg, cls); };
  if(!apiConnected){
    // 断线时绝不假装保存成功
    finish("保存失败：与游戏服务断开连接（请确认游戏在运行、维护开关已开）。内容仍在页面上，连接恢复后重试即可","err");
    return;
  }
  fetch("/api/save?id="+encodeURIComponent(curEditor), {method:"POST", body: r.text})
    .then(res=>res.json())
    .then(j=>{
      if(j && j.ok){ dirty = false; finish("✔ 已保存 "+curEditor+"NewFuckingButtonMobile.json —— 游戏内约 1 秒自动生效","ok"); }
      else finish("保存失败："+(j&&j.error||"未知错误"), "err");
    })
    .catch(e=>{ apiConnected = false; updateConnUi(false); finish("保存失败：连接中断（"+e+"）。内容未丢失，重连后可再保存","err"); });
}
function closeModal(){ document.getElementById("modal").classList.remove("show"); }
function copyJson(){ navigator.clipboard && navigator.clipboard.writeText(document.getElementById("jsonOut").textContent); closeModal(); }
document.getElementById("modal").addEventListener("mousedown", (ev)=>{ if(ev.target.id==="modal") closeModal(); });

/* ==================== NovaFlare 引擎 API 接线 ==================== */
let apiConnected = false;
let knownFolder = null;

async function apiJson(path, opts){
  try{
    const res = await fetch(path, opts);
    return await res.json();
  }catch(e){ return null; }
}

async function loadStatus(){
  const st = await apiJson("/api/status");
  if(!st || !st.running) return null;
  apiConnected = true;
  const dot = document.getElementById("connDot");
  if(dot){ dot.style.background = "var(--ok)"; dot.style.boxShadow = "0 0 8px var(--ok)"; }
  if(st.folder) knownFolder = st.folder;
  if(st.editors && st.editors.length){
    const sel = document.getElementById("edSel");
    sel.innerHTML = "";
    for(const e of st.editors){
      const o = document.createElement("option");
      o.value = e.id;
      o.textContent = ((e.displayName && e.displayName !== e.id) ? (e.displayName + " " + e.id) : e.id) + (e.exists ? "  ●" : "");
      sel.appendChild(o);
    }
    // 不强制切换当前 Editor（尊重用户选择/记忆），只保证下拉与当前值一致
    if(sel.value !== curEditor) sel.value = curEditor;
  }
  refreshHead();
  return st;
}

async function loadEditor(id, opts){
  opts = opts || {};
  const r = await apiJson("/api/load?id="+encodeURIComponent(id));
  if(!r || !r.ok){ setFoot("读取 "+id+" 失败（连接断开？）","err"); return; }
  let fromTemplate = false;
  if(r.exists && r.text){
    try{
      const doc = JSON.parse(r.text);
      buttons = (doc.buttons||[]).map(normalizeButton);
    }catch(e){ setFoot("解析已保存 JSON 失败："+e+"（将改用默认键位模板）","err"); fromTemplate = true; }
  }
  if(!r.exists || fromTemplate){
    // 没有自定义文件（或解析失败）：自动载入该 Editor 自己的默认键位模板，
    // 每个默认键都带「等价键值对 + 含义」，保存后才会真正生效。
    const t = await apiJson("/api/template?id="+encodeURIComponent(id));
    if(t && t.ok && t.text){
      try{
        const doc = JSON.parse(t.text);
        buttons = (doc.buttons||[]).map(normalizeButton);
        if(!opts.silent){
          if(r.exists) setFoot("已保存文件解析失败，已改载默认键位模板（未保存）","warn");
          else setFoot("该 Editor 还没有自定义文件——已载入其默认键位模板（含键值对说明）；点「💾 保存」后游戏内才生效","warn");
        }
      }catch(e){ setFoot("默认键位模板解析失败："+e,"err"); buttons = []; }
    } else {
      buttons = [];
',
'      if(!opts.silent) setFoot("模板暂不可用：点「＋ 新建按键」开始，或稍后重试「从默认键位生成」","warn");
    }
  }
  dirty = false;
  expanded.clear(); selSet.clear();
  refreshHead(); renderCanvas(); renderList();
  applyBg();
  refreshImportSrc();
}

async function boot(){
  // 记住用户上次选择的 Editor：刷新后不要再被“游戏最近 Editor”强行切走
  let remembered = null;
  try{ remembered = localStorage.getItem("emkEditor"); }catch(e){}
  const st = await loadStatus();
  if(st){
    const ids = (st.editors||[]).map(e=>e.id);
    if(!remembered || !ids.includes(remembered)){
      remembered = (st.current && ids.includes(st.current)) ? st.current : "ChartEditor";
    }
    curEditor = remembered;
    try{ localStorage.setItem("emkEditor", curEditor); }catch(e){}
    const sel = document.getElementById("edSel");
    if(sel) sel.value = curEditor;
    refreshHead();
    await loadEditor(curEditor);
  } else {
    apiConnected = false;
    updateConnUi(false);
    setFoot("未连接游戏（请先在 维护设置 开启「调整移动端各Editor键位」）——连接恢复后自动重载","err");
    applyBg();
  }
  // 连接状态巡检：游戏重启/服务恢复后自动重连；断线时保存按钮会明确报错而不是假装成功
  setInterval(async ()=>{
    try{
      const res = await fetch("/api/status", {cache:"no-store"});
      const st = await res.json();
      if(st && st.running){
        if(!apiConnected){
          apiConnected = true;
          updateConnUi(true);
          if(!dirty){ await loadStatus(); await loadEditor(curEditor); }
          else setFoot("已重新连接游戏——当前编辑内容未保存，点「💾 保存」写入","warn");
        }
      } else if(apiConnected){
        apiConnected = false;
        updateConnUi(false);
        setFoot("与游戏服务断开——修复连接后自动恢复；你的编辑仍在页面里","err");
      }
    }catch(e){
      if(apiConnected){
        apiConnected = false;
        updateConnUi(false);
        setFoot("与游戏服务断开——修复连接后自动恢复；你的编辑仍在页面里","err");
      }
    }
  }, 5000);
}

function updateConnUi(on){
  const dot = document.getElementById("connDot");
  if(!dot) return;
  if(on){ dot.style.background = "var(--ok)"; dot.style.boxShadow = "0 0 8px var(--ok)"; }
  else { dot.style.background = "var(--danger)"; dot.style.boxShadow = "none"; }
}

/* 有未保存修改时，关页面/刷新前提醒（避免“做好的键位被换掉”的误会） */
window.addEventListener("beforeunload", (e)=>{
  if(dirty){
    e.preventDefault();
    e.returnValue = "";
  }
});

/* ---------- 启动 ---------- */
refreshHead();
layoutPhone();
renderList();
window.addEventListener("resize", layoutPhone);
boot();
</script>
</body>
</html>
',
];

	public static var HTML:String = CHUNKS.join("");
}
