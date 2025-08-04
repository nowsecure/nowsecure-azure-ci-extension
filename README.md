# nowsecure-azure-ci-extension

## Development

### Dependencies
- node

### Making Changes

The core functionality is handled by the `nowsecure-ci` golang binary. The logic in `Nowsecure/index.ts` is merely a wrapper around that binary file.

To adjust any of the inputs / default values edit the `nowsecure/task.json`

To adjust any of the wrapper logic, edit `nowsecure/index.ts`

### Building

There is a convenience bash script, `publish` which can handle packaging and publishing the ADO extension. 

To package for testing in the QA environment, run the following:

``` shell
ENV=QA ./publish package
```

This will create a `.vsix` file which can be uploaded to the [QA storefront](https://marketplace.visualstudio.com/publishers/qa-nowsecure) 

## Deploying
This should be handled automatically by a Github Action in the future, but the bash script in this repo can also publish directly to the [public storefront](https://marketplace.visualstudio.com/publishers/Nowsecure-com)

```
ENV=PROD TOKEN=<some-token> ./publish publish
```
