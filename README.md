# Get-ADGroupUserMatrix.ps1
# AD Gruppen-User-Matrix Analyse

Dieses PowerShell-Skript dient zur **Analyse von
Active-Directory-Gruppenmitgliedschaften** für definierte
Benutzergruppen oder Benutzerlisten.

Ziel ist es, **gemeinsame Gruppen, Ausreißer und
Rollengruppen-Kandidaten** transparent darzustellen und datenbasiert
Rollenmodelle (RBAC) abzuleiten.

Das Ergebnis ist eine **Gruppen-User-Matrix** inklusive
Relevanzkennzahlen, ideal für IAM-, Audit- und Berechtigungsprojekte.

------------------------------------------------------------------------

## 🧩 Funktionsumfang

-   Verarbeitung von:
    -   einer **AD-Gruppe** oder
    -   einer **manuellen Benutzerliste**
-   Ermittlung aller **Security-Gruppenmitgliedschaften**
-   Aufbau einer **Matrix: Gruppe × Benutzer**
-   Automatische Berechnung von:
    -   `MemberCount` -- Anzahl Benutzer pro Gruppe
    -   `CoveragePct` -- Abdeckung in Prozent
    -   `Relevance` -- High / Medium / Low
-   Flexible **Benutzer-Ausschlussmechanismen**
-   Ausschluss irrelevanter Gruppen (z. B. Default- oder
    Infrastrukturgruppen)
-   Export nach **CSV (Excel-geeignet)**

------------------------------------------------------------------------

## 📋 Voraussetzungen

-   Windows PowerShell 5.1 oder höher
-   RSAT / ActiveDirectory-Modul
-   Leserechte im Active Directory

``` powershell
Import-Module ActiveDirectory
```

------------------------------------------------------------------------

## 🚀 Schnellstart

1.  Repository klonen
2.  Skript öffnen und Konfiguration anpassen
3.  Skript ausführen
4.  CSV-Export in Excel auswerten

------------------------------------------------------------------------

## ⚙️ Konfiguration

### 🔹 Benutzerquelle

#### Option A: Benutzer aus AD-Gruppe

``` powershell
$SourceGroup    = "TEAM-FINANCE"
$UseSourceGroup = $true
```

#### Option B: Manuelle Benutzerliste

``` powershell
$UseSourceGroup = $false

$ManualUsers = @(
    "user1",
    "user2",
    "user3"
)
```

------------------------------------------------------------------------

## 🚫 Benutzer ausschließen (optional & kombinierbar)

### 1️⃣ Explizite Ausschlussliste

``` powershell
$ExcludedUsers = @(
    "svc_backup",
    "svc_sap",
    "user_old"
)
```

### 2️⃣ Naming Convention / Regex

``` powershell
$ExcludeUserPattern = "^(svc_|adm_|ext_)"
```

### 3️⃣ Nur aktive Benutzer berücksichtigen

``` powershell
$OnlyEnabledUsers = $true
```

------------------------------------------------------------------------

## 🧹 Gruppenfilter

``` powershell
$ExcludeGroupPattern = "Domain Users|Printer|VPN|WLAN|Default"
```

------------------------------------------------------------------------

## 📊 Ergebnis: Gruppen-User-Matrix

  -----------------------------------------------------------------------------------
  Group          user1   user2   user3   MemberCount     CoveragePct     Relevance
  -------------- ------- ------- ------- --------------- --------------- ------------
  APP_SAP        X       X       X       3               100             High

  FILE_FINANCE   X       X               2               66.67           Medium

  PRINTER_XY             X               1               33.33           Low
  -----------------------------------------------------------------------------------

------------------------------------------------------------------------

## 📤 Export

``` powershell
$ExportPath = ".\AD_Gruppen_User_Matrix.csv"
```

------------------------------------------------------------------------

## 🏗️ Typische Use Cases

-   Rollenmodell-Definition (RBAC)
-   Bereinigung historisch gewachsener Gruppen
-   IAM- & Audit-Projekte

------------------------------------------------------------------------

## 👤 Maintainer

Interne IT / IAM / Active Directory Team
