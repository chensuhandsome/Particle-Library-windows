import '../../data/pdg_database.dart';
import '../../domain/labels.dart';
import '../../domain/models.dart';

/// Second-level catalog groups, following the PDG Live Summary Tables.
enum CatalogGroupKind {
  mesonLight,
  mesonStrange,
  mesonCharmed,
  mesonCharmedStrange,
  mesonBottom,
  mesonBottomStrange,
  mesonBottomCharmed,
  mesonCCbar,
  mesonBBbar,
  mesonOther,
  baryonN,
  baryonDelta,
  baryonLambda,
  baryonSigma,
  baryonXi,
  baryonOmega,
  baryonCharmed,
  baryonDoublyCharmed,
  baryonBottom,
  baryonOther,
}

class CatalogGroup {
  const CatalogGroup(this.kind, this.zh, this.en);

  final CatalogGroupKind kind;
  final String zh;
  final String en;

  String label(TextLang lang) => pick(lang, zh, en);
}

const _mesonGroups = <CatalogGroup>[
  CatalogGroup(CatalogGroupKind.mesonLight, '轻无味介子', 'Light unflavored'),
  CatalogGroup(CatalogGroupKind.mesonStrange, '奇异介子', 'Strange'),
  CatalogGroup(CatalogGroupKind.mesonCharmed, '粲介子', 'Charmed'),
  CatalogGroup(
    CatalogGroupKind.mesonCharmedStrange,
    '粲奇异介子',
    'Charmed, strange',
  ),
  CatalogGroup(CatalogGroupKind.mesonBottom, '底介子', 'Bottom'),
  CatalogGroup(CatalogGroupKind.mesonBottomStrange, '底奇异介子', 'Bottom, strange'),
  CatalogGroup(CatalogGroupKind.mesonBottomCharmed, '底粲介子', 'Bottom, charmed'),
  CatalogGroup(
    CatalogGroupKind.mesonCCbar,
    'c cbar（粲偶素）',
    'c cbar (charmonium)',
  ),
  CatalogGroup(
    CatalogGroupKind.mesonBBbar,
    'b bbar（底偶素）',
    'b bbar (bottomonium)',
  ),
  CatalogGroup(CatalogGroupKind.mesonOther, '其他介子', 'Other mesons'),
];

const _baryonGroups = <CatalogGroup>[
  CatalogGroup(CatalogGroupKind.baryonN, 'N', 'N'),
  CatalogGroup(CatalogGroupKind.baryonDelta, 'Δ', 'Delta'),
  CatalogGroup(CatalogGroupKind.baryonLambda, 'Λ', 'Lambda'),
  CatalogGroup(CatalogGroupKind.baryonSigma, 'Σ', 'Sigma'),
  CatalogGroup(CatalogGroupKind.baryonXi, 'Ξ', 'Xi'),
  CatalogGroup(CatalogGroupKind.baryonOmega, 'Ω', 'Omega'),
  CatalogGroup(CatalogGroupKind.baryonCharmed, '粲重子', 'Charmed'),
  CatalogGroup(CatalogGroupKind.baryonDoublyCharmed, '双粲重子', 'Doubly charmed'),
  CatalogGroup(CatalogGroupKind.baryonBottom, '底重子', 'Bottom'),
  CatalogGroup(CatalogGroupKind.baryonOther, '其他重子', 'Other baryons'),
];

List<CatalogGroup> catalogGroups(ParticleCategory category) =>
    switch (category) {
      ParticleCategory.meson => _mesonGroups,
      ParticleCategory.baryon => _baryonGroups,
      _ => const [],
    };

CatalogGroup? catalogGroupFor(Entry entry) {
  final category = categoryFromFlags(entry.flags)?.category;
  final desc = entry.description.trim();
  if (category == ParticleCategory.meson) {
    return _mesonGroup(desc);
  }
  if (category == ParticleCategory.baryon) {
    return _baryonGroup(desc);
  }
  return null;
}

CatalogGroup? _mesonGroup(String desc) {
  // Section headings are not particle names; match them before prefixes.
  if (desc == 'Charmonium') {
    return _group(CatalogGroupKind.mesonCCbar);
  }
  if (desc == 'Bottomonium') {
    return _group(CatalogGroupKind.mesonBBbar);
  }
  // Heavy-flavour subscripts precede the simpler D/B/K prefixes.
  if (desc.startsWith('D_s') || desc.startsWith('D_{s')) {
    return _group(CatalogGroupKind.mesonCharmedStrange);
  }
  if (desc.startsWith('D')) {
    return _group(CatalogGroupKind.mesonCharmed);
  }
  if (desc.startsWith('B_s') || desc.startsWith('B_{s')) {
    return _group(CatalogGroupKind.mesonBottomStrange);
  }
  if (desc.startsWith('B_c') || desc.startsWith('B_{c')) {
    return _group(CatalogGroupKind.mesonBottomCharmed);
  }
  if (desc.startsWith('B')) return _group(CatalogGroupKind.mesonBottom);
  if (desc.startsWith('K')) return _group(CatalogGroupKind.mesonStrange);

  if (desc.startsWith('eta_c') ||
      desc.startsWith('J/psi') ||
      desc.startsWith('psi') ||
      desc.startsWith('chi_c') ||
      desc.startsWith('h_c') ||
      desc.startsWith("psi'")) {
    return _group(CatalogGroupKind.mesonCCbar);
  }
  if (desc.startsWith('Upsilon') ||
      desc.startsWith('eta_b') ||
      desc.startsWith('chi_b') ||
      desc.startsWith('h_b')) {
    return _group(CatalogGroupKind.mesonBBbar);
  }
  if (desc.contains("psi's and chi's")) {
    return _group(CatalogGroupKind.mesonCCbar);
  }
  if (desc.toLowerCase().contains('b-flavored')) {
    return _group(CatalogGroupKind.mesonBottom);
  }

  const lightPrefixes = [
    'pi',
    'eta',
    'rho',
    'omega',
    'phi',
    'f_',
    'f(',
    'a_',
    'a(',
    'h_',
    'h(',
    'b_',
    'b(',
    'pi_',
    'eta_',
    'omega_',
    'rho_',
  ];
  if (lightPrefixes.any(desc.startsWith)) {
    return _group(CatalogGroupKind.mesonLight);
  }
  return _group(CatalogGroupKind.mesonOther);
}

CatalogGroup? _baryonGroup(String desc) {
  // Multi-heavy-flavour labels first.
  if (desc.startsWith('Xi_cc') || desc.startsWith('Xi_{cc')) {
    return _group(CatalogGroupKind.baryonDoublyCharmed);
  }
  if (desc.startsWith('Lambda_c') ||
      desc.startsWith('Sigma_c') ||
      desc.startsWith('Xi_c') ||
      desc.startsWith('Omega_c')) {
    return _group(CatalogGroupKind.baryonCharmed);
  }
  if (desc.startsWith('Lambda_b') ||
      desc.startsWith('Sigma_b') ||
      desc.startsWith('Xi_b') ||
      desc.startsWith('Omega_b')) {
    return _group(CatalogGroupKind.baryonBottom);
  }
  if (desc.startsWith('N')) return _group(CatalogGroupKind.baryonN);
  if (desc.startsWith('Delta')) return _group(CatalogGroupKind.baryonDelta);
  if (desc.startsWith('Lambda')) return _group(CatalogGroupKind.baryonLambda);
  if (desc.startsWith('Sigma')) return _group(CatalogGroupKind.baryonSigma);
  if (desc.startsWith('Xi')) return _group(CatalogGroupKind.baryonXi);
  if (desc.startsWith('Omega')) return _group(CatalogGroupKind.baryonOmega);
  return _group(CatalogGroupKind.baryonOther);
}

CatalogGroup _group(CatalogGroupKind kind) {
  for (final group in [..._mesonGroups, ..._baryonGroups]) {
    if (group.kind == kind) return group;
  }
  throw StateError('unknown catalog group $kind');
}

/// Topic/section roots have no particle identity row. PDG's flag column can
/// still say `M` (e.g. "V(cb) and V(ub) CKM Matrix Elements"), so particle
/// category membership requires an actual particle row.
ParticleCategory catalogCategoryForRoot(CatalogRoot root) {
  if (root.particleCount == 0) return ParticleCategory.unknown;
  return categoryFromFlags(root.entry.flags)?.category ??
      ParticleCategory.unknown;
}

CatalogGroup? catalogGroupForRoot(CatalogRoot root) {
  if (root.particleCount == 0) return null;
  return catalogGroupFor(root.entry);
}
