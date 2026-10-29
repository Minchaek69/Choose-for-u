# AGENTS.md — GAI3008 중간고사: UI 프로토타입 전용 규칙

## 목적
이 프로젝트는 실제 앱 v2의 **UI 프로토타입**이다. 보이기는 동작하는 것처럼, 실제 동작은 구현하지 않는다.
기준 문서: 중간고사 안내문 5장(허용과 감점). 이 파일은 Claude Code · Cursor · Copilot이 함께 읽는다.

## 반드시 지킬 것 (MUST)
- 화면 전환은 3방식만 쓴다: 쌓기 `Navigator.push`/`pop` · 옆으로 `TabBar`/`NavigationBar` · 덮기 `showModalBottomSheet`/`showDialog`.
- 데이터는 (1) 하드코딩 상수 또는 (2) 로컬 json-server(`mock_server/`, `http://localhost:3000` · Android 에뮬레이터 `http://10.0.2.2:3000`)의 **GET**만 쓴다. 요청은 `lib/api.dart`에만 둔다.
- 화면 안 표시 변화(탭 선택, 펼치기, 가짜 검색 결과)는 `StatefulWidget` + `setState`만 쓴다.
- GET을 쓰는 화면은 **로딩 / 오류 / 빈 상태** 3가지를 모두 그린다(`FutureBuilder` + `lib/widgets.dart`의 `LoadingView` · `ErrorView` · `EmptyView`).
- 레이아웃은 `LayoutBuilder` 또는 `MediaQuery.sizeOf`로 **창 너비** 기준 분기한다(기기 종류로 분기하지 않는다, 화면 방향 고정 금지).
- 위젯·클래스 이름은 기획서의 "비즈니스 명칭"과 맞춘다. 기획서(`docs/디자인가이드.md`)에 없는 화면은 만들지 않는다.
- 버튼이 실제 동작을 해야 하는 자리(결제, 로그인, 저장)는 **가짜 결과 화면 또는 SnackBar**로만 응답한다.

## 하지 말 것 (MUST NOT) — 구현 시 감점
- `http.post` / `put` / `patch` / `delete` 호출 금지.
- 로그인·회원가입·결제·인증 로직 금지 (Firebase Auth 등 포함).
- `shared_preferences`, `sqflite`, `hive`, 파일 쓰기 등 **영구 저장 금지**.
- `provider`, `riverpod`, `flutter_bloc`, `get`, `mobx` 등 **상태관리 패키지 추가 금지**.
- 실제 계산·추천 알고리즘·실시간 처리(WebSocket, Stream 구독) 금지.
- 외부 유료 API, LLM API 호출, 실제 개인정보 사용 금지. AI 기능은 **미리 쓴 가짜 응답**으로 보여 준다.
- `pubspec.yaml`에 패키지를 추가하기 전에 반드시 이유를 말하고 사람에게 확인받는다. (지금 추가 패키지는 `http` 하나)

## 작업 방식
- 한 번에 화면 하나만 만든다. 만들기 전에 그 화면의 위젯 트리(요소 번호 · 위젯명 · 비즈니스 명칭)를 먼저 보여 준다.
- 상태가 바뀌는 지점은 구현하지 말고 코드 주석으로 표시한다: `// STATE: <데이터> → <보여질 위젯>`
- 화면 파일 맨 위 **디자인 가이드 대응표** 주석(번호 · 위젯명 · 비즈니스 명칭 · 원칙)을 `docs/디자인가이드.md`와 같게 유지한다.
- 원칙을 보여 주는 위젯 줄 끝에 요소 번호와 원칙 번호를 단다: `// A-5 P09`. 커밋 메시지는 `p09: …`로 시작한다.
- 끝나면 `flutter analyze`가 0 issues인지 확인한다.

## 제출 전 자가 점검 (사람이 실행 — 규칙 파일은 참고 문맥이지 차단 장치가 아니다)
```bash
grep -rnE "http\.(post|put|patch|delete)|SharedPreferences|sqflite|hive|FirebaseAuth|ChangeNotifierProvider|Riverpod|BlocProvider" lib/ pubspec.yaml
```
결과가 비어 있어야 한다. 걸린 줄은 지운다(안내문 8장: "AI가 실제 동작을 넣었다면 지워야 감점이 없다").
