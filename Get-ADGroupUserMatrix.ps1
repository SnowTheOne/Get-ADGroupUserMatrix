Import-Module ActiveDirectory

# ==========================================================
# KONFIGURATION
# ==========================================================

# --- User-Quelle ---
$SourceGroup     = "Finance-Team-Group"
$UseSourceGroup  = $true

$ManualUsers = @(
    "user1",
    "user2"
)

# --- OPTIONALE USER-AUSSCHLÜSSE ---
# (alle optional – leere Werte = keine Wirkung)

# A) explizite User
$ExcludedUsers = @(
    "SVC_Automation_user",
    "max_admin"
)

# B) Naming Convention / Regex (leer lassen zum Deaktivieren)
#$ExcludeUserPattern = "^(svc_|adm_|ext_)"
 $ExcludeUserPattern = $null

# C) Nur aktive Benutzer berücksichtigen
$OnlyEnabledUsers = $false

# --- Gruppenfilter ---
$ExcludeGroupPattern = "Domain Users|Printer|VPN|WLAN|Default"

# --- Export ---
$ExportPath = ".\AD_Gruppen_User_Matrix.csv"

# ==========================================================
# USER ERMITTELN + FILTERN
# ==========================================================

$Users = @()

if ($UseSourceGroup) {

    $RawUsers = Get-ADGroupMember -Identity $SourceGroup -Recursive |
        Where-Object objectClass -eq "user"

    foreach ($User in $RawUsers) {

        $Sam = $User.SamAccountName

        # A) Explizite Excludes
        if ($ExcludedUsers -and $Sam -in $ExcludedUsers) { continue }

        # B) Regex Excludes
        if ($ExcludeUserPattern -and $Sam -match $ExcludeUserPattern) { continue }

        # C) Enabled-Status prüfen
        if ($OnlyEnabledUsers) {
            $ADUser = Get-ADUser $Sam -Properties Enabled
            if (-not $ADUser.Enabled) { continue }
        }

        $Users += $Sam
    }
}
else {
    foreach ($Sam in $ManualUsers) {

        if ($ExcludedUsers -and $Sam -in $ExcludedUsers) { continue }
        if ($ExcludeUserPattern -and $Sam -match $ExcludeUserPattern) { continue }

        if ($OnlyEnabledUsers) {
            $ADUser = Get-ADUser $Sam -Properties Enabled
            if (-not $ADUser.Enabled) { continue }
        }

        $Users += $Sam
    }
}

if (-not $Users) {
    Write-Error "Keine Benutzer nach Filterung übrig."
    return
}

# ==========================================================
# GRUPPENMITGLIEDSCHAFTEN EINMALIG LADEN
# ==========================================================

$UserGroupMap = @{}
$AllGroups    = New-Object System.Collections.Generic.HashSet[string]

foreach ($User in $Users) {

    $Groups = Get-ADPrincipalGroupMembership $User |
        Where-Object {
            $_.GroupCategory -eq "Security" -and
            $_.Name -notmatch $ExcludeGroupPattern
        } |
        Select-Object -ExpandProperty Name

    $UserGroupMap[$User] = $Groups

    foreach ($Group in $Groups) {
        $AllGroups.Add($Group) | Out-Null
    }
}

# ==========================================================
# MATRIX AUFBAUEN
# ==========================================================

$Matrix = @()

foreach ($Group in ($AllGroups | Sort-Object)) {

    $Row = [ordered]@{
        Group = $Group
    }

    $MemberCount = 0

    foreach ($User in $Users) {
        if ($UserGroupMap[$User] -contains $Group) {
            $Row[$User] = "X"
            $MemberCount++
        }
        else {
            $Row[$User] = ""
        }
    }

    $Coverage = [math]::Round(($MemberCount / $Users.Count) * 100, 2)

    $Row["MemberCount"] = $MemberCount
    $Row["CoveragePct"] = $Coverage

    if ($Coverage -ge 80) {
        $Row["Relevance"] = "High"
    }
    elseif ($Coverage -ge 40) {
        $Row["Relevance"] = "Medium"
    }
    else {
        $Row["Relevance"] = "Low"
    }

    $Matrix += [PSCustomObject]$Row
}

# ==========================================================
# AUSGABE & EXPORT
# ==========================================================

$Matrix |
    Sort-Object MemberCount -Descending |
    Format-Table -AutoSize

$Matrix | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Matrix exportiert nach:" -ForegroundColor Cyan
Write-Host $ExportPath
