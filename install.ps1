<#
.SYNOPSIS
    Install the stack and its verification tools for Claude Code, Codex or Cursor.
.DESCRIPTION
    Copies are staged before replacing existing files. Replaced files are moved
    to a dated backup under the selected host. Unrelated skills and Git metadata
    are preserved. Run the portable build before installing.
.PARAMETER HostName
    Claude (the default), Codex, Cursor, or All.
.PARAMETER ProfileRoot
    User profile to install into. Override for an isolated installation test.
.PARAMETER Symlink
    Link Claude/Cursor specialist skills to this checkout. Requires Windows
    Developer Mode or administrator rights. Codex always receives a full bundle.
.PARAMETER Uninstall
    Move this stack's installed skills and support files to a dated backup.
.EXAMPLE
    .\install.ps1 -HostName All
#>
[CmdletBinding()]
param(
    [ValidateSet('Claude', 'Codex', 'Cursor', 'All')]
    [string] $HostName = 'Claude',
    [string] $ProfileRoot = $HOME,
    [switch] $Symlink,
    [switch] $Uninstall
)

$ErrorActionPreference = 'Stop'
$profilePath = [IO.Path]::GetFullPath($ProfileRoot).TrimEnd('\', '/')
$profilePrefix = $profilePath + [IO.Path]::DirectorySeparatorChar
$sourceSkills = Join-Path $PSScriptRoot '.claude\skills'
$skills = @(Get-ChildItem -LiteralPath $sourceSkills -Directory | Where-Object {
    Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md')
})
if ($skills.Count -eq 0) { throw "No skills found at $sourceSkills" }
if ($profilePath -eq [IO.Path]::GetPathRoot($profilePath).TrimEnd('\', '/')) {
    throw 'ProfileRoot must not be a filesystem root'
}

function Assert-ProfilePath([string] $Path) {
    $absolute = [IO.Path]::GetFullPath($Path)
    if (-not $absolute.StartsWith($profilePrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Installation path leaves ProfileRoot: $absolute"
    }
    # A linked destination itself can be moved as a link; a linked ancestor
    # would send writes outside the explicitly selected profile.
    $ancestor = Split-Path -Parent $absolute
    while ($ancestor -and $ancestor.StartsWith($profilePrefix, [StringComparison]::OrdinalIgnoreCase)) {
        if (Test-Path -LiteralPath $ancestor) {
            $item = Get-Item -LiteralPath $ancestor -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Installation parent is a link: $ancestor"
            }
        }
        $ancestor = Split-Path -Parent $ancestor
    }
    return $absolute
}

$runId = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 8)
$stageRoot = Assert-ProfilePath (Join-Path $profilePath ".roblox-luau-expert-stage-$runId")
$hosts = if ($HostName -eq 'All') { @('Claude', 'Codex', 'Cursor') } else { @($HostName) }
$operations = [Collections.Generic.List[object]]::new()
$utf8 = [Text.UTF8Encoding]::new($false)

function Add-Copy([string] $Source, [string] $Destination, [string] $HostFolder, [bool] $Link = $false) {
    $destinationPath = Assert-ProfilePath $Destination
    $staged = Join-Path $stageRoot ([string] $operations.Count)
    if (-not $Uninstall) {
        if (-not (Test-Path -LiteralPath $Source)) { throw "Installation source missing: $Source" }
        if ($Link) {
            New-Item -ItemType SymbolicLink -Path $staged -Target $Source | Out-Null
        } else {
            Copy-Item -LiteralPath $Source -Destination $staged -Recurse -Force
        }
    }
    $operations.Add([pscustomobject]@{ Destination = $destinationPath; Staged = $staged; HostFolder = $HostFolder })
    return $staged
}

function Add-Text([string] $Content, [string] $Destination, [string] $HostFolder) {
    $destinationPath = Assert-ProfilePath $Destination
    $staged = Join-Path $stageRoot ([string] $operations.Count)
    if (-not $Uninstall) { [IO.File]::WriteAllText($staged, $Content, $utf8) }
    $operations.Add([pscustomobject]@{ Destination = $destinationPath; Staged = $staged; HostFolder = $HostFolder })
}

function Remove-Stage([string] $Path) {
    $safe = Assert-ProfilePath $Path
    if (-not $safe.StartsWith($stageRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid staging cleanup path' }
    if (-not (Test-Path -LiteralPath $safe)) { return }
    $item = Get-Item -LiteralPath $safe -Force
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -or -not $item.PSIsContainer) {
        Remove-Item -LiteralPath $safe -Force
        return
    }
    foreach ($child in Get-ChildItem -LiteralPath $safe -Force) { Remove-Stage $child.FullName }
    Remove-Item -LiteralPath $safe -Force
}

try {
    New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null
    foreach ($hostNameEntry in $hosts) {
        $hostFolder = Join-Path $profilePath ('.' + $hostNameEntry.ToLowerInvariant())
        $skillRoot = Join-Path $hostFolder 'skills'
        $bundleRoot = if ($hostNameEntry -eq 'Codex') {
            Join-Path $skillRoot 'roblox-luau-expert-skill'
        } else {
            Join-Path $hostFolder 'roblox-luau-expert'
        }
        $bundleDisplay = $bundleRoot.Replace('\', '/')
        $pathsNote = "`n`n## Installed bundle paths`n`nThe complete stack is installed at ``$bundleDisplay``. Resolve ``tools/``, ``library/``, ``docs/``, ``evals/`` and ``.claude/skills/`` from that bundle root, not from the current project. Run bundled commands there or use absolute paths. Load only the specialist references relevant to the task.`n"

        if ($hostNameEntry -ne 'Codex') {
            foreach ($skill in $skills) {
                $stagedSkill = Add-Copy $skill.FullName (Join-Path $skillRoot $skill.Name) $hostFolder ([bool] $Symlink)
                if (-not $Uninstall -and -not $Symlink -and $skill.Name -eq 'roblox-luau-expert') {
                    [IO.File]::AppendAllText((Join-Path $stagedSkill 'SKILL.md'), $pathsNote, $utf8)
                }
            }
        }

        # Replace owned subtrees individually: an existing Codex clone may have
        # .git metadata and local files beside these directories.
        foreach ($entry in @('.claude\skills', '.agents\skills', '.cursor\rules\roblox-luau-expert.mdc', 'tools', 'library', 'docs', 'evals', 'AGENTS.md', 'README.md', 'install.ps1')) {
            $stagedEntry = Add-Copy (Join-Path $PSScriptRoot $entry) (Join-Path $bundleRoot $entry) $hostFolder
            if (-not $Uninstall -and $entry -eq 'docs') {
                $knowledge = Join-Path $stagedEntry 'portability\gpt\knowledge'
                if (Test-Path -LiteralPath $knowledge) {
                    foreach ($archive in Get-ChildItem -LiteralPath $knowledge -Filter '*.zip' -File) {
                        $archivePath = Assert-ProfilePath $archive.FullName
                        Remove-Item -LiteralPath $archivePath -Force
                    }
                }
            }
        }

        if ($hostNameEntry -eq 'Codex') {
            $wrapper = @'
---
name: roblox-luau-expert-skill
description: Develop, debug, and review Roblox Luau scripts using bundled API verification tools and specialist guidance for language, architecture, engine APIs, networking, UI, performance, security, and client/executor scripting. Use for Roblox or Luau implementation and troubleshooting.
---

# Roblox Luau Expert Skill

Read [.claude/skills/roblox-luau-expert/SKILL.md](.claude/skills/roblox-luau-expert/SKILL.md) first. Load the task contract and the specialists relevant to the current task.

This directory is the installed bundle root. Resolve each specialist's reference paths relative to that specialist. Read the local skill files directly; Claude-specific skill commands are not required in Codex. Preserve the user's requested scope and use tools available in the current session.
'@
            Add-Text ($wrapper + $pathsNote) (Join-Path $bundleRoot 'SKILL.md') $hostFolder
        }
        if ($hostNameEntry -eq 'Cursor') {
            $rule = [IO.File]::ReadAllText((Join-Path $PSScriptRoot '.cursor\rules\roblox-luau-expert.mdc'))
            Add-Text ($rule + $pathsNote) (Join-Path $hostFolder 'rules\roblox-luau-expert.mdc') $hostFolder
        }
    }

    # All source copies have succeeded before any installed file is moved.
    foreach ($operation in $operations) {
        $destination = Assert-ProfilePath $operation.Destination
        $backupRoot = Assert-ProfilePath (Join-Path $operation.HostFolder "skill-backups\roblox-luau-expert-$runId")
        $relative = $destination.Substring($operation.HostFolder.Length).TrimStart('\', '/')
        $backup = Assert-ProfilePath (Join-Path $backupRoot $relative)
        if (Test-Path -LiteralPath $destination) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $backup) -Force | Out-Null
            Move-Item -LiteralPath $destination -Destination $backup
        }
        if (-not $Uninstall) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
            try {
                Move-Item -LiteralPath $operation.Staged -Destination $destination
            } catch {
                if (Test-Path -LiteralPath $backup) { Move-Item -LiteralPath $backup -Destination $destination }
                throw
            }
        }
    }
    $action = if ($Uninstall) { 'Moved installed stack to backups' } else { 'Installed skills and complete verification bundle' }
    Write-Output "$action for $($hosts -join ', ')."
    Write-Output "Backup identifier: roblox-luau-expert-$runId"
} finally {
    Remove-Stage $stageRoot
}
