# ChefOS: структура репозитория и варианты запуска

Документ для переноса/обкатки продукта (в т.ч. Telegram Web App) и ориентиров по платформам.  
**Дата:** 2026-04-27

---

## 1. Верхний уровень

```
chefai/
├── .cursor/                    # настройки Cursor (если есть)
├── ChefOS/                     # основной код iOS-приложения (SwiftUI)
├── ChefOSTests/                # unit-тесты
├── stitch_welcome_screen/      # HTML-прототипы экранов (Stitch) для веб/TMA-наброска
├── audit_report.md
├── BETA_TESTING_GUIDE.md
├── deployment_resume.md
├── execution_log.md
├── final_fixes_report.md
├── Нчальное ТЗ.md              # исходное ТЗ
└── transfertotg.md             # этот файл
```

**Замечание:** в этой копии репозитория **нет** `.xcodeproj` / `.xcworkspace` — для сборки в Xcode обычно нужен полный проект с таргетом, `Info.plist`, `Assets.xcassets`, `GoogleService-Info.plist` (при Firebase). Проверьте, что у вас локально или в другом архиве есть эти артефакты.

---

## 2. ChefOS — дерево папок и файлов

### 2.1. App (точка входа, DI, корневой UI)

| Путь | Назначение |
|------|------------|
| `ChefOS/App/ChefOSApp.swift` | `@main`, SwiftData/InMemory, Firebase (опционально), `LanguageManager` |
| `ChefOS/App/RootView.swift` | ветвление: онбординг vs Dashboard |
| `ChefOS/App/AppContainer.swift` | DI: сервисы (storage, auth, OpenAI и т.д.) |

### 2.2. DesignSystem

| Путь | Назначение |
|------|------------|
| `ChefOS/DesignSystem/Colors.swift` | цвета Neo-Gourmet |
| `ChefOS/DesignSystem/Components.swift` | общие UI-компоненты |
| `ChefOS/DesignSystem/RecipeCard.swift` | карточка рецепта |
| `ChefOS/DesignSystem/ImageMapper.swift` | маппинг изображений |
| `ChefOS/DesignSystem/Localization.swift` | хелперы локализации |

### 2.3. Features

| Папка | Файлы | Назначение |
|-------|--------|------------|
| **Auth** | `WelcomeView`, `LoginView`, `RegistrationView`, `MedicalProfileView`, `AuthViewModel` | вход, регистрация, медпрофиль |
| **Onboarding** | `OnboardingView` | онбординг |
| **Dashboard** | `DashboardView`, `DashboardViewModel`, `CameraPreview` | главный кабинет, камера |
| **Main** | `MainTabView`, `HomeView`, `HomeViewModel`, `ProfileView` | табы, дом, профиль |
| **Cooking** | `CookingModeView` | режим готовки |
| **Recipes** | `RecipeChoiceView`, `RecipeDetailView` | выбор и детали рецепта |

### 2.4. Models

| Путь | Назначение |
|------|------------|
| `ChefOS/Models/RecipeAIModels.swift` | модели данных для AI/рецептов |

### 2.5. Services

| Путь | Назначение |
|------|------------|
| `ChefOS/Services/OpenAIService.swift` | запросы к OpenAI (рецепты, vision и т.д.) |
| `ChefOS/Services/AppConfig.swift` | `OPENAI_API_KEY`, `apiBaseURL` |
| `ChefOS/Services/StorageService.swift` | SwiftData / in-memory |
| `ChefOS/Services/AuthService.swift` | авторизация (mock/Firebase) |
| `ChefOS/Services/AppleSignInManager.swift` | Sign in with Apple |
| `ChefOS/Services/LanguageManager.swift` | язык UI |
| `ChefOS/Services/NotificationManager.swift` | уведомления |
| `ChefOS/Services/VoiceManager.swift` | голос |
| `ChefOS/Services/HapticManager.swift` | тактильная отдача |

### 2.6. Ресурсы локализации

| Путь | Назначение |
|------|------------|
| `ChefOS/Resources/en.lproj/Localizable.strings` | English |
| `ChefOS/Resources/ru.lproj/Localizable.strings` | Русский |
| `ChefOS/Resources/es.lproj/Localizable.strings` | Español |

### 2.7. Тесты

| Путь | Назначение |
|------|------------|
| `ChefOSTests/ChefOSSafetyTests.swift` | тесты безопасности/инвариантов |

---

## 3. stitch_welcome_screen — веб-прототипы

Каждая подпапка — отдельный экран; внутри, как правило, **`code.html`**.

```
stitch_welcome_screen/
├── welcome_screen/
├── login_screen/
├── registration_screen_1/ | registration_screen_2/
├── forgot_password_screen/
├── main_recipes_screen/
├── advanced_search_screen_1/ | advanced_search_screen_2/
├── search_by_ingredients_screen/
├── recipe_details_screen_1/ | recipe_details_screen_2/
├── create_new_recipe_screen/
├── favorites_screen_1/ | favorites_screen_2/
├── meal_planning_screen_1/ | meal_planning_screen_2/
├── shopping_list_screen_1/ | shopping_list_screen_2/
├── cooking_timer_screen_1/ | cooking_timer_screen_2/
├── step-by-step_cooking_screen/
├── cooking_tips_screen/
├── settings_screen/
├── user_profile_screen_1/ | user_profile_screen_2/
├── user_preferences_screen/
├── usage_&_achievements_screen_1/ | usage_&_achievements_screen_2/
```

Использование: **база для Telegram Mini App** (статика + `telegram-web-app.js`), без переноса Swift-кода.

---

## 4. Рекомендации по запуску и платформам

### 4.1. Нативный iOS (основной продукт)

- **Среда:** macOS, Xcode 15+ (целевой iOS 17+ по ТЗ).
- **Сборка:** открыть `.xcodeproj` / workspace, выбрать схему ChefOS, симулятор или устройство.
- **Секреты:** `OPENAI_API_KEY` в Environment Variables схемы (см. `AppConfig.swift`); в релизе — проксирование через backend, не ключ в бинарнике.
- **Firebase:** при использовании — положить `GoogleService-Info.plist`; иначе Firebase пропускается в коде.
- **Без Mac сейчас:** полноценно собрать iOS **нельзя**; варианты — облачный Mac, CI (GitHub Actions + `macos-latest`, Codemagic, Bitrise) или попросить коллегу собрать IPA/TestFlight.

### 4.2. Telegram Mini App (обкатка UX и сценариев без iOS)

- **Суть:** отдельное **веб-приложение** по HTTPS; SwiftUI не исполняется внутри Telegram.
- **Минимум:** статический хостинг (Cloudflare Pages, Vercel, Netlify) или HTTPS-туннель (ngrok) к локальному `http-server` / Vite.
- **Интеграция:** скрипт [Telegram Web Apps](https://core.telegram.org/bots/webapps), бот в @BotFather, URL Mini App.
- **AI:** **не** вшивать ключ OpenAI в фронт; прокси (Supabase Edge Function, Cloudflare Worker, свой API, n8n webhook).
- **Артефакты в репо:** `stitch_welcome_screen` — логичная отправная точка для вёрстки и навигации.

### 4.3. PWA / обычный браузер

- Те же веб-артефакты, что и для TMA; можно добавить `manifest.json` и service worker позже. Полезно для демо без Telegram.

### 4.4. Android (если появится запрос)

- Прямого Kotlin-порта в репозитории нет. Варианты: **Flutter/React Native** с общей бизнес-логикой на API; или оставить **только веб+TMA** для кросс-платформенного теста.

### 4.5. Безопасность и продукт

- Секреты только на сервере; лимиты и биллинг OpenAI — на прокси.
- Для TMA: учитывать [ограничения WebView](https://core.telegram.org/bots/webapps) (камера, файлы — по политике Telegram/бота).
- Соответствие `deployment_resume.md` и `BETA_TESTING_GUIDE.md` по чек-листам перед публичным тестом.

---

## 5. Краткая «дорожная карта» transfer → TG

1. Собрать **один** входной `index.html` (или Vite) и подключить `welcome_screen` / нужные экраны из `stitch_welcome_screen`.
2. Подключить `telegram-web-app.js`, вызвать `WebApp.ready()`, подстроить тему под `themeParams`.
3. Вынести вызовы к OpenAI в **backend**; фронт — только `fetch` к вашему URL.
4. Залить на HTTPS, прописать URL в боте, прогнать в Telegram на телефоне.

---

*Файл сгенерирован по фактическому составу папки `chefai` на момент редактирования; при появлении `.xcodeproj` и ассетов структуру Xcode стоит дописать в раздел 1–2.*
