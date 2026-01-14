# X5 iOS App — Правила и Суть

## Главная задача приложения:
1. **Открыть URL** `https://x5marketing.com` в WebView
2. **Слушать команды** от сайта через JavaScript bridge `x5App`
3. **Выполнять нативные действия**, которые сайт сам не может:
   - Google Login (нативный, через GIDSignIn или ASWebAuthenticationSession)
   - Apple Pay / In-App Purchases
   - Haptic Feedback (вибрация)
   - Push Notifications (в будущем)

## Структура Bridge (Web → Swift):
Сайт отправляет JSON через:
```javascript
window.webkit.messageHandlers.x5App.postMessage(JSON.stringify({
  type: "PAYMENT_REQUEST" | "LOGIN_GOOGLE" | "HAPTIC",
  payload: { ... }
}));
```

## Структура ответа (Swift → Web):
Swift отправляет результат обратно через:
```swift
webView.evaluateJavaScript("window.postMessage(\(jsonString), '*')")
```

## КРИТИЧЕСКИЕ ПРАВИЛА:
1. **ВСЕГДА вызывать `webView.load(URLRequest(url: url))`** в `makeUIView` — иначе ничего не загрузится!
2. URL хранится в `Config.swift` — `Config.targetURL`
3. Имя message handler строго `x5App`
4. UserAgent должен содержать `X5IOSClient` для идентификации платформы

## Версионирование:
- `MARKETING_VERSION` — версия для пользователей (1.0.3)
- `CURRENT_PROJECT_VERSION` — номер билда (16, 17, 18...)
- Менять в: `project.yml`, `Info.plist`, `codemagic.yaml` (agvtool и archive-flags)

## Публикация:
- `submit_to_testflight: true` — загружает в TestFlight (НЕ в публичный App Store)
- Публикация в App Store требует ручного нажатия "Submit for Review" в App Store Connect
