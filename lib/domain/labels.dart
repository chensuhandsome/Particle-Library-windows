/// Human-readable, bilingual interpretations of PDG codes.
///
/// Unknown codes are never silently mapped to a plausible physical meaning:
/// callers receive an explicit "uninterpreted" label while the raw code stays
/// visible in the source-record inspector.
library;

enum TextLang { zh, en }

String pick(TextLang lang, String zh, String en) => lang == TextLang.zh ? zh : en;

enum PropertyGroup {
  particle,
  mass,
  width,
  lifetime,
  branching,
  electromagnetic,
  cp,
  formFactor,
  coupling,
  section,
  search,
  other,
  unclassified,
}

class DataTypeInfo {
  const DataTypeInfo({
    required this.code,
    required this.zh,
    required this.en,
    required this.group,
    this.official,
  });

  final String code;
  final String zh;
  final String en;
  final PropertyGroup group;
  final String? official;

  String label(TextLang lang) => pick(lang, zh, en);
}

const Map<String, DataTypeInfo> dataTypes = {
  'PART': DataTypeInfo(
      code: 'PART', zh: '粒子', en: 'Particle', group: PropertyGroup.particle),
  'M': DataTypeInfo(
      code: 'M', zh: '质量', en: 'Mass', group: PropertyGroup.mass, official: 'mass'),
  'D': DataTypeInfo(
      code: 'D',
      zh: '质量差',
      en: 'Mass difference',
      group: PropertyGroup.mass,
      official: 'mass difference'),
  'G': DataTypeInfo(
      code: 'G',
      zh: '总宽度',
      en: 'Full width',
      group: PropertyGroup.width,
      official: 'full width'),
  'T': DataTypeInfo(
      code: 'T',
      zh: '寿命',
      en: 'Lifetime',
      group: PropertyGroup.lifetime,
      official: 'lifetime'),
  'g': DataTypeInfo(
      code: 'g',
      zh: '平均寿命',
      en: 'Mean life',
      group: PropertyGroup.lifetime,
      official: 'mean life (specific case for Sigma, Sigma-)'),
  'BR': DataTypeInfo(
      code: 'BR',
      zh: '分支比',
      en: 'Branching ratio',
      group: PropertyGroup.branching,
      official: 'branching ratio'),
  'BFX': DataTypeInfo(
      code: 'BFX',
      zh: '遍举分支分数',
      en: 'Exclusive branching fraction',
      group: PropertyGroup.branching,
      official: 'exclusive branching fraction'),
  'BFX1': DataTypeInfo(
      code: 'BFX1',
      zh: '遍举分支分数（缩进 1）',
      en: 'Exclusive branching fraction (indent 1)',
      group: PropertyGroup.branching,
      official: 'exclusive branching fraction with indentation 1'),
  'BFX2': DataTypeInfo(
      code: 'BFX2',
      zh: '遍举分支分数（缩进 2）',
      en: 'Exclusive branching fraction (indent 2)',
      group: PropertyGroup.branching,
      official: 'exclusive branching fraction with indentation 2'),
  'BFX3': DataTypeInfo(
      code: 'BFX3',
      zh: '遍举分支分数（缩进 3）',
      en: 'Exclusive branching fraction (indent 3)',
      group: PropertyGroup.branching,
      official: 'exclusive branching fraction with indentation 3'),
  'BFX4': DataTypeInfo(
      code: 'BFX4',
      zh: '遍举分支分数（缩进 4）',
      en: 'Exclusive branching fraction (indent 4)',
      group: PropertyGroup.branching,
      official: 'exclusive branching fraction with indentation 4'),
  'BFX5': DataTypeInfo(
      code: 'BFX5',
      zh: '遍举分支分数（缩进 5）',
      en: 'Exclusive branching fraction (indent 5)',
      group: PropertyGroup.branching,
      official: 'exclusive branching fraction with indentation 5'),
  'BFI': DataTypeInfo(
      code: 'BFI',
      zh: '单举分支分数',
      en: 'Inclusive branching fraction',
      group: PropertyGroup.branching,
      official: 'inclusive branching fraction'),
  'BFI1': DataTypeInfo(
      code: 'BFI1',
      zh: '单举分支分数（缩进 1）',
      en: 'Inclusive branching fraction (indent 1)',
      group: PropertyGroup.branching,
      official: 'inclusive branching fraction with indentation 1'),
  'BFI2': DataTypeInfo(
      code: 'BFI2',
      zh: '单举分支分数（缩进 2）',
      en: 'Inclusive branching fraction (indent 2)',
      group: PropertyGroup.branching,
      official: 'inclusive branching fraction with indentation 2'),
  'e': DataTypeInfo(
      code: 'e',
      zh: '电偶极矩',
      en: 'Electric dipole moment',
      group: PropertyGroup.electromagnetic,
      official: 'electric dipole moment'),
  'm': DataTypeInfo(
      code: 'm',
      zh: '磁矩',
      en: 'Magnetic moment',
      group: PropertyGroup.electromagnetic,
      official: 'magnetic moment'),
  'v': DataTypeInfo(
      code: 'v',
      zh: 'CP 破坏参数',
      en: 'CP-violation parameter',
      group: PropertyGroup.cp,
      official: 'CP-violation parameter'),
  'f': DataTypeInfo(
      code: 'f',
      zh: '形状因子',
      en: 'Form factor',
      group: PropertyGroup.formFactor,
      official: 'form factor'),
  's': DataTypeInfo(
      code: 's',
      zh: '斜率参数',
      en: 'Slope parameter',
      group: PropertyGroup.formFactor,
      official: 'slope parameter'),
  'c': DataTypeInfo(
      code: 'c',
      zh: '耦合常数比',
      en: 'Coupling constant ratio',
      group: PropertyGroup.coupling,
      official: 'coupling constant ratio'),
  'd': DataTypeInfo(
      code: 'd',
      zh: '衰变参数',
      en: 'Decay parameter',
      group: PropertyGroup.coupling,
      official: 'decay parameter'),
  'SEC': DataTypeInfo(
      code: 'SEC',
      zh: '章节',
      en: 'Section',
      group: PropertyGroup.section,
      official: 'section heading'),
  'SRCH': DataTypeInfo(
      code: 'SRCH',
      zh: '搜索专题',
      en: 'Searches',
      group: PropertyGroup.search,
      official: 'searches'),
  '': DataTypeInfo(
      code: '',
      zh: '未分类条目',
      en: 'Unclassified entry',
      group: PropertyGroup.unclassified,
      official: 'no data_type in the snapshot'),
};

DataTypeInfo dataTypeInfo(String code) =>
    dataTypes[code] ??
    DataTypeInfo(
      code: code,
      zh: '未解释类型「$code」',
      en: 'Uninterpreted type "$code"',
      group: PropertyGroup.other,
    );

PropertyGroup propertyGroupOf(String dataType) => dataTypeInfo(dataType).group;

bool isDecayType(String dataType) =>
    dataType.startsWith('BFX') || dataType.startsWith('BFI');

bool isBranchingRatioType(String dataType) => dataType == 'BR';

bool isParticleType(String dataType) => dataType == 'PART';

bool isSectionType(String dataType) => dataType == 'SEC';

bool isSearchType(String dataType) => dataType == 'SRCH';

String propertyGroupLabel(PropertyGroup group, TextLang lang) => switch (group) {
      PropertyGroup.particle => pick(lang, '粒子', 'Particle'),
      PropertyGroup.mass => pick(lang, '质量与质量差', 'Mass & mass differences'),
      PropertyGroup.width => pick(lang, '宽度', 'Widths'),
      PropertyGroup.lifetime => pick(lang, '寿命', 'Lifetimes'),
      PropertyGroup.branching => pick(lang, '分支分数与分支比', 'Branching fractions & ratios'),
      PropertyGroup.electromagnetic =>
        pick(lang, '电磁性质', 'Electromagnetic properties'),
      PropertyGroup.cp => pick(lang, 'CP 与混合参数', 'CP & mixing parameters'),
      PropertyGroup.formFactor => pick(lang, '形状因子与斜率', 'Form factors & slopes'),
      PropertyGroup.coupling => pick(lang, '耦合与衰变参数', 'Couplings & decay parameters'),
      PropertyGroup.section => pick(lang, '章节标题', 'Section headings'),
      PropertyGroup.search => pick(lang, '搜索专题', 'Searches'),
      PropertyGroup.other => pick(lang, '其他性质', 'Other properties'),
      PropertyGroup.unclassified => pick(lang, '未分类条目', 'Unclassified entries'),
    };

enum ParticleCategory { gaugeHiggs, lepton, quark, meson, baryon, search, unknown }

class CategoryInfo {
  const CategoryInfo(this.category, this.zh, this.en, this.letter);

  final ParticleCategory category;
  final String zh;
  final String en;
  final String letter;

  String label(TextLang lang) => pick(lang, zh, en);
}

const List<CategoryInfo> particleCategories = [
  CategoryInfo(ParticleCategory.gaugeHiggs, '规范与 Higgs 玻色子', 'Gauge & Higgs bosons', 'G'),
  CategoryInfo(ParticleCategory.lepton, '轻子', 'Leptons', 'L'),
  CategoryInfo(ParticleCategory.quark, '夸克', 'Quarks', 'Q'),
  CategoryInfo(ParticleCategory.meson, '介子', 'Mesons', 'M'),
  CategoryInfo(ParticleCategory.baryon, '重子', 'Baryons', 'B'),
  CategoryInfo(ParticleCategory.search, '搜索', 'Searches', 'S'),
];

CategoryInfo? categoryFromFlags(String flags) {
  for (final info in particleCategories) {
    if (flags.contains(info.letter)) return info;
  }
  return null;
}

/// The category letters are the first documented role of `pdgid.flags`; the
/// remaining characters (`A`, `D`, charge symbols, `s`) are decoded separately.
List<String> decodeFlagRoles(String flags) {
  final roles = <String>[];
  final seen = <String>{};
  for (final char in flags.split('')) {
    final role = switch (char) {
      'G' => 'Gauge/Higgs boson category',
      'L' => 'Lepton category',
      'Q' => 'Quark category',
      'M' => 'Meson category',
      'B' => 'Baryon category',
      'S' => 'Searches category',
      'A' => 'Alternative entry',
      'D' => 'Default value',
      '0' => 'Neutral charge flag',
      '1' => 'Singly charged flag',
      '2' => 'Doubly charged flag',
      '+' => 'Positive charge flag',
      '-' => 'Negative charge flag',
      's' => 'Special case (see PDG identifier description)',
      _ => 'Uninterpreted flag "$char"',
    };
    if (seen.add(role)) roles.add(role);
  }
  return roles;
}

/// Localized decoding of the documented flag characters. Unknown characters
/// stay visible instead of being given a physical meaning.
/// PDG's `technique` column mixes experiment abbreviations with method codes.
/// Only well-established experiment spellings are expanded; method codes stay
/// raw rather than being presented as collaborations.
const Map<String, String> _experimentTechniques = {
  'BABR': 'BaBar',
  'BELL': 'Belle',
  'BEL2': 'Belle II',
  'BES': 'BES',
  'BES2': 'BES II',
  'BES3': 'BES III',
  'CLEO': 'CLEO',
  'CLE2': 'CLEO II',
  'CLE3': 'CLEO III',
  'ALEP': 'ALEPH',
  'DLPH': 'DELPHI',
  'LHCB': 'LHCb',
  'ATLS': 'ATLAS',
  'CMS': 'CMS',
  'CDF': 'CDF',
  'D0': 'D0',
  'L3': 'L3',
  'OPAL': 'OPAL',
  'SLD': 'SLD',
  'ARG': 'ARGUS',
  'MRK1': 'Mark I',
  'MRK2': 'Mark II',
  'MRK3': 'Mark III',
  'CBAL': 'Crystal Ball',
  'KLOE': 'KLOE',
  'KTEV': 'KTeV',
  'NA48': 'NA48',
  'SND': 'SND',
  'OMEG': 'OMEGA',
  'H1': 'H1',
  'ZEUS': 'ZEUS',
  'UA1': 'UA1',
  'UA2': 'UA2',
};

String techniqueFullName(String technique) =>
    _experimentTechniques[technique.trim()] ?? technique;

bool techniqueIsExpanded(String technique) {
  final full = techniqueFullName(technique);
  return full != technique;
}

String decodedFlags(String flags, TextLang lang, {bool includeCategory = false}) {
  if (flags.isEmpty) return '';
  final parts = <String>[];
  for (final char in flags.split('')) {
    final label = switch (char) {
      'G' || 'L' || 'Q' || 'M' || 'B' || 'S' => includeCategory
          ? pick(lang, '分类标记', 'category flag')
          : '',
      'A' => pick(lang, '备选条目', 'alternative entry'),
      'D' => pick(lang, '默认值', 'default value'),
      '0' => pick(lang, '中性', 'neutral'),
      '1' => pick(lang, '单电荷', 'singly charged'),
      '2' => pick(lang, '双电荷', 'doubly charged'),
      '+' => pick(lang, '正电荷', 'positive charge'),
      '-' => pick(lang, '负电荷', 'negative charge'),
      's' => pick(lang, '特殊条目', 'special case'),
      _ => pick(lang, '未解释「$char」', 'uninterpreted "$char"'),
    };
    if (label.isNotEmpty && !parts.contains(label)) parts.add(label);
  }
  return parts.join(' · ');
}

const Map<String, ({String zh, String en, String indicator})> valueTypes = {
  'AC': (zh: 'PDG 加权平均', en: 'PDG weighted average', indicator: 'OUR AVERAGE'),
  'FC': (zh: 'PDG 拟合', en: 'PDG fit', indicator: 'OUR FIT'),
  'D': (zh: '由另一模式分支比得到的平均', en: 'Average from another mode', indicator: 'OUR AVERAGE'),
  'V': (zh: '由相关量测量得到的评估', en: 'Evaluation from related measurements', indicator: 'OUR EVALUATION'),
  'L': (zh: '最佳限值', en: 'Best limit', indicator: 'BEST LIMIT'),
  'OL': (zh: 'PDG 评估限值', en: 'PDG evaluated limit', indicator: 'OUR LIMIT'),
  'E': (zh: 'PDG 估计', en: 'PDG estimate', indicator: 'OUR ESTIMATE'),
  'DR': (zh: '拟合衰变率', en: 'Fitted decay rate', indicator: 'OUR FIT'),
  'OM': (zh: '汇总下方的附加记录', en: 'Extra entry below summary', indicator: ''),
  'ON': (zh: '汇总上方的附加记录', en: 'Extra entry above summary', indicator: ''),
  'O': (zh: 'PDG 评估（无默认说明）', en: 'PDG evaluation (no default description)', indicator: ''),
  'DV': (zh: '内部保留评估', en: 'Reserved internal evaluation', indicator: 'OUR EVALUATION'),
};

String valueTypeLabel(String code, TextLang lang) {
  final info = valueTypes[code];
  if (info == null) {
    return pick(lang, '未解释取得方式「$code」', 'Uninterpreted value type "$code"');
  }
  return pick(lang, info.zh, info.en);
}

String? valueTypeIndicator(String code) => valueTypes[code]?.indicator;

String limitTypeLabel(String? code, TextLang lang) => switch (code) {
      null || '' => pick(lang, '测量值', 'Measured value'),
      'U' => pick(lang, '上限', 'Upper limit'),
      'L' => pick(lang, '下限', 'Lower limit'),
      'R' => pick(lang, '区间', 'Range'),
      'X' => pick(lang, '排除区间', 'Range exclusion'),
      _ => pick(lang, '未解释结果类型「$code」', 'Uninterpreted result type "$code"'),
    };

String itemTypeLabel(String code, TextLang lang) => switch (code) {
      'P' => pick(lang, '具体电荷粒子', 'Particle with specific charge'),
      'A' => pick(lang, '又称', '"also known as" alias'),
      'W' => pick(lang, '旧称', '"was" alias'),
      'S' => pick(lang, '快捷写法', 'Shortcut'),
      'B' => pick(lang, '两种电荷', 'Both charges (e.g. +-)'),
      'C' => pick(lang, 'B 项的共轭', 'Conjugate of a B entry'),
      'G' => pick(lang, '通用粒子名', 'Generic particle name'),
      'L' => pick(lang, '粒子列表', 'Specific list of particles'),
      'I' => pick(lang, '任意/单举项', '"anything" (inclusive)'),
      'T' => pick(lang, '文本', 'Text'),
      _ => pick(lang, '未解释名称项类型「$code」', 'Uninterpreted item type "$code"'),
    };

String ccTypeLabel(String? code, TextLang lang) => switch (code) {
      'P' => pick(lang, '粒子态', 'Particle state'),
      'A' => pick(lang, '反粒子态', 'Antiparticle state'),
      'S' => pick(lang, '自共轭态', 'Self-conjugate state'),
      null || '' => pick(lang, '未注明', 'Not stated'),
      _ => pick(lang, '未解释共轭类型「$code」', 'Uninterpreted conjugation type "$code"'),
    };

String textTypeLabel(String type, TextLang lang) => switch (type) {
      'h' => pick(lang, '标题/说明', 'Heading / explanatory text'),
      't' => pick(lang, '正文段落', 'Body text'),
      _ => pick(lang, '未解释文本类型「$type」', 'Uninterpreted text type "$type"'),
    };

String chargeText(double? charge) {
  if (charge == null) return '—';
  if (charge == 0) return '0';
  final thirds = (charge * 3).round();
  if ((charge * 3 - thirds).abs() < 1e-6) {
    final reduced = _reduceThirds(thirds);
    if (reduced.$2 == 1) return '${reduced.$1}';
    return '${reduced.$1}/${reduced.$2}';
  }
  final fixed = charge.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

(int, int) _reduceThirds(int numeratorOverThree) {
  var numerator = numeratorOverThree.abs();
  var denominator = 3;
  final divisor = numerator % 3 == 0 ? 3 : (numerator % 2 == 0 && denominator == 2 ? 2 : 1);
  numerator ~/= divisor;
  denominator ~/= divisor;
  return (numeratorOverThree < 0 ? -numerator : numerator, denominator);
}

String chargeWithUnit(double? charge) =>
    charge == null ? '—' : '${chargeText(charge)} e';

String quantumLabel(String field, TextLang lang) => switch (field) {
      'I' => pick(lang, '同位旋 I', 'Isospin I'),
      'G' => pick(lang, 'G 宇称', 'G parity'),
      'J' => pick(lang, '自旋 J', 'Spin J'),
      'P' => pick(lang, '宇称 P', 'Parity P'),
      'C' => pick(lang, 'C 宇称', 'C parity'),
      _ => field,
    };

/// Publication citation in the snapshot contains light HTML italics; the raw
/// string is preserved in the record inspector, this is only a display aid.
String plainCitation(String? citation) {
  if (citation == null) return '';
  return citation
      .replaceAll('<i>', '')
      .replaceAll('</i>', '')
      .replaceAll('<b>', '')
      .replaceAll('</b>', '')
      .replaceAll('<sub>', '')
      .replaceAll('</sub>', '');
}
