import 'dart:typed_data';

import 'package:jsontool/jsontool.dart';

/// Returns a deep copy of the GeoJSON [object] with the most precise types for
/// the structure by traversing and rebuilding on the way back.
Map<String?, dynamic> geoParseObject(Object object) =>
    _jsonGeoObjectType(JsonReader.fromObject(object));

/// Equivalent to [geoParseObject] except it accepts the GeoJSON [object] as
/// string.
Map<String?, dynamic> geoParseString(String object) =>
    _jsonGeoObjectType(JsonReader.fromString(object));

/// Equivalent to [geoParseObject] except it accepts the GeoJSON [object] as
/// utf8.
Map<String?, dynamic> geoParseUtf8(Uint8List object) =>
    _jsonGeoObjectType(JsonReader.fromUtf8(object));

JsonBuilder _jsonBbox = jsonArray(jsonNum);

JsonBuilder<Map<String?, dynamic>> _jsonGeoObjectType = (reader) {
  reader.expectObject();
  var result = <String?, dynamic>{};
  String? key, type, object;
  JsonReader? pending;
  while (reader.hasNextKey()) {
    if ((key = reader.tryKey(["type"])) != null) {
      result[key] = (type = reader.expectString());
      if (pending != null) result[object] = _jsonGeoObject[type]!(pending);
    } else if ((key = reader
            .tryKey(["coordinates", "geometries", "geometry", "features"])) !=
        null) {
      object = key;
      if (type != null) {
        result[object] = _jsonGeoObject[type]!(reader);
      } else {
        pending = reader.copy();
        reader.skipAnyValue();
      }
    } else if ((key = reader.tryKey(["bbox"])) != null) {
      result[key] = _jsonBbox(reader);
    } else {
      result[reader.nextKey()] = jsonValue(reader);
    }
  }
  return result;
};

Map<String?, JsonBuilder> _jsonGeoObject = {
  "Point": jsonArray(jsonValue),
  "MultiPoint": jsonArray(jsonArray(jsonValue)),
  "LineString": jsonArray(jsonArray(jsonValue)),
  "MultiLineString": jsonArray(jsonArray(jsonArray(jsonValue))),
  "Polygon": jsonArray(jsonArray(jsonArray(jsonValue))),
  "MultiPolygon": jsonArray(jsonArray(jsonArray(jsonArray(jsonValue)))),
  "GeometryCollection": jsonArray(_jsonGeoObjectType),
  "Feature": _jsonGeoObjectType,
  "FeatureCollection": jsonArray(_jsonGeoObjectType)
};
