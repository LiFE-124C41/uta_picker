import 'package:flutter_test/flutter_test.dart';
import 'package:uta_picker/presentation/app.dart';
import 'package:uta_picker/domain/repositories/playlist_repository.dart';
import 'package:uta_picker/domain/entities/playlist_item.dart';

class FakePlaylistRepository implements PlaylistRepository {
  @override
  Future<void> addPlaylistItem(PlaylistItem item) async {}

  @override
  Future<void> clearPlaylist() async {}

  @override
  Future<List<PlaylistItem>> getPlaylist() async => [];

  @override
  Future<void> removePlaylistItem(int index) async {}

  @override
  Future<void> savePlaylist(List<PlaylistItem> playlist) async {}

  @override
  Future<void> updatePlaylistItem(int index, PlaylistItem item) async {}
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      playlistRepository: FakePlaylistRepository(),
    ));

    // Verify that the app builds without crashing.
    expect(find.byType(MyApp), findsOneWidget);
  });
}
