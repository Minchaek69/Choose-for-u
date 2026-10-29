// 골라줘 v2 — 고민을 게임으로, 탭 3번에 결정 끝 · GAI3008 중간고사 (UI만 구현)
//
// ┌──────── 디자인 가이드 대응표: 앱 뼈대 ──────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명        │ 비즈니스 명칭(한글)              │ 원칙(P번호) │
// │ S-1  │ MaterialApp           │ 골라줘                           │ —           │
// │ S-2  │ ThemeData + Tok       │ 디자인 토큰(iOS 회색 + 코랄 하나)│ P04 일관성  │
// └────────────────────────────────────────────────────────────────────────────┘
// 화면 흐름(docs/디자인가이드.md 1장과 같게):
//   A 무슨 결정? ──쌓기(push)──▶ B 상세 [옆으로(tab): 옵션 | 결정 방식] ──덮기(modal)──▶ C 결과(임의)
// 기획 문서에 없는 화면은 만들지 않는다(감점).
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'screens/a_list_screen.dart';
import 'widgets.dart';

void main() => runApp(const MidProjectApp());

class MidProjectApp extends StatelessWidget {
  const MidProjectApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: Tok.accent).copyWith(
      primary: Tok.accent,
      onPrimary: Colors.white,
      surface: Tok.surface,
      onSurface: Tok.ink,
      outline: Tok.muted,
      outlineVariant: Tok.line,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return MaterialApp(
      title: '골라줘', // S-1
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: Tok.page, // S-2 P04
        textTheme: base.textTheme.apply(
          bodyColor: Tok.ink,
          displayColor: Tok.ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Tok.page,
          foregroundColor: Tok.ink,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Tok.ink,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Tok.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Tok.mark,
            shape: const StadiumBorder(),
            minimumSize: const Size(64, 52),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Tok.ink,
            side: const BorderSide(color: Tok.line),
            backgroundColor: Tok.surface,
            shape: const StadiumBorder(),
            minimumSize: const Size(64, 52),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Tok.muted),
        ),
        dividerColor: Tok.lineSoft,
        // iOS처럼 오른쪽에서 밀려 들어오는 화면 전환 (모든 플랫폼 같게)
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
            TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
          },
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Tok.page,
          dragHandleColor: Color(0xFFC7C7CC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Tok.ink,
          shape: StadiumBorder(),
        ),
      ),
      home: const ListScreen(),
    );
  }
}
