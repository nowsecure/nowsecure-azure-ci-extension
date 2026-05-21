# NowSecure Azure CI Extension

NowSecure provides purpose-built, fully automated mobile application security testing (static and dynamic) for your development pipeline.
By testing your mobile application binary post-build from Azure, NowSecure ensures comprehensive coverage of newly developed code, third party components, and system dependencies.

NowSecure quickly identifies and details real issues, provides remediation recommendations, and integrates with ticketing systems such as Azure DevOps and Jira.

This integration requires a NowSecure platform license. See <https://www.nowsecure.com> for more information.

## Prerequisites

Before installing this extension, ensure you have the following:

- **NowSecure platform license** — contact [NowSecure](https://www.nowsecure.com) if you don't have one
- **Supported binary types** — Android `.apk` / `.aab` and iOS `.ipa` files are supported
- **Supported runner (vmImage)** — the task runs on Windows/Linux (x64) or macOS (ARM). Ensure your pipeline's `vmImage` matches one of these architectures.

> [!NOTE]
> [Hosted macOS ARM64 images have been paused by Microsoft.][arm64-paused]
> If your pipelines are using a `macOS` `vmImage`, please ensure one of the following applies:
>
> - you are using self-hosted runners
> - you are grandfathered-in to hosted ARM64 runners
> - you are running the `nowsecure-azure-ci-extension` task in a separate job with a supported `vmImage`
>   (see the [iOS example pipeline](#ios--static-scan-multi-job) below)

[arm64-paused]: https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/hosted?view=azure-devops&tabs=macos-images%2Cyaml#macos-15-arm64-image-limited-public-preview-paused

## Getting Started

### 1. Install the Extension

Find and install the extension from the [Azure DevOps Marketplace][marketplace],
following [Microsoft's guide on installing Marketplace extensions][ms-install-guide].

[marketplace]: https://marketplace.visualstudio.com/items?itemName=Nowsecure-com.nowsecure-azure-ci-extension
[ms-install-guide]: https://learn.microsoft.com/en-us/azure/devops/marketplace/install-extension?view=azure-devops

### 2. Create a NowSecure API Token

Generate an API token from your NowSecure platform instance. See the
[NowSecure Support Portal][create-token] for instructions.

Once you have the token, store it as an [Azure DevOps secret variable][secret-var].
In our examples, we'll call it `NS_TOKEN`.

[create-token]: https://support.nowsecure.com/hc/en-us/articles/7499657262093-Creating-a-NowSecure-Platform-API-Bearer-Token
[secret-var]: https://learn.microsoft.com/en-us/azure/devops/pipelines/process/set-secret-variables?view=azure-devops&tabs=yaml%2Cbash#secret-variable-in-the-ui

### 3. Get Your NowSecure Group ID

Identify the ID of the NowSecure platform group you want assessments assigned to.
See the [NowSecure Support Portal][retrieve-ids] for instructions.

[retrieve-ids]: https://support.nowsecure.com/hc/en-us/articles/38057956447757-Retrieve-Reference-and-ID-Numbers-for-API-Use-Task-ID-Group-App-and-Assessment-Ref

### 4. Add the Task to Your Pipeline

Add the following to your pipeline YAML after your build step:

```yaml
- task: nowsecure-azure-ci-extension@0
  inputs:
    # Required
    group: "<your-group-id>"
    token: $(NS_TOKEN)
    binary_file: "<path-to-your-binary>"
    artifact_dir: "$(build.artifactStagingDirectory)/NowSecureArtifacts"
    # Recommended
    minimum_score: 70
    analysis_type: static
```

## Input Reference

| Name | Required | Type | Default | Description |
| ---- | -------- | ---- | ------- | ----------- |
| `group` | Yes | string | | The NowSecure platform group to assign assessments to. See the [NowSecure Support Portal][retrieve-ids] for how to retrieve this value. |
| `token` | Yes | string | | The API token used to authenticate with NowSecure. Store this as an Azure DevOps secret variable. See the [NowSecure Support Portal][create-token] for how to create one. |
| `binary_file` | Yes | string | | Path to the mobile app binary (`.apk` or `.ipa`) to upload to NowSecure. This is typically an artifact produced by a prior build step. |
| `artifact_dir` | Yes | string | | Directory where artifacts will be written, e.g. `$(build.artifactStagingDirectory)/NowSecureArtifacts`. Results are at `<artifact_dir>/nowsecure/assessment.json`. |
| `analysis_type` | No | string | `static` | Assessment type: `static` for static-only, or `full` for static and dynamic. Recommend `static` for PRs and `full` for tagged releases. |
| `minimum_score` | No | number | `-1` | The minimum security score required to pass. If the assessment score falls below this threshold, the pipeline will fail. Set to `-1` to disable score gating. |
| `polling_duration_minutes` | No | number | `30` (static), `60` (full) | How long (in minutes) to poll for assessment completion before timing out. |
| `log_level` | No | string | `info` | Log verbosity for the task. Valid values: `info`, `debug`. |
| `ui_host` | No | string | `https://app.nowsecure.com` | NowSecure platform UI base URL. Only change this if you are on a single-tenant deployment. |
| `api_host` | No | string | `https://api.nowsecure.com` | NowSecure API base URL. Only change this if you are on a single-tenant deployment. |

## Example Pipelines

### Android — Static Scan

Builds an Android app with Gradle and runs a NowSecure static scan on the resulting `.apk`:

```yaml
pool:
  vmImage: "ubuntu-latest"

steps:
  - task: Gradle@4
    inputs:
      cwd: ""
      wrapperScript: "gradlew"
      gradleOpts: "-Xmx3072m"
      publishJUnitResults: false
      testResultsFiles: "**/TEST-*.xml"
      tasks: "assembleDebug"

  - task: CopyFiles@2
    inputs:
      contents: "**/*.apk"
      targetFolder: "$(build.artifactStagingDirectory)"

  - task: PublishBuildArtifacts@1
    inputs:
      pathToPublish: "$(build.artifactStagingDirectory)"
      artifactName: "apk"
      artifactType: "container"

  - task: nowsecure-azure-ci-extension@0
    inputs:
      # Required
      group: "0000-00000-0000-0000" # replace with your group id
      token: $(NS_TOKEN)
      binary_file: "$(build.artifactStagingDirectory)/binary.apk"
      artifact_dir: "$(build.artifactStagingDirectory)/NowSecureArtifacts"
      # Recommended
      minimum_score: 70
      analysis_type: static
      polling_duration_minutes: 30

  - task: PublishBuildArtifacts@1
    inputs:
      pathToPublish: "$(build.artifactStagingDirectory)/NowSecureArtifacts"
      artifactName: "nowsecure_results"
      artifactType: "container"
```

### iOS — Static Scan (Multi-Job)

iOS apps must be built on a macOS runner. The `nowsecure-azure-ci-extension` task supports Linux (x64),
Windows (x64), and macOS (ARM64) runners. If your pipeline is using macOS (AMD64) runners, you must split
the pipeline into two jobs: first build on macOS, then pass the `.ipa` artifact to a Linux runner for the
NowSecure scan as per the example below:

```yaml
jobs:
  - job: build_app
    pool:
      vmImage: macOS-latest
    steps:
      - task: Xcode@5
        inputs:
          actions: "build"
          scheme: "ExampleApp"
          sdk: "iphoneos"
          configuration: "Release"
          xcodeVersion: "default"
          packageApp: true
        displayName: "Build iOS app"

      - task: CopyFiles@2
        inputs:
          contents: "$(Build.SourcesDirectory)/$(APP_NAME)"
          targetFolder: "$(Build.ArtifactStagingDirectory)"
          flattenFolders: true
        displayName: "Stage IPA"

      - task: PublishPipelineArtifact@1
        inputs:
          targetPath: "$(Build.ArtifactStagingDirectory)"
          artifact: "ipa_artifact"
          publishLocation: "pipeline"
        displayName: "Publish IPA artifact"

  - job: nowsecure_scan
    dependsOn: build_app
    condition: succeeded('build_app')
    pool:
      vmImage: ubuntu-latest
    steps:
      - task: DownloadPipelineArtifact@2
        inputs:
          artifact: "ipa_artifact"
          path: "$(Pipeline.Workspace)/ipa_artifact"
        displayName: "Download IPA artifact"

      - task: nowsecure-azure-ci-extension@0
        inputs:
          # Required
          group: $(NS_GROUP)
          token: $(NS_TOKEN)
          binary_file: "$(Pipeline.Workspace)/ipa_artifact/$(APP_NAME)"
          artifact_dir: "$(Build.ArtifactStagingDirectory)/NowSecureArtifacts"
          # Recommended
          minimum_score: 70
          analysis_type: static
          polling_duration_minutes: 30
        displayName: "NowSecure security scan"

      - task: PublishBuildArtifacts@1
        inputs:
          pathToPublish: "$(Build.ArtifactStagingDirectory)/NowSecureArtifacts"
          artifactName: "nowsecure_results"
          artifactType: "container"
        displayName: "Publish scan results"
```

## Debugging

To enable debug-level logging, add the `log_level` input to your task:

```yaml
- task: nowsecure-azure-ci-extension@0
  inputs:
    group: "0000-00000-0000-0000" # replace with your group id
    token: $(NS_TOKEN)
    binary_file: "$(build.artifactStagingDirectory)/binary.apk"
    artifact_dir: "$(build.artifactStagingDirectory)/NowSecureArtifacts"
    log_level: "debug"
```
