import 'dart:convert';

import 'package:dpip/core/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool init = false;

dynamic convertIntsToDoubles(dynamic value) {
  if (value is int) {
    return value.toDouble();
  } else if (value is List) {
    return value.map(convertIntsToDoubles).toList();
  } else if (value is Map) {
    return value.map(
      (key, value) => MapEntry(key, convertIntsToDoubles(value)),
    );
  } else {
    return value;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  int _page = 0;
  List<Widget> _List_children = <Widget>[];
  var data;
  late GeoJsonParser myGeoJson = GeoJsonParser(
      defaultPolygonBorderColor: Colors.white,
      defaultPolygonFillColor: const Color(0xff3F4045));
  bool loadingData = false;

  Future<void> processData() async {
    var geojson_data = await get(
        "https://cdn.jsdelivr.net/gh/ExpTechTW/TREM-Lite@master/src/resource/maps/tw.json");
    myGeoJson
        .parseGeoJsonAsString(jsonEncode(convertIntsToDoubles(geojson_data)));
  }

  @override
  void initState() {
    loadingData = true;
    processData().then((_) {
      setState(() {
        loadingData = false;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    init = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (!init) {
        data = await get(
            "https://exptech.com.tw/api/v1/dpip/alert?city=${prefs.getString('loc-city')}&town=${prefs.getString('loc-town')}");
        if (data != false) init = true;
        print(data);
      }
      _List_children = <Widget>[];
      _List_children.add(
        SizedBox(
          height: 400,
          child: FlutterMap(
            mapController: MapController(),
            options: MapOptions(
              center: const LatLng(23.6, 120.1),
              zoom: 7,
              interactiveFlags: InteractiveFlag.all - InteractiveFlag.all,
            ),
            children: [
              PolygonLayer(polygons: myGeoJson.polygons),
              PolylineLayer(polylines: myGeoJson.polylines),
            ],
          ),
        ),
      );
      if (data == false) {
        _List_children.add(const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "服務異常",
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w100, color: Colors.red),
            ),
            Text(
              "稍等片刻後重試 如持續異常 請回報開發人員",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ));
      } else {
        if (_page == 0) {
          if (prefs.getString('loc-town') == null) {
            _List_children.add(const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "服務區域外",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w100,
                      color: Colors.white),
                ),
                Text(
                  "無法取得相關資訊 可能是因為尚未設定所在地位置",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                )
              ],
            ));
          } else {
            _List_children.add(Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        prefs.getString("loc-city") ?? "",
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        prefs.getString("loc-town") ?? "",
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey),
                      ),
                    ],
                  )
                ],
              ),
            ));
            _List_children.add(Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 0, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xff333439),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sunny, color: Colors.white, size: 50),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.baseline, // 修改這裡
                          textBaseline: TextBaseline.alphabetic, // 添加這行
                          children: [
                            Text(
                              "40",
                              style: TextStyle(
                                fontSize: 50,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              ".1°C",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "降雨機率 10%",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w100,
                                color: Colors.white),
                          ),
                          Text(
                            "預估氣溫 28 ~ 36°C",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w100,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ));
            if (data["loc"].length == 0) {
              _List_children.add(const Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: double.infinity),
                    Text(
                      "暫無生效中的防災資訊",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ));
            } else {
              for (var i = 0; i < data["loc"].length; i++) {
                DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
                        data["all"][i]["time"],
                        isUtc: true)
                    .add(const Duration(hours: 8));
                String formattedDate =
                    '${dateTime.year}年${formatNumber(dateTime.month)}月${formatNumber(dateTime.day)}日 ${formatNumber(dateTime.hour)}:${formatNumber(dateTime.minute)} 發布';
                _List_children.add(Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: double.infinity),
                      Text(
                        data["all"][i]["title"],
                        style: TextStyle(
                            fontSize: 20,
                            color: (data["all"][i]["type"] == 2)
                                ? Colors.red
                                : (data["all"][i]["type"] == 1)
                                    ? Colors.amber
                                    : Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        formattedDate,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        data["all"][i]["body"],
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      )
                    ],
                  ),
                ));
              }
            }
          }
        } else {
          if (data["all"].length == 0) {
            _List_children.add(const Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: double.infinity),
                  Text(
                    "暫無生效中的防災資訊",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  )
                ],
              ),
            ));
          } else {
            for (var i = 0; i < data["all"].length; i++) {
              DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
                      data["all"][i]["time"],
                      isUtc: true)
                  .add(const Duration(hours: 8));
              String formattedDate =
                  '${dateTime.year}年${formatNumber(dateTime.month)}月${formatNumber(dateTime.day)}日 ${formatNumber(dateTime.hour)}:${formatNumber(dateTime.minute)} 發布';
              _List_children.add(Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: double.infinity),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          data["all"][i]["title"],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red[900],
                            borderRadius: BorderRadius.circular(5), // 設置圓角
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(3),
                            child: Text(
                              "最大震度 6強",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      data["all"][i]["body"],
                      style:
                          const TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  ],
                ),
              ));
            }
          }
        }
      }
      if (!mounted) return;
      setState(() {});
    });
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (_page == 1) ? Colors.blue[800] : Colors.transparent,
                    elevation: 20,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    setState(() {
                      _page = 1;
                    });
                  },
                  child: const Text(
                    "全國",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (_page == 0) ? Colors.blue[800] : Colors.transparent,
                    elevation: 20,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    setState(() {
                      _page = 0;
                    });
                  },
                  child: const Text(
                    "所在地",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                  padding: const EdgeInsets.all(0),
                  children: _List_children.toList()),
            ),
          ],
        ),
      ),
    );
  }
}
