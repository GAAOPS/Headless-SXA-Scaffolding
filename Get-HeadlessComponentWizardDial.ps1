function Get-HeadlessComponentWizardDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0 )]
        [Item]$CurrentItem
    )

    begin {
        Write-Verbose "Cmdlet Get-ComponentWizardDialog - Begin"
        Import-Function Get-UniqueItem
        Import-Function Select-InheritingFrom
    }

    process {
        Write-Verbose "Cmdlet Get-ComponentWizardDialog - Process"
        $nonDataSourceOption = [Sitecore.XA.Foundation.Scaffolding.Models.ComponentDataSourceMode]::CurrentPage
        $datasourcesSelection = [ordered]@{
            "Ask user for data source"                    = [Sitecore.XA.Foundation.Scaffolding.Models.ComponentDataSourceMode]::AskUser
            "User current page"                           = $nonDataSourceOption
            "Automatically create data source under page" = [Sitecore.XA.Foundation.Scaffolding.Models.ComponentDataSourceMode]::AutoCreate
        };
        
        $standardTemplate = Get-Item -Path "/sitecore/templates/System/Templates/Standard template"
        $standardRenderingParameters = Get-Item -Path "/sitecore/templates/Foundation/JSS Experience Accelerator/Presentation/Rendering Parameters/BaseRenderingParameters"
        if ($CurrentItem) {
            $defaultTargeModule = $CurrentItem
        }
        else {
            $defaultTargeModule = Get-Item -Path "/sitecore/layout/Renderings/Feature"
        }
        
        $defaultRenderingTemplate = Get-Item -Path "/sitecore/templates/Foundation/JavaScript Services/Json Rendering"
        $defaultDataFolderTemplate = Get-Item -Path "/sitecore/templates/Common/Folder"
        $defaultScaffoldingPath= Get-Item -Path "/sitecore/system/Settings/Feature"

        $dialogParmeters = @()
        $dialogParmeters += @{ Name = "componentName"; Value = "Component Name"; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ComponentName)); Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General)) }
        $dialogParmeters += @{ Name = "targetModule"; Value = $defaultTargeModule; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::FeatureToPutThisRenderingIn)); Root = "/sitecore/layout/Renderings/Feature"; Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General)) }

        $dialogParmeters += @{ Name = "scaffolding"; Value = $true; Title = ("Update Scaffolding"); Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General)); GroupId = 4;}
        $dialogParmeters += @{ Name = "scaffoldingModule"; Value = $defaultScaffoldingPath; Title = ("Scaffolding Module"); Root = "/sitecore/system/Settings"; Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General)); ParentGroupId = 4; HideOnValue = 0; }
        
        $dialogParmeters += @{ Name = "datasourcesMode"; Value = [Sitecore.XA.Foundation.Scaffolding.Models.ComponentDataSourceMode]::AskUser; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Datasource)); Options = $datasourcesSelection; Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Datasource)); GroupId = 1; }

        $dialogParmeters += @{ Name = "renderingTemplate"; Value = $defaultRenderingTemplate; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::RenderingTemplate)); Root = "/sitecore/templates"; Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Datasource)); }
        $dialogParmeters += @{ Name = "rpTemplate"; Value = $standardRenderingParameters; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::BaseRenderingParametersTemplate)); Root = "/sitecore/templates"; Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Datasource)); }
        $dialogParmeters += @{ Name = "dsTemplate"; Value = $standardTemplate; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::BaseDataSourceTemplate)); Root = "/sitecore/templates"; Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Datasource)); ParentGroupId = 1; HideOnValue = $nonDataSourceOption; }
        
        $dialogParmeters += @{ Name = "createDataFolder"; Value = $true; Title = ("Create Data folder Template"); Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Datasource)); GroupId = 3;}
        $dialogParmeters += @{ Name = "dfTemplate"; Value = $defaultDataFolderTemplate; Title = ("Base Folder Template"); Root = "/sitecore/templates"; Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Datasource)); ParentGroupId = 3; HideOnValue = 0; }

        $dialogParmeters += @{ Name = "publishingGroupingTemplates"; Value = $false; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::PublishingGroupingTemplate)); Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Datasource)); ParentGroupId = 1; HideOnValue = $nonDataSourceOption; }

        $dialogParmeters += @{ Name = "compatibleTemplates"; Source = "DataSource=/sitecore/templates&DatabaseName=master&IncludeTemplatesForSelection=Template"; editor = "treelist"; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::AdditionalCompatibleTemplates)); Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Datasource); ParentGroupId = 1; HideOnValue = $nonDataSourceOption; }
        
        $dialogParmeters += @{ Name = "canSelectPages"; Value = $false; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CanSelectPages)); Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Behaviors)); ParentGroupId = 1; HideOnValue = $nonDataSourceOption; }

        $dialogParmeters += @{ Name = "dsSelection"; Value = $false; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::AbilityToSetDataSourceSelectionBehavior)); Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Behaviors)); ParentGroupId = 1; HideOnValue = $nonDataSourceOption; }
        
        $dialogParmeters += @{ Name = "IComponentVariant"; Value = $false; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SupportForComponentVariants)); Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Behaviors)); GroupId = 2; }
        $dialogParmeters += @{ Name = "IDynamicPlaceholder"; Value = $false; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SupportForDynamicPlaceholders)); Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Behaviors)); }


        $result = Read-Variable -Parameters $dialogParmeters `
            -Description ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ComponentWizardDescription)) `
            -Title ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ComponentWizardTitle)) -Width 650 -Height 700 -ShowHints `
            -OkButtonName $([Sitecore.Globalization.Translate]::Text("Ok")) -CancelButtonName $([Sitecore.Globalization.Translate]::Text("Cancel")) `
            -Validator {
            $componentName = $variables.componentName.Value;
            $pattern = "^[\w][\w\s\-]*(\(\d{1,}\)){0,1}$"
            if ($componentName.Length -gt 100) {
                $variables.componentName.Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.Texts]::ThelengthofthevalueistoolongPleasespecifyavalueoflesstha)) -f 100
                continue
            }
            if ([System.Text.RegularExpressions.Regex]::IsMatch($componentName, $pattern, [System.Text.RegularExpressions.RegexOptions]::ECMAScript) -eq $false) {
                $variables.componentName.Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::IsNotAValidName)) -f $componentName
                continue
            }
            [Sitecore.Data.ID]$renderingOptionsSectionTemplateID = "{D1592226-3898-4CE2-B190-090FD5F84A4C}"
            $forbiddenComponentNames = $variables.targetModule.Value.Children | Select-InheritingFrom $renderingOptionsSectionTemplateID | % { $_.Name }
            if ($forbiddenComponentNames -contains $componentName -eq $true) {
                $variables.componentName.Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ComponentWithThatNameAlreadyExists))
                continue
            }
                
            $componentClass = $variables.componentClass.Value;
            $pattern = "^[0-9-_]+(.)*$"
            if ([System.Text.RegularExpressions.Regex]::IsMatch($componentClass, $pattern, [System.Text.RegularExpressions.RegexOptions]::ECMAScript) -eq $true) {
                $variables.componentClass.Error = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ComponentWizardErrorCssStart)
                continue
            }

            $pattern = "^[a-zA-Z0-9-_]*$"
            if ([System.Text.RegularExpressions.Regex]::IsMatch($componentClass, $pattern, [System.Text.RegularExpressions.RegexOptions]::ECMAScript) -eq $false) {
                $variables.componentClass.Error = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ComponentWizardErrorCssInvalidCharacters)
                continue
            }
                
            Import-Function Test-ValidComponentWizardTemplate
                
            $renderingTemplate = $variables.renderingTemplate.Value
            $sxaExtendedOptionsRenderingSection = "{478A5C00-6B7A-4344-8F98-4886B984F3EE}"
            $renderingTemplateError = Test-ValidComponentWizardTemplate $renderingTemplate $sxaExtendedOptionsRenderingSection
            if ($renderingTemplateError.Length -gt 0) {
                $variables.renderingTemplate.Error = $renderingTemplateError
                continue
            }
                
            $dsTemplate = $variables.dsTemplate.Value
            $standardTemplateTemplateID = "{1930BBEB-7805-471A-A3BE-4858AC7CF696}"
            $dsTemplateError = Test-ValidComponentWizardTemplate $dsTemplate $standardTemplateTemplateID
            if ($dsTemplateError.Length -gt 0) {
                $variables.dsTemplate.Error = $dsTemplateError
                continue
            }
                
            $rpTemplate = $variables.rpTemplate.Value
            $standardRenderingParametersTemplateID = "{8CA06D6A-B353-44E8-BC31-B528C7306971}"
            $rpTemplateError = Test-ValidComponentWizardTemplate $rpTemplate $standardRenderingParametersTemplateID
            if ($rpTemplateError.Length -gt 0) {
                $variables.rpTemplate.Error = $rpTemplateError
                continue
            }
                
            Import-Function Get-ModuleRootCandidate
            Import-Function Test-ModuleContainsRoots
            $targetModule = $variables.targetModule.Value
            $targetModule = Get-ModuleRootCandidate $targetModule
                
            $requiredRoots = @("Renderings", "Templates", "Branches", "Settings")
            $testResult = Test-ModuleContainsRoots $targetModule $requiredRoots
            if ($testResult -eq $false) {
                $variables.targetModule.Error = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ComponentWizardErrorTargetModule) -f ($requiredRoots -join ', ')
                continue
            }
                
        } `
            -ValidatorParameters @{variablex = "s" }
        if ($result -ne "ok") {
            Exit
        }
        
        
        $baseRenderingParametersTemplates = @($rpTemplate)
        $otherProperties = @()
        $dynamicPlaceholderRenderingParameterID = "{5C74E985-E055-43FF-B28C-DB6C6A6450A2}" #/sitecore/templates/Foundation/Experience Accelerator/Dynamic Placeholders/Rendering Parameters/IDynamicPlaceholder
        $componentVariantRenderingParameterID = "{A9F8A74E-5F7D-4506-8661-B08E7B9A7B91}" # /sitecore/templates/Foundation/Experience Accelerator/Variants/Rendering Parameters/IComponentVariant
        if ($IComponentVariant -eq $true) {
            $baseRenderingParametersTemplates += Get-Item master: -ID $dynamicPlaceholderRenderingParameterID
            $baseRenderingParametersTemplates += Get-Item master: -ID $componentVariantRenderingParameterID
        }
        if ($IDynamicPlaceholder -eq $true) {
            $baseRenderingParametersTemplates += Get-Item master: -ID $dynamicPlaceholderRenderingParameterID
            $otherProperties += "IsRenderingsWithDynamicPlaceholders"
        }
        if ($datasourcesMode -eq [Sitecore.XA.Foundation.Scaffolding.Models.ComponentDataSourceMode]::AutoCreate) {
            $otherProperties += "IsAutoDatasourceRendering"
        }
        
        # add base rendering parameters templates - const
        $baseRenderingParametersTemplates += Get-Item master: -ID "{FF75632A-03ED-4D31-B42A-1EEE45E5147F}" #/sitecore/templates/Foundation/Experience Accelerator/Grid/Rendering Parameters/Grid Parameters
        $baseRenderingParametersTemplates += Get-Item master: -ID "{D959F476-2A2C-40C6-81F5-FB75342BBFB9}" #/sitecore/templates/Foundation/Experience Accelerator/Presentation/Rendering Parameters/IStyling
        $baseRenderingParametersTemplates += Get-Item master: -ID "{6DA8A00F-473E-487D-BEFE-6834350D5B67}" #/sitecore/templates/Foundation/Experience Accelerator/Presentation/Rendering Parameters/ICacheable
        
        
        $model = New-Object PSObject
        Add-Member -InputObject $model -MemberType NoteProperty -Name ComponentName -Value $componentName
        Add-Member -InputObject $model -MemberType NoteProperty -Name TargetModule -Value $targetModule
        Add-Member -InputObject $model -MemberType NoteProperty -Name DataSourceMode -Value $datasourcesMode
        Add-Member -InputObject $model -MemberType NoteProperty -Name BaseDataSourceTemplate -Value $dsTemplate
        Add-Member -InputObject $model -MemberType NoteProperty -Name BaseRenderingParametersTemplates -Value (Get-UniqueItem $baseRenderingParametersTemplates)

        Add-Member -InputObject $model -MemberType NoteProperty -Name RenderingTemplate -Value $renderingTemplate
        Add-Member -InputObject $model -MemberType NoteProperty -Name CompatibleTemplates -Value $compatibleTemplates
        Add-Member -InputObject $model -MemberType NoteProperty -Name CanSelectPages -Value $canSelectPages
        Add-Member -InputObject $model -MemberType NoteProperty -Name CanSetDataSourceBehaviour -Value $dsSelection
        Add-Member -InputObject $model -MemberType NoteProperty -Name DynamicPlaceholdersSupport -Value $IDynamicPlaceholder
        Add-Member -InputObject $model -MemberType NoteProperty -Name ComponentsVariantsSupport -Value $IComponentVariant
        Add-Member -InputObject $model -MemberType NoteProperty -Name OtherProperties -Value $otherProperties
        Add-Member -InputObject $model -MemberType NoteProperty -Name PublishingGroupingTemplates -Value $publishingGroupingTemplates
        Add-Member -InputObject $model -MemberType NoteProperty -Name Scaffolding -Value $scaffolding
        Add-Member -InputObject $model -MemberType NoteProperty -Name ScaffoldingModule -Value $scaffoldingModule
        Add-Member -InputObject $model -MemberType NoteProperty -Name CreateDataFolder -Value $createDataFolder
        Add-Member -InputObject $model -MemberType NoteProperty -Name DataFolderBaseTemplate -Value $dfTemplate

        $model
    }

    end {
        Write-Verbose "Cmdlet Get-ComponentWizardDialog - End"
    }
}
$CurrentItem = Get-Item master:/sitecore/layout/Renderings/Feature
$model = Get-HeadlessComponentWizardDialog $CurrentItem
$model



#Add-HeadlessComponent $model