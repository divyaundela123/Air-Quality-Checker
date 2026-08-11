import 'package:hive/hive.dart';

part 'aqi_record.g.dart';

@HiveType(typeId: 0)
class AqiRecord extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late double aqiScore;

  @HiveField(2)
  late String status;

  @HiveField(3)
  late double temperature;

  @HiveField(4)
  late double humidity;

  @HiveField(5)
  late double co2;

  @HiveField(6)
  late double voc;

  @HiveField(7)
  late DateTime timestamp;

  AqiRecord({
    required this.id,
    required this.aqiScore,
    required this.status,
    required this.temperature,
    required this.humidity,
    required this.co2,
    required this.voc,
    required this.timestamp,
  });
}
