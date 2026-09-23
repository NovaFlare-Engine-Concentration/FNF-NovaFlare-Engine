package mobile.objects;

/**
 * Built-in mobile Editor key configs shipped inside the APK.
 * First enable writes these into the device storage folder.
 * Regenerate with: tools/gen-editor-key-defaults.ps1
 */
class EditorMobileKeyDefaults
{
	static final C_CharacterEditor:String = '{
  "editor": "CharacterEditor",
  "screenW": 1280,
  "screenH": 720,
  "buttons": [
    {
      "name": "动作序列上",
      "click": [
        "W"
      ],
      "x": 0,
      "y": 500,
      "w": 110,
      "h": 110,
      "color": "#12FA05",
      "desc": "微调动画 offset 上移；与 G 同按 = 上移摄像机（桌面 I）"
    },
    {
      "name": "动作序列左",
      "click": [
        "A"
      ],
      "x": 110,
      "y": 610,
      "w": 110,
      "h": 110,
      "color": "#C24B99",
      "desc": "微调动画 offset 左移；与 G 同按 = 左移摄像机（桌面 J）"
    },
    {
      "name": "动作序列右",
      "click": [
        "D"
      ],
      "x": 220,
      "y": 610,
      "w": 110,
      "h": 110,
      "color": "#F9393F",
      "desc": "微调动画 offset 右移；与 G 同按 = 右移摄像机（桌面 L）"
    },
    {
      "name": "动作序列下",
      "click": [
        "S"
      ],
      "x": 0,
      "y": 610,
      "w": 110,
      "h": 110,
      "color": "#00FFFF",
      "desc": "微调动画 offset 下移；与 G 同按 = 下移摄像机（桌面 K）"
    },
    {
      "name": "Zoom +",
      "click": [
        "E"
      ],
      "x": 950,
      "y": 500,
      "w": 110,
      "h": 110,
      "color": "#99062D",
      "desc": "放大摄像机（按住连续放大）"
    },
    {
      "name": "Shift",
      "click": [
        "SHIFT"
      ],
      "x": 950,
      "y": 610,
      "w": 110,
      "h": 110,
      "color": "#44FF00",
      "desc": "按住加速：位移/缩放步长 ×4（offset 长按 ×10）"
    },
    {
      "name": "切换显示Ghost",
      "click": [
        "F12"
      ],
      "x": 840,
      "y": 610,
      "w": 110,
      "h": 110,
      "color": "#EA00FF",
      "desc": "显示/隐藏参照剪影"
    },
    {
      "name": "Switch",
      "click": [],
      "x": 110,
      "y": 500,
      "w": 110,
      "h": 110,
      "color": "#EA00FF",
      "desc": "修饰键：按住 G + 方向键 = 平移摄像机（对应桌面 I/J/K/L）；单独按无键盘等价——建议把它设成父键(CanSwitch)来切换方向键输出",
      "isFather": true,
      "FuckItKey": [
        "动作序列上",
        "动作序列左",
        "动作序列右",
        "动作序列下"
      ],
      "CanSwitch": true,
      "SwitchNum": 2,
      "Switch": {
        "动作序列上": [
          {
            "keys": [
              "I"
            ],
            "NameChinese": "相机上移",
            "NameEnglish": "Camera Up"
          },
          {
            "keys": [
              "UP"
            ],
            "NameChinese": "动作x+",
            "NameEnglish": "Action X+"
          }
        ],
        "动作序列左": [
          [
            "J"
          ],
          [
            "LEFT"
          ]
        ],
        "动作序列右": [
          [
            "L"
          ],
          [
            "RIGHT"
          ]
        ],
        "动作序列下": [
          [
            "K"
          ],
          [
            "DOWN"
          ]
        ]
      }
    },
    {
      "name": "Zoom -",
      "click": [
        "Q"
      ],
      "x": 1060,
      "y": 500,
      "w": 110,
      "h": 110,
      "color": "#4A35B9",
      "desc": "缩小摄像机（按住连续缩小）"
    },
    {
      "name": "Quit",
      "click": [
        "ESCAPE"
      ],
      "x": 1060,
      "y": 610,
      "w": 110,
      "h": 110,
      "color": "#FFCB00",
      "desc": "返回/退出角色编辑器，回到主编辑器菜单"
    },
    {
      "name": "Zoom Reset",
      "click": [
        "R"
      ],
      "x": 1170,
      "y": 500,
      "w": 110,
      "h": 110,
      "color": "#CCB98E",
      "desc": "重置摄像机缩放为 1x"
    },
    {
      "name": "播放动画",
      "click": [
        "SPACE"
      ],
      "x": 1170,
      "y": 610,
      "w": 110,
      "h": 110,
      "color": "#FF0000",
      "desc": "粘贴已复制的动画 offset（桌面 Ctrl+V）"
    }
  ]
}';
	static final C_ChartEditor:String = '{
  "editor": "ChartEditor",
  "screenW": 1280,
  "screenH": 720,
  "buttons": [
    {
      "name": "UP",
      "click": [
        "W"
      ],
      "x": 0,
      "y": 500,
      "w": 110,
      "h": 110,
      "color": "#12FA05",
      "desc": "向上滚动时间轴"
    },
    {
      "name": "LEFT",
      "click": [
        "A"
      ],
      "x": 110,
      "y": 500,
      "w": 110,
      "h": 110,
      "color": "#C24B99",
      "desc": "上一小节（按住 Y 加速）"
    },
    {
      "name": "RIGHT",
      "click": [
        "D"
      ],
      "x": 110,
      "y": 610,
      "w": 110,
      "h": 110,
      "color": "#F9393F",
      "desc": "下一小节（按住 Y 加速）"
    },
    {
      "name": "DOWN",
      "click": [
        "S"
      ],
      "x": 0,
      "y": 610,
      "w": 110,
      "h": 110,
      "color": "#00FFFF",
      "desc": "向下滚动时间轴"
    },
    {
      "name": "Move Note Switch",
      "click": [
        "L"
      ],
      "x": 1170,
      "y": 0,
      "w": 110,
      "h": 110,
      "color": "#49A9B2",
      "desc": "切换 Note 放置/移动模式"
    },
    {
      "name": "Note -",
      "click": [
        "Q"
      ],
      "x": 1060,
      "y": 170,
      "w": 110,
      "h": 110,
      "color": "#49A9B2",
      "desc": "缩短选中 Note 尾长"
    },
    {
      "name": "Note +",
      "click": [
        "E"
      ],
      "x": 1170,
      "y": 170,
      "w": 110,
      "h": 110,
      "color": "#49A9B2",
      "desc": "加长选中 Note 尾长"
    },
    {
      "name": "撤销",
      "click": [
        "CONTROL",
        "Z"
      ],
      "x": 1170,
      "y": 280,
      "w": 110,
      "h": 110,
      "color": "#49A9B2",
      "desc": "撤销（原版长按另含变速重置）"
    },
    {
      "name": "Zoom +",
      "click": [
        "X"
      ],
      "x": 1170,
      "y": 390,
      "w": 110,
      "h": 110,
      "color": "#0078FF",
      "desc": "放大网格"
    },
    {
      "name": "Space",
      "click": [
        "SPACE"
      ],
      "x": 1060,
      "y": 500,
      "w": 110,
      "h": 110,
      "color": "#99062D",
      "desc": "播放/暂停歌曲"
    },
    {
      "name": "Chart State",
      "click": [
        "ESCAPE"
      ],
      "x": 1170,
      "y": 500,
      "w": 110,
      "h": 110,
      "color": "#44FF00",
      "desc": "试玩当前谱面（编辑器内）"
    },
    {
      "name": "Shift",
      "click": [
        "SHIFT"
      ],
      "x": 1060,
      "y": 280,
      "w": 110,
      "h": 110,
      "color": "#4A35B9",
      "desc": "按住 = 4倍速 / 自由放置"
    },
    {
      "name": "Quit",
      "click": [
        "BACKSPACE"
      ],
      "x": 1060,
      "y": 610,
      "w": 110,
      "h": 110,
      "color": "#FFCB00",
      "desc": "退出编谱器（带保存提示）"
    },
    {
      "name": "Zoom -",
      "click": [
        "Z"
      ],
      "x": 1060,
      "y": 390,
      "w": 110,
      "h": 110,
      "color": "#CCB98E",
      "desc": "缩小网格"
    },
    {
      "name": "Play State",
      "click": [
        "ENTER"
      ],
      "x": 1170,
      "y": 610,
      "w": 110,
      "h": 110,
      "color": "#FF0000",
      "desc": "整曲播放"
    }
  ]
}';
	static final C_StageEditor:String = '{
  "editor": "StageEditor",
  "screenW": 1280,
  "screenH": 720,
  "buttons": [
    {
      "name": "UP",
      "click": [
        "UP"
      ],
      "x": 0,
      "y": 500,
      "w": 110,
      "h": 110,
      "color": "#12FA05",
      "desc": "移动选中精灵上移 5px（按住 C 为 ×4；与 G 同按 = 上移摄像机，桌面 I）"
    },
    {
      "name": "LEFT",
      "click": [
        "LEFT"
      ],
      "x": 110,
      "y": 610,
      "w": 110,
      "h": 110,
      "color": "#C24B99",
      "desc": "移动选中精灵左移 5px（按住 C 为 ×4；与 G 同按 = 左移摄像机，桌面 J）"
    },
    {
      "name": "RIGHT",
      "click": [
        "RIGHT"
      ],
      "x": 220,
      "y": 610,
      "w": 110,
      "h": 110,
      "color": "#F9393F",
      "desc": "移动选中精灵右移 5px（按住 C 为 ×4；与 G 同按 = 右移摄像机，桌面 L）"
    },
    {
      "name": "DOWN",
      "click": [
        "DOWN"
      ],
      "x": 0,
      "y": 610,
      "w": 110,
      "h": 110,
      "color": "#00FFFF",
      "desc": "移动选中精灵下移 5px（按住 C 为 ×4；与 G 同按 = 下移摄像机，桌面 K）"
    },
    {
      "name": "对象列表 上",
      "click": [
        "W"
      ],
      "x": 840,
      "y": 500,
      "w": 110,
      "h": 110,
      "color": "#49A9B2",
      "desc": "对象列表选中上一个精灵"
    },
    {
      "name": "对象列表下",
      "click": [
        "S"
      ],
      "x": 840,
      "y": 610,
      "w": 110,
      "h": 110,
      "color": "#0078FF",
      "desc": "对象列表选中下一个精灵"
    },
    {
      "name": "Zoom +",
      "click": [
        "E"
      ],
      "x": 1060,
      "y": 610,
      "w": 110,
      "h": 110,
      "color": "#99062D",
      "desc": "放大摄像机（按住连续放大）"
    },
    {
      "name": "Shift",
      "click": [
        "SHIFT"
      ],
      "x": 950,
      "y": 610,
      "w": 110,
      "h": 110,
      "color": "#44FF00",
      "desc": "按住加速：移动/缩放步长 ×4"
    },
    {
      "name": "Switch",
      "click": [],
      "x": 950,
      "y": 500,
      "w": 110,
      "h": 110,
      "color": "#EA00FF",
      "desc": "修饰键：按住 G + 方向键 = 平移摄像机（对应桌面 I/J/K/L），按住期间屏蔽精灵移动；单独按无键盘等价——建议把它设成父键(CanSwitch)来切换方向键输出",
      "isFather": true,
      "FuckItKey": [
        "UP",
        "LEFT",
        "RIGHT",
        "DOWN"
      ],
      "CanSwitch": true,
      "SwitchNum": 1,
      "Switch": {
        "UP": [
          {
            "keys": [
              "I"
            ],
            "NameChinese": "相机上移",
            "NameEnglish": "Camera up"
          }
        ],
        "LEFT": [
          {
            "keys": [
              "J"
            ],
            "NameChinese": "相机左移",
            "NameEnglish": "Camera left"
          }
        ],
        "RIGHT": [
          {
            "keys": [
              "L"
            ],
            "NameChinese": "相机右移",
            "NameEnglish": "Camera right"
          }
        ],
        "DOWN": [
          {
            "keys": [
              "K"
            ],
            "NameChinese": "相机下移",
            "NameEnglish": "Camera down"
          }
        ]
      }
    },
    {
      "name": "Zoom -",
      "click": [
        "Q"
      ],
      "x": 1060,
      "y": 500,
      "w": 110,
      "h": 110,
      "color": "#4A35B9",
      "desc": "缩小摄像机（按住连续缩小）"
    },
    {
      "name": "Quit",
      "click": [
        "ESCAPE"
      ],
      "x": 1170,
      "y": 610,
      "w": 110,
      "h": 110,
      "color": "#FFCB00",
      "desc": "返回：帮助/浮层开着先关闭，否则退出舞台编辑器（带未保存确认）"
    },
    {
      "name": "Zoom Reset",
      "click": [
        "R"
      ],
      "x": 1170,
      "y": 500,
      "w": 110,
      "h": 110,
      "color": "#CCB98E",
      "desc": "重置摄像机缩放为舞台默认值"
    }
  ]
}';
	static final C_WeekEditor:String = '{
  "editor": "WeekEditor",
  "screenW": 1280,
  "screenH": 720,
  "buttons": [
    {
      "name": "UP",
      "click": [],
      "x": 360,
      "y": 600,
      "w": 120,
      "h": 120,
      "color": "#12FA05",
      "desc": "原版布局中存在但未绑定操作（代码无引用，仅保留布局）"
    },
    {
      "name": "DOWN",
      "click": [],
      "x": 480,
      "y": 600,
      "w": 120,
      "h": 120,
      "color": "#00FFFF",
      "desc": "原版布局中存在但未绑定操作（代码无引用，仅保留布局）"
    },
    {
      "name": "B",
      "click": [
        "ESCAPE"
      ],
      "x": 780,
      "y": 600,
      "w": 120,
      "h": 120,
      "color": "#FFCB00",
      "desc": "返回：关闭当前打开的编辑面板；无面板时退出周目编辑器（并列检查 ESCAPE）"
    }
  ]
}';

	/** Built-in config for an Editor id, or null when none was embedded. */
	public static function get(editorId:String):Null<String>
	{
		switch (editorId)
		{
			case 'CharacterEditor': return C_CharacterEditor;
			case 'ChartEditor': return C_ChartEditor;
			case 'StageEditor': return C_StageEditor;
			case 'WeekEditor': return C_WeekEditor;
		}
		return null;
	}
}

