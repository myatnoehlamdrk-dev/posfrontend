# posfrontend

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Configuration: BASE_URL

The app is compiled with a single origin that every API call **and** every
`/uploads/…` image URL is resolved against (`ApiClient.baseUrl`, from
`--dart-define=BASE_URL`).

- **Default: the deployed API**, `https://mdrkposbackend.onrender.com`. It is
  the `defaultValue` on `String.fromEnvironment('BASE_URL')`, so a build with
  no `--dart-define` at all — including a bare `flutter build apk --release` —
  ships an origin that answers instead of the empty string.
- To build against a local backend, say so explicitly: copy
  `config/env.example.json` to `config/env.json` and set `BASE_URL` to the
  origin serving `posback/posbackend/public`, e.g. `http://127.0.0.1:8000` —
  no trailing slash, no `/api` suffix.
- Run with `tool\run.bat`, build with `tool\build.bat [apk|web|all]`. Both read
  that one file, so a build can never ship a different origin from the one you
  tested against.
- The machine's LAN address is assigned by DHCP. When it changes, edit
  `config/env.json` and rebuild — a stale value is exactly what turns every
  uploaded photo into a broken-image icon.
- Every debug startup prints `API origin: …`, so a wrong origin is visible in
  the console at launch rather than as broken images later.

Uploaded images are stored on the API server's own disk by default
(`IMAGES_STORE=local` in the backend, served through `GET /uploads/{file}`),
so they need no internet and no third-party host. That route is what carries
the `Access-Control-Allow-Origin` header the web build needs — without it the
browser blocks the byte fetch and every local upload shows a broken icon.
