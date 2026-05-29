# SignInScreen

## 概要

Google アカウントでのサインインを行う画面。未認証ユーザーが最初に操作する画面。

## ルート

```
/sign-in
```

## ソースファイル

`lib/presentation/views/auth/sign_in_screen.dart`

## UI

```
┌──────────────────────────────────┐
│                                  │
│         [school アイコン]         │
│                                  │
│      Classroom Remaked           │
│  Google Classroomをもっと使いやすく  │
│                                  │
│  ┌──────────────────────────┐   │
│  │ ▶  Google でサインイン    │   │
│  └──────────────────────────┘   │
│                                  │
└──────────────────────────────────┘
```

| 要素 | 詳細 |
|------|------|
| アイコン | `Icons.school_rounded`（サイズ 64、primary カラー） |
| タイトル | "Classroom Remaked"（`textTheme.h2`） |
| サブタイトル | "Google Classroomをもっと使いやすく"（`textTheme.muted`） |
| ボタン | `ShadButton` — "Google でサインイン" |

## 状態

| 状態 | ボタン表示 |
|------|-----------|
| 通常 | `Icons.login_rounded` + "Google でサインイン" テキスト |
| サインイン中 | `CircularProgressIndicator`（`strokeWidth: 2`）でボタン無効化 |

## インタラクション

### サインインボタン押下
1. `authViewModelProvider.notifier.signIn()` を呼び出す
2. 成功時：Router の `redirect` が `/notification-setup` または `/dashboard` へ自動遷移
3. 失敗時：`ShadToast.destructive` でエラートースト表示（タイトル "サインインに失敗しました"）

## 遷移元 / 遷移先

| 方向 | 画面 | 条件 |
|------|------|------|
| 遷移元 | `/splash` | 未認証 |
| 遷移先（成功） | `/notification-setup` | オンボーディング未完了 |
| 遷移先（成功） | `/dashboard` | オンボーディング完了済み |

## 依存

- `authViewModelProvider` — サインイン処理・ローディング状態管理
- `shadcn_ui` — `ShadButton`、`ShadToaster`、`ShadTheme`
