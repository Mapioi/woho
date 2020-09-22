import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'config.g.dart';

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
