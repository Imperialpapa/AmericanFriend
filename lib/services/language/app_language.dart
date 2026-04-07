/// 앱에서 지원하는 언어 목록
enum AppLanguage {
  englishUS(
    code: 'en-US',
    displayName: 'English (US)',
    nativeName: '영어 (미국)',
    ttsCode: 'en-US',
    sttCode: 'en-US',
    aiName: 'American English',
  ),
  englishUK(
    code: 'en-GB',
    displayName: 'English (UK)',
    nativeName: '영어 (영국)',
    ttsCode: 'en-GB',
    sttCode: 'en-GB',
    aiName: 'British English',
  ),
  chineseMandarin(
    code: 'zh-CN',
    displayName: 'Chinese (Mandarin)',
    nativeName: '中文 (普通话)',
    ttsCode: 'zh-CN',
    sttCode: 'zh-CN',
    aiName: 'Mandarin Chinese',
  ),
  chineseCantonese(
    code: 'zh-HK',
    displayName: 'Chinese (Cantonese)',
    nativeName: '中文 (廣東話)',
    ttsCode: 'zh-HK',
    sttCode: 'zh-HK',
    aiName: 'Cantonese Chinese',
  ),
  korean(
    code: 'ko-KR',
    displayName: 'Korean',
    nativeName: '한국어',
    ttsCode: 'ko-KR',
    sttCode: 'ko-KR',
    aiName: 'Korean',
  ),
  japanese(
    code: 'ja-JP',
    displayName: 'Japanese',
    nativeName: '日本語',
    ttsCode: 'ja-JP',
    sttCode: 'ja-JP',
    aiName: 'Japanese',
  ),
  spanish(
    code: 'es-ES',
    displayName: 'Spanish',
    nativeName: 'Español',
    ttsCode: 'es-ES',
    sttCode: 'es-ES',
    aiName: 'Spanish',
  ),
  french(
    code: 'fr-FR',
    displayName: 'French',
    nativeName: 'Français',
    ttsCode: 'fr-FR',
    sttCode: 'fr-FR',
    aiName: 'French',
  ),
  italian(
    code: 'it-IT',
    displayName: 'Italian',
    nativeName: 'Italiano',
    ttsCode: 'it-IT',
    sttCode: 'it-IT',
    aiName: 'Italian',
  );

  const AppLanguage({
    required this.code,
    required this.displayName,
    required this.nativeName,
    required this.ttsCode,
    required this.sttCode,
    required this.aiName,
  });

  /// BCP-47 언어 코드
  final String code;

  /// 영어 표시명
  final String displayName;

  /// 해당 언어 원어 표시명
  final String nativeName;

  /// TTS 엔진용 locale 코드
  final String ttsCode;

  /// STT 엔진용 locale 코드
  final String sttCode;

  /// AI 프롬프트에서 사용할 언어명
  final String aiName;

  /// 드롭다운 표시용: "English (US) · 영어 (미국)"
  String get label => '$displayName · $nativeName';

  /// code 문자열로 enum 찾기
  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (e) => e.code == code,
      orElse: () => AppLanguage.korean,
    );
  }

  /// 시스템 로케일(languageCode)로 가장 가까운 AppLanguage 찾기
  static AppLanguage fromSystemLocale(String languageCode) {
    return switch (languageCode) {
      'ko' => AppLanguage.korean,
      'ja' => AppLanguage.japanese,
      'zh' => AppLanguage.chineseMandarin,
      'es' => AppLanguage.spanish,
      'fr' => AppLanguage.french,
      'it' => AppLanguage.italian,
      _ => AppLanguage.englishUS, // en 및 기타
    };
  }
}
