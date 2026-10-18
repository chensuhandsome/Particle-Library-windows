<p align="center">
  <img src="docs/assets/quark-idle.gif" alt="Particle Library Quark" width="150">
</p>

# Particle Library

[English](README.md) | **简体中文**

Particle Library 是一个离线 PDG（Particle Data Group）粒子数据浏览器，面向高能物理及相关领域的科研使用。PDG 数据快照保持只读且保存在本机，笔记、收藏、标签和 PDF 批注与数据分开存储。

这是一个用 **DeepSeek Harness** 与 **DeepSeek-V4.1-Flash-1017** 在周末构建的项目。

应用使用 Flutter，当前目标平台为 **macOS（Apple Silicon）** 与 **iPhone/iPad**，两端共享响应式布局。

## 功能

- **离线 PDG 数据**：只读 SQLite 快照，SHA-256 完整性校验、首次启动安装、schema 校验和原始字段查看。
- **搜索与导航**：粒子名与别名、希腊字母/LaTeX 写法、MC 编号、PDG 标识符、专题、衰变、文献和全文搜索。
- **条目页面**：粒子、专题、衰变模式、系列/性质和文献页面，包含汇总、全部测量、误差、脚注、历史、文献和原始记录。
- **数据语义**：区分 PDG Average / PDG Fit；保留 limit、range、CL、scale factor 和 used-in-average/fit 等字段，不擅自归一化。
- **数学排版**：PDG ASCII 表达式、粒子符号、衰变方程和单位在无歧义时排版为数学；否则保留原文。
- **历史与趋势**：按版次查看汇总值和带非对称误差的趋势图。
- **笔记**：本机 Markdown 笔记，支持锚点、反向链接、Collection、标签、搜索、导入/导出和冲突保护；所有“加入笔记”入口共用同一个选择器。
- **标签**：跨笔记筛选、浏览、重命名和删除。
- **文献**：本地文献信息、可选 Crossref 题名补全、INSPIRE 搜索、BibTeX/cite key 和 Zotero 本地桥接。
- **Zotero 索引**：手动构建/更新的本地 Zotero 条目缓存，避免 INSPIRE 结果逐条请求。
- **PDG 综述**：按需缓存 PDF、选择性清理、PDF 文字高亮；高亮直接存为带 review anchor 的本地笔记，可搜索、打标签、导出，并显示在右侧批注栏。
- **桌面工作区**：可独立收起的左侧页面目录和右侧上下文栏、可拖拽分栏、移动端紧凑布局。
- **双语界面**：中文/英文界面，支持跟随系统、浅色/深色主题。

## 环境要求

- macOS 15 或更高版本（推荐 Apple Silicon）；
- Flutter **3.47.7** / Dart **3.13.5** stable；
- macOS/iOS 构建需要 Xcode **26.3** 和对应 iOS platform；
- 部分插件需要 CocoaPods。

### PDG 数据快照

PDG 数据库**不包含在仓库中**（体积大，且使用 CC BY 4.0 许可）。构建前放到：

```text
assets/pdgall-2026.0.sqlite
```

要求：

- PDG 2026，schema 0.3；
- SHA-256：
  `c82dab0c0a7c5264f23508066cabb8df9eacc1dbfc83c8d20fade6053394ba8a`；
- 应用使用前会校验哈希。

`pubspec.yaml` 的 asset 条目要求该文件在 `flutter test`、`flutter run` 或任意平台构建前存在。生产构建必须把快照打包进应用。

## 安装

目前还没有公开的二进制 Release。未来若 GitHub Releases 提供 `.dmg`/`.zip`、`.ipa`/TestFlight 等安装包，普通用户直接下载即可，不需要 Flutter、Xcode 或源码。

在此之前，macOS 可从源码构建；iOS 模拟器构建已通过冒烟测试，但真机安装仍需你自己的 Apple 签名 Team。Android、Windows 和 Linux 目前还没有平台脚手架。

## 从源码构建

构建说明与普通用户文档分开，避免把未经验证的构建说成官方安装方式：

- [构建说明（英文）](docs/development/BUILDING.md)
- [平台支持矩阵（英文）](docs/development/PLATFORMS.md)

macOS 已验证的简短流程：

```bash
# 先把 pdgall-2026.0.sqlite 放入 assets/；详见 assets/README.md。
flutter pub get
flutter test
flutter build macos --release
open "build/macos/Build/Products/Release/Particle Library.app"
```

## 测试

```bash
flutter analyze
flutter test
```

测试覆盖快照契约、显示语义、数学解析、笔记/标签、PDF 批注坐标与持久化、Zotero 缓存解析和 UI 辅助逻辑。除显式联网测试外，测试不需要网络。

## 本机数据与隐私

- PDG 快照只读并校验哈希；
- 笔记和用户设置保存在独立 SQLite 数据库；
- 收藏、最近搜索和 Zotero 索引保存在应用支持目录；
- PDG 综述 PDF 按需下载，不包含在仓库中；
- Zotero 仅通过 `http://127.0.0.1:23119` 只读访问；
- 应用不发送遥测数据。

## 仓库结构

```text
lib/            Flutter 应用
test/           单元与 widget 测试
assets/         图标/主题资源；PDG 快照需自行提供
macos/          macOS runner
ios/            iOS runner
docs/           设计与开发文档
```

## 文档

- [文档索引](docs/README.md)
- [产品设计](docs/design/PDG_App_Design.md)
- [数据图集](docs/design/PDGall_Data_Atlas.md)
- [数学转换规则](docs/design/Math_Conversion.md)
- [衰变结构设计](docs/design/Decay_Structure_Design.md)

开发文档目前以中文为主；构建/平台说明为英文，避免重复维护。

## License

- **应用代码**：Mozilla Public License 2.0（MPL-2.0），见 [LICENSE](LICENSE)。Copyright 2026 Particle Library contributors。
- **PDG 数据快照**：CC BY 4.0，需保留 Particle Data Group 署名；MPL-2.0 不覆盖数据。
- **PDG 综述 PDF**：不随仓库分发；从 PDG 下载并受 PDG 条款约束。
- **第三方依赖**：见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

本项目是独立应用，不是 PDG 官方产品。
