$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get 실패' }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'flutter analyze 실패' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'flutter test 실패' }
Write-Host '검사 통과. 휴대폰 연결 후 flutter run 명령어를 실행하세요.'
