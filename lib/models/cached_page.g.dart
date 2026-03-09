// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_page.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedPageAdapter extends TypeAdapter<CachedPage> {
  @override
  final int typeId = 0;

  @override
  CachedPage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedPage(
      url: fields[0] as String,
      title: fields[1] as String,
      contentHtml: fields[2] as String,
      fetchedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedPage obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.contentHtml)
      ..writeByte(3)
      ..write(obj.fetchedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedPageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
