package options.groupData;

/**
 * 「语言」面板 —— 侧边栏里排在**最上面**的那一项（常规设置之上）。
 *
 * ── 和别的分类不一样 ────────────────────────────────────────────────
 *   其它分类的内容是一列设置项（optionArray），本分类的内容是**一块自绘面板**：
 *   左边一列「国旗 + 母语名」，右边一段该语言的示例文本（见 LanguagePanel）。
 *
 *   所以这里 `optionArray` 保持为空、`heightSet` 保持 0：
 *     · measureContent 会算出 contentMaxScroll = 0 —— 语言面板不需要滚动；
 *     · titleH = 0 —— 内容从面板标题栏正下方开始，不像别的分类要先上移掉旧大标题。
 *
 * ── 原来的样子 ──────────────────────────────────────────────────────
 *   以前语言是侧边栏底部那列纯文字（Chinese / English / Português…），
 *   由 NaviGroup.buildLangList 建。文字既不直观（"Portuguese (Brazil)" 得读完才认出来），
 *   竖栏底部空间也不够。现在那一列已经不再创建（见 NaviGroup.buildMembers 的注释）。
 */
class LanguageGroup extends OptionCata
{
	public var panel:LanguagePanel;

	public function new(X:Float, Y:Float, width:Float, height:Float)
	{
		super(X, Y, width, height);

		panel = new LanguagePanel();
		// 面板自己每帧按「内容可视区」对齐（见 LanguagePanel.update）：
		// 面板几何是补间出来的，这里拿不到"布局完成"的回调。
		add(panel);

		changeHeight(0);
	}

	/**
	 * 换语言时把卡片名和右侧示例文本重刷一遍。
	 * 由 OptionsState.changeLanguage() 统一调用（它遍历 cataGroup）。
	 */
	override public function changeLanguage():Void
	{
		super.changeLanguage();
		if (panel != null) panel.refresh();
	}

	/**
	 * 本分类没有 optionArray，OptionCata.setFade 够不到那块自绘面板 ——
	 * 得在这里把它一起带上（详见 LanguagePanel.setFade 的注释）。
	 */
	override public function setFade(v:Float):Void
	{
		super.setFade(v);
		if (panel != null) panel.setFade(v);
	}
}
