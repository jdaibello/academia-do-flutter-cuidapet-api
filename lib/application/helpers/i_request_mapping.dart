import 'dart:convert';

abstract class IRequestMapping {
  final Map<String, dynamic> data;

  IRequestMapping.empty() : data = {};

  IRequestMapping(String dataRequest) : data = jsonDecode(dataRequest) {
    map();
  }

  void map();
}
