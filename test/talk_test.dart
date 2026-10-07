import 'dart:io';

import 'package:duettalk/core/constants/iap_constants.dart';
import 'package:duettalk/core/services/hive_service.dart';
import 'package:duettalk/core/services/storage_service.dart';
import 'package:duettalk/models/talk.dart';
import 'package:duettalk/providers/shop_provider.dart';
import 'package:duettalk/providers/talk_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('dt_talk');
    await HiveService.init(path: dir.path, suffix: '_talk');
    await StorageService.instance.init();
  });

  setUp(() async {
    await HiveService.kv.clear();
  });

  test('a wiped chat is gone when the session ends, phrases stay', () async {
    final shop = ShopProvider();
    await shop.init(remote: false);
    final talk = TalkProvider(shop);
    await talk.init();
    expect(talk.wipeOnExit, isTrue);
    expect(talk.mode, TalkMode.face);

    await talk.beginSession();
    final line = await talk.send('a', 'Want a hot tea?');
    expect(line?.speaker, 'a');
    await talk.send('b', 'Yes');
    expect(talk.lines, hasLength(2));
    expect(talk.turn, 'a');
    expect(talk.savePhrase('Yes'), PhraseSave.added);

    await talk.finishSession();
    expect(talk.lines, isEmpty);
    expect(talk.phrases, hasLength(1));
  });

  test('saved phrases stop at the free limit', () async {
    final shop = ShopProvider();
    await shop.init(remote: false);
    final talk = TalkProvider(shop);
    await talk.init();
    for (var i = 0; i < IapConstants.freeArchiveLimit; i++) {
      expect(talk.savePhrase('Phrase $i'), PhraseSave.added);
    }
    expect(talk.savePhrase('One more'), PhraseSave.limit);
    expect(talk.savePhrase('Phrase 0'), PhraseSave.duplicate);
  });

  test('pass the phone alternates the turn', () async {
    final shop = ShopProvider();
    await shop.init(remote: false);
    final talk = TalkProvider(shop);
    await talk.init();
    await talk.setMode(TalkMode.pass);
    await talk.setWipeOnExit(false);
    await talk.beginSession();
    await talk.send('a', 'Hello');
    expect(talk.turn, 'b');
    await talk.send('b', 'Hi');
    expect(talk.turn, 'a');
    expect(talk.lastOf('b')?.text, 'Hi');
  });
}
