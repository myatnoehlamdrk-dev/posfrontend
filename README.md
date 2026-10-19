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

- Copy `config/env.example.json` to `config/env.json` and set `BASE_URL` to the
  origin serving `posback/posbackend/public`, e.g. `http://192.168.1.109:8000`
  — no trailing slash, no `/api` suffix.
- Run with `tool\run.bat`, build with `tool\build.bat [apk|web|all]`. Both read
  that one file, so a build can never ship a different origin from the one you
  tested against.
- The machine's LAN address is assigned by DHCP. When it changes, edit
  `config/env.json` and rebuild — a stale value is exactly what turns every
  uploaded photo into a broken-image icon.
- An unset `BASE_URL` fails the debug build at startup instead of failing
  silently later.
