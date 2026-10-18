# 工具链与目标系统版本记录

版本：1.0　日期：2026-10-13　对应任务：T00（[开工说明](Implementation_Start.md) §4）

本文件只记录实际验证过的结果；工具链变化时更新本文件并在提交说明中注明。
"记录"不等于发布承诺：最低系统版本、签名与商店事项见总体设计 §12 的发布矩阵。

## 1. 本机环境（T00 实测）

| 项 | 值 | 验证方式 |
|---|---|---|
| 机器 / 系统 | Apple Silicon (arm64) · macOS 15.6.1 (24G90) | `flutter doctor -v` |
| Flutter | 3.47.7 stable（框架 revision abaf9c5237，2026-10-08） | `flutter --version` |
| Dart | 3.13.5 | 同上 |
| Xcode | 26.3 (17C529)，developer directory 已指向 `/Applications/Xcode.app/Contents/Developer`，first-launch 已完成 | `xcodebuild -version`、`xcodebuild -checkFirstLaunchStatus` 退出码 0 |
| Apple SDK | iphoneos26.2、iphonesimulator26.2、macosx26.2 | `xcodebuild -showsdks` |
| CocoaPods | 1.17.0（Homebrew 安装） | `pod --version` |
| locale | `LANG=en_US.UTF-8`（`~/.zshrc`；CocoaPods 需要 UTF-8） | 交互 shell 验证 |

Flutter SDK 安装方式：`flutter-io.cn` 镜像 zip 解压至 `~/development/flutter`，
`~/.zshrc` 内设置 `PUB_HOSTED_URL=https://pub.flutter-io.cn`、
`FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn` 与 PATH。
镜像只用于获取工具与包；应用数据仍以随包只读快照为准（总体设计 §8）。

## 2. 工程生成参数（不可手写平台文件）

```text
flutter create --project-name pdgapp --org com.example --platforms ios,macos .
```

- 仅启用 ios、macos 两平台；Android/Windows/Linux 文件未生成（阶段 D 再加）。
- `com.example` 为占位 org：正式 bundle id / 品牌未定（总体设计 §1、§12），
  发布准备时由所有者决定后整体替换。
- 平台目录（ios/、macos/）全部由所冻结的 Flutter 工具生成，无手写签名配置。

## 3. 最低部署目标（当前模板值）

| 平台 | 最低系统 | 来源 |
|---|---|---|
| macOS | 12.0 | `macos/Runner.xcodeproj` MACOSX_DEPLOYMENT_TARGET |
| iOS | 15.0 | `ios/Runner.xcodeproj` IPHONEOS_DEPLOYMENT_TARGET |

以上是 Flutter 3.47.7 模板默认值，已随工具链冻结记录；是否上调在阶段 C
发布矩阵确定，不以后续 Xcode 版本默认值静默漂移。

## 4. T00 验证结果

| 检查 | 结果 |
|---|---|
| `flutter pub get` | 通过（`pubspec.lock` 已提交） |
| `flutter analyze` | No issues found |
| `flutter test` | 2 个 widget 测试通过（zh 入口、语言切换） |
| `flutter build macos --debug` | 成功，产物 `build/macos/Build/Products/Debug/pdgapp.app` |
| macOS 启动 | `open` 启动后进程存在（arm64 debug），随后正常关闭 |
| iOS 构建/安装 | **未验证**：模拟器 runtime 未下载、无真机配对、未申请签名。按开工说明 T00 记为缺项，不冒充已通过 |

链接器出现 `/usr/local/gfortran/lib` 搜索路径警告，来自本机 shell 配置的
环境残留，与工程无关；Flutter 模板的 Run Script 警告为模板固有行为。

## 5. 待办（不阻塞 T00 数据工作）

- Apple 开发者账户、开发签名与真机注册：所有者事项（阶段 A0/C）。
- iOS 模拟器 runtime：需要时 `xcodebuild -downloadPlatform iOS`。
- 正式 bundle id、显示名称与图标：发布准备时决定。

## 6. T01 增量（2026-10-13）

直接依赖新增（版本以提交的 `pubspec.lock` 为准）：

| 包 | 锁定版本 | 用途 |
|---|---|---|
| sqlite3 | 2.9.4 | SQLite 本地绑定；`OpenMode.readOnly` 打开快照 |
| sqlite3_flutter_libs | 0.5.42 | Apple 构建内的 SQLite 来源 |
| crypto | 3.0.7 | 快照 SHA-256 流式哈希 |

SQLite 实际来源（依审查更正）：sqlite3_flutter_libs 在本机不链接系统
libsqlite3.dylib，而是通过 Swift Package Manager 解析 `CSQLite`
（https://github.com/simolus3/CSQLite，revision `1ee46d1`，见已提交的
`macos/**/swiftpm/Package.resolved`）从源码编译 SQLite 并捆绑进应用。
实际捆绑的 SQLite 具体版本号在 T02 于真机/模拟器运行时核实后记录，
不以 podspec 版本约束充当实测值。

依赖均来自 flutter-io.cn 镜像；lockfile 已提交。曾试装 sqlite3 3.x（引入
native-assets 工具链）与 sqlite3_flutter_libs 0.6.0+eol（已停止维护），均
回退到稳定组合，未保留在依赖中。

T01 验证（`flutter test`，真实库经 `PDGAPP_SOURCE_DB` 传入）：

| 检查 | 结果 |
|---|---|
| `flutter analyze` | No issues found |
| 真实库测试 `test/data/snapshot_live_test.dart` | 10/10 通过 |
| 离线负例 `test/data/snapshot_negative_test.dart` | 5/5 通过 |
| widget 测试 | 2/2 通过 |
| `flutter build macos --debug`（含 sqlite3 原生依赖） | 成功且启动验证通过 |

真实库覆盖内容：基线哈希/字节数、pdginfo 元数据（edition 2026、
schema_version 0.3、release 2026-05-30 13:41:24 PDT、CC BY 4.0）、15 表
行数与数据清单一致、NULL/空串计数抽查（pdgdata.value 41,433 NULL、
unit_text 303,803 空串等）、used_in_average/fit 仅 (0,0)(1,0)(1,1) 组合、
读前读后哈希不变、chmod 444 只读副本可查询、非 SELECT 语句拒绝。

原始库路径仅通过 `PDGAPP_SOURCE_DB` 环境变量传入，代码与测试均不硬编码
机器路径；快照文件未进入仓库（.gitignore 已排除 `*.sqlite`）。

## 7. T01 代码审查轮（2026-10-13）

两个独立子智能体并行审查 T00+T01 提交，报告全文见
`internal/reviews/t01_code_review_implementation.md`（实现质量，
REQUEST_CHANGES）与 `internal/reviews/t01_code_review_fidelity.md`
（契约忠实度，FAITHFUL：15 表/128 列三方核对通过、无循环验证、
T00 固定决定全部成立）。发现项已全部处置：

- HIGH×2：select 守卫误杀 WITH/EXPLAIN/VALUES（白名单扩充并测试）；
  open() 校验失败路径泄漏 sqlite3 句柄（失败即 dispose 再 rethrow）。
- MEDIUM×7：schema_version 负例未真正覆盖版本分支（契约 fixture 重写）；
  检查顺序文档与实现不一致（修正文档）；裸转型 TypeError 逃逸错误契约
  （类型检查后抛 SnapshotException）；重名列静默折叠（检测并拒绝）；
  extras 承诺未实现（`SnapshotInfo.extraColumns` 报告并测试）；
  `_scalarInt` 键名脆弱（位置取值）；异步倒置（见下）。
- LOW×6：queryFailed/参数化/守卫面覆盖、不可变 map、chmod 测试
  try/finally、多语句截断文档化、命名对齐（新增 `openSnapshot` 别名）。
- 记录类：sqlite3_flutter_libs 措辞更正（见 §6）；本节即延期记录。

修复后验证：analyze 干净；离线负例 14/14（含新增 9 项）；真实库
11/11；widget 2/2；macos debug 重建成功。

### 修复轮复审（round 2）与 N1–N5 处置

两位审查者（原实现质量审查者复核 + 全新独立复审）确认上述全部发现项
真实解决；复审报告见 `internal/reviews/t01_rereview_followup.md` 与
`t01_rereview_independent.md`。复审发现修复 diff 自身引入 5 项，已全部
修复：

- N1 MEDIUM：无换行结尾的行注释/未终止块注释中的关键字骗过守卫，
  sqlite3 抛裸 ArgumentError 逃逸错误契约 → 正则改为剥离到行尾/结尾，
  select() 增捕 ArgumentError → invalidInput。
- N2 MEDIUM：open() 的 dispose 重写删除了 phases 2–3 的
  SqliteException 映射，且 `PRAGMA table_info($table)` 未加引号插值，
  含空格表名可触发裸异常 → 恢复映射（unsupportedSchema）并对标识符
  加双引号。
- N3 LOW：`sqlite_*` 内部簿记表（sqlite_sequence/sqlite_stat1）被计入
  extras → 排除并文档化。
- N4 LOW：本节测试计数笔误（新增 9 项）→ 更正。
- N5 LOW：映射类型错误路径无仓库测试 → 补错型行负例（含 EXPLAIN
  接受路径测试）。

round 2 后验证：analyze 干净；离线负例 19/19；真实库 11/11；widget 2/2。

### 显式延期（转入 T02 交付；均已闭合）

1. **后台 isolate**：设计 §2/§9 与开工说明 §3 要求连接由长寿命后台
   isolate 独占持有。T01 快照层为同步原语（测试直接使用）。→ 已于
   T02 闭合：`lib/data/snapshot/gateway.dart`。
2. **SourceRef**：§3 要求每个返回对象保留源表名、源行键与快照哈希。
   T01 原始行只有行键。→ 已于 T02 闭合（审查轮补齐嵌套行）：顶层
   记录与嵌套行均带 `SourceRef`/`Sourced<T>`。

## 8. T02 增量（2026-10-14，分支 t02-repositories）

交付 `lib/data/repositories` 六个只读 repository（条目/衰变/相关量/汇总/
测量/文献）+ 信封服务 `SnapshotService`（§3 的 requestId/status/data/error
契约，notFound 只用于父对象缺失）+ `SnapshotSourceRef`（每对象带源表名、
行键、快照哈希）。测量分页每页 50、严格 (sort,id) 字典序、cursor 携带
快照+系列并在不匹配时 invalidInput；子 value/脚注/引用按页批量读取，
完整组不跨页拆分。

**§7 两项显式延期在本次闭合**：

1. 后台 isolate：`lib/data/snapshot/gateway.dart` 以长寿命工作 isolate
   独占连接，全部接口异步；错误跨 isolate 前净化为 code+message。
2. SourceRef：全部返回记录带 `SourceRef`（表名/行键/快照哈希）。

实现期发现并修复一处死锁缺陷：worker 内 dynamic 引用使枚举 `.name`
扩展在运行时不可见（NoSuchMethodError），worker 崩溃导致对端永久等待；
已改为静态类型并在 worker 内兜底捕获、异常必达回复。测试挂死即由
探针（tool/probe，临时）定位，未合入。

预期数据来源：`internal/build_t02_fixtures.py` 以独立 sqlite3 SQL 生成
`test/data/fixtures/t02_d0.json`（707 子项、40 相关边、125 测量、254 分页
序列、正常空态例），不从被测代码反推。

| 检查 | 结果 |
|---|---|
| `flutter analyze` | No issues found |
| 服务层真实库测试 | 20/20（集合与 fixture 精确对照） |
| 网关离线 | 3/3 |
| 网关真实库 | 1/1（跨 isolate 信封完整） |
| 全套（live env） | 56/56 |
| 离线全套 | 25 过 + 31 skip（无 env 时 live 组跳过） |
| `flutter build macos --debug` | 成功 |

## 9. T02 审查轮（2026-10-14）

两份报告：`internal/reviews/t02_code_review_implementation.md`（实现质量，
REQUEST_CHANGES）与 `internal/reviews/t02_code_review_fidelity.md`（契约
忠实度，DIVERGENT）。处置：

- HIGH×2（双审查者一致）：getDecaySource 缺失模式误用 error/invalidInput
  → 改为与其他接口一致的 notFound；测试同步更新。
- MEDIUM：worker close 路径与裸转型未包 try/catch（与已修死锁同类，
  可致调用方永久等待）→ 监听器整体包裹、必达回复；并发/关闭时序/
  worker 故障无回归测试 → 补并发 24 请求逐对校验、in-flight 关闭、
  命令后关闭；嵌套行无 SourceRef → 引入通用 `Sourced<T>` 包装全部
  返回行；254 行序列的值/脚注/引用集合只验首页 → fixture 补全集合，
  测试改为跨页累计精确对照。
- LOW：悬空 pdgreference_id 语义在 MeasurementRecord.reference 文档化
  （null ⇔ 悬空，原始 id 始终保留；当前基线 0 悬空）；网关方法类型化
  返回；open 失败消息固定不外泄 toString；fixture 选择加 tiebreaker、
  token_items 加 ORDER BY（重生成两次字节一致验证）；README 审查结论
  措辞改为"审查中"。

### 记录的决策

1. **请求侧 snapshotHash（§3 输入列）**：网关在 open 时绑定单一快照
   （可选哈希钉住），信封回带哈希，cursor 逐调用校验；不逐调用传
   hash。T03 接入若需 per-call 钉住再加可选参数。
2. **代码格式约定**：仓库未统一运行 `dart format`（T01/T02 一致），
   以 `flutter analyze` 零问题为准；如后续引入格式化需全库一次性
   单独提交。
3. **service 层兜底**：`SnapshotService._guard` 统一将任何异常（含非
   SnapshotException）转为稳定错误码信封，与网关 worker 兜底双层。

### 修复轮后刷新计数（两位审查者均确认 ALL_RESOLVED）

analyze 干净；网关离线 6/6（新增并发/关闭时序/重复 pdgid 三项）；
服务层真实库 21/21（新增跨页附件对照一项）；网关真实库 1/1；真实库
全套 60/60；离线 28 过 + 32 skip。§8 表中数字为修复前首测值，以本节
为准。

## 10. T03 增量（2026-10-14，分支 t03-pages）

第一条真实页面流程（开工说明开篇：离线打开 → 按 identifier 查到条目
→ 全部衰变目录 → 模式 → 原始参与项与相关量 → 完整测量、脚注、文献 →
返回原位）。

交付：

- **资产管道** `lib/data/app_database.dart`：随包资产（pubspec assets，
  gitignore 排除、见 assets/README.md）→ 暂存复制 → SHA-256 校验 →
  原子启用 → 网关打开；每次启动重验容器内文件哈希，不匹配即删重拷，
  绝不静默使用。实测：沙盒容器
  `…/Containers/com.example.pdgapp/Data/Library/Application Support/PDGapp/`
  内副本哈希 = 基线。
- **页面**：精确标识查询（空闲/查询中/未收录/失败/成功五态分开）、
  条目目录页（全部子项、类型不过滤获取 + 全部/衰变显示筛选、宽窗
  380px 列表 + 详情双栏）、模式原文详情（原文卡片、参与项、身份候选
  全列不自动选择、名称映射）、相关量列表（目标保持自身 BR/G/T 定义）、
  系列页（显式版次汇总 + 分页测量"加载更多"）、文献页（空题名照实
  显示）。全部数值按**原始记录**卡片呈现（T03 规则：未经格式化核查
  的值不包装成推荐值），显示与复制同一字符串。
- **架构**：UI 仅依赖 `PdgApi` 接口（gateway implements）；`ApiScope`
  位于 MaterialApp 之上（pushed 路由可达）；主题/语言入口移至查询页
  菜单（ShellController）；窄屏 `IndexedStack` 保活列表状态（返回保留
  滚动位置与选中项）。

### 记录的已知限制

1. **testWidgets 的 FakeAsync 区不能等待跨 isolate 端口消息**：真实网关
   的 widget 级端到端会死等（实测 10 分钟超时）。处置：widget 流程测试
   用 FakePdgApi（5/5）；真实快照的首条流程在 API 层顺序断言
   （first_flow_live_test.dart，普通 test 真异步）；真实 UI 由启动验证
   覆盖。后续如需 UI 级真库测试，用 `tester.runAsync` 或集成测试另行
   设计。
2. iOS 构建仍未验证（无模拟器 runtime/真机/签名），维持 T00 记录。

| 检查 | 结果 |
|---|---|
| `flutter analyze` | No issues found |
| widget 测试（FakePdgApi 全流程+四态+语言） | 5/5 |
| 真实库全套（含 first_flow_live 7 步流） | 64/64 |
| 离线全套 | 31 过 + 33 skip |
| `flutter build macos --debug`（含 64M 资产） | 成功，.app 175 MiB |
| 真实启动 + 首次复制校验 | 沙盒容器副本哈希 = 基线；进程存活 |

### T03 审查轮（2026-10-14，PR #2）

两份报告：`internal/reviews/t03_code_review_implementation.md`（REQUEST_
CHANGES：1 BLOCKING + 2 HIGH + 6 MEDIUM + 4 LOW）与
`t03_code_review_fidelity.md`（FAITHFUL：1 MEDIUM + 6 LOW）。全部处置：

- BLOCKING：宽屏双栏切换模式复用同一 State（A 模式数据显示在 B 模式
  头下）→ ModeDetailPage 按模式 id 加 ValueKey + didUpdateWidget 兜底；
  新增宽屏切换回归测试。
- HIGH：汇总原始记录缺 scale_factor/display 三件套（真实库 47% 行有
  scale_factor）→ 补齐四字段；加载更多失败被静默吞掉 → `_moreError`
  状态 + 内联错误行 + 重试（分页失败可见、页一状态保留），并修复
  in-flight load-more 与 reload 的代际竞态。
- MEDIUM：窄屏系统返回手势绕过浮层 → PopScope；查询输入框 label 误用
  "PDG 年份" → identifierLabel；启动错误图标浅色下不可见 → Theme.of；
  ShellScope 移到 MaterialApp 之上与 ApiScope 对称；AppDatabase 管道
  拆出 ensureInstalled 并补 4 场景单测（新装/损坏重拷/陈旧 staging/
  哈希不符拒装）；新增回归测试 5 组（宽屏切换、加载更多失败+重试、
  列表错误+重试、剪贴板 copy==display、AppDatabase）。
- LOW：死字符串清理+菜单标签入 AppStrings、EN 错误括号 ASCII 化、
  '（空）'本地化、raw 卡 maxLines 死参数移除、测量头标 [原始记录]、
  脚注显示 changebar、resultPanel 防御性空守卫。

### 追加已知限制与决策

1. 首次启动经 rootBundle.load 瞬时整库 ~64 MiB 内存（一次性复制；
  asUint8List 为零拷贝视图）；流式复制需平台通道，后续阶段再评估。
2. 非 Apple 平台容器回退 Directory.systemTemp（可被系统清理导致
  重拷）；引入 path_provider 于阶段 D 前再定。
3. 每次启动两道 SHA-256（AppDatabase 预检 + 网关 open 钉住）；SSD 上
  合计 <1s，暂不优化。
4. 宽屏双栏目前覆盖目录→模式；相关量→系列、文献仍整页推入，双栏
  化留待页面打磨轮；左栏宽度已按设计 §3 收敛到 340。
5. `flutter test` 需要本地放置 64 MiB 资产（assets/README.md 已注明）。
6. pubspec.lock 中包 URL 被工具重写为 pub.dev（镜像源取包，版本与
  哈希不变），不影响构建。

## 11. T04 增量（2026-10-14，分支 t04-format）

统一显示对象（lib/domain/display.dart）+ 七个真实例证自动核对：

- **显示规则**（§5，与 internal/build_t04_fixtures.py 的独立 Python 实现
  锁步）：基础文本取 display_value_text（回退 value_text、原值）；舍入
  文本已含误差，误差列是机器值绝不重复拼接；百分显示补一个 % 且不叠加
  −2 幂；非百分非零幂补 ×10^N（完整 value_text 已含幂记号则不再补）；
  限值符号缺省按 limit_type 补 < 或 >（已有则保留）；单位随后；CL 最后。
  无单位换算。显示/复制/读屏共用同一字符串（FormattedValueCard +
  Semantics）。
- **七例证**（fixture：test/data/fixtures/t04_examples.json，独立 SQL +
  独立规则实现生成期望显示串）：S009.1 单行 ×2 光子；S035.218→S035.27
  目录边+ex.K0+四个子模式；S035.286 两阶段（K−/ντ 各出现两次、'-->'
  是参与行不是粒子）；S035.319 零 outgoing 保留原文；S043.1 五个相关
  比值各自定义；S016.22（>10000 (CL 90.0)）与 S016T22（>14000 years）
  分立无拼接；item 1593 双 listing（B185/B205）全暴露无 first()。
- **合成负例**（test/domain/display_test.dart，8 项，全部 synthetic_ 前缀
  标注）：百分/幂/幂已含/限值补与留/单位 % 路径/回退链/误差不重现/
  测量单元格同规则。
- 系列页：完整显示卡与原始记录卡并列（T03 原始记录规则保持）。

| 检查 | 结果 |
|---|---|
| `flutter analyze` | No issues found |
| 真实例证测试（含格式化 vs Python 期望） | 9/9 |
| 合成负例 | 8/8 |
| 真实库全套 | 86/86 |
| 离线全套 | 44 过 + 42 skip |
| `flutter build macos --debug` | 成功 |

### T04 审查轮（2026-10-14，PR #3）

两份报告：`internal/reviews/t04_code_review_implementation.md`（REQUEST_
CHANGES：1 HIGH + 2 MEDIUM + 4 LOW）与 `t04_code_review_fidelity.md`
（DIVERGENT minor：2 MEDIUM + 6 LOW/INFO）。全部处置：

- **HIGH（规则误读，双实现一致地错）**：幂抑制检查了 value_text 而非
  实际显示的基础文本（dvt）——63% 带幂汇总行与 87% 带幂测量单元格丢失
  量级；S016T22 曾显示 ">14000 years" 隐去 ×10^30。修正：抑制只看被
  显示底本（数值后可带空格的 E 指数 / 10^ / ×10）；S016T22 现为
  ">14000×10^30 years"；反向 dvt 已含幂的双叠同修。
- MEDIUM：limit_type='R'（15,625 行）曾以舍入尾数伪装单值——改用完整
  value_text 呈现区间（§16.5 不从中值伪造点估计）；空底本不再产出
  孤立单位装饰（返回 ''）。
- MEDIUM：结果类型标签——FormattedValueCard 增加 pdgdoc 官方 indicator
  （AC=OUR AVERAGE…12 项）；定性文本（'seen'/'not seen'）保留原文不
  组合幂/百分。
- MEDIUM：显示=复制=读屏零覆盖——新增 widget 测试（Semantics label ==
  文本 == 剪贴板；2s 反馈定时器冲刷）；复制交互抽取共享 CopyButton
  （dispose 取消定时器）。
- LOW：fixture 非空守卫 + 新增 range/qualitative 样本；S040.72 经
  getDecaySource 钉死 item 1593 双 listing 应用路径；S009.1 负例改为
  实质断言（总光子数==2）；卡片标题"完整显示"区分两个复制按钮；
  Semantics excludeSemantics；系列页过时注释更新。

### 记录的决策

1. 幂抑制语义：§5 例外"完整 value_text 已含幂不再补幂"仅当 value_text
  本身是被显示底本（dvt 为空）时生效；dvt 是底本时必补 ×10^N（dvt 按
  定义不含幂）。依据 §5 主规则与衰变专篇 §382。
2. R 区间以完整 value_text 呈现；X（排除区间）dvt 自带完整文本不受
  影响；R 且 value_text 为空的行回落尾数（真实库 0 行）。
3. 定性底本（非数值引导）跳过幂/百分组合，原文保留；"提示未解释"的
  UI 标记延期（§5 矛盾编码真实库 0 行）。
4. 双回退（value→字符串）路径 Dart/Python 表示在极小/极长小数上有差
  异（真实库 0 行走到该路径）；标记为未指定，不为对齐而发明格式。
5. 缺失尺度语境标记（抑制发生时）延期：原始记录卡始终带完整
  value_text 供核对。
6. fixture（t04_examples.json）sha256：`3eeb1276a094f6332b311cbd23b7d21f759516e47621f574efc9c58679752241`；重生成须与该值
  一致后再改期望。

### 复审第二轮（NEW-1 回归修复与残留清理，commit 6509ad7）

- NEW-1 MEDIUM（定性门过宽回归，双审查者交叉发现）：数值探针现剥离
  ~ ≈ ( 前缀——'~100%'、'(100)%'、百分 R 区间 '55--75%' 恢复官方百分
  显示（重量化：2,484/2,487 百分汇总行与 2,415/2,427 百分测量格获得
  %；无一行的 % 与量级同时丢失，除定性行外）；百分 R 行不做
  value_text 替换（横线区间 dvt 非点估计）；幂记号补 )E 形式防
  '(90+110-120)E-3' 双叠。percent_edge fixture（B061.1/S004.1/
  M174.1）+ 合成 + 真实测试钉死。
- NEW-3：O/OM/ON 结果类型标签改为 null（本快照 pdgdoc indicator 为
  空，不编造）。
- NEW-5：Semantics(excludeSemantics) 收窄到值文本节点——标题行与复制
  按钮恢复读屏可达；值文本单次播报且与显示/复制同串。
- 记录残留：'presumably 100' 类 prose-数值前缀仍按定性保留原文
  （2026 版 1 行，行为正确、不改）；B038R4 区间尾随 ×10⁻³（1 行，
  '0.007 to 0.011×10^-3'，INFO 记录待 T05+ 决定是否需要区间感知幂）。
- 本轮计数：合成 13/13；widget 12/12；T04 例证 14/14；真实库全套
  98/98；离线 52 过 + 46 skip。fixture sha256 已更新为 3eeb1276…。

## 12. 路线图决策（2026-10-14，随 T05-A）

### 12.1 名称查询的分步开放

- 首批（已完成）仅完整 PDG identifier 精确查询（开工说明边界）。
- T05 后插入**过渡阶段**："标准 ASCII 名称精确匹配 + 候选列表"——仅用
  pdgparticle.name 这一有据字段；无别名/模糊/中文；候选不自动跳转；
  冻结小预期集合（唯一/歧义/不存在）。
- 完整名称识别（Unicode/LaTeX/中文别名 + ≥100 冻结预期）仍按开工说明
  §5 缺口表在中期交付。

### 12.2 符号与数学显示（数据普查 2026-10-14）

普查结论（其中名称语法特征数为初估，以符号层规范冻结时的可复算 SQL 为准）：粒子名与衰变描述（22,049+3,270）全部为 ASCII 命名约定
（nu_tau/Kbar0），反斜杠 TeX 仅 3+5 行——**符号映射层即可全覆盖**；
真实 LaTeX 集中在文献题名（2,079 行含 `\`、2,050 行含 `$`）及少量
pdgtext/comment（45/28 行）。

决策：
1. **符号层**（先做）：ASCII 约定 → 希腊/上下标/反粒子横线映射表；
   Python 独立锁步预期（T04 同法）；符号化显示/复制/读屏同串，原文
   恒可达。
2. **数学子集渲染**（随后）：flutter_math_fork（KaTeX 语法子集的
   Flutter 原生渲染，无 WebView/JS）；先审计 2,079 行题名的实际命令
   集并冻结白名单语法进 fixture；未知命令回退可复制原文并注明
   （设计 §7 回退规则）。
3. **不采用 KaTeX 本体/WebView**：设计红线（不执行任意脚本/HTML/
   外链；显示=复制=读屏一致）+ macOS WebView 支持不完整；若未来出现
   Flutter Web 目标再重议。

## 13. T05-B 增量（2026-10-14，分支 t05-parser）

D1 引擎 + 名称搜索过渡阶段 + 末态查询 UI：

- **引擎** `lib/data/repositories/decay_structure.dart`：严格按冻结规则
  实现（§0 七类分区、R1a/R1b 解析器携带终点粒子行穿越别名链、R2 权威
  行、R3 包容三态、§4 包含查询与守恒）。批量装载参考表后在内存求值。
- **验收**（test/data/d1_engine_live_test.dart，4/4）：分区七类与
  fixture 全等；**2,898 模式 × 9 列逐格相等（7,976 行零错配）**；
  K⁻ 基线 417/2,481/0 复现（sample_true 逐模式核对）；双作用域守恒。
- **服务/网关**：queryD1（inclusiveness scope + names + entry 过滤）、
  findEntryByName（标准 ASCII 精确名 → 候选列表；§12.1 过渡阶段，
  无模糊/别名猜测）。
- **UI**：查询页 notFound 时显示名称候选（点击经 findEntryExact 打开
  条目）；条目页顶部 D1QueryPanel（产物 chip 输入、直接/包容作用域、
  运行后真/假/未知计数 + 徽章列表 + 守恒注记）。

| 检查 | 结果 |
|---|---|
| `flutter analyze` | 无错误（2 个历史 cast 警告） |
| 引擎验收（live） | 4/4 |
| widget（含新面板布局回归） | 12/12 |
| 真实库全套 | 107/107 |
| 离线 | 55 过 + 52 skip |
| macOS debug 构建 | 成功 |
