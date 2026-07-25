/// OCR로 읽은 줄 중 '주문 가능한 메뉴 항목'으로 보이는 것만 걸러내는 휴리스틱.
///
/// 카테고리 제목·설명 문구·주의사항·가격/영문만 있는 줄 등을 제거한다.
/// 완벽하진 않지만(정확히 하려면 LLM 분류가 필요) 흔한 비(非)메뉴는 대부분 걸러진다.
class MenuFilter {
  // 가격/기호만 (예: "980엔", "¥380")
  static final RegExp _priceOnly = RegExp(r'^[\s\d,.\-~¥￥원엔円]*$');

  // 영문·숫자·기호만 (예: "ALL 180", "OPEN")
  static final RegExp _latinOnly = RegExp(r'^[\sA-Za-z0-9,.\-~!?&/]+$');

  // 문장·설명·주의문에서 자주 나오는 표시
  static final RegExp _sentence =
      RegExp(r'[。！？…♪]|※|ございません|ありません|できます|ください|いたします|使用|注意|税込|税抜');

  // 카테고리 제목·비메뉴 단어 (일본어 원문 또는 한국어 번역이 정확히 일치하면 제외)
  static const Set<String> _headers = {
    // 일본어
    '酒の肴', '料理', '一品料理', '逸品料理', 'お通し', 'おすすめ', '本日のおすすめ',
    'メニュー', '串焼き', '博多串焼き', '豚串', '鶏串', '野菜', '巻き物', '揚げ物',
    '甘味', 'ご飯もの', 'ご飯物', 'サラダ', 'ドリンク', '飲み物', 'お飲み物',
    'デザート', 'セットメニュー', 'ランチ', 'ディナー', '選べる小鉢の彩り',
    'おまかせ', '国産米使用', '新名物', '博多',
    // 한국어 번역
    '술안주', '요리', '추천', '오늘의 추천', '메뉴', '꼬치구이', '야채', '말이',
    '튀김류', '디저트', '샐러드', '음료', '밥류', '신메뉴', '하카타',
  };

  /// ja=원문(일본어), ko=번역(한국어). 주문 가능한 메뉴로 보이면 true.
  static bool looksOrderable(String ja, String ko) {
    ja = ja.trim();
    ko = ko.trim();
    if (ko.isEmpty) return false;
    if (_priceOnly.hasMatch(ko)) return false; // 가격만
    if (_latinOnly.hasMatch(ja)) return false; // 영문/숫자만 (프로모션 등)
    if (ja.length > 20) return false; // 너무 긴 줄 = 설명/문장
    if (_sentence.hasMatch(ja)) return false; // 문장·주의문
    if (_headers.contains(ja) || _headers.contains(ko)) return false; // 카테고리 제목
    return true;
  }
}
