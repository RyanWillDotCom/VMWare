######################################################################################################
# Author: Ryan Will
#
# What is my Purpose?
#          You migrate Content Libraries.
#          This will assist in migrating the contents of an existing Content Library to a new one.
#
# Notes: Install the latest version of PowerCLI. The itemtype parameter for New-ContentLibraryItem
#        was introduced sometime after PowerCLI 12.0. It exists in at least v 12.3.0
#        This assumes the new Library already exists and is empty. Fill out the variables as req'd.
#        You may need to add ingore certificate options and user/password to connect-viserver if not
#        using pass-thru creds.
#       
#        Reasons it may not work: Both library names must be accurate. Make sure $FileDir exists. Make
#          sure it connects to vCenter. This has not been tested for anything other than ISO and OVF.
#
######################################################################################################

##-- Variables

# vCenters
$SrcvCenter = 'vcenter01.fqdn'  #- Source vCenter server IP or fqdn
$DstvCenter = 'vcenter02,fqdn'  #- Destination vCenter server IP or fqdn

# Source (old) Content Library
$SrcLibraryName = 'Source Library Name'

# Destination (new) content library
$DstLibraryName = 'Destination Library Name'

# Local dir to export the existing library. Be sure you have enough space. I recommend using local storage or a mapped drive for simplicity.
$FileDir = 'E:\contentlib'

# File Type to export and import from the Content Libs. Typically OVF or ISO
$itemtype = 'ovf'

##-- Script time

# Connect to vCenter server
Connect-VIServer -Server $SrcvCenter
Connect-VIServer -Server $DstvCenter

# Path\Type to store the exports
$FileDirType = $FileDir + '\' + $itemtype

# Get the content library itemtype list
$SrcContentList = Get-ContentLibraryItem -Server $SrcvCenter -contentlibrary $SrcLibraryName -ItemType $itemtype

# Download the content library specified itemtype
$SrcContentList | Export-ContentLibraryItem -Destination $FileDirType

# Get the list of files from the path that was specified
$FileList = get-childitem -path $FileDirType -File -recurse
$DirList = get-childitem -path $FileDirType -Directory

# Count the imports
$Count = $null
$i = $null
if($itemtype -eq "iso"){$Count = $FileList.Count}
if($itemtype -eq "ovf"){$Count = $DirList.Count}

# Import the exported files into the new Library
    ForEach ($dir in $DirList){
        $i++
        Write-Host "Importing $itemtype $i of $count"  
        "$dir"
        New-ContentLibraryItem -Server $DstvCenter -ContentLibrary $DstLibraryName -Name $dir.Name -Files $dir.GetFiles() -itemtype $itemtype
        if ($? -eq $true){
            "Import sucessful. Deleting directory"
            Remove-Item $dir.FullName -Recurse -Force
        }
    } 
