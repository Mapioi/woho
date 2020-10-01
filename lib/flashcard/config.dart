import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'config.g.dart';

/// Configuration for a folder.
///
/// The display colour [colourValue] of the folder and the order of the contents
/// [orderedContents] are stored in a json file.
@JsonSerializable()
class Config {
  Config(this.colourValue, this.orderedContents);

  @JsonKey(required: true)
  int colourValue;

  @JsonKey(required: true)
  List<String> orderedContents;

  Config.empty()
      : colourValue = Colors.lightBlue[200].value,
        orderedContents = [];

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigToJson(this);
}
