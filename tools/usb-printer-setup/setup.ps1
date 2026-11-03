# SmartPOS USB Printer setup: installs the WinUSB driver for the STMicroelectronics
# thermal printer (VID_0483 / PID_5743) so browsers can reach it over WebUSB.
$ErrorActionPreference = 'Stop'

$log = Join-Path $env:TEMP 'smartpos-usb-setup.log'
Start-Transcript -Path $log -Force | Out-Null

try {
    Write-Host ''
    Write-Host 'SmartPOS USB Printer Setup'
    Write-Host '=========================='
    Write-Host ''

    $srcInf = Join-Path $PSScriptRoot 'SmartPosUsb.inf'
    if (-not (Test-Path -LiteralPath $srcInf)) {
        throw "Driver INF not found next to this script: $srcInf"
    }

    Write-Host 'Step 1/5 - Creating a local code-signing certificate...'
    $cert = New-SelfSignedCertificate -Type CodeSigningCert `
        -Subject 'CN=SmartPOS USB Printer Setup' `
        -CertStoreLocation Cert:\LocalMachine\My `
        -NotAfter (Get-Date).AddYears(5)
    Write-Host ('  thumbprint: ' + $cert.Thumbprint)

    Write-Host 'Step 2/5 - Trusting the certificate on this PC...'
    $cer = Join-Path $env:TEMP 'smartpos-usb-setup.cer'
    Export-Certificate -Cert $cert -FilePath $cer | Out-Null
    Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
    Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\TrustedPublisher | Out-Null

    Write-Host 'Step 3/5 - Preparing the driver package...'
    $work = Join-Path $env:TEMP 'smartpos-usb-setup'
    if (Test-Path $work) { Remove-Item -Recurse -Force $work }
    New-Item -ItemType Directory -Force -Path $work | Out-Null
    $infPath = Join-Path $work 'SmartPosUsb.inf'
    $catPath = Join-Path $work 'SmartPosUsb.cat'
    Copy-Item -LiteralPath $srcInf -Destination $infPath -Force

    Write-Host 'Step 4/5 - Building and signing the catalog...'
    New-FileCatalog -Path $infPath -CatalogFilePath $catPath -CatalogVersion 2 | Out-Null
    $sig = Set-AuthenticodeSignature -FilePath $catPath -Certificate $cert
    if ($sig.Status -ne 'Valid') {
        throw "Catalog signature is not valid: $($sig.Status)"
    }
    Write-Host ('  signature: ' + $sig.Status)

    Write-Host 'Step 5/5 - Installing the driver with pnputil...'
    & pnputil /add-driver $infPath /install
    if ($LASTEXITCODE -ne 0) {
        throw "pnputil failed with exit code $LASTEXITCODE"
    }

    Write-Host ''
    Write-Host 'SUCCESS: the USB printer driver is installed.'
    Write-Host 'You can now plug in the printer and use it from the browser (WebUSB).'
    Write-Host ''
    Write-Host ('Log: ' + $log)
} catch {
    Write-Host ''
    Write-Host ('FAILED: ' + $_.Exception.Message)
    Write-Host ('Log: ' + $log)
    throw
} finally {
    Stop-Transcript | Out-Null
}
