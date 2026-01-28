Import-Module ActiveDirectory

# ==========================================================
# CONFIGURATION
# ==========================================================

# --- User-Source ---
$SourceGroup     = "Finance-Team-Group"
$UseSourceGroup  = $true

$ManualUsers = @(
    "user1",
    "user2"
)

# --- OPTIONAL USER-Exclusions ---
# (all optional – empty values = no effect)

# A) explicit User
$ExcludedUsers = @(
    "SVC_Automation_user",
    "max_admin"
)

# B) Naming Convention / Regex (leave empty to deactivate)
#$ExcludeUserPattern = "^(svc_|adm_|ext_)"
 $ExcludeUserPattern = $null

# C) only use enabled users
$OnlyEnabledUsers = $false

# --- group filter ---
$ExcludeGroupPattern = "Domain Users|Printer|VPN|WLAN|Default"

# --- Export ---
$ExportPath = ".\AD_Group_User_Matrix.csv"

# ==========================================================
# collect users + filter
# ==========================================================

$Users = @()

if ($UseSourceGroup) {

    $RawUsers = Get-ADGroupMember -Identity $SourceGroup -Recursive |
        Where-Object objectClass -eq "user"

    foreach ($User in $RawUsers) {

        $Sam = $User.SamAccountName

        # A) Explicit Excludes
        if ($ExcludedUsers -and $Sam -in $ExcludedUsers) { continue }

        # B) Regex Excludes
        if ($ExcludeUserPattern -and $Sam -match $ExcludeUserPattern) { continue }

        # C) check enabled status 
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
    Write-Error "There are no users after applying the filter."
    return
}

# ==========================================================
# Read Group memberships
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
# Build matrix
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
# Output & EXPORT
# ==========================================================

$Matrix |
    Sort-Object MemberCount -Descending |
    Format-Table -AutoSize

$Matrix | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Matrix exported to:" -ForegroundColor Cyan
Write-Host $ExportPath
