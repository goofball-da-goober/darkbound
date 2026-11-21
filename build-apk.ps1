# Builds the Darkbound Quest APK using only tools on THE VAULT (D:).
$ErrorActionPreference = 'Stop'
$T = 'D:\darkbound\tools'
$env:JAVA_HOME         = "$T\jdk\jdk-17.0.21.1+2"
$env:ANDROID_HOME      = "$T\android-sdk"
$env:ANDROID_SDK_ROOT  = "$T\android-sdk"
$env:GRADLE_USER_HOME  = "$T\gradle"          # keep Gradle's big cache off C:
$env:ANDROID_USER_HOME = "$T\.android"
$env:TEMP = "$T\dl"; $env:TMP = "$T\dl"
$env:npm_config_cache  = "$T\npm-cache"
$env:Path = "$T\node-v22.11.0-win-x64;$env:JAVA_HOME\bin;$env:Path"

# Tell Bubblewrap where Java + Android SDK are, so it doesn't download its own copies to C:
$cfgDir = Join-Path $HOME '.bubblewrap'
New-Item -ItemType Directory -Force $cfgDir | Out-Null
@{ jdkPath = $env:JAVA_HOME; androidSdkPath = $env:ANDROID_HOME } | ConvertTo-Json | Set-Content (Join-Path $cfgDir 'config.json') -Encoding ascii

$bw = "$T\bw\node_modules\.bin\bubblewrap.cmd"
$proj = 'D:\darkbound\android'
$bt = "$T\android-sdk\build-tools\34.0.0"
New-Item -ItemType Directory -Force $proj | Out-Null
Set-Location $proj

if (-not (Test-Path "$proj\twa-manifest.json")) {
  Write-Host "`n=== Step 1: create the Quest app project ===" -ForegroundColor Cyan
  Write-Host "Press Enter to accept the defaults. When asked about the signing key, pick a password you'll remember (you need it for every update)." -ForegroundColor Yellow
  & $bw init --manifest=https://goofball-da-goober.github.io/darkbound/manifest.webmanifest --metaquest
}

# Step 2 runs the same three tools 'bubblewrap build' would, directly
# (newer Node on Windows refuses to launch gradlew.bat from Bubblewrap: "spawn EINVAL").
Set-Content "$proj\local.properties" ("sdk.dir=" + ($env:ANDROID_HOME -replace '\\', '\\')) -Encoding ascii

Write-Host "`n=== Step 2a: compile the app (first time downloads Gradle, takes a while) ===" -ForegroundColor Cyan
& "$proj\gradlew.bat" assembleRelease --no-daemon
if ($LASTEXITCODE -ne 0) { Write-Host "`nCompile failed - scroll up for the first red error." -ForegroundColor Red; exit 1 }

$unsigned = Get-ChildItem "$proj\app\build\outputs\apk\release" -Filter '*.apk' | Select-Object -First 1
if (-not $unsigned) { Write-Host "`nNo APK came out of the compile step." -ForegroundColor Red; exit 1 }

Write-Host "`n=== Step 2b: align ===" -ForegroundColor Cyan
& "$bt\zipalign.exe" -f -p 4 $unsigned.FullName "$proj\app-release-aligned.apk"
if ($LASTEXITCODE -ne 0) { Write-Host "zipalign failed." -ForegroundColor Red; exit 1 }

Write-Host "`n=== Step 2c: sign it - type your key store password, then your key password ===" -ForegroundColor Cyan
& "$bt\apksigner.bat" sign --ks "$proj\android.keystore" --ks-key-alias Darkbound --out 'D:\darkbound\Darkbound.apk' "$proj\app-release-aligned.apk"
if ($LASTEXITCODE -ne 0) { Write-Host "Signing failed (wrong password?). Run this script again to retry." -ForegroundColor Red; exit 1 }

& "$bt\apksigner.bat" verify 'D:\darkbound\Darkbound.apk'
if ($LASTEXITCODE -eq 0) { Write-Host "`nDONE: D:\darkbound\Darkbound.apk" -ForegroundColor Green }
