/// Aliases explicitly printed by the corresponding PDG listing.
///
/// The snapshot's `pdgid.description` is the current PDG name only. These
/// aliases are display/search aids and never replace the raw description.
/// Source: https://pdg.lbl.gov/2026/listings/rpp2026-list-chi-c1-3872.pdf
/// ("also known as X (3872)").
const Map<String, List<String>> pdgAliases = {
  'M176': ['X(3872)'],
};

List<String> aliasesForPdgid(String pdgid) =>
    pdgAliases[pdgid] ?? const <String>[];
