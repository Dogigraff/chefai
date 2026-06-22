# ChefOS — запуск в iOS Simulator

## Требования

- macOS с **Xcode 15+**
- [Homebrew](https://brew.sh/) (для XcodeGen)

## Быстрый старт

```bash
git clone https://github.com/Dogigraff/chefai.git
cd chefai
chmod +x scripts/setup-ios.sh
./scripts/setup-ios.sh
open ChefOS.xcodeproj
```

В Xcode: выберите **iPhone Simulator** → **Product → Run** (⌘R).

## OpenAI (опционально)

Без ключа приложение работает в **mock-режиме** (3 демо-рецепта).

Для реальных запросов: **Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables**:

| Name | Value |
|------|--------|
| `OPENAI_API_KEY` | ваш ключ `sk-...` |

## Firebase (опционально)

По умолчанию Firebase **не подключён** — используется `MockAuthService`.

Для Firebase:
1. Добавьте SPM-пакет `https://github.com/firebase/firebase-ios-sdk` (FirebaseCore, FirebaseAuth).
2. Положите `GoogleService-Info.plist` в target ChefOS (не коммитьте в публичный репозиторий).

## Структура iOS-обвязки

```
project.yml              → XcodeGen: генерирует ChefOS.xcodeproj
ChefOS/Support/Info.plist → разрешения камеры, фото, микрофона, speech
ChefOS/Support/ChefOS.entitlements → Sign in with Apple
ChefOS/Resources/Assets.xcassets → иконка и AccentColor
.github/workflows/ios.yml → CI-сборка на macOS
```

## CI

При push в `main` GitHub Actions собирает проект и запускает `ChefOSTests` на `macos-15`.

## Windows

iOS Simulator на Windows недоступен. Используйте Mac, облачный Mac или проверяйте сборку через GitHub Actions (вкладка **Actions** в репозитории).
