# GitAutoBackup

Automatically commit and push changes in a Git repository on a schedule using **Windows Task Scheduler** and **PowerShell**.

GitAutoBackup works with GitHub, GitLab, Bitbucket, Azure DevOps, Gitea, and self-hosted Git servers. It simply commits local changes and runs `git push origin HEAD` for the branch currently checked out.

## Features

- Automatic Git commits and pushes on a schedule
- Supports **hourly, daily, weekly, and monthly** schedules
- Works with any Git hosting provider
- Each repository can have its own backup task and schedule
- Only backs up the **currently checked-out branch**
- Skips backups during merge, rebase, cherry-pick, or revert operations
- Skips backups when HEAD is detached
- Does nothing when there are no changes
- Keeps a simple `git-backup.log`
- Uses Windows Task Scheduler; no background application needs to remain open
- The task runs using your Windows user account, so Git can use your saved credentials

> **Important:** GitAutoBackup commits everything not excluded by `.gitignore`. Do not store passwords, API keys, private keys, or other secrets in files that will be backed up.

---

## Requirements

- Windows
- PowerShell
- Git
- A Git repository with a configured `origin` remote
- Git authentication that allows `git push` without interactive input

Test Git first:

```powershell
git push
```

If Git can push successfully, GitAutoBackup can normally use the same authentication.

---

# Installation

## 1. Put the script in your repository

Save `git-backup.ps1` inside the repository's hidden `.git` folder:

```text
your-repository/
└── .git/
    └── git-backup.ps1
```

The `.git` folder is ignored by Git, so the script itself will not become part of your project.

You can open the `.git` folder from a terminal in your repository:

```powershell
explorer .git
```

Then copy `git-backup.ps1` into that folder.

### Alternative layout

The script also supports the older:

```text
your-repository/
└── scripts/
    └── git-backup.ps1
```

layout.

---

## 2. Install the `GitAutoBackup` command

This only needs to be done **once per Windows PC**.

Open PowerShell and run:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force; if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Force $PROFILE | Out-Null }; Add-Content $PROFILE 'function GitAutoBackup { $s = @("$PWD\.git\git-backup.ps1", "$PWD\scripts\git-backup.ps1") | Where-Object { Test-Path $_ } | Select-Object -First 1; if ($s) { powershell -NoProfile -ExecutionPolicy Bypass -File $s @args } else { Write-Host "Open the terminal in your repo folder (the one containing the .git folder)." } }'
```

Close the terminal and open a new PowerShell/Windows Terminal window.

The command automatically finds the GitAutoBackup script in the repository where the terminal is currently open.

---

## 3. Open a terminal in your repository

Open the repository in File Explorer.

Right-click an empty area and choose:

**Open in Terminal**

Test the installation:

```powershell
GitAutoBackup -help
```

You should see the GitAutoBackup command help.

---

# Usage

All commands should be run from a terminal opened in the repository.

## List tasks

Show backup tasks for the current repository:

```powershell
GitAutoBackup -list
```

Show backup tasks for every repository:

```powershell
GitAutoBackup -list all
```

The `all` option also shows the script path, making it possible to identify which repository each task belongs to.

---

## Create a backup task

The general syntax is:

```text
GitAutoBackup -create [-name <taskname>] -schedule <type> <value> [hh:mm]
```

If `-name` is omitted, the task name is:

```text
GitAutoBackup-<repository-folder>
```

### Every N hours

```powershell
GitAutoBackup -create -schedule hour 2
```

Runs every 2 hours.

Valid values are:

```text
1-24
```

For example:

```powershell
GitAutoBackup -create -schedule hour 6
```

---

### Every day

```powershell
GitAutoBackup -create -schedule day 17:00
```

Runs every day at 17:00.

If no time is supplied, **12:00 (noon)** is used:

```powershell
GitAutoBackup -create -schedule day
```

---

### Every week

Specify either a number from `1` to `7`:

```text
1 = Monday
2 = Tuesday
3 = Wednesday
4 = Thursday
5 = Friday
6 = Saturday
7 = Sunday
```

For example:

```powershell
GitAutoBackup -create -schedule week 1 09:00
```

or use a day name:

```powershell
GitAutoBackup -create -schedule week mon 09:00
```

If the time is omitted, 12:00 is used:

```powershell
GitAutoBackup -create -schedule week fri
```

---

### Every month

Specify a day from `1` to `31`:

```powershell
GitAutoBackup -create -schedule month 15 08:00
```

This runs on the 15th of every month.

You can also use:

```powershell
GitAutoBackup -create -schedule month last 18:00
```

to run on the last day of the month.

If a month does not contain the requested day, that occurrence is skipped. For example, a task scheduled for day `31` does not run in April.

---

## Custom task names

Use `-name` when you want a custom Windows Task Scheduler task name:

```powershell
GitAutoBackup -create -name MyBackup -schedule day 17:00
```

Task names cannot contain:

```text
\ / : * ? " < > |
```

Creating another task with the same name **replaces the existing task**, which is useful for changing its schedule.

---

# Run a Backup Manually

To run a backup immediately:

```powershell
GitAutoBackup -run
```

This performs the same backup operation that the scheduled task performs.

Check the log afterwards:

```text
.git\git-backup.log
```

A successful run will contain either:

```text
backup pushed
```

or:

```text
no changes
```

---

# Delete a Backup Task

Delete one task:

```powershell
GitAutoBackup -delete GitAutoBackup-MyRepo
```

Delete multiple tasks:

```powershell
GitAutoBackup -delete OldBackup AnotherBackup
```

If a task name contains spaces, quote it:

```powershell
GitAutoBackup -delete "My old backup"
```

GitAutoBackup checks that the task is actually a GitAutoBackup task before deleting it.

---

# How Backups Work

GitAutoBackup behaves like an automatic Git autosave.

When a scheduled run occurs:

1. It checks that the directory is a Git repository.
2. It checks whether a Git operation is currently in progress.
3. It checks which branch is currently checked out.
4. It checks for uncommitted changes.
5. If there are changes, it runs:

```text
git add -A
```

6. It creates a commit:

```text
Auto backup (<branch>) <date and time>
```

7. It pushes the current branch:

```text
git push origin HEAD
```

8. It records the result in `git-backup.log`.

If there are no changes, no commit or push is performed.

---

# Branch Behavior

Backups are made on **the branch that is checked out when the task runs**.

For example:

```text
Monday     feature-a
Tuesday    main
Wednesday  feature-b
```

Backups made on Monday go to `feature-a`.

Backups made on Tuesday go to `main`.

Backups made on Wednesday go to `feature-b`.

Nothing is copied between branches.

If the branch does not yet exist on the remote, the first successful push can create it.

## Example

Suppose your history looks like this:

```text
main       ---o----B----o----B---------
feature-a  ---o----B----B--------------
feature-b  -------------------B----B---
```

Where:

```text
o = your normal commit
B = automatic backup commit
```

Automatic backups are ordinary Git commits. Your Git history can therefore contain many backup commits.

Before merging a feature branch, you can optionally squash those commits into a cleaner history.

---

# When a Backup Is Skipped

GitAutoBackup intentionally does **not** create a backup in certain situations.

## Merge in progress

If Git has a `MERGE_HEAD`, the backup is skipped.

## Rebase in progress

If a rebase is in progress, the backup is skipped.

## Cherry-pick in progress

If a cherry-pick is in progress, the backup is skipped.

## Revert in progress

If a revert is in progress, the backup is skipped.

These operations can temporarily leave files in a partially resolved state, so committing them automatically could capture an unwanted intermediate state.

The log records the reason:

```text
skipped: a merge is in progress
```

---

## Detached HEAD

If you check out an old commit or otherwise enter a detached HEAD state, there is no current branch to back up.

The backup is skipped and the log records:

```text
skipped: detached HEAD (not on a branch)
```

Once you return to a normal branch, future scheduled backups work normally.

---

# Logging

The script writes one line for every run.

When installed in `.git`, the log is:

```text
.git\git-backup.log
```

Example entries:

```text
2026-10-15 12:00:01 - no changes
2026-10-15 14:00:02 - backup pushed (main)
2026-10-15 16:00:01 - skipped: detached HEAD (not on a branch)
2026-10-15 18:00:03 - ERROR: git push failed: ...
```

When troubleshooting, **check this file first**.

---

# `.gitignore`

When the script uses the older `scripts` layout, it automatically adds:

```text
git-backup.log
```

to the repository's `.gitignore`.

When the script is inside `.git`, the log is already inside Git's ignored `.git` directory, so no `.gitignore` change is required.

---

# Windows Task Scheduler

GitAutoBackup creates a Windows Scheduled Task for each backup schedule.

Tasks run under your current Windows account with:

- Interactive logon
- Least-privilege execution
- Hidden PowerShell execution
- Automatic startup when the scheduled time was missed
- Protection against overlapping instances

You can also manage the tasks directly through:

**Start → Task Scheduler**

To temporarily pause a backup:

1. Open **Task Scheduler**.
2. Find the GitAutoBackup task.
3. Right-click it.
4. Select **Disable**.

You can re-enable it later.

---

# Authentication

GitAutoBackup must be able to run:

```powershell
git push
```

without asking you to enter credentials.

Test this manually before creating a scheduled task:

```powershell
git push
```

If Git asks for authentication, configure Git authentication first.

## HTTPS

Use your Git provider's supported Personal Access Token mechanism.

For GitLab, the token needs permission to write to the repository.

For GitHub, use a supported Personal Access Token with the permissions required to push to the repository.

Run `git push` manually once and allow Git's configured credential manager to save the credentials if appropriate.

## SSH

Alternatively, configure an SSH key for your Git provider.

For unattended backups, the authentication method must work without requiring an interactive password prompt.

---

# Remote Repository

The script currently pushes to:

```powershell
git push origin HEAD
```

This means the remote must normally be named:

```text
origin
```

Check your remotes with:

```powershell
git remote
```

If your remote has another name, change:

```powershell
git push origin HEAD
```

in `git-backup.ps1` to use your remote name.

For example:

```powershell
git push upstream HEAD
```

---

# Troubleshooting

## `GitAutoBackup is not recognized`

Close and reopen the terminal after completing installation.

If it still does not work, repeat the installation command from **Step 2**.

You can also run the script directly:

```powershell
powershell -ExecutionPolicy Bypass -File .\.git\git-backup.ps1
```

---

## `not a git repository`

Make sure the script is located in:

```text
<repository>\.git\git-backup.ps1
```

or:

```text
<repository>\scripts\git-backup.ps1
```

Also make sure you are running the command from the repository directory.

---

## `Authentication failed`

Run:

```powershell
git push
```

manually.

Configure HTTPS credentials/token authentication or SSH until this command succeeds without requiring interactive credentials.

---

## `could not read Username`

Git is trying to authenticate interactively, which is not suitable for an unattended scheduled task.

Configure Git credentials or SSH and test:

```powershell
git push
```

again.

---

## `'origin' does not appear to be a git repository`

Check the configured remote:

```powershell
git remote
```

If it is not named `origin`, update the `git push origin HEAD` command in the script.

---

## `rejected` / `non-fast-forward`

The remote contains commits that your local repository does not have.

For example, another computer may have pushed changes.

Run a normal Git synchronization manually, for example:

```powershell
git pull
```

Resolve any conflicts if necessary, then run:

```powershell
git push
```

Once the branches are synchronized, automatic backups can continue.

---

## No entries in the log

Check whether the scheduled task exists:

```powershell
GitAutoBackup -list
```

If no task is listed, create one:

```powershell
GitAutoBackup -create -schedule day 17:00
```

You can also test the backup immediately:

```powershell
GitAutoBackup -run
```

---

# Important Limitations

### The computer must be available

Scheduled tasks run according to Windows Task Scheduler.

If the computer is off at the scheduled time, the task is configured to run when it becomes available.

The task is intended to run while you are logged into Windows so that Git can use your saved authentication.

### Backups are not stored separately

The backup is an ordinary Git commit pushed to your configured remote repository.

It is not a separate snapshot database.

### `.git` is not backed up

The script lives inside `.git`, which Git does not version.

Therefore:

- the script is not pushed to the remote;
- the Windows scheduled task is not pushed;
- cloning the repository on another computer does not recreate the task.

Keep a copy of `git-backup.ps1` somewhere safe.

After cloning the repository onto another computer, repeat the installation and task-creation steps.

### Secrets can be committed

GitAutoBackup stages everything using:

```powershell
git add -A
```

Anything not excluded by `.gitignore` can therefore be committed and pushed.

Make sure sensitive files are included in `.gitignore`.

---

# Command Reference

| Command | Description |
|---|---|
| `GitAutoBackup -help` | Show help |
| `GitAutoBackup -man` | Show help |
| `GitAutoBackup -list` | List tasks for the current repository |
| `GitAutoBackup -list all` | List tasks for all repositories |
| `GitAutoBackup -run` | Run a backup immediately |
| `GitAutoBackup -create -schedule hour 2` | Run every 2 hours |
| `GitAutoBackup -create -schedule day 17:00` | Run every day at 17:00 |
| `GitAutoBackup -create -schedule week mon 09:30` | Run every Monday at 09:30 |
| `GitAutoBackup -create -schedule month 15` | Run on the 15th of every month |
| `GitAutoBackup -create -schedule month last` | Run on the last day of every month |
| `GitAutoBackup -delete <name>` | Delete a backup task |

---

# Examples

## Backup every 2 hours

```powershell
GitAutoBackup -create -schedule hour 2
```

## Backup every day at 17:00

```powershell
GitAutoBackup -create -schedule day 17:00
```

## Backup every Monday at 09:30

```powershell
GitAutoBackup -create -schedule week mon 09:30
```

## Backup on the 15th of every month

```powershell
GitAutoBackup -create -schedule month 15
```

## Backup on the last day of every month at 18:00

```powershell
GitAutoBackup -create -schedule month last 18:00
```

## Use a custom task name

```powershell
GitAutoBackup -create -name MyBackup -schedule day 17:00
```

## Change an existing schedule

Simply create the task again with the same name:

```powershell
GitAutoBackup -create -name MyBackup -schedule day 20:00
```

The existing task is replaced.

---

# Typical Setup

A minimal setup looks like this:

```powershell
# 1. Test Git authentication
git push

# 2. Install the GitAutoBackup command
#    (run the installation command from the installation section)

# 3. Close and reopen the terminal

# 4. Test GitAutoBackup
GitAutoBackup -help

# 5. Check existing tasks
GitAutoBackup -list

# 6. Create a daily backup at 17:00
GitAutoBackup -create -schedule day 17:00

# 7. Test immediately
GitAutoBackup -run

# 8. Check the log
# .git\git-backup.log
```

After that, Windows Task Scheduler handles the recurring backups.

---

# License

Choose and add a license appropriate for your project, for example MIT:

```text
MIT License
```

If this project is intended to be distributed publicly, include a `LICENSE` file containing the complete license text.
