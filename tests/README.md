# Pester tests

Basic testing of modules in this repository uses the [Pester](https://pester.dev/docs/v4/quick-start) testing Framework for Powershell. 

This module requires certain Azure resources to be present. Temporary resources are created during the testing to account for this. 

The testing process is defined in tests/pester-tests.yaml and is as follows: 

- Resources in tests/terraform/infra-build are deployed
- Resources in tests/terraform/vm-build are deployed
- Pester runs the tests in tests/tests.ps1
- All resources are destroyed
