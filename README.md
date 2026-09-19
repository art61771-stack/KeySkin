# KeySkin 0.1.4 — 设置页稳定性修复

**本包仅修复设置页稳定性，不代表键盘换肤已修好。宿主诊断尚未实现。**
目标设备仍为 iPhone 14 Pro Max / iOS 16.6 / RootHide；未进行真机 PreferenceLoader 或键盘效果验收。

## 本版变更
生产 KSRootListController 改为 UITableViewController，固定五行：Enabled（实验性图片换肤）、生成示例、预览、导出兼容报告、清除。不再依赖 PSListController/specifier 发布或重载生命周期。各初始化入口均可创建列表，返回页面及清除后重载；复用单元格先清理 accessoryView。
Root.plist 仅保留为历史资源，不参与当前设置页数据源。旧 Enabled 和图片配置保留；默认关闭，错误类型按关闭处理。生成两张 192×192 合成 PNG 不自动开启换肤，预览使用生产逐键离屏裁剪函数。清除图片并关闭 Enabled / 旧 ProbeEnabled。

Tweak.xm、KSRuntime.h 及键盘渲染未修改。既有 UIKBKeyView 背景实验仍需真实宿主注入和运行验证；不保证覆盖键帽、不遮字或适配所有键盘。Settings 导出报告仅反映当前设置进程，不能定位键盘宿主、确认宿主注入或解释键盘无效原因；宿主诊断尚未实现。

## 测试与构建
公开 GitHub Actions macos-14 CI 从 simctl list -j 选择可用 iOS runtime/iPhone 类型，新建独立模拟器，boot/bootstatus 后执行 tests/run_prefs_uikit.sh，退出时关闭并删除设备。
测试直接编译生产 PrefsController.m，使用真实 UIKit 窗口、导航和分享控制器；仅覆盖信息提示以避免阻断测试。覆盖五行数据源及动作、严格布尔值与默认关闭、生成与开关持久化、三种初始化、三轮预览 push/pop 和真实分享 present/dismiss、清除后重载和空预览。不是自动触摸测试，不是 PreferenceLoader 加载测试，也不是键盘宿主测试。是否通过以对应 CI 日志为准。

`python3 tests/check_prefs.py` 是静态检查，不替代上述 UIKit 测试。
`bash build.sh` 在 macOS/Xcode 执行几何、生产 CoreGraphics 及运行时守卫测试，然后编译并 ad-hoc 签名 arm64e 主 dylib 与设置 MH_BUNDLE、打包并校验 0.1.4 deb。包内六个有效负载文件；control 归档仅有 control，无维护/安装/自动重启脚本。compat/Preferences 只是链接 stub，不随包分发。
Theos 构建：`make package THEOS=/path/to/roothide-theos FINALPACKAGE=1`，需要支持 roothide scheme 的工具链。RootHide 安装路径处理依赖目标包管理器，未真机认证。

## 使用与回退
安装后先检查五行可见，反复生成、预览返回、导出取消、清除并退出重进。只在可恢复测试设备开启实验开关，更改配置后手动重启目标宿主；当前运行进程不会动态卸钩。关闭后重启或卸载后重启用于回退。需保留安全模式/包管理器恢复途径。
无用户选图、GIF、动画、网络或宿主诊断；不采集输入文本，不 hook 输入回调，不访问或上传用户图片。注入过滤仍为 com.apple.UIKit，覆盖范围与远程键盘服务注入未获真机证实。
