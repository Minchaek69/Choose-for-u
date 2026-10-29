// 공용 화면 조각 — GET을 쓰는 화면은 모두 이 세 상태를 그린다 (AGENTS.md MUST).
//   LoadingView  불러오는 중   P01 시스템 상태의 가시성
//   ErrorView    오류 + 다시 시도   P09 오류 인식·진단·복구
//   EmptyView    빈 목록 안내   P01
// 문구는 docs/디자인가이드.md 의 명칭과 맞춘다.
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

/// 로딩 상태
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = '불러오는 중…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(label),
        ],
      ),
    );
  }
}

/// 오류 상태: 무엇이 잘못됐는지 + 다시 시도 버튼
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.title = '정보를 불러오지 못했습니다.',
    this.message = '',
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😵‍💫', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(message, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(CupertinoIcons.arrow_clockwise, size: 18),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 빈 상태: 목록이 비었을 때 안내 (+ 선택: 다음 행동 버튼)
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.message = '표시할 항목이 없습니다.',
    this.emoji = '🫥',
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String emoji;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// 네트워크 이미지 — 실패해도 화면은 그대로 보이게
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.width, this.height});

  final String url;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => SizedBox(
        width: width,
        height: height,
        child: const Icon(Icons.image_outlined, size: 40),
      ),
    );
  }
}

/// ───── 디자인 토큰 — iOS 시스템 회색 + 강조색은 코랄 하나 (P04 일관성) ─────
class Tok {
  static const page = Color(0xFFF2F2F7); // 화면 바탕 (iOS grouped background)
  static const surface = Color(0xFFFFFFFF); // 카드
  static const surface2 = Color(0xFFF9F9FB); // 보조 칸
  static const ink = Color(0xFF1C1C1E); // 주 글자
  static const ink2 = Color(0xFF3A3A3C); // 보조 글자
  static const muted = Color(0xFF8E8E93); // 약한 글자
  static const line = Color(0xFFE5E5EA); // 구분선 · 테두리
  static const lineSoft = Color(0xFFEFEFF4); // 옅은 구분선
  static const mark = Color(0xFFF2F2F7); // 칩 · 이모지 타일 바탕
  static const accent = Color(0xFFFF5A36); // 유일한 강조색 (코랄)
  static const accentInk = Color(0xFFC63A1A);
  static const accentBg = Color(0xFFFFF0EA);
  static const stop = Color(0xFFB2431C); // 그만 고민 배너 글자
  static const stopBg = Color(0xFFFDF3EE);
  static const stopLine = Color(0xFFF0C9B8);
}

/// 카테고리 색 — 칩 앞의 작은 점에만 쓴다 (색이 많아도 화면이 어지럽지 않게)
const categoryColors = <String, Color>{
  '음식': Color(0xFFF97316),
  '쇼핑': Color(0xFFEC4899),
  '활동': Color(0xFF3B82F6),
  '영화': Color(0xFF8B5CF6),
  '패션': Color(0xFF14B8A6),
  '여행': Color(0xFF10B981),
  '음료': Color(0xFFA16207),
  '운동': Color(0xFF65A30D),
};

Color? catColor(String tag) => categoryColors[tag];

/// 무채색 칩 — dot을 주면 앞에 색 점(카테고리), accent면 코랄 칩(추천 · 선택)
class SoftChip extends StatelessWidget {
  const SoftChip(this.label, {super.key, this.dot, this.accent = false});

  final String label;
  final Color? dot;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: accent ? Tok.accentBg : Tok.mark,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent ? Tok.accentInk : Tok.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

/// 흰 카드 — 테두리 없는 iOS 그룹 카드, 둥근 18. selected면 코랄 테두리 + 옅은 코랄 바탕 (P01)
class RoundCard extends StatelessWidget {
  const RoundCard({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Tok.accentBg : (color ?? Tok.surface),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: selected
            ? const BorderSide(color: Tok.accent, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// 이모지 타일 — 무채색 바탕 위 큰 이모지
class EmojiTile extends StatelessWidget {
  const EmojiTile(this.emoji, {super.key, this.size = 56});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Tok.mark,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.52)),
    );
  }
}

/// 섹션 머리 — 굵은 제목 + 옅은 보조 글
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.title, {super.key, this.note = ''});

  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Tok.ink,
          ),
        ),
        if (note.isNotEmpty) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: Tok.muted),
            ),
          ),
        ],
      ],
    );
  }
}
