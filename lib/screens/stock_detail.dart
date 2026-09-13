import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../models/stock.dart';

class StockDetailScreen extends StatefulWidget {
  final Stock stock;

  const StockDetailScreen({
    super.key,
    required this.stock,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  // 기간 탭 상태 ('1개월', '3개월', '6개월', '1년')
  String _selectedPeriod = '1개월';
  late bool _isFavorite;

  // 일별 시세 데이터 비동기로 불러오기 위한 상태 변수
  bool _isLoading = true;
  List<DailyPrice> _dailyPrices = [];

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.stock.isFavorite;
    _loadDailyData(); // 화면 켜질 때 데이터 로드
  }

  int _getPageCountForPeriod(String period) {
    switch (period) {
      case '1개월':
        return 1;
      case '3개월':
        return 3;
      case '6개월':
        return 6;
      case '1년':
        return 12;
      default:
        return 1;
    }
  }

  Future<void> _loadDailyData() async {
    setState(() {
      _isLoading = true;
    });

    List<DailyPrice> fetchedList = [];
    int targetPages = _getPageCountForPeriod(_selectedPeriod);

    // 요구사항: 캐싱과 페이지네이션을 활용해 지정된 페이지 수만큼 데이터 수집
    for (int page = 1; page <= targetPages; page++) {
      final pageData =
          await NaverApiService.fetchDailyPrices(widget.stock.code, page);
      fetchedList.addAll(pageData);
    }

    if (mounted) {
      setState(() {
        _dailyPrices = fetchedList;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;
    final stock = widget.stock;

    final currentPriceStr =
        stock.currentPrice != null ? _formatPrice(stock.currentPrice!) : '-';
    final changeVal = stock.change ?? 0;
    final changeRateVal = stock.changeRate ?? 0.0;
    final changeColor = _getChangeColor(changeVal, colors);
    final changeIcon = changeVal > 0
        ? Icons.arrow_drop_up
        : changeVal < 0
            ? Icons.arrow_drop_down
            : Icons.remove;
    final changeText = stock.currentPrice != null
        ? _formatChangeText(changeVal, changeRateVal)
        : '정보 없음';

    // 안드로이드 시스템 백 버튼이나 상단 뒤로 가기 시 변경된 관심 상태를 전달하기 위한 PopScope
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.pop(context, _isFavorite);
      },
      child: Scaffold(
        backgroundColor: colors.surfaceBase,
        appBar: AppBar(
          backgroundColor: colors.surfaceBase,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: colors.textPrimary, size: dimens.iconMd),
            // 뒤로 갈 때 변경된 _isFavorite 값을 이전 화면으로 전달
            onPressed: () => Navigator.pop(context, _isFavorite),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stock.name,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: dimens.space1),
              Text(
                '${stock.code} · ${stock.market}',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.star : Icons.star_border,
                color: _isFavorite
                    ? colors.favoriteActive
                    : colors.favoriteInactive,
                size: dimens.iconMd,
              ),
              onPressed: () {
                setState(() {
                  _isFavorite = !_isFavorite;
                  stock.isFavorite = _isFavorite; // 원본 모델 상태 동기화
                });
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(dimens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 현재가 및 전일 대비 등락 정보
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    currentPriceStr,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: dimens.space1),
                  Text('원',
                      style:
                          TextStyle(color: colors.textSecondary, fontSize: 14)),
                  SizedBox(width: dimens.space3),
                  if (stock.currentPrice != null) ...[
                    Icon(changeIcon, color: changeColor, size: 24),
                    Text(
                      changeText,
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]
                ],
              ),
              SizedBox(height: dimens.space6),

              // 기간 탭 (1개월 / 3개월 / 6개월 / 1년) - accentDefault / accentBg 토큰 활용
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['1개월', '3개월', '6개월', '1년'].map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: dimens.space1),
                      child: InkWell(
                        onTap: () {
                          if (_selectedPeriod != period) {
                            setState(() {
                              _selectedPeriod = period;
                            });
                            _loadDailyData(); // 탭 변경 시 해당 기간 데이터 재요청 (캐시)
                          }
                        },
                        borderRadius: BorderRadius.circular(dimens.radiusMd),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(vertical: dimens.space2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.accentBg
                                : colors.surfaceRaised,
                            borderRadius:
                                BorderRadius.circular(dimens.radiusMd),
                            border: Border.all(
                              color: isSelected
                                  ? colors.accentDefault
                                  : Colors.transparent,
                              width: dimens.borderHairline,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            period,
                            style: TextStyle(
                              color: isSelected
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: dimens.space6),

              // 캔들 차트 영역
              Container(
                height: 220,
                padding: EdgeInsets.all(dimens.space4),
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(dimens.radiusLg),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _dailyPrices.isEmpty
                        ? Center(
                            child: Text('차트 데이터가 없습니다.',
                                style: TextStyle(color: colors.textSecondary)),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${stock.name} - $_selectedPeriod 가격 추이',
                                    style: TextStyle(
                                        color: colors.textSecondary,
                                        fontSize: 12),
                                  ),
                                  Text(
                                    '최종일 종가: ${_formatPrice(_dailyPrices.first.close)}원',
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: dimens.space2),
                              Expanded(
                                child: CustomPaint(
                                    size: Size.infinite,
                                    painter: CandlestickChartPainter(
                                        prices: _dailyPrices.reversed.toList(),
                                        colors: colors)),
                              ),
                            ],
                          ),
              ),

              // 요약 카드 (현재 보유 시세 데이터 기반 동적 표시)
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBox(
                      '시가',
                      stock.openPrice != 0
                          ? _formatPrice(stock.openPrice)
                          : '-',
                      colors,
                    ),
                  ),
                  SizedBox(width: dimens.space2),
                  Expanded(
                    child: _buildInfoBox(
                      '고가',
                      stock.highPrice != 0
                          ? _formatPrice(stock.highPrice)
                          : '-',
                      colors,
                    ),
                  ),
                  SizedBox(width: dimens.space2),
                  Expanded(
                    child: _buildInfoBox(
                      '저가',
                      stock.lowPrice != 0 ? _formatPrice(stock.lowPrice) : '-',
                      colors,
                    ),
                  ),
                ],
              ),
              SizedBox(height: dimens.space2),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBox('거래량', stock.volume, colors),
                  ),
                  SizedBox(width: dimens.space2),
                  Expanded(
                    child: _buildInfoBox('시가총액', stock.marketCap, colors),
                  ),
                ],
              ),
              SizedBox(height: dimens.space6),

              // 일별 시세 표 (MM.DD 날짜 및 등락 부호/색상)
              Text(
                '일별 시세',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: dimens.space3),
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(dimens.radiusLg),
                  border: Border.all(
                      color: colors.borderSubtle, width: dimens.borderHairline),
                ),
                child: Column(
                  children: [
                    // 테이블 헤더
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: dimens.space4,
                        vertical: dimens.space3,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('날짜',
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 12)),
                          Text('종가',
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 12)),
                          Text('등락',
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 12)),
                          Text('거래량',
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Divider(color: colors.borderSubtle, height: 1),

                    // 로딩 중일 때 로딩 표시, 아닐 때 파싱된 일별 데이터 렌더링
                    _isLoading
                        ? Padding(
                            padding: EdgeInsets.all(dimens.space6),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _dailyPrices.isEmpty
                            ? Padding(
                                padding: EdgeInsets.all(dimens.space6),
                                child: Center(
                                  child: Text(
                                    '일별 시세 정보가 없습니다.',
                                    style:
                                        TextStyle(color: colors.textSecondary),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _dailyPrices.length,
                                itemBuilder: (context, index) {
                                  final item = _dailyPrices[index];
                                  final itemChangeColor =
                                      _getChangeColor(item.change, colors);

                                  String itemChangeText;
                                  if (item.change > 0) {
                                    itemChangeText =
                                        '+${_formatPrice(item.change)}';
                                  } else if (item.change < 0) {
                                    itemChangeText = _formatPrice(
                                        item.change); // 이미 음수(-) 부호가 포함되어 있음
                                  } else {
                                    itemChangeText = '0';
                                  }

                                  return Column(
                                    children: [
                                      _buildDailyRow(
                                        item.date,
                                        _formatPrice(item.close),
                                        itemChangeText,
                                        item.volume,
                                        itemChangeColor,
                                        colors,
                                        dimens,
                                      ),
                                      if (index < _dailyPrices.length - 1)
                                        Divider(
                                            color: colors.borderSubtle,
                                            height: 1),
                                    ],
                                  );
                                },
                              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label1,
    String val1,
    String label2,
    String val2,
    AppColors colors,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label1,
                  style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                val1,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: label2.isNotEmpty
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label2,
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 13)),
                    Text(
                      val2,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildDailyRow(
    String date,
    String close,
    String change,
    String volume,
    Color changeColor,
    AppColors colors,
    AppDimens dimens,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: dimens.space4, vertical: dimens.space3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(date,
              style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Text(
            close,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(change, style: TextStyle(color: changeColor, fontSize: 13)),
          Text(volume,
              style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

String _formatPrice(int price) {
  return price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
}

String _formatChangeText(int change, double rate) {
  final prefix = change > 0 ? '+' : '';
  return '$prefix${_formatPrice(change)} ($prefix${rate.toStringAsFixed(2)}%)';
}

Color _getChangeColor(int change, AppColors colors) {
  if (change > 0) {
    return colors.priceUpText; // 상승: 빨간색
  } else if (change < 0) {
    return colors.priceDownText; // 하락: 파란색
  } else {
    return colors.priceFlatText; // 보합: 기본 색상
  }
}

class CandlestickChartPainter extends CustomPainter {
  final List<DailyPrice> prices;
  final AppColors colors;

  CandlestickChartPainter({required this.prices, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty) return;

    const double verticalPadding = 20.0;
    double chartHeight = size.height - (verticalPadding * 2);
    if (chartHeight <= 0) chartHeight = size.height;

    // 전체 데이터 중 최고가와 최저가를 기준으로 화면 스케일 산출
    int maxPrice = prices.map((e) => e.high).reduce((a, b) => a > b ? a : b);
    int minPrice = prices.map((e) => e.low).reduce((a, b) => a < b ? a : b);

    if (maxPrice == minPrice) {
      maxPrice += 1000;
      minPrice -= 1000;
    }

    double priceRange = (maxPrice - minPrice).toDouble();
    double totalWidth = size.width;
    double spacing = totalWidth / prices.length;
    double candleWidth = (spacing * 0.5).clamp(2.5, 10.0);

    for (int i = 0; i < prices.length; i++) {
      final item = prices[i];

      int close = item.close;
      int open = close - item.change; // 시가 추정
      int high = item.high;
      int low = item.low;

      bool isUp = close >= open;
      Color bodyColor = isUp ? colors.priceUpText : colors.priceDownText;

      double x = i * spacing + (spacing / 2);

      // 가격을 화면 Y 좌표로 변환
      double yHigh = chartHeight * (1.0 - ((high - minPrice) / priceRange)) +
          verticalPadding;
      double yLow = chartHeight * (1.0 - ((low - minPrice) / priceRange)) +
          verticalPadding;
      double yOpen = chartHeight * (1.0 - ((open - minPrice) / priceRange)) +
          verticalPadding;
      double yClose = chartHeight * (1.0 - ((close - minPrice) / priceRange)) +
          verticalPadding;

      // 박스 이탈 방지 클램프
      yHigh = yHigh.clamp(verticalPadding, size.height - verticalPadding);
      yLow = yLow.clamp(verticalPadding, size.height - verticalPadding);
      yOpen = yOpen.clamp(verticalPadding, size.height - verticalPadding);
      yClose = yClose.clamp(verticalPadding, size.height - verticalPadding);

      // 1. 꼬리(Wick) 그리기: 예시 UI처럼 차분한 회색톤으로 고가~저가 연결
      final wickPaint = Paint()
        ..color = Colors.grey.withOpacity(0.6) // 은은한 회색 꼬리
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(x, yHigh), Offset(x, yLow), wickPaint);

      // 2. 몸통(Body) 그리기: 시가와 종가 사이의 직사각형 (상승은 빨강, 하락은 파랑)
      double topBody = yOpen < yClose ? yOpen : yClose;
      double bottomBody = yOpen > yClose ? yOpen : yClose;
      double bodyHeight = (bottomBody - topBody).abs();
      if (bodyHeight < 2.0) bodyHeight = 2.0; // 최소 두께 보장

      final bodyPaint = Paint()
        ..color = bodyColor
        ..style = PaintingStyle.fill;

      Rect rect = Rect.fromCenter(
        center: Offset(x, (topBody + bottomBody) / 2),
        width: candleWidth,
        height: bodyHeight,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
        bodyPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
