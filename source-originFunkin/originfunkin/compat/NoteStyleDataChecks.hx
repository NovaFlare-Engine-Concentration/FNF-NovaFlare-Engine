package originfunkin.compat;

#if (sys && FEATURE_DEBUG_FUNCTIONS)
using Lambda;

@:access(funkin.play.notes.SustainTrail)
class NoteStyleDataChecks
{
  static function require(condition:Bool, message:String):Void
  {
    if (!condition) throw 'Note style compatibility check failed: $message';
    trace('[Origin note style check] PASS $message');
  }

  public static function run(root:String):Void
  {
    var registry = funkin.data.notestyle.NoteStyleRegistry.instance;
    var path = haxe.io.Path.join([root, 'api-0.1.0/preload/data/notestyles/compat-early-funkin.json']);
    var contents = sys.io.File.getContent(path);
    var data = registry.parseEntryDataRaw(contents, 'original v0.3.2 note style');
    require(data != null && data.assets.noteSplash.assetPath == 'noteSplashes' && data.assets.noteSplash.alpha == 0.6
      && data.assets.noteSplash.data.downSplashes[0].prefix == 'note impact 1  blue0',
      'original early JSON acquires the original global splash resource, alpha and exact animation prefixes');
    require(data.assets.holdNoteCover.data.left.assetPath == 'holdCoverPurple'
      && data.assets.holdNoteCover.data.right.end.prefix == 'holdCoverEndRed0'
      && data.assets.holdNoteCover.data.down.hold.looped == true,
      'early hold covers acquire their four original sheets and looping hold animation');
    require(data.assets.countdownThree.assetPath == null && data.assets.countdownThree.data.audioPath == 'intro3'
      && data.assets.countdownGo.assetPath == 'go' && data.assets.judgementSick.scale == 0.65
      && data.assets.comboNumber9.scale == 0.45, 'early countdown, judgments and all ten combo digits retain their native defaults');
    var original:Dynamic = haxe.Json.parse(contents);
    original.assets.noteSplash.alpha = 0.23;
    original.assets.countdownGo = {assetPath:'custom/go', scale:2.0};
    original.assets.judgementSick = null;
    var authored = registry.parseEntryDataRaw(haxe.Json.stringify(original), 'authored early overrides');
    require(authored.assets.noteSplash.alpha == 0.23 && authored.assets.countdownGo.assetPath == 'custom/go'
      && authored.assets.countdownGo.scale == 2.0 && authored.assets.judgementSick == null,
      'explicit asset configuration, alpha and null fallback choices keep priority over old defaults');
    var migrated = LegacyNoteStyleData.migrate(contents);
    require(LegacyNoteStyleData.migrate(migrated) == migrated, 'early note style migration is idempotent');
    var modern:Dynamic = haxe.Json.parse(contents);
    modern.version = '1.1.0';
    var modernText = haxe.Json.stringify(modern);
    require(LegacyNoteStyleData.migrate(modernText) == modernText, 'current note style schema retains its explicit empty paths');
    modern.version = '1.1.1';
    modernText = haxe.Json.stringify(modern);
    var legacyEffects:Dynamic = haxe.Json.parse(LegacyNoteStyleData.migrate(modernText, true));
    require(legacyEffects.assets.noteSplash.assetPath == 'noteSplashes'
      && legacyEffects.assets.holdNoteCover.data.left.assetPath == 'holdCoverPurple'
      && !Reflect.hasField(legacyEffects.assets, 'countdownGo'),
      'pre-0.6 mod placeholders use hard-coded effects without altering later schema UI');
    require(LegacyNoteStyleData.migrate(modernText) == modernText, 'newer mods keep their authored effects');
    require(!LegacyNoteStyleData.hasModernSplash(modernText), 'empty old effects do not imply a modern note format');
    modern.assets.noteSplash.assetPath = 'custom/splash';
    for (direction in ['leftSplashes', 'downSplashes', 'upSplashes', 'rightSplashes'])
      Reflect.setField(modern.assets.noteSplash.data, direction, [{prefix:'authored'}]);
    require(LegacyNoteStyleData.hasModernSplash(haxe.Json.stringify(modern)),
      'authored four-direction splash identifies the newer effect format despite a 0.5 API minimum');
    Reflect.deleteField(modern.assets.noteSplash.data, 'upSplashes');
    require(!LegacyNoteStyleData.hasModernSplash(haxe.Json.stringify(modern)),
      'partial effect data alone does not change historical sizing');
    modern = haxe.Json.parse(contents);
    modern.version = '1.0.0';
    modern.assets.noteSplash.assetPath = 'custom/splash';
    modernText = haxe.Json.stringify(modern);
    var partial:Dynamic = haxe.Json.parse(LegacyNoteStyleData.migrate(modernText));
    require(partial.assets.noteSplash.assetPath == 'custom/splash'
      && partial.assets.holdNoteCover.data.left.assetPath == 'holdCoverPurple',
      'an authored effect keeps priority while the other early placeholder still migrates');
    for (malformed in ['null', '[]', '12', '"bad"', '{"version":"1.0.0","assets":[]}'])
      require(LegacyNoteStyleData.migrate(malformed) == malformed, 'malformed shape stays available to normal parser diagnostics: $malformed');

    var disk = registry.parseEntryData('compat-early-funkin');
    require(disk != null && disk.assets.noteSplash.assetPath == data.assets.noteSplash.assetPath,
      'actual old preload path applies the same migration through the live registry');
    var style110 = registry.parseEntryData('compat-sizing-110');
    var style111 = registry.parseEntryData('compat-sizing-111');
    require(style110 != null && style110.legacyNoteSizing == 2 && style111 != null && style111.legacyNoteSizing == 0,
      'API 0.5.0 retains its early 1.1.0 sizing while patched 1.1.1 styles use proportional sizing');
    var legacyStyleText = sys.io.File.getContent(haxe.io.Path.join([root, 'api-0.5.0/data/notestyles/compat-sizing-110.json']));
    var modernEvidence:Dynamic = haxe.Json.parse(legacyStyleText);
    modernEvidence.assets.noteSplash = {assetPath:'custom/splash', data:{leftSplashes:[{prefix:'l'}], downSplashes:[{prefix:'d'}], upSplashes:[{prefix:'u'}], rightSplashes:[{prefix:'r'}]}};
    @:privateAccess var resolvedPath = registry.loadEntryFile('compat-sizing-110').fileName;
    var oldStyle = registry.parseEntryDataRaw(legacyStyleText, resolvedPath);
    var newStyle = registry.parseEntryDataRaw(haxe.Json.stringify(modernEvidence), resolvedPath);
    require(oldStyle != null && oldStyle.legacyStaticReceptor == true
      && newStyle != null && newStyle.legacyStaticReceptor == false,
      'old minimum API with authored directional splashes keeps dynamic receptors');
    var pixel = registry.parseEntryData('compat-early-pixel');
    require(pixel != null && !pixel.assets.noteSplash.data.enabled && !pixel.assets.holdNoteCover.data.enabled
      && pixel.assets.countdownGo.assetPath == 'weeb/pixelUI/date-pixel' && pixel.assets.countdownTwo.scale == 6.0
      && pixel.assets.judgementSick.scale == 4.2 && pixel.assets.comboNumber9.assetPath == 'weeb/pixelUI/num9-pixel',
      'early pixel styles keep disabled effects and pixel countdown/judgment/digit defaults');
    var style = new funkin.play.notes.notestyle.NoteStyle('compat-early-pixel');
    for (type in [funkin.assets.Assets.AssetType.IMAGE, funkin.assets.Assets.AssetType.XML])
    {
      var assets = style.queryAssets(type);
      require(!assets.exists(asset -> asset.toString() == 'assets/.png' || asset.toString() == 'assets/.xml'),
        'disabled empty effects do not request empty $type resource IDs');
      if (type == funkin.assets.Assets.AssetType.XML)
        require(!assets.exists(asset -> asset.toString().indexOf('note-holds') >= 0),
          'sustain strip images do not request a nonexistent Sparrow XML');
    }
    var images = style.queryAssets(funkin.assets.Assets.AssetType.IMAGE);
    require(images.exists(asset -> asset.toString().indexOf('note-holds') >= 0), 'sustain strips remain in the image preload list');
    require(images.exists(asset -> asset.toString().indexOf('num9') >= 0 || asset.toString().indexOf('digit-9') >= 0),
      'resource queries include the ninth combo digit');
    require(LegacyAssetLayout.aliases('shared/images/ready.png').contains('gameplay/notestyles/funkin/countdown/graphics/ready.png')
      && LegacyAssetLayout.aliases('week6/sounds/intro3-pixel.ogg').contains('gameplay/notestyles/pixel/countdown/sound/intro-three.ogg')
      && LegacyAssetLayout.aliases('preload/images/num9.png').contains('gameplay/notestyles/funkin/popup/digit-9.png'),
      'original global UI assets keep canonical mod override aliases across old libraries');
    require(LegacyAssetLayout.aliases('shared/images/characters/senpai.xml').contains('gameplay/characters/senpai/senpai.xml'),
      'image-only upstream move entries also resolve their existing companion Sparrow XML');
    var senpai = funkin.Paths.getSparrowAtlas('characters/senpai');
    require(senpai != null && senpai.frames.exists(frame -> StringTools.startsWith(frame.name, 'Senpai Idle instance 10')),
      'the original Senpai path constructs a real native atlas from the existing external image and XML');
    for (index in 0...5)
    {
      var expected = 'compatibility/origin-v0.3.2/stages/phillyTrain/win$index.png';
      require(LegacyAssetLayout.aliases('week3/images/philly/win$index.png').contains(expected),
        'original Philly light $index keeps its external resource alias');
      var relative = funkin.assets.Paths.formatRelative('philly/win$index', 'gameplay/stages/phillyTrain', 'png');
      require(funkin.assets.Paths.image(relative, false).exists(), 'native stage path formatting resolves restored Philly light $index');
      var erectExpected = 'compatibility/origin-v0.3.2/stages/phillyTrainErect/win$index.png';
      require(LegacyAssetLayout.aliases('week3/images/philly/erect/win$index.png').contains(erectExpected),
        'original Philly Erect light $index keeps its distinct external resource alias');
      var erectRelative = funkin.assets.Paths.formatRelative('philly/erect/win$index', 'gameplay/stages/chillyTrainErect', 'png');
      require(funkin.assets.Paths.image(erectRelative, false).exists(), 'native stage path formatting resolves restored Philly Erect light $index');
    }

    var earlyStyle = new funkin.play.notes.notestyle.NoteStyle('compat-early-funkin');
    verifySizing(earlyStyle, 104, Std.int(104 * earlyStyle.getStrumlineScale()));
    for (api in ['0.5.0', '0.5.1', '0.9.0'])
    {
      var sized = new funkin.play.notes.notestyle.NoteStyle('compat-sizing-' + api.split('.').join('-'));
      verifySizing(sized, api == '0.5.0' ? 208 : null, api == '0.5.0' ? 52 : null);
      require(sized._data.legacyNoteSizing == (api == '0.5.0' ? 2 : 0), 'API $api selects the original native sizing contract');
      var receptor = new funkin.play.notes.StrumlineNote(sized, false, funkin.play.notes.NoteDirection.LEFT);
      if (api != '0.9.0') require(!receptor.active, 'API $api starts with its legacy static receptor frozen');
      receptor.animation.add('static', [0, 0], 24, true);
      receptor.playStatic();
      require(receptor.active == (api == '0.9.0'), 'API $api selects its historical static receptor animation behavior');
      receptor.forceActive = true;
      receptor.playStatic();
      require(receptor.active, 'API $api retains explicit forceActive for static receptors');
      receptor.destroy();
      if (api == '0.5.0')
      {
        var previousScale = sized._data.assets.note.scale;
        sized._data.assets.note.scale = 0.7;
        var fractionalNote = new funkin.play.notes.NoteSprite(sized);
        var fractionalWidth = fractionalNote.width;
        fractionalNote.destroy();
        sized._data.assets.note.scale = previousScale;
        require(Math.abs(fractionalWidth - 72.8) < 0.01, 'API 0.5.0 preserves fractional note width');
      }
    }
  }

  static function verifySizing(style:funkin.play.notes.notestyle.NoteStyle, noteWidth:Null<Float>, receptorWidth:Null<Float>):Void
  {
    var note = new funkin.play.notes.NoteSprite(style);
    var receptor = new funkin.play.notes.StrumlineNote(style, false, funkin.play.notes.NoteDirection.LEFT);
    require(Math.abs(note.width - (noteWidth ?? note.frameWidth * style.getNoteScale())) < 0.01,
      '${style.id} builds the actual native note at its expected width');
    if (receptorWidth != null)
      require(Math.abs(receptor.width - receptorWidth) < 0.01, '${style.id} builds the actual native receptor at its expected width');
    else
      require(receptor.scale.x == style.getStrumlineScale() && receptor.scale.y == style.getStrumlineScale(),
        '${style.id} preserves current native receptor scale across different animation frame sizes');
    var hold = new funkin.play.notes.SustainTrail(funkin.play.notes.NoteDirection.LEFT, 500, style);
    var zoom = style.fetchHoldNoteScale() * (style._data.legacyNoteSizing == 0 ? 1.0 : 0.7);
    require(Math.abs(hold.graphicWidth - hold.graphic.width / 8 * zoom) < 0.01,
      '${style.id} builds the native sustain mesh with its original zoom contract');
    var line = new funkin.play.notes.Strumline(style, false, 1);
    for (child in line.strumlineNotes.members)
      require(Math.abs(child.scale.x - style.getStrumlineScaleForFrame(child.styleFrameWidth)) < 0.0001,
        '${style.id} preserves receptor sizing when the complete strumline initializes');
    line.strumlineScale.set(0.5, 0.75);
    for (child in line.strumlineNotes.members)
    {
      var base = style.getStrumlineScaleForFrame(child.styleFrameWidth);
      require(Math.abs(child.scale.x - base * 0.5) < 0.0001 && Math.abs(child.scale.y - base * 0.75) < 0.0001,
        '${style.id} retains its native style dimensions through the strumline scaling callback');
    }
    line.noteStyle = style;
    for (child in line.strumlineNotes.members)
    {
      var base = style.getStrumlineScaleForFrame(child.styleFrameWidth);
      require(Math.abs(child.scale.x - base * 0.5) < 0.0001 && Math.abs(child.scale.y - base * 0.75) < 0.0001,
        '${style.id} retains the current line scale when receptors are rebuilt');
    }
    note.flipX = true;
    note.flipY = true;
    note.lowPriority = true;
    note.kill();
    note.revive();
    require(!note.flipX && !note.flipY && !note.lowPriority,
      '${style.id} clears script-specific state when the note sprite is reused');
    note.destroy();
    receptor.destroy();
    hold.destroy();
    line.destroy();
  }
}
#end
