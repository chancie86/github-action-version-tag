# github-action-version-tag

This action uses git tags to read and, optionally, push incremented version tag. Versions should be formatted using [semver](https://semver.org/). The version number is also available via the action's outputs allowing you to use it in downstream steps in your workflow.

## Summary of Features
- Allows specifying a prefix to the version value. This is helpful in supporting multiple components that reside in the same repository.
- Choosing which version value to increment: Major, Minor or Patch
- Use of a pre-release tag, e.g. 1.0.0-pre.0. The tag is customisable and the builder number increments automatically.

## Usage

**IMPORTANT**: You will need to seed the first version tag manually. You just need to push the tag in your desired format, e.g. `v0.0.1`

### Inputs
|Name|Default|Description|
|-|-|-|
|`versionPrefix`|`v`|A git tag prefix.|
|`versionPrefix`|Patch|The version value to increment. Possible values are Major, Minor, Patch.|
|`isPrerelease`|`false`|If 'true', appends '-pre' to the patch number and includes an auto incremented build number, e.g. 1.0.1-pre.0.|
|`push`|`false`|A git tag prefix.|
|`preLabel`|pre|The pre-release label to use, e.g. 'pre' would result in '1.0.0-pre.0'.|
|`gitUserName`|GitHub|Git username.|
|`gitUserEmail`|github@contoso.org|Git email.|

### Outputs

|Name|Description|
|-|-|
|`currentVersion`|The current git tag version|
|`nextVersion`|The next git tag version|

## Examples

### Increment patch version
- Increments the patch version. For example, 1.0.0 would be updated to 1.0.1.
- Pushes the new tag to git
```
on: [workflow_dispatch]
jobs:
  build:
    steps:
    - uses: actions/checkout@v4
    - name: Tag
      id: tag
      uses: chancie86/github-action-version-tag@v0.0.1-pre.25
      with:
        versionPrefix: ""
        incrementType: Patch
        push: true
```

### Increment major version
- Increments the major version, which uses a prefix "v". For example, v1.0.0 would be updated to v2.0.0.
- Pushes the new tag to git
```
on: [workflow_dispatch]
jobs:
  build:
    steps:
    - uses: actions/checkout@v4
    - name: Tag
      id: tag
      uses: chancie86/github-action-version-tag@v0.0.1-pre.25
      with:
        versionPrefix: "v"
        incrementType: Major
        push: true
```

### Increment a pre-release

- Increments the build version of the pre-release. If the latest version is not a pre-release, a new patch version is created.
- Pushes the new tag to git

For example:
|Branch|Current Version|New Version|
|-|-|-|
|`main`|1.0.0|1.0.1-pre.0|
|`feature`|1.0.0|1.0.1-pre.0|
|`feature`|1.0.1-pre.0|1.0.1-pre.1|
```
on: [workflow_dispatch]
jobs:
  build:
    steps:
    - uses: actions/checkout@v4
    - name: Tag
      id: tag
      uses: chancie86/github-action-version-tag@v0.0.1-pre.25
      with:
        versionPrefix: ""
        incrementType: Patch
        isPrerelease: ${{ github.ref != 'refs/heads/main' }}
        push: true
```

### Using build output
- Increments the patch version
- Echos the `currentVersion` and `nextVersion` to standard output in the next step
- Does not push the tag to git
```
on: [workflow_dispatch]
jobs:
  build:
    steps:
    - uses: actions/checkout@v4
    - name: Tag
      id: tag
      uses: chancie86/github-action-version-tag@v0.0.1-pre.25
      with:
        versionPrefix: "v"
        incrementType: Major
        push: false
    - run: |
        echo currentVersion "${{ steps.tag.outputs.currentVersion }}"
        echo nextVersion "${{ steps.tag.outputs.nextVersion }}"
```
