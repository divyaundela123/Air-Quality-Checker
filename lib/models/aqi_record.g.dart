// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aqi_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AqiRecordAdapter extends TypeAdapter<AqiRecord> {
  @override
  final int typeId = 0;

  @override
  AqiRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AqiRecord(
      id: fields[0] as String,
      aqiScore: fields[1] as double,
      status: fields[2] as String,
      temperature: fields[3] as double,
      humidity: fields[4] as double,
      co2: fields[5] as double,
      voc: fields[6] as double,
      timestamp: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AqiRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.aqiScore)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.temperature)
      ..writeByte(4)
      ..write(obj.humidity)
      ..writeByte(5)
      ..write(obj.co2)
      ..writeByte(6)
      ..write(obj.voc)
      ..writeByte(7)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AqiRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
