# KeySkin 0.1.5 — Preferences 入口兼容修复候选

目标：iPhone 14 Pro Max / iOS 16.6 / RootHide。**未完成真机 PreferenceLoader 验收，不声称闪退已修好；键盘未生效仍未解决。**

入口 `KSRootListController` 恢复真实 `PSViewController` 基类（Theos headers：`PSListController → PSViewController → UIViewController`），继承 Preferences 的初始化及 specifier/parent/root 契约，不补空 setter、不吞 unknown selector。内部使用标准 child containment 和 safe-area 布局承载独立 `KSSettingsTableController : UITableViewController` 的五行内容。避免 PSListController 私有表管理与子表数据源冲突，无 specifier 双缓存。Info 的 NSPrincipalClass 与 PreferenceLoader detail 保持匹配。预览通过外部导航栈 push/pop，分享/提示由可见子控制器呈现。

打开设置不改已有 Enabled 或图片，缺省 Enabled=false。生成不自动启用；只有主动清除会删除图片并关闭 Enabled/旧 ProbeEnabled。Root.plist 是保留资源，不驱动表格。Tweak.xm 和 KSRuntime.h 与 905808b 完全相同；未新增宿主诊断、全局 UIKit/Preferences hook 或换肤修复。

## 验证边界
- `python3 tests/check_prefs.py`：入口继承、containment、独立五行、无 specifier 缓存、资源/版本及运行代码零差异静态检查。
- `bash build.sh`：几何、macOS CoreGraphics、生产运行时守卫；arm64e dylib/MH_BUNDLE 编译签名及包结构校验。仅 control，无维护/安装/重启脚本。
- CI 只允许 **iOS16** 可用 runtime，记录实际名称/版本并检查现有 Xcode。没有则明确 `NOT RUN: iOS16 runtime unavailable`，不降级到其他 iOS，不计测试 PASS。
- 可运行时 UIKit 测试直接编译生产子控制器，用公开 UIKit containment 测五行、toggle、生成、清除、预览返回及分享取消；不是私有 Preferences 或 16.6 PreferenceLoader 实测。入口私有契约仅经真实 Theos header、链接及静态检查。

## 初次检查
保持 Enabled 关闭，仅进入设置确认五行；生成 → 预览并返回 → 导出并取消 → 清除 → 退出重进。不要为了验收入口开启键盘实验。不会自动安装或重启。

设置导出仅反映 Settings 进程，不证明键盘宿主注入或效果。无用户选图、GIF、动画、网络或输入内容采集；RootHide 安装路径与真机导航仍待验证。
