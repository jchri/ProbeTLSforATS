param (
    [Parameter(Mandatory=$true)][string]$URI
       )
<#
MIT License

Copyright (c) 2018 jchri

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>
#************************************************
# ProbeTLSforATS.ps1
# Version 1.0
# Date: 10-25-2018
# Author: Joel Christiansen [MSFT] 
# Description: This script will make SSl and TLS connections to the specified URI and reflect back the details of the connection. 
# The purpose of the script is to quickly identify if the TLS 1.2 connection is successful and 
# if the Hash Algorithm and Cipher Algorithm meet the requirements for Apple ATS.
#************************************************

#Many Thanks to the work of Chris Duck. His script "Checking SSL and TLS Versions with Powershell" '
#was very helpful in creating this script. It is available here: 
#http://blog.whatsupduck.net/2014/10/checking-ssl-and-tls-versions-with-powershell.html

#Usage:      .\ProbeTSLforATS.ps1 -URI <webserviceFQDN>

#Example     .\ProbeTSLforATS.ps1 -URI www.bing.com

#Initialize variables/defaults
[System.Collections.ArrayList]$TestTheseProtocols = @{}
$NullCert = $null
$CheckCertificateRevocation = $false
$SupportedProtocol = "Tls12"
$SupportedHashAlgorithms = @("Sha2", "Sha256")
$SupportedCipherAlgorithms = @("Aes256", "Aes128")
[System.Collections.ArrayList]$AllProtos=@("Ssl1", "Ssl2", "Ssl3","Tls","Tls11","Tls12") 
$AllProtosTable=@{"Ssl1"="SSL 1.0"; "Ssl2"="SSL 2.0";"Ssl3"="SSL 3.0";"Tls"="TLS 1.0";"Tls11"="TLS 1.1";"Tls12"="TLS 1.2"}

#Define output file
$URIString = $URI.Replace(".","_")
$OutputFile = $Pwd.path + "\AppleATSCompatTests-" + $URIString + "-" + (get-date -f MM-dd-yyyy-hh-mm-ss) + ".txt"
Get-Date | Out-File $OutputFile 
"Testing endpoint service URI: $URI " | Out-File $OutputFile  -Append
"TLS Endpoint Test for Apple Application Transport Security (ATS) Compatibility" | Out-File $OutputFile -Append
"`n" | Out-File $OutputFile -Append


#Get protocols supported by the local machine
$LocalProtocols = @([System.Security.Authentication.SslProtocols] | Get-member -static -MemberType Property) | ?{$_.Name -notin @("Default","None")} | %{$_.Name}
$LocalProtos = [string]::Join(" ", $LocalProtocols)

#Create output PSObject
$UnsupportedProtocolsPSO = New-Object PSObject
#Make sure that we only probe with the local machine's supported protocols
for($i=0;$i -lt $AllProtos.count; $i++)
{
   if ($LocalProtocols -inotcontains $AllProtos[$i])
    {
      $ProtocolName = $AllProtosTable.($Allprotos[$i])
      Add-member -InputObject $UnsupportedProtocolsPSO -MemberType NoteProperty -Name $ProtocolName -Value "Skipping test. The local client machine does not support the protocol."
    }
        else
    {
       $NoPrint= $TestTheseProtocols.Add($AllProtos[$i]) 
    }
}

#Create output PSObject
$ResultsPSO = New-Object PSObject

#Set up the connection
$ConnectionParams=@{URI=$URI; Port='443'; KeyLength=$null;CipherSuite=$null}
Foreach($protocol in $TestTheseProtocols)
    {
        $ProtocolName = $AllProtosTable.($Protocol)
		
		If($protocol -ieq $SupportedProtocol)
			{Add-member -InputObject $ResultsPSO -MemberType NoteProperty -Name "$ProtocolName - Supported ATS Protocol"  -Value "$ProtocolName IS supported by ATS"}
		Else
			{Add-member -InputObject $ResultsPSO -MemberType NoteProperty -Name "$ProtocolName - Unsupported ATS Protocol"  -Value "$ProtocolName Is NOT supported by ATS"}
		
        Try
        {
        #Create Socket
        $ThisSocket=New-Object System.Net.Sockets.Socket([System.Net.Sockets.SocketType]::Stream, [System.Net.Sockets.ProtocolType]::Tcp)
        $ThisSocket.Connect($Uri,$ConnectionParams.Port)
        #Create NetConnection
        $ThisNetConnection = New-Object System.Net.Sockets.NetworkStream($ThisSocket, $true)
        #Create SSLConnection
        $ThisSslConnection = New-Object System.Net.Security.SslStream($ThisNetConnection, $true)
        $ThisSslConnection.AuthenticateAsClient($Uri, $NullCert, $protocol, $CheckCertificateRevocation )
        $RemoteConnectionParams=[System.Security.Cryptography.X509Certificates.X509Certificate2]$ThisSslConnection.RemoteCertificate

            If($protocol -ieq $SupportedProtocol)
            {
                #Add-Member -InputObject $ResultsPSO -MemberType NoteProperty -Name "Testing ATS Compliant Protocol" -Value $ProtocolName
				$SigningHashString = $ThisSslConnection.HashAlgorithm.ToString()
                $SupportedConfig=$true
                #Verify that the SHA key size is at least 256
                If($SigningHashString.Contains("Sha"))
                {
                    $HashKeySize = $SigningHashString.Replace("Sha","")
                    If($HashKeySize -eq "2") {$SupportedConfig = $true}
                    ElseIf ($HashKeySize -ge 256) {$SupportedConfig=$true}
                    Else 
                    {
                        $SupportedConfig =$false
						Add-member -InputObject $ResultsPSO -MemberType NoteProperty -Name "$ProtocolName - Hash Key Size"  -Value "Hash Key Size is not compatible with ATS"
                    }                     
                }
                #Verify that a supported Cipher is being used    
                If ($SupportedCipherAlgorithms -inotcontains $ThisSslConnection.CipherAlgorithm)
                {
                    $SupportedConfig = $false
					Add-member -InputObject $ResultsPSO -MemberType NoteProperty -Name "$ProtocolName - Cipher Algorithm"  -Value "Cipher Algorithm is not compatible with ATS"
                }
             
                Add-member -InputObject $ResultsPSO -MemberType NoteProperty -Name "$ProtocolName - ATS test successful?" -Value $SupportedConfig
            }
			
        
        Add-member -InputObject $ResultsPSO -MemberType NoteProperty -Name $ProtocolName  -Value "**************************"
		Add-member -InputObject $ResultsPSO -MemberType NoteProperty -Name "$ProtocolName Test Result"  -Value "Connection Succeeded"
        Add-member -InputObject $ResultsPSO -MemberType NoteProperty -Name "$ProtocolName Cipher Algorithm" -Value $ThisSslConnection.CipherAlgorithm
        Add-member -InputObject $ResultsPSO -MemberType NoteProperty -Name "$ProtocolName Hash Algorithm" -Value $ThisSslConnection.HashAlgorithm
		}
        Catch
        {
            $Exception1 = $_.Exception
			Add-member -InputObject $ResultsPSO -MemberType NoteProperty -Name "$ProtocolName Test Result" -Value "Connection Failed"
            Add-member -InputObject $ResultsPSO -MemberType NoteProperty -Name "$ProtocolName Exception Message" -Value $Exception1.Message
            If($Exception1.InnerException.InnerException -ne $null)
            {
                Add-member -InputObject $ResultsPSO -MemberType NoteProperty -Name "$ProtocolName Exception Details" -Value $Exception1.InnerException.InnerException.Message
            }
        }
        Finally
        {
        #Tear Down Connection
		Add-member -InputObject $ResultsPSO -MemberType NoteProperty -Name "$ProtocolName Test Complete"  -Value "`n`n"
        If($ThisSocket.Connected) 
            {
		    $ThisSslConnection.Close()
            }
        }
    }
    $ReferalMessage= "Refer to the `"Requirements for Connecting Using Apple Application Transport Security (ATS)`" located at `nhttps://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html"
    
   #Screen Report
   "`nClient Side Unsupported Protocols" | Out-host
    "*********************************"  | Out-host 
    $UnsupportedProtocolsPSO | Out-host 
    "`nClient Side Supported Protocols"  | Out-host 
    "*********************************"  | Out-host 
	
    $ResultsPSO | Out-host 
    $ReferalMessage |  Out-host 

	#File Report
    "`nClient Side Unsupported Protocols"  | Out-File $OutputFile -Append
    "**********************************"  | Out-File $OutputFile -Append
    $UnsupportedProtocolsPSO | Out-File $OutputFile -Append
    "`nClient Side Supported Protocols"  | Out-File $OutputFile -Append
    "********************************"  | Out-File $OutputFile -Append
    $ResultsPSO | Out-File $OutputFile -Append
    $ReferalMessage | Out-File $OutputFile -Append
    "`n" |  Out-host 
    Write-host "Results are available at: `n$OutputFile `n" 

