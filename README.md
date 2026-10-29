# 골라줘 v2 — 고민을 게임으로, 탭 3번에 결정 끝

GAI3008-01 응용모바일프로그래밍 중간고사 · 1인 프로젝트 · UI 프로토타입(Flutter + json-server GET)

## 앱 소개

| 칸 | 내용 |
|---|---|
| **앱 이름** | 골라줘 v2 |
| **부제** | 고민을 게임으로, 탭 3번에 결정 끝 |
| **카테고리** | 라이프스타일 · 엔터테인먼트 |
| **대상 사용자 / 사용 상황** | 작은 결정(메뉴·옷·주말·영화·쇼핑) 앞에서 비교만 반복하는 20대. 점심시간 직전·외출 10분 전·장바구니 앞에서, 폰으로 |
| **설명** | 1. 고민 상황을 고르면, 그 상황의 옵션 · **단톡방 친구들의 표** · 어울리는 **결정 게임**(듀얼 · 토너먼트 · 하나씩 지우기 · 가짜 랜덤 · 친구 투표 · 거부권)을 보여 주고 「골라줘!」 한 번에 결과를 낸다.<br>2. v2가 해결하는 문제: 현행 랜덤 휠 앱은 **매번 옵션을 직접 입력**해야 하고, 결과가 "그냥 랜덤"이라 **받아들이지 못하고 다시 돌리기를 반복**한다(리뷰 · 저니 최저점 "결과 확인").<br>3. v2 핵심 가치: **"결정을 대신해 주는 앱"이 아니라 "결정을 끝내게 해 주는 게임"** — 상황 템플릿(입력 0) + 게임형 결정 + 후회 테스트 + 결정 잠금. |
| **평가 및 리뷰 (현행)** | 비교 대상: **Decide Now! Spin the Wheel** (Catforce Studio) · App Store ★4.3 (6건, 지역 스토어) · Google Play 리뷰 3.52K · 대표 리뷰: "it is not that random…" ★1 (2021-11-13) — 전체는 `docs/기획.md` 1장 |
| **스크린샷** | `docs/screenshots/` — 01_A · 02_B_options · 03_B_games · 05_C_result · 06_C_twist(반전) · 07_C_stop · 09/10 넓은 화면 · 11 로딩 · 12 오류 · 13 빈 상태 |
| **새로운 기능** | 아래 표 |

### 새로운 기능 (v1 → v2에서 바뀐 것 3개)

| P번호 | 바뀐 것 (화면 · 요소 번호) | 근거 (리뷰 유형 · 원칙) |
|---|---|---|
| P06 | **상황 템플릿**: A-6 결정 상황 카드를 고르기만 하면 옵션이 이미 들어 있다 (입력 0번) | 리뷰 유형 ① "매번 입력" · 닐슨 6 재인 |
| P07 | **결정 게임 + 추천**: B-6 게임 카드에 상황별 "추천"이 미리 선택돼 있어 「골라줘!」 한 번 (탭 3번: A 카드 → 골라줘! → 결정 잠금) | 리뷰 유형 ③ "결과를 못 받아들임" · 닐슨 7 효율성 |
| P05 | **멈춤 설계**: C-6 후회 테스트 · C-8 「다시」 3번째에 STOP 배너 · C-7 결정 잠금(잠그면 다시 비활성) | 저니 최저점 "다시 돌리기 반복" · 닐슨 5 오류 예방 |

## 데모

- 데모 영상(1분): [`docs/영상/demo.mp4`](docs/영상/demo.mp4) — 고민 고르기 → 골라줘! → 반전 · STOP · 잠금 → 넓은 화면 → 오류 · 빈 상태
- 배포 URL(가산 +5, 선택): `https://<프로젝트>.vercel.app` — `mock_server/README.md` 5장

## 실행 방법

```bash
# 1) mock 서버 (터미널 A)
cd mock_server
npm install      # 처음 한 번
npm start        # http://localhost:3000  → /items (8개) · /notes?itemId=1 · /history (결정 지갑 4장)
```

```bash
# 2) 앱 (터미널 B, 저장소 루트)
flutter pub get
flutter run -d chrome
```

```bash
# 3) 로딩 · 오류 · 빈 상태 시연 (서버 없이도 됨)
flutter run -d chrome --dart-define=DEMO_STATE=loading   # error / empty 로 바꿔 실행
```

- B 화면의 빈 상태는 「🏃 운동 뭐 하지?」(옵션 0개)를 누르면 바로 보인다.
- 넓은 화면(≥600dp): Chrome 창을 넓히면 A가 2단(왼쪽 제목 · 결정 지갑 / 오른쪽 격자)으로 바뀐다.
- 결정 지갑 카드를 누르면 그 카드가 맨 앞으로 펼쳐진다. B 옵션 카드의 ✕로 하나씩 지우고, ❤️로 내 표를 넣을 수 있다.

## 폴더 구조

```
lib/
  main.dart                 앱 뼈대 (S-1 · S-2 브랜드 코랄)
  api.dart                  GET만 (fetchItems / fetchNotes / fetchHistory) + DEMO_STATE
  models.dart               Item(결정 상황) / Note(옵션 · 친구 표) / 결정 게임 6종 / 기분 3종
  widgets.dart              Tok(디자인 토큰) · Loading/Error/Empty · SoftChip · RoundCard · EmojiTile
  screens/
    a_list_screen.dart      A 무슨 결정?
    b_detail_screen.dart    B 상세 (지금 기분 · 옵션 | 결정 방식 · 골라줘!)
    c_result_sheet.dart     C 결과 시트 (결승 · 결과 · 후회 테스트 · 잠금/다시)
mock_server/db.json         history 4 (결정 지갑) · items 8 (상황) · notes 28 (옵션 · votes = 친구 예시 표 · pick:true = 예시 결과)
docs/                       기획 · 디자인가이드 · 원칙카드 · 셀프논증 · 자가평가 · prompt-log · 발표대본
```

## 규칙 준수 (안내 5장)

- GET만 · 영구 저장 없음 · 상태관리 패키지 없음 · 로그인/결제 없음 · 유료/LLM API 없음 · 추가 패키지는 `http` 하나
- 결정 지갑 · 인증 사진은 `db.json`의 `history` 예시(사진은 picsum 예시 이미지) — 앱은 아무것도 저장하지 않음
- 친구 표는 `db.json`의 `votes`(미리 모은 예시), 「친구 부르기」는 SnackBar만 — 실제 공유 · 전송 · 실시간 수집 없음
- 결과는 `db.json`에 `pick: true`로 **미리 표시한 값**, 「다시」는 db.json 순서대로 다음 옵션 — 계산·추천·랜덤 로직 없음. 화면에 "※ 예시 결과입니다 (실제 추천 로직 없음)" 표시(C-9)
- 자가 점검:

```bash
grep -rnE "http\.(post|put|patch|delete)|SharedPreferences|sqflite|hive|FirebaseAuth|ChangeNotifierProvider|Riverpod|BlocProvider" lib/ pubspec.yaml
```
