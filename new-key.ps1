# Makes a NEW signing key (old one is kept as android.keystore.old-<time>, not deleted), then signs the APK with it.
$T  = 'D:\darkbound\tools'
$env:JAVA_HOME = "$T\jdk\jdk-17.0.21.1+2"
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
$ks = 'D:\darkbound\android\android.keystore'

if (Test-Path $ks) {
  $old = "$ks.old-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
  Rename-Item $ks (Split-Path $old -Leaf)
  Write-Host "Old key set aside as $old" -ForegroundColor DarkGray
}

Write-Host "`n=== Make the new key ===" -ForegroundColor Cyan
Write-Host "It asks for the new password TWICE. Nothing shows while typing - type it slowly from your paper." -ForegroundColor Yellow
& keytool -genkeypair -keystore $ks -storetype PKCS12 -alias Darkbound -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Goof Inc, OU=Bound Team, O=Goof Inc, C=US"
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $ks)) { Write-Host "`nKey wasn't made (passwords didn't match?). Run this again." -ForegroundColor Red; exit 1 }

Write-Host "`n=== Sign the app - type the SAME new password once more ===" -ForegroundColor Cyan
& powershell -ExecutionPolicy Bypass -File 'D:\darkbound\sign-apk.ps1'
