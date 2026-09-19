# 0.1.1 渲染兼容性结论

结论：BLOCKED / 原生回退。没有新增真实渲染 hook，不冒充完成换肤。

核查来源（2026-09-19）：
- https://github.com/nst/iOS-Runtime-Headers/blob/master/PrivateFrameworks/UIKitCore.framework/UIKBKeyplaneView.h
- https://github.com/nst/iOS-Runtime-Headers/blob/master/PrivateFrameworks/UIKitCore.framework/UIKBKeyView.h
- 同目录 UIKBRenderer.h、UIKBRenderFactory.h

这些是历史 RuntimeBrowser headers，不是 iOS16.6 / iPhone14PM 的实现证明。UIKBKeyplaneView 声明 _keyBackgrounds/_keyBorders/_keyCaps 和缓存索引；UIKBKeyView 声明 render flags、active background、renderAsMask、cachedAnchorCorner 等。无法由 UIView.bounds 或类名推断真实单键可见轮廓，也不能证明普通/功能键映射、背景与原生文字分层、按下/弹出/候选/分裂键盘状态及缓存所有权。禁止按 bounds 加图层或替换猜测的私有返回值。

Laetus 地址核查返回 404，OledKeyboard 查询未取得可用于目标版本 ABI 的源码证据；没有把第三方名称当成兼容性证明。

实际小步：设置预览已调用 KSCreateKeyImage，而非只显示 metadata。普通44x54、功能78x54均为明确标注的合成轮廓；同一函数在 macOS CoreGraphics 原生执行像素测试，校验透明角/不透明中心及非法尺寸回退。不能将这些轮廓用于真实键盘。设置可输出兼容 JSON，始终 renderingEnabled=false / targetABIProven=false；Settings 进程类不存在不代表键盘宿主不存在。

启用真实路径前必须提供：目标系统宿主中的方法签名和调用上下文、背景独立层证据、每键实际轮廓/状态映射、所有权/缓存契约、原生文字保留验证；在离线或测试设备逐键验证后再开门。当前无目标设备调用证据，不安装，不监听输入，不上传图片。
