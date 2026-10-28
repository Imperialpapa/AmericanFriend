import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:eng_friend/core/constants/ad_constants.dart';
import 'package:eng_friend/core/theme/app_colors.dart';

class BannerAdWidget extends StatefulWidget {
  /// false면 광고를 그리지 않는다. 광고 객체는 살려 둬서 다시 보일 때 새로 요청하지 않는다
  /// (키보드를 여닫을 때마다 재요청하면 요청 수만 늘고 노출률이 떨어진다).
  final bool visible;

  /// 로드 전에도 배너 높이만큼 자리를 잡는다 — 광고가 뜰 때 위 레이아웃이 튀지 않게.
  /// 로드에 실패하면 자리를 접는다.
  final bool reserveSpace;

  /// 위쪽에 구분선과 여백을 둔다. 입력창·버튼 바로 옆 배치는 오클릭을 부른다(tobe P-06).
  final bool separated;

  const BannerAdWidget({
    super.key,
    this.visible = true,
    this.reserveSpace = false,
    this.separated = false,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adUnitId = AdConstants.bannerAdUnitId;
    // 실기기 테스트 시 테스트 광고가 맞는지 로그로 확인 (실광고 클릭 = AdMob 정책 위반)
    debugPrint('[Ads] banner unit=$adUnitId debug=$kDebugMode');
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() => _isAdLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: ${error.message}');
          ad.dispose();
          // 잡아 둔 자리를 접으려면 다시 그려야 한다.
          if (mounted) {
            setState(() => _bannerAd = null);
          } else {
            _bannerAd = null;
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    final loaded = _isAdLoaded && ad != null;
    if (ad == null || (!loaded && !widget.reserveSpace)) {
      return const SizedBox.shrink();
    }

    Widget banner = SizedBox(
      width: loaded ? ad.size.width.toDouble() : null,
      height: AdSize.banner.height.toDouble(),
      child: loaded ? AdWidget(ad: ad) : null,
    );
    if (widget.separated) {
      banner = Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: KFPalette.of(context).hairline, width: 0.5),
          ),
        ),
        child: banner,
      );
    }
    // Offstage로 숨겨 AdWidget(플랫폼 뷰)을 트리에 남긴다 — 빼면 광고가 폐기·재요청된다.
    return Visibility(
      visible: widget.visible,
      maintainState: true,
      child: banner,
    );
  }
}
