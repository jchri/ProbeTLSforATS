# ProbeTLSforATS
<#
 Disclaimer: The sample scripts are not supported under any Microsoft standard support program or service. 
 The sample scripts are provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties 
 including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. 
 The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.
#>

Usage:   .\ProbeTlsforATS.ps1 -URI <Website URI>
Example: .\ProbeTLSforATS.ps1 -URI www.bing.com

Many Thanks to the work of Chris Duck. His script "Checking SSL and TLS Versions with Powershell" was very helpful in creating this script. It is available here: http://blog.whatsupduck.net/2014/10/checking-ssl-and-tls-versions-with-powershell.html

This script is intended to assist administrators by checking connectivity to the supplied URL and reflecting back the details of the connection.

App Transport Security (ATS) is an Apple defined networking security feature enabled by default on Apple platforms. See more by searching the following document for "NSAppTransportSecurity"
https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html

Apple has defined the "Requirements for Connecting Using ATS" in the following section of the document: https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW57

Please keep in mind that this script does not exhaustively test all requirements for ATS. The script is limited to checking TLS version, symmetric cipher, and certificate hashing algorithm.

At the time of this writing, the requirements for connecting using ATS include the following
TLS version: TLS 1.2 
Symmetric Cipher: AES-128 or AES-256
Certificate Hashing Algorithm: SHA-2 (digest length >= 256)

The script must be run on a Windows 10 PC or Windows Server. The script will test all the enabled SSL/TLS algorithms enabled on the machine to provide basic connectivity details for all SSL/TLS versions enabled on the machine. However, the script is focused on the TLS 1.2 connection that is required by ATS.

When checking TLS 1.2, the script will also reflect the current Symmetric Cipher and the Certificate Hashing Algorithm. 

Usage:   .\ProbeTlsforATS.ps1 -URI <Website URI>
Example: .\ProbeTLSforATS.ps1 -URI www.bing.com
  
Sample Output:
++++++++++++++++++++++++++++++++++++++++++++
+PS C:\> .\ProbeTLSforATS.ps1 -Uri www.bing.com
+
+Testing SSL and TLS protocols...
+
+Client Side Unsupported Protocols
+*********************
+
+SSL 1.0
+-------
+Skipping test. The local client machine does not support the protocol.
+
+
+
+Client Side Supported Protocol Test Results
+*********************
+
+
+SSL 2.0 Test Result             : Connection Failed
+SSL 2.0 Exception Message       : Exception calling "AuthenticateAsClient" with "4" argument(s): "The client and
+                                  server cannot communicate, because they do not possess a common algorithm"
+SSL 3.0 Test Result             : Connection Failed
+SSL 3.0 Exception Message       : Exception calling "AuthenticateAsClient" with "4" argument(s): "Unable to read data
+                                  from the transport connection: An existing connection was forcibly closed by the
+                                  remote host."
+SSL 3.0 Exception Details       : An existing connection was forcibly closed by the remote host
+TLS 1.0 Test Result             : Connection Succeeded
+TLS 1.0 Cipher Algorithm        : Aes256
+TLS 1.0 Hash Algorithm          : Sha1
+TLS 1.1 Test Result             : Connection Succeeded
+TLS 1.1 Cipher Algorithm        : Aes256
+TLS 1.1 Hash Algorithm          : Sha1
+
+Testing ATS Compliant Protocol : TLS 1.2
+
+TLS 1.2 Algorithms support ATS : True
+TLS 1.2 Test Result             : Connection Succeeded
+TLS 1.2 Cipher Algorithm        : Aes128
+TLS 1.2 Hash Algorithm          : Sha256
+
+
+
+Refer to the "Requirements for Connecting Using Apple Application Transport Security (ATS)" located at
+https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html
++++++++++++++++++++++++++++++++++++++++++++

