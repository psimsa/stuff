param(
    [switch]$confirm = $true
)

function Get-DefaultBranch {
    try {
        $branch = & git remote show origin | Select-String 'HEAD branch' | ForEach-Object { $_ -replace '.*: ', '' }
        return $branch.Trim()
    }
    catch {
        Write-Error "Error: Failed to get default branch. $_"
        exit 1
    }
}

try {
    # Ensure we have the latest from the remote.
    & git fetch
}
catch {
    Write-Error "Error: Failed to fetch from remote. $_"
    exit 1
}

try {
    # Stash any uncommitted changes.
    & git stash
}
catch {
    Write-Error "Error: Failed to stash changes. $_"
    exit 1
}

# Determine the default branch.
$defaultBranch = Get-DefaultBranch

try {
    # Check out the default branch if not already on it.
    $currentBranch = & git rev-parse --abbrev-ref HEAD
    if ($currentBranch -ne $defaultBranch) {
        & git checkout $defaultBranch
    }
}
catch {
    Write-Error "Error: Failed to checkout $defaultBranch. $_"
    exit 1
}

try {
    # Pull the latest changes from the remote for the default branch.
    & git pull
}
catch {
    Write-Error "Error: Failed to pull from remote. $_"
    exit 1
}

# Get all local branches.
$branches = & git branch
$branches = $branches -replace '\*', '' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne $defaultBranch }

$branchesToDelete = @()
foreach ($branch in $branches) {
    try {
        # Check if the branch has an upstream.
        $upstream = & git rev-parse --abbrev-ref $branch@ { upstream } 2>$null
        if ($upstream) {
            # Check if there are changes that have not been pushed.
            $diff = & git log origin/$branch..$branch --oneline 2>$null
            if (!$diff) {
                $branchesToDelete += $branch
            }
        }
        else {
            $branchesToDelete += $branch
        }
    }
    catch {
        Write-Error "Error: Failed to process branch $branch. $_"
        exit 1
    }
}

if ($branchesToDelete) {
    if ($confirm) {
        $message = "This will force-delete the following branches:`n$($branchesToDelete -join '`n')`nDo you want to continue? (y/n)"
        $response = Read-Host -Prompt $message
        if ($response -eq 'y') {
            foreach ($branch in $branchesToDelete) {
                try {
                    Write-Host "Deleting $branch"
                    & git branch -D $branch
                }
                catch {
                    Write-Error "Error: Failed to delete branch $branch. $_"
                    exit 1
                }
            }
        }
    }
    else {
        foreach ($branch in $branchesToDelete) {
            try {
                Write-Host "Deleting $branch"
                & git branch -D $branch
            }
            catch {
                Write-Error "Error: Failed to delete branch $branch. $_"
                exit 1
            }
        }
    }
}
