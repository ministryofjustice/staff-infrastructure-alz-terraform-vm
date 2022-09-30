[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [String]
    $Path,
    [string]
    $suffix
)

Write-Host "
path: $path
suffix: $suffix"

$modules = Get-Module -list

if ($modules.Name -notcontains 'pester') {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

if ($suffix) {
    Write-Host "Using Pester Container to pass data to tests"
    $container = New-PesterContainer -Path "$path/tests/*" -Data @{suffix = $suffix }
    Invoke-Pester -CI -Container $container
}
else {
    Invoke-Pester -CI -Path "$path/tests/*"
}