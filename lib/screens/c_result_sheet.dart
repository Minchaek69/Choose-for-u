// 화면 C: 골라줘 결과(임의) — 덮기(modal)
//
// ┌──────── 디자인 가이드 대응표: C 결과(임의) ─────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                   │ 비즈니스 명칭(한글)    │ 원칙(P번호)  │
// │ C-1  │ showModalBottomSheet + 손잡이·닫기│ 결과 시트              │ P03 통제·자유│
// │ C-2  │ 4칸 진행 막대 (FEEL·FIGHT·REVEAL·LOCK)│ 결정 단계 표시     │ P01 가시성   │
// │ C-3  │ 결승 Text (A 🆚 B)               │ 마지막 대결            │ P02 실세계   │
// │ C-4  │ 결과 카드 (RoundCard)            │ 골라준 옵션 + 이유     │ P08 미니멀   │
// │ C-5  │ 브랜드 카피 Text                 │ 넌 이미 답을 알고 있었잖아 │ P02 실세계│
// │ C-6  │ OutlinedButton × 2 + 답 Text     │ 아쉬웠어? 반응 테스트  │ P06 재인     │
// │ C-7  │ FilledButton                     │ 결정 잠금 / 잠금 해제  │ P03 통제·자유│
// │ C-8  │ OutlinedButton + STOP 배너       │ 다시 · 그만 고민 배너  │ P05 오류 예방│
// │ C-9  │ 회색 고지 Text                   │ 예시 결과 고지         │ P10 도움말   │
// │ C-10 │ _DuoPanel (가위바위보 손 버튼)    │ 둘이서 정하기          │ P02 실세계   │
// └────────────────────────────────────────────────────────────────────────────┘
//
// ⚠ 실제 계산·추천·랜덤 로직 없음 (안내 5장).
//   결과 = db.json에서 pick: true 로 미리 표시한 옵션. 「다시」 = db.json 순서대로 다음 옵션(랜덤 아님).
import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets.dart';

class ResultSheet extends StatefulWidget {
  const ResultSheet({
    super.key,
    required this.item,
    required this.notes,
    required this.game,
    required this.feeling,
    this.myVotes = const {},
    this.vetoed = const {},
  });

  final Item item;
  final List<Note> notes;
  final DecisionGame game;
  final (String, String) feeling;
  final Set<int> myVotes; // B에서 내가 ❤️ 누른 옵션 (표 수 표시에만 씀)
  final Set<int> vetoed; // B에서 내가 ✕로 지운 옵션 — 결과 후보에서 뺀다

  /// 덮기(modal): 지금 화면 위에 잠깐 띄우고 닫는다.
  static Future<void> show(
    BuildContext context, {
    required Item item,
    required List<Note> notes,
    required DecisionGame game,
    required (String, String) feeling,
    Set<int> myVotes = const {},
    Set<int> vetoed = const {},
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true, // C-1 P03 끌어내리거나 바깥을 누르면 닫힌다
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Tok.page,
      builder: (_) => ResultSheet(
        item: item,
        notes: notes,
        game: game,
        feeling: feeling,
        myVotes: myVotes,
        vetoed: vetoed,
      ),
    );
  }

  @override
  State<ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<ResultSheet> {
  late int _index = _presetIndex;
  int _retries = 0; // 「다시」 누른 횟수 — 화면 안 표시만
  bool _locked = false;
  bool? _regret; // null = 아직 답 안 함 · true = 아쉬움 · false = 괜찮음

  // STATE: S3 결정 잠금 여부·결과 → (v3) 결정 일기 목록 — 영구 저장은 감점이라 구현하지 않음
  // STATE: S4 결과 만족도(😍/😐/😭) → (v3) 내 결정 스타일 카드 — 구현하지 않음

  /// 내가 지우지 않은 옵션들의 위치 (db.json 순서 그대로)
  late final List<int> _alive = [
    for (final (i, n) in widget.notes.indexed)
      if (!widget.vetoed.contains(n.id)) i,
  ];

  /// 처음 보여 줄 결과: 하나만 남겼으면 그것, 아니면 db.json의 pick (지웠으면 남은 것 중 첫째)
  int get _presetIndex {
    if (_alive.length == 1) return _alive.first;
    final i = widget.notes.indexWhere((n) => n.pick);
    return _alive.contains(i) ? i : _alive.first;
  }

  int _nextAlive(int from) =>
      _alive[(_alive.indexOf(from) + 1) % _alive.length];

  void _again() {
    setState(() {
      _index = _nextAlive(_index);
      _retries++;
      _regret = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final winner = widget.notes[_index];
    final rival = widget.notes[_nextAlive(_index)];
    final onlyOne = _alive.length == 1;
    final (fEmoji, fName) = widget.feeling;
    int votesOf(Note n) =>
        n.votes.length + (widget.myVotes.contains(n.id) ? 1 : 0);
    final battle = onlyOne
        ? '✂️ 네가 끝까지 남긴 단 하나'
        : widget.game.name == '친구 투표'
        ? '👯 친구 투표 결승 · ${winner.text} ${votesOf(winner)}표 vs ${rival.text} ${votesOf(rival)}표'
        : '${widget.game.emoji} ${widget.game.name} 결승 · ${winner.emoji} ${winner.text} vs ${rival.emoji} ${rival.text}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepBar(locked: _locked), // C-2 P01 지금 어느 단계인지
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Tok.surface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                battle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: Tok.ink2),
              ),
            ),
          ), // C-3 P02
          const SizedBox(height: 12),
          RoundCard(
            selected: _locked,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              children: [
                Text(winner.emoji, style: const TextStyle(fontSize: 60)),
                const SizedBox(height: 4),
                Text(
                  winner.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '💬 ${winner.reason.isNotEmpty ? winner.reason : '고민은 그만 — 이거면 충분해'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Tok.ink2,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                if (winner.crowd > 0) ...[
                  Text(
                    '🌍 같은 고민을 한 사람 ${winner.crowd}%도 이걸 골랐어',
                    style: const TextStyle(fontSize: 12.5, color: Tok.ink2),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  '$fEmoji $fName 모드 결과',
                  style: const TextStyle(fontSize: 12, color: Tok.muted),
                ),
              ],
            ),
          ), // C-4 P08
          const SizedBox(height: 14),
          const Text(
            '넌 이미 답을 알고 있었잖아 😉',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Tok.accentInk,
            ),
          ), // C-5 P02
          const SizedBox(height: 16),
          if (widget.game.duo) ...[
            _DuoPanel(game: widget.game), // C-10 P02
            const SizedBox(height: 14),
          ],
          if (!_locked) ...[
            RoundCard(
              color: Tok.surface2,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '이 결과 보고 살짝 아쉬웠어?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ReactionButton(
                          label: '😐 아니, 좋아',
                          selected: _regret == false,
                          onTap: () => setState(() => _regret = false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ReactionButton(
                          label: '😭 응…',
                          selected: _regret == true,
                          onTap: () => setState(() {
                            // 🔄 반전: 아쉬워하면 바로 대결 상대로 뒤집는다 (db.json 순서의 다음 옵션 — 랜덤 아님)
                            if (_regret != true && _alive.length > 1) {
                              _index = _nextAlive(_index);
                            }
                            _regret = true;
                          }),
                        ),
                      ),
                    ],
                  ), // C-6 P06
                  if (_regret != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _regret!
                          ? '🔄 반전! 아쉬웠다면 그게 답이야 — 그럼 이걸로 가자!'
                          : '좋아, 그럼 결정 끝! 아래에서 잠가 버리자 🔒',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Tok.ink2),
                    ), // C-6 P06
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (_retries >= 2 && !_locked) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Tok.stopBg,
                border: Border.all(color: Tok.stopLine),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '✋ STOP. 벌써 ${_retries + 1}번째 결과야.\n'
                '넌 결정 문제가 아니라 "허락"이 필요한 거야. 지금 이걸로 잠그자!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Tok.stop,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
            ), // C-8 P05 무한 비교 멈추기
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () => setState(() => _locked = !_locked),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: _locked ? Tok.ink : Tok.accent,
                  ),
                  child: Text(_locked ? '🔓 잠금 해제' : '🔒 결정 잠금'),
                ), // C-7 P03 잠가도 되돌릴 수 있다
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: _locked || onlyOne
                      ? null
                      : _again, // C-8 P05 잠그면 다시 못 누른다
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text('🎲 다시'),
                ),
              ),
            ],
          ),
          if (_locked) ...[
            const SizedBox(height: 10),
            const Text(
              '🔒 결정 완료! 오늘은 다른 옵션 다시 보지 않기 (예시)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Tok.accentInk,
                fontWeight: FontWeight.w700,
              ),
            ), // C-7 P03
          ],
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ), // C-1 P03
          const Text(
            '※ 예시 결과입니다 (실제 추천 로직 없음)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Tok.muted),
          ), // C-9 P10
        ],
      ),
    );
  }
}

/// FEEL · FIGHT · REVEAL · LOCK 4칸 진행 막대 — 잠그면 마지막 칸까지 채워진다
class _StepBar extends StatelessWidget {
  const _StepBar({required this.locked});

  final bool locked;

  static const _steps = ['FEEL', 'FIGHT', 'REVEAL', 'LOCK'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, name) in _steps.indexed) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: (i < 3 || locked) ? Tok.accent : Tok.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: (i < 3 || locked) ? Tok.ink : Tok.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// 후회 테스트 버튼 — 고른 쪽은 검정으로 채운다
class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        backgroundColor: selected ? Tok.ink : Tok.surface,
        foregroundColor: selected ? Colors.white : Tok.ink,
        side: BorderSide(color: selected ? Tok.ink : Tok.line),
      ),
      child: Text(label),
    );
  }
}

/// 둘이서 정하기 — 가위바위보는 한 폰으로 각자 손을 내고 동시에 공개 (랜덤 없음, 사람이 낸 손만 보여 준다)
class _DuoPanel extends StatefulWidget {
  const _DuoPanel({required this.game});

  final DecisionGame game;

  @override
  State<_DuoPanel> createState() => _DuoPanelState();
}

class _DuoPanelState extends State<_DuoPanel> {
  static const _hands = ['✊', '✌️', '🖐'];
  int? _me;
  int? _you;

  bool get _isRps => widget.game.name == '가위바위보';

  Widget _row(String who, int? picked, ValueChanged<int> onPick) {
    final hidden = picked != null && (_me == null || _you == null);
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            who,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        if (hidden)
          const Expanded(
            child: SizedBox(
              height: 44,
              child: Center(
                child: Text(
                  '🤫 냈어!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Tok.ink2,
                  ),
                ),
              ),
            ),
          )
        else
          for (final (i, h) in _hands.indexed) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: picked == null ? () => onPick(i) : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  padding: EdgeInsets.zero,
                  backgroundColor: picked == i ? Tok.accentBg : Tok.surface,
                  side: BorderSide(color: picked == i ? Tok.accent : Tok.line),
                ),
                child: Text(h, style: const TextStyle(fontSize: 20)),
              ),
            ),
            if (i < 2) const SizedBox(width: 6),
          ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRps) {
      return RoundCard(
        color: Tok.surface2,
        padding: const EdgeInsets.all(12),
        child: Text(
          '👫 둘이서 · ${widget.game.emoji} ${widget.game.name} — ${widget.game.howTo}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Tok.ink2),
        ),
      );
    }
    final done = _me != null && _you != null;
    return RoundCard(
      color: Tok.surface2,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '✊ 가위바위보 — 폰을 돌려 가며 각자 몰래 내기',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _row('🙋 나', _me, (i) => setState(() => _me = i)),
          const SizedBox(height: 6),
          _row('🙋‍♂️ 너', _you, (i) => setState(() => _you = i)),
          if (done) ...[
            const SizedBox(height: 10),
            Text(
              '${_hands[_me!]}  vs  ${_hands[_you!]}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 30),
            ),
            Text(
              '이긴 사람 마음대로! (승부 판정은 둘이 직접 — 앱은 손만 보여 줘요)',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Tok.accentInk,
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _me = null;
                _you = null;
              }),
              child: const Text('한 판 더'),
            ),
          ],
        ],
      ),
    );
  }
}
