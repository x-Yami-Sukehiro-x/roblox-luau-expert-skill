# Register the scheduled task that keeps GitHub and the installed Codex / ChatGPT
# desktop plugin current: tools/bin/auto-update.mjs every 20 minutes and at
# sign-in, as you, with no window. Its log is auto-update.log in the .git folder.
#
#   powershell -ExecutionPolicy Bypass -File tools\bin\install-auto-update.ps1
#   powershell -ExecutionPolicy Bypass -File tools\bin\install-auto-update.ps1 -Remove
param([switch]$Remove, [int]$Minutes = 20)

$ErrorActionPreference = 'Stop'
$taskName = 'Roblox Luau Expert auto-update'

if ($Remove) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    "Removed '$taskName'."
    return
}

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$node = (Get-Command node).Source
$runner = Join-Path $repo 'tools\bin\auto-update.mjs'
$user = "$env:USERDOMAIN\$env:USERNAME"

# conhost --headless runs a console program without opening a console window.
$action = New-ScheduledTaskAction -Execute 'conhost.exe' `
    -Argument "--headless `"$node`" `"$runner`"" -WorkingDirectory $repo
$triggers = @(
    (New-ScheduledTaskTrigger -AtLogOn -User $user),
    (New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) `
        -RepetitionInterval (New-TimeSpan -Minutes $Minutes))
)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 30)
$principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $triggers `
    -Settings $settings -Principal $principal -Force | Out-Null
"Registered '$taskName': every $Minutes minutes and at sign-in."
