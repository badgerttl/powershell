<#
.SYNOPSIS
  Guided install of Splunk Universal Forwarder. Allows for Active Directory lookup, batch input, 
  or local install
.DESCRIPTION
  This is a guided install. you will have the option of looking up a machine in Active Directory, 
  supply a text file or csv with a list of machines, or install locally.
.PARAMETER <Parameter_Name>
  NONE
.INPUTS
  This is a guided install. you will have the option of looking up a machine in Active Directory, 
  supply a text file or csv with a list of machines, or install locally. 
  
  ACTIVE DIRECTORY LOOKUP:
	You can use the AD lookup to deploy to multiple machines by wildcarding the search. Verify your
	list of by running "Get-ADComputer -filter {Name -like $adfilter} |Select DNSHostName" where $adfilter 
	is your search parameter
  LIST OF HOSTS:
	You will need to supply a text file or CSV contianing a list of hosts you wish to deploy to.
  LOCAL INSTALL:
	Will install the universal forwarder locally.
  DEPLOYMENT SERVER:
	You will be asked to provide a deployment server (e.g. 192.168.1.33:8089).  If none is supplied 
	no deployment server 
	will be configured for you.
  INSTALL LOCATION:
	You will be prompted for an install location. If none is supplied it will install in 
	C:\Program Files\Splunkuniversalforwarder.
	
.OUTPUTS
  Outputs an MSI log file to C:\temp\splunk_install
.NOTES
  Version:        1.0.0
  Author:         Jay Morris
  Creation Date:  2/4/2018
  Purpose/Change: Initial script development
  
#>

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$time = Get-Date -f yyyyMMddhhmm
$uf_uri = "https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=windows&version=7.0.2&product=universalforwarder&filename=splunkforwarder-7.0.2-03bbabbd5c0f-x64-release.msi&wget=true"
$launchsplunk = 1

#-----------------------------------------------------------[Functions]------------------------------------------------------------
function Get-System
{
     param (
           [string]$Title = 'Get System List'
     )
     cls
     Write-Host "================ $Title ================"
     
     Write-Host "1: Press '1' to search Active Directory for host."
     Write-Host "2: Press '2' to Provide a list of hosts via csv."
     Write-Host "3: Press '3' to install locally."
     Write-Host "Q: Press 'Q' to quit."
}

#function System-Type
#{
#     param (
#           [string]$Title = 'Get System Type'
#     )
#     cls
#     Write-Host "================ $Title ================"
#     
#     Write-Host "1: Press '1' for PCI systems."
#     Write-Host "2: Press '2' for Store systems."
#     Write-Host "Q: Press 'Q' to quit."
#}

function remote
{
	param([string[]]$systems,[string[]]$deploy, [string[]]$location)
	Write-Host "Installing Universal Forwarder... 
	Deployment Server = $deploy
	Install location = $location
	Install log can be found here > C:\temp\install_splunk.log"
	foreach ($system in $systems){
		try {
			invoke-command -ComputerName $system -ErrorVariable error -ErrorAction SilentlyContinue -ScriptBlock `
			{invoke-webrequest -uri $uf_uri -OutFile "C:\temp\splunkforwarder.msi"}
			invoke-command -ComputerName $system -ErrorVariable error -ErrorAction SilentlyContinue -ScriptBlock `
			{cmd.exe /c msiexec.exe /i C:\temp\splunkforwarder.msi SERVICESTARTTYPE=auto DEPLOYMENT_SERVER=$deploy `
			$install LAUNCHSPLUNK=$launchsplunk AGREETOLICENSE=yes /quiet /l*v C:\temp\install_splunk.log}
			invoke-command -ComputerName $system -ErrorVariable error -ErrorAction SilentlyContinue -ScriptBlock `
			{cmd.exe /c del C:\temp\splunkforwarder.msi}
		}
		catch {
			write-host "Install Failed`t$system"
			Write-Output "$error" >> C:\temp\splunk_error$time.txt
		}
	}
}

function local
{
	param([string[]]$deploy, [string[]]$location)
	Write-Host "Installing Universal Forwarder... "
	Write-Host "`tDeployment Server = $deploy" -ForegroundColor Green
	Write-Host "`tInstall location = $location" -ForegroundColor Green
	Write-Host "`tInstall log can be found here > C:\temp\install_splunk.log" -ForegroundColor Green
	try {
		$install = "INSTALLDIR=`"$location`""
		#invoke-webrequest -uri $uf_uri -OutFile "C:\temp\splunkforwarder.msi"
		write-host $log
		cmd.exe /c msiexec.exe /i C:\temp\splunkforwarder.msi SERVICESTARTTYPE=auto DEPLOYMENT_SERVER=$deploy $install `
		LAUNCHSPLUNK=$launchsplunk AGREETOLICENSE=yes /quiet /l*v C:\temp\install_splunk.log
		#cmd.exe /c del C:\temp\splunkforwarder.msi
	}
	catch {
		write-host "Install Failed`t$system"
	}
}	

#-----------------------------------------------------------[Execution]------------------------------------------------------------

do
{
     Get-System
     $lookup = Read-Host "Please make a selection"
     switch ($lookup)
     {
           '1' {
                cls
                #'Search Active Diretory for host'
           } '2' {
                cls
                #'Provide a list of hosts via csv'
           } '3' {
                cls
                #'Install Local'
           }'q' {
                return
           }
     }
	 write-host $lookup
}
until ($lookup -eq 'q' -or $lookup -eq '1' -or $lookup -eq '2' -or $lookup -eq '3')

If ($lookup -eq 1) {
	cls
	$adfilter = read-host "Enter AD Filter"
	$remotehosts = Get-ADComputer -filter {Name -like $adfilter} |Select DNSHostName
	$deploy = read-host "Enter Deployment Server"
	remote -systems $remotehosts.DNSHostName -deploy $deploy
	}
ElseIf ($lookup -eq 2){
	cls
	$UserDefinedList = read-host "Enter Computer List (e.g. C:\temp\servers.csv)"
	$deploy = read-host "Enter Deployment Server (e.g. 192.168.1.33:8089)"
	$location = read-host "Where would you like to install? (e.g c:\Program Files\SplunkUniversalForwarder)"
	$list = get-content $UserDefinedList
	remote -systems $list -deploy $deploy -location $location
	}
ElseIF ($lookup -eq 3){
	cls
	$deploy = read-host "Enter Deployment Server (e.g. 192.168.1.50:8089)"
	$location = read-host "Where would you like to install? (e.g c:\Program Files\SplunkUniversalForwarder)"
	if ($location -eq ""){
		$location="c:\Program Files\SplunkUniversalForwarder"}
	cls
	local -deploy $deploy -location $location
	}


