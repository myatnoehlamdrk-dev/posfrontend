@echo off
setlocal
cd /d "%~dp0.."

rem Single source of truth for BASE_URL.
rem
rem The origin was previously passed by hand on each run, which is how three
rem different values (192.168.1.104, .112 and an empty one) ended up baked into
rem shipped builds while the machine was on .109 — every API call and every
rem /uploads image URL resolved against a host that no longer answered, showing
rem up as broken-image icons rather than an error. One file, one value.

if not exist "config\env.json" (
  echo [run.bat] config\env.json is missing.
  echo           Copy config\env.example.json to config\env.json and set BASE_URL
  echo           to the origin serving posback\posbackend\public, then re-run.
  exit /b 1
)

flutter run --dart-define-from-file=config\env.json %*
