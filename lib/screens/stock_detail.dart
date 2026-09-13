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

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.stock.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;
    final stock = widget.stock;

    // 실제 데이터 있는 경우 값 추출 (없으면 기본 0)
    final currentPriceStr =
        stock.currentPrice != null ? _formatPrice(stock.currentPrice!) : '-';
    final changeVal = stock.change ?? 0;
    final changeRateVal = stock.changeRate ?? 0.0;
    final changeColor = _getChangeColor(changeVal, colors);
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
            // ★ 핵심: 뒤로 갈 때 변경된 _isFavorite 값을 이전 화면으로 전달
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
              // 1. 현재가 및 전일 대비 등락 정보 (상승 빨강, 하락 파랑 관행 적용)
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
                    Icon(Icons.arrow_drop_up,
                        color: colors.priceUpText, size: 24),
                    Text(
                      changeText,
                      style: TextStyle(
                        color: colors.priceUpText,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]
                ],
              ),
              SizedBox(height: dimens.space6),

              // 2. 기간 탭 (1개월 / 3개월 / 6개월 / 1년) - accentDefault / accentBg 토큰 활용
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['1개월', '3개월', '6개월', '1년'].map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: dimens.space1),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedPeriod = period;
                          });
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

              // 3. 캔들 차트 영역 (chartLineUp, chartLineDown 토큰 대응)
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(dimens.radiusLg),
                  border: Border.all(
                      color: colors.borderSubtle, width: dimens.borderHairline),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${stock.name} - $_selectedPeriod 캔들 차트 영역\n(chartLineUp / chartLineDown 적용)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.chartAxisLabel, fontSize: 14),
                ),
              ),
              SizedBox(height: dimens.space6),

              // 4. 요약 카드 (현재 보유 시세 데이터 기반 동적 표시)
              Container(
                padding: EdgeInsets.all(dimens.space4),
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(dimens.radiusLg),
                  border: Border.all(
                      color: colors.borderSubtle, width: dimens.borderHairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '종목 요약',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: dimens.space3),
                    _buildSummaryRow('현재가', currentPriceStr, '등락금액',
                        changeVal != 0 ? _formatPrice(changeVal) : '0', colors),
                    Divider(color: colors.borderSubtle, height: 20),
                    _buildSummaryRow(
                        '상태',
                        stock.currentPrice != null ? '정상 거래' : '정보 대기중',
                        '시장',
                        stock.market,
                        colors),
                  ],
                ),
              ),
              SizedBox(height: dimens.space6),

              // 5. 일별 시세 표 (MM.DD 날짜 및 등락 부호/색상)
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
                    // 실제 모델 데이터 연동하거나 HTML 파싱 결과 행 배치
                    _buildDailyRow('09.13', currentPriceStr, changeText,
                        '12,450천', changeColor, colors, dimens),
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
  if (change > 0) return colors.priceUpText;
  if (change < 0) return colors.priceDownText;
  return colors.priceFlatText;
}
