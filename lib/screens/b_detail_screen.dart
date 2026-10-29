// 화면 B: 상세 — 지금 기분 + [옵션 | 결정 방식] 탭 + 골라줘!
//
// ┌──────── 디자인 가이드 대응표: B 상세 ───────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                    │ 비즈니스 명칭(한글)   │ 원칙(P번호)  │
// │ B-1  │ AppBar + BackButton               │ 상황 제목줄           │ P03 통제·자유│
// │ B-2  │ SegmentedButton (3칸)             │ 지금 기분(FEEL) 고르기│ P02 실세계   │
// │ B-3  │ TabBar + TabBarView               │ 옵션 | 결정 방식 탭   │ P06 재인     │
// │ B-4  │ LoadingView · ErrorView · EmptyView│ 옵션 불러오기 3상태  │ P01 · P09    │
// │ B-5  │ LayoutBuilder → ListView/GridView │ 옵션 카드 목록        │ P08 미니멀   │
// │ B-6  │ GameCard (RoundCard + 추천 배지)  │ 결정 게임 고르기      │ P07 효율성   │
// │ B-7  │ Container(노란 안내)              │ 게임 방식 안내        │ P10 도움말   │
// │ B-8  │ FilledButton + 설정 요약 Text     │ 골라줘! 버튼          │ P05 오류 예방│
// │ B-9  │ OutlinedButton → SnackBar         │ 친구 의견 모으기(가짜)│ P10 도움말   │
// │ B-10 │ 표 아바타 + IconButton(❤️)        │ 친구 표 · 내 한 표    │ P01 가시성   │
// │ B-11 │ IconButton(✕) + 취소선            │ 하나씩 지우기(거부권) │ P03 통제·자유│
// │ B-12 │ 한 줄 Text (🌍 % · 친구 표)       │ 🌍 모두의 선택 · 친구 표│ P06 재인   │
// │ B-13 │ TextButton(펼치기)                │ 더 많은 방법 보기     │ P08 미니멀   │
// └────────────────────────────────────────────────────────────────────────────┘
// 전환: A → B 쌓기(push) · B 안에서 옆으로(tab) · B → C 덮기(modal)
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'a_list_screen.dart' show wideBreakpoint;
import 'c_result_sheet.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.item,
    this.loadNotes = fetchNotes,
  });

  final Item item;
  final NotesLoader loadNotes;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<List<Note>> _future = _load();
  List<Note>? _notes; // 옵션을 다 불러와야 「골라줘!」를 켠다 (B-8)

  // 화면 안 표시만 바꾸는 값 — setState만 쓴다 (저장하지 않음)
  int _feeling = 1; // 😐 그냥
  final Set<int> _myVotes = {}; // 내가 ❤️ 누른 옵션 id — 화면 안에서만
  final Set<int> _vetoed = {}; // 내가 ✕로 지운 옵션 id — 화면 안에서만
  bool _moreGames = false; // 「더 많은 방법 보기」 펼침 — 기본은 4개만 (선택장애 배려, P08)

  /// 처음부터 보이는 기본 게임 4개 — 나머지는 펼쳐야 보인다
  static const _coreGames = ['듀얼', '토너먼트', '하나씩 지우기', '친구 투표'];
  late int _game = _recommendedGame;

  /// db.json의 mode(미리 정한 추천 게임)와 같은 이름의 카드 — 계산이 아니라 찾기만 한다.
  int get _recommendedGame {
    final i = decisionGames.indexWhere((g) => g.name == widget.item.mode);
    return i < 0 ? 0 : i;
  }

  Future<List<Note>> _load() async {
    final notes = await widget.loadNotes(widget.item.id);
    if (mounted) setState(() => _notes = notes);
    return notes;
  }

  void _retry() {
    setState(() {
      _notes = null;
      _future = _load();
    });
  }

  void _pick() {
    final notes = _notes;
    if (notes == null || notes.isEmpty) return;
    ResultSheet.show(
      context,
      item: widget.item,
      notes: notes,
      game: decisionGames[_game],
      feeling: feelings[_feeling],
      myVotes: _myVotes,
      vetoed: _vetoed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final canPick = _notes?.isNotEmpty ?? false;
    final game = decisionGames[_game];
    final (fEmoji, fName) = feelings[_feeling];
    final accent = item.tags.isNotEmpty ? catColor(item.tags.first) : null;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('고민 상세')), // B-1 P03 (뒤로 버튼 자동)
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Row(
                children: [
                  EmojiTile(item.emoji, size: 60),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            for (final (i, t) in item.tags.indexed)
                              SoftChip(t, dot: i == 0 ? accent : null),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  const Text(
                    '지금 기분',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Tok.ink2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SegmentedButton<int>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        backgroundColor: Tok.surface,
                        selectedBackgroundColor: Tok.ink,
                        selectedForegroundColor: Colors.white,
                        side: const BorderSide(color: Tok.line),
                        visualDensity: VisualDensity.compact,
                      ),
                      segments: [
                        for (final (i, (emoji, name)) in feelings.indexed)
                          ButtonSegment(value: i, label: Text('$emoji $name')),
                      ],
                      selected: {_feeling},
                      onSelectionChanged: (s) =>
                          setState(() => _feeling = s.first),
                    ), // B-2 P02
                  ),
                ],
              ),
            ),
            const TabBar(
              labelColor: Tok.ink,
              unselectedLabelColor: Tok.muted,
              indicatorColor: Tok.ink,
              dividerColor: Tok.line,
              labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              unselectedLabelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(text: '옵션'),
                Tab(text: '결정 방식'),
              ],
            ), // B-3 P06
            Expanded(child: TabBarView(children: [_optionsTab(), _gamesTab()])),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: Tok.surface,
            border: Border(top: BorderSide(color: Tok.line)),
          ),
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      !canPick
                          ? '옵션을 불러오면 고를 수 있어요'
                          : _notes!.length - _vetoed.length == 1
                          ? '🏁 하나 남았어! 이걸로 골라줘'
                          : '$fEmoji $fName 모드 · ${game.emoji} ${game.name} · 남은 옵션 ${_notes!.length - _vetoed.length}개',
                      style: const TextStyle(fontSize: 12.5, color: Tok.muted),
                    ), // B-8 P05 지금 설정을 한 줄로
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: canPick
                          ? _pick
                          : null, // B-8 P05 옵션이 없으면 누를 수 없다
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(58),
                      ),
                      child: const Text(
                        '골라줘!',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ✕ 지우기 — 마지막 하나는 지울 수 없다 (B-11 P05). 다시 누르면 되살린다 (P03).
  void _toggleVeto(int id, int total) {
    setState(() {
      if (_vetoed.contains(id)) {
        _vetoed.remove(id);
      } else if (total - _vetoed.length > 1) {
        _vetoed.add(id);
      }
    });
  }

  void _toggleVote(int id) {
    setState(
      () => _myVotes.contains(id) ? _myVotes.remove(id) : _myVotes.add(id),
    );
  }

  /// 친구 의견 모으기 — 실제 공유 · 전송 없이 SnackBar로만 응답 (AGENTS.md MUST)
  void _invite() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('단톡방 초대 링크를 복사했어요 (예시 — 실제 전송 없음)')),
    );
  }

  Widget _friendsHeader(List<Note> notes) {
    final voters = {for (final n in notes) ...n.votes};
    // STATE: S5 친구 표 실시간 모으기 → B-10 표 아바타 — 실시간 처리 · POST 금지라 예시 표만 보여 줌
    return RoundCard(
      color: Tok.surface2,
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          const Text('👯', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '단톡방 친구 ${voters.length}명 의견 도착',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  '끌리는 옵션에 ❤️ 를 누르면 내 표도 들어가요',
                  style: TextStyle(fontSize: 12, color: Tok.muted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _invite,
            child: const Text('친구 부르기'),
          ), // B-9 P10
        ],
      ),
    );
  }

  /// '옵션' 탭 — GET /notes?itemId=… (두 번째 GET)
  Widget _optionsTab() {
    return FutureBuilder<List<Note>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView(label: '옵션을 불러오는 중…'); // B-4 P01
        }
        if (snap.hasError) {
          return ErrorView(
            title: '옵션을 불러오지 못했어요.',
            message: '${snap.error}',
            onRetry: _retry,
          ); // B-4 P09
        }
        final notes = snap.data ?? const <Note>[];
        if (notes.isEmpty) {
          return EmptyView(
            emoji: '🧺',
            message: '아직 옵션이 없어요.\n이 고민은 준비 중 — 다른 고민을 골라 볼까요?',
            actionLabel: '목록으로',
            onAction: () => Navigator.of(context).pop(),
          ); // B-4 P01
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            Widget card(int i) => OptionCard(
              notes[i],
              myVote: _myVotes.contains(notes[i].id),
              onVote: () => _toggleVote(notes[i].id),
              vetoed: _vetoed.contains(notes[i].id),
              onVeto: () => _toggleVeto(notes[i].id, notes.length),
            );
            if (constraints.maxWidth >= wideBreakpoint) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _friendsHeader(notes),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        24,
                      ), // B-5 P08 넓은 화면: 격자
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 360,
                            mainAxisExtent: 92,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: notes.length,
                      itemBuilder: (context, i) => card(i),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                24,
              ), // B-5 P08 폰: 목록
              itemCount: notes.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) =>
                  i == 0 ? _friendsHeader(notes) : card(i - 1),
            );
          },
        );
      },
    );
  }

  /// '결정 방식' 탭 — 게임 소개 카드 (고르기만, 실제 대진·랜덤 로직 없음)
  Widget _gamesTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= wideBreakpoint ? 2 : 1;
        final cardWidth = (constraints.maxWidth - 40 - 10 * (cols - 1)) / cols;
        Widget gameCard(int i) => GameCard(
          decisionGames[i],
          selected: i == _game,
          recommended: i == _recommendedGame,
          onTap: () => setState(() => _game = i),
        ); // B-6 P07
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Tok.surface2,
                border: Border.all(color: Tok.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                style: TextStyle(fontSize: 13, color: Tok.ink2, height: 1.45),
                '💡 어떻게 골라 줄까? 이 상황에 어울리는 게임에 "추천"이 붙어 있어요. '
                '지금은 UI 프로토타입이라 실제 대진·랜덤 로직은 없어요.',
              ),
            ), // B-7 P10
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (i, g) in decisionGames.indexed)
                  if (_coreGames.contains(g.name) ||
                      i == _recommendedGame ||
                      i == _game)
                    SizedBox(width: cardWidth, child: gameCard(i)),
              ],
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => setState(() => _moreGames = !_moreGames),
              child: Text(_moreGames ? '접기 ▲' : '더 많은 방법 보기 (둘이서 · 가위바위보 등) ▼'),
            ), // B-13 P08
            if (_moreGames)
              for (final duo in [false, true]) ...[
                const SizedBox(height: 8),
                SectionLabel(
                  duo ? '👫 둘이서' : '🙋 더 해 보기',
                  note: duo ? '커플 · 친구 둘이 각자 원하는 게 다를 때' : '조금 더 재밌게',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final (i, g) in decisionGames.indexed)
                      if (g.duo == duo &&
                          !_coreGames.contains(g.name) &&
                          i != _recommendedGame &&
                          i != _game)
                        SizedBox(width: cardWidth, child: gameCard(i)),
                  ],
                ),
              ],
          ],
        );
      },
    );
  }
}

/// 옵션 카드 — 이모지 · 이름 · 한 줄 분위기 · 친구 표 아바타 · 내 ❤️
class OptionCard extends StatelessWidget {
  const OptionCard(
    this.note, {
    super.key,
    this.myVote = false,
    this.onVote,
    this.vetoed = false,
    this.onVeto,
  });

  final Note note;
  final bool myVote;
  final VoidCallback? onVote;
  final bool vetoed;
  final VoidCallback? onVeto;

  @override
  Widget build(BuildContext context) {
    final total = note.votes.length + (myVote ? 1 : 0);
    return Opacity(
      opacity: vetoed ? 0.45 : 1,
      child: RoundCard(
        selected: myVote && !vetoed,
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        child: Row(
          children: [
            EmojiTile(note.emoji, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      decoration: vetoed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (note.desc.isNotEmpty)
                    Text(
                      note.desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: Tok.muted),
                    ),
                  if (note.crowd > 0 || total > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (note.crowd > 0) '🌍 ${note.crowd}%',
                        if (total > 0)
                          '${[for (final v in note.votes) v.split(' ').first, if (myVote) '🙋'].join('')} $total표',
                      ].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Tok.ink2),
                    ), // B-10 P01 · B-12 P06
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onVeto,
              tooltip: vetoed ? '되살리기' : '지우기',
              icon: Icon(
                vetoed ? CupertinoIcons.arrow_uturn_left : CupertinoIcons.xmark,
                size: 18,
                color: Tok.muted,
              ),
            ), // B-11 P03
            IconButton(
              onPressed: vetoed ? null : onVote,
              tooltip: '내 한 표',
              icon: Icon(
                myVote ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                color: myVote ? Tok.accent : Tok.muted,
              ),
            ), // B-10 P01
          ],
        ),
      ),
    );
  }
}

/// 결정 게임 카드 — 고르면 코랄 테두리 + 체크, 이 상황 추천이면 배지
class GameCard extends StatelessWidget {
  const GameCard(
    this.game, {
    super.key,
    required this.selected,
    required this.recommended,
    required this.onTap,
  });

  final DecisionGame game;
  final bool selected;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RoundCard(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          EmojiTile(game.emoji, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      game.name,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (recommended) const SoftChip('추천', accent: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  game.howTo,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Tok.ink2,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            selected
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.circle,
            color: selected ? Tok.accent : Tok.line,
          ),
        ],
      ),
    );
  }
}
