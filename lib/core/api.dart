import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trem_web/core/ntp.dart';

import 'http_get.dart';

Future<Map<String, dynamic>> parseJsonFromAssets(String assetsPath) async {
  var file = await rootBundle.loadString(assetsPath);
  return jsonDecode(file);
}

String int_to_intensity(int _i) {
  String _i_ = _i.toString();
  if (_i_ == "5") _i_ = "5-";
  if (_i_ == "6") _i_ = "5+";
  if (_i_ == "7") _i_ = "6-";
  if (_i_ == "8") _i_ = "6+";
  if (_i_ == "9") _i_ = "7";
  return _i_;
}

Future<List> Earthquake(json) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var loc = await parseJsonFromAssets("assets/resource/location.json");
  List Loc = (prefs.getString("location") ?? "臺南市 歸仁區").split(" ");
  String city = Loc[0];
  String town = Loc[1];
  double point = sqrt(pow(
          (loc[city][town][1] +
                      double.parse(json["NorthLatitude"].toString()) * -1)
                  .abs() *
              111,
          2) +
      pow(
          (loc[city][town][2] +
                      double.parse(json["EastLongitude"].toString()) * -1)
                  .abs() *
              101,
          2));
  double distance =
      sqrt(pow(int.parse(json["Depth"].toString()), 2) + pow(point, 2));
  var ans = PGAcount(
      double.parse(json["Scale"].toString()), distance, loc[city][town][3]);
  double num_s =
      (distance - ((await Now(false) - json["Time"]) / 1000) * 3.5) / 3.5;
  double num_p =
      (distance - ((await Now(false) - json["Time"]) / 1000) * 6.5) / 6.5;
  return [ans[0], distance, num_s, num_p];
}

PGAcount(Scale, distance, Si) {
  double PGA = double.parse(
      (1.657 * pow(e, (1.533 * Scale)) * pow(distance, -1.607) * Si)
          .toStringAsFixed(3));
  return [
    PGA >= 800
        ? 9
        : 800 >= PGA && 440 < PGA
            ? 8
            : 440 >= PGA && 250 < PGA
                ? 7
                : 250 >= PGA && 140 < PGA
                    ? 6
                    : 140 >= PGA && 80 < PGA
                        ? 5
                        : 80 >= PGA && 25 < PGA
                            ? 4
                            : 25 >= PGA && 8 < PGA
                                ? 3
                                : 8 >= PGA && 2.5 < PGA
                                    ? 2
                                    : 2.5 >= PGA && 0.8 < PGA
                                        ? 1
                                        : 0,
    PGA
  ];
}
