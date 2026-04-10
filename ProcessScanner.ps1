# ============================================================
#  PROCESS SECURITY SCANNER - Triple Hash (SHA256+MD5+SHA1) VT Lookup
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# =======================
#  GUI
# =======================
function Show-ApiKeyDialog {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Process Security Scanner"
    $form.Size = New-Object System.Drawing.Size(480, 280)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false; $form.MinimizeBox = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(18, 18, 26)
    $form.ForeColor = [System.Drawing.Color]::White

    $t = New-Object System.Windows.Forms.Label
    $t.Text = "PROCESS SECURITY SCANNER"
    $t.Font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)
    $t.ForeColor = [System.Drawing.Color]::FromArgb(0, 230, 180)
    $t.Location = New-Object System.Drawing.Point(20, 20)
    $t.Size = New-Object System.Drawing.Size(440, 28)
    $form.Controls.Add($t)

    $s = New-Object System.Windows.Forms.Label
    $s.Text = "VirusTotal API Key দিন:"
    $s.Font = New-Object System.Drawing.Font("Consolas", 9)
    $s.ForeColor = [System.Drawing.Color]::FromArgb(160, 160, 200)
    $s.Location = New-Object System.Drawing.Point(20, 58)
    $s.Size = New-Object System.Drawing.Size(440, 20)
    $form.Controls.Add($s)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(20, 85)
    $textBox.Size = New-Object System.Drawing.Size(430, 28)
    $textBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $textBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 45)
    $textBox.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 180)
    $textBox.BorderStyle = "FixedSingle"
    $textBox.UseSystemPasswordChar = $true
    $form.Controls.Add($textBox)

    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text = "API Key দেখান"
    $chk.Font = New-Object System.Drawing.Font("Consolas", 8)
    $chk.ForeColor = [System.Drawing.Color]::FromArgb(140, 140, 180)
    $chk.Location = New-Object System.Drawing.Point(20, 115)
    $chk.Size = New-Object System.Drawing.Size(200, 20)
    $chk.Add_CheckedChanged({ $textBox.UseSystemPasswordChar = -not $chk.Checked })
    $form.Controls.Add($chk)

    $info = New-Object System.Windows.Forms.Label
    $info.Text = "Admin হিসেবে run করলে System32 সহ সব process scan হবে"
    $info.Font = New-Object System.Drawing.Font("Consolas", 8)
    $info.ForeColor = [System.Drawing.Color]::FromArgb(255, 200, 80)
    $info.Location = New-Object System.Drawing.Point(20, 143)
    $info.Size = New-Object System.Drawing.Size(440, 18)
    $form.Controls.Add($info)

    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = "SCAN শুরু করুন"
    $ok.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
    $ok.Location = New-Object System.Drawing.Point(20, 175)
    $ok.Size = New-Object System.Drawing.Size(200, 38)
    $ok.BackColor = [System.Drawing.Color]::FromArgb(0, 180, 130)
    $ok.ForeColor = [System.Drawing.Color]::Black
    $ok.FlatStyle = "Flat"; $ok.FlatAppearance.BorderSize = 0
    $ok.Add_Click({
        if ([string]::IsNullOrWhiteSpace($textBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show("API Key খালি রাখা যাবে না!", "Error", "OK", "Warning")
        } else { $form.DialogResult = "OK"; $form.Close() }
    })
    $form.Controls.Add($ok)

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = "বাতিল"
    $cancel.Font = New-Object System.Drawing.Font("Consolas", 10)
    $cancel.Location = New-Object System.Drawing.Point(240, 175)
    $cancel.Size = New-Object System.Drawing.Size(120, 38)
    $cancel.BackColor = [System.Drawing.Color]::FromArgb(60, 30, 40)
    $cancel.ForeColor = [System.Drawing.Color]::FromArgb(255, 100, 100)
    $cancel.FlatStyle = "Flat"
    $cancel.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255, 100, 100)
    $cancel.DialogResult = "Cancel"
    $form.Controls.Add($cancel)

    $form.AcceptButton = $ok; $form.CancelButton = $cancel
    $result = $form.ShowDialog()
    if ($result -eq "OK") { return $textBox.Text.Trim() }
    return $null
}

# =======================
#  LOGGING
# =======================
$LogPath = "ProcessScan_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $e = "[$ts] [$Type] $Message"
    Write-Host $e
    Add-Content -Path $LogPath -Value $e
}

# =======================
#  SIGNATURE CHECK
# =======================
function Get-SignatureStatus {
    param([string]$FilePath)
    try {
        if (-not (Test-Path -LiteralPath $FilePath -ErrorAction SilentlyContinue)) { return "FileNotFound" }
        return (Get-AuthenticodeSignature -FilePath $FilePath -ErrorAction Stop).Status.ToString()
    }
    catch { return "AccessDenied" }
}

# =======================
#  SAFE MULTI-HASH (SHA256 + MD5 + SHA1)
#  FileStream দিয়ে locked files ও read করা যায়
# =======================
function Get-FileHashes {
    param([string]$FilePath)

    $result = @{ SHA256=$null; MD5=$null; SHA1=$null }

    # FileStream — locked System32 files এর জন্য সবচেয়ে ভালো
    try {
        $fs = New-Object System.IO.FileStream(
            $FilePath,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            ([System.IO.FileShare]::Read -bor [System.IO.FileShare]::Write -bor [System.IO.FileShare]::Delete)
        )
        $buf = New-Object byte[] $fs.Length
        [void]$fs.Read($buf, 0, $buf.Length)
        $fs.Close(); $fs.Dispose()

        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $md5    = [System.Security.Cryptography.MD5]::Create()
        $sha1   = [System.Security.Cryptography.SHA1]::Create()

        $result.SHA256 = ([System.BitConverter]::ToString($sha256.ComputeHash($buf))).Replace("-","").ToUpper()
        $result.MD5    = ([System.BitConverter]::ToString($md5.ComputeHash($buf))).Replace("-","").ToUpper()
        $result.SHA1   = ([System.BitConverter]::ToString($sha1.ComputeHash($buf))).Replace("-","").ToUpper()

        $sha256.Dispose(); $md5.Dispose(); $sha1.Dispose()
        return $result
    }
    catch {}

    # Fallback: Get-FileHash
    try {
        $result.SHA256 = (Get-FileHash -LiteralPath $FilePath -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpper()
        $result.MD5    = (Get-FileHash -LiteralPath $FilePath -Algorithm MD5    -ErrorAction Stop).Hash.ToUpper()
        $result.SHA1   = (Get-FileHash -LiteralPath $FilePath -Algorithm SHA1   -ErrorAction Stop).Hash.ToUpper()
        return $result
    }
    catch {}

    return $null
}

# =======================
#  VIRUSTOTAL LOOKUP — SHA256 fail হলে MD5, তারপর SHA1 try করে
# =======================
function Check-VirusTotal {
    param([string]$FilePath, [string]$ApiKey)

    $hashes = Get-FileHashes -FilePath $FilePath

    if ($null -eq $hashes) {
        return @{ SHA256="N/A"; MD5="N/A"; UsedHash="N/A"; Malicious=0; Suspicious=0; Detection="FILE_LOCKED"; Risk="Unreadable" }
    }

    $headers = @{ "x-apikey" = $ApiKey }

    # SHA256 → MD5 → SHA1 ক্রমে try করি
    foreach ($hashType in @("SHA256","MD5","SHA1")) {
        $hash = $hashes[$hashType]
        if ([string]::IsNullOrEmpty($hash)) { continue }

        $url = "https://www.virustotal.com/api/v3/files/$hash"

        for ($attempt = 1; $attempt -le 2; $attempt++) {
            try {
                $resp  = Invoke-RestMethod -Method GET -Uri $url -Headers $headers -ErrorAction Stop
                $stats = $resp.data.attributes.last_analysis_stats
                $mal   = [int]$stats.malicious
                $sus   = [int]$stats.suspicious
                $total = [int]$stats.harmless + [int]$stats.undetected + $mal + $sus

                $risk = "Clean"
                if     ($mal -ge 5)                { $risk = "HIGH RISK" }
                elseif ($mal -ge 3)                { $risk = "MEDIUM RISK" }
                elseif ($mal -ge 1 -or $sus -ge 3) { $risk = "LOW RISK" }

                return @{
                    SHA256    = $hashes.SHA256
                    MD5       = $hashes.MD5
                    UsedHash  = $hashType
                    Malicious = $mal
                    Suspicious= $sus
                    Detection = "$mal/$total"
                    Risk      = $risk
                }
            }
            catch {
                $status = 0
                try { $status = [int]$_.Exception.Response.StatusCode } catch {}

                if ($status -eq 404) { break }  # এই hash VT তে নেই, পরেরটা try করো

                if ($status -eq 429 -and $attempt -eq 1) {
                    Write-Host "  [RATE LIMIT] 20s অপেক্ষা..." -ForegroundColor Yellow
                    Start-Sleep 20; continue
                }
                if ($status -eq 401) {
                    return @{ SHA256=$hashes.SHA256; MD5=$hashes.MD5; UsedHash="N/A"; Malicious=0; Suspicious=0; Detection="BAD_API_KEY"; Risk="Check API Key" }
                }
                break
            }
        }
    }

    # তিনটা hash দিয়েই পাওয়া যায়নি
    return @{
        SHA256    = $hashes.SHA256
        MD5       = $hashes.MD5
        UsedHash  = "None matched"
        Malicious = 0; Suspicious = 0
        Detection = "Not in VT DB"
        Risk      = "Not Submitted"
    }
}

# =======================
#  FILE DETAILS
# =======================
function Get-FileDetails {
    param([string]$FilePath)
    try {
        $f = Get-Item -LiteralPath $FilePath -ErrorAction Stop
        $v = $f.VersionInfo
        return @{
            Company     = if ($v.CompanyName)     { $v.CompanyName }     else { "N/A" }
            Description = if ($v.FileDescription) { $v.FileDescription } else { "N/A" }
            Version     = if ($v.FileVersion)     { $v.FileVersion }     else { "N/A" }
            SizeKB      = [math]::Round($f.Length / 1KB, 2)
        }
    }
    catch { return @{ Company="N/A"; Description="N/A"; Version="N/A"; SizeKB="N/A" } }
}

# =======================
#  MAIN SCAN
# =======================
function Start-ProcessSecurityScan {
    param([string]$ApiKey)

    Write-Log "Scan started (SHA256+MD5+SHA1 triple-hash lookup)"

    $scannedFiles = @{}
    $unsigned=0; $suspicious=0; $locked=0; $notInVT=0

    foreach ($p in (Get-Process -ErrorAction SilentlyContinue)) {

        $allPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        try { if ($p.MainModule.FileName) { [void]$allPaths.Add($p.MainModule.FileName) } } catch {}
        try { foreach ($m in $p.Modules) { if ($m.FileName) { [void]$allPaths.Add($m.FileName) } } } catch {}

        foreach ($modulePath in $allPaths) {
            if ([string]::IsNullOrEmpty($modulePath))   { continue }
            if (-not $modulePath.StartsWith("C:\"))      { continue }
            if ($scannedFiles.ContainsKey($modulePath)) { continue }
            $scannedFiles[$modulePath] = $true

            $sig = Get-SignatureStatus $modulePath
            if ($sig -eq "Valid") { continue }

            $unsigned++
            Write-Host "`n════════════════════════════════" -ForegroundColor DarkCyan
            Write-Host " Process  : $($p.ProcessName)  [PID: $($p.Id)]" -ForegroundColor Yellow
            Write-Host " Path     : $modulePath" -ForegroundColor Cyan
            Write-Host " Signature: $sig" -ForegroundColor $(if ($sig -eq "NotSigned") { "Magenta" } else { "DarkYellow" })

            $info = Get-FileDetails $modulePath
            Write-Host " Company  : $($info.Company)"
            Write-Host " Desc     : $($info.Description)"
            Write-Host " Version  : $($info.Version)"
            Write-Host " Size KB  : $($info.SizeKB)"
            Write-Host " VT check..." -ForegroundColor Gray

            $vt = Check-VirusTotal -FilePath $modulePath -ApiKey $ApiKey

            if ($vt.Detection -eq "FILE_LOCKED") {
                $locked++
                Write-Host " [LOCKED] পড়া যাচ্ছে না" -ForegroundColor DarkYellow
            }
            elseif ($vt.Detection -eq "Not in VT DB") {
                $notInVT++
                Write-Host " SHA256   : $($vt.SHA256)" -ForegroundColor DarkGray
                Write-Host " MD5      : $($vt.MD5)" -ForegroundColor DarkGray
                Write-Host " Detection: SHA256+MD5+SHA1 — VT তে নেই (Clean হওয়ার সম্ভাবনা বেশি)" -ForegroundColor DarkYellow
            }
            else {
                Write-Host " SHA256   : $($vt.SHA256)"
                Write-Host " MD5      : $($vt.MD5)"
                Write-Host " Matched  : $($vt.UsedHash) hash দিয়ে পাওয়া গেছে" -ForegroundColor DarkGreen
                Write-Host " Detection: $($vt.Detection)"

                $rc = switch ($vt.Risk) {
                    "HIGH RISK"   { "Red" }
                    "MEDIUM RISK" { "DarkRed" }
                    "LOW RISK"    { "Yellow" }
                    default       { "Green" }
                }
                Write-Host " Risk     : $($vt.Risk)" -ForegroundColor $rc

                if ($vt.Malicious -ge 3) {
                    Write-Host " !! MALICIOUS FILE DETECTED !!" -BackgroundColor DarkRed -ForegroundColor White
                    $suspicious++
                    Write-Log "MALICIOUS: $modulePath | $($vt.Detection) via $($vt.UsedHash)" "ALERT"
                }
                elseif ($vt.Malicious -ge 1) {
                    Write-Host " [WARN] Low detection — manual check করুন" -ForegroundColor Yellow
                    Write-Log "LOW_RISK: $modulePath | $($vt.Detection)" "WARN"
                }
            }

            Start-Sleep -Milliseconds 800
        }
    }

    Write-Host "`n═══════ SCAN SUMMARY ═══════" -ForegroundColor Green
    Write-Host " Total scanned  : $($scannedFiles.Count)"
    Write-Host " Unsigned       : $unsigned"
    Write-Host " Not in VT DB   : $notInVT  (SHA256+MD5+SHA1 সব try করা হয়েছে)" -ForegroundColor DarkYellow
    Write-Host " Locked/Skipped : $locked" -ForegroundColor DarkYellow
    Write-Host " MALICIOUS      : $suspicious" -ForegroundColor $(if ($suspicious -gt 0) {"Red"} else {"Green"})
    Write-Host " Log            : $LogPath" -ForegroundColor Cyan

    Write-Log "Done. Total:$($scannedFiles.Count) Unsigned:$unsigned NotInVT:$notInVT Locked:$locked Malicious:$suspicious"

    $icon = if ($suspicious -gt 0) { "Warning" } else { "Information" }
    [System.Windows.Forms.MessageBox]::Show(
        "Scan সম্পন্ন!`n`n" +
        "Total Scanned : $($scannedFiles.Count)`n" +
        "Unsigned      : $unsigned`n" +
        "Not in VT DB  : $notInVT`n" +
        "Locked/Skip   : $locked`n" +
        "MALICIOUS     : $suspicious`n`n" +
        "Log: $LogPath",
        "Scan Complete", "OK", $icon)
}

# =======================
#  ENTRY POINT
# =======================
$host.UI.RawUI.WindowTitle = "Process Security Scanner"
Write-Host "=== PROCESS SECURITY SCANNER ===" -ForegroundColor Cyan

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    $choice = [System.Windows.Forms.MessageBox]::Show(
        "Admin permission ছাড়া System32 files scan সীমিত হবে।`nAdmin হিসেবে restart করবেন?",
        "Permission Warning", "YesNo", "Warning")
    if ($choice -eq "Yes") {
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }
}

$apiKey = Show-ApiKeyDialog
if ([string]::IsNullOrEmpty($apiKey)) { Write-Host "বাতিল।" -ForegroundColor Red; exit }

Write-Host "Scan শুরু হচ্ছে..." -ForegroundColor Green
Start-ProcessSecurityScan -ApiKey $apiKey

Write-Host "`nPress any key to exit..."
try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch {}
