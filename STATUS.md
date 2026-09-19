# KeySkin 0.1.2 状态

- 已实际编写 UIKBKeyView layoutSubviews 实验 hook，不再是仅计数探针。
- 默认 Enabled 缺失/false/类型错误不安装 hook；读取 NormalImageData / FunctionImageData，缺资源不画。ProbeEnabled 为旧版保留字段，不再参与启用判断。
- 验证 UIKitCore 类来源、UIView 继承、无参数 void 实例方法签名；先调用原方法，仅处理精确 UIKBKeyView 和有界有限 bounds。
- 自有 UIImageView、关联对象、自有 tag、不响应触摸/辅助功能，放在所有现有子视图下面，仅自己的 layer 做 bounds 内圆角裁切；没有输入监听、整屏遮罩或整键盘贴图。
- 功能键仅宽高比启发式（>=1.35），不读取文本；无法可靠覆盖所有键盘结构。未知子类/异常几何/资源缺失均保留系统外观。
- 未真机验收：系统自绘文本与图片层关系、原生背景遮挡、远程键盘注入、RootHide 安装均需验证。不声称真实设备换肤成功。
- 本次静态测试/本地构建结果将在执行后追加；旧 evidence 仅表示历史版本。
