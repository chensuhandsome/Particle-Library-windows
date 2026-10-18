import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/domain/labels.dart';
import 'package:pdgapp/domain/models.dart';
import 'package:pdgapp/data/pdg_database.dart';
import 'package:pdgapp/features/catalog/catalog_groups.dart';

Entry entry(String description, String flags) => Entry({
  'id': description.hashCode,
  'pdgid': 'X',
  'description': description,
  'flags': flags,
  'data_type': 'PART',
});

CatalogGroupKind? kind(String description, String flags) =>
    catalogGroupFor(entry(description, flags))?.kind;

void main() {
  test('section headings are grouped as quarkonium', () {
    expect(kind('Bottomonium', 'M'), CatalogGroupKind.mesonBBbar);
    expect(kind('Charmonium', 'M'), CatalogGroupKind.mesonCCbar);
  });

  test('mesons follow the PDG Live summary-table groups', () {
    expect(kind('pi0', 'M'), CatalogGroupKind.mesonLight);
    expect(kind('b_1(1235)', 'M'), CatalogGroupKind.mesonLight);
    expect(kind('K^*(892)', 'M'), CatalogGroupKind.mesonStrange);
    expect(kind('D^*(2010)+-', 'M'), CatalogGroupKind.mesonCharmed);
    expect(kind('D_s3^*(2860)+-', 'M'), CatalogGroupKind.mesonCharmedStrange);
    expect(kind('B^+-', 'M'), CatalogGroupKind.mesonBottom);
    expect(kind('B_s^()0', 'M'), CatalogGroupKind.mesonBottomStrange);
    expect(kind('B_c()+', 'M'), CatalogGroupKind.mesonBottomCharmed);
    expect(kind('eta_c(1S)', 'M'), CatalogGroupKind.mesonCCbar);
    expect(kind('Upsilon(1S)', 'M'), CatalogGroupKind.mesonBBbar);
    expect(kind('X(2370)', 'M'), CatalogGroupKind.mesonOther);
  });

  test('baryons follow the PDG Live summary-table groups', () {
    expect(kind('N(1440)', 'B'), CatalogGroupKind.baryonN);
    expect(kind('Delta(1232)', 'B'), CatalogGroupKind.baryonDelta);
    expect(kind('Lambda(1405)', 'B'), CatalogGroupKind.baryonLambda);
    expect(kind('Sigma(1385)', 'B'), CatalogGroupKind.baryonSigma);
    expect(kind('Xi(1530)', 'B'), CatalogGroupKind.baryonXi);
    expect(kind('Omega-', 'B'), CatalogGroupKind.baryonOmega);
    expect(kind('Lambda_c()+', 'B'), CatalogGroupKind.baryonCharmed);
    expect(kind('Xi_cc()+', 'B'), CatalogGroupKind.baryonDoublyCharmed);
    expect(kind('Lambda_b()0', 'B'), CatalogGroupKind.baryonBottom);
  });

  test('topic-only roots are not classified as particles', () {
    final vcb = CatalogRoot(
      entry('V(cb) and V(ub) CKM Matrix Elements', 'M'),
      0,
      0,
    );
    final spectroscopy = CatalogRoot(
      entry('Heavy Quarkonium Spectroscopy', 'M'),
      0,
      0,
    );
    expect(catalogCategoryForRoot(vcb), ParticleCategory.unknown);
    expect(catalogCategoryForRoot(spectroscopy), ParticleCategory.unknown);
    expect(catalogGroupForRoot(vcb), isNull);
    expect(catalogGroupForRoot(spectroscopy), isNull);

    final pi0 = CatalogRoot(entry('pi0', 'M'), 1, 1);
    expect(catalogCategoryForRoot(pi0), ParticleCategory.meson);
    expect(catalogGroupForRoot(pi0)?.kind, CatalogGroupKind.mesonLight);
  });

  test('group lists are only exposed for mesons and baryons', () {
    expect(catalogGroups(ParticleCategory.meson).length, 10);
    expect(catalogGroups(ParticleCategory.baryon).length, 10);
    expect(catalogGroups(ParticleCategory.lepton), isEmpty);
  });
}
