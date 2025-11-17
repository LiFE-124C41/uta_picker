// lib/domain/repositories/track_repository.dart
import '../entities/track.dart';

abstract class TrackRepository {
  Future<void> initialize();
  Future<List<Track>> getAllTracks();
  Future<void> saveTrack(Track track);
  Future<void> updateTrackEndSec(int trackId, int endSec);
  Future<void> deleteTrack(int trackId);
}

