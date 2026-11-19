import '../data/local_metric_data_source.dart';
import '../models/metric_point.dart';

class TerritoryRepository {
  const TerritoryRepository(this._dataSource);

  final LocalMetricDataSource _dataSource;

  Future<MetricSeries> loadWater() =>
      _dataSource.load('assets/data/water_history.json');

  Future<MetricSeries> loadEnergy() =>
      _dataSource.load('assets/data/energy_history.json');
}
