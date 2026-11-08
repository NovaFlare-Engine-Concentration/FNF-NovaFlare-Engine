<div align="center">
  <img src="https://raw.githubusercontent.com/NovaFlare-Engine-Concentration/NovaFlare-Engine.github.io/refs/heads/main/images/logo2.png" width="380" alt="NovaFlare Icon"></img>
  <br/>
  <h1 align="center">Friday Night Funkin' - NovaFlare Engine</h1>
  <p align="center">Engine based on Psych originally used on VS Camellia fanmade and focused on optimisation and perfomance to give players best possible experience. It was later moved to support modules.</p>
  
  <div style="max-width: 500px; margin: 0 auto;">
    <p style="margin: 12px 0;">
      <a href="https://novaflare.fun" style="font-size: 1.1em; display: block;">🌐 Our Official Website 🌐</a>
    </p>
    <p style="margin: 12px 0;">
      <a href="https://novaflare.fun/docs-choose.html" style="font-size: 1.1em; display: block;">❗Our Docs❗</a>
    </p>
  </div>
</div>
<br />

# Announcement

> [!WARNING]
> The NovaFlare-1.2.2 version was withdrawn at 13:20:21 Beijing time on September 30, 2026.

> [!WARNING]
> Reason: It was overly customized, relied too much on AI modifications, was too flashy, didn't meet general user needs, and went against NF's development trend.

I really don't recommend using AI to write interfaces, and don't belittle Haxe just because you haven't mastered it yourself ----MaoPou

## Next Version

Added:  
[NF side] Added back controller support  
[NF side] Added new tea-time music  
[NF side] Added a bunch of chart converters  

[cne side] Synced to 1.1.0-rc4  

[origin side] Synced to 0.9-preview and enabled editor features  
[origin side] Theoretically supports mods from 0.3 to 0.9  

Fixed:  
[Global] Fixed an issue where mouse effects might stutter  

[NF side] Fixed an issue where videos in playstate would autoplay when the app lost focus  
[NF side] Fixed a game crash caused by the freeplay input box  
[NF side] Fixed an issue where freeplay play counts couldn't be saved  
[NF side] Fixed an issue in the editor where the delete key couldn't be used on the song name  
[NF side] Fixed a possible offset of arrow splashes in playstate  
[NF side] (Possibly) fixed an issue where misreading chart versions caused charts to be flipped  

加入的：  
[NF侧] 加回手柄支持  
[NF侧] 加入新的tea-time音乐  
[NF侧] 加入一大堆铺面转化器  

[cne侧] 同步至1.1.0-rc4  

[origin侧] 同步至0.9-preview并启用编辑器功能  
[origin侧] 理论上支持0.3至0.9的模组  

修复的：  
[全局] 修复鼠标特效可能抽搐的问题  

[NF侧] 修复应用程序失焦后playstate的视频自动播放的问题  
[NF侧] 修复freeplay输入框导致游戏崩溃的问题  
[NF侧] 修复freeplay游玩次数无法保存的问题  
[NF侧] 修复编辑器无法song name使用删除按键的问题  
[NF侧] 修复playstate箭头喷溅可能偏移的问题  
[NF侧] （可能）修复铺面版本识别错误导致铺面被反转的问题

# Introduction
The FNF-NovaFlare-Engine was originally created to be compatible with the Camellia mod, and it has continuously evolved into an independent engine, developed by Chinese developers. 

V1.0.1 is based on FNF-Psych-Engine-0.6.3.

V1.1.0-beta-1 and above are based on 0.7.3.

V1.1.8-HOTFIX is based on 0.7.3 and supports mods version 1.0.0 and above (partially).

v1.2.1: Minimum support **Psych mod 0.7.3 to 1.0.4**, **V-Slice 0.8.4**, **CodeName 1.0.1**

v1.2.1-HotFix-2: Minimum support **Psych mod 0.7.3 to 1.0.4**, **V-Slice 0.8.7**, **CodeName 1.1.0-rc3**


Highly optimize a large number of pending issues, including but not limited to frame rate improvement, loading optimization, major overhauls of the underlying system, and script system overhauls...  
Add more practical features and beautify the interface.  

~~Make your device stronger, more awesome, more invincible, more frequent, more ridiculous, more despair-inducing, and more frustratingly prone to crashes.~~

# Function
## Hscript Upgrade

Starting from NovaFlare 1.2.0, Hscript has been upgraded to Hscript--iris-improved. This update brings script syntax closer to actual source code, with support for `class` and `package`.

## Performance Improvements

- The first TPS frame count has exceeded 1000.
- Thread separation for rendering has been implemented for the first time.
- Immix GC optimization reduces lag during gameplay.

## Interface and Underlying Updates

- The freeplay option interface has been rewritten for a better visual experience.
- The underlying Haxelib has been fully upgraded, with added recording and replay features.

## Miscellaneous

- ~~All of NF's developers are Chinese (though this is not particularly relevant).~~

**You'll need to explore more features on your own.**

**[For more info, check out the release](https://github.com/NovaFlare-Engine-Concentration/FNF-NovaFlare-Engine/releases)**

# Notes!!!!
## Open Source Usage

We welcome everyone to use our open-source code, **but please make sure to give proper credit to the original source.** Our open-source code is for reference, not for plagiarism. Of course, you can copy **small amounts** of it, but please cite the original source. Copy too much, and you might even confuse players between your engine and the NF engine. Just wait, buddy, we’ll come after you.

## About the "private" Directory

The `private` directory in this repository is used for integrating NovaFlare with [GameAnalytics](https://www.gameanalytics.com) to collect usage data from our staff. It is not made public because it contains sensitive API keys, and we require real data for internal purposes.

[You can use now](https://github.com/NovaFlare-Engine-Concentration/Gameanalytics-haxe/tree/main)

## How To Use Other Engines Mods
> [!NOTE]
> [How to use?](https://github.com/NovaFlare-Engine-Concentration/FNF-NovaFlare-Engine/blob/main/NovaSetup/FunkinMods-EN.md)

> [!WARNING]
> **Not** guaranteed to support all mods, so **PLEASE** support their official channels.**They really did an amazing job!!**
> **[Friday Night Funkin](https://github.com/FunkinCrew/Funkin)**------**[Codename Engine](https://github.com/CodenameCrew/CodenameEngine)**

## CNE And V-Slice Mod Support
> [!CAUTION]
> Our support for the CNE mod has **been officially approved by the CNE development team**. For detailed information, please refer to the "Usage Info" section in the CNE repository's [README](https://github.com/CodenameCrew/CodenameEngine/blob/main/README.md) . [Click here for more information](https://github.com/NovaFlare-Engine-Concentration/FNF-NovaFlare-Engine/releases/tag/V1.2.1).
<img width="1087" height="521" alt="image" src="https://github.com/user-attachments/assets/fcc41210-ae20-4177-9ee5-92a564ec13f8" />

## Ah Man
> [!CAUTION]
> We **REALLY, REALLY, REALLY, REALLY** don’t want anyone to confuse the NF engine with these perfect engines.
> If the confusion goes beyond what we expect, **we’ll pull back the update and remove the feature that supports mods for other engines.**


# NovaFlare crew credits:
| Avatar | Username | Involvement |
| ------ | -------- | ----------- | 
| ![](https://avatars.githubusercontent.com/u/105789304?v=4) | [NF Beihu](https://youtube.com/@beihu235) | Creator and programmer for NF (NovaFlare) Engine.
| ![](https://avatars.githubusercontent.com/u/166735337?s=400&u=90192fb223fa071ae4cfcfec0853ea7593f9d13d&v=4) |[MaoPou](https://github.com/MaoPou) | Helper and programmer for NF (NovaFlare) Engine.
| ![](https://raw.githubusercontent.com/NovaFlare-Engine-Concentration/FNF-NovaFlare-Engine/refs/heads/main/assets/shared/images/credits/bigIcon/chiny.png) |[Chiny](https://space.bilibili.com/3493288327777064) | Programmer for NF (NovaFlare) Engine and Touhou player.
| ![](https://raw.githubusercontent.com/NovaFlare-Engine-Concentration/FNF-NovaFlare-Engine/refs/heads/main/assets/shared/images/credits/bigIcon/tieguo.png) |[TieGuo](https://b23.tv/7OVWzAO) | Pause menu redesigner for NF (NovaFlare) Engine.
| ![](https://raw.githubusercontent.com/NovaFlare-Engine-Concentration/FNF-NovaFlare-Engine/refs/heads/main/assets/shared/images/credits/bigIcon/Careful_Scarf_487.png) |[Careful_Scarf_487](https://b23.tv/DQ1a0jO) | Main artist for NF (NovaFlare) Engine.
| ![](https://raw.githubusercontent.com/NovaFlare-Engine-Concentration/FNF-NovaFlare-Engine/refs/heads/main/assets/shared/images/credits/bigIcon/mengqi.png) |[MengQi](https://space.bilibili.com/2130239542) | Artist for NF's pause menu.
| ![](https://raw.githubusercontent.com/NovaFlare-Engine-Concentration/FNF-NovaFlare-Engine/refs/heads/main/assets/shared/images/credits/bigIcon/AZjessica.png) |[AZjessica](https://www.youtube.com/@azjessica) | Freeplay menu artist for NF (NovaFlare) Engine.
| ![](https://raw.githubusercontent.com/NovaFlare-Engine-Concentration/FNF-NovaFlare-Engine/refs/heads/main/assets/shared/images/credits/bigIcon/beneyre.png) |[Ben Eyre](https://x.com/hngstngxng83905?t=GDKWYMRZsCMUMXYs0cmYrw&s=09) | Credits menu artist for NF (NovaFlare) Engine.
| ![](https://raw.githubusercontent.com/NovaFlare-Engine-Concentration/FNF-NovaFlare-Engine/refs/heads/main/assets/shared/images/credits/als.png) |[Als](https://b23.tv/mNNX8R8) | Init intro artist for NF (NovaFlare) Engine.
| ![](https://raw.githubusercontent.com/NovaFlare-Engine-Concentration/FNF-NovaFlare-Engine/refs/heads/main/assets/shared/images/credits/bigIcon/ddd.png) |[blockDDDdark](https://space.bilibili.com/401733211) | Engine sound effort helper for NF (NovaFlare) Engine.

# Psych Engine credits
| Avatar | Username | Involvement |
| ------ | -------- | ----------- |
| ![](https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/refs/heads/main/assets/shared/images/credits/shadowmario.png) | [Shadow Mario](https://ko-fi.com/shadowmario) | Main programmer and Head of Psych Engine
| ![](https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/refs/heads/main/assets/shared/images/credits/riveren.png) | [Riveren](https://x.com/riverennn) | Main Artist/Animator of Psych Engine
| ![](https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/refs/heads/main/assets/shared/images/credits/bb.png) | [Bb-Panzu](https://x.com/bbsub3) | Ex-programmer of Psych Engine
| ![](https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/refs/heads/main/assets/shared/images/credits/crowplexus.png) | [Crowplexus](https://twitter.com/IamMorwen) | Linux Support, HScript Iris, Input System v3, and Other PRs
| ![](https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/refs/heads/main/assets/shared/images/credits/kamizeta.png) | [Kamizeta](https://www.instagram.com/cewweey/) | Creator of Pessy, Psych Engine's mascot
| ![](https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/refs/heads/main/assets/shared/images/credits/maxneton.png) | [MaxNeton](https://bsky.app/profile/maxneton.bsky.social) | Loading Screen Easter Egg Artist/Animator
| ![](https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/refs/heads/main/assets/shared/images/credits/keoiki.png) | [Keoiki](https://x.com/Keoiki_) | Note Splash Animations and Latin Alphabet
| ![](https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/refs/heads/main/assets/shared/images/credits/sqirra.png) | [SqirraRNG](https://x.com/gedehari) | Crash Handler and Base code for Chart Editor's Waveform
| ![](https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/refs/heads/main/assets/shared/images/credits/mastereric.png) | [EliteMasterEric](https://x.com/EliteMasterEric) | Runtime Shaders support and Other PRs"
| ![](https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/refs/heads/main/assets/shared/images/credits/majigsaw.png) | [MAJigsaw](https://x.com/MAJigsaw77) | MP4 Video Loader Library (hxvlc)
| ![](https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/refs/heads/main/assets/shared/images/credits/flicky.png) | [iFlicky](https://x.com/flicky_i) | Composer of Psync and Tea Time and some sound effects
| ![](https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/refs/heads/main/assets/shared/images/credits/kade.png) | [KadeDev](https://x.com/kade0912) | Fixed some issues on Chart Editor and Other PRs
| ![](https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/refs/heads/main/assets/shared/images/credits/superpowers04.png) | [Superpowers04](https://x.com/superpowers04) | LUA JIT fork contributor
| ![](https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/refs/heads/main/assets/shared/images/credits/cheems.png) | [CheemsAndFriends](https://x.com/CheemsnFriendos) | Creator of FlxAnimate lib

# Funkin Crew credits
| Avatar | Username | Involvement |
| ------ | -------- | ----------- |
| ![](https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/refs/heads/main/assets/shared/images/credits/ninjamuffin99.png) | [NinjaMuffin99](https://x.com/ninja_muffin99) | Programmer of Friday Night Funkin'
| ![](https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/refs/heads/main/assets/shared/images/credits/phantomarcade.png) | [PhantomArcade](https://x.com/PhantomArcade3K) | Animator of Friday Night Funkin'
| ![](https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/refs/heads/main/assets/shared/images/credits/evilsk8r.png) | [Evilsk8r](https://x.com/evilsk8r) | Artist of Friday Night Funkin'
| ![](https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/refs/heads/main/assets/shared/images/credits/kawaisprite.png) | [KawaiSprite](https://x.com/kawaisprite) | Composer of Friday Night Funkin'
