// 데이터 모양 — db.json의 한 항목을 화면이 쓰기 좋은 객체로 바꾼다.
// Item = 결정 상황(무엇을 정할지), Note = 그 상황의 선택지(옵션).
// 형식이 틀린 항목은 null을 돌려준다 → 목록에서 빠질 뿐 앱이 멈추지 않는다 (Dart 3 패턴 매칭).

class Item {
  const Item({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    this.tags = const [],
    this.emoji = '🎲',
    this.mode = '',
  });

  final int id;
  final String title; // 결정 상황 (예: 오늘 뭐 먹지?)
  final String subtitle; // 한 줄 설명 (예: 점심·저녁 메뉴, 3분 컷)
  final String image; // (미사용 — 이모지로 대체) db.json 호환용
  final List<String> tags; // [카테고리, 옵션 N개]
  final String emoji; // 상황 대표 이모지
  final String mode; // 이 상황의 추천 결정 게임 (db.json에 미리 정한 값 — 계산하지 않음)

  static Item? fromJson(Object? json) {
    return switch (json) {
      {
        'id': int id,
        'title': String title,
        'subtitle': String subtitle,
        'image': String image,
      } =>
        Item(
          id: id,
          title: title,
          subtitle: subtitle,
          image: image,
          tags: switch (json['tags']) {
            List<Object?> t => t.whereType<String>().toList(),
            _ => const [],
          },
          emoji: switch (json['emoji']) {
            String e => e,
            _ => '🎲',
          },
          mode: switch (json['mode']) {
            String m => m,
            _ => '',
          },
        ),
      _ => null,
    };
  }
}

class Note {
  const Note({
    required this.id,
    required this.itemId,
    required this.text,
    this.desc = '',
    this.emoji = '•',
    this.pick = false,
    this.reason = '',
    this.votes = const [],
    this.crowd = 0,
  });

  final int id;
  final int itemId;
  final String text; // 옵션 이름 (예: 마라탕)
  final String desc; // 한 줄 분위기 (예: 얼얼하게 땀 빼기)
  final String emoji;
  final bool pick; // true = C 결과 화면에 보여 줄 "예시 결과" (db.json에 미리 표시)
  final String reason; // 이 옵션이 결과로 나올 때 보여 줄 한 줄 이유 (미리 쓴 문장)
  final List<String> votes; // 단톡방 친구들의 표 — db.json에 미리 모아 둔 예시 (실제 수집 없음)
  final int crowd; // 🌍 모두의 선택 % — 같은 고민을 한 사람들의 예시 통계 (계산 안 함)

  static Note? fromJson(Object? json) {
    return switch (json) {
      {'id': int id, 'itemId': int itemId, 'text': String text} => Note(
        id: id,
        itemId: itemId,
        text: text,
        desc: switch (json['desc']) {
          String d => d,
          _ => '',
        },
        emoji: switch (json['emoji']) {
          String e => e,
          _ => '•',
        },
        pick: json['pick'] == true,
        reason: switch (json['reason']) {
          String r => r,
          _ => '',
        },
        votes: switch (json['votes']) {
          List<Object?> v => v.whereType<String>().toList(),
          _ => const [],
        },
        crowd: switch (json['crowd']) {
          int c => c,
          _ => 0,
        },
      ),
      _ => null,
    };
  }
}

/// 지난 결정 한 장 (A 「결정 지갑」, GET /history) — db.json에 미리 넣은 예시 기록 (앱이 저장하지 않음)
class History {
  const History({
    required this.id,
    required this.emoji,
    required this.text,
    required this.situation,
    required this.date,
    this.place = '',
    this.mood = '',
    this.checkin = '',
    this.photo = '',
    this.color = '#FF5A36',
  });

  final int id;
  final String emoji;
  final String text; // 고른 것 (예: 마라탕)
  final String situation; // 어떤 고민이었나 (예: 오늘 뭐 먹지?)
  final String date;
  final String place;
  final String mood; // 결정 뒤 만족도 이모지
  final String checkin; // 인증(체크인) 상태 문구
  final String photo; // 인증 사진 (예시 이미지 URL)
  final String color; // 카드 색 #RRGGBB

  static History? fromJson(Object? json) {
    return switch (json) {
      {
        'id': int id,
        'emoji': String emoji,
        'text': String text,
        'situation': String situation,
        'date': String date,
      } =>
        History(
          id: id,
          emoji: emoji,
          text: text,
          situation: situation,
          date: date,
          place: switch (json['place']) {
            String v => v,
            _ => '',
          },
          mood: switch (json['mood']) {
            String v => v,
            _ => '',
          },
          checkin: switch (json['checkin']) {
            String v => v,
            _ => '',
          },
          photo: switch (json['photo']) {
            String v => v,
            _ => '',
          },
          color: switch (json['color']) {
            String v => v,
            _ => '#FF5A36',
          },
        ),
      _ => null,
    };
  }
}

/// 결정 게임 (B 「결정 방식」 탭) — 소개 카드만, 실제 대진·랜덤 로직은 없다.
class DecisionGame {
  const DecisionGame(this.emoji, this.name, this.howTo, {this.duo = false});

  final String emoji;
  final String name;
  final String howTo;
  final bool duo; // true = 둘이서 하는 게임 (커플 · 친구)
}

const decisionGames = [
  DecisionGame('🆚', '듀얼', '둘씩 붙여서 "하나만 남긴다면?" — 비교 대신 쉬운 이분 선택'),
  DecisionGame('🏆', '토너먼트', '8강 → 4강 → 결승! 여러 개를 한 개까지'),
  DecisionGame('❌', '하나씩 지우기', '좋은 걸 고르기보다 싫은 걸 지우기가 쉽다'),
  DecisionGame('🎰', '가짜 랜덤', '결과를 보고 "아쉬운지" 내 반응으로 답을 찾는다'),
  DecisionGame('👯', '친구 투표', '단톡방 친구들 표가 제일 많은 쪽 — 내 ❤️도 한 표'),
  DecisionGame('✋', '거부권', '한 명당 "이건 절대 싫어" 하나씩 지우고 남은 것 중에서'),
  DecisionGame('✊', '가위바위보', '한 폰으로 각자 손을 내고 동시에 공개 — 이긴 사람 마음대로', duo: true),
  DecisionGame('🤫', '비밀 픽', '서로 몰래 하나씩 고르고 동시에 공개 — 같으면 바로 끝', duo: true),
  DecisionGame('🔁', '번갈아 지우기', '한 명씩 번갈아 ✕ — 마지막에 남은 게 오늘의 답', duo: true),
  DecisionGame('👆', '하나 둘 셋 지목', '셋 세고 동시에 손가락으로 옵션 가리키기', duo: true),
  DecisionGame('🎤', '30초 어필', '각자 30초 동안 설득 — 더 설득된 사람이 양보', duo: true),
  DecisionGame('🎁', '양보 쿠폰', '이번엔 내가 양보, 다음엔 네가 — 쿠폰 한 장 쓰기', duo: true),
];

/// 지금 기분 (B 상단 FEEL 칩) — 결과 문구에만 쓰고 계산에는 쓰지 않는다.
const feelings = [('😴', '피곤'), ('😐', '그냥'), ('🤩', '신남')];
