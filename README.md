# CardWise

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-Express-339933?style=for-the-badge&logo=node.js&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-47A248?style=for-the-badge&logo=mongodb&logoColor=white)
![AI](https://img.shields.io/badge/AI-OpenRouter-111827?style=for-the-badge)

CardWise is an AI-first credit card rewards assistant that helps users choose the most rewarding card for every purchase. Users can manage their cards, ask natural-language spend questions, receive deterministic reward recommendations, and track the estimated rewards they saved by using CardWise.

## Product

CardWise is built around a simple chat-first workflow:

- Sign in or create an account.
- Add owned credit cards from the catalog.
- Ask spend questions such as `I am spending ₹12,000 on Swiggy`.
- Receive the best card recommendation from saved cards.
- Confirm whether the recommended card was used.
- Track CardWise profit and reward activity in the profile dashboard.

## Highlights

- AI-assisted chat interface for natural purchase input and follow-up questions.
- Deterministic reward engine for card selection and estimated reward calculation.
- MongoDB-backed user profiles, saved cards, merchants, catalog cards, and reward events.
- OpenRouter primary and fallback API key support.
- Flutter dark-theme mobile/web frontend with Provider architecture.
- Express API with modular controllers, services, models, middleware, and seed data.
- Production-oriented security defaults with Helmet, CORS configuration, JWT auth, bcrypt password hashing, and API rate limiting.

## Tech Stack

| Layer | Technology |
| --- | --- |
| Frontend | Flutter, Provider, HTTP, SharedPreferences, Flutter SVG |
| Backend | Node.js, Express, Mongoose |
| Database | MongoDB |
| Auth | JWT, bcrypt |
| AI | OpenRouter chat completions |
| Dev Runtime | Nodemon, Flutter CLI, Android Debug Bridge |

## Repository Structure

```text
CardWise/
├── backend/      # Express API, Mongo models, reward engine, AI services
└── frontend/     # Flutter app for Android, web, and desktop targets
```

## Prerequisites

- Flutter SDK
- Node.js 20+
- npm
- MongoDB connection string
- OpenRouter API key
- Android device with USB debugging enabled for mobile testing

## Backend Setup

```sh
cd backend
npm install
cp .env.example .env
```

Configure `backend/.env`:

```env
NODE_ENV=development
PORT=3000
CORS_ORIGIN=*
MONGO_URI=mongodb+srv://user:password@cluster.mongodb.net/creditwise
MONGO_SERVER_SELECTION_TIMEOUT_MS=5000
JWT_SECRET=replace-with-a-long-random-secret
JWT_EXPIRES_IN=7d
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
OPENROUTER_MODEL=openai/gpt-4.1-mini
OPENROUTER_API_KEY_PRIMARY=replace-with-primary-openrouter-key
OPENROUTER_API_KEY_FALLBACK=replace-with-fallback-openrouter-key
```

Run the API in development mode:

```sh
npm run dev
```

Health check:

```sh
curl http://localhost:3000/health
```

Production start:

```sh
npm start
```

## Frontend Setup

```sh
cd frontend
flutter pub get
```

Run on Chrome:

```sh
cp env/development.example.json env/development.json
flutter run -d chrome --dart-define-from-file=env/development.json
```

Run on a connected Android phone through USB port forwarding:

```sh
adb reverse tcp:3000 tcp:3000
flutter run -d <device-id> --dart-define-from-file=env/development.json
```

Build Android debug APK:

```sh
flutter build apk --debug --dart-define-from-file=env/development.json
```

Install the APK:

```sh
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Build web:

```sh
cp env/production.example.json env/production.json
flutter build web --dart-define-from-file=env/production.json
```

## API Overview

| Area | Endpoint |
| --- | --- |
| Health | `GET /health` |
| Auth | `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/auth/me` |
| Cards | `GET /api/cards/catalog`, `GET /api/cards/mine`, `POST /api/cards/mine`, `DELETE /api/cards/mine/:id` |
| Chat Recommendations | `POST /api/recommendations/chat` |
| Manual Recommendations | `POST /api/recommendations` |
| Recommendation Confirmation | `POST /api/recommendations/confirm` |
| Profile | `GET /api/profile/reward-stats`, `PATCH /api/profile` |
| AI Parsing | `POST /api/ai/parse-intent` |

## Development Checks

Backend:

```sh
cd backend
npm test
```

Frontend:

```sh
cd frontend
flutter analyze
flutter test
```

Web build verification:

```sh
cd frontend
cp env/production.example.json env/production.json
flutter build web --dart-define-from-file=env/production.json
```

Android build verification:

```sh
cd frontend
flutter build apk --debug --dart-define-from-file=env/development.json
```

## Architecture

CardWise keeps recommendation quality predictable by separating AI interaction from reward calculation.

- OpenRouter parses natural-language input and responds to conversational follow-ups.
- The backend reward engine scores saved cards using catalog and merchant rules.
- Confirmed recommendations are stored as reward events for profile analytics.
- Current-chat context is passed as compact structured data for session-level questions.
- User credentials, profile data, card ownership, and reward events are persisted in MongoDB.

## License

This project is licensed under the [MIT](./LICENSE.md) license.

Made with ❤️ by Aaron Kurian Abraham
