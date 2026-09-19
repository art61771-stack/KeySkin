# KeySkin 0.1.3 — 设置加载修复

本版仅修复设置加载与按钮绑定，Tweak.xm/KSRuntime.h 与 0.1.2 相同。入口任意名称均从本 bundle 读取 Root.plist，显式创建、绑定并发布设置项；缺资源时显示错误。新版只有 Enabled 图片实验开关，默认关闭。先生成示例、预览，再开启并重启键盘宿主。关闭后也需重启宿主。无自定义选图，无安装脚本。旧版已保存的 Enabled 值保留。

0.1.2 起运行代码尝试在真实 UIKBKeyView 内插入独立背景视图，尺寸比例仅作普通/功能键启发式分类；bounds 与固定圆角并非已证明的真实键帽轮廓，原生内容可能不在子视图中，故不能保证不遮字或覆盖所有键。设置页和键盘效果均需真机验收。当前测试包括资源/绑定静态检查、运行时方法签名守卫与 CoreGraphics 离屏测试，不等于真实 PreferenceLoader 验收。

以下为 **0.1.1 历史记录，不是本版行为**：

# KeySkin 0.1.1

**构建原型，未真机验收。不是已经完成的键盘换肤插件。**
目标：iPhone 14 Pro Max / iOS 16.6 / RootHide。标识 com.zuotian.keyskin。

## 实际功能及边界
- 默认 Enabled=false、ProbeEnabled=false，默认不安装任何 hook、不输出诊断。
- 显式双开关启动后，只查询 UIKBRenderer `renderBackgroundTraits:` 和 UIKBRenderFactory `_traitsForKey:onKeyplane:` 的方法编码，不调用、不替换，不猜测私有 ABI/所有权。
- UIKitCore 的 UIView 子类 UIKeyboardLayoutStar 若存在，核对 layoutSubviews 的 v/@/: 参数类型、参数数量、所属镜像，然后通过运行时 MSHookMessageEx 挂接原方法；保持原行为，仅累加有界内存计数，不记录键对象或输入。缺类、方法、编码或 hook API 时退出。
- **按键背景替换未启用**。BackgroundReplacementEnabled 仅作保留说明，代码不读取该开关。取得目标真机编码也不代表可以安全推断语义；后续仍需核实签名、所有权、缓存及回退。
- KSGeometry.h 是自写的有限数校验、逐键 aspect-fill 源裁剪和圆角几何；KSKeyImage.h 使用 CGRect 源裁剪、离屏 CGContext 和 CGPath 圆角遮罩，每次处理一个键的独立图片，限制尺寸及内存。它未接入系统键盘，不把整键盘图片冒充逐键。
- tests/geometry.cpp 的离屏 PPM 展示四个独立键的程序化渐变，测试空/NaN/无穷/越界/裁剪/圆角/键间间隙。该模型不等于 UIKit 真机效果验收。

## 注入范围
KeySkin.plist 的 Substrate Filter Bundles 使用 com.apple.UIKit（匹配进程中加载的 UIKit bundle，不是键盘服务 bundle ID）。用于 UIKit 宿主中的探索性探针；不同注入器是否以此匹配，以及远程键盘宿主是否加载并注入，均**未真机验证**。代码额外只接受类实际位于 UIKitCore.framework 的情况；不存在则无 hook。没有宣称覆盖所有键盘宿主。默认关闭降低全 UIKit 过滤范围风险，生产版本应在确认目标宿主后改为精确白名单。

## 配置与回退
配置域 `com.zuotian.keyskin`，参考 config.example.plist。0.1.1 新增 PreferenceLoader 入口与真正继承 PSListController 的设置 bundle：中文双开关、生成并保存两张合成 PNG、从配置回读预览、清除示例并关闭两个开关。默认均关闭。使用 CFPreferences 与探针共享配置域；只允许写两个已知布尔开关，错误配置按关闭显示。合成 PNG 为 192×192 像素，每张最多 512 KiB，保存后回读校验；预览先检查类型/长度/PNG 帧数与尺寸再解码。同步失败会提示，双图片写入不承诺事务性，失败应清除后重试。

**示例仅为设置页缓存/逐键离屏预览，不接入系统键盘；没有用户选图、真实换肤或兼容性认证。** 新增“兼容性检查并导出报告”：只列 Settings 进程类存在性、系统版本、合成图片离屏创建是否成功；通过系统分享面板由用户主动导出文字 JSON，不含图片/键对象/输入/设备标识。报告明确 targetABIProven=false，不等同目标键盘宿主验证。 不访问相册、文档或用户图片，无网络。生成示例不会自动启用探针。清除只移除两个示例键并关闭两个探针开关，不删除其他配置。安装不写入默认偏好以免覆盖旧配置；已有开启值会保留。修改开关后须手动重启目标宿主；无 postinst/维护脚本、无自动重启。
关闭两个开关并重启相关宿主即可不再安装 hook；卸载后重启宿主完成回退。正在运行的进程不会动态卸钩；只在进程启动时读配置。需要能访问设备安全模式/包管理器进行恢复。不要在主力设备上未经验证直接启用。

## 构建
Theos 工程：`make package THEOS=/path/to/roothide-theos FINALPACKAGE=1`。需要 RootHide Theos 对 roothide scheme 的支持及 iOS SDK/arm64e Apple 工具链；普通 Theos 不保证支持该 scheme。
此目标同时构建 KeySkin tweak 和 KeySkinPrefs.bundle（Preferences 私有框架），将 Root.plist / Info.plist 放入 bundle，将 layout 中入口放入 Library/PreferenceLoader/Preferences。运行设备需要 PreferenceLoader；RootHide 路径重定位由相应 Theos scheme 处理，未做目标设备安装验收。
公开 GitHub macos-14 CI 使用 `bash build.sh`：Apple clang 同时构建 arm64e 主 dylib / MH_BUNDLE 设置二进制，ad-hoc codesign，package.py 打包六个文件，verify.py 验证双 Mach-O、入口、资源、control-only。不包含路径搬运或安装脚本；RootHide 的实际安装路径处理依赖目标包管理器，未进行真机安装认证。compat/Preferences 为最小编译声明及链接 stub（只引用系统框架，不打包 stub），不依赖私有 ivar 布局。CI 原生执行 tests/coregraphics.cpp，直接测试生产 KSCreateKeyImage 的普通/功能键合成尺寸、透明圆角、中心像素、非法输入回退；不是 UIKit 键盘真机测试。
本地静态检查：`python3 tests/check_prefs.py`。SDK 语法检查：`sh tests/check_syntax.sh /var/theos`（需要完整 iOS SDK 和 Preferences 头文件，不等同链接或真机验证）。
本地模型测试：`clang++ -std=c++17 -Wall -Wextra -Werror tests/geometry.cpp -o /tmp/keyskin-test && /tmp/keyskin-test /tmp/keyskin.ppm`。

真机验收待办：安装后确认设置入口能加载；双开关初次安装默认关闭；生成→预览→退出重进仍可预览；清除后预览提示空缓存且两个开关关闭；检查保存失败提示；键盘外观必须不变化。仅在测试设备中启用双开关并重启宿主观察元数据探针，关闭后再重启验证无探针。未执行这些步骤之前不得称为真机闭环。

不采集输入文本、不 hook 输入回调、不访问或上传用户图片、无网络功能、无维护脚本。CI 上传的都是源码/合成测试图/构建输出。精确构建和仓库可见性结果以 STATUS.md 和 evidence 为准。
