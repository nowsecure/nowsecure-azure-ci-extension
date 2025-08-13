# NowSecure Azure CI Extension

NowSecure provides purpose-built, fully automated mobile application security testing (static and dynamic) for your development pipeline.
By testing your mobile application binary post-build from Azure, NowSecure ensures comprehensive coverage of newly developed code, third party components, and system dependencies.

NowSecure quickly identifies and details real issues, provides remediation recommendations, and integrates with ticketing systems such as Gitlab and Jira.

This integration requires a NowSecure platform license. See <https://www.nowsecure.com> for more information.

## Job Parameters

To add this component to your CI/CD pipeline, the following should be done:

- Get a token from your NowSecure platform instance. More information on this can be found in the [NowSecure Support Portal](https://support.nowsecure.com/hc/en-us/articles/7499657262093-Creating-a-NowSecure-Platform-API-Bearer-Token)
- Identify the ID of the group in NowSecure Platform that you want your assessment to be included in. More information on this can be found in the
  [NowSecure Support Portal](https://support.nowsecure.com/hc/en-us/articles/6290991166605-Getting-Started-with-Groups#h_01G396F6CTEZ4P6G5Z1FDGJ12K).
  (Note: Authentication is required to access this page)
- Add a CI/CD variable to your project named, `NS_TOKEN` and add the token created above. As this is a credential, be sure to check the box labeled `Keep this value secret`.
- Add the following include entry to your project's CI/CD configuration and set your input values

  ```yaml
  - task: nowsecure-azure-ci-extension@<tag>
    inputs:
      group: "<group-ref>"
      token: $(NS_TOKEN)
      binary_file: "<path-to-binary>"
  ```

  - `<tag>` is the release tag you want to use

  - `<group-ref>` is uuid of the group that will be used to trigger assessments.
    Information on how to get the group reference can be found in the [NowSecure Support Portal](https://support.nowsecure.com).
  - `<path-to-binary>` is the filepath for the ipa / apk that is to be uploaded to run an assessments against. Ideally this will be an artifact of some previous build step in a pipeline.
  - `$NS_TOKEN` is the token used to communicate with the NowSecure API. This token should be an
    [Azure Devops Secret Variable](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/set-secret-variables?view=azure-devops&tabs=yaml%2Cbash#secret-variable-in-the-ui).
    Information on how to create a token can be found in the [NowSecure Support Portal](http://support.nowsecure.com/).

### Installation

Find this extension in the [Azure Devops Marketplace](https://marketplace.visualstudio.com/items?itemName=Nowsecure-com.nowsecure-azure-ci-extension)

Then install it following [Microsoft's instructions](https://learn.microsoft.com/en-us/azure/devops/marketplace/install-extension?view=azure-devops) on installing Azure Devops Marketplace extensions.

_NOTE:_ Currently, compatibility is limited to either Windows / Linux running an X64 architecture, or MacOS on ARM. In order for the extension to work, please make sure you have an appropriate `vmImage`.

### Sample Configurations

#### Sample Build Pipeline for Android

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

Note: The `nowsecure-azure-extension` task is the main task for security analysis and other tasks above are used to generate Android apk file.

#### Publish/View Artifacts

You can add task to publish artifacts (API results) from the Nowsecure Azure Extension task as shown:

```yaml
- task: PublishBuildArtifacts@1
  inputs:
    pathToPublish: "$(build.artifactStagingDirectory)/NowSecureArtifacts"
    artifactName: "nowsecure_results"
    artifactType: "container"
```

##### Debugging

To enable debug-level logging for the NowSecure Azure Extension, add the `log_level` input with the `'debug'` option as shown below:

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
