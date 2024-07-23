function Get-GitCurrentVersionTag {
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

function Get-GitNextVersionTag {
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

  $currentTag = Get-GitCurrentVersionTag -Prefix $Prefix
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

  "$($Prefix)$($newVersion)"
}

function Set-GitVersionTag {
  param(
    [Parameter(Mandatory = $true)]
    [string]
    $VersionTag,

    [Parameter(Mandatory = $true)]
    [string]
    $GitOriginRefName
  )

  if ([string]::IsNullOrWhiteSpace($VersionTag)) {
    throw "Version must have a value"
  }

  git config user.email "github@salveapp.co.uk"
  git config user.name "Github"
  git tag -a $VersionTag -m "[Tagged $VersionTag]"
  git push --atomic origin $GitOriginRef $VersionTag
}