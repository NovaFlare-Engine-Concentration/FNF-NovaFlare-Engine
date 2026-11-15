<!-- 2026-11-07 Devil's Swing Insanity 739 incomplete: visible build 733 loaded actual gb-devils-041 (API 0.1.0); log shows missing default note-style fallback and paused=true at countdown position -1564 ms. A separate game was observed in the foreground, so no focus or input was taken; no gameplay completion, result or visual acceptance is claimed. The guarded test window remains open. -->
<!-- 2026-11-07 VS. Tord Norway real-mod run 738: visible build 733, bot/practice and isolated storage, original gb-tord-032 (API 0.1.0). Norway reached the results screen; gameplay and results were visually observed. Its metadata requests item note style and Inst-mom but the mod directory lacks both; registry logged item failure and PlayState used the default style and Inst.ogg. Both packaged Norway vocal files have identical SHA-256 AA454B3B394C4209F2242BFA91257E3C4BBEFED6DCE0FADA1A1C19017E497288; this observation does not by itself establish an audio defect. Automatic Enter produced no visible exit from results, so results exit remains unverified and user interaction was not requested. Checked user saves, Project.xml and chain.json hashes match 717 baseline. The window remained open after observation. -->
<!-- 2026-11-07 user observed Eradication and said the mod looks fine; continue to the next mod. This is user visual acceptance of the observed run, not proof of every arrow frame, complete gameplay, or every version. -->
<!-- 2026-11-07 Eradication falling/hold probe 737: visible build 733 and actual gb-alien-hominid-05 with a separate measurement module logged one spawned falling note at frame 155x155, scale 0.7, hitbox 108.5x108.5; one hold trail logged zoom 0.7, width 36.4 and 16 vertex values. Source hold texture is 416x87; official Origin v0.5.1 SustainTrail computes texture width / 8 * style scale = 416/8*0.7 = 36.4, matching this sample. Official NoteStyle applies the configured 0.7 directly, matching the measured falling-note scale. Visual window showed notes; this is a small sample, not pixel-aligned official rendering or complete gameplay. Preserve the user-reported size concern as unresolved beyond the measured samples. -->
<!-- 2026-11-07 Eradication real-mod size probe 736: visible build 733 with real gb-alien-hominid-05 and a separate measurement module logged style hominid, noteScale=0.7, strumScale=0.7, legacy sizing=0, lineScale=1; all four receptor frame widths 155 and hitbox widths 108.5, x positions 732.4/844.4/956.4/1068.4. No falling-note measurement was captured at 1.8 seconds (zero spawned); gameplay screenshot visually resembled the saved official 0.5.1 comparison but was not an aligned pixel comparison. Checked user saves, Project.xml and chain.json still match 717 baseline. This does not establish all arrow sizes or resolve the user visual report. -->
<!-- 2026-11-07 Mindless actual receptor measurement 735: visible build 733, real mod, isolated settings and read-only measurement fixture report style DarkNote, legacy sizing 0, authored scale 0.75, line scale 1, initial left frame width 155, resulting displayed hitbox width 116.25; four lane x coordinates 679.4, 791.4, 903.4, 1015.4 in a 1280x720 game viewport (origin-size-probe-735.out.log). Official v0.8.5 StrumlineNote applies getStrumlineScale directly, so the measured initial scale matches the authored calculation for this mod. This is not a live official-runtime screenshot comparison or proof of all animation frames/Eradication sizes. Test paused through reflection after measurement; its screenshot was taken, but the pause overlay hides arrows. -->
<!-- 2026-11-07 Mindless pause-camera layering 733-734: screenshot 732 showed the window partly off-screen; moving it left restored the full window, so clipping was not established as an engine defect. The mod CinematicBarsHandler removes and re-adds camHUD after camPause, causing its arrows to draw over pause metadata. Origin PlayState now re-adds the pause camera last when opening a pause menu, preserving its default-draw-target flag and other camera order. Single-thread Windows build 733 exited 0 (minimum available RAM 254 MB). Visible real Mindless test 734 with separate settings and pause probe reported pause index 8, HUD index 7, total 9; screenshot showed unobscured pause metadata and arrows behind the dark pause overlay. Probe triggered pause by reflection, so this is not physical-keyboard validation; other mods, input and long-term camera lifecycle remain unverified. Arrow size is unchanged and remains a separate concern. -->
<!-- 2026-11-07 Mindless visual investigation: after local Computer Use capture repair, visible pause screenshot 732 shows large receptors and right metadata cut off; actual capture JPEG was 1186x752 and a later capture contained an overlapping browser window, so screenshots must be interpreted with foreground and capture boundaries in mind. The mod DarkNote.json declares strumline scale 0.75; its static arrow atlas frames are approximately 155 pixels wide, suggesting approximately 116 pixels before any additional game/window transformations. Official v0.8.5 StrumlineNote.hx applies the authored scale directly. No original 0.8.5 runtime screenshot or measured live transform establishes that arrow sizes match, and user-reported visual issue remains open. Pause menu metadata clipping was observed but its cause is unproven. Pressing automated Enter did not visibly resume the pause menu; no further input was sent. -->
<!-- 2026-11-07 visual rerun 718 observation: process remained Windows-responding and foreground-accessible while its output log stopped advancing after music resync at 60055 ms (last write 19:12:02, checked 19:28:51 local); CPU increased 0.7 s over a 3 s sample. This does not distinguish pause, focus, audio stop, game-state behavior, or a defect. No image was obtainable through Computer Use; the visible run remains incomplete and must not be scored as a pass. The process and 200 MB monitor were retained. -->
<!-- 2026-11-07 Mindless shader scope: source inspection refines the fixture limitation: Graphics&GameplayOptions.Shaders gates GlobalMenuEffects chromatic filter in menu states; outside those states that module clears FlxG.game filters. The song PAShaderModule separately uses PibbyApocalypse.glitchEffects, initialized true by the mod when absent, to install camera and HUD filters. The fixture does not directly set glitchEffects. Actual shader creation and pixels in run 717 were not instrumented or visually verified; GlobalMenuEffects interactions and the reported visual defect remain unresolved. -->
<!-- 2026-11-07 Mindless settings dependency audit: original GameBanana archive contains exactly one reference to Graphics&GameplayOptions, in GlobalMenuEffects.hxc line 82, which calls .get(Shaders) on that map without a null check. Its separate PibbyApocalypse options module initializes only its own key. Isolated stock-save test 658 raises a null-object script error; 710 supplies Shaders=false to continue later tests. Official Origin preview d3fdf329 Save.get_modOptions also returns the raw map, with no automatic entry initialization in that accessor. Evidence supports a missing mod/dependency configuration, not a demonstrated engine regression; 0.8.5 official runtime and the mod author intended dependencies are not yet verified. The fixture disables this shader path, so visual equivalence is not established. -->
<!-- 2026-11-07 Mindless audio log review: original GameBanana archive mindless.zip contains only songs/mindless/inst.ogg (2,557,291 bytes), no separate Voices audio; metadata names finn and bf-gun vocal IDs. ffprobe reports the supplied instrumental as stereo Vorbis, 44100 Hz, 323.610136 seconds. Thus the no-vocals warning is consistent with the packaged files and is not alone proof of a loader defect. Whether vocals are mixed into the instrumental or omitted is unverified. Visual issue reported by user remains unresolved. -->
<!-- 2026-11-07 Origin 0.9 hold-cover priority fixture: against official preview source d3fdf329, direct and saved HScript calls in isolated fixture 721 resolve child direction, then child root, then parent root; parent direction does not precede parent root (official-root-order.log, exit 0). This confirms selected behavior only in a stand-in fixture; native-subclass and real mod rendering remain unverified. -->
<!-- 2026-11-07 correction to 721 hold-cover experiment: official Origin preview commit d3fdf329 (source in _build/origin-upstream-preview-20261101/preview-d3fdf329.zip) explicitly falls back from getHoldCoverRootAssetPath to fallback.getHoldCoverRootAssetPath, unlike the older imported String API, which falls back to direction. The experimental special case changing this to parent direction was therefore wrong for the 0.9 preview bridge and was removed from the isolated experiment; the earlier all-methods-fixed.log test used an invalid expectation and is not a passing 0.9 compatibility result. Production bridge was not changed. -->
<!-- 2026-11-07 native NoteStyle experiment 721 countdown: explicit native countdown override passes direct/saved fixture with preserved library (countdown.log), but a native subclass inheriting default countdown behavior strips the library before the preview bridge receives the string; the new regression correctly fails (inherited-countdown.log). The experimental implementation is therefore not safe to promote. Need distinguish inherited native methods from actual overrides without duplicate side effects and cover scripted/native combinations. -->
<!-- 2026-11-07 native NoteStyle experiment 721 follow-up: extended real-HScript fixture to native overrides of eight raw-capable path methods, direct and saved calls, library preservation, exact argument and single invocation. Initial direction fallback failed (all-methods.log): falling back through a root method bypassed the native direction override. A fixture-only special case made these cases pass (all-methods-fixed.log), but its interaction with scripted subclasses and production engine paths is not established. Countdown remains unresolved; no production code was changed. -->
<!-- 2026-11-07 native NoteStyle fallback isolated experiment 721: using real Polymod/HScript with an isolated fixture, an experimental Preview resolver invokes a native subclass override once with raw=true and preserves example:native-custom.png as library example / file native-custom; direct and saved access and prior scripted-parent/blacklist cases passed (library-result.log). This is NOT production code, and covers only getNoteAssetPath for a native override. Countdown has no raw parameter, private hold-cover root and scripted native-subclass combinations need design and tests; resolution and side effects for other methods remain unverified. -->
<!-- 2026-11-07 Mindless 717: Windows build 715 completed Mindless Retake with its own ASTC textures and separate missing-settings fixture, reached results and exited 0; monitored minimum system available memory was 3293.8 MB and checked saves, Project.xml and chain.json hashes were unchanged (_build/origin-mindless-harden-717.json and logs). User reported a visual problem during this run; Computer Use capture timed out on both the game and a separate ChatGPT window, so visuals are explicitly NOT verified and reaching results is not a visual pass. Follow-up run 718 remains open with a 200 MB guard for investigation. Build 715 printed Failed to update resources during Lime icon replacement; the extracted 32x32 EXE icon differs from the generated icon.ico at 602 pixels, so this build warning is not resolved. -->
<!-- 2026-11-07 ASTC hardening (714-716): AddressSanitizer exposed malformed-block out-of-bounds reads in the vendored decoder. Bounded bit access and invalid weight-grid checks were added; 10,000 random blocks for each of 14 legal 2D block sizes passed the MSVC AddressSanitizer run (astc-harden-714/fuzz-all.out.log). All 62 real Mindless Retake ASTC textures matched texture2ddecoder 1.0.6 byte for byte (astc-harden-714/fidelity.log); this comparison uses a related upstream decoder, not an independent correctness oracle. Windows build 715 recompiled AstcSoftware.cpp and returned 0 but printed Failed to update resources, requiring follow-up. Visible foundation 716 passed with exit 0; saved user files, Project.xml and chain.json hashes were unchanged. Full real-mod gameplay on build 715 and other ASTC payloads remain unverified. -->
<!-- 2026-11-03 Windows Origin ASTC fallback (704-713): vendored the MIT Texture2DDecoder ASTC implementation with upstream and FP16 license notices, and added a serialized CPU decoder. Origin's mod filesystem publishes virtual PNG paths only when that mod lacks the PNG, preserving original files and Polymod load ordering; normal and per-mod lookups both use the same conversion. Input header, block shape, 2D depth, payload length, and a 16,777,216-pixel ceiling are checked before allocation; arbitrary corrupt block payloads have not been exhaustively validated. Build 705 failed due to a relative native include path, fixed in 706; the visible foundation 707 then failed because the selected Lime PNG encoder returned no bytes for the fixture. Build 708 uses the existing format library and Haxe zlib encoder; foundation 709 passes color/channel, dimensions and invalid-header/truncation tests. Visible folder/ZIP tests 711 pass normal and direct mod lookups and PNG-over-ASTC within a mod; both reversed mixed-format mod-order tests 712 match normal PNG priority. Real Mindless Retake 0.8.5 ran in a visible isolated window without the former PNG texture overlay: only a separate missing-settings fixture was retained. Full test 713 reached results after 347.8 seconds, logged 29 character-change events, exited 0, min available physical memory 3546.2 MB, and preserved checked user saves, chain.json and Project.xml hashes. This establishes one Windows mod path, not all ASTC encodings, all corrupted payloads, all mods or all platforms. -->
<!-- 2026-11-03 ASTC software-decoder investigation (701-703): Mindless Retake includes ASTC-only textures; current OpenFL ASTCReader parses containers but does not decode pixels, and Paths.getBitmapDataFromMod returns null on unsupported GPU. Downloaded texture2ddecoder 1.0.6 source (MIT, wrapper K0lb3; derived from Perfare/AssetStudio, MIT; FP16 third-party MIT notices) into _build only. An isolated single-threaded native executable with header/dimension/block-length checks decoded the real 694x122 6x6 ASLogo2.astc into BGRA, byte-identical to the previously used Python decoder (338,672 bytes; SHA-256 f4d44cee818ab515df0820036b68d9e408e78f7e1bfe0f4b8d1ad4cfd1273c8d); a separate Haxe/hxcpp native bridge produced the same bytes. A 10,000-random-block subprocess exited 0, which is not proof malformed ASTC is safe. All code and outputs are experimental under _build; no decoder has been integrated, and real ASTC-only mod gameplay still depends on the prior PNG overlay. Future integration must cover ordinary and mod-specific lookups, precedence, asynchronous loading, memory, malformed data and cache lifecycle. -->
<!-- 2026-11-03 static receptor ambiguity correction (695-700): two real Alien Hominid releases intended for 0.5 and 0.6.0 both declare the same minimum API 0.5.0, but the latter supplies a fully authored directional splash/hold-cover style. The former unconditional old-API freeze would incorrectly freeze the 0.6.0 package. A complete authored four-direction splash is now treated as evidence of a newer style and leaves its static receptor animated; an old style without that evidence remains frozen. This remains a heuristic, not a reliable way to infer an author's exact target version. Build 695 compiled but foundation 696 failed because a synthetic test invented an incorrect non-nested virtual path; corrected test uses the registry-resolved path. Build 697 and visible foundation 698 pass. In visible real package tests 699, old static stays frame 0 inactive and 0.6.0 static changes from frame 0 to 1 active; both emit probe PASS, modern exits 0, but old exited 1 when closed immediately with no cause established. Repeated old test 700 allowed song startup, observed the same static PASS, and exited 0. Protected user save, Project.xml and chain hashes were unchanged in batch 699. This does not prove full gameplay or all ambiguous old-API mods. -->
<!-- 2026-11-03 old static receptor compatibility (688-694): official Origin v0.5.1 StrumlineNote.playStatic disables updates, whereas v0.5.2 and v0.5.3 allow dynamic static animations. The Alien Hominid 0.5 style declares six static receptor frames and API 0.5.0; using that minimum API as a compatibility default, note styles declared before 0.5.2 now freeze static receptors on the first frame unless forceActive is set. Newer and non-mod styles retain current behavior. This is an unavoidable ambiguity: some authors declare 0.5.0 as a minimum while targeting a newer engine, so the rule can freeze intended animations in such mods; it does not change the scale. First build 689 passed the initial fixture checks but the real mod probe failed (active=true, first frame 0 changed to 1), revealing the constructor unconditionally reactivated the receptor; this failed result is _build/origin-eradication-static-691.out.log. Build 692 fixes initialization, and the visible foundation run 693 passes old/modern/forceActive and initial-state checks. The visible real-mod run 694 observes six frames, active=false and unchanged frame 0 over 30 updates; it exits 0 and protected save, chain and Project.xml hashes are unchanged. This verifies static animation behavior only, not all note dimensions, all 0.5.x mods, or author intent. -->
<!-- 2026-11-03 Eradication official comparison (685-687): an isolated test-only shim redirects the SDL Windows shell-folder calls used by the extracted official v0.5.1 lime.ndll to _build/origin-051-isolation-685/appdata; the official DLL copy was modified only in the two bytes of its SHELL32 import name, with the original saved separately. The shim fails closed when its test directory is absent; standalone A/W/special-folder probes passed, and official launches logged redirection. The original user's FunkinCrew save files retained their previously recorded hashes. A byte-for-byte copy of all 92 Alien Hominid 0.5 mod files and a separate auto-start test module loaded the real Eradication song in the visible official 0.5.1 window. Visible screenshots from the official release and NovaFlare build 668 at the same 1282x752 outer window size are _build/origin-051-isolation-685/official-compare.png and novaflare-compare.png. They show similarly sized and positioned receptor arrows, but captures are from different animation frames and do not quantify every note or establish author intent. This comparison does not prove the user's reported visual-size concern resolved, and no production assets or sizing rules were changed. The official window was closed after the time-limited isolated test; all shim and test files remain confined to _build. -->
<!-- 2026-11-03 Eradication scale investigation (683-684): range-reading the official FunkinCrew v0.5.1 Windows release extracted 1,418 files (320,267,989 bytes), excluding official songs, videos and VLC plugins; only 253,294,190 bytes were fetched. This incomplete official runtime is isolated under _build/origin-051-runtime-683 and has not been launched. Environment variables alone are not proven to redirect its native SDL save path; current Lime's SDL Windows implementation calls SHGetFolderPathW, so user saves were not risked. Comparing its pinned upstream Flixel f2b090d6c608471e730b051c8ee22b8b378964b1 Sparrow parser with current Flixel shows additional bitmap graphicScale handling in current. A visible NovaFlare build 668 test using the real unmodified Alien Hominid 0.5 mod and a separate read-only probe measured receptor scale 0.7, bitmap/atlas/sprite graphicScale 1, source frame 155x155 and hitbox 108.5x108.5 (_build/origin-eradication-scale-684.out.log, exit 0); therefore that parser difference is inactive for the measured asset. Protected save, chain.json and Project.xml hashes were unchanged. Frame drawing and author intent remain unverified: this does not establish that the displayed arrows are correct or resolve the user's report. -->
<!-- 2026-11-03 CPPIA patch packaging (682): added tools/hxcpp-origin-cppia.patch and setup-hxcpp-origin-cppia.ps1 in both worktrees, based on FunkinCrew/hxcpp f299cd15bf7a7c0cc5cefdbc64338b810803252a, 1f4661402a and d5bda40ac13f2823fe1bdcb5476e0eb027f1e7e9 adapted to NovaFlare hxcpp 3f50506. The installer checks the patch hash and normalized hashes of all seven target files; it refuses unexpected local changes, saves original bytes and an exact-hash backup manifest, and supports Check, Install, Verify and Rollback. Isolated seven-file copies passed install/verify/rollback and byte-identical restoration, and a modified source was refused without changing it. Check on the selected real hxcpp reports original; no install was performed. This remains experimental: the full game build, Polymod integration, real mod ABI, GC and concurrent unload remain unverified. -->
<!-- 2026-11-03 CPPIA follow-up (680-681): non-executing scan of actual Mod Engine 1.0.3 found 266 builtin-call sites: 229 __hxcpp_memory_set_float(3), 36 __hxcpp_memory_set_ui16(3), and one __hxcpp_memory_set_ui32(3); these exact signatures occur in the selected Polymod ALLOWED_GLOBALS. None of the audit's explicit deny/alias type names occur; this is not a complete blacklist or ABI validation (_build/cppia-audit-680/result.log). A small native isolated fixture using the combined experimental hxcpp patch invoked a host callback that unloaded its currently running CPPIA module: the current call returned normally and a subsequent saved callable was rejected (_build/cppia-inflight-681/run.out.log, exit 0). This tests one synchronous case only, not concurrent unload or the real game. An isolated copy of the approximately 2.8 GiB existing game object directory cannot fit on the currently available D: space; production binaries and selected hxcpp were not overwritten. -->
<!-- 2026-11-03 CPPIA cross-module experiment (679): with only the experimental unload backport, an independently compiled Consumer extending Provider in a separate loaded CPPIA fails with Invalid super class / Missing super class (_build/cppia-multimodule-679/run.out.log, exit -1). Adapted upstream hxcpp d5bda40ac13f2823fe1bdcb5476e0eb027f1e7e9 cross-module changes to the isolated hxcpp copy; single-threaded native compile succeeded, and a visible isolated test then passed cross-module static calls, inheritance, unloading in dependent-first order and reloading (_build/cppia-multimodule-679/run-cross.out.log, exit 0). A combined seven-file experimental patch applies cleanly to the installed hxcpp but is kept only under _build/cppia-backport-677/cppia-unload-cross-experimental.patch. This fixture does not establish real mod ABI compatibility, in-flight unload safety, GC or game integration; production CPPIA is still disabled and the installed hxcpp remains unchanged. -->
<!-- 2026-11-03 CPPIA experimental hxcpp backport (676-678): Origin preview fa9b80c pins FunkinCrew/hxcpp d5bda40ac13f2823fe1bdcb5476e0eb027f1e7e9, whose f299cd15bf and 1f4661402a implement CPPIA unload; NovaFlare's selected hxcpp has no such interface. An adapted five-file patch exists only under _build/cppia-backport-677/cppia-unload-experimental.patch and applies cleanly to the current hxcpp; the installed dependency was not changed. A single-threaded isolated native build of the patched hxcpp succeeded; the small visible console test loaded and called a compiled class, unloaded it, rejected boot and a previously saved callable, and reloaded it (_build/cppia-smoke-678/run3.out.log, exit 0). An earlier run failed because the manually adapted unload overrides had not been inserted; it was fixed in the isolated copy and repeated. This does not verify real Mod Engine, game hot reload, in-flight calls, dependent modules, GC or ABI compatibility; CPPIA remains disabled in production. -->
<!-- 2026-11-03 CPPIA follow-up (673-675): static inspection of the real Mod Engine 1.0.3 CPPIA manifest finds gameVersion=0.8.7 (class 196, field string 4690, value string 4692), although its metadata API version is 0.9.0. PolymodHandler now supplies Origin API_VERSION (0.8.7), rather than the NovaFlare application version (1.2.1), to the conditional compiled-script version check. A no-output typecheck using the current release hxml and FEATURE_CPPIA, POLYMOD_CPPIA and scriptable passed: _build/cppia-typecheck-675.log. The older typecheck hxml used stale json2object paths and failed before checking the change: _build/cppia-typecheck-674.log. Native build has not been run: the installed hxcpp CppiaLoadedModule_obj has no unload method whereas the installed Polymod emits an untyped C++ call to unload(), which typechecking cannot detect. Native compatibility and script runtime remain unverified, and CPPIA has not been enabled. -->
<!-- 2026-11-03 CPPIA investigation: the real Mod Engine 1.0.3 script was scanned without executing it: text CPPIA, 4,973 strings, 208 types, scanner walked the body with no unknown tokens or suspect flag; see D:/game/FNF-NovaFlare-Engine/_build/cppia-scan-673/result.log. The existing Windows build has neither POLYMOD_CPPIA nor the hxcpp scriptable host, so loading remains unsupported. Enabling those flags alone does not establish host ABI or manifest-version compatibility; no native script execution or Hex V3 gameplay has been verified. During test runs, force-close this task's test application and its child processes if system available physical memory falls below 200 MB; the prior 4 GB/4.6 GB thresholds are not stop conditions. -->
# Origin 历史模组兼容

真实 0.9 CPPIA 依赖缺口（671/672）：[Hex V3](https://gamebanana.com/mods/44225) 的 [公开源码 c9c344d](https://github.com/Kade-github/Hex-V3/tree/c9c344d341d03e537f019775978f8ec9f440c733) 元数据为 API 0.9.0 且依赖 mod-engine；其构建脚本把 cppia-src/cppia-charts 编译为 CPPIA，HScript 也导入这些类。完整发行包约 1.41 GB，大于当时 D 盘可用空间，未下载或运行完整 Hex。下载作者的 [Mod Engine 1.0.3](https://gamebanana.com/mods/725611) 原包（file 1845599，MD5 92342eb094bf08b7d6a64994dfede961），包含 gameplay/scripts/ModEngine.cppia；可见隔离窗口正确加载 mod-engine 和 ChartLoader，但 CppiaScripts.list() 返回空、Chart 类不存在（`_build/origin-cppia-modengine-672.out.log`）。当前构建生成的 CppiaScripts.cpp 的 exists() 返回 false、list() 返回空数组，符合未启用 POLYMOD_CPPIA 的源码分支，不能认为 CPPIA 模组受支持；完整兼容需要核实宿主 scriptable 构建、版本戳、注册及依赖加载，而不是只扩大 API 版本范围。首次 671 使用目录名而非 metadata id，模组未被加载，不作为测试结果。两次用户存档及配置哈希不变；672 退出码未可靠采集。


角色暂时 kill 边界（670）：构建 668 的可见隔离 Mindless 测试中，独立探针先对现有 BF 调用 kill，再添加新 BF；旧对象仍在舞台组、动画控制器仍有效，新对象成为当前 BF，探针 PASS（`_build/origin-mindless-killed-670.out.log`）。探针随后主动移除并销毁旧对象；该测试使用 PNG/默认选项覆盖层，不覆盖所有角色或脚本。用户存档和配置哈希不变，最低可用内存约 5772 MB；退出码未可靠采集（`.json`）。测试程序 History-670 与保留的 History-668 哈希一致，已删除重复副本。


Eradication 官方画面对照资源检查：本地只有 Origin v0.5.0/v0.5.1 源码快照，没有发现对应 Windows 可执行程序。GitHub 官方 release 的 v0.5.0、v0.5.1 Windows ZIP 分别约 795 MB、794 MB；当时 D 盘剩余约 0.92 GiB，压缩包及解压所需空间不足，未下载。精确核验后仅删除本任务生成且与 History-665 SHA-256 完全一致的重复测试程序 History-666.exe，释放约 127.3 MiB；保留 665、源码、日志和其他构建。删除后 D 盘约 1.05 GiB 可用，仍不足以安全下载并解压完整官方版本。不能据此判断用户报告的箭头尺寸已修复。


ZIP 修正后基础回归（669）：构建 668 在可见隔离窗口运行完整 Origin 基础夹具，ALL FOUNDATION CHECKS PASSED 且可靠采集退出码 0；覆盖 ZIP 元数据、旧资源别名、混合大小写谱面等（`_build/origin-foundation-669.out.log`、`.json`）。另以当前 LegacyModFileSystem、真实 Polymod 和空文件夹具验证 STORE/DEFLATE 零字节条目可读取、可列举且可经资源索引访问，见 `_build/origin-zip-virtual-668/empty-current.log`；这是解释器夹具，未单独记录该运行退出码。用户存档和配置哈希不变，最低可用内存约 6125 MB；不代表所有 ZIP 或平台通过。


Origin ZIP 虚拟目录枚举修正（668）：底层 SysZipFileSystem 枚举压缩包虚拟目录时先访问实体目录并误报缺失。LegacyModFileSystem 现对仅存在于 ZIP 的目录直接枚举并去重；实体目录和真正缺失目录继续走原路径。以真实 0.9 Preview ZIP 和实际 Polymod 的隔离对照，修改前列出资源但产生 7 条缺失目录警告，修改后资源仍在、警告为 0，实体目录和真实缺失警告检查通过（`_build/origin-zip-virtual-668/before.log`、`after.log`）。单线程 Windows 构建 668 退出 0；同一真实 ZIP 的可见 FreeplayState 测试再次 PASS，虚拟目录警告从 7 条降为 0，用户存档/配置哈希不变（`_build/origin-preview-freeplay-668.out.log`、`.json`）。测试未覆盖所有 ZIP 结构或平台；窗口退出码未可靠采集。


真实 0.9 ZIP 的 Freeplay 窗口检查（667）：构建 665 加载 WeekEnd1 Pico Preview 3 原 ZIP，独立测试模块从真实 MainMenuState 打开 FreeplayState，参数选择 pico；2 秒后实际 backingImage.graphic 为 assets/ui/freeplay/styles/pico/background-darnell.png 且 visible=true，探针 PASS，脚本预热 0 错误（`_build/origin-preview-freeplay-667.out.log`）。这是真实 FreeplayState 构造及可见窗口，但由测试模块直接打开，未验证手动菜单导航、其它歌曲切换或逐像素画面；退出码未可靠采集。用户存档、Project.xml 和 chain.json 哈希不变，最低可用内存约 5522 MB（`.json`）。


真实 0.9 预览 ZIP 原生窗口资源检查（666）：使用 [WeekEnd1 Pico Freeplay BG 0.9 Preview 3 测试包](https://gamebanana.com/mods/607150) 原 ZIP（SHA-256 c5e0d35819c986a244fc246707589befcbdf080213a10cfcc886157632caec1f），以构建 665、隔离存储和独立探针模组启动可见窗口。原 ZIP 的非标准元数据经兼容层读取为 API 0.9.0、mod 3.0.0-beta1；预热 0 错误。实际 FreeplayStyleRegistry 获取 pico 样式，按其 bgAsset 加载 821×516 BitmapData，并将其精灵添加到主菜单状态，探针 PASS（`_build/origin-preview-bg-666.out.log`）。这是直接实例化并显示背景精灵，不是进入完整 Freeplay 菜单、交互或逐像素画面验收；ZIP 虚拟目录探测仍有警告，退出码未可靠采集。用户存档和配置哈希不变。GitHub 上游 preview/public-playtest 对比 fa9b80ca 为 identical，develop 仍为 b221548；本次 git 网络直连失败，使用 GitHub 连接器只读核对。


缺失长按确认动画回退（665）：Mindless DarkNote 的四个 confirm-hold 配置前缀均在原 XML 中匹配 0 帧；此前长按时每帧重复尝试播放并输出 confirm-hold does not exist。现 StrumlineNote.holdConfirm 仅在动画存在时播放，否则保留已结束的 confirm 帧。提取正式方法的轻量检查覆盖 100 次缺失时调用、存在时一次播放和启动确认（`_build/origin-hold-missing-665/result.log`）；单线程 Windows 构建 665 退出 0。真实 Mindless 加隔离纹理/选项覆盖的可见 bot/practice 短测累计收到 746 次长按命中回调、探针 PASS，日志中无 confirm-hold 缺失提示（`_build/origin-mindless-hold-665.out.log`）。746 为回调次数，不是独立音符数；未对实际画面逐帧比较、未测人工操作，用户存档和配置哈希一致，进程退出码未可靠采集（`.json`）。


Mindless flipY 与 ASTC GPU 检查（664）：隔离覆盖层仅将 bfdark1 的 JSON flipY 改为 true，并添加观察模块；构建 663 在可见窗口加载角色后报告 bfdark1 flipY=true，探针 PASS、脚本预热 0 错误（`_build/origin-mindless-flipy-664.out.log`）。这是实际运行时属性检查，未像素对照翻转画面；原模组未修改。该窗口的 context3D.isASTCSupported() 返回 false，因此既有 Paths.getBitmapDataFromMod 的 GPU ASTC 路径不能直接解决本机该包；普通 NoteStyle 资源路径也没有直接调用该方法。用户存档及配置哈希不变，最低可用内存约 5650 MB，退出码未可靠采集（`.json`）。


旧模组直接替换角色的舞台引用修复（662/663）：Mindless 的 ChangeCharacterBurgerModule 先 destroy 旧角色、再调用 Stage.addCharacter，而不调用引擎 changeCharacter。构建 657 的原模组方法联测中，连续 6 次切换后舞台组残留 6 个已销毁角色（`_build/origin-mindless-retired-662.out.log`）。现 addCharacter 替换同一槽位时，仅从组中移除已不存在且动画控制器为 null 的旧对象，未销毁当前仍可用或仅 kill 的对象；单线程 Windows 构建 663 退出 0。相同原模组方法再测 6 次，逐次 priorRetained=false、retired=0（`_build/origin-mindless-retired-663.out.log`），两次用户存档和配置哈希不变。探针脚本已从测试覆盖层移除，测试覆盖层仍包含转换纹理和缺失选项默认值；退出码 null。此修复消除了所测舞台组引用残留，但未证明先前进程内存峰值由它导致或长期内存稳定。


Mindless 全曲及内存采样（660/661）：660 在隔离纹理解码和缺失选项默认值覆盖下中途退出，未到结算；旧监控器未获取退出码，日志无明确脚本异常，不能确定原因。Windows Error Reporting 有 RADAR_PRE_LEAK_64 提示，但不能单独证明泄漏。随后 661 增加独立歌曲进度/事件探针和 5 秒左右进程内存采样，完整播放 323.6 秒伴奏；记录 29 次 BurgerChangeCharEvent 分发，进入结算并停留约 8 秒，进程退出 0（`_build/origin-mindless-monitored-661.out.log`、`.json`）。57 次采样私有内存从约 772 MiB 上升至峰值约 2590 MiB，最后约 2308 MiB（`_build/origin-mindless-memory-661.csv`）；没有与原引擎及相同资源加载基线比较，不能判断是否泄漏，需进一步分析。两份用户存档、Project.xml 和 chain.json 哈希不变，系统可用内存最低约 4910 MB。结论只适用于添加 PNG 解码覆盖和默认选项的 bot/practice 运行，不证明原 ASTC 包可直接加载、视觉效果、人工操作或长期内存稳定。


Mindless Retake 0.8.5 模组检查（656–659）：[GameBanana 711995](https://gamebanana.com/mods/711995) 原始文件 1802797 MD5 03d40bd1352033a3ce11c2508f8b4e62，原包存 `_build/gamebanana-mindless-656/mindless.zip`，隔离解压未修改。初次 656 因 9 个角色 JSON 含非官方顶层 flipY 被拒绝、脚本调用不存在的 super.onTurnChange 而未进入歌曲。参照官方 0.8.7 源码，两者均为模组扩展而非该上游 API；现增加可选 flipY 并应用角色垂直翻转、Module 提供空 onTurnChange 父方法。正式 CharacterData 结合真实 json2object 成功解析 9 份真实 JSON，合成 true/false 均通过（`_build/origin-mindless-json-657/result.log`）；单线程 Windows 构建 657 退出 0。复测 657 显示脚本预检查 0 错误、角色解析通过，但因原包仅有 ASTC 纹理而无法按 PNG 加载（`_build/origin-mindless-657.out.log`）。测试覆盖层使用 texture2ddecoder 1.0.6 将 62 张 ASTC 转为 PNG，未修改原包，记录 `_build/astc-decoder-658/convert.log`；运行 658 暴露模组 GlobalMenuEffects 对未初始化 Graphics&GameplayOptions 的空引用，原包内未发现该组初始化。仅隔离覆盖层补 Shaders=false 后，659 角色和舞台加载、脚本预检查 0 错误并开始播放伴奏（`_build/origin-mindless-659.out.log`），随后主动关闭短测；日志未看到该段脚本异常。此测试依赖人为转换及选项默认值，不能称原包直接可用；onTurnChange 只是可安全调用的空父方法，尚未实现自动派发，真实 flipY=true 渲染、整曲和 ASTC 原生加载均未验证。四次测试核对的用户存档、Project.xml 和 chain.json 哈希均不变；辅助脚本 reason=timeout/exit=null 不代表准确的退出状态。


My Streets 处理效果探针（654/655）：独立模块在真实模组歌曲中检查前四次 Pulse Fire 事件之后的舞台对象，以及六个 attackNote 经歌曲脚本处理后的图集与动画。首个探针使用 Reflect.hasField 判断继承字段，未检测到火焰（`_build/origin-my-streets-handler-654.out.log`），因此提前强制结束该测试；这不能证明事件处理失败。改用 FlxSprite 类型检查和直接读取 graphic 后，4 次均发现活动的 assets/images/fireblammo.png，6 个特殊音符使用 funniNote 图集且具有当前动画（`_build/origin-my-streets-handler-655.out.log`，HANDLERPROBE PASS）。两次用户存档和配置哈希均不变，655 最低可用内存约 5168 MB；第二次窗口退出码未可靠采集（`.json`）。未对画面像素或后续全部事件作对照。


My Streets 实际分发探针（653）：检查原始 normal 谱面含 25 个 Pulse Fire、205 个 AddCamZoomPsych、54 个 attackNote；在原模组外添加独立监测模块并以可见隔离窗口运行，16 秒时收到 4 次 Pulse Fire、2 次 AddCamZoomPsych 和 6 次特殊音符进入事件，探针 PASS（`_build/origin-my-streets-events-653.out.log`）。这证明相关事件被分发，不证明事件处理器的每个视觉效果或所有后续事件正确；未修改原模组。用户存档及配置哈希一致、最低可用内存约 5305 MB（`.json`）；辅助脚本沿用的 reason=reached-results 实际表示本次探针 PASS，不表示本次运行到结算，退出码 null。


真实 0.6.3 模组整曲检查（652）：[My Streets V-Slice Port](https://gamebanana.com/mods/581159) 作者页面注明支持 0.6.3+；下载文件 1439314 的 MD5 为 1ae5cd178e6728fa0abcfe202f5a01e2，与 API 一致。原包 `_build/gamebanana-my-streets-652/my_streets_v-slice_port.zip`；未修改内容，解压到隔离测试模组目录，元数据 API 0.6.3，歌曲仅 normal。构建 649 可见窗口以 bot/practice 运行约 159 秒伴奏，加载 47 个旧路径别名、角色/歌曲/事件脚本，预热 0 错误，进入结果界面后停留约 8 秒（`_build/origin-my-streets-652.out.log`）；未见捕获的脚本异常。两份用户存档、Project.xml 与 chain.json 哈希前后一致，最低可用内存约 5157 MB，窗口退出码未可靠采集（`_build/origin-my-streets-652.json`）。未验证人工击键、视觉细节、结算返回或其它设置。


## 当前状态（2026-11-03，构建 649）

以下按时间倒序保留测试记录；历史段落中的“尚未构建”或“尚未验证”只描述该段当时的状态，以本节和较新的记录为准。

- Origin 旧模组兼容仍在进行，目标尽可能覆盖至 0.9.0；基础夹具 651 显示通过，但不能代表全部版本或模组。
- Playable KB hard 在 bot/practice 下完成整曲并进入结算；构建 649 连续切换多图集角色 10 次并清理旧对象后也进入结算。长期内存、异常释放及所有第三方资源组合未验证。
- Eradication 的箭头尺寸仍缺可用的作者画面或同版本游戏画面对照，用户反馈的问题尚不能认定已修好。
- 0.9 HScript NoteStyle 路径和脚本继承有专门测试；外部原生 NoteStyle 子类的覆盖路径仍有已复现缺口。
- 用户已完成 Mod Menu 真实键盘操作验收；NF 手机小窗暂停、长按断连等移动端行为未在真实设备验收。
- Windows 构建 649 成功；视频、Tracy 和部分其它检查的证据属于较早构建。最终差异、外置资源边界和可审查提交仍待整理。


当前构建基础回归（651）：构建 649 在可见窗口、隔离存储下运行 `--origin-test=compat` 和既有真实文件/脚本夹具，日志最终出现 ALL FOUNDATION CHECKS PASSED，标准错误为空（`_build/origin-foundation-651.out.log`）；该检查覆盖指定历史版本夹具，不代表全模组通过。两份用户存档、Project.xml、chain.json 哈希不变（`.json`）。辅助脚本误把检查自身 Sys.exit(0) 记为 reason=timeout 且 exit=null，因为它只在进程仍运行时查询成功标记；实际日志显示成功标记且进程已退出，退出码未被可靠采集，不应将该 JSON 的 timeout 当作测试超时。


0.9 NoteStyle 原生子类缺口复核：当前 source 与 source-originFunkin 下的 Haxe 源码未发现实际 extends NoteStyle 的原生类（现有匹配为回归检查中构造的 HScript 字符串）；不能据此排除外部原生扩展。九个路径方法中 buildCountdownSpritePath 无 raw 参数，其他八个有；旧版非 raw 结果可能剥离 library 前缀或变成 Paths.image 格式。现有 bridge 直接读取数据会忽略原生父类覆盖；无条件使用旧返回值可能丢失 library，额外调用 raw 方法可能改变覆盖方法副作用次数。现有 `_build/origin-real-hscript-notestyle-subclass-guard-lowmem-542/NativeParent.hx` 已复现返回 native-default 而非覆盖的 native-custom，未提交不完整修复。


角色切换后整曲结算检查（650）：构建 649 的可见隔离窗口在 Playable KB hard、bot/practice 下完成 10 次切换与旧对象 graphic 清理检查，继续播放至结算界面并停留约 8 秒，日志含 CYCLEPROBE PASS、WENT TO RESULTS SCREEN 及结果角色，未见捕获的脚本异常（`_build/origin-stage-complete-650.out.log`）。用户两份存档、Project.xml 和 chain.json 前后哈希一致，最低可用内存约 5571 MB（`.json`）。窗口关闭的退出码仍为 null；没有单独仪表确认 Stage.onDestroy 的每个清理分支，也未覆盖失败退出或所有脚本，不能视为完整生命周期验证。


角色切换自动释放改动（649，待构建及真实回归）：探针 648 在移除并销毁共享 pico-death 图集的旧角色后，新角色播放 deathLoop 约 5 秒，动画名、当前帧及 graphic 状态通过，恢复原角色检查通过；存档和配置哈希不变（`_build/origin-stage-shared-animation-648.out.log`、`.json`）。据此 Stage.changeCharacter 改为先安装替换角色、再销毁退役角色，避免每次切换永久保留旧对象；提取正式方法的舞台/注册器替身检查通过（`_build/origin-stage-retire-649/result.log`）。单线程 Windows 构建 649 退出 0。可见窗口中以实际构建在 Playable KB hard 连续切换 pico-dark、pico-playable、bf-pixel 共 10 次并恢复原角色；每次旧角色均不在舞台组且 graphic 为空，活动角色帧/graphic 有效，pico-playable 播放 deathLoop，脚本记录 PASS（`_build/origin-stage-cycle-649.out.log`）。两份用户存档及 Project.xml、chain.json 前后哈希相同，最低可用内存约 5680 MB，窗口退出码 null（`_build/origin-stage-cycle-649.json`）。该短测未证明各类脚本销毁异常处理、长时间内存走势、最终舞台销毁或所有模组；仍需覆盖这些边界。


共享子图集销毁窗口探针（647）：构建 644 的隔离 Playable KB 运行中切换至 pico-dark，再切至同样引用 pico-death 子图集的 pico-playable；脚本从舞台移除并 destroy 已退役的 pico-dark，5 秒后 pico-playable 仍 alive、visible 且当前 frame/graphic 有效；随后切回原角色、销毁 pico-playable，原角色帧及图集仍有效（`_build/origin-stage-release-647.out.log`）。这是人工探针销毁，不是 Stage 自动清理；未播放共享死亡动画，也未检查所有子图像像素、同资源多次循环或异常释放，故不能证明完全安全。存档及配置哈希不变，最低可用内存约 5616 MB，窗口退出码 null（`_build/origin-stage-release-647.json`）。


多图集延时窗口检查（646）：构建 644 在隔离存储下运行 Playable KB，辅助脚本依次让 bf-pixel 与 pico-dark 在舞台各停留约 4 秒，随后恢复原角色；两角色在停留结束时 alive、visible、frame、graphic 和 graphic.isDestroyed 检查均通过，恢复后帧和图集检查也通过（`_build/origin-stage-render-646.out.log`）。该检查证明运行期间对象和帧仍有效，并不证明屏幕像素、动画所有帧、资源实际释放或长时间循环切换；退出码因窗口关闭方式记为 null。两份用户存档、Project.xml 和 chain.json 前后哈希相同；测试期间系统最低可用内存约 5632 MB（`_build/origin-stage-render-646.json`）。


多图集可见窗口短测（644/645）：构建 644 在隔离存储、Playable KB hard 和辅助脚本下依次切换 MultiSparrow bf-pixel（主图加死亡子图、12 动画）及 MultiAnimate pico-dark（Animate 死亡子图、18 动画），脚本检查缺失目标保留原角色、切换成功和恢复原角色均 PASS；后者同时加载 pico-playable 的 Sparrow 和多个 Animate 子图、30 动画。日志 `_build/origin-stage-swap-644.out.log`、`_build/origin-stage-multianimate-645.out.log`，两次用户存档、Project.xml、chain.json 哈希前后一致，最低可用内存分别约 5108/5574 MB。脚本在同一更新周期切换后恢复，未证明两种角色的实际可见渲染、旧角色资源销毁或长时间重复切换；窗口以关闭请求结束，进程退出码记录为 null，不宣称正常退出。


多图集持有改动（644，待构建和游戏回归）：新增 CharacterAtlasLease，MultiSparrow 与 MultiAnimate 对加载的主、子图集显式持有，销毁时释放，避免直接覆盖共享 graphic 的 destroyOnNoUse；MultiAnimate 使用独立 BorrowedAnimateFrames 组合，避免修改缓存的主帧集合。生产 lease 原样复制到隔离目录后，以真实 FlxAnimateSpritemapCollection 测试共享计数、去重、重复释放和已有策略（`_build/origin-atlas-lease-643/production-isolated.log`）；素材和角色类尚未运行。Stage 旧角色仍保留到舞台销毁，内存累积尚未解决。完整单线程 `haxelib run lime build windows` 构建 644 退出 0，日志 `_build/origin-atlas-lease-build-644.out.log` 和 `.err.log`；尚无真实多图集角色运行结果。


图集持有原型（643）：在 `_build/origin-atlas-lease-643/AtlasLease.hx` 实验显式持有 FlxGraphic，每个持有者对同一 graphic 去重，release 可重复调用且保持原自动销毁策略；配合实际 FlxAnimateSpritemapCollection，测试两个持有者、重复 hold/release、最后释放、原禁用销毁策略，结果见 `result.log`。这是独立原型，不是生产代码；渲染器初始化中途失败、多个子图集及 Animate 合并缓存等生命周期尚未覆盖，旧角色尚未改为立即销毁。


图集引用实验（642）：使用项目实际 FlxAnimateSpritemapCollection 与 FlxGraphic 引用计数，配合记录 destroy 调用的 FlxAnimateFrames 子类，在 Haxe interp 中验证：两个显式引用时设置 destroyOnNoUse=true 及释放一个引用均不销毁，释放最后一个引用才销毁；仅保留普通对象引用而不增加 useCount 时，设为 true 会立即销毁。日志 `_build/origin-graphic-lifetime-642/result-standard.log`。此实验没有加载真实素材或运行角色类，不能证明整个多图集释放方案已安全；首次未设置资源目录宏的编译失败记录于 `result.log`。


角色资源所有权审查：FlxSprite 仅对自身 graphic 增减 useCount，FlxGraphic 的 destroyOnNoUse 在设为 true 时会立即检查引用数；多图集角色的子图集未必都由该计数持有。MultiSparrowCharacter 和 MultiAnimateAtlasCharacter 把部分图集设为 destroyOnNoUse=false，但 _usedAtlases 未覆盖全部 Animate 子图集；销毁时又对记录的图集直接设为 true。多个角色共享这些资源时存在提前释放或遗留缓存的风险，尚无实测证明其影响。需先建立完整子图集持有与释放的可验证机制，再移除 Stage 的旧角色暂留；未作臆测性销毁修改。


角色切换创建事件修正（641）：CharacterRegistry.fetchEntry 本身发送 CREATE，Stage.changeCharacter 原先再次发送，导致新角色脚本重复初始化；已移除第二次派发。轻量夹具模拟注册器真实派发行为，修改前失败、修改后通过（`_build/origin-stage-create-once-641/before.log`、`after.log`）。夹具使用注册器和舞台替身，尚未重新构建或在游戏内验证；旧角色累积及共享图集释放仍未解决。


角色切换资源审查：当前 `Stage.changeCharacter` 每次切换都会保留旧角色直至舞台销毁，重复切换会累计对象；既有短测不证明长时间内存稳定或共享图集释放正确。需进一步验证后修复，不能将此项视为完成。


本任务的目标范围：从 FunkinCrew/Funkin 最早通过 `_polymod_meta.json` 的 `api_version` 加载模组的实现，到 Origin 0.9.0 预览及其后续正式版，尽可能扩大模组兼容；持续核对 Origin 上游更新，同时保留 NovaFlare 的 SDL2、外置资源、输出目录与既有本地修改。以下区分已核实的历史、已实现的适配和仍需验证的内容，不能以版本检查通过代替运行兼容，也不宣称所有模组都已通过。

性能约束（用户要求，更新）：正常推进工作，不以 4 GB 或 4.6 GB 作为停工线，也不反复因检查内存而停滞。测试运行期间，系统可用物理内存低于 200 MB 时，强制关闭本任务启动的测试应用及其子进程；不关闭用户的其他程序。重负载任务不并行，hxcpp 编译先设置 `HXCPP_COMPILE_THREADS=1`，避免电脑过载。无法完成的验证明确记录为未验证，不要求用户代操作。

补充修复（2026-11-03）：`StagedCache` 从 previous/current 替换资源时，移除回调原先误收到新资源，可能让音频或图片的清理逻辑提前关闭新资源；现改为传入被替换的旧资源。隔离测试使用实际缓存类和替身信号，覆盖 previous→current、previous→permanent、current→permanent 的不同对象替换及相同对象复用；修复前复现错误，修复后通过，日志见 `_build/origin-staged-replacement-598/before.log` 与 `after.log`。尚未用包含此修改的完整 Windows 构建和真实模组资源重载验收，不能据此宣称运行时全覆盖。

Eradication 箭头基准补充（2026-11-03）：找到 V-Slice 移植作者 DaWaterMalone 发布的展示视频 https://www.youtube.com/watch?v=Vsay9P-wq_k ，其说明标注 Eradication 从 02:58 开始；发布页 https://gamebanana.com/mods/551680 将 0.5 包标为支持 0.5.0–0.5.3。当前浏览器播放器显示“无法播放媒体”，尚未取得该段画面，故不能拿视频确认箭头尺寸，仍需对照可访问的作者画面或对应官方版本运行结果。

缓存修复构建及旧模组短测（2026-11-03）：包含 StagedCache 回调修复的单线程 `lime test windows` 编译、链接并打开可见标题窗口，正常关闭后退出 0（`_build/origin-staged-lime-599.out.log`、`.guard.log`）。隔离窗口加载正式兼容夹具后基础回归显示 ALL FOUNDATION CHECKS PASSED；Alien Hominid 0.5 的 Eradication 使用 normal 难度进入歌曲并播放伴奏，脚本预热 0 错误、运行日志 brokenScripts=0，进程正常退出 0（`_build/origin-staged-foundation-601.out.log`、`origin-staged-eradication-601.out.log`、`origin-staged-runtime-601.json`）。测试前后核对的三个用户存档、chain.json 和 Project.xml 哈希一致。此前 600 次启动遗漏夹具路径及误选 hard 难度，均为测试参数错误，不计通过。短测没有验证完整歌曲、资源重载期间替换回调或作者画面对照，箭头尺寸仍未确认。

缓存修复后热重载回归（2026-11-03）：使用构建 599 和隔离测试目录中的图片、音频覆盖模组，分别在可见窗口同步热重载。图片检查确认重载后旧 BitmapData/FlxGraphic 仍可读取，移除旧图后新图仍可读取；音频检查确认旧声音从 9144ms 的模组覆盖切回 642ms 的基础声音后，旧通道仍在前进且旧长度保持不变。两进程输出 CHECKS PASSED 且退出 0（`_build/origin-reload-image-602.out.log`、`origin-reload-audio-602.out.log`、`origin-reload-602.json`）；核对的三个用户存档、chain.json、Project.xml 哈希保持不变。覆盖模组为人工夹具，测试不证明所有模组、持续重载内存回收或正式 StagedCache 各替换分支都已在真实资源路径触发。

0.9 原生样式子类分派补充（2026-11-03）：在 Haxe 解释器探针中，`Type.getInstanceFields` 对基类、仅继承方法的子类、重写方法的子类均列出同名方法；类对象和 prototype 反射取方法均为 null（`_build/origin-native-subclass-dispatch-603/interp.log`）。因此不能用这些结果可靠地区分覆盖；简单地对所有子类转换旧方法返回值也可能丢失旧方法已剥离的资源库前缀。此探针仅覆盖解释器，不代表 hxcpp；正式桥未改，已知原生子类自定义路径缺口仍待解决。

Origin 预览角色选择资源查询（2026-11-03）：按上游 fa9b80ca8ca5063a34022acc809bf5499e1d81c4 补充 CharSelectCharacter.getCharacterData/queryAssets，并让 CharacterSelectState 预加载复用该查询。Sparrow/Packer 路径先去掉扩展名再构造 XML/TXT，避免带 .png 的输入变成 .png.xml。隔离测试覆盖缺失角色、锁定角色、空路径、图集去重、资源类型和带 .png 的 XML 路径，使用实际方法及替身数据和路径构造（_build/origin-charselect-query-604/result.log）。完整单线程 lime test windows 编译、链接并打开可见标题窗口，正常关闭退出 0（_build/origin-charselect-lime-605.out.log、.guard.log）。实际角色选择窗口、真实模组和文件解析尚未验收。

角色选择查询真实运行时回归（2026-11-03）：在隔离目录用 Alien Hominid 0.5 原始模组与合成 0.9 查询模组启动可见窗口；测试角色引用实际 char-selector-confirm.png/XML，真实 HScript 调用新增接口及 CharacterSelectState.queryAssets，确认 PNG/XML 都存在、XML 没有 .png.xml 且包含在预加载列表。脚本预热 0 错误，CHARSELECTPROBE PASS，进程退出 0（_build/origin-charselect-probe-606.out.log、.json）。该角色数据为合成夹具，未打开实际角色选择画面或验证所有渲染器。存档核对发现 NF funkin.sol 与 600 次较早基线不同，修改时间在 605 次普通标题启动结束前；606 次使用隔离存储。无法单凭现有证据确定具体更改内容或归因，未覆盖或恢复用户存档，后续普通启动需避免对真实存档产生写入。

角色选择图集实际加载修复（2026-11-03）：基于合成 0.9 角色和实际 char-selector-confirm.png/XML，通过真实 HScript 构造 CharSelectCharacter；修复前尝试读取 .png.xml 并失败（_build/origin-charselect-render-607.out.log）。Sparrow、Packer、多 Sparrow 加载统一按预加载规则去掉图像扩展名；单线程 lime build windows 退出 0（_build/origin-charselect-render-build-608.out.log），同一 Sparrow 夹具在可见隔离窗口成功加载 16 帧，进程退出 0（_build/origin-charselect-render-608.out.log、.json）。测试前后核对的三个用户存档、chain.json 和 Project.xml 哈希一致。Packer、多 Sparrow 实际加载、完整角色选择画面及第三方玩家模组尚未验收。

角色选择格式与无 GF 回归（2026-11-03）：真实 HScript 构造合成角色，Packer 使用项目 spirit PNG/TXT 加载 100 帧，多 Sparrow 使用两组实际 PNG/XML 加载 31 帧；两者资源路径存在并进入状态预加载列表，进程退出 0（_build/origin-charselect-formats-609.out.log、.json）。实际角色选择窗口 610 中多 Sparrow 对象有 31 帧，但发生 hxSehException 及无 GF 查找异常，不能计界面通过。修正当前角色的无 GF 占位对象被提前 kill 的问题，单线程构建 611 退出 0；同一真实 HScript 的状态切换回调对照，修复前 GFPROBE 取空失败、修复后取得当前角色的存活空占位并 PASS（_build/origin-charselect-gf-before-613.out.log、origin-charselect-gf-612.out.log）。这两次探针按结果主动终止，均退出 1；均仍出现 FlxSprite.draw 第 975 行 hxSehException，原因未确定。完整角色选择界面、自然解锁和第三方角色仍未通过。

角色选择缺失姓名牌修复（2026-11-03）：官方 BF 对照正常；单独 Packer 和多 Sparrow 合成角色在缺姓名牌时均复现 draw hxSehException，给同一夹具补 BF 姓名牌副本后两者均正常退出（_build/origin-charselect-control-614.out.log、origin-charselect-*-control-615.out.log、origin-charselect-*-nametag-616.out.log）。Nametag 现对缺失资源隐藏，后续加载到存在的姓名牌时恢复显示。单线程 lime build windows 退出 0（_build/origin-nametag-build-617.out.log）；原始缺姓名牌与无 GF 多图集角色在可见隔离窗口通过隐藏→BF 恢复→再次隐藏、GF 占位存活和 31 帧检查，运行后正常退出 0、无未捕获异常，核对 NF 存档、chain.json、Project.xml 哈希前后相同（_build/origin-nametag-618.out.log、.json）。结果针对合成角色，未验证所有缺失资源形式及第三方模组。

真实旧模组 Playable KB 初测（2026-11-03）：下载 GameBanana 模组 https://gamebanana.com/mods/679062 的文件 1712578（20.2 MiB，MD5 1410e1f7134fd0efc0a158d0b573d30c），元数据声明 API 0.8.4。原包仅保存在 _build；隔离解压时因 Windows 文件名限制跳过附加 kb femboy 目录中的四项，明细 _build/gamebanana-playable-kb-619/extract-620.log。原始模组在可见窗口挂载后，玩家 kb 未注册：其 _merge/data/players/kb.json 含不合法的 JSON 尾随逗号，日志记录 Invalid char 125；事件脚本另有 super.update 预检错误（_build/origin-playable-kb-screen-620.out.log）。仅在单独测试副本中排除该补丁后，kb 被发现，但角色选择缺少默认 Animation.json，窗口退出 1（_build/origin-playable-kb-nopatch-621.out.log）。移除补丁只是诊断，不是兼容通过；尚需核对旧角色选择资源布局及脚本基类，未改原始模组。

Origin JSON 补丁容错候选（2026-11-03）：在 Origin 的 Polymod JSON 合并规则加入兼容解析器，对字符串外结尾逗号进行修正；补丁语法仍无效或操作失败时记录原因并保留该补丁前的基础内容，基础 JSON 错误仍向上抛出。隔离检查使用正式兼容类、实际 jsonpatch 库及解析器替身，覆盖有效补丁、逗号及转义字符串、不合法补丁、不存在的目标和基础数据错误；Playable KB 的真实补丁去掉尾随逗号后仍因目标 /animations 不存在而跳过，玩家 JSON 得以保留（_build/origin-json-patch-622/result.log）。两个工作区已更新；尚未完成实际项目构建和原始模组运行验收，不能称模组已兼容。

Playable KB 旧图集回退（2026-11-03）：通过实际资源探针确认 KB 与 QT 旧目录均有成对 PNG/XML，Haxe XML 解析器可读 QT 图集（_build/origin-kb-path-624.out.log、origin-kb-xml-625/result.log）。角色选择查询与创建共用识别逻辑：标准图集缺失时，尝试显示名对应的同名旧 Sparrow 图集；GF 仅在旧 charSelect 目录格式且成对资源存在时回退，并按真实 XML 前缀提供 idle/select。含 JSON 容错的构建 627 成功；使用原包隔离副本（四个 Windows 不支持的附加文件仍跳过，原 JSON 补丁保留）在可见角色选择窗口读到 KB 33 帧、QT 48 帧，均有当前动画并正常退出 0，核对 NF 存档、chain.json、Project.xml 哈希不变（_build/origin-kb-render-627.out.log、.json）。无效补丁仍因目标不存在而被跳过；SawbladeEvent 的 super.update 预检错误仍在，未验证完整歌曲或所有动画。随后进一步将玩家回退限定为 characterData 完全缺省，避免覆盖显式渲染配置；这一步尚未重新构建及运行。

Playable KB 事件更新桥（2026-11-03）：对照 https://raw.githubusercontent.com/FunkinCrew/Funkin/v0.8.4/source/funkin/play/event/SongEvent.hx ，官方基类有 onUpdate 而没有 update，故模组 super.update 并非上游兼容回归。为容忍该写法新增 SongEvent.update 空钩子并从 onUpdate 传入 elapsed；构建 628 成功，真实 Polymod/HScript 的合成 SongEvent 在 super.update 后恰好执行一次、接收 0.125，Playable KB 原始脚本预热 0 错误，角色选择 KB/QT 仍成功并退出 0；无效玩家补丁仍因目标不存在而跳过（_build/origin-kb-batch-628.out.log、.json）。该构建包含收紧后的角色数据条件；隔离基础回归 ALL FOUNDATION CHECKS PASSED，退出 0（_build/origin-foundation-630.out.log）。Playable KB 的 blammed-kb:normal 短测在资源预加载阶段 75 秒超时并被测试器终止，未进入歌曲（_build/origin-kb-song-629.out.log、.json），原因未定，不能算歌曲兼容通过。

Playable KB 歌曲失败定位（2026-11-03）：此前 629 的 normal 超时并非已证实预加载死锁；再次查看可见窗口发现“该难度无音符数据”弹窗（_build/origin-kb-song-diagnostic-631.out.log）。原始谱面只有 hard 的 551 个音符，元数据却同时列出 easy/normal/hard。hard 在 _build/origin-kb-song-hard-632.out.log 实际开始伴奏，但歌曲脚本调用缺失的 changeCharacter 后触发脚本错误弹窗，最终由测试器超时终止。官方 0.8.4 Stage 不含该方法（https://raw.githubusercontent.com/FunkinCrew/Funkin/v0.8.4/source/funkin/play/stage/Stage.hx）；模组歌曲脚本明确调用 currentStage.changeCharacter。仅在隔离对照副本中排除整个歌曲脚本并按其原始目录大小写 blammed-KB 启动，hard 可见窗口播放十余秒、brokenScripts=0 并正常退出 0（_build/origin-kb-no-songscript-634.out.log）；排除脚本是诊断，不代表原始模组兼容通过，也不证明其他脚本分支通过。633 误用小写 ID 未进入歌曲。

舞台角色切换兼容（2026-11-03）：为旧模组使用的 Stage.changeCharacter 添加兼容方法，相同 ID 保留现有实例，目标不存在时不移除现有角色；更换 BF/GF/DAD 时构造新角色、分发销毁/创建事件并更新舞台，旧实例保留至舞台正常清理以避免提前释放共享图集。隔离测试覆盖三个槽位、相同 ID、无效 ID 和生命周期事件（_build/origin-stage-swap-635/result.log）；单线程 Windows 构建 636 退出 0。原始 Playable KB 歌曲脚本保留的 hard 短测，在可见窗口播放约 15 秒，脚本预热 0 错误、brokenScripts=0，进程正常退出 0，NF 存档、chain.json 和 Project.xml 哈希一致（_build/origin-kb-song-hard-636.out.log、.json）。另在相同歌曲的覆盖层通过 HScript 实际切换 BF→bf-pixel→BF，并检查相同 ID 和不存在 ID 保留原实例，退出 0（_build/origin-stage-swap-637.out.log）。这不是官方 0.8.4 API，仍未验证所有角色脚本回调、长时间多次切换、完整歌曲/结算及所有共享资源释放顺序；KB 无效 JSON 补丁仍被跳过，包内四个 Windows 不支持的附加文件未解压。

Playable KB 整曲与结算音乐回退（2026-11-03）：在构建 636 的可见隔离窗口中完整自动演奏 blammed-kb:hard 后进入结算，但原角色缺失结果音乐配置，尝试读取 assets/results-shit.ogg 并抛异常（_build/origin-kb-full-638.out.log）。ResultState 现只在所选音乐不存在时按评分回退到已存在的 BF 结算音乐；模组自带有效音乐保持优先，静态预加载与实际播放共用路径。隔离检查覆盖各评分、intro 后缀、自定义音乐与缺失回退（_build/origin-results-music-fallback-639/result.log），单线程 lime build windows 退出 0（_build/origin-results-music-build-640.out.log）。原模组隔离副本在构建 640 完整自动演奏并进入结算，记录使用 BF results-shit 音乐回退，停留约 25 秒后窗口正常退出 0，未发现脚本或未捕获异常；NF/Origin 存档、chain.json 与 Project.xml 核对哈希不变（_build/origin-kb-full-640.out.log、.json）。这是练习/自动演奏下的一次 hard 测试，不覆盖正常计分、手动操作、结算返回菜单、其他评分或四个未解压的附加文件；原包无效补丁仍被跳过。

补充验证（2026-11-03）：从 `LegacyPublicApiChecks.hx` 提取的完整 0.9 父脚本回归片段，在真实 Polymod/HScript 与替身注册表、样式宿主中通过；日志为 `_build/origin-formal-block-lowmem-559/guarded-559d.out.log`（进程退出码 0）。此结果不证明真实注册表、完整项目或 Windows 构建通过。

完整项目构建进展（2026-11-03）：`origin-current-lime-test-560` 发现资源类型枚举及测试私有访问错误，`561` 发现对话数据空值检查错误；已修正并同步两工作区。`562` 单线程完成 Haxe、hxcpp 和链接，可见窗口到达 NF 标题画面，正常关闭后 `lime test windows` 退出码 0；日志 `_build/origin-current-lime-test-562.out.log`、`origin-current-lime-test-562.err.log`。日志含 `Failed to update resources`，具体影响尚未查明。此项仅证明当前构建与 NF 标题启动，尚不证明 Origin 模组或完整兼容回归通过。

当前构建基础回归（2026-11-03）：可见隔离进程 28492 以退出码 0 结束，日志出现 `ALL FOUNDATION CHECKS PASSED`；隔离存档启用，核对的用户存档、`chain.json` 和 `Project.xml` 哈希前后一致（`_build/origin-history-batch-foundation-563.log`、`.stderr.log`、`.json`）。其中真实注册表及 HScript 验证 0.9 音符样式九个路径的直接/保存调用，以及脚本父样式的对象身份、单次调用和 null；日志中的部分 ERROR 属于无效数据拒绝夹具。此结果不代表所有模组或游戏内视觉通过。构建末尾资源更新提示此前定位为 Lime `ReplaceVistaIcon.exe` 图标替换步骤，本次失败原因和输出图标尚未核实。

当前构建真实模组短测（2026-11-03）：隔离运行 Alien Hominid 0.5 包的 Eradication，窗口实际显示舞台、角色、判定线和移动音符，临时帧率限制显示 60 FPS；脚本预热记录 0 个错误，AlienBF 动画加载 25/25，伴奏开始播放。正常关闭进程退出 0，核对的用户存档、chain.json 与 Project.xml 哈希前后一致（`_build/origin-eradication-current-564.log`、`.stderr.log`、`.json`）。这是自动演奏的歌曲短测，未完成整曲；作者现有参考图无箭头，不能判断用户反馈的箭头大小已修复。

当前构建 Alien Hominid 死亡/假死回归（2026-11-03）：0.5 包 Eradication 在隔离可见窗口分别运行 death 与强制 fakeout 分支，实际 AlienBF MultiSparrow 的死亡循环、有帧渲染、音乐播放、确认动画及重试后存活检查通过，两进程退出码均为 0；重试后脚本损坏数为 0，核对的用户存档、chain.json 和 Project.xml 哈希均不变（`_build/origin-eradication-death-current-565.log`、`_build/origin-eradication-fakeout-current-566.log` 及对应 JSON）。测试直接调用死亡和确认方法，并强制选择分支，不证明实际漏键扣血、自然假死概率或真实键盘操作。

当前构建旧模组结算回归（2026-11-03）：可见隔离窗口加载 The Devil's Swing Port v1.0.2（元数据 API 0.1.0，测试目录 gb-devils-041），以 BF、Good 等级运行结果检查：一个 Animate 图层和一个 Sparrow 图层可见并推进，音乐及元数据解析、退出后渲染器与音频清理通过，进程退出码 0。用户存档、chain.json、Project.xml 核对哈希不变（_build/origin-devils-results-current-567.log、.stderr.log、.json）。测试直接进入合成结算参数，并未证明所播放音频来自该模组，也未验证整曲到结算或所有等级的视觉一致性。

当前构建真实模组整曲（2026-11-03）：隔离可见窗口中以练习和自动演奏播放 The Devil's Swing Port v1.0.2（API 0.1.0）的 Insanity，完整进入结果界面；预热 156 个脚本类、0 个错误，日志未发现脚本执行异常，启动阶段 brokenScripts=0。模组请求的 default 音符样式仍记录查找失败并回退 funkin。手动关闭测试窗口后进程退出码 0，用户存档、chain.json 和 Project.xml 核对哈希不变（_build/origin-devils-full-current-568.log、.stderr.log、.json）。练习/自动演奏下结算统计为 0，本次未验证正常计分、结算确认或模组其他歌曲。

NF 当前源码隔离回归（2026-11-03）：以独立目录重新提取当前 PlayState 等生产方法，结合真实 OpenFL 与测试替身运行，25 项通过、进程退出 0；包括长按断连后新按键与回放不能重接、关闭设置后的恢复、漏掉长按头，以及暂停期间焦点和视频恢复（_build/nf-gameplay-regressions/current-569.out.log）。当前 Windows 项目已构建，但以上仍不是手机系统小窗、真实设备输入或实际存档加载验收。

混合图集原型重验（2026-11-03）：对此前修改后的隔离原型重新生成 Neko 程序并运行，Animate 符号来源检查通过（_build/origin-mixed-isolated-lowmem-481/run-571.out.log）；独立复验同名 Sparrow 来源、两种离屏绘制及销毁首个角色后第二个角色继续绘制通过（_build/origin-mixed-survivor-current-572/run.out.log）。两次编译和运行均退出 0；首次运行启动器路径错误未实际启动，随后修正。此测试使用替身相机和部分适配依赖，不覆盖 GPU、全部销毁顺序或真实模组；原型仍未接入正式代码。

混合图集原型提前释放对照（2026-11-03）：在隔离夹具中直接先销毁角色借用帧集合，再销毁角色，修改前出现 frames.resize 空引用并以退出码 1 结束（_build/origin-mixed-early-release-573/run.err.log）；原型加入帧列表空值检查后，同一顺序正常完成、共享角色仍可离屏绘制，退出码 0（fixed.out.log）。这是直接模拟提前释放，不证明真实缓存必然采用该顺序；原型仍未接入正式代码，GPU、真实模组和其他释放路径尚未验证。

混合图集正式源码整合候选（2026-11-03）：在隔离目录以当前 MultiSparrowCharacter 正式源码为基础，保留同路径不同类型去重、实际加载类型分支及 BorrowedSparrowFrames，合入混合图集候选。补回夹具缺失的项目级导入后，Neko 编译与提前释放／共享角色离屏绘制检查均退出 0（_build/origin-mixed-integration-574/compile-retry.err.log、run.out.log）。渲染基类、资源、相机及部分依赖仍为替身；未验证真实 GPU、所有生命周期或完整项目，候选未写入正式源码。

混合图集动态符号边界（2026-11-03）：候选集合复制符号表导致源图集后续 setSymbol 的新增项不可见；真实 flixel-animate 隔离夹具复现 source=true、candidate=false（_build/origin-mixed-late-symbol-576/run.out.log，退出码 1）。候选改为借用同一符号表、销毁时不清除源表后，新增项可见、销毁候选后源符号仍存在，并通过此前共享角色提前释放检查（fixed2-run.out.log、_build/origin-mixed-late-cleanup-577/run.out.log，均退出 0）。另一次“延迟加载”试验因依赖在加载结束清空临时字典而前提不成立，不作为缺陷证据。候选仍位于隔离目录，未验证真实 GPU、全部生命周期及完整项目。

混合图集候选接入（2026-11-03）：以当前正式 MultiSparrowCharacter 为基线接入独立借用 Animate 集合及 Sparrow 来源动画，两个 Origin 工作区同步。单线程 lime test windows 完成编译、链接、可见 NF 标题启动和正常退出（退出 0；_build/origin-mixed-lime-test-578.out.log；末尾仍有图标资源更新失败提示）。接入后 Origin 基础检查可见隔离进程退出 0 且出现 ALL FOUNDATION CHECKS PASSED（_build/origin-foundation-mixed-579.out.log）；Alien Hominid 实际 AlienBF 多 Sparrow 角色死亡与重试检查退出 0（_build/origin-mixed-alien-580.out.log）。这两项未验证混合 Animate/Sparrow 的真实 GPU 画面、共享图集全部释放顺序或真实混合模组。

混合图集真实窗口夹具（2026-11-03）：在隔离模组目录创建单独覆盖层 zz-origin-mixed-fixture-581，将 AlienBF 待机动画指向现有 BF Animate 图集，其他动画保留原模组 Sparrow，未修改原模组。当前 Windows 构建实际加载两种图集、注册 25 个动画，Eradication 可见窗口短测进入歌曲，角色画面可见并正常关闭（_build/origin-mixed-visual-582.out.log，退出 0）；另一次直接触发死亡与重试检查通过并退出 0，用户存档、chain.json 和 Project.xml 核对哈希不变（_build/origin-mixed-real-window-581.out.log、.json）。这是真实 GPU 窗口的合成混合配置，不是现成第三方混合模组；未逐帧核实每次动画切换、同名冲突或所有共享资源释放顺序。

当前构建谱面编辑器可见短测（2026-11-03）：通过隔离存储打开 Origin Chart Editor 新建歌曲窗口，画面显示与外置 cursor-default.png 一致的白色编辑器默认鼠标，点击对话框空白区域后仍显示，未观察到 NF 点击/轨迹效果；正常关闭进程退出 0（_build/origin-editor-visible-583.out.log）。这是单一对话框的短测，截图中另有小指针标记，无法仅凭画面确定其来源；控件悬停、系统鼠标与全部编辑器进出切换仍未完整验证。

Origin 上游更新复核（2026-11-03）：远端 preview/public-playtest 已从 d3fdf329 更新至 fa9b80ca8ca5063a34022acc809bf5499e1d81c4，比较结果为前进 40 个提交、60 个文件；develop 与 v0.8.7 仍为 b221548，未发现 v0.9.0 标签。新变化涵盖人声同步、资源预加载、编辑器、角色选择和加载界面，完整统计及优先差异保存在 _build/origin-preview-20261103-fa9b80c/。初步源码核对发现本地 resyncVocals 先设置偏移时间、随后 SoundGroup.play 又传入未调整的伴奏时间，可能覆盖人声偏移；上游新 VoicesGroup 则按各轨偏移播放并排队正偏移。尚未复现实际音频或完成适配，其他新改动仍待逐项审查；0.9 预览兼容不能据此宣称完成。

人声偏移修复（2026-11-03）：使用当前 VoicesGroup 及声音替身复现重同步 1000ms 后玩家/对手本应为 750/1100ms，却均被播放调用重设为 1000ms（_build/origin-voices-offset-584/before.out.log、before.err.log）。参照上游 fa9b80ca 的分轨偏移与伴奏时钟等待，接入 PlayState 和谱面编辑器，并保留脚本直接添加的未分组音轨、避免恢复时待播放音轨自行提前启动；替身检查覆盖偏移、暂停、等待、变更偏移、停止及清理（candidate4.out.log）。完整 lime test windows 编译、可见 NF 标题启动并正常退出 0（_build/origin-voices-lime-test-585.out.log）；Origin 基础回归和 Alien Hominid 死亡重试可见检查均退出 0（_build/origin-voices-foundation-586.out.log、_build/origin-voices-alien-587.out.log）。本次未对真实有非零人声偏移的音频做时钟/听感验收，编辑器音频及 Web 仍待验证。

默认伴奏的人声偏移修复（2026-11-03）：PlayState 默认伴奏 ID 是空字符串，SongOffsets.getVocalOffset 原先仅将 null 视为默认，导致配置中的默认人声偏移被忽略。提取正式方法复现 null 返回 250ms、空字符串返回 0；修复后两者均返回 250ms，指定备用伴奏仍返回其独立 600ms（_build/origin-default-vocal-offset-588/before.out.log、after.out.log）。正式回归增加默认、备用及不存在备用的断言；单线程 lime test windows 可见标题启动并退出 0（_build/origin-vocal-default-lime-589.out.log），包含新断言的 Origin 隔离基础回归退出 0（_build/origin-default-vocal-foundation-590.out.log）。真实非零偏移音频及编辑器听感仍未验证。

人声时钟真实模组短测（2026-11-03）：在隔离覆盖层添加独立 HScript 探针，以 Alien Hominid 原始 Eradication 伴奏和玩家人声运行当前 Windows 构建。人为设定 250ms 偏移并按伴奏重同步，实际时钟差为 250ms；再人为设置较大正偏移，确认等待期间人声未播放、到达时按伴奏时钟启动，实际时钟差 5920ms、预设 5919ms。可见窗口短测正常关闭、进程退出 0，日志 _build/origin-voice-clock-591.out.log；原模组未修改。探针直接调用重同步相关方法并人为设置偏移，本次没有验证实际原始模组自带非零偏移、双人声音轨、编辑器或听感。

双人声偏移真实模组短测（2026-11-03）：使用 Vs Beepie 的 Stalker 两条约 99 秒原始音轨与独立 HScript 覆盖层，可见窗口中人为设置玩家 +250ms、对手 -100ms，实际重同步时钟差分别为 250ms 和 -100ms；再让玩家音轨等待并执行音轨组暂停/恢复，对手保持播放，玩家到时启动，后续时钟差分别与目标相差 1ms，进程正常关闭退出 0（_build/origin-dual-voice-594.out.log）。首次错误歌曲 ID 的 592 未进入歌曲；Polkka 的 593 两条音轨各只有 1 秒，超出长度后的时钟结果不能作为真实播放通过证据。此测试人为设置偏移并直接调用音轨组暂停恢复，未覆盖游戏暂停菜单、编辑器或主观听感。

编辑器拖动鼠标（2026-11-03）：参考 Origin 预览 c28a4a1f，编辑器拥有鼠标时根据 HaxeUI DragManager 状态使用 grabbing 图案，拖动结束恢复悬停控件指针；保留本项目已有的所有权与主题接管逻辑。使用正式 Cursor 源码和 UI/鼠标替身，修改前拖动断言失败，修改后拖动、释放、离开编辑器与无 HaxeUI 分支通过（_build/origin-cursor-drag-595/drag-before.err.log、drag-after.out.log、drag-no-ui.out.log）。单线程 lime test windows 可见标题启动并退出 0（_build/origin-cursor-drag-lime-596.out.log）；在线更新检查返回 Blocked。当前构建的谱面编辑器在隔离窗口正常打开和关闭（_build/origin-editor-cursor-597.out.log，退出 0）；未在真实 HaxeUI 拖动动作中验证抓取指针。

## 当前验收状态（2026-11-02）

- 范围是 Origin 历史模组至 0.9.0 预览，兼容程度按实际模组和功能记录；不以 API 元数据通过认定全部模组兼容。
- 原生视频回调：已修复可复现的线程交接竞态，真实视频自然结束、跳过、关闭与再次进入已有旧构建证据；原始崩溃是否由该竞态唯一导致不能仅凭旧转储确定，当前源码尚需重新构建回归。
- 模组菜单：用户真实键盘完成启用/禁用、单步导航、排序恢复和 DONE，见 `docs/upstream-migration.md` 的 `keyboard-only-125.log` 记录；不要求用户继续代操作。
- 兼容工作：已有旧版本资源、脚本、角色、歌曲和结算的运行及隔离证据；最新多图集、编辑器指针等多项改动主要经过隔离检查，不能代替当前完整工程和实际模组运行。
- 尚未确认：Eradication 箭头的作者预期尺寸；已接入的混合 Animate/Sparrow 方案在真实 GPU、模组及全部共享图集释放顺序下的表现；手机小窗暂停和长按断连的真实设备表现。
- 构建与性能：此前已有 Windows、Tracy 采集及视频检查，但覆盖的是记录中对应的旧构建；当前代码尚未完整构建或在窗口回归。内存保护最近连续停止了 C++ 生成和 Neko 夹具编译，在资源安全之前不重试高负载任务。
- 0.9 新增适配：对话框文本、位置和速度，以及九种 NoteStyle 路径返回类型已接入源码；现有证据为替身联测和部分真实模组文件检查。真实 Polymod、脚本继承、完整 native 构建与画面验收均尚未完成。
- 父样式边界：0.9 HScript 父重写的路径分派已接入并通过精简真实解释器检查；原生 NoteStyle 子类沿用旧路径，其自定义路径仍有已复现缺口。真实模组、完整原生构建和 Eradication 箭头尺寸均未验收。
- 资源生命周期：混合 Animate/Sparrow 的共享所有权尚未解决；Flixel 帧集合类型登记遗漏有轻量复现，依赖修复仅为候选，未应用或完成真实清理回归。
- 设备与收尾：NF 手机小窗暂停、长按断连与 fixLNL 的真实设备未验收；当前 Windows 构建和部分隔离回归已完成，最终差异审查和提交仍未完成。

## 历史依据

最早集成提交为 [bfad5b33526d75211c950b8c09deb08790f3fc81](https://github.com/FunkinCrew/Funkin/commit/bfad5b33526d75211c950b8c09deb08790f3fc81)，提交日期为 2022-01-20。该提交的 [PolymodHandler](https://github.com/FunkinCrew/Funkin/blob/bfad5b33526d75211c950b8c09deb08790f3fc81/source/modding/PolymodHandler.hx) 使用 API `0.1.0`，同时新增的 [示例元数据](https://github.com/FunkinCrew/Funkin/blob/bfad5b33526d75211c950b8c09deb08790f3fc81/example_mods/testing123/_polymod_meta.json) 明确包含 `api_version: "0.1.0"`。

对当前仓库全部 v0.3.x–v0.8.x 标签逐个读取加载器和示例元数据，得到以下分段。API 号与游戏版本并非始终一致，不能把 API `0.1.0` 当成游戏 v0.1.0。

| 游戏版本/提交 | 加载器 API 约定 |
| --- | --- |
| 最早集成提交、v0.3.2–v0.4.1 | `0.1.0` |
| v0.5.0 | `0.5.0` |
| v0.5.1–v0.6.2 | `>=0.5.0 <0.6.0` |
| v0.6.3–v0.6.4 | `>=0.6.3 <0.7.0` |
| 已检查的 v0.7.0、v0.7.2–v0.7.5 | `>=0.6.3 <0.8.0` |
| v0.8.1–v0.8.7 | `>=0.8.0 <0.9.0` |
| 本项目导入的 miniaudio-public-playtest | 项目声明版本仍为 `0.8.7` |

原始研究材料保存在本机忽略目录 `_build/origin-version-history/`：`manifest.json` 保存每个标签的完整提交号、API 约束、示例元数据；`source-files.json` 与 `api-path-inventory.json` 保存历史模块路径差异。研究仓库位于 `_build/funkin-history.git`，没有检出另一份游戏或修改运行输出目录。

## 当前实现与验证边界

普通 Windows 完整原生重编译及链接（`origin-ordinary-native-rebuild-118.log`）退出0，日志确认重新编译 `Immix.cpp`；随后 `lime test windows`（`origin-ordinary-lime-test-135.log`）打开 NF 标题画面，人工窗口关闭后命令退出0。启动前 NF 存档的跳过标题视频设置为 true；本次没有执行真实视频生命周期回归。运行后 NF 存档的字节哈希与启动前不同；对反序列化后的全部现有类型（包括六个 StringMap 的键和值）比较未发现变化，验证记录为 `_build/ordinary-nf-save-comparison-145.json`。已保留只读副本，未覆盖用户当前存档；Origin 主存档与较早的预检记录不同，不能据此判断何时发生变化。`Project.xml` 与 `chain.json` 的哈希保持预期。

旧 Polymod 的裸标识符赋值会创建解释器变量。例如官方 v0.3.2 的 Philly 舞台直接赋值 `curLight`，Philly Blazin 直接赋值 `rainShaderFilter`。现按所属模组 API `>=0.1.0 <0.9.0` 恢复此规则；未赋值就读取仍报错，变量不会伪装成已声明字段，实例、父子解释器及局部作用域保持分离。旧 `this.xxx` 访问另行适配，保留原有黑名单检查。历史实现从游戏 v0.8.2 开始收紧这种显式访问；但游戏版本与元数据 API 不等同，API `0.8.0` 无法区分此前后的游戏，兼容层为它保留早期语义，不能据此声称精确重现每个游戏版本的诊断。

构建59b的 `lime test windows` 正常退出0，基础测试实际进程94732退出0、该 PID 的原生异常报告为0。新增检查覆盖10个元数据 API、赋值和未初始化读取、空值、闭包、局部参数遮蔽、实例及继承隔离、静态变量、显式访问与黑名单，以及预热阶段的作用域诊断。原始187份文本回归中的 `curLight` / `rainShaderFilter` 预热错误已经消失；实际 Philly 舞台随后暴露五张历史灯光图缺失，需由外置资源包补充后继续运行验证。

外置安装脚本现在还从同一固定 assets 提交补充 `stages/phillyTrain/win0.png`–`win4.png`，供旧舞台的五个独立灯光道具使用。新版资源只有单张 `win.png`，不能直接代替旧脚本要求的五个资源。文件来源和 SHA256 同样记录在外置清单中。构建60的实际基础测试进程96048退出0，五个资源均通过原生舞台路径解析；原始187份文本回归的 Philly Nice 实际进程99272完成整曲、四种判定测试并进入结果界面，灯光、角色和音符已实际绘制，正常关闭。两次进程的原生异常报告均为0，日志分别为 `origin-compat-foundation-60.log` 和 `origin-core-v032-philly-full-song-60.log`。

构建62修正 Mod Menu 的鼠标按钮未接入，以及共享 Flixel 已分发输入、菜单又在更新中重复分发的问题。实际点击 Done 后仅有一次保存备份，完成应用列表、热重载并返回标题，原 Impostor 启用选择保留；测试进程93036没有原生异常报告，正常关闭。证据为 `origin-modmenu-single-apply-62.log`。该次没有验证列表启停和排序；后续真实键盘检查见下文，各平台输入仍需分别验证。

`origin-impostor-hud-full-song-62.log` 记录安装中原始 `HUDFadeModule` 的实际淡出/恢复两项检查和 Bopeebo 整曲回到 Freeplay，进程98880没有原生异常报告，正常关闭。临时验证模块已从用户模组目录移除。

构建63–65继续补齐旧 Nene Sparrow 图集、旧版 `switch` 的可变实例/继承/静态/局部值比较，以及 Animate 图集的目录迁移解析。图集仅放在外置兼容包；当前 Nene 原角色配置保持原样。构建65的 `lime test windows` 正常退出0，实际基础测试进程96924退出0、原生异常报告为0，原有检查和新增图集/作用域检查全部通过（`origin-compat-foundation-65.log`）。原始 Blazin 已进入歌曲，实际绘制雨景、旧 Nene/A-Bot 和音符，随后停在旧 Nene 的嵌套方法参数作用域问题（`origin-core-v032-blazin-event-scope-65.log`）；因此不能宣称 Blazin 整曲或全版本兼容完成。

该作用域问题现已按历史解释器处理：旧 `PolymodScriptClass.callFunction` 将参数临时放进实例解释器的 `variables`，执行结束后恢复原值；当前 `Interp.executeFunction` 则创建独立 `locals`。旧 Nene 的 `onNoteHit(event)` 调用 `moveByNoteKind(kind)`，后者仍读取调用者的 `event`，在前一种规则下能够访问。兼容层按所属 API 恢复临时参数变量、嵌套同名遮蔽及返回/异常后的恢复，并为旧回调恢复已移除的参数快照。未创建永久 `event` 对象，也未跳过该方法。

构建66c、67的实际基础测试均退出0、对应 PID 的原生异常报告均为0。构建67覆盖8个 API 的缺参、默认值、显式 null、继承、实例隔离、递归、闭包、黑名单与异常恢复。历史游戏 v0.8.1 的方法仍允许缺参并区分显式 null，v0.8.2 开始引入参数校验和 null 默认值回退；匿名函数在早期已有自己的参数校验，不能一起放宽。元数据 API `0.8.0` 的版本歧义仍按前述原则保留早期语义。

`origin-core-v032-blazin-full-song-67.log` 记录原始 Blazin 完成整曲及四种判定测试并进入结果界面，实际进程25364没有原生异常报告，正常关闭。此证据只证明运行流程：实测仍发现旧 Pico/Darnell 战斗角色位于视野外，简单开启 `applyStageMatrix` 未解决，需要继续核对历史图集定位。角色位置诊断和矩阵试验的临时模组均已移除。

构建67的 `lime test windows` 虽编译成功，标题视频期间进程92504在 VLC 音频回调线程发生未处理原生访问异常，最终退出1，不能算作该命令通过。基础测试的成功与此问题分开记录。已保留对应程序、dump 和机器码匹配的符号表，崩溃点为 OpenAL `sourceQueueBuffer` 调用中的 `hx::ArrayBase::__SetSizeExact`；根因未修复，不能以减少分配或脚本优化代替根因结论。

构建69c修复早期 Animate 角色的首次定位：v0.3.2/v0.4.1 的父角色没有自己的图帧，子渲染器首次绘制前尺寸为零；[v0.5.0 的实现](https://github.com/FunkinCrew/Funkin/blob/v0.5.0/source/funkin/play/character/AnimateAtlasCharacter.hx) 则在放置前主动绘制以计算尺寸。现仅对所属 API `>=0.1.0 <0.5.0`、且未明确指定现代图集设置的角色恢复早期初始锚点、导出舞台矩阵及零父帧偏移；绘制后恢复可查询的尺寸。规则来自角色数据的实际模组来源，JSON 不能自行启用内部标记，新版和明确设置保持原行为。原始数据解析接口仍不补注册表默认值。

该构建的 `lime test windows` 正常退出0，实际基础测试进程99768退出0，新增所属版本、显式设置、伪造字段拒绝及原始解析接口检查全部通过（`origin-compat-foundation-69c.log`）。原始187份文本回归中的 Blazin 进程92296已实际显示 Pico/Darnell、雨景和 Nene，完成整曲与四种判定检查进入结果界面，正常退出0、无本次原生异常报告（`origin-core-v032-blazin-placement-full-song-69c.log`）。临时诊断模块只读取坐标，没有修正位置，测试后已移除。

原生分配压力测试在回调线程反复挂接/脱离、分配复用和大小回收场景中检查524,288次数组分配，进程96696退出0且未发现非零初始指针（`origin-native-allocation-69b.log`）。这不能代替标题视频偶发崩溃的根因修复；该问题仍未解决。

### 2026-10-31：原生回调线程交接竞态

旧 dump 的数组接收指针落在程序代码区，并非单纯的空数组或模组脚本异常。原可执行文件的反汇编显示故障指令按虚函数表调用；接收地址处的前八个机器码字节与转储中的 RAX 完全一致，说明机器码被误读为虚函数表指针（`_build/origin-crash67-instruction-148.json`、`origin-crash67-disasm-148.txt`）。这一吻合确定了故障机制，但没有直接确定此前的指针损坏来源。 进一步从转储恢复调用者保存的 RBX，找到刚分配的数组对象：其 `+0x18` 缓冲区字段与故障接收指针相同。原始机器码显示当前路径设置对象类型与长度后读取该字段，再因非零而调用 `__SetSizeExact`；这一表现与分配对象中残留旧数据的对照复现相符（`_build/origin-crash67-array-origin-156.json`）。这仍不能单凭转储断定是哪次更早的事件留下了这些字节。 相邻内存进一步呈现与 `hx::CMemberFunction0` 的 `next` 方法对象一致的布局：函数指针和方法名与附近完整的同类对象相同，而对象前部被新数组字段覆盖；这支持对象分配范围重叠的判断（`_build/origin-crash67-overlap-layout-158.json`）。转储是单次快照，不能单独证明重叠发生的时序或具体 GC 交错。 使用原始可执行映像的 Windows 栈展开与独立静态展开一致，得到 `audio_play → audioPlay → sourceQueueBuffer → __SetSizeExact`，各层调用指令也已核对（`_build/origin-crash67-unwind-crosscheck-155.json`）。`onThreadAttach` 和 `PushTopOfStack` 仅作为原始栈候选出现，不在该展开链中；原始回调机器码确认 `audio_play` 在调用 `audioPlay` 前调用了 `PushTopOfStack`（`_build/origin-crash67-attach-order-157.json`），但这不足以证明当时创建了新线程注册或发生了 GC 交错；因此既不能证明也不能排除此竞态。进一步核对共享 hxcpp 发现：`GetPooledAllocator` 从池中移除分配器后释放状态锁，随后 `AttachThread` 才将其放回活跃分配器列表。这段间隔发生 GC 时，该分配器既不在池中、也不在活跃列表中，其旧分配范围不会被清理，之后可与其他存活对象占用同一内存。

`tools/test-hxcpp-callback-handoff.ps1` 在不修改已选运行库的隔离副本中强制这一交错。正式测试 `hxcpp-callback-handoff-suite-77.log` 的原始副本返回 `handoff_locked=0 overlaps=2`，数组 base 指向代码区；修补副本返回 `handoff_locked=1 overlaps=0 base=0x0`。这是可重复的线程交接/GC 错误及前后对照证据，与此前仅在回调间隔进行回收的分配压力测试不同。原始崩溃转储并未直接记录这次交错，因此该竞态是有证据支持的原因候选，尚不能单独证明它就是原崩溃的唯一原因；真实视频生命周期需独立验收，后续 Windows 结果见下文。 后续发现原脚本快速切换变体时共用构建目录，存在复用旧可执行文件的风险；现改为每次运行及每个变体使用独立目录。新对照 `callback-formal-161.log` 再次得到原版重叠2、修补版重叠0。以 `CMemberFunction0` 为对象的独立试验同样得到原版重叠2、修补版重叠0，但本次残留指针不等于试验函数地址（`callback-mfunc-160-distinct-retry.log`），不能声称逐字节复现原转储。 增加覆盖前字段快照后确认，该试验中的残留值等于被覆盖方法对象原有的虚函数表指针（`callback-fields-162.log`）；尝试一组额外分配对齐后仍是该字段（`callback-fields-pad-163.log`），而原转储对应方法函数字段。 随后通过在回调线程增加一次小对象分配，独立对照 `callback-formal-member-165.log` 在未修补版精确读到方法对象的函数字段（`functionMatch=1 slot=2 slotMatch=1`），修补版无重叠且字段为零。该可重复对照可用 `tools/test-hxcpp-callback-handoff.ps1 -MemberLayout` 运行；默认对照也再次通过。它复现了与转储相同的字段覆盖机制，但不证明原次 GC 交错的具体时序。 进一步的独立测试 `callback-formal-crash-167.log` 在未修补副本中实际调用损坏指针并得到 `0xc0000005`，异常前记录确认该指针等于方法函数地址；修补副本字段为零并正常退出。可通过 `tools/test-hxcpp-callback-handoff.ps1 -MemberLayout -CrashOnCorruption` 显式运行：该选项会有意使隔离的未修补测试进程崩溃，不运行视频，也不修改选定运行库。该试验复现同类异常，不将其误记为原始视频崩溃的直接重放。 随后对隔离异常记录寄存器与指令，确认接收指针就是残留函数地址，故障操作码 `FF 90 10 01 00 00` 与原转储的 `call [rax+0x110]` 完全一致；新的断言及修补版对照通过（`_build/callback-formal-context-169.log`）。

修补仅在 `RegisterCurrentThread` 的整个池到活跃列表交接期间持有既有递归状态锁。当前本地源码已通过 `tools/setup-hxcpp-callback-handoff.ps1` 应用；对应补丁、完整输入/输出哈希校验、备份、幂等安装和回滚检查均已保留。Windows 原始字节、LF 与纯 CRLF 三种已知源码的安装、验证、重复安装、逐字节回滚和未知修改保留检查均通过（`hxcpp-installer-profiles-81.log`），测试未改变所选运行库。

构建78的日志确认已重新编译修补后的 `Immix.cpp`；完整 `lime test windows` 正常启动 NF 并退出0，基础兼容检查也退出0并记录 `ALL FOUNDATION CHECKS PASSED`（`origin-compat-build-78.log`、`origin-compat-foundation-78.log`）。这两项与完整标题视频验收分开记录。

Attract 状态另有重复结束的空引用风险：结束、错误或跳过请求在实际切换前再次触发，会对已清空的播放器再次调用销毁。现以结束标记保护转换，先分离播放器再停止/销毁，外部销毁也屏蔽迟到回调。构建91的 `origin-attract-lifecycle-91.log` 检查真实状态及未加载媒体的播放器，覆盖停止/销毁中的重入、重复结束、外部销毁与迟到回调，最终标记完整且进程退出0。此项仅验证状态控制逻辑；真实视频播放、跳过和窗口退出的后续检查见下文。

构建73的真实视频基线已验证三个标题视频自然结束、实际解码帧与 OpenAL 已排队音频、播放期间1234次 GC，以及随后的暂停/恢复和三轮停止销毁；日志在第6轮播放中销毁检查启动后结束，没有最终完成标记。虽然进程退出0且没有对应的原生报告，这仍是部分证据，不能记作九轮全部通过。日志为 `origin-native-video-73.log`。新检查要求最终 `CHECKS PASSED`，提前关闭会记录 `INCOMPLETE`。

修补后的 `origin-native-video-78.log` 完成第一个标题视频的5003个解码帧、音频和414次 GC 检查，在第二个视频中记录 `INCOMPLETE`。用户确认两次都是手动关闭，当时选择暂缓视频窗口；该次不是新崩溃，也不能算完整通过。后续用户允许测试后的结果见下文。

用户随后允许视频回归。`origin-native-video-174.log` 在普通 Windows 构建中完成9轮并以退出0结束：三个视频各自然结束一次，另外覆盖暂停/恢复、三次停止及三次播放中销毁；检查实际解码帧、OpenAL 排队音频、销毁后资源与迟到显示回调，并在播放中执行1327次 GC。随后用户实际长按 F 跳过 Attract，观察到返回标题且进程退出0（`origin-attract-skip-175.log`）；另一次在视频可见播放时关闭窗口，进程退出0（`origin-attract-close-176.log`）。这三个 PID 无对应新增原生崩溃文件。测试前后三份存档反序列化内容未发现变化；Origin 主存档字节哈希因序列化顺序不同而变化，未覆盖用户存档。`Project.xml` 和 `chain.json` 哈希不变。汇总与范围限制见 `_build/origin-native-video-verification-176.json`：实际跳过及播放中关闭各检查一次，不代表其他平台或所有视频后端均已验证。 另一次同进程实际 Attract 检查中，首个视频自然结束并回到标题，随后自动再次进入 Attract 且第二个视频可见播放；播放中关闭后退出0、无对应新崩溃文件，三份存档与预检字节一致（`_build/origin-attract-reentry-178.verified.json`）。

构建79通过官方 v0.3.2 原始核心脚本的普通死亡、假死及 Pixel BF 死亡后重开三条短回归。实际游戏达到解锁的 `deathLoop`、播放中的死亡音乐和 authored `deathConfirm`，执行原生确认与重新开始，恢复同一存活角色并稳定运行三秒，没有损坏脚本；Pixel 还验证 `-pixel` 音乐和音效后缀。日志为 `origin-core-v032-death-restart-79.log`、`origin-core-v032-fakeout-restart-79.log`、`origin-core-v032-pixel-death-restart-79.log`，三个进程均正常退出0。此显式练习/自动演奏检查调用流程方法，不冒充真实键盘确认验收。临时 ZIP 已按源文件哈希核对后移出用户模组目录。

官方 v0.5.0 的[原始 BF 玩家数据](https://github.com/FunkinCrew/funkin.assets/blob/bc7009b4242691faa5c4552f7ca8a2f28e8cb1d2/preload/data/players/bf.json) 暴露了两个注册表缺口：缺少后来新增的 `results.perfectGold`，以及新版移除了 `freeplayDJ.cartoon`。旧[PlayableCharacter](https://github.com/FunkinCrew/Funkin/blob/v0.5.0/source/funkin/ui/freeplay/charselect/PlayableCharacter.hx) 将 Perfect/Perfect Gold 都映射到 `perfect`；[官方模组文档](https://funkincrew.github.io/funkin-modding-docs/05-custom-playable-characters/05-02-creating-a-playable-character.html) 将独立 `perfectGold` 字段标记为 v0.5.1 新增；现仅在 schema 1.0 的注册表迁移中恢复这一默认值，保留严格原始解析及显式配置。DJ 的旧字段、五个帧标记查询方法和原缺省值也已恢复。构建84的完整基础检查通过，覆盖原始数据的实际玩家构造、自定义/缺省帧、延迟图层、显式 Gold、当前格式和无关无效数据的边界，以及不重写模组文件（`origin-compat-foundation-84.log`）。

`origin-results-v050-bf-good-84.log` 的原生动画、实际音乐推进、退出渲染器销毁和音频停止检查通过，但对应实际画面中 BF 位于可视区域之外，仅 GF 正常显示。因此该次不算视觉兼容通过。旧 [ResultState](https://github.com/FunkinCrew/Funkin/blob/v0.5.0/source/funkin/play/ResultState.hx) 直接使用旧图集的导出坐标；旧 schema 下未显式选择矩阵且未使用脚本渲染器的 Animate 图集，现由注册表标记并恢复其导出舞台坐标与初始锚点。新版、现代资源路径和明确的矩阵选择保持原规则；内部标记不接受 JSON 伪造。

构建89完成 Windows 编译和完整基础回归后，表中构建89的实际进程均以最终 `CHECKS PASSED` 和退出0结束；后补的 Gold 构建130达到最终检查标记，但未采集进程退出码。每例同时检查原生绘制、动画帧推进、实际音乐、对应元数据、无损坏脚本、退出后的渲染器销毁及音频停止。测试为显式练习/自动演奏，不是键盘验收。

| Results 样本 | 实际覆盖 | 日志 |
| --- | --- | --- |
| 官方 v0.5.0 BF Good | Animate + Sparrow 两个角色恢复到正确可视位置，已保存实际画面 | `origin-results-v050-bf-good-89.log` |
| 官方 v0.5.0 BF Great | 双 Animate 图集、0.93 缩放、延迟出现和循环，已保存实际画面 | `origin-results-v050-bf-great-89.log` |
| 官方 v0.5.0 BF Perfect Gold | 沿用旧 Perfect 两层，延迟爱心、循环及退出清理；已采集两帧画面，角色部分被记分板遮挡，仍需与旧版实际画面比对 | `origin-results-v050-bf-gold-130.log` |
| 官方 v0.5.0 Pixel BF、零音符 | 归属 BF 结算角色、0% 显示、`loopLabel` 和退出清理，已保存实际画面 | `origin-results-v050-pixel-empty-89.log` |
| 当前 Pico Good | 实际脚本从默认射击 intro 转为 `resultsLoop`，已保存实际画面；未覆盖随机特殊分支 | `origin-results-current-pico-good-89.log` |

`origin-compat-foundation-89.log` 还验证旧图集标记、显式矩阵优先、现代原始数据保持默认、拒绝伪造内部字段，以及通过现代资源 ID 读取逐字相同的旧音乐元数据。临时 Results ZIP 已按本次使用的原始哈希核对后移除，用户两个原有模组目录保留。上述案例不代表所有玩家、所有结算等级或所有历史版本均已覆盖。

旧结算音乐元数据也跟随音频别名挂载；原始 Normal 结算元数据的 BPM 就是1，保留该值，不以现代资源中的速度覆盖它。结算检查验证实际元数据命中、播放推进和退出清理。完整资源快照和44份原始回归文件的提交/blob SHA 清单保存在本机 `_build/origin-results-v050-manifest.json`，测试资源保持外置。

2026-11-01 的 Gold 复测使用同一固定 v0.5.0 外置夹具：真实结果状态记录两个 Animate 图层持续推进、爱心出现、音乐播放及销毁清理，最终 `CHECKS PASSED`；本机保存 `_build/origin-results-v050-bf-gold-130.jpg` 和 `-130-later.jpg` 两帧。画面中角色动画有部分落在左侧记分板后方；旧版源码确实将结算角色置于比记分板更低的绘制层，但仅凭两帧还不能判断遮挡范围是否与旧版运行结果一致，因此视觉一致性仍需对照原版，不把这项记作完全通过。测试进程已结束，退出码未捕获；临时模组按 SHA 校验后移除，原有两个模组及两份存档保持测试前状态。

显式调试参数现在仅为该进程选择 Origin，覆盖保存的 NF/CNE 启动选择，不改写 `chain.json`；四种保存模式的普通与调试启动路由已分别检查。键盘诊断74中 Down 的 OpenFL 按下/释放和菜单移动已确认，测试工具的 `Return`/`Enter` 当时未到达 OpenFL；该次检查不能证明确认键通过。

2026-11-01 的 `keyboard-only-125.log` 使用实际游戏进程24004，由用户仅用键盘操作，诊断器只观察。日志记录空格（OpenFL keyCode 32）禁用 YOURSELF/SILLY-BILLY、左键进入禁用列表并以空格重新启用；用户确认单按上下键每次只移动一项；日志记录 Ctrl+下/上将该模组从索引2移到1再移回2。随后两次右键选中 DONE、空格确认，一次写入 slot 1000，热重载并回到标题；保存顺序仍为 Impostor、YOURSELF。关闭窗口前没有进入 Attract。热重载将备用 slot 1000 的音量字段从0.65更新为主存档的0.05，其余字段不变；检查哈希并保留写入后的副本后，已将备用存档精确恢复到测试前，两份存档语义比较均无变化（`keyboard-only-125.verified.json`、`keyboard-only-125.save-restoration.json`）。窗口正常关闭，但本次没有捕获进程退出码。此证据验证该 Windows 键盘路径和当前已安装模组，不代表 Enter 或其他平台均已验证。

- 版本准入下限已设为已核实的 API `0.1.0`；Origin 的 API 版本与 NovaFlare 应用版本分离。
- 文件系统通过虚拟路径适配旧资源布局，覆盖文件夹和 ZIP，不移动、复制或重写用户模组。原生音频、视频路径需要返回真实文件路径。
- 同一个模组同时提供新旧路径时，新路径优先；不同模组间沿用 Polymod 的加载顺序。
- 注册表的平铺目录与嵌套目录、旧分库目录、旧歌曲音频路径需要分别验证；旧 `_merge` / `_append` 补丁必须只应用一次。
- 同一脚本被资源库以不同路径暴露时按真实来源去重；不同文件声明相同类仍应报告冲突。
- 旧角色、歌曲、舞台、关卡、对话框、着色器及已知舞台道具脚本提供迁移后的虚拟路径；后加载的规范路径覆盖同一脚本的旧来源，不依赖类名去重掩盖冲突。
- 可选的逐动画 `scale`、`cameraOffsets` 已加入数据结构和角色播放处理。
- 启动遵循保存的启用列表；独立测试可重复传入 `--origin-mod=<模组 ID>`，不改写保存的选择。
- 旧 `FlxAtlasSprite` 使用历史构造方式和 `.anim` 控制器；`ScriptedObject`、旧角色脚本的嵌套导入、流式音频类、键盘事件的 `event` 属性和旧注册表列表方法分别适配。
- API `>=0.1.0 <0.9.0` 的模组按实际脚本来源保留历史原生字段写入行为；较后 API 与无所属模组的脚本沿用当前只读规则。切换模组前恢复所记录的原生静态字段赋值，实例字段遵循对象生命周期，避免保留已销毁的精灵。字段黑名单仍由解释器先检查。历史依据为官方 v0.8.4 固定的 [Polymod fb123758](https://github.com/FunkinCrew/polymod/blob/fb123758b90127f5647727727f273d27e93cabdb/polymod/hscript/_internal/PolymodInterpEx.hx) 和 v0.8.7 固定的 [Polymod acfdc2e](https://github.com/FunkinCrew/polymod/blob/acfdc2e26722f20339a2bc0cc8cd7dd5fe0c6b5e/polymod/hscript/_internal/PolymodAbstractScriptClass.hx)。0.8.8 的覆盖是本项目为已安装 Impostor 模组采用的 0.8 系列补丁兼容策略，并非声称已验证官方 0.8.8 发布版；该模组在 `SpacedStrumline.onSongLoaded` 实际使用了历史原生写入接口。
- API `<0.7.0` 的脚本使用三参数 `new SongMetadata(name, artist, variation)` 时，在原生构造边界补上空谱师参数；API `>=0.7.0` 沿用第三参数为谱师的当前约定。依据为官方 v0.3.2、v0.5.0、v0.6.3 与 v0.7.0 的 `SongData.hx`；适配按脚本实际所属模组生效，不修改 Haxe 原生调用。
- 恢复旧 `FrameBuffer`、`FrameBufferManager`、`SpriteCopy`、`FlxFilteredSprite`、`TitleOutline` 和 `DropShadowScreenspace`。屏幕空间阴影保留旧标量 uniform、调色与抗锯齿设置，避免调用新版基类的矩阵 uniform 时崩溃。
- 旧模组的 `case SONG_NAME` 等静态/局部 final 常量按值比较，保留当前通配符与后续 API 的模式匹配规则；使用真实脚本测试匹配、未匹配和局部作用域。
- 同步切换模组时，角色注册表先清理旧角色数据与脚本类缓存，文本缓存也在重新加载模组后清除，再读取新的 JSON；图片、音频和图集缓存的专项检查另见下条。`origin-album-freeplay-185.log`：先加载含 `tankman-atlas` 的临时样本，再同步切换回已保存的 Impostor + YOURSELF，YOURSELF 遍历残留角色时抛出缺失 JSON；修正角色缓存后，`origin-character-reload-189.log` 越过该错误，却因旧专辑 JSON 文本残留在进入 Freeplay 时失败。最终 `origin-character-reload-191.log` 使用同样切换顺序，YOURSELF 模块初始化完成并实际显示 Freeplay，未出现这两处错误，正常关闭退出码0；临时样本已移出，三个存档语义未变。此验证不代表所有模组、图像与音频热重载均已覆盖。
- 同步模组重载的图片缓存对照：`origin-image-reload-198.log` 加载临时 ZIP 的同名图片，再切回保存的模组后仍得到旧像素，实际复现缓存残留。现根据重载前后模组图片键及旧路径别名，把对应 BitmapData / FlxGraphic 从查找表移除，不主动销毁已有引用。`origin-image-reload-200.log` 对同一样本验证直接读取和 FlxGraphic 均取得原资源的新像素，旧图片与旧图形引用仍可读取，进程退出0；临时 ZIP 已移出，存档语义不变。该检查只覆盖单个 PNG 的模组退出路径，不证明所有图集、连续重载内存回收或音频行为。构建199退出0但末尾报告 `Failed to update resources`；已定位为 Lime 的 `ReplaceVistaIcon.exe` 步骤，失败后程序的32像素图标不匹配项目 `icon.ico`。同一工具在独立副本上成功后，对当前程序重试也成功，32像素图标与项目图标像素哈希相同，修改前后程序 `.text` 段哈希一致；版本信息保持原值。首次失败的原因尚未确定，以后构建仍需检查该警告与输出图标。
- 在图片修复基础上，同步重载会从模组切换前后资源路径及旧路径别名中失效对应图片、声音和 Animate 图集查找项，不主动销毁现有对象。`origin-reload-image-204.log` 显示图片和 FlxGraphic 更新且旧引用仍可读；`origin-reload-audio-204.log` 使用静音播放验证新音效时长从9144ms变为642ms，旧声音引用仍有效、原通道位置继续推进；`origin-reload-atlas-204.log` 验证真实 Animate 图集重建且旧帧引用有效。三个测试都退出0并有通过标记，临时样本已移出。覆盖范围为各一个样本的模组退出路径；未覆盖所有格式、模组加入路径或连续重载内存回收。
- 图形生命周期补充：旧图形与新图形可能共享资源键，释放旧图形时按对象身份检查缓存，避免误删或销毁新图。`origin-reload-image-205.log` 在新图载入后直接执行旧图形移除，验证新 BitmapData 和 FlxGraphic 均仍可读取；`origin-reload-audio-205.log`、`origin-reload-atlas-205.log` 也通过，三个进程均退出0。测试只覆盖各一个资源样本，连续重载内存回收、所有图集和所有模组仍未证明。
- `forceReloadAssets()` 在重建注册表前同步注册脚本。加载初始化已经拆分脚本阶段，旧调用遗漏这一步会在歌曲结束后无法构造 Freeplay DJ；独立同步重载回归已实际进入 Freeplay。
- 保留旧 `BaseCharacter(id, renderType)` 的渲染类型参数；不再把旧字符串当作新参数对象后忽略。旧命中事件的 combo 参数、长按事件追加 combo 参数前的位置分别适配，原生 Haxe 调用不改写。
- `Song.buildRaw()` 同时接受早期的变体数组与当前变体 ID；早期数组参数原本不参与入口选择，适配后仍保留传入的全部元数据和谱面。`getFirstValidVariation()` 区分旧变体数组与新角色参数，`listAlbums()` 保留无参数形式。旧两参数重写函数与当前三参数重写函数在原生回调中分别接收正确位置的参数，不包装或替换原生函数引用。
- 旧分段谱面已接入运行时文件系统：`data/<song>/<song>.json` 及 easy/normal/hard 文件在内存中呈现为当前歌曲元数据和谱面，支持旧分库目录与 ZIP；不在用户模组内生成文件。合并谱面优先于遗留的分难度副本，显式当前格式文件优先。只替换 hard 时保留较低层模组或外置基础资源中的 easy/normal；各难度保留各自的 BPM、角色、舞台和镜头事件。旧格式不含作者、专辑等字段时继承已有信息。
- 转换后的完整文档先进入原有 Polymod 补丁流程；元数据与音符补丁不被后续合并丢弃。各难度的历史时间轴分别应用镜头/时间变化补丁，每处只生效一次。`Song.buildRaw()` 保持编辑器显式数据独立；其展示属性优先使用传入的元数据，避免返回同名磁盘歌曲的作者。
- 难度初始化后，重新缓存谱面保留脚本对音符样式和舞台的修改；各次缓存建立独立的镜头事件及 JSON 值，不继承已触发状态。新建歌曲实例分别克隆角色元数据，避免污染文件系统中的转换记录。
- 恢复早期没有舞台元数据时按歌曲名选择舞台/GF 的规则，以及 `needsVoices:false` 和字面后缀形式的 `voiceList`。旧合并人声优先于较低层的原版分角色人声，较后模组提供的新版分角色音轨仍可覆盖它。可选候选音轨的存在性探测不报告缺失资源错误。依据为[首个加载器时期的 PlayState](https://github.com/FunkinCrew/Funkin/blob/bfad5b33526d75211c950b8c09deb08790f3fc81/source/PlayState.hx) 和 [VoicesGroup](https://github.com/FunkinCrew/Funkin/blob/bfad5b33526d75211c950b8c09deb08790f3fc81/source/VoicesGroup.hx)。
- 旧 `funkin.data.dialogue.conversation` 下的 `BackdropData` / `OutroData` 枚举路径映射到当前同一个原生枚举；支持模块内完整路径和带导入的构造，不另建同名枚举。当前类型的导入黑名单仍然生效。

旧 `FlxAnim.onComplete = function` 和帧 `callback(name, frame)` 已通过解释器适配到当前信号；重赋值/清空只移除该旧回调，保留其他原生和脚本监听器，销毁时释放状态。旧回调时代的读取与后续 Signal 读取按脚本来源区分，字段黑名单继续生效。所有属性读取先筛选字段和目标类型，兼容版本判断按来源和规则缓存，并随 Polymod 资源库重建失效。

重复实例字段和方法按脚本所属 API 恢复历史行为：API `>=0.1.0 <0.7.2` 保留声明顺序、各次初始化和后声明覆盖前声明的缓存行为；后续 API 仍报告重复字段。依据为 [v0.7.0 固定的 Polymod](https://github.com/FunkinCrew/polymod/blob/6a3f3793c29ec2922630854ba5186f6f1d73d25a/polymod/hscript/_internal/PolymodScriptClass.hx) 与 [v0.7.2 固定的 Polymod](https://github.com/FunkinCrew/polymod/blob/3e030c81de99ca84acde681431f806d8103bcf6e/polymod/hscript/_internal/PolymodScriptClass.hx)。归属记录绑定最终注册的类描述，在脚本重载时清理，不接受脚本自定义元数据冒充旧版本。

旧 `GameOverSubState.playBlueBalledSFX()` 静态函数已桥接到当前 GameOver 实例；保存函数引用后再创建 GameOver，调用仍选择新实例，不保留已销毁的实例。没有实例时保留历史静态播放行为，静态与实例字段黑名单均继续生效。新版实例方法保持原有调用方式。依据包括 [v0.3.2 GameOverSubState](https://github.com/FunkinCrew/Funkin/blob/v0.3.2/source/funkin/play/GameOverSubState.hx) 与 [v0.8.7 GameOverSubState](https://github.com/FunkinCrew/Funkin/blob/v0.8.7/source/funkin/play/GameOverSubState.hx)。

恢复 `SongSerializer` 四个同步/异步导入入口。同步读取经过现有 `FileUtilSandboxed`，缺失文件返回空结果；文件选择器读取用户选中的文件。导入使用注册表的数据解析与迁移，返回实际 `SongMetadata` / `SongChartData` 和原生 Map，支持后续克隆和歌曲构造；不把匿名 JSON 强制当作原生类。接口依据为 [v0.3.2 SongSerializer](https://github.com/FunkinCrew/Funkin/blob/v0.3.2/source/funkin/play/song/SongSerializer.hx)。

早期 NoteStyle `1.0.0` 的空特效占位数据按原有原生实现补齐：splash 使用原版图集、动画前缀及 `0.6` 透明度，长按特效使用四张颜色图集。倒计时、判定与十个数字补上旧版默认资源；像素样式保留像素资源、尺寸和禁用特效的选择。逐项迁移，显式路径、数值及空值选择保留，文件夹/ZIP 中的原始 JSON 不改写。依据为 [旧 NoteSplash](https://github.com/FunkinCrew/Funkin/blob/v0.3.2/source/funkin/play/notes/NoteSplash.hx)、[旧 NoteHoldCover](https://github.com/FunkinCrew/Funkin/blob/v0.3.2/source/funkin/play/notes/NoteHoldCover.hx) 与 [旧 Countdown](https://github.com/FunkinCrew/Funkin/blob/v0.3.2/source/funkin/play/Countdown.hx)。禁用特效不再请求空路径资源，长按 PNG 条带不请求不存在的 XML；splash 的空图集在访问其 parent 前检查。

音符尺寸存在单独的历史差异：早期音符固定为 104 像素，v0.5.0 按 `104 × scale` 设置目标宽度，v0.5.1 起直接使用缩放倍数；旧箭头与长按条也分别保留目标宽度与额外 `0.7` 倍宽度规则。API 归属来自实际资源文件，运行时尺寸标记不从 JSON 读取；原始 scale 数值仍供脚本访问。初始化与 Strumline 后续缩放回调使用同一换算，避免后者覆盖恢复的旧尺寸。依据包括 [v0.5.0 NoteStyle](https://github.com/FunkinCrew/Funkin/blob/v0.5.0/source/funkin/play/notes/notestyle/NoteStyle.hx) 和 [v0.5.1 NoteStyle](https://github.com/FunkinCrew/Funkin/blob/v0.5.1/source/funkin/play/notes/notestyle/NoteStyle.hx)。

上游路径表有仅迁移 PNG、遗漏配套 XML 的记录。缺少显式 XML 映射时，从已有 PNG 映射推导 XML 候选路径，并继续检查文件存在性；显式映射优先，不生成虚假资源。旧 Sparrow 入口保留 Flixel 先查图集缓存的行为，缺失 XML 时给出路径诊断，避免解析空 XML 引发原生空引用。

纯 PNG 角色替换使用外部 `compatibility/origin-v0.3.2` 配置匹配旧 XML、动画及原版角色脚本。安装脚本为 `tools/setup-origin-legacy-assets.ps1`，来源固定到官方 assets 提交 `962130b2243a839106607d08a11599b1857bf8b3`；补充包不加入引擎打包资源。当前安装 12 个角色配置，模组自带 JSON/脚本优先，较后现代 atlas 覆盖恢复当前原版配置。详细放置方法见 NovaSetup 中英文资源教程。

当前尚未证明全版本兼容完成。12 个角色已取得实例构造、动画存在性及实际绘制证据，旧 BF 另有整曲游玩及两种死亡流程证据；其余历史类型及代表性模组继续补齐。标题视频原生崩溃已定位到音频回调中的对象内存重叠机制，并有受控的修补前后复现；原次 GC 交错时序仍未直接记录；Windows 视频生命周期回归已通过所列范围，详见前文。NF/CNE 已取得标题启动证据，不能据此声称两侧全部功能都已验收。

### 已取得的运行证据

- `origin-compat-foundation-49.log`：实际进程退出0，所有基础检查通过；新旧舞台脚本覆盖、歌曲脚本别名、平铺关卡脚本、着色器和角色道具脚本的规范路径与物理来源去重通过。对应 `lime test windows` 正常退出0。
- `origin-modmenu-reload-49.log`：真实热重载完成，实际显示 YOURSELF 禁用、Impostor 启用及双角色，正常关闭。启停和排序交互继续单独保留为未验证。
- 更完整的官方 v0.3.2 回归包包含187份原始脚本/JSON。构建51已修正旧整文件覆盖造成的当前脚本基类缺失，实际补回 `NeneBaseCharacter` 和 `PicoPlayerBaseCharacter`，随后暴露 `StressSong` 重复字段的历史解释器差异；此整包回归尚未通过。
- `origin-compat-foundation-51.log`：进程退出0，所有基础检查通过。补回的当前脚本保留原始 AST 和当前接口语义，只参与所需依赖，不作为角色/歌曲/模块入口重复实例化；模组自带定义优先，未引用的模块不补回，黑名单及后续 API 的导入诊断保留。检查还覆盖旧原始 preload 路径被真实来源去重后定位到当前文件的情况。
- `origin-compat-build-53.log`：`lime test windows` 编译、标题启动及正常关闭，退出0。`origin-compat-foundation-53.log` 的实际测试进程退出0，新增七个 API 的重复字段与初始化顺序检查和此前基础检查均通过。
- `origin-core-v032-note-effects-failed-53.log`：187份原始文本的实际加载已构造 `StressSong`，进入 Bopeebo 场景；随后因旧 NoteStyle 的空特效路径在当前 `buildSplashFrames` 中解引用空 atlas 失败。旧版特效原先硬编码资源路径，尚需迁移其数据和默认行为。该次记录的原生 first-chance 异常源于此处空引用，需与此前 VLC/GC 崩溃分开。
- `origin-modmenu-reload-53.log`：实际异步热重载完成，默认音符样式为 `funkin`，界面展示 Impostor 已启用、YOURSELF 未启用和两个角色。模拟键盘未改变选择，Done 鼠标点击也未触发应用流程，因此本次不能证明切换、排序和点击应用已通过。
- `origin-impostor-full-song-53.log`：安装中的 Impostor 使用自己的音符样式完成 Bopeebo 整曲，四种判定测试均执行，实际观察到箭头、HUD、判定图片及结束后的 Freeplay，随后正常关闭。该次未新增崩溃报告；模组自身的三处未解析标识符与缺失后缀图片诊断仍保留。
- `origin-core-v032-full-song-54.log`：187 份官方原始脚本/JSON 的加载已越过空 NoteStyle 崩溃，Bopeebo 完成整曲、执行四种判定并进入结果界面，未新增崩溃报告。此实测又发现箭头尺寸偏大，随后按旧版目标宽度语义继续修正。
- `origin-compat-foundation-56b.log`：实际进程退出0、全部基础检查通过，该 PID 的原生异常报告为0。新增检查构造真实 NoteSprite、StrumlineNote、SustainTrail，覆盖 API 0.1、0.5.0、0.5.1、0.9 的尺寸规则；普通文件名不会触发资源路径空引用。`origin-core-v032-full-song-size-callback-56b.log` 实测显示完整 Strumline 的后续回调仍覆盖箭头尺寸，因而不能将该轮精灵检查视为显示问题全部解决；已扩展整组缩放回归继续验证。
- `origin-compat-foundation-57.log`：实际进程退出0、无原生异常报告，完整 Strumline 四个箭头的初始化与不同横纵缩放回归通过；`origin-core-v032-full-song-57.log` 随后实际显示正常大小的旧箭头、音符和长按条，四种判定执行，Bopeebo 整曲到达结果界面。
- `origin-compat-build-58b.log` 的 `lime test windows` 正常退出0；`origin-compat-foundation-58b.log` 的实际进程退出0、全部基础检查通过、无原生异常报告，并通过旧 Senpai 路径构造了当前外置 PNG/XML 的真实 Sparrow 图集。
- `origin-core-v032-pixel-full-song-58b.log`：相同原始脚本包中的 Senpai 已实际显示旧像素舞台、角色、箭头和长按条，四种判定执行，整曲到达结果界面；该进程未新增原生异常报告。此前的像素加载失败是 XML 路径映射遗漏，文件本身已存在，无需新增外置资源。进入结果界面时记录了缺少 `cheer` 的诊断，但日志未标明动画所属角色，不能确定是结算 BF；该次加载了 GF Pixel，当前结算过渡代码会尝试播放目标角色的 `cheer`，因此 GF 是可能来源。此日志来自构建58b，尚未证明当前构建仍有该提示；该旧版整曲结果界面的退出交互也尚未验证。
- `origin-core-v032-pixel-current-181.log`：当前构建以官方旧版脚本快照、练习自动演奏重新完成 Senpai 整曲，四种判定均执行，进入 BF 结果界面后仍出现缺少 `cheer` 的提示。旧版 GF Pixel 配置确无 `cheer`，但日志未记录调用对象，归属仍是推断；关闭游戏窗口不等于验证结算界面退出交互，进程退出码也未捕获。脚本预检仍报告三个旧脚本错误（Tankman、Darnell 和 TwoHOT），不能视作整个旧脚本包通过。临时 ZIP 已移出模组目录，主存档重序列化后经逐字段比较内容不变，另外两个存档字节不变。
  三项预检诊断的静态来源已按官方 assets 提交 `962130b2243a839106607d08a11599b1857bf8b3` 核对哈希（`origin-v032-script-diagnostics-182.json`）：[Tankman](https://github.com/FunkinCrew/funkin.assets/blob/962130b2243a839106607d08a11599b1857bf8b3/preload/scripts/characters/tankman-atlas.hxc) 写了 `playAnimFbfation`，同一脚本其他分支使用 `playAnimation`；[Darnell](https://github.com/FunkinCrew/funkin.assets/blob/962130b2243a839106607d08a11599b1857bf8b3/preload/scripts/characters/darnell-blazin.hxc) 一处分支调用 `playPissed`，脚本实际定义的是 `playPissedAnim`；[TwoHOT](https://github.com/FunkinCrew/funkin.assets/blob/962130b2243a839106607d08a11599b1857bf8b3/preload/scripts/songs/2hot.hxc) 调用 `super.onStateChangeEnd`，而官方 v0.3.2 和当前 `Song` 均未声明该方法。这里是源码与预检比较，并未证明上述分支在实战中触发或不触发，也未修改上游文件或为它们虚构接口。
- `origin-pixel-exit-183.log`：同一旧版 Senpai 练习整曲后由用户手动按确认键；已触发结果退出，但创建 Freeplay 时因 `ui/freeplay/albums/freeplay/albumRoll/fnf-ost-v1` 图集缺失而报错，**退出验收失败**。旧版专辑数据指定 `freeplay/albumRoll/fnf-ost-v1`；当前 `formatRelative` 找不到原路径后又以新专辑目录作前缀，仍需区分旧资源缺失与路径兼容修复，不得用无关图片掩盖。测试进程关闭退出码0不代表游戏流程成功。临时模组已移出，三个存档逐字段内容不变（其中两个字节完全一致）。
- `origin-modmenu-reload-57.log`：修改 NoteStyle 解析和尺寸处理后，实际异步热重载再次完成，默认样式为 `funkin`，Impostor 与 YOURSELF 的启用状态及角色显示正常；此证据仍不覆盖列表切换、排序或点击应用。
- `origin-impostor-full-song-58b.log`：在最终尺寸、资源查询与 PNG/XML 转换代码下，已安装的 Impostor 使用自身音符样式完成 Bopeebo 整曲，执行四种判定并实际返回 Freeplay；该进程没有新增原生异常报告，随后正常关闭。原有三个脚本标识符诊断和缺失后缀图片仍保留。

- `origin-compat-foundation-48.log`：实际测试进程退出0，所有检查通过。API 0.1、0.5、0.8.8、0.9 脚本分别导入 v0.3.2、v0.5.0、v0.6.3、v0.7.0、v0.8.7 官方元数据/谱面，得到实际原生对象并构造含困难音符的歌曲；越过配置文件根目录的绝对文件读取被拒绝，未生成原生异常报告。对应 `lime test windows` 退出0。
- `origin-serializer-async-import-47.log`：通过两个实际 Windows 文件选择窗口导入 v0.3.2 元数据与谱面，两次回调各执行一次，实际构造 Bopeebo 及124个困难音符，观察到通过画面。基础测试的异步函数可访问检查与此项实际文件选择回调测试分开记录。
- `origin-authentic-bf-fakeout-45.log` / `origin-authentic-bf-normal-gameover-45.log`：使用官方 v0.3.2 BF 脚本原始代码体，经真实游戏流程分别通过假死和普通死亡。覆盖旧 FlxAtlasSprite、函数式完成回调、旧子状态字段写入和旧静态死亡音效调用；均达到解锁的 deathLoop 和播放中的死亡音乐，实际观察 Retry 画面。
- `origin-compat-foundation-45.log`：旧静态音效直接调用、保存引用、切换实例后的调用、新旧实例调用、后续API原规则、两种字段黑名单与无实例调用均通过。构建47的旧缺失文件拒绝测试曾记录可捕获的空引用异常，已通过同步读取的空结果检查修正，由上述构建48的进程退出码及无异常报告验证。

- `origin-compat-foundation-43.log`：全部基础检查通过；同一脚本资源路径在重建 Polymod 库后分别归属 API 0.1、0.9、0.1，缓存的真/假版本策略均正确更新。无原版脚本的 Dad 配置不会生成额外脚本类，GF 旧文件名映射及脚本渲染基类匹配通过。构建42、43的 `lime test windows` 均正常退出0，42标题回归启动全部三个轮播视频，未再出现原生崩溃。
- `origin-classic-profiles-runtime-43.log`：12 个角色的 PNG-only ZIP 实际运行，原始 JSON 动画均存在，图片来自模组且历史渲染器/非空帧数正确，实际查看完整角色网格；Sparrow 动画轮播通过。BF 假死需要真实 GameOver 上下文，单独由上述游戏流程回归覆盖。临时 ZIP 已移除。
- `origin-modmenu-reload-43.log`：真实异步热重载完成，实际显示 YOURSELF 禁用、Impostor 启用及双角色，正常关闭；启停/排序交互仍未据此宣称通过。

- `origin-classic-bf-impostor-full-song-40.log`：只有 PNG/XML 的旧 BF 模组与实际 Impostor 合用，BF 实际加载 20 个动画、574 帧，四种零分测试判定执行，整曲结束返回 Freeplay 并实际观察画面。临时 BF ZIP 已移除。
- `origin-classic-bf-normal-gameover-40.log` / `origin-classic-bf-fakeout-40.log`：分别实际进入普通死亡和假死，旧 BF 均达到未锁定的 `deathLoop` 且死亡音乐播放。两次均有实际画面及运行断言。
- `origin-compat-foundation-39.log`：所有基础检查通过，含旧纯图片 BF、模组自带脚本/JSON、现代 atlas 后覆盖、角色脚本移动路径去重及真实注册。对应 `lime test windows` 正常退出0。构建40编译成功，但标题视频期间发生原生崩溃并退出1，不列为完整通过。
- `origin-compat-foundation-37.log`：真实旧/新 API 脚本在实际 FlxAtlasSprite 上验证回调赋值、重赋值、清空、原生信号共存、跨来源读取、帧参数、黑名单及销毁释放，全部通过。

- `origin-modmenu-reload-34.log`：最新构建完成真实热重载，默认音符样式为 `funkin`；实际显示 YOURSELF 禁用、Impostor 启用以及双角色画面。合成方向键仍未观察到选择变化，启用/禁用切换交互保留为未验证。临时测试模组已移除，`Funkin/chain.json` SHA256 与原始值一致。
- `origin-compat-foundation-34.log`：所有基础检查通过；增加重复缓存时保留脚本样式/舞台、事件实例与 JSON 数据隔离、不同歌曲实例的角色元数据隔离。真实 API 0.1.0、0.8.8 脚本的旧对话枚举构造、原生枚举身份、模式匹配、完整路径和黑名单检查均通过。对应 `lime test windows` 正常启动并关闭，退出码为 0。
- `origin-legacy-impostor-visible-32.log`：临时 ZIP 只包含官方早期 Bopeebo JSON，配合实际 Impostor 模组和其音符样式运行困难谱面。实际观察到判定弹字、连击数字、角色与音符，四种零分测试判定均执行，整曲结束后同步重载并返回 Freeplay；未新增游玩崩溃。临时 ZIP 已移出用户模组目录，测试副本保存在忽略目录。自动演奏测试不代表物理输入计时已验收。
- `origin-legacy-impostor-full-song-31.log` / `origin-legacy-visual-style-reset-31.log`：早期谱面已跑完整曲并返回 Freeplay，但这两次发现请求的样式在二次缓存中被重置；因此不作为 Impostor 样式通过的证据。该问题已在上述后续回归中修复。
- `origin-compat-foundation-31.log`：所有基础检查通过。官方早期合并谱面通过真实注册表、歌曲构造与谱面缓存加载，文件夹和 ZIP 均保留 easy 110、normal 118、hard 124 个音符。分难度时间轴、空谱面、只替换 hard 时保留基础谱面、跨模组覆盖顺序、当前格式优先、人声规则、元数据与音符/镜头补丁精确生效一次均通过；早期各周舞台/GF 默认值、显式配置优先及编辑器同名歌曲数据隔离也通过。`lime test windows` 编译启动并正常关闭，退出码为 0。该项验证运行时数据流程，整曲游玩证据单独记录。
- `origin-compat-foundation-26.log`：上述基础回归全部通过；增加官方早期 Bopeebo 合并版（普通 118、困难 124、简单 110 音符）和独立困难版的转换，检查速度、角色、舞台、音符方向及长按时长。边界夹具验证空分段变速、首分段变速、多难度独立时间轴、无开头音符时的镜头事件及非法 BPM。参考[最初加载器的 BPM 计算](https://github.com/FunkinCrew/Funkin/blob/bfad5b33526d75211c950b8c09deb08790f3fc81/source/Conductor.hx)。
- 早期原始样本来自 [assets 0ae2921](https://github.com/FunkinCrew/funkin.assets/commit/0ae2921cefa5e93b0ccac3402ed56ae36f7714e8)，日期 2021-12-30，是首个元数据加载器日期之前的官方资源快照；该代码提交未固定 assets 子模块，不能称其为精确配套资源。研究目录 `first-api-assets/manifest.json` 记录路径与原始 blob SHA；数组速度格式的遗留备份保留作研究，没有冒充已验证的有效输入。
- `origin-compat-foundation-24.log`：API 0.1.0、0.5.0、0.6.3、0.7.0、0.8.8、0.9.0 夹具经真实解释器构造角色和事件；渲染类型匹配/拒绝、combo/判定/分数和可选参数位置检查通过。歌曲的直接/保存函数调用、两个变体保留、查询匹配/未匹配、无参数专辑列表、函数引用身份、新旧脚本重写函数的原生回调均通过。对应 `lime test windows` 构建正常退出，退出码为 0。
- `origin-modmenu-reload-22.log`：真实热重载完成，默认音符样式为 `funkin`；Mod Menu 显示 YOURSELF 禁用、Impostor 启用以及角色画面。合成方向键未观察到选择变化，不能把该检查记为启用/禁用切换交互已经验证。
- `origin-compat-foundation-19.log`：旧静态与局部常量的匹配/未匹配、通配符、较后 API 的原规则、静态原值恢复和实例生命周期检查全部通过。
- `origin-sync-reload-20.log`：脚本与模块重新注册后才返回；Freeplay BF DJ 实际加载九个动画，界面与曲目列表显示正常。
- `origin-impostor-full-song-20.log`：使用实际 Impostor 模组及其 `impostor` 音符样式完整跑完 Bopeebo；模组在歌曲结束时同步重载并正常返回 Freeplay，时间条和 DJ 构造错误均消失。自动演奏产生 `perfect` 判定，不能把这一结果当作普通判定弹字已经覆盖。
- `origin-impostor-player-judgements-22.log`：显式测试标志在玩家自动演奏分支轮流派发 sick/good/bad/shit 的零分事件；实际 Impostor 弹字和连击数字显示，四种分支均执行，完整歌曲结束后同步重载并正常返回 Freeplay。该入口保持练习与自动演奏，验证脚本响应，不代表物理按键计时已验收。
- `nf-boot-20-stdout.log`、`cne-boot-20-stdout.log`：共用构建分别实际进入 NF 与 CNE 的标题画面，CNE 使用原位置的外置资源；临时启动配置已按原始字节恢复，并核对 SHA256。仅验证启动，未据此声称两侧全部游玩回归已通过。
- `origin-compat-foundation-15.log`：API 0.5.0、0.6.3、0.7.0、0.8.8 的真实解释器分别验证 `SongMetadata` 第三参数语义；双参数默认值、显式四参数和无所属脚本规则均通过。旧图片目录路由、27 份官方数据样本、补丁、字段黑名单和异步读取检查同时通过。
- `origin-compat-video-13.log`：真实视频分别从文件夹和 ZIP 加载，VLC 均实际解码到 1280×720，完成三个显示帧后正常销毁；测试资源位于显式临时夹具目录，没有加入游戏打包资源。
- `origin-compat-render-14.log`：在共用 SDL2 环境中实际显示帧缓冲复制和模糊滤镜，两个旧着色器均完成构造与绘制，没有新增崩溃；阴影颜色的进一步视觉检查使用带透明边缘的夹具。
- `origin-compat-render-15.log`：带透明边缘的灰色色块实际显示橙色顶部边缘；旧角度、亮度、对比度及抗锯齿 uniform 的值检查通过。
- `origin-compat-foundation-16.log`：0.8.8 脚本实际完成原生字段写入与静态原值恢复，0.9.0 夹具保留当前 final 检查；这仅证明对应兼容策略，不等同于官方 0.9 全部 API 已验收。
- `origin-impostor-blocker-16.log`：原只读字段阻塞已越过，歌曲开始播放；随后时间条的 `case SONG_NAME` 暴露新解释器的模式匹配差异。旧实现对该分支执行 `expr(v) == val`，见 [官方旧 Interp](https://github.com/FunkinCrew/polymod/blob/fb123758b90127f5647727727f273d27e93cabdb/polymod/hscript/_internal/Interp.hx#L594)。该阻塞需修复后重新完成整曲回归。
- `origin-compat-build-05.log`：`lime test windows` 完成 Haxe、原生编译和链接；仅启用 Impostor 的自动启动进入标题画面，原先阻塞启动的重复脚本类报错消失。
- `origin-compat-foundation-05.log`：真实 Polymod 索引下的旧歌曲路径、文件夹/ZIP、模组顺序、新路径优先、旧文本追加与 JSON Patch 均通过；32 次并发读取的完成回调全部在主线程各执行一次。后续构建将 JSON Patch 的断言加强为精确应用一次。
- Polymod 的 `LimeAsyncHandler` 同时在工作线程和主线程完成同一个 Promise，本项目的 Lime Promise 立即调用监听器，可能因此重复注册类并让共享解析器跨线程运行。编译桥接只保留主线程完成，不忽略不同文件之间的重复类错误，也不关闭资源异步读取。
- `origin-bopeebo-play-05.log`：不启用模组的 Bopeebo 正常进入歌曲，已记录伴奏开始、声音同步与相机事件；该次是启动对照，未作为完整通关回归。
- `origin-compat-foundation-09.log`：25 份官方历史样本全部通过真实解析器；JSON Patch 精确应用一次；真实旧脚本经解释器完成原生字段写入、恢复原值，新规则拒绝原生 final 写入；目录、ZIP 与 32 次主线程单次异步回调检查通过。
- YOURSELF 在创建阶段的首个失败是 `NoteStyle.buildHoldCoverSprite`：没有启用长按特效的音符样式被无条件预热，之后才连锁出现空音乐对象错误。现已遵循样式的特效启用状态；`origin-yourself-full-song-09.log` 记录完整歌曲推进至结果界面，实测中没有脚本异常和新的崩溃文件。该次未验证视频资源解析，且包含较低帧率与音频时钟追赶日志，不能作为视觉效果和性能全部通过的证据。
- Mod Menu 热重载的实际日志发现 `PsychHolds` 构造先于默认音符样式就绪，以及 `LegacyPopUps` 在工作线程触发图形缓存。SDL2 路径改为逐步在主线程构造注册表，最后再构造模块；CPU/文件读取的异步加载保留。`origin-modmenu-reload-09.log` 已完成真实重载、默认音符样式为 `funkin`，上述两个模块均成功重建，两个模组列表与角色画面正常显示。该测试未改写保存的启用列表。

官方 v0.3.2、v0.5.0、v0.6.3、v0.7.0、v0.8.7 各自固定 assets 子模块提交的角色、舞台、音符样式、歌曲元数据与谱面，共 25 份原始 JSON，已取样到研究目录。`asset-samples-manifest.json` 保存每份来源和提交；它们进入真实解析器检查后才能算对应格式的验证证据。模块路径和公开成员差异清单只是人工审查线索，不能代替继承、宏生成字段、方法参数及行为的验证。

## 复测入口

先关闭游戏，再在项目根目录运行 `lime test windows`。完整编译日志保存在 `_build/origin-compat-build-*.log`。构建后从原有 `export/release/windows/bin` 运行：

```powershell
& '.\NovaFlare Engine.exe' '--origin-test=play:silly-billy' '--origin-mod=YOURSELF'
& '.\NovaFlare Engine.exe' '--origin-test=play:bopeebo' '--origin-mod=Vs Impostor Legacy Scripts - Gameplay Scripts'
& '.\NovaFlare Engine.exe' '--origin-test=play:bopeebo' '--origin-test-style=impostor' '--origin-mod=Vs Impostor Legacy Scripts - Gameplay Scripts'
& '.\NovaFlare Engine.exe' '--origin-test=play:bopeebo' '--origin-test-style=impostor' '--origin-test-judgements' '--origin-mod=Vs Impostor Legacy Scripts - Gameplay Scripts'
& '.\NovaFlare Engine.exe' '--origin-test=reload'
& '.\NovaFlare Engine.exe' '--origin-test=sync-reload'
```

测试歌曲使用练习与自动演奏，不计成绩。基础文件系统与 ZIP 检查使用显式指定的临时夹具：

```powershell
& '.\NovaFlare Engine.exe' '--origin-test=compat' '--origin-fixtures=D:/game/FNF-NovaFlare-Engine/_build/origin-compat-fixtures'
```

Impostor 当前文件中另有 `newChar` / `newchar` 拼写不一致，以及在 `SongEvent` 子类中直接使用另一个类的 `DEFAULT_MODE`。`daHUD = hud` 属于历史裸赋值，已由解释器兼容解决；构建62的临时验证模块调用安装中原始 `HUDFadeModule`，确认 HUD 先淡出再恢复，并完成 Bopeebo 整曲回到 Freeplay，未修改用户模组。其 `LegacyPopUps` 预缓存 `-pixel`、`-nuzzus` 后缀图片，但当前安装的模组只提供普通图片。这些诊断需与版本接口缺失分开，不应通过伪造变量、替换为错误图片或静默跳过功能来认定兼容。

当前安装模组中仅发现一份 `*chart.json`：YOURSELF 的 Silly Billy。其谱面包含4个 `ChangeCharacters`，但没有 Impostor 的 `ChangeCharacterEvent` 或 `ClassicCameraZoom` 事件（`_build/impostor-chart-event-audit-194.json`，含谱面 SHA256）；前者属于 YOURSELF 自己的事件，不能混同。Impostor 的 `newchar` 诊断位于缺少预载角色的报错分支；`DEFAULT_MODE` 仅在读取的 mode 为空时作为后备，事件自身 schema 给出 `direct` 默认值，但尚未验证所有谱面的默认值处理。此静态统计不覆盖脚本动态派发、外部谱面或其他格式，也不代表这些事件已修复。


## GameBanana 真实旧模组诊断（2026-11-01）

- 选取 [The Devil’s Swing V-Slice](https://gamebanana.com/mods/419740) 的 0.4.1、0.5.x 两个包，以及 [Azzy’s BF Reskin](https://gamebanana.com/mods/557592) 0.5.3 包；下载校验、SHA-256、元数据及目录清单见 `_build/gamebanana-origin-legacy-20261101/inventory.json`。前两包只有 `_polymod_meta.json` 不同，分别声明 API 0.1.0 和 0.5.0；网页的游戏版本与元数据 API 不应混为一谈。
- 使用资源副本、独立模组目录及独立存档；三组诊断前后用户的两个 Origin 存档、NF 存档和正式 `chain.json` 的哈希一致，见 `real-save-hashes-v3.json`。首次隔离启动未跳过视频，未进入模组；日志保留，该次不算模组结果。
- 原始二版 Devil’s Swing 均因角色文件的转换器 `Made_With` 标记被严格解析器拒绝，脚本预热 0 错误但角色不能实例化。代码现仅对可确认归属旧 API 模组的角色文件去除字符串形式的顶层标记，保留原始解析器严格性及其他未知字段错误。构建230后的三组日志显示 Bendy 和 Bendy Sad 已加载和实例化；这只证明越过该阻塞。
- 接下来三组均在 Insanity 游玩初始化时遇到模组请求 `default` 音符样式而该样式不存在，日志显示加载过渡已回退至 `funkin`，但 PlayState 未回退并抛错。已让 PlayState 与加载和倒计时采用相同的默认样式回退，同时保留缺失 ID 诊断；该新增改动的运行效果等待构建231及后续回归。Azzy 组合的脚本预热为 0 错误，但尚未证明其角色在游玩中显示。所有上述诊断均为限时启动检查，未完成整曲。

- 构建231退出0；`postfix-reviewed-v5.json` 汇总三组各50秒的隔离运行。两个 Devil’s Swing API 声明版本及与 Azzy 的组合都成功构造 Bendy 并开始播放模组歌曲 Insanity；原始 `postfix-results-v5.json` 的 `reachedPlay` 字符串检查不匹配实际日志、`errors` 会误匹配 `persistent`，以复核摘要及各原始日志为准。`default` 样式不存在的错误仍保留，PlayState 回退后能够进入歌曲，不代表该样式存在。
- 0.5.0 声明版本在测试期间另报 `BFZero.onUpdate` 对 `BaseCharacter.holdTimer` 的无效访问。脚本通过类名访问该成员，而本地官方 v0.3.2 和 v0.5.0 快照中 `holdTimer` 都是实例字段，属于模组脚本与官方接口不一致，不能当作已解决的引擎 API 变化。0.4.1 与组合在限时窗口未记录此错误，不代表该分支不会触发。三组均未跑完整曲；Azzy 实际角色画面和更多模组内容仍未验证。用户存档及 `chain.json` 前后哈希一致，见 `real-save-hashes-v5.json`。

- 0.4.1 声明版本进一步运行时也复现了相同的 `BFZero.onUpdate` / `BaseCharacter.holdTimer` 错误；因此两版都不能算完整游玩通过。为避免卡在报错窗口无效等待，测试进程由测试脚本外按 PID 和可执行文件路径核对后终止；`v6-fullsong-result.json` 中 `finished=true` 只表示进程已经结束，退出码 -1 是人为终止，不是正常退出。原始日志、终止说明与存档哈希对照保存在 `_build/gamebanana-origin-legacy-20261101/`。

- `boundary-reviewed-v7.json`：在隔离测试覆盖层中仅把 Insanity 的玩家 ID 从 `bfZero` 改为 `bf`，未改下载的原模组；同时加载 Azzy 与 Devil’s Swing。45秒窗口中注册了 `AzzyBoyfriend`、创建歌曲玩家 `bf`、加载 28 个 BF 动画并开始播放模组歌曲，未观察到脚本异常；未验证画面或整曲。独立旧/现代 API 边界样本证实：旧模组的字符串 `Made_With` 可通过；旧模组的非字符串标记、其他未知字段，以及现代 API 模组的该标记均被拒绝。三个用户存档和正式 `chain.json` 的哈希在两项检查前后保持一致。


## 全版本变更审查与集中实现（进行中）

- 以最早 Polymod 集成提交 `bfad5b33526d75211c950b8c09deb08790f3fc81`、全部 25 个 v0.3.2–v0.8.7 正式标签、当前导入的 `92b437886e1ef1b5c7a0fa184be92a66b14e2cd3` 和 2026-11-01 查询的官方 main `86cb949c74743b2bdbb58a66326acdb47a36f43a` 为固定样本。导入分支不是 v0.8.7 的后代，单独与两条线比较；两个方向的分支对比会重复统计变化。更早 v0.2.7.1 为 2021-02-14，早于 2022-01-20 的 Polymod 集成，不作为同一 Origin 模组 API 的起点。
- 资料位于 `_build/origin-complete-version-audit-233/`：28 个源码快照、28 组 Git 树差异、4,765 份源码/配置/测试等文本差异，以及 22 个资源子模块树、2,869 份去重文本对象和 5,709 份资源文本差异（含分支反向对比）；源码文本及资源对象的 Git 哈希校验均无失败。二进制资源仅保留路径和对象哈希，未逐字节比对内容。30 个固定依赖提交和 Haxe hscript 2.5.0 标签也已取得；后者尚未与 haxelib 发布包逐字节核对。
- `semantic-review-ledger.json` 按领域组织全部路径变化；`unique-removed-api-candidates.json` 和 `unique-signature-change-candidates.json` 分别是 606 个去重的移除候选与 1,074 个声明变化候选。它们是文本索引，会包含继承、宏、格式和内部成员造成的误报，尚未逐项完成语义审查，不能作为缺陷数或完成度。1,559 个历史资源 JSON 的根字段已索引，嵌套结构及运行行为仍需检查。
- 已开始同一批次的未验证实现：恢复旧 `ScoringSystem` 与 LEGACY/WEEK7 评分入口及公开常量，恢复 `SongEventHelper.easeDirList` / `easeDirs`，以及旧 `NoteKindManager.listNoteStyles` 的原始空结果行为。默认 PBOT1 路径拟保持当前实现；历史 `PBOT1_MISS_SCORE` 在早期为 0、后期为 -100，按模组版本处理的准确性仍待设计和验证。以上改动尚未编译或运行验收，其他候选也尚未处理完。

- 持续整理的待验证批次还包括：旧输入偏移与音画偏移字段、旧全局谱面渲染距离/位置计算、舞台 `maskTexture`、旧玩家/周列表入口、旧 Discord 偏好、早期结算音乐方法、旧音符特效无参构造及预加载，以及 `StructureUtil`、`FlxColorUtil`、`DataAssets` 的旧导入。列表别名使用当前引擎的基础/模组分组，不声称还原每个旧发布版本的固定列表；输入偏移虽映射现存偏好，导入分支的组合偏移符号与旧版不同，实际计时语义还须验证。`LegacyPublicApiChecks` 已加入批量验证入口，包含评分边界、HScript 调用、列表别名及音符特效等检查；本批尚未编译或运行。
- `registry-root-key-audit.json` 静态核对了 186 份角色、106 份舞台和 11 份音符样式的官方历史 JSON，根字段均在现有类型声明中出现；`stage-character-nested-key-audit.json` 对 879 个舞台道具、318 个舞台角色和 2,677 个动画条目进行嵌套键统计，并处理了动画 typedef 继承。发现4份官方角色数据中的8个动画条目使用未声明的 `asset` 字段；对应版本源码同样声明 `assetPath`，应作为待查的上游数据/兼容边界，不能仅凭名称猜测并静默转换。上述均为静态字段检查，非格式、实际解析或运行通过的结论。

- 对上述 `asset` 字段，结合其值指向角色死亡图集、所在条目为 `firstDeath` / `deathConfirm`，本批新增了仅对旧模组角色数据生效的兼容推断：把字符串 `asset` 用作缺失时的 `assetPath`，显式 `assetPath` 优先；非法类型及现代模组继续交给严格解析器报错。这是为兼容历史数据增加的适配，不宣称旧版源码原生识别该字段。批量回归夹具包含未改动的官方 `bf-car.json`、显式新字段优先、非法类型及现代模组边界；尚未编译和运行。

- 后续候选审查中，`NoteKindManager.registerBaseNoteKinds` / `registerScriptedNoteKinds` 已按当前初始化逻辑拆成旧版公开入口，旧 `Song.getVariationsByCharId` 和 v0.4 结算等级音乐查询方法已恢复。旧 `StructureUtil` 使用当前受限反射访问字段，批量检查包括对黑名单字段的拒绝，避免旧接口绕过当前脚本安全边界。对应实现和检查都尚未编译运行。

### 2026-11-01 集中回归更新

上文标为“尚未编译或运行”的条目描述的是当时状态；本批代码随后完成 `lime build windows`（构建 249，退出 0），隔离运行的基础兼容检查退出 0，日志出现 `ALL FOUNDATION CHECKS PASSED`。构建日志末尾仍有 `Failed to update resources`，不把退出码扩大解释成所有运行场景通过。回归覆盖上述旧 API、黑名单、歌曲事件参数、旧按键接口、角色图集字段及既有夹具；未覆盖所有历史游戏行为。首次运行发现官方旧角色图集 `atlasSettings.uniqueInCache` 无法解析；现已把这一选项加入数据类型并通过夹具验证，其值进入现有图集加载器的独立缓存设置。扫描已收集的官方 JSON 后，其余 `atlasSettings` 字段均有声明。

两次隔离运行均在测试目录使用单独存档；核对的用户存档、`chain.json` 和 `Project.xml` 前后哈希一致。记录为 `_build/origin-history-batch-build-249.log`、`_build/origin-history-batch-foundation-249.log` 和对应 JSON。启动器最初以含方括号的字符串寻找标记，但 trace 输出去掉方括号，已按实际终止标记更正记录。

仍有已知语义边界：不同历史版本的 PBOT1 漏键分数与组合音频偏移符号有差异；旧 `SongDifficulty` 部分音轨路径 API 曾返回字符串，现在返回 `AssetPath`，脚本直接使用字符串方法时仍需适配验证；歌曲事件 scalar 值在旧版无参调用时使用 `key`，当前有事件 schema 时默认使用 schema 首字段。候选接口和二进制资源尚未全部完成语义审查，不能据此次基础回归宣称所有历史模组兼容。
同一构建使用从 GameBanana 取得的 Devil's Swing 旧版和 Azzy 组合在可见窗口中测试，结果记录于 `_build/gamebanana-origin-legacy-20261101/postfix-results-v10.json`。两种组合进入 Insanity，均出现 `BFZero.onUpdate` 对 `holdTimer` 的无效访问；旧版官方源码中该字段为实例字段，模组对其作静态访问是其脚本问题，不能据此宣称该模组通过。另一次测试因失焦暂停未完成。各项在测试时限结束后终止，均非整曲通过。日志还存在查找 `default` 音符样式失败后回退默认样式的记录，须继续核对。测试前后用户存档和 `chain.json` 哈希一致。
音符样式警告进一步核对：该模组元数据写的是 `default`，而官方 v0.4.1 的 `Constants.DEFAULT_NOTE_STYLE` 为 `funkin`；当前运行日志确认回退到 `funkin`。该样本本身指定了不存在的样式 ID，不能将警告简单归因为旧 API 缺失；是否存在模组自带的其他同名样式仍应按具体包检查。

### 旧版歌曲路径与事件键（构建 251）

官方 v0.3.2 至 v0.8.7 的歌曲音轨路径接口返回字符串；现对归属 API `>=0.1.0 <0.9.0` 的 HScript 直接方法调用，在解释器完成原有访问检查后将 `getInstPath` 的路径对象和三个 `build*VoiceList` 数组中的路径对象转换为字符串。新版脚本和引擎内部调用保留对象类型，数组转换不修改原数组。对同一旧脚本直接调用歌曲事件 `valueAsStruct()`，恢复旧默认键 `key`；新版脚本继续使用事件 schema 的首字段。保存方法引用后调用、旧版备用伴奏参数筛选以及旧版音频偏移符号尚未完成适配和验证，不应解释为全部路径行为已一致。

`lime build windows` 构建 251 退出 0；可见窗口运行完整兼容检查，进程退出 0 且出现全部基础检查通过标记。真实 API 0.8.0 和 0.9.0 脚本覆盖直接调用的路径类型及事件默认键，单独断言数组转换不改写原数组。运行使用独立存档，受保护文件哈希前后一致；日志和结果分别为 `_build/origin-history-batch-build-251.log`、`_build/origin-history-batch-foundation-251.log` 和 `_build/origin-history-batch-foundation-251.json`。此前提到的字符串返回与事件默认键为本段所覆盖的直接调用路径，不代表保存方法引用等其他路径已经通过。


### 保存方法引用及旧备用伴奏（构建 252）

构建 251 之后，对旧脚本读取到的 `SongDifficulty` 路径方法和 `SongEventDataRaw.valueAsStruct` 方法引用增加兼容包装；字段读取仍先经过解释器原有访问检查，保存后的方法执行时也重新检查实例字段黑名单。旧脚本直接调用或调用保存的 `getInstPath` 时，显式备用伴奏必须在元数据 `altInstrumentals` 中，未声明则回退默认；API 0.9.0 保留现有行为。适配限定脚本调用边界，原生内部调用和未测试的其他播放接口不能由此推断为完整复现所有历史行为。

构建 252 `lime build windows` 退出 0，日志末尾仍有 `Failed to update resources`；可见隔离回归进程退出 0 并出现 `ALL FOUNDATION CHECKS PASSED`。API 0.8.0 和 0.9.0 的真实 HScript 覆盖直接和保存引用两种调用、已声明与未声明备用 ID、事件默认键；保存引用后增加字段黑名单的拒绝检查通过。用户存档、`chain.json`、`Project.xml` 核对哈希前后相同。证据见 `_build/origin-history-batch-build-252.log`、`_build/origin-history-batch-foundation-252.log` 与对应 JSON。此前构建 251 的未完成条目以本段验证范围为准。


### 真实 API 0.8.0 模组与歌曲注册线索（构建 252）

取得 [Vs. Beepie BF Lover - VSlice](https://gamebanana.com/mods/626644) 的 `vsbeppie_vslice_5f9b2.zip`（GameBanana 文件 1613641；MD5 `39ead686b19a0f0799872dd3966b4881`；SHA-256 `cb1c4384731040b3f5129fb67a481b10c1f4914233d3f2d7dfe85fb365866e73`），元数据 API 为 `0.8.0`，仅解压至隔离测试目录。可见窗口以自动演奏和练习模式运行 `Polkka` 的 hard 谱面，完整歌曲进入结果界面；模组的 `animeExpopolkka` 舞台脚本在期间执行。日志未见脚本执行错误，但存在重复导入和旧纹理缓存 API 弃用警告。窗口在 150 秒测试时限结束后终止，未验证结果界面退出；因此这是单首实际流程证据，非整个模组通过。测试日志 `_build/gamebanana-origin-legacy-20261101/v12-beepie-080-polkka.log`；启动器 `errors` 字段将诊断字段 `critical=false` 误匹配为错误，需以原始日志为准。用户存档与 `chain.json` 哈希保持一致。

同包 `Its-okay`、`Mine` 等目录名与其元数据文件名大小写不一致，而 `Polkka` 名称一致；现引擎实际只从该包注册了 `Polkka`，第一次按 `its-okay` 启动回到标题，未算通过。官方 v0.8.7 通过列举匹配后缀的路径并取首层目录发现歌曲，现 `Assets.listDataFilesInPath(..., nested=true)` 还要求文件名以目录 ID 精确匹配；旧引擎在该样本的真实加载结果及当前虚拟文件系统的大小写解析尚需验证，不能直接认定是模组作者错误或声称已修复。


### 旧歌曲大小写别名（构建 254）

对于旧 `data/songs/<目录>/` 中，元数据或谱面文件的歌曲名前缀与目录名仅大小写不同的情况，增加与目录名一致的虚拟 `gameplay/songs` 别名；不重命名或改写原始模组。Windows 上允许同一来源的大小写不同的虚拟名称都进入 Polymod 资源索引，同时保留已有物理文件及其他来源的优先级。此适配不处理完全不同的目录名与歌曲名，也不改变通用歌曲 ID 的大小写匹配规则。

`lime build windows` 构建 254 和可见隔离基础回归均退出 0；夹具经过资源索引与真实歌曲解析，检查大小写别名及同包显式现代元数据优先，原文件未被改动。日志 `_build/origin-history-batch-build-254.log` 和 `_build/origin-history-batch-foundation-254.log`。

对未修改的 Beepie API 0.8.0 样本，修复前只注册包内歌曲 `Polkka`；修复后还注册 `Its-okay`、`Mine`、`Stalker`、`That-i-need` 和 `Together-forever`。可见窗口自动演奏 `Its-okay` 的 hard 谱面进入结果界面，日志未见脚本执行错误；重复导入、旧纹理缓存 API 及结果角色缺少 `cheer` 动画的提示仍存在。测试采用练习和自动演奏，结果画面计数为零，未确认该计数的原因；测试时限结束前未验证结果界面退出。样本自己的 `Its-okay/manifest.json` 还把 `songId` 写为 `together-forever`，不能归因于本次大小写改动。日志与记录见 `_build/gamebanana-origin-legacy-20261101/v14-beepie-080-Its-okay.log`、`postfix-results-v14.json` 和 `real-save-hashes-v14.json`；核对的用户存档及 `chain.json` 前后哈希一致。启动器的 `errors` 字段会误匹配 `critical=false`，以原始日志为准。

结果界面的零计数已核对代码：`--origin-test=play` 以练习和 Bot Play 运行；Bot Play 自动命中分支发送零分事件并执行命中动画，但不调用真人命中分支中增加 `Highscore.tallies.totalNotesHit` 的逻辑。结果界面的“TOTAL NOTES”显示的是 `totalNotesHit`，因此这次零计数本身不能证明谱面缺失，也不能证明 804 个原始谱面音符全部命中。实际音符数量和计分仍应以非 Bot Play 的独立验收为准。


### 旧评分与 ZIP 路径边界（构建 256）

官方 v0.3.2–v0.6.2 的 PBOT1 超出 160ms 时返回 0，v0.6.3 起为 -100。依据这些版本接受的模组 API 范围，归属 API `>=0.1.0 <0.6.0` 的旧脚本读取 `PBOT1_MISS_SCORE`、直接或通过保存的引用调用 `Scoring.scoreNote` 时使用早期值；后期脚本及引擎原生调用保持当前值，LEGACY/WEEK7 的路径不改。模组 API 是兼容策略依据，不保证所有作者填写的元数据都能唯一识别他们实际针对的游戏版本。已取得的旧版源码和版本/API 对照保存在 `_build/origin-complete-version-audit-233/` 与 `_build/origin-version-history/manifest.json`。

构建 256 `lime build windows` 退出 0，可见隔离基础回归进程退出 0 且完整通过。API 0.1.0、0.5.0、0.6.3 和 0.9.0 的真实 HScript 分别验证常量、直接和保存引用的调用、160ms 边界与 LEGACY 模式；保存引用后的静态字段黑名单检查通过。另使用独立 ZIP 模组验证旧歌曲目录与文件名前缀大小写不同时的元数据和谱面解析，并确认后加载模组的现代文件优先于较早模组的虚拟别名。测试未覆盖全部 ZIP 结构及全部评分行为。记录为 `_build/origin-history-batch-build-256.log`、`_build/origin-history-batch-foundation-256.log` 和对应 JSON；核对的用户存档、`chain.json` 和 `Project.xml` 前后哈希一致。


### 实际模组结算退出观察（构建 256）

Beepie API 0.8.0 原始模组的 `Polkka` 在可见窗口自动演奏进入结果界面，用户报告手动按确认键后已返回；测试日志 `_build/gamebanana-origin-legacy-20261101/v15-beepie-080-result-exit.log` 没有记录返回后的具体目标菜单，启动器在其时限结束后终止进程，故此处保留用户观察，不把日志作为完整的 Freeplay 返回证明。隔离测试前后核对用户存档与 `chain.json` 哈希一致，见 `real-save-hashes-v15.json`。

此前 `Its-okay` 的 `cheer` 提示来自其选用的模组角色 `gfexpo`：原始 `data/characters/gfexpo.json` 有 9 个动画，不包含 `cheer`，而上游 `PlayState.zoomIntoResultsScreen` 会请求该动画；控制器检测缺失后跳过并记录提示。没有伪造动画或把提示记成崩溃；其他角色的结算动画和缺失资产问题仍须分别验证。


历史官方脚本导入清单中，12 个按源码文件路径看似缺失的类型进一步分类：8 个有对应的生成原生类型、2 个有 Polymod 生成的 abstract 实现，另 2 个在历史 HScript 中声明；路径分类证据见 `_build/origin-complete-version-audit-233/import-review-257.json`。这是静态生成物和历史文本检查，不证明所有相应导入和成员在运行时都有效，也没有据此添加可能重复的别名。


### Philly Erect 历史灯光与 0.5.x 模组（构建 258）

[原始 Pico (Chill Mix) 模组](https://gamebanana.com/mods/569584) 提供的 0.5.1 和 0.5.3 两个包均声明 API 0.5.0；它们的旧舞台引用 `philly/erect/win0`。修复前两版均因资源缺失而无法创建该舞台对象，脚本随后对空对象访问 `shader`。核对官方 0.5.1 和 0.5.3 的 assets 树，两版五张 Erect 灯光 Git blob 哈希一致，且与普通 Philly 灯光不同。现从固定的官方 assets 提交 `b2404b6b1cba47da8eef4910f49985d54318186b` 获取对应原图，逐张校验 SHA-256；路径兼容层在原始资源不存在时映射到现有外置兼容目录下的 `stages/phillyTrainErect/`，不会用普通灯光代替。更新后的资源安装脚本可重复使用，并在检测到本地修改时保留已有文件。

构建 258 和可见隔离基础回归退出 0；五张资源均验证了旧路径到原图的解析。安装脚本在隔离目录实际运行通过。原始模组的 0.5.1 版与 0.5.3 版均已在可见窗口自动播放重混歌曲并进入结果界面，未再出现先前灯光缺失及其空对象错误；结算退出未验证。两版原始脚本在预热时仍报告未声明的 `cutsceneMusic`，旧版 Stage 源码也未声明该字段；当前运行中未观察到对应分支异常，不能算模组全无问题。0.5.3 的首次重测被人工误关，已另行完整重跑。日志 `_build/gamebanana-origin-legacy-20261101/v17-pico-chill-051.log`、`v18-pico-chill-053.log`；测试在隔离存档执行，核对用户存档和 `chain.json` 前后哈希一致。

为使当前本地运行目录可使用该修复，已向现有外置兼容目录新增五个经校验文件（共 51,295 字节）；未覆盖既有文件，原资源清单哈希未变化。文件来源和哈希记录在 `_build/gamebanana-origin-legacy-20261101/pico-chill-05/main-assets-install.json`。其他安装位置可运行 `tools/setup-origin-legacy-assets.ps1` 补充，不将完整上游 assets 打包。

### Alien Hominid Revival 版本辨识（构建 260）

[Alien Hominid Revival V-Slice](https://gamebanana.com/mods/551680) 的 0.5.x 包（文件 1415824）、0.6.0–0.6.2 包（1415823）和 0.6.3 包（1431108）均保存于隔离测试目录并通过发布方 MD5 校验。三版 `hominid` 音符和判定线 `scale` 均为 0.7；前两包都声明最低 API 0.5.0，但后者提供了四方向自定义音符特效，与 0.6.3 包的样式一致。官方 0.5.0 将音符与判定线宽度按固定轨道宽计算，0.5.1 起按贴图比例缩放；0.6.0 起才由样式数据构建音符特效。最低 API 因而不能唯一标识模组所针对的具体游戏版本。

构建 258 可见测试中，0.5.x 包因启用的音符特效路径为空，在歌曲开始前尝试加载空资源并报错；0.6.0–0.6.2 包自动演奏原创歌曲 `Eradication` 并进入结果界面，但画面判定箭头偏小；0.6.3 包的同款箭头明显更大，该次测试因录屏安排未完成全曲。证据分别为 `_build/gamebanana-origin-legacy-20261101/v19-alien-05.log`、`v19-alien-060.log` 和 `v19-alien-063.log`。测试使用隔离存档及模组目录，结果界面退出未验证。

构建 260 已完成，可见窗口的隔离基础回归出现 `ALL FOUNDATION CHECKS PASSED`，但启动器记录的进程退出码为 null，不能据此声称退出码为 0；其核对的用户存档、`chain.json` 和 `Project.xml` 哈希不变。基础检查覆盖旧空特效占位、现代显式配置以及四方向完整和不完整特效配置。

修复后两版分别在可见窗口以自动演奏和练习模式完整运行原创歌曲 `Eradication` 并进入结果界面，0.5.x 未再发生空资源异常；0.6.0 版可见箭头大小与修复前的 0.6.3 对照一致，PlayState 右下角的版本文字已移除。日志为 `_build/gamebanana-origin-legacy-20261101/v20-alien-05.log`、`v20-alien-060.log`；隔离运行前后用户存档与 `chain.json` 哈希不变。测试在结算后按时限结束，结果界面退出、手动游玩及计分未验证；日志中出现 Conductor 更新延迟警告。0.6.0 版还出现 `NoteSplash failed to initialize all animations`：该包为四个方向各配置一个溅射动画，实际共四个；官方 0.6.0、0.6.3 和 0.8.7 的提示仍用少于八个动画的固定阈值，因而不能仅凭这条提示认定加载失败。溅射的逐方向视觉效果尚未单独验收。

新版四方向特效是尺寸判断线索，并非作者目标版本的可靠证明，其他同 API 模组仍有歧义，不能将本样本推及全部模组。

构建 260 的可见隔离死亡流程使用该模组原始 0.5.x 包、`Eradication` 谱面及角色 `AlienBF`：测试在练习和自动演奏模式中直接触发引擎死亡方法，观察到角色的 MultiSparrow 死亡循环和 `gameOver-alien` 音乐，再直接调用确认方法完成重试，重试后三秒角色存活且没有受保护脚本损坏。检查器报告 `CHECKS PASSED`，用户存档和 `chain.json` 哈希不变；证据为 `_build/gamebanana-origin-legacy-20261101/v21-alien-05-death.log` 和 `real-save-hashes-v21.json`。这不是键盘输入验收，也没有覆盖从实际漏键扣血或自杀音符到死亡的路径。

### Devil’s Swing 的 `default` 音符样式回退

该模组的四首歌曲元数据明确指定 `noteStyle: "default"`，原始包内没有同名样式。核对保存在 `_build/origin-complete-version-audit-233/asset-trees/` 的 22 份官方资源树，也没有 `notestyles/default.json`；官方 0.3.2、0.4.1、0.5.1、0.5.3 和 0.6.0 的默认样式常量均为 `funkin`，相应 `PlayState` 在指定样式查找失败时调用 `fetchDefault()`。当前版本的回退路径与这一历史行为一致。因此，此前真实模组日志中的 `default` 样式查找失败本身不是已证实的迁移缺陷，不应通过覆盖或伪造用户样式来消除；若另一个已启用模组确实提供 `default`，仍应按实际资源优先级加载。上述是资源清单与源码比较，不能证明该模组其他脚本或完整歌曲均已通过。

### 早期强制动画的待处理差异

官方 0.3.2 和 0.4.1 的 `Bopper.playAnimation` 在 `canPlayOtherAnims` 为 false 时，仍允许参数 `ignoreOther=true` 的新动画打断当前动画；0.5.0 至已核对的 0.8.7 改为根据当前名称、重启标志及前缀例外决定是否放行。当前实现沿用后者。真实 Devil’s Swing API 0.1.0 包的 `bfZero.hxc`、`bendy.hxc`、`bendy-sad.hxc` 和 `BendyNormalStage.hxc` 存在 `playAnimation(..., true, true)` 调用，因此该差异可能影响旧模组的强制动画切换。现有真实模组测试没有证明在前一强制动画尚未结束时触发这些调用，也不能确认该条件下的实际画面；此项仍待构造同时覆盖脚本 `this`、`super`、原生对象及保存方法引用的运行验证后再决定适配方式。不得对所有新旧角色直接改用旧版规则，否则会改变 0.5.0 之后的官方行为。

强制动画诊断还暴露了独立问题：测试中的临时 Bopper 动画未注册偏移时，当前 `applyAnimationOffsets` 把 null 传给偏移 setter，发生 `hxSehException`；官方 0.3.2 和 0.4.1 会把缺省或零偏移处理为全局偏移。失败证据 `_build/origin-history-batch-foundation-262.log`；该测试夹具随后显式提供零偏移，以便单独检验强制动画规则。空偏移及旧版全局偏移坐标语义尚未修复或验证，不能将夹具修正当作问题已解决。

### 0.5.x 的样式尺寸与强制动画（构建 267）

Alien Hominid 的 0.5.x 包和 0.6.0 包都声明最低 API 0.5.0；前者 `hominid` 样式版本为 `1.1.1`，没有新版方向溅射数据。先前只用方向溅射判断导致 0.5.x 仍按 0.5.0 固定宽度缩小。现对 API 0.5.0 的 `1.1.1` 至低于 `1.2.0` 的样式默认采用后续版本的比例缩放；`1.1.0` 保留固定宽度规则。隔离回归通过模组拥有的两种样式文件检查边界，真实 0.5.x 模组可见窗口中箭头大小与该模组 0.6.3 版一致。最低 API 和样式 patch 版本都不能唯一证明作者针对的精确引擎，故这是一条兼容默认规则，不保证其他模组全部适用。日志为 `_build/origin-history-batch-foundation-267.log`、`_build/gamebanana-origin-legacy-20261101/v23-alien-05-sizing.log`。

旧强制动画规则现限于声明 API `>=0.1.0 <0.5.0` 的脚本调用：锁定时强制调用可切换，非强制调用按旧规则被拦截；其他 API 和调用后的原生代码继续使用当前规则。隔离检查使用真实 HScript 和原生 Bopper，覆盖直接调用、保存原生方法、脚本自身调用、`super` 以及保存自身方法；对照 API 0.1.0、0.5.0、0.9.0，并检查保存方法的原生黑名单及异常后的范围恢复。作用域按线程隔离。历史基线、失败和修复后的记录分别为 `_build/origin-history-batch-foundation-261.log`、`-262.log`、`-263.log` 和 `-267.log`；构建 267 完整基础检查标记通过，用户存档、`chain.json` 和 `Project.xml` 校验值不变，启动器记录退出码为 null。该适配针对脚本调用，并不声称原生引擎主动调用旧角色时也切换为旧规则；Devil’s Swing 实际触发重叠强制动画的具体画面还未单独验收。

### 缺省动画偏移（构建 268）

针对构建 262 复现的缺省偏移空值异常，`Bopper` 在动画未登记偏移时使用全局锚点的副本，避免把 null 传给 setter 或沿用上一动画的偏移；已登记偏移保持原路径。可见隔离基础回归通过，真实旧 HScript 操作原生 Bopper 验证了从有偏移动画切换至无偏移动画、非零全局锚点及数组互不别名；日志 `_build/origin-history-batch-foundation-268.log`，所核对的用户存档、`chain.json`、`Project.xml` 哈希前后一致。历史版本的非零偏移曾直接修改对象坐标，当前实现通过屏幕位置计算；本次未证明所有缩放与脚本读取坐标场景完全一致。

构建 270 进一步把旧版动画规则限定于 Bopper 及其脚本代理，并在嵌套的旧、新脚本调用之间保存和恢复各自规则；非 Bopper 同名方法不启用旧规则。可见隔离基础回归检查了这些边界，以及脚本代理保存自身方法后重新应用脚本类字段黑名单；此前五种调用形式、空偏移和样式大小检查也继续通过。证据 `_build/origin-history-batch-foundation-270.log` 及对应 JSON；所核对的用户存档、`chain.json`、`Project.xml` 哈希不变，启动器的进程退出码仍为 null。嵌套规则检查使用受控调用，不能推断所有第三方脚本和所有跨模组交互均已覆盖。

构建 270 的可见短时真实模组回归使用 Devil’s Swing API 0.1.0 和 Alien Hominid API 0.5.0：两者进入各自的原创歌曲；前者再次报告 `Bendy.onUpdate` 写入 `BaseCharacter.holdTimer` 无效，后者在本次短时窗口未见脚本执行错误。前者的原始脚本将 `holdTimer` 当作 `BaseCharacter` 的静态字段赋值，但对应官方旧版和当前源码将其声明为实例字段；这一错误并非前述强制动画差异的证明，也不能算模组通过。日志为 `_build/gamebanana-origin-legacy-20261101/v24-devils-041.log` 和 `v24-alien-05.log`；窗口按测试时限关闭，未进行整曲及结算验收，用户存档与 `chain.json` 哈希不变。

### 旧角色脚本的 `BaseCharacter.holdTimer` 写法（构建 271）

Devil’s Swing 的旧角色脚本把实例字段 `holdTimer` 写成 `BaseCharacter.holdTimer`，这不是官方旧版的有效静态字段。为兼容该模组写法，解释器仅在归属旧 API 的脚本、写入目标正是 `BaseCharacter.holdTimer`、值为数字且当前脚本代理确实拥有一个角色实例时，将写入导向该实例；不修改模组文件，也不把字段变成全局静态值。静态字段、实例字段和脚本类字段的黑名单检查仍适用。API 0.1.0 和 0.5.0 的真实 HScript 角色样本通过实例写入检查，API 0.9.0 样本保留无效静态字段诊断；另检查非角色调用和静态/实例字段黑名单。可见隔离基础回归标记全部通过，证据 `_build/origin-history-batch-foundation-271.log`。

原始 Devil’s Swing 的 0.4.1 和 0.5.x 包在可见窗口各运行约 100 秒进入 `Insanity`；此前开场出现的 `Bendy.onUpdate`／`holdTimer` 脚本异常没有再次出现，两份日志中未见脚本执行异常。模组指定 `default` 样式的查找失败仍按旧版回退 `funkin`，相关依据见上节。窗口按时限结束，未验完整曲目、结算或所有脚本分支；日志 `_build/gamebanana-origin-legacy-20261101/v25-devils-041.log`、`v25-devils-051.log`。隔离测试前后用户存档及 `chain.json` 哈希一致；基础回归还核对 `Project.xml`，哈希不变。该补偿是针对模组不符合原始 API 的写法，不能视为官方历史字段语义。

构建 271 随后对 Devil’s Swing 原始 0.4.1 和 0.5.x 包分别运行可见窗口完整曲目：两版均以练习／自动演奏模式播放 `Insanity` 并进入结果界面；两份日志未出现先前的 `holdTimer` 无效访问或其他脚本执行异常。模组的 `default` 样式仍按历史规则回退。测试进程在各自时限结束后终止，结果界面退出、手动操作及正常计分未覆盖；用户存档和 `chain.json` 的测试前后哈希一致。证据 `_build/gamebanana-origin-legacy-20261101/v26-devils-041-full.log`、`v26-devils-051-full.log` 和 `real-save-hashes-v26.json`。这覆盖该曲目的这两次运行，不代表模组所有歌曲和分支通过。

### 原始 0.3.2 模组样本（构建 271）

取得 [Yippie V-Slice 0.3.X Port](https://gamebanana.com/mods/511184) 的文件 1186571（MD5 `726e7da102474eb4e988b43b136f27f8`，SHA-256 `2dce968ed07c9c79beb794a9440ec6290f74e8172784223d888e219f02b31339`）和 [VS. Tord](https://gamebanana.com/mods/511442) 的文件 1186977（MD5 `2a87963486964f07b1732437447ebe3e`，SHA-256 `d66d8ac38511ba5c1395885586d1790328f6b1b7678bf098feb212f5f7d21433`）；两包均声明 API 0.1.0，经过路径和链接检查后只解压到隔离目录。可见窗口分别以练习／自动演奏模式完整播放 `Yipe` 与 `Norway`，均进入结果界面；未见脚本执行异常。

两份谱面都引用未随包提供的 `item` 音符样式以及 `Inst-mom.ogg`，引擎日志报告查找失败后回退到默认样式与 `Inst.ogg`；Yippie 包也没有独立人声文件，日志记录缺失。官方 0.3.2 的 `playInst` 使用默认 `Inst.ogg`，但缓存路径仍会参考元数据的伴奏字段；因此不能仅凭回退后的播放把资源配置问题视为完全解决。未验证手动游玩、正常计分或结算退出。日志 `_build/gamebanana-origin-legacy-20261101/v27-yippie-032.log`、`v27-tord-032.log`；隔离测试前后用户存档及 `chain.json` 的哈希一致。

### 0.9 预览接口增量（待验证，构建 275）

依据固定预览提交 `d3fdf329faa7419dbf91afd7b3204f36e010daa2`：旧路径解析接口增加第四个参数以跳过兼容映射，并增加 Animate 图集目录辅助方法；歌曲事件字符串数组返回类型更正为 `Array<String>`。保留默认旧路径重定向，并增加针对选项关闭、旧映射、图集路径和字符串数组的基础回归检查。相关文件在两份本地工作目录分别更新。

构建 275 在 Haxe 阶段消耗内存后，可用内存降至约 1.5 GiB；根据用户防止电脑过载的要求，主动停止本次构建，停止后可用内存回升至约 6.1 GiB。此次构建和新增回归未完成，不能作为兼容通过证据。0.9 预览对话数据、资源预加载、模组管理和其他脚本接口仍待审查；不宣称完整支持。

### Origin 0.9 预览对话 1.1（代码待验证）

固定预览提交 `d3fdf329faa7419dbf91afd7b3204f36e010daa2` 的对话数据从 1.0 扩展到 1.1。对照源码后，本地增加 1.1 版本接受范围、可选动画、逐条打字音效、静音数组和按行自动推进；1.1 的速度按倍率设置，1.0 保留原有速度路径。同步修复空动画及循环动画导致的开场等待，并添加新旧数据解析检查。旧格式与新格式的跨模组、音效生命周期、自动推进、脚本回调及实际运行尚未验证；这不是完整移植预览版对话组件，资源预加载、静态图片等其他上游变更仍待处理。

这些修改与构建 275 的接口改动都尚未完成编译，受可用内存约束暂停完整构建；新增测试也尚未运行。不得将静态审查写成运行通过。

轻量检查（276）：采用真实 `ConversationData`、从生产源码提取的对话解析函数和当前 json2object，在 Haxe 解释器中验证 1.0 缺省字段、1.1 自定义字段以及显式静音；另从实际源码提取自动推进、音效切换和路径方法，以替身模拟外部组件，检查推进阈值、音效释放、速度倍率、默认旧路径和关闭兼容映射。三组检查均退出 0，日志 `_build/origin-dialogue-lowmem-276/results.log`；路径测试中不存在的示例图集产生的 ERROR 是该用例预期日志。提取的替身测试不能证明 Flixel、脚本事件、真实音频和文件系统集成，也没有完成完整游戏编译或运行。

继续核查实际 FlxTypeText 更新逻辑发现，非 null 的空音效数组会取空元素后调用 `play`，而零打字延迟会用于除法和取模。现将显式静音映射为底层的 null 音效列表；1.1 零速度保留正延迟并请求跳过打字，空文本避免在同步回调后误跳过下一行。提取实际方法并用替身进行的低内存检查退出 0，见 `_build/origin-dialogue-lowmem-276/silent-zero-speed-277.log`；未验证真实 Flixel 更新循环或完整游戏构建。

### 0.9 歌曲事件资源声明（代码待完整验证）

对照固定 0.9 预览提交，增加歌曲事件 `queryAssets(type, data)` 接口和注册表分发；本地 LoadingState 在谱面已缓存且非 minimal 模式时收集每个事件声明的图片与声音资源，复用既有预加载流程。脚本异常走既有 ScriptGuard，缺失处理器或空返回不会阻塞其他事件。内置切换血条图标事件会在文件存在时声明图标图片及 XML；本地预加载流程目前消费图片和声音，XML 声明供查询接口使用，不代表已增加 XML 预加载。

低内存 Haxe 检查从实际注册表方法和 LoadingState 代码提取路径，以替身模拟事件处理器、异常和空返回，检查图片与声音进入列表及空事件列表，退出 0；日志 `_build/origin-event-lowmem-278/results.log`。完整工程编译、真实 HScript 覆写和实际资源加载尚未验证，不能把此测试当作整条真实加载链通过。

### 0.9 角色选择访问器（代码待完整验证）

对照固定预览提交，为角色选择数据增加公开的渲染类型和 Animate 图集路径访问器，并让角色选择界面使用这些访问器。空路径继续回退到角色默认目录；旧版顶层路径和新版嵌套字段的优先级与原本界面保持一致。低内存检查从真实方法提取代码，以替身验证默认渲染器、空白路径、旧路径及新版嵌套字段，退出 0，见 `_build/origin-character-select-lowmem-279/results.log`。另为完整基础回归添加真实玩家数据解析用例，尚未运行；脚本调用、实际角色选择及完整构建均未验证。

对照 0.9 预览继续补充对话文字换行回退：当文本布局暂时报告零行或空内容时保留原文，避免对话文字被清空；HTML5 按上游禁用预换行。低内存检查从真实方法提取代码，以替身模拟零行、跨行及空布局，退出 0，日志 `_build/origin-wrap-lowmem-280/results.log`。该检查不覆盖真实 OpenFL 字体布局、HTML5 或完整游戏构建。

为弥补替身事件测试的覆盖缺口，新增 API 0.9 的 `PreviewAssetEvent.hxc` 夹具，以及通过实际 Polymod 类注册、`SongEvent.scriptInit` 和事件注册表查询图片的完整基础回归用例。夹具已使用项目所选 Polymod 解析器作低内存语法检查，退出 0，见 `_build/origin-event-parser-lowmem-281/results.log`；完整回归尚未构建和运行，解析成功不能证明 HScript 覆写已实际执行。

### 0.9 真实模组元数据与 ZIP 读取（低内存检查，完整运行待验）

取得 [WeekEnd1 Pico Freeplay BG 的 0.9 Preview 3 测试版](https://gamebanana.com/mods/607150)，该作者在页面的备用下载提供测试包；文件大小 5,039,922 字节，SHA-256 `c5e0d35819c986a244fc246707589befcbdf080213a10cfcc886157632caec1f`，包中声明 API 0.9.0。其 `_polymod_meta.json` 存在尾随逗号，且 `mod_version` 使用非 SemVer 的 `3.0.0(beta1)`。使用项目选中的 Polymod 解析器复现：原文因 JSON 失败，单独移除逗号后仍因版本失败；这是样本内容错误，不是官方 0.9 元数据语义。

Origin 模组文件系统现仅在读取 `_polymod_meta.json` 时生成内存中的兼容文本：安全移除字符串之外的尾随逗号，并将 `数字.数字.数字(后缀)` 转换为对应的 SemVer 预发布形式；有效元数据原样返回，其他不合法 JSON 不隐藏，也不改写原包或原文件。项目实际选择的 Polymod 和实际 Origin 文件系统在隔离检查中通过原始 ZIP 与文件夹扫描、API 版本识别、ZIP 模组初始化和样式 JSON 读取；没有修改用户模组选择。

同一次检查发现项目 Polymod 的 ZIP 读取实现遇到短读取时使用剩余长度追加缓冲区，解释器测试中该模组的 1,107,538 字节 PNG 被错误读成 7,832,310 字节。现只在 Origin 模组文件系统中使用完整读取并验证解压长度，保留 ZIP 失效清理；修复后原始图片长度与 SHA-256 `04a4057fc42dd5802e1ea88b973270be5008ada6f7c78aaf46ca09700d474354` 均匹配。所选 Polymod、实际 Origin 文件系统与真实样本的隔离检查通过，日志 `_build/gamebanana-origin-preview-20261101/origin-zip-read-test.log`；其中其他历史资源迁移协作者使用替身。完整游戏编译、可见窗口中的该模组和其他 ZIP 变体尚未验证。

ZIP 读取继续补充边界检查：在隔离目录生成大文件的 STORE、DEFLATE、带 data descriptor 的 DEFLATE、大小写不同的路径，以及长度字段损坏的条目。使用所选 Polymod 和实际 Origin 模组文件系统检查，前三种读取结果与源数据逐字节一致；大小写不敏感查询正确；长度不符的条目返回 null；历史图片路径别名仍能读取原始 ZIP 字节。测试同时使用实际 `LegacyAssetLayout`，其中上游路径映射表与歌曲/角色迁移协作者使用受控替身，日志 `_build/origin-zip-variants-lowmem-282/results.log`。只验证这些构造用例，不代表检测所有损坏或完成游戏内验证。

进一步复现并修复中文及其他非 ASCII 模组名／文件名的 Origin 读取问题：所选 Polymod 的 ZIP 文件系统读取前会过滤非 ASCII 字符。Origin 文件系统现保留 ZIP 原始路径，并对存在的非 ASCII 普通文件使用原路径读取。构造的中文 ZIP 和文件夹均通过实际 Polymod 元数据扫描；中文 ZIP 还通过 Polymod 初始化与资源索引，读取内容与源字节一致。记录 `_build/origin-zip-variants-lowmem-282/unicode-before.log`（修复前失败）和 `unicode-polymod.log`（修复后通过）。该隔离检查使用实际 Origin 文件系统与所选 Polymod；历史路径映射表和歌曲／角色迁移部分仍为替身，完整游戏和其他平台尚未验证。

为避免损坏 ZIP 的伪造长度造成不必要的分配，读取前先检查压缩数据范围是否位于实际文件内；DEFLATE 按声明的解压大小设边界，超出即停止。隔离测试涵盖伪造超大压缩长度、实际内容超出声明、65,535 字节缓冲边界和单字节内容，并重跑旧别名、中文路径、STORE、DEFLATE、descriptor 和真实 Polymod 索引，见 `_build/origin-zip-variants-lowmem-282/bounded-read-283.log`。真实 0.9 样本的元数据、样式和图片 SHA-256 复核通过，见 `_build/gamebanana-origin-preview-20261101/origin-zip-bounded-283.log`。这些是 Haxe 解释器的隔离检查，完整游戏构建、原生目标和所有损坏格式仍未验证。

真实 0.9 样本进一步以低内存方式联合所选 Polymod、实际 Origin 模组文件系统、json2object 的真实 `FreeplayStyleData` 类型，以及提取自生产代码的 `getBgAssetKey` 和 `formatRelative` 方法测试：原始包初始化后，样式 JSON 成功解析，背景路径解析为 `ui/freeplay/styles/pico/background-darnell`，图片字节与原 ZIP 的 SHA-256 一致。记录 `_build/gamebanana-origin-preview-20261101/freeplay-style-284.log`。路径存在性查询使用指向实际 Polymod 索引的受控替身，未实例化完整 FreeplayState，也未验证画面或 UI 交互。

### 0.9 及历史 ZIP 空文件的兼容修复

静态核查项目实际选用的 Polymod `SysZipFileSystem.addZipFile` 发现，它跳过压缩大小或解压大小为零的 ZIP 条目；`ZipParser.LocalFileHeader.isValid` 也会拒绝没有 data descriptor 且两个大小均为零的本地文件头。因此修复前的 Origin ZIP 兼容读取不能保证空文件被索引或读取；空脚本、空资源覆盖等运行场景仍需进一步验证。

2026-11-01 修复与对照：已用实际 Polymod 构造文件夹、STORE 和 DEFLATE 空文件对照，修复前 ZIP 条目均不可见，文件夹可读取；Origin 文件系统现为非目录空条目补充索引，并针对合法的零长度 STORE 文件校验本地头后返回空字节。修复后文件夹和两种 ZIP 条目均可读取，真实 Polymod 初始化及资源索引也能取得空字节，见 `_build/origin-zip-variants-lowmem-282/empty-285.log`。原 ZIP、别名、Unicode、截断和解压边界回归通过，见 `empty-regression-285.log`。上述测试使用 Haxe 解释器和隔离夹具；原生完整构建和游戏内行为尚未验证。

### Origin 编辑器默认鼠标恢复

四个 Origin 编辑器进入时接管鼠标并抑制 NF 鼠标特效，销毁时释放。进一步检查发现，其他界面或 HaxeUI 可能在 `cursorMode` 仍是 Default 时替换实际 Flixel 鼠标图像，原 `Cursor.show()` 因模式未变而不重新载入默认图像。现显示时重新应用 Origin 默认图像，并清除 HaxeUI 的上次指针解析缓存，使后续鼠标移动可重新解析控件样式。提取实际 `show()` 的低内存替身测试覆盖首次显示、图像被替换后的重复显示、指针模式和样式缓存，见 `_build/origin-cursor-lowmem-286/results.log`；真实编辑器窗口和原生构建尚未验证。

### 0.9 对话角色实例

对照 Origin 预览提交 `d3fdf329faa7419dbf91afd7b3204f36e010daa2`，SpeakerRegistry 的 `fetchEntry` 现优先实例化脚本角色；非脚本角色有已知数据时新建实例，未知 ID 保留基类查找行为。此前该注册表直接返回缓存对象，可能让多个对话共享角色的可变状态。提取实际方法的低内存替身测试覆盖实例隔离、参数传递、未知 ID、脚本优先级和仅有脚本的 ID，见 `_build/origin-speaker-lowmem-287/results.log`。未完成完整原生构建或真实模组对话验证，不据此宣称该路径已在游戏中通过。

### 0.9 注册表静态资源查询的接口冲突

固定预览提交新增的 `BaseRegistry.queryAllAssets/queryAssets` 和注册表宏依赖条目类的静态 `queryAssets(type, id, params)` 与脚本静态方法分发。本地 `Song`、`Stage`、`BaseCharacter`、`NoteStyle` 已有同名实例方法，直接添加上游静态方法会触发 Haxe 的“同名字段不能同时用于静态和实例”编译错误；最小复现见 `_build/origin-query-conflict-288/result.log`。预览源码中静态查询声明与本地对应文件的自动清单见 `_build/origin-upstream-preview-20261101/query-assets-inventory-288.json`，该清单是文本筛查，包含注释命中与上游移动文件，不等于逐类完成语义审查。现有事件实例查询属于不同接口，不能证明歌曲、角色等静态脚本查询可用；需要统筹旧实例 API、0.9 静态脚本分发、各条目默认资源、注册表继承和加载器后再实现并运行真实脚本回归。

对照同一 0.9 预览提交，切换到下一条对话时现按上游要求强制重新播放指定的说话角色动画；此前连续对话使用同一动画名时，播放进度可能延续而不会从头开始。代码调用与当前 `Speaker.playAnimation(name, restart)` 接口已核对，实际对话场景和原生构建尚未验证。

对静态查询冲突进一步使用项目实际选用的 Polymod 进行隔离试验：HScript 派生类可声明与 Haxe 基类实例方法同名的静态 `queryAssets`；静态方法可被发现和调用，传入的类型、ID 和参数对象可在脚本中接收，原生实例方法也可调用，见 `_build/origin-static-query-probe-289/arguments.log`、`params.log`。首个尝试在脚本表达式中访问参数属性并拼接字符串时出现空引用，原因未确认（`result.log`）；以上通过结果不覆盖该表达式，也不覆盖注册表、原生目标或实际模组。下一步必须明确该异常并验证静态分发和旧实例回退，再整体接入，而不能将上述试验作为完整适配通过。

静态查询试验空引用定位：分别测试发现字符串拼接可用，访问匿名参数对象的 `variation` 时才报错。隔离副本保留的栈指向 Polymod `Interp.get` 调用 `checkTypeForDeprecation(oScriptCls)`；普通对象的 `getScriptClassName` 返回 null，随后弃用检查对空键执行 `StringMap.exists`。在解释器隔离副本中为类型和字段弃用检查增加空类名提前返回后，属性读取和原失败表达式均通过，见 `_build/origin-static-query-probe-289/field-stack-294.log`、`guard-295.log`。简单 StringMap 空键试验在 Haxe 解释器及 Neko 均报错；完整 Polymod Neko 探针因既有 null-safety 编译错误未运行（`neko-296.log`），Windows hxcpp 尚未验证。修补目前仅在 `_build` 隔离副本，未修改用户选择的共享 Polymod 依赖，也未接入正式引擎；需核实依赖固定与分发方式并做原生回归。

正式源码现通过已在 Project.xml 配置的 `OriginScriptCompatMacro` 对所选 Polymod 的两个弃用检查在编译期添加空类名保护，不改共享依赖或 Project.xml；若目标方法或签名改变，宏会报错要求复核。对实际所选 Polymod、正式宏和真实 HScript 的解释器测试断言匿名对象属性读取、静态方法参数、字符串拼接、原实例方法及空/普通类检查通过，见 `_build/origin-static-query-probe-289/project-macro-assertions-298.log`。完整兼容测试中也新增同场景断言，尚未编译运行。完整宏组合、Windows hxcpp 和真实游戏仍待验证；注册表静态资源查询尚未接入。

兼容宏交互补充：以项目所选 Polymod 和 `-D hscriptPos` 联合启用实际 `historicalSongPaths` 与 `nullDeprecationSafety`，脚本属性读取、参数、拼接和旧实例方法断言均通过，见 `_build/origin-static-query-probe-289/macro-interaction-300.log`；历史运行时适配函数使用透传替身，因此不覆盖真实旧版转换，也没有覆盖其余全部宏。首次缺少项目的 `hscriptPos` 标志时无法编译（`macro-interaction-299.log`），第二次已按项目配置启用该标志。完整工程原生构建仍未执行。

注册表静态查询第一阶段已接入：`BaseRegistry.queryAssets/queryAllAssets` 优先通过 Polymod 脚本桥调用条目的静态查询并传递类型、ID 与参数；不存在静态方法时，仅对已有缓存条目的现有实例查询回退，不因查询而新建有副作用的对象。角色注册表按其独立缓存和现有目录查询处理。提取正式方法、联用真实 Polymod 和真实 HScript 的低内存测试通过静态优先、参数、旧实例回退、缺失 ID 及汇总，见 `_build/origin-static-query-probe-289/registry-dispatch-301.log`；完整测试中已增加真正 SongRegistry 的静态脚本查询断言，尚未构建运行。上游其他条目类的默认静态资源规则尚未逐一移植，没有现有实例查询的类型会返回空列表；谱面加载器尚未接入这些注册表查询，角色自定义渲染器静态分发、变体实例回退与 hxcpp 反射仍待验证，不声称完整 0.9 预加载支持。

0.9 静态脚本预加载已接入 Windows 常用 `PRELOAD_ALL` 路径：缓存谱面后查询当前歌曲、舞台、谱面角色和相关音符样式所声明的图片及声音；字符 ID 和最终资源路径去重，不为无静态方法的条目触发全目录回退。查询异常通过 ScriptGuard 回退空列表，原有事件与实例样式加载保留。提取正式注册表方法、联合真实 Polymod/HScript 的测试覆盖声明、旧回退、脚本失败与汇总（`_build/origin-static-query-probe-289/registry-error-304.log`，ScriptGuard 使用替身）；提取加载器分发代码的低内存测试覆盖歌曲变体、不同资源类型与角色去重（`loader-303.log`，注册表使用替身）。上述不是完整工程、真实 Flixel 预加载或原生运行验证；自定义角色的特殊静态资源规则、其他注册表默认规则及 `NO_PRELOAD_ALL` 路径仍需核对。

0.9 对话注册表默认查询补充：说话角色返回图片和 XML；静态对话框只返回图片，有动画时才返回 XML；会话汇总说话角色、对话框、默认或自定义打字音效以及音乐，显式空音效保持静音，并按资源路径去重。提取正式方法的低内存替身检查通过静态/动画对话框、角色资源、缺失条目、静音、自定义音效、音乐及去重（`_build/origin-dialogue-assets-lowmem-305/results.log`、`conversation-306.log`）。测试没有构建真实注册表或载入图像音频，也没有证明对话预加载已与完整游戏状态联通；其他条目默认查询及原生构建仍待完成。

0.9 自由选曲注册表默认查询补充：样式提供背景、数字和选择器图片，以及数字、选择器 XML；专辑提供封面和标题图片，并仅在 XML 实际存在时返回 XML。`_build/origin-freeplay-assets-307/results.log` 以原始 0.9 模组 ZIP、实际 Polymod 和实际样式数据解析器，联合提取自正式代码的样式资源键与注册表查询，确认背景路径指向已索引的真实模组图片，并检查类型与可选 XML；注册表实例和资源存在性桥使用隔离替身，未绘制游戏画面或完成完整工程构建。

0.9 舞台默认资源查询现依据已加载舞台数据及与实际舞台相同的相对路径规则解析道具，而不只扫描舞台目录；覆盖静态图片、Sparrow XML、Packer 文本、Animate Atlas 图片/JSON、纯色跳过及路径去重。Windows 常用预加载现在在没有静态脚本查询时使用该舞台默认查询；有脚本查询时保持上游脚本优先，错误不阻塞加载。低内存测试读取真实旧模组 `gb-alien-hominid-05` 的舞台 JSON 和存在的 `Escenarios/Callejon/sky.png`，并用替身检查其他渲染格式（`_build/origin-stage-assets-lowmem-308/results.log`）；提取加载器分发的替身回归通过（`_build/origin-static-query-probe-289/loader-stage-309.log`）。测试中的路径和资源索引使用替身，未执行真实 Flixel 舞台加载、完整构建或所有外置资源场景。

0.9 角色默认资源查询现使用角色实际 `assetPath`，按照本地角色加载器解析相对路径，并覆盖 Sparrow、Packer、Animate Atlas、Multi-Sparrow 与 Multi-Animate 的混合子图集；添加存在的血条图标，按路径去重。常用加载流程在角色没有静态脚本查询时使用这些默认结果，脚本查询仍优先。低内存测试读取真实旧模组 `gb-alien-hominid-05` 的 alien 配置，验证角色目录外的 `characters/Alien assets.png`，并以替身覆盖混合图集及去重（`_build/origin-character-assets-lowmem-310/results.log`）；加载器提取测试见 `_build/origin-static-query-probe-289/loader-character-311.log`。这些测试未运行完整角色加载或构建；非默认资源库中的 Animate 图集、脚本自定义渲染和原生资产缓存仍需验证。

Animate 图集路径构造现拆分 `库名:路径`，通过现有兼容路径转换获取实际资源目录，供图片/JSON 列举和相对路径判断使用；目录字符串避免重复添加库名，旧别名仍按实际 Animation 路径解析。提取正式构造器、相对路径方法和图集列表方法的低内存替身测试覆盖默认库、指定库、旧别名及缺少 Animation 的图集（`_build/origin-atlas-library-lowmem-312/results.log`）；完整兼容回归新增指定库路径断言但尚未运行。实际资源库索引、真实图集渲染和完整原生构建仍待验证。

Animate 路径进一步在实际所选 Polymod 和 ZIP 文件系统中验证：隔离 ZIP 同时包含默认目录与 `shared` 目录的图集，Polymod 初始化后，将真实索引传给提取的正式图集构造器和相对路径方法，默认库、指定库、别名及缺少 Animation 的情况均通过（`_build/origin-atlas-polymod-313/results.log`）。测试的资源路径构造和列表包装仍是指向实际 Polymod 索引的替身，别名转换是受控替身；没有加载位图或实例化 FlxAnimate，不能代替完整游戏验证。

故事关卡和贴纸包的默认资源查询已补充：关卡汇总标题、关卡图、难度图、道具和非纯色背景，并只返回存在的可选 XML；空歌曲列表不会调用依赖首曲的难度查询。贴纸路径与本地实际显示方法使用同一相对路径规则并去重。提取正式方法的低内存测试读取真实旧模组 `weekalien.json`，检查标题、道具与背景，并以替身验证难度、缺失 XML 和贴纸路径（`_build/origin-story-assets-lowmem-314/results.log`）。实际故事菜单、贴纸显示、完整注册表和原生构建尚未验证；玩家注册表的上游默认查询本身返回空列表。

歌曲注册表默认查询现对 JSON 列出歌曲数据及变体，排除目录内 Animate 图集的 `Animation.json` 和 `spritemap1.json`，其他类型不因默认查询触发整目录音画缓存；脚本静态查询仍优先。`_build/origin-song-assets-lowmem-315/results.log` 使用实际 Polymod、实际旧资源别名文件系统、提取的正式数据列表及注册表方法，读取真实旧模组 Eradication 的谱面和元数据副本，确认旧路径映射、额外变体和图集排除；变体与图集文件为隔离合成夹具，Paths 返回值使用替身。完整兼容测试新增真实 SongRegistry 对旧路径谱面的查询断言，尚未构建或运行；未验证游戏内 Eradication 箭头视觉尺寸。

加载画面分支现在与常用分支共用歌曲、舞台、角色、音符样式和事件的资源收集；跳过 minimal 模式，对资源和已请求的伴奏/人声路径去重。缓存成功、异步失败和同步抛错均释放相应加载回调，避免资源失败后加载画面永远等待；谱面音符列表为空时跳过额外样式遍历。提取正式回调方法的替身检查覆盖成功、异步失败、同步异常、待完成与重复完成（`_build/origin-loading-callback-lowmem-316/results.log`）；提取正式收集代码的替身测试覆盖旧样式、脚本、舞台、角色、事件和空音符（`collection-317.log`）。没有完成实际加载画面、HTML5、手机或完整工程构建验证；这项加载画面修复不等同于 NF PlayState 手机小窗自动暂停的设备验收。

2026-11-01 再次只读核对 Origin 上游远端分支：`preview/public-playtest` 仍指向已审查的 `d3fdf329faa7419dbf91afd7b3204f36e010daa2`，本次未发现该分支的新提交；`develop` 指向 `b2215482c25c5e98a72ac47b4807018934480d01`。该检查只比较远端分支头，不能证明其他分支或未发布资源没有变化。GitHub 未认证 REST 请求触发共享 IP 限流，未据此推断最新正式发布版本；本地代码和远端均未修改。

静态脚本查询的继承语义已核对：Haxe 类不继承父类静态方法，项目所选 Polymod 也仅检查当前脚本类的静态声明；真实 Polymod/HScript 隔离测试确认子类没有显式声明时不会错误调用父类静态查询，已有实例回退仍可用（`_build/origin-static-query-probe-289/inheritance-318.log`）。完整兼容回归增加相应断言，尚未在原生工程运行；这不证明所有脚本继承或注册表场景均兼容。

较完整的低内存源码编译检查：将未裁剪的正式 `BaseRegistry.hx` 与 `StageRegistry.hx` 放入隔离工程，用项目选定的 Polymod、Lime、OpenFL 和 json2object 编译运行；测试真实泛型继承、舞台默认查询覆盖、图片/XML 路径，另以真实 Polymod/HScript 检查基类的静态脚本分发和实例回退（`_build/origin-real-registry-lowmem-319/script-dispatch-320.log`、`_build/origin-real-stage-registry-321/results.log`）。注册表宏、Stage、资源路径和其他引擎依赖使用隔离替身，目标为 Haxe 解释器；不等同完整工程宏组合、hxcpp 或真实舞台渲染通过。

### Eradication 箭头尺寸复核的限制

针对用户反馈重新审查 `gb-alien-hominid-05`、`060`、`063` 的原始样式与图集：三份 `Alien_Notes.xml` 的 SHA-256 相同，PNG 的 SHA-256 也相同；样式均为 1.1.1、音符和接收箭头 scale 均为 0.7。所抽查的帧在 XML 中的裁剪区域为 260×310，而 `frameWidth/frameHeight` 为 155×155；像素透明范围中的非透明部分高度超过 155。逐帧尺寸、偏移和哈希见 `_build/eradication-arrow-audit-322.json`。现有选定 Flixel 解析器会分别读取裁剪区域与 sourceSize；这些数据本身不足以确定最终屏幕绘制大小或作者预期。因此此前“0.5.x 视觉大小与 0.6.3 一致”只能证明两个移植包相互一致，不能独立证明尺寸正确；用户所指的 Eradication 视觉问题仍需原生运行时、参考版本或作者预期的直接证据。不要仅根据这些静态数据修改原图集，也不要声称该问题已完全验收。

补充上游源码核对：Origin v0.5.1 的 NoteStyle 对音符使用配置 scale 直接设置两轴，StrumlineNote 也直接使用接收箭头 scale；该模组 1.1.1 样式当前选择的比例缩放与这一版本的源码约定一致。此证据只说明缩放公式一致，尚未证明所用 Flixel 帧解析、显示位置和最终视觉大小一致，也无法排除模组配置自身的问题。

Origin 编辑器初始化现于 Toolkit.init 后调用 Cursor.setupHaxeUICursors，注册编辑器默认、指针、文字等鼠标素材与 HaxeUI 同步回调；此前该函数在工程内没有调用点。低内存隔离测试使用实际 OriginFunkinEditors 源码和 HaxeUI、资源与 Cursor 替身，确认调用顺序、样式注册流程及主题设置（_build/origin-editor-init-lowmem-323/results.log）；未验证真实 HaxeUI 图像加载、界面鼠标动态切换或完整原生构建。

编辑器鼠标主题补充：将 HaxeUI 常见调整大小指针映射到编辑器十字光标，等待指针映射到编辑器沙漏，未知名称的同步回退使用编辑器默认图像；谱面编辑器仅在指针不可见时才于节拍恢复，避免反复重置已选样式。提取实际注册段的低内存检查通过（_build/origin-editor-cursor-alias-lowmem-324/results.log）；HaxeUI 鼠标事件的真实执行顺序、未知样式回退及可见窗口仍未验证。

编辑器鼠标缓存衔接：HaxeUI 与 Cursor.cursorMode 各自缓存状态，鼠标图像被另一方替换时仅检查名称可能不重新加载。现解析到新样式时显式加载已注册图像并失效 Cursor 模式缓存，使随后编辑器工具能够重新应用自身指针；自定义图像、未知名称和 none 保留各自处理。提取正式 applyCursor 的低内存替身测试覆盖注册图像、模式恢复、自定义图像、默认回退及隐藏（_build/origin-cursor-sync-lowmem-325/results.log）；真实 HaxeUI 事件顺序、外部图像加载及可见窗口尚未验证。

进一步低内存检查编译了未裁剪的正式 Cursor.hx 和项目选定的实际 HaxeUI CursorHelper.hx，运行默认、控件指针、切回工具指针、缩放别名、未知名称、隐藏和恢复用例，全部通过（_build/origin-cursor-real-source-lowmem-326/results.log）。Flixel、OpenFL、Screen、MouseHelper、资源系统等为替身，解释器结果不证明真实窗口、事件顺序或完整原生构建通过。

通用注册表的静态脚本资源查询现复用已有的 ScriptGuard 路径，单个模组查询抛错时返回空列表，不中断其他条目；没有静态查询的条目仍使用原生回退。低内存测试使用未裁剪的 BaseRegistry、实际 Polymod/HScript 和项目匿名对象安全宏，验证真实脚本抛错、正常脚本和原生回退（_build/origin-real-registry-guard-lowmem-328/results.log）；ScriptGuard 与部分注册表依赖是隔离替身，未验证完整游戏或原生构建。

继续以正式 BaseRegistry、正式 ScriptGuard 和实际 Polymod/HScript 验证静态资源查询：Polymod 自身会捕获并报告一类 HScript 错误，因此上次测试不能单独证明外层保护器捕获了该类错误；另用替身桥接验证了逃逸异常的保护。真实解释器测试发现脚本报错后 _classDeclOverride 未恢复（context-before.log），现查询调用保存并恢复原上下文，包括已有外层上下文的情况；修正后的检查通过（_build/origin-real-registry-real-guard-lowmem-329/context-after.log）。保护器、注册表与解释器为实际源码，Flixel 和部分工程依赖使用替身；本修正仅覆盖注册表资源查询，不声称修复 Polymod 所有静态调用，也未完成原生构建。

将静态脚本上下文恢复从注册表局部提升到 Origin 的 Polymod 兼容宏：补丁作用于所选解释器的通用静态调用，保留原有错误报告，并在该捕获路径和额外异常路径恢复之前的上下文；注册表不再直接访问解释器私有状态。低内存检查直接调用实际 HScript 桥接，验证脚本错误、宿主函数错误、原有外层上下文与后续脚本调用，并与匿名对象安全宏和历史路径宏组合通过（_build/origin-real-registry-real-guard-lowmem-329/macro-interaction-332.log）。测试依赖部分工程替身；完整宏配置因隔离工程缺少其他运行时类型未能测试，尚未验证原生构建，额外异常分支尚无独立运行覆盖。

扩展解释器宏组合检查：使用真实 LegacyFunctionArguments，并由隔离替身把故障脚本识别为旧模组，断言旧参数处理分支确实执行；旧参数范围、历史路径、匿名对象安全和静态上下文恢复四个宏同时启用时，真实 Polymod/HScript 用例通过（_build/origin-real-registry-real-guard-lowmem-329/legacy-macro-interaction-335.log）。LegacyRuntime 策略和部分工程依赖为替身，仍不等于完整工程宏组合或原生构建。再次读取 Origin 的 preview/public-playtest 分支，仍指向 d3fdf329faa7419dbf91afd7b3204f36e010daa2。

历史键盘脚本 API：对照 v0.3.2 确认 KeyboardInputScriptEvent 的 event 字段后来改名为 keyEvent；现有兼容别名经实际 Polymod/HScript、实际 OpenFL KeyboardEvent 和旧参数执行路径检查，能读取同一事件的 keyCode（_build/origin-real-registry-real-guard-lowmem-329/keyboard-api-336.log）。事件类从生产源码提取，其父类和旧版本识别策略为替身，未验证真实系统键盘分发。正式基础回归新增事件对象身份断言，尚未完整编译或运行。

NF PlayState 手机自动暂停复核：提取当前 onFocusLost、onFocus 和 update 的移动端分支，用低内存替身测试失焦仅排队、恢复后的下一次更新打开一次暂停界面、关闭设置、尚未开始、恢复时禁止暂停及脚本取消；均通过（_build/nf-mobile-focus-lowmem-337/results.log）。这些是状态逻辑测试，没有 Android 小窗、系统生命周期、真实音视频或实际设备验收，不能据此宣称手机问题已实测修复。NF 长按断连已有源码处理和隔离测试；fixLNL 当前为 INT，加载旧 Bool 会转换为整数，仍需真实游戏与设备验证。

NF 长按断连：重新运行 tools/test-nf-gameplay-unit.ps1，共 19 项通过（_build/nf-gameplay-regressions/recheck-338.log）。其中检查有效迟判窗口内可接回、过期后整条长按链断开、再次按下和回放输入不得接回、对手模式、关闭设置后的接回、漏掉长按头；使用提取自当前 PlayState 的实际方法及替身对象，尚非可见游戏窗口或移动设备验收。

Eradication 箭头补充证据：发布页同一旧包明确声称支持 0.5.0–0.5.3，而官方 0.5.0 和 0.5.1 都接受 1.1.x 样式，前者把箭头按目标宽度缩放，后者直接使用样式比例。故 1.1.1 不能排除 0.5.0，也不能唯一还原该包的目标视觉；当前根据 patch 版本选择比例缩放只是有歧义的默认策略。发布页的 Stage 图片没有 HUD 或箭头，不能作为箭头对照；图片副本 SHA-256 f5ac92f1c595df454cd9db268eb07fed7bde3abe202f636e5bf663770b461c97。用户反馈的实际尺寸问题仍未确认修复。

Eradication 特殊音符补充：真实 0.5.x 包的 normal 谱面有 1214 个音符，其中 104 个标记为 hominid。模组自带 HominidAttackNotes.onNoteIncoming 会为这些音符更换 NOTE_hominid 图集并设置 0.9 缩放；该脚本在三个包中的 SHA-256 相同（e75038c8d9cb3024f247dcc1f87053d8dd24acd700e3c443fa0c9b901b39ce1f）。现有 v23 日志只证实模块加载，普通样式比较不能证明特殊音符实际缩放正确；当前和官方 v0.5.1 都在构造并定位音符后分发 incoming 事件，但脚本执行、复用对象和最终画面尚需验证。

Eradication 特殊攻击音符脚本已用未修改的真实 GameBanana hominidAttack.hxc 和实际 Polymod/HScript 在隔离工程运行，覆盖四个方向、上/下滚、对应偏移、0.9 缩放、图集名称以及普通音符不受影响（_build/origin-hominid-script-lowmem-339/directions-340.log）。测试 Module、Note、Paths、Preferences 和旧版原生写入策略为替身，故不证明实际游戏的事件分发、真实图集、像素尺寸、对象复用或画面正确。首次不启用旧版字段写入桥接的夹具在 frames 写入处失败，不能据此认定正式工程失败。

进一步缩小 Eradication 脚本检查的替身范围：在隔离工程中替换简化的字段写入桥接，使用从正式 LegacyRuntime 提取的完整 setNativeField 方法；实际模组脚本仍通过四方向、上下滚及普通音符检查（_build/origin-hominid-native-writes-lowmem-341/private-getter.log），并用非公开的 Preferences getter 替身覆盖其调用。旧模组归属判定、动画回调、Module、音符和图集加载仍为替身，解释器结果不能证明 hxcpp、真实事件或可见尺寸。

可见 Eradication 短测（构建 273）进入歌曲并显示普通箭头和特殊攻击音符；截图观察到约 450 FPS，进程内存约 1.0 GiB、系统可用内存约 4.6 GiB，因此及时关闭，之后回升至约 5.4 GiB。用户三份存档和 chain.json 前后哈希一致（测试使用隔离存储）；该旧构建不能验证后续源码改动，也没有独立视觉基准证明箭头尺寸。为后续测试加入仅在 FEATURE_DEBUG_FUNCTIONS、--origin-test=... 和 --origin-test-low-load 同时存在时生效的 60 FPS 临时读取覆盖，不写入存档；提取正式读取函数的 Neko 检查覆盖双标志及缺任一标志，偏好值不变（_build/origin-test-fps-lowmem-343）。新选项尚未经完整原生构建和实际窗口验证，旧构建不支持它。

使用项目选定的真实 HaxeFlixel/OpenFL，以实际模组 XML 和相同尺寸的透明位图进行低内存几何检查：普通 purple 帧 sourceSize 为 155×155，0.7 缩放后 hitbox 为 108.5×108.5；特殊 noteLeft 帧为 184×187，0.9 缩放且显式 updateHitbox 后为 165.6×168.3。模组脚本没有显式 updateHitbox，在该独立顺序中显示的 hitbox 为 187×184（_build/origin-real-flixel-notes-lowmem-344/results.log）。这反映帧和碰撞框计算，位图为透明替身且不代表实际绘制像素、原版预期或完整游戏事件；仍需真实画面比较。

Origin 0.5.0 音符宽度精度修正：该版 NoteStyle 将 104×scale 的浮点值直接传给 setGraphicSize，固定依赖的 Flixel f2b090d6c608471e730b051c8ee22b8b378964b1 也接受浮点宽度；旧兼容路径提前 Std.int 会把 72.8 截为 72。现仅移除音符路径的取整；该版本接收箭头上游确实使用 Std.int，保持原样。基于正式缩放分支、实际 Flixel 和模组 XML 的低内存检查验证 0.5.0 的 72.8、早期的 104 以及现代的 108.5（_build/origin-note-width-precision-lowmem-346/results.log）。本修正作用于识别为 0.5.0 原始缩放模式的样式；不能证明当前 Eradication 1.1.1 默认选择的模式或用户反馈的视觉问题已解决，原生构建尚未验证。

已将 0.5.0 普通音符浮点宽度的真实 NoteSprite 断言加入正式历史样式回归：临时设置 0.7 后应得到 72.8，完成后恢复夹具原值；该正式回归尚未编译运行。再次对照 v0.3.2 官方 NoteSprite 和 StrumlineNote，前者使用固定 104 宽，后者对 104×配置比例取整；0.5.0 普通音符保留小数，三个规则与当前分支相符。实际 Flixel 的隔离验证见 origin-note-width-precision-lowmem-346/results.log。

0.9 音符副本隔离待修：SongNoteData.clone 当前复用 params 数组，编辑副本参数会影响原音符；但编辑器 MoveNotesCommand 先克隆并依赖 SongDataUtils.subtractNotes 的 == 匹配，而 SongNoteData 的 == 当前按 params 数组身份比较。单独将 clone 改为复制数组会使移动/撤销无法匹配原音符，因此已撤回该局部尝试。需要一并设计参数值比较、重复音符和撤销语义，并在完整编辑器验证前保持未解决。该问题在已核对的 0.9 预览上游同样存在。

完整源码类型检查资源限制尝试：使用当前 release.hxml、--no-output 和无原生编译，Windows Job Object 为 Haxe 进程设置 2.5 GiB 内存上限，并在系统可用内存低于 3 GiB 时终止。首次运行达到 48 秒自行设置的时间限制；第二次在编译器约 2.37 GiB 后触发系统可用内存保护并终止（_build/origin-guarded-typecheck-347.log、-348.log），退出后可用内存回升至约 6.05 GiB。两次均未完成、不能视为类型检查或构建通过；旧生成配置也需要新构建再次核实。未启动游戏或原生编译。

0.9 歌曲事件类型补全：SongEventDataRaw 已提供 getFloatArray/getStringArray，但 SongEventData 抽象类型的 @:forward 漏掉两者，直接以 SongEventData 类型调用会编译失败；现补齐转发，正式兼容回归改为通过抽象类型检查两个方法。提取实际转发声明与两个读取方法的低内存类型检查在修改前复现缺字段错误、修改后通过（_build/origin-event-array-forward-lowmem-349/baseline.log、results.log）；底层事件字段读取使用替身，正式全工程测试尚未运行。0.9 预览上游也有相同转发遗漏。

歌曲事件数组接口进一步验证：隔离工程使用未裁剪的正式 SongEventDataRaw 和 SongEventData 类型、实际 json2object/hxjsonast，从谱面格式 JSON 解析字符串与浮点数组后，通过抽象类型读取、处理缺失值并修改字段，检查通过（_build/origin-event-actual-data-lowmem-350/parsed-json-351.log）。事件注册表、时间轴和解析辅助类为隔离替身；不能代替完整游戏或原生构建。

谱面音符匹配修正：此前 SongNoteData 的 == 并未比较两个非空 kind 的具体名称，且 != 的空值分支与 == 不互补；编辑器 subtractNotes 可能把时间、轨道、长度和参数数组相同的不同类型音符一起移除。现比较规范化后的 kind，并让 != 取 == 的相反值，保留原来的参数数组身份规则。使用未裁剪的正式 SongNoteDataRaw、SongNoteData、NoteParamData 及正式 subtractNotes 提取方法，在解释器和 Neko 验证不同类型、同类克隆、空值、不同参数数组和编辑器扣除（_build/origin-note-equality-lowmem-352/before.log、after.log、neko.log）。其他时间轴和 NoteKind 依赖为替身；正式完整工程及编辑器 UI 未验证。该修复不解决前述 clone 共用参数数组的问题。

真实模组音符复用修正：Alien Hominid 脚本在下滚时将特殊音符 flipY 设为 true；NoteSprite 被池复用时此前没有恢复 flipX/flipY，也没有清除 lowPriority，后续普通音符可能继承上一个脚本音符的状态。现 revive 恢复这三个默认值，之后的 incoming 脚本仍可重新设置。未裁剪的正式 NoteSprite 配合真实 Flixel 的复用检查在旧逻辑失败、新逻辑通过（_build/origin-recycled-note-baseline-353/results.log、_build/origin-recycled-note-lowmem-353/results.log）；进一步用未修改的真实模组脚本、正式 NoteSprite、真实 Polymod/HScript、Flixel 与模组 XML 跑特殊→普通→特殊的下滚序列，通过（_build/origin-hominid-recycle-lowmem-354/results.log）。像素位图、模块宿主、音符数据与部分资源/策略为替身；正式回归新增复用断言但尚未构建，真实游戏窗口、所有模组及尺寸视觉仍未验证。

目标执行约束（2026-11-01）：优先保护电脑性能，避免资源过载和系统卡死。编译、测试及其他耗资源任务控制并发并监测可用内存；资源紧张时及时停止，避免重试高负载完整构建，改用低内存检查并如实记录未完成的验证。保留用户已有代码与数据。

复用补充验证：使用真实模组脚本、正式 NoteSprite、正式 NoteStyle.buildNoteSprite 方法及 Flixel 图集，检查特殊音符→普通音符→特殊音符时普通音符图集、缩放、动画和翻转恢复，隔离测试通过（_build/origin-hominid-style-recycle-lowmem-355/results.log）。位图像素及部分宿主、资源和样式辅助方法为替身；不代表完整游戏构建或箭头视觉尺寸验收通过。

旧舞台偏移编辑子界面鼠标：进入时此前只设置 Flixel 可见性，可能沿用 NF 或前一状态的鼠标图案；现通过 Origin Cursor.show 加载编辑器默认图案，退出用 Cursor.hide 清理，并仅在鼠标被隐藏时恢复，避免每帧覆盖 HaxeUI 指针。两个工作目录分别应用；基于源码检查，Cursor 自身此前的隔离测试见 _build/origin-cursor-real-source-lowmem-326/results.log。该旧子界面及完整构建尚未运行验收，不代表所有编辑界面均已验证。

旧 StageBuilder 入口鼠标：创建界面时改为 Cursor.show，主动加载 Origin 编辑器默认图案，原有的 select/grab/grabbing 工具图案切换代码保留。已静态检查两个工作目录；该旧界面工具切换与全局 HaxeUI 鼠标监听之间的运行行为、完整构建和实际窗口仍需验证。

历史角色公开接口候选复核：自动差异索引把 AnimateAtlasCharacter 的 playAnimation、hasAnimation、getCurrentAnimation、isAnimationFinished、resetCharacter 列为缺失，但当前 AnimateAtlasCharacter 继承 BaseCharacter，后者继承 FunkinSprite；这些方法分别由 BaseCharacter 或 FunkinSprite 提供。对照索引中的旧声明，参数和返回类型在本次静态检查范围内一致；因此不能仅根据子类未重复声明判为缺失。渲染、动画帧和脚本动态分发的实际行为仍需运行验证，其他候选不受此结论覆盖。

对话框图集资源查询修正：DialogueBox.loadSpritesheet 无论动画列表是否为空，都通过 Paths.getSparrowAtlas 读取图集；原 DialogueBoxRegistry 仅在有动画时返回 XML，导致静态对话框的预加载清单遗漏 XML。现对有效图集路径无条件返回 XML。提取正式查询方法的低内存隔离检查覆盖空动画、非空动画、图片、缺失 ID 和不支持的类型，见 _build/origin-dialogue-assets-lowmem-356/results.log；资源路径和注册表宿主为替身，未验证完整构建或真实对话框运行。

0.5.0 判定线缩放的源码交叉核对：官方 v0.5.0 的 StrumlineNote.setup 在载入帧和动画后、播放 static 前，以 Std.int(STRUMLINE_SIZE * getStrumlineScale()) 调用 setGraphicSize；当前所选 Flixel 的 setGraphicSize 将目标宽度除以 frameWidth 并令 X/Y 缩放一致。当前兼容实现按相同阶段的 frameWidth 做此换算，静态公式一致；该核对不覆盖运行时图集差异、设备缩放或用户观察到的 Eradication 箭头视觉问题。

真实模组脚本导入批查与更正：隔离目录中排除诊断/测试覆盖层后共 68 个 HScript 文件、35 个不同 funkin 导入，路径词法筛查结果见 _build/origin-scripted-wrapper-audit-357/imports.json；文件名缺失不能证明接口不可用。此前直接反射 FlxRuntimeShader 的检查未加载 Polymod 的全局构建宏，得出包装初始化缺失的结论不成立。加入实际 Polymod extraParams 宏后，FlxRuntimeShader 获得 scriptInit 和 _isHScriptedClass；再使用真实 Polymod、真实 Flixel、项目的解释器空值保护宏，以及旧导入别名和 HScript 样本，成功以 ScriptedFlxRuntimeShader.init 创建脚本着色器并用 scriptCall 调用其方法（_build/origin-scripted-wrapper-audit-357/hscript-init-guarded.log）。此前未配置宏的失败检查不能代表正式构建。Pico Chill 的 BuildingEffectShader 在其包内未找到；Alien Hominid 包包含 HominidShader 并有同样的旧式初始化调用。这次检查未运行真实模组着色器、GPU 绘制或完整原生构建，其他包装类仍需核实。

Alien Hominid 原始着色器脚本补充检查：使用 0.6.0 包未修改的 hominidShader.hxc 与 glitchChromatic.frag，真实 Polymod、Flixel、旧导入别名及项目解释器空值保护宏，在低内存解释器夹具中通过旧式 init 构造并以 scriptCall 调用 setiTime，读取脚本字段确认更新为 1.25（_build/origin-hominid-shader-lowmem-358/final.log）。Paths 与资源库是替身；首次失败因夹具未保留 Paths 类型，补齐后通过。未创建 GPU 窗口，不证明着色器视觉效果、真实舞台条件或 hxcpp 构建通过。

判定线资源库修正：NoteStyle 原先从 noteStrumline.assetPath 取出去库名的路径后，以默认库加载 Sparrow 图集，显式 library:path 因而可能取错资源；IMAGE/XML 查询也遗漏库名。现加载和查询都将原始路径的库名传给 Paths.file，默认路径保持原规则。提取正式加载、查询及路径方法的低内存夹具覆盖指定库、默认库和 fallback（_build/origin-strumline-library-lowmem-359/preload.log）；Paths、资源库和音符对象为替身，真实资产库和完整游戏未验证。其他音符样式资源的带库名查询仍需分别核实；这不证明 Eradication 的视觉尺寸问题已解决。

音符样式其余图集的资源库修正：普通音符、溅射和四方向长按特效实际加载时会使用原始 library:path 中的库名，IMAGE/XML 查询和图形缓存提示此前却丢失库名。现查询和缓存检查与对应加载路径使用相同库名；隔离夹具使用正式查询方法检查 note、splash、cover、strumline，覆盖指定库、默认库和判定线 fallback（_build/origin-strumline-library-lowmem-359/all-atlases-final.log）。资源构造、资源库和部分样式方法为替身，未验证真实资源库或原生完整游戏；倒计时等其他资源的库名行为仍待核对。

倒计时、判定与连击数字资源库：这些样式字段此前会拆去 library:path 的库名，实际加载和 IMAGE 预加载均可能指向默认库。FunkinSprite.loadTexture 增加可选库参数；三类样式加载及查询传入各自库名，判定与数字路径方法新增可选 raw 参数，原有无参/单参返回值保持不变，fallback 继承原始路径。提取正式样式方法的低内存检查覆盖指定库、默认库、路径公开接口与 fallback（_build/origin-style-static-library-lowmem-360/results.log），正式资源查询提取检查覆盖三类预加载（_build/origin-strumline-library-lowmem-359/countdown-query.log）；Sprite、资源路径和部分样式数据使用替身。真实资源库、倒计时/判定画面及完整构建仍未验证。

资源库路径交叉验证：提取正式 funkin.assets.Paths 的 build/file/image 和兼容路径解析器的 getPath，检查 Paths.image('foo') 与新增 Paths.file('foo','png',true,null) 均解析为 assets/foo.png，指定 week7 库解析为 assets/week7/foo.png（_build/origin-actual-paths-lowmem-361/results.log）。AssetPath 和资源存在性检查为替身，未覆盖真实资源别名、资源优先级、文件系统或完整构建；用于确认默认参数与指定库的路径组合，不作为实际图像加载证据。

2026-11-01 再次只读查询官方 FunkinCrew/Funkin 远端：main 为 86cb949c74743b2bdbb58a66326acdb47a36f43a，与本次审查固定样本一致；远端 v0.9* 标签查询无结果。此结果只反映查询时 main 和标签，不代表全部分支或未来发布状态；没有 fetch、合并或改动用户工作区。

FunkinSprite.loadTexture 向后兼容补充检查：在前述实际路径解析方法的隔离夹具中加入正式 loadTexture 方法，核对单参数调用仍加载 assets/foo.png 并返回原对象，新增库参数加载 assets/week7/foo.png 并返回原对象（_build/origin-actual-paths-lowmem-361/loadtexture.log）。Flixel 精灵、图形缓存和资源存在性仍是替身；HScript 动态调用、实际图片加载及完整构建未覆盖。

loadTexture 脚本调用补充：使用正式 loadTexture 方法、正式路径解析方法、真实 Polymod 和 HScript，旧单参数调用与新增库参数调用均得到预期路径（_build/origin-loadtexture-hscript-lowmem-362/final.log）。首次夹具因 OpenFL 资源库未登记测试图片，原生和脚本调用都在存在性检查处返回；最终检查将资源存在性和图形缓存替换为测试对象，Sprite 宿主亦为替身。因此验证的是 HScript 参数分发和路径计算，不能证明真实图像加载或完整原生构建。

0.9 谱面参数与撤销补充审查：MoveNotesCommand 构造时克隆每个音符，但 SongNoteData.clone 仍共享 params；MoveItemsCommand 仅克隆数组，既共享音符对象也共享参数。两者 execute/undo 均依赖 subtractNotes 的现有匹配语义；同时鼠标放置和实时输入会通过 cloneNoteParams 为新谱面音符复制参数，网格预览与待放置参数共享引用本身不能证明已保存谱面损坏。修复需要同时覆盖这两条命令、历史快照、重复音符和撤销重做，不能单独改 clone 或仅凭预览引用推断问题已修复；完整编辑器行为仍未验证。

角色渲染类型构造兼容：现有原生 Sparrow/Packer/Animate 等子类仍向 BaseCharacter 传旧版 renderType 字符串，而 BaseCharacter 只读取 params.renderType，导致字符串参数被忽略、类型不符未按历史规则报错。现构造器兼容字符串、参数对象及省略参数，并统一使用解析出的渲染类型校验和赋值。提取正式构造函数的低内存检查覆盖旧字符串、新参数对象、默认、类型不匹配和缺数据（_build/origin-character-constructor-lowmem-363/results.log）；角色注册表、父类和舞台为替身，真实角色渲染和完整构建尚未验证。

角色渲染类型回归补充：扫描隔离的真实模组中继承五种内置角色渲染器、构造器直接写出角色 ID、且能定位随包 JSON 的 13 个脚本，声明渲染器与其数据一致，未发现不匹配（_build/origin-character-constructor-lowmem-363/mod-render-audit.json）；这只是静态样本，重复版本分别计数。现有 CompatibilityChecks 的构造器回归入口增加原生旧字符串成功和类型不匹配失败检查；该正式检查尚未构建运行。实际角色注册、用户自有模组、全量资源和 GPU 渲染仍需验证。

旧 HealthIcon 无参构造：官方 v0.3.2–v0.5.0 的 HealthIcon() 默认选择 bf，而 v0.5.1 起首参数必需。现历史构造参数桥仅对声明 API >=0.1.0 且 <0.5.1 的脚本、无参数调用补充 bf；现代、未知来源及显式参数保持不变。提取正式参数转换方法的低内存检查覆盖旧、新、未知和显式参数（_build/origin-healthicon-constructor-lowmem-364/results.log）；结合实际 Polymod/HScript 与正式宏验证了旧无参调用（hscript.log）。版本归属判断和 HealthIcon 图形对象在夹具中为替身，未验证实际图标渲染、所有模组或完整原生构建；最低 API 可能低于实际目标版本，因此此补偿只处理原本不能无参调用的情况。

旧 PopUpStuff 构造兼容：官方 0.3.2/0.4.1 允许无参数构造并公开 offsets；当前组件原本要求 NoteStyle 且 offsets 私有。现允许省略样式，优先采用当前 PlayState 样式，尚未初始化时使用默认样式，并恢复 offsets 的公开访问；显式样式优先。提取正式构造函数的低内存检查覆盖旧无参、公开偏移、当前 pixel、显式 custom 和无活动样式回退（_build/origin-popup-constructor-lowmem-365/results.log）；PlayState、NoteStyle 和精灵组为替身，画面及完整工程未验证。旧版 displayCombo 返回输入的整数、现代版本返回 Void，这一单独差异仍未适配，不代表整个旧组件 API 均兼容。

旧 PopUpStuff.displayCombo 返回值补偿：官方 0.3.2/0.4.1 返回输入的 combo，0.5.0 起返回 Void。现对声明 API >=0.1.0 且 <0.5.0 的脚本，在现有原生调用桥中保留原有绘制副作用并返回旧值；无参数或 null 返回 0。直接调用及保存方法引用均处理，后者继续执行实例字段黑名单检查；较新脚本维持当前原生返回行为。提取正式桥接方法，配合实际 Polymod/HScript 与项目宏，验证旧版直接/保存/无参调用和新版与未适配原生调用一致（_build/origin-popup-result-lowmem-366/final.log）。版本归属、PopUpStuff 宿主及渲染为替身；未验证 GPU 画面、正式完整构建或所有脚本，补充本文件上一条未适配说明。

旧连击返回值的归属与访问边界补充：使用未改动的 Devil’s Swing API 0.1.0 和 Beepie API 0.8.0 元数据及各一份脚本，复制到隔离模组目录，通过实际 Polymod 文件系统和正式 apiVersionForOrigin/hasApiVersion 方法检查，只有旧样本获得旧返回值，较新及未知来源保持原返回值（_build/origin-popup-version-lowmem-367/with-icons.log）。另用实际 Polymod/HScript 在获取保存方法后加入实例字段黑名单，调用被阻止且组件未执行（_build/origin-popup-result-lowmem-366/blacklist.log）。两项使用替身组件，未验证完整原生游戏；隔离目录仅含复制的元数据、图标和脚本，不改原模组。

旧 Bopper 无参默认节拍：官方 v0.3.2/v0.4.1 的 Bopper() 默认 danceEvery=1，v0.5.0 起为 0；现仅对声明 API >=0.1.0 且 <0.5.0 的脚本无参数原生构造传入 1，显式 0 与新版默认不变。提取正式构造参数桥并结合真实 Polymod/HScript 和项目宏，验证旧脚本直接 new、脚本子类 super()、显式零及新版默认（_build/origin-bopper-constructor-lowmem-368/results.log）；Bopper 本体与版本归属判断为替身，实际舞台动画、模组及完整原生构建尚未验证。API 声明为最低版本，可能不能准确识别作者实际目标。

Bopper 版本归属联测：使用复制到隔离目录的 Devil’s Swing API 0.1.0、Beepie API 0.8.0 原始元数据和对应脚本路径，配合实际 Polymod 文件系统、正式版本归属方法、正式构造参数桥及真实 HScript，验证旧来源无参得到 1，较新及未知来源得到 0（_build/origin-bopper-actual-origin-lowmem-369/results.log）。测试脚本内容及 Bopper 宿主为替身；未直接证明真实模组舞台播放或原生构建。

Bopper 节拍回调差异待验证：官方 v0.3.2 在 onBeatHit 中执行 dance，当前实现在 onStepHit 中按 danceEvery×STEPS_PER_BEAT 执行，onBeatHit 本身为空。旧脚本若覆盖 Bopper.onBeatHit 并选择不调用 super，或在 super 前修改跳舞状态，可能与当前先按 step 执行的行为不同；现有已下载模组的 onBeatHit 命中项主要是 Stage 脚本，不能据此证明 Bopper 子类触发该问题。尚需用真实事件顺序和旧/新 HScript 子类进行验证，再决定如何按脚本来源隔离，避免双重跳舞或改变现代脚本。

旧 Bopper 节拍覆盖兼容：Conductor 在同一拍先分发 step 后分发 beat；隔离复现旧脚本覆盖 onBeatHit 且不调用 super 时，现代步进逻辑仍提前跳舞（_build/origin-bopper-beat-repro-lowmem-370/results.log）。现仅当实际 onBeatHit 脚本覆盖来自 API >=0.1.0 且 <0.5.0 时，将该对象的自动跳舞从 step 路径移到原生 beat 父方法：旧覆盖不调用 super 可阻止跳舞，调用 super 跳一次；新版和原生对象保留 step 行为。真实 Polymod/HScript、项目版本归属方法及隔离复制的真实旧/新版元数据联测了旧不调用 super、调用 super、修改节拍后调用、新版覆盖和原生对象（_build/origin-bopper-beat-actual-origin-lowmem-371/results.log）。Bopper 宿主和事件为替身，按已核对 Conductor 顺序手动分发；真实舞台、复杂跨版本继承、hxcpp 反射与完整构建仍未验证。无 beat 覆盖的旧脚本仍使用现代 step 路径，未宣称完全复刻旧事件次序。

Bopper 节拍继承补充：使用真实 Polymod/HScript、正式来源判定及隔离复制的旧/新版模组元数据，验证旧脚本父类定义的 onBeatHit 被旧子类或新版子类继承时，按该方法声明来源应用旧规则（_build/origin-bopper-beat-actual-origin-lowmem-371/inheritance.log）。Bopper 和事件为替身，未覆盖新版子类重新覆盖并调用旧父方法、原生 hxcpp 反射、真实舞台或完整构建。

Bopper 节奏边界补测：在前述真实 Polymod 与模组版本归属隔离夹具中，对旧/新带 super 覆盖分别检查 danceEvery=2 时奇数拍不跳、两拍之间不重复、偶数拍跳一次；对新版检查 danceEvery=0.5 时半拍和整拍各跳一次（_build/origin-bopper-beat-actual-origin-lowmem-371/intervals.log）。手动按当前 Conductor 的 step→beat 顺序派发，Bopper 与事件为替身；不代替实际游戏或复杂跨版本覆盖验证。

Bopper 本体进一步验证：隔离夹具直接编译未裁剪的正式 Bopper.hx，使用实际 Flixel、Polymod/HScript、正式旧节拍来源判断和真实旧/新模组元数据，复核直接覆盖、继承、super、不调用 super、两拍间隔及新版半拍（_build/origin-bopper-real-source-lowmem-372/results.log）。StageProp、事件和舞台环境为替身，测试子类仅计数 dance，不绘制动画；未验证 hxcpp/真实游戏窗口或完整构建。

Bopper 实际动画选择补测：使用未裁剪正式 Bopper、真实 Flixel 动画控制器和 Polymod/HScript，在旧覆盖不调用 super、旧覆盖调用 super、新版覆盖不调用 super 三种情况下检查 idle 动画是否实际被选择（_build/origin-bopper-real-source-lowmem-372/animation.log）。图集是 1×1 透明夹具，StageProp、事件及版本样本脚本为替身；仅验证动画控制器选择，不验证 GPU 画面、真实舞台或完整原生构建。

旧 Bopper 仅覆盖 onStepHit 的边界：官方旧版在 onBeatHit 自动跳舞，旧脚本只覆盖 onStepHit、即使不调用其空的父方法，也不应阻止节拍跳舞；现代版本依赖 onStepHit，因此规则不同。现旧节拍来源检测在未找到脚本 onBeatHit 时继续检查 onStepHit 的声明来源，按旧节拍路径执行。使用未裁剪正式 Bopper、真实 Flixel/Polymod 和真实旧/新模组元数据，隔离验证旧/新 step-only 覆盖有无 super，并重跑此前 beat/继承/动画选择检查（_build/origin-bopper-real-source-lowmem-372/step-override.log）。事件、StageProp 和脚本内容为替身；无回调覆盖的旧脚本、复杂跨版本双覆盖、真实舞台和原生构建仍需验证。

PopUpStuff 本体补充检查：隔离夹具直接编译未裁剪的正式 PopUpStuff，结合真实 Flixel/Polymod/HScript，检查旧脚本无参构造、写入 offsets、连击直接与保存方法返回值、新版基线以及当前样式/默认样式回退（_build/origin-popup-real-source-lowmem-373/constructor.log）。NoteStyle、PlayState、资源和图形精灵为替身，样式返回空精灵以避免创建窗口；因此不验证实际数字、像素画面或完整原生构建。

旧音符类型加载入口：官方 0.5.0–0.7.5 暴露 NoteKindManager.loadScripts()，作用是注册脚本音符类型而非清空全部类型；现恢复该入口并委托现有 registerScriptedNoteKinds。当前编辑器从管理器动态读取列表。提取正式两个方法并结合真实 Polymod/HScript 的隔离检查确认旧脚本可调用、注册新类型且保留原有类型（_build/origin-notekind-loadscripts-lowmem-374/results.log）；NoteKind 实例与列表为替身，宏对测试替身的重复静态字段有警告，真实模组注册和完整构建仍未验证。

无节拍回调覆盖的旧 Bopper：当脚本既未覆盖 onBeatHit 也未覆盖 onStepHit、但定义了构造器时，现以构造器声明来源判断旧版节拍时序；旧对象在 beat 跳舞，现代对象仍在 step 跳舞。未裁剪正式 Bopper、Flixel/Polymod 及旧/新模组元数据的隔离测试验证了两者的先后顺序，并重跑回调覆盖、继承和动画检查（_build/origin-bopper-real-source-lowmem-372/no-callback.log）。脚本、事件和 StageProp 为替身；没有可识别构造器来源、跨版本复杂覆盖、实际舞台及原生构建仍未覆盖。

无显式构造器的旧 Bopper：利用现有脚本类声明注册记录来源，使没有回调覆盖和构造器的旧脚本也按旧版 beat 时序跳舞，新版仍按 step；脚本缓存清理同时清除声明来源。隔离检查使用未裁剪正式 Bopper、真实 Flixel/Polymod 和复制的旧/新模组元数据，验证无显式构造器、新旧回调、动画选择及清理后重新加载（_build/origin-bopper-real-source-lowmem-372/reload.log）。脚本内容、StageProp、事件和透明测试图集为替身；复杂跨版本覆盖、真实舞台、hxcpp 与完整构建仍未验证。

旧 Bopper 隐式构造补充：直接继承 Bopper 且不声明构造器的旧脚本，创建原生父类时解释器没有当前表达式来源，之前的旧默认频率补偿因此失效（_build/origin-bopper-real-source-lowmem-372/direct-implicit-constructors.log）。现构造器兼容宏在表达式来源为空时回退脚本类声明来源。使用真实 Polymod/HScript、正式构造器宏及未裁剪 Bopper 的隔离检查验证旧默认 1、新默认 0、显式参数 2 和之前的节拍/重载检查（_build/origin-bopper-real-source-lowmem-372/direct-implicit-fixed.log）。事件、舞台与测试脚本为替身，未验证真实游戏或完整 hxcpp 构建。

旧舞台编辑器鼠标接管补充：StageBuilderState 与 StageOffsetSubState 进入时现在抑制 NF 鼠标特效，销毁时释放抑制并隐藏编辑器鼠标；计数式接管允许其他编辑器嵌套时保持抑制。源码检查及 diff 格式检查通过，旧舞台界面、关闭路径和原生构建尚未实际运行验证。

Eradication 判定线位置复核：该包 AlienBFCharacter.onCreate 将 STRUMLINE_X_OFFSET 设置为 96，并根据上下滚设置 Y 为 24 或 52；当前 PlayState 先 initCharacters，CharacterRegistry.fetchCharacter 在返回前派发 CREATE，然后才 initStrumlines 并读取这些常量计算位置。已有原生旧脚本检查覆盖 Constants 写入和恢复，但上述实际角色运行时的具体坐标尚未记录，因此此处仅确认源码时序；位置调整不是箭头图像尺寸的独立基准，不证明用户反馈已解决。查询部分历史 Git 对象时触发自动整理，已停止本次查询派生的 Git 进程；未运行完整构建或修改模组资源。

Eradication 特殊音符定位时序复核：从官方 v0.5.1 的 Strumline.hx 获取源码快照（SHA-256 4745ec8a2a0be2c50e4f25dc67b8d2b65e01d564b40d0aecc474c65418cab0ad，来源 https://raw.githubusercontent.com/FunkinCrew/Funkin/v0.5.1/source/funkin/play/notes/Strumline.hx）。官方先按样式构造音符、用已有宽度居中，再派发 incoming；当前相同顺序，并在默认 strumlineScale=1 时按样式比例更新碰撞框后居中。Alien Hominid 之后替换图集和设置 0.9 缩放，因此不能仅依据事件发生在居中之后就认定是本移植引入的尺寸或位置差异。该核对为源码对照；未证实实际绘制、不同依赖版本、其他缩放配置或用户反馈已修复。

0.9 编辑器参数撤销复现：使用从正式 SongData 提取的未裁剪 SongNoteData/参数类型，在解释器中确认 clone 后修改原参数会同时改变快照；相同参数内容但不同数组实例又不满足现有音符相等判定（_build/origin-editor-param-history-lowmem-375/results.log）。因此仅深拷贝会使现有 subtractNotes 无法匹配，必须同时设计对象匹配及重复音符/撤销重做语义；本次没有改动生产逻辑，也没有声称 UI 行为已验收。

NF 长按断连当前源码复核：重新运行 tools/test-nf-gameplay-unit.ps1，19 项通过（_build/nf-gameplay-regressions/recheck-current-376.log），包括迟判窗口、断连后再次按键和回放、关闭设置、对手模式与遗漏长按头。脚本提取 PlayState 当前方法并使用替身，未覆盖真实输入或手机设备；手机小窗暂停的真实生命周期仍未实测。

编辑器参数快照修复范围复核：subtractNotes 同时用于添加、删除、选择、反选、剪切、粘贴、翻转、镜像、移动和移除重叠音符；不能直接全局改成忽略参数引用的值匹配，否则会改变其他命令及重复音符行为。MoveNotesCommand 在构造时克隆音符对象，MoveItemsCommand 只复制数组，两者执行和撤销都把自身数组直接加入当前谱面与选区。后续修复需分别持有不可变历史快照与当前谱面对象，测试两类命令的重复音符、参数修改及多次 execute/undo/redo；本次只完成依赖审查。

0.9 编辑器移动音符参数快照修复：MoveNotesCommand 与 MoveItemsCommand 记录独立参数对象快照，执行和重做从快照生成移动后的音符；撤销时恢复原音符对象，使更早的命令仍能匹配。移动专用删除优先按对象身份逐项移除，避免移除共享参数数组的其他重叠音符；全局 subtractNotes 未变。提取实际两种命令、正式音符数据类型，配合替身状态和辅助类型，在 Haxe 解释器与 Neko 验证两种命令、重叠音符、修改参数后撤销、早期匹配和多次撤销重做（_build/origin-editor-move-lowmem-377/history.log、neko.log）。NoteParamData.clone 对 value 是浅复制，嵌套数组/对象尚未独立；事件快照、真实编辑器 UI、完整原生构建仍未验证。

编辑器移动快照与连续历史补充：谱面参数按 JSON 数据处理，移动快照递归复制数组及匿名对象。进一步发现连续两次移动、依次撤销后重做时，新建第一步音符会导致第二步持有的原对象失效（_build/origin-editor-move-lowmem-377/real-redo-before.log）；现重做复用首轮移动音符对象并恢复快照字段。实际命令源码及正式音符类型的隔离检查在解释器和 Neko 通过嵌套参数、重叠音符、两个不同移动命令连续撤销并使用同一命令实例重做（real-redo-after.log、real-redo-neko.log）；状态、事件与部分工具为替身，非 JSON 类对象仍保持原引用，实际编辑器和原生构建未验证。

0.9 谱面事件移动快照补充：混合移动和单独移动事件原本共用嵌套 value 引用，修改后污染撤销内容；现保存 JSON 容器独立快照、逐对象移除，并在重做时复用事件对象以维持连续历史引用。移除了单独移动事件命令重复执行的删除。使用实际三种命令及正式音符/事件类型、替身编辑器状态，在解释器和 Neko 覆盖事件嵌套值、重复事件、连续撤销重做、同一次混合移动音符与事件（_build/origin-editor-move-lowmem-377/mixed-final.log、mixed-final-neko.log）。事件和音符的数据依赖、编辑器状态及资源为替身；真实编辑器、hxcpp 和非 JSON 类对象未验证。

0.9 静态对话框加载：对照预览 d3fdf329，DialogueBox 原来只接受 Sparrow 图集，静态图片缺少 XML 时 getSparrowAtlas 抛错；现加载图集失败或返回空时回退加载同路径图片。DialogueBoxRegistry 的 XML 查询改为仅在 XML 存在时返回，兼顾空动画但实际有 XML 的图集。提取正式方法的低内存替身检查覆盖图集成功、抛错/空返回回退、像素及翻转缩放设置，资源查询检查覆盖静态与动画图集（_build/origin-dialogue-static-lowmem-378/results.log、_build/origin-dialogue-registry-lowmem-378/results.log）。Flixel 精灵、资源存在性及注册表为替身；真实图片、脚本对话、可见画面和完整原生构建尚未验证。再次只读查询上游 main、develop 和 preview/public-playtest，与文档记录相同，未发现 v0.9 标签。

静态对话框 Flixel 补充检查：提取正式 loadSpritesheet，使用项目所选真实 Flixel/OpenFL 精灵、内存 BitmapData 与 8×6 Sparrow 图集，验证图集成功和缺少图集时静态图片加载、帧尺寸及像素抗锯齿设置（_build/origin-dialogue-static-flixel-lowmem-379/results.log）。路径、对话框宿主和图像为替身，未读取实际模组资源或显示窗口，也不代替完整原生构建。

静态对话框开场时序补充：提取正式 DialogueBox 动画状态访问方法及 Conversation 的开场阻塞判断，使用项目真实 Flixel 动画控制器验证静态图在无动画名或指定缺失动画时均不阻塞，非循环开场动画完成前阻塞、完成后放行，循环动画不阻塞（_build/origin-dialogue-static-flixel-lowmem-379/opening.log）。对话状态、图像和资源仍为替身，此检查不覆盖完整对话推进、脚本事件或可见画面。

0.9 对话静态资源查询入口：预览版 DialogueBox.queryAssets 和 Speaker.queryAssets 可供模组脚本直接调用，而此前只有注册表内部默认查询。现恢复两个静态入口，以注册表宏生成的 _fetchData 查询资源，不创建对话对象；对话框 XML 仅在文件存在时返回，说话角色保留图集 XML。使用提取的正式方法、真实 Polymod/HScript 和替身数据/资源路径，验证脚本静态调用、静态图、动画 XML、说话角色及缺失 ID（_build/origin-dialogue-static-api-lowmem-380/results.log）。未使用实际 RegistryMacro 的数据解析，也未验证真实资源索引、脚本静态继承或完整原生构建。

0.9 对话注册表宏衔接与说话角色偏移：使用项目未裁剪 RegistryMacro.buildEntry、IRegistryEntry 和提取的两项静态查询，验证宏生成的 _fetchData 与入口可编译调用及缺失数据回退（_build/origin-dialogue-registry-macro-lowmem-382/results.log）；注册表实现和资源路径为替身。对照预览上游，Speaker.set_globalOffsets 现同时更新 localX/localY，加载及缩放后同步局部坐标，避免 FunkinGroup 下次布局覆盖全局偏移。提取正式 setter 与组位置公式的低内存检查覆盖初始与变化后的偏移（_build/origin-speaker-offset-lowmem-381/results.log）；组和精灵为替身，实际注册表、可见对话和完整构建仍未验证。

对话资源查询脚本覆盖联测：在同一隔离夹具中组合项目实际 RegistryMacro.buildEntry、生成的 _fetchData、正式 DialogueBox/Speaker 静态查询方法与真实 Polymod/HScript；脚本子类声明 queryAssets 并显式调用 DialogueBox.queryAssets，再追加自定义图片，返回基础图片和追加图片（_build/origin-dialogue-static-api-lowmem-380/macro-script.log）。数据解析实现、资源索引和精灵宿主为替身；此测试不涵盖脚本用 super 访问静态方法、完整注册表或原生游戏。

0.9 Conversation 静态资源入口：恢复 Conversation.queryAssets，使用注册表宏的 _fetchData 读取数据，并与 ConversationRegistry 的缓存回退共用资源汇总逻辑，涵盖说话角色、对话框、打字音效及背景音乐。低内存检查覆盖去重、默认/静音/自定义音效、音乐元数据与缺失 ID（_build/origin-conversation-static-api-lowmem-383/results.log）；真实 Polymod/HScript 可调用提取的正式静态入口并取得说话角色与对话框图片（_build/origin-conversation-hscript-lowmem-384/results.log）。数据解析、资源路径及子注册表为替身，实际注册表、原生构建和游戏内对话仍未验证。

0.9 自由选曲静态资源入口：按固定预览版恢复 Album、FreeplayStyle、PlayableCharacter.queryAssets；前两者调用各自注册表的共享默认资源规则，可选角色按上游当前实现返回空列表。真实 Polymod/HScript 联合提取的正式方法测试了专辑图片/可选 XML、样式图片/XML、缺失条目和空角色资源（_build/origin-freeplay-static-api-lowmem-385/results.log）。注册表获取、资源路径及条目键为替身；真实资源索引、脚本覆盖与完整原生构建尚未验证。

0.9 真实模组自由选曲静态查询联测：使用原始 GameBanana 预览 ZIP、实际 Polymod 与 Origin 兼容文件系统、真实 FreeplayStyleData 解析器及 HScript，调用提取的正式 FreeplayStyle.queryAssets 和注册表资源方法，确认返回的 pico 背景图片路径存在于模组索引（_build/origin-freeplay-real-mod-static-lowmem-386/results.log）。注册表获取、路径构造桥和精灵宿主为替身；日志中部分目录缺失提示来自路径探测，最终检查通过；未绘制自由选曲画面或完成原生构建。

0.9 静态查询与旧实例方法冲突复现：真实 Polymod/HScript 对同时拥有旧实例 queryAssets 的原生类调用同名静态方法会报告 Invalid access（_build/origin-static-query-conflict-lowmem-387/before.log）。在隔离替身中通过解释器已授权字段读取后的兼容桥，验证直接调用、保存函数调用和旧实例调用可共存；初版保存的函数会绕过之后新增的静态字段黑名单（prototype-blacklist.log），在闭包调用时重新检查后通过（prototype-guarded.log）。这是机制原型，版本归属、真实 Song/Stage/NoteStyle/BaseCharacter、资源返回、其他黑名单和原生目标尚未覆盖，未接入生产代码。

0.9 同名资源查询兼容桥：对来源 API >=0.9.0 且 <0.10.0 的 HScript，在正常字段权限检查后，为 Song、Stage、NoteStyle、BaseCharacter 类缺失的静态 queryAssets 提供回退；直接调用对应注册表默认查询，避免重复触发脚本覆盖。旧实例方法和未知/旧来源行为保留；保存的函数调用时重新检查字段黑名单。隔离检查结合正式宏、提取的正式桥和版本归属方法、真实 Polymod/HScript 与两份合成 0.8/0.9 元数据，覆盖四类静态查询、保存函数、旧实例、未知来源、读取前及保存后黑名单，脚本预检 0 错误（_build/origin-static-query-conflict-lowmem-387/preheat.log；旧来源和黑名单错误为预期）。四种原生类和注册表为替身；实际资源内容、派生角色静态类、全部黑名单、完整宏组合及 hxcpp 未验证。

0.9 静态歌曲查询与真实旧模组联测：加载 Alien Hominid 旧模组谱面/元数据副本及单独的合成 0.9 脚本，通过真实 Polymod/HScript、提取的正式兼容桥、SongRegistry 查询与旧路径别名文件系统，确认脚本静态查询获得 Eradication 谱面和元数据并排除图集 JSON（_build/origin-static-query-real-song-lowmem-388/results.log）。初次夹具使用预览测试用的旧版文件系统替身，未挂载歌曲别名而返回空；换成先前用于歌曲索引的兼容文件系统后通过。Song 类、资源路径和部分文件系统依赖为替身；没有实际渲染或验证箭头尺寸，也未进行完整原生构建。

0.9 静态舞台查询联测：真实 Polymod/HScript 运行合成 0.9 脚本，经正式兼容桥和提取的 StageRegistry 默认资源方法读取 Alien Hominid 原始 alienAlley 舞台数据，返回实际存在的 Escenarios/Callejon/sky.png（_build/origin-static-query-real-stage-lowmem-389/results.log）。舞台对象、注册表容器和路径解析桥为替身；读取舞台数据和图片存在性使用原模组文件，未加载纹理、渲染舞台或完成原生构建。

0.9 角色静态查询补充：恢复 BaseCharacter.queryBaseAssets，只返回存在的通用血条图标；静态桥增加 Sparrow、Packer、AnimateAtlas、MultiSparrow、MultiAnimateAtlas 五种原生角色类，并将显式渲染类型传给 CharacterRegistry，避免查询子类时误用数据中的另一类型。真实 Polymod/HScript、正式桥和合成版本配置覆盖五类调用、通用入口、旧/未知来源及黑名单（_build/origin-static-query-conflict-lowmem-387/character-subtypes.log）；提取正式角色注册表查询，结合真实 Alien Hominid 角色配置和混合图集替身，验证通用图标、明确指定 Packer/Animate 及默认资源（_build/origin-character-query-subtypes-lowmem-390/results.log）。类、注册表容器和路径桥为替身，真实角色实例、资源缓存、窗口画面和完整 hxcpp 构建尚未验证。

0.9 歌曲静态覆盖防递归联测：使用真实 Polymod/HScript、提取的正式 BaseRegistry 静态分发、正式兼容桥和 SongRegistry 默认查询，让合成 0.9 歌曲脚本覆盖 queryAssets、显式调用 Song.queryAssets 并追加资源；最终同时取得 Alien Hominid 旧模组 Eradication 谱面和自定义资源，未发生递归（_build/origin-static-query-override-lowmem-391/results.log）。注册表对象、脚本宿主及 ScriptGuard 为替身，模组谱面为隔离副本；未验证实际游戏加载或原生构建。

0.9 静态角色查询端到端隔离联测：真实 Polymod/HScript 和正式兼容桥、提取的角色注册表资源方法联合读取 Alien Hominid 原始角色 JSON；MultiSparrow 查询返回实际存在的角色图片，Packer 查询在数据记录为 MultiSparrow 时仍返回 Packer 文本图集路径（_build/origin-static-query-real-character-lowmem-392/results.log）。角色宿主、注册表缓存及路径桥为替身，Packer 样本为合成数据；未实际创建角色、加载图集或完成原生构建。

Eradication 实际图片与历史 Flixel 缩放复核：官方 Origin v0.5.1、v0.6.3 的 hmm.json 分别锁定 Flixel f2b090d6c608471e730b051c8ee22b8b378964b1、fffb1a74cf08f63dacc2ab09976340563f5b6e6d；两者 fromSparrow 方法文本一致，当前 Flixel 额外处理 bitmap.graphicScale。Neko 实际解码 Alien_Notes.png 并解析原 XML，在项目启用的 CODENAME_ENGINE_COMPAT 条件下测得 bitmap.graphicScale=1、sprite.graphicScale=(1,1)、source frame 155×155、scale=0.7 时 hitbox=108.5；使用真实 FlxAnimate 的 Sparrow 绘制矩阵检查得到矩阵横纵缩放均为 0.7（_build/origin-eradication-real-pixels-lowmem-394/codename.log、matrix.log）。无窗口夹具手动启用 tile 模式，未执行 FunkinSprite GPU 绘制、完整 Strumline 或原版屏幕对照，无法认定用户反馈已修复。

Eradication 原图全部动画帧像素范围：读取原始 Alien_Notes.png 与 XML 的全部帧，所有普通箭头和判定箭头源尺寸均标记为 155×155；但图集裁剪区域的非透明像素宽度，静止判定箭头为 155–162 像素，确认动画为 221–248 像素，按 0.7 估算分别约 108.5–113.4 与 154.7–173.6 像素。逐动画统计见 _build/origin-eradication-real-pixels-lowmem-394/frame-alpha-summary.json；这些是源图像 alpha 包围盒，不能替代 Flixel 屏幕绘制结果或证明确认帧大小是引擎错误，也不能据此判断用户看到的具体问题已解决。此前 GameBanana 页面截图缺少可用 HUD，API 查询返回 403，未获得可验证的原版画面对照。

Eradication 历史图集解析对照：将 Origin 0.6.3 锁定的 Flixel 原始 fromSparrow 方法移植到隔离夹具，与当前 Flixel 使用相同的真实 Alien_Notes.png/XML 逐帧比较；68 帧的名称、裁剪矩形、源尺寸、偏移、旋转及翻转均一致（D:/game/FNF-NovaFlare-Engine/_build/origin-eradication-real-pixels-lowmem-394/compare.log）。历史解析方法使用当前 Flixel 的支持类运行，不代表完整历史引擎或实际 GPU 画面；箭头大小问题仍待定位。

Eradication 真实图片与特殊音符脚本的联合检查尚未通过：以既有 HScript/NoteSprite 复用夹具替换为实际 Alien_Notes 与 NOTE_hominid PNG，Neko 运行中脚本抛出 Invalid field access: join（_build/origin-hominid-real-pixels-lowmem-395/real-pixels.log）。该夹具需要禁用 PolymodStaticAbstractReference 副本的空安全类型检查才能编译，仍有音符数据、样式、Paths 和模块宿主替身；异常尚未定位，不能归因于正式游戏，也不能算作兼容通过。此前使用替身位图的解释器检查不等于这项真实像素联合检查通过。

真实图片联合检查的 Neko 异常定位：带调试栈确认上一条 Invalid field access: join 发生在 Polymod 的 Util.getTypeNameOf 对匿名对象调用 Type.getClassName，异常来自测试传入的匿名事件；用更接近游戏事件的类实例替换后，原始 hominidAttack.hxc、实际 Alien_Notes.png/NOTE_hominid.png、实际 Flixel 和提取的正式样式重建方法完成特殊→普通→特殊音符复用检查（_build/origin-hominid-real-pixels-lowmem-395/final.log；调试栈见 debug.log）。特殊音符记录源帧 184×187、scale=0.9、碰撞框 187×184；普通音符源帧 155×155、scale=0.7、碰撞框 108.5×108.5。该测试以 Neko 运行，PolymodStaticAbstractReference 的夹具副本关闭了空安全类型检查，Interp 夹具副本仅加入异常栈日志，事件、路径、样式辅助及宿主仍为替身；未验证真实 GPU 画面、完整游戏或箭头大小，碰撞框数值也不能直接当作画面尺寸。

判定线运行时换样式缩放修正：Strumline.noteStyle 的 setter 会重新构造判定箭头，之前没有把已设置的 strumlineScale 应用到新箭头；当模组先设置非默认缩放再替换样式时，箭头回到样式原始大小。现构造新箭头时按各自样式帧缩放乘当前判定线横纵缩放，与既有 strumlineScaleCallback 一致；两个工作目录均已更新，并在正式 NoteStyleDataChecks 增加重建断言。提取正式 setter 的低负载夹具在修改前复现 0.8/0.8 而非期望 0.4/0.6，修改后通过（_build/origin-strumline-style-switch-lowmem-396/before.log、after.log）。夹具中的线、箭头和样式是替身；正式回归、真实模组运行和 Eradication 可见箭头大小尚未验证。

判定线重建缩放补充：以实际项目 Flixel/OpenFL、未裁剪的正式 StrumlineNote（夹具仅补全项目级 using StringTools）、真实 Alien_Notes.png/XML 以及提取的正式 setter，在 Neko 夹具验证四个箭头切换样式后保持横纵 0.4/0.6 缩放、155 像素源帧和预期位置，旧箭头均销毁（_build/origin-strumline-real-flixel-lowmem-397/results.log）。NoteStyle、FunkinSprite 的扩展方法和判定线宿主为替身，未渲染窗口或运行完整游戏，也不能据此判定 Eradication 视觉尺寸问题已解决。

0.9 预览模组目录 API：对照 d3fdf329 的 PolymodHandler.readModDirectory，在两份工作区恢复此公开方法；sys 平台读取当前 MOD_FOLDER 的原始目录项，失败返回空数组，非 sys 返回现有模组 ID。低负载测试提取正式方法，在本机隔离目录覆盖普通文件、文件夹、空目录与不存在目录，并用 JS 验证非 sys 回退（_build/origin-mod-directory-api-lowmem-398/eval.log、js.log）；文件系统包装和处理器宿主为替身，未运行完整构建或真实模组脚本。2026-11-01 检查官方 release 页面仍显示 v0.8.7、官方里程碑仍称 0.9 为预览，不能据此断言未来不会更新。

0.9 模组目录 API 脚本联测：使用真实 Polymod/HScript、实际加载的合成 0.9 元数据和项目 nullDeprecationSafety 宏，通过 HScript 静态调用提取的正式 readModDirectory，获得隔离目录里的模组文件与文件夹（_build/origin-mod-directory-hscript-lowmem-399/results-guarded.log）。第一次未启用正式空值保护宏时解释器抛出 Null Access，不代表完整项目行为；启用后通过。处理器及 FileUtil 宿主为替身，未执行完整构建。当前系统可用内存与先前触发 3 GiB 保护时接近，按照性能约束未重试高负载完整类型检查。

0.9 预览旧模组持久资源查询：参考 d3fdf329 的 PolymodHandler.queryPersistentAssets，原生目标返回空列表；HTML5 对当前已加载且 API 小于 0.9 的模组按请求资源类型查询，忽略未加载、未知和新版模组。Assets.queryPersistentAssets 现汇入这批结果，使异步资源预加载可使用该接口；两个工作区均已更新。提取正式方法，以模拟资源枚举、元数据和私有 Paths.raw，在解释器及 JS 覆盖无模组、旧/新/缺失模组和各资源类型（_build/origin-persistent-assets-lowmem-400/native-abstract.log、js-abstract.log）。版本校验、资源目录和宿主为替身；真实 HTML5 构建、加载顺序与全部资源类型仍未验证，不代表旧模组已全部兼容。

持久资源查询版本边界补充：JS 夹具换用从正式 VersionUtil 提取的 validateVersionStr 与实际 thx.semver，0.5/0.8 被收集而 0.9 不被收集（_build/origin-persistent-assets-lowmem-400/real-version.log）；其他资源与宿主仍为替身。尝试在独立 JS 夹具中链接实际 Polymod/OpenFL/Flixel 时，当前项目选择的 Lime/Flixel 在浏览器后端报缺少 setVSyncMode、getNativeHandle 等字段及 _samples（_build/origin-persistent-assets-real-polymod-lowmem-401/compile.log）；该夹具不包含完整 Lime 项目构建参数，不能确定正式 HTML5 目标是否有相同错误，也不能算真实资源联测通过。Windows 原生分支保持返回空数组。

Eradication 角色长按动画补偿：先前可见日志中 AlienBF 只注册了 25 个配置动画中的 21 个。核对原始 JSON 和图集，四个 sing*-hold 指定序号 29/61/14/14，但匹配帧名分别以空格加 10029/10061/10014/10014 结尾；Origin 0.5.1 与 0.6.3 固定依赖的 Flixel findSpriteFrame 和当前实现均按数字后缀精确查找，因此这些配置在历史引擎中也不匹配，是模组数据问题，不能称为上游迁移回归。为了尽可能兼容该类模组，在 FlxAnimationUtil 中仅当精确索引完全未注册且所有序号在按前缀排序的帧列表范围内时，回退按列表位置取帧；有效精确匹配保持优先，越界不注册，并清理临时动画。以原始 AlienBF.png/XML/JSON、真实 Flixel 和提取的正式方法，修改前的直接索引无法注册四个动画，修改后分别命中正确末帧，同时通过精确匹配、越界和临时名称冲突检查（_build/origin-hominid-frame-indices-lowmem-402/results.log）；没有运行完整游戏或验证角色画面，也不证明箭头尺寸问题已解决。

动画序号回退重建边界补充：此前以目标名称不存在判断回退，若同名旧动画存在且新图集无法精确索引，则不会恢复新动画。现比较调用前后动画实例，精确添加失败时允许有效的位置回退替换旧动画；越界时保留旧动画，精确匹配部分帧时保持 Flixel 原规则。启用 CODENAME_ENGINE_COMPAT 时为回退动画保留 prefix 和 usesIndices 元数据。真实 AlienBF 图片/XML 与 Flixel 的隔离检查覆盖四方向、同名替换、无效替换、部分精确匹配、临时名冲突，并分别在有/无该编译标志下通过（_build/origin-hominid-frame-indices-lowmem-402/rebuild.log、no-codename.log）。完整原生构建及实际角色画面未验证。

真实样本动画索引影响筛查：只读扫描隔离测试目录 37 份角色 JSON 中 126 个带帧序号的动画，并按本地 XML 文件名模拟匹配：94 项完整精确匹配、4 项部分匹配，12 项满足位置回退条件，均为 Alien Hominid 三个包中相同的四个角色长按动画；16 项未能在各自模组目录定位图集，全部来自用于边界检查的 marker 夹具。完整报告见 _build/origin-animation-index-audit-lowmem-403.json，部分匹配及未找到图集详情见 _build/origin-animation-index-detail-lowmem-403.log。此词法筛查不模拟跨模组资源覆盖、缓存和全部路径解析，也不证明其他模组都兼容；4 项部分匹配沿用原 Flixel 行为，没有套用位置回退。

已下载样本角色图集前缀检查：只读扫描隔离模组目录，排除 marker 测试夹具后，33 份角色 JSON 的 463 个动画前缀均能在对应模组本地 XML 中找到（_build/origin-character-animation-audit-lowmem-404.json）。该检查只验证前缀存在，不验证指定序号、动画播放、像素画面或运行时跨模组覆盖；帧序号另见 403 报告。

动画帧索引正式回归：LegacyCharacterChecks.inspectHistoricalAtlases 现包含内存图集测试，检查位置回退、原有精确匹配、越界保留旧动画和临时名称冲突；无需安装第三方模组。提取新增正式检查和正式动画方法、结合真实 Flixel/OpenFL 的 Neko 隔离运行通过（_build/origin-index-permanent-check-lowmem-405/results.log）；项目级基础回归与原生构建尚未执行。

AlienBF 全动画注册联测：使用原始角色 JSON、原始 PNG/XML、真实 Flixel 与提取的正式 FlxAnimationUtil.addAtlasAnimation，对该角色全部 25 项执行注册并核对名称，现均存在（_build/origin-hominid-frame-indices-lowmem-402/all-animations.log）；其中四个长按动画位置回退、精确及越界边界仍通过。该夹具没有实例化 MultiSparrowCharacter 或播放画面，不代表完整游戏和角色视觉效果已通过。

AlienBF MultiSparrow 真实源码隔离联测：加载正式 MultiSparrowCharacter 与完整 FlxAnimationUtil 源码、项目 Flixel/flixel-animate 及原始 AlienBF PNG/XML/JSON，实际 onCreate 构建并合并图集后注册 25/25 动画；四个长按动画分别播放到目标末帧，动画偏移也逐项核对（_build/origin-multisparrow-real-source-lowmem-406/results.log）。夹具为角色基类、资产路径/缓存、事件和数据类型提供替身，并补项目级 import/using；没有 HScript 角色代理、GPU 窗口、完整游戏和 hxcpp 构建，不代表画面及用户反馈的箭头尺寸已验证。

旧模组伴奏预加载与实际播放一致性：Yippie 0.3.x 元数据填写 instrumental=mom，但模组仅提供 Inst.ogg；PlayState 的空选项实际播放默认 Inst，LoadingState 与 cacheInst 先前却按 getInstPath 的元数据回退尝试预加载 Inst-mom。新增 getPlaybackInstPath，两个预加载入口改按实际传入的空/非空选择生成路径，显式变体仍保留；原 getInstPath 的元数据回退 API 未改。使用真实 Yippie 元数据和默认文件存在性、提取的正式方法及替身路径/缓存检查空、null 与显式变体（_build/origin-playback-cache-lowmem-407/results.log）。未运行真实播放、LoadingState 异步流程、其他伴奏场景或完整构建。

伴奏预加载回归补充：源码核对显示 funkin.Paths.inst 和 funkin.assets.Paths.inst 都将同一 gameplay/songs/<id>/Inst<suffix> 路径交给兼容路径解析器；资产包装随后保留同一扩展名。LegacyPublicApiChecks 新增默认和显式变体的路径一致性断言。低内存夹具复核默认和显式选择（_build/origin-playback-cache-lowmem-407/playback-matching.log），但路径解析器在该夹具中为替身；正式回归、真实旧路径挂载与完整游戏异步加载仍未运行。

变体合并人声路径修正：buildVoiceList 先前检查默认 Voices 是否存在，却在变体非默认时返回未经存在性确认的 Voices-<variation>；仅有变体人声时也会遗漏。buildVocals 原本只尝试变体路径，不回退默认人声。现两者共用 getCombinedVoicePath：优先存在的变体，缺失时回退存在的默认合并人声，两者都缺失返回空；分角色人声仍优先。提取正式三个方法，以路径、音频和分组替身复现旧错误并验证仅默认、仅变体、两者都有、都缺失及分角色优先，预加载与播放使用相同路径（_build/origin-combined-voice-variation-lowmem-408/before.log、after-shared.log，_build/origin-combined-voice-playback-lowmem-409/results.log）。未验证真实音频解码、时序、实际模组画面或完整构建。

人声旧版边界补充：提取正式 legacyVocalPaths、buildVoiceList 和 buildVocals，结合替身文件存在性、音频、分组与来源优先级判断，验证 needsVoices=false 保持静音、显式 voiceList 只使用存在的指定音轨、旧版合并人声保留优先，以及普通变体回退（_build/origin-legacy-voice-boundaries-lowmem-410/results.log）。此前 Yippie 样本没有独立人声，不能将缺失资源认定为本次变体回退缺陷。音频解码、实际来源覆盖优先级、设备及完整构建仍未验证。

Yippie 旧伴奏真实挂载检查：用该模组原始元数据、图标和 Inst.ogg 副本，实际 Polymod 与字节一致的正式 LegacyModFileSystem/LegacyAssetLayout 加载隔离目录；规范请求 assets/gameplay/songs/yipe/Inst.ogg 经虚拟路径解析回原始 songs/yipe/Inst.ogg，元数据中提及的 Inst-mom.ogg 确认不存在（_build/origin-yippie-audio-alias-lowmem-411/with-icon.log）。首次夹具未复制图标且默认库为空，初始化空路径报错；加入真实图标后完成，不能据此推断正式游戏中缺图标模组一定会失败。此检查验证索引与路径，不解码或播放音频；元数据转换、角色布局为替身，未执行完整游戏。

编辑器鼠标接管嵌套回归：扩展 D:/game 工作区 tools/tests/nf_gameplay_eval/Main.hx，使用正式 MouseEffect 和 OpenFL、合成舞台事件宿主，验证进入编辑器清理已有 NF 特效、接管期间禁止新特效、嵌套编辑器计数、游戏与编辑器同时抑制、全部释放后恢复以及用户关闭设置保持关闭；连同现有长按与暂停检查共 25 项通过（_build/nf-gameplay-regressions/editor-cursor-412.log）。当前 worktree 原本没有这套 NF 测试工具，未覆盖或创建其测试树；不代表编辑器自身指针主题或真实窗口交互已验证。

旧合并人声与分角色人声跨模组优先级联测：使用真实 Polymod 索引、正式 LegacyModFileSystem/LegacyAssetLayout 和提取的正式 preferCombinedVoice，以独立模组与占位音频文件交换启用顺序；新版分角色模组在后时选择分角色，旧合并人声模组在后时选择合并（_build/origin-voice-priority-lowmem-413/split-last.log、legacy-last.log）。音频内容、角色/曲目宿主和部分布局方法为替身，未解码或实际播放，也未将整个 SongDifficulty 联合运行；此结果不涵盖全部覆盖组合。

跨模组人声预加载/播放选择联测：在 413 实际 Polymod 与旧路径索引的两种模组顺序上，进一步接入提取的正式 getCombinedVoicePath、buildVoiceList、buildVocals、legacyVocalPaths 及 preferCombinedVoice，确认两个顺序下预加载与播放选择分别一致（_build/origin-voice-priority-integrated-lowmem-414/split-last-integrated.log、legacy-last-integrated.log）。声音加载器、人声组、角色音轨查找与路径包装为替身，文件为占位资源；未解码音频或覆盖真实游戏。

0.9 预览已启用模组列表接口：PolymodHandler 增加 enabledModIds 的公开读写属性，继续使用 NF 当前 Save.instance.enabledModIds，不新建或读取 enabled.txt；读取与写入均复制数组，显式赋值后沿用现有保存 flush。用真实 Polymod/HScript、合成 0.9 元数据和保存替身检查脚本读取、赋值、顺序、调用方修改数组不隐式改变存档，以及一次 flush（_build/origin-enabled-mod-api-lowmem-415/results.log）。该接口后端不同于预览上游的原生 enabled.txt；未触碰用户实际存档、未重载模组，也未运行完整构建。

0.9 预览状态资源查询：恢复 GameOverSubState.queryAssets 与 PixelatedIcon.queryAssets。前者按可玩角色目录筛选 game-over/loss-sfx 文件并去重，后者只返回自由选曲角色图标的图片或 XML；对照固定上游预览实现。提取正式方法并用真实 Polymod/HScript 与资源索引替身覆盖类型、目录、无关文件和重复项（_build/origin-preview-state-assets-lowmem-416/results.log）；真实注册表、资源索引、游戏状态和完整构建尚未验证。

0.9 歌曲难度及备用暂停资源接口：SongDifficulty.queryAssets 恢复歌曲注册表、音符样式、已缓存事件、伴奏、人声与存在的字幕查询；GitarooPause.queryAssets 恢复备用暂停界面的图片/XML 查询。基于提取的正式方法和真实 Polymod/HScript，分别检查歌曲查询类型、事件、显式伴奏、字幕存在/缺失、脚本调用，以及暂停图片/XML 数量（_build/origin-songdifficulty-assets-lowmem-417/results.log、_build/origin-gitaroo-query-lowmem-418/results.log）。注册表、资源路径、事件和音频为替身，未验证真实游戏资产或完整构建；PlayState 的完整预览版静态查询尚未实现。

0.9 PlayState 静态资源查询已补齐：使用 SongDifficulty.queryAssets，并按普通/最小模式汇总贴纸包、舞台、角色、游戏结束音效、暂停音乐/图集、漏键音效、界面及着色器；无目标难度时报错。由于当前工程使用 StickerSubState 而非预览版 StickerLoadingState，实现按预览版 StickerTransition 规则直接查询贴纸注册表和点击音效。提取正式方法并以真实 Polymod/HScript、歌曲/注册表/资源替身覆盖普通、最小、缺少难度、角色及贴纸、声音和脚本调用（_build/origin-playstate-query-lowmem-419/results.log）。这覆盖此前记录的 PlayState 静态接口缺失，但真实注册表、资源缓存、界面与完整构建仍未验证。

PlayState 静态查询贴纸包补充：歌曲已显式指定贴纸包时不再实例化玩家条目，仅在缺省时查询玩家默认包；低内存夹具新增该边界并通过（_build/origin-playstate-query-lowmem-419/results.log）。玩家注册表仍为替身，完整游戏未验证。

SongDifficulty 真实旧模组资源联测：加载 Alien Hominid 原始谱面/元数据副本与合成 0.9 脚本，通过真实 Polymod、正式旧路径文件系统、提取的 SongRegistry 默认查询和正式 SongDifficulty.queryAssets，在原生及 HScript 调用中找到旧模组的 Eradication 谱面（_build/origin-songdifficulty-real-mod-lowmem-420/results.log）。音符样式/事件注册表、路径包装、歌曲宿主及音频查询为替身；没有实际播放、真实完整注册表或完整构建。

歌曲难度查询参数补充：低内存解释器夹具显式传入 null 伴奏 ID，确认该方法按默认空 ID 调用伴奏路径构造（_build/origin-songdifficulty-assets-lowmem-417/null-default.log）；路径构造为替身，尚未覆盖 hxcpp。

0.9 结算静态资源入口：恢复 ResultState.queryAssets，汇总指定难度图、评分图、结算界面、Sparrow/Animate 角色图集、贴纸、结算音乐及存在的开场/元数据。当前工程结算音乐路径使用旧版字符串路径，查询与实际播放现共用 resultsMusicStem，避免预览版嵌套路径构造器重复拼接目录。真实 Polymod/HScript 配合角色、资源及评分替身验证 IMAGE/XML/SOUND/JSON、脚本调用、缺角色与无成绩回退（_build/origin-results-query-lowmem-421/results.log）。未验证真实角色注册表、旧资源别名、音频解码、实际结算窗口及完整构建。

0.5 结算真实 ZIP 路径与查询联测：使用固定的官方 v0.5.0 BF 结算回归 ZIP 副本、实际 Polymod、正式旧路径映射/文件系统及提取的兼容路径解析器；规范路径下的 BF Animate JSON/PNG、GF Sparrow PNG/XML、音乐 OGG/元数据均能读取（_build/origin-results-real-mod-lowmem-422/results.log）。进一步用 ZIP 中原始 BF 玩家 JSON 和提取的 ResultState.queryAssets，确认 GOOD 结算查询包含这些真实已索引路径（_build/origin-results-query-real-legacy-lowmem-423/results.log）。夹具的玩家宿主、评分、AssetPath 包装与资源列表适配为替身；ZIP 中为隔离夹具补充了图标副本，原 ZIP 未修改。未实际播放音频、渲染结果或完成原生构建。

0.5 BF 金色 Perfect 结算查询联测：在真实 Polymod 旧版 ZIP 索引上，使用原始 BF JSON、提取的正式 PlayerRegistry 1.0 迁移、PlayableCharacter 等级方法与 ResultState.queryAssets，确认缺省 perfectGold 采用 perfect 的两层图集，并查询到对应音乐（_build/origin-results-migration-query-lowmem-424/results.log）。首次断言误要求主图集只能使用规范别名；实际查询返回已索引的旧 shared 路径，按实际路径修正检查后通过（diagnostic.log 留存）。解析器、角色宿主、评分及资源包装仍为替身；未渲染或播放，也未完成原生构建。

歌曲查询与实际伴奏一致性修正：新增的 SongDifficulty.queryAssets 原先照预览上游调用 getInstPath，空选择仍会从 Yippie 元数据构造缺失的 Inst-mom；现改用此前与 PlayState 实际播放一致的 getPlaybackInstPath，原 getInstPath API 不变。真实 Yippie 元数据和 Inst.ogg 副本经实际 Polymod/旧路径文件系统验证，查询空选择返回已挂载的默认文件、显式 pico 仍返回对应变体、旧 getter 仍返回元数据路径（_build/origin-yippie-query-lowmem-426/results.log）。注册表、路径包装和声音加载为替身，未解码音频或运行完整游戏。


### 持续目标约束：控制电脑负载

遵照用户要求，兼容工作须控制 CPU、内存和磁盘负载，避免电脑卡死。先检查可用资源，优先使用低负载、分批或受限并发的检查；资源不足时停止高负载任务，不强行进行完整编译或并发测试。需要游戏窗口测试时保持窗口可见；无法自行完成的操作留待未验证，不要求用户代操作。保留已有本地代码。


0.9 预览菜单静态资源查询：DifficultyDot、FreeplayFlames、DifficultyStars、角色选择 Lock、AlbumRoll 与 DifficultySprite 增加 queryAssets，对照 d3fdf329 的资源类型和路径，难度 XML 不存在时跳过。提取正式方法的低负载 Haxe 夹具检查返回路径、类型、难度缺失、专辑注册表汇总，并用真实 Polymod/HScript 调用六个接口（_build/origin-freeplay-query-lowmem-427/results.log）。资源路径、图集和专辑注册表为替身；未验证真实菜单资源加载、原生构建及模组画面，不代表完整模组兼容。


Eradication 特殊音符联合检查补充：此前记录 real-pixels.log 中的 join 异常后，夹具后续 final.log 已通过；本次重运行既有 final.n 亦通过（_build/origin-hominid-real-pixels-lowmem-395/recheck-20261101.log）。运行时读取原模组 HScript 和 Alien_Notes/NOTE_hominid 图集，检查特殊音符切换回普通音符并再切回特殊音符；当前正式 NoteSprite 与夹具副本一致，正式 buildNoteSprite 与夹具提取方法一致。特殊音符源帧 184×187、脚本 scale 0.9，普通音符源帧 155×155、scale 0.7。此为既有 Neko 二进制重运行，编译时使用过禁用 PolymodStaticAbstractReference 夹具副本空安全检查，NoteStyle 数据、Paths、事件等为替身；未重新构建游戏或绘制窗口，不证明用户看到的箭头尺寸已修复。


编辑器鼠标主题缓存修复：工具更改 Cursor.cursorMode 后，HaxeUI 仍可能保留相同的上次 CSS 指针名，下一次鼠标移动时误判无需更新，导致控件继续显示工具图案。现切换模式时清除该解析缓存，使下一次移动重新应用控件指针；两个工作目录均已修改。使用正式 Cursor 源码及 Flixel/HaxeUI 替身的低负载夹具先复现再通过，并检查默认、指针、缩放、未知值和隐藏/恢复（_build/origin-cursor-cache-lowmem-428/before.log、after.log）；关闭 HaxeUI 编译分支也通过（no-haxeui.log）。真实 HaxeUI、窗口事件顺序与完整游戏仍未验证。


0.9 预览自由选择菜单查询补充：为 LetterSort/FreeplayLetter、CapsuleOptionsMenu、SongMenuItem、FreeplayScore/ScoreNum 增加静态 queryAssets，覆盖排序字母图集、菜单图集、歌曲胶囊与数字图集，并处理自定义样式和默认回退。预览版 ScoreNum 已组装数字资源但最终返回空数组；此处返回实际组装的资源，避免预加载遗漏，属于有意修正而非逐字复刻。提取正式方法并通过真实 Polymod/HScript 的低负载夹具检查资源类型、路径、默认/自定义样式与脚本调用（_build/origin-freeplay-query-lowmem-429/results.log）；资源路径、图集和样式为替身，未验证真实菜单或原生构建。


旧模组专辑路径实物复核：从 Pico Chill 0.5.3 原包复制 ACE177.json、图标及实际封面/标题 PNG 和标题 XML 到隔离目录，结合真实 Polymod、正式 LegacyModFileSystem/LegacyAssetLayout、完整兼容路径解析器及提取的 formatRelative，均能解析到对应旧 images/freeplay/albumRoll 文件（_build/origin-old-album-lowmem-430/real-resolver.log）。第一次 results.log 使用未包含正式路径猜测逻辑的 Paths 替身，误报路径缺失，不能代表正式工程。资源存在性桥及 AssetPath 包装为替身；未绘制选曲界面。此前 Senpai 旧版数据引用的 fnf-ost-v1 资源在已检查的样本中未找到，不能用此结果认定该次退出失败已解决。


旧专辑标题容错：AlbumRoll.buildAlbumTitle 原本无条件加载 Sparrow，旧模组或旧数据缺少标题图/XML 时可能导致自由选曲创建失败。现缺少 PNG 时记录警告并跳过标题；有 PNG 而无 XML 时显示静态图片；有 XML 时保留原动画图集，播放前检查动画存在。提取正式方法的低负载夹具覆盖动画、静态、缺图和旧标题清除（_build/origin-album-title-lowmem-431/results.log）；图片、图集和界面对象为替身，真实窗口、损坏 XML、专辑封面缺失及完整构建尚未验证，不能宣称此前退出流程已实测通过。


旧专辑标题容错的真实资源判定补充：真实 Pico Chill 0.5.3 封面 PNG、标题 PNG/XML 经正式旧路径解析器与 Polymod 索引，分别命中“静态图片”和“动画图集”；此前缺失的 fnf-ost-v1 在隔离资源集命中“缺图”分支（_build/origin-old-album-lowmem-430/title-branches.log）。资源存在性桥和 AssetPath 包装为替身，三个判定没有直接调用完整 AlbumRoll，也未绘制窗口或验证实际结果界面退出。


Pico Chill 建筑着色器来源复核：先前记录的 BuildingEffectShader 不在模组包内，但当前用户外置 Origin 基础资源含 ui/shaders/BuildingEffectShader.hxc 和 building.frag。将实际基础脚本/fragment 与真实 Polymod、Flixel 及解释器兼容宏联测，以合成脚本复现 Pico Chill 0.5.3 的 ScriptedFlxRuntimeShader.init 调用，成功构造并保留 speed=1（_build/origin-pico-base-shader-lowmem-432/results.log）。脚本由夹具手动注册，路径和资源库为替身；未运行真实舞台脚本、自动预热、GPU 渲染或原生构建，因此只确认依赖存在和该构造调用可用。


Pico Chill 基础着色器预热补充：使用 Polymod.registerAllScriptClasses 的真实同步发现/预热流程，从替身资源库列出外置 BuildingEffectShader.hxc 和模拟 Pico 调用脚本，2 个脚本、16 个引用预热零错误，随后成功创建实际基础着色器（_build/origin-pico-shader-preheat-lowmem-433/results.log）。资源库列表与 Paths 仍为替身、调用脚本为合成样本，并未启用项目的脚本去重/依赖注册宏或运行异步启动流程；不能据此认定完整游戏启动及舞台渲染通过。


多图集自由选曲 DJ 容错：正式 Paths.getSparrowAtlas 在缺图/XML 时抛异常，原先 MultiSparrowFreeplayDJ 的 null 检查接不到异常，且 null 分支之后仍无条件合并；附加图集缓存也使用了未解析的原始相对路径。现捕获附加图集加载错误、记录并跳过缺失项，成功项使用实际解析路径缓存并合并；主图集仍按原方式处理。提取正式 loadFrames 的低负载夹具覆盖有效图集、重复路径、抛错、空值与缓存路径（_build/origin-dj-atlas-lowmem-434/results.log）；资源、Flixel 和 DJ 宿主为替身，真实模组/GPU 与完整构建未验证。


歌曲角色混合图集容错：MultiSparrowCharacter 与 MultiAnimateAtlasCharacter 原先附加 Sparrow 图集缺失时，Paths.getSparrowAtlas 抛错绕过 null 检查；Animate 附加图集失败也会中断。现记录错误并跳过无法加载的附加图集，保留主图集与其他图集；MultiSparrow 缓存改用解析后的 Sparrow 路径。使用正式 MultiSparrowCharacter/FlxAnimationUtil、真实 Flixel 和 AlienBF PNG/XML 注册 25 个动画后注入缺失 Sparrow 及 Animate 附加项，主图集仍保留（_build/origin-character-subatlas-lowmem-435/results.log）；Animate 加载器和角色基类等为替身。提取 MultiAnimateAtlasCharacter.loadAtlases 的替身夹具覆盖主图集、有效 Sparrow、缺失 Sparrow/Animate（_build/origin-multianimate-subatlas-lowmem-436/results.log）；真实多 Animate 角色、可见画面和完整构建未验证。


Eradication 音符样式真实路径复核：隔离挂载 Alien Hominid 0.5 包的实际 hominid.json、Alien_Notes PNG/XML，以真实 Polymod、正式 LegacyModFileSystem/LegacyAssetLayout 和完整兼容路径解析器检查普通音符与判定线的 shared:notes/Alien_Notes，PNG/XML 均解析到模组 shared/images/notes 下的原文件；JSON 两处 scale 均为 0.7（_build/origin-alien-style-path-lowmem-437/results.log）。AssetPath 和存在性桥为替身，按 JSON 人工拆分库名；未执行完整 NoteStyle 解析/渲染或屏幕对照，这只能排除该隔离样本中的资源路径缺失，不能证明用户反馈的箭头尺寸问题已解决。


编辑器鼠标接管边界：Origin 初始化时注册的 HaxeUI 鼠标移动监听此前只检查鼠标是否可见，即使已离开编辑器、其他状态显示 NF 指针，也可能加载编辑器指针。现由 Cursor.show/hide 标记接管和释放，监听器仅在持有鼠标时工作；保留编辑器默认/控件/工具指针行为。正式 Cursor 源码配合 Flixel/HaxeUI 替身的低负载测试在旧逻辑复现其他状态图案被覆盖，修复后覆盖接管前、接管中、释放后和无 HaxeUI 分支均通过（_build/origin-cursor-ownership-lowmem-438/before.log、results.log、no-haxeui.log）；真实窗口与完整构建尚未验证。


HaxeUI 原生鼠标处理补充：上条接管边界只限制自定义监听，依赖 haxeui-flixel 的 ScreenImpl.setCursor 还有独立入口，并检查 CursorHelper.useCustomCursors。现初始化时关闭该入口，Cursor.show 时开启、hide 时关闭，与编辑器指针接管一致。正式 Cursor 和来自依赖的 CursorHelper 配合替身界面复现修复前入口仍开启，修复后覆盖编辑器外/内/退出、默认及控件指针和无 HaxeUI 分支（_build/origin-cursor-haxeui-ownership-lowmem-439/before.log、results.log、no-haxeui.log）。没有真实 HaxeUI 窗口或完整构建；其他使用 HaxeUI 且不调用 Cursor.show 的界面不再由它自动更改 Flixel 指针，需在整体运行验收时检查。


0.9 预览自由选曲 DJ 静态资源查询：BaseFreeplayDJ 和 AnimateAtlas/MultiSparrow/Sparrow/Packer 四种渲染器增加 queryAssets；基础入口优先调用模组静态覆盖，否则按渲染类型收集图集，路径按本工程渲染器的相对路径规则解析，多 Sparrow 重复图集去重。低负载检查提取正式入口并使用正式 FreeplayDJAssets，真实 Polymod/HScript 覆盖四种类型、资源类型、相对路径、缺失玩家和脚本覆盖（_build/origin-freeplay-dj-query-lowmem-440/results.log）。玩家注册表、资源路径/图集及 ScriptGuard 为替身，脚本为合成样本；真实 DJ 模组、预加载与完整构建仍未验证。


自由选曲 DJ 静态查询重入修复：模组的 queryAssets 覆盖调用 BaseFreeplayDJ.queryAssets 时原先会再次分发到自身，导致递归。现用线程局部活动脚本栈识别重入，改走对应原生渲染器查询，并在完成及异常时恢复状态。真实 Polymod/HScript 隔离夹具先限制递归深度复现资源丢失，修复后返回原生资源和脚本追加项；故意抛错两次验证后续调用仍能执行（_build/origin-freeplay-dj-reentry-lowmem-441/before.log、final.log）。注册表、路径和 ScriptGuard 为替身，故意抛错日志是测试的一部分；Neko 编译被 Polymod 依赖的空安全错误阻止（neko-compile.log），未验证完整 hxcpp 和多线程并发。


自由选曲 DJ 真实基础资源检查：用外置 Origin 资源中 BF/Pico 实际角色 JSON 的 freeplayDJ 字段及其原始图集文件，调用正式 FreeplayDJAssets/提取的基础查询，各返回一张 PNG 和两份存在的 JSON（_build/origin-freeplay-dj-real-assets-lowmem-442/results.log）。这是基础资源对照，不是第三方 DJ 模组验收；注册表、路径与图集列表为文件系统替身，未加载真实脚本覆盖或渲染窗口。


工作区保全核对（2026-11-01）：GitHub PR #220 已于 2026-10-31 合并，合并提交 e5a1c759b6f8ad86a6c36cd45e1aabae5ad928fb 是 D:/game 工作区 HEAD 的祖先。只读比较两个工作区当前所有改动涉及的 source-originFunkin 与 docs 文件：595 个文件两边均存在，其中 116 个字节一致、479 个仅换行符不同，按换行规范化后内容一致；另有 43 个路径两边均不存在（包含现有 Git 删除项），没有发现只在一边存在的这些路径。此比较不审查其他目录的所有内容，不代表 43 个删除应当提交，也未重置、同步或删除任何本地代码。


DJ 查询重入 Neko 补充：上次 Neko 失败中，生成类空安全错误来自夹具对 DJ 类额外添加的 @:nullSafety；去掉该夹具专属标记，并仅对隔离副本 PolymodStaticAbstractReference 关闭空安全检查后，Neko 下真实 Polymod/HScript 的重入及两次故意抛错恢复检查通过（_build/origin-freeplay-dj-reentry-lowmem-441/neko-workaround.log）。另以两个 Neko 线程检查正式活动查询栈的线程局部隔离通过（thread.log）；该测试只检查栈隔离，不是并发调用 Polymod 的线程安全证明。依赖工作区和正式源码没有因该绕过而修改；完整 hxcpp 与实际模组仍未验证。


0.9 选曲界面整体资源查询：为 FreeplayState、BackingCard 与 NewCharacterCard 增加静态资源查询，汇总选曲界面、难度、歌曲胶囊、专辑、DJ 和卡片；返回结算排名动画时按需包含资源，并支持按 getCharacterId 找到脚本卡片后查询其额外资源。卡片查询不缓存脚本类，以避免热重载后沿用旧结果；不含新静态接口的旧卡片仍按默认卡片资源处理。提取正式方法并用真实 Polymod/HScript 的低负载夹具覆盖脚本调用、卡片匹配、解锁卡、排名动画、字体和音效（_build/origin-freeplay-state-query-lowmem-443/results.log）；玩家/样式/路径/资源注册表及脚本卡类列表为替身，未运行真实第三方卡片、完整资源缓存或原生构建。


选曲预加载角色选择修复：FreeplayState.queryAssets 接受 params.character，但此前无显式 characterId 时 DJ/卡片仍按 rememberedCharacterId 查询；若这两个角色不同会遗漏所选角色资源。现默认使用实际查到的玩家 ID，保留显式 characterId 覆盖；目标不存在时使用实际回退的默认角色。BaseFreeplayDJ 的渲染器名称同时按现有创建路径 trim 并转小写。低负载 Polymod/HScript 夹具在修复前复现切换角色加载错误，修复后覆盖所选角色、显式覆盖、缺失回退和带大小写空格的类型（_build/origin-freeplay-character-query-lowmem-444/before.log、results.log）；注册表与资源路径为替身，真实模组预加载、窗口和完整构建仍未验证。


0.9 第三方模组选曲整体查询联测：使用 WeekEnd1 Pico Freeplay BG 真实 GameBanana 预览 ZIP、真实 Polymod 与正式 LegacyModFileSystem、实际样式数据解析器、提取的正式 FreeplayState.queryAssets 和真实 HScript 调用，确认汇总结果包含并能解析该模组 background-darnell.png（_build/origin-freeplay-real-mod-aggregate-lowmem-445/final.log）。ZIP 模拟目录扫描仍有找不到实体目录的提示，但资源可从压缩包读到；玩家与注册表、路径/图集包装及卡片类列表为替身，调用脚本为合成样本，没有真实菜单、GPU、完整游戏或原生构建。


0.9 角色选择资源查询：增加 CharacterSelectState.queryAssets，汇总界面、锁、图标和每个玩家及其 GF 的资源。角色图集按本地实际支持的 Animate、Sparrow、多 Sparrow 和 Packer 类型及相对路径分别查询 PNG/JSON/XML/TXT，多图集路径去重；这一部分扩展了预览上游只按 Animate 查询的行为。提取正式方法的低负载 Polymod/HScript 夹具覆盖角色和 GF 不同渲染类型、附加图集、文件类型与脚本调用（_build/origin-charselect-query-lowmem-446/results.log）；玩家注册表、路径和图集为替身，真实第三方角色选择界面、资源缓存及完整构建未验证。


0.9 解锁界面图标查询：增加 CharacterUnlockState.queryAssets，按 HealthIcon 的存在性规则选择角色图标或默认占位图，并仅在存在时返回动画 XML。低负载 Polymod/HScript 夹具覆盖旧静态、动画和缺失图标回退（_build/origin-unlock-icon-query-lowmem-447/results.log）；进一步以 Alien Hominid 原始 AlienBF.json、icon-bfanimado PNG/XML、真实 Polymod 和正式旧路径解析器验证脚本查询能找到实际旧模组图标（_build/origin-real-unlock-icon-lowmem-448/results.log）。角色注册表与 AssetPath 包装为替身，未验证解锁画面或完整构建。


0.9 菜单及注册表静态查询补充：为 Level、StickerPack、StoryMenuState、ModMenuButton 和 CheckboxPreferenceItem 增加 queryAssets。关卡与贴纸沿用已实现的注册表默认资源规则；故事菜单包含默认难度和界面资源，缺少的可选难度图集跳过。提取五个正式入口并以真实 Polymod/HScript 的低负载夹具检查资源类型、缺失条目、可选 XML 和脚本调用（_build/origin-menu-registry-query-lowmem-449/results.log）；注册表和资源路径为替身，实际故事菜单、贴纸和完整构建尚未验证。既有真实 Alien 旧关卡数据检查见 _build/origin-story-assets-lowmem-314/results.log，但没有和本次脚本入口直接联测。


旧关卡与 0.9 静态查询联测：使用 Alien Hominid 原始 weekalien.json、标题与道具 PNG/XML，结合真实 Polymod/HScript、正式 LegacyModFileSystem/旧路径解析器，以及提取的 Level.queryAssets 和 LevelRegistry 默认规则，确认脚本可查询并解析三个实际模组文件（_build/origin-real-level-query-lowmem-450/results.log）。关卡对象、缓存注册表、难度列表及 AssetPath 包装为替身，未绘制故事菜单或运行完整游戏。


真实 0.5 模组角色选择图集路径修复：从 GameBanana 的 Character Select GF & Nene ingame（https://gamebanana.com/mods/542560，文件 1281225，MD5 a01d34886a7bf0dce38e6c30512996dc）取得未修改 ZIP。模组 GF/Nene 角色引用旧 charSelect/gfChill 和 neneChill 图集；隔离加载原包并使用正式兼容解析器时，修复前无法找到图集（_build/origin-gf-charselect-legacy-lowmem-451/before.log）。现将两种旧路径形式下的 Animation.json、spritemap1.json 和 PNG 映射到外置资源对应 GF/Nene 目录；真实 Polymod 与基础资源替身联测两者成功解析（after.log），另用旧版真实 GF 图集建立合成覆盖模组，验证旧路径资源优先于基础资源（override.log）。历史和当前图集文件并非字节相同，但各自包含模组引用的动画名称；本检查未创建角色、验证动画视觉或完整游戏，ZIP 的虚拟目录扫描仍有提示。


GF/Nene 旧模组脚本回调联测：直接从未修改的 0.5 ZIP 读取 gf.hxc 和 nene.hxc，以真实 Polymod/HScript、正式 LegacyModFileSystem 和真实 FlxPoint 构造脚本角色，通过带事件参数的原生代理调用模组无参 onAdd；对手分支按预期应用位置偏移，GF 与 debug 分支不移动（_build/origin-gf-legacy-script-lowmem-452/final.log）。AnimateAtlasCharacter、PlayState、舞台和 CharacterType 为替身，事件对象直接传入代理而非真实事件分发器；没有加载真实角色图集、绘制窗口或完整构建。ZIP 虚拟目录扫描仍有提示。


Origin 0.5 Animate Atlas 角色符号回退：上游 0.5.0 的 FlxAtlasSprite 同时接受帧标签和符号名，而当前角色加载默认仅按帧标签注册；实际 GF/Nene 旧模组使用的 `Partner GF idle`、`nene cs idle` 在当前真实图集中是符号定义。现当角色的帧标签动画不存在或帧数为零，且图集中确有同名符号时，按符号重新注册，保留帧率、循环、翻转与指定帧索引；有效帧标签和显式 symbol 配置保持原路径。低内存检查从正式角色方法提取该分支，读取真实 GF/Nene 图集 JSON，使用替身模拟动画控制器，覆盖缺失、零帧、有效帧、索引、显式 symbol 和不存在符号（`_build/origin-legacy-symbol-lowmem-453/results.log`）。图集渲染器、完整原生构建及可见游戏画面尚未验证；该测试不能证明旧模组整体可玩。


进一步使用项目选定的真实 flixel-animate 控制器及 HaxeFlixel 动画类执行上述正式分支：检查真实 GF/Nene JSON 中的符号定义，以受控时间轴验证符号注册、空动画替换、已有有效动画保留及索引帧注册，结果见 `_build/origin-real-atlas-symbol-lowmem-454/results.log`。时间轴和图集是手工构造，未验证实际图集解析、绘制或完整游戏。独立 Neko 尝试直接解析真实 Animation.json 时发生数组表示不匹配（`$asize`），不代表正式 Windows C++ 运行结果。


真实旧模组角色数据联合回归：以 GF/Nene 原始 ZIP 的角色 JSON，编译未经裁剪的正式 `AnimateAtlasCharacter.hx`、`FlxAnimationUtil.hx` 与实际 flixel-animate 控制器；图集加载和角色父类仍为替身，时间轴人工构造。移除符号回退的基线在 GF `danceLeft` 失败，保留回退后 GF 和 Nene 的四个舞蹈动画均注册成功（`_build/origin-character-production-lowmem-455/before.log`、`results.log`）。这验证了真实角色加载与控制器之间的调用，仍不证明真实图集绘制、脚本联合运行或完整原生游戏通过。


Eradication 绘制变换进一步对照：读取旧模组实际 Alien_Notes PNG/XML 和当前真实 flixel-animate，按已保存的官方 v0.5.1 固定 Flixel `drawComplex` 计算未旋转精灵的旧变换，与当前 `prepareDrawMatrix` 比较；68 帧及水平翻转共 136 个变换在 0.7 缩放、固定相机下完全一致（`_build/origin-eradication-old-draw-lowmem-456/results.log`，启用工程 CODENAME_ENGINE_COMPAT 编译标志）。这是离屏矩阵对照，不覆盖 GPU、完整游戏相机、设备缩放、作者期望或 0.5.0 宽度缩放，因此不能据此称用户反馈的箭头大小已修复。


截图与编辑器鼠标所有权：截图插件原先借用 `Cursor.hide/show` 临时隐藏和恢复鼠标，可能释放编辑器接管、重置工具图案，或在普通界面恢复时错误接管 NF 鼠标。现截图和预览只改变鼠标可见性，不修改光标图案和 HaxeUI 归属；其他编辑器的正常 show/hide 保持不变。使用正式 Cursor 源码、截图插件实际可见性语句及 Flixel/HaxeUI 替身进行低负载检查：旧逻辑在 NF 鼠标归属用例失败，修改后通过普通界面、编辑器工具指针、临时隐藏及退出释放（`_build/origin-screenshot-cursor-lowmem-457/before.log`、`results.log`）。尚未验证完整截图插件、真实窗口事件顺序或原生构建；编辑器可能在截图期间主动恢复可见性的问题仍需运行检查。


Origin 0.5–0.7 角色图集舞台矩阵：核对官方 0.5.0 及其固定 flxanimate 提交 `0654797e5eb7cd7de0c1b2dbaa1efe5a1e1d9412`，旧角色在放置前已计算边界，但播放符号时仍保留图集舞台实例矩阵；0.7.5 仍是旧子渲染器，0.8.1 已改用新渲染器。真实 GF 旧/新图集的舞台实例平移均为 (639.95, 360)。之前共用 `<0.5.0` 的初始边界开关，导致 API 0.5 角色漏用旧舞台矩阵。现分别判断初始边界（<0.5）与舞台矩阵（<0.8），不覆盖显式图集设置或未知来源，并增加正式兼容检查。真实模组 JSON 配合正式角色类、真实动画控制器及图集加载替身的回归中，旧条件在 GF 失败，新条件对 GF/Nene 通过；提取正式注册表策略并使用实际 thx.semver 验证版本边界和显式设置（`_build/origin-atlas-stage-matrix-lowmem-460/before.log`、`results.log`，`_build/origin-atlas-policy-lowmem-461/results.log`）。模组元数据声明的是最低 API，并不必然等于作者实际使用的引擎；隔离测试未解析或绘制真实图集，实际位置和完整原生构建仍需验证。源码快照保存在 `_build/origin-atlas-history-lowmem-458`。


旧图集舞台矩阵的归属与数据边界补充：实际挂载 GF/Nene 原始 ZIP 后，使用真实 Polymod、旧路径文件系统和提取的正式版本归属方法，两个角色 JSON 都解析到其模组并识别 API 0.5.0，启用旧舞台矩阵而不启用早期零边界（`_build/origin-gf-charselect-legacy-lowmem-451/actual-policy.log`；版本工具在夹具中以实际 thx.semver 调用代替）。另用未裁剪的正式 CharacterData 与项目选定 json2object 解析真实模组数据；伪造 `legacyAtlasStageMatrix` 字段产生解析错误，未能注入内部策略（`_build/origin-character-json-policy-lowmem-462/results.log`；动画与舞台数据类型为替身）。正式兼容回归也增加伪造字段检查，但尚未运行完整项目回归；仍未验证真实图集绘制或原生游戏。


GF/Nene 舞台矩阵进一步对照：用实际当前 GF/Nene Animation.json 的舞台矩阵和模组 1.2 倍缩放，在真实 flixel-animate 的 `prepareAnimateMatrix` 中传入人工边界和替身帧，对照官方 0.5.0 固定 flxanimate 的实例矩阵及 `drawLimb` 计算。未翻转时变换一致；水平翻转的模拟变换出现明显差异（`_build/origin-atlas-old-stage-matrix-lowmem-463/results.log`）。此检查使用合成边界、1 像素替身帧与固定相机，旧渲染器只按源码重算，不能确定真实图集绘制中的最终偏移；GF/Nene 的示例角色数据没有显式 flipX。翻转差异需要真实帧和历史依赖联合验证后再决定修复方式，不能认为舞台矩阵兼容已全面完成。


GF 实际旧图集历史渲染对照：在 Neko 中分别运行官方 0.5.0 固定 flxanimate 源码和项目选定 flixel-animate 源码，读取真实旧 GF Animation.json、spritemap JSON/PNG，以替身相机记录绘制矩阵，不创建窗口。两者都处理 29 个可见部件；按名称取首个部件比较，22 个共同名称中未翻转有 9 个矩阵不一致，水平翻转 22 个均不一致，例如 `0000` 的横坐标分别为 1578.828 和 1678.74（`_build/origin-atlas-renderer-compare-lowmem-465/results.log`）。同名部件可能重复，统计并非逐实例完整比对；设置了相同初始位置、缩放及 origin，但模拟未覆盖完整角色初始化与 GPU。为适配 Neko，历史依赖夹具关闭 GPU 滤镜渲染器并显式初始化整数，新依赖夹具将两个 JSON 符号数组从 Vector 改为 Array 并显式初始化时间轴帧数；正式依赖未改。该结果加强了翻转差异的证据，同时发现未翻转部件差异，尚不能直接推断统一修正量或宣称画面兼容。


GF 图集对照的初始化顺序修正：上一次对照遗漏了旧渲染器播放后更新动画状态，并未给新渲染器设置角色实际使用的 `swfMode=true`。补齐两点并在缩放后调用 `updateHitbox` 后，22 个共同名称的首个可见部件在未翻转时矩阵全部一致；先前报告的 9 个未翻转差异是该夹具初始化差异，不应视为引擎缺陷。水平翻转仍有 22 个共同名称的首个部件不一致，代表帧 `0000` 的横向差为 99.912。对应旧渲染器上一帧宽度 524.64、新渲染器整体动画边界 442.2、当前帧边界 437.2；旧宽度恰为当前帧宽 437.2 乘角色比例 1.2。记录 `_build/origin-atlas-renderer-compare-lowmem-465/runtime-order.log`；仍使用同名首个实例及 Neko 适配夹具，未覆盖多帧、旋转、裁剪和真实窗口，不能据单帧偏差硬编码修正。


旧 Animate 角色翻转补偿：针对历史舞台矩阵角色的轴对齐、无 skew、无旋转、未启用纹理缓存和像素取整的绘制路径，以当前帧边界、舞台实例和缩放补偿新版按整段动画边界翻转造成的偏移；现代角色和上述其他绘制路径保持原行为。以真实旧 GF 图集及历史/当前渲染依赖，在修正后的动画更新顺序下对照 7 帧、3 种缩放和 4 种翻转组合，共 84 组通过；还检查连续帧与现代、旋转、纹理缓存保护分支（`_build/origin-atlas-flip-candidate-lowmem-466/production.log`）。测试执行从正式角色类提取的实际补偿方法并比较共同名称的部件矩阵；历史/当前依赖仍含前述 Neko 夹具改动、替身相机，未覆盖真实 GPU、所有重复部件、视野裁剪和不同帧边界变化。正式角色类使用真实 flixel-animate 的隔离编译及 GF/Nene 加载替身通过（`_build/origin-atlas-stage-matrix-lowmem-460/whole-class.log`）。旋转、倾斜、像素取整与渲染纹理路径的旧式翻转仍未处理，完整原生构建及画面验收未完成。


旧角色连续帧翻转修正：真实 GF 图集第 0 帧宽 437.2、第 1 帧宽 442.2；水平翻转从第 0 帧切到第 1 帧时，上一版以当前帧宽计算，29 个共同部件全部偏离旧渲染器。现保留上一轮绘制的帧边界，下一轮翻转使用该尺寸；首次绘制才回退当前帧，非适用绘制路径清除缓存。提取正式方法、使用同一真实图集和两版渲染依赖的低负载对照中，0→1 连续帧的 29 个共同部件全部一致，84 组单帧缩放/翻转及现代、旋转、纹理缓存保护分支仍通过（`_build/origin-atlas-flip-candidate-lowmem-466/previous-production.log`）；正式角色类的隔离编译重新通过。历史/当前依赖有前述 Neko 夹具适配，使用替身相机；视野裁剪、多相机、首次初始化、像素取整、旋转/倾斜及真实 GPU 和完整原生游戏仍未验证。


旧角色连续翻转扩展检查：对真实旧 GF 图集增加 27 组相邻/跨帧切换、缩放变化以及横向、纵向、双向翻转的历史渲染矩阵对照，均通过；检查切换至现代或旋转模式时清除旧边界缓存，同一帧重复绘制 60 次未增加时间轴边界缓存条目（`_build/origin-atlas-flip-candidate-lowmem-466/cache.log`）。这是 Neko 和替身相机的有限样本，不能代表实际 CPU、内存曲线、所有模组或 GPU 画面。


第二份旧图集翻转验证：从官方 `funkin.assets` 的 0.5.0 资源提交 `bc7009b4242691faa5c4552f7ca8a2f28e8cb1d2` 取得 Nene 图集，三个文件的 Git blob SHA-1 均与上游树一致。原始图集含 8 个滤镜定义，因离屏 Neko 夹具不具备 GPU 滤镜上下文，原始运行在历史滤镜渲染器处失败；复制的测试 JSON 移除这 8 处滤镜后，使用历史和当前渲染依赖对照，84 组单帧及 27 组连续切帧/缩放/翻转均通过，首个连续帧对照含 19 个共同部件（`_build/origin-historical-nene-atlas-lowmem-467/no-filters.log`）。这是无滤镜副本，不证明原始 Nene 的滤镜、真实 GPU 或完整游戏画面兼容；正式资源文件没有被修改。


2026-11-01 Origin 上游复核：GitHub API 当前 main 为 `86cb949c74743b2bdbb58a66326acdb47a36f43a`、`preview/public-playtest` 为 `d3fdf329faa7419dbf91afd7b3204f36e010daa2`，均与已存快照一致；最新正式发布列表仍为 0.8.7 等，0.9 预览不是正式发布。对既有 0.9 公开声明差异做名称筛查，`CharacterRegistry.queryAssets` 由本地 BaseRegistry 继承并通过其角色默认查询实现；另两项 Polymod 文件导入接口属于上游 `#if js`，HTML5Video 兼容文件也是 HTML5 专用，本次未移植或验证。筛查和归属见 `_build/origin-upstream-preview-20261101/declaration-recheck-468.json`；名称存在不证明行为等价，也不代表 0.9 完整兼容。


NF `fixLNL` 类型与数值链补充：提取正式设置字段、旧值读取转换及 PlayState 长按段数公式，静态确认菜单声明为 INT、范围 0–4；低负载 Haxe 夹具验证旧 Bool false/true 分别变为 0/1、缺项保留默认 0，0–4 的整数均参与段数计算（`_build/nf-fixlnl-lowmem-469/results.log`）。存档对象和周边运行环境为替身，未验证实际存档加载、菜单操作或设备长按手感；不应将其与 `guitarHeroSustains` 的断连行为混为一项。


角色顶层舞台矩阵设置修复：角色 JSON 已有顶层 `applyStageMatrix`，但当未提供嵌套 `atlasSettings` 时，校验器原先直接使用矩阵为 false 的共享默认对象，导致显式 true 无法到达渲染器；0.8.7 与当前 0.9 预览的同一路径也如此。现仅在嵌套设置缺省且顶层字段明确给出时，以独立默认副本保留该值；已提供的嵌套设置继续优先，未指定时保留原默认值。真实 GF 数据、未裁剪 CharacterData 和项目 json2object 的低负载对照在修复前复现 false，修复后通过 true、false、嵌套优先及共享默认不变（`_build/origin-character-json-policy-lowmem-462/matrix-before.log`、`matrix-after.log`）；动画和舞台类型为替身。正式兼容回归已加入检查，完整构建、真实图集加载与屏幕画面尚未验证。


角色矩阵设置合并补充：嵌套 `atlasSettings` 仅提供 `swfMode` 等其他字段时，仍应保留顶层显式矩阵值；只有嵌套的 `applyStageMatrix` 自身明确给值才优先。现通过复制部分嵌套设置补入缺失矩阵字段，不改写原对象。此前部分嵌套夹具复现失败，修复后通过；真实 GF JSON、正式 CharacterData 和 AnimateAtlasCharacter 组合检查覆盖顶层 true/false、嵌套冲突、部分嵌套及默认值，结果见 `_build/origin-character-json-policy-lowmem-462/partial-before.log`、`partial-after.log`、`_build/origin-character-matrix-chain-lowmem-470/results.log`。图集加载和角色父类为替身，尚未验证实际画面或完整原生构建；此条细化前一条的“嵌套优先”为同名字段显式优先。


旧图集目录搬迁补充：当历史图集 `Animation.json` 已有明确的新目录映射，而模组同目录或其子目录提供表中没有逐项列出的文件时，旧文件现在沿该目录映射生成虚拟别名；已有精确映射优先，不重写模组文件。真实 Polymod 和正式旧文件系统配合合成 ZIP 测试中，修复前第二个 spritemap JSON 无法在新路径读取，修复后第二张图及 JSON、嵌套 `LIBRARY` 文件均可索引；同一模组实际新路径文件优先于其旧路径别名及前序模组，无关图集不被映射（`_build/origin-moved-atlas-multisheet-lowmem-471/before.log`、`after.log`、`precedence.log`）。测试图片是替身、未解码绘制或运行完整游戏；正式兼容检查已增加目录别名断言，但完整项目回归尚未执行。


搬迁图集别名边界补充：遍历当前兼容表全部 291 条历史 `Animation.json` 映射，分别检查普通、`_merge` 和 `_append` 下的嵌套库文件，共 873 项通过；另以真实 Polymod 和合成 ZIP，把旧路径第二张 spritemap 的 JSON Patch 应用于新路径基础数据，确认修改和未改字段均正确（`_build/origin-moved-atlas-multisheet-lowmem-471/inventory.log`、`merge-child.log`）。映射表夹具仅增加测试所需 using 导入；基础数据和补丁是替身，未覆盖完整资源缓存、图集加载或画面。


双工作区边界复核：D 盘主仓库 `main` HEAD 为 `cc13a37c`，C 盘保留工作树 HEAD 为已合并 PR #220 的 `e5a1c759`，两者基线不同，Git 未跟踪状态不能直接等同于文件缺失。近期 8 份 Origin/文档文件按换行归一化内容一致；D 的 NF `PlayState` 另引用 `GameplayVideoPause.hx`，C 盘该类及相应调用尚未同步。D 的两份上游许可证和 Tracy 工具是已跟踪文件，C 对应文件存在但在其旧基线中显示未跟踪。未覆盖、删除或强制同步任何一侧的已有文件；外部资源和 `chain.json` 未显示在两侧 Git 修改列表中，忽略文件不在该结论范围。


受限 C++ 目标检查：使用未裁剪的正式 CharacterData、AnimateAtlasCharacter 和 FlxAnimationUtil，以及角色父类、图集加载等替身，启用 Haxe `-cpp` 和 `-D no-compilation` 生成 C++ 代码，退出 0；生成文件含近期翻转缓存逻辑，三个正式文件与工作区内容一致（`_build/origin-character-matrix-chain-lowmem-470/cpp-check`）。该检查未调用 C++ 编译器，也未构建或运行游戏。随后对 Polymod 资源映射夹具执行相同目标检查，在预设的进程工作集 900 MiB 或系统可用内存 4 GiB 保护条件下被自动停止，未取得检查结果；停止后系统可用内存约 5.68 GiB。未继续重试或停止其他用户进程。


搬迁图集映射的受限 C++ 目标检查：使用未经裁剪且与工作区一致的正式 `LegacyAssetLayout.hx`，将当前表中 291 条图集元数据映射复制到轻量类型夹具，执行 Haxe 解释器及 `-cpp -D no-compilation`。873 个普通/合并/追加路径断言通过，C++ 代码生成退出 0；监测到的 Haxe 进程工作集峰值约 35 MiB（`_build/origin-atlas-mapping-cpp-lowmem-472`）。Polymod 文件系统和非图集映射为替身，未调用 C++ 编译器、未覆盖完整映射表或实际游戏；此前包含完整 Polymod 宏的 C++ 检查因资源保护停止，仍不算通过。


搬迁图集映射的原生目标检查：在上述轻量夹具生成的 C++ 上，以单编译线程、900 MiB 作业内存上限、系统可用内存不得低于 4 GiB 和 55 秒上限运行 hxcpp。首次到时停止时已进入链接；确认进程结束后利用已有中间文件完成增量编译，退出 0。生成的 Windows 原生程序运行退出 0，291 条图集元数据映射共 873 个路径检查通过（`_build/origin-atlas-mapping-cpp-lowmem-472/native-run.log`）；结束时可用内存约 5.69 GiB。该程序仍使用文件系统替身和只含图集元数据的映射表，不是完整 Polymod、完整项目构建或游戏画面验证。


角色矩阵设置的原生语义检查：以未裁剪的正式 CharacterData、项目 json2object 和真实 GF 角色 JSON 构建轻量 Windows hxcpp 夹具；单线程编译受作业内存 900 MiB、系统可用内存 4 GiB 和每次 55 秒上限约束，首次到时停止后增量链接完成。原生程序验证顶层 true/false、显式嵌套优先、部分嵌套继承、伪造内部策略字段被拒绝和默认对象不变，全部通过（`_build/origin-character-json-policy-lowmem-462/native-matrix.log`）。动画/舞台类型及其余游戏环境仍为替身，未覆盖完整角色加载或游戏构建；结束时可用内存约 5.66 GiB。


旧角色翻转的原生数值语义检查：把正式 `prepareAnimateMatrix` 和 `draw` 方法提取到轻量夹具，以先前真实 GF 图集测得的矩阵与帧边界为输入，增量单线程编译并运行 Windows hxcpp 程序；上一帧横向/纵向尺寸、空值回退和离开旧角色时缓存释放通过，角色 JSON 矩阵设置回归亦通过（`_build/origin-character-json-policy-lowmem-462/native-flip.log`）。矩阵、时间轴、相机和父类均为替身，未在该原生程序中解析或绘制真实图集，不能代替 GPU、完整游戏或带滤镜测试；结束时可用内存约 5.69 GiB。

动画数据命名与去名转换现在保留 `animType`、`renderType` 和 `atlasSettings`，避免脚本或音符样式转换时丢失符号动画及图集设置。低内存 Haxe 解释器检查使用实际 BF 角色的 symbol 动画，并为该动画补入合成的渲染类型和图集设置，验证命名、还原及数组转换；修复前失败、修复后通过及提取项目内长期回归检查的方法分别记录于 `_build/origin-animation-conversion-lowmem-473/before.log`、`after.log` 和 `permanent-check.log`；项目内检查尚未在完整工程中运行，这些结果均非完整游戏或原生运行验收。

动画转换原生语义补充：使用未裁剪的正式 AnimationData、真实 BF JSON 和合成的渲染/图集字段，及从项目内回归方法提取的检查，分别在 Windows hxcpp 轻量夹具运行通过（`_build/origin-animation-conversion-lowmem-473/native-real.log`、`native-check.log`）。编译使用单线程、作业内存 900 MiB、系统可用内存不低于 4 GiB 和每次 55 秒上限；夹具的 StageData 与数组扩展是替身，不代表完整游戏或图集画面验收。

多 Animate 图集符号动画补充：单图集角色已有缺失帧标签时按符号回退，多图集角色此前缺少该处理。现仅对 Animate 子动画且标签不存在或帧数为零时，在合并图集中查到同名符号后回退；Sparrow、有效标签、显式 symbol 和找不到的符号保持原处理。离屏 Neko 夹具将两份真实旧 GF 图集合并，真实 flixel-animate 中原帧标签得到零帧，提取正式回退后同名符号为 30 帧，并检查有效动画保留、指定帧和不存在符号（`_build/origin-multianimate-symbol-lowmem-474/before.log`、`after.log`）。两份图集使用相同素材模拟合并，Neko 依赖使用此前夹具适配，未验证完整角色类、真实多图集模组、GPU 画面或原生游戏。

多图集符号回退的正式类检查：未裁剪的 MultiAnimateAtlasCharacter 与 FlxAnimationUtil 在 Neko 夹具中通过 onCreate 加载并合并实际 GF 主图集与实际 Nene 副图集；Nene 的 symbol 标签修复前为零帧、修复后注册为 30 帧（`_build/origin-multianimate-character-lowmem-475/before.log`、`distinct.log`）。为适应离屏运行，Nene 使用移除滤镜的副本，资源路径、角色基类和部分数据类型为替身；不代表原始滤镜、GPU、完整游戏或真实多图集模组已验证。

多图集资源释放待处理：MultiAnimateAtlasCharacter 对主 Animate 图集及 Animate 子图集设置 `destroyOnNoUse=false`，但其销毁循环只记录 Sparrow 子图集；MultiSparrowCharacter 的 Animate 子图集也未加入销毁列表。使用正式 MultiAnimateAtlasCharacter、GF/Nene 图集与角色/资源路径替身，观察到角色销毁后两份 Animate 图集的自动释放标志仍为 false（`_build/origin-multianimate-character-lowmem-475/leak.log`）。当前 FlxGraphic 在把标志设回 true 时立即检查引用计数；合并图集可共享资源，直接恢复可能提前销毁仍被其他角色使用的图集。该隔离结果不证明实际游戏的内存持续增长，需进一步厘清缓存所有权、并发角色和退出顺序后修复，未修改资源释放逻辑。

多图集共享引用实证：在使用真实 flixel-animate 缓存的隔离夹具中，两个正式 MultiAnimateAtlasCharacter 复用同一 GF 主图集与 Nene 副图集；主图集的附加集合由 1 增至 2，副图集 parent 的 useCount 仍为 0，销毁第一个角色后第二个仍需它。此时直接将副图集 `destroyOnNoUse` 设为 true 会立即销毁其 parent 和符号字典，即使第二个角色尚存活（`_build/origin-multianimate-character-lowmem-475/shared.log`、`release.log`）。因此补写销毁列表不足以安全修复；还需解决合并操作修改共享缓存、同一子集合重复添加，以及跨角色和其他使用方的所有权。夹具使用去滤镜的 Nene 副本和替身路径，不证明实际游戏的内存增长速度；本次未改资源释放行为。

多 Animate 图集重复合并修正：相同缓存主图集再次加载相同 Animate 子图集时，flixel-animate 会重复追加同一个集合；现跳过已追加的同一对象以及主图集自身，不跳过不同子图集。使用正式角色类、真实 GF/Nene 图集及真实 flixel-animate 的离屏共享夹具，修改前附加集合由 1 增至 2，修改后两个角色共享时保持 1；不同子图集仍可加入，销毁一个角色后另一个仍有动画（`_build/origin-multianimate-character-lowmem-475/shared.log`、`dedupe.log`）。测试使用去滤镜 Nene 副本与替身资源路径；此修改依赖当前 flixel-animate 的内部集合字段，未解决不同子图集留在共享主图集、共享资源所有权或自动释放，也未进行完整游戏/GPU 验证。

多图集共享缓存的动画冲突实证：两个不同缓存键的 Nene 图集包含同名 `nene cs idle` 符号；三个正式 MultiAnimateAtlasCharacter 共享 GF 主图集时，第三个角色虽请求第二份 Nene 图集，实际动画时间轴却来自前一个角色的图集（`_build/origin-multianimate-character-lowmem-475/collision.log`）。因此前述去重只限制相同对象反复追加，并未实现图集隔离；真实不同内容的同名符号可能显示错误动画。测试使用相同 Nene 去滤镜副本产生两个不同实例与替身路径，未覆盖实际第三方模组、GPU 或释放顺序；还需在不破坏共享纹理和缓存的前提下隔离每个角色的合并结果。

多图集隔离原型：隔离夹具让每个角色的主 Animate 图集采用独立缓存键，同时保留副图集共享；相同符号的角色选择到了自己请求的图集（`_build/origin-multianimate-isolation-lowmem-476/results.log`）。但进一步让图集加载使用同一底层 BitmapData 后，两个隔离主图集仍共享同一 FlxGraphic；释放第一个主图集会让第二个角色持有的图像被销毁（`release.log`）。因此该原型未接入生产，不能只靠独立缓存键解决共享图像所有权；图像引用、内存回收和不同渲染器的共同所有权仍需设计及验证。该结果来自 Neko、真实图集与替身路径，不代表真实游戏已复现崩溃。

多 Animate 图集动画来源修正：角色加载时记录每个指定 assetPath 对应的 Animate 图集，动画优先从该图集选择帧标签或符号时间轴，避免共享主图集中其他角色同名符号抢先匹配；找不到时保留原有通用加载/回退。基于真实 GF/Nene 图集和真实 flixel-animate 的正式类隔离测试验证同名符号选中正确子图集，以及显式 symbol、索引和帧标签路径（`_build/origin-multianimate-targeted-lowmem-477/results.log`）；Nene 为去滤镜副本，资源路径和角色基类为替身。该修复只处理有明确 assetPath 的 Animate 动画来源，不解决共享主图集本身的缓存污染、底层图集释放或完整游戏画面。

混合 Sparrow/Animate 角色动画来源修正：真实 flixel-animate 夹具先复现 MultiSparrowCharacter 在多个子图集有同名符号时误选先前图集；现与 MultiAnimateAtlasCharacter 共用来源选择辅助方法，按动画 assetPath 优先选择对应 Animate 帧标签/符号并保留原回退。隔离检查中混合角色选择正确符号，原多 Animate 的显式符号、索引和帧标签通过；真实 AlienBF Sparrow 数据的 25 个动画及四个长按末帧仍通过（`_build/origin-multisparrow-mixed-lowmem-478/before.log`、`refactor.log`、`multi-animate.log`、`alien.log`）。测试采用去滤镜 Nene 副本、替身路径与基类；未覆盖完整游戏、GPU 或共享资源释放。

多 Sparrow 同名帧待处理：使用正式 MultiSparrowCharacter、真实 AlienBF 图集复制出的两个不同图集实例，合成角色分别在主图集和副图集配置相同前缀；虽然副动画明确指定副图集，合并后选中的帧仍属于主图集（`_build/origin-sparrow-collision-lowmem-479/results.log`）。当前 Flixel 合并按名称去重，不能直接沿用 Animate 的独立时间轴方案；需要保留每个来源的帧索引并避免改坏共享缓存或图集销毁。两张测试图片内容相同，故该试验只证明帧对象归属错误，不代表已观察到真实模组画面错误；未修改此逻辑。

纯 Sparrow 多图集同名帧修正：不含 Animate 子图集的 MultiSparrowCharacter 使用独立合并帧集合，并以动画的 assetPath 从对应图集取得实际帧，再映射到角色自己的帧索引；未指定 assetPath 优先主图集，找不到时保留通用回退。销毁独立集合前清空借用帧引用，避免直接销毁源帧。真实 AlienBF 图集双实例同名冲突从错误主图集变为正确副图集，两个角色共享图集时销毁一个后另一个仍可访问（`_build/origin-sparrow-collision-lowmem-479/results.log`、`_build/origin-sparrow-sourced-lowmem-480/shared.log`）；25 个 AlienBF 动画与四个长按帧及混合图集原有路径也通过隔离检查（`alien.log`、`mixed.log`）。Flixel 为实际依赖，路径与角色基类为替身，测试没有窗口或 GPU；混合 Animate/Sparrow 图集的 Sparrow 同名帧与共享图集释放尚未解决。

混合 Animate/Sparrow 图集隔离原型：以借用源图集时间轴和图片、独立持有帧列表的夹具验证同名 Sparrow 帧来源、Animate 符号、离屏绘制及两个共享角色先后销毁（`_build/origin-mixed-isolated-lowmem-481/survivor.log`、`symbol.log`）。原型直接访问 flixel-animate 内部缓存、图集集合及 Flixel 动画表，尚需审查更多生命周期、不同加载顺序、原生目标和真实模组；目前未接入生产代码。带 900 MiB 作业内存上限与 4 GiB 系统可用内存保护的 C++ 代码生成触发后者而停止，未取得结果；停止后未重试，也未终止其他程序。Neko 绘制使用替身相机与经过适配的依赖，不代表 GPU 画面或共享图集的完整释放安全。

混合图集原型边界补充：源码审查发现，若动画声明了 Animate 类型但所有 Animate 子图集加载失败，按声明选择混合实现会对空图集解引用；原型现改为按实际成功加载的图集选择实现。另在借用集合销毁前再次避开实际缓存键，以降低误删缓存的风险。这两处仅修改 `_build/origin-mixed-isolated-lowmem-481` 下的原型，因可用内存不足未重新编译或验证，也未接入生产。

Sparrow 缺失 Animate 边界待验证：当前 MultiSparrowCharacter 根据动画声明而非成功加载结果选择纯 Sparrow 的独立帧列表；若所有 Animate 子图集都缺失，主图集仍可保留，但新加的 Sparrow 同名帧隔离不会启用。已准备正式类与真实 AlienBF 图集的复现夹具 `_build/origin-missing-animate-lowmem-482`；单线程、600 MiB 作业内存及 4 GiB 系统可用内存保护的 Neko 编译也触发系统内存保护并自动停止，没有得到可执行结果。尚未修改正式逻辑，也没有声称该场景已运行复现。

Sparrow 缺失 Animate 边界源码修正：MultiSparrowCharacter 现根据实际成功加载的图集类型选择合并方式，所有 Animate 子图集失败时仍可采用纯 Sparrow 独立帧集合；原先用于是否预缓存图片的声明判断保留。两个工作区已同步、差异格式检查通过；因内存余量不足，`_build/origin-missing-animate-lowmem-482` 的实际类/资源夹具尚未成功编译运行，不能声称该场景已实测通过。

FNFC 试奏菜单的编辑器鼠标接管：该独立调试菜单此前显示 Origin 指针却未抑制 NF 鼠标特效，也未在进入试奏和返回后切换指针。现桌面鼠标分支进入时接管并抑制 NF 特效、启动试奏后隐藏指针、子状态关闭后恢复编辑器指针、状态销毁时释放接管；触屏分支保持原行为。已对照进入/退出代码和 FNFC 试奏使用子状态的调用链，两个工作区同步并通过差异格式检查；受内存保护限制，尚未进行完整构建或真实窗口验收。

FNFC 试奏菜单指针低负载检查：从正式菜单提取进入、启动试奏及异常、子状态返回和销毁语句，使用 Cursor、MouseEffect、加载器与状态替身运行 Haxe 解释器；桌面分支的接管、加载失败保留指针、成功隐藏、返回恢复和退出释放，以及无桌面鼠标分支不改变状态均通过（`_build/origin-fnfc-cursor-lowmem-483/desktop.log`、`touch.log`）。未运行完整菜单、真实 HaxeUI/Flixel 事件或窗口，不能代替完整游戏验收。

NF 长按断连回放时间源复核：D 盘主仓库的 PlayState 更新中只有非回放模式调用 keysCheck，使用 Conductor.songPosition；回放模式的 Replay.handleInput 将记录的 frame.time 传入 replayApplyInput，后者在处理按键前按该帧时间检查过期长按。源码核对没有发现两种时间源在上述调用路径混用；之前隔离回归覆盖断连后回放输入不得重接，但此处没有重新运行完整回放、设备或游戏窗口。

当前工具链只读复核：D 盘主仓库选择的 hxcpp 分别通过 `tools/setup-hxcpp-callback-handoff.ps1 -VerifyOnly` 和 `tools/setup-hxcpp-tracy-on-demand.ps1 -VerifyOnly`；完整文件哈希匹配已安装的回调线程交接修补和 Tracy 按需连接修补。此检查只确认选中源码字节，未重新编译当前游戏，也不证明运行时或原始崩溃的唯一原因。

多图集同名动画样本筛查：只读解析隔离测试目录 `mods-vslice/*/data/characters/*.json` 中 37 份角色 JSON，按配置中的完全相同 prefix 检查其是否指向不同 assetPath，没有发现命中。此筛查未展开实际图集帧名、不同 prefix 的重叠、跨模组覆盖或其他角色目录，不能排除真实模组发生前述冲突；合成配置与真实图集的复现仍有效。

真实 Sparrow 图集帧名筛查：只读解析隔离目录中 25 份 MultiSparrow 角色配置及模组本身 `shared/images` 下可找到的 XML；Azzy’s BF Reskin & Others 的 bf-car、bf-christmas 和 bf 配置中发现 26 组动画／其他图集同名帧（如 bf-car 的 `bf idle0000` 同时存在于 bfCar 与 BOYFRIEND）。全部命中请求的是各自的主图集，原合并顺序也优先主图集，不能据此认定旧代码在这些动画中显示错误；该样本说明真实资源存在同名帧。另有 4 项 marker 测试数据找不到本地 XML。完整结果为 `_build/origin-real-sparrow-frame-collisions-484.json`；未解析跨模组覆盖、外部资源或真实画面。

Sparrow 副图集绘制路径静态核对：当前 Flixel 在设置 sprite.frame 时复制原帧 parent；tile 模式的 FlxCamera.drawPixels/copyPixels 按该帧 parent 选择批次，blit 模式的 FlxFrame.paint 从该 parent.bitmap 取像素。因此，独立帧列表中保留副图集帧对象符合两种路径的源码数据流，而不是强制使用角色主 graphic；这是源码检查，未验证 GPU、遮罩、shader 或实际窗口画面。

纯 Sparrow 临时集合销毁保护：FlxGraphic.destroy 会销毁登记在图片上的全部帧集合；此前只有角色自身 destroy 路径先清空借用帧，若图片被其他缓存清理入口提前销毁，临时集合可能误销毁其他源图集帧，后续角色销毁也可能再次访问已清空数组。现由临时集合自身覆盖 destroy，任何入口均先解除借用并防止重复销毁。该边界依据当前 Flixel 源码静态分析；提取正式临时集合类与父类/图集替身的轻量解释器检查通过借用帧保留和重复销毁（`_build/origin-borrowed-sparrow-lowmem-485/results.log`）。两个工作区已同步；真实 Flixel 缓存清理、完整工程及原生目标尚未验证。

真实多 Sparrow 模组回归夹具已准备：`_build/origin-real-azzy-sparrow-lowmem-486` 使用 Azzy’s BF Reskin & Others 的原始 bf-car/bf-christmas JSON 和各自 PNG/XML，计划检查 idle、hey、hurt 的帧归属及两个角色共用 BOYFRIEND 图集时的销毁顺序。夹具中的角色基类和路径包装为替身；因可用内存接近保护阈值，本次没有编译或运行，不能记为通过，也不能代替游戏窗口验收。

混合图集原型重复销毁边界：借用的 Animate 集合同时由角色和主图片的集合列表持有，缓存提前销毁和角色销毁可能先后调用其 destroy。原型加入释放标志及字段空值保护，避免第二次销毁时访问已清空数组；本次仅作源码修改，未重新编译运行，正式工程未接入该原型。

双工作区依赖复核：近期两个多图集角色、动画工具/数据、FNFC 试奏菜单与本文档在 D 主仓库和 C 保留工作树的内容哈希一致；两侧均保留 609 项 Git 修改/未跟踪记录。D 仓库的 haxelib 当前解析到项目内 flixel-animate 1.5.0，C 保留工作树单独执行同一查询时报告该库未安装，且当前没有自身 `.haxelib`；因此 C 侧不能仅凭源码一致就认定可独立构建。未安装、链接或覆盖任何依赖，D 仍为实际验证目标。

Sparrow 缓存提前清理回归已准备：`_build/origin-sparrow-purge-lowmem-487` 使用当前正式多图集角色类、真实 Flixel 与 AlienBF 图集，准备强制移除主图集后检查借用的副图集帧是否仍有效，并继续销毁角色。同时准备旧实现对照 `_build/origin-sparrow-purge-before-lowmem-488`，以确认测试能识别原边界。路径和角色基类为替身；当前可用内存接近 4 GiB，两个夹具均未编译或运行，尚不能把该测试列为通过。

编辑器指针释放修正：HaxeUI 加载控件指针时会将 Cursor 模式缓存置空，之前退出编辑器时 setter 看到已为空而跳过卸载，可能把编辑器图案留给随后显示鼠标的 NF 界面。现仅在编辑器仍持有指针、且模式已为空时显式卸载；未接管时的外部鼠标图案不受重复 hide 影响。正式 Cursor 源码配合 HaxeUI/Flixel 替身的轻量解释器检查在修复前复现残留，修复后验证卸载、外部图案保护、控件指针和无 HaxeUI 分支（`_build/origin-cursor-release-lowmem-489/before.log`、`after.log`、`no-haxeui.log`）。真实窗口及完整原生构建尚未验证。

编辑器前后系统鼠标模式：进入编辑器需要将 useSystemCursor 关闭以显示编辑器图案，之前退出时未恢复进入前的设置。现首次接管时记录模式，重复 show 不覆盖原值；释放时恢复原模式，并再次保持 visible=false，因为当前 Flixel 设置系统鼠标模式可能直接显示系统指针。提取正式 Cursor 配合模拟该 Flixel 副作用的轻量夹具，修复前复现模式未恢复，修复后覆盖重复 show、隐藏状态、恢复显示及无 HaxeUI 分支（`_build/origin-cursor-system-lowmem-490/before.log`、`after.log`、`no-haxeui.log`）；实际 OS 指针和完整窗口尚未验证。

0.9 预览数据注册表版本常量复核：从固定预览快照 d3fdf329 与当前 Origin 源码中提取两边均存在的 data 注册表版本/版本规则字符串，共 13 个文件、29 个字面量均一致；逐项记录见 `_build/origin-preview-registry-version-audit-491.json`。这只核对声明，不验证版本迁移、数据字段或实际模组加载，也不覆盖计算得出的常量。

0.9 预览数据类公开名称筛查：固定预览快照 d3fdf329 中 18 份与当前工程同路径的 `funkin/data/**/*Data.hx`，按词法提取 public function/var 名称后，没有发现本地完全不存在的名称（`_build/origin-preview-data-public-names-492.json`）。这是名称级筛查，不区分同名不同类，不检查类型、参数、条件编译或行为，不能据此声称数据类兼容；预览快照也不代表实时上游。

2026-11-02 Origin 上游只读复核：GitHub 的 [main](https://github.com/FunkinCrew/Funkin/commit/86cb949c74743b2bdbb58a66326acdb47a36f43a) 仍为 `86cb949c74743b2bdbb58a66326acdb47a36f43a`，[preview/public-playtest](https://github.com/FunkinCrew/Funkin/commit/d3fdf329faa7419dbf91afd7b3204f36e010daa2) 仍为 `d3fdf329faa7419dbf91afd7b3204f36e010daa2`，均与前次记录一致；最近的 [发布列表](https://github.com/FunkinCrew/Funkin/releases) 仍包含 v0.8.7 正式版。此次仅查询分支和发布列表，没有修改本地源码，也不能代表其他分支或上游资源仓库未变化。

0.9 预览数据方法签名筛查：18 个同路径 Data.hx 的公开方法按名称词法比对，仅筛出 SongEventDataRaw 的 getStepTime 与 valueAsStruct 两类签名差异。前者本地用 Dynamic 同时接纳旧版首参数 Bool 和新版 Conductor，并对其他类型报错；后者增加可选旧键覆盖，无参仍优先事件 schema。细节见 `_build/origin-preview-data-signatures-493.json`；此筛查不按所属类严格匹配，不验证全部类型、条件编译和 HScript 分发，不代表完整签名兼容。

歌曲事件双签名轻量检查：提取正式 getStepTime 与 valueAsStruct 方法，配合 Conductor/schema 替身检查默认时间、缓存、显式 conductor 与强制刷新、旧 Bool 首参、null 和非法参数，以及 schema 键、旧键、缺 schema、空值和对象身份，解释器均通过（`_build/origin-event-signatures-lowmem-494/results.log`）。此检查不包含真实 Conductor、完整注册表、HScript 调用或原生目标。

歌曲事件反射调用补充：在提取正式事件方法的轻量夹具中，以 Haxe 反射调用旧式 getStepTime(true)、新版 getStepTime(conductor, true) 和无参 valueAsStruct，结果通过（`_build/origin-event-reflection-lowmem-495/results.log`）。此处是 Haxe 解释器反射与 Conductor/schema 替身，不代表 Polymod HScript 或 hxcpp 的实际分发验收。

歌曲事件旧构建脚本证据补充：构建 273 的基础回归通过真实 Polymod 脚本分别以 API 0.8.0 和 0.9.0 直接调用及保存后调用 valueAsStruct，验证旧 `key` 与现代 schema 键的区别；同日志达到全部基础检查通过（`_build/origin-history-batch-foundation-273.log`）。这补充前述轻量反射检查，证据属于旧构建；getStepTime 的真实 HScript 调用及当前源码完整构建仍未由此证明。

歌曲事件时间脚本正式回归已补充：现有真实 Polymod 的 API 0.8.0/0.9.0 夹具在内存中追加测试方法，分别通过旧 Bool 首参或新版 conductor 参数直接调用和保存后调用 getStepTime，并与独立 Conductor 的结果比较；测试先要求该实例的步数与全局实例不同，以便识别忽略参数的错误，不改测试模组文件。当前只完成源码接入和差异格式检查，内存余量不足以安全执行完整工程，新增断言尚未编译或运行。

同路径多类型子图集：MultiSparrow 和 MultiAnimate 原先仅以 assetPath 去重，同名 Sparrow 图片与 Animate 目录同时声明时，先加载者会使另一种类型被跳过；现按渲染类型与路径共同去重，重复的同类型路径仍只加载一次。低内存 Haxe 解释器提取两处正式去重语句，验证同路径两种类型各保留一次（`_build/origin-atlas-type-dedup-lowmem-496/Main.hx`）。该检查未读取图集或验证混合渲染、共享资源生命周期和完整构建；其他混合图集问题仍未解决。

同路径多类型的加载流程补充：以两处正式加载方法为主体、路径及图集为轻量替身，验证 Sparrow 与 Animate 两种声明顺序各调用一次相应加载器，且首次 Sparrow 加载失败后后续同类型声明仍会重试（`_build/origin-atlas-loader-types-lowmem-497/Main.hx`）。同一夹具恢复旧的仅按路径去重后，第二种类型的加载次数为零，检查按预期失败（`_build/origin-atlas-loader-types-before-lowmem-497/Main.hx`）。这是加载分发测试，不证明真实图集帧绑定、绘制或释放正确。

Flixel 图形清理风险（2026-11-02）：D 仓库当前锁定的 Flixel `4a45067` 中，`FlxGraphic.getFramesCollections` 新建集合时写入 map，但未向 `frameCollectionTypes` 登记类型；`destroy` 又只遍历该列表。提取这两处正式逻辑及登记方法，用轻量替身登记 atlas、tile 两类集合并销毁图形，两类均未收到销毁调用（`_build/origin-flxgraphic-collection-before-lowmem-498/Main.hx`）。隔离候选在新建类型时将其加入列表，同一检查通过（`_build/origin-flxgraphic-collection-candidate-lowmem-498/Main.hx`）。这证明了调用遗漏，不证明实际内存泄漏规模；改变销毁顺序可能暴露现有混合图集对共享帧的所有权问题。候选尚未应用于 Flixel 或项目，需先用真实依赖覆盖共享图集、强制清理及后续再次释放，再考虑可复现的依赖补丁。

谱面编辑器 HaxeUI 鼠标接管补充：原 `handleCursor` 每帧在 UI 控件上也将 Cursor 设为默认值，可能覆盖 HaxeUI 刚加载的指针、文本等样式；现在没有活动手势时，悬停 UI 由 HaxeUI 保留样式，离开 UI 后恢复编辑器默认样式，拖动等明确指定的编辑器模式仍优先。低内存对照使用提取的最终分发语句和 Cursor 替身：旧逻辑在 UI 悬停检查失败，新逻辑覆盖悬停、离开及手势三种情况通过（`_build/origin-chart-cursor-before-lowmem-499/Main.hx`、`_build/origin-chart-cursor-after-lowmem-499/Main.hx`）。未验证真实 HaxeUI 事件时序、系统鼠标显示或可见编辑器窗口。

谱面标记遮挡补充：`overlapsRenderedPins` 之前不检查上层 HaxeUI，控件下方存在标记时仍会指定 Pointer，绕过前述控件样式保护。现仅在鼠标不处于实体 HaxeUI 控件上时采用标记的 Pointer；拖动状态仍保持自身光标。提取条件及最后分发逻辑配 Cursor 替身的低内存对照，在 UI 覆盖标记时旧逻辑失败，新逻辑对被遮挡标记、可见标记、拖动和默认光标通过（`_build/origin-chart-cursor-pins-before-lowmem-500/Main.hx`、`_build/origin-chart-cursor-pins-after-lowmem-500/Main.hx`）。控件命中、实际画面和鼠标事件仍需真实窗口验收。

0.9 预览 gameplay 接口筛查与补充：对固定快照 d3fdf329 中 54 个本地同路径 play 文件按词法检查公开方法及字段，初步筛出 10 文件存在名称差异（`_build/origin-preview-play-public-names-501.json`）；名称匹配不区分所属类、条件编译、重载与 HScript 桥，不能当作完整 API 审计。经核对，补充 DialogueBox 的公开 text、capturePosition、restorePosition，按上游维护替换和追加文本的可读值，同时保留现有即时打字处理；也补充 PlayState.resolveStickerPackId 的谱面覆盖、角色及默认回退。提取正式方法、配合文本控件或角色注册表替身的解释器检查分别通过位置副本/偏移恢复、空文本、追加与即时打字，以及贴纸包选择（`_build/origin-dialogue-preview-api-lowmem-502/Main.hx`、`_build/origin-play-sticker-api-lowmem-503/Main.hx`）。未实际运行 0.9 HScript、游戏窗口或完整构建；筛查中的角色 queryAssets 另有兼容桥，不应简单按缺少同名方法判定失败，其他差异尚待逐项核实。

对话框速度状态补充：预览 1.1 数据调用 setPreviewTypingSpeed 后，公开 speed 现返回当前倍率；速度可在文本控件创建之前设置并在创建时应用。旧脚本直接写 speed 仍按原来的延迟系数解释；零或负值使用正的内部延迟并在非空文本开始后跳过，避免底层除零。无论通过 text 属性还是 setText 开始打字，即时模式均只跳过一次，空文本不跳过。提取正式方法与替身的解释器检查覆盖新旧速度、控件创建前赋值和即时模式（`_build/origin-dialogue-speed-lowmem-504/Main.hx`）。注意：0.9 上游脚本直接写 speed 的倍率语义与旧版的延迟语义仍有差异，目前尚未按脚本来源分流；此检查未运行真实 FlxTypeText、HScript 或完整构建。

对话框真实脚本回归准备：现有 API 0.8.0/0.9.0 来源的 Polymod 夹具新增对 DialogueBox.text 的脚本写入和读取断言；空实例不加载图形或更改模组资源。该断言仅接入正式兼容检查，尚未编译或运行。审查当前选用的 Polymod 发现原生对象写入和已附脚本的对象/代理写入经不同路径；为确保不绕过黑名单或脚本自定义 setter，0.9 speed 倍率差异尚未简单接入仅覆盖原生字段的桥，仍需同时覆盖两条路径并进行真实 HScript 验证。

对话框 speed 版本分流：对已识别为 API 0.9 的脚本，赋值、复合赋值或自增 speed 时，在原解释器赋值流程外设置临时版本上下文；DialogueBox 原生 setter 在该上下文采用预览倍率，旧版本和无法识别来源继续使用历史延迟系数。原有字段访问检查、脚本代理和自定义 setter 仍走原解释器路径；非 speed 赋值不分配作用域闭包，异常及嵌套调用恢复上下文。使用实际构建宏、实际 DialogueBox 速度方法和简化解释器替身进行低内存检查，覆盖显式/隐式赋值、复合赋值、自增、限制写入、嵌套及异常（`_build/origin-dialogue-speed-macro-lowmem-505/Main.hx`）。正式 0.8/0.9 Polymod 回归亦加入 speed 赋值与复合赋值断言，但尚未编译或运行；替身不能证明真实脚本分派、全部语法、原生目标和线程安全已通过。

对话空行重入修正：真实 FunkinTypeText.start 对空文本同步调用完成回调，可能立即将下一行写入同一对话框。此前公开 text setter 在回调后读取已变化的 _text 来决定是否跳过，会额外跳过下一行；现于 start 前依据本行文本确定是否跳过。提取正式 setter，用会同步推进下一行的文本控件替身进行对照，旧实现对下一行调用两次 skip，新实现仅调用一次（`_build/origin-dialogue-empty-callback-before-lowmem-506/Main.hx`、`_build/origin-dialogue-empty-callback-after-lowmem-506/Main.hx`）。真实对话、音频和 HScript 仍未运行。

速度分流作用域收窄：复合赋值会先执行右侧表达式，旧分流原型在整个表达式求值期间启用 0.9 标记，可能影响右侧调用中对其他对话框的原生写入。现仅在解释器执行实际 setter、setVar 或脚本 setter 调用期间启用版本上下文，右侧求值仍保持原有上下文。基于正式宏及正式 DialogueBox 速度方法的简化解释器夹具，先复现右侧其他对象被误按 0.9 倍率处理，修改后验证目标仍按 0.9 倍率、右侧原生写入仍按旧默认处理，并保留版本切换、复合、自增、嵌套、异常及受限写入检查（`_build/origin-dialogue-speed-macro-lowmem-505/Main.hx`）。夹具使用简化解释器；实际 Polymod 和游戏运行仍待验证。

Polymod 赋值宏的真实源码结构核查：从 D 仓库当前选中的 Polymod `origin-4740cb234311` 提取真实 assignValue、evalAssignOp、increment、set 函数，交给项目实际构建宏做语法树改写，分别得到 1、3、5 个速度作用域，并通过宏的原字段检查计数（`_build/origin-polymod-real-ast-lowmem-507/InspectMacro.hx`）。为了在低内存运行，检查器丢弃改写后的函数体，且宏副本仅去掉入口的 macro 关键字以便由检查器直接调用；这证明宏能遍历当前真实源码结构，不证明完整类型检查、Polymod 执行或原生编译。

速度分流左侧求值补充：普通属性赋值也可能在确定目标对象时执行代码；先前只收窄了复合赋值的作用域，普通赋值仍可能影响目标表达式内对其他对话框的原生写入。现对普通赋值、复合赋值和自增统一只包裹实际写入，并先求值写入参数；简化解释器夹具先复现该影响，修改后连同前述右侧求值、版本分流、嵌套和异常检查通过（`_build/origin-dialogue-speed-macro-lowmem-505/Main.hx`）。当前宏对真实 Polymod 函数的语法树改写分别发现 8、3、5 个写入点（`_build/origin-polymod-real-ast-lowmem-507/InspectMacro.hx`）；前述 1、3、5 为修改前的结构。真实 Polymod 类型检查、脚本执行和完整构建尚未完成。

对话框重复创建资源清理：参考固定 Origin 0.9 预览 d3fdf329，重建时先移除、kill 并销毁旧箱体精灵和旧文本控件，重置旧动画偏移后再创建新对象；已有文本音效仍由现有 setTypingSounds 负责替换释放。提取正式清理语句与精灵替身的解释器检查覆盖首次创建、再次创建、旧对象移除及销毁、偏移重置（`_build/origin-dialogue-recreate-lowmem-508/Main.hx`）。未实际执行 Flixel、声音或游戏对话流程，不能据此量化内存变化或证明完整生命周期。

0.9 gameplay 公开方法签名筛查：固定 d3fdf329 快照中与本地同路径的 54 个 play 文件按名称词法比较，得到 34 处可能差异（`_build/origin-preview-play-signature-audit-509.json`）；部分只是完整类型名、可选参数或不同类同名方法，不能直接认定为不兼容。已重点核对 NoteStyle 的 9 个音符、长条、判定、连击、倒计时路径方法：0.9 返回 AssetPath 对象，检查文件不存在则返回 null，而当前原生方法返回 String；其中 8 个使用 png、倒计时声音使用音频扩展，含库前缀和长条方向回退细节（`_build/origin-notestyle-preview-path-gap-510.json`）。0.9 脚本对返回值调用 exists 等方法可能失败，该差异尚未修复或通过真实脚本验证；需同时保留旧模组字符串结果、直接调用与保存方法后的访问检查。

0.9 NoteStyle 路径桥：对已识别的 0.9 脚本，在解释器直接调用和保存方法后调用时，将九个旧字符串路径方法的结果适配为 0.9 AssetPath，按预览版本处理库前缀、去扩展名、png/音频扩展与不存在返回 null；旧版及未知来源仍返回原生字符串。保存的方法再次检查类/脚本字段黑名单。对长按特效，0.9 自身方向资源缺失后按自身根、父样式根递归回退；保留旧接口原有的父样式方向回退。提取正式路径解析和桥函数，配合资源、NoteStyle 和权限替身，解释器检查覆盖九种名称、库、扩展、缺失、0.8/0.9/未知来源、代理、保存方法及后加黑名单（`_build/origin-notestyle-path-lowmem-511/Main.hx`、`_build/origin-notestyle-bridge-lowmem-512/Main.hx`、`_build/origin-notestyle-hold-fallback-lowmem-513/Main.hx`）。正式 0.8/0.9 HScript 夹具新增真实默认音符样式直接/保存调用断言，但尚未编译运行；未验证真实资源库、实际模组、原生构建或所有脚本代理形态。

NoteStyle 路径桥真实数据及重写边界：读取 Alien Hominid 0.5 原始 hominid.json，使用正式路径方法和资源适配函数、轻量文件路径替身，确认 note、strumline、hold 和倒计时声音对应的四个实际模组文件存在，旧 note 路径仍为字符串（`_build/origin-notestyle-real-mod-lowmem-514/Main.hx`）。进一步审查发现适配器二次调用公开路径方法可能再次触发模组脚本重写；现直接读取样式数据并按预览规则访问 fallback，不再次调用公开方法。提取正式解析器的轻量检查覆盖九种路径、缺字段回退、文件缺失不回退及避免重复调用（`_build/origin-notestyle-data-lowmem-515/Main.hx`）。真实文件存在性检查使用简单路径替身，不代表 Flixel 纹理加载；脚本重写返回自定义路径、真实 Polymod、原生构建及其他模组仍未验收。

NoteStyle 脚本重写路径补充：适配桥检查 Polymod 的实际重写及 super 跳过列表；脚本重写返回 String 时按其返回的自定义路径构造 AssetPath，返回现成 AssetPath 时保持原值，避免误替换成 JSON 默认路径。无重写或调用 super 时沿用数据解析，不重复调用公开方法。使用正式桥和解析方法配合 Polymod/资源替身，覆盖自定义库路径、super 跳过列表、旧版与未知来源、代理和保存方法权限检查（`_build/origin-notestyle-data-lowmem-515/Main.hx`、`_build/origin-notestyle-bridge-lowmem-512/Main.hx`）；真实 Polymod 重写调用、完整资源解析、native 构建与可见游戏尚未验证。

NoteStyle super 调用上下文补充：Polymod 的 scriptCallSuper 在返回前会移除跳过脚本重写的标记，导致仅在结果返回后检查时可能把父类的旧字符串当作重写路径。解释器宏现在在调用前识别实际原生 super 调用并传给适配桥，其他调用仍按真实脚本重写判断。真实项目构建宏和正式适配函数配简化解释器/Polymod 对象，模拟 super 返回前清除标记，仍能选择样式数据（`_build/origin-notestyle-super-macro-lowmem-516/Main.hx`）；另用提取自实际 Polymod 的 findScript/findOverride 配替身覆盖继承重写和 skip 列表（`_build/origin-notestyle-bridge-lowmem-512/Main.hx`）。这不是实际 Polymod 或原生目标运行；保存 super 方法、真实资源及完整构建仍待验证。

NoteStyle 保存的 super 方法补充：解释器读取方法时记录是否来自原生 super；保存方法稍后调用时，临时添加 Polymod 的跳过重写标记，调用完毕或抛错后移除，并按 0.9 数据路径适配结果，保留调用前后的黑名单检查。实际项目的 fcall/get 构建宏与正式桥配轻量解释器及脚本对象替身，覆盖直接 super、保存后调用和异常恢复（`_build/origin-notestyle-super-macro-lowmem-516/Main.hx`）；底层 Polymod 继承查找仍使用提取的实际 findScript/findOverride。此检查未运行真实 HScript、真实黑名单变更、native 目标或完整游戏。

NoteStyle 批量真实脚本回归准备：正式 0.8/0.9 Polymod 回归现在为九个路径方法各生成直接调用和保存后调用，共 18 个脚本探针，并对照原生旧字符串或预览 AssetPath。提取正式探针生成代码的低内存检查确认全部名称及参数生成正确，并用当前 Polymod 的真实 Parser/Expr 解析生成脚本（`_build/origin-notestyle-fixture-builder-lowmem-517/Main.hx`、`ParseMain.hx`）；两个非解析器类型为替身。此处只证明脚本语法可解析，真实解释器、资源和完整构建尚未运行。

保存的 NoteStyle super 方法绑定补充：源码复核发现 Polymod 对附带脚本的原生对象读取字段时可能先返回脚本重写方法；仅在调用该方法时设置跳过标记不足以改变已经绑定的函数。现在读取时先保留 Polymod 的正常权限检查，确认是原生 super 后改为绑定同名原生方法，再由已有的作用域临时跳过重写。轻量夹具将字段读取模拟为返回脚本重写，旧实现会调用重写；项目实际构建宏修改后不再调用重写，并通过直接/保存 super 与异常清理检查（`_build/origin-notestyle-super-macro-lowmem-516/Main.hx`）。真实 Polymod 运行、native 目标及完整构建仍未验证。

Alien Hominid 三个发行包的路径补充：同一轻量夹具读取 0.5、0.6.0 和 0.6.3 包各自的 hominid.json，并按每个包自己的实际目录检查 note、strumline、hold 和倒计时声音，共 12 条资源路径存在；三份旧 note 路径仍返回字符串（`_build/origin-notestyle-real-mod-lowmem-514/Main.hx`）。三份配置的这些路径相同，这是三个发行包的文件存在性检查，不等于三套不同图像或完整模组兼容验证，路径解析仍使用替身。

NoteStyle 0.9 重写参数及对象身份复核：当前 Polymod 原生重写转发会传递旧方法的 raw 参数；提取实际 validateArgumentCount 配替身确认新版零参数/单参数重写允许多余参数，真正缺少必需参数仍报错（`_build/origin-notestyle-extra-arguments-lowmem-518/Main.hx`）。正式路径桥轻量检查补充验证模组已返回的 AssetPath 对象在直接及保存方法两条路径保持同一对象，避免丢失像素数据等标记（`_build/origin-notestyle-bridge-lowmem-512/Main.hx`）。源码中 hxcpp 的 Dynamic 到 String 转换会执行字符串化，因此原生旧 String 返回签名经过脚本重写时仍需实际 native 回归；该结论为代码审查，不是运行证据。

NoteStyle 脚本化 fallback 待处理：对固定 0.9 预览源码复核，除长按方向特殊规则外，八个路径方法缺字段时会调用父样式的同名公开方法（`_build/origin-notestyle-scripted-fallback-audit-519.json`）。当前适配桥的 resolvePreviewRawPath 会直接递归读取父样式数据，因此若父样式脚本重写了该公开方法，可能忽略其自定义结果；根样式自身重写已有处理，但不能推及此情况。该问题仅有源码证据，尚未在真实 HScript 或独立可执行夹具复现，也尚未修改生产逻辑。

脚本化父音符样式隔离夹具已准备：`_build/origin-notestyle-scripted-parent-lowmem-520` 使用正式预览路径解析方法和样式/资源替身，模拟子样式缺字段、父样式脚本返回自定义路径，并检查只调用一次；期望能区分脚本结果与父样式 JSON 默认值。当前系统可用内存接近 4 GiB 保护线，夹具尚未编译或运行，不作为复现或修复证据。

父音符样式重写样本筛查：只读扫描当前隔离模组目录中的 75 个 .hxc 与 3 个 note style JSON，未在这些脚本文本中发现九个路径方法的调用或重写（`_build/origin-notestyle-fallback-sample-audit-521.json`）。这是已采集样本的词法筛查，没有验证脚本继承、动态反射、其他模组或用户实际启用列表；不能排除脚本化 fallback 问题，也不代表已修复。

脚本化父样式返回值隔离原型：`_build/origin-notestyle-capture-prototype-lowmem-522` 准备在原生 String 转换前捕获属于目标样式继承链的脚本返回对象，并设计对象身份、空返回、单次调用、无关对象、嵌套及异常恢复检查。该原型尚未连接 Polymod 或项目源码，也未编译运行；线程局部 GC 保活、真实继承链判定、路径重写及权限边界仍需验证。当前可用内存约 4 GiB，未启动 Haxe。

父样式捕获原型的 TLS 保活源码核查：D 主仓库当前 haxelib 解析到 `.haxelib/hxcpp/git`；该版本 Thread.cpp 的 __hxcpp_tls_set 将值放入 hxThreadInfo.mTLS，hxThreadInfo.__Mark/__Visit 遍历该数组，外部线程信息使用 GCAddRoot，Haxe 创建的线程将信息放在已注册栈范围。D:/app/haxe/haxe/std/cpp/_std/sys/thread/Tls.hx 调用相应原生 TLS 接口。Thread.cpp SHA-256 为 F397DCFAC81AB751C597BBA7E2308D97734AEF33F23D21BF86243AB2D5878B5D。这是选中依赖的源码分析，不是 GC 压力、线程安全或捕获原型运行证据；未确定其他 hxcpp 版本行为。

脚本化父样式捕获联测模型已准备：`_build/origin-notestyle-capture-prototype-lowmem-522/IntegrationMain.hx` 模拟子样式经父脚本及 callOn 返回对象、原生 String 转换、显式 null 和普通父数据回退，检查对象身份与脚本只执行一次；不改变现有项目或依赖。当前内存低于既定保护线，模型尚未编译运行；该模型不是实际 Polymod、GC 或游戏验收。

父样式捕获接入夹具已准备：`_build/origin-notestyle-real-callon-lowmem-523` 使用当前选中 Polymod 的实际 callOn 函数体，以隔离构建宏和脚本类替身插入捕获，准备检查父脚本返回对象及 null、单次调用、原生父数据回退。捕获仍是原型，未修改实际 Polymod 或生产桥；内存低于保护线，夹具尚未编译执行，未证明真实 Polymod、原生目标或 GC 安全。

父样式夹具范围补充：`_build/origin-notestyle-real-callon-lowmem-523` 使用简化的 `Style.nativePath()` 和替身脚本，即使后续运行通过，也只能证明所提取 `callOn` 中捕获结果的隔离机制，不能证明正式 NoteStyle 继承路径。正式 `getNoteAssetPath(false)` 会先调用 `getNoteAssetPath(true)`，而 0.9 解析器 `resolvePreviewRawPath` 直接递归读取父数据；父脚本返回值、实际参数及旧版 String／新版 AssetPath 的转换必须结合真实方法与真实脚本逐项验证，尤其不能简单将捕获到的任意内层结果视为最终返回值。该夹具尚未运行，也未接入产品。

父样式进一步对照：新增隔离夹具 `_build/origin-notestyle-actual-path-lowmem-524`，从当前正式源码提取 `getNoteAssetPath` 和四个 preview 解析方法，使用 Haxe 子类替身记录父方法的参数和调用次数；预期能检测父路径被解析器忽略的问题。它尚未运行，子类也不等于真实 Polymod 脚本，不能据此认定缺陷已复现或修复。建立夹具时可用内存约 4.17 GiB，低于 4.3 GiB 的轻量 Haxe 保护线，故未启动解释器。

父样式对照运行结果：`_build/origin-notestyle-actual-path-lowmem-524` 在可用内存约 4.47 GiB 时以 `haxe -cp . -main Main --interp` 运行，原生路径的返回值、父方法仅调用一次及 `raw=true` 前置断言通过；随后 preview 返回父数据中的默认路径而非父子类覆盖的自定义路径，抛出 `BUG: preview ignored scripted parent`。因此已在提取正式方法和 Haxe 子类替身的隔离条件下复现结果丢失；真实 Polymod 脚本、AssetPath 对象和 native 目标仍未验证。该次仅运行一个轻量解释器，未改产品源码。

父样式候选捕获机制隔离检查：修正 `_build/origin-notestyle-real-callon-lowmem-523/Main.hx` 中测试结果的 Dynamic 类型声明后，在运行前可用内存不低于 4.3 GiB 的条件下执行 `haxe -cp . -main Main --interp`，得到 `PASS actual callOn body with isolated capture hook`。该夹具使用提取的 Polymod `callOn` 方法体及替身脚本，覆盖捕获父结果对象、null 和普通回退；首次运行因夹具类型推断报错，修正后通过。它尚未覆盖正式 NoteStyle 调用链、真实 HScript、嵌套调用或 native GC，也未接入产品，不能证明父样式问题已修复。

捕获机制补充：`_build/origin-notestyle-capture-prototype-lowmem-522` 首次运行也因测试变量类型推断失败；显式声明 Dynamic 后，`haxe -cp . -main Main --interp` 通过对象身份、无关对象隔离、null、嵌套作用域及异常清理检查。此为独立原型，和正式 NoteStyle、真实脚本、线程与 GC 的结合仍未验证，也未应用到产品。

父样式对象返回边界：`_build/origin-notestyle-object-return-lowmem-525` 使用从正式源码提取的旧路径方法及返回对象的 Haxe 子类替身，单次 `haxe -cp . -main Main --interp` 观察到 `Unexpected value ... expected string`；父方法调用一次，夹具通过其预期异常断言。说明在这个解释器替身场景中，对象会在旧 String 调用链内触发异常，不能假设现有捕获原型只在原生调用正常返回后替换结果即可。正式 Polymod、真实 AssetPath 与 hxcpp 行为仍需分别验证；未对产品接入该原型。

父路径重复调用补充：在提取正式 `getNoteAssetPath` 的夹具 `_build/origin-notestyle-actual-path-lowmem-524` 中执行 `haxe -cp . -main RepeatMain --interp`，父子类返回不带库前缀的 `custom` 时，实际调用父覆盖两次；断言通过。该现象来自旧原生方法在无库前缀分支再次获取 raw 路径。修复时需评估脚本副作用及上游语义，不能仅以捕获最后一次结果保证行为一致；真实 Polymod 尚未测试。

父路径上游语义复核：从本地保存的官方 `preview-d3fdf329.zip` 直接读取 NoteStyle：0.9 的 `getNoteAssetPath()` 在自身路径缺失时调用父级同名方法且不传 `raw` 参数，并直接返回结果；而当前旧原生路径调用父级时传入 `true`，无库前缀时甚至可调用两次（见前述夹具）。因此兼容 0.9 的修复不能只在旧方法外捕获其结果，还必须保留预览版参数及调用语义。该比较仅针对该方法，其他八个方法需要分别核对。

0.9 路径回退调用核对（官方 preview d3fdf329 源码）：note、hold、strumline 和 splash 缺项时无参数调用父级同名方法；countdown sprite、countdown sound、judgement、combo 分别仅传 step、step、rating、digit。hold cover direction 缺项先检查本级 root，root 缺项再以 direction 调用父级 root，而不是父级 direction。splash 的公开签名虽保留 `raw:Bool = false`，父级调用仍不传参数。这些是预览版本行为，当前桥在调用旧原生方法后才转换，不能保证这些父级脚本调用语义；对九种路径的修复和真实脚本联测尚未完成。

编辑器鼠标当前源码复核：`git diff --no-index` 确认 `_build/origin-cursor-system-lowmem-490/funkin/input/Cursor.hx` 与当前正式 Cursor 内容一致（文件换行格式不同）；重新运行 `haxe -cp . -main Main -D FEATURE_HAXEUI --interp`，默认、控件样式、切回工具、退出释放和系统指针模式恢复等断言通过。夹具的 Flixel/HaxeUI 仍为替身，不能代替可见编辑器窗口和实际系统鼠标验收。

0.9 路径提前分派的权限边界：检查当前选用的 Polymod `Interp.fcall` 发现，普通调用在取方法前执行严格语法私有访问检查（启用时）、脚本类黑名单和弃用检查，并处理静态引用、脚本代理及 using fallback；super 调用有单独的 `scriptCallSuper` 分支。因此在 `originHistoricalFcall` 之前简单返回自定义路径会绕过这些语义，不能作为安全修复。已保存方法的桥还要在调用时重查黑名单；修复需要在保留这些检查的实际分派路径接入，并验证 super 与代理。

0.9 九路径候选分派模型：新增 `_build/origin-preview-parent-dispatch-lowmem-526`，以模拟样式、资源与脚本验证官方源码所示的父级方法名、参数数量、对象身份、显式 null、缺失文件不继续回退及 hold cover root 次序；单次 `haxe -cp . -main Main --interp` 通过。此模型未使用正式 NoteStyle、真实 Polymod、权限检查或私有 root 的实际脚本分派，只用于检验候选规则，尚不能作为修复或兼容通过证据。

长按特效私有 root 方法分派复核：当前 PolymodBaseClassMacro 的 `overrideBaseFunctions` 跳过静态、inline、macro、构造器等，但不按 public/private 排除实例方法；因此不能仅因 `getHoldCoverRootAssetPath` 为私有方法就假定它不会经过脚本重写。已修正 `_build/origin-preview-parent-dispatch-lowmem-526` 的模拟规则，使本级 direction 缺项时也检查本级 root 重写，单次解释器检查通过。实际宏生成、脚本私有访问规则及真实对象返回仍未联测，不能据此宣布修复。

私有方法宏生成验证：`_build/origin-private-root-macro-lowmem-527` 使用当前选用的原样 PolymodBaseClassMacro 构造隔离类，给私有 `getHoldCoverRootAssetPath` 注入脚本分派；补齐夹具所需抽象类替身后，`haxe -cp . -main Main --interp` 输出 `PASS actual macro dispatches private root`。这证实该宏实际生成私有方法分派；PolymodScriptBridge 和脚本本身仍为替身，正式 NoteStyle、真实 HScript 与 native 构建尚未覆盖。

父路径对象返回的宏联测：`_build/origin-notestyle-real-macro-parent-lowmem-528` 将当前 PolymodBaseClassMacro 原样应用于提取自正式 NoteStyle 的路径方法，以桥和脚本替身让父级返回对象。修正夹具桥的语法错误后运行 `haxe -cp . -main Main --interp`，实际宏分派父脚本一次，并复现 `Unexpected value ... expected string`；夹具按预期异常通过。此结果比纯 Haxe 子类替身多覆盖实际宏生成，但仍不包含真实 Polymod 解释器、AssetPath、完整 NoteStyle 或 native 环境，尚未修复产品。

实际宏父调用参数补充：扩展 `_build/origin-notestyle-real-macro-parent-lowmem-528` 的桥替身以记录参数；轻量解释器确认提取的旧方法通过真实宏向父重写传 `[true]`，不带库前缀的字符串触发两次 `[true]` 调用，对象返回仍在字符串边界抛错。与官方 preview 的无参数单次父调用不同；真实脚本执行器及 native 仍未覆盖。

父路径候选与实际宏联测：`_build/origin-preview-real-macro-candidate-lowmem-529` 在提取的 Style 上运行当前原样 PolymodBaseClassMacro，以独立预览解析候选和模拟桥覆盖九个方法的父脚本对象身份、null、调用次数、参数数量以及文件不存在时不回退；修正夹具中的关键字变量名后解释器通过。候选没有接入生产，桥、资产路径及数据为替身，也未验证真实 HScript、原生子类覆盖、权限检查、super 和 native；不能据此认为问题已修复。

候选分派边界补充：扩展 `_build/origin-preview-real-macro-candidate-lowmem-529`，在模拟桥下检查本级重写优先、模拟 super 跳过本级后调用父重写、脚本异常透传、旧原生字符串及同级私有 root 重写；解释器断言通过。这里的 super 以显式布尔参数模拟，未调用真实 Polymod `scriptCallSuper`；权限检查、脚本解释器和 native 仍未覆盖，候选仍未接入正式代码。

候选分派原生子类反例：现有桥通过 `Std.isOfType` 接受 NoteStyle 子类。对 `_build/origin-preview-real-macro-candidate-lowmem-529` 新增 `NativeSubclassMain.hx`：父类使用原生 Haxe 子类覆盖 `getNoteAssetPath`，候选直接读取父数据而没有调用覆盖，按预期兼容断言失败 `BUG: candidate bypasses native override`。源码搜索未在项目 Origin 源码中发现此类子类，不等于外部扩展不可能存在。此候选因此不能原样接入；需保留真实虚方法分派并重新验证新旧行为。

当前桥的原生子类反例：`_build/origin-notestyle-bridge-lowmem-512/NativeSubclassMain.hx` 以提取的正式 `previewNoteStylePathResult`、NoteStyle/资源替身和覆盖路径的原生 Haxe 子类测试；候选输出默认路径而非覆盖结果，抛出 `BUG: native override path lost`。这是现有桥已有的隔离兼容缺口，不仅是新候选问题；夹具的 NoteStyle、资源和版本识别为替身，完整项目及实际外部子类尚未验证。

原生子类检测探索：`_build/origin-preview-real-macro-candidate-lowmem-529/MethodIdentityMain.hx` 的 Haxe 解释器探针显示，分别绑定在基类实例和继承子类实例上的同一继承方法，`Reflect.compareMethods` 返回 false；重写子类也返回 false，而同一实例上的同一方法返回 true。因此不能用不同实例的 `compareMethods` 区分继承与重写。此结论只覆盖解释器，未覆盖 hxcpp；候选分派和现有桥均未修改。

Polymod super 异常标记修复：真实 PolymodBaseClassMacro 的生成代码在 `scriptCallSuper` 内调用原生方法抛异常时不会移除 `_skipAscFrom` 标记；`_build/origin-private-root-macro-lowmem-527/SuperFailureMain.hx` 使用实际宏与替身桥复现。现 Origin 解释器包装只在脚本 super 调用失败时，移除本次相同方法新增的跳过标记并原样抛出异常，保留调用前已有的同名及其他标记；普通调用不走此清理。`_build/origin-super-exception-macro-lowmem-530` 使用正式项目宏和提取的正式清理函数，结合解释器替身覆盖异常与已有标记，原直接/保存 super 夹具继续通过；`_build/origin-private-root-macro-lowmem-527/SafeSuperMain.hx` 结合实际 PolymodBaseClassMacro 验证异常清理。两个工作区同步。实际 Polymod 解释器、真实模组与 native 构建未验证，直接从解释器包装之外调用 `scriptCallSuper` 也不在本修复范围；这不修复 NoteStyle 父路径问题。

super 异常修复的嵌套检查：`_build/origin-private-root-macro-lowmem-527/NestedSuperMain.hx` 结合实际 PolymodBaseClassMacro 及提取的正式清理函数，验证同名嵌套失败时保留原有同名及其他标记、原样抛出异常，并验证正常 super 结果和标记清理；解释器断言通过。桥及脚本仍为替身，真实 HScript/native 未验证。

实际 Interp AST 与 super 宏检查：`_build/origin-real-interp-fcall-ast-lowmem-531` 从当前选中的 Polymod Interp 提取真实 `fcall` 和 `get` 方法，以当前项目宏检查改写后的旧方法、包装方法及 `withSafeScriptSuper` 注入，解释器检查通过。为限制资源，检查器丢弃方法体而非完整类型检查，宏副本仅把所调用入口的 `macro` 标记去掉；此结果不能代替真实 Interp 执行或 native 构建。

真实 HScript super 回归准备：基于既有真实 Polymod 夹具创建 `_build/origin-real-hscript-super-lowmem-532`，包含抛异常的原生 TestBase、调用 `super.boom()` 并捕获异常的 HScript，以及对残留标记的断言；使用当前项目构建宏和包含正式清理函数的简化 LegacyRuntime。当前可用内存约 5.50 GiB，上次完整 Polymod/OpenFL/Flixel 类型检查消耗至少约 580 MiB，故本次未启动该较重检查。夹具未编译或运行，构建参数和依赖仍需核实，不能作为通过证据。

真实 HScript super 探针语法检查：使用当前 Polymod 的 Parser/Expr，在轻量夹具 `_build/origin-notestyle-fixture-builder-lowmem-517/ParseSuperMain.hx` 解析 `_build/origin-real-hscript-super-lowmem-532/Probe.hxc`，成功接受 `super.boom()` 与 try/catch 的脚本语法。该步骤没有执行脚本或验证解释器构建；完整真实 HScript 夹具仍未运行。

真实 HScript super 夹具构建配置：新增 `_build/origin-real-hscript-super-lowmem-532/run.hxml`，明确启用 Polymod/OpenFL/Flixel 与项目 `historicalSongPaths`、`nullDeprecationSafety` 宏。该文件尚未经 Haxe 运行，宏顺序、依赖和脚本运行效果仍需验证；当前可用内存约 5.43 GiB，未启动较重检查。

真实 HScript super 异常前后对照：`_build/origin-real-hscript-super-minimal-lowmem-533` 使用当前真实 Polymod Parser/Interp 和项目 `historicalSongPaths`、`nullDeprecationSafety` 宏，在不加载 OpenFL/Flixel 的精简宿主中注册并执行 HScript；脚本捕获 `super.boom()` 异常后检查跳过标记，输出 `PASS real HScript super exception cleanup`。同样配置去掉修复的 `_build/origin-real-hscript-super-before-lowmem-534` 在同一断言抛出 `BUG leaked skip`，退出码 1。最初两次夹具编译因宏范围及漏设项目使用的 `hscriptPos` 失败，修正配置后完成前后对照。项目 LegacyRuntime 的其余方法、NoteStyle 和 TestBase 使用替身；未加载真实模组、完整项目或 native 目标。

真实 HScript 父路径复现：`_build/origin-real-hscript-notestyle-parent-lowmem-535` 使用真实 Polymod 解释器和当前构建宏，把提取的正式 NoteStyle 路径方法与 HScript 父类组合。父脚本返回对象时旧原生 String 路径抛 `Unexpected value ... expected string`，父脚本收到 raw=true；返回无库前缀字符串时父脚本被调用两次。两项断言通过。该轻量宿主的资源类、样式数据与 ProbeRuntime 为替身，未使用真实模组或 native；此结果复现缺口而非修复。

真实 HScript 调用侧基线：`_build/origin-real-hscript-notestyle-call-lowmem-536` 增加真实 HScript Caller 对缺项子样式直接调用；父脚本返回对象时，父脚本调用一次，外层脚本调用返回 null，而直接 Haxe 调用同一路径抛 String 类型异常。最初假定外层异常一定透传，测试因此失败；按实际解释器行为调整为检查返回值与调用次数后通过。版本识别、样式宿主及资源为替身，尚不能代表真实模组或 native 行为，也未修复该缺口。

候选与真实 HScript 直接/保存调用联测：`_build/origin-real-hscript-notestyle-candidate-lowmem-537` 在精简宿主中使用真实 Polymod Interp、项目宏、提取的 NoteStyle 路径方法和独立预览候选；父脚本返回对象时，HScript 直接调用及保存后调用均保持同一对象、只调用一次父脚本，且使用 preview 的默认参数 false。原生旧字符串路径对照仍按旧行为调用两次。候选仅在精确基类、非 super 且本级无脚本覆盖时接管；版本判断、资源及部分宿主为替身，九方法、super、黑名单、原生子类和 native 尚未完整联测，未接入产品。

九路径真实 HScript 候选联测：`_build/origin-real-hscript-notestyle-nine-lowmem-538` 提取正式九个路径方法，使用真实 Polymod 解释器与项目宏，分别对直接调用和保存后调用执行 18 项父脚本对象身份、调用一次、方法名和参数断言，全部通过；还检查了本级脚本重写及关闭预览版本时的旧字符串行为。候选仍为隔离实现，版本判断、数据与资源为替身；super、黑名单、原生子类、真实模组及 native 尚未完整验证，未接入正式工程。

真实 HScript super 候选前后对照：在 `_build/origin-real-hscript-notestyle-super-candidate-lowmem-539` 中，子样式脚本分别直接调用和保存后调用 `super.getNoteAssetPath()`，父脚本各返回同一对象且调用一次，前述九路径及旧版断言继续通过；保留旧 super 包装的 `_build/origin-real-hscript-notestyle-super-before-lowmem-540` 对同一案例抛出 `Unexpected value ... expected string`。版本识别、数据、资源与部分宿主仍为替身；候选尚未验证黑名单、原生子类、真实模组或 native，未接入产品。

候选访问限制联测：`_build/origin-real-hscript-notestyle-access-lowmem-541` 使用真实 Polymod 黑名单及解释器，先通过 HScript 保存路径方法，再添加 NoteStyle 原生实例字段黑名单并调用 `bumpBlacklistGeneration()`；保存方法调用被拒绝、父脚本未执行，直接 HScript 调用也未绕过黑名单。前述九路径及 super 断言继续通过。版本识别、资源、样式宿主及候选实现仍为替身，其他私有访问分支、原生子类和 native 尚未验证；候选未接入产品。

候选的原生子类保护及旧字符串父重写：`_build/origin-real-hscript-notestyle-subclass-guard-lowmem-542` 在候选遍历遇到原生子类时返回专用未处理标记，交回现有调用路径；真实 HScript 的直接和保存调用检查确认原生父覆盖仍被调用并保留现有结果。该结果仍包含现有桥丢失原生子类自定义路径的已知缺口，不代表子类已兼容。候选还将父脚本返回的旧字符串按预览版资源规则转换，九方法真实 HScript 检查了库名、扩展、单次调用及 null；对象、super、黑名单和旧版对照继续通过。资源、版本和样式宿主为替身，完整项目/native 未验证，候选尚未接入。

候选类型边界联测：`_build/origin-real-hscript-notestyle-typecheck-lowmem-543` 将轻量宿主的方向改为与工程一致的 Int enum abstract，倒计时补齐 BEFORE/AFTER，并将样式数据声明为 final、fallback 改为私有 getter；真实 Polymod/HScript 的九路径、super、黑名单、旧版及子类保护检查仍通过。样式数据和资源仍为替身，尚未对完整正式 NoteStyle 做类型检查或 native 构建，候选未接入。

长按特效私有 root 的真实 HScript super：`_build/origin-real-hscript-notestyle-root-super-lowmem-544` 构造子脚本覆盖私有 root、调用 super，再从父脚本取得对象。原候选只覆盖九个公开方法时断言失败；将 root 纳入隔离候选后，直接与保存后的 super 调用均返回同一对象且父脚本调用一次，其他九路径、旧版、黑名单及子类回退断言继续通过。当前候选仍在夹具内，资源/版本/宿主为替身，正式严格私有访问、真实模组和 native 仍需验证。

严格私有访问对照：`_build/origin-real-hscript-notestyle-strict-lowmem-545` 启用 `POLYMOD_STRICT_SYNTAX`，给脚本覆盖补齐 override 后，普通九路径和 super 检查通过；但外部 HScript 直接访问私有 root 的断言失败，父脚本被调用。对照去掉候选包装的 `_build/origin-real-hscript-notestyle-strict-before-lowmem-546` 也调用了父脚本，随后旧 String 类型异常被解释器处理；所以该访问检查缺口在精简解释器宿主的原有路径中同样存在，候选使对象结果可返回。诊断中 `getPrivateFieldsOf` 返回空，`Util.getTypeNameOf` 给出 `Class<funkin.play.notes.notestyle.NoteStyle>`；需核对解释器目标的类型名与私有元数据键，不能据此推断 hxcpp 行为。Project.xml 中未找到该严格定义；候选仍未接入产品。


0.9 NoteStyle 父脚本路径适配：对已识别的 0.9 调用，在已执行原有字段访问检查后按预览规则解析九种路径和私有 root 的 super 调用；父脚本返回 AssetPath 对象保留身份，返回旧字符串时转换资源路径，null 保持不回退。遇到原生 NoteStyle 子类时使用未处理标记退回现有路径，故其已知的自定义路径缺口仍未修复。真实 Polymod/HScript 精简夹具 `_build/origin-preview-production-shape-lowmem-548` 已替换为正式宏、正式 PreviewNoteStylePaths 和正式桥接方法；九路径直接/保存、super、旧版、黑名单、严格模式及子类回退断言通过。夹具的样式数据、资源与版本识别仍为替身；严格私有访问中既有类型名问题、真实模组和完整原生构建尚未验证。本次改动已同步两个工作区。

已接入预览路径的多级回退检查：扩展 `_build/origin-preview-production-shape-lowmem-548`，使用真实 Polymod/HScript 与正式路径解析器，九种方法经过两级缺项回退后均一次取得父脚本返回对象；本级资源路径存在但文件缺失时不调用父脚本，父脚本明确返回 null 时也不继续向祖父回退。解释器断言通过；样式注册表、资源存在性与版本判断为替身，真实模组及 native 仍未验证。

真实模组来源分流夹具准备：`_build/origin-preview-real-version-lowmem-549` 复制隔离的 0.8/0.9 元数据，使用提取的正式 `hasApiVersion` 和 `apiVersionForOrigin`，以及真实 Polymod 文件系统、精简自定义 backend。首次编译因夹具缺少正式代码的 private access 标记失败；补齐后两份模组元数据加载成功，但 backend 尚未映射脚本路径而未进入版本断言。现已补充隔离 backend 映射，重新运行时可用内存低于 5 GiB，保护线阻止启动；版本分流尚未通过，真实 OpenFL backend 与 native 亦未覆盖。

真实 0.8/0.9 模组来源分流通过：按用户要求将可用内存保护线调整为 4.6 GiB 后，以低优先级单独运行 `_build/origin-preview-real-version-lowmem-549/run.hxml`，启动时可用内存约 5.20 GiB，执行期间监测保护线，进程退出码 0；`guarded-550.out.log` 记录 0.9 来源返回预览对象并调用父脚本一次、0.8 来源返回原生字符串并保持旧调用次数。使用真实 Polymod 文件系统、模组元数据及正式来源/版本判断，脚本、样式数据、资源和自定义 backend 为隔离测试用途；未验证真实 OpenFL backend、实际第三方模组或原生构建。

来源识别补充：`_build/origin-preview-real-version-lowmem-549/guarded-551.out.log` 在 4.6 GiB 保护下，除真实 0.8/0.9 模组元数据外，还注册不属于任何模组的脚本；该脚本继续获得旧字符串，原有调用次数不变，三种来源断言通过、进程退出码 0。测试 backend 与样式资源仍为替身，不代表真实 OpenFL/native 已验证。

真实旧模组数据经新版分派复核：`_build/origin-preview-real-mod-lowmem-552` 读取隔离保存的 Alien Hominid 0.5、0.6.0、0.6.3 原始 `hominid.json`，以真实 Polymod/HScript、正式路径解析器及文件存在性替身检查 note、hold、strumline、倒计时声音，0.9 直接/保存调用各 12 项匹配实际文件，旧接口直接调用各 12 项返回预期字符串；受 4.6 GiB 保护的低优先级进程退出 0，见 `guarded.out.log`。版本判断、样式宿主和路径包装为替身，未运行完整模组、真实 OpenFL 资源库或 native，也不能证明箭头视觉尺寸。

Neko 来源分流对照：原 `_build/origin-preview-real-version-lowmem-549` Neko 编译遇到实际 PolymodStaticAbstractReference 三处空值类型错误；使用仅在隔离目录把该类 `@:nullSafety` 改为 Off 的副本后编译成功，但以匿名对象构造父样式时运行报 `Invalid field access : join`，未进入版本断言。随后 `_build/origin-preview-neko-class-data-lowmem-555` 以类实例替代测试数据对象，在相同隔离依赖副本下编译并运行，真实 Polymod 来源/版本判断的 0.8、0.9、未知来源断言通过（`build-555.out.log`、`run-555.out.log`，退出码均为 0），全程监控 4.6 GiB 保护线。该夹具改动了空值检查和测试数据类型，样式/资源 backend 仍为替身；不能据此认定原始 Neko 构建、真实 OpenFL 或 hxcpp 已通过。

来源版本缓存重载检查：`_build/origin-preview-version-reload-lowmem-556` 使用真实 Polymod 文件系统和正式版本识别，先让同一脚本路径命中 0.9 规则，再重建隔离资源库并将同一路径模组元数据改为 0.8；第二次判断不再命中 0.9，缓存失效断言通过。此前的 0.8、0.9 和未知来源调用断言也通过；低优先级进程受 4.6 GiB 保护，日志为 `guarded-556.out.log`。自定义 backend 和样式资源仍为替身，未覆盖真实 OpenFL 热重载或 native。

正式 NoteStyleData 类型检查：`_build/origin-preview-real-datatype-lowmem-557` 复制未修改的正式 `NoteStyleData.hx`，将隔离 NoteStyle 的 `_data` 改为该类型，并使用正式预览解析器、项目宏和真实 Polymod/HScript；九路径、多级回退、super、黑名单、旧版及子类回退断言通过，低优先级检查受 4.6 GiB 保护，日志 `guarded-557.out.log`。AnimationData、样式宿主、资源与版本判断仍为替身，未对完整正式 NoteStyle 或 Windows native 构建做类型检查。

正式回归入口补充父样式脚本：`LegacyPublicApiChecks` 的 0.9 真实来源探针在内存中注册父样式脚本，构造独立子样式并临时注册唯一父样式 ID，检查直接/保存调用保持同一个 AssetPath 对象、父方法只调用一次以及 null 返回；成功和异常路径均移除临时注册，两个工作区同步。`_build/origin-formal-parent-probe-lowmem-558` 用真实 Polymod/HScript 和样式替身验证该探针类的构造、scriptSet/scriptGet、直接/保存及 null 语义，`guarded-558.out.log` 退出码 0。正式回归代码和真实 NoteStyle 注册表尚未在完整工程中编译或运行，不能把隔离结果当作正式回归通过。

正式父样式回归块隔离运行：`_build/origin-formal-block-lowmem-559` 从正式 `LegacyPublicApiChecks` 提取原样父样式断言，结合真实 Polymod/HScript、正式路径桥、注册表和 NoteStyle 替身。首次类型检查发现测试替身缺少正式类已有的 destroy 方法；补充替身后重试时系统可用内存降到 4.6 GiB 以下，保护器停止本次启动的 Haxe。该回归块尚未跑完，不能记为通过；完整工程未运行。

CPPIA 版本检查编译条件修正（2026-11-07）：Polymod 的编译模块加载以 `hxcpp && POLYMOD_CPPIA` 为条件；原 `loadScripts` 使用独立的 `FEATURE_CPPIA`，只启用前者时不会设置 `expectedVersion`，可能绕过编译模块的游戏版本检查。现将条件对齐，保持 Origin 版本 `0.8.7`；未启用 CPPIA 的现有构建不受此条件改变。`_build/cppia-version-guard-740` 从正式源码提取条件块，使用替身版本字段通过四种 Haxe 解释器配置检查：两项同时启用时设为 0.8.7，均未启用、只有 FEATURE_CPPIA 或只有 POLYMOD_CPPIA 时不设置。这只是条件检查，未验证真实 CPPIA 模块加载或游戏 ABI；正式 Windows 构建仍未启用该功能。

CPPIA 真模组与拒绝路径核查（741）：用已构建的独立最小 hxcpp 宿主加载原版 ModEngine.cppia，在链接阶段报告缺少 `funkin.modding.module.Module` 并退出 -1（`_build/cppia-real-minimal-host-741.log`）；该宿主没有游戏类，此结果不能证明完整游戏也会失败。另查当前选用的 Polymod：它在检查 manifest 版本及 classRefs 之前调用 module.boot，并把已解析类写入 declared；版本不符或 classRefs 缺失时直接返回，未在该路径撤销 declared 或调用 unload。hxcpp 的 boot 会初始化静态字段，因此版本拒绝不能被当作启动前检查；被拒绝模块的类状态及清理需要真实运行验证和修复。当前生产构建未启用 CPPIA，暂未改动共享依赖或宣称该路径已修复。

CPPIA 拒绝路径隔离修复候选（742）：复制当前 Polymod 加载器到 `_build/cppia-loader-742/PolymodCppiaClassReference.hx`；候选在启动失败、缺清单、版本不匹配和缺 classRefs 时尝试卸载模块，并推迟发布 declared 类，避免拒绝结果覆盖之前记录。`test.py` 提取原版及候选的实际相应代码，以 Haxe 替身测试上述四种失败及成功路径：原版在启动失败未卸载的断言失败，候选五项通过（`result.log`）。替身不能证明原生 hxcpp 卸载、异常或跨模块行为，且无法撤销 boot 已执行的静态初始化；候选只在隔离目录，未安装进共享依赖，尚需原生测试和真实游戏验证。

CPPIA 拒绝路径原生隔离验证（743）：使用独立宿主、实验性 hxcpp 和真实生成的 CPPIA 测试样本，单线程构建退出 0，最低可用物理内存 2,620,524 KiB。提取候选加载器的对应代码执行：正常模块成功，版本不匹配、缺 manifest、缺 classRefs 和 boot 异常均拒绝且保留已有同名记录；四种拒绝后的原生模块均不能再次 boot（`_build/cppia-loader-743/native-run.log`）。原先候选 helper 的 `cpp.cppia.Module` 参数导致原生生成头缺少声明，已改为 Dynamic 参数与局部强类型后重新构建。前两次使用复制的对象缓存分别暴露编译头和链接 PCH 问题，第三次在全新目录完整构建成功。可审查补丁为 `tools/polymod-origin-cppia-loader.patch`，通过所选 Polymod 源码的 apply --check，但尚未安装；本次使用提取代码与简化宿主，不等于完整 Polymod、并发卸载或真实游戏通过，也不能撤销 boot 前后已发生的副作用。

完整 Polymod 原生拒绝路径验证及本地安装（744–745）：隔离副本应用 `tools/polymod-origin-cppia-loader.patch`，用实际 Polymod 扫描器、注册器及实验性 hxcpp 加载文本 CPPIA；分别对版本不匹配、缺 manifest、缺 classRefs 和 boot 异常，在同一进程拒绝后加载有效样本、调用 `Probe.answer()` 并卸载，四组退出 0（`_build/cppia-polymod-744/run3.log`）。首次隔离构建漏设 hxcpp 导致空实现，已修正后重新构建；有效构建最低可用物理内存 2,918,644 KiB。新增 `tools/setup-polymod-origin-cppia-loader.ps1`，隔离验证安装、Verify、逐字节回滚以及异常本地修改拒绝覆盖，随后对 D 盘选中 Polymod 安装并 Verify，原文件备份在 `_build/polymod-cppia-backup-EB51B8D4814C2EE1`，可用脚本 Rollback 恢复。此验证为测试宿主及合成脚本，不代表完整游戏、真实模组 ABI、并发及热卸载通过；正式游戏仍未启用 CPPIA，boot 已执行的副作用也不能由卸载撤销。

CPPIA 当前工程检查及隔离构建准备（746）：已安装的 Polymod 补丁与当前完整源码使用 release HXML 加 `POLYMOD_CPPIA`、`scriptable`、`--no-output` 类型检查退出 0（`_build/cppia-current-typecheck-746.out.log`、`.err.log`）。监控每两秒采样的最低系统可用物理内存为 205,084 KiB，略高于 200 MiB 强制停止线；采样间瞬时值未知，因此此时不进行更重的完整游戏编译。已生成 `_build/cppia-game-746/release.hxml`，仅将生成输出改为独立目录、hxcpp 指向实验性已验证补丁副本并启用 CPPIA；它只是待运行配置，尚未生成或链接游戏。原正式输出、Project.xml 和用户模组配置未因本次配置准备被更改。类型检查不能替代原生编译、真实模组运行和 ABI 检查。

CPPIA 模块替换原生隔离验证（747）：继续使用完整 Polymod 和实验性 hxcpp 的隔离宿主。先加载有效脚本，再分别尝试版本不匹配、缺 manifest、缺 classRefs、boot 异常的同路径更新：四组均拒绝更新，原类仍可调用，重新注册原文件可复用旧模块，之后可卸载（`_build/cppia-polymod-744/reload4.log`）。另加载返回 42 的旧脚本，再替换为返回 43 的有效脚本：新调用返回 43，保存的旧函数被拒绝，退出 0（`_build/cppia-polymod-744/replace5.log`）。这是顺序执行的合成模块测试，不能证明跨模块依赖、并发、游戏热重载或实际 Mod Engine 兼容。

CPPIA 跨模块依赖替换保护（748–749）：完整 Polymod、实验性 hxcpp 与两个独立文本 CPPIA 样本完成跨模块静态调用及继承调用。随后在 Consumer 仍依赖 Provider 时替换 Provider，原实现卸载旧代码后 Consumer 调用报 `Called a function from a cppia class that has been unloaded`（`_build/cppia-polymod-748/update.log`）。现有依赖仍指向旧版本时保留该版本、提示延后替换；卸载两模块后按 Provider、Consumer 顺序重新加载，Consumer 使用新版返回值（`update-fixed.log`）。无依赖的成功替换和四种错误更新回归均通过；本方案需要后续重新加载，尚不自动完成依赖重载，也未覆盖复杂依赖图、并发或真实游戏。补丁及校验安装器分别为 `tools/polymod-origin-cppia-dependencies.patch` 和 `tools/setup-polymod-origin-cppia-dependencies.ps1`，已在 D 盘选中 Polymod 安装；隔离测试证实逐字节回滚和拒绝覆盖本地改动。要完整撤销两层补丁，应先用 dependencies 安装器 Rollback，再用 loader 安装器 Rollback；原文件备份分别保存在 `_build/polymod-cppia-dependencies-backup-EB51B8D4814C2EE1` 和 `_build/polymod-cppia-backup-EB51B8D4814C2EE1`。正式游戏尚未启用 CPPIA。

异步 CPPIA 结果统计修正（750）：完整 Polymod 的异步注册先前在 `registerModule` 返回空类列表时仍将 Future 完成为 true，而 Origin 汇总只看 Future 是否完成；因此被拒绝模块可能计为成功。现让空类列表完成为 false，并让汇总仅计完成且值为 true 的 Future。`_build/cppia-async-750/Main.hx` 使用真实 Lime Promise/Future 和提取的正式表达式，验证成功、空列表、错误三种状态计数为 1/3（`result.log`）；Polymod 改动以 `tools/polymod-origin-cppia-async-result.patch` 和 `tools/setup-polymod-origin-cppia-async-result.ps1` 校验安装，隔离测试了逐字节回滚及未知本地修改拒绝覆盖，所选依赖原文件保存在 `_build/polymod-cppia-async-backup-EB51B8D4814C2EE1`。该检查尚未跑完整异步游戏加载；多个 CPPIA 文件的并行读取完成顺序与依赖注册顺序仍需单独解决，当前生产游戏没有启用 CPPIA。

异步 CPPIA 注册顺序保护（751）：原加载器对所有 CPPIA 文件同时发起异步读取并在各自完成时注册，较晚路径可能先注册，导致依赖前一路径的模块加载失败。候选改为按同步加载器选出的路径顺序逐个异步读取并注册，读取/注册失败后继续后续项目；这保证与给定路径顺序一致，不自动对依赖拓扑排序。`_build/cppia-async-751/test.py` 提取正式方法，使用真实 Lime Promise/Future 和替身资源库/注册器，验证延迟完成、异步错误、同步异常、空注册结果及 2000 个即时完成任务（`result.log`）；完整 Polymod 隔离源码在启用 Lime、hxcpp 和 POLYMOD_CPPIA 时类型检查通过（`typecheck.log`），但尚未在真实游戏及真实异步资源库中验证。补丁 `tools/polymod-origin-cppia-async-order.patch` 与安装器 `tools/setup-polymod-origin-cppia-async-order.ps1` 已校验安装于 D 盘所选依赖，隔离测试通过逐字节回滚和未知修改拒绝覆盖。此补丁叠加在 async-result 后；回滚时应先回滚 async-order，再回滚 async-result。正式游戏尚未启用 CPPIA。

空脚本异步等待修正（752）：Polymod 使用的 `PromiseUtil.allSettled` 对空 Future 数组不会完成，导致无脚本时异步脚本注册的收尾可能一直等待，且与 CPPIA 是否启用无关。现仅在数组为空时返回已完成的空数组，非空仍使用原聚合器，保留原有进度及错误行为。`_build/cppia-empty-752/Main.hx` 使用实际 Lime Future/Promise 和 Polymod PromiseUtil，复现旧空数组不完成，并验证修正后空数组完成以及成功、错误混合时等待全部完成（`result.log`）；含真实 Polymod、Lime 和 CPPIA 条件的隔离类型检查退出 0（`typecheck.log`），未运行完整游戏无模组启动。补丁和安装器为 `tools/polymod-origin-cppia-empty-async.patch`、`tools/setup-polymod-origin-cppia-empty-async.ps1`，已校验安装；隔离验证了逐字节回滚和未知修改拒绝覆盖。该补丁叠加在 async-order 之后，回滚时应先撤销 empty-async，再依次撤销 async-order 和 async-result。

HScript 异步失败收尾修正（753）：旧 `registerScriptClassByPathAsync` 在资源返回 404 时只报错不结束 Promise，导致整批异步加载无法收尾；同步读取抛错和非 HScript 解析异常也可能逃逸。现让 404 和其他读取错误均结束为 error，并捕获同步读取与非 HScript 解析异常；原 HScript 解析错误及成功路径保留。`_build/hscript-async-753/test.py` 从实际方法提取代码，用真实 Lime Future/Promise 和替身资源/解析器复现原 404 未结束，验证立即和延迟 404、其他读取错误、同步异常、两种解析异常及成功；默认与 `hscriptPos` 两种配置均通过（`baseline.log`、`result.log`、`result-pos.log`）。隔离完整 Polymod 分别在启用和未启用 hscriptPos 时类型检查通过，未运行真实游戏异步资源加载。补丁及安装器为 `tools/polymod-origin-hscript-async-errors.patch`、`tools/setup-polymod-origin-hscript-async-errors.ps1`，已安装于 D 盘所选依赖；安装器隔离验证逐字节回滚及未知本地改动拒绝覆盖，原文件备份在 `_build/polymod-hscript-async-backup-EB51B8D4814C2EE1`。

Origin 上游只读复核（2026-11-07）：`main` 已从 `86cb949c74743b2bdbb58a66326acdb47a36f43a` 更新到 `94ee0f2a9386d80e445be39ee2ed4b4a630cfbac`，比较结果为新增 1 个提交、只变更 `docs/COMPILING_MOBILE.md`。`preview/public-playtest` 已从此前核对的 `fa9b80ca8ca5063a34022acc809bf5499e1d81c4` 更新到 `5a63f2062bfc95a1fe35f83405acdee1f8c845ec`，比较结果为新增 69 个提交、175 个变动路径；其中新增 `source/funkin/play/event/ScrollVelocityEvent.hx` 和 `source/funkin/play/notes/ScrollVelocityTimeline.hx`，本地 Origin 同位置目前不存在，且 Strumline、SustainTrail、SongData、Song 和 PolymodHandler 等也有变动。这是路径级审查，尚未逐项比较语义、移植或验证真实模组，不能视为新预览版本兼容。比较链接：https://github.com/FunkinCrew/Funkin/compare/fa9b80ca8ca5063a34022acc809bf5499e1d81c4...5a63f2062bfc95a1fe35f83405acdee1f8c845ec 和 https://github.com/FunkinCrew/Funkin/compare/86cb949c74743b2bdbb58a66326acdb47a36f43a...94ee0f2a9386d80e445be39ee2ed4b4a630cfbac 。


2026-11-13 预览事件更新：通过 GitHub 官方比较核实 `main` 仍为 `94ee0f2a9386d80e445be39ee2ed4b4a630cfbac`，`preview/public-playtest` 前进至 `8712214ec7a94d2ed3fd74844c1a9c738d4c92c8`（较 `5a63f2062bfc95a1fe35f83405acdee1f8c845ec` 增加 117 次提交）。移植其 ScrollVelocity 显式起始速度及曲中滚速变化的修正，以及 RenderDistance 事件和谱面重置时的对应状态复位；既有旧模组全局渲染距离回退仍保留。`_build/origin-scroll-velocity-756/result.log` 是含替身数据与节拍器的轻量 Haxe 算法检查，覆盖目标、停止、反向、缓动、显式起始速度和变化中的滚速；尚未完成完整编译或真实谱面运行验证。其余预览更新仍待逐项审查，不代表支持整个预览版本。上游比较：https://github.com/FunkinCrew/Funkin/compare/5a63f2062bfc95a1fe35f83405acdee1f8c845ec...8712214ec7a94d2ed3fd74844c1a9c738d4c92c8 。


预览自定义事件和滚速起点（2026-11-13）：按上游 `8712214ec7a94d2ed3fd74844c1a9c738d4c92c8` 接入 CustomEvent 运行器、脚本事件类型与分发，以及 Song、Stage、Bopper、SongEvent、Module 的默认回调；PlayState 每帧处理并在重建谱面时清理事件。ScrollSpeed 接受可选 `useStart` / `startScroll`，未提供时沿用原调用方式。`_build/origin-custom-event-757/result.log` 使用正式 CustomSongEvent 和替身节拍器、数据、回调检查参数读取及起始、中途、结束；未验证实际游戏分发、脚本回调、编辑器或原生构建。完整项目编译、旧模组回归和新预览谱面仍待验证。

自定义事件池宏边界检查（2026-11-13）：`_build/origin-custom-event-pool-758` 从当前正式 ScriptEvent、CustomEventScriptEvent 与 ScriptEventPoolMacro 提取对应类，使用实际 thx.core 和替身歌曲数据/Flixel 类型运行 Haxe 解释器；验证事件创建、回收后复用及自定义事件进度，结果见 `result.log`。该夹具未覆盖整个 ScriptEvent 模块、真实 Flixel、原生编译或游戏分发。


CPPIA 依赖卸载顺序（2026-11-13）：先前的更新保护仅覆盖替换模块，`unloadInactiveModules` 仍可能先卸载被活动 Consumer 引用的 Provider。现按依赖顺序反复卸载无活动引用的模块；活动或卸载失败的依赖者仍在时保留提供者，循环依赖保留以避免失效引用。提取正式方法的轻量 Haxe 夹具在旧实现复现活动依赖者丢失提供者，新实现通过活动依赖、完整链的卸载顺序和循环依赖检查（`_build/cppia-unload-759/before.log`、`after.log`）；它使用模块替身，尚无真实 CPPIA 原生卸载验证。补丁 `tools/polymod-origin-cppia-unload-order.patch` 与校验安装器已安装于 D 盘选定的 Polymod；隔离安装、校验及逐字节回滚通过，备份在 `_build/polymod-cppia-unload-order-backup-EB51B8D4814C2EE1`。回滚前应先执行该安装器 Rollback，再回滚先前的 dependencies 补丁；正式游戏仍未启用 CPPIA，完整构建和真实模组未验收。

CPPIA 原生依赖验证尝试（2026-11-13）：隔离宿主 `_build/cppia-unload-native-760` 以实际 Polymod 加载器和已补丁 hxcpp 准备 Provider/Consumer 测试。首次构建遗漏 `hxcpp` 条件，模块注册失败，不能作为依赖修复结果；补齐条件后 Haxe 类型生成通过，第二次单线程原生构建期间系统可用内存下降到约 800 MiB 且响应变慢，为保护电脑提前终止构建。`codegen2.*.log`、`build2.*.log` 和首次 `run.*.log` 保留；真实 CPPIA 模块卸载验收仍未完成，原始项目输出未被覆盖。

2026-11-13 版本差异复核：官方 v0.8.5→v0.8.6 的角色数据从 1.0.1 升至 1.0.2，新增 `healthIcon.shouldBop`，缺省为 true。当前 CharacterRegistry 接受 `1.0.x`，CharacterData.validateCharacterData 对缺省值填 true，HealthIcon 也以 true 作为回退；这项变动的静态路径已覆盖，不构成需要重复添加的补丁。依据 `_build/origin-complete-version-audit-233/diff-23.patch.gz`、正式解析器和 HealthIcon；未因此宣称真实角色运行验收通过。

CPPIA 替换失败边界待核对（2026-11-13）：静态审查发现，`registerModule` 成功登记新类后调用 `unloadModule(previous, path)`，没有检查该方法的 false 返回值，随后从 `loadedModules` 移除旧记录。若原生卸载实际失败，旧模块可能仍存活但不再被后续清理跟踪。此结论来自控制流，尚未复现该失败或证明资源泄漏；候选修复必须同时处理新旧模块在 boot 后的类注册状态，不能简单提前卸载旧版本。由于 C 盘空间不足，原生复现和修复尚待完成。

CPPIA 版本戳复核（2026-11-13）：官方 preview/public-playtest 固定提交 `8712214ec7a94d2ed3fd74844c1a9c738d4c92c8` 的 `project.hxp` 仍将游戏版本设为 `0.8.7`，其 CppiaManifestMacro 从 `funkin` 构建定义生成 gameVersion；这与本地真实 Mod Engine 1.0.3 样本的 `gameVersion=0.8.7` 一致，即使该模组 metadata 标为 API 0.9.0。因此不能仅依据模组 metadata 把 CPPIA 版本检查改成 0.9.0；该源码比较不证明 ABI 兼容或全部 0.9 编译模组可运行。来源：https://github.com/FunkinCrew/Funkin/blob/8712214ec7a94d2ed3fd74844c1a9c738d4c92c8/project.hxp 与 https://github.com/FunkinCrew/Funkin/blob/8712214ec7a94d2ed3fd74844c1a9c738d4c92c8/source/funkin/util/macro/CppiaManifestMacro.hx 。

结算返回编辑器的摄像机清理（2026-11-13）：参考 Origin 预览提交 `8712214ec7a94d2ed3fd74844c1a9c738d4c92c8`，在本地两条谱面编辑模式结算退出分支中关闭前移除结算背景、滚动和主摄像机，避免背景色在关闭时闪现；普通结算路线不变。两工作区源码均已修改；目前仅核对上游与本地控制流，尚未编译或在编辑器实测。

0.9 真实模组候选（2026-11-13）：从 GameBanana 官方项目页 https://gamebanana.com/mods/617450 下载 Accurate Week Order 2.0.4 预览版原包（文件 1849208，100506 字节），保存在 `_build/gamebanana-origin-legacy-20261101/accurate-week-order-preview-1849208.zip`；GameBanana MD5 `f267f80a748171ff510114fd8e0632e4` 验证通过，SHA-256 为 `e57fb3b65a4693ba0a31a9d68a398e06525873f04a5b0fb7afb4f686b3add549`。包内 metadata 声明 API 0.9.0，含五份 `ui/story-mode/levels` 的 1.0.0 数据，本地 LevelRegistry 静态接受该版本及目录。仅检查原包和源码，尚未安装、启动或验证故事菜单及排序；不能计为通过。

Accurate Week Order 2.0.4 素材依赖静态检查（2026-11-13）：逐项读取原 ZIP 的五个关卡 JSON，对每项 titleAsset 检查外置 Origin 资源中的 PNG，对每个 prop 检查 PNG 与 XML；当前外置资产中均能找到。检查不验证 XML 内容、资源合并优先级、排序结果、真实窗口或游玩，模组仍为未运行。

CPPIA 隔离宿主续编（2026-11-13）：C 盘空余恢复后尝试在 `_build/cppia-unload-native-760` 单线程续编，监控到系统可用内存最低采样 865360 KiB，低于 900 MiB 提前停止线，构建以监控退出码 3 终止；随后确认无本次 neko/cl/link/haxe 进程。`build3.out.log` 和 `build3.err.log` 保留，宿主未生成新的可用结果，原生依赖测试仍未完成。

CPPIA 无导出类模块清理边界（2026-11-13）：`registerModule` 可能留下零注册类的已加载模块；旧卸载逻辑把 0 个活动类等同于全部活动，导致该模块不被卸载。现仅在没有其他已加载模块时清理它，避免因为内部类依赖未完整记录而提前释放；多个空模块或同时存在其他模块时会保守保留，可能延迟释放。提取正式逻辑的替身夹具在旧逻辑复现保留，在修复后覆盖单独空模块、与活动模块并存、依赖链及循环（`_build/cppia-empty-unload-761/before.log`、`after-conservative.log`）。首轮测试生成器的断言和安装器手填哈希曾失败，修正后重跑通过；安装器隔离安装、校验和逐字节回滚通过。补丁及安装器为 `tools/polymod-origin-cppia-empty-unload.patch` 与 `tools/setup-polymod-origin-cppia-empty-unload.ps1`，已安装于 D 盘选定 Polymod；回滚时先撤销本补丁，再撤销 unload-order。没有验证真实原生模块或完整游戏，正式构建仍未启用 CPPIA。

CPPIA 加载顺序扫描试验（2026-11-13）：当前同步与异步加载均沿用资源列表顺序，不能保证 Provider 先于 Consumer。`_build/cppia-order-plan-762` 使用实际 PolymodCppiaScanner 扫描先前的真实 CPPIA 编译样本：Consumer 继承 Provider，原次序反转时隔离排序原型能恢复顺序（`result.log`）。进一步扫描原始 Mod Engine 1.0.3，发现声明表除了模组类还包含 `funkin.ui.debug.charting.ChartEditorTheme` 等引擎类型；因此不能直接将所有声明当作模组提供者，否则可能引入假依赖和错误顺序。此排序尚未接入生产；重复类、静态引用、循环、异步读取和真实模组加载仍待处理。

CPPIA 导出清单只读解析试验（2026-11-13）：`_build/cppia-order-plan-762/manifest_probe.py` 在文本 CPPIA 中定位 PolymodCppiaManifest，分别读取 `classes` 字符串数组与 `classRefs` 类型引用数组，并要求数量及对应名称一致；Provider、Consumer 样本分别返回各 1 项，原始 Mod Engine 返回 76 项且无 `funkin.*` 导出（`manifest-probe.log`）。这能区分该样本中的公开类与扫描到的引擎声明，但目前只是针对已见文本布局的隔离原型；其他 hxcpp 编码、异常文件、重名、循环和热重载语义尚未验证，未接入正式加载器，不作为安全校验。

CPPIA 导出解析与排序候选（2026-11-13）：`_build/cppia-order-plan-763` 使用 Haxe 读取文本 CPPIA 清单，只接受 `classes` 与 `classRefs` 数量和名称一致的布局，并结合正式 PolymodCppiaScanner 检查引用。隔离测试通过 Provider/Consumer 反序、原始 Mod Engine 76 个导出、原顺序、格式错误、无效引用、重名、循环以及模块内部同名类型回退（`result.log`、`order-result.log`）；不支持的布局、重名或循环保留输入顺序。首次编译因测试类型导入不完整失败，已修正后重跑。该候选尚未接入同步或异步加载，未覆盖不同 CPPIA 编码、真实模块注册、热重载和内存占用，不视为 0.9 编译模组已支持。

CPPIA 依赖顺序加载候选（2026-11-13）：隔离版同时为同步和异步加载添加逐个读取的预扫描，使用清单导出和类型引用排序，再逐个重读注册；无法可靠判断、重名和循环时保留原顺序。提取的正式方法使用真实 Lime Future、真实 CPPIA Provider/Consumer 字节和替身资源库/注册器，覆盖反序、延迟读取、读取错误回退、单文件不额外读取及 Future 对应关系（`_build/cppia-order-integration-764/sync-result.log`、`async-result.log`）。候选差异保存在 `tools/polymod-origin-cppia-dependency-order.patch`，已检查可干净应用，但没有安装。隔离目录并非完整依赖，完整 Polymod 类型检查、真实原生模块、热重载、真实异步资源库、模组覆盖优先级及内存表现均未验证，不能认为此补丁已验收。

CPPIA 预扫描内存改进（2026-11-13）：排序候选不再把整个 CPPIA 正文按行拆分，而是先定位清单类边界，仅拆分该区块；未识别的格式或重复清单继续回退原顺序。使用原始 Mod Engine 3 MiB 文件、Provider/Consumer、损坏数据重新检查解析及同步/异步加载候选，通过 `parser-result-optimized.log`、`sync-result-optimized.log`、`async-result-optimized.log`；首次运行因遗漏 Lime 测试类路径失败，补全后重跑通过。补丁已同步并重新通过 `git apply --check`，仍未安装，实际峰值内存、完整 Polymod 类型检查及原生加载未验证。

CPPIA 依赖排序候选安装（2026-11-13）：隔离加载器同时引用同步和异步入口，以 `POLYMOD_CPPIA`、`scriptable` 和完整 Polymod 依赖执行无输出 Haxe 类型检查，退出 0（`_build/cppia-order-integration-764/full-typecheck.out.log`、`.err.log`；最低采样可用物理内存 1233300 KiB）。三文件补丁安装器在隔离副本验证安装、逐字节回滚及拒绝覆盖修改过的辅助文件；随后将补丁安装于 D 盘选定 Polymod，并保存精确原文件至 `_build/polymod-cppia-dependency-order-backup-EB51B8D4814C2EE1`。安装器为 `tools/setup-polymod-origin-cppia-dependency-order.ps1`，回滚同一 Polymod.hx 的旧异步补丁前必须先回滚此补丁。此为依赖源码和类型检查结果，正式游戏仍未启用 CPPIA；真实原生模块依赖、模组覆盖顺序、热重载、运行内存及完整游戏均未验证。

CPPIA 原生隔离验证增量重建（2026-11-13）：构造与旧宿主相同的 Haxe 编译定义后，371 个生成的 C++ 文件与旧宿主字节一致、4 个变化；在独立副本单线程重建 3 个源码后链接失败，MSVC 报 LNK2011/LNK1120，旧对象引用的 runtime 预编译头符号未加入当前链接（`_build/cppia-codegen-probe-766/build.out.log`）。已在隔离副本准备附加旧预编译头对象的链接配置，尚未重新运行或证明生成二进制正确；系统可用内存偏低时不继续链接。此失败不代表依赖卸载通过，也未更改正式游戏输出。

CPPIA 增量链接重试（2026-11-13）：隔离链接配置已包含先前对象所需的预编译头，但实际链接时可用物理内存最低采样 896592 KiB，低于 900 MiB 提前停止线，监控终止了进程；`_build/cppia-codegen-probe-766/link2.out.log` 与 `.err.log` 只保存中断过程，不构成链接或运行成功证据。随后确认无 neko/cl/link 进程。需要在资源条件允许后重新链接并运行依赖卸载测试。

CPPIA 分段依赖排序（2026-11-13）：原候选遇到任意无法解析的模块会放弃整批排序。现将未知模块保留在原位置并作为边界，分别排序相邻的可解析模块；某段内重名或循环时仅该段保留原顺序，避免跨越未知模块改变覆盖次序。真实编译样本及替身资源库测试了未知边界、两个独立段、重名、循环以及同步/异步失败回退（`_build/cppia-order-integration-764/segment-result.log`、`sync-segment-result.log`、`async-segment-result.log`）；首次同步回归仍按旧全局回退预期而失败，改为验证新行为后重跑通过。补丁 `tools/polymod-origin-cppia-segment-order.patch` 与校验安装器已安装到 D 盘所选 Polymod，隔离安装、校验及逐字节回滚通过；回滚 dependency-order 补丁前先回滚 segment-order。正式游戏未启用 CPPIA，分段策略的完整 Polymod 新版本类型检查、真实原生加载和模组覆盖行为仍未验收。

CPPIA 原生模块依赖卸载复核（2026-11-13）：`_build/cppia-codegen-probe-766` 使用与已选 PolymodCppiaClassReference 完全相同的源码、实验性 hxcpp 副本及以前生成对象的隔离副本，单线程增量链接退出 0（`link3.out.log`，MSVC 报重复对象 LNK4042 提示）。独立编译的 Provider/Consumer 文本 CPPIA 在真实 native 宿主中加载，手动从注册表移除 Provider 后 Consumer 仍可调用，清空注册表后按 Consumer、Provider 顺序卸载（`run.out.log`，退出 0）；另验证有依赖时延后 Provider 更新、卸载后重载并使用新版本（`update.out.log`，退出 0）。测试通过私有接口模拟停用，不等于真实 Mod Menu 热重载；样本为合成模块，链接复用了经比较内容一致的旧对象，未验证完整游戏、真实 Mod Engine 或 CPPIA 依赖排序入口。正式游戏仍未启用 CPPIA。


CPPIA 分段排序原生验证准备（2026-11-13）：基于已验证卸载测试的隔离宿主，使用当前安装的排序辅助源码和相同编译选项重新生成 C++，并保留旧预编译头链接输入；`order-codegen.*.log` 显示代码生成退出 0，安装器 Verify 通过。单线程增量构建到达链接阶段时，系统可用物理内存降至 911832 KiB，低于本次 900 MiB 提前保护线，监控终止了构建（`_build/cppia-codegen-probe-766/order-build.*.log`）；进程检查未发现残留 neko、cl 或 link。此次没有完成链接或执行新排序原生测试，不能视为原生排序验收通过；已保存的 `host/Main-unload-verified.exe` 是此前卸载测试二进制，不能用于证明排序。正式游戏和模组选择未改动。


历史歌曲版本声明批量复核（2026-11-13）：读取本地保存的 25 份 Origin 正式版本源码快照（v0.3.2 至 v0.8.7，具体覆盖版本及各 SongRegistry 源码 SHA-256 见 `_build/origin-complete-version-audit-233/song-registry-version-review-767.json`）。这些快照的歌曲 metadata 版本为 2.2.2、2.2.3 或 2.2.4，注册器均声明接受 2.2.x；chart 和 music 数据版本及规则均为 2.0.0 / 2.0.x。当前注册器分别声明 2.2.8 / 2.2.x 与 2.0.0 / 2.0.x，并另有 2.0.x、2.1.x metadata 迁移分支。这只核对源码版本声明，不证明解析默认值、运行行为、未列入快照的版本或真实模组兼容。


旧版歌曲元数据变体修复（2026-11-13）：`parseEntryMetadataRawWithMigration` 的 2.0.x / 2.1.x 分支此前迁移后直接返回，忽略调用方传入的 variation；2.1.x 旧字段标记为 `@:jignored`，FNFC 导入等调用方实际传入变体，导致非默认变体可能被错误标成默认。现在旧分支在解析成功后与当前格式一样设置调用方变体，未传入时使用默认值，解析失败仍返回 null。`_build/origin-song-variation-768` 提取实际分支，使用解析器替身运行 Haxe 解释器：旧分支重现 2.0 丢失变体（`before.err.log`），新分支覆盖 2.0、2.1、2.2 的指定/默认变体、解析失败和未知版本（`result.log`）。测试不覆盖真实 JSON 解析器、FNFC 实际导入或完整游戏构建；这些仍需验收。两工作区均已作同一局部修改。


FNFC 谱面变体修复（2026-11-13）：`loadSongChartDataFromFNFCZipEntries` 根据传入 variation 选择谱面文件，却没有把 variation 传给 `parseEntryChartDataRawWithMigration`，因此非默认谱面对象被标为默认；现在将变体传入解析器，和元数据导入保持一致。`_build/origin-fnfc-chart-variation-769` 提取当前 FNFC 加载函数和注册器分发函数，使用 ZIP、版本判断与底层解析器替身运行 Haxe 解释器；修复前复现 `erect` 被标为 `default`（`baseline.err.log`），修复后覆盖默认/非默认变体、解析失败、版本缺失和不支持版本（`current.out.log`）。该测试不覆盖真实 ZIP 解压、JSON 解析或游戏编辑器中的 FNFC 导入；完整运行验收待做。两工作区均有相同局部修改。


FNFC 附加变体缺失的导入收尾（2026-11-13）：加载附加变体元数据的错误原本按非致命错误写入 issues，但启用音频加载后又因该元数据为空直接抛错，整个导入失败。现跳过已记录错误的缺失变体，继续读取其他变体音频；默认变体仍是必需项。`_build/origin-fnfc-missing-variation-770` 提取实际导入控制流，以 ZIP 和音频替身运行 Haxe 解释器：旧代码重现后续抛错，新代码验证错误保留、默认及其他有效变体音频继续加载、关闭音频以及默认数据缺失仍失败（`baseline.err.log`、`current.out.log`）。首次夹具因扩展类型导入错误未编译，修正夹具后重跑；真实 FNFC 文件、音频和完整游戏尚未验收。两工作区均已修改。


真实旧模组字体路径修复（2026-11-13）：[The Devil’s Swing](https://gamebanana.com/mods/419740) v0.4.1 原包的 `InkFinalStage.hxc` 导入 `funkin.Paths` 并调用 `Paths.font("fofbb_reg.ttf")`，原包实际含 `fonts/fofbb_reg.ttf`；Origin v0.3.2/v0.5.1 的同名入口按 `assets/fonts/$key` 处理。当前兼容入口此前得到 `assets/fofbb_reg.ttf.ttf`。现在对已带常见字体扩展名的旧式调用恢复 `fonts/` 相对路径，对无扩展名的新式调用保留现有扩展参数行为。`_build/origin-real-mod-font-771` 记录原包脚本和文件路径，提取正式方法运行 Haxe 解释器：旧实现复现错误路径，修复后覆盖真实模组文件名、扩展名大小写、新式默认及显式扩展名；路径解析器是替身，没有验证 Polymod 实际资源覆盖、字体渲染或整首游玩。两工作区源码均已修改。


真实旧模组字体路径分发复核（2026-11-13）：`_build/origin-real-mod-font-path-772` 提取当前 `funkin.Paths.font`、其 getPath 包装及实际 `funkin.modding.compat.Paths.getPath` 主体，结合按原包文件列表设置的资源存在性替身，验证 `fofbb_reg.ttf` 可分发到 `assets/fonts/fofbb_reg.ttf`，现代无扩展名路径仍落在预期位置（`result.log`）。兼容表、路径猜测与资源存在性使用替身，故该测试仍不证明实际 Polymod 挂载、字体显示或游戏运行。


旧模组字体实际挂载尝试（2026-11-13）：`_build/origin-real-font-polymod-773` 从 Devil’s Swing 0.4.1 原包仅复制原元数据和原字体到隔离目录，准备以实际 Polymod、Lime/OpenFL 和正式旧模组文件系统检验路径及字体字节。Haxe 解释器构建期间系统可用内存降至 744120 KiB，监控提前终止测试；进程退出码 2，未得到挂载或读取结果。随后确认本次测试进程已退出，现存独立 Haxe server 不属于本次测试，未操作。真实资源挂载及游戏字体显示仍未验收。


CPPIA 同名提供者依赖保护（2026-11-13）：`recordDependencies` 曾为每个类名只保存一个提供者，多个已加载模块导出同名类时，其选中项取决于 Map 迭代顺序，无法保证与原生类解析得到的提供者相同；之后卸载或替换未记录的提供者有使消费者持有失效引用的风险。现在遇到引用时保守记录所有导出该名称的已加载模块，避免随意选择；代价是可能延迟无需保留的同名模块更新或卸载。`_build/cppia-duplicate-provider-774` 提取实际方法并使用模块替身：旧方法未记录全部同名提供者，新方法覆盖两提供者、重复引用、自身及无关模块（`baseline.err.log`、`candidate.out.log`）。补丁 `tools/polymod-origin-cppia-duplicate-providers.patch` 与安装器已在隔离副本验证安装、校验、逐字节回滚及拒绝未知修改，并安装到 D 盘选定 Polymod；备份在 `_build/polymod-cppia-duplicate-providers-backup-EB51B8D4814C2EE1`。回滚早先修改同一加载器的 empty-unload、unload-order 或 dependencies 补丁前，须先回滚此补丁。尚未验证真实同名原生模块、完整 Polymod 类型检查或游戏热重载；正式游戏仍未启用 CPPIA。


CPPIA 同名提供者卸载联合检查（2026-11-13）：`_build/cppia-duplicate-provider-unload-775` 将新依赖记录方法与提取的卸载控制流组合，模块和注册表使用替身；活动消费者引用两个同名提供者时，两者均保留，清除活动消费者后先卸载消费者，再卸载两个提供者（`result.log`）。该检查不等于原生模块或真实热重载验证。更新隔离原生宿主为当前 Polymod 源码后重新生成 C++，可用内存跌至 902652 KiB，触发 900 MiB 提前保护并以退出码 2 中止；`_build/cppia-codegen-probe-766/order2-codegen.*.log` 不构成编译成功证据。监控输出包含 taskkill 子进程拒绝访问/进程已退出提示；后续进程清单未见本次编译器进程，独立 Haxe server 不属于本次测试，未操作。


CPPIA 未导出内部类卸载待核实（2026-11-13）：当前加载器将模块解析到的所有类写入 `declared`，但 `everProvided` 仅登记 manifest 导出类；`unloadInactiveModules` 成功卸载时没有清理 `declared`。因此非导出内部类的旧引用会留在该表，且 `isInactiveCppiaClass` 不会仅凭非导出类名将其判为失效。HScript 对 `Type.resolveClass` 的失效过滤依赖后者，理论上可能暴露已卸载内部类；是否能实际解析到这些类及是否影响真实模组尚未通过原生运行确认。应构造带内部类的真实 CPPIA，验证卸载后查询、同名覆盖和重新加载，再决定如何保留其他仍在使用的同名提供者，不能直接删除共享名称。


CPPIA 已卸载内部类原生复现（2026-11-13）：在 `_build/cppia-internal-class-776` 使用 Haxe `-cppia -debug` 生成文本 CPPIA；旧样本声明但不导出 Hidden，新样本的 Probe.answer 在 `Type.resolveClass("Hidden")` 为 null 时返回 43，否则返回 44。已验证的独立 native 宿主按同一路径加载旧样本再替换为新样本，替换后预期 43 的断言失败（`native.out.log`、退出 -1），而旧样本换成不含 Hidden 的对照时通过（`control.out.log`、退出 0）。这证明该隔离 hxcpp 宿主替换后仍能解析旧内部类；它没有运行真实模组或完整游戏，且使用前一版 Polymod 加载器，不证明同名提供者新补丁。代码追踪显示 CppiaClassInfo::deactivate 清除函数和状态但不从 hxcpp 全局类表撤销注册；简单按名字删除会误删后来注册的同名类，且可能丢失仍存活的先前提供者。尚未实施原生修复，需处理对象身份和多代覆盖恢复并作真实原生测试。


CPPIA 原生类注册生命周期修复候选（2026-11-13）：在隔离 hxcpp 副本中，卸载类时仅当全局表仍指向该类对象才更新注册，向前跳过已卸载的同名 CPPIA 代并恢复最近仍存活的代；原生宿主类不被覆盖或按名字盲删。`_build/cppia-class-registry-native-777` 以与正式 Polymod 加载器一致的源码和已打补丁的实验 hxcpp 源文件单线程增量编译隔离宿主；初次链接缺旧预编译头符号，加入原有 PCH 对象后链接成功（重复 runtime 对象报告 LNK4042，`link.out.log`、`stack-build.out.log`）。构建临时使用实验 hxcpp 原路径，结束后两源文件已按哈希验证恢复；正式安装的 hxcpp 未修改。此前内部 Hidden 类复现现在通过（`hidden-final.out.log`）；三个真实编译的合成 CPPIA 依次覆盖同名 Shared，先卸中间代保持最新代、卸最新代恢复仍存活的首代、最后卸首代后无残留（`stack.out.log`）。正式排序辅助方法与真实原生注册器的 Provider/Consumer 反序加载、调用和卸载通过（`order-final.out.log`）；依赖者存在时延后提供者更新及卸载后重载通过（`update-final.out.log`）。以上是隔离宿主及合成模块，不是完整游戏或真实模组运行；GC 压力、并发卸载、宿主原生类同名碰撞、资源覆盖及真实 Mod Menu 热重载仍待验证。候选已整理为 `tools/hxcpp-origin-cppia-class-registry.patch` 和 `tools/setup-hxcpp-origin-cppia-class-registry.ps1`，隔离安装、校验、逐字节回滚及拒绝未知修改通过；它要求先安装 `hxcpp-origin-cppia.patch`，回滚基础补丁前须先回滚本补丁。仅候选实验副本已带新补丁，正式游戏未启用 CPPIA、未完成完整构建。


CPPIA 类注册表原生 GC 和宿主重名复核（2026-11-13）：在 `_build/cppia-class-registry-native-777` 的隔离宿主中，以三个独立编译的文本 CPPIA 覆盖 `Shared`，并让第三模块另外声明与宿主原生类同名的 `Main`。分别在加载后和乱序卸载过程中执行三次完整 GC，验证宿主 Main 在加载/卸载后仍不变、卸中间代不影响最新代、卸最新代恢复存活的首代、最后卸首代后名称消失（`gc2.out.log`，退出 0）。首次冲突样本主动调用 `Main.value`，在链接时解析到宿主 Main 并报不存在该方法（`gc.out.log`）；改为保留但不调用同名类后才进行上述有效测试。重新构建的宿主再次通过旧内部类替换和反序依赖加载（`hidden-gcbuild.out.log`、`order-gcbuild.out.log`）。使用的是隔离原生宿主与合成模块，并非长时间 GC 压力、并发卸载、真实模组或完整游戏验收。


真实 0.9 预览模组资源覆盖检查（2026-11-13）：在带隔离存储标记的 `_build/cne-isolated-runtime-219`，以原包 Accurate Week Order 2.0.4（`_build/gamebanana-origin-legacy-20261101/accurate-week-order-preview-1849208.zip`，SHA-256 `e57fb3b65a4693ba0a31a9d68a398e06525873f04a5b0fb7afb4f686b3add549`）启动既有 `NovaFlare-Origin-History-733.exe` 可见窗口。原模组成功挂载并进入主菜单（`accurate-090-visible.out.log`）；自动输入未进入故事菜单，不算交互验收。随后另加载只读诊断模组，在注册表加载后读取 week2–week6 名称和歌曲；`accurate-090-probe.out.log` 五项均与原包 JSON 逐项一致，证明该隔离构建读取到了对应模组数据。检查前后四个既有存档／配置文件的存在性及 SHA-256 一致（`accurate-090-save-before.json`、`accurate-090-save-after.json`）。这不证明故事菜单显示、实际游玩或当前源码构建通过，也不代表其他 0.9 模组均兼容。

CPPIA 宿主同名分类探针（2026-11-13）：`_build/cppia-class-registry-native-777/classification2.out.log` 中，冲突脚本的 Main 未被独立记录，宿主 Main 被判为非编译脚本类，Shared 实例被判为编译脚本类；首次 `classification-before.out.log` 是夹具错误地假设冲突 Main 被独立记录导致断言失败。通过日志中的 “by class identity” 文案过度表述了测试范围：Polymod 分类实现仍基于名称，此结果不证明所有同名类按对象身份分类，也未验证真实模组。


无图标模组空路径修复及字体挂载尝试（2026-11-13）：使用 Devil’s Swing 0.4.1 原元数据和原字体建立无图标隔离夹具；实际 Polymod 在找不到图标时向 LegacyModFileSystem.exists 传入 null，旧实现对该值调用 Path.normalize，Haxe 解释器中抛出空引用（`_build/origin-real-font-polymod-773/error-785.log`）。现令 exists(null) 返回 false，复测通过模组发现并进入资源加载（`result-786.log`），说明已越过该崩溃点；该夹具有意只放元数据及字体，不代表原模组缺少图标。后续 OpenFL 字体注册在独立解释器环境抛空引用（`error-786.log`），因此字体实际挂载与渲染仍未通过。此夹具使用正式 Polymod、Lime/OpenFL、兼容文件系统及真实字体，但旧歌曲布局和 Origin 资源根使用替身；未运行完整游戏或原生构建。两工作区源码均已修复。


无图标模组初始化复测（2026-11-13）：使用仅含真实 Devil’s Swing 元数据、无图标和字体的隔离模组，以及相同的实际 Polymod 和兼容文件系统；`exists(null)` 返回 false，Polymod 完成模组初始化并返回一个模组（`_build/origin-real-font-polymod-773/no-icon-787.out.log`，退出 0）。夹具对旧歌曲布局和 Origin 资源根使用替身，不构成完整游戏、字体加载或真实完整模组启动验收。


真实 Devil’s Swing 字体资源可见运行检查（2026-11-13）：在带隔离存储标记的 `_build/cne-isolated-runtime-219` 使用既有 `NovaFlare-Origin-History-733.exe`，加载 [The Devil’s Swing v0.4.1](https://gamebanana.com/mods/419740) 与只读诊断模组；`Paths.font("fofbb_reg.ttf")` 返回 `assets/fonts/fofbb_reg.ttf`，OpenFL 资源存在且读取到 77116 字节，游戏内计算的 SHA-256 `627ea1ca97f1d2193eb131b4a017c5b20c2c912a823882a71521857f76e760e9` 与原 ZIP 和隔离模组中的字体一致（`_build/gamebanana-origin-legacy-20261101/devils-font-probe-790.out.log`，进程退出 0）。`devils-font-probe-788.out.log` 因监控错误匹配日志中的模组路径而提前退出，不作为通过证据；`789` 已读得相同字节长度，`790` 补充了字节哈希。测试后核对的四个现有存档／配置文件未变。测试基于既有构建，不证明当前源码已重新编译；未验证字体实际绘制或完整歌曲游玩，不能用来宣称整个模组兼容。


真实 Mod Engine 编译脚本的隔离加载失败恢复检查（2026-11-13）：将真实 Mod Engine 1.0.3 原包的 `gameplay/scripts/ModEngine.cppia` 交给 `_build/cppia-class-registry-native-777/host/Main.exe` 中的实验原生加载器。该独立宿主不包含完整游戏类，加载在缺少 `funkin.modding.module.Module` 父类时被拒绝；随后同一进程成功加载、调用和卸载合成对照模块（`real-modengine-791.out.log`，进程退出 0，最低可用内存 3158412 KiB）。这只证明当前独立宿主对该缺失父类的失败处理及后续对照模块可用，不证明真实模组能够在完整游戏加载、正常执行或热重载，也不说明真实模组自身有错误。正式游戏仍未启用 CPPIA。


当前源码 CPPIA 条件类型检查尝试（2026-11-13）：使用现有 `export/release/windows/haxe/release.hxml` 和 FEATURE_CPPIA、POLYMOD_CPPIA、scriptable，执行 Haxe `--no-output` 类型检查；系统可用内存跌至 856204 KiB，监控主动终止本次检查，进程退出 2，内存随后回升。`_build/cppia-current-typecheck-792.out.log` / `.err.log` 不构成类型检查通过或失败结论；HXML 为既有构建生成文件，并非本次重新生成。现存独立 Haxe server 非本次进程，未操作。当前源码的完整类型检查、原生构建和真实 0.9 CPPIA 运行仍未验收。


Mod Engine 宿主类型路径核对（2026-11-13）：将真实 `ModEngine.cppia` 扫描结果中 45 个 `funkin.*` 类型名与既有 Windows release 生成 C++ 的预期文件路径逐项比较，45 个路径均存在，清单见 `_build/cppia-class-registry-native-777/real-modengine-host-inventory-793.json`。这些是旧构建的生成文件，仅证明路径存在；未证明当前源码已生成、全部类型已链接、scriptable 注册、ABI 匹配或运行时可解析。孤立宿主依然缺少 Module，真实完整游戏的 CPPIA 验收仍未完成。


CPPIA 完整宿主生成条件对照（2026-11-13）：旧的普通 Windows release 生成物中，真实 Mod Engine 引用的 45 个 `funkin.*` 类型虽都有对应 C++ 文件，但在这些文件中词法搜索 `__scriptable` 均为零（`_build/cppia-class-registry-native-777/real-modengine-host-inventory-794.json`），不能把文件存在当作可供 CPPIA 继承。独立微型 Haxe 源码分别使用普通参数和 `-D scriptable`、`-D no-compilation` 生成 C++：前者的 Base.cpp 没有该标记，后者生成了 `Base_obj__scriptable` 等包装（`_build/cppia-scriptable-generation-794/ordinary` 和 `scriptable`）。所选 hxcpp 的 `toolchain/common-defines.xml` 还在 scriptable 条件下定义 HXCPP_SCRIPTABLE。该对照确认宿主生成配置需要重新生成并原生构建，不能仅对既有普通二进制打开模组开关；微型生成测试未链接或运行，也不能证明完整游戏各类、依赖及 ABI 兼容。


真实 Mod Engine 字段引用批量筛查（2026-11-13）：使用选定 Polymod CPPIA 扫描器读取原 `ModEngine.cppia`，以全部字符串作为字段筛选键，得到 235 个去重的 `funkin.*` 类型／字段对；逐对检查既有 release 生成 C++ 与头文件，并沿生成头文件中的第一条 C++ 父类链查找，同名词法文本均可找到（`_build/cppia-real-fields-795/review.json`）。初次只检查直接类时有 41 项未找到，沿父类链后归零；这只是文本筛查，可能匹配注释或无关声明，不证明访问权限、签名、继承行为、scriptable 注册或运行时 ABI，也不证明扫描覆盖所有动态引用。该结果尚不能替代真实 CPPIA 模组加载。


0.9 NoteStyle 原生子类路径候选（2026-11-13）：从 `_build/origin-preview-production-shape-lowmem-548` 复制隔离夹具，在候选路径分发遇到原生 NoteStyle 子类时按旧方法的 raw 参数调用一次并转换返回值，候选保存方法桥也允许进入此分支。真实 Polymod/HScript 下，子样式回退到原生父类的直接／保存调用由原先错误的 `native-default` 改为 `native-custom`，调用次数从两次降至一次（`_build/origin-notestyle-native-subclass-796/result.out.log`）；新增直接调用原生子类的测试在仅修改路径分发时失败（`direct.err.log`），进一步修改隔离保存方法桥后通过（`direct2.out.log`），原九路径及黑名单夹具仍通过。该候选仅测试 getNoteAssetPath；buildCountdownSpritePath 未有 raw 参数仍返回未处理，其他原生方法、返回已处理路径的覆盖、脚本 super、实际资源与原生构建尚未覆盖，因此没有接入正式源码，也不能宣称原生子类缺口已修复。


0.9 NoteStyle 原生子类路径适配（2026-11-13）：在预览版本脚本调用中，当路径查找遇到原生 NoteStyle 子类时，对支持 raw 参数的旧虚方法按原始路径调用并将结果转换为预览 AssetPath；保存的方法和脚本 super 同样进入此路径，继续检查字段黑名单。隔离夹具 `_build/origin-notestyle-native-subclass-796` 使用实际 Polymod/HScript、正式路径辅助类及宏、替身样式／资源，覆盖除倒计时图像外八种路径的直接／保存调用、直接原生子类与子样式父回退、库名前缀、参数和单次调用，以及空值、异常、黑名单、脚本 super 和旧版对照（`post-integration.out.log`，退出 0）。hold cover 子样式回退仍按上游顺序先取父级 root，不把父方向路径当 root。旧 `buildCountdownSpritePath` 没有 raw 参数，可能已剥离库名前缀，故继续使用此前回退路径，该原生子类情形仍未修复；脚本 super 的完整排列、真实资源、真实模组及原生构建也未验收。改动已同步两工作区。


原生 NoteStyle 继承与 super 访问限制复核（2026-11-13）：新增未覆盖任何路径方法的原生子类和以其为父样式的用例，九路径的直接／保存调用在替身资源中保持库名前缀，hold cover 子样式回退到父 root（`_build/origin-notestyle-native-subclass-796/inherited-fallback.out.log`）。继续测试脚本对原生子类的 super 直接调用时，发现上次接入的提前分支可绕过原生类字段黑名单（`super-blacklist.err.log`）；现调用路径解析前按实际原生类及其继承关系检查黑名单。针对原生子类及 NoteStyle 基类分别设置黑名单，验证直接与保存 super 均拒绝，正常路径、旧版、空值及异常回归继续通过（`super-blacklist-final.out.log`，退出 0）。实际资源、完整原生构建和真实模组仍未验收；原生子类的倒计时覆盖缺口仍存在。两工作区同步。


正式回归入口补充原生样式父类（2026-11-13）：`LegacyPublicApiChecks` 增加仅供显式回归运行的原生 NoteStyle 子类，使用 `funkin` 已加载样式的真实 hold 原始路径作为覆盖结果；构造直接子类及注册表父回退两种情况，检查 0.9 HScript 直接／保存调用返回对应 AssetPath、以 raw 参数恰好调用一次，并在异常路径移除临时注册。两个工作区已同步。独立替身夹具的路径辅助类和宏与正式源码逐字一致，`previewNoteStylePathResult` 和 `previewNoteStylePathMethod` 主体也逐字一致；该正式新增用例尚未随完整项目编译或运行，不能当作真实注册表、资源或构建通过的证据。隔离夹具另覆盖八种原生方法的脚本 super 直接／保存调用（`_build/origin-notestyle-native-subclass-796/super-eight.out.log`）。


正式原生样式回归主体隔离检查（2026-11-13）：从 `LegacyPublicApiChecks` 原样提取新增原生父类和回归主体，结合真实 Polymod/HScript、正式路径桥及宏，使用替身 NoteStyle 数据、AssetPath、注册表和调用适配器运行，直接子类与注册表父回退的直接／保存调用及成功后临时注册清理通过（`_build/origin-formal-native-probe-797/result3.out.log`，退出 0）。首次夹具因调用私有 API 和替身动态调用缺少类型上下文而未通过，修正夹具后才获得结果。此检查不能替代完整工程编译、真实注册表/资源或错误路径的实际运行。


正式原生样式回归清理路径隔离复核（2026-11-13）：在 `_build/origin-formal-native-probe-797` 以提取的正式回归主体运行成功和强制断言失败两条路径；失败用例确认异常确由 native parent 断言触发，且临时注册均被清除（`success-final.out.log`、`failure-cleanup3.out.log`，均退出 0）。真实注册表、游戏资源和完整构建仍未验证；首次强制失败夹具因试图重绑定静态方法未编译，不算有效结果。


原生到脚本父样式混合回退（2026-11-13）：在 `_build/origin-notestyle-native-subclass-796` 给未覆盖旧路径方法的原生子类清除本地 note 路径，并接上返回 AssetPath 对象的脚本父样式；真实 Polymod/HScript 解释器的直接与保存调用均保留对象身份且只调用一次（`native-to-script-before.out.log`，退出 0），样式、路径和版本识别为替身，未覆盖 hxcpp 原生转换。试图将同一夹具编译为 Neko 做第二目标验证时，当前 Polymod 的 `PolymodStaticAbstractReference.hx` 产生空安全类型错误（`neko-build.err.log`），未生成或运行 Neko 用例；不能据此判断混合回退在 Neko 或 hxcpp 上通过。


Origin 预览上游增量与修复（2026-11-13）：官方 `main` 仍为 `94ee0f2a9386d80e445be39ee2ed4b4a630cfbac`；`preview/public-playtest` 从 `8712214ec7a94d2ed3fd74844c1a9c738d4c92c8` 前进 5 个提交至 `11c42037d664f4437c6187fef3bb88893931930b`，涉及 CharacterRegistry、ModuleHandler、BaseFreeplayDJ、ModReloader 和依赖版本（https://github.com/FunkinCrew/Funkin/compare/8712214ec7a94d2ed3fd74844c1a9c738d4c92c8...11c42037d664f4437c6187fef3bb88893931930b）。依赖版本未直接升级；CharacterRegistry 脚本查询回退和热重载线程位置还需单独核对，不能视为已全部移植。

Freeplay DJ 资源查询空值回退：上游修复脚本查询结果被丢弃并在结果为 null 时采用渲染器默认资源；本地已保留非空脚本结果，但原先把 null 提前转为空列表。现令 null 回退默认渲染器，显式空数组仍表示无资源，异常继续使用原 ScriptGuard 空列表回退。`_build/origin-freeplay-dj-null-798` 提取正式查询方法并使用真实 Polymod/HScript 和资源／注册表替身：修复前复现 null 未回退（`before.err.log`），修复后 null、显式空数组和自定义结果通过（`final.out.log`）；递归脚本夹具在 ScriptGuard 捕获 Null Access（`after-recursion4.out.log`），原因未定位，递归路径未通过且不能判定为真实游戏故障。未验证实际模组预加载或完整游戏，改动同步两工作区。

异步模块完成顺序：原本先完成 Lime Promise、再排序模块，而 Lime 完成监听器同步执行，可能先看到未排序缓存；上游还将排序放到 onCreate 前。现完成 Promise 前先排序，并在 onCreate 前再次排序。`_build/origin-module-async-order-799` 提取实际完成闭包及 onCreate，使用真实 Lime Promise 与替身缓存／事件；旧顺序在完成回调复现未排序（`before.err.log`），修正后完成通知和 onCreate 排序通过（`create-after.out.log`）。未覆盖真实多线程竞争、实际模块加载或完整构建；两工作区同步。


注册表脚本资源查询空值回退（2026-11-13）：针对上游 CharacterRegistry 修复及其回退行为，本地 BaseRegistry 的通用查询在脚本返回 null 时现回退现有默认查询；显式空数组仍不回退，脚本报错仍按 ScriptGuard 原逻辑返回空列表。供预加载专用的 `queryScriptedAssets` 仍只返回脚本显式资源，null 继续对外表现为空列表，避免扩大预加载范围。`_build/origin-registry-null-800` 从正式代码提取方法，以替身脚本桥、注册表和 ScriptGuard 复现修复前 null 不回退，并在修复后检查 null、空数组、指定结果、异常及无脚本（`before.err.log`、`after.out.log`）；未运行真实 HScript、角色资源或完整构建。两工作区同步。

热重载卸载阶段线程位置（2026-11-13）：依据 Origin 预览上游将脚本／模块清理移到异步加载任务之前的变更，`HotReloadState.queueLoadEnabledMods` 现先在调用线程清理模块和脚本，再启动原有异步加载；清理失败时沿用报告并继续后续阶段的错误路径。Lime 的 FutureWork 经 ThreadPool 事件分发完成通知，SDL2 分支的上一阶段由 OriginRegistryLoader.defer 主线程执行；但本次没有在真实游戏窗口测量线程身份。`_build/origin-hotreload-main-thread-801` 提取该方法，模拟主线程和异步任务：旧代码在模拟工作线程清理时失败，修复后验证清理先于任务、加载与缓存顺序以及清理抛错时的收尾（`before.err.log`、`failure-after.out.log`）。该检查使用任务与模块替身，真实多线程热重载和已启用模组状态仍未验收；两工作区同步。


Freeplay DJ 递归查询夹具纠正（2026-11-13）：此前 `_build/origin-freeplay-dj-null-798` 的递归 HScript 空引用发生在调用原生类方法时；夹具遗漏了正式工程给 Polymod Interp 添加的 `nullDeprecationSafety` 宏。补齐该宏及 staticScriptContextSafety 后，递归脚本可调用默认渲染器查询，两次连续查询均返回预期资源数量，null、显式空数组与自定义结果回归通过（`recursion-final.out.log`，退出 0）。因此先前 Null Access 是该夹具配置缺陷，不作为真实游戏故障；使用真实 Polymod/HScript 与正式查询方法，但注册表、资源和 ScriptGuard 仍为替身，未在完整游戏或真实模组中验收。


注册表脚本错误边界补充（2026-11-13）：`origin-registry-null-800` 的报错用例使用直接抛异常的脚本桥替身，只证明抛到 ScriptGuard 的异常继续返回空数组，不能涵盖 Polymod 在解释器内部捕获后返回 null 的脚本错误。源码 `Interp.callScriptClassStaticFunction` 对 `Expr.Error` 会报告错误并返回 null；按新的 null 回退逻辑，这种情况会进入默认资源查询，不保持此前空列表行为。`origin-registry-hscript-null-802/result.out.log` 用真实 Polymod/HScript 验证正常 null、显式空及自定义结果；错误分支复测因可用内存跌至 738120 KiB 被监控终止（`error-check.*.log`），没有运行结果。以上修正此前对所有脚本异常语义保持不变的表述；实际游戏仍需验证。


真实 HScript 资源查询异常复核（2026-11-13）：`_build/origin-registry-hscript-null-802` 用实际 Polymod/HScript 执行 `BadEntry.queryAssets` 的脚本抛错，验证错误被报告、Polymod 返回 null 后通用注册表采用默认资源；正常 null、显式空数组和自定义结果同时通过（`error-assert.out.log`，退出 0，最低可用内存 1895696 KiB）。这是对上一段源码推断的隔离运行确认；注册表、AssetPath 和 ScriptGuard 为替身，未验证真实角色或游戏。


异步模块重复 ID 收尾修复（2026-11-13）：`loadModuleCacheAsync` 以前用模块缓存中唯一 ID 的数量加错误数判断全部任务完成；两个不同模块类返回相同 moduleId 时，后者覆盖缓存项，完成任务数为二但缓存数量仍为一，Future 可能一直等待。现单独按成功／错误回调次数统计完成任务，保留既有缓存覆盖与加载结果计数；模块任务完成通知由现有 TaskHandler/ThreadPool 传回调用侧，未改变其调度。`_build/origin-module-duplicate-803` 提取正式完成闭包并使用真实 Lime Promise、替身缓存和任务：旧逻辑复现两个任务共享一个 ID 时不结束（`before.err.log`）；修复后覆盖唯一 ID、重复 ID、成功/失败混合和全部失败，确认不提前完成且仅完成一次（`scenarios.out.log`）。真实多模组、并发回调、同名模块获胜顺序及完整游戏仍未验收；该检查不代表所收集的真实模组已经复现不同类共享 ID。两工作区同步。


异步模块登记异常收尾（2026-11-13）：模块构造完成并不保证登记缓存成功；例如 moduleId 为 null 时，所选 haxe-concurrent 的 SynchronizedMap 在 Haxe 解释器中抛 Null Access（`_build/origin-null-module-804/result2.out.log`）。此前成功回调中的 `onModuleLoaded` 若抛错，不会进入任务错误回调或完成计数，后续模块也可能无法让 Future 收尾。现在该登记异常转入现有 onError，计为失败后继续处理其他完成任务；原模块缓存和失败报告机制保留。`_build/origin-module-callback-failure-804` 提取实际完成及回调代码，使用真实 Lime Promise、haxe-concurrent 同步映射与数组、模块替身：修复前空 ID 登记抛错后完成信号缺失（`before3.err.log`），修复后空 ID 计一次失败、后续有效模块仍加载且 Future 完成（`after.out.log`）。此前两次夹具编译缺少项目的同步数组扩展或类型别名，不能作为结果。该样本为合成模块，未验证真实模组、原生多线程或完整游戏；两工作区同步。


历史舞台角色 pop 接口批量筛查（2026-11-13）：对本地保存的 25 个 Origin 正式版本源码快照中 Stage.getDad/getBoyfriend/getGirlfriend 与当前实现进行词法检查，均找到对应角色键、pop 条件、舞台移除与角色映射移除语句；这些接口也被隔离目录中的多份真实旧模组脚本调用。逐版本源码哈希及检查结果见 `_build/origin-complete-version-audit-233/stage-role-pop-review-805.json`。该检查不证明控制流、事件、对象生命周期或所有历史版本的行为等价，未实际触发真实模组的 pop 分支，不据此宣称接口已全面兼容。


Origin 0.9 依赖上游变更与 CPPIA Bool 修复候选（2026-11-13）：预览分支将 hxcpp 从 `d5bda40ac13f2823fe1bdcb5476e0eb027f1e7e9` 更新到 `2c38e141704465b41ddff59bfdaab42121ab64ed`，新提交修正 CPPIA 中按整数存储的 Bool 经动态反射读取时返回整数的问题（https://github.com/FunkinCrew/hxcpp/commit/2c38e141704465b41ddff59bfdaab42121ab64ed）。以独立原生宿主和合成 CPPIA 模块复现原始布尔反射类型断言失败（`_build/cppia-bool-upstream-806/before.out.log`，退出 -1）；将上游对应修改应用到隔离 hxcpp 副本后，单线程编译 CppiaVars 对象并在复制的宿主中重新链接，Bool true/false 以及 Int 对照通过（`after.out.log`、`bool-int.out.log`，均退出 0），先前多代类注册和三次 GC 对照仍通过（`gc-regression.out.log`）。首次对象编译使用了与宿主不同的运行库选项，链接以 LNK2038 失败，改为匹配选项后重新链接成功；最终链接仍有既有 PCH 重复对象 LNK4042 警告。补丁和校验安装器为 `tools/hxcpp-origin-cppia-bool.patch`、`tools/setup-hxcpp-origin-cppia-bool.ps1`，单文件隔离安装、验证、逐字节回滚及拒绝未知更改通过；它依赖先应用基础 CPPIA 补丁，回滚基础补丁前先回滚本补丁。仅实验源码与隔离宿主使用该修正，正式 hxcpp 和游戏未启用或编译，真实模组未验收。

预览分支同时将 Polymod 从 `4f52985b5c8190f427aecdb7a87a1bd3e7ec1814` 更新到 `8f488e00a47d484010d64577aff3174cb7ac0cd8`；最后提交给 HScript 静态调用、字段和函数检测增加 CPPIA 目标分支（https://github.com/FunkinCrew/polymod/commit/8f488e00a47d484010d64577aff3174cb7ac0cd8），本地所选 Interp 对应方法尚无该分支。该上游增量和其余五个 Polymod 提交仍需与本地黑名单、同名优先级、生命周期补丁共同审查和测试，尚未移植，不能据此宣称 0.9 编译模组可用。Lime 更新主要触及 miniaudio 配置，与本次已复现的 CPPIA 布尔问题独立，未直接升级本地依赖。


CPPIA 静态脚本桥候选（2026-11-13）：参考 Polymod 上游 `8f488e00a47d484010d64577aff3174cb7ac0cd8`，在隔离 Interp 为仅有 CPPIA 类的静态函数调用、字段/函数检测和字段读取增加分支；另补静态字段写入，保留已有 CPPIA 引用的字段黑名单检查，同名 HScript 描述符优先。`_build/polymod-cppia-static-bridge-807` 使用真实 Polymod Interp、真实 CPPIA 引用类与 HScript 解析器，但将普通 Haxe 类手动登记为编译类替身：旧代码复现静态函数不可发现（`before.err.log`）；候选检查调用、读取、写入、缺失字段、黑名单及同名 HScript 优先（`security.out.log`）；未启用 CPPIA 时普通 HScript 静态读写调用也通过（`no-cppia.out.log`）。补丁和安装器为 `tools/polymod-origin-cppia-static-bridge.patch`、`tools/setup-polymod-origin-cppia-static-bridge.ps1`，隔离安装、验证、逐字节回滚及拒绝未知更改通过；需要现有 CPPIA 加载器和可运行的 scriptable hxcpp。只在隔离副本验证，真实 CPPIA 原生类、完整游戏、热重载及上游其余增量仍未验证，所选 Polymod 正式依赖未安装此候选。


真实 CPPIA 静态桥原生宿主构建尝试（2026-11-13）：`_build/cppia-native-static-bridge-808` 使用真实编译的合成 CPPIA、候选 Polymod Interp 和隔离 hxcpp 补丁副本准备原生调用/读写/卸载检查。首次源码生成遗漏 hxcpp 条件，虽然宿主构建成功但加载器返回空，因此 `native-run.out.log`（退出 -1）不能评价候选桥；补齐 hxcpp 条件后重新生成。第一次单线程构建达到时限被终止，留下损坏对象导致下一次链接 LNK1136；已将该隔离对象移到 `.interrupted` 并重新编译成功。补齐条件后的第二轮构建因编译条件变化重新编译对象，执行约 391 秒后系统响应和内存查询明显变慢，主动停止本次编译器进程树；日志 `native-build4.out.log` 最后显示 haxe 组约 48%，监控记录最低可用内存 2566264 KiB，进程退出 1，不构成构建通过。停止后未见本次 cl/neko/link 进程。中断时最后正在处理 Sys.cpp，其对应对象可能不完整，后续继续前应核对并重新生成，不得把残缺对象当作可用证据。正式游戏和用户依赖未更改，真实 CPPIA 桥接运行仍未验收。


Polymod 上游 accessor 差异待验证（2026-11-13）：对比 `4f52985b5c8190f427aecdb7a87a1bd3e7ec1814` 与 `8f488e00a47d484010d64577aff3174cb7ac0cd8`，上游 Interp/脚本引用增加了 `@:bypassAccessor` 状态及相关读写传播；本地 Interp 的未识别元数据分支直接计算原表达式，尚无该标记的专门逻辑。本地 Origin 的 Haxe 源码也有此标记，但那是 Haxe 编译路径，不能据此证明 HScript 支持或故障；当前收集的模组 HXC 中未找到该标记。上游实现进入 bypass 状态后直接求值再复位，若求值异常能否正确恢复状态需要实际验证，不应不加审查整体覆盖本地已修改的解释器。已准备 `_build/polymod-bypass-accessor-809` 隔离对照，当前系统 CPU 接近满载且可用内存约 1.4 GiB，为保护电脑尚未运行；其测试源码不构成复现或修复证据。


Polymod 上游导入优先级差异待验证（2026-11-13）：对比 `4f52985b5c8190f427aecdb7a87a1bd3e7ec1814` 与 `8f488e00a47d484010d64577aff3174cb7ac0cd8`，上游在 ClassImport 增加默认导入标记，并在脚本类与接口导入合并时区分默认项和已有显式导入；本地当前 Interp 尚无该标记，部分导入合并直接覆盖。`_build/polymod-import-precedence-810` 已准备默认 `a.Paths` 与显式 `b.Paths` 的 HScript 对照，但因系统 CPU 满载、内存紧张尚未运行；这只是待审查差异，不证明已发生真实模组故障，也未改动正式依赖。包级 import.hx、通配符与同名脚本类的优先级仍需一并验证。


脚本导入优先级隔离复现（2026-11-13）：`_build/polymod-import-precedence-810` 在真实本地 Polymod/HScript 中注册默认 `a.Paths`，再让脚本显式导入 `b.Paths`；`before3.err.log` 显示实际取得 default，未达到显式导入应获优先权的预期。`_build/polymod-import-precedence-811` 准备了参考 Polymod 上游 8f488e00 的隔离修复候选，保留黑名单并区分默认项和包级 import.hx；因 CPU 达 88% 暂未运行修复后测试。此为合成夹具，未证明真实模组已受影响，候选尚未安装到正式依赖；通配符、脚本接口、重名类和真实游戏仍需验证。上文“尚未运行”所述导入夹具状态以本条为准。

Accessor 夹具状态更新：`_build/polymod-bypass-accessor-809` 首次因 Haxe 属性夹具定义不完整而无法编译，补正后 HScript 解析在分号处报错；尚未隔离具体语法原因，因此不能作为 accessor 兼容通过或失败的证据。


脚本导入优先级候选验证（2026-11-13）：`_build/polymod-import-precedence-811` 使用真实 Polymod/HScript 与合成类，`after.out.log` 验证显式类可覆盖默认类且包级导入不覆盖显式类；扩展用例 `scenarios.out.log` 发现显式导入与默认导入路径相同时，后续 import.hx 仍会覆盖，隔离候选进一步将该显式导入标记为非默认。`scenarios3.out.log` 覆盖默认类、显式覆盖、别名、包级覆盖默认、显式覆盖包级和 `blacklistImport` 原生类黑名单，退出 0。`scenarios2` 使用了仅用于脚本类的 blacklistScriptClassImport 测试原生类而失败，是夹具 API 选择错误，不代表正确原生黑名单通过或失败。候选补丁和严格校验安装器为 `tools/polymod-origin-import-precedence.patch`、`tools/setup-polymod-origin-import-precedence.ps1`；隔离安装/验证、逐字节回滚和拒绝未知改动通过。该安装器仅支持已核对的基础版本，无法直接与其他修改 Interp 的候选叠加；通配符、脚本接口、实际模组、正式依赖和游戏仍未验证，不能宣称正式修复已部署。


导入优先级与 CPPIA 静态桥组合候选（2026-11-13）：两份候选补丁已在 `_build/polymod-combined-812` 隔离副本顺利叠加；这只证明补丁可应用，不证明组合运行正确。检查 `importWildcard` 发现其在构建通配符候选列表时，遇到任何同名已有导入都会提前跳过，包括默认导入，因此外层针对默认导入的优先级处理可能无法生效；已准备同时覆盖通配符、显式类、默认类和包级导入的合成用例。系统 CPU 达到 99–100%，负载保护拒绝启动组合测试，尚无通配符故障复现或修复后证据；真实 CPPIA 原生宿主和正式依赖同样未验收。


通配符导入审查补充（2026-11-13）：`_build/polymod-combined-812` 的组合夹具新增包级 import.hx 与显式通配符同名冲突场景；另在 `_build/polymod-combined-wildcard-813` 独立准备只放宽默认项过滤的候选，用于检查是否还需要区分包级和显式通配符的优先级。两组尚未运行，不能把词法审查或准备好的候选视作复现与修复。当前另有 Unity 构建和编辑器安装正在消耗系统资源，未终止用户进程；候选仍未进入正式依赖。已在所保存的七组 GameBanana 样本目录中搜索 HXC/HX 的通配符 import 语句，本次搜索没有命中；不代表其他模组没有使用。


组合补丁交付准备（2026-11-13）：从已叠加的隔离候选生成 `tools/polymod-origin-combined-import-cppia.patch` 及 `tools/setup-polymod-origin-combined-import-cppia.ps1`，解决两份候选分别安装时都需要修改同一 Interp 文件、严格哈希互不兼容的问题。对隔离基础源执行安装、校验、逐字节回滚及拒绝未知修改均通过；脚本和补丁同步两个工作区。组合代码尚未运行组合 HScript/CPPIA 回归，不包含 `_build/polymod-combined-wildcard-813` 的未验证通配符候选，正式依赖未安装。需先验证组合运行、真实原生 CPPIA 与完整游戏再考虑部署。


通配符导入隔离复现（2026-11-13）：负载短暂回落后运行组合夹具，`_build/polymod-combined-812/imports.err.log` 显示脚本 `import b.*` 获取到同名默认 `a.Paths`，与预期不符。`_build/polymod-combined-wildcard-813/imports.err.log` 显示只允许通配符覆盖默认导入后，脚本 `import a.*` 仍被包级 `import b.Paths` 覆盖；两次均为真实 Polymod/HScript、合成原生类及人为登记的包列表。已在 `_build/polymod-combined-wildcard-814` 准备区分包级来源的隔离候选，但启动前 CPU 再次达到 100%，保护条件阻止测试，候选未验证，正式组合补丁也未包含该候选。不能由合成夹具推断真实模组受影响或已修复。


通配符及组合候选验证（2026-11-13）：`_build/polymod-combined-wildcard-814` 为包级导入添加独立来源标记，使显式通配符可以覆盖包级和默认项，同时避免覆盖显式类导入；在真实 Polymod/HScript 的合成类夹具中，`imports.out.log` 覆盖默认、显式、别名、显式通配符、包级覆盖、包级与通配符冲突和原生类黑名单，退出 0。相同候选 `bridge.out.log` 使用普通 Haxe 类模拟 CPPIA 注册，检查静态调用、读写、黑名单和同名 HScript 优先，`no-cppia.out.log` 检查关闭 CPPIA 的普通脚本静态操作，均退出 0。已更新 `tools/polymod-origin-combined-import-cppia.patch` 和安装器，并在隔离根验证安装、逐字节回滚及拒绝未知改动；同步两个工作区。上述仍是合成测试；脚本接口导入、真实 CPPIA 原生模块、真实模组和完整游戏未验证，正式依赖未安装组合候选。


Accessor 夹具解析错误定位（2026-11-13）：本地 Parser 对元数据名后紧跟的圆括号优先调用 `parseMetaArgs()`；此前 `_build/polymod-bypass-accessor-809` 写成 `@:bypassAccessor (o.value=20)`，括号被解释成元数据参数，后续表达式从分号开始解析而报错。已在隔离夹具中改为不带该括号的赋值表达式，尚未重新运行；这解释了此前解析失败，不证明 bypassAccessor 行为通过或失败。


新增真实 0.7.3 模组样本（2026-11-13）：[Your Idol Chart (PC)](https://gamebanana.com/mods/617732) 作者说明适配 0.7.3，0.7.4 亦可使用；本地保存官方修正版 ZIP `_build/gamebanana-your-idol-815/v-slice_fix_your_idol_chart_pc_.zip`，40,680,485 字节，SHA-256 `b6051588c40f748764e3ec5f7ce08f4dc0ce4d9d669a2dcbfd32093c21104a13`。包内元数据声明 API 0.7.3、模组 1.2.0；目录索引含角色、歌曲、事件、模块和音符 HXC。谱面 2.0.0 有 easy/normal/hard 352/454/578 个音符，包含 46 个 ChangeCharacter、4 个 ChangeStage 以及多个 extra-events 特效事件。作者页面将 Stage Changer+ 与 Extra Events 列为推荐依赖，未安装依赖时相关演出不可当作引擎兼容失败。上述仅为 ZIP 元数据和谱面静态检查，未加载模组或进行游戏验收。


Your Idol 0.7.3 角色切换预检（2026-11-13）：原包 46 个 ChangeCharacter 事件的 `character` 均为 bf/gf/dad，`newchar` 均为非空字符串；其中 10 个目标角色 JSON 随模组提供，`pico` 依赖外置基础资源。脚本引用旧路径 `funkin.play.character.CharacterDataParser` 的 listCharacterIds/fetchCharacter；当前 PolymodHandler 已将该路径映射到兼容类，兼容类也声明这两个方法，Stage 声明了 addCharacter 和角色槽位 getter。模组在倒计时预取每次切换目标，可能反复创建同 ID 角色；是否造成泄漏或影响运行需实际测试，不能仅凭静态代码归因。以上只核对名称、数据形状和存在性，不证明脚本加载、资源或角色切换行为通过。


Your Idol 推荐依赖样本（2026-11-13）：根据模组页面列出的链接，取得 [Stage Changer+](https://gamebanana.com/mods/587120) 原 ZIP（20,377 字节，SHA-256 `3a1f4b7ba326939226aa651a9174becc718b763b2207786a7282b31469eabdf3`，元数据 API 0.6.3、模组 1.1.0，包含 scripts/events 和 scripts/modules），以及 [Extra Events 1.2.0](https://gamebanana.com/tools/19459) 历史原 ZIP（36,496,915 字节，SHA-256 `1725a6a48edcc74a3430436945fbf4d1154788c5c7cd7314c00fc4b0f9751934`，元数据 API 0.7.3）。两包保存在 `_build/gamebanana-your-idol-815`，尚未启用或运行。Extra Events 原包的 HXC 位于顶层 events 和根目录、未发现 scripts 目录；其安装或资源映射要求仍待核对，不能据此判定游戏故障或擅自改写原包。两个推荐依赖及组合运行、舞台切换和特效均未验收。


Extra Events 历史包路径核对（2026-11-13）：另取得 1.2.1 原 ZIP `_build/gamebanana-your-idol-815/extra-events_fb8f9.zip`（36,781,970 字节，SHA-256 `32c079cac3ebe9b8e7f02491ea8f7d7eee92bff82d40356a9618672fd4da3b20`），元数据为 API 0.7.4，HXC 同样分布在顶层 events 和根目录。检查所选 Polymod 的同步 registerAllScriptClasses：它扫描资源库列出的全部 TEXT 文件，按 scriptClassExt 判断扩展名；PolymodAssetLibrary 默认将 hxc 标记为 TEXT。因此不能仅凭没有 scripts 目录断定这两个历史包布局有误；实际后端能否列出并读取这些 ZIP 中的路径、异步路径及脚本是否成功注册仍需运行验证。作者当前 [Extra Events 仓库](https://github.com/MAZ12211/extra-events)使用 scripts 目录，也不能倒推历史包不可用。两份历史 ZIP 均未安装。


导入与访问器补充测试（2026-11-13）：组合候选 `_build/polymod-combined-wildcard-814/interface.out.log` 对真实 Polymod 解释器注册的合成接口检查默认、显式、通配符及包级导入优先级，退出 0；`imports2.out.log` 在既有脚本类场景之外增加通配符黑名单访问对照，退出 0。仍未验证真实 CPPIA、完整游戏和真实模组。修正元数据语法后 `_build/polymod-bypass-accessor-809/before4.out.log` 显示原生 `@:isVar` getter 测试中 `Reflect.hasField=true`，普通脚本读取取得原始值 4 而 getter 调用 0 次，期望调用 getter 返回 14，故在普通读取断言失败，尚未进入 bypass 测试。源码对应分支优先 Reflect.field；这只证明真实 Polymod/HScript 与合成原生属性在 Haxe 解释器目标中的行为，不证明真实模组受影响或原生 C++ 行为一致，也不证明 bypass 已实现或未实现。


访问器对照结论修正（2026-11-13）：进一步核对 [Polymod 上游 8f488e00 的 Interp](https://github.com/FunkinCrew/polymod/blob/8f488e00/polymod/hscript/_internal/Interp.hx)，对普通原生对象、非 HashLink 目标且 `Reflect.hasField` 为 true 的读取仍优先使用 `Reflect.field`，与本地分支相同。因此前述合成 `@:isVar` getter 用例虽如实记录了 Haxe 解释器中的行为，但不能视为本地相对该上游的兼容回归，不能仅依据 Haxe 编译语义修改它。上游新增 bypass 状态还会影响脚本代理、脚本静态属性和字段赋值等路径，这些仍需另设有效用例核对。


HScript 静态属性 bypass 差异复现（2026-11-13）：`_build/polymod-bypass-accessor-809/ScriptPropertyMain.hx` 使用真实 Polymod/HScript 注册合成脚本静态 getter/setter，`script-property4.out.log` 显示普通读取 14、getter 一次；带 `@:bypassAccessor` 的读取仍为 14 且 getter 次数增加，带该元数据的赋值仍调用 setter 一次。当前 Interp 的未知元数据分支直接执行表达式；[上游 8f488e00](https://github.com/FunkinCrew/polymod/blob/8f488e00/polymod/hscript/_internal/Interp.hx) 已对该元数据设置绕过状态并传播到脚本静态属性。先前 `script-property` 因夹具未授权私有测试入口无法编译，`script-property2/3` 因脚本引用及初始化方式错误不能作为行为证据；有效的第四次只是打印对照，并非上游修复或实际模组通过。未发现已收集真实 HXC 使用此元数据，现有项目 Haxe 源码使用不等于脚本使用，真实 C++、脚本实例/父类、异常恢复和黑名单仍未验证。


HScript 静态访问器隔离候选（2026-11-13）：在组合候选上建立 `_build/polymod-accessor-817`，参考上游为解释器元数据、脚本类静态引用及静态属性读写传播 bypass 标记；额外在元数据求值异常时恢复原状态。`script-property.out.log` 对合成静态属性记录普通读取 14、getter 一次，标记读取 4、getter 次数不增加，标记写入后读取 20、setter 零次，进程退出 0。该用例目前为打印结果、未自动断言，且实例、脚本父类、原生引用、黑名单、异常恢复和真实 CPPIA 尚未验证；候选不完整，未更新正式组合补丁或安装正式依赖。


HScript 访问器扩展候选（2026-11-13）：在 `_build/polymod-accessor-817` 将上游绕过状态传播扩展到脚本实例、脚本父类及原生字段辅助路径，元数据异常时恢复原状态。真实 Polymod/HScript 合成夹具自动断言：静态 `static-assert.out.log`、实例 `instance.out.log`、继承实例 `inherited.out.log`、异常后普通 getter 状态恢复 `exception.out.log` 均退出 0。新增实例字段黑名单读写夹具，但运行前内存不足，尚无结果；原生父类代理、静态字段黑名单、真正 C++、真实模组及同导入/CPPIA 桥完整组合回归未验收。本候选尚未制作安装补丁，正式依赖未更改。


访问器安全与组合回归（2026-11-13）：`_build/polymod-accessor-817/blacklist.out.log` 自动断言脚本实例的黑名单字段在 bypass 读写下仍报错并返回 null，退出 0。组合回归先发现启用 `POLYMOD_CPPIA` 时访问器候选为父类 getField/setField 添加参数，既有 CPPIA 子类重写签名不匹配而编译失败（`bridge.err.log`）；隔离副本将相同可选参数添加到子类，保留该子类现有 Reflect 字段访问和黑名单行为。修正后 `bridge2.out.log`（普通 Haxe 类模拟 CPPIA 静态调用/字段/黑名单）、`no-cppia2.out.log` 和 `imports2.out.log` 退出 0；这些不替代真实原生 CPPIA 或完整游戏验证。访问器候选仍只在隔离目录，未更新正式组合补丁或正式依赖，原生继承、静态黑名单等仍待验证。


Haxe eval 原生字段黑名单差异（2026-11-13）：`_build/polymod-accessor-817/native-accessor3.out.log` 中，合成原生类调用 blacklistInstanceFields 后仍可读写该字段；诊断显示 Util.getTypeNameOf 实例为 `Class<NativeProperty>`，注册黑名单的 Type.getClassName 为 `NativeProperty`，解析结果为空。使用未打访问器候选的原始 Polymod 重复得到相同名称不匹配及未拦截（`_build/polymod-native-blacklist-baseline-818/result.out.log`），说明 eval 合成用例的问题并非访问器候选新增。隔离候选针对 `#if eval` 用 Type.getClassName 后，`native-accessor4.out.log` 自动断言普通 setter、bypass 读写及黑名单拦截通过。此修正仅在候选副本，尚未验证 Windows C++ 的类型名、其他对象及真实脚本；不应把 eval 结果当作原生安全漏洞或全平台修复结论，也未安装正式依赖。


访问器只读与兼容回归（2026-11-13）：`_build/polymod-accessor-817/static-safety.out.log` 自动检查标记赋值不能写静态 `never` 属性，静态黑名单字段的标记读写均报错，退出 0；`notestyle.out.log` 使用已有真实 Polymod/HScript、项目 NoteStyle 宏和替身资源的原生子类夹具，检查直接/保存路径、脚本 super 和字段黑名单等既有边界，退出 0。该回归没有专门验证原生父类属性的 bypass，也未运行 C++ 或真实模组，访问器候选仍未安装正式依赖。


Polymod 七文件组合候选打包（2026-11-13）：已将导入优先级、CPPIA 静态桥与 HScript 访问器隔离候选整理为 `tools/polymod-origin-integrated-cppia-accessor.patch` 和 `tools/setup-polymod-origin-integrated-cppia-accessor.ps1`，包括当前已叠加 CPPIA 加载器的精确源基线及仅 eval 类型名修正。隔离副本完成安装、Verify、7 文件逐字节回滚和拒绝未知改动，并同步两工作区；此前各项是合成 HScript/替身验证，不代表完整游戏或真实原生 CPPIA 通过。正式依赖尚未安装，其他基线或先前组合补丁已安装时严格哈希会拒绝，不得强行覆盖。


CPPIA 原生桥续构准备（2026-11-13）：对上次中断附近的两个 `Sys.obj` 用 dumpbin /headers 检查均可读取 x64 COFF 头，但头可读不证明整个对象可用；已仅在 `_build/cppia-native-static-bridge-808/generated/obj/msvc1964` 将它们改名为 `.before-resume` 保留，后续须重新生成。首次续构误从生成目录直接调用 hxcpp 的 run.n，因其要求当前目录为 hxcpp 根目录而提示缺少 hxcpp.n，超时结束，未编译（`native-build5.out.log`）。已改为直接调用隔离工具的 hxcpp.n 并设置 HXCPP 与单线程环境，但可用内存约 1.1 GiB，启动保护阻止了该次构建；真实原生静态桥仍未验收。


CPPIA 原生续构中止（2026-11-13）：`native-build6.out.log` 因把 `-64` 误作 hxcpp 构建目标而立即失败；更正为 `-DHXCPP_M64` 后，`native-build7.out.log` 使用隔离 hxcpp、单线程重建 188 个 Haxe 对象并完成核心组，进入 CPPIA 组。系统内存降至保护阈值，监控终止了本次构建进程树；随后单独查询可用物理内存约 352 MB，没有继续测试或结束其他应用。日志最后正在处理 ArrayBuiltin.cpp，已将隔离目录中对应对象保留为 `.interrupted7`，下次必须重新生成。该次未链接和运行，不能作为真实 CPPIA 桥通过的证据。


真实合成 CPPIA 静态桥原生回归（2026-11-13）：`_build/cppia-native-static-bridge-808/native-build8.out.log` 单线程链接通过；`native-run2.out.log` 使用 scriptable hxcpp 原生宿主加载真实编译的合成 `Probe` 模块，静态方法调用、字段读取、字段写入和模块卸载均通过，进程退出 0。通过时宿主副本 SHA-256 `6bed170c4550cb0ab0b9a6487bdc14cfff6b8e16dc77c80e477b971d15472d96`，保存在同目录 `native-bridge-only-passed.exe`。该宿主使用隔离加载器与静态桥，并非正式游戏或真实第三方模组；组合访问器版本另在构建，不据此宣称全套集成通过。


CPPIA 与访问器组合原生宿主（2026-11-13）：将 `_build/polymod-accessor-817` 中导入、CPPIA 静态桥和访问器候选用于 scriptable hxcpp 宿主代码生成，`integrated-build.out.log` 和增量加入断言后的 `integrated-build2.out.log` 单线程链接退出 0。`integrated-run.out.log` 实际加载合成 CPPIA 模块并验证静态调用/读写/卸载，同时在同一 Windows C++ 进程用真实 HScript 自动断言普通 getter 及 `@:bypassAccessor` 静态读写，均 PASS，进程退出 0；生成宿主 SHA-256 `3ce47f2dca1dc2aee6b071a77f5fa22daca1016fa0d8bfd2851639db674e7e00`。这是同一原生宿主中的合成脚本，不覆盖真实第三方编译模组、实例继承、并发/热重载或完整 NF 游戏；组合补丁尚未安装正式依赖，完整游戏构建和可见窗口仍待验收。

实际 Polymod 依赖安装及回归（2026-11-13）：D 盘项目所选 `.haxelib/polymod/origin-4740cb234311` 已安装七文件组合补丁，安装器 `-Action Verify` 通过。安装前七文件的原始字节及 SHA-256 保存在 `_build/polymod-integrated-cppia-accessor-backup-EB51B8D4814C2EE1`，可使用同一安装器的 `-Action Rollback` 校验并还原；C 盘工作树只同步补丁和安装器，不代表已安装该依赖。此前本文件关于组合补丁“尚未安装”的表述记录的是当时状态，以此条为准。

使用 D 盘项目的 `haxelib path polymod` 实际选中依赖，且不将隔离 Polymod 候选目录加入 classpath，`_build/polymod-selected-integrated-822` 下 11 个 Haxe eval 合成夹具退出 0 并输出 PASS：静态、实例、继承、异常恢复、实例及静态黑名单、只读属性、原生合成属性、类和接口导入优先级，以及模拟 CPPIA 静态桥和不启用 CPPIA 的 HScript。各自的 `.hxml`、`.out.log` 和 `.err.log` 保留；黑名单日志中的错误是预期被拦截的操作。模拟桥使用普通 Haxe 类，不能称为真实 CPPIA 运行。此前 `cppia-native-static-bridge-808/integrated-run.out.log` 的 Windows C++ 宿主运行了真实编译的合成 CPPIA，但使用隔离候选依赖而非此次直接运行正式依赖；两种证据不能合并表述为正式游戏或第三方编译模组通过。完整游戏、真实第三方 CPPIA 模组、跨版本矩阵及热重载仍须验证。

正式依赖的原生合成宿主回归（2026-11-13）：`_build/cppia-selected-native-823/build.hxml` 仅使用项目选中的 Polymod、hxcpp 和宿主夹具 classpath，Haxe 生成代码成功；使用隔离的 scriptable hxcpp 补丁单线程构建，`build2.out.log` 链接成功。`run.out.log` 显示真实编译的合成 `Probe` CPPIA 模块成功加载、静态调用、读取、写入和卸载，并在同一 Windows C++ 进程中通过 HScript 静态 getter 与 `@:bypassAccessor` 读写断言，进程退出 0。宿主 `generated/Main.exe` SHA-256 为 `3a1075a15d073b74c3cf4676cd59a33f078555e699b89f4a9777c00ce3dde912`。首次 `build.err.log` 是误设空编译缓存变量导致构建立即退出，未作为通过证据。此测试不是完整 NF 游戏，也不是实际第三方 CPPIA 模组；实例继承、热重载、依赖组合、真实模组与可见游戏运行仍未由它证明。

正式 Windows 构建与 CPPIA 前置条件复核（2026-11-13）：当前生成的 `export/release/windows/haxe/release.hxml` 不含 `POLYMOD_CPPIA` 或 `scriptable`；所选 `.haxelib/hxcpp/git` 的基础 CPPIA 安装器报告 `original`。依赖补丁及原生合成宿主通过不等于普通发行构建具备 0.9 编译模组能力，启用方式与正式运行时集成仍待解决；未更改 Project.xml。基础补丁尚未应用时，class-registry 与 Bool 后续补丁的 Check 因前置基线不匹配而拒绝，不能当作未知文件损坏或强制覆盖依据。

单线程 `lime build windows` 在 Haxe 阶段运行时系统内存触及 700 MiB 提前保护线，监控只终止本次构建进程树，构建退出 1；`_build/nf-build-preflight-824/lime-build.out.log` 仅含编译过程信息，不能作为成功证据。构建前备份的 bin 根文件及哈希在该目录，事后比较原游戏 exe 和 NF `modsList.txt` 与备份的 SHA-256 均相同；未启动游戏或更改模组选择。`lime test windows`、新游戏运行和真实模组验收仍未完成。

CPPIA 正式依赖与实验构建入口（2026-11-13）：D 盘所选 `.haxelib/hxcpp/git` 先后安装基础 CPPIA、类注册、Bool 反射三层补丁，逐层 Verify 通过；8 个受影响文件按 LF 归一后与此前通过原生合成宿主的 `_build/cppia-hxcpp-class-registry-777` 对应文件一致。各安装器在 `_build/hxcpp-cppia-backup-EFED42431DE86317`、`_build/hxcpp-cppia-class-registry-backup-EFED42431DE86317` 和 `_build/hxcpp-cppia-bool-backup-EFED42431DE86317` 保存逐字节备份及哈希；若需回滚，依次回滚 Bool、类注册、基础补丁，不能在叠加补丁后直接对基础层做状态 Verify。C 盘工作树没有因此安装 D 盘以外的 hxcpp。

新增根目录 `Project-OriginCPPIA.xml`（两工作树相同），包含原 `Project.xml`，仅在 Windows 添加 `POLYMOD_CPPIA` 与 `scriptable`；没有修改原 Project.xml。`lime build Project-OriginCPPIA.xml windows -dryrun -verbose` 显示普通 `export/release/windows` 输出，实际构建生成的 `export/release/windows/haxe/release.hxml` 确认包含两个定义。单线程实际构建在 Haxe 阶段触及 700 MiB 提前保护线，被监控终止，日志为 `_build/nf-cppia-integration-825/build.out.log`、`build.err.log`；尚未产出新游戏。原游戏 exe 和 NF `modsList.txt` 的 SHA-256 与 `_build/nf-build-preflight-824/bin-root` 的构建前备份相同。Lime display 直接附加 `-D`/`--haxedef` 的数次尝试未在显示输出中得到这两个定义，故不以那些尝试证明开关生效；以包装文件实际生成的 release.hxml 为准。普通 `lime test windows` 不自动使用包装文件，仍不应宣称默认发行构建支持 CPPIA。真实模组、热重载、完整构建及运行均未验证。

默认构建开关的初始化宏可行性（2026-11-13）：`_build/cppia-init-macro-826` 使用 Haxe 初始化宏 `Compiler.define` 注入 `POLYMOD_CPPIA` 与 `scriptable`，合成小程序编译分支输出 `enabled`，生成的 `Options.txt` 同时含两个标志。第二个夹具在项目实际选择的 Polymod 及 `hxcpp` 依赖下生成原生宿主 C++，其 `Options.txt` 同时含两个标志，生成的 `PolymodCppiaClassReference.cpp` 与此前 `cppia-selected-native-823` 原生通过宿主对应文件 SHA-256 均为 `2db648948d2bd62dc498722bc1bc3fd4c7a36f45313f5f4d3d015a07f785d4d4`。这证明该隔离生成路径可传递标志，不证明完整游戏、初始化宏先后顺序、跨平台或未安装 hxcpp 补丁的构建正确；未在正式宏中自动启用，默认构建行为未变。正式补丁与实验包装入口状态仍以前一条记录为准。

完整 CPPIA Windows 构建与访问器桥修正（2026-11-13）：依用户指定的可用物理内存低于 200 MiB 停止本次构建进程树，单线程重跑实验入口。第一轮 Haxe 报两处编译错误：组合版 Interp 将 bypass 布尔值传给 setClassObjectField，而 `legacyNativeWrites` 把全部参数放在 LegacyRuntime 的 origin 参数之前；D 盘新增的 Credits3DState 销毁阶段还引用未声明的 `backCanvas`。现宏明确处理三参数旧调用或四参数组合调用，将 bypass 放到桥的末尾；LegacyRuntime 在现代路径将其传回 Polymod，在旧模组特殊实例和普通旧写入路径上按该标志选择直接字段写入或属性写入。删除 D 盘 Credits 中唯一的未声明 backCanvas 清理语句，没有改动其他 Credits 逻辑。Origin 宏和 LegacyRuntime 同步两个工作树，Credits 文件仅在 D 盘存在。

修复后的完整 Haxe 编译通过并进入 C++（`_build/nf-cppia-integration-825/build-fix2.out.log`），但 C++ 编译 `llua/Lua_helper.cpp` 因 scriptable 自动生成包装将 Dynamic 传给 `lua_State *` 参数而失败（`build-fix2.err.log`）；没有生成新游戏，原 exe 与构建前备份 SHA-256 相同。`_build/polymod-legacy-bypass-828/test2.out.log` 用实际 Polymod 与实际 legacyNativeWrites 宏、替身 LegacyRuntime 委托入口验证普通 setter、bypass 读写和黑名单，退出 0；该夹具不直接执行正式 LegacyRuntime 的旧模组分支。首次夹具漏设 hscriptPos 而失败，已补齐并重跑。`_build/cppia-lua-native-827` 的 Haxe 4.3.7 小夹具显示为相关字段添加 `@:unreflective` 虽影响可反射字段表，仍生成不能编译的 CPPIA 包装；对类加 `@:nativeGen` 会改变类生成形式且生成的 boot 引用未匹配，未采用。Lua 指针包装的修复、完整链接、游戏运行及真实模组验收仍待完成。

scriptable 构建中 Lua 指针隔离（2026-11-13）：Haxe 4.3.7 的 C++ 生成器对带 `lua_State *` 参数的公共类生成 CPPIA 动态包装，造成先前 `Lua_helper.cpp` 与隔离测试中的 `Convert.cpp` 无法编译。根据所选 linc_luajit 1.0.3 源码制作三文件项目侧覆盖 `source/llua/Lua.hx`、`Convert.hx`、`LuaCallback.hx`：保留原有 Haxe 类型名作为 typedef，将实现改为模块私有类并标记 `@:hscriptBaseCreated`，阻止对原生 Lua 指针方法生成不安全脚本包装；函数体未改，随附 `LICENSE.linc-luajit`，两工作区同步。私有实现的运行时反射类名与上游不同，第三方脚本对这些内部类的反射依赖尚未验证；普通非 scriptable 游戏运行亦未单独验收。

`_build/cppia-lua-private-829/build2.out.log` 为使用 D 盘实际 Polymod、已修补 hxcpp、启用 scriptable/CPPIA 的原生小宿主单线程构建成功记录；`run.out.log` 记录实际创建 Lua 状态、注册 Haxe 回调、执行 Lua、转换整数结果 42 并关闭状态，进程退出 0。主程序 SHA-256 `b18b75bfdda7c9912b01dd3cd83625fae1c8e165951be483ed924dfffa8a0125`。第一次仅改 Lua_helper 后暴露 Convert 的同类报错，故补充另外两个类；小宿主通过不代表游戏或所有 Lua 功能通过。

完整游戏 `lime build Project-OriginCPPIA.xml windows` 已在 200 MiB 可用内存监控下启动，Haxe 阶段通过，C++ 编译正在单线程运行；日志 `_build/nf-cppia-integration-825/build-lua-fix.out.log` 与 `.err.log`。此条记录时任务仍在运行，不视为构建、完整游戏或真实模组验收通过；最终状态以进程退出与后续日志为准。

Lua 覆盖的普通模式边界（2026-11-13）：`_build/cppia-lua-conditional-830` 在隔离目录为三个 Lua 覆盖文件增加 `#if scriptable` 分支。Haxe C++ 代码生成在普通与 scriptable 两种模式均退出 0；普通模式生成原 `llua.Lua_helper` 类路径，scriptable 模式生成私有实现且不生成三个不安全指针包装。已将这一条件化声明同步两工作区，以避免普通构建无条件改变这些 Lua 类的运行时名称；该检查不是普通模式原生运行测试。上述完整游戏构建已先完成 Haxe 代码生成并进入 C++，之后才修改了源码条件；该次构建使用的是先前生成的 scriptable 实现，和条件化后的 scriptable 分支目的相同，但不是对最终源码重新生成的证据。最终源码仍需重新构建验证，不能把正在运行的构建当作最终源码的完整验收。

NF Discord 原生回调的 scriptable 构建修正（2026-11-13）：检查完整游戏生成文件时，发现 `general.backend.DiscordClient` 的 `onReady`、`onError` 与 `onDisconnected` 被生成接收 Dynamic 的 CPPIA 包装，但其签名使用 `DiscordUser *` 或原生字符串指针，与前述 Lua 编译错误同型。将三项原私有回调移入模块私有 `DiscordNativeCallbacks`，注册处改为引用该类；`onReady` 仍调用公开的 `DiscordClient.changePresence()`，事件内容及公开 Discord API 保留，两个工作树同步。为避免已确定包含不兼容包装的长时间单线程构建继续消耗资源，在 C++ 约 5.4% 时终止了该次任务；最后正在编译的 `JsonParser_54.obj` 已改名保留为 `.interrupted-20261113`，避免作为完整目标文件复用。

修复后的最终源码已重新启动实验 CPPIA 构建，Haxe 阶段通过。当前生成的 `general/backend/DiscordClient.cpp` 不再含三项回调的 CPPIA 包装；私有回调 C++ 文件已生成。主构建仍在单线程 C++ 阶段，日志 `_build/nf-cppia-integration-825/build-lua-discord.out.log`、`.err.log`；尚未证明 C++ 编译、链接、Discord 回调运行、完整游戏或模组通过。

Windows scriptable 原生回调包装检查（2026-11-13）：批量检查实际生成头文件发现 hxvlc 的 Video、VideoFix、Audio 共 26 个带原生指针的回调及 CNE 内部 DiscordUtil 的两个 C 字符串转换函数也被 Haxe 4.3.7 生成不兼容的 CPPIA Dynamic 包装。该处理解决共同 Windows 构建边界，不新增 CNE 模组版本兼容。已停止包含已知不兼容包装的前一轮构建（约 2.9%），中断的 `c36dab04_PsychParser.obj` 长度为 0，已改名保留为 `.interrupted-20261113-cppia2`，不复用为完整目标文件。

新增 `originfunkin.macro.OriginCppiaNativeWrappers`，只在 Windows C++ scriptable 构建中注册 Lime 生成后的检查：对于本次识别的 28 个原生指针包装，CPPIA 动态调用明确抛错；视频类的 26 个对应虚方法直接转发至其原生基类实现，以保留原生媒体回调路径；普通构建不启用此处理。严格检查生成文件和目标方法，结构不符时停止而非静默修改。`_build/cppia-native-wrap-831` 的合成原生指针夹具在 Haxe 生成后处理 C++、单线程链接并执行正常原生调用成功（`run.out.log`）；在四个实际项目生成文件的隔离副本中，生产钩子找到 28 个包装，手动使用 MSVC 单线程分别编译 Video、VideoFix、Audio、DiscordUtil 四文件成功（`compile-actual.out.log`）。这是静态编译及合成指针调用证据，没有运行实际视频、Discord 或 CPPIA 调用拒绝分支，不证明视频生命周期崩溃已修复。

最终源码的实验 CPPIA 完整构建已重新启动并通过 Haxe 生成；正式生成文件中 Video、VideoFix、Audio、DiscordUtil 分别处理 10、10、6、2 个包装。构建仍在单线程 C++ 阶段，日志 `_build/nf-cppia-integration-825/build-native-wrappers.out.log`、`.err.log`；链接、运行、真实模组和普通模式回归尚未完成，目标仍未完成。

真实 0.9 编译模组字段的当前生成代码复核（2026-11-13）：针对先前从原始 Mod Engine 1.0.3 `ModEngine.cppia` 提取的引擎字段引用（该文件 SHA-256 `e676b800806458bf99224bfc39b7c2fb6537f2d68eb307fa635002ad6d0133bc`），以当前 CPPIA 构建 Haxe 阶段生成的 C++/头文件重新做词法比对。`_build/cppia-real-fields-current-832/review.json` 共 235 个不重复类型与字段组合，沿首条 C++ 父类链均能找到同名文本；涉及的 43 个类型对应 `.cpp` 均列于本轮 `Build.xml`（`build-membership.json`，该 XML SHA-256 `561ee49c572119f48de387883a12946da0bf865ed073e463a72ec5f7ff97daca`）。该检查只核对名称与构建清单，不验证方法签名、字段类型、脚本可访问性、ABI、语义、加载或游戏行为；不把 235 项视为运行通过。单线程完整构建在本条记录时仍运行。

真实 Mod Engine 的 CPPIA 调用参数数量静态核对（2026-11-13）：`_build/cppia-real-call-audit-833/review.py` 从先前所存 0.9 Mod Engine 原始文本 CPPIA 提取对 `funkin.*` 的 `CALLSTATIC` 与 `CALLMEMBER` 指令，对照本轮生成的 `ScriptNamedFunction` 表并沿首条原生父类链查找。去重后共 103 组调用（静态 26、成员 77，涉及 30 个类型），均找到静态/成员种类及参数数量相同的生成签名；逐项见 `review.json` 和 `review.out.log`。这比同名文本存在检查更严格，但仍未比较参数和返回值的具体类型、可空性、可覆盖性、内部函数动态回退、实际链接或语义，也未覆盖 CALLTHIS、CALLSUPER 和其他模组；不能据此认定该真实模组已经加载或兼容。

真实 Mod Engine 父类调用的静态核对（2026-11-13）：对同一原始 0.9 编译样本额外扫描 `CALLSUPER` 和 `CALLTHIS` 中引用 `funkin.*` 的调用，得到 11 组不同的 `CALLSUPER`（均指向 `funkin.modding.module.Module` 事件方法），未发现以 `funkin.*` 为目标的 `CALLTHIS`。`_build/cppia-real-super-audit-834/review.json` 中 11 组调用均找到参数数量相同的生成成员签名；`super-callbacks.json` 检查到这些生成表项都使用 `HXCPP_CPPIA_SUPER_ARG(__s_<name><true>)`，所选 hxcpp 的 `Scriptable.h` 定义了该参数。这只是生成代码及清单静态检查，不能证明实际父类调用的 ABI 或语义；`CALLSUPERNEW` 构造函数、模组自有类及真实运行仍未由此覆盖。

同一 Mod Engine 样本的父类构造补充核对（2026-11-13）：`_build/cppia-real-super-audit-834/constructors.json` 按文本 token 统计 `CALLSUPERNEW`，共有 32 处、7 组类型/参数数量；其中指向 `funkin.modding.module.Module` 的 4 处均传 3 个参数。本轮生成 `Module_obj::__script_construct` 的签名是 `vsoo`（3 个参数），对应当前 Haxe 构造函数 `new(moduleId, priority, params)`。这是参数数量及生成签名静态核对，不代表参数类型、其他父类或原生构造流程已通过运行验证。首次临时统计命令因 Python 编码名称拼写错误未执行，修正后才生成上述 JSON。

真实 Mod Engine 的旧 Flixel 信号名待运行验证（2026-11-13）：`_build/cppia-host-types-835/review.json` 将该编译样本的 207 个非空类型项与本轮生成构建清单对照，未直接找到的候选为小写基础类型、Math 和 `flixel.util._FlxSignal.FlxSignal0/1`；前者可能由 hxcpp 内建解析，不能仅凭没有项目 C++ 文件认定缺失。该真实样本四处 `CALLMEMBER` 分别对旧信号名调用 add/remove，来源为模组 Backdrop.hx 与 Field.hx，位置及参数数目见 `signal-review.json`。当前生成宿主的类名为 `flixel.util.FlxSignal0/1`，两者继承的 `FlxBaseSignal` 在动态 `__Field` 暴露 add/remove；所选 hxcpp `TypeData::link` 对未解析类会采用 hxObject 基类，`CallMember::link` 可能回退到动态调用。源码路径显示该差异可能可回退，但尚未在原生 CPPIA 中触发这四处信号调用，不把它记为通过，也不据此修改类型别名或判定失败。

旧 Flixel 信号名运行对照准备（2026-11-13）：`_build/cppia-signal-fallback-836` 已准备独立 Haxe/CPPIA 夹具：编译模块以旧 `flixel.util._FlxSignal.FlxSignal0/1` 原生名声明 add/remove，宿主创建项目选中 Flixel 的当前 `FlxSignal0/1` 实例，调用编译模块安装及移除监听器，再检查事件分发次数与参数。两个构建配置和源码仅为候选；为遵守单线程编译约束，完整游戏构建运行期间尚未编译或执行该夹具，也尚未确认 Haxe `@:native` 在 CPPIA 输出中实际生成预期旧类型名。需先检查生成字节码、构建并运行，不能将夹具存在当作动态回退或真实模组通过。

旧 Flixel 信号夹具对照补充（2026-11-13）：在 `_build/cppia-signal-fallback-836` 为同一 CPPIA 测试源码增加当前宿主类型名对照配置，并准备 `verify_module.py`，用于在执行前检查字节码中旧名/当前名及 add/remove 的 CALLMEMBER 指令。这样旧名案例若失败可与同宿主当前名案例比较，避免直接把夹具或环境错误归为兼容问题。两个模块与宿主目前均未编译或运行；验证脚本也尚未实际执行，检查通过不能提前假定。

Hex V3 小范围真实源码与音符素材准备（2026-11-13）：[作者固定源码提交 c9c344d](https://github.com/Kade-github/Hex-V3/tree/c9c344d341d03e537f019775978f8ec9f440c733) 的元数据声明 API 0.9.0、依赖 `mod-engine`。在 `_build/hex-v3-source-838` 保存该提交的原始元数据、两份真实 NoteStyle HXC、两组对应 JSON/PNG/XML 及一份真实 RightPaceModchart 源码，共 10 文件、508,972 字节；每个文件的 Git blob SHA-1 已与该提交树核对，并记录 SHA-256 与大小于 `source-inventory.json`。其中两份脚本分别调用 `NoteStyle` 的 `super("hex_mines")` / `super("hex_mine_reg")`，两份素材声明版本 1.1.0，当前 NoteStyle 声明接受 id 和可选 params；这里只检查源码形状，未实际注册、载入图集、播放或编译真实图表。首次文件校验把一个预期 Git hash 复制错误而中止；核对仓库树后以正确 hash 验证已下载字节，后续文件均通过。该目录是原作者内容的少量子集，不是 Hex 完整发行版或兼容通过证据。

[Hex V3 GameBanana 页面](https://gamebanana.com/mods/44225) 当前列出的发行包为 `hexv3_game_mod_patch_3.rar`，约 1.41 GB。下载并重命名该发行包的命令被自动审批以“blocked by policy”拒绝，未执行，发行包没有下载；本段保存的公开源码与素材是独立的小范围只读检查，不能替代该发行包的真实运行验收。

Hex V3 真实音符样式静态素材核对（2026-11-13）：对已按原作者固定 Git 提交校验的两组素材，`_build/hex-v3-source-838/review-notestyles.py` 读取 JSON、Sparrow XML 和 PNG 头，记录于 `notestyle-static-review.json`。`hex_mines` 有 28 帧、四个方向前缀各匹配 7 帧；`hex_mine_reg` 有 14 帧，四个方向共享前缀各匹配这 14 帧；检查到的裁切矩形均在 PNG 声明尺寸内。两份 JSON 均为 1.1.0，而当前 `NoteStyleRegistry` 版本规则为 `>=1.0.0 <1.2.0`。`hex_mine_reg` 声明 `animated=true`；`hex_mines` 未声明该字段、无 fallback，当前数据默认值为 false，这只反映当前规则和作者数据，不能据此推断作者意图或报告缺陷。检查未解码纹理，也未运行注册器、脚本、动画或完整 Hex 模组；运行结果仍待验证。

Origin 上游预览分支增量审查（2026-11-13）：[11c4203 到 4a0137e](https://github.com/FunkinCrew/Funkin/compare/11c42037d664f4437c6187fef3bb88893931930b...4a0137e764cf6dfd20f4d2883f9790cb076c356d) 前进 12 个提交，涉及 assets 子模块、Flixel/hxcpp 依赖、资源枚举、渲染纹理、FunkinGroup、图表编辑器、模组菜单和缓存等。当前本地 `funkin.assets.Assets.listInPath` 对已有 `assets/` 前缀的路径仍会重复加前缀；`FunkinGroup.set_maxSize` 的旧循环在缩容时有下标和数组变更问题，`update` 还会反复乘算子项 scrollFactor。这些是源码审查发现的风险，尚未通过游戏运行复现，也尚未应用本次上游更新。渲染纹理及依赖更新会改变更广的运行行为，应结合现有 NF 修改逐项合并和回归，不能直接覆盖。进行中的实验 CPPIA 构建基于更新前源码；旧模组兼容、最新上游同步均不能仅凭这次差异审查认定完成。

Origin 4a0137e 上游适配候选（2026-11-13）：在 `_build/origin-upstream-4a-candidates-839` 基于当前两个源文件的 SHA-256 创建隔离候选：Assets 的已带前缀路径处理和先筛选再查询，以及 FunkinGroup 的缩容、嵌套尺寸、子项容器、移动坐标和空项移除修正；每项替换均要求旧文本唯一匹配，原始及候选哈希见 `manifest.json`。候选来自上游对应增量，但尚未写入生产源码、编译或运行。scrollFactor 传播、渲染纹理、模组菜单及编辑器变更没有纳入该候选，需与本地行为和依赖一起复核。现有引擎内 `listInPath` 调用主要传未带 `assets/` 前缀的路径；静态搜索不能排除外部模组调用，也不能证明已有具体模组受前缀问题影响。

Hex V3 死亡与地雷源码边界（2026-11-13）：从作者固定提交 c9c344d 获取 `HexEvilGameOver.hx`、`HexGameOverMenu.hx`、`Mine.hxc` 和 `MineReg.hx`，4 个文件各自的 Git blob SHA-1 与仓库树匹配；副本及大小和 SHA-256 见 `_build/hex-v3-script-review-840/review.json`。静态核对发现两种地雷分别以三个参数构造 NoteKind、漏按时取消事件，当前 NoteKind 源码构造签名接受这些参数；MineReg 用 `@:privateAccess` 调用 PlayState 的四参数 `applyScore`，本轮生成代码中存在对应四参数的 CPPIA 表项 `vfsfi`。生成目录中还存在其引用的 FunkinHitbox 类型文件。此核对未加载这些脚本、验证取消事件和分数语义、死亡重试、触控或完整模组；源码层及生成表中出现接口不能证明 ABI、行为或兼容通过。四份源码与前述音符资源均只是作者仓库子集，不能替代发行包测试。

Origin 4a0137e 部分修复已写入源码（2026-11-13）：将上述经过哈希核对的 Assets 和 FunkinGroup 隔离候选应用到 D 工作区和 C 工作树，共两文件各两份；每份旧源码 SHA-256 均在写入前与候选生成时一致，D 侧旧文件逐字节备份于 `_build/origin-upstream-4a-candidates-839/preapply-originals`。对应修复包括已带 `assets/` 前缀的资源枚举、容器缩容、嵌套尺寸、make/insert 的 container、move 坐标和 null 移除；未纳入 scrollFactor、渲染纹理、菜单和编辑器变更。写入发生在实验 CPPIA 构建完成 Haxe 代码生成之后，因此该轮正在进行的 C++ 构建不包含这些新源码，不能作为这些修复的编译或运行证据；必须再增量生成/构建并回归实际资源枚举和容器行为。

FunkinGroup 移动容量边界（2026-11-13）：源码检查发现 `move` 先从原组删除、再调用可能因目标组已满而返回 null 的 `add`，会让该子项离开两个组。已在两个工作树的移动循环中加入容量检查，目标组满时停止移动，避免丢失剩余子项；这是基于实现顺序的修复，尚未运行验证。`_build/origin-group-method-fixture-841` 已从本轮正式源码提取 set_maxSize/add/make/insert/move/remove 的原方法文本，准备对缩容、container、移动坐标、满组保留及 null 移除进行轻量对照；夹具依赖 Flixel 替身，尚未编译或执行，不能证明真实游戏渲染。待当前单线程完整构建结束后运行，再针对最终源码重新生成并进行真实回归。

FunkinGroup 滚动系数修正（2026-11-13）：原 `update` 每帧把子项的当前 scrollFactor 乘以组的 scrollFactor，非 0/1 系数会跨帧指数变化，且遇到 null 子项时会解引用。上游 4a0137e 改为复制组系数；本地沿用复制语义，但仍在 `update` 循环中执行，因为当前 `IconGroup` 覆盖 `updateChildren` 且不调用 super，直接照搬上游移动到 `updateChildren` 会改变该子类的同步路径。空子项现在跳过，同步发生在子项 update 之前；与上游相同，组系数为 (1,1) 时此逻辑不主动覆盖子项原系数。正式源码已改，提取正式 update 方法的轻量夹具位于 `_build/origin-group-scroll-fixture-842`，涵盖多帧、null、非 active 子项与 updateChildren 覆盖；尚未编译执行，真实摄像机渲染和从非 1 恢复到 1 的预期行为仍需验收，不能当作运行通过。

FunkinGroup 移动数组别名边界（2026-11-13）：`move(source, source.children)` 在遍历参数时原地移除同一数组，会跳过后续子项；移动到自身也会无意义地删除并重加。已改为遍历参数快照，并把源组和目标组相同时视为无操作；目标组满时仍按前述保护保留源组剩余项。`_build/origin-group-method-fixture-841` 已按最新正式方法重新提取并加入数组别名与自身移动案例，尚未执行。此处是源码逻辑修复，不声称真实模组已触发或通过。

FunkinGroup 已提取方法的解释执行回归（2026-11-13）：在主原生构建运行时分别以单进程 Haxe `--interp` 运行 `_build/origin-group-method-fixture-841` 和 `_build/origin-group-scroll-fixture-842`，两次退出码均为 0，输出保存在各自 `eval.out.log`，错误日志为空。前者覆盖缩容、make/insert 的 container、移动坐标、目标满、null 移除、源数组别名和自身移动；后者覆盖多帧非 1 滚动系数、null、非 active 子项和 updateChildren 覆盖。`_build/origin-group-method-fixture-841/extraction-verification.json` 对照最新正式源码，确认两份夹具中的七个方法文本完全一致。运行前及运行中设置了可用内存低于 200 MiB 停止本次测试进程树的检查。夹具使用轻量替身和解释器，不涉及实际 Flixel 对象、游戏绘制、真实模组或原生生成后的 ABI，不能代替完整增量构建及可见窗口回归。

旧 Flixel 信号 CPPIA 字节码对照（2026-11-13）：在低内存进程树保护下，以 Haxe 单进程分别生成 `_build/cppia-signal-fallback-836/signal.cppia` 与 `current-signal.cppia`，两个命令退出 0。`verify_module.py` 实际检查生成的类型表和 CALLMEMBER 后，旧名 `flixel.util._FlxSignal.FlxSignal0/1` 与当前名 `flixel.util.FlxSignal0/1` 两组各自的 add/remove 指令均符合夹具目标；文件 SHA-256、命令退出码和核对日志见 `module-verification.json`、`*-verify.out.log`。这解决了此前不确定 `@:native` 是否生成预期名称的问题，但两个模块尚未在原生宿主运行，不能说明旧名的动态回退、事件派发或真实 Mod Engine 已通过；主游戏原生编译仍在单线程进行，暂未同时启动另一个原生编译。

旧信号原生宿主准备进展（2026-11-13）：首次为 `_build/cppia-signal-fallback-836` 生成宿主 C++ 时失败，原因是独立 HXML 未定义 Flixel 资源目录模式，AssetFrontEnd 因而引用未声明的字段；仅在该夹具 HXML 增加 `FLX_STANDARD_ASSETS_DIRECTORY` 后，第二次 Haxe C++ 生成退出 0，日志分别为 `host-generate*.out/err.log`。完整 Flixel 夹具的生成构建清单较大，因此另建 `_build/cppia-signal-fallback-slim-843`：逐字节复制当前选中的 FlxSignal.hx，FlxDestroyUtil 的接口及 destroyArray 用最小替身，沿用实际选中的 Polymod 和 hxcpp。首次生成发现替身缺少 destroyArray，补齐后 `generate-2` 退出 0。两个版本均只生成 C++、未进行原生编译或运行；精简版不能证明完整 Flixel 或游戏集成，主要用于之后先验证当前/旧类型名的真实原生派发与回退。主游戏原生编译期间未启动第二个原生编译。

Origin 上游预览分支同步与 0.9 实测（2026-11-13）：官方 main 为 94ee0f2，preview/public-playtest 为 4a0137e。按本地结构移植其编辑器热重载快照、ChartManifestData 克隆、渲染纹理、FunkinGroup、纹理缓存、tween 清理及加载过渡闪光修正；保留本地 Mod Menu 输入实现、NF 自定义依赖及用户外置 assets，不将所有上游差异标为已合入。原文件备份于 `_build/origin-upstream-4a-sync-849/backup`。首次完整 CPPIA 链接成功（hxcpp 增量构建，`build-handlers-resume.out.log`）；隔离可见窗口加载原始 Mod Engine 1.0.3 时失败于 `CallHaxe: Invalid arg count`（`cppia-848.stdout.log`），并非运行通过。对原始 CPPIA 与生成调用表核对发现 FlxCamera.drawTriangles 多一个默认 null 的 blendTarget，BitmapData.fromTexture 多一个默认 null 的 shared 参数。已安装有哈希检查和回滚备份的 `tools/hxcpp-origin-cppia-null-args.patch`：只对这两个精确类型、方法、宿主签名和字面 null 兼容；非 null 的新参数语义仍不支持。最新源码和补丁的完整构建正在运行，加载修复尚未实测，不能声称已兼容全部 0.9 模组。

真实 Mod Engine 最小复测（2026-11-13）：上游适配及两个默认 null 参数补丁后的完整 Windows CPPIA 构建退出 0，构建日志另有 `Failed to update resources` 提示；隔离可见窗口中先前 `Invalid arg count` 已不再出现，但加载推进至 `lime.utils.ArrayBufferView.transferElement` 缺失并以 `Bad link` 失败，日志 `cppia-853.stdout.log`。已依据本机 Lime 8.3.2 的原实现通过 Origin 编译宏补回该静态方法，不改所选 Lime 源文件；Float32/UInt8 跨类型及偏移转换的解释执行夹具通过，scriptable Haxe 生成的静态表包含四参数签名 `voioi`（`_build/origin-lime-transfer-854`）。这还不是 CPPIA 原生调用或模组通过证据；包含该修复的单线程完整构建正在进行，之后需复测真实模组。

真实 Mod Engine 启动复测（2026-11-14）：包含 Lime transferElement 兼容方法的 Windows CPPIA 完整构建返回 0，仍提示 Failed to update resources。隔离可见窗口中 Modchart Engine 1.0.3 的原始 CPPIA 已加载，脚本预热检查 150 个类、11680 个引用且报告 0 错误，五个模块实例化并进入主菜单；此前的 Invalid arg count 和 Unknown static call 未在本次日志出现（_build/cne-isolated-runtime-219/cppia-855.stdout.log）。此结果只覆盖启动和加载，不证明模组实际谱面或所有 0.9 模组兼容。

真实 Mod Engine 歌曲启动（2026-11-14）：使用同一实验性 CPPIA 构建，在隔离存档和可见窗口中启用 Modchart Engine 1.0.3 并启动 tutorial，PlayState 初始化、歌曲和音频开始，运行日志报告 brokenScripts=0（_build/cne-isolated-runtime-219/cppia-856.stdout.log）。这是原版歌曲与框架并存的短时检查，未运行该框架的专用 modchart，不能据此断言其效果兼容。

Modchart Engine 1.1.0（2026-11-14）：GameBanana 原始 ZIP SHA-256 A888E803A9A4F0F52DBE9038BD2BF4DB363839D5FE7B2C5EAD5CDC36F92DD0E4，隔离可见运行日志 cppia-857.stdout.log 显示 CPPIA 链接时 Invalid arg count，未通过。静态调用表发现新版对 NoteStyle.getHoldNoteAssetPath 的零参数调用与本地一参数 String 接口不匹配；上游 0.9 接口返回 AssetPath，因此已添加专用预览桥和仅匹配该方法及签名的 hxcpp 补丁，保留旧接口。补丁安装器经过哈希核对并备份，构建及真实模组复测正在进行，尚不能把该候选视为根因或修复已验证。原 1.0.3 隔离样本已恢复。

Modchart Engine 1.1.0 桥接复测（2026-11-14）：包含 NoteStyle 适配的 CPPIA 构建退出 0（仍有 Failed to update resources 警告）；第一次 cppia-858 测试因测试样本移动不完整导致未找到模组，不能作为兼容结果。重新从 ZIP 解压后 cppia-859 识别到 1.1.0，越过先前 Invalid arg count，随后在 funkin.touch.input.ControlsHandler.get_hasExternalInputDevice 缺失处 Bad link。已按上游设备查询契约新增该接口，移动端委托现有设备检测，桌面查询活动手柄；补齐后的构建正在进行，尚未验证。隔离测试的 1.0.3 样本已恢复。

Modchart Engine 1.1.0 第二次复测（2026-11-14）：加入设备查询后，单线程 Windows CPPIA 构建退出 0，仍有 Failed to update resources 警告。隔离可见窗口 cppia-860.stdout.log 识别并加载 1.1.0，预热 150 类、11680 个引用且报告 0 错误，Tutorial 开始播放时 brokenScripts=0；此前 Invalid arg count、ControlsHandler 静态调用缺失和 Bad link 未再出现在该日志。该检查未运行专用 modchart，也未验证移动端设备检测或所有模组；不能将其表述为完整兼容。测试后旧 1.0.3 样本已恢复。

Your Idol 及推荐依赖实际检查（2026-11-14）：隔离窗口 idol-861.stdout.log 加载 Your Idol 1.2.0、Stage Changer+ 1.1.0、Extra Events 1.2.0；模组原包 scripts/notes/HeyNote.hxc 与 CheerNote.hxc 都声明 HeyNote，但各自模块 ID 和音符类型不同，脚本注册出现重复类名错误，不能将其直接归因为引擎缺陷。保持原包不变，仅对隔离副本将 CheerNote 类名改为 CheerNote，idol-862.stdout.log 预热 185 类、13475 引用且无预热错误，随后 Stage Changer+ 的 onSongLoaded 因历史 FunkinSprite.cacheTexture 缺失而报错。已按 Origin v0.6.3 的公开签名恢复 cacheTexture、isTextureCached、cacheSparrow、cachePacker 入口并使用当前缓存实现；包含修复的单线程构建正在运行，尚未验收舞台切换、歌曲完成或特效，修正过的模组副本不能代替原包通过。

Your Idol 旧缓存接口复测（2026-11-14）：包含 FunkinSprite 历史缓存入口的单线程 CPPIA 构建退出 0，仍提示 Failed to update resources。隔离测试副本仅将原包 CheerNote.hxc 重复的类名更正；idol-863.stdout.log 显示 Stage Changer+ 已预加载多个舞台道具并越过 cacheTexture 错误，歌曲启动，运行期间多次触发 ChangeCharacter，PlayState 报告 brokenScripts=0；日志未见新的脚本错误。窗口运行约 45 秒后结束，未覆盖整首歌、结算及所有舞台/特效；未修改原始 ZIP，原包自身重复类名问题仍存在。

Windows 构建资源警告定位（2026-11-14）：Lime WindowsPlatform.hx 在链接并复制 exe 后调用 ReplaceVistaIcon.exe；在隔离副本上复现该工具输出 Failed to update resources、退出 1，副本哈希不变。正常输出 exe 与 obj/ApplicationMain.exe 哈希均为 2053BDC0B214320CB40249F98028BBA53624C6816114CA6E1B1CFBE602669D04，版本资源显示 NovaFlare Engine 1.2.1.0。使用 Windows Begin/Update/EndUpdateResource API 在另一隔离副本写入同一 ICO 的 8 个图像及图标组成功，说明资源 API 在该副本可用；旧替换工具失败的具体原因和图标显示尚未确认，不以此报告已修复。诊断文件在 _build/windows-icon-diagnostic-864。

旧 FunkinSprite 缓存同步语义复核（2026-11-14）：0.6.3 的 cacheTexture 直接调用 FlxGraphic.fromAssetKey 并在返回前设置 persist；上一版桥委托现有 FunkinMemory.cacheTexture，而该方法最终使用异步 Future，短时成功不证明立即缓存语义。现改用同签名同步加载，交由当前 FunkinBitmapFrontend 的 staged cache 管理，并保留缺失资源警告；构建正在进行，新实现尚未实测，之前 idol-863 仅验证旧异步候选。

旧 FunkinSprite 同步缓存复测（2026-11-14）：新实现的单线程 Windows CPPIA 构建退出 0，仍有此前图标更新警告；隔离可见窗口以修正重复类名的 Your Idol 测试副本及推荐依赖运行约 45 秒（idol-865.stdout.log）。脚本预热 185 类、13475 引用、0 错误，多个舞台纹理预加载完成，歌曲开始且角色切换脚本继续运行，未见脚本执行错误。同步语义源自 FlxGraphic.fromAssetKey 的同步调用路径；本轮未单独探测每张图在调用返回瞬间的缓存状态，也未验证原包直接运行或完整歌曲。

CPPIA 依赖组合只读检查（2026-11-14）：新增 tools/check-origin-cppia-dependencies.ps1 与 origin-cppia-dependencies.json，核对当前实验性组合的 10 个 Polymod 文件、8 个 hxcpp 文件的 LF 归一 SHA-256 及 17 个补丁文件原始哈希；不安装或修改依赖。当前选定依赖检查通过，隔离复制后在 Polymod.hx 添加本地变更时正确报告差异并失败。此指纹反映当前已用于构建与短测的组合，不证明所有功能、纯净依赖的安装顺序或未来上游版本兼容；依赖变更时需人工审查而非强制覆盖。

Hex V3 0.9 子集加载（2026-11-14）：将固定作者提交 c9c344d 的原始元数据、两个 NoteStyle 脚本及对应 JSON/PNG/XML 放入隔离测试目录，与真实 Modchart Engine 1.0.3 一同在可见窗口加载（hex-subset-867.stdout.log）；依赖顺序正确，脚本预热检查 152 类、11682 引用、0 错误，注册器实例化 hex_mines 和 hex_mine_reg，进入主菜单。测试目录因没有复制图标而有缺图标警告；仅加载作者内容子集，并未测试完整 Hex、原生 CPPIA 谱面、纹理渲染或实际歌曲，不代表该模组整体通过。

Hex V3 0.9 音符实例短测（2026-11-14）：在可见隔离窗口加载固定提交 c9c344d 的两个原始样式脚本与 JSON/PNG/XML，以及 Modchart Engine 1.0.3；独立测试模块通过 NoteStyleRegistry 分别创建真实 NoteSprite，hex_mines 图集读取 28 帧、左方向动画 7 帧，hex_mine_reg 图集 14 帧、左方向动画 14 帧，两者 scale.x 均为 0.7（hex-subset-868.stdout.log）。脚本预热 153 类、11705 引用、0 错误；这是程序对象与素材加载检查，未将音符放入谱面或比较画面，也未覆盖完整 Hex 和 CPPIA 谱面。原始样式文件未修改。

旧谱面编辑器 NOTE_KINDS 兼容（2026-11-14）：批量对照历史公开字段与已下载真实模组脚本，发现 My Streets 0.6.3 的 ChartNoteKindsDSides.hxc 在进入谱面编辑器时调用 ChartEditorDropdowns.NOTE_KINDS.set('attackNote','Attack Note')，而当前编辑器只读取 NoteKindManager。已按官方 v0.6.3 恢复旧 mutable map 和默认项，合并新版注册器的列表、避免重复并允许旧脚本标签生效；重新加载模组时清除旧注册并恢复默认项，保留 map 对象引用。_build/origin-note-kinds-869 使用提取的实际 map/方法及下拉组件替身检查旧自定义项、新注册器、重复项、未知项和重载清理，解释器通过。完整构建及真实编辑器 UI/热重载尚未验证，旧脚本在编辑器已创建后写入时是否立即刷新也未验证。

My Streets 旧音符注册真实路径（2026-11-14）：首轮构建因 DropDownEntry 的 id 空安全失败；补充非空回退后单线程 CPPIA 构建退出 0，仍有图标工具警告。可见隔离编辑器加载未修改的 My Streets 1.1.0 和独立观测模块（editor-870.stdout.log），原模组 DDTONoteKindsDSides 成功加载并注册 attackNote；观测模块在编辑器状态读取到 Attack Note，lookupNoteKind 返回 attackNote:Attack Note，预热 158 类、12045 引用且 0 错误。此检查证明真实脚本注册和查询，没有打开下拉菜单或验证其已创建时的即时刷新；模组热重载清理仅由提取方法与替身组件的轻量检查覆盖。

旧音符表工具箱刷新（2026-11-14）：已确认 Note Data 工具箱重新显示时会调用 refresh，但原 refresh 只按当前谱面值更新选项，不重新填充数据；因此模组在工具箱创建后往 NOTE_KINDS 写入的项可能不可选。现 refresh 暂停 CHANGE 事件后重建合并后的列表并恢复当前选择，以便下次打开工具箱显示更新。该改动尚在单线程构建中，未验证窗口中即时刷新、鼠标或键盘操作；仍打开的下拉菜单不会被此改动主动刷新。

旧音符表工具箱刷新复测（2026-11-14）：完整构建链接时可用内存低于 200 MiB 被监控终止，2 MiB 不完整 obj 已重命名保留；随后用相同选项单线程续接 hxcpp 链接成功。可见隔离编辑器加载 My Streets 原模组及独立测试模块：先确认原模组注册 Attack Note，测试模块临时移除后显示工具箱，再添加并关闭/重新显示工具箱，读取其实际数据源结果 before=false、after=true（editor-refresh-871.stdout.log）。此步骤直接调用工具箱接口，不是鼠标或键盘 UI 验收，也未测试已展开列表即时更新。验证后已备份普通输出原 exe 至 _build/origin-note-kinds-869/bin-before-871.exe，再将新链接程序放入正常 bin 目录；obj 与 bin SHA-256 均为 286B3D2A6B2A7403FB9EC5CA6DB773B43DAA451B2752F8B3EA777A1F5E79C65C。

历史静态成员与实际模组交叉检查（2026-11-14）：对先前历史缺失成员候选与隔离目录 143 个真实模组 HXC 文件中的 Class.member 文本进行词法交集，再检查当前 Origin 源码声明；两个命中均找到同名声明，未留下本规则下的未匹配项（_build/origin-complete-version-audit-233/real-mod-static-intersection-872.json）。该粗筛不解析导入、继承、实例变量、类型和行为，也不覆盖 CPPIA，不能据此断言兼容。

CPPIA 动态方法 Bool 返回修复（2026-11-14）：在可见隔离窗口实际调用 Modchart Engine 1.1.0 的 QuantSkin.ready/warm；修复前 quant-874.stdout.log 报告 ready=1、Std.isOfType(ready, Bool)=false，而原生 NoteStyle 布尔对照为 true。定位到 hxcpp CppiaClosure::doRun 的 etInt 分支统一按整数装箱，忽略函数声明的 Bool 返回类型；仅当所属模块的返回类型为 Bool 时改用布尔装箱，其余整数不变，JIT 与解释路径均修改。补丁及校验安装器为 tools/hxcpp-origin-cppia-return-bool.patch 和 setup-hxcpp-origin-cppia-return-bool.ps1，原文件备份于 _build/hxcpp-cppia-return-bool-backup-EFED42431DE86317；叠加层变更后旧基础层安装器不能直接 Verify，回滚基础层前先回滚此补丁。单线程增量链接第一次因低于 200 MiB 中止，保留不完整输出后续接链接成功。首个控制夹具生成 CPPIB 被 Polymod 安全校验拒绝，重新用 -debug 生成文本 CPPIA；quant-876.stdout.log 中真实 ready 返回 true 且 isBool=true，真实 warm 返回，对照 CPPIA true/false 均为 Bool、1/0 均为 Int。验证覆盖当前 Windows JIT 动态实例调用，不证明解释路径、所有静态/异步调用或完整 modchart。正常输出已备份至 _build/cppia-return-bool-875/bin-before-875.exe 后更新，obj 与 bin SHA-256 为 11AE51EF24558F489CA3430C7584D1592AAAE54EBBEC40752448F3271CB08367；依赖指纹同步更新。

实验性 0.9 Windows 构建入口（2026-11-14）：普通 lime build windows 不带 CPPIA 宏；新增 tools/build-origin-cppia-windows.ps1，根据 haxelib path 定位所选 hxcpp/Polymod，先以只读指纹脚本拒绝未知组合，再使用 Project-OriginCPPIA.xml、正常输出目录和单线程运行 Lime；每 500ms 检测低于 200 MiB 时停止其构建进程树，监控异常也停止本次进程。-CheckOnly 已在 D 工作区通过，未启动构建；新增脚本的完整构建和低内存停止路径尚未执行，因此不把它们当作验收通过。保持 Project.xml 不变。

NF Lua 摄像机滤镜引用刷新（2026-11-14）：所选 FlxCamera 在渲染时以数组引用比较判断是否重新赋值给 flashSprite；ShaderFunctions.addShaderToCam/removeCamShader 过去原地修改 _filters，可能导致同一数组引用不触发刷新。现在复制已有数组并经 setFilters 提交，保留其他滤镜和既有开关；_build/nf-shader-filter-reference-877 使用提取的实际修改代码及替身相机检查增删后引用变化和已有滤镜保留，Haxe 解释器通过。完整 Windows 构建正在运行，实际着色器图像和 GPU 仍未验收。

NF 滤镜及 CPPIA 构建入口复核（2026-11-14）：tools/build-origin-cppia-windows.ps1 实际完成一次单线程 Windows CPPIA 构建，obj 与正常 bin 程序 SHA-256 均为 80A68568CF3548445EC5B6771D597F6CFC71EE3C3524218473F00CD285613A87，日志位于 _build/origin-cppia-build/build-20261114-023912-2531-15224.out.log；Lime 仍提示已定位的图标资源更新失败。NF 色盲与游戏滤镜的现有轻量检查通过，Lua 增删滤镜的提取代码引用检查也通过。实际着色器画面和低内存终止分支未在该轮验证，不能由编译成功推断渲染正确。

NF Lua 滤镜字段访问修正（2026-11-14）：检查生成的 C++ 发现，FlxCamera 的 _filters 是 getter/setter 属性，动态 camera._filters 以 paccDynamic 访问时不会调用该 getter；因此上一版虽然替换数组引用，仍可能在摄像机路径丢失已有滤镜或使移除失败。现按目标分别以类型化 FlxCamera.filters 或 FlxG.game._filters 读取，复制后通过对应类型写入；空目标安全返回。_build/nf-shader-typed-filter-879 用提取的正式访问方法与属性替身分别验证游戏、摄像机增删保留与空目标；完整构建运行中，真实 GPU 画面未验收。此条取代前述仅验证数组引用的结论。

NF Lua 滤镜类型化访问构建（2026-11-14）：单线程 CPPIA Windows 构建完成，日志 _build/origin-cppia-build/build-20261114-025001-5283-21212.out.log，仍有已知图标资源更新警告。生成的 ShaderFunctions.cpp 显示 FlxGame 分支直接读取 game->_filters 并调用 setFilters；FlxCamera 分支直接读取 filters 并通过类型化 setter 写入，避免此前的动态私有属性读取。该核对与替身夹具不等同于真实着色器画面验证。

Origin 上游复核（2026-11-14）：官方 main 仍为 94ee0f2a9386d80e445be39ee2ed4b4a630cfbac；preview/public-playtest 现为 08c0b800002bd50c432d4f4b5f6fdb3088ca619e，与此前记录的 4a0137e 分叉，但两者源码树差异仅为 assets 子模块指针。对官方资源两棵完整 Git 树 1eb6b7bf49c1be81943e536bd3c0e9c28940122f 与 dbfb530be1a64d7ea90ce74e9c324f95e09aa694 逐路径比较，唯一文件差异是后一版移除了 ui/editors/chart-editor/events/Checkpoint.png 和 Checkpoint.xml；其他文件 blob 均相同。外置资源由用户管理，本次未删除或覆盖这些文件；也没有将先前仅部分移植的预览源码称为完整同步。未做游戏运行测试。

Origin 0.9 摄像机 CPPIA 默认参数兼容（2026-11-14）：探针 `camera-defaults.cppia` 在修复前加载失败，记录见 `_build/cne-isolated-runtime-219/camera-defaults-880.stdout.log`。在已有 `drawTriangles` 的默认参数桥基础上，针对 `drawPixels`、`copyPixels`、`startTrianglesBatch`、`getNewDrawTrianglesItem` 和 `startQuadBatch` 增加精确宿主签名匹配；仅当额外参数是字面 `null` 时去掉该参数，非空 `blendTarget` 的新语义未实现。新增 `tools/hxcpp-origin-cppia-camera-defaults.patch` 与带源码指纹、安装校验及回滚备份的安装脚本；它接在 notestyle 补丁之后安装，回滚时先回滚该补丁。依赖指纹检查通过，单线程 hxcpp 增量编译成功（`_build/cppia-camera-defaults-880/build-881.stdout.log`），隔离存档的可见窗口加载合成探针并完成脚本预热（`_build/cne-isolated-runtime-219/camera-defaults-881.stdout.log`，零预热错误）。探针验证链接与加载，并未执行真实摄像机绘制或证明全部模组兼容。普通输出 exe 已更新，旧文件备份至 `_build/cppia-camera-defaults-880/bin-before-881.exe`。

摄像机默认参数验证更正及复测（2026-11-14）：881 探针确已成功链接并通过脚本预热，但此前启动参数 `--origin-test=compat` 缺少必需的 `--origin-fixtures`，随后 CompatibilityChecks 主动抛错；该轮不构成正常进入菜单的证据。使用相同构建、隔离存档及可见窗口改以 `--origin-test=main` 复测，合成摄像机探针与未修改 Modchart Engine 1.0.3 同时加载，脚本预热 150 类、11680 引用、0 错误，真实模组五个模块完成加载，日志确认进入主菜单并转为 Idle（`_build/cne-isolated-runtime-219/camera-defaults-882.stdout.log`）。退出阶段关闭窗口后进程先行结束，随后 taskkill 输出进程不存在；未见该轮未捕获异常。此测试仍未执行探针中的绘制调用或完整歌曲。

谱面重复音符删除修正（2026-11-14）：`SongDataUtils.subtractNotes` 原先按 `==` 过滤全部匹配项；两个音符属性相同并共享参数数组时，删除其中一个会一起删掉另一个，影响删除重叠音符及依赖该方法的编辑命令。现先为每个目标保留精确实例匹配，再对未匹配目标使用原有 `==` 克隆回退，每个目标最多消费一个音符，保持剩余顺序及输入数组。提取正式方法、使用提取的音符类型的夹具在修改前复现误删，修改后覆盖重复实例、克隆回退、实例优先、不同类型、顺序和输入不变（`_build/origin-note-subtract-883/after.log`）；这不是完整编辑器交互测试。单线程 CPPIA 完整构建通过（`_build/origin-cppia-build/build-20261114-031859-8148-56476.out.log`），Lime 仍输出已知 `Failed to update resources` 警告，正常输出和 obj 程序哈希一致。此修正不解决 `SongNoteData.clone` 参数数组共享的问题。

谱面复制难度隔离（2026-11-14）：`ChartEditorState.cloneDifficulty` 原本使用 `ArrayTools.clone`，只复制容器而保留音符实例，编辑复制后的难度会改变原难度的音符及参数。现对每个音符使用现有 `MoveNoteHistory.snapshot` 复制，包括参数内嵌套 JSON 数组和对象；空或缺失难度仍沿用原有创建空难度路径。提取生产复制语句及生产快照方法的 Haxe 夹具中，旧数组浅复制复现源难度被修改（`_build/origin-difficulty-copy-884/before.log`），修改后音符时间、参数名及嵌套值独立，空／缺失检查通过（`after.log`）。这是逻辑夹具，未操作真实编辑器，代码变更尚未重新完整编译；不代表全局 `SongNoteData.clone` 参数共享问题已经解决。

谱面级深复制与合并构建（2026-11-14）：`SongChartData.clone()` 以前的音符参数值、事件值和 `editorData` 仍可能与原谱面共享；`SongChartEditorData.clone()` 也只复制数组而共享图层和批注对象。现复制谱面中可编辑的音符参数及事件嵌套 JSON 值，独立复制编辑器数据与图层、批注；原单个 `SongNoteData.clone()` 及相等语义未改变。`_build/origin-chart-clone-885/after.log` 使用提取的生产复制方法、音符类型和替身事件／谱面对象，验证嵌套参数、事件、图层、批注、速度独立及空 editorData；并非真实编辑器交互。该修复与上一条复制难度修复一并完成单线程 CPPIA Windows 构建，日志 `_build/origin-cppia-build/build-20261114-033252-7953-55672.out.log`；仍有 `Failed to update resources` 警告，普通输出与 obj 程序 SHA-256 均为 27B1DD672407A4C2447ADE9DA8729C1625E9574FD2B0F68125C6707EBCFDEB72。未验证 GPU、完整模组或所有脚本复制行为。

Origin 0.9 CPPIA 音符样式路径补充（2026-11-14）：固定官方预览源码的 `getNoteAssetPath()`、`getStrumlineAssetPath()` 是无参、返回 AssetPath；本地历史宿主对应方法接受一个可选参数并返回 String。编译的无参合成脚本修复前在可见隔离窗口加载时以 `Invalid arg count` 失败（`_build/cne-isolated-runtime-219/notestyle-zero-886.stdout.log`）。现新增两个保留的预览桥；hxcpp 补丁仅在精确宿主类型、旧签名 `so`、非 super 且零参数时将这两个方法路由到返回对象的桥，原 holdNote 桥及历史带参数调用保留。补丁及哈希校验／回滚脚本为 `tools/hxcpp-origin-cppia-notestyle-zero.patch`、`tools/setup-hxcpp-origin-cppia-notestyle-zero.ps1`，需在 camera-defaults 等基础补丁之后安装，回滚按相反顺序。依赖指纹检查及单线程完整构建通过（`_build/origin-cppia-build/build-20261114-034720-3421-54592.out.log`），构建仍有 `Failed to update resources` 警告。可见隔离窗口中，同一探针加载并实际调用默认 NoteStyle，新 note 与 strumline 返回 AssetPath 且 exists 均为 true，旧版带可选参数调用仍返回 String；日志 `_build/cne-isolated-runtime-219/notestyle-zero-887.stdout.log`，预热 0 错误，正常退出。探针为合成 CPPIA，未覆盖真实模组的该两条调用、原生子类、脚本覆盖、super 或其他路径签名，也不代表所有 0.9 脚本兼容。

Origin 0.9 CPPIA 一参数样式路径兼容（2026-11-14）：官方预览的 `getCountdownSoundPath`、`buildJudgementSpritePath`、`buildComboNumSpritePath`、`getHoldCoverDirectionAssetPath` 接受一个参数并返回 AssetPath，历史宿主接受两个参数并返回 String。合成新旧脚本在修复前以 `Invalid arg count` 加载失败（`_build/cne-isolated-runtime-219/notestyle-one-888.stdout.log`）。现为四个方法添加预览桥；hxcpp 按精确 NoteStyle 类型、各旧宿主签名、非 super 及一个参数筛选，只有新形状路由到对应桥；旧编译脚本包含第二个可选参数，仍走历史路径。`tools/hxcpp-origin-cppia-notestyle-one.patch` 及安装器提供指纹验证和备份，需接在 notestyle-zero 后安装、先回滚；依赖检查及单线程 Windows 构建通过（`_build/origin-cppia-build/build-20261114-040159-9083-19196.out.log`），保留已有 `Failed to update resources` 警告。可见隔离窗口中同一探针对默认样式实际调用四组新旧接口，四个新结果均为存在的 AssetPath，四个旧结果均为 String，脚本预热零错误、进程退出 0（`_build/cne-isolated-runtime-219/notestyle-one-889.stdout.log`）。这是合成 CPPIA；未验证真实模组、原生子类、脚本重写、super 及同参数数量但返回类型变化的其他接口。

CPPIA 与 HScript 组合原生崩溃（2026-11-14）：当前构建的可见隔离窗口中，未修改 Modchart Engine 1.1.0 与合成 `notestyle-one` CPPIA／HScript 探针同时加载时，两次在两个编译模块 boot 完成后、脚本预热完成前出现访问冲突（`_build/cne-isolated-runtime-219/notestyle-engine-890.stdout.log`、`notestyle-engine-892.stdout.log`，进程退出 -1073741819；对应 `crash/native-crash-20261114-041537-746-p58280-t55788-2.*` 和 `crash/native-crash-20261114-041745-851-p18504-t50896-2.*`）。同一构建中真实模组单独运行进入主菜单（891）；去掉探针 HScript、保留两个 CPPIA 时进入主菜单（893）；去掉探针 CPPIA、保留 HScript 时预热完成（894）；两 CPPIA 加简化空 HScript 时进入主菜单（895）。原 HScript 仅保留全部六个 import 与空类时仍崩溃（896），单独包含 AssetPath 导入（897）、保留其他导入但去除 CountdownStep（898）、仅包含 CountdownStep（899）均进入主菜单。样本显示特定组合相关，不能归因于某个单独导入或证明并发为根因。崩溃转储已保留；本次 exe 缺少可用匹配符号，故尚未定位原生堆栈与修复。全部测试使用隔离存档，结束后恢复原 1.0.3 隔离样本；不得将上一轮探针独立通过解读为该组合通过。

组合崩溃原生定位补充（2026-11-14）：重链接生成完整 map 时可用内存跌破 200 MiB，监控终止进程；原 `obj/ApplicationMain.exe` 已恢复，SHA-256 与崩溃副本均为 `9286401ab59c03bf38b2c7776405f8c08663059985ab978e91149e4b38edab94`。未完成 map 与 2 MiB 部分 exe 保存在 `_build/origin-crash-symbols-900`，不得作为可执行构建。以该 exe 故障 RVA 的机器码在当前 C++ 目标文件中精确匹配：`0x7fa2273` 对应 `661ad508_Immix.obj` 的 `hx::MarkStringArray` 第 0x43 字节；另两个原始栈候选分别匹配 `hx::MarkContext::processMarkStack` 和 `GlobalAllocator::ThreadLoop`，见 `evidence.json`。这不是使用 PDB 完整展开的调用栈。首个转储中的 String 数组包含 `ui`、`debug`、`stage` 等片段，一个元素的数据指针高位已损坏，故现有证据表明 GC 扫描时读到无效字符串指针，尚不能证明是谁或何时写坏，也不能认定与标题视频崩溃同一根因；未修改 GC 或声称修复。

脚本同步注册对照（2026-11-14）：为避免重链时再次超出内存保护线，核对原 exe 的 `OriginFunkinBootState.initializeOrigin` 目标文件及机器码后，仅对隔离副本 `NovaFlare-Origin-CPPIA-902.exe` 的唯一匹配指令将 `loadScripts(true)` 的显式 Bool 值改为 false；原始及副本 SHA-256 分别为 `9286401ab59c03bf38b2c7776405f8c08663059985ab978e91149e4b38edab94` 和 `c2379980a399918e3a40c3f5f8922e6b57913f420d965795c86b0ca6d87c70d6`，文件只改变一个字节。与 890 相同的真实 Modchart Engine 1.1.0 加原 CPPIA/HScript 探针在可见隔离窗口中同步注册通过预热，四组新旧接口调用均成功，退出 0（`_build/cne-isolated-runtime-219/notestyle-engine-902.stdout.log`）。原始程序仍保持原值。同步注册会改变加载顺序与线程/时间特征，一次通过只能说明该对照不再复现，不能认定异步路径或某个线程是根因，亦不能证明该组合长期安全；尚未将同步路径作为正式修复。此前生成源码对照因可用内存低于 200 MiB 被终止，恢复时目标文件曾被短暂锁定；进程结束后源码、目标文件和可执行文件均逐项恢复并哈希核对，未完成输出留于 `_build/origin-sync-script-diagnostic-901`。


CPPIA 与 HScript 混合加载崩溃排查（2026-11-14）：在隔离运行目录中，真实 Modchart Engine 1.1.0 与合成 NoteStyle CPPIA/HScript 同时启用时，两次在预热完成前触发原生访问异常（`notestyle-engine-890.stdout.log`、`notestyle-engine-892.stdout.log`）；删去任一合成脚本或改为同步加载后，所做的单次对照没有复现。同步对照同时改变时序和注册顺序，不能确定根因。转储定位到 hxcpp `hx::MarkStringArray` 读取损坏的字符串指针，具体写坏者尚不明，不能将此归因于标题视频崩溃。证据及原文件哈希见 `_build/origin-crash-symbols-900/evidence.json`。

线程路径复核：当前 Polymod 核心资源 `loadText` 经 `BaseFileSystem.loadFileBytes` 使用 `new Future(work, true)`；该 Lime 版本 `FutureWork.threadPool_doWork` 通过 `sendComplete`，`ThreadPool.onComplete` 在主线程派发，才完成 Promise。核心资源 `loadBytes` 的本地文件路径经 `NativeHTTPRequest.localThreadPool`，同样通过主线程完成回调。因此不能以这两条路径绕过模组资源专用 `LimeAsyncHandler` 为理由断言脚本注册发生在工作线程；这里只核对源码路径，不排除其他线程安全或内存问题。暂未应用猜测性修复，继续保留该崩溃为未解决。


模组异步读取失败处理（2026-11-14）：Polymod `LimeAsyncHandler` 原 worker 对空读取结果直接取 length，对抛出的读取异常未构造带原 Promise 的错误事件；无效任务发出的错误也缺少 Promise。Origin 编译宏保留成功回调主线程派发，并在空值、读取异常及无效任务时发送包含原 Promise 的错误事件，避免等待请求无法结束。`_build/origin-async-reader-903` 以真实编译宏和匹配的 worker 形状做 Haxe 解释器检查，成功、空值、异常及无效任务均通过；该替身检查不等于完整游戏重编译、真实线程池或受损模组运行验收，也不代表已修复此前原生 GC 崩溃。

异步读取类型检查补充（2026-11-14）：使用项目当前 release HXML、CPPIA 和全部实际依赖，以隔离输出目录及 `--no-output` 运行 Haxe 类型检查，退出码 0（`_build/origin-async-typecheck-904`）；未生成或替换正式程序。该结果不代替原生编译及真实线程池运行验收。脚本加载器的 `registerScriptClassByPathAsync` 已核对有 `onError`，会将读取错误传递给注册 Promise。

异步读取线程池检查补充（2026-11-14）：`_build/origin-async-threadpool-905` 在 Neko 下使用实际 Lime ThreadPool 和 Promise，以及与 Polymod worker 形状匹配的夹具和正式编译宏，确认正常数据、空值、抛异常三种情况均结束且回调在主线程；进程退出 0。Haxe `--interp` 的首次尝试在线程池内部因 output 为 null 失败，不算通过。该检查不是 hxcpp 或完整游戏运行验收。

异步读取 Windows 原生夹具补充（2026-11-14）：使用本项目 hxcpp 与 Lime 的真实 ThreadPool/Promise，以正式编译宏作用于匹配的 worker 夹具，Windows 单线程编译及运行退出码均为 0；成功、空返回和异常回调均在主线程完成（`_build/origin-async-threadpool-906/build.out`、`run.out`）。此为原生夹具，不是实际 Polymod 后端或完整游戏测试；此前混合模组原生 GC 崩溃仍未修复。

谱面节拍细分隔离（2026-11-14）：`SongTimeChange` 以前将所有缺省 beatTuplets 指向同一可变数组，clone 也复用源数组；现仅为缺省值及 clone 复制数组，明确传入数组的构造语义不变。同时把缺省数组的静态初始化放在默认时间变化对象之前，防止默认对象在数组初始化前取得 null。`_build/origin-tuplet-clone-907` 从正式类提取源码，修改前复现共享默认数组、修改后验证默认对象及多实例隔离、clone 隔离和显式值保留；为 Haxe 解释器轻量测试，尚未验证完整游戏或用户谱面。

谱面元数据克隆修复（2026-11-14）：`SongPlayData.clone` 现保留 Discord 图像和 stickerPack；`SongMusicData.clone` 现逐项克隆时间变化，配合节拍细分数组隔离，避免编辑快照与原始音乐数据共享节拍信息。`_build/origin-song-metadata-clone-908` 从正式类提取代码，使用替身依赖；修改前复现字段丢失和时间变化共享，修改后通过。尚未进行游戏内编辑器验收或完整原生构建。

音符步数缓存修复（2026-11-14）：`SongNoteDataRaw.getStepLength(true)` 现同时强制重新计算音符起点，避免 BPM 变化后终点使用新节拍而起点仍用旧缓存；设置音符时间也会清除依赖起点的长度缓存，避免移到变速点另一侧后沿用旧长度。谱面编辑器的 ghostHold 长度处理实际调用 `getStepLength(true)`。`_build/origin-note-step-cache-909` 提取正式方法并用变速 Conductor 替身复现两种问题，修复后通过；完整游戏、真实节拍器与旧模组运行尚未验证。

批次构建记录（2026-11-14）：`tools/build-origin-cppia-windows.ps1` 的依赖指纹检查通过，单线程 Haxe 与 C++ 编译到 100%，链接器生成候选 EXE；但包装脚本读取的子进程退出码为空并报告失败，故本次整轮构建结果未确认，不计为通过。候选程序保留在 `_build/origin-batch-build-910`；普通 bin 和 obj 的原 EXE 已从事前备份恢复并校验 SHA-256 `9286401ab59c03bf38b2c7776405f8c08663059985ab978e91149e4b38edab94`。候选 obj 与 bin 的 .text 哈希一致，但这不证明正常运行。链接期间最低观察到可用内存约 341 MiB，200 MiB 自动停止条件未报告触发；无用户模组或资源改动。日志 `_build/origin-cppia-build/build-20261114-051719-4713-53676.out.log`、`_build/origin-batch-build-910/build.log`。

候选构建隔离可见窗口检查（2026-11-14）：候选 `5252589f9bc97ed07d8ca1468a0364a55a40cbcc77ae0a00e941b3501365356b` 加载真实 Modchart Engine 1.0.3 的 CPPIA，并进入 Mod Menu 绘制，但随后发生 `hxSehException`（`candidate-911.stdout.log`；不要将脚本捕获到加载标记或进程 exit 0 当作通过）。旧程序 `9286401a...` 同样在该隔离环境和同一菜单报错（`candidate-control-912.stdout.log`）；旧程序以空模组选择进入菜单仍报错（`candidate-control-913.stdout.log`）。异常栈在 `FlxSprite.draw`、`FunkinSprite.draw` 和 `FunkinGroup.drawToRenderTexture`，首遇访问异常读地址 0x50；根因尚未确认，不能认定这次新改动或模组本身导致，也不能认定完整 Origin 或模组菜单已通过。常规 bin/obj 保持旧程序，候选仅作隔离测试。

模组菜单 WebP 图标空帧修复（2026-11-14）：`frame-diagnostic-917.stdout.log` 的隔离可见窗口诊断定位到 Pico Chill Mix 两个版本的图标精灵帧为空；原包 `_polymod_icon.png` 内容实际为 336×188 静态 WebP，Lime 动画解码未创建位图。`ModMenuItem` 现在先尝试动画解码、失败后尝试静态解码，再用菜单备用图标；备用图也无法产生帧时隐藏该图标并记录日志，避免空帧绘制。`frame-diagnostic-918.stdout.log` 在旧程序内由临时 HScript 在绘制前模拟普通解码及备用流程：实际静态解码返回 0×0，两项均成功设置备用帧，窗口继续运行三秒无上述异常。正式改动使用项目 release 配置与真实依赖的隔离 Haxe `--no-output` 类型检查退出码 0（`_build/origin-icon-typecheck-919`）；尚未编译新程序实测该正式代码，也未实现静态 WebP 本图解码。诊断模组已移出活动模组目录。

Windows 静态 WebP 图标兼容（2026-11-14）：原 Lime `LimeCompat.cpp` 的 `lime_webp_decode_bytes/file` 是返回 null 的占位实现；Pico Chill Mix 原图是静态 WebP。新增 Origin 专用 WIC 解码桥，仅在 Windows C++、Lime 解码失败且文件头为 WebP 时尝试系统安装的 WIC 编解码器；不支持或失败时保留备用图标。解码限制尺寸、输出长度，回收 COM 对象并保留已有线程的 COM 模式。`_build/origin-wic-webp-920` 使用正式原生辅助函数及该原始 336×188 图标得到 RGBA，逐字节与独立解码结果相同，同时拒绝无效输入和过小输出；`_build/origin-wic-typecheck-921` 为完整项目实际依赖的 Haxe 类型检查，退出 0；`_build/origin-wic-haxe-922` 的正式 Haxe 桥生成 C++ 且单独用 MSVC 编译通过。尚未完成完整程序链接和游戏内显示验收，不保证系统均安装 WebP WIC 解码器，也不证明动画 WebP 兼容。

Windows WebP 完整构建与真实图标运行（2026-11-14）：构建脚本保留子进程句柄以读取退出状态，本轮单线程 `build-origin-cppia-windows.ps1` 退出 0；Lime 日志仍有 `Failed to update resources` 警告。常规 bin 的 EXE SHA-256 为 `d2aef63a8576bea5b34a18799cfa4fd16ca066d5cd22d9dcc5c6a8521f842ee9`。在带隔离存档标记的可见窗口，用该构建打开 Mod Menu，临时只读探针在绘制前检查真实 Pico Chill Mix 两个版本：两个图标均有帧、位图为 336×188、左上像素 FF020202，与原始 WebP 解码一致；随后菜单持续 4 秒未发生先前空帧异常（`_build/cne-isolated-runtime-219/wic-924.stdout.log` 和 `wic-924.result.txt`）。探针已移出活动模组目录；未验证整个模组游玩、其他 Windows 的 WIC 组件、动画 WebP 或此前混合模组 GC 崩溃。

混合 CPPIA/HScript 可见窗口复核（2026-11-14）：使用新构建 EXE `d2aef63a8576bea5b34a18799cfa4fd16ca066d5cd22d9dcc5c6a8521f842ee9`，在隔离存档中同时启用真实 Modchart Engine 1.1.0 与合成 NoteStyle CPPIA/HScript 探针；两份 CPPIA 均加载，探针四项新/旧路径返回检查为 `true:true/true`，进入 Mod Menu 后继续运行 4 秒并退出 0（`_build/cne-isolated-runtime-219/mixed-925.stdout.log` 和 `mixed-925.result.txt`）。隔离运行时原有 1.0.3 模组已移回，临时模组从活动目录移出。本次单次通过不能证明此前两次复现的 GC 内存损坏已修复；尚未确定根因，也未验证真实谱面游玩。

Hex 0.9 样式与 Modchart Engine 1.1.0 联合加载（2026-11-14）：新构建 `d2aef63a...` 在可见隔离窗口同时加载真实 Modchart Engine 1.1.0、作者固定提交 c9c344d 的 Hex V3 两个原始 NoteStyle 脚本及图集子集、只读探针。两种原样式分别创建 NoteSprite：hex_mines 28 帧、purple 动画 7 帧，hex_mine_reg 14 帧、动画 14 帧，scale 均为 0.7；日志 `_build/cne-isolated-runtime-219/hex-engine-926.stdout.log`，进程退出 0。隔离运行时原来的 Mod Engine 1.0.3 已恢复，测试模组副本移出活动目录。该测试创建后立即销毁音符，未验证画面、真实谱面、整包 Hex 或歌曲游玩；它不证明此前随机原生 GC 崩溃已修复。

角色人声配置克隆（2026-11-14）：`SongCharacterData.clone` 原先在源 playerVocals 或 opponentVocals 为 null 时，保留构造器生成的角色默认列表，丢失 null（自动发现）与显式列表的区别；现分别保留 null、空数组及非空数组，并复制非空数组。`_build/origin-vocals-clone-927` 使用提取的实际类和数组复制替身，在修改前复现 null 被替换，修改后验证三种配置和修改隔离。此为轻量检查，尚未在完整游戏中验证人声选择或构建新二进制。

旧 Flixel 信号 CPPIA 原生调用（2026-11-14）：在新构建 `d2aef63a...` 的可见隔离窗口，分别加载 `_build/cppia-signal-fallback-836` 已核实类型名与 CALLMEMBER 的旧名和当前名合成 CPPIA 模块；HScript 探针使用游戏中真实 FlxSignal0/1 对象及监听函数，分别添加、派发、移除、再派发。两组均记录 `hits=1 total=7 pass=true`，退出 0，未见 Bad link 或 Invalid arg count（`signal-legacy-928.stdout.log`、`signal-current-928.stdout.log`）。临时模组已移出活动目录。这覆盖与真实 Mod Engine 静态引用相同的旧名称和调用形状，但不是实际 Mod Engine 的 Backdrop/Field 运行，也不证明所有 Flixel 版本或回调兼容。

Hex 原始 Mine 漏按事件检查（2026-11-14）：新构建在可见隔离窗口加载 Modchart Engine 1.1.0、Hex V3 作者固定提交 c9c344d 的原始 `gameplay/notekinds/Mine.hxc` 与先前音符样式子集。实际 NoteKindManager 实例化 `kade.hex.notes.Mine = mine`；独立探针构造可取消的 NOTE_MISS 事件，通过正式 ScriptEventDispatcher 分发到该对象，日志 `HEX929 kind=mine style=hex_mines canceled=true`，退出 0（`_build/cne-isolated-runtime-219/hex-mine-929.stdout.log`）。Mine 脚本复制前后 SHA-256 均为 `dee514a17af266b2b64ffba377f203dfb48635d740db6e26b31641bfc594cb8a`；隔离模组已恢复。该事件的 note 为 null，且由测试探针触发，未覆盖实际漏按、生命值、音符画面或完整 Hex 歌曲。

Hex 地雷实际游玩路径（2026-11-14）：在隔离存档、可见窗口加载 Modchart Engine 1.1.0 与 Hex V3 原始 `Mine.hxc`（SHA-256 `dee514a17af266b2b64ffba377f203dfb48635d740db6e26b31641bfc594cb8a`）及其样式；诊断模块只在内存中把 Bopeebo 测试谱面替换为 5 秒处一个 `mine` 音符，歌曲开始后关闭自动演奏。日志 `_build/cne-isolated-runtime-219/hex-mine-gameplay-930.stdout.log` 显示实际游玩中注册 `kade.hex.notes.Mine`、音符自然漏过，并在后续更新读到该事件 `canceled=true`、`kind=mine`、`hasMissed=true`；程序正常关闭，stderr 为空。事件在记录前已归还对象池，因此该后续读取只作为辅助观测；前一轮 929 直接分发验证了原始 Mine 处理器会取消事件。这不是完整 Hex 歌曲、地雷命中、积分变化或正式完整包的验收。测试副本已移出活动目录，原隔离模组恢复，用户模组和存档未改。使用的是 924 测试程序，不包含之后尚未重新构建的源码更改。

资源安全别名与真实模组复测（2026-11-14）：本次 Windows CPPIA 单线程构建 944 退出 0，bin 和 obj 的 EXE SHA-256 为 `c32de4519a7822f5059bed7127012bc3fcfd24befddc0fc462cf827c7468db08`，构建日志仍报告 `Failed to update resources`。可见隔离窗口中 Yippie 0.3.2 进入播放且 5 秒短测退出 0，但有三条 NoteStyle null 注册表错误，不能记作无错误通过；Alien Hominid 0.5.0 加载舞台与角色，记录 HominidShader 调用 `openfl.utils.Assets` 被黑名单拦截，110 秒测试到时未观察到伴奏开始（主动结束后进程码 1），不能证明单一脚本错误就是未启动的唯一原因。结果、日志及用户存档、chain.json、Project.xml 前后哈希在 `_build/origin-integrated-build-944/runtime-results-945.json`；首次测试脚本遇到日志共享冲突而中断，使用 945 修正监控后重测。

根因检查确认 `buildBlacklist` 先给 `openfl.utils.Assets` 和 `lime.utils.Assets` 注册到 `funkin.Assets` 的安全别名，随后 `blacklistImport` 将同一映射覆盖为 null。已删除这两次覆盖，保留安全包装映射与 `funkin.Assets.getLibrary`、`Sys` 等原有限制；`_build/origin-assets-alias-946` 使用当前实际 Polymod 解释器、项目 nullDeprecationSafety 宏和替身资源包装，复现原先黑名单错误；修复顺序下两个导入的 `getText` 可调用，`getLibrary` 仍被拦截、Sys 映射仍为空。别名修复的单线程构建 947 在链接阶段系统可用内存低于 200 MiB，由监控终止，退出 1；正式 bin 程序未被覆盖，损坏的 obj EXE 已从哈希一致的构建前备份恢复。该修复尚未进入现有程序，不能声称 Alien Hominid 已修复或运行通过。

Alien Hominid 安全包装隔离对照（2026-11-14）：在不更改原模组的情况下复制已安装的 0.5.0 模组，只将副本 `hominidShader.hxc` 的 `openfl.utils.Assets` 导入替换为同一安全包装 `funkin.Assets`，使用尚未包含 947 别名修复的 944 程序，在可见窗口和隔离存档中启动 Eradication。日志 `_build/origin-alien-alias-runtime-949/stdout.log` 显示加载舞台、角色并开始播放歌曲，短测约 5 秒后正常退出 0，未见此前的资源类黑名单错误；`result.json` 记录原模组脚本及用户存档、chain.json、Project.xml 哈希不变。测试副本已移出活动模组目录。这支持资源别名冲突是先前失败的一个原因，但副本修改不等于原包直接通过；正式源码修复仍未链接进游戏，完整歌曲、图像效果及其他版本均未验收。

Alien Hominid 原包及低内存链接（2026-11-14）：复用 947 已生成的正式 C++ 对象，在独立配置中选择本机 LLVM `lld-link` 并设置 `/threads:1`，输出到 `_build/origin-lowmem-link-952/AliasCandidate.exe`；链接退出 0、采样最低可用物理内存 2,034,844 KiB，候选 SHA-256 `df97f5a90b6004cd508b9e67653cecb82e671913b54a9477532b8ae3cbde69fe`。950/951 两次路径引用失败发生在链接器启动前，952 使用指向已安装 LLVM 目录的工作区 junction 修正；用户的 hxcpp 全局配置未修改。候选是从 947 对象单独链接的实验程序，未完成普通 Lime 后处理或替换正式输出；bin 和原 obj 程序哈希仍为 `c32de451...`。

使用候选程序和未修改的隔离 Alien Hominid 0.5.0 原模组，可见窗口中 Eradication 进入播放，继续约 5 秒后主动关闭，进程退出 0，stderr 为空，日志未出现先前 `openfl.utils.Assets` 黑名单错误（`_build/origin-integrated-build-944/alien-05-953.stdout.log`、`runtime-results-953.json`）；用户存档、chain.json 和 Project.xml 哈希前后一致。这验证了实际原模组的启动与短时游玩，不证明整曲、着色器视觉效果、所有别名访问方式或正式发行构建完成。

Yippie 音符样式缺失归属（2026-11-14）：945 日志中的 `item(null)` 指请求的样式 ID 是 `item`，不是样式 ID 本身为 null。原 Yippie 谱面元数据明确指定 `noteStyle: item`，该原包未提供相应样式；官方 v0.3.2 的 assets 固定子模块 `962130b2243a839106607d08a11599b1857bf8b3` 中 `preload/data/notestyles` 也只有 `funkin.json` 和 `pixel.json`。因此本次回退到默认样式是对缺失内容的处理，暂归为模组缺失样式，非已证明的引擎旧格式缺陷；不能据此推断作者预期画面。更正上文“NoteStyle null 注册表错误”的简写。

滚速边界源码修复（2026-11-14，尚未编译）：`Strumline` 根据滚速绝对值计算默认音符生成距离，脚本设置负滚速时不再得到负生成距离；滚速恰为零时使用普通窗口，避免无限距离一次生成整首谱面的音符。漏按音符的屏外回收方向也随负滚速反转。自定义生成距离仍按模组提供的值使用。此处仅修复生成窗口和普通音符回收，零速下远期音符不会全部提前生成；尚未证明负速长条、复杂滚速曲线或任何真实模组的完整显示与判定，均需统一运行验收。

旧谱面空音符处理（2026-11-14，尚未编译）：`songNotesMap` 为兼容旧解析器允许音符数组内的 null；音符样式预查询、PlayState 分轨和公开 `Strumline.applyNoteData` 先前仍会解引用空项或在排序中使用它。现仅在这些消费路径跳过 null，保留谱面原始数据和历史 `listNoteStyles` 空结果行为。尚未覆盖全部编辑器/工具消费者，也没有用空项谱面做运行验收。

旧谱面复制与保存空值（2026-11-14，尚未编译）：旧解析允许空难度及空音符，但谱面深复制会直接遍历空难度或克隆空音符，保存也通过该复制路径；现复制时保留这些空值，清理输出中的空难度时将 null 难度视为空难度，并为编辑器复制难度保留空音符。事件数组中的空项也在复制时保留。此项只覆盖复制和保存前清理，不证明所有编辑器或事件消费路径接受空项；等待统一编译及运行验证。

谱面空事件消费保护（2026-11-14，尚未编译）：谱面克隆保留空事件后，事件资源查询、按激活时间排序、派发、查询/跳过/重置、滚速时间线及 PlayState 的重置扫描现跳过空事件；排序把空项放在有效事件之后，保留原列表及有效事件对象。此修改为容错，不表示任何已测试真实模组含空事件；编辑器其他事件路径与运行结果仍待验证。

Mindless 非官方回合接口补充核查（2026-11-14）：原包 CameraMovementModule 在 `onSongEvent` 中按 FocusCamera 的 char 参数独立选择目标；其额外 `onTurnChange` 分支读取 `PlayState.instance.isPlayerTurn`。当前 Module 仅提供兼容用空父方法，源码既未派发此回调，PlayState 也没有该属性。由于官方 0.8.7 不定义这套回合接口，且该模组已使用 FocusCamera 事件，暂不臆造回合切换规则；此分支未验证，不能把先前成功进入歌曲解释为该接口可用。

资源枚举前缀兼容（2026-11-14，尚未编译）：`Assets.listDataFilesInPath` 与已修正的 `listInPath` 一样接受带 `assets/` 前缀的路径，避免重复添加前缀后找不到文件；既有不带前缀的注册表调用保持原路径。尚未发现真实模组使用该带前缀调用，也未进行运行验证。

历史 DataAssets 接口批量核对（2026-11-14）：离线读取官方 v0.3.2、v0.5.0、v0.7.5 三个源码快照，`funkin.util.assets.DataAssets.listDataFilesInPath` 都以 `assets/data/` 加调用方路径枚举文本资源，返回去前缀、去后缀且去重的结果。本地兼容入口委托 `Assets.listDataFilesInPath('data/$path', suffix)`，主要路径构造和结果形状一致；当前真实模组样本未检出该接口调用，不能据此认定所有资源库或模组运行通过。v0.3.2 文件的 Git 按需抓取网络重置，本次证据取自已保存的固定版本 ZIP。

真实脚本接口交叉核查（2026-11-14）：对隔离目录中 14 个非诊断 GameBanana 模组的 HXC 按 `PlayState.instance.<成员>` 筛查得到 32 个名称；未在 PlayState 直接声明的常见 `add`、`insert`、`members` 和 `refresh` 属于继承路径，不能当作缺失。Playable KB 原包 `RandomSkinModule` 使用 `onCreatePost` 与 `PlayState.instance.player.changeCharacter`；本地 PlayState 没有 player 属性，事件分发也未发现该回调。对官方 v0.3.2、v0.5.0、v0.7.5、v0.8.7 的 PlayState、Module 和事件分发器快照核对，同样未发现这些声明。该模组额外分支暂归为非官方接口、未验证行为，不因为此前进入歌曲而声称随机皮肤成功；暂不凭词法结果伪造 API。

FocusCamera 默认目标源码修复（2026-11-14，尚未编译）：旧式整数事件值仍用于选择角色；当事件值为只含位置或缓动字段的对象且没有 `char` 时，不再把整个对象强转为整数，而使用已有的默认目标。已检查的 Mindless 原谱 47 个 FocusCamera 事件都显式包含 `char`，因此该检查不能作为此边界在真实模组中出现或运行通过的证据；需统一验收。

真实谱面事件批量静态核对（2026-11-14）：读取隔离目录 14 个非诊断 GameBanana 模组中 36 个谱面文件，统计 2868 个事件；其中 FocusCamera 共 885 个，368 个值是旧式整数，来自 Azzy 0.5.3 与 Devil’s 0.4.1/0.5.1，数值均为 0 或 1；其余对象事件均显式包含 char。新默认目标防护仍保留整数分支；这是文件形状检查，没有执行事件。Pico Chill 0.5.1/0.5.3 合计 6 个 ScrollSpeed 事件均使用 both、相对倍数及现有 ease 字段，可用于统一运行回归，静态数据不证明滚速显示或判定已通过。

ZoomCamera 事件临时对象回收（2026-11-14，尚未编译）：事件使用 `FlxPoint.get` 创建临时缩放参数，但原实现计算后未将它归还对象池。现完成计算后调用 `put()`，不改变缩放公式；已核对的 36 个真实谱面包含 225 个此类事件。该源码修复尚未运行验证，不能据此量化内存占用变化或证明模组演出画面正确。

歌曲过场视频源码生命周期修复（2026-11-14，尚未编译）：`VideoCutscene` 在 hxvlc `load` 或 `play` 返回 false 时调用现有结束流程，避免一直停留在黑屏；结束和销毁标记阻止重入，空播放器不再无条件销毁。原生播放器的格式、错误和结束回调先确认仍属于当前播放器；延迟淡出捕获原屏幕、状态、过场类型及世代，避免旧回调删除新屏幕或执行新过场的结束动作。结束动作现使用捕获的类型。此改动针对歌曲过场，尚未验证真实媒体失败、重复播放、重入、状态切换或移动端；它不证明标题视频原生堆损坏的根因或修复。

歌曲过场重复进入补充（2026-11-14，尚未编译）：新过场替换前先销毁现有播放器与黑屏，取消上一段由 VideoCutscene 自己创建的相机恢复动画；显式销毁时也取消该动画并释放黑屏。此处理不取消其他模块的相机动画。代码路径尚未进行运行验证，尤其需要覆盖连续过场、结束监听器中启动新过场以及状态销毁。

HTML5 过场回调补充（2026-11-14，尚未编译）：HTML5 视频结束回调现在确认播放器仍为当前实例；FlxVideo 销毁时移除其此前注册的音量变更监听并清除结束回调。该项根据源码生命周期审查，尚未在浏览器中验证，不能推断 Windows 原生视频行为。

真实模组视频缺失时的倒计时兜底（2026-11-14，尚未编译）：Mindless 原脚本 `onCountdownStart` 会先 `e.cancel()` 再请求视频，因此旧 `VideoCutscene.play` 在资源不存在时直接返回可能让倒计时无法继续。现记录缺失路径并在下一次更新发送结束信号、按请求的过场类型继续；延迟回调检查原 PlayState 和过场世代，避免覆盖后续过场。隔离样本中存在 `videos/videos/HUMAN.mp4`，未证明该文件实际加载失败；本次仅修复缺失场景的控制流，未运行影片、故事模式或缺失资源对照。

旧版模组视频路径回退（2026-11-14，尚未编译）：官方 v0.3.2、v0.5.0、v0.7.5 和 v0.8.7 的 `Paths.videos` 默认使用 videos 资源库和 `videos/` 相对目录；Mindless 原包实际文件为 `videos/videos/HUMAN.mp4`，其脚本调用 `Paths.videos('HUMAN')`。当前方法仅请求新路径并尝试单层 videos，可能找不到该旧布局。现保留已有路径优先，找不到时再尝试旧的资源库与目录组合；调用方显式库名仍被保留。以上是对固定源码和原包路径的静态核对，尚未用实际 Polymod 索引、ZIP 或故事模式运行验证，不能声称原视频已播放。

视频路径宏参数修复（2026-11-14，尚未编译）：`ValidatedPaths.video(key, ext, validate)` 原宏忽略 ext；传入 validate 时还将布尔值放到运行时 video 的扩展名参数位置。现按运行时签名转发扩展名和校验参数，省略或显式 null 时分别使用 mp4、true。单参数调用保持默认值；这属于源码签名错误修复，尚未编译或执行任何扩展名/关闭校验用例，不证明视频播放。

字体与音乐资源路径参数修复（2026-11-14，尚未编译）：同视频宏一样，`ValidatedPaths.font` 和 `music` 先前忽略扩展名/后缀，并在提供 validate 时把布尔值传到字符串参数位置；现按各自运行时签名转发全部参数。音乐路径构造器此前接受 validate 却丢弃它，现将其用于 audio/metadata 路径并在 withSuffix 复制时保留，存在性查询仍按原有方式不发缺失警告。默认调用沿用原有默认值；编译期宏、非默认扩展名、后缀及关闭校验均尚未运行验证。

动态资源参数的编译期校验（2026-11-14，尚未编译）：字体/视频扩展名或音乐后缀是运行时表达式时，宏不再假定其为 ttf、mp4 或空字符串而校验错误文件；字面值和省略参数仍进行原有静态校验，运行时参数继续传递。该调整仅据宏源码确定，尚未执行编译期或运行时验证。

FocusCamera 数值回退补充（2026-11-14，尚未编译）：在此前防止对象强转的基础上，补回整数及浮点数形式的旧式标量目标，浮点数按原有数值转整数行为处理；对象缺省 char 仍采用默认目标。当前真实旧谱面的标量样本均为整数，浮点边界未有真实模组或运行证据。

预览版显式音乐文件路径（2026-11-14，尚未编译）：固定 Origin 预览的音乐路径构造器支持传入带音频扩展名的文件，本地此前将其当作嵌套目录并重复添加扩展名。现识别与当前音频扩展名相同的显式文件，去掉扩展名并按非嵌套文件构造；带后缀的复制保留非嵌套模式。音乐宏对可静态确定的 .ogg 文件也按同样形状检查。已检查样本未发现真实 HXC 使用带扩展名的该新接口；不同平台大小写、实际资源解析及宏展开尚未验证。

视频资源索引链补充核对（2026-11-14）：所选 Polymod 的资源库将 mp4 标记为 VIDEO；`LegacyVideoLocation` 对已索引的模组视频优先使用实际文件路径，ZIP 等没有普通文件路径的情况则取得字节交给 VLC。新旧路径匹配仍依赖实际 OpenFL/Polymod 索引，这是源码检查，尚未证明 Mindless 原包或 ZIP 实际播放。另核对 Haxe 4.3.7 的 `Path.extension`：无扩展名时返回空字符串，音乐路径构造器的扩展名检查不会因这一情况解引用 null。

HTML5 视频释放与迟到回调（2026-11-14，尚未编译）：FlxVideo 现保存 NetConnection，结束与销毁共用一次性流关闭路径，移除状态和音量监听并移除显示对象；已关闭后忽略元数据、状态及音量回调，重复销毁不再重复释放。此修改只基于源码中监听器和 dispose 的生命周期，浏览器实际播放、结束、重复进入与失败路径尚未验证，也不涉及 Windows VLC 原生崩溃。

真实模组数据版本批量核对（2026-11-14）：隔离目录的非诊断样本中，52 份角色数据声明 1.0.0/1.0.1，25 份舞台数据为 1.0.0；Alien Hominid 三个版本的音符样式为 1.1.1、谱面为 2.0.1，这些均落在本地注册表相应的 1.0.x、>=1.0.0 <1.2.0 和 2.0.x 接受范围内。本地歌曲元数据、谱面和音乐版本声明与固定预览 08c0b800 一致。扫描中 songs 目录还含版本 1.0.0 的 atlas manifest，不能误当作歌曲数据。以上仅核对版本声明，不能证明字段、资源或运行兼容。

0.9 HScript 原生样式倒计时路径补充（2026-11-14，尚未编译）：此前原生 NoteStyle 子类的 `buildCountdownSpritePath` 没有 raw 参数，预览路径适配可能忽略其自定义返回值。现调用该旧虚方法一次；若返回值与样式数据的旧式去库名结果一致，则使用数据中的完整路径保留库名，否则转换子类实际返回值。直接调用与回退到原生父样式共用此处理，旧版字符串 API 未改。旧接口本身不携带被剥离的库名，子类若返回相同相对路径但意图不同库，无法从该值唯一推断；本修改尚无完整宏编译、HScript、原生目标或真实模组验证，不能宣称此类路径全部兼容。


集中验收顺序（2026-11-14，待执行）：按用户要求，在这一批代码完成前不启动编译，CPPIA 暂缓。之后只启动一次单线程普通 Windows 构建；保留现有可执行文件和用户未提交工作，内存监控在可用物理内存低于 200 MiB 时终止本次进程树。构建成功后使用隔离存档与可见窗口集中抽样：Yippie 0.3.2 覆盖早期脚本及歌曲进入；Alien Hominid 0.5 的 Eradication 覆盖旧谱面、音符尺寸和实际游玩；Devil’s 0.4.1/0.5.1 或 Azzy 0.5.3 覆盖整数 FocusCamera；Pico Chill 0.5.1/0.5.3 覆盖 ScrollSpeed；Mindless 覆盖歌曲脚本与可取得的旧视频路径；0.9 的 HScript 音符样式/路径仅在样本及依赖可用时检查。优先复用同一构建和隔离环境，不因模组切换重新编译，记录模组版本、实际观察、错误和退出状态。将加载、短时游玩、完整歌曲、视觉结果与未验证项目分别记录；单个样本不能代表所有版本或模组。CPPIA 模组及其混合加载崩溃、本次不具备条件的手机功能和标题视频堆损坏根因继续列为未验证或未解决，不因普通构建通过而宣称解决。


旧谱面空项的编辑器消费路径（2026-11-14，尚未编译）：此前读取和克隆保留空音符、空事件，编辑器的事件绘制、预览、排序、范围查询、批量选择、时间线选择及重叠检测却仍可能解引用空值。现使这些路径跳过不可操作的空项，排序将空项置后；裁剪保留空项，避免进入编辑器时因时长更新静默删除它们。音符粘贴的重叠判定也跳过空项并保留原列表。只审查了这些明确入口，其他编辑器插件和调用路径仍未验证；已检查的真实模组未证明含此类空项，不把容错修改记为模组运行通过。


异步歌曲事件与角色加载计数修复（2026-11-14，尚未编译）：SongEventRegistry 先前以事件缓存唯一 ID 数加错误数判断任务完成，而脚本可覆盖内置或另一脚本 ID；内置事件报错数又被带入下一阶段，可能提前完成或一直等待。CharacterRegistry 的脚本分阶段加载也以唯一角色 ID 数判断任务完成，多个脚本返回同一 ID 时会等待已完成的任务；没有角色数据时也未启动下一阶段。现两者按每阶段完成／失败回调数推进，保留原有缓存覆盖与最终结果统计，并让空角色数据阶段继续。TaskHandler 的线程池完成／错误回调按源码在调用侧派发；两模组竞争同一 ID 的最终优先级仍由已有加载顺序决定，本改动不宣称顺序确定。静态扫描隔离样本发现 Alien Hominid 多版本声明相同 AddCamZoom 等事件 ID，也有多个包声明相同角色 ID，但未证明这些类同时启用时会以不同脚本类同时进入注册器。上述缺陷由源码控制流识别，尚未编译或运行重复 ID、失败、空列表及真实多模组回归。


通用注册器及音符种类异步计数补充（2026-11-14，尚未编译）：进一步检查发现 BaseRegistry 和 NoteKindManager 也用唯一缓存项数量判断加载完成，多个脚本注册同一 ID 时可能等待永不增长的数量；NoteKindManager 的内置失败还可能污染脚本阶段计数。现分别按实际任务回调计数，仍保留缓存覆盖行为及最终条目／错误数量。BaseRegistry、CharacterRegistry 的前置列表扫描失败现将错误传给返回的 Future；启动和热重载路径使用 allSettled 汇总这些 Future。此结果来自源码控制流检查与调用链核对，未执行重复 ID、扫描失败、空阶段或热重载验证；不同模组覆盖同一 ID 时的胜出顺序没有由此固定。


异步注册失败收尾（2026-11-14，尚未编译）：通用注册器在主线程写入脚本或普通条目时若抛出异常，现计入该任务失败并继续推进，避免成功回调中途异常使加载一直等待。核对项目 Lime 的 `Promises.allSettled` 实现后，启动和热重载现在遍历返回的各个 Future 并记录失败原因；既有继续加载行为不变。普通条目解析失败仍由注册器逐条记录，枚举阶段失败由返回的 Future 标记。以上为源码修改及调用链核对，尚未执行注册失败、空 ID 或真实热重载验证。


歌曲暂停前事件游标保护（2026-11-14，尚未编译）：PlayState 同一帧可能先打开暂停或死亡子状态，之后仍进入 `processSongEvents`；当前查询会推进事件游标，但处理器因 `shouldSubstatePause` 而不运行，造成当帧到期事件丢失。现在已进入暂停子状态时在查询前返回，恢复后再处理。此修改只覆盖调用开始前已经暂停的情形；事件脚本在事件批次执行过程中打开子状态时的剩余事件处理仍待核实。隔离样本 Mindless 包含 onSongEvent 脚本，但尚未证明它触发了该暂停情形；本项仅为源码控制流修复，未做运行验收。


事件批次中途暂停补充（2026-11-14，尚未编译）：脚本或事件处理器在派发批次中途打开暂停子状态时，先保存已派发但尚未处理的当前事件，恢复后只调用其处理器；对批次剩余未派发事件回退查询游标，恢复后按原顺序继续。脚本取消当前事件时不安排其处理器。重新生成谱面或主动跳转时清除待处理事件；派发期间替换整个事件数组时退出旧批次。仍需统一运行验证：脚本打开暂停、处理器打开暂停、取消、同时间多事件、重载及跳转；在位修改同一事件数组和模组自定义状态切换尚未证明安全。

集中普通构建及启动回归（2026-11-14）：按要求完成本批代码后，单线程执行一次 `haxelib run lime build windows`；构建退出 0，最低可用物理内存 296852 KiB，仍有 Lime `Failed to update resources` 提示。新程序 SHA-256 为 E95B3432754E3C1C5888A444E58302955B0D627C8E8E51C621548374A4990783；此前 bin/obj 可执行文件备份在 `_build/origin-batch-acceptance-960/`。隔离存档和可见窗口脚本先后尝试 Yippie 0.3.2 和 Alien Hominid 0.5，各等待约 120 秒仍未创建窗口且标准输出/错误为空；停止后续重复样本。随后无模组 `--origin-test=main` 复现启动卡住，约 31 秒 CPU、单线程、无窗口，日志为空。上述属于启动回归，根因尚未确定；不能据此判断模组兼容性，亦不能把构建成功视为验收通过。CPPIA 未作为本批目标；历史 953 旧候选 Alien 短测证据仅适用于当时的旧二进制，不适用于新构建。

启动诊断补充：对新程序进行只读线程采样，部分运行停在 `win32u.dll` 且出现标题为 Error 的原生对话框，正文尚未捕获；另一些运行在 hxcpp `ArrayBase::Realloc` 容量翻倍循环内，采样到请求元素数为 1，但通过虚表读取的元素大小异常。对该次采样中调用目标的反汇编显示该虚函数返回对象指针而非合理元素大小，表明存在虚表或二进制接口不一致的迹象；尚未确定不一致的来源，不能认定是模组或某次代码修改导致，也未修复。采样期间仅终止本次测试进程。

普通构建混合 ABI 的定位与可见抽样（2026-11-14）：从 960 卡住进程的数组扩容现场取样，`ArrayBase::Realloc` 按虚表偏移 0x110 请求元素大小，但实际数组虚表的 0x110 指向返回 this 的方法，正常大小 16 的方法位于 0x120；两槽差与 hxcpp `HXCPP_SCRIPTABLE` 额外两个虚方法一致。检查当前链接响应文件中的对象，发现 8 个先前脚本模式的 hxcpp regexp/std/ssl/zlib 对象仍被复用，其中 File、Sys、SSL 还包含 String 数组虚表；当前生成的普通模式 EventPhase 对象的虚表布局与之不同。将 8 个对象移至 `_build/origin-abi-repair-961/objects-before` 并记录哈希，只重新生成这 8 个对象；扫描 7130 个当前链接对象，未再发现旧模式 `__GetScriptVTable@Object@hx@@` 符号。该扫描不证明所有可能 ABI 不一致都不存在。普通 Lime 增量构建的微软链接器触发 200 MiB 内存保护并被终止（最低采样 133228 KiB）；之后以已有对象和单线程 lld 独立链接成功，最低可用 2874964 KiB（`link-result.json`），这不是一次成功完成的完整 Lime 构建。可见窗口隔离抽样证实新候选能创建窗口并运行，候选、普通 bin 和 obj 程序哈希均为 9C1993923F80ED22FF0ECFF207C275244669041A8A2CBB2F74C795704564E85F；先前二进制和中断文件均已保留。切换脚本模式后应核对 hxcpp 原生对象 ABI，不能仅凭 Haxe 对象重新生成认定原生缓存已更新。

同一候选的集中可见短测：Yippie 0.3.2、Alien Hominid 0.5、Devil’s Swing 0.4.1、Pico Chill 0.5.3 和 Mindless 0.8.5 均到达相应歌曲的伴奏播放标记，观察数秒后退出 0；其中 Alien 和 Mindless 未检出本次扫描定义内的错误。Yippie 数据指定缺失的 item 样式、Devil’s 指定缺失的 default 样式，均记录查找错误并回退默认样式；是否符合各模组的预期视觉效果未核验。Pico Chill 的 ChillyTrainErectStage 预热报告未声明的 cutsceneMusic；该字段在原脚本及官方 0.5.3 Stage 中均未声明，属于模组内容问题的证据，但未覆盖所有可能的注入机制。0.9 Accurate 样本只确认带其数据的进程到主菜单，不能算真实 0.9 脚本验收；单独的合成 CharSelect 探针报告 PASS，但日志还有三个资源路径不存在的错误，不能算无错误的完整兼容通过。所有测试使用隔离存档，前后用户存档、chain.json 和 Project.xml 哈希一致，详细结果及逐项日志在 `_build/origin-abi-repair-961/runtime-results.json`。这些是短时进入歌曲／菜单检查，未证明整曲、箭头视觉大小、结算、完整脚本分支、真实键盘或视频生命周期。

角色选择 XML 查询修正（2026-11-14，源码待编译）：961 合成探针在调用 `CharacterSelectState.queryAssets(XML)` 时，对 dipshit-blur、dipshit-backing 和 char-selector 三张普通图片无条件构造并校验 XML，产生三条不存在的资源错误。现在这三项先不报警地探测，存在历史图集 XML 时仍返回；确认与拒绝光标仍按必需 Sparrow 图集路径处理。双工作区采用同一小范围修改；目前尚未重新编译或用该探针复验，961 的 PASS 与日志仅适用于修正前二进制。

事件派发时重置时间轴保护（2026-11-14，源码待编译）：`processSongEvents` 预先取出一批到期事件；脚本或事件处理器在回调中调用注册表重置／跳转时，即使仍使用同一个数组，旧批次也不再有效，原先的数组身份检查无法发现。`SongEventRegistry` 现为重置和跳转递增时间轴版本；派发或处理器返回后若版本变化立即停止旧批次，批量处理同样停止；处理器本身重置时间轴时不把旧事件重新标记为已激活。暂停后待执行的处理器也记录创建时的版本，恢复时若时间轴已变化则不执行旧事件。以上属于源码控制流修正，尚未重新编译或运行回归；直接在原数组中增删但不调用注册表重置的模组写法仍未覆盖。

事件重置及角色选择资源合并回归（2026-11-14）：以隔离的 HXCPP_CONFIG 选择单线程 lld，不修改全局配置，运行 `haxelib run lime build windows` 完成且退出 0；最低可用内存 1687036 KiB。Lime 普通输出 bin SHA-256 为 3486252CFDF7A7AF441AE1C93BFF1CC22B61DDEF9744E30AC012E5B998B71DCB，obj SHA-256 为 156D9966804D4CB1AB017BD94334C4296FD1D5CDA2E2274E2E38AC4BABA316FF；二者经过不同后处理，不能仅因哈希不等认定错误。先前 bin/obj 与 `_build/origin-abi-repair-961/candidate.exe` 哈希一致；962 中的两份重复副本已删除，原件和去重哈希清单予以保留。`event-fixture.log` 从正式源码提取事件查询、处理、时间轴重置和 PlayState 派发方法，配合替身事件、处理器、时钟及脚本派发，在 Haxe 解释器中覆盖暂停与恢复、派发期间跳转、处理器重置、暂停后失效、批量处理和取消分支；7 项通过，但不是游戏内真实模组回调。可见隔离窗口中，CharSelect 合成探针 PASS 且先前三条 XML 错误不再出现；Alien Hominid 0.5 的 Eradication 到达伴奏播放，短时观察后退出 0。两项均无脚本扫描定义内的错误，用户存档、Project.xml 和 chain.json 的前后哈希一致，详见 `runtime-results.json` 及逐项日志。可选旧 XML 确实存在时是否被返回、同时间事件顺序、真实模组重置时间轴及整曲玩法仍未覆盖；0.9 编译模组按用户要求暂缓。

角色选择可选图集与小节跳转（2026-11-14）：用仅存在于隔离测试目录的合成 0.9 HScript 模组提供 `char-selector.xml`，可见窗口实际调用 `CharacterSelectState.queryAssets(XML)`，确认该可选文件存在时仍返回且可访问，探针 PASS、日志错误数为零、进程退出 0；用户存档、Project.xml 和 chain.json 前后哈希相同（`_build/origin-optional-xml-963/runtime-results.json`）。这是合成资源，不代表真实模组覆盖。

另审查发现 `changeSection` 先修改音乐时间，却用尚未更新的 `Conductor.songPosition` 调整事件游标；启用 preventDeath 时后续 `regenNoteData` 还会替换事件数组并重置刚调整的游标。现先完成可能的谱面重建，再按 `Conductor.update` 相同的音乐时间、offset 与播放边界计算跳转目标，调整当前事件数组，最后更新时钟。正式方法提取到 `_build/origin-optional-xml-963/seek-fixture`，以替身音乐、时钟及注册表在 Haxe 解释器覆盖前跳带 offset、重建事件数组、清理待处理事件、停止状态后跳和无音乐分支，五项通过（`seek-fixture.log`）；这不是游戏内按键、整曲或真实模组验收。源码已同步两个工作区，尚未进行包含此修改的新 Windows 构建，962 输出仍是修改前版本。

MultiAnimate 中 Sparrow 同名帧修正（2026-11-14，Windows 待构建）：`MultiAnimateAtlasCharacter` 已加载各动画声明的 Sparrow 子图集，但原注册方式只从合并后的帧名查找，两个子图集出现相同前缀时可能选到先加入的图集。现保存 assetPath 对应 Sparrow 源，按指定源解析帧并映射到角色自己的组合帧；缺少该源或匹配不到动画时保留原有通用回退。原 MultiSparrow 的相同来源解析提取为共用 `SparrowAnimationSource`，保留已有入口及动画元数据设置。隔离对照使用两份真实 AlienBF 图集、正式角色类与 Flixel、替身路径／角色基类；只撤回 MultiAnimate 来源选择时第二个动画选错并退出 1（`_build/origin-sparrow-source-before-964/run.log`），修复后两项均选择指定图集，销毁首个角色后第二个角色仍保留来源（`_build/origin-sparrow-source-964/run-legacy.log`）。原 MultiSparrow 混合图集的指定来源、离屏绘制及提前释放回归通过（`sparrow-run.log`）。这些 Neko 检查使用了先前夹具中的 Animate 实现；切换到当前 Animate 实现时该夹具在解析真实图集的 `_symbolDictionary` 处报 `$asize`，不能用该失败判断正式 Windows 路径，也不能把旧夹具通过视为当前 GPU 或真实模组验收。源码已同步两个工作区，尚未执行包含此修正和小节跳转修正的完整 Windows 构建。

0.9 HScript 音符样式倒计时路径补充检查（2026-11-14）：此前导入优先级旧日志发生在安装修复前；实际选中的 Polymod 已含默认／包级导入标记及修复，既有 `_build/polymod-selected-integrated-822/WildcardMain.out.log` 对默认、显式、别名、通配符、包级和黑名单的合成场景报告通过，本次未覆盖或重装依赖。另以当前正式 `PreviewNoteStylePaths` 和 `OriginScriptCompatMacro`、当前选中的 Polymod 及替身 NoteStyle/资源运行扩展夹具，取消原先对 countdown 的跳过；原生子类和继承子类的直接、保存方法及脚本 super 路径通过，null 返回和异常传播检查也通过（`_build/origin-notestyle-countdown-965/null-exception.log`，日志中的黑名单及 native failure 为夹具预期）。这是 Haxe 解释器和合成类型，不代表真实模组、原生 Windows 或所有资源库语义；当旧接口返回已去库名前缀且恰与数据默认路径相同，仍无法唯一判定子类原本意图的库。

小节跳转与混合图集合并构建／可见短测（2026-11-14）：完成本批源码后，使用进程级隔离 HXCPP_CONFIG、单线程编译与 lld 链接执行 `haxelib run lime build windows`，退出 0，最低可用内存 1545412 KiB；Lime 输出 `Failed to update resources` 提示。bin 和 obj SHA-256 均为 102BE2B63B96800C00808063F100217A714E3D953FB2FA78A4BAF2CD95B54046，原文件备份在 `_build/origin-batch-966/`。首次混合图集覆盖层直接把原有脚本类 AlienBF 从 MultiSparrow 改成 MultiAnimate，触发角色脚本要求的 renderType 不匹配；这是夹具配置错误，测试中止，不算引擎回归（`mixed-sparrow-source.stdout.log`）。改用隔离新角色 ID、仅在测试覆盖层中让 Eradication 指向新角色后，真实 Windows 可见窗口加载 BF Animate 主图集及真实 AlienBF Sparrow 图集和其复制副本；HScript 探针观察两个同名前缀动画分别对应 AlienBF.png 和 AlienBFAlt.png，报告 `SPARROW_SOURCE_PROBE PASS`，进程退出 0，日志中无本次扫描定义内的错误（`_build/origin-mixed-real-967/runtime-results.json`）。标记在歌曲开始前出现，因此不作为整曲或真实第三方混合模组通过。单独使用未修改的 Alien Hominid 0.5 原模组启动 Eradication，进入伴奏播放并短时运行、退出 0，无本次扫描定义内错误（`_build/origin-stock-alien-968/runtime-results.json`）。两次核对用户存档、Project.xml、chain.json 的前后哈希一致；未确认箭头视觉尺寸、整曲及所有释放时序。小节跳转修正进入本次构建，但仍仅有先前提取方法的替身测试，没有游戏内跳转证据。


0.9 HScript 倒计时路径黑名单补充（2026-11-14）：当前选中 Polymod 和正式兼容宏的合成夹具对原生子类与 NoteStyle 基类分别设置 `buildCountdownSpritePath` 黑名单；直接调用及保存方法调用均被阻止，原生方法调用计数保持 0（`_build/origin-notestyle-countdown-965/blacklist.log`，其中黑名单错误为预期）。这是 Haxe 解释器替身场景，不证明所有脚本 super 或原生 Windows 模组行为。

本次备份去重（2026-11-14）：按 SHA-256 验证，962 的 bin-before.exe 与 obj-before.exe 均和保留的 `_build/origin-abi-repair-961/candidate.exe` 完全相同；仅删除这两个重复生成文件，腾出 267147264 字节，去重清单为 `_build/origin-final-batch-962/duplicate-backups-manifest.json`。其他旧程序、模组和验收日志均保留。

旧样式同 ID 的长按音符回收修正（2026-11-14，Windows 待构建）：官方 0.8.5 的 `SustainTrail.setupHoldNoteGraphic` 每次调用均重新读取样式路径、像素标记、缩放和偏移；当前按样式 ID 跳过整段处理，同一 ID 的样式在脚本或数据重建中变化时可能继续使用旧图与旧尺寸。已保留相同资源的图形复用：只有样式对象、路径、图形身份变化或图形已销毁时重新加载；每次调用均重新读取像素设置、缩放、旧版宽度系数和偏移，destroy 清除新增引用。提取正式方法、使用替身图形与样式的解释器夹具中，修改前同 ID 路径／缩放变化仍返回旧值（`_build/origin-hold-refresh-969/before.log`）；修改后覆盖同对象变化、同路径属性变化、相同 ID 的新对象、外部替换图形、图形销毁及不变时缓存复用，7 项通过（`after.log`）。这不证明真实模组发生过该模式，也未覆盖同路径底层缓存热替换、真实图像和完整游戏；修改尚未进入 Windows 构建。

音符与溅射图集路径变化修正（2026-11-14，Windows 待构建）：`NoteStyle.buildNoteFrames` 和 `buildSplashFrames` 过去仅在已持有图集销毁或强制刷新时重新加载；同一样式把路径或资源库切换到另一张已缓存图时仍会返回旧图集。现分别记录实际路径和库名，任一变化时丢弃自身旧引用并重新获取，不直接销毁共享图集；路径与库名未变时继续复用，强制刷新和已销毁检查保留。提取正式方法与替身图集的解释器对照先复现路径变更后仍返回旧图（`_build/origin-note-frame-path-970/before.log`），修复后覆盖两类图集的初次加载、缓存复用、路径变化、同路径不同库、强制刷新、图集已销毁和缺失路径（`after.log`）。这是合成样式与资源替身，未证明真实模组曾触发、同路径底层资源替换或 GPU 画面；与 969 的长按复用修正均待统一 Windows 构建和真实资源回归。

长按特效图集及缺省动画修正（2026-11-14，Windows 待构建）：每次从当前方向资源重新组合图集，避免单方向路径更改后继续返回旧图，或强制刷新时混入旧帧；旧集合不主动销毁，保留已显示精灵的引用。动画注册根据名称设置持续动画循环，避免缺失开始／持续／结束动画时访问不存在的数组项或错误地让结束动画循环。正式方法提取后的替身测试分别覆盖资源替换、强制刷新、方向增删及引用保留（`_build/origin-hold-cover-refresh-971/`），以及完整、缺少开始、缺少持续、空和 null 动画（`_build/origin-hold-cover-animations-972/`）；均通过。这些是合成替身测试，不证明真实模组或 Windows 图形运行，尚未进行本批完整编译。

长按特效缺失方向的父样式回退（2026-11-14，Windows 待构建）：子样式没有某方向的数据时，动画数据原本可回退父样式，但方向图集直接返回空。现相应地从父样式查找该方向的图集，子样式已有方向仍优先使用自己的数据。提取正式分支并以替身数据运行的 Haxe 夹具覆盖多层继承、本地覆盖与找不到方向（`_build/origin-hold-cover-parent-973/`）；未验证真实资源、继承样式或 Windows 运行。

Origin 上游核对与定向移植（2026-11-14，Windows 待构建）：只读获取官方 main `94ee0f2a9386d80e445be39ee2ed4b4a630cfbac`，相比已记录的 `86cb949c` 只有移动编译文档措辞变更；公开预览 `8e938d1c528f35c2507a32210457453161177179` 相比之前审查的 `08c0b800` 前进四次提交。`1414435c` 角色 Animate 图集动态枚举由本地 CharacterRegistry 的 animateAtlas.image/json 查询实现；移植 `8e938d1c` 的 difficulty-selector 图片和 XML 声明，并针对本地编辑器适配 `895f1626`：销毁事件工具箱时取消预览定时器，回调检查控件销毁状态。本地 HaxeUI 源码确认 dispose 会设置 _isDisposed 并调用 onDestroy；上述修改尚未编译和可见运行。`4666b8ed` 更改外置 assets 子模块，由 dbfb530be1a64d7ea90ce74e9c324f95e09aa694 前进至 e882b5b92aad99ae39178363499dc325216a2074；未覆盖用户外置资源，具体资源行为未验收。

标题视频回调修补状态复核（2026-11-14）：执行 `tools/setup-hxcpp-callback-handoff.ps1 -VerifyOnly`，当前 D 工作区选择的 hxcpp `Immix.cpp` SHA-256 为 `FBBF094A4117E82CFA9E0F15CB8063F56045E8975A4F6870B50BF78988CD77FE`，匹配已记录的线程交接修补版本。该校验只证明源码处于预期状态，不证明本批二进制已重新编译，也不能证明历史崩溃的唯一根因。尝试只读获取最新外置 assets 子模块版本以核对资源差异时 GitHub 连接失败；未改动用户资源。

普通音符相同 ID 的不同样式对象（2026-11-14，Windows 待构建）：音符池按 ID 和图集复用动画；当不同 NoteStyle 对象共享 ID 与图集但动画定义不同，原判断会跳过动画重建。现在额外比较样式对象身份，销毁音符时清除引用；对象与图集不变时继续复用。提取正式方法的 Haxe 替身检查覆盖相同样式复用、同 ID 新对象和图集变化（`_build/origin-note-style-identity-974/`）；未验证同一对象原位修改动画数据、真实模组或 Windows 游戏画面。

真实模组接口候选批量声明复核（2026-11-14）：对旧的 33 个词法交集候选中尚无声明说明的 28 项，核对当前声明、继承与宏生成并记录在 `_build/origin-real-api-batch-975/declaration-review.json`。例如 Stage/Song 的 id 来自 IRegistryEntry 宏，SongRegistry.instance 来自 ISingleton 宏，MultiSparrow 的 playAnimation 由 BaseCharacter 继承；相机字段类型改为 FlxCamera 子类，Paths 的两个旧调用入口保留原参数并增加默认参数。其余包括可空标注、初始值和 Int 到 Float 的变化，不能仅据声明差异认定故障。原清单是脚本文本共现，不证明每个候选都由相应接收者调用；这轮也不证明方法运行行为或真实模组完整兼容。

异步事件、角色与音符类型登记异常收尾（2026-11-14，Windows 待构建）：三类注册器的成功回调在写入缓存或读取脚本 ID 时抛异常，会跳过任务完成计数并可能使加载一直等待。现在将登记失败送入各自已有错误路径并继续推进，成功与 ID 覆盖路径保持不变。提取六个正式回调，使用拒绝空 ID 的替身映射检查各注册器的普通／脚本登记失败及其他成功任务，完成计数和失败计数均符合预期（`_build/origin-registry-callbacks-976/`）；这不证明真实 Polymod、线程池或游戏热重载运行通过，尚待统一编译。

异步脚本枚举失败的 Future 传播（2026-11-14，Windows 待构建）：歌曲事件在内置事件回调后枚举脚本类，异常此前可能使其 Future 永不完成；音符类型的枚举异常则可能直接从创建 Future 的调用抛出，绕过启动／热重载 allSettled。现将两处异常写入对应 Promise 并结束该注册器的加载流程。提取正式异常分支、使用 Promise 和脚本列表替身，检查正常枚举与异常均通过（`_build/origin-registry-enumeration-977/`）；首次夹具提取漏掉 catch，导致预期异常未被捕获，修正夹具后才得到通过结果。该检查不等同真实线程池、完整启动或热重载。

同步音符类型与异步模块失败路径（2026-11-14，Windows 待构建）：项目内置的两个 NoteKind 子类是无参构造，而同步注册此前向 Type.createInstance 传入一个参数；现与异步路径一致使用空参数。非多线程分支使用普通 Map 及对应的键／值迭代，不引用只在多线程导入的 SynchronizedMap。提取正式注册和列表方法的 Haxe 解释器夹具覆盖无参构造、列表与遍历（`_build/origin-registry-sync-978/`）；对照中多传参数会抛异常。模块异步入口现把脚本枚举及最后排序的异常写入 Future，避免绕过调用方的 allSettled 或让其一直等待；这两处依据控制流审查，尚未运行真实模块错误、非多线程完整构建或热重载。

同步注册单项异常隔离（2026-11-14，Windows 待构建）：模块、歌曲事件、基础角色脚本、通用注册器脚本条目及内置音符类型的同步加载现逐项捕获构造／登记异常，记录错误并继续处理后续条目；正常加载顺序与覆盖规则不变。提取正式歌曲事件同步方法，以失败和成功的内置／脚本类交错检查后续项仍登记（`_build/origin-sync-registry-errors-979/`）；提取正式音符类型方法检查失败内置类之后正常类仍登记（`_build/origin-registry-sync-978/`）。其他注册器仅做源码检查；所有夹具使用替身，不代表真实模组或完整构建已通过。

共享 SDL2 热重载逐注册器继续（2026-11-14，Windows 待构建）：实际 `OriginRegistryLoader.load` 使用主线程串行任务，先前任一步失败即结束，导致后续注册器及模块没有加载；调用方虽然继续关闭重载状态，但可能留下未加载内容。现在每一步仍经原有主线程 defer 顺序运行，失败会记录并继续，全部步骤结束后将聚合错误交给既有热重载错误处理。提取正式调度方法、以同步 Future 与动作替身测试错误后继续、末尾报错、全成功和空列表（`_build/origin-serial-registry-errors-980/`）；开发时发现 Haxe 不允许局部函数前向引用并在落地前改为显式闭包。尚未执行真实定时器、Polymod 热重载或 Windows 构建；失败的注册器仍可能数据不完整，不应视为成功。

NF PlayState 滤镜数组刷新补充（2026-11-14，Windows 待构建）：FlxGame 在更新末尾将 _filters 应用于显示对象，摄像机 flashSprite 是其子对象；源码链路支持游戏级滤镜的设计，但不能代替像素验收。PlayState 的另一套 addShaderToObject/removeShaderFromCamera 此前在原数组上增删，PsychCamera 按数组引用跳过重复赋值时可能看不到更新；首次添加也提前返回，未同步着色器设置。现对游戏和摄像机的既有数组复制后再增删提交，首次添加同样更新开关。提取正式添加语句并使用替身验证首次添加、保留旧滤镜、新数组引用和开关（`_build/nf-playstate-filters-981/`）；删除分支只做源码检查，尚未执行真实 GPU 或画面验证，不能据此断言用户所见问题已完全解决。

构建备份去重（2026-11-14）：复核每对文件的 SHA-256 和 `_build` 内绝对路径，仅删除 9 个名含 before 的重复生成 EXE，释放 1,592,859,136 字节；每项保留与之字节相同的隔离测试可执行文件，原路径、保留路径、哈希和大小记录在 `_build/origin-dedup-result-982.json`。未删除模组、存档、源码或日志；旧日志若引用被删除的备份路径，可通过清单找到内容相同的保留文件。

多 Animate 角色主图集延迟符号查询（2026-11-14，Windows 待构建）：`BorrowedAnimateFrames` 为避免污染共享缓存而使用独立集合，但关闭了自身的内联符号表和目录列表；主图集尚未物化的 symbol 因此可能无法由该集合找到。现先检查主图集的已加载符号及其内联／目录清单，并由原图集负责延迟创建；未匹配时保留组合集合的原回退。这样共享字典中新建的时间轴仍属于原图集，临时集合销毁时清除对原图集的引用。提取正式查询方法、使用替身测试内联、目录、子集合回退和缺失符号（`_build/origin-borrowed-symbol-984/`）；真实 Animate 数据、GPU 和共享销毁时序尚待统一 Windows 构建回归。

组合 Animate 子图集延迟符号补充（2026-11-14，Windows 待构建）：检查实际 FlxAnimateFrames.getSymbol 后发现，组合集合的默认回退只查询子图集已经实例化的字典，不查其尚未加载的内联或目录符号。现先按主图集、再按子图集顺序检查各自符号清单，并由对应源图集实例化符号，未命中仍走原回退。扩展 `_build/origin-borrowed-symbol-984/` 的正式方法提取夹具，覆盖延迟子符号、主图集同名优先、目录符号及回退；夹具首次因替身字段访问权限配置错误未编译，修正后通过。该结果不证明实际 Animate 源数据或 GPU 运行；相关所有权与生命周期仍待统一验证。

Animate 延迟符号解析数据生命周期（2026-11-14，Windows 待构建）：复核发现 `_fromAnimateInput` 在初始解析结束时清空符号字典源数据、目录列表和设置，因此后续延迟符号查询无法找到未用过的符号，且新建内容取不到原设置。现保留这些数据到图集 destroy，并为空目录列表使用空数组；JSON 解析产生的是 Array，符号表类型相应改为 Array，避免现有 Neko 图集夹具中 Vector/JSON 数组不匹配的 `$asize` 路径。提取正式 AnimationJson getter 的解释器检查覆盖新旧两种 JSON 结构（`_build/origin-animation-json-985/`）；先前 `_build/origin-sparrow-source-964/run.log` 是修正前的 Neko 失败证据，本次尚未重跑真实图集或构建 Windows。保留原始符号数据会增加图集存活期间的内存占用；释放时清除引用，实际内存影响未测。

Animate 延迟符号存在性一致性（2026-11-14，Windows 待构建）：`existsSymbol` 原先只检查已实例化字典，导致尚未加载的合法符号被舞台编辑器误判为帧标签；直接扩大该方法又会让 getSymbol 的原有快捷分支返回空。现在 getSymbol 仅对已实例化字典快捷返回，存在性查询检查当前及直接组合图集的内联／目录清单而不触发加载，子图集符号由其源集合创建；独立借用集合也使用同一原则。提取正式存在性与查询方法的替身夹具验证查询不提前实例化、主／子图集延迟创建及所有者（`_build/origin-symbol-exists-986/`）；未验证真实编辑器、复杂嵌套图集或 GPU 画面。

集中构建及可见窗口短测（2026-11-14）：本批修改后单线程 `haxelib run lime build windows` 退出 0，最低可用物理内存 482052 KiB，日志提示 `Failed to update resources`（`_build/origin-final-987/result.json` 及构建日志）；EXE SHA-256 `CD2108D9D0103E7EDA892F6D850FD39E0660801DB4F49562851CA8FD55AD8C95`。使用隔离存档与可见窗口，Yippie 0.3.2 与 Mindless 0.8.5 到歌曲播放标记并短时运行、退出 0；Mindless 无本次扫描定义内错误，Yippie 报告其未提供的 item 音符样式后回退。Alien Hominid 0.5 首次启动停在外置资源挂载之后并超时，原因未明（`_build/origin-final-987/runtime-results.json`）；随后同一二进制的独立重试进入 Eradication 并短时运行、退出 0，无扫描定义内错误（`_build/origin-final-988/runtime-results.json`）。两次用户存档、Project.xml 与 chain.json 前后哈希一致。这些是短时加载检查，未验整曲、箭头尺寸、真实热重载、Animate 所有符号路径或其他模组；首次超时仍未解释，CPPIA 按要求暂缓。

0.9 HScript 真实样式子集短测（2026-11-14）：使用构建 987 的同一 EXE 和可见隔离窗口，加载 Hex V3 原始两套 HScript 音符样式及资源子集，由合成探针创建 NoteSprite；hex_mines 为 28 帧／紫色动画 7 帧，hex_mine_reg 为 14 帧／动画 14 帧，缩放均为 0.7，进程退出 0，用户存档、Project.xml 和 chain.json 哈希不变（`_build/origin-hex-hscript-990/results.json`）。为遵循暂缓 CPPIA，在隔离副本中移除 Hex 元数据的 mod-engine 依赖；原包和用户模组未改。首次 989 使用目录名而非模组 ID，样本未加载，不算通过。此次只验证两种样式的构造和动画数据，不代表完整 Hex、谱面、画面或所有 0.9 模组兼容。

当前构建的混合图集窗口短测（2026-11-14）：构建 987 在可见隔离窗口加载 Alien Hominid 0.5 与合成覆盖层，探针确认两个同名前缀 Sparrow 动画分别来自 AlienBF 和 AlienBFAlt，标记 PASS、退出 0，日志无本次扫描定义内错误；用户存档、Project.xml 与 chain.json 哈希不变（`_build/origin-mixed-final-991/runtime-results.json`）。该标记在歌曲开始前，覆盖来源选择而非延迟符号、完整角色画面或整曲；二进制与构建 987 的 SHA-256 一致。
