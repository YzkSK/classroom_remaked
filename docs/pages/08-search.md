# SearchScreen

## 概要

課題名でローカル検索を行う画面。ボトムナビゲーションの3番目のタブ。

## ルート

```
/search
```

## ソースファイル

`lib/presentation/views/search/search_screen.dart`

## UI 構成

```
┌──────────────────────────────────┐
│  AppBar: "検索"                   │
├──────────────────────────────────┤
│  🔍 [課題名で検索...]         × │  ← ShadInput
├──────────────────────────────────┤
│  （空クエリ）                     │
│  🔍  課題名で検索できます          │
│                                   │
│  （クエリあり・結果あり）           │
│  AssignmentCard (search)          │
│  AssignmentCard (search)          │
│                                   │
│  （クエリあり・結果なし）           │
│  「XXX」に一致する課題はありません   │
└──────────────────────────────────┘
```

---

## 検索入力（`ShadInput`）

| 要素 | 詳細 |
|------|------|
| プレースホルダー | "課題名で検索..." |
| 左アイコン | `Icons.search`（サイズ 16） |
| 右アイコン（クリア） | `Icons.close`（クエリが空でないときのみ表示） |

`onChanged` で `searchViewModelProvider.notifier.search(query)` を呼び出す（即時）。
クリアボタンタップで `TextEditingController.clear()` + `notifier.clear()` を実行。

---

## 検索状態の切り替え

| 状態 | 条件 | UI |
|------|------|-----|
| 初期 | `state.query.isEmpty` | `_buildEmptyPrompt` — 検索アイコン + "課題名で検索できます" |
| 結果あり | `query != empty && results.isNotEmpty` | `AssignmentCard`（variant: search）のリスト |
| 結果なし | `query != empty && results.isEmpty` | `_buildNoResults` — "「XXX」に一致する課題はありません" |

---

## 検索ロジック

検索処理は `searchViewModelProvider` が担う（ViewModel 内でローカルデータに対してフィルタ）。
ネットワークリクエストは発生しない（Drift DB のキャッシュ済みデータを対象とする）。

---

## 遷移元 / 遷移先

この画面からの明示的な画面遷移はない（`AssignmentCard` の `variant: search` はタップ無効の場合もある）。

## 依存

- `searchViewModelProvider` — 検索クエリ・結果管理
- `shadcn_ui` — `ShadInput`
- `AssignmentCard` — 結果の課題カード表示
