import 'package:flutter_test/flutter_test.dart';
import 'package:duettalk/core/constants/iap_constants.dart';
import 'package:duettalk/core/services/iap_config_service.dart';
import 'package:duettalk/models/shop_item.dart';

void main() {
  test('DuetTalk IAP ids and N305 endpoint', () {
    expect(IapConstants.productPrefix, 'dt');
    expect(IapConstants.remoteConfigUrl, 'https://api2.blwsmartware.net/N305.json');
    expect(IapConstants.coinPackIds.first, 'dt_pack_1');
    expect(IapConstants.coinPackIds.last, 'dt_pack_10');
    expect(IapConstants.coinPackIds, hasLength(10));
    expect(IapConstants.removeAdsProductId, 'dt_remove_ads');
    expect(IapConstants.proProductId, 'dt_pro');
    expect(IapConstants.allProductIds, containsAll([...IapConstants.coinPackIds, 'dt_remove_ads', 'dt_pro']));
    expect(IapConstants.coinsForProduct('dt_pack_5'), 500);
    expect(IapConstants.freeArchiveLimit, 8);
    expect(IapConstants.proArchiveLimit, 99);
  });

  test('disable=1 hides billing only', () {
    final off = IapRemoteConfig.fromJson({'disable': 1, 'name': 'DuetTalk'});
    expect(off.billingDisabled, isTrue);
    final on = IapRemoteConfig.fromJson({'disable': 0, 'name': 'DuetTalk', 'code': 'FULL_IAP'});
    expect(on.billingDisabled, isFalse);
    expect(on.name, 'DuetTalk');
  });

  test('shop catalog extras can be applied and reverted', () {
    expect(ShopCatalog.items.where((e) => e.id.startsWith('theme_')), isNotEmpty);
    expect(ShopCatalog.find(ShopCatalog.featPro), isNotNull);
    expect(ShopCatalog.find('remove_ads'), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featHint), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featSound), isNotNull);
    expect(ShopCatalog.isDefaultId(ShopCatalog.defaultThemeId), isTrue);
  });
}
