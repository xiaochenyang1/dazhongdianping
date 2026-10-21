import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/shop_detail_screen.dart';
import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:dazhongdianping_app/features/community/post_commerce_picker_screen.dart';
import 'package:dazhongdianping_app/features/community/post_detail_screen.dart';
import 'package:dazhongdianping_app/features/community/post_editor_screen.dart';
import 'package:dazhongdianping_app/features/trade/deal_detail_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _shop = <String, dynamic>{
  'id': 20001,
  'name': 'Maison Sichuan Paris',
  'currency': 'EUR',
  'address': 'Paris',
};
const _otherShop = <String, dynamic>{
  'id': 20002,
  'name': 'Mitte Bread & Brew',
  'currency': 'EUR',
  'address': 'Berlin',
};
const _deal = <String, dynamic>{
  'id': 41001,
  'shopId': 20001,
  'title': 'Sichuan Dinner for Two',
  'price': 32,
  'currency': 'EUR',
  'rules': 'Book one day ahead',
};

Map<String, dynamic> _page(
  List<Map<String, dynamic>> items, {
  int page = 1,
  int? total,
}) => {
  'list': items,
  'page': page,
  'pageSize': 20,
  'total': total ?? items.length,
};

class _CommerceApi implements JsonApi, JsonMutationApi {
  final paths = <String>[];
  final searches = <Map<String, Object?>>[];
  final saves = <Map<String, dynamic>>[];
  Map<String, dynamic> overrides = {};
  Future<Map<String, dynamic>> Function(Map<String, Object?> query)? onSearch;
  bool failDeals = false;
  bool failOwnedPost = false;

  Map<String, dynamic> get post => {
    'id': 7,
    'userId': 9,
    'userName': 'Lin',
    'title': 'A Paris evening',
    'content': 'Dinner with friends.',
    'shopId': 20001,
    'dealId': 41001,
    'circleId': 33,
    'linkedShop': {..._shop, 'available': true},
    'linkedDeal': {..._deal, 'available': true},
    'images': <String>[],
    'topics': <String>[],
    ...overrides,
  };

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    paths.add(path);
    if (path == '/api/c/v1/search/shops') {
      searches.add(Map.of(query!));
      return onSearch == null ? _page([_shop, _otherShop]) : onSearch!(query);
    }
    if (path == '/api/c/v1/user/posts/7' && failOwnedPost) {
      throw const ApiException('temporarily unavailable');
    }
    if (path == '/api/c/v1/posts/7' || path == '/api/c/v1/user/posts/7') {
      return post;
    }
    if (path == '/api/c/v1/shops/20001') return _shop;
    if (path == '/api/c/v1/deals/41001') return _deal;
    if (path == '/api/c/v1/shops/20001/deals') {
      if (failDeals) {
        failDeals = false;
        throw const ApiException('temporarily unavailable');
      }
      return {
        'value': [
          _deal,
          {
            ..._deal,
            'id': 41002,
            'shopId': 20002,
            'title': 'Another place deal',
          },
        ],
      };
    }
    if (path.endsWith('/amenities')) return {};
    if (path.endsWith('/comments') ||
        path.endsWith('/similar') ||
        path.endsWith('/reviews') ||
        path.endsWith('/questions')) {
      return _page([]);
    }
    throw StateError('Unexpected GET: $path');
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    paths.add(path);
    if (path.endsWith('/like')) return {'liked': true, 'likeCount': 1};
    if (path == '/api/c/v1/posts') {
      saves.add(Map<String, dynamic>.from(body! as Map));
      return {...post, ...saves.last};
    }
    throw StateError('Unexpected POST: $path');
  }

  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    paths.add(path);
    if (path != '/api/c/v1/posts/7') throw StateError('Unexpected PUT: $path');
    saves.add(Map<String, dynamic>.from(body! as Map));
    return {...post, ...saves.last};
  }
}

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.binding.setSurfaceSize(const Size(900, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: screen,
    ),
  );
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('public post links open the associated shop and deal details', (
    tester,
  ) async {
    final api = _CommerceApi();
    await _pump(
      tester,
      PostDetailScreen(
        repository: CommunityRepository(api),
        postId: 7,
        canInteract: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Places and deals in this post'), findsOneWidget);
    expect(find.textContaining('32.00'), findsOneWidget);
    await _tap(tester, 'post-shop-link');
    final shop = tester.widget<ShopDetailScreen>(find.byType(ShopDetailScreen));
    expect(shop.shopId, 20001);
    expect(shop.enableFavorite, isFalse);
    expect(shop.canInteractReviews, isFalse);
    expect(api.paths, contains('/api/c/v1/shops/20001'));
    expect(find.text('Maison Sichuan Paris'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _tap(tester, 'post-deal-link');
    expect(
      tester.widget<DealDetailScreen>(find.byType(DealDetailScreen)).dealId,
      41001,
    );
    expect(api.paths, contains('/api/c/v1/deals/41001'));
    expect(find.text('Book one day ahead'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final state in ['unavailable', 'missing', 'mismatched']) {
    testWidgets('post hides $state commerce details and disables their links', (
      tester,
    ) async {
      final api = _CommerceApi()
        ..overrides = {
          'linkedShop': state == 'missing'
              ? null
              : {
                  ..._shop,
                  'id': state == 'mismatched' ? 9 : 20001,
                  'available': state != 'unavailable',
                },
          'linkedDeal': state == 'missing'
              ? null
              : {
                  ..._deal,
                  'id': state == 'mismatched' ? 9 : 41001,
                  'available': state != 'unavailable',
                },
        };
      await _pump(
        tester,
        PostDetailScreen(
          repository: CommunityRepository(api),
          postId: 7,
          canInteract: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dinner with friends.'), findsOneWidget);
      expect(find.text('Maison Sichuan Paris'), findsNothing);
      expect(find.text('Sichuan Dinner for Two'), findsNothing);
      expect(find.textContaining('32.00'), findsNothing);
      expect(find.text('This place is no longer available'), findsOneWidget);
      expect(find.text('This deal is no longer available'), findsOneWidget);
      expect(
        tester.widget<ListTile>(find.byKey(const Key('post-shop-link'))).onTap,
        isNull,
      );
      expect(
        tester.widget<ListTile>(find.byKey(const Key('post-deal-link'))).onTap,
        isNull,
      );
      expect(
        api.paths.where(
          (path) => path.contains('/shops/') || path.contains('/deals/'),
        ),
        isEmpty,
      );
    });
  }

  testWidgets('liking a post retains its commerce previews', (tester) async {
    final api = _CommerceApi();
    await _pump(
      tester,
      PostDetailScreen(
        repository: CommunityRepository(api),
        postId: 7,
        canInteract: true,
      ),
    );
    await tester.pumpAndSettle();
    await _tap(tester, 'post-like-button');
    expect(find.text('Maison Sichuan Paris'), findsOneWidget);
    expect(find.text('Sichuan Dinner for Two'), findsOneWidget);
    expect(
      tester.widget<ListTile>(find.byKey(const Key('post-deal-link'))).onTap,
      isNotNull,
    );
  });

  testWidgets(
    'editing content retains unavailable associations and the original circle',
    (tester) async {
      final api = _CommerceApi()
        ..overrides = {
          'linkedShop': {'id': 20001, 'available': false},
          'linkedDeal': {'id': 41001, 'available': false},
        };
      await _pump(
        tester,
        PostEditorScreen(repository: CommunityRepository(api), postId: 7),
      );
      await tester.pumpAndSettle();
      expect(find.text('This place is no longer available'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('post-content')),
        'Updated dinner notes.',
      );
      await _tap(tester, 'post-submit');
      expect(api.saves.single, containsPair('shopId', 20001));
      expect(api.saves.single, containsPair('dealId', 41001));
      expect(api.saves.single, containsPair('circleId', 33));
      expect(
        api.saves.single,
        containsPair('content', 'Updated dinner notes.'),
      );
    },
  );

  for (final removeShop in [true, false]) {
    testWidgets(
      'removing the ${removeShop ? 'place clears both associations' : 'deal retains the place'}',
      (tester) async {
        final api = _CommerceApi();
        await _pump(
          tester,
          PostEditorScreen(repository: CommunityRepository(api), postId: 7),
        );
        await tester.pumpAndSettle();
        await _tap(
          tester,
          removeShop ? 'post-remove-shop' : 'post-remove-deal',
        );
        await _tap(tester, 'post-submit');
        expect(api.saves.single['shopId'], removeShop ? isNull : 20001);
        expect(api.saves.single['dealId'], isNull);
        expect(api.saves.single['circleId'], 33);
      },
    );
  }

  testWidgets(
    'a new post can choose a place and one of its deals before saving',
    (tester) async {
      final api = _CommerceApi();
      await _pump(
        tester,
        PostEditorScreen(repository: CommunityRepository(api), circleId: 33),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ListTile>(find.byKey(const Key('post-choose-deal')))
            .onTap,
        isNull,
      );
      await tester.enterText(
        find.byKey(const Key('post-title')),
        'Paris dinner',
      );
      await tester.enterText(
        find.byKey(const Key('post-content')),
        'A good evening.',
      );
      final chooseShop = tester
          .widget<ListTile>(find.byKey(const Key('post-choose-shop')))
          .onTap!;
      chooseShop();
      chooseShop();
      await tester.pumpAndSettle();
      expect(find.byType(PostShopPickerScreen), findsOneWidget);
      expect(api.searches, hasLength(1));
      await _tap(tester, 'post-shop-choice-20001');
      await _tap(tester, 'post-choose-deal');
      expect(find.text('Another place deal'), findsNothing);
      await _tap(tester, 'post-deal-choice-41001');
      await _tap(tester, 'post-submit');
      expect(api.saves.single['shopId'], 20001);
      expect(api.saves.single['dealId'], 41001);
      expect(api.saves.single['circleId'], 33);
    },
  );

  testWidgets('changing the place clears a previously selected deal', (
    tester,
  ) async {
    final api = _CommerceApi();
    await _pump(
      tester,
      PostEditorScreen(repository: CommunityRepository(api), postId: 7),
    );
    await tester.pumpAndSettle();
    await _tap(tester, 'post-choose-shop');
    await _tap(tester, 'post-shop-choice-20002');
    expect(find.text('Sichuan Dinner for Two'), findsNothing);
    await _tap(tester, 'post-submit');
    expect(api.saves.single['shopId'], 20002);
    expect(api.saves.single['dealId'], isNull);
  });

  testWidgets('scrolling to submit still validates the entire post form', (
    tester,
  ) async {
    final api = _CommerceApi();
    await _pump(tester, PostEditorScreen(repository: CommunityRepository(api)));
    await tester.binding.setSurfaceSize(const Size(400, 650));
    await tester.pumpAndSettle();
    await _tap(tester, 'post-submit');
    expect(api.saves, isEmpty);
    final form = tester.state<FormState>(find.byType(Form));
    expect(form.validate(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an editor load failure exposes retry without editable associations',
    (tester) async {
      final api = _CommerceApi()..failOwnedPost = true;
      await _pump(
        tester,
        PostEditorScreen(repository: CommunityRepository(api), postId: 7),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('post-choose-shop')), findsNothing);
      api.failOwnedPost = false;
      await _tap(tester, 'post-editor-retry');
      expect(find.text('Maison Sichuan Paris'), findsOneWidget);
    },
  );

  testWidgets('shop search ignores results from an older request', (
    tester,
  ) async {
    final oldResult = Completer<Map<String, dynamic>>();
    final api = _CommerceApi()
      ..onSearch = (query) => query['keyword'] == ''
          ? oldResult.future
          : Future.value(_page([_otherShop]));
    await _pump(
      tester,
      PostShopPickerScreen(repository: ApiBrowseRepository(api)),
    );
    await tester.enterText(find.byKey(const Key('post-shop-search')), 'Berlin');
    await _tap(tester, 'post-shop-search-submit');
    oldResult.complete(_page([_shop]));
    await tester.pumpAndSettle();
    expect(find.text('Mitte Bread & Brew'), findsOneWidget);
    expect(find.text('Maison Sichuan Paris'), findsNothing);
  });

  testWidgets(
    'shop pagination retries the same submitted query and deduplicates results',
    (tester) async {
      var failPage = true;
      final api = _CommerceApi()
        ..onSearch = (query) async {
          if (query['page'] == 1) return _page([_shop], total: 2);
          if (failPage) {
            failPage = false;
            throw const ApiException('network unavailable');
          }
          return _page([_shop, _otherShop], page: 2, total: 2);
        };
      await _pump(
        tester,
        PostShopPickerScreen(repository: ApiBrowseRepository(api)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('post-shop-search')),
        'Paris',
      );
      await _tap(tester, 'post-shop-search-submit');
      await tester.enterText(
        find.byKey(const Key('post-shop-search')),
        'Not submitted',
      );
      await _tap(tester, 'post-shop-picker-more');
      expect(find.text('Maison Sichuan Paris'), findsOneWidget);
      await _tap(tester, 'post-shop-picker-retry');
      expect(api.searches.last, containsPair('keyword', 'Paris'));
      expect(api.searches.last, containsPair('page', 2));
      expect(find.text('Maison Sichuan Paris'), findsOneWidget);
      expect(find.text('Mitte Bread & Brew'), findsOneWidget);
      expect(find.byKey(const Key('post-shop-picker-more')), findsNothing);
    },
  );

  testWidgets('deal picker recovers a failed load and excludes other places', (
    tester,
  ) async {
    final api = _CommerceApi()..failDeals = true;
    await _pump(
      tester,
      PostDealPickerScreen(repository: TradeRepository(api), shopId: 20001),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not load. Please try again.'), findsOneWidget);
    await _tap(tester, 'post-deal-picker-retry');
    expect(find.text('Sichuan Dinner for Two'), findsOneWidget);
    expect(find.text('Another place deal'), findsNothing);
  });
}
