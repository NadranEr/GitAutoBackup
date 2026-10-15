<#
=====================================================================
 GIT AUTO BACKUP - QUICK GUIDE
=====================================================================

WHAT IT DOES
  On a schedule, this script checks if anything changed in your repo.
  If yes, it saves the changes (a "commit") and uploads them ("push")
  to your remote repository. It works with any Git host: GitLab,
  GitHub, Bitbucket, Azure DevOps, Gitea, self-hosted... (it simply
  runs "git push origin" for the current branch).
  If not, it does nothing. Each run adds one line to git-backup.log.

THE COMMAND
  Once installed (STEP 3), you manage everything with one command,
  typed in a terminal opened in your repo:

    GitAutoBackup -list [all]
    GitAutoBackup -delete <taskname1> [taskname2] ...
    GitAutoBackup -create [-name <taskname>] -schedule <type> <value> [hh:mm]
    GitAutoBackup -run
    GitAutoBackup -help        (or -man)

  Schedule types:
    hour  <n>             every n hours (1-24)
    day   [hh:mm]         every day at hh:mm (24-hour format)
    week  <d> [hh:mm]     every week on day d: 1-7 (1=Monday) or
                          mon,tue,wed,thu,fri,sat,sun
    month <dd> [hh:mm]    every month on day dd (1-31, or "last")
  If you leave out hh:mm, 12:00 (noon) is used.

  Examples:
    GitAutoBackup -create -schedule hour 2
    GitAutoBackup -create -schedule day 17:00
    GitAutoBackup -create -schedule week mon 09:30
    GitAutoBackup -create -name MyBackup -schedule month 15
    GitAutoBackup -delete GitAutoBackup-MyRepo

  If no -name is given, the task is called GitAutoBackup-<repo folder>.
  Each repo can have its own task and its own schedule.


---------------------------------------------------------------------
 STEP 1 - Put the script in your repo
---------------------------------------------------------------------
  The script lives inside the hidden ".git" folder of your repo. Git
  ignores that folder, so nothing is added to your project files.
  - In File Explorer, open your repo folder, right-click an empty spot
    > "Open in Terminal", type:   explorer .git    and press Enter.
    (Or: File Explorer > View > Show > Hidden items, then open ".git".)
  - Paste this file (git-backup.ps1) in the window that opens.
  Result:   <your repo>\.git\git-backup.ps1


---------------------------------------------------------------------
 STEP 2 - Open this file in Notepad
---------------------------------------------------------------------
  Right-click the file > Open with > Notepad.
  Keep it open: you will copy the commands from it.


---------------------------------------------------------------------
 STEP 3 - Install the GitAutoBackup command (ONCE per PC)
---------------------------------------------------------------------
  Skip this step if you already did it for another repo.

  Open PowerShell (Start menu > type PowerShell > Enter), paste the
  line below, press Enter, then CLOSE and REOPEN the terminal:

Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force; if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Force $PROFILE | Out-Null }; Add-Content $PROFILE 'function GitAutoBackup { $s = @("$PWD\.git\git-backup.ps1", "$PWD\scripts\git-backup.ps1") | Where-Object { Test-Path $_ } | Select-Object -First 1; if ($s) { powershell -NoProfile -ExecutionPolicy Bypass -File $s @args } else { Write-Host "Open the terminal in your repo folder (the one containing the .git folder)." } }'

  (What it does: allows PowerShell to load your personal profile, and
  adds a "GitAutoBackup" shortcut that runs the script of whichever
  repo your terminal is currently in. If you installed an earlier
  version of this shortcut, paste the line again: the new one replaces it.)


---------------------------------------------------------------------
 STEP 4 - Open a terminal in your repo
---------------------------------------------------------------------
  In File Explorer, open your repo folder (the one that contains
  ".git"). Right-click an empty spot > "Open in Terminal".
  Use this same window for the next steps. To paste in the terminal:
  right-click (or Ctrl+V). Then press Enter.

  Quick test:      GitAutoBackup -help

  Also make sure Git can upload without asking a password: type
  "git push". If it uploads or says "up-to-date", all good. If it asks
  for a login, see TROUBLESHOOTING at the end.


---------------------------------------------------------------------
 STEP 5 - Is there already a backup task for this repo?
---------------------------------------------------------------------
      GitAutoBackup -list

  - "No backup task found" = none yet. Go to STEP 7.
  - A table = existing tasks of this repo (name, state, schedule,
    next run).
    Several rows = old tasks you may have forgotten: they all keep
    running.
  To see the backup tasks of ALL your repos (and tasks made with older
  versions of this script):      GitAutoBackup -list all


---------------------------------------------------------------------
 STEP 6 - (Optional) Delete tasks
---------------------------------------------------------------------
  Use the TaskName shown by -list. You can give several names:

      GitAutoBackup -delete GitAutoBackup-MyRepo
      GitAutoBackup -delete OldName1 OldName2

  If a name contains spaces, put it between quotes: "My old task".
  Only backup tasks can be deleted this way (other Windows tasks are
  refused). The remaining tasks are displayed afterwards.


---------------------------------------------------------------------
 STEP 7 - Create the backup task
---------------------------------------------------------------------
  Pick your schedule (see THE COMMAND at the top), for example:

      GitAutoBackup -create -schedule day 17:00

  The result is displayed right away: you should see ONE row with the
  name of your task and its NextRun time. That is your confirmation.

  Creating a task with the same name again REPLACES it: this is how you
  change a schedule. If other tasks already exist for this repo, you
  are warned.

  Optional test - run a backup right now, then open git-backup.log
  (in the .git folder, next to the script). "backup pushed" or "no
  changes" means it works:

      GitAutoBackup -run


---------------------------------------------------------------------
 WHERE ARE THE BACKUPS DONE? (example with 3 branches)
---------------------------------------------------------------------
  Think of it as an AUTOSAVE: each backup is a commit made on the
  branch that is checked out at that moment, and only that branch is
  pushed. Branches you are not on are never touched.

  Example: you work on feature-a on Monday, on main on Tuesday and on
  feature-b on Wednesday. The task runs a few times each day.

                  Monday              Tuesday             Wednesday
     you work on: feature-a           main                feature-b
                  
     main         -------------------------B----o-----B-----------------------
     feature-a    ---o----B-----B---o-----------------------------------------
     feature-b    ---------------------------------------------B-----B----o---

     o = a commit you made yourself
     B = an automatic backup commit

  What to notice:
  - Monday's backups all went to feature-a, Tuesday's to main,
    Wednesday's to feature-b. Each branch only holds the backups made
    while you were on it. Nothing is copied between branches.
  - If a branch does not exist on the remote yet, its first backup
    creates it there.
  - Each backup commit is named:  Auto backup (<branch>) <date time>
  - Backups are plain commits, so your history will contain many of
    them. Before merging a branch you can squash them into one commit
    (GitLab: "Squash commits" option on the merge request; GitHub:
    "Squash and merge").

  WHEN A BACKUP IS SKIPPED
  The script does nothing, and writes "skipped: ..." in the log, when:
  - a merge, rebase, cherry-pick or revert is in progress: files may be
    half-resolved, and the backup would commit and push that broken
    state;
  - you are on a "detached HEAD" (you checked out an old commit just to
    look at it): you are on no branch, so there is nowhere to back up.
  The next scheduled run backs up normally once you are done.


---------------------------------------------------------------------
 GOOD TO KNOW
---------------------------------------------------------------------
  - Tasks only run while you are logged in to Windows (so Git can use
    your saved login). If the PC was off at the scheduled time, the
    backup runs as soon as it is back on.
  - Everything not listed in .gitignore is backed up, including
    secrets or large files if they are in the folder.
  - The script sits in .git, so switching branches never affects it.
    But it is NOT backed up or pushed (Git ignores .git): keep a copy
    of git-backup.ps1 somewhere safe. If you delete the repo folder or
    clone it again, redo STEPS 1 to 7.
  - On a new computer, tasks are not copied either: redo STEPS 1 to 7.
  - Each backup creates a commit named "Auto backup (<branch>) <date
    and time>". A long list of these in your history is normal.
  - Months shorter than the chosen day are skipped (for example day 31
    does not run in April). Use "last" to run on the last day.
  - Pause a task: open "Task Scheduler" (Start menu), find it, and
    right-click > Disable.


---------------------------------------------------------------------
 TROUBLESHOOTING
---------------------------------------------------------------------
  Read git-backup.log first (in the .git folder, next to the script):
  lines starting with ERROR give the cause.

  - "GitAutoBackup is not recognized":
      STEP 3 was not done, or the terminal was not reopened afterwards.
      Without STEP 3 you can still use the script directly, from the
      repo folder, by replacing "GitAutoBackup" with:
      powershell -ExecutionPolicy Bypass -File .\.git\git-backup.ps1
  - "Authentication failed" or "could not read Username":
      Git cannot log in by itself. Set up ONE of these:
      a) HTTPS: on your Git host, create a Personal Access Token with
         write access to the repo (GitLab: User settings > Access
         tokens, scope write_repository; GitHub: Settings > Developer
         settings > Personal access tokens). Use it as the password
         once with "git push"; Windows remembers it.
      b) SSH: add an SSH key (without passphrase) to your account on
         your Git host.
  - "not a git repository":
      The script is not in <your repo>\.git\. Redo STEP 1.
  - Nothing in the log at all:
      Run GitAutoBackup -list. If no task is shown, redo STEP 7.
  - "'origin' does not appear to be a git repository":
      Your remote has another name. Type "git remote" to see it, then
      replace "origin" with that name in the line "git push origin
      HEAD" near the end of this file.
  - "rejected" or "non-fast-forward":
      The remote has changes your PC does not (for example from another
      machine). Run "git pull" once manually, then backups work again.


=====================================================================
 THE SCRIPT (nothing below needs to be edited)
=====================================================================
#>

# --- Basic settings ---------------------------------------------------

# The repository is the parent folder of the folder containing this script
# (the script normally sits in <repo>\.git).
$repo        = Split-Path -Parent $PSScriptRoot
$inGitFolder = (Split-Path $PSScriptRoot -Leaf) -eq ".git"
# The log sits next to the script when it is in .git (Git ignores it there).
# With the older "scripts" folder layout, it sits at the repo root instead.
if ($inGitFolder) { $log = Join-Path $PSScriptRoot "git-backup.log" }
else              { $log = Join-Path $repo "git-backup.log" }
$scriptPath  = $PSCommandPath
$defaultName = "GitAutoBackup-" + (Split-Path $repo -Leaf)

# --- Helpers ----------------------------------------------------------

# Writes one line to the log, prefixed with date and time.
function Write-Log($message) {
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$stamp - $message" | Out-File $log -Append -Encoding utf8
}

# Shows an error message and stops.
function Fail($message) {
    Write-Host "ERROR: $message" -ForegroundColor Red
    Write-Host "Type GitAutoBackup -help to see the syntax."
    exit 1
}

# Prints the help text (-help or -man).
function Show-Help {
    Write-Host @'

GitAutoBackup - automatic Git backups on a schedule

USAGE (in a terminal opened in your repo folder)
  GitAutoBackup -list [all]
  GitAutoBackup -delete <taskname1> [taskname2] ...
  GitAutoBackup -create [-name <taskname>] -schedule <type> <value> [hh:mm]
  GitAutoBackup -run
  GitAutoBackup -help | -man

COMMANDS
  -list [all]   Show the backup tasks of this repo: name, state,
                schedule and next run.
                With "all": show the tasks of every repo (+ script path).
  -delete       Delete one or more backup tasks, by name (see -list).
                Names with spaces must be put between quotes.
  -create       Create a backup task (or replace the one of same name).
                -name      Task name. Default: GitAutoBackup-<repo folder>
                -schedule  When to run (see below). Required.
  -run          Run a backup right now (this is what the task runs).
  -help, -man   Show this help.

SCHEDULE TYPES
  hour  <n>             Every n hours (1-24).
  day   [hh:mm]         Every day at hh:mm (24-hour format).
  week  <d> [hh:mm]     Every week on day d: 1-7 (1=Monday)
                        or mon,tue,wed,thu,fri,sat,sun.
  month <dd> [hh:mm]    Every month on day dd (1-31, or "last").
                        Months without that day are skipped.
  If hh:mm is not given, 12:00 is used.

EXAMPLES
  GitAutoBackup -list
  GitAutoBackup -create -schedule hour 2
  GitAutoBackup -create -schedule day 17:00
  GitAutoBackup -create -schedule week mon 09:30
  GitAutoBackup -create -schedule week 5
  GitAutoBackup -create -name MyBackup -schedule month 15 08:00
  GitAutoBackup -delete GitAutoBackup-MyRepo MyBackup

NOTES
  - Re-creating a task with the same name replaces it (change schedule).
  - Tasks run only while you are logged in to Windows.
  - Log file: git-backup.log, next to this script.
  - Backups are skipped during a merge/rebase/cherry-pick/revert and
    on a detached HEAD (a "skipped: ..." line is written in the log).

'@
}

# Returns the backup tasks of this repo (or of all repos with -AllRepos).
function Get-BackupTasks {
    param([switch]$AllRepos)
    if ($AllRepos) { $pattern = "*git-backup.ps1*" }
    else { $pattern = "*" + [WildcardPattern]::Escape($scriptPath) + "*" }
    Get-ScheduledTask -ErrorAction SilentlyContinue |
        Where-Object { $_.Actions.Arguments -like $pattern }
}

# Turns an ISO 8601 interval such as PT2H or P1D into words ("2 hour(s)").
function Convert-Interval($iso) {
    if ("$iso" -match '^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?)?$') {
        $parts = @()
        if ($Matches[1]) { $parts += "$([int]$Matches[1]) day(s)" }
        if ($Matches[2]) { $parts += "$([int]$Matches[2]) hour(s)" }
        if ($Matches[3]) { $parts += "$([int]$Matches[3]) min" }
        if ($parts.Count -gt 0) { return ($parts -join " ") }
    }
    return "$iso"
}

# Describes when a task runs, in plain words (read from the task's XML).
function Get-ScheduleText {
    param($Task)
    try {
        $x  = [xml](Export-ScheduledTask -TaskName $Task.TaskName -TaskPath $Task.TaskPath)
        $ns = New-Object System.Xml.XmlNamespaceManager($x.NameTable)
        $ns.AddNamespace('t', 'http://schemas.microsoft.com/windows/2004/02/mit/task')
        $texts = @()
        foreach ($trg in $x.SelectNodes('//t:Triggers/*', $ns)) {
            $at = ""
            $sb = $trg.SelectSingleNode('t:StartBoundary', $ns)
            if ($sb -and $sb.InnerText -match 'T(\d\d:\d\d)') { $at = $Matches[1] }
            $rep  = $trg.SelectSingleNode('t:Repetition/t:Interval', $ns)
            $text = $trg.LocalName
            if ($rep) {
                $text = "every " + (Convert-Interval $rep.InnerText)
            }
            elseif ($trg.LocalName -eq 'TimeTrigger') {
                $text = "once at $at"
            }
            elseif ($trg.LocalName -eq 'LogonTrigger') { $text = "at logon" }
            elseif ($trg.LocalName -eq 'BootTrigger')  { $text = "at startup" }
            elseif ($trg.SelectSingleNode('t:ScheduleByDay', $ns)) {
                $n = [int]$trg.SelectSingleNode('t:ScheduleByDay/t:DaysInterval', $ns).InnerText
                if ($n -gt 1) { $text = "every $n days at $at" } else { $text = "every day at $at" }
            }
            elseif ($trg.SelectSingleNode('t:ScheduleByWeek', $ns)) {
                $days = (@($trg.SelectNodes('t:ScheduleByWeek/t:DaysOfWeek/*', $ns) | ForEach-Object { $_.LocalName.Substring(0, 3) })) -join ","
                $w = [int]$trg.SelectSingleNode('t:ScheduleByWeek/t:WeeksInterval', $ns).InnerText
                if ($w -gt 1) { $text = "every $w weeks on $days at $at" } else { $text = "every week on $days at $at" }
            }
            elseif ($trg.SelectSingleNode('t:ScheduleByMonth', $ns)) {
                $days = (@($trg.SelectNodes('t:ScheduleByMonth/t:DaysOfMonth/t:Day', $ns) | ForEach-Object { $_.InnerText.ToLower() })) -join ","
                $text = "every month on day $days at $at"
            }
            $texts += $text
        }
        if ($texts.Count -eq 0) { return "-" }
        return ($texts -join "; ")
    }
    catch {
        return "?"
    }
}

# Displays tasks as a small table: name, state, schedule, next run.
# With -ShowScript, also shows which script (which repo) each task runs.
function Show-Tasks {
    param($Tasks, [switch]$ShowScript)
    $Tasks = @($Tasks | Where-Object { $_ })
    if ($Tasks.Count -eq 0) {
        Write-Host "No backup task found."
        return
    }
    $rows = foreach ($t in $Tasks) {
        $info = Get-ScheduledTaskInfo -TaskName $t.TaskName -TaskPath $t.TaskPath
        $next = "-"
        if ($info.NextRunTime -and $info.NextRunTime.Year -gt 2000) {
            $next = $info.NextRunTime.ToString("yyyy-MM-dd HH:mm")
        }
        $row = [ordered]@{
            TaskName = $t.TaskName
            State    = "$($t.State)"
            Schedule = Get-ScheduleText $t
            NextRun  = $next
        }
        if ($ShowScript) {
            $m = [regex]::Match("$($t.Actions.Arguments)", '-File "?([^"]+?git-backup\.ps1)')
            $row['Script'] = $m.Groups[1].Value
        }
        [pscustomobject]$row
    }
    $rows | Format-Table -AutoSize -Wrap | Out-String | Write-Host
}

# Checks a time like 9:30 or 17:00 and returns it as hh:mm.
# No value = 12:00.
function Get-Hhmm($value) {
    if (-not $value) { return "12:00" }
    if ("$value" -match '^([01]?\d|2[0-3]):([0-5]\d)$') {
        return ('{0:00}:{1}' -f [int]$Matches[1], $Matches[2])
    }
    Fail "Invalid time '$value'. Use hh:mm in 24-hour format, for example 17:00."
}

# --- The backup itself ------------------------------------------------

function Invoke-Backup {
    # Work from inside the repository.
    Set-Location $repo

    try {
        # Where Git keeps its internal files for this repo.
        $gitDir = git rev-parse --absolute-git-dir 2>$null
        if (-not $gitDir) { throw "not a git repository: $repo" }

        # Skip while a merge, rebase, cherry-pick or revert is in progress:
        # files may be half-resolved and must not be committed and pushed.
        $operations = [ordered]@{
            'MERGE_HEAD'       = 'merge'
            'CHERRY_PICK_HEAD' = 'cherry-pick'
            'REVERT_HEAD'      = 'revert'
            'rebase-merge'     = 'rebase'
            'rebase-apply'     = 'rebase'
        }
        foreach ($item in $operations.Keys) {
            if (Test-Path (Join-Path $gitDir $item)) {
                Write-Log "skipped: a $($operations[$item]) is in progress"
                return
            }
        }

        # Skip on a detached HEAD (no current branch to back up).
        $branch = git symbolic-ref --short -q HEAD 2>$null
        if (-not $branch) {
            Write-Log "skipped: detached HEAD (not on a branch)"
            return
        }

        # "git status --porcelain" prints nothing when no file has changed.
        $changes = git status --porcelain

        if ($changes) {
            # 1. Stage all changes (new, modified and deleted files).
            git add -A
            if ($LASTEXITCODE -ne 0) { throw "git add failed" }

            # 2. Save them as a commit, named with the branch and the time.
            $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $out = git commit -m "Auto backup ($branch) $stamp" 2>&1
            if ($LASTEXITCODE -ne 0) { throw "git commit failed: $out" }

            # 3. Upload the commit to the remote (GitLab, GitHub, ...).
            $out = git push origin HEAD 2>&1
            if ($LASTEXITCODE -ne 0) { throw "git push failed: $out" }

            Write-Log "backup pushed ($branch)"
        }
        else {
            Write-Log "no changes"
        }
    }
    catch {
        # Any failure is recorded in the log instead of showing a window.
        Write-Log "ERROR: $_"
    }
}

# --- Delete tasks (-delete) -------------------------------------------

function Remove-BackupTasks {
    param($Names)
    if (@($Names).Count -eq 0) {
        Fail "Give at least one task name. Example: GitAutoBackup -delete GitAutoBackup-MyRepo"
    }
    foreach ($n in $Names) {
        $t = Get-ScheduledTask -TaskName $n -ErrorAction SilentlyContinue
        if (-not $t) {
            Write-Host "Not found: $n"
            continue
        }
        if (-not ($t.Actions.Arguments -like "*git-backup.ps1*")) {
            Write-Host "Skipped '$n': it is not a GitAutoBackup task."
            continue
        }
        try {
            Unregister-ScheduledTask -TaskName $n -TaskPath $t.TaskPath -Confirm:$false -ErrorAction Stop
            Write-Host "Deleted: $n"
        }
        catch {
            Write-Host "Could not delete '$n': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    Write-Host ""
    Write-Host "Backup tasks remaining for this repo:"
    Show-Tasks (Get-BackupTasks)
}

# --- Create a task (-create) ------------------------------------------

function New-BackupTask {
    param([string]$TaskName, $Sched)

    if ($TaskName -match '[\\/:*?"<>|]') {
        Fail "The task name cannot contain any of these characters: \ / : * ? `" < > |"
    }
    $Sched = @($Sched)
    if ($Sched.Count -eq 0) {
        Fail "Missing -schedule. Example: GitAutoBackup -create -schedule day 17:00"
    }

    $type  = "$($Sched[0])".ToLower()
    $extra = @()
    if ($Sched.Count -gt 1) { $extra = @($Sched[1..($Sched.Count - 1)]) }

    $dayShort = @('mon','tue','wed','thu','fri','sat','sun')
    $dayFull  = @('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')
    $allMonths = '<January /><February /><March /><April /><May /><June /><July /><August /><September /><October /><November /><December />'
    $fmt = "yyyy-MM-dd'T'HH:mm:ss"

    switch ($type) {

        'hour' {
            $n = 0
            if ($extra.Count -lt 1 -or -not [int]::TryParse("$($extra[0])", [ref]$n) -or $n -lt 1 -or $n -gt 24) {
                Fail "'hour' needs a number between 1 and 24. Example: -schedule hour 2"
            }
            $start   = (Get-Date).ToString($fmt)
            $trigger = "<TimeTrigger><Repetition><Interval>PT${n}H</Interval><StopAtDurationEnd>false</StopAtDurationEnd></Repetition><StartBoundary>$start</StartBoundary><Enabled>true</Enabled></TimeTrigger>"
            $desc    = "every $n hour(s)"
        }

        'day' {
            $time    = Get-Hhmm ($extra | Select-Object -First 1)
            $start   = (Get-Date).Date.Add([TimeSpan]::Parse($time)).ToString($fmt)
            $trigger = "<CalendarTrigger><StartBoundary>$start</StartBoundary><Enabled>true</Enabled><ScheduleByDay><DaysInterval>1</DaysInterval></ScheduleByDay></CalendarTrigger>"
            $desc    = "every day at $time"
        }

        'week' {
            if ($extra.Count -lt 1) {
                Fail "'week' needs a day: 1-7 or mon,tue,wed,thu,fri,sat,sun. Example: -schedule week mon"
            }
            $d   = "$($extra[0])".ToLower()
            $idx = -1
            if ($d -match '^[1-7]$') { $idx = [int]$d - 1 }
            elseif ($d.Length -ge 3 -and $dayShort -contains $d.Substring(0, 3)) {
                $idx = [array]::IndexOf($dayShort, $d.Substring(0, 3))
            }
            if ($idx -lt 0) {
                Fail "Invalid day '$($extra[0])'. Use 1-7 (1=Monday) or mon,tue,wed,thu,fri,sat,sun."
            }
            $time    = Get-Hhmm ($extra | Select-Object -Skip 1 -First 1)
            $start   = (Get-Date).Date.Add([TimeSpan]::Parse($time)).ToString($fmt)
            $dayName = $dayFull[$idx]
            $trigger = "<CalendarTrigger><StartBoundary>$start</StartBoundary><Enabled>true</Enabled><ScheduleByWeek><DaysOfWeek><$dayName /></DaysOfWeek><WeeksInterval>1</WeeksInterval></ScheduleByWeek></CalendarTrigger>"
            $desc    = "every week on $dayName at $time"
        }

        'month' {
            if ($extra.Count -lt 1) {
                Fail "'month' needs a day of the month (1-31 or last). Example: -schedule month 15"
            }
            $d = "$($extra[0])".ToLower()
            if ($d -eq 'last') { $dayXml = 'Last' }
            elseif ($d -match '^([1-9]|[12]\d|3[01])$') { $dayXml = [string][int]$d }
            else { Fail "Invalid day of month '$($extra[0])'. Use 1-31 or last." }
            $time    = Get-Hhmm ($extra | Select-Object -Skip 1 -First 1)
            $start   = (Get-Date).Date.Add([TimeSpan]::Parse($time)).ToString($fmt)
            $trigger = "<CalendarTrigger><StartBoundary>$start</StartBoundary><Enabled>true</Enabled><ScheduleByMonth><DaysOfMonth><Day>$dayXml</Day></DaysOfMonth><Months>$allMonths</Months></ScheduleByMonth></CalendarTrigger>"
            $desc    = "every month on day $($dayXml.ToLower()) at $time"
        }

        default {
            Fail "Unknown schedule type '$($Sched[0])'. Use hour, day, week or month."
        }
    }

    # Make sure the log file is ignored by Git (otherwise it would be
    # backed up again and again).
    $gi = Join-Path $repo ".gitignore"
    # (Not needed when the script is in the .git folder: Git ignores it.)
    $alreadyIgnored = $inGitFolder -or ((Test-Path $gi) -and (Select-String -Path $gi -SimpleMatch -Pattern "git-backup.log" -Quiet))
    if (-not $alreadyIgnored) {
        Add-Content -Path $gi -Value "`ngit-backup.log" -Encoding ASCII
        Write-Host "Added git-backup.log to .gitignore."
    }

    # Build and register the Windows task.
    $esc    = { param($s) [System.Security.SecurityElement]::Escape($s) }
    $taskArgs = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -run"
    $argsXml  = & $esc $taskArgs
    $userXml  = & $esc ([Security.Principal.WindowsIdentity]::GetCurrent().Name)

    $xml = @"
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>GitAutoBackup for $(& $esc $repo)</Description>
  </RegistrationInfo>
  <Triggers>
    $trigger
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$userXml</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <StartWhenAvailable>true</StartWhenAvailable>
    <ExecutionTimeLimit>PT1H</ExecutionTimeLimit>
    <Enabled>true</Enabled>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>$argsXml</Arguments>
    </Exec>
  </Actions>
</Task>
"@

    try {
        Register-ScheduledTask -TaskName $TaskName -Xml $xml -Force -ErrorAction Stop | Out-Null
    }
    catch {
        Fail "Could not create the task: $($_.Exception.Message)"
    }

    Write-Host "Task '$TaskName' created: backup $desc."

    # Warn about other tasks already attached to this repo.
    $others = @(Get-BackupTasks | Where-Object { $_.TaskName -ne $TaskName })
    if ($others.Count -gt 0) {
        $list = ($others | ForEach-Object { $_.TaskName }) -join ", "
        Write-Host ""
        Write-Host "WARNING: other backup task(s) already exist for this repo: $list" -ForegroundColor Yellow
        Write-Host "They keep running too. To remove them: GitAutoBackup -delete <taskname>" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Backup tasks for this repo:"
    Show-Tasks (Get-BackupTasks)
}

# --- Command dispatcher -----------------------------------------------
# No argument = run a backup (this is what older tasks do).

$mode = "-run"
if ($args.Count -gt 0) { $mode = "$($args[0])".ToLower() }
$rest = @()
if ($args.Count -gt 1) { $rest = @($args[1..($args.Count - 1)]) }

switch ($mode) {

    '-run' { Invoke-Backup }

    '-list' {
        $all = ($rest -contains 'all') -or ($rest -contains '-all')
        if ($all) {
            Write-Host "Backup tasks of all repos:"
            Show-Tasks (Get-BackupTasks -AllRepos) -ShowScript
        }
        else {
            Write-Host "Backup tasks for this repo ($repo):"
            Show-Tasks (Get-BackupTasks)
        }
    }

    '-delete' { Remove-BackupTasks $rest }

    '-create' {
        $name  = $defaultName
        $sched = @()
        $i = 0
        while ($i -lt $rest.Count) {
            $token = "$($rest[$i])".ToLower()
            if ($token -eq '-name') {
                $i++
                if ($i -ge $rest.Count) { Fail "-name needs a value. Example: -name MyBackup" }
                $name = "$($rest[$i])"
                $i++
            }
            elseif ($token -eq '-schedule') {
                $i++
                while ($i -lt $rest.Count -and "$($rest[$i])" -notlike '-*') {
                    $sched += $rest[$i]
                    $i++
                }
            }
            else {
                Fail "Unknown option '$($rest[$i])'."
            }
        }
        New-BackupTask -TaskName $name -Sched $sched
    }

    { $_ -in '-help', '-man', '-h', '--help' } { Show-Help }

    default { Fail "Unknown command '$($args[0])'." }
}
