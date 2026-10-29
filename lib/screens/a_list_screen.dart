// 화면 A: 무슨 결정? — 결정 상황 목록 (GET /items)
//
// ┌──────── 디자인 가이드 대응표: A 무슨 결정? ─────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                    │ 비즈니스 명칭(한글)   │ 원칙(P번호)  │
// │ A-1  │ AppBar(브랜드) + 큰 제목 Text     │ 무슨 결정? 제목줄     │ P02 실세계   │
// │ A-2  │ LoadingView                       │ 고민 불러오는 중      │ P01 가시성   │
// │ A-3  │ ErrorView + FilledButton          │ 오류 안내·다시 시도   │ P09 오류 복구│
// │ A-4  │ EmptyView + 새로고침              │ 빈 목록 안내          │ P01 가시성   │
// │ A-9  │ 3단계 안내 Row (① ② ③)            │ 탭 3번 안내           │ P10 도움말   │
// │ A-10 │ WalletStack (AnimatedPositioned)  │ 결정 지갑(지난 결정·인증 사진)│ P06 재인 │
// │ A-5  │ LayoutBuilder → ListView/GridView │ 결정 상황 목록·격자   │ P07 유연성   │
// │ A-6  │ SituationCard (RoundCard)         │ 결정 상황 카드        │ P06 재인     │
// │ A-7  │ SoftChip(카테고리 색)             │ 카테고리 칩           │ P04 일관성   │
// │ A-8  │ SoftChip(옵션 수 · 추천 게임)     │ 옵션 수·추천 게임 배지│ P01 가시성   │
// └────────────────────────────────────────────────────────────────────────────┘
// 전환: A → B 는 쌓기(Navigator.push).  적응형: LayoutBuilder 600dp 분기(A-5).
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'b_detail_screen.dart';

/// 이 너비 이상이면 넓은 화면 배치 (Material 3: medium ≥ 600dp)
const wideBreakpoint = 600.0;

class ListScreen extends StatefulWidget {
  const ListScreen({
    super.key,
    this.load = fetchItems,
    this.loadNotes = fetchNotes,
    this.loadHistory = fetchHistory,
  });

  final ItemsLoader load;
  final NotesLoader loadNotes;
  final HistoryLoader loadHistory;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late Future<List<Item>> _future = widget.load();
  late Future<List<History>> _history = widget
      .loadHistory(); // 세 번째 GET (결정 지갑)

  // STATE: S6 결정 잠금 → A-10 결정 지갑에 새 카드 추가 — 영구 저장 감점이라 db.json 예시 기록만 보여 줌

  // STATE: S1 검색어·카테고리 필터 → A-5 목록 — v3 상태관리 수업에서 구현 (지금은 표시만)

  void _retry() {
    setState(() {
      _future = widget.load();
    });
  }

  void _retryHistory() {
    setState(() {
      _history = widget.loadHistory();
    });
  }

  void _open(Item item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailScreen(item: item, loadNotes: widget.loadNotes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const _Brand(), // A-1 P02
      ),
      body: FutureBuilder<List<Item>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView(label: '고민 목록을 불러오는 중…'); // A-2 P01
          }
          if (snap.hasError) {
            return ErrorView(
              title: '고민 목록을 불러오지 못했어요.',
              message: '${snap.error}',
              onRetry: _retry,
            ); // A-3 P09
          }
          final items = snap.data ?? const <Item>[];
          if (items.isEmpty) {
            return EmptyView(
              message: '아직 등록된 고민이 없어요.\n새 고민이 추가되면 여기에 보여요.',
              actionLabel: '새로고침',
              onAction: _retry,
            ); // A-4 P01
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= wideBreakpoint; // A-5 P07
              final pad = EdgeInsets.symmetric(horizontal: wide ? 32 : 20);
              final header = Padding(
                padding: pad.copyWith(top: 4, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Hero(),
                    const SizedBox(height: 22),
                    _WalletSection(future: _history, onRetry: _retryHistory),
                    const SizedBox(height: 22),
                    SectionLabel(
                      '고민 ${items.length}개',
                      note: '탭 한 번이면 옵션까지 준비돼 있어요',
                    ), // A-8 P01
                  ],
                ),
              );
              if (wide) {
                // 넓은 화면: 왼쪽 = 큰 제목 · 결정 지갑, 오른쪽 = 결정 상황 격자 (iPad식 2단)
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 380, child: ListView(children: [header])),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          0,
                          4,
                          32,
                          32,
                        ), // A-5 P07 넓은 화면: 격자
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 400,
                              mainAxisExtent: 136,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                        itemCount: items.length,
                        itemBuilder: (context, i) => SituationCard(
                          items[i],
                          onTap: () => _open(items[i]),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 32), // A-5 P07 폰: 목록
                itemCount: items.length + 1,
                separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 0 : 10),
                itemBuilder: (context, i) => i == 0
                    ? header
                    : Padding(
                        padding: pad,
                        child: SituationCard(
                          items[i - 1],
                          onTap: () => _open(items[i - 1]),
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 브랜드 — 검은 네모 "골" + 이름 + 부제
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Tok.ink,
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Text(
            '골',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '골라줘',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
            ),
            Text(
              '선택장애 구급대 🚑',
              style: TextStyle(fontSize: 11.5, color: Tok.muted),
            ),
          ],
        ),
      ],
    );
  }
}

/// 화면의 단 하나의 주인공 — 큰 질문 + 탭 3번 안내 + 고민 수
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '무슨 결정?',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.15,
          ),
        ), // A-1 P02
        const SizedBox(height: 4),
        const Text(
          '고민을 고르면, 게임으로 끝내 줄게.',
          style: TextStyle(fontSize: 14, color: Tok.ink2),
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _Step('1', '고민 고르기'),
            _Step('2', '골라줘!'),
            _Step('3', '결정 잠금'),
          ],
        ), // A-9 P10
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.no, this.label);

  final String no;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
        color: Tok.surface,
        border: Border.all(color: Tok.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Tok.ink,
              shape: BoxShape.circle,
            ),
            child: Text(
              no,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// 결정 상황 카드 한 장 — 이모지 타일 + 제목 + 한 줄 설명 + 칩(카테고리 · 옵션 수 · 추천 게임)
class SituationCard extends StatelessWidget {
  const SituationCard(this.item, {super.key, this.onTap});

  final Item item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return RoundCard(
      onTap: onTap, // A-6 P06 카드 전체가 버튼 — 고르기만 하면 된다
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Row(
        children: [
          EmojiTile(item.emoji),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: Tok.muted),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    for (final (i, t) in item.tags.indexed)
                      SoftChip(
                        t,
                        dot: i == 0 ? catColor(t) : null,
                      ), // A-7 P04 · A-8 P01
                    if (item.mode.isNotEmpty)
                      SoftChip('🎮 ${item.mode}', accent: true), // A-8 P01
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            CupertinoIcons.chevron_forward,
            size: 18,
            color: Color(0xFFC7C7CC),
          ),
        ],
      ),
    );
  }
}

/// 결정 지갑 섹션 — GET /history 3상태(로딩 · 오류 · 빈)를 작게 그린다
class _WalletSection extends StatelessWidget {
  const _WalletSection({required this.future, required this.onRetry});

  final Future<List<History>> future;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('결정 지갑', note: '잠근 결정 · 인증 사진'),
        const SizedBox(height: 10),
        FutureBuilder<List<History>>(
          future: future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 64,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ); // A-10 P01
            }
            if (snap.hasError) {
              return RoundCard(
                padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '지난 결정을 불러오지 못했어요.',
                        style: TextStyle(fontSize: 13, color: Tok.ink2),
                      ),
                    ),
                    TextButton(onPressed: onRetry, child: const Text('다시 시도')),
                  ],
                ),
              ); // A-10 P09
            }
            final list = snap.data ?? const <History>[];
            if (list.isEmpty) {
              return const RoundCard(
                child: Text(
                  '🗂 아직 잠근 결정이 없어요. 첫 결정을 잠그면 여기 카드로 쌓여요.',
                  style: TextStyle(fontSize: 13, color: Tok.ink2),
                ),
              ); // A-10 P01
            }
            return WalletStack(list.take(4).toList()); // A-10 P06
          },
        ),
      ],
    );
  }
}

/// Apple Wallet처럼 겹친 카드 — 누른 카드가 맨 앞(아래)으로 펼쳐진다 (setState만)
class WalletStack extends StatefulWidget {
  const WalletStack(this.items, {super.key});

  final List<History> items;

  @override
  State<WalletStack> createState() => _WalletStackState();
}

class _WalletStackState extends State<WalletStack> {
  int _front = 0;

  static const _peek = 64.0;
  static const _cardHeight = 150.0;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final order = [
      for (var i = 0; i < items.length; i++)
        if (i != _front) i,
      _front,
    ];
    return SizedBox(
      height: _peek * (items.length - 1) + _cardHeight,
      child: Stack(
        children: [
          for (final (slot, i) in order.indexed)
            AnimatedPositioned(
              key: ValueKey(items[i].id),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              top: slot * _peek,
              left: 0,
              right: 0,
              height: _cardHeight,
              child: GestureDetector(
                onTap: () => setState(() => _front = i),
                child: WalletCard(items[i], front: i == _front),
              ),
            ),
        ],
      ),
    );
  }
}

/// 지갑 카드 한 장 — 색 바탕 + 고른 것 + 날짜 · 장소 + 인증 사진
class WalletCard extends StatelessWidget {
  const WalletCard(this.h, {super.key, this.front = false});

  final History h;
  final bool front;

  Color get _color {
    final hex = h.color.replaceFirst('#', '');
    return Color(int.tryParse('FF$hex', radix: 16) ?? 0xFFFF5A36);
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c, Color.lerp(c, Colors.black, 0.28)!],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${h.situation} · ${h.date}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xCCFFFFFF),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${h.emoji} ${h.text}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  '📍 ${h.place}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xCCFFFFFF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '🔒 잠금 · ✅ ${h.checkin} · ${h.mood}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 92,
              height: 92,
              child: h.photo.isEmpty
                  ? _photoFallback()
                  : Image.network(
                      h.photo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _photoFallback(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoFallback() => Container(
    color: const Color(0x33FFFFFF),
    alignment: Alignment.center,
    child: Text(h.emoji, style: const TextStyle(fontSize: 40)),
  );
}
