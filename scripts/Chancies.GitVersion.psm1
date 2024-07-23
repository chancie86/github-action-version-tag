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
    [ValidateSet("Major", "Minor", "Patch")]
    [string]
    $Increment,

    [Parameter()]
    [string]
    $Prefix = "v",

    [Parameter()]
    [string]
    $PreLabel = "pre",

    [Parameter()]
    [switch]
    $IsPrerelease
  )

  $incrementInternal = $Increment

  $currentTag = Get-GitCurrentVersionTag -Prefix $Prefix

  Write-Verbose "Current tag: $currentTag"

  $currentTag = $currentTag.Substring($Prefix.Length, $currentTag.Length - $Prefix.Length)
  $currentTag = $currentTag -replace "[-a-zA-Z]*",""

  $currentVersion = [Version]$currentTag

  $major = $currentVersion.Major
  $minor = $currentVersion.Minor
  $patch = $currentVersion.Build
  $build = $currentVersion.Revision

  Write-Verbose "Current version: $major.$minor.$patch.$build"  

  if ($IsPrerelease) {
    if ([string]::IsNullOrWhiteSpace($PreLabel)) {
      throw "PreLabel must have a non empty value"
    }

    if ($build -gt -1) {
      Write-Verbose "Existing pre-release found in next version. Incrementing build number instead."
      $incrementInternal = "Build"
    }
  }

  switch ($incrementInternal)
  {
    "Major" {
      $major = $major + 1
      $minor = 0
      $patch = 0
      $build = 0
    }
    "Minor" {
      $minor = $minor + 1
      $patch = 0
      $build = 0
    }
    "Patch" {
      $patch = $patch + 1
      $build = 0
    }
    "Build" {
      $build = $build + 1
    }
  }

  if ($IsPrerelease) {
    "$major.$minor.$patch-$PreLabel.$build"
  } else {
    "$major.$minor.$patch"
  }
}

function Set-GitVersionTag {
  param(
    [Parameter(Mandatory = $true)]
    [string]
    $VersionTag,

    [Parameter(Mandatory = $true)]
    [string]
    $GitOriginRefName,

    [Parameter()]
    [string]
    $UserName = "GitHub",

    [Parameter()]
    [string]
    $UserEmail = "github@contoso.org"
  )

  if ([string]::IsNullOrWhiteSpace($VersionTag)) {
    throw "Version must have a value"
  }

  git config user.email $UserEmail
  git config user.name $UserName
  git tag -a $VersionTag -m "[Tagged $VersionTag]"
  git push --atomic origin $GitOriginRef $VersionTag
}