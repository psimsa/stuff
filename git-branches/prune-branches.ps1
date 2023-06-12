param (
    [switch]$deleteNoUpstream,
    [switch]$deleteNoUnpushed,
    [switch]$force,
    [switch]$quiet,
    [switch]$help
)

if ($help)
{
    Write-Host @"
This script is designed to assist with managing local git branches. It has the following options:

-deleteNoUpstream: Deletes local branches that do not have a corresponding remote branch on origin.
-deleteNoUnpushed: Deletes local branches that do not have any unpushed changes.
-force: Forces the deletion of branches, even if they have not been fully merged. Use with caution.
-quiet: Suppresses all confirmation prompts.
-help: Displays this help message.

The script displays a list of all local branches that have unpushed changes.

Run the script like this:

powershell -File <script_name.ps1> -deleteNoUpstream -deleteNoUnpushed -force -quiet -help

Replace <script_name.ps1> with the name of the file where you saved the script.

NOTE: The script does not attempt to delete the currently checked-out branch.
"@
    exit
}

# Color variables
$colorNoUpstream = "Yellow"
$colorHeader = "Cyan"
$colorUnpushedChanges = "Green"
$colorConfirmation = "Magenta"
$colorForceConfirmation = "Red"

# Initialize an empty array to hold branches with unpushed changes
$branchesWithUnpushedChanges = @()
$branchesWithoutUpstream = @()

# Get a list of all local branches
$localBranches = git branch --format "%(refname:short)"

# Get a list of all remote branches
$remoteBranches = git branch -r --format "%(refname:short)"

# Get the currently checked-out branch
$currentBranch = git rev-parse --abbrev-ref HEAD

# For each local branch
foreach ($branch in $localBranches)
{
    # Exclude the currently checked-out branch
    if ($branch -ne $currentBranch)
    {
        # Check if the branch exists on origin
        if ($remoteBranches -contains "origin/$branch")
        {
            # Use git rev-list to list all commits that are in the local branch but not in the remote branch
            $unpushedCommits = git rev-list origin/$branch..$branch

            # If there are any such commits, add the branch to the list of branches with unpushed changes
            if ($unpushedCommits)
            {
                $branchesWithUnpushedChanges += $branch
            }
        }
        else
        {
            Write-Host -ForegroundColor $colorNoUpstream "Branch '$branch' does not exist on origin"
            $branchesWithoutUpstream += $branch
        }
    }
}

function Confirm-Delete {
    param(
        [string]$message,
        [array]$branches,
        [switch]$force
    )
    if ($branches.Count -gt 0)
    {
        Write-Host -ForegroundColor $colorHeader $message
        foreach ($branch in $branches)
        {
            Write-Host $branch
        }

        if (!$quiet)
        {
            Write-Host -ForegroundColor $colorConfirmation "Are you sure you want to delete these branches? (yes/no)"
            $confirmation = Read-Host 
            if ($confirmation -eq "yes")
            {
                if ($force)
                {
                    Write-Host -ForegroundColor $colorForceConfirmation "Force delete was requested. Are you sure? This cannot be undone. (yes/no)"
                    $confirmation = Read-Host 
                    if ($confirmation -eq "yes")
                    {
                        foreach ($branch in $branches)
                        {
                            git branch -D $branch
                        }
                    }
                }
                else
                {
                    foreach ($branch in $branches)
                    {
                        git branch -d $branch
                    }
                }
            }
        }
        else
        {
            if ($force)
            {
                foreach ($branch in $branches)
                {
                    git branch -D $branch
                }
            }
            else
            {
                foreach ($branch in $branches)
                {
                    git branch -d $branch
                }
            }
        }
    }
}

# Handle deleteNoUpstream switch
if ($deleteNoUpstream)
{
    Confirm-Delete -message "Branches without upstream:" -branches $branchesWithoutUpstream -force:$force
}

# Handle deleteNoUnpushed switch
if ($deleteNoUnpushed)
{
    $branchesWithoutUnpushedChanges = $localBranches | Where-Object { $branchesWithUnpushedChanges -notcontains $_ -and $_ -ne $currentBranch }
    Confirm-Delete -message "Branches without unpushed changes:" -branches $branchesWithoutUnpushedChanges -force:$force
}

# Print out all branches with unpushed changes
if ($branchesWithUnpushedChanges.Count -gt 0)
{
    Write-Host -ForegroundColor $colorUnpushedChanges "Branches with unpushed changes:"
    foreach ($branch in $branchesWithUnpushedChanges)
    {
        Write-Host $branch
    }
}
else
{
    Write-Host -ForegroundColor $colorUnpushedChanges "No branches with unpushed changes"
}
