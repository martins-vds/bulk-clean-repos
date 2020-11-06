[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [securestring]
    $Token,
    [Parameter(Mandatory=$true)]
    [ValidateScript({
        if ( -Not ($_ | Test-Path) ) {
            throw "Path '$_' does not exist"
        }
        if (-Not ($_ | Test-Path -PathType Leaf) ) {
            throw "The Path argument must be a file. Folder paths are not allowed."
        }
        return $true
    })]
    [System.IO.FileInfo]
    $ReposFile,
    [Switch]$Force
)

function Invoke-DeleteRepo  {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^[^/]+/[^$]+$")]
        [string]
        $Repo,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [securestring]
        $PAT
    )
    try {
        $cred = ConvertFrom-SecureString -SecureString $PAT -AsPlainText
        Invoke-WebRequest -Uri "https://api.github.com/repos/$Repo" -Method "DELETE" -Headers @{ "Authorization" = "token $cred"} | Out-Null
        Write-Host "Deleted repository '$Repo'." -ForegroundColor Red
    }
    catch {
        Write-Error "Failed to delete repository '$Repo'. Reason:\n$($_.ErrorDetails)"
    }   
}

if ($Force -and -not $Confirm){
    $ConfirmPreference = 'None'
}

Get-Content $ReposFile | Where-Object{ $_ -match "^[^/]+/[^$]+$" } | ForEach-Object { 
    if ($PSCmdlet.ShouldProcess($_, "delete")) {
        Invoke-DeleteRepo -Repo $_ -PAT $Token
    }else{
        Write-Warning "Skipped deletion of repository '$_'"
    }
}

