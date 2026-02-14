# Firebase App Distribution CI 설정

이 프로젝트는 `GitHub Actions`로 `push` 시 Android/iOS 빌드를 만들고 Firebase App Distribution으로 자동 배포하도록 구성되어 있습니다.

워크플로 파일:
- `.github/workflows/firebase-app-distribution.yml`

기본 트리거:
- `push` to `main`, `develop`
- 수동 실행: `workflow_dispatch` (`both` / `android` / `ios`)

## 1) GitHub Secrets/Variables 설정

`Repository Settings > Secrets and variables > Actions`에서 아래 값을 등록하세요.

공통 Secrets:
- `FIREBASE_SERVICE_ACCOUNT_JSON`: Firebase 배포 권한이 있는 서비스 계정 JSON 원문
- `FIREBASE_TESTERS`: (선택) 콤마 구분 이메일 목록
- `FIREBASE_TESTER_GROUPS`: (선택) 콤마 구분 그룹 alias

주의:
- `FIREBASE_TESTERS` 또는 `FIREBASE_TESTER_GROUPS` 중 최소 1개는 반드시 필요합니다.

Android Secrets:
- `FIREBASE_ANDROID_APP_ID`: Firebase Android App ID (`1:xxxx:android:xxxx`)
- `ANDROID_KEYSTORE_BASE64`: 업로드 keystore 파일 base64
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

iOS Secrets:
- `FIREBASE_IOS_APP_ID`: Firebase iOS App ID (`1:xxxx:ios:xxxx`)
- `IOS_DISTRIBUTION_CERT_BASE64`: 배포 인증서 `.p12` base64
- `IOS_DISTRIBUTION_CERT_PASSWORD`: `.p12` 비밀번호
- `IOS_MOBILEPROVISION_BASE64`: Ad Hoc/Development 프로비저닝 프로파일 base64
- `IOS_TEAM_ID`: Apple Developer Team ID

iOS Variables:
- `IOS_BUNDLE_ID`: (권장) iOS Bundle ID. 미설정 시 기본값 `com.changmin.hyefit` 사용

## 2) 값 생성 방법

Android keystore base64:
```bash
base64 -i android/app/upload-keystore.jks | pbcopy
```

iOS cert/provisioning profile base64:
```bash
base64 -i ios_distribution.p12 | pbcopy
base64 -i profile.mobileprovision | pbcopy
```

Firebase App ID 확인:
- Firebase Console > Project settings > Your apps

서비스 계정 JSON:
- Google Cloud Console > IAM & Admin > Service Accounts
- Firebase App Distribution 권한이 있는 계정 키(JSON) 생성 후 전체 JSON 문자열을 `FIREBASE_SERVICE_ACCOUNT_JSON`에 저장

## 3) 동작 방식

Android:
1. `android/key.properties`를 CI에서 동적으로 생성
2. `flutter build apk --release`
3. `firebase appdistribution:distribute`로 업로드

iOS:
1. CI keychain 생성 후 `.p12` 인증서 import
2. provisioning profile 설치
3. `ios/ExportOptions.plist` 동적 생성
4. `flutter build ipa --release --export-options-plist=...`
5. `firebase appdistribution:distribute`로 업로드

## 4) 자주 발생하는 이슈

iOS 서명 실패:
- profile의 Bundle ID와 `IOS_BUNDLE_ID` 일치 여부 확인
- profile Team ID와 `IOS_TEAM_ID` 일치 여부 확인
- 배포 인증서와 profile 타입(Ad Hoc/Development) 조합 확인

테스터 전송 실패:
- `FIREBASE_TESTERS` 이메일 오타 확인
- `FIREBASE_TESTER_GROUPS` alias 존재 여부 확인

Android 서명 실패:
- `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEYSTORE_PASSWORD` 재확인

