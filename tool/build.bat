@echo off
setlocal
cd /d "%~dp0.."

rem Builds with the same BASE_URL as tool\run.bat, so what you tested and what
rem you ship cannot drift apart. Usage: tool\build.bat [apk^|web^|all]
rem
rem --no-tree-shake-icons is forced because the dashboard builds its icons from
rem data (IconData(m.iconCodePoint) in dashboard_screen.dart) rather than from
rem const literals, which is exactly what the shaker refuses. Without this flag
rem every release build stops with "Avoid non-constant invocations of IconData"
rem and no bundle is produced at all; the flag costs some bundle size, and
rem making those icons const means changing the dashboard's design, which is a
rem separate piece of work.

if not exist "config\env.json" (
  echo [build.bat] config\env.json is missing.
  echo             Copy config\env.example.json to config\env.json and set BASE_URL,
  echo             then re-run.
  exit /b 1
)

set TARGET=%1
if "%TARGET%"=="" set TARGET=all

if /i "%TARGET%"=="apk" (
  flutter build apk --release --no-tree-shake-icons --dart-define-from-file=config\env.json
) else if /i "%TARGET%"=="web" (
  flutter build web --release --no-tree-shake-icons --dart-define-from-file=config\env.json
) else if /i "%TARGET%"=="all" (
  flutter build apk --release --no-tree-shake-icons --dart-define-from-file=config\env.json
  flutter build web --release --no-tree-shake-icons --dart-define-from-file=config\env.json
) else (
  echo usage: tool\build.bat [apk^|web^|all]
  exit /b 1
)
