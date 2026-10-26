$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
flutter create --platforms=android --project-name dayframe .
if ($LASTEXITCODE -ne 0) { throw 'flutter create 실패' }
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get 실패' }
Write-Host '준비 완료! 휴대폰 연결 후 flutter run 명령어를 실행하세요.'
