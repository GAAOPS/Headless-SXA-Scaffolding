
function Add-HeadlessComponent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [PSObject]$Model
    )

    begin {
        Write-Verbose "Cmdlet Add-Component - Begin"
        Import-Function Get-TemplatesFolderForFeature
        Import-Function Add-FolderStructure
        Import-Function Copy-Rendering
        Import-Function Get-SettingsFolderForFeature
        Import-Function Get-SiteSetupForModule
        Import-Function Add-SetupItemDependency
        Import-Function Get-BranchesFolderForFeature
        Import-Function Get-ModuleRootCandidate
    }

    process {
        Write-Verbose "Cmdlet Add-Component - Process"
        
        # Check if the rendering is supported
        [Sitecore.Data.ID]$renderingOptionsSectionTemplateID = "{D1592226-3898-4CE2-B190-090FD5F84A4C}" # /sitecore/templates/System/Layout/Sections/Rendering Options   -  Base Rendering Options (Editor Options,Layout Service)
        if ($Model.RenderingTemplate -ne $null -and [Sitecore.Data.Managers.TemplateManager]::GetTemplate($Model.RenderingTemplate.ID, $Model.RenderingTemplate.Database).InheritsFrom($renderingOptionsSectionTemplateID)) {
            $itemType = $Model.RenderingTemplate.Paths.Path
        }
        else {
            throw "Please choose the correct rendering template."
        }
        
        # Create Rendering Item
        $componentRendering = New-Item -Parent $Model.TargetModule -Name $Model.ComponentName -ItemType $itemType | Wrap-Item

        $Model.TargetModule = Get-ModuleRootCandidate $Model.TargetModule

        if ($Model.CanSelectPages) {
            $componentRendering."Can select Page as a data source" = $Model.CanSelectPages
        } 
        if ($Model.CompatibleTemplates) {
            $componentRendering."Additional compatible templates" = ($Model.CompatibleTemplates | % { $_.ID }) -join '|'
        }
        if ($Model.OtherProperties) {
            $componentRendering."OtherProperties" = ($model.OtherProperties | % { "$($_)=true" }) -join "&"
        }

        # Get the rendering Type
        $renderingType = switch ($componentRendering.Template.Name) {
            "Json Rendering" { [Sitecore.XA.Foundation.Scaffolding.Models.RenderingType]::JsonRendering; Break }
            "JavaScript Rendering" { [Sitecore.XA.Foundation.Scaffolding.Models.RenderingType]::JavaScriptRendering; Break }
            "Controller rendering" { [Sitecore.XA.Foundation.Scaffolding.Models.RenderingType]::ControllerRendering; Break }
            Default {
                [Sitecore.XA.Foundation.Scaffolding.Models.RenderingType]::Other
            }
        }
        
        # site setup + available renderings
        $settingsFolderForFeature = Get-SettingsFolderForFeature $Model.TargetModule # example: /sitecore/system/Settings/Feature/Portal/Page Content
        $branhcesFolderForFeature = Get-BranchesFolderForFeature $Model.TargetModule # example: /sitecore/templates/Branches/Feature/Portal/Page Content        
        $siteSetupItem = Get-SiteSetupForModule $settingsFolderForFeature -RenderingType $renderingType # example: /sitecore/system/Settings/Feature/Portal/Page Content/Page Content Site Setup

        # Create Placeholder
        if ($model.OtherProperties -contains "IsRenderingsWithDynamicPlaceholders") {
            $placeHolderRoot = Get-Item -Path "/sitecore/layout/Placeholder Settings/Feature/$($Model.TargetModule.Name)"
            if (-not $placeHolderRoot) {
                New-Item -ItemType "/sitecore/templates/System/Layout/Placeholder Settings Folder" -Path $placeHolderRoot.Paths.FullPath -Name "$($Model.TargetModule.Name)" > $null
            }

            if ($Model.TargetModule.Name -ne $Model.Name) {
                $placeHolderRoot = Get-Item -Path "/sitecore/layout/Placeholder Settings/Feature/$($Model.TargetModule.Name)/$($Model.Name)"
                if (-not $placeHolderRoot) {
                    New-Item -ItemType "/sitecore/templates/System/Layout/Placeholder Settings Folder" -Path $placeHolderRoot.Paths.FullPath -Name "$($Model.Name)" > $null
                }
            }
            # Main Placeholder
            $placeHolderItem = New-Item -ItemType "/sitecore/templates/System/Layout/Placeholder" -Path $placeHolderRoot.Paths.FullPath -Name "$($Model.ComponentName)"
            $componentRendering."Placeholders" = $placeHolderItem.ID
            #$placeHolderItem = New-Item -ItemType "/sitecore/templates/Foundation/JSS Experience Accelerator/Placeholder Settings/Placeholder" -Path $placeHolderRoot -Name "$($Model.ComponentName)"
            $virtualLocationIDPlaceholderSettings = "{050361FC-A05F-44CD-AC01-EEBCA2C57581}"
            $placeholderSettingsAction = Get-ChildItem -Path $siteSetupItem.Paths.Path -Recurse | ? { $_.TemplateName -eq "AddItem" } | ? { $_.Location -eq $virtualLocationIDPlaceholderSettings } | Select-Object -First 1
            # Update or create placeholder  action
            if ($placeholderSettingsAction) {
                $branch = $model.TargetModule.Database.GetItem($placeholderSettingsAction.Fields['Template'].Value)
                $availableRenderingsItem = $branch.Children | Select-Object -First 1 | Wrap-Item
                $placeholderFolder = Get-Item -Path "$($branch.Paths.FullPath)/$($Model.TargetModule.Name)" | Wrap-Item
                if(-not $placeholderFolder){
                    $placeholderFolder = New-Item -ItemType "/sitecore/templates/Foundation/JSS Experience Accelerator/Placeholder Settings/Placeholder Settings Folder" -Parent $branch -Name "$($Model.TargetModule.Name)" | Wrap-Item
                }
                if ($Model.TargetModule.Name -ne $Model.Name) {
                    $placeholderFolder = Get-Item -Path "$($placeholderFolder.Paths.FullPath)/$($Model.Name)"
                    if (-not $placeholderFolder) {
                        $placeholderFolder = New-Item -ItemType "/sitecore/templates/Foundation/JSS Experience Accelerator/Placeholder Settings/Placeholder Settings Folder" -Path $placeHolderRoot.Paths.FullPath -Name "$($Model.Name)" | Wrap-Item
                    }
                }
                $placeholderItem = Get-Item -Path "$($placeholderFolder.Paths.FullPath)/$($Model.ComponentName)" -ErrorAction Ignore
                if(-not $placeHolderItem){
                    # Create Placeholder in branch
                    New-Item -ItemType "/sitecore/templates/Foundation/JSS Experience Accelerator/Placeholder Settings/Placeholder" -Parent $placeholderFolder -Name "$($Model.ComponentName)" > $null
                }
            }
            else {
                $placeholderSettingsAction = New-Item -ItemType "Foundation/Experience Accelerator/Scaffolding/Actions/Site/AddItem" -Path $siteSetupItem.Paths.Path -Name "Add $($Model.TargetModule.Name) Placeholder Settings" | Wrap-Item
                $placeholderSettingsAction."Location" = $virtualLocationIDPlaceholderSettings
                $placeholderSettingsAction."__Name" = $Model.TargetModule.Name
                $TemplatesFolderForFeature = $branhcesFolderForFeature
                if ($TemplatesFolderForFeature -eq $null) {
                    $TemplatesFolderForFeature = Get-TemplatesFolderForFeature $Model.TargetModule
                }
                # Creating a branch for JSS placeholder settings
                $branch = New-Item -ItemType "/sitecore/templates/System/Branches/Branch" -Path $TemplatesFolderForFeature.Paths.FullPath -Name "$($Model.TargetModule.Name) Placeholder Settings" | Wrap-Item
                $branch."__Display Name" = ""
                $placeholderFolder = Get-Item -Path "$($branch.Paths.FullPath)/$($Model.TargetModule.Name)" -ErrorAction Ignore
                if(-not $placeholderFolder){
                    $placeholderFolder = New-Item -ItemType "/sitecore/templates/Foundation/JSS Experience Accelerator/Placeholder Settings/Placeholder Settings Folder" -Parent $branch -Name "$($Model.TargetModule.Name)" | Wrap-Item
                }
                if ($Model.TargetModule.Name -ne $Model.Name) {
                    $placeholderFolder = Get-Item -Path "$($placeholderFolder.Paths.FullPath)/$($Model.Name)" -ErrorAction Ignore
                    if (-not $placeholderFolder) {
                        $placeholderFolder = New-Item -ItemType "/sitecore/templates/Foundation/JSS Experience Accelerator/Placeholder Settings/Placeholder Settings Folder" -Path $placeHolderRoot.Paths.FullPath -Name "$($Model.Name)" | Wrap-Item
                    }
                }
                # Create Placeholder in branch
                New-Item -ItemType "/sitecore/templates/Foundation/JSS Experience Accelerator/Placeholder Settings/Placeholder" -Parent $placeholderFolder -Name "$($Model.ComponentName)" > $null

                $placeholderSettingsAction."__Template" = $branch.ID
            }

        }




        # Create Rendering param template & set it up 
        if ($Model.BaseRenderingParametersTemplates.Count -gt 0) {
            $renderingParametersItemName = $Model.ComponentName
            $templatesFolderForFeature = Get-TemplatesFolderForFeature $Model.TargetModule
            
            $renderingParametersFolder = Add-FolderStructure "$($templatesFolderForFeature.Paths.Path)/Rendering Parameters" "System/Templates/Template Folder"
            $newRenderingRenderingParameterTemplateItem = New-Item -ItemType "System/Templates/Template" -Parent $renderingParametersFolder -Name $renderingParametersItemName | Wrap-Item
            $newRenderingRenderingParameterTemplateItem."__Base template" = ($Model.BaseRenderingParametersTemplates.ID -join '|')
            
            $componentRendering."Parameters Template" = $newRenderingRenderingParameterTemplateItem.ID
        }

        # Create datasource template and setup the rendering datasource
        if ($Model.BaseDataSourceTemplate -and $Model.DataSourceMode -ne [Sitecore.XA.Foundation.Scaffolding.Models.ComponentDataSourceMode]::CurrentPage) {
            $dataSourceItemName = $Model.ComponentName
            $templatesFolderForFeature = Get-TemplatesFolderForFeature $Model.TargetModule
            $dataSourceFolder = Add-FolderStructure "$($templatesFolderForFeature.Paths.Path)/Data Source" "System/Templates/Template Folder"
            
            $datasourceFolderTemplateItem = New-Item -ItemType "System/Templates/Template" -Parent $dataSourceFolder -Name $dataSourceItemName | Wrap-Item
            ($datasourceFolderTemplateItem -as [Sitecore.Data.Items.TemplateItem]).CreateStandardValues() > $null
            
            $componentRendering."Datasource Template" = $datasourceFolderTemplateItem.Paths.Path
            
            $baseDataSourceTemplates = @($Model.BaseDataSourceTemplate.ID)
            if ($model.CanSetDataSourceBehaviour) {
                $globalDatasourceBehaviorTemplateID = "{A7837DE9-3266-46CB-A945-62C55DA45E9E}"
                $baseDataSourceTemplates += $globalDatasourceBehaviorTemplateID
            }
            if ($model.PublishingGroupingTemplates) {
                $baseDataSourceTemplates += "{8BA7DAC6-32ED-4378-BD9E-5DA5B0F9848D}"
            }            
            $datasourceFolderTemplateItem."__Base template" = $baseDataSourceTemplates -join "|"

            # Add Data folder template
            if ($Model.CreateDataFolder) {
                # Create data folder
                $dataFolderTemplate = New-Item -ItemType "System/Templates/Template" -Parent $dataSourceFolder -Name "$($Model.ComponentName)Folder" | Wrap-Item
                $dataFolderTemplate."__Base template" = $Model.DataFolderBaseTemplate.ID
                ($dataFolderTemplate -as [Sitecore.Data.Items.TemplateItem]).CreateStandardValues() > $null
                # Removing inherited insert options
                $stdValues = Get-Item "$($dataFolderTemplate.Paths.FullPath)/__Standard Values"
                $stdValues."__Masters" = ''
                # Update Scaffolding for Data Folder
                $virtualLocationIdData = "{BA2F959D-A614-4C92-8B57-F1FC1A323ABE}" #/sitecore/templates/Branches/Foundation/JSS Experience Accelerator/Scaffolding/JSS Tenant Folder/JSS Tenant Folder/JSS Tenant/JSS Site/Data
                
                $dataFolderAction = Get-ChildItem -Path $siteSetupItem.Paths.Path -Recurse | ? { $_.TemplateName -eq "AddItem" } | ? { $_.Location -eq $virtualLocationIdData } | Select-Object -First 1
                # Update or create available rendering action
                if ($dataFolderAction) {
                    if (-not ($dataFolderAction."_Template" -like "*$($dataFolderTemplate.ID)*")) {
                        if ($dataFolderAction."_Template") {
                            $dataFolderAction."_Template" = "$($dataFolderAction."_Template")|$($dataFolderTemplate.ID)"
                        }
                        else {
                            $dataFolderAction."_Template" = "$($dataFolderTemplate.ID)"
                        }
                    }
                }
                else {
                    $dataFolderAction = New-Item -ItemType "Foundation/Experience Accelerator/Scaffolding/Actions/Site/AddItem" -Path $siteSetupItem.Paths.Path -Name "Add $($Model.TargetModule.Name) Folder" | Wrap-Item
                    $dataFolderAction."Location" = $virtualLocationIdData
                    $dataFolderAction."__Name" = $Model.TargetModule.Name
                    $dataFolderAction."__Display Name" = ""
                    $dataFolderAction."_Template" = "$($dataFolderTemplate.ID)"
                }
            }
        }
        
        $addAvailableRenderingsAddActionID = "{4342A029-0186-4B0D-8959-FFEF4FD998C2}" #/sitecore/system/Settings/Foundation/JSS Experience Accelerator/Headless Variants/Headless Variants Site Setup # "{BDF83718-907A-435B-B1BA-64139E07983F}"
        Add-SetupItemDependency $siteSetupItem $addAvailableRenderingsAddActionID
        
        $virtualLocationIDAvailableRenderings = "{3F14C1B6-5A2D-44CA-A8EF-DFE3CBD574E4}" # /sitecore/templates/Branches/Foundation/Experience Accelerator/Scaffolding/Tenant Folder/Tenant Folder/Tenant/Site Folder/Site/Presentation/Available Renderings
        # Get existing available rendering action
        $availableRenderingsAction = Get-ChildItem -Path $siteSetupItem.Paths.Path -Recurse | ? { $_.TemplateName -eq "AddItem" } | ? { $_.Location -eq $virtualLocationIDAvailableRenderings } | Select-Object -First 1
        # Update or create available rendering action
        if ($availableRenderingsAction) {
            $branch = $model.TargetModule.Database.GetItem($availableRenderingsAction.Fields['Template'].Value)
            $availableRenderingsItem = $branch.Children | Select-Object -First 1 | Wrap-Item
        }
        else {
            $availableRenderingsAction = New-Item -ItemType "Foundation/Experience Accelerator/Scaffolding/Actions/Site/AddItem" -Path $siteSetupItem.Paths.Path -Name "Add $($Model.Name) Available Renderings" | Wrap-Item
            $availableRenderingsAction."Location" = $virtualLocationIDAvailableRenderings
            $availableRenderingsAction."__Name" = $Model.TargetModule.Name
            $TemplatesFolderForFeature = $branhcesFolderForFeature
            if ($TemplatesFolderForFeature -eq $null) {
                $TemplatesFolderForFeature = Get-TemplatesFolderForFeature $Model.TargetModule
            }
            $emptyAvailableRenderingsBranch = Get-Item -Path "/sitecore/templates/Branches/Foundation/Experience Accelerator/Scaffolding/Empty Available Renderings"
            $branch = $emptyAvailableRenderingsBranch.CopyTo($TemplatesFolderForFeature, "Available $($model.Name) Renderings") | Wrap-Item
            $branch."__Display Name" = ""
            $availableRenderingsItem = $branch.Children | Select-Object -First 1 | Wrap-Item
            $availableRenderingsAction."__Template" = $branch.ID
        }
        
        $availableRenderingsItem."Renderings" = ($availableRenderingsItem."Renderings", $componentRendering.ID | ? { $_ -ne "" }) -join "|"
        
        
        # ComponentsVariantsSupport
        if ($Model.ComponentsVariantsSupport -eq $true) {
            $newDefaultVariantName = 'Default ' + $model.ComponentName + ' Variant'
            $newDefaultVariantBranch = New-Item -ItemType "System/Branches/Branch" -Parent $branhcesFolderForFeature -Name $newDefaultVariantName | Wrap-Item
            $variantBranchItem = New-Item -ItemType "Foundation/Experience Accelerator/Rendering Variants/Variants" -Parent $newDefaultVariantBranch -Name '$name' | Wrap-Item
            New-Item -ItemType "/Foundation/JSS Experience Accelerator/Headless Variants/Variant Definition" -Parent $variantBranchItem -Name 'Default' > $null
            
            # site setup add action
            $newRenderingSiteSetupAddRVFolderName = "Rendering Variants"
            $newRenderingSiteSetupAddRVFolderPath = $siteSetupItem.Paths.Path + "/" + $newRenderingSiteSetupAddRVFolderName
            if (Test-Path $newRenderingSiteSetupAddRVFolderPath) {
                $newRenderingSiteSetupAddRVFolder = Get-Item -Path $newRenderingSiteSetupAddRVFolderPath
            }
            # If it does not exist, create new one
            if ($newRenderingSiteSetupAddRVFolder -eq $null) {
                $newRenderingSiteSetupAddRVFolder = New-Item -ItemType "/sitecore/templates/Common/Folder" -Parent $siteSetupItem -Name $newRenderingSiteSetupAddRVFolderName
            }            
            $addRenderingVariantItem = New-Item -ItemType "Foundation/Experience Accelerator/Scaffolding/Actions/Site/AddItem" -Parent $newRenderingSiteSetupAddRVFolder -Name $Model.ComponentName | Wrap-Item
            
            #3. Change newly created AddItem Action Item fields (not standard one)
            $virtualLocationIDRenderingVariants = "{5CDC5EB2-F14F-4495-88E8-AA882DDFAA05}"
            $addRenderingVariantItem._Name = $Model.ComponentName
            $addRenderingVariantItem.Location = $virtualLocationIDRenderingVariants
            $addRenderingVariantItem._Template = $newDefaultVariantBranch.ID.ToString()
        }
    }

    end {
        Write-Verbose "Cmdlet Add-Component - End"
    }
}





