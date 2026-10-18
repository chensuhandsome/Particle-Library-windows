# pdgall 数据内容与功能映射

版本：1.0　日期：2026-10-13

`pdgall-2026.0.sqlite` 包含 15 张业务表、128 个字段，文件大小 67,457,024 bytes（约 64.33 MiB）。当前 listing 版次为 2026，schema 为 0.3；发布标记为 2026-05-30 13:41:24 PDT。以下统计仅描述这一快照。

数据应有四种相互贯通的入口：粒子、性质/专题、衰变、文献。粒子表不能充当全库目录；`pdgid` 才是完整条目索引。历史汇总版次与当前结构、测量、引用、脚注的快照版次必须分开。

配套规范：[总体设计](PDG_App_Design.md)、[衰变结构详细设计](Decay_Structure_Design.md)。

## 1. 全表用途

| 表 | 行数 | 字段数 | 主要用途 |
|---|---:|---:|---|
| `pdgdata` | 352,047 | 19 | 当前/历史汇总与原始显示 |
| `pdgdecay` | 30,357 | 9 | 衰变参与项序列与结构查询 |
| `pdgdoc` | 71 | 7 | 编码解释与支持覆盖 |
| `pdgfootnote` | 22,885 | 5 | 脚注全文与修订提示 |
| `pdgid` | 22,049 | 10 | 全库目录、专题、粒子/性质/衰变入口 |
| `pdgid_map` | 12,334 | 7 | 相关量和间接测量入口 |
| `pdginfo` | 10 | 3 | 版本、来源、许可及修订起算日 |
| `pdgitem` | 3,270 | 3 | 标准名称、通用名称、衰变参与项 |
| `pdgitem_map` | 1,341 | 5 | 别名路径与一对多候选 |
| `pdgmeasurement` | 43,872 | 12 | 全部测量及来源 |
| `pdgmeasurement_footnote` | 27,632 | 3 | 精确脚注附件 |
| `pdgmeasurement_values` | 49,080 | 19 | 完整列、数值/文本结果及每列纳入状态 |
| `pdgparticle` | 1,170 | 13 | 身份、量子数和候选消歧 |
| `pdgreference` | 14,594 | 7 | 文献检索及反向测量目录 |
| `pdgtext` | 1,832 | 6 | 章节约定与说明 |

## 2. 信息覆盖和产品含义

- 22,049 个条目形成 475 个根节点；其中 37 个根节点无粒子身份行，既含中微子混合、CKM、混合样本和搜索专题，也含缺少身份映射的粒子条目。
- 1,170 条粒子记录对应 438 个 listing；439 个 PART 条目中，`M169` 缺少粒子行。554 条粒子记录没有 MC 编号。
- 352,047 条汇总记录分布在 54 个实际版次标签中，最早 1958、最新 2026；早期稀疏，不能宣称每个年份或每个性质均完整。2026 有 19,587 条汇总，涉及 18,389 个条目。
- 43,872 条测量包含 49,080 个数值/文本单元格；2,270 条测量有多列，最多 6 列。44 种列名包括模、相位、同位素、方法、置信水平和条件列。
- 2,074 个条目有测量但没有 2026 汇总。空 data_type 的 2,564 个条目下有 12,805 条测量，不能视为空目录丢弃。
- 全部汇总中 41,433 行的数值 value 为空，其中当前版 2,569 行；测量单元格中 8,082 行 value 为空。源文本可能含范围、限值或定性结果，必须继续显示。
- 7,938 个 BF 条目具有 30,357 条参与项；19 个条目仅有 incoming 行。所有 subdecay_id 都为空；1,959 个缩进 BF 条目仍须沿 parent_id 获取。
- 12,334 条条目关联中，12,317 条指向 BR、5 条指向宽度、12 条指向寿命。7,580 个 BF 条目有相关量映射，7,561 个可沿一跳映射找到至少一条测量；关联不等于该量就是衰变概率。
- 14,594 条文献中，13,978 条有 DOI、14,252 条有 INSPIRE 标识、14,532 条有题名。2,283 条没有当前测量反向链接；文献搜索须直接覆盖引用表。
- 22,885 条脚注均有精确条目标识和至少一条测量附件边。章节脚注索引可列出全部，但详情必须显示挂接测量，不能冒称每条说明都适用于整节。
- 1,832 个文本块含 1,670 个 h 与 162 个 t；t 中确有物理定义和约定，故说明正文属于离线核心数据。
- pdgdoc 的 71 条记录没有解释全部观测编码，例如 SEC、空 data_type、place、technique、pdgid_map.type 和 pdgtext.type；枚举编码不等于解释完毕。

## 3. 性质类型全量分布

下表大小写敏感；“空串”单独保留。行数不能作为独立物理量的数量。BF* 的直接测量为零是本库组织方式；测量入口须沿相关量访问。

| data_type | 条目 | 当版汇总行 | 全版汇总行 | 直接测量 | 单元格 | 有测量无当版汇总条目 |
|---|---:|---:|---:|---:|---:|---:|
| `BR` | 8,667 | 8,515 | 148,722 | 18,428 | 20,131 | 1,008 |
| `BFX` | 5,700 | 5,335 | 98,015 | 0 | 0 | 0 |
| 空串 | 2,564 | 1,746 | 26,935 | 12,805 | 16,282 | 837 |
| `BFX1` | 1,586 | 1,500 | 25,126 | 0 | 0 | 0 |
| `M` | 619 | 581 | 14,742 | 6,670 | 6,670 | 93 |
| `SEC` | 546 | 0 | 0 | 0 | 0 | 0 |
| `G` | 476 | 405 | 9,198 | 3,011 | 3,011 | 91 |
| `PART` | 439 | 0 | 0 | 0 | 0 | 0 |
| `BFI` | 279 | 266 | 5,750 | 0 | 0 | 0 |
| `v` | 275 | 282 | 4,261 | 661 | 661 | 5 |
| `BFX2` | 243 | 235 | 3,251 | 0 | 0 | 0 |
| `d` | 161 | 176 | 3,499 | 634 | 634 | 9 |
| `D` | 123 | 179 | 3,757 | 386 | 386 | 12 |
| `f` | 115 | 134 | 2,666 | 339 | 349 | 0 |
| `BFI1` | 55 | 54 | 1,122 | 0 | 0 | 0 |
| `BFX3` | 47 | 44 | 1,042 | 0 | 0 | 0 |
| `T` | 38 | 48 | 1,710 | 447 | 465 | 2 |
| `s` | 22 | 20 | 522 | 97 | 97 | 0 |
| `m` | 21 | 19 | 548 | 184 | 184 | 2 |
| `c` | 20 | 7 | 92 | 129 | 129 | 13 |
| `BFI2` | 15 | 15 | 384 | 0 | 0 | 0 |
| `e` | 11 | 11 | 326 | 78 | 78 | 0 |
| `SRCH` | 11 | 0 | 0 | 0 | 0 | 0 |
| `BFX4` | 7 | 7 | 159 | 0 | 0 | 0 |
| `BFX5` | 6 | 6 | 168 | 0 | 0 | 0 |
| `g` | 3 | 2 | 52 | 3 | 3 | 2 |

## 4. 全部字段的解释与使用位置

“NULL”与空字符串分开统计。字段角色以实际列结构与数据为依据；适用范围尚需条目级解释的字段明确保留原文。所有 id 都只在本快照内有效。

### pdgdata

| 字段 | SQL 类型 | NULL 行 | 空字符串行 | 处理与用途 |
|---|---|---:|---:|---|
| `id` | `INTEGER` | 0 | 0 | 一条汇总/附加显示记录的快照键 |
| `pdgid_id` | `INTEGER` | 0 | 0 | 对应具体物理定义或衰变条目 |
| `pdgid` | `VARCHAR` | 0 | 0 | 冗余条目标识 |
| `edition` | `VARCHAR` | 0 | 0 | 汇总版次；历史表必须逐行使用，不套当前测量状态 |
| `value_type` | `VARCHAR(2)` | 0 | 0 | 官方取得方式或附加记录类型；AC、D、FC、DR、L、OL、V、E、DV、OM 等分别保存 |
| `in_summary_table` | `BOOLEAN` | 0 | 0 | 是否进入 Summary Table；不是单项测量纳入标志 |
| `confidence_level` | `FLOAT` | 270,848 | 0 | 本行置信水平；不由误差或相邻行猜测 |
| `limit_type` | `VARCHAR(1)` | 249,814 | 0 | 上限/下限/范围/排除区间；NULL 也可能是文本结果 |
| `comment` | `VARCHAR` | 349,004 | 0 | 本汇总行说明；与测量脚注及章节文本分开展示 |
| `value` | `FLOAT` | 41,433 | 0 | 原始数值；可能是点值/边界，先检查类型；NULL 不代表零或没收录结果 |
| `value_text` | `VARCHAR` | 644 | 0 | 含源格式的值文本；保留表达式、定性结果、范围与幂 |
| `error_positive` | `FLOAT` | 42,937 | 0 | 原始正误差；不对称化 |
| `error_negative` | `FLOAT` | 42,937 | 0 | 原始负侧误差；保留原字段约定 |
| `scale_factor` | `FLOAT` | 184,874 | 0 | 误差调整因子信息；显示来源，不再次乘已存储误差 |
| `unit_text` | `VARCHAR` | 0 | 303,803 | 原始单位；空串和文本单位按定义判断，不能一律认作无量纲 |
| `display_value_text` | `VARCHAR` | 0 | 644 | 源舍入显示部分；结合 display 幂/百分标志；部分模式摘要仍缺表头单位/尺度，须核查语境 |
| `display_power_of_ten` | `INTEGER` | 0 | 0 | 显示尺度；不能再次作用于原始 value |
| `display_in_percent` | `BOOLEAN` | 0 | 0 | 百分显示标志；与单位中直接存 % 的情况分开处理 |
| `sort` | `INTEGER` | 0 | 0 | 同条目、同版次的显示次序；不是 best 判据 |

### pdgdecay

| 字段 | SQL 类型 | NULL 行 | 空字符串行 | 处理与用途 |
|---|---|---:|---:|---|
| `id` | `INTEGER` | 0 | 0 | 参与项行键；必须保留原文位置与重复项 |
| `pdgid_id` | `INTEGER` | 0 | 0 | 所属衰变条目；这是一个 mode 的参与项集合 |
| `pdgid` | `VARCHAR` | 0 | 0 | 冗余衰变标识；与整数连接核对 |
| `pdgitem_id` | `INTEGER` | 0 | 0 | 参与名称项；可为粒子、集合、别名、包容项、标点或未解析文本 |
| `name` | `VARCHAR` | 0 | 0 | 本行原始名称/文本；保持保真，不将箭头、逗号等视为粒子 |
| `is_outgoing` | `BOOLEAN` | 0 | 0 | 原始 incoming/outgoing 标志；outgoing 不保证是最终稳定粒子 |
| `multiplier` | `INTEGER` | 0 | 0 | 本行重复数；与多行重复共同保留；未解析分组时不自由分配乘数 |
| `subdecay_id` | `INTEGER` | 30,357 | 0 | 显式后续衰变条目关联；本库全部为空，不能据此宣称已有完整级联树 |
| `sort` | `INTEGER` | 0 | 0 | 参与项顺序；渲染文本序列时必用，不能按粒子名字重排 |

### pdgdoc

| 字段 | SQL 类型 | NULL 行 | 空字符串行 | 处理与用途 |
|---|---|---:|---:|---|
| `id` | `INTEGER` | 0 | 0 | 码表记录键 |
| `table_name` | `VARCHAR` | 0 | 0 | 编码作用表 |
| `column_name` | `VARCHAR` | 0 | 0 | 编码作用字段；同字母跨字段含义不同 |
| `value` | `VARCHAR` | 1 | 0 | 编码值；NULL 也是被说明的值 |
| `indicator` | `VARCHAR` | 0 | 60 | 官方显示标签；可空，不以其空白推断无意义 |
| `description` | `VARCHAR` | 0 | 0 | 官方编码说明；本地解释页来源 |
| `comment` | `VARCHAR` | 71 | 0 | 补充说明；本库全空但仍兼容 |

### pdgfootnote

| 字段 | SQL 类型 | NULL 行 | 空字符串行 | 处理与用途 |
|---|---|---:|---:|---|
| `id` | `INTEGER` | 0 | 0 | 脚注键；测量附件据此去重 |
| `pdgid` | `VARCHAR` | 0 | 0 | 脚注所属条目字符串；需精确核查，不按前缀归属 |
| `text` | `VARCHAR` | 0 | 7 | 完整脚注原文；保留物理假设和不纳入原因 |
| `footnote_index` | `INTEGER` | 0 | 0 | 局部脚注序号；不作为全局键 |
| `changebar` | `BOOLEAN` | 0 | 0 | 脚注当版修订标记；不证明测量数值发生变化 |

### pdgid

| 字段 | SQL 类型 | NULL 行 | 空字符串行 | 处理与用途 |
|---|---|---:|---:|---|
| `id` | `INTEGER` | 0 | 0 | 条目连接主键；所有已声明整数外键以此连接 |
| `pdgid` | `VARCHAR` | 0 | 0 | 用户可复制的 PDG 条目标识；粒子、性质、衰变、专题均可能使用 |
| `parent_id` | `INTEGER` | 475 | 0 | 官方条目树父节点；目录、面包屑、递归枚举及缩进树依据 |
| `parent_pdgid` | `VARCHAR` | 475 | 0 | 冗余父标识；交叉检查/展示，不代替整数连接 |
| `description` | `VARCHAR` | 0 | 0 | 权威原始定义/衰变描述；全文检索、详情标题、解析回退 |
| `mode_number` | `INTEGER` | 14,111 | 0 | 当版衰变模式显示编号；不是跨版主键，也不是排序值或乘数 |
| `data_type` | `VARCHAR(4)` | 0 | 2,564 | 区分性质、分支分数、比值、章节和搜索专题；大小写敏感；空串仍有数据 |
| `flags` | `VARCHAR(8)` | 0 | 20,548 | 逐字符、按条目语境解释；粒子分类、默认/替代、适用电荷和特殊条件不能混用 |
| `year_added` | `INTEGER` | 22,049 | 0 | 可能记录条目加入年份；本库全空，不提供发现年份或新增条目榜 |
| `sort` | `INTEGER` | 0 | 0 | 原始目录顺序；同值以 id 稳定排序，不作为物理优先级 |

### pdgid_map

| 字段 | SQL 类型 | NULL 行 | 空字符串行 | 处理与用途 |
|---|---|---:|---:|---|
| `id` | `INTEGER` | 0 | 0 | 条目关联边键；记录来源路径 |
| `source_id` | `INTEGER` | 0 | 0 | 源条目；本库均为 BF 系列 |
| `source` | `VARCHAR` | 0 | 0 | 冗余源标识 |
| `target_id` | `INTEGER` | 0 | 0 | 关联量端点；本库有 BR、G、T；BR 也有寿命定义，须同时检查描述和单位 |
| `target` | `VARCHAR` | 0 | 0 | 冗余目标标识 |
| `type` | `VARCHAR(1)` | 0 | 0 | 原始关系编码；本库均 D，但快照码表不定义代数角色 |
| `sort` | `INTEGER` | 0 | 0 | 关联量显示次序；不表示分子/分母、加减或拟合权重 |

### pdginfo

| 字段 | SQL 类型 | NULL 行 | 空字符串行 | 处理与用途 |
|---|---|---:|---:|---|
| `id` | `INTEGER` | 0 | 0 | 快照内记录键；不作为版本身份 |
| `name` | `VARCHAR` | 0 | 0 | 元信息键；设置页按白名单解释，未知键原样保留 |
| `value` | `VARCHAR` | 0 | 0 | 元信息值；edition、release、schema、引用、许可和 changebar 起算日分别保存 |

### pdgitem

| 字段 | SQL 类型 | NULL 行 | 空字符串行 | 处理与用途 |
|---|---|---:|---:|---|
| `id` | `INTEGER` | 0 | 0 | 名称项主键；它可能对应零个、一个或多个粒子记录 |
| `name` | `VARCHAR` | 0 | 0 | 名称项原文；粒子/别名/集合/任意文本均保存 |
| `item_type` | `VARCHAR(1)` | 0 | 0 | 解释名称项角色；不能将 T 文本或 I 包容项强制转成粒子 |

### pdgitem_map

| 字段 | SQL 类型 | NULL 行 | 空字符串行 | 处理与用途 |
|---|---|---:|---:|---|
| `id` | `INTEGER` | 0 | 0 | 映射边快照键；保留展开路径 |
| `pdgitem_id` | `INTEGER` | 0 | 0 | 源名称项；可递归映射 |
| `name` | `VARCHAR` | 0 | 0 | 源名称便捷字段；核对后用于搜索解释 |
| `target_id` | `INTEGER` | 0 | 0 | 目标名称项；不保证是具体粒子；必须继续检查类型/一对多 |
| `sort` | `INTEGER` | 0 | 0 | 候选次序；不代表唯一性 |

### pdgmeasurement

| 字段 | SQL 类型 | NULL 行 | 空字符串行 | 处理与用途 |
|---|---|---:|---:|---|
| `id` | `INTEGER` | 0 | 0 | 单次 listing 记录键；一篇文献可有很多条记录 |
| `pdgid_id` | `INTEGER` | 0 | 0 | 所测系列；可能是 BR/其他量而非 BF 条目 |
| `pdgid` | `VARCHAR` | 0 | 0 | 冗余系列标识 |
| `pdgreference_id` | `INTEGER` | 0 | 0 | 直接文献关联；文献页反向列出测量 |
| `event_count` | `VARCHAR(20)` | 0 | 34,681 | 事件数原文；带估计/范围时不能强转整数 |
| `confidence_level` | `FLOAT` | 34,329 | 0 | 测量级置信水平；不覆盖同测量内显式 CL% 列 |
| `place` | `VARCHAR(1)` | 0 | 0 | 来源排列编码；本库 N/U/L/B，官方快照码表未解释，不译为实验地点或纳入状态 |
| `technique` | `VARCHAR(4)` | 0 | 954 | 技术/实验缩写原文；本库 423 种，不按缩写猜探测器/合作组归属 |
| `charge` | `VARCHAR(3)` | 0 | 42,209 | 随系列定义的电荷字符串；空串或 +- 等不能直接与粒子 charge 做数值相等 |
| `changebar` | `BOOLEAN` | 0 | 0 | 当版新增/修订标记；结合 metadata 起算日，不称发现年份 |
| `comment` | `VARCHAR` | 0 | 2,972 | 本测量行说明；保留全部条件和限定 |
| `sort` | `INTEGER` | 0 | 0 | listing 原序；分页同值以 id 收尾 |

### pdgmeasurement_footnote

| 字段 | SQL 类型 | NULL 行 | 空字符串行 | 处理与用途 |
|---|---|---:|---:|---|
| `id` | `INTEGER` | 0 | 0 | 附件边键 |
| `pdgmeasurement_id` | `INTEGER` | 0 | 0 | 具体测量端点 |
| `pdgfootnote_id` | `INTEGER` | 0 | 0 | 具体脚注端点；不能据所属章节广播到其他测量 |

### pdgmeasurement_values

| 字段 | SQL 类型 | NULL 行 | 空字符串行 | 处理与用途 |
|---|---|---:|---:|---|
| `id` | `INTEGER` | 0 | 0 | 数值/文本单元格键；每列状态和查询证据以此定位 |
| `pdgmeasurement_id` | `INTEGER` | 0 | 0 | 同一次测量记录；保留该记录全部兄弟列 |
| `column_name` | `VARCHAR` | 0 | 111 | 列名原文；VALUE/MODULUS/PHASE/METHOD 等角色随系列判定，不保证同记录内唯一 |
| `value_text` | `VARCHAR` | 0 | 2,767 | 完整源值文本；没有数值字段时仍可有物理信息 |
| `unit_text` | `VARCHAR` | 0 | 27,818 | 本列单位；允许文本；不与测量中另一列共用 |
| `display_value_text` | `VARCHAR` | 0 | 2,767 | 舍入显示部分；保留定性结果和实验条件文字 |
| `display_power_of_ten` | `INTEGER` | 0 | 0 | 本列显示十次幂；不再缩放原始 value |
| `display_in_percent` | `BOOLEAN` | 0 | 0 | 本列百分显示标志；不与 unit_text=% 重复添加 |
| `limit_type` | `VARCHAR(1)` | 37,389 | 0 | 本列结果类型；限值列不能当作中心值 |
| `used_in_average` | `BOOLEAN` | 0 | 0 | 本列是否用于本 listing 的平均；兼容 true/false/unknown |
| `used_in_fit` | `BOOLEAN` | 0 | 0 | 本列是否用于本 listing 的拟合；与 average 分开 |
| `value` | `FLOAT` | 8,082 | 0 | 原始数值；文本/材料/同位素等列可能为 NULL |
| `error_positive` | `FLOAT` | 20,500 | 0 | 原始总正误差（若提供）；不自动以统计和系统合成替代 |
| `error_negative` | `FLOAT` | 20,500 | 0 | 原始总负侧误差（若提供） |
| `stat_error_positive` | `FLOAT` | 33,040 | 0 | 统计正误差；与其他分量并列 |
| `stat_error_negative` | `FLOAT` | 33,040 | 0 | 统计负侧误差 |
| `syst_error_positive` | `FLOAT` | 33,040 | 0 | 系统正误差；不默认独立、不自行平方求和 |
| `syst_error_negative` | `FLOAT` | 33,040 | 0 | 系统负侧误差 |
| `sort` | `INTEGER` | 0 | 0 | 列顺序；列名重复时用 sort 和 id 保持身份 |

### pdgparticle

| 字段 | SQL 类型 | NULL 行 | 空字符串行 | 处理与用途 |
|---|---|---:|---:|---|
| `id` | `INTEGER` | 0 | 0 | 具体粒子记录键；与快照组成安全身份，不能以 name 或 item_id 去重 |
| `pdgid_id` | `INTEGER` | 0 | 0 | 所属 listing 条目；多个电荷态/反粒子可能共享 |
| `pdgid` | `VARCHAR` | 0 | 0 | 冗余 listing 标识 |
| `pdgitem_id` | `INTEGER` | 0 | 0 | 名称项关联；本库存在一个名称项指向两条不同 listing 的情况 |
| `name` | `VARCHAR` | 0 | 0 | 标准 ASCII 名称；显示与精确检索，另有保真符号形式 |
| `cc_type` | `VARCHAR(1)` | 0 | 0 | P 粒子/A 反粒子/S 自共轭；不由电荷正负代替 |
| `mcid` | `INTEGER` | 554 | 0 | Monte Carlo 编号；允许为空；空号粒子必须仍可查询 |
| `charge` | `FLOAT` | 0 | 0 | 以基本电荷为单位的电荷数；不等同于测量 charge 字符串或 CP-charge 标志 |
| `quantum_i` | `VARCHAR(40)` | 76 | 0 | 同位旋原文；有问号和多候选，按已核验语法筛选 |
| `quantum_g` | `VARCHAR(1)` | 969 | 0 | G 宇称原文；空值不能自动解释成不适用 |
| `quantum_j` | `VARCHAR(40)` | 17 | 0 | 自旋原文；包括 >=5/2、2++ or 4 等，不能强制浮点化 |
| `quantum_p` | `VARCHAR(1)` | 34 | 0 | 宇称原文；确定值、问号、空值分别保留 |
| `quantum_c` | `VARCHAR(1)` | 970 | 0 | C 宇称原文；确定值、问号、空值分别保留 |

### pdgreference

| 字段 | SQL 类型 | NULL 行 | 空字符串行 | 处理与用途 |
|---|---|---:|---:|---|
| `id` | `INTEGER` | 0 | 0 | 引用记录键；DOI 相同不自动合并记录 |
| `document_id` | `VARCHAR` | 0 | 0 | PDG 文献短标识；可精确查找，不当作完整作者字段 |
| `publication_name` | `VARCHAR` | 0 | 1 | 出版信息原文；可能已含卷页等，不丢弃 |
| `publication_year` | `INTEGER` | 0 | 0 | 发表年份；不当作 PDG 收录版次 |
| `doi` | `VARCHAR(240)` | 0 | 616 | DOI 原文；非空时校验后生成 HTTPS 外链；全库不保证唯一 |
| `inspire_id` | `VARCHAR(16)` | 0 | 342 | INSPIRE 标识；非空时生成允许模板外链；不保证唯一 |
| `title` | `VARCHAR` | 0 | 62 | 题名；可能缺失；当前库没有独立作者/arXiv/摘要/全文字段 |

### pdgtext

| 字段 | SQL 类型 | NULL 行 | 空字符串行 | 处理与用途 |
|---|---|---:|---:|---|
| `id` | `INTEGER` | 0 | 0 | 文本块键 |
| `pdgid_id` | `INTEGER` | 0 | 0 | 所属条目/章节；可沿父路径显示来源明确的上下文 |
| `pdgid` | `VARCHAR` | 0 | 0 | 冗余条目标识 |
| `text` | `VARCHAR` | 0 | 0 | 标题或解释性段落；包含物理约定，不能只做搜索词 |
| `type` | `VARCHAR(1)` | 0 | 0 | 本库 h/t；原文显示保留类型，完整语义须与 Listings 对照 |
| `sort` | `INTEGER` | 0 | 0 | 同节点文本块原序；不假设可与 measurement.sort 直接混排 |

## 5. 全部原始编码说明

本节逐行列出快照自带的 pdgdoc。它是原始数据库的内容，不是应用对未知字段的猜测。应用可显示经核查的中文解释，同时保留官方原文。

| 表.字段 | 值 | indicator | 官方 description |
|---|---|---|---|
| `PDGDATA.VALUE_TYPE` | `AC` | OUR AVERAGE | from weighted average of selected data |
| `PDGDATA.VALUE_TYPE` | `L` | BEST LIMIT | best limit among available data |
| `PDGDATA.VALUE_TYPE` | `D` | OUR AVERAGE | from branching ratio of another mode |
| `PDGDATA.VALUE_TYPE` | `V` | OUR EVALUATION | not from direct measurement, but evaluated from measurements of related quantities |
| `PDGDATA.VALUE_TYPE` | `OL` | OUR LIMIT | for special cases where limit is evaluated from measured ratios or other data |
| `PDGDATA.VALUE_TYPE` | `OM` |  | extra entry, printed below summary value |
| `PDGDATA.VALUE_TYPE` | `ON` |  | extra entry, printed above summary value |
| `PDGDATA.VALUE_TYPE` | `FC` | OUR FIT | from constrained or overdetermined multi-parameter fit of selected data |
| `PDGDATA.VALUE_TYPE` | `DR` | OUR FIT | fitted decay rates |
| `PDGDATA.VALUE_TYPE` | `E` | OUR ESTIMATE | from estimate chosen by person rather than statistical procedure |
| `PDGDATA.VALUE_TYPE` | `O` |  | our evaluation without a default description |
| `PDGDATA.VALUE_TYPE` | `DV` | OUR EVALUATION | reserved for internal use |
| `PDGDATA.LIMIT_TYPE` | NULL |  | NULL means not a limit (i.e. a measurement) |
| `PDGDATA.LIMIT_TYPE` | `U` |  | upper Limit |
| `PDGDATA.LIMIT_TYPE` | `L` |  | lower Limit |
| `PDGDATA.LIMIT_TYPE` | `R` |  | range |
| `PDGDATA.LIMIT_TYPE` | `X` |  | range exclusion |
| `PDGID.DATA_TYPE` | `e` |  | electric dipole moment |
| `PDGID.DATA_TYPE` | `m` |  | magnetic moment |
| `PDGID.DATA_TYPE` | `v` |  | CP-violation parameter |
| `PDGID.DATA_TYPE` | `D` |  | mass difference |
| `PDGID.DATA_TYPE` | `f` |  | form factor |
| `PDGID.DATA_TYPE` | `g` |  | mean life (specific case for Sigma, Sigma-) |
| `PDGID.DATA_TYPE` | `s` |  | slope parameter |
| `PDGID.DATA_TYPE` | `G` |  | full width |
| `PDGID.DATA_TYPE` | `M` |  | mass |
| `PDGID.DATA_TYPE` | `c` |  | coupling constant ratio |
| `PDGID.DATA_TYPE` | `d` |  | decay parameter |
| `PDGID.DATA_TYPE` | `T` |  | lifetime |
| `PDGID.DATA_TYPE` | `BFX` |  | exclusive branching fraction |
| `PDGID.DATA_TYPE` | `BFX1` |  | exclusive branching fraction with indentation 1 |
| `PDGID.DATA_TYPE` | `BFX2` |  | exclusive branching fraction with indentation 2 |
| `PDGID.DATA_TYPE` | `BFX3` |  | exclusive branching fraction with indentation 3 |
| `PDGID.DATA_TYPE` | `BFX4` |  | exclusive branching fraction with indentation 4 |
| `PDGID.DATA_TYPE` | `BFX5` |  | exclusive branching fraction with indentation 5 |
| `PDGID.DATA_TYPE` | `BFI` |  | inclusive branching fraction |
| `PDGID.DATA_TYPE` | `BFI1` |  | inclusive branching fraction with indentation 1 |
| `PDGID.DATA_TYPE` | `BFI2` |  | inclusive branching fraction with indentation 2 |
| `PDGID.DATA_TYPE` | `BFI3` |  | inclusive branching fraction with indentation 3 |
| `PDGID.DATA_TYPE` | `BFI4` |  | inclusive branching fraction with indentation 4 |
| `PDGID.DATA_TYPE` | `BFI5` |  | inclusive branching fraction with indentation 5 |
| `PDGID.DATA_TYPE` | `BR` |  | branching ratio |
| `PDGID.DATA_TYPE` | `PART` |  | particle |
| `PDGID.DATA_TYPE` | `SRCH` |  | searches |
| `PDGID.FLAGS` | `G` |  | Gauge and Higgs Bosons |
| `PDGID.FLAGS` | `L` |  | Leptons |
| `PDGID.FLAGS` | `Q` |  | Quarks |
| `PDGID.FLAGS` | `M` |  | Mesons |
| `PDGID.FLAGS` | `B` |  | Baryons |
| `PDGID.FLAGS` | `S` |  | searches |
| `PDGID.FLAGS` | `A` | ALT | alternative |
| `PDGID.FLAGS` | `D` | DEFAULT | default value |
| `PDGID.FLAGS` | `0` |  | neutral charge |
| `PDGID.FLAGS` | `1` |  | single charged |
| `PDGID.FLAGS` | `2` |  | doubly charged |
| `PDGID.FLAGS` | `+` |  | positive charge |
| `PDGID.FLAGS` | `-` |  | negative charge |
| `PDGID.FLAGS` | `s` |  | special case - see PDG Identifier description |
| `PDGITEM.ITEM_TYPE` | `P` |  | particle with specific charge |
| `PDGITEM.ITEM_TYPE` | `A` |  | "also known as" alias |
| `PDGITEM.ITEM_TYPE` | `W` |  | "was" alias |
| `PDGITEM.ITEM_TYPE` | `S` |  | shortcut |
| `PDGITEM.ITEM_TYPE` | `B` |  | both charges (e.g. +-) |
| `PDGITEM.ITEM_TYPE` | `C` |  | conjugate of B entry |
| `PDGITEM.ITEM_TYPE` | `G` |  | generic particle name (not charge specific, for resonances) |
| `PDGITEM.ITEM_TYPE` | `L` |  | specific list of particles (such as \ell) |
| `PDGITEM.ITEM_TYPE` | `I` |  | anything (used for inclusive decays) |
| `PDGITEM.ITEM_TYPE` | `T` |  | text |
| `PDGPARTICLE.CC_TYPE` | `P` |  | particle state |
| `PDGPARTICLE.CC_TYPE` | `A` |  | anti-particle |
| `PDGPARTICLE.CC_TYPE` | `S` |  | self-conjugate state |

## 6. 历史版次的实际覆盖

版次选择器只列以下实际存在的标签；具体性质再按自己的可用集合过滤。同一版次存在多行时全部保留，不按年压成一个点。

| 版次 | 汇总记录 | 不同条目 | Summary Table 标记行 |
|---|---:|---:|---:|
| 1958 | 19 | 19 | 19 |
| 1961 | 27 | 27 | 27 |
| 1963 | 27 | 27 | 27 |
| 1964 | 63 | 63 | 63 |
| 1965 | 132 | 68 | 132 |
| 1966 | 2 | 2 | 2 |
| 1967 | 93 | 93 | 92 |
| 1968 | 98 | 96 | 97 |
| 1969 | 101 | 101 | 100 |
| 1970 | 211 | 109 | 209 |
| 1971 | 108 | 108 | 107 |
| 1972 | 110 | 110 | 110 |
| 1973 | 117 | 117 | 116 |
| 1974 | 120 | 120 | 119 |
| 1976 | 118 | 118 | 117 |
| 1977 | 1 | 1 | 1 |
| 1978 | 119 | 119 | 118 |
| 1980 | 120 | 120 | 119 |
| 1982 | 120 | 120 | 119 |
| 1984 | 125 | 125 | 124 |
| 1986 | 124 | 124 | 123 |
| 1988 | 128 | 128 | 127 |
| 1990 | 3,339 | 2,827 | 1,780 |
| 1992 | 4,043 | 3,449 | 2,134 |
| 1994 | 4,366 | 3,900 | 2,413 |
| 1996 | 5,066 | 4,553 | 2,824 |
| 1997 | 5,224 | 4,704 | 2,913 |
| 1998 | 5,535 | 5,000 | 3,088 |
| 2000 | 5,963 | 5,403 | 3,328 |
| 2002 | 6,547 | 5,904 | 3,616 |
| 2003 | 6,790 | 6,128 | 3,735 |
| 2004 | 7,108 | 6,417 | 3,924 |
| 2005 | 7,526 | 6,837 | 4,151 |
| 2006 | 8,349 | 7,624 | 4,600 |
| 2007 | 8,916 | 8,142 | 4,887 |
| 2008 | 9,626 | 8,788 | 5,239 |
| 2009 | 10,320 | 9,448 | 5,606 |
| 2010 | 10,775 | 9,884 | 5,870 |
| 2011 | 11,110 | 10,204 | 6,032 |
| 2012 | 11,729 | 10,762 | 6,390 |
| 2013 | 12,074 | 11,095 | 6,583 |
| 2014 | 12,603 | 11,611 | 6,860 |
| 2015 | 13,092 | 12,088 | 7,150 |
| 2016 | 13,613 | 12,557 | 7,492 |
| 2017 | 14,004 | 12,935 | 7,729 |
| 2018 | 14,527 | 13,449 | 8,037 |
| 2019 | 15,016 | 13,919 | 8,284 |
| 2020 | 15,779 | 14,715 | 8,832 |
| 2021 | 16,297 | 15,216 | 9,106 |
| 2022 | 16,951 | 15,857 | 9,425 |
| 2023 | 17,422 | 16,312 | 9,680 |
| 2024 | 18,036 | 16,902 | 10,008 |
| 2025 | 18,631 | 17,472 | 10,296 |
| 2026 | 19,587 | 18,389 | 10,752 |

## 7. 数值列与单位的支持策略

`column_name` 的全量原始词表如下；分组和规范别名不能覆盖原字段。相同列名也可能对应不同物理定义；CL% 有重复列名的测量，因此列键必须包含行身份与顺序。

| 列名原文 | 单元格行数 |
|---|---:|
| VALUE | 41,419 |
| MODULUS | 815 |
| PHASE | 814 |
| CL% | 585 |
| MASS | 544 |
| LIMIT | 456 |
| EVTS | 432 |
| BKGD EST | 432 |
| PARTICLE | 425 |
| CHG | 409 |
| FLUX | 230 |
| MSbar MASS | 204 |
| BEAM | 187 |
| METHOD | 157 |
| ISOTOPE | 157 |
| sqrt(s) | 145 |
| STD. MODEL | 145 |
| ASYMMETRY | 145 |
| WIDTH | 141 |
| t(1/2) | 117 |
| TRANSITION | 117 |
| ENERGY | 117 |
| X-SECT | 113 |
| 空串 | 111 |
| COMMENTS | 99 |
| ENRGY | 70 |
| LambdaLL- | 63 |
| LambdaLL+ | 63 |
| SHIELDING | 61 |
| QUARKS/ NUCLEON | 50 |
| MATERIAL/METHOD | 50 |
| Units | 41 |
| Mass | 41 |
| MATERIAL | 20 |
| DENSITY | 20 |
| p-value | 15 |
| <lambda> | 15 |
| <eta> | 15 |
| dlambda(0)/dlambda(+) | 10 |
| CHARGE | 10 |
| CHG e/3 | 8 |
| EFFECTIVE DENOM. | 7 |
| SPIN | 4 |
| Gamma.B(X --> hadrons) (eV) | 1 |

汇总有 44 种、测量有 58 种单位文本（均包含空串）。单位先原样可读，再按已核验的定义允许换算。空串可能是无量纲也可能是源字段未表达；`e/3`、`pi rad`、`GeV**-1/2`、`hbar s**-1`、`beta = v/c` 等不能交给简单大小写归一化处理。`Mev`、`KeV` 等历史拼写只能以显式别名表处理。

百分表达有两条实际路径：`display_in_percent=1, display_power_of_ten=-2, unit_text=""`，以及 `display_in_percent=0, display_power_of_ten=0, unit_text="%"`。两者都显示一个百分号，但原始数值所在单位不同；后者如要转无量纲须经过明确的单位换算，不能把显示规则套到存储值。

## 8. 数据无法独立提供的内容

- 完整作者列表、arXiv 编号、摘要、论文全文、完整 PDG reviews；当前引用 schema 没有这些独立字段。
- 每个历史版次的粒子目录、衰变结构、所有单项测量及纳入关系；历史值不能被包装成该年数据库全貌。
- 完整联合拟合输入组合、协方差矩阵、相关系数和可自动重做的 likelihood；used_in_fit 不提供这些信息。
- 所有衰变的完全解析末态、共轭组合约束、概率树或可直接用于事件发生器的级联表。
- 自动求和/归一化的互斥通道集合；子项可能交叠、有排除条件或是共振分量。
- 精确发现年份和全量变更历史；year_added 全空，changebar 只记录有限修订信号。

## 9. 官方参考

- [PDG 数据下载及 pdgall 说明](https://pdg.lbl.gov/2026/api/index.html)
- [SQLite schema 与关联说明](https://pdgapi.lbl.gov/doc/schema.html)
- [名称项与粒子接口](https://pdgapi.lbl.gov/doc/pdg.particle.html)
- [衰变及相关量接口](https://pdgapi.lbl.gov/doc/pdg.decay.html)
- [汇总显示及选择语义](https://pdgapi.lbl.gov/doc/pdg.data.html)
- [测量与多列接口](https://pdgapi.lbl.gov/doc/pdg.measurement.html)

数据来源：Particle Data Group，`pdgall-2026.0.sqlite`，CC BY 4.0。表结构、编码、数量和少量例项来自原始快照；中文说明与功能映射为本方案新增。具体引用以数据库 metadata 原文为准。
