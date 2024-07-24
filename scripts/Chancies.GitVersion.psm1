function Get-GitVersionWithoutPrefix {
  param(
    [Parameter(Mandatory = "true")]
    [string]
    $VersionTag,

    [Parameter(Mandatory = "true")]
    [string]
    $Prefix
  )

  if ([string]::IsNullOrWhiteSpace($VersionTag)) {
    throw "VersionTag must have a non empty value"
  }

  if ([string]::IsNullOrWhiteSpace($Prefix)) {
    return $VersionTag
  }

  $VersionTag.Substring($Prefix.Length)
}

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

  # The git command's sort function doesn't work with pre-release tags, so we apply a
  # max search using the .NET semver comparator.
  $max = $versions[0]
  foreach ($v in $versions) {
    $versionWithoutPrefix = Get-GitVersionWithoutPrefix -VersionTag $v -Prefix $Prefix
    $maxWithoutPrefix = Get-GitVersionWithoutPrefix -VersionTag $max -Prefix $Prefix

    try {
      if ([System.Management.Automation.SemanticVersion]::Compare($versionWithoutPrefix, $maxWithoutPrefix) -gt 0) {
        $max = $v
      }
    } catch [System.Management.Automation.MethodException] {
      Write-Verbose "Could not compare version $v. $_"
    }
  }

  $max
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

  $currentTag = Get-GitVersionWithoutPrefix -VersionTag $currentTag -Prefix $Prefix
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
    "$Prefix$major.$minor.$patch-$PreLabel.$build"
  } else {
    "$Prefix$major.$minor.$patch"
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

Export-ModuleMember -Function Get-GitCurrentVersionTag,Get-GitNextVersionTag,Set-GitVersionTag