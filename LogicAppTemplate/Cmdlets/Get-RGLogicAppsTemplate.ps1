﻿<#
.Synopsis
   Create template Files for All logic Apps in a Resource Group.
.DESCRIPTION
   This script will create template files from all logic apps in a resource group and parameter files and saves them in folders defined as parameter.
   It assumes that the user has already been authenticated against Azure.
   It depends on the following components:
   - armclient
   - AzureRM
.EXAMPLE
   ./Get-RGLogicAppsTemplate.ps1 "My Subscription" "mytenant.onmicrosoft.com" "MyResourceGroup" "c:\mydestination"
.PARAMETER subscriptionname
    The subscription name where the resource group is deployed.
.PARAMETER tenantname
    The tenant associated to the subscription
.PARAMETER resourcegroup
    The Resource Group containing the Logic Apps to be extracted
.PARAMETER destination
    The local folder where the logic app templates will be created. if this folder doesn't exists it will be created. A new params folder will be created inside the destination folder.
#>
param([string] $subscriptionname, [string] $tenantname, [string] $resourcegroup, [string] $destination)

# Import the Logic Apps Template Module #
$module = resolve-path ".\..\bin\Debug\LogicAppTemplate.dll"
Import-Module $module

# Creates the Parames folder location #
$paramdestination = [IO.Path]::GetFullPath((Join-Path $destination "\params\"))

# Create required folders #
md -Force $destination | Out-Null
md -Force $paramdestination | Out-Null

# Select the correct subscription #
Get-AzureRmSubscription -SubscriptionName $subscriptionname | Select-AzureRmSubscription | Out-Null

Write-Host

# Gets a list of logic apps and generates the associated ARM template, saving on $destination #
Find-AzureRmResource -ResourceGroupNameContains $resourcegroup -ResourceType Microsoft.Logic/workflows | ForEach-Object { Write-Host $("Creating {0} Logic App Template" -f $_.Name) | armclient token $_.SubscriptionId | Get-LogicAppTemplate -LogicApp $_.Name -ResourceGroup $_.ResourceGroupName -SubscriptionId $_.SubscriptionId -TenantName $tenantname -Verbose | Out-File $(Join-path $destination ($_.Name + ".json")) -Force}

Write-Host

# Parses the generated ARM Template files and generate the templates #
Get-ChildItem -Path $destination -File |ForEach-Object {Write-Host $("Creating {0} Logic App parms file" -f $_.Name) ; Get-ParameterTemplate -TemplateFile $_.FullName | Out-File $(Join-path $paramdestination ("param_" + $_.Name)) -Force}

write-Host