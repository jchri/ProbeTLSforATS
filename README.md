# ProbeTLSforATS
See MIT license in project root for license details.

Usage:	.\ProbeTlsforATS.ps1 -URI <Website URI>

Example:	.\ProbeTLSforATS.ps1 -URI www.bing.com

Many Thanks to the work of Chris Duck. His script "Checking SSL and TLS Versions with Powershell" was very helpful in creating this script. It is available here: http://blog.whatsupduck.net/2014/10/checking-ssl-and-tls-versions-with-powershell.html

This script is intended to assist administrators by checking connectivity to the supplied URL and reflecting back the details of the connection.

App Transport Security (ATS) is an Apple defined networking security feature enabled by default on Apple platforms. See more by searching the following document for "NSAppTransportSecurity"
https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html

Apple has defined the "Requirements for Connecting Using ATS" in the following section of the document: https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW57

Please keep in mind that this script does not exhaustively test all requirements for ATS. The script is limited to checking TLS version, symmetric cipher, and certificate hashing algorithm.

At the time of this writing, the requirements for connecting using ATS include the following:

 TLS version: TLS 1.2 
 
 Symmetric Cipher: AES-128 or AES-256
 
 Certificate Hashing Algorithm: SHA-2 (digest length >= 256)

The script must be run on a Windows 10 PC or Windows Server. The script will test all the enabled SSL/TLS algorithms enabled on the machine to provide basic connectivity details for all SSL/TLS versions enabled on the machine. However, the script is focused on the TLS 1.2 connection that is required by ATS.

When checking SSL/TLS versions < TLS 1.2, the script will reflect the current Symmetric Cipher and the Certificate Hashing Algorithm if the connection is successful.
When checking TLS 1.2, the script will reflect the settings, but will also highlight if the connection fails, or if the symmetric cipher or certificate hashing algorithm are incompatible with the ATS requirements.

