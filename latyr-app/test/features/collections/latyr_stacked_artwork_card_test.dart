import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/features/collections/domain/user_collection_model.dart';
import 'package:latyr_app/features/collections/presentation/widgets/latyr_stacked_artwork_card.dart';

void main() {
  group('LatyrStackedArtworkCard Tests', () {
    testWidgets('renders empty collection placeholder with name and item count', (tester) async {
      bool tapped = false;
      const collection = UserCollectionModel(
        id: '1',
        userId: 'u1',
        name: 'My Watchlist',
        itemCount: 0,
        previewArtworkUrls: [],
        isPinned: false,
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: SizedBox(
              width: 180,
              height: 240,
              child: LatyrStackedArtworkCard(
                collection: collection,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('My Watchlist'), findsOneWidget);
      expect(find.text('0 items'), findsOneWidget);

      await tester.tap(find.text('My Watchlist'));
      expect(tapped, isTrue);
    });

    testWidgets('renders stacked card with 1 item correctly', (tester) async {
      const collection = UserCollectionModel(
        id: '2',
        userId: 'u1',
        name: 'Favorite Movies',
        itemCount: 1,
        previewArtworkUrls: [
          'https://image.tmdb.org/t/p/w500/test.jpg',
        ],
        isPinned: false,
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: SizedBox(
              width: 180,
              height: 240,
              child: LatyrStackedArtworkCard(
                collection: collection,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Favorite Movies'), findsOneWidget);
      expect(find.text('1 item'), findsOneWidget);
    });
  });
}
