$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Verbose -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

# DSC resource to manage SQL database compatibility levels

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [parameter(Mandatory = $true)]
        [ValidateSet("130","120","110","100","90","80")]
        [System.String]
        $Compatibility,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        # Check database exists
        if(!($SQLDatabase = $SQL.Databases[$Database]))
        {
            throw New-TerminatingError -ErrorType NoDatabase -FormatArgs @($Database,$SQLServer,$SQLInstanceName) -ErrorCategory InvalidResult
        }

        $Compatibility = [int]($SQLDatabase.CompatibilityLevel.ToString().TrimStart('Version'))
    }
    else
    {
        $Compatibility = $null
    }

    $returnValue = @{
        Database = $Database
        Compatibility = $Compatibility
        SQLServer = $SQLServer
        SQLInstanceName = $SQLInstanceName
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [parameter(Mandatory = $true)]
        [ValidateSet("130","120","110","100","90","80")]
        [System.String]
        $Compatibility,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        $SQLDatabase = $SQL.Databases[$Database]
        $Version = "Version" + $Compatibility
        $SQLDatabase.CompatibilityLevel = [Microsoft.SqlServer.Management.Smo.CompatibilityLevel]"$Version"
        $SQLDatabase.Alter()
    }

    if(!(Test-TargetResource @PSBoundParameters))
    {
        throw New-TerminatingError -ErrorType TestFailedAfterSet -ErrorCategory InvalidResult
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [parameter(Mandatory = $true)]
        [ValidateSet("130","120","110","100","90","80")]
        [System.String]
        $Compatibility,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )

    $result = ((Get-TargetResource @PSBoundParameters).Compatibility -eq $Compatibility)

    $result
}


Export-ModuleMember -Function *-TargetResource
