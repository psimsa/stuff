# Prune Branches PowerShell Script

The `prune-branches.ps1` script is designed to assist with managing local git branches. It can list and optionally delete branches based on whether they have unpushed changes or no corresponding remote branch.

## Usage

```
powershell -File prune-branches.ps1 [-deleteNoUpstream] [-deleteNoUnpushed] [-force] [-quiet] [-help]
```

## Parameters

- `-deleteNoUpstream`: Deletes local branches that do not have a corresponding remote branch on origin.
- `-deleteNoUnpushed`: Deletes local branches that do not have any unpushed changes.
- `-force`: Forces the deletion of branches, even if they have not been fully merged. Use with caution.
- `-quiet`: Suppresses all confirmation prompts.
- `-help`: Displays a help message.

## Output

The script displays a list of all local branches that have unpushed changes.

## Notes

The script does not attempt to delete the currently checked-out branch.
