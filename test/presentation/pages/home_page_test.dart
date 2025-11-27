import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:uta_picker/domain/repositories/playlist_repository.dart';
import 'package:uta_picker/presentation/pages/home_page.dart';

@GenerateMocks([PlaylistRepository])
import 'home_page_test.mocks.dart';

void main() {
  late MockPlaylistRepository mockPlaylistRepository;

  setUp(() {
    mockPlaylistRepository = MockPlaylistRepository();
  });

  testWidgets('HomePage smoke test', (WidgetTester tester) async {
    // Arrange
    when(mockPlaylistRepository.getPlaylist()).thenAnswer((_) async => []);

    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      home: HomePage(playlistRepository: mockPlaylistRepository),
    ));

    // Verify that the HomePage is displayed.
    expect(find.byType(HomePage), findsOneWidget);

    // Verify that the AppBar title is correct.
    // Note: The title might be an image or text depending on implementation,
    // but checking for HomePage widget existence is a good start.
    // Based on code: Image.asset('assets/logo.png') ... errorBuilder: Text('Uta(Gawa)Picker')
    // Since assets are not loaded in test environment usually, it might show text.
    // Let's just check for HomePage for now.
  });
}
