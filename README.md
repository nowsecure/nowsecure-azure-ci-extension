# NowSecure Azure CI Extension

NowSecure provides purpose-built, fully automated mobile application security testing (static and dynamic) for your development pipeline.
By testing your mobile application binary post-build from Azure, NowSecure ensures comprehensive coverage of newly developed code, third party components, and system dependencies.

NowSecure quickly identifies and details real issues, provides remediation recommendations, and integrates with ticketing systems such as Azure DevOps and Jira.

This integration requires a NowSecure platform license. See <https://www.nowsecure.com> for more information.

## Getting Started

### Installation

First, find this extension in the [Azure DevOps Marketplace](https://marketplace.visualstudio.com/items?itemName=Nowsecure-com.nowsecure-azure-ci-extension)

Then install it following [Microsoft's instructions](https://learn.microsoft.com/en-us/azure/devops/marketplace/install-extension?view=azure-devops) on installing Azure DevOps Marketplace extensions.

**NOTE:** Currently, compatibility is limited to either Windows / Linux running an X64 architecture, or MacOS on ARM. In order for the extension to work, please make sure you are running on an appropriate `vmImage`.

### Configuration 

To add this component to your CI/CD pipeline, the following should be done:

- Get a token from your NowSecure platform instance. More information on this can be found in the [NowSecure Support Portal](https://support.nowsecure.com/hc/en-us/articles/7499657262093-Creating-a-NowSecure-Platform-API-Bearer-Token).
- Identify the ID of the group in NowSecure Platform that you want your assessment to be included in. More information on this can be found in the
  [NowSecure Support Portal](https://support.nowsecure.com/hc/en-us/articles/38057956447757-Retrieve-Reference-and-ID-Numbers-for-API-Use-Task-ID-Group-App-and-Assessment-Ref).
- Add an [Azure DevOps Secret Variable](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/set-secret-variables?view=azure-devops&tabs=yaml%2Cbash#secret-variable-in-the-ui) to your project named, `NS_TOKEN`. Set this to the value of the token created above. 
- Add the following include entry to your project's CI/CD configuration and set your input values:

  ```yaml
  - task: nowsecure-azure-ci-extension@<tag>
    inputs:
      # Required Inputs    
      group: "<group-ref>"
      token: $(NS_TOKEN)
      binary_file: "<path-to-binary>"
      # Recommended Optional Inputs
      minimum_score: 70
      analysis_type: static
      artifact_dir: '$(build.artifactStagingDirectory)/NowSecureArtifacts'
  ```

  Where:

    - `task` is specifying the task to run.  In the example, `<tag>` is the release tag of the `nowsecure-azure-ci-extention` that you want to use.  At time, NowSecure recommends setting this to `0.1`
    - `group` is the NowSecure platform group to use. `<group-ref>` is the group ID acquired above.
    - `token` is the token used to communicate with the NowSecure API. This token should be the Azure DevOps Secret Variable set above.
    - `binary_file` is the binary that is to be uploaded to NowSecure.  In the example, `<path-to-binary>` should be set to the filepath for the IPA/apk that is to be uploaded. Ideally this will be an artifact of a previous build step in a pipeline.
    - `minimum_score` is the score that your assessment needs to exceed.  If it does not, your pipeline will fail.  This is valuable to ensure that your application's security scores do not decline as new versions are released.
    - `analysis_type` is the type of assessment that you want to run.  By default, NowSecure recommends running a static assessment on pull requests and a full assessments on a tagged release.
    - `artifact_dir` is the directory where assessment results should be stored.  In the example above, artifacts are stored in a subdirectory of the default `$(build.artifactStagingDirectory)` named `NowSecureArtifacts`. 

## Job Parameters

The NowSecure Azure CI Extension supports the following parameters:

| Name | Mandatory | Type | Description | Default Value|
|------|-----------|------|-------------|---------------|
| `group`| true     | string |Defines the group reference that is used to trigger assessments. Information on how to get the group reference can be found in the[NowSecure Support Portal](https://support.nowsecure.com/hc/en-us/articles/38057956447757-Retrieve-Reference-and-ID-Numbers-for-API-Use-Task-ID-Group-App-and-Assessment-Ref) |  | 
| `token` | true | string | Defines the token used to communicate with the NowSecure API. This token should be stored as a secret. Information on how to create a token can be found in the [NowSecure Support Portal](https://support.nowsecure.com/hc/en-us/articles/7499657262093-Creating-a-NowSecure-Platform-API-Bearer-Token). | |
| `binary_file` | true | string | Defines the path to the mobile application binary to be processed by NowSecure | |
| `ui_host` | false | string | Defines the NowSecure base UI to use. This will not change unless you are leveraging a single tenant. | https://app.nowsecure.com | 
| `api_host` | false | string | Defines the NowSecure base API to use. This will not change unless you are leveraging a single tenant. | https://lab-api.nowsecure.com | 
| `log_level` | false | string | Defines the log level set for the NowSecure analysis task. | `info` | 
| `analysis_type` | false | string |Defines the type of analyst that you want to run.  Options are `static` for a static only assessment or `full` for both a static and dynamic assessment. | ??? |
| `artifacts_dir`| true | string | Defines the directory for nowsecure artifacts to be output to. In the case of the default assessment results would be `./artifacts/nowsecure/assessment.json` | | 
| `polling_duration_minutes` | false | number | Defines the length of time (in minutes) to poll for job completion. | If `analysis_type` is `static`, 30.  If `full`, 60 |
| `minimum_score` | false | number | Defines the score under which an assessment will fail | -1 |

## Sample Configurations

### Sample Build Pipeline for Android

The following is a sample pipeline that builds an Android application and runs a static assessment on it

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
  - task: nowsecure-azure-ci-extension@0.1
    inputs:
      # Required inputs
      group: "0000-00000-0000-0000"
      token: $(NS_TOKEN)
      binary_file: "$(build.artifactStagingDirectory)/binary.apk"
      # Common optional parameters
      minimum_score: 70
      analysis_type: static
      polling_duration_minutes: 30
      artifact_dir: '$(build.artifactStagingDirectory)/NowSecureArtifacts'
```

**Note**: The `nowsecure-azure-extension` task is the main task for security analysis and other tasks above are used to generate Android apk file.

### Publish/View Artifacts

You can add task to publish artifacts (API results) from the NowSecure Azure Extension task as shown:

```yaml
- task: PublishBuildArtifacts@1
  inputs:
    pathToPublish: "$(build.artifactStagingDirectory)/NowSecureArtifacts"
    artifactName: "nowsecure_results"
    artifactType: "container"
```

### Debugging

To enable debug-level logging for troubleshooting of the NowSecure Azure Extension, add the `log_level` input with the `'debug'` option as shown below:

```yaml
- task: nowsecure-azure-extension@1
  inputs:
    # Required inputs
    group: "0000-00000-0000-0000"
    token: $(NS_TOKEN)
    binary_file: "$(build.artifactStagingDirectory)/binary.apk"
    # Enable Debug Level Logging
    log_level: "debug"
```
