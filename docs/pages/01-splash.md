# SplashScreen

## 概要

アプリ起動時に最初に表示されるローディング画面。認証状態の確認が完了するまで表示され続ける。

## ルート

```
/splash
```

## ソースファイル

`lib/presentation/views/splash/splash_screen.dart`

## 役割

- アプリ起動直後の初期ルート（`initialLocation: '/splash'`）
- Router の `redirect` ロジックが認証状態を非同期に解決する間、ユーザーに待機 UI を提供する
- `authViewModelProvider` が `isLoading` の間はこの画面に留まり続ける

## UI

| 要素 | 内容 |
|------|------|
| 背景 | デフォルト `Scaffold` |
| 中央 | `ShadProgress(minHeight: 4, value: null)` — 不確定プログレスバー |

インタラクティブな要素は一切なく、ユーザーは何も操作できない。

## 遷移ロジック

この画面自体にナビゲーションコードはない。遷移はすべて `app_router.dart` の `redirect` が制御する。

```
認証ロード中      → /splash (留まる)
認証済み + オンボーディング未完了 → /notification-setup
認証済み + オンボーディング完了   → /dashboard
未認証            → /sign-in
```

## 依存

- `authViewModelProvider` — 認証状態監視
- `shadcn_ui` — `ShadProgress` ウィジェット
