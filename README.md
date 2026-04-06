# avislap
A cross‑platform Flutter application for managing and performing **aircraft audits**.  
This app communicates with a backend API and supports multiple environments.
## API Base URL Setup

The app reads `API_BASE_URL` from `String.fromEnvironment()` in
`lib/services/app_api_service.dart`.

Included config files:

- `.env.development`
- `.env.android-emulator`
- `.env.production`

### Development

Web or desktop:

```bash
flutter run --dart-define-from-file=.env.development
```

Android emulator:

```bash
flutter run --dart-define-from-file=.env.android-emulator
```

### Production APK

Always build the APK with an explicit production base URL:

```bash
flutter build apk --release --dart-define-from-file=.env.production
```

You can also override it directly:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-domain.com/api
```

### Notes

- `10.0.2.2` only works from the Android emulator.
- A real phone needs a publicly reachable backend URL or your machine's LAN IP.
- `trycloudflare.com` URLs are temporary. Replace `.env.production` with your stable production API when available.
