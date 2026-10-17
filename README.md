# NaSCon '26

Flutter client for NaSCon multi-sport league and club operations. The React/Vite
demo in `dashboard/` is a separate project; the app in `lib/` is Flutter.

## Run the app

```powershell
flutter pub get
flutter run
```

The app uses mock data by default. To connect it to the Express API, start the
backend (see [`backend/README.md`](./backend/README.md)) and set the API URL:

```powershell
flutter run --dart-define=USE_MOCK_BACKEND=false --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
```

On a physical device, use your computer's LAN address instead of `10.0.2.2`.

## Project layout

```text
lib/
  app/             App root and routes
  core/            Theme, configuration, networking, storage, shared widgets
  features/        Authentication, fixtures, standings, store, profile, etc.
  models/          Typed API and application models
  repositories/    Mock and API data sources
test/              Unit, widget, and integration tests
backend/           Express API
dashboard/         Separate React/Vite demo
```

## Validate

```powershell
flutter analyze
flutter test
```
