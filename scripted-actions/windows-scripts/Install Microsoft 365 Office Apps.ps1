#description: Installs/Updates Office 365 Apps to newest version and disables Auto-Update. Recommended to run on desktop images.
#execution mode: IndividualWithRestart
#tags: Nerdio, Apps install
<# 
Notes:
This script will update Microsoft 365 apps on an Image VM without turning on automatic updates.
It downloads automatically downloads the latest version of ODT and uses it to update M35 Apps.

Please edit $ODTConfig if you use a non-standard deployment of Office 365 (i.e. leaving out powerpoint)
$ODTConfig is what ODT will use for configuration. 
see https://docs.microsoft.com/en-us/deployoffice/overview-office-deployment-tool 
and https://docs.microsoft.com/en-us/deployoffice/office-deployment-tool-configuration-options
for details on ODT configuration XML documentation.

To learn more about the process this script does, 
See https://docs.microsoft.com/en-us/azure/virtual-desktop/install-office-on-wvd-master-image 
#>

# Configure powershell logging
$SaveVerbosePreference = $VerbosePreference
$VerbosePreference = 'continue'
$VMTime = Get-Date
$LogTime = $VMTime.ToUniversalTime()
mkdir "$env:windir\Temp\NMWLogs\ScriptedActions\msoffice_sa" -Force
Start-Transcript -Path "$env:windir\Temp\NMWLogs\ScriptedActions\msoffice_sa\ps_log.txt" -Append -IncludeInvocationHeader
Write-Host "################# New Script Run #################"
Write-Host "Current time (UTC-0): $LogTime"

# create directory to store ODT and setup files
mkdir "$env:windir\Temp\odt_sa\raw" -Force

# Evergreen URL for the latest version of ODT
$SetupUrl = "https://officecdn.microsoft.com/pr/wsus/setup.exe"

# Local path to the ODT executable
$SetupFile = "$env:windir\Temp\odt_sa\raw\setup.exe"

# Download the Office Deployment Tool setup.exe
$ProgressPreference = 'SilentlyContinue'
$params = @{
    Uri             = $SetupUrl
    OutFile         = $SetupFile
    UseBasicParsing = $true
}
Invoke-WebRequest @params

# create a base config XML for ODT to use, this one has auto-update disabled
$ODTConfig = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="MonthlyEnterprise">
    <Product ID="O365ProPlusRetail">
      <Language ID="en-US" />
      <Language ID="MatchOS" />
      <ExcludeApp ID="Groove" />
      <ExcludeApp ID="Lync" />
      <ExcludeApp ID="OneDrive" />
      <ExcludeApp ID="Teams" />
    </Product>
  </Add>
  <RemoveMSI/>
  <Updates Enabled="FALSE"/>
  <Display Level="None" AcceptEULA="TRUE" />
  <Logging Level="Standard" Path="%temp%\WVDOfficeInstall" />
  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE"/>
  <Property Name="SharedComputerLicensing" Value="1"/>
</Configuration>
"@ 
$ODTConfig | Out-File -FilePath "$env:windir\Temp\odt_sa\raw\odtconfig.xml"

# execute odt.exe using the newly created odtconfig.xml. This updates/installs office (takes a while)
$params = @{
    FilePath     = $SetupFile
    ArgumentList = "/configure $env:windir\Temp\odt_sa\raw\odtconfig.xml"
    Wait         = $true
}
Start-Process @params

# End Logging
Stop-Transcript
$VerbosePreference = $SaveVerbosePreference
