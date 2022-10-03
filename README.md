# Azure Landing Zone VM Module 

[![Build Status](https://dev.azure.com/MoJ-OFFICIAL/Velocity-Landing-Zone/_apis/build/status/pullrequests/alz-vm?repoName=ministryofjustice%2Fstaff-infrastructure-alz-terraform-vm&branchName=main)](https://dev.azure.com/MoJ-OFFICIAL/Velocity-Landing-Zone/_build/latest?definitionId=197&repoName=ministryofjustice%2Fstaff-infrastructure-alz-terraform-vm&branchName=main)

The Terraform modules in this repository provide the means to easily create Virtual Machines in Azure Landing Zone using Terraform. 

Due to the way that the Terraform azure provider makes a distinction between Linux and Windows Virtual Machines by using a different resource type, there is a separate module for each Operating System. Specific versions or family of OS can be passed to the module.

See specific documentation in each module. Documentation is generated when a PR is opened using [terraform-docs](https://github.com/terraform-docs/terraform-docs/).

Module usage examples and further useful documentation can be found in the [ALZ user guides](https://ministryofjustice.github.io/azure-landing-zone-user-guides/documentation/building-alz-vms.html)