# Request Handling Workflow (Flutter + Node)

## Run Backend
```bash
cd backend
npm install
npm start    # http://localhost:4000
```

## Run Flutter App
```bash
cd flutter_app
flutter pub get
flutter run
```

If running on a physical device, set the base URL in `lib/state.dart` to your machine IP (e.g., `http://192.168.1.10:4000`).

## API
- `POST /requests` `{ userId, items:[string], receiverId? }`
- `GET /requests?role=enduser&userId=USER`
- `GET /requests?role=receiver&receiverId=RID`
- `PATCH /requests/:id/confirm` `{ receiverId, results:[{index, available:boolean}] }`

## Notes
- In-memory data store for simplicity.
- Polling every 5s for "real-time" updates (no Firebase).
- WebSocket server is present; you can subscribe later if desired.
