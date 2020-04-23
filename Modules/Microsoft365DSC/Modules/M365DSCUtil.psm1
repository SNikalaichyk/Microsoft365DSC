
#region Session Objects
$Global:SessionSecurityCompliance = $null
#endregion

#region Extraction Modes
$Global:DefaultComponents = @("SPOApp","SPOSiteDesign")
$Global:FullComponents = @("O365Group","O365User","SPOSiteGroup","SPOSite","SPOUserProfileProperty","SPOPropertyBag","TeamsTeam","TeamsChannel", "TeamsUser")
#endregion

function Format-EXOParams
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [System.Collections.Hashtable]
        $InputEXOParams,

        [Parameter()]
        [ValidateSet('New', 'Set')]
        [System.String]
        $Operation
    )
    $EXOParams = $InputEXOParams
    $EXOParams.Remove("GlobalAdminAccount") | Out-Null
    $EXOParams.Remove("Ensure") | Out-Null
    $EXOParams.Remove("Verbose") | Out-Null
    if ('New' -eq $Operation)
    {
        $EXOParams += @{
            Name = $EXOParams.Identity
        }
        $EXOParams.Remove("Identity") | Out-Null
        $EXOParams.Remove("MakeDefault") | Out-Null
        return $EXOParams
    }
    if ('Set' -eq $Operation)
    {
        $EXOParams.Remove("Enabled") | Out-Null
        return $EXOParams
    }
}

function Get-TimeZoneNameFromID
{
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ID
    )

    $TimezoneObject = $Timezones | Where-Object -FilterScript { $_.ID -eq $ID }

    if ($null -eq $TimezoneObject)
    {
        throw "The specified Timzone with ID {$($ID)} is not valid"
    }
    return $TimezoneObject.EnglishName
}
function Get-TimeZoneIDFromName
{
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $TimezoneObject = $Timezones | Where-Object -FilterScript { $_.EnglishName -eq $Name }

    if ($null -eq $TimezoneObject)
    {
        throw "The specified Timzone {$($Name)} is not valid"
    }
    return $TimezoneObject.ID
}

function Get-TeamByGroupID
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $GroupId
    )

    $team = Get-Team -GroupId $GroupId
    if ($null -eq $team)
    {
        return $false
    }
    return $true
}
function Get-TeamByName
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TeamName
    )

    $loopCounter = 0
    do
    {
        $team = Get-Team -DisplayName $TeamName
        if ($null -eq $team)
        {
            Start-Sleep 5
        }
        $loopCounter += 1
        if ($loopCounter -gt 5)
        {
            break
        }
    } while ($null -eq $team)

    if ($null -eq $team)
    {
        throw "Team with Name $TeamName doesn't exist in tenant"
    }
    return $team
}

function Convert-M365DscHashtableToString
{
    param
    (
        [Parameter()]
        [System.Collections.Hashtable]
        $Hashtable
    )
    $values = @()
    foreach ($pair in $Hashtable.GetEnumerator())
    {
        try
        {
            if ($pair.Value -is [System.Array])
            {
                $str = "$($pair.Key)=($($pair.Value -join ","))"
            }
            elseif ($pair.Value -is [System.Collections.Hashtable])
            {
                $str = "$($pair.Key)={$(Convert-M365DscHashtableToString -Hashtable $pair.Value)}"
            }
            else
            {
                if ($null -eq $pair.Value)
                {
                    $str = "$($pair.Key)=`$null"
                }
                else
                {
                    $str = "$($pair.Key)=$($pair.Value)"
                }
            }
            $values += $str
        }
        catch
        {
            Write-Warning "There was an error converting the Hashtable to a string: $_"
        }
    }

    [array]::Sort($values)
    return ($values -join "; ")
}

function New-EXOAntiPhishPolicy
{
    param (
        [Parameter()]
        [System.Collections.Hashtable]
        $AntiPhishPolicyParams
    )
    try
    {
        $VerbosePreference = 'Continue'
        $BuiltParams = (Format-EXOParams -InputEXOParams $AntiPhishPolicyParams -Operation 'New' )
        Write-Verbose -Message "Creating New AntiPhishPolicy $($BuiltParams.Name) with values: $(Convert-M365DscHashtableToString -Hashtable $BuiltParams)"
        New-AntiPhishPolicy @BuiltParams
        $VerbosePreference = 'SilentlyContinue'
    }
    catch
    {
        Close-SessionsAndReturnError -ExceptionMessage $_.Exception
    }
}

function New-EXOAntiPhishRule
{
    param (
        [Parameter()]
        [System.Collections.Hashtable]
        $AntiPhishRuleParams
    )
    try
    {
        $VerbosePreference = 'Continue'
        $BuiltParams = (Format-EXOParams -InputEXOParams $AntiPhishRuleParams -Operation 'New')
        Write-Verbose -Message "Creating New AntiPhishRule $($BuiltParams.Name) with values: $(Convert-M365DscHashtableToString -Hashtable $BuiltParams)"
        New-AntiPhishRule @BuiltParams -Confirm:$false
        $VerbosePreference = 'SilentlyContinue'
    }
    catch
    {
        Close-SessionsAndReturnError -ExceptionMessage $_.Exception
    }
}

function New-EXOHostedContentFilterRule
{
    param (
        [Parameter()]
        [System.Collections.Hashtable]
        $HostedContentFilterRuleParams
    )
    try
    {
        $VerbosePreference = 'Continue'
        $BuiltParams = (Format-EXOParams -InputEXOParams $HostedContentFilterRuleParams -Operation 'New' )
        Write-Verbose -Message "Creating New HostedContentFilterRule $($BuiltParams.Name) with values: $(Convert-M365DscHashtableToString -Hashtable $BuiltParams)"
        New-HostedContentFilterRule @BuiltParams -Confirm:$false
        $VerbosePreference = 'SilentlyContinue'
    }
    catch
    {
        Close-SessionsAndReturnError -ExceptionMessage $_.Exception
    }
}

function New-EXOSafeAttachmentRule
{
    param (
        [Parameter()]
        [System.Collections.Hashtable]
        $SafeAttachmentRuleParams
    )
    try
    {
        $VerbosePreference = 'Continue'
        $BuiltParams = (Format-EXOParams -InputEXOParams $SafeAttachmentRuleParams -Operation 'New' )
        Write-Verbose -Message "Creating New SafeAttachmentRule $($BuiltParams.Name) with values: $(Convert-M365DscHashtableToString -Hashtable $BuiltParams)"
        New-SafeAttachmentRule @BuiltParams -Confirm:$false
        $VerbosePreference = 'SilentlyContinue'
    }
    catch
    {
        Close-SessionsAndReturnError -ExceptionMessage $_.Exception
    }
}

function New-EXOSafeLinksRule
{
    param (
        [Parameter()]
        [System.Collections.Hashtable]
        $SafeLinksRuleParams
    )
    try
    {
        $VerbosePreference = 'Continue'
        $BuiltParams = (Format-EXOParams -InputEXOParams $SafeLinksRuleParams -Operation 'New' )
        Write-Verbose -Message "Creating New SafeLinksRule $($BuiltParams.Name) with values: $(Convert-M365DscHashtableToString -Hashtable $BuiltParams)"
        New-SafeLinksRule @BuiltParams -Confirm:$false
        $VerbosePreference = 'SilentlyContinue'
    }
    catch
    {
        Close-SessionsAndReturnError -ExceptionMessage $_.Exception
    }
}

function Set-EXOAntiPhishRule
{
    param (
        [Parameter()]
        [System.Collections.Hashtable]
        $AntiPhishRuleParams
    )
    try
    {
        $VerbosePreference = 'Continue'
        $BuiltParams = (Format-EXOParams -InputEXOParams $AntiPhishRuleParams -Operation 'Set' )
        if ($BuiltParams.keys -gt 1)
        {
            Write-Verbose -Message "Setting AntiPhishRule $($BuiltParams.Identity) with values: $(Convert-M365DscHashtableToString -Hashtable $BuiltParams)"
            Set-AntiPhishRule @BuiltParams -Confirm:$false
            $VerbosePreference = 'SilentlyContinue'
        }
        else
        {
            Write-Verbose -Message "No more values to Set on AntiPhishRule $($BuiltParams.Identity) using supplied values: $(Convert-M365DscHashtableToString -Hashtable $BuiltParams)"
            $VerbosePreference = 'SilentlyContinue'
        }
    }
    catch
    {
        Close-SessionsAndReturnError -ExceptionMessage $_.Exception
    }
}

function Set-EXOAntiPhishPolicy
{
    param (
        [Parameter()]
        [System.Collections.Hashtable]
        $AntiPhishPolicyParams
    )
    try
    {
        $VerbosePreference = 'Continue'
        $BuiltParams = (Format-EXOParams -InputEXOParams $AntiPhishPolicyParams -Operation 'Set' )
        if ($BuiltParams.keys -gt 1)
        {
            Write-Verbose -Message "Setting AntiPhishPolicy $($BuiltParams.Identity) with values: $(Convert-M365DscHashtableToString -Hashtable $BuiltParams)"
            Set-AntiPhishPolicy @BuiltParams -Confirm:$false
            $VerbosePreference = 'SilentlyContinue'
        }
        else
        {
            Write-Verbose -Message "No more values to Set on AntiPhishPolicy $($BuiltParams.Identity) using supplied values: $(Convert-M365DscHashtableToString -Hashtable $BuiltParams)"
            $VerbosePreference = 'SilentlyContinue'
        }
    }
    catch
    {
        Close-SessionsAndReturnError -ExceptionMessage $_.Exception
    }
}
function Set-EXOHostedContentFilterRule
{
    param (
        [Parameter()]
        [System.Collections.Hashtable]
        $HostedContentFilterRuleParams
    )
    try
    {
        $VerbosePreference = 'Continue'
        $BuiltParams = (Format-EXOParams -InputEXOParams $HostedContentFilterRuleParams -Operation 'Set' )
        if ($BuiltParams.keys -gt 1)
        {
            Write-Verbose -Message "Setting HostedContentFilterRule $($BuiltParams.Identity) with values: $(Convert-M365DscHashtableToString -Hashtable $BuiltParams)"
            Set-HostedContentFilterRule @BuiltParams -Confirm:$false
            $VerbosePreference = 'SilentlyContinue'
        }
        else
        {
            Write-Verbose -Message "No more values to Set on HostedContentFilterRule $($BuiltParams.Identity) using supplied values: $(Convert-M365DscHashtableToString -Hashtable $BuiltParams)"
            $VerbosePreference = 'SilentlyContinue'
        }
    }
    catch
    {
        Close-SessionsAndReturnError -ExceptionMessage $_.Exception
    }
}

function Confirm-ImportedCmdletIsAvailable
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $CmdletName
    )
    try
    {
        $CmdletIsAvailable = (Get-Command -Name $CmdletName -ErrorAction SilentlyContinue)
        if ($CmdletIsAvailable)
        {
            return $true
        }
        else
        {
            return $false
        }
    }
    catch
    {
        return $false
    }
}

function Set-EXOSafeAttachmentRule
{
    param (
        [Parameter()]
        [System.Collections.Hashtable]
        $SafeAttachmentRuleParams
    )
    try
    {
        $VerbosePreference = 'Continue'
        $BuiltParams = (Format-EXOParams -InputEXOParams $SafeAttachmentRuleParams -Operation 'Set' )
        if ($BuiltParams.keys -gt 1)
        {
            Write-Verbose -Message "Setting SafeAttachmentRule $($BuiltParams.Identity) with values: $(Convert-M365DscHashtableToString -Hashtable $BuiltParams)"
            Set-SafeAttachmentRule @BuiltParams -Confirm:$false
            $VerbosePreference = 'SilentlyContinue'
        }
        else
        {
            Write-Verbose -Message "No more values to Set on SafeAttachmentRule $($BuiltParams.Identity) using supplied values: $(Convert-M365DscHashtableToString -Hashtable $BuiltParams)"
            $VerbosePreference = 'SilentlyContinue'
        }
    }
    catch
    {
        Close-SessionsAndReturnError -ExceptionMessage $_.Exception
    }
}

function Set-EXOSafeLinksRule
{
    param (
        [Parameter()]
        [System.Collections.Hashtable]
        $SafeLinksRuleParams
    )
    try
    {
        $VerbosePreference = 'Continue'
        $BuiltParams = (Format-EXOParams -InputEXOParams $SafeLinksRuleParams -Operation 'Set' )
        if ($BuiltParams.keys -gt 1)
        {
            Write-Verbose -Message "Setting SafeLinksRule $($BuiltParams.Identity) with values: $(Convert-M365DscHashtableToString -Hashtable $BuiltParams)"
            Set-SafeLinksRule @BuiltParams -Confirm:$false
            $VerbosePreference = 'SilentlyContinue'
        }
        else
        {
            Write-Verbose -Message "No more values to Set on SafeLinksRule $($BuiltParams.Identity) using supplied values: $(Convert-M365DscHashtableToString -Hashtable $BuiltParams)"
            $VerbosePreference = 'SilentlyContinue'
        }
    }
    catch
    {
        Close-SessionsAndReturnError -ExceptionMessage $_.Exception
    }
}

function Compare-PSCustomObjectArrays
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $DesiredValues,

        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $CurrentValues
    )

    $DriftedProperties = @()
    foreach ($DesiredEntry in $DesiredValues)
    {
        $Properties = $DesiredEntry.PSObject.Properties
        $KeyProperty = $Properties.Name[0]

        $EquivalentEntryInCurrent = $CurrentValues | Where-Object -FilterScript { $_.$KeyProperty -eq $DesiredEntry.$KeyProperty }
        if ($null -eq $EquivalentEntryInCurrent)
        {
            $result = @{
                Property     = $DesiredEntry
                PropertyName = $KeyProperty
                Desired      = $DesiredEntry.$KeyProperty
                Current      = $null
            }
            $DriftedProperties += $DesiredEntry
        }
        else
        {
            foreach ($property in $Properties)
            {
                $propertyName = $property.Name

                if ($DesiredEntry.$PropertyName -ne $EquivalentEntryInCurrent.$PropertyName)
                {
                    $result = @{
                        Property     = $DesiredEntry
                        PropertyName = $PropertyName
                        Desired      = $DesiredEntry.$PropertyName
                        Current      = $EquivalentEntryInCurrent.$PropertyName
                    }
                    $DriftedProperties += $result
                }
            }
        }
    }

    return $DriftedProperties
}

function Test-Microsoft365DSCParameterState
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 1)]
        [HashTable]
        $CurrentValues,

        [Parameter(Mandatory = $true, Position = 2)]
        [Object]
        $DesiredValues,

        [Parameter(Position = 3)]
        [Array]
        $ValuesToCheck,

        [Parameter(Position = 4)]
        [System.String]
        $Source = 'Generic'
    )
    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", "$Source")
    $data.Add("Method", "Test-TargetResource")
    #endregion
    $returnValue = $true

    $DriftedParameters = @{ }

    if (($DesiredValues.GetType().Name -ne "HashTable") `
            -and ($DesiredValues.GetType().Name -ne "CimInstance") `
            -and ($DesiredValues.GetType().Name -ne "PSBoundParametersDictionary"))
    {
        throw ("Property 'DesiredValues' in Test-Microsoft365DSCParameterState must be either a " + `
                "Hashtable or CimInstance. Type detected was $($DesiredValues.GetType().Name)")
    }

    if (($DesiredValues.GetType().Name -eq "CimInstance") -and ($null -eq $ValuesToCheck))
    {
        throw ("If 'DesiredValues' is a CimInstance then property 'ValuesToCheck' must contain " + `
                "a value")
    }

    if (($null -eq $ValuesToCheck) -or ($ValuesToCheck.Count -lt 1))
    {
        $KeyList = $DesiredValues.Keys
    }
    else
    {
        $KeyList = $ValuesToCheck
    }

    $KeyList | ForEach-Object -Process {
        if (($_ -ne "Verbose") -and ($_ -ne "InstallAccount"))
        {
            if (($CurrentValues.ContainsKey($_) -eq $false) `
                    -or ($CurrentValues.$_ -ne $DesiredValues.$_) `
                    -or (($DesiredValues.ContainsKey($_) -eq $true) -and ($null -ne $DesiredValues.$_ -and $DesiredValues.$_.GetType().IsArray)))
            {
                if ($DesiredValues.GetType().Name -eq "HashTable" -or `
                        $DesiredValues.GetType().Name -eq "PSBoundParametersDictionary")
                {
                    $CheckDesiredValue = $DesiredValues.ContainsKey($_)
                }
                else
                {
                    $CheckDesiredValue = Test-M365DSCObjectHasProperty -Object $DesiredValues -PropertyName $_
                }

                if ($CheckDesiredValue)
                {
                    $desiredType = $DesiredValues.$_.GetType()
                    $fieldName = $_
                    if ($desiredType.IsArray -eq $true)
                    {
                        if (($CurrentValues.ContainsKey($fieldName) -eq $false) `
                                -or ($null -eq $CurrentValues.$fieldName))
                        {
                            Write-Verbose -Message ("Expected to find an array value for " + `
                                    "property $fieldName in the current " + `
                                    "values, but it was either not present or " + `
                                    "was null. This has caused the test method " + `
                                    "to return false.")
                            $DriftedParameters.Add($fieldName, '')
                            $returnValue = $false
                        }
                        elseif ($desiredType.Name -eq 'ciminstance[]')
                        {
                            Write-Verbose "The current property {$_} is a CimInstance[]"
                            $AllDesiredValuesAsArray = @()
                            foreach ($item in $DesiredValues.$_)
                            {
                                $currentEntry = @{ }
                                foreach ($prop in $item.CIMInstanceProperties)
                                {
                                    $value = $prop.Value
                                    if ([System.String]::IsNullOrEmpty($value))
                                    {
                                        $value = $null
                                    }
                                    $currentEntry.Add($prop.Name, $value)
                                }
                                $AllDesiredValuesAsArray += [PSCustomObject]$currentEntry
                            }

                            $arrayCompare = Compare-PSCustomObjectArrays -CurrentValues $CurrentValues.$fieldName `
                                -DesiredValues $AllDesiredValuesAsArray
                            if ($null -ne $arrayCompare)
                            {
                                foreach ($item in $arrayCompare)
                                {
                                    $EventValue = "<CurrentValue>[$($item.PropertyName)]$($item.CurrentValue)</CurrentValue>"
                                    $EventValue += "<DesiredValue>[$($item.PropertyName)]$($item.DesiredValue)</DesiredValue>"
                                    $DriftedParameters.Add($fieldName, $EventValue)
                                }
                                $returnValue = $false
                            }
                        }
                        else
                        {
                            $arrayCompare = Compare-Object -ReferenceObject $CurrentValues.$fieldName `
                                -DifferenceObject $DesiredValues.$fieldName
                            if ($null -ne $arrayCompare -and
                                -not [System.String]::IsNullOrEmpty($arrayCompare.InputObject))
                            {
                                Write-Verbose -Message ("Found an array for property $fieldName " + `
                                        "in the current values, but this array " + `
                                        "does not match the desired state. " + `
                                        "Details of the changes are below.")
                                $arrayCompare | ForEach-Object -Process {
                                    Write-Verbose -Message "$($_.InputObject) - $($_.SideIndicator)"
                                }

                                $EventValue = "<CurrentValue>$($CurrentValues.$fieldName)</CurrentValue>"
                                $EventValue += "<DesiredValue>$($DesiredValues.$fieldName)</DesiredValue>"
                                $DriftedParameters.Add($fieldName, $EventValue)
                                $returnValue = $false
                            }
                        }
                    }
                    else
                    {
                        switch ($desiredType.Name)
                        {
                            "String"
                            {
                                if ([string]::IsNullOrEmpty($CurrentValues.$fieldName) `
                                        -and [string]::IsNullOrEmpty($DesiredValues.$fieldName))
                                {
                                }
                                else
                                {
                                    Write-Verbose -Message ("String value for property " + `
                                            "$fieldName does not match. " + `
                                            "Current state is " + `
                                            "'$($CurrentValues.$fieldName)' " + `
                                            "and desired state is " + `
                                            "'$($DesiredValues.$fieldName)'")
                                    $EventValue = "<CurrentValue>$($CurrentValues.$fieldName)</CurrentValue>"
                                    $EventValue += "<DesiredValue>$($DesiredValues.$fieldName)</DesiredValue>"
                                    $DriftedParameters.Add($fieldName, $EventValue)
                                    $returnValue = $false
                                }
                            }
                            "Int32"
                            {
                                if (($DesiredValues.$fieldName -eq 0) `
                                        -and ($null -eq $CurrentValues.$fieldName))
                                {
                                }
                                else
                                {
                                    Write-Verbose -Message ("Int32 value for property " + `
                                            "$fieldName does not match. " + `
                                            "Current state is " + `
                                            "'$($CurrentValues.$fieldName)' " + `
                                            "and desired state is " + `
                                            "'$($DesiredValues.$fieldName)'")
                                    $EventValue = "<CurrentValue>$($CurrentValues.$fieldName)</CurrentValue>"
                                    $EventValue += "<DesiredValue>$($DesiredValues.$fieldName)</DesiredValue>"
                                    $DriftedParameters.Add($fieldName, $EventValue)
                                    $returnValue = $false
                                }
                            }
                            "Int16"
                            {
                                if (($DesiredValues.$fieldName -eq 0) `
                                        -and ($null -eq $CurrentValues.$fieldName))
                                {
                                }
                                else
                                {
                                    Write-Verbose -Message ("Int16 value for property " + `
                                            "$fieldName does not match. " + `
                                            "Current state is " + `
                                            "'$($CurrentValues.$fieldName)' " + `
                                            "and desired state is " + `
                                            "'$($DesiredValues.$fieldName)'")
                                    $EventValue = "<CurrentValue>$($CurrentValues.$fieldName)</CurrentValue>"
                                    $EventValue += "<DesiredValue>$($DesiredValues.$fieldName)</DesiredValue>"
                                    $DriftedParameters.Add($fieldName, $EventValue)
                                    $returnValue = $false
                                }
                            }
                            "Boolean"
                            {
                                if ($CurrentValues.$fieldName -ne $DesiredValues.$fieldName)
                                {
                                    Write-Verbose -Message ("Boolean value for property " + `
                                            "$fieldName does not match. " + `
                                            "Current state is " + `
                                            "'$($CurrentValues.$fieldName)' " + `
                                            "and desired state is " + `
                                            "'$($DesiredValues.$fieldName)'")
                                    $EventValue = "<CurrentValue>$($CurrentValues.$fieldName)</CurrentValue>"
                                    $EventValue += "<DesiredValue>$($DesiredValues.$fieldName)</DesiredValue>"
                                    $DriftedParameters.Add($fieldName, $EventValue)
                                    $returnValue = $false
                                }
                            }
                            "Single"
                            {
                                if (($DesiredValues.$fieldName -eq 0) `
                                        -and ($null -eq $CurrentValues.$fieldName))
                                {
                                }
                                else
                                {
                                    Write-Verbose -Message ("Single value for property " + `
                                            "$fieldName does not match. " + `
                                            "Current state is " + `
                                            "'$($CurrentValues.$fieldName)' " + `
                                            "and desired state is " + `
                                            "'$($DesiredValues.$fieldName)'")
                                    $EventValue = "<CurrentValue>$($CurrentValues.$fieldName)</CurrentValue>"
                                    $EventValue += "<DesiredValue>$($DesiredValues.$fieldName)</DesiredValue>"
                                    $DriftedParameters.Add($fieldName, $EventValue)
                                    $returnValue = $false
                                }
                            }
                            "Hashtable"
                            {
                                Write-Verbose -Message "The current property {$fieldName} is a Hashtable"
                                $AllDesiredValuesAsArray = @()
                                foreach ($item in $DesiredValues.$fieldName)
                                {
                                    $currentEntry = @{ }
                                    foreach ($key in $item.Keys)
                                    {
                                        $value = $item.$key
                                        if ([System.String]::IsNullOrEmpty($value))
                                        {
                                            $value = $null
                                        }
                                        $currentEntry.Add($key, $value)
                                    }
                                    $AllDesiredValuesAsArray += [PSCustomObject]$currentEntry
                                }

                                if ($null -ne $DesiredValues.$fieldName -and $null -eq $CurrentValues.$fieldName)
                                {
                                    $returnValue = $false
                                }
                                else
                                {
                                    $AllCurrentValuesAsArray = @()
                                    foreach ($item in $CurrentValues.$fieldName)
                                    {
                                        $currentEntry = @{ }
                                        foreach ($key in $item.Keys)
                                        {
                                            $value = $item.$key
                                            if ([System.String]::IsNullOrEmpty($value))
                                            {
                                                $value = $null
                                            }
                                            $currentEntry.Add($key, $value)
                                        }
                                        $AllCurrentValuesAsArray += [PSCustomObject]$currentEntry
                                    }
                                    $arrayCompare = Compare-PSCustomObjectArrays -CurrentValues $AllCurrentValuesAsArray `
                                    -DesiredValues $AllCurrentValuesAsArray
                                    if ($null -ne $arrayCompare)
                                    {
                                        foreach ($item in $arrayCompare)
                                        {
                                            $EventValue = "<CurrentValue>[$($item.PropertyName)]$($item.CurrentValue)</CurrentValue>"
                                            $EventValue += "<DesiredValue>[$($item.PropertyName)]$($item.DesiredValue)</DesiredValue>"
                                            $DriftedParameters.Add($fieldName, $EventValue)
                                        }
                                        $returnValue = $false
                                    }
                                }
                            }
                            default
                            {
                                Write-Verbose -Message ("Unable to compare property $fieldName " + `
                                        "as the type ($($desiredType.Name)) is " + `
                                        "not handled by the " + `
                                        "Test-Microsoft365DSCParameterState cmdlet")
                                $EventValue = "<CurrentValue>$($CurrentValues.$fieldName)</CurrentValue>"
                                $EventValue += "<DesiredValue>$($DesiredValues.$fieldName)</DesiredValue>"
                                $DriftedParameters.Add($fieldName, $EventValue)
                                $returnValue = $false
                            }
                        }
                    }
                }
            }
        }
    }

    if ($returnValue -eq $false)
    {
        $EventMessage = "<M365DSCEvent>`r`n"
        $EventMessage += "    <ConfigurationDrift Source=`"$Source`">`r`n"

        $EventMessage += "        <ParametersNotInDesiredState>`r`n"
        $driftedValue = ''
        foreach ($key in $DriftedParameters.Keys)
        {
            Write-Verbose -Message "Detected Drifted Parameter [$Source]$key"
            #region Telemetry
            $driftedData = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
            $driftedData.Add("Event", "DriftedParameter")
            $driftedData.Add("Parameter", "[$Source]$key")
            Add-M365DSCTelemetryEvent -Type "DriftInfo" -Data $driftedData
            #endregion
            $EventMessage += "            <Param Name=`"$key`">" + $DriftedParameters.$key + "</Param>`r`n"
        }
        #region Telemetry
        $data.Add("Event", "ConfigurationDrift")
        #endregion
        $EventMessage += "        </ParametersNotInDesiredState>`r`n"
        $EventMessage += "    </ConfigurationDrift>`r`n"
        $EventMessage += "    <DesiredValues>`r`n"
        foreach ($Key in $DesiredValues.Keys)
        {
            $Value = $DesiredValues.$Key
            if ([System.String]::IsNullOrEmpty($Value))
            {
                $Value = "`$null"
            }
            $EventMessage += "        <Param Name =`"$key`">$Value</Param>`r`n"
        }
        $EventMessage += "    }"
        $EventMessage += "    </DesiredValues>`r`n"
        $EventMessage += "</M365DSCEvent>"

        Add-M365DSCEvent -Message $EventMessage -EntryType 'Error' -EventID 1 -Source $Source
    }
    #region Telemetry
    Add-M365DSCTelemetryEvent -Data $data
    #endregion
    return $returnValue
}

<# This is the main Microsoft365DSC.Reverse function that extracts the DSC configuration from an existing
   Office 365 Tenant. #>
function Export-M365DSCConfiguration
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [Switch]
        $Quiet,

        [Parameter()]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $FileName,

        [Parameter()]
        [System.String]
        $ConfigurationName,

        [Parameter()]
        [System.String[]]
        $ComponentsToExtract,

        [Parameter()]
        [ValidateSet('AAD', 'SPO', 'EXO', 'SC', 'OD', 'O365', 'PP', 'TEAMS')]
        [System.String[]]
        $Workloads,

        [Parameter()]
        [ValidateSet('Lite', 'Default', 'Full')]
        [System.String]
        $Mode = 'Default',

        [Parameter()]
        [ValidateRange(1, 100)]
        $MaxProcesses,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.string]
        $ApplicationSecret,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )
    $InformationPreference = 'SilentlyContinue'
    $WarningPreference = 'SilentlyContinue'

    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Event", "Extraction")
    $data.Add("Quiet", $Quiet)
    $data.Add("Path", [System.String]::IsNullOrEmpty($Path))
    $data.Add("FileName", $null -ne [System.String]::IsNullOrEmpty($FileName))
    $data.Add("ComponentsToExtract", $null -ne $ComponentsToExtract)
    $data.Add("Workloads", $null -ne $Workloads)
    $data.Add("MaxProcesses", $null -ne $MaxProcesses)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    if ($null -eq $MaxProcesses)
    {
        $MaxProcesses = 16
    }

    if (-not $Quiet)
    {
        Show-M365DSCGUI -Path $Path
    }
    else
    {
        if ($null -ne $Workloads)
        {
            Start-M365DSCConfigurationExtract -GlobalAdminAccount $GlobalAdminAccount `
                -Workloads $Workloads `
                -Path $Path -FileName $FileName `
                -MaxProcesses $MaxProcesses `
                -ConfigurationName $ConfigurationName `
                -ApplicationId $ApplicationId `
                -TenantId $TenantId `
                -ApplicationSecret $ApplicationSecret `
                -CertificateThumbprint $CertificateThumbprint `
                -Quiet
        }
        elseif ($null -ne $ComponentsToExtract)
        {
            Start-M365DSCConfigurationExtract -GlobalAdminAccount $GlobalAdminAccount `
                -ComponentsToExtract $ComponentsToExtract `
                -Path $Path -FileName $FileName `
                -MaxProcesses $MaxProcesses `
                -ConfigurationName $ConfigurationName `
                -ApplicationId $ApplicationId `
                -TenantId $TenantId `
                -ApplicationSecret $ApplicationSecret `
                -CertificateThumbprint $CertificateThumbprint `
                -Quiet
        }
        elseif ($null -ne $Mode)
        {
            Start-M365DSCConfigurationExtract -GlobalAdminAccount $GlobalAdminAccount `
                -Mode $Mode `
                -Path $Path -FileName $FileName `
                -MaxProcesses $MaxProcesses `
                -ConfigurationName $ConfigurationName `
                -ApplicationId $ApplicationId `
                -TenantId $TenantId `
                -ApplicationSecret $ApplicationSecret `
                -CertificateThumbprint $CertificateThumbprint `
                -Quiet
        }
        else
        {
            Start-M365DSCConfigurationExtract -GlobalAdminAccount $GlobalAdminAccount `
                -AllComponents `
                -Path $Path -FileName $FileName `
                -MaxProcesses $MaxProcesses `
                -ConfigurationName $ConfigurationName `
                -ApplicationId $ApplicationId `
                -TenantId $TenantId `
                -ApplicationSecret $ApplicationSecret `
                -CertificateThumbprint $CertificateThumbprint `
                -Quiet
        }
    }
}

function Get-M365DSCTenantDomain
{
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TenantId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $CertificateThumbprint
    )

    Test-MSCloudLogin -Platform AzureAD -ApplicationId $ApplicationId -TenantId $TenantId -CertificateThumbprint $CertificateThumbprint

    $tenantDetails = Get-AzureADTenantDetail
    $defaultDomain = $tenantDetails.VerifiedDomains | Where-Object -Filterscript {$_._Default}
    return $defaultDomain.Name
}

function Get-SPOAdministrationUrl
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        [switch]
        $UseMFA,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )
    if ($UseMFA)
    {
        $UseMFASwitch = @{UseMFA = $true }
    }
    else
    {
        $UseMFASwitch = @{ }
    }
    Write-Verbose -Message "Connection to Azure AD is required to automatically determine SharePoint Online admin URL..."
    Test-MSCloudLogin -Platform "AzureAD" -CloudCredential $GlobalAdminAccount | Out-Null
    Write-Verbose -Message "Getting SharePoint Online admin URL..."
    $defaultDomain = Get-AzureADDomain | Where-Object { ($_.Name -like "*.onmicrosoft.com" -or $_.Name -like "*.onmicrosoft.de") -and $_.IsInitial -eq $true } # We don't use IsDefault here because the default could be a custom domain

    if ($defaultDomain[0].Name -like '*.onmicrosoft.com*')
    {
        $global:tenantName = $defaultDomain[0].Name -replace ".onmicrosoft.com", ""
    }
    elseif ($defaultDomain[0].Name -like '*.onmicrosoft.de*')
    {
        $global:tenantName = $defaultDomain[0].Name -replace ".onmicrosoft.de", ""
    }
    $global:AdminUrl = "https://$global:tenantName-admin.sharepoint.com"
    Write-Verbose -Message "SharePoint Online admin URL is $global:AdminUrl"
    return $global:AdminUrl
}

function Split-ArrayByBatchSize
{
    [OutputType([System.Object[]])]
    Param(
        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $Array,

        [Parameter(Mandatory = $true)]
        [System.Uint32]
        $BatchSize
    )
    for ($i = 0; $i -lt $Array.Count; $i += $BatchSize)
    {
        $NewArray += , @($Array[$i..($i + ($BatchSize - 1))]);
    }
    return $NewArray
}

function Split-ArrayByParts
{
    [OutputType([System.Object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $Array,

        [Parameter(Mandatory = $true)]
        [System.Uint32]
        $Parts
    )

    if ($Parts)
    {
        $PartSize = [Math]::Ceiling($Array.Count / $Parts)
    }
    $outArray = New-Object 'System.Collections.Generic.List[PSObject]'

    for ($i = 1; $i -le $Parts; $i++)
    {
        $start = (($i - 1) * $PartSize)

        if ($start -lt $Array.Count)
        {
            $end = (($i) * $PartSize) - 1
            if ($end -ge $Array.count)
            {
                $end = $Array.count - 1
            }
            $outArray.Add(@($Array[$start..$end]))
        }
    }
    return , $outArray
}

function Invoke-M365DSCCommand
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ScriptBlock]
        $ScriptBlock,

        [Parameter()]
        [System.String]
        $InvokationPath,

        [Parameter()]
        [Object[]]
        $Arguments,

        [Parameter()]
        [System.UInt32]
        $Backoff = 2
    )

    $InformationPreference = 'SilentlyContinue'
    $WarningPreference = 'SilentlyContinue'
    $ErrorActionPreference = 'Stop'
    try
    {
        if (-not [System.String]::IsNullOrEmpty($InvokationPath))
        {
            $baseScript = "Import-Module '$InvokationPath\*.psm1' -Force;"
        }

        $invokeArgs = @{
            ScriptBlock = [ScriptBlock]::Create($baseScript + $ScriptBlock.ToString())
        }
        if ($null -ne $Arguments)
        {
            $invokeArgs.Add("ArgumentList", $Arguments)
        }
        return Invoke-Command @invokeArgs
    }
    catch
    {
        if ($_.Exception -like '*M365DSC - *')
        {
            Write-Warning $_.Exception
        }
        else
        {
            if ($Backoff -le 128)
            {
                $NewBackoff = $Backoff * 2
                Write-Warning "    * Throttling detected. Waiting for {$NewBackoff seconds}"
                Start-Sleep -Seconds $NewBackoff
                return Invoke-M365DSCCommand -ScriptBlock $ScriptBlock -Backoff $NewBackoff -Arguments $Arguments -InvokationPath $InvokationPath
            }
            else
            {
                Write-Warning $_
            }
        }
    }
}

function Get-SPOUserProfilePropertyInstance
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $Key,

        [Parameter()]
        [System.String]
        $Value
    )

    $result = [PSCustomObject]@{
        Key   = $Key
        Value = $Value
    }

    return $result
}

function ConvertTo-SPOUserProfilePropertyInstanceString
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $Properties
    )

    $results = @()
    foreach ($property in $Properties)
    {
        $content = "             MSFT_SPOUserProfilePropertyInstance`r`n            {`r`n"
        $content += "                Key   = `"$($property.Key)`"`r`n"
        $content += "                Value = `"$($property.Value)`"`r`n"
        $content += "            }`r`n"
        $results += $content
    }
    return $results
}

function Install-M365DSCDevBranch
{
    [CmdletBinding()]
    param()
    #region Download and Extract Dev branch's ZIP
    $url         = "https://github.com/microsoft/Microsoft365DSC/archive/Dev.zip"
    $output      = "$($env:Temp)\dev.zip"
    $extractPath = $env:Temp + "\O365Dev"

    Invoke-WebRequest -Uri $url -OutFile $output

    Expand-Archive $output -DestinationPath $extractPath -Force
    #endregion

    #region Install All Dependencies
    $manifest = Import-PowerShellDataFile "$extractPath\Microsoft365DSC-Dev\Modules\Microsoft365DSC\Microsoft365DSC.psd1"
    $dependencies = $manifest.RequiredModules
    foreach ($dependency in $dependencies)
    {
        Install-Module $dependency.ModuleName -RequiredVersion $dependency.RequiredVersion -Force
        Import-Module $dependency.ModuleName -Force
    }
    #endregion

    #region Install M365DSC
    $defaultPath = 'C:\Program Files\WindowsPowerShell\Modules\Microsoft365DSC\'
    $currentVersionPath = $defaultPath + $($manifest.ModuleVersion)
    if (Test-Path $currentVersionPath)
    {
        Remove-Item $currentVersionPath -Recurse -Confirm:$false
    }
    Copy-Item "$extractPath\Microsoft365DSC-Dev\Modules\Microsoft365DSC" -Destination $currentVersionPath -Recurse -Force
    #endregion
}

function Get-AllSPOPackages
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable[]])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )

    Test-MSCloudLogin -CloudCredential $GlobalAdminAccount `
        -Platform PnP

    $tenantAppCatalogUrl = Get-PnPTenantAppCatalogUrl

    Test-MSCloudLogin -ConnectionUrl $tenantAppCatalogUrl `
        -CloudCredential $GlobalAdminAccount `
        -Platform PnP

    $filesToDownload = @()

    if ($null -ne $tenantAppCatalogUrl)
    {
        $spfxFiles = Find-PnPFile -List "AppCatalog" -Match '*.sppkg'
        $appFiles = Find-PnPFile -List "AppCatalog" -Match '*.app'

        $allFiles = $spfxFiles + $appFiles

        foreach ($file in $allFiles)
        {
            $filesToDownload += @{Name = $file.Name; Site = $tenantAppCatalogUrl; Title = $file.Title}
        }
    }
    return $filesToDownload
}

function Remove-NullEntriesFromHashtable
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [System.COllections.HashTable]
        $Hash
    )

    $keysToRemove = @()
    foreach ($key in $Hash.Keys)
    {
        if ([System.String]::IsNullOrEmpty($Hash.$key))
        {
            $keysToRemove += $key
        }
    }

    foreach ($key in $keysToRemove)
    {
        $Hash.Remove($key) | Out-Null
    }

    return $Hash
}

function Assert-M365DSCTemplate
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [System.String]
        $TemplatePath,

        [Parameter()]
        [System.String]
        $TemplateName
    )
    $InformationPreference = 'SilentlyContinue'
    $WarningPreference = 'SilentlyContinue'

    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Event", "AssertTemplate")
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    if (([System.String]::IsNullOrEmpty($TemplatePath) -and [System.String]::IsNullOrEmpty($TemplateName)) -or
    (-not [System.String]::IsNullOrEmpty($TemplatePath) -and -not [System.String]::IsNullOrEmpty($TemplateName)))
    {
        throw "You need to one of either TemplatePath or TemplateName"
    }
    if (-not [System.String]::IsNullOrEmpty($TemplateName))
    {
        try
        {
            $TemplatePath = Join-Path -Path $env:Temp -ChildPath "$TemplateName.M365"
            $url = "https://office365dsc.blob.core.windows.net/office365dsc/Templates/$TemplateName.M365"
            Invoke-WebRequest -Uri $url -OutFile $TemplatePath
        }
        catch
        {
            throw $_
        }
    }
    if ((Test-Path -Path $TemplatePath) -and ($TemplatePath -like '*.m365' -or $TemplatePath -like '*.ps1'))
    {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($TemplatePath, [ref] $tokens, [ref] $errors)
        $configObject = $ast.FindAll( {$args[0] -is [System.Management.Automation.Language.ConfigurationDefinitionAST]}, $true)

        $configurationName = $configObject.InstanceName.ToString()
        $configContent = $configObject.Extent.ToString()

        $configDataString = "`$configData = @{ `
            AllNodes = @( `
                @{ `
                    NodeName                    = 'localhost' `
                    PSDscAllowPlainTextPassword = `$true; `
                    PSDscAllowDomainUser        = `$true; `
                } `
            ) `
        }"
        $configContent += "`r`n" + $configDataString + "`r`n"
        $configContent += "`$compileResults = " + $ConfigurationName + " -ConfigurationData `$ConfigData`r`n"
        $configContent += "`$testResults = Test-DSCConfiguration -ReferenceConfiguration `$compileResults.FullName`r`n"

        $configContent += "if (`$testResults.InDesiredState)`r`n"
        $configContent += "{`r`n"
        $configContent += "    Write-Host 'The template was validated against the environment. The tenant is in the Desired State.' -ForeGroundColor Green"
        $configContent += "}`r`n"
        $configContent += "elseif (-not `$testResults.InDesiredState)`r`n"
        $configContent += "{`r`n"
        $configContent += "    Write-Host 'The environment does not match the template. The following component(s) are not in the Desired State:' -Foreground Red`r`n"
        $configContent += "    foreach (`$component in `$testResults.ResourcesNotInDesiredState){Write-Host `"    -> `$(`$component.ResourceId)`" -Foreground Red}`r`n"
        $configContent += "}`r`n"

        $randomName = (New-GUID).ToString() + '.ps1'
        $tempScriptLocation = Join-Path -Path $env:Temp -ChildPath $randomName
        $configContent | Out-File $tempScriptLocation

        & $tempScriptLocation
    }
    elseif (-not (Test-Path $TemplatePath))
    {
        Write-Error "M365DSC Template Path {$TemplatePath} does not exist."
    }
    else
    {
        Write-Error "You need to specify a path to an Microsoft365DSC Template (*.m365 or *.ps1)"
    }
}
