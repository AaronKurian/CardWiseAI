# CardWise

Flutter frontend for CardWise, an AI-first credit card recommendation app.

## Development

Run with a backend URL:

```sh
cp env/development.example.json env/development.json
flutter run --dart-define-from-file=env/development.json
```

Build with production configuration:

```sh
cp env/production.example.json env/production.json
flutter build web --dart-define-from-file=env/production.json
```
