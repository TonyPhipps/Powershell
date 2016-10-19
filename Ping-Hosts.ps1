####################################################################################
#.Synopsis 
#    Pings mulitple systems and provides status. 
#
#.Description 
#    Pings mulitple systems and provides status. Outputs unreachable hosts to .\Ping-Hosts_errors.txt
#
#.Parameter InputList  
#    Piped-in list of hosts/IP addresses
#
#.Example 
#    get-content .\hosts.txt | Ping-Hosts | export-csv pingable.csv
#
#.Example 
#    Get-Content .\hosts.txt | Ping-Hosts | Select-Object IPV4Address | export-csv pingable.csv
#
#.Example 
#    Get-Content .\hosts.txt | Ping-Hosts | Select-Object PSComputerName | export-csv pingable.csv
#
#.Notes 
#   Author: Anthony Phipps
#   Updated: 2016-10-19
#   LEGAL: PUBLIC DOMAIN.  SCRIPT PROVIDED "AS IS" WITH NO WARRANTIES OR GUARANTEES OF 
#          ANY KIND, INCLUDING BUT NOT LIMITED TO MERCHANTABILITY AND/OR FITNESS FOR
#          A PARTICULAR PURPOSE.  ALL RISKS OF DAMAGE REMAINS WITH THE USER, EVEN IF
#          THE AUTHOR, SUPPLIER OR DISTRIBUTOR HAS BEEN ADVISED OF THE POSSIBILITY OF
#          ANY SUCH DAMAGE.  IF YOUR STATE DOES NOT PERMIT THE COMPLETE LIMITATION OF
#          LIABILITY, THEN DELETE THIS FILE SINCE YOU ARE NOW PROHIBITED TO HAVE IT.
####################################################################################

Function Ping-Hosts() {
	[cmdletbinding()]


	param(
		[Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True, Position=0)]
		[Alias("iL")]
		[string]$INPUTLIST = "localhost"
	);


	PROCESS{

		TRY{
			foreach ($thisHost in $INPUTLIST){
				Test-Connection -Computername $thisHost -Count 1 -ErrorAction Stop;
			};
		}
		CATCH{
			Add-Content -Path .\Ping-Hosts_errors.txt -Value ("$thisHost");
		};
	};
};

