import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../models/stock.dart';
import '../screens/stock_detail.dart';

enum SortType {
  koreanAlpha('가나다순'),
  currentPrice('현재가순'),
  changeRate('등락률순');

  final String label;
  const SortType(this.label);
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  List<Stock> _allStocks = [];
  bool _isLoading = true;
  SortType _currentSort = SortType.koreanAlpha;

  // 검색 상태
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 커스텀 토스트 상태
  String? _toastMessage;
  IconData? _toastIcon;
  Color? _toastIconColor;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final stocks = await StockRepository.loadStocks();
    setState(() {
      _allStocks = stocks;
      _isLoading = false;
    });
  }

  List<Stock> get _favoriteStocks {
    final list = _allStocks.where((s) => s.isFavorite).toList();
    switch (_currentSort) {
      case SortType.currentPrice:
        list.sort(
            (a, b) => (b.currentPrice ?? 0).compareTo(a.currentPrice ?? 0));
        break;
      case SortType.changeRate:
        list.sort((a, b) => (b.changeRate ?? 0).compareTo(a.changeRate ?? 0));
        break;
      case SortType.koreanAlpha:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return list;
  }

  List<Stock> get _searchResults {
    if (_searchQuery.isEmpty) return [];
    return _allStocks.where((s) {
      return s.name.contains(_searchQuery) || s.code.contains(_searchQuery);
    }).toList();
  }

  void _toggleFavorite(Stock stock) {
    setState(() {
      stock.isFavorite = !stock.isFavorite;
    });

    final colors = context.colors;
    _showToast(
      message: stock.isFavorite ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
      icon: stock.isFavorite ? Icons.star : Icons.star_border,
      iconColor: stock.isFavorite ? colors.favoriteActive : colors.textDisabled,
    );
  }

  // 종목 상세 화면으로 이동, 돌아올 때 관심 상태 동기화
  Future<void> _navigateToDetail(Stock stock) async {
    final bool? isFavoriteChanged = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => StockDetailScreen(
                  stock: stock,
                )));

    // 상세 화면에서 관심 상태 변경되어 돌아온 경우 목록 갱신
    if (isFavoriteChanged != null && isFavoriteChanged != stock.isFavorite) {
      setState(() {
        stock.isFavorite = isFavoriteChanged;
      });
    }
  }

  void _showToast(
      {required String message,
      required IconData icon,
      required Color iconColor}) {
    setState(() {
      _toastMessage = message;
      _toastIcon = icon;
      _toastIconColor = iconColor;
    });

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted && _toastMessage == message) {
        setState(() => _toastMessage = null);
      }
    });
  }

  void _showSortBottomSheet() {
    final colors = context.colors;
    final dimens = context.dimens;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(dimens.radiusLg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: dimens.space4, horizontal: dimens.space4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '정렬',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                SizedBox(height: dimens.space4),
                ...SortType.values.map((sort) {
                  final isSelected = _currentSort == sort;
                  return InkWell(
                    onTap: () {
                      setState(() => _currentSort = sort);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: dimens.space3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            sort.label,
                            style: TextStyle(
                              color: isSelected
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? AppTypography.bold
                                  : AppTypography.regular,
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check,
                                color: colors.textPrimary, size: dimens.iconMd),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: SafeArea(
        child: Stack(
          children: [
            _currentIndex == 0
                ? _buildWatchlist(colors, dimens)
                : _buildSearchScreen(colors, dimens),

            // 토스트 오버레이
            if (_toastMessage != null)
              Positioned(
                left: dimens.space4,
                right: dimens.space4,
                bottom: dimens.space3,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: dimens.space4,
                    vertical: dimens.space3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    borderRadius: BorderRadius.circular(dimens.radiusMd),
                    border: Border.all(
                      color: colors.borderSubtle,
                      width: dimens.borderHairline,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(_toastIcon,
                          color: _toastIconColor, size: dimens.iconMd),
                      SizedBox(width: dimens.space2),
                      Text(
                        _toastMessage!,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: AppTypography.medium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: colors.borderSubtle, width: dimens.borderHairline)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: colors.surfaceBase,
          selectedItemColor: colors.navActive,
          unselectedItemColor: colors.navInactive,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.star_border),
              activeIcon: Icon(Icons.star),
              label: '관심',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: '검색',
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ 01. 관심종목 화면 ------------------
  Widget _buildWatchlist(AppColors colors, AppDimens dimens) {
    final favList = _favoriteStocks;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: dimens.space4, vertical: dimens.space3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '관심',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 20,
                  fontWeight: AppTypography.bold,
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: _showSortBottomSheet,
                    child: Row(
                      children: [
                        Text(
                          _currentSort.label,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                            fontWeight: AppTypography.regular,
                          ),
                        ),
                        SizedBox(width: dimens.space1),
                        Icon(Icons.arrow_downward,
                            color: colors.textSecondary, size: 14),
                      ],
                    ),
                  ),
                  SizedBox(width: dimens.space3),
                  InkWell(
                    onTap: _loadData,
                    child: Icon(Icons.refresh,
                        color: colors.textSecondary, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : favList.isEmpty
                  ? _buildWatchlistEmpty(colors, dimens)
                  : ListView.separated(
                      itemCount: favList.length,
                      separatorBuilder: (_, __) => Divider(
                        color: colors.borderSubtle.withOpacity(0.3),
                        height: dimens.borderHairline,
                      ),
                      itemBuilder: (context, index) {
                        return _buildWatchlistTile(
                            favList[index], colors, dimens);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildWatchlistTile(Stock stock, AppColors colors, AppDimens dimens) {
    final isSkeleton = stock.currentPrice == null;

    // 관심 목록 행 클릭 시 상세 페이지 이동
    return InkWell(
      onTap: () => _navigateToDetail(stock),
      child: Container(
        constraints: BoxConstraints(minHeight: dimens.rowMinHeight),
        padding: EdgeInsets.symmetric(
            horizontal: dimens.space4, vertical: dimens.space2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: AppTypography.medium,
                  ),
                ),
                SizedBox(height: dimens.space1),
                Text(
                  '${stock.code} · ${stock.market}',
                  style: TextStyle(
                    color: colors.textDisabled,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (isSkeleton)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 55,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colors.feedbackSkeleton,
                      borderRadius: BorderRadius.circular(dimens.radiusSm),
                    ),
                  ),
                  SizedBox(height: dimens.space1),
                  Container(
                    width: 40,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors.feedbackSkeleton,
                      borderRadius: BorderRadius.circular(dimens.radiusSm),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPrice(stock.currentPrice!),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  SizedBox(height: dimens.space1),
                  Text(
                    _formatChangeText(stock.change!, stock.changeRate!),
                    style: TextStyle(
                      color: _getChangeColor(stock.change!, colors),
                      fontSize: 12,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchlistEmpty(AppColors colors, AppDimens dimens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 48, color: colors.textDisabled),
          SizedBox(height: dimens.space3),
          Text(
            '관심 종목이 없습니다',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: AppTypography.bold,
            ),
          ),
          SizedBox(height: dimens.space2),
          Text(
            '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ 02. 검색 화면 ------------------
  Widget _buildSearchScreen(AppColors colors, AppDimens dimens) {
    final results = _searchResults;

    return Column(
      children: [
        // 검색바
        Padding(
          padding: EdgeInsets.all(dimens.space4),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: dimens.space3),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(dimens.radiusMd),
            ),
            child: Row(
              children: [
                Icon(Icons.search,
                    color: colors.textDisabled, size: dimens.iconMd),
                SizedBox(width: dimens.space2),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '종목명 또는 종목코드',
                      hintStyle:
                          TextStyle(color: colors.textDisabled, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: Icon(Icons.close,
                        color: colors.textDisabled, size: dimens.iconSm),
                  ),
              ],
            ),
          ),
        ),

        // 검색 결과 분기 (02_검색_empty / 02_검색결과_empty / 목록)
        Expanded(
          child: _searchQuery.isEmpty
              ? _buildSearchEmpty(colors, dimens)
              : results.isEmpty
                  ? _buildSearchResultEmpty(colors, dimens)
                  : ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, __) => Divider(
                        color: colors.borderSubtle.withOpacity(0.3),
                        height: dimens.borderHairline,
                      ),
                      itemBuilder: (context, index) {
                        return _buildSearchResultTile(
                            results[index], colors, dimens);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSearchEmpty(AppColors colors, AppDimens dimens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 48, color: colors.textDisabled),
          SizedBox(height: dimens.space3),
          Text(
            '종목을 검색해 보세요',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: AppTypography.bold,
            ),
          ),
          SizedBox(height: dimens.space2),
          Text(
            '종목명 또는 종목코드 6자리로\n검색하실 수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultEmpty(AppColors colors, AppDimens dimens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel_outlined, size: 48, color: colors.textDisabled),
          SizedBox(height: dimens.space3),
          Text(
            '검색 결과가 없습니다',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: AppTypography.bold,
            ),
          ),
          SizedBox(height: dimens.space2),
          Text(
            '‘$_searchQuery’와\n일치하는 검색 결과를 찾지 못했습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultTile(
      Stock stock, AppColors colors, AppDimens dimens) {
    // 검색 결과 행 클릭 시 상세 페이지 이동
    return InkWell(
      onTap: () => _navigateToDetail(stock),
      child: Container(
        constraints: BoxConstraints(minHeight: dimens.rowMinHeight),
        padding: EdgeInsets.symmetric(
            horizontal: dimens.space4, vertical: dimens.space2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHighlightedText(stock.name, _searchQuery, colors),
                SizedBox(height: dimens.space1),
                Text(
                  '${stock.code} · ${stock.market}',
                  style: TextStyle(
                    color: colors.textDisabled,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => _toggleFavorite(stock),
              icon: Icon(
                stock.isFavorite ? Icons.star : Icons.star_border,
                color: stock.isFavorite
                    ? colors.favoriteActive
                    : colors.textDisabled,
                size: dimens.iconMd,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 검색어 일치 텍스트 하이라이트
  Widget _buildHighlightedText(String text, String query, AppColors colors) {
    if (query.isEmpty || !text.contains(query)) {
      return Text(
        text,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 15,
          fontWeight: AppTypography.medium,
        ),
      );
    }

    final startIndex = text.indexOf(query);
    final endIndex = startIndex + query.length;

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 15,
          fontWeight: AppTypography.medium,
        ),
        children: [
          if (startIndex > 0)
            TextSpan(
              text: text.substring(0, startIndex),
              style: TextStyle(color: colors.textPrimary),
            ),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: TextStyle(
                color: colors.searchHighlight, fontWeight: AppTypography.bold),
          ),
          if (endIndex < text.length)
            TextSpan(
              text: text.substring(endIndex),
              style: TextStyle(color: colors.textPrimary),
            ),
        ],
      ),
    );
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
}
