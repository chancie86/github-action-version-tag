function Get-GitCurrentVersion {
  param(
    [Parameter()]
    [string]
    $Prefix = "v"
  )
  Invoke-Expression "git fetch --tags origin"

  $versions = @(Invoke-Expression "git tag --list '$Prefix*' --sort '-version:refname'")

  if ($versions.Length -eq 0) {
    throw "No tags found"
  }

  $versions[0]
}

function Get-GitNextVersion {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Major", "Minor", "Patch", "Build")]
    [string]
    $Increment,

    [Parameter()]
    [string]
    $Prefix = "v",

    [Parameter()]
    [switch]
    $IsPrerelease
  )

  $currentTag = Get-GitCurrentVersion -Prefix $Prefix
  $currentVersion = [Version]$currentTag.Substring($Prefix.Length, $currentTag.Length - $Prefix.Length)

  if ($IsPrerelease) {
    $pre = "-pre"

    if ($Increment -eq "Build") {
      $build = ".$($currentVersion.Revision + 1)"
    } else {
      $build = ".0"
    }
  } else {
    if ($Increment -eq "Build") {
      throw "Build number can only be incremented on Prerelease versions"
    }

    $pre = ""
    $build = ""
  }

  $preSuffix = "$pre$build"

  Write-Verbose "Current version: $currentVersion"

  switch ($Increment)
  {
    "Major" {
      $newVersion = "$($currentVersion.Major + 1).0.0$preSuffix"
    }
    "Minor" {
      $newVersion = "$($currentVersion.Major).$($currentVersion.Minor + 1).0$preSuffix"
    }
    "Patch" {
      $newVersion = "$($currentVersion.Major).$($currentVersion.Minor).$($currentVersion.Build + 1)$preSuffix"
    }
    "Build" {
      $newVersion = "$($currentVersion.Major).$($currentVersion.Minor).$($currentVersion.Build)$preSuffix"
    }
  }

  $newVersion
}

function Set-GitVersion {
  param(
    [Parameter()]
    [string]
    $Prefix = "v",

    [Parameter(Mandatory = $true)]
    [string]
    $Version,

    [Parameter(Mandatory = $true)]
    [string]
    $GitOriginRefName
  )

  if ([string]::IsNullOrWhiteSpace($Version)) {
    throw "Version must have a value"
  }

  $versionTag = "$($Prefix)$($Version)"
  $versionTag
  # git config user.email "github@salveapp.co.uk"
  # git config user.name "Github"
  # git tag -a $versionTag -m "[Tagged $versionTag]"
  # git push --atomic origin $GitOriginRef $versionTag
}