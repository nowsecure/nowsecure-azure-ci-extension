# Development

## Dependencies

Required for development:
    - tfx-cli
    - nodejs_20
    - typescript

Optional but helpful:
    - jq
    - biome
    - markdownlint-cli
    - typos

Note that if you use Nix, then there is a flake included which produces a devshell containing all the tools above.
If you use `direnv` and and `nvm`, that similarly will automatically switch to the node version specified in `.nvmrc`.

## Making Changes

The core functionality is handled by the `nowsecure-ci` golang binary. That code can be found in [its own repository](https://github.com/nowsecure/nowsecure-ci)
The logic in `nowsecure/index.ts` is merely a wrapper around that binary file.

To adjust any of the inputs / default values edit the `nowsecure/task.json`

To adjust any of the wrapper logic, edit `nowsecure/index.ts`

## Building

To build the node project, change into the `nowsecure` directory and run

```shell
npm run build
```

To package for testing in a private azure environment, run:

``` shell
tfx extension create \
    --manifest-globs vss-extension.json \
    --overrides-file dev-overrides.json
```

This will create a `.vsix` file which can be uploaded to the [QA storefront](https://marketplace.visualstudio.com/manage/publishers/qa-nowsecure).
You will have to have access to the publisher account to perform this action

**IMPORTANT:** The `version` string in this file _must_ match the `version` object in `nowsecure/task.json` or you'll get runtime errors

## Publishing

Currently there are three tiers of creating / publishing artifacts:

- Every PR event will trigger a build and packing of this repository.
The assembled `.vsix` file will be uploaded as a pipeline artifact afterwards called `dev-nowsecure-azure-ci-extension`
  - This assembled extension can be manually uploaded to the [Marketplace Management Portal](https://aka.ms/vsmarketplace-manage)
  - Refer to the
  [Azure guide](https://learn.microsoft.com/en-us/azure/devops/extend/publish/overview?toc=%2Fazure%2Fdevops%2Fmarketplace-extensibility%2Ftoc.json&view=azure-devops)
  on publishing extensions for more specific instructions
- Every merge to main will trigger a `qa-publish` job which publishes a private extension called `qa-nowsecure-azure-ci-extension` which is shared with the `nowsecure-test` org in Azure.
This should allow for internal testing before publicly publishing any extension
- Every tag creation will trigger a `prod-publish` job which publishes a public extension called `nowsecure-azure-ci-extension`
