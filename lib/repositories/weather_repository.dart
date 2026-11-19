import '../data/preferences_local_data_source.dart';
import '../data/weather_remote_data_source.dart';
import '../models/weather_snapshot.dart';

class WeatherRepository {
  const WeatherRepository(this._remote, this._local);

  final WeatherRemoteDataSource _remote;
  final PreferencesLocalDataSource _local;

  Future<WeatherSnapshot> loadWeather() async {
    try {
      final live = await _remote.fetch();
      await _local.saveWeather(live);
      return live;
    } catch (_) {
      final cached = _local.loadWeather();
      if (cached != null) return cached;
      rethrow;
    }
  }
}
