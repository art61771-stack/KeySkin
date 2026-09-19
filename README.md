# KeySkin 0.1.0

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
配置域 com.zuotian.keyskin，参考 config.example.plist。用设备上的偏好工具为目标进程所属用户设置 Enabled 和 ProbeEnabled 两个布尔值，再重新启动目标宿主。此项目不安装配置以免覆盖原配置；无设置面板、无 postinst/维护脚本、无自动重启。
关闭两个开关并重启相关宿主即可不再安装 hook；卸载后重启宿主完成回退。正在运行的进程不会动态卸钩；只在进程启动时读配置。需要能访问设备安全模式/包管理器进行恢复。不要在主力设备上未经验证直接启用。

## 构建
Theos 工程：`make package THEOS=/path/to/roothide-theos FINALPACKAGE=1`。需要 RootHide Theos 对 roothide scheme 的支持及 iOS SDK/arm64e Apple 工具链；普通 Theos 不保证支持该 scheme。
CI 使用 macos-14 的 Apple iPhoneOS SDK，直接编译同一 Tweak.xm（纯 Objective-C++ runtime hook，无 Logos 语法），签名并打包；没有伪造二进制。`bash build.sh`。CI 原型包布局参考已有 RootHide 探针：iphoneos-arm64e、根相对 Library/MobileSubstrate/DynamicLibraries、.jbroot install_name。这不是目标设备的安装兼容性保证。
本地模型测试：`clang++ -std=c++17 -Wall -Wextra -Werror tests/geometry.cpp -o /tmp/keyskin-test && /tmp/keyskin-test /tmp/keyskin.ppm`。
验证：`python3 verify.py build/KeySkin-0.1.0-roothide.deb`。

不采集输入文本、不 hook 输入回调、不访问或上传用户图片、无网络功能、无维护脚本。CI 上传的都是源码/合成测试图/构建输出。精确构建和仓库可见性结果以 STATUS.md 和 evidence 为准。
