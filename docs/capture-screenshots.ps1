param(
    [string]$DashboardUrl = "http://localhost:3000",
    [string]$ApiUrl = "http://localhost:8080",
    [string]$Email = "demo@example.com",
    [string]$Password = "password123"
)

$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path -LiteralPath $edgePath)) {
    throw "Microsoft Edge was not found at $edgePath"
}

$assetsDir = Join-Path $PSScriptRoot "assets"
New-Item -ItemType Directory -Force -Path $assetsDir | Out-Null

$login = Invoke-RestMethod -Method Post -Uri "$ApiUrl/auth/login" -ContentType "application/json" -Body (@{
    email = $Email
    password = $Password
} | ConvertTo-Json -Compress)
$token = $login.access_token

$port = Get-Random -Minimum 9300 -Maximum 9700
$userDataDir = Join-Path $env:TEMP "winnie-docs-edge-$PID-$port"
New-Item -ItemType Directory -Force -Path $userDataDir | Out-Null

$edgeArgs = @(
    "--headless=new",
    "--remote-debugging-port=$port",
    "--user-data-dir=$userDataDir",
    "--disable-gpu",
    "--no-first-run",
    "--hide-scrollbars",
    $DashboardUrl
)

$edge = Start-Process -FilePath $edgePath -ArgumentList $edgeArgs -PassThru -WindowStyle Hidden

try {
    $targets = $null
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        try {
            $targets = Invoke-RestMethod -Uri "http://127.0.0.1:$port/json" -TimeoutSec 2
            if ($targets) { break }
        } catch {
            Start-Sleep -Milliseconds 250
        }
    }
    if (-not $targets) {
        throw "Could not connect to Edge DevTools on port $port"
    }

    $page = @($targets | Where-Object { $_.type -eq "page" })[0]
    if (-not $page.webSocketDebuggerUrl) {
        throw "Could not find a page target for screenshot capture"
    }

    $ws = [System.Net.WebSockets.ClientWebSocket]::new()
    $ws.ConnectAsync([Uri]$page.webSocketDebuggerUrl, [Threading.CancellationToken]::None).GetAwaiter().GetResult()
    $script:nextId = 0

    function Receive-CdpMessage {
        param([System.Net.WebSockets.ClientWebSocket]$Socket)

        $buffer = New-Object byte[] 1048576
        $segment = [ArraySegment[byte]]::new($buffer)
        $stream = [System.IO.MemoryStream]::new()
        do {
            $result = $Socket.ReceiveAsync($segment, [Threading.CancellationToken]::None).GetAwaiter().GetResult()
            if ($result.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) {
                throw "DevTools socket closed during capture"
            }
            $stream.Write($buffer, 0, $result.Count)
        } until ($result.EndOfMessage)

        [Text.Encoding]::UTF8.GetString($stream.ToArray()) | ConvertFrom-Json
    }

    function Send-CdpCommand {
        param(
            [string]$Method,
            [hashtable]$Params = @{}
        )

        $script:nextId += 1
        $commandId = $script:nextId
        $payload = @{
            id = $commandId
            method = $Method
            params = $Params
        } | ConvertTo-Json -Depth 20 -Compress

        $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
        $ws.SendAsync([ArraySegment[byte]]::new($bytes), [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [Threading.CancellationToken]::None).GetAwaiter().GetResult()

        while ($true) {
            $message = Receive-CdpMessage -Socket $ws
            if ($message.id -eq $commandId) {
                if ($message.error) {
                    throw "$Method failed: $($message.error.message)"
                }
                return $message.result
            }
        }
    }

    function Invoke-PageScript {
        param([string]$Expression)

        Send-CdpCommand -Method "Runtime.evaluate" -Params @{
            expression = $Expression
            awaitPromise = $true
            returnByValue = $true
        } | Out-Null
    }

    function Save-Screenshot {
        param([string]$Name)

        $result = Send-CdpCommand -Method "Page.captureScreenshot" -Params @{
            format = "png"
            fromSurface = $true
            captureBeyondViewport = $false
        }
        [IO.File]::WriteAllBytes((Join-Path $assetsDir $Name), [Convert]::FromBase64String($result.data))
    }

    Send-CdpCommand -Method "Page.enable" | Out-Null
    Send-CdpCommand -Method "Runtime.enable" | Out-Null
    Send-CdpCommand -Method "Emulation.setDeviceMetricsOverride" -Params @{
        width = 1440
        height = 1050
        deviceScaleFactor = 1
        mobile = $false
    } | Out-Null

    Send-CdpCommand -Method "Page.navigate" -Params @{ url = $DashboardUrl } | Out-Null
    Start-Sleep -Seconds 2
    $escapedToken = $token.Replace("\", "\\").Replace("'", "\'")
    Invoke-PageScript -Expression "localStorage.setItem('winnie-token', '$escapedToken'); localStorage.setItem('winnie-tour-complete', 'true'); location.reload();"
    Start-Sleep -Seconds 6
    Save-Screenshot -Name "overview-screenshot.png"

    Invoke-PageScript -Expression "Array.from(document.querySelectorAll('button')).find((button) => button.textContent && button.textContent.includes('Manage'))?.click();"
    Start-Sleep -Seconds 2
    Save-Screenshot -Name "manage-screenshot.png"

    Invoke-PageScript -Expression "Array.from(document.querySelectorAll('button')).find((button) => button.textContent && button.textContent.includes('Compare'))?.click();"
    Start-Sleep -Seconds 2
    Save-Screenshot -Name "compare-screenshot.png"
} finally {
    if ($ws) {
        try {
            $ws.Dispose()
        } catch {}
    }
    if ($edge -and -not $edge.HasExited) {
        Stop-Process -Id $edge.Id -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath $userDataDir -Recurse -Force -ErrorAction SilentlyContinue
}
