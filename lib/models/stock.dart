import 'dart:convert';
import 'package:flutter/services.dart';

class DailyPrice {
  final String date;
  final int close;
  final int change;
  final String volume;

  DailyPrice({
    required this.date,
    required this.close,
    required this.change,
    required this.volume,
  });

  factory DailyPrice.fromJson(Map<String, dynamic> json) {
    return DailyPrice(
      date: json['date'] as String,
      close: json['close'] as int,
      change: json['change'] as int,
      volume: json['volume'] as String,
    );
  }
}

class Stock {
  final String code;
  final String name;
  final String market;
  final int? currentPrice;
  final int? change;
  final double? changeRate;
  final int openPrice;
  final int highPrice;
  final int lowPrice;
  final String volume;
  final String marketCap;
  bool isFavorite;
  final List<DailyPrice> dailyPrices;

  Stock({
    required this.code,
    required this.name,
    required this.market,
    this.currentPrice,
    this.change,
    this.changeRate,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
    required this.marketCap,
    this.isFavorite = false,
    this.dailyPrices = const [],
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      code: json['code'] as String,
      name: json['name'] as String,
      market: json['market'] as String,
      currentPrice: json['currentPrice'] as int?,
      change: json['change'] as int?,
      changeRate: (json['changeRate'] as num?)?.toDouble(),
      openPrice: json['openPrice'] as int? ?? 0,
      highPrice: json['highPrice'] as int? ?? 0,
      lowPrice: json['lowPrice'] as int? ?? 0,
      volume: json['volume'] as String? ?? '-',
      marketCap: json['marketCap'] as String? ?? '-',
      isFavorite: json['isFavorite'] as bool? ?? false,
      dailyPrices: (json['dailyPrices'] as List<dynamic>?)
              ?.map((e) => DailyPrice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class StockRepository {
  static List<Stock> _stocks = [];

  static Future<List<Stock>> loadStocks() async {
    if (_stocks.isNotEmpty) return _stocks;
    try {
      final jsonString = await rootBundle.loadString('mock/stocks.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _stocks = jsonList.map((e) => Stock.fromJson(e)).toList();
    } catch (_) {
      _stocks = [
        Stock(
            code: '005930',
            name: '삼성전자',
            market: '코스피',
            currentPrice: 179700,
            change: -400,
            changeRate: -0.22,
            openPrice: 172100,
            highPrice: 181700,
            lowPrice: 172000,
            volume: '29,113천',
            marketCap: '1,063조',
            isFavorite: true),
        Stock(
            code: '000660',
            name: 'SK하이닉스',
            market: '코스피',
            currentPrice: 412500,
            change: 9500,
            changeRate: 2.36,
            openPrice: 405000,
            highPrice: 416000,
            lowPrice: 402000,
            volume: '4,821천',
            marketCap: '300조',
            isFavorite: true),
        Stock(
            code: '035720',
            name: '카카오',
            market: '코스피',
            currentPrice: 61300,
            change: -800,
            changeRate: -1.29,
            openPrice: 62000,
            highPrice: 62500,
            lowPrice: 60900,
            volume: '1,850천',
            marketCap: '27조',
            isFavorite: true),
        Stock(
            code: '247540',
            name: '에코프로비엠',
            market: '코스닥',
            currentPrice: 195400,
            change: 0,
            changeRate: 0.0,
            openPrice: 195400,
            highPrice: 198000,
            lowPrice: 194000,
            volume: '950천',
            marketCap: '19조',
            isFavorite: true),
        Stock(
            code: '373220',
            name: 'LG에너지솔루션',
            market: '코스피',
            currentPrice: null,
            change: null,
            changeRate: null,
            openPrice: 0,
            highPrice: 0,
            lowPrice: 0,
            volume: '-',
            marketCap: '-',
            isFavorite: true),
        Stock(
            code: '005935',
            name: '삼성전자우',
            market: '코스피',
            currentPrice: 63400,
            change: 200,
            changeRate: 0.32,
            openPrice: 63200,
            highPrice: 63900,
            lowPrice: 63000,
            volume: '1,200천',
            marketCap: '52조',
            isFavorite: false),
        Stock(
            code: '207940',
            name: '삼성바이오로직스',
            market: '코스피',
            currentPrice: 780000,
            change: -5000,
            changeRate: -0.64,
            openPrice: 785000,
            highPrice: 789000,
            lowPrice: 778000,
            volume: '180천',
            marketCap: '55조',
            isFavorite: false),
        Stock(
            code: '018260',
            name: '삼성에스디에스',
            market: '코스피',
            currentPrice: 156000,
            change: 1500,
            changeRate: 0.97,
            openPrice: 154500,
            highPrice: 157000,
            lowPrice: 154000,
            volume: '210천',
            marketCap: '12조',
            isFavorite: false),
        Stock(
            code: '010140',
            name: '삼성중공업',
            market: '코스피',
            currentPrice: 9800,
            change: 120,
            changeRate: 1.24,
            openPrice: 9650,
            highPrice: 9850,
            lowPrice: 9600,
            volume: '5,400천',
            marketCap: '8조',
            isFavorite: false),
        Stock(
            code: '028260',
            name: '삼성물산',
            market: '코스피',
            currentPrice: 142000,
            change: -1000,
            changeRate: -0.70,
            openPrice: 143000,
            highPrice: 144500,
            lowPrice: 141000,
            volume: '320천',
            marketCap: '26조',
            isFavorite: false),
      ];
    }
    return _stocks;
  }
}
