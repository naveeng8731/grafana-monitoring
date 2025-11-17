# ---------------------------
# Windows Exporter Installer + Prometheus Target Auto-Register
# No Drive Mapping — Direct UNC Write
# ---------------------------

$version = "0.25.1"
$installerUrl = "https://github.com/prometheus-community/windows_exporter/releases/download/v$version/windows_exporter-$version-amd64.msi"
$installerPath = "$env:TEMP\windows_exporter-$version.msi"

# ---- USER CONFIG ----
$sambaShareUNC = "\\server-ip\grafana-monitoring\prometheus\windows-targets.json"
$sambaUsername = "your-samba-username"
$sambaPassword = "your-samba-password"

# Create credential object
$securePassword = ConvertTo-SecureString -String $sambaPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($sambaUsername, $securePassword)

# Enable TLS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ---- Download Windows Exporter ----
Write-Host "Downloading Windows Exporter..."
Invoke-RestMethod -Uri $installerUrl -OutFile $installerPath

Write-Host "Installing Windows Exporter..."
Start-Process "msiexec.exe" "/i `"$installerPath`" ENABLED_COLLECTORS=cpu,cs,logical_disk,memory,net,os,system,process,service,users /quiet" -Wait
Start-Sleep -Seconds 5

# ---- Detect IP & Hostname ----
$hostname = $env:COMPUTERNAME
$ipInfo = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.IPAddress -notlike "169.*" -and $_.IPAddress -ne "127.0.0.1"
} | Select-Object -First 1

if (-not $ipInfo) {
    Write-Host "No valid IP found."
    exit 1
}

$ip = $ipInfo.IPAddress
$newTarget = "$($ip):9182"

Write-Host "Machine: $hostname  IP: $ip"

# ---- Prepare new entry ----
$newEntry = [PSCustomObject]@{
    targets = @($newTarget)
    labels  = @{
        role     = "windows"
        hostname = $hostname
        instance = $ip
    }
}

# ---- Use global mutex lock to avoid concurrent writes ----
$mutexName = "Global\PrometheusTargetUpdate"
$mutex = New-Object System.Threading.Mutex($false, $mutexName)

try {
    $acquired = $mutex.WaitOne(60000)
    if (-not $acquired) {
        Write-Host "Could not get lock. Try again later."
        exit 1
    }

    # ---- Read existing JSON from UNC path ----
    Write-Host "Accessing $sambaShareUNC using credentials..."

    $existingContent = Invoke-Command -ScriptBlock {
        param ($path)

        if (Test-Path $path) {
            return Get-Content $path -Raw
        }

        return "[]"
    } -ArgumentList $sambaShareUNC -Credential $credential

    try {
        $existingJson = $existingContent | ConvertFrom-Json
    } catch {
        Write-Host "Invalid JSON found. Resetting file."
        $existingJson = @()
    }

    if ($existingJson -isnot [System.Collections.IEnumerable]) {
        $existingJson = @($existingJson)
    }

    # ---- Remove duplicates ----
    $updatedJson = @()
    $seenIPs = @{}

    foreach ($entry in $existingJson) {
        if ($entry.targets -and $entry.targets[0] -ne "") {
            $entryIP = ($entry.targets[0] -split ":")[0]
            if (-not $seenIPs.ContainsKey($entryIP) -and $entryIP -ne $ip) {
                $updatedJson += $entry
                $seenIPs[$entryIP] = $true
            }
        }
    }

    # ---- Add our new entry ----
    $updatedJson += $newEntry

    # ---- Convert back to JSON ----
    $jsonOutput = $updatedJson | ConvertTo-Json -Depth 5

    # ---- Write JSON back to server using credential ----
    Invoke-Command -ScriptBlock {
        param ($path, $data)
        Set-Content -Path $path -Value $data -Encoding UTF8
    } -ArgumentList $sambaShareUNC, $jsonOutput -Credential $credential

    Write-Host "Successfully registered $hostname ($ip) → windows-targets.json"

}
catch {
    Write-Host "Error: $($_.Exception.Message)"
}
finally {
    if ($acquired) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
