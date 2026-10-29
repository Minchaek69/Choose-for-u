// 3상태(로딩·오류·빈) + 화면 흐름(push · tab · modal) + 적응형(600dp) 위젯 테스트.
// 네트워크를 쓰지 않도록 ListScreen에 가짜 loader를 넣는다 → json-server 없이 `flutter test`가 돈다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mid_project_template/api.dart';
import 'package:mid_project_template/models.dart';
import 'package:mid_project_template/screens/a_list_screen.dart';

const _items = [
  Item(
    id: 1,
    title: '오늘 뭐 먹지?',
    subtitle: '점심·저녁 메뉴, 3분 컷',
    image: '',
    tags: ['음식', '옵션 3개'],
    emoji: '🍜',
    mode: '토너먼트',
  ),
  Item(id: 2, title: '운동 뭐 하지?', subtitle: '옵션 준비 중', image: '', tags: ['운동']),
];

const _notes = [
  Note(
    id: 1,
    itemId: 1,
    text: '마라탕',
    emoji: '🍜',
    pick: true,
    reason: '얼얼한 국물이 국룰',
  ),
  Note(id: 2, itemId: 1, text: '초밥', emoji: '🍣', reason: '가볍고 깔끔하게'),
  Note(id: 3, itemId: 1, text: '치킨', emoji: '🍗', reason: '치킨은 언제나 옳다'),
];

Future<List<Note>> _fakeNotes(int itemId) async =>
    _notes.where((n) => n.itemId == itemId).toList();

const _history = [
  History(
    id: 1,
    emoji: '🍜',
    text: '마라탕',
    situation: '오늘 뭐 먹지?',
    date: '10/28 점심',
    mood: '😍',
  ),
  History(
    id: 2,
    emoji: '🧺',
    text: '한강 피크닉',
    situation: '주말 뭐 하지?',
    date: '10/26 오후',
    color: '#3B82F6',
  ),
];

Widget _app(ItemsLoader load, {HistoryLoader? history}) => MaterialApp(
  home: ListScreen(
    load: load,
    loadNotes: _fakeNotes,
    loadHistory: history ?? () async => const <History>[],
  ),
);

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('A 3상태: 로딩 → 오류 → 다시 시도 → 성공', (tester) async {
    _setSize(tester, const Size(400, 800));

    final first = Completer<List<Item>>();
    var calls = 0;
    await tester.pumpWidget(
      _app(() => ++calls == 1 ? first.future : Future.value(_items)),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('고민 목록을 불러오는 중…'), findsOneWidget);

    first.completeError(Exception('테스트 오류'));
    await tester.pumpAndSettle();
    expect(find.text('고민 목록을 불러오지 못했어요.'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('오늘 뭐 먹지?'), findsOneWidget);
    expect(find.text('🎮 토너먼트'), findsOneWidget); // 추천 게임 배지
    expect(calls, 2);
  });

  testWidgets('A 3상태: 빈 상태', (tester) async {
    await tester.pumpWidget(_app(() async => const []));
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 등록된 고민이 없어요'), findsOneWidget);
  });

  testWidgets('흐름: A → push B → 결정 방식 탭 → 골라줘 모달 → 다시 · 잠금', (tester) async {
    _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_app(() async => _items));
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsOneWidget); // 폰: 목록
    expect(find.byType(GridView), findsNothing);

    await tester.tap(find.text('오늘 뭐 먹지?'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget); // push
    expect(find.text('초밥'), findsOneWidget); // 옵션 탭(기본)

    // 옆으로(tab): 결정 방식 — db.json의 mode와 같은 카드에 "추천"
    await tester.tap(find.text('결정 방식'));
    await tester.pumpAndSettle();
    expect(find.text('토너먼트'), findsOneWidget);
    expect(find.text('추천'), findsOneWidget);

    // 덮기(modal): 골라줘 결과 — pick: true 인 옵션
    await tester.tap(find.text('골라줘!'));
    await tester.pumpAndSettle();
    expect(find.text('※ 예시 결과입니다 (실제 추천 로직 없음)'), findsOneWidget);
    expect(find.text('넌 이미 답을 알고 있었잖아 😉'), findsOneWidget);
    expect(find.text('💬 얼얼한 국물이 국룰'), findsOneWidget);

    // 다시 = db.json 순서대로 다음 옵션
    await _tapVisible(tester, find.text('🎲 다시'));
    expect(find.text('💬 가볍고 깔끔하게'), findsOneWidget);

    // 두 번째 다시 → STOP 배너
    await _tapVisible(tester, find.text('🎲 다시'));
    expect(find.textContaining('STOP'), findsOneWidget);

    // 결정 잠금 → 다시 버튼 비활성
    await _tapVisible(tester, find.text('🔒 결정 잠금'));
    expect(find.text('🔓 잠금 해제'), findsOneWidget);
    final again = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '🎲 다시'),
    );
    expect(again.onPressed, isNull);
  });

  testWidgets('둘이서: 가위바위보 — 각자 손을 내면 공개', (tester) async {
    _setSize(tester, const Size(400, 900));
    await tester.pumpWidget(_app(() async => _items));
    await tester.pumpAndSettle();
    await tester.tap(find.text('오늘 뭐 먹지?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('결정 방식'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.textContaining('더 많은 방법 보기'));
    await tester.scrollUntilVisible(
      find.text('가위바위보'),
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .last,
    );
    await _tapVisible(tester, find.text('가위바위보'));
    await tester.tap(find.text('골라줘!'));
    await tester.pumpAndSettle();
    Finder inSheet(String t) =>
        find.descendant(of: find.byType(BottomSheet), matching: find.text(t));
    await _tapVisible(tester, inSheet('✊').first); // 나
    expect(find.text('🤫 냈어!'), findsOneWidget); // 내 손은 숨김
    await _tapVisible(tester, inSheet('🖐').last); // 너
    expect(find.text('✊  vs  🖐'), findsOneWidget);
    expect(find.textContaining('이긴 사람 마음대로'), findsOneWidget);
  });

  testWidgets('B 빈 상태: 옵션이 없으면 골라줘! 비활성', (tester) async {
    _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_app(() async => _items));
    await tester.pumpAndSettle();

    await tester.tap(find.text('운동 뭐 하지?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 옵션이 없어요'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '골라줘!'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('결정 지갑: 카드를 누르면 맨 앞으로 (GET /history)', (tester) async {
    _setSize(tester, const Size(400, 900));
    await tester.pumpWidget(
      _app(() async => _items, history: () async => _history),
    );
    await tester.pumpAndSettle();
    expect(find.text('🍜 마라탕'), findsOneWidget);
    await tester.tap(find.text('🧺 한강 피크닉'));
    await tester.pumpAndSettle();
    expect(find.byType(WalletCard), findsNWidgets(2));
  });

  testWidgets('결정 지갑: 빈 상태', (tester) async {
    _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_app(() async => _items));
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 잠근 결정이 없어요'), findsOneWidget);
  });

  testWidgets('적응형: 600dp 이상이면 격자', (tester) async {
    _setSize(tester, const Size(1024, 768));
    await tester.pumpWidget(_app(() async => _items));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
  });
}
