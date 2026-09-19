# KeySkin 0.1.0 状态

- 初始化：开始创建独立、默认关闭的构建原型。

- 源码阶段：已创建 Makefile/control/Tweak.xm、默认关闭示例配置、逐键几何与 CGContext/CGPath 辅助、测试、README、CI。
- 本地测试：C++17 -Wall -Wextra -Werror 通过，离屏逐键测试 PASS；Python py_compile 通过。
- 本地构建：实际执行 make package，失败：本机 /opt/theos 不支持 roothide package scheme，且无 iOS SDK。保留 evidence/local-build.txt。不伪称本地 iOS 编译通过。
- CI 阶段：准备敏感扫描后创建独立仓库。私有渲染 hook 仍未启用，真机未验收。
