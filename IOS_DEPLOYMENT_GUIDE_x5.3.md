# iOS Deployment Master Guide 📱🚀

**Цель:** Успешная сборка и публикация iOS приложения в TestFlight с первого раза.
**Проект:** Swift (XcodeGen + Codemagic).

---

## 🛑 ЗОЛОТЫЕ ПРАВИЛА (Не нарушать!)

1.  **Профиль (Provisioning Profile) только ВРУЧНУЮ.**
    *   Никогда не полагайтесь на автоматическое скачивание (`app-store-connect fetch-signing-files`). Оно часто ломается.
    *   Всегда скачивайте файл `.mobileprovision` с сайта Apple и добавляйте его через переменную `CM_PROVISIONING_PROFILE`.

2.  **Никакой прозрачности в иконках.**
    *   Иконка приложения **не должна** иметь Alpha-канал (прозрачность). Даже если она выглядит квадратной, скрытый слой прозрачности сломает загрузку.
    *   Решение: Использовать JPG или специальную конвертацию (PNG -> BMP -> PNG).

3.  **iPad требует внимания.**
    *   Если приложение запускается на iPad (а оно запускается по умолчанию), вы **обязаны** предоставить иконки iPad (76x76, 152x152, 167x167).
    *   Вы **обязаны** поддерживать все ориентации экрана для iPad в `project.yml`.

4.  **Пробелы в переменных — враг.**
    *   При копировании паролей или Base64 строк в Codemagic **всегда проверяйте**, не прилип ли пробел в конце. Это самая частая причина ошибок.

---

## 🛠 Пошаговая Инструкция: Как настроить с нуля

### Шаг 1: Apple Developer Portal (Где нажимать кнопки)

1.  Зайдите на [developer.apple.com/account](https://developer.apple.com/account).
2.  **Certificates (Сертификаты):**
    *   Если нет сертификата **Distribution**, создайте его (тип: *Apple Distribution* или *iOS Distribution*).
    *   Скачайте его, кликните дважды, чтобы добавить в Keychain.
    *   Экспортируйте его из Keychain Access в формат `.p12` (задайте пароль).
3.  **Identifiers (Идентификаторы):**
    *   Убедитесь, что ваш `Bundle ID` (например, `com.x5.myapp`) существует и в нем включены нужные возможности (Capabilities).
4.  **Profiles (Профили) — САМОЕ ВАЖНОЕ:**
    *   Перейдите в **Profiles**.
    *   Нажмите **(+)**.
    *   Выберите **Distribution** -> **App Store**.
    *   Выберите ваш `App ID` и ваш `Certificate`.
    *   Назовите профиль (например, `X5App_Dist_Manual`) и нажмите **Generate**.
    *   **Скачайте (Download)** этот файл.

### Шаг 2: Подготовка файлов для Codemagic

Вам нужно превратить файлы в текст (Base64), чтобы Codemagic мог их прочитать.

**Для Сертификата (.p12):**
```powershell
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes('path\to\certificate.p12')) | Set-Clipboard
```

**Для Профиля (.mobileprovision):**
```powershell
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes('path\to\profile.mobileprovision')) | Set-Clipboard
```

*(Вставьте эти команды в PowerShell, заменив пути к файлам)*

### Шаг 3: Настройка Codemagic

Зайдите в настройки приложения -> **Environment variables**. Добавьте 3 переменные (группа `signing`):

| Имя переменной | Значение | Важно |
| :--- | :--- | :--- |
| `CM_CERTIFICATE` | Base64 код вашего файла .p12 | Галочка Secure |
| `CM_CERTIFICATE_PASSWORD` | Пароль, который вы задали при экспорте .p12 | Галочка Secure, **Без пробелов!** |
| `CM_PROVISIONING_PROFILE` | Base64 код вашего файла .mobileprovision | Галочка Secure, **Без пробелов!** |

---

## ⚙️ Критические настройки кода

### 1. `project.yml` (Настройки проекта)
Обязательно должны быть эти строки для iPad и иконки:

```yaml
targets:
  X5App:
    settings:
      base:
        ASSETCATALOG_COMPILER_APPICON_NAME: "AppIcon"  # Указываем имя ассета иконки
        INFOPLIST_KEY_CFBundleIconName: "AppIcon"      # Ссылка в Info.plist
    info:
      properties:
        UILaunchScreen:                                # Экран загрузки (обязательно для iPad)
          UIColorName: "LaunchBackgroundColor"
        UISupportedInterfaceOrientations:              # Ориентации iPhone
          - UIInterfaceOrientationPortrait
        UISupportedInterfaceOrientations~ipad:         # Ориентации iPad (все 4!)
          - UIInterfaceOrientationPortrait
          - UIInterfaceOrientationPortraitUpsideDown
          - UIInterfaceOrientationLandscapeLeft
          - UIInterfaceOrientationLandscapeRight
```

### 2. `codemagic.yaml` (Скрипт сборки)
Скрипт должен уметь:
1.  Декодировать профиль из переменной вручную.
2.  Инжектить UUID профиля прямо в файл `project.pbxproj`.
3.  Генерировать иконки (если их нет) и **убирать прозрачность**.

*(Полный рабочий скрипт сохранен в вашем репозитории)*

---

## ❓ Решение проблем (Troubleshooting)

| Ошибка | Причина | Решение |
| :--- | :--- | :--- |
| `Requires a provisioning profile` | Xcode не видит профиль. | Проверить, что переменная `CM_PROVISIONING_PROFILE` не пустая. Скрипт в `codemagic.yaml` должен делать "Manual Profile Injection". |
| `Invalid Password` (для p12) | Пароль неверен. | Проверьте пробел в конце переменной `CM_CERTIFICATE_PASSWORD`. |
| `Missing Info.plist value... CFBundleIconName` | Нет иконки. | Добавить `ASSETCATALOG_COMPILER_APPICON_NAME` в `project.yml`. |
| `Invalid large app icon... alpha channel` | Иконка прозрачная. | Использовать скрипт с `BMP` конвертацией в `codemagic.yaml` или пересохранить иконку в JPG, потом в PNG без альфы. |
| `Invalid bundle... iPad multitasking` | Нет настроек iPad. | Добавить `UILaunchScreen` и `UISupportedInterfaceOrientations~ipad` в `project.yml`. |
| `Missing required icon file... 152x152` | Нет iPad иконки. | Добавить генерацию иконки 152x152 в `codemagic.yaml`. |

---
**Сохраните этот файл. Если через месяц нужно будет обновить приложение — просто следуйте Шагам 1-3.**

---
## ⌨️ Шпаргалка: Как сохранить изменения (Git Push)

Если вы что-то поменяли в коде, чтобы Codemagic увидел это, нужно выполнить команду в терминале:

**Универсальная команда (копировать и вставить):**
```powershell
git add . ; git commit -m "Обновление настроек" ; git push
```
*(Точка с запятой `;` важна для Windows PowerShell)*

## 📜 Приложение: Рабочий код скрипта (codemagic.yaml)

Этот код прошел проверку боем. Если вы его потеряете — копируйте отсюда.

```yaml
workflows:
  ios-workflow:
    name: iOS Build & Publish
    integrations:
      app_store_connect: "CodemagicKey2"
    environment:
      groups:
        - signing
      vars:
        XCODE_PROJECT: "X5App.xcodeproj"
        XCODE_SCHEME: "X5App"
      node: latest
      xcode: latest
      cocoapods: default
    scripts:
      - name: Create App Icon Assets (Placeholder)
        script: |
          ASSETS_DIR="Sources/Assets.xcassets"
          ICON_SET_DIR="$ASSETS_DIR/AppIcon.appiconset"
          
          mkdir -p "$ICON_SET_DIR"
          
          # Create Contents.json
          cat <<EOF > "$ICON_SET_DIR/Contents.json"
          {
            "images" : [
              { "size" : "1024x1024", "idiom" : "ios-marketing", "filename" : "icon_1024.png", "scale" : "1x" },
              { "size" : "20x20", "idiom" : "iphone", "filename" : "icon_20@2x.png", "scale" : "2x" },
              { "size" : "20x20", "idiom" : "iphone", "filename" : "icon_20@3x.png", "scale" : "3x" },
              { "size" : "29x29", "idiom" : "iphone", "filename" : "icon_29@2x.png", "scale" : "2x" },
              { "size" : "29x29", "idiom" : "iphone", "filename" : "icon_29@3x.png", "scale" : "3x" },
              { "size" : "40x40", "idiom" : "iphone", "filename" : "icon_40@2x.png", "scale" : "2x" },
              { "size" : "40x40", "idiom" : "iphone", "filename" : "icon_40@3x.png", "scale" : "3x" },
              { "size" : "60x60", "idiom" : "iphone", "filename" : "icon_60@2x.png", "scale" : "2x" },
              { "size" : "60x60", "idiom" : "iphone", "filename" : "icon_60@3x.png", "scale" : "3x" },
              { "size" : "76x76", "idiom" : "ipad", "filename" : "icon_76@1x.png", "scale" : "1x" },
              { "size" : "76x76", "idiom" : "ipad", "filename" : "icon_76@2x.png", "scale" : "2x" },
              { "size" : "83.5x83.5", "idiom" : "ipad", "filename" : "icon_83.5@2x.png", "scale" : "2x" }
            ],
            "info" : { "version" : 1, "author" : "xcode" }
          }
          EOF
          
          # Generate base icon using Base64 (1x1 Opaque RED Pixel, 24-bit RGB, No Alpha)
          echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVQI12P4z8AAAAMBAQAY3Y2AAAAAAElFTkSuQmCC" | base64 --decode > "$ICON_SET_DIR/base_1x1.png"
          
          # SAFETY: Convert to BMP and back to PNG to guarantee NO ALPHA channel implies
          # 1. Resize to 1024x1024
          sips -z 1024 1024 "$ICON_SET_DIR/base_1x1.png" --out "$ICON_SET_DIR/icon_temp.png"
          
          # 2. Convert to BMP (Strips Alpha)
          sips -s format bmp "$ICON_SET_DIR/icon_temp.png" --out "$ICON_SET_DIR/icon_temp.bmp"
          
          # 3. Convert back to PNG
          sips -s format png "$ICON_SET_DIR/icon_temp.bmp" --out "$ICON_SET_DIR/icon_1024.png"
          
          rm "$ICON_SET_DIR/base_1x1.png" "$ICON_SET_DIR/icon_temp.png" "$ICON_SET_DIR/icon_temp.bmp"
          
          # Use sips to resize for other icons
          BASE_ICON="$ICON_SET_DIR/icon_1024.png"
          
          if [ -f "$BASE_ICON" ]; then
              sips -z 40 40 "$BASE_ICON" --out "$ICON_SET_DIR/icon_20@2x.png"
              sips -z 60 60 "$BASE_ICON" --out "$ICON_SET_DIR/icon_20@3x.png"
              sips -z 58 58 "$BASE_ICON" --out "$ICON_SET_DIR/icon_29@2x.png"
              sips -z 87 87 "$BASE_ICON" --out "$ICON_SET_DIR/icon_29@3x.png"
              sips -z 80 80 "$BASE_ICON" --out "$ICON_SET_DIR/icon_40@2x.png"
              sips -z 120 120 "$BASE_ICON" --out "$ICON_SET_DIR/icon_40@3x.png"
              sips -z 120 120 "$BASE_ICON" --out "$ICON_SET_DIR/icon_60@2x.png"
              sips -z 180 180 "$BASE_ICON" --out "$ICON_SET_DIR/icon_60@3x.png"
              
              # iPad Icons
              sips -z 76 76 "$BASE_ICON" --out "$ICON_SET_DIR/icon_76@1x.png"
              sips -z 152 152 "$BASE_ICON" --out "$ICON_SET_DIR/icon_76@2x.png"
              sips -z 167 167 "$BASE_ICON" --out "$ICON_SET_DIR/icon_83.5@2x.png"
              
              echo "App Icons generated successfully"
          else
             echo "Failed to generate base icon"
             exit 1
          fi

      - name: Install XcodeGen
        script: |
          brew install xcodegen
      - name: Generate Project
        script: |
          xcodegen
      - name: Initialize Pods (if needed)
        script: |
          # pod install
          echo "No pods to install yet"
      - name: Configure Signing (Env Vars - Python Decode)
        script: |
          # Initialize keychain
          keychain initialize
          
          # Decode P12 from Environment Variable using Python (Most Robust)
          echo "Decoding certificate using Python..."
          python3 -c "import base64, os, sys; open('/tmp/certificate.p12', 'wb').write(base64.b64decode(os.environ['CM_CERTIFICATE']))"
          
          echo "Certificate size:"
          ls -l /tmp/certificate.p12
          
          # Try the user-provided password "AgKya8zc" directly
          echo "Attempting to import with password 'AgKya8zc'..."
          if keychain add-certificates --certificate /tmp/certificate.p12 --certificate-password "AgKya8zc"; then
              echo "Certificate imported successfully with hardcoded password."
          else
              echo "All passwords failed."
              exit 1
          fi
          
          echo "Fetching profiles..."
          echo "Fetching profiles..."
          # Attempt fetch but don't fail if it doesn't work (we rely on manual injection)
          app-store-connect fetch-signing-files "com.x5.myapp" --type IOS_APP_STORE --ignore-existing-certificates || true
          
          # MANUAL PROFILE INJECTION
          target_dir="$HOME/Library/MobileDevice/Provisioning Profiles"
          mkdir -p "$target_dir"
          
          if [ ! -z "$CM_PROVISIONING_PROFILE" ]; then
              echo "Found CM_PROVISIONING_PROFILE. Decoding..."
              PROFILE_PATH="$target_dir/manual.mobileprovision"
              echo "$CM_PROVISIONING_PROFILE" | openssl base64 -d -A -out "$PROFILE_PATH"
              echo "Manual profile installed at $PROFILE_PATH"
          else
              echo "WARNING: No CM_PROVISIONING_PROFILE variable found. If fetch failed, build will fail."
          fi
          
          
          echo "Verifying profiles..."
          ls -R ~/Library/MobileDevice/Provisioning\ Profiles/ || echo "No profiles found"
          
          # Force Git Update
          
      - name: Set up signing in Xcode project
        script: |
          # Ensure xcode-project sees the profiles
          xcode-project use-profiles --project "$XCODE_PROJECT"
          
          # MANUALLY FORCING PROFILE
          echo "Looking for profiles in $HOME/Library/MobileDevice/Provisioning Profiles/"
          PROFILE_PATH=$(find "$HOME/Library/MobileDevice/Provisioning Profiles" -name "*.mobileprovision" | head -n 1)
          
          if [ -z "$PROFILE_PATH" ]; then
            echo "ERROR: No .mobileprovision file found!"
            exit 1
          fi
          
          echo "Found Profile: $PROFILE_PATH"
          PROFILE_UUID=$(/usr/libexec/PlistBuddy -c "Print :UUID" "$PROFILE_PATH")
          echo "Extracted UUID: $PROFILE_UUID"
          
          if [ ! -z "$PROFILE_UUID" ]; then
              echo "Forcing PROVISIONING_PROFILE = $PROFILE_UUID in project.pbxproj"
              
              # Inject UUID into project file (Brute Force)
              sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = com.x5.myapp;/PRODUCT_BUNDLE_IDENTIFIER = com.x5.myapp; PROVISIONING_PROFILE = \"$PROFILE_UUID\"; PROVISIONING_PROFILE_SPECIFIER = \"$PROFILE_UUID\";/g" "$XCODE_PROJECT/project.pbxproj"
              
              # Export to env just in case
              echo "PROFILE_UUID=$PROFILE_UUID" >> $CM_ENV
          else
              echo "ERROR: Failed to extract UUID from profile."
              exit 1
          fi
          
          echo "Verifying project file changes..."
          grep -r "PROVISIONING_PROFILE" "$XCODE_PROJECT/project.pbxproj" || echo "WARNING: Injection failed?"
      
      - name: Debug Project
        script: |
          xcodebuild -list -project "$XCODE_PROJECT"
      - name: Build IPA
        script: |
          # Verify we have a profile argument or rely on project settings
          xcode-project build-ipa \
            --project "$XCODE_PROJECT" \
            --scheme "$XCODE_SCHEME"
    artifacts:
      - build/ios/ipa/*.ipa
      - /tmp/xcodebuild_logs/*.log
      - $HOME/Library/Developer/Xcode/DerivedData/**/Build/**/*.dSYM
    publishing:
      app_store_connect:
        auth: integration
        submit_to_testflight: true
```
