# Signs the already-compiled Darkbound APK (skips the slow compile). Run build-apk.ps1 first if the game app itself changed.
$T  = 'D:\darkbound\tools'
$env:JAVA_HOME = "$T\jdk\jdk-17.0.21.1+2"
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
$bt = "$T\android-sdk\build-tools\34.0.0"
$aligned = 'D:\darkbound\android\app-release-aligned.apk'
if (-not (Test-Path $aligned)) { Write-Host "No compiled app found - run build-apk.ps1 instead." -ForegroundColor Red; exit 1 }

Write-Host "`nType your KEY STORE password (nothing shows while typing - that's normal), then press Enter." -ForegroundColor Cyan
& "$bt\apksigner.bat" sign --ks 'D:\darkbound\android\android.keystore' --ks-key-alias Darkbound --out 'D:\darkbound\Darkbound.apk' $aligned
if ($LASTEXITCODE -ne 0) { Write-Host "`nWrong password - just run this again and retype it slowly." -ForegroundColor Red; exit 1 }
& "$bt\apksigner.bat" verify 'D:\darkbound\Darkbound.apk'
if ($LASTEXITCODE -eq 0) { Write-Host "`nDONE: D:\darkbound\Darkbound.apk" -ForegroundColor Green }
