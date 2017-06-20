Function Get-StringHash {
<#
.SYNOPSIS
    This function returns the hash of a string 
    using the specified hashing algorithm.
.DESCRIPTION
    This function returns the hash of a string 
    using the specified hashing algorithm.

    The hash will be returned as a hexadecimal
    string.
.PARAMETER Strings
    This parameter should contain the strings 
    for which you need a hash value.
.PARAMETER Algorithm
    This parameter specifies the hashing algorithm
    you want to use.

    The allowed values are:
        * MD5
        * SHA1
        * SHA256
        * SHA384
        * SHA512
.PARAMETER ToLower
    This parameter has the hash converted to 
    lowercase.  The default is to output the hash
    in uppercase.
.INPUTS
    System.String
.OUTPUTS
    System.String
.LINK
    http://msdn.microsoft.com/en-us/library/system.security.cryptography.hashalgorithm.aspx
.EXAMPLE
    C:\ PS>Get-StringHash -Strings "hello" -Algorithm "MD5"
    5D41402ABC4B2A76B9719D911017C592
.EXAMPLE
    C:\ PS>Get-StringHash -Strings "hello" -Algorithm "SHA256"
    2CF24DBA5FB0A30E26E83B2AC5B9E29E1B161E5C1FA7425E73043362938B9824
.EXAMPLE
    C:\ PS>"hello","goodbye" | Get-StringHash -Algorithm "MD5"
    5D41402ABC4B2A76B9719D911017C592
    69FAAB6268350295550DE7D587BC323D
#>
[CmdletBinding()]
Param(
    [Parameter(
        Mandatory=$True,
        Position=0,
        ValueFromPipeline=$True
    )]
    [String[]]
    $Strings,

    [Parameter(
        Mandatory=$True,
        Position=1
    )]
    [ValidateSet("MD5","SHA1","SHA256","SHA384","SHA512")]
    [String]
    $Algorithm,

    [Switch]
    $ToLower
)
Begin {
    Switch ($Algorithm) {
        "MD5" {
            $hasher = New-Object -TypeName `
                "System.Security.Cryptography.MD5CryptoServiceProvider"
            Break
        }
        "SHA1" {
            $hasher = New-Object -TypeName `
                "System.Security.Cryptography.SHA1CryptoServiceProvider"
            Break
        }
        "SHA256" {
            $hasher = New-Object -TypeName `
                "System.Security.Cryptography.SHA256CryptoServiceProvider"
            Break
        }
        "SHA384" {
            $hasher = New-Object -TypeName `
                "System.Security.Cryptography.SHA384CryptoServiceProvider"
            Break
        }
        "SHA512" {
            $hasher = New-Object -TypeName `
                "System.Security.Cryptography.SHA512CryptoServiceProvider"
            Break
        }
    }
    $encoding = [System.Text.Encoding]::UTF8
}
Process {
    ForEach($String in $Strings){
        $hash = ($hasher.ComputeHash($encoding.GetBytes($String)) | % {
            "{0:X2}" -f $_
        }) -join ""

        If($ToLower){
            [String]$hash.toLower()
        } Else {
            [String]$hash
        }
    }
}
}

Function Add-MemberHash() {
####################################################################################
#.Synopsis 
#	Creates a new property containing the SHA512 hash of one or two concatenated properties.
#
#.Description 
#	Creates a new property containing the SHA512 hash of one or two concatenated properties.
#
#.Parameter InputList  
#	Any object
#
#.Parameter PropertyToHash  
#	The first (or only) property to hash.
#
#.Parameter PropertyToHash2
#	Optional. The second property to concatenante to the first property before hashing.
#
#.Example 
#	import-csv "C:\temp\dbexport.txt" | Add-MemberHash -PropertyToHash "edipi"
#
#.Example 
#	import-csv "C:\temp\dbexport.txt" | Add-MemberHash -PropertyToHash "edipi" -PropertyToHash2 "data1" | export-csv "readytosend.txt"
#
#
#.Notes 
# Updated: 2017-06-20
# LEGAL: Copyright (C) 2017  Anthony Phipps
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
####################################################################################

	[cmdletbinding()]


	PARAM(
		[Parameter(
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True)]
		$INPUT,
		
		[String]
		$PropertyToHash,
		
		[String]
		$PropertyToHash2
		
	);

	BEGIN{
		#change the error action temporarily
		$RecordErrorAction = $ErrorActionPreference
		$ErrorActionPreference = "SilentlyContinue"
	}
	
	PROCESS{
		$output = $INPUT;
		
		$output | Add-Member NoteProperty Sha512Hash (Get-StringHash ($output.$PropertyToHash + $output.$PropertyToHash2) -Algorithm sha512);
		
		Write-Output $output;
		$output.PsObject.Members.Remove('*');
	};
	
	END{
		#restore the error action
		$ErrorActionPreference = $RecordErrorAction
	}
};

