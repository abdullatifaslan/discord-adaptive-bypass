$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue

# Console UTF-8 Configuration
$null = & chcp 65001 2>&1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Administrative Privilege Verification
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue

$workingDir = 'C:\Discord_Bypass_Tool'
if (-not (Test-Path $workingDir)) { New-Item -ItemType Directory -Path $workingDir | Out-Null }
Set-Location -Path $workingDir

# UI Rendering Engine
$cTL = [char]0x250C
$cTR = [char]0x2510
$cBL = [char]0x2514
$cBR = [char]0x2518
$cH  = [char]0x2500
$cV  = [char]0x2502
$cM  = [char]0x251C
$cMR = [char]0x2524
$WIDTH = 73

function Draw-Line([string]$L, [string]$R, [ConsoleColor]$Color) {
    $line = [string]$cH * ($WIDTH - 2)
    Write-Host " $L$line$R" -ForegroundColor $Color
}

function Draw-Text([string]$Text, [ConsoleColor]$Color, [ConsoleColor]$BorderColor) {
    $pad = $WIDTH - 4
    if ($Text.Length -gt $pad) { $Text = $Text.Substring(0, $pad) }
    
    Write-Host " $cV " -NoNewline -ForegroundColor $BorderColor
    Write-Host $Text.PadRight($pad) -NoNewline -ForegroundColor $Color
    Write-Host " $cV" -ForegroundColor $BorderColor
}

function Show-Header {
    Clear-Host
    Write-Host ""
    Draw-Line $cTL $cTR Cyan
    Draw-Text "   ___   _  ____  ____  ____  ____  ___" Yellow Cyan
    Draw-Text "   |  \  |  [__   |     |  |  |__/  |  \" Yellow Cyan
    Draw-Text "   |__/  |  ___]  |___  |__|  |  \  |__/" Yellow Cyan
    Draw-Text "" Yellow Cyan
    Draw-Text "    ADAPTIVE DPI BYPASS ENGINE  |  V6.6 (VALDIKSS CORE)" Cyan Cyan
    Draw-Line $cBL $cBR Cyan
    Write-Host ""
}

# Network & Driver Purge
function Invoke-NuclearCleanup {
    Get-Process -Name 'goodbyedpi' -ErrorAction SilentlyContinue | Stop-Process -Force
    $null = & sc.exe stop WinDivert 2>&1
    $null = & sc.exe delete WinDivert 2>&1
}

Show-Header
Write-Host " [*] Sistem temizleniyor ve ortam hazirlaniyor..." -ForegroundColor DarkGray

Invoke-NuclearCleanup

# Core Binary Verification & Fetching
$exeFile = Get-ChildItem -Path $workingDir -Filter 'goodbyedpi.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

if ($null -eq $exeFile) {
    Write-Host " [+] Resmi motor bileşenleri indiriliyor..." -ForegroundColor Yellow
    
    $url = 'https://github.com/ValdikSS/GoodbyeDPI/releases/download/0.2.3rc3/goodbyedpi-0.2.3rc3-2.zip'
    $zipPath = Join-Path -Path $workingDir -ChildPath 'src.zip'
    
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath $workingDir -Force
    Remove-Item -Path $zipPath -ErrorAction SilentlyContinue
    
    $exeFile = Get-ChildItem -Path $workingDir -Filter 'goodbyedpi.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
}

$hostPath = Join-Path -Path $exeFile.DirectoryName -ChildPath 'discord_hosts.txt'
$hostsList = @('discord.com', 'discordapp.com', 'discordapp.net', 'discord.gg', 'gateway.discord.gg', 'cdn.discordapp.com', '*.discord.gg')
$hostsList | Out-File -FilePath $hostPath -Encoding ascii -Force

# Adaptive Matrix Setup
$dnsPool = @(
    @{ Name = 'Cloudflare';        IP = '1.1.1.1';         Port = '53' },
    @{ Name = 'Google DNS';        IP = '8.8.8.8';         Port = '53' },
    @{ Name = 'OpenDNS';           IP = '208.67.222.222';  Port = '53' },
    @{ Name = 'Yandex DNS';        IP = '77.88.8.8';       Port = '1253' }
)

$methods = @(
    @{ Name = 'L1: Header Mix';    Cmd = '-s -m' },
    @{ Name = 'L2: TTL Limit';     Cmd = '--set-ttl 3' },
    @{ Name = 'L3: Pasif Koruma';  Cmd = '-p -r -s' },
    @{ Name = 'L4: Hafif (-3)';    Cmd = '-3' },
    @{ Name = 'L5: Dengeli (-5)';  Cmd = '-5' },
    @{ Name = 'L6: Agresif (-9)';  Cmd = '-9' },
    @{ Name = 'L7: Extreme';       Cmd = '-p -r -e 1 -f 1 -m --wrong-chksum' }
)

# Socket Probe Engine
Show-Header
Write-Host " [*] Baglanti taramasi baslatildi..." -ForegroundColor Yellow
Write-Host "     Metotlar deneniyor:`n" -ForegroundColor DarkGray

$bestArgs = ''
$bestMethodName = ''
$bestDnsName = ''
$foundMatch = $false

$handler = New-Object System.Net.Http.HttpClientHandler
$httpClient = New-Object System.Net.Http.HttpClient($handler)
$httpClient.Timeout = [TimeSpan]::FromMilliseconds(1500)
$httpClient.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0")

foreach ($m in $methods) {
    if ($foundMatch) { break }
    foreach ($dns in $dnsPool) {
        Invoke-NuclearCleanup
        
        $dnsCmd = '--dns-addr ' + $dns.IP + ' --dns-port ' + $dns.Port
        $currentArgs = $m.Cmd + ' ' + $dnsCmd + ' --blacklist "' + $hostPath + '"'
        
        Write-Host ("   -> TEST: {0} via {1}" -f $m.Name.PadRight(18), $dns.Name) -ForegroundColor Cyan
        
        $p = Start-Process -FilePath $exeFile.FullName -ArgumentList $currentArgs -WindowStyle Hidden -PassThru -ErrorAction SilentlyContinue
        
        if ($null -ne $p) {
            Start-Sleep -Milliseconds 300
            $check = $false
            try {
                $response = $httpClient.GetAsync('https://discord.com').Result
                if ($response.IsSuccessStatusCode) { $check = $true }
            } catch { $check = $false }
            
            if ($check) {
                $bestArgs = $currentArgs
                $bestMethodName = $m.Name
                $bestDnsName = $dns.Name
                $foundMatch = $true
                if (-not $p.HasExited) { $p.Kill() }
                break
            } else {
                if (-not $p.HasExited) { $p.Kill() }
            }
        }
    }
}

$httpClient.Dispose()

Show-Header

if ($bestArgs -eq '') {
    Draw-Line $cTL $cTR Red
    Draw-Text " [X] HATA: UYGUN TUNEL METODU BULUNAMADI" Red Red
    Draw-Line $cBL $cBR Red
    Write-Host ""
    Write-Host " [!] Lutfen guvenlik duvari ayarlarinizi veya internet baglantinizi kontrol edin." -ForegroundColor Red
    Write-Host ""
    exit
}

Invoke-NuclearCleanup

Draw-Line $cTL $cTR Green
Draw-Text " [OK] KILITLENDI: TUNEL MIMARISI BASARIYLA AKTIFLESTIRILDI" Green Green
Draw-Line $cM $cMR Green
Draw-Text ("   >> OPTIMUM METOT   : " + $bestMethodName) White Green
Draw-Text ("   >> AKTIF DNS PROXY : " + $bestDnsName) White Green
Draw-Line $cBL $cBR Green
Write-Host ""

# Guard Process & Driver Cleanup Protocol
$exePath    = $exeFile.FullName
$parentPID  = $PID

$guardCommand = @"
`$proc = Start-Process -FilePath '$exePath' -ArgumentList '$bestArgs' -WindowStyle Hidden -PassThru
`$parent = Get-Process -Id $parentPID -ErrorAction SilentlyContinue
if (`$parent) {
    `$parent.WaitForExit()
    if (-not `$proc.HasExited) { `$proc.Kill() }
} else {
    if (-not `$proc.HasExited) { `$proc.Kill() }
}
Start-Sleep -Seconds 2
& sc.exe stop WinDivert 2>&1 | Out-Null
& sc.exe delete WinDivert 2>&1 | Out-Null
"@

Start-Process powershell -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -Command `"$guardCommand`"" -WindowStyle Hidden

Write-Host " [ONLINE] " -NoNewline -ForegroundColor Black -BackgroundColor Green
Write-Host " Discord baglantisi saglandi. Bu pencereyi kucultebilirsiniz." -ForegroundColor White
Write-Host " [*] Pencere kapatildiginda GoodbyeDPI ve surucu tamamen temizlenir." -ForegroundColor Cyan
Write-Host " [*] Klasor artik silinebilir duruma gelir." -ForegroundColor Cyan
Write-Host ""

while ($true) { 
    Start-Sleep -Seconds 60
}