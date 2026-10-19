$url = "https://download.microsoft.com/download/ff69247e-f90f-495d-a846-0de5527f3849/ExchangeSubscriptionEdition-KB5128895-x64-en.exe"
$destinationFolder = "C:\Temp"
$fileName = "ExchangeSubscriptionEdition-KB5128895-x64-en.exe"
$destinationPath = Join-Path -Path $destinationFolder -ChildPath $fileName

if (-not (Test-Path -Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
}

# Stop and Disable Rapid7 service
$s = Get-Service -Name "ir_agent" -ErrorAction SilentlyContinue; if ($s) 
{
if ($s.Status -eq 'Running') 
{Stop-Service -Name $s.Name -Force; $s.WaitForStatus('Stopped', '00:00:30') }; Set-Service -Name $s.Name -StartupType Disabled }

$ProgressPreference = 'SilentlyContinue'
Write-Host "Downloading $fileName to $destinationFolder..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $url -OutFile $destinationPath -UseBasicParsing

if (Test-Path -Path $destinationPath) {
    Write-Host "Download complete. Starting installer with elevated privileges..." -ForegroundColor Green    
    $process = Start-Process -FilePath $destinationPath -ArgumentList "/passive" -Verb RunAs -Wait -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Host "Installation completed. Initiating server restart..." -ForegroundColor Yellow
        Restart-Computer -Force
    } elseif ($process.ExitCode -eq 3010) {
        Write-Host "Installation completed (reboot required, exit code 3010). Initiating server restart..." -ForegroundColor Yellow
        Restart-Computer -Force
    } else {
        Write-Error "Installation failed or returned unexpected exit code: $($process.ExitCode)"
    }
} else {
    Write-Error "Failed to locate downloaded file at $destinationPath"
}
