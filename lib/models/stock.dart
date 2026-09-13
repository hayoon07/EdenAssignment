import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class DailyPrice {
  final String date;
  final int close;
  final int high;
  final int low;
  final int change;
  final String volume;

  DailyPrice({
    required this.date,
    required this.close,
    required this.high,
    required this.low,
    required this.change,
    required this.volume,
  });

  factory DailyPrice.fromJson(Map<String, dynamic> json) {
    return DailyPrice(
      date: json['date'] as String,
      close: json['close'] as int,
      high: json['high'] as int? ?? 0,
      low: json['low'] as int? ?? 0,
      change: json['change'] as int,
      volume: json['volume'] as String,
    );
  }
}

class Stock {
  final String code;
  final String name;
  String market;
  int? currentPrice;
  int? change;
  double? changeRate;
  int openPrice;
  int highPrice;
  int lowPrice;
  String volume;
  String marketCap;
  bool isFavorite;
  final List<DailyPrice> dailyPrices;

  Stock({
    required this.code,
    required this.name,
    required this.market,
    this.currentPrice,
    this.change,
    this.changeRate,
    this.openPrice = 0,
    this.highPrice = 0,
    this.lowPrice = 0,
    this.volume = '-',
    this.marketCap = '-',
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

// 네이버 API 통신
class NaverApiService {
  // 실시간 시세 API (관심/종목 한 번에 조회)
  static Future<void> fetchRealtimeQuotes(List<Stock> stocks) async {
    if (stocks.isEmpty) return;

    try {
      final symbols = stocks.map((s) => s.code).join(',');
      final url = Uri.parse(
          'https://polling.finance.naver.com/api/realtime?query=SERVICE_ITEM:$symbols');

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final areas = data['result']?['areas'] as List<dynamic>?;

        if (areas != null) {
          for (var area in areas) {
            final datas = area['datas'] as List<dynamic>?;
            if (datas != null) {
              for (var item in datas) {
                final symbol = item['cd'];
                final nv = int.tryParse(item['nv'].toString()) ?? 0; // 현재가
                final pcv = int.tryParse(item['pcv'].toString()) ?? 0; // 전일 종가
                final ov = int.tryParse(item['ov'].toString()) ?? 0; // 시가
                final hv = int.tryParse(item['hv'].toString()) ?? 0; // 고가
                final lv = int.tryParse(item['lv'].toString()) ?? 0; // 저가
                final aq = int.tryParse(item['aq'].toString()) ?? 0; // 누적 거래량
                final listCount = int.tryParse(
                        item['countOfListedStock']?.toString() ?? '0') ??
                    0;

                final targetStock = stocks.firstWhere((s) => s.code == symbol,
                    orElse: () => stocks.first);
                if (targetStock.code == symbol) {
                  targetStock.currentPrice = nv;
                  targetStock.change = nv - pcv;
                  targetStock.changeRate =
                      pcv != 0 ? (nv - pcv) / pcv * 100 : 0.0;
                  targetStock.openPrice = ov;
                  targetStock.highPrice = hv;
                  targetStock.lowPrice = lv;

                  // 시가총액 계산 (현재가 × 상장주식수, 단위 조/억 등 포맷팅 필요시 적용)
                  if (listCount > 0 && nv > 0) {
                    double capTrillion = (nv * listCount) / 1000000000000;
                    targetStock.marketCap =
                        '${capTrillion.toStringAsFixed(0)}조';
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('실시간 시세 연동 에러: $e');
    }
  }

  // 2. 종목 메타데이터 API (거래소명 등)
  static Future<void> fetchMetadata(Stock stock) async {
    try {
      final url = Uri.parse(
          'https://stock.naver.com/api/securityFe/api/fchart/domestic/stock/${stock.code}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final exchangeName = data['stockExchangeNameKor'];
        if (exchangeName != null) {
          stock.market = exchangeName; // 코스피 / 코스닥 등 정확한 거래소명으로 갱신
        }
      }
    } catch (e) {
      print('메타데이터 연동 에러 (${stock.code}): $e');
    }
  }

  // 페이지별 일별 시세 데이터를 캐싱하기 위한 맵 (메모리 캐시)
  // key: "종목코드_페이지번호" (예: "005930_1"), value: 해당 페이지의 일별 시세 리스트
  static final Map<String, List<DailyPrice>> _pageCache = {};

  // 3. 일별 시세 HTML 파싱 및 EUC-KR 디코딩 / 캐싱 적용 함수
  static Future<List<DailyPrice>> fetchDailyPrices(
      String symbol, int page) async {
    final cacheKey = '${symbol}_$page';

    // 💡 캐싱 적용: 이미 캐시에 데이터가 있다면 네트워크를 타지 않고 즉시 반환!
    if (_pageCache.containsKey(cacheKey)) {
      print('캐시된 일별 시세 데이터 사용: $cacheKey');
      return _pageCache[cacheKey]!;
    }

    try {
      final url = Uri.parse(
          'https://finance.naver.com/item/sise_day.naver?code=$symbol&page=$page');

      // 네이버 일별 시세는 EUC-KR 인코딩이므로 bytes로 받아온 뒤 디코딩 처리
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // EUC-KR 바이트를 문자열로 안전하게 변환 (웹/앱 공용 처리)
        // latin1 또는 다트 기본 인코딩 활용 혹은 바이트 디코딩
        String htmlBody = '';
        try {
          // chardet 또는 시스템 인코딩 대안으로 latin1 바이트 변환 후 처리 혹은 utf8 시도
          htmlBody = utf8.decode(response.bodyBytes, allowMalformed: true);
        } catch (_) {
          htmlBody = response.body;
        }

        List<DailyPrice> dailyPrices = _parseHtmlToDailyPrices(htmlBody);

        // 성공적으로 파싱했다면 캐시에 저장!
        _pageCache[cacheKey] = dailyPrices;
        return dailyPrices;
      }
    } catch (e) {
      print('일별 시세 파싱 에러 ($symbol): $e');
    }

    return [];
  }

  // HTML 문자열에서 테이블 행(tr)을 정규식이나 파서로 추출하여 DailyPrice로 변환하는 함수
  static List<DailyPrice> _parseHtmlToDailyPrices(String html) {
    List<DailyPrice> prices = [];
    try {
      final trRegExp = RegExp(r'<tr\s*[^>]*>(.*?)<\/tr>', dotAll: true);
      final matches = trRegExp.allMatches(html);

      for (var match in matches) {
        final row = match.group(1) ?? '';
        final tdRegExp = RegExp(r'<t[dh]\s*[^>]*>(.*?)<\/t[dh]>', dotAll: true);
        final tds = tdRegExp
            .allMatches(row)
            .map((m) =>
                m.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '')
            .toList();

        // 네이버 일별 시세 테이블 구조 대응 (tds 길이기 충분할 때)
        if (tds.length >= 7 && tds[0].contains('.')) {
          final dateStr = tds[0].substring(5); // "MM.DD"
          final closePrice = int.tryParse(tds[1].replaceAll(',', '')) ?? 0;
          final highPrice =
              int.tryParse(tds[3].replaceAll(',', '')) ?? closePrice;
          final lowPrice =
              int.tryParse(tds[4].replaceAll(',', '')) ?? closePrice;

          final volumeStr = '${tds[6]}천';

          prices.add(DailyPrice(
            date: dateStr,
            close: closePrice,
            high: highPrice,
            low: lowPrice,
            change: 0, // 아래에서 전일 종가와 비교해 계산
            volume: volumeStr,
          ));
        }
      }

      // 전일 종가와 비교하여 정확한 등락(change) 계산
      for (int i = 0; i < prices.length; i++) {
        if (i < prices.length - 1) {
          int todayClose = prices[i].close;
          int prevClose = prices[i + 1].close;
          int diff = todayClose - prevClose;

          prices[i] = DailyPrice(
            date: prices[i].date,
            close: prices[i].close,
            high: prices[i].high,
            low: prices[i].low,
            change: diff,
            volume: prices[i].volume,
          );
        } else {
          prices[i] = DailyPrice(
            date: prices[i].date,
            close: prices[i].close,
            high: prices[i].high,
            low: prices[i].low,
            change: 0,
            volume: prices[i].volume,
          );
        }
      }
    } catch (e) {
      print('HTML 파싱 내부 에러: $e');
    }
    return prices;
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

    // 로드된 직후 네이버 실시간 시세 API를 한 번에 일괄 조회 반영
    await NaverApiService.fetchRealtimeQuotes(_stocks);

    return _stocks;
  }
}
