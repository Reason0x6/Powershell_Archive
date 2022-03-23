Write-Host
Write-Host


# Variables, States, Objects & Flags Breakdown
#####
# Variable: $name -> The Username given by the user, used to find the folder to expand
# Variable: $folderlocation -> the full link to the main profiles folder
# Variable: $flag -> Used to show an errored state thatis not given by a run time error
# Variable: $dest -> The folder allocated to the given user
# Variable: $srcpath -> the link to the current virtual drive file, made from $folderlocation, $dest & $name
# Variable: $newpath -> the link to the new virtual drive, also made from $folderlocation, $dest & $name
# Object:   $userobject -> the object used to allocated the $name to the $dest folder permissions
# Object:   $acl -> The object that houses the permissions for $dest & the Drive File
# Object:   $AccessRule -> The object that holds the new access rule for the $dest folder (enables inheritance as well)
# Function: FileSystemAccessRule -> Parameters = Identity, fileSystemRights, type
            #File Sytem Rights found @ https://docs.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights?view=net-5.0
#####

########
# INITAL VARIABLES
########
$folderLocation = "\\<<Domain>>\dfsroot\FSLogixProfile"
$OK = 0
$MAX = 0
$ADD = 0
$users = @()
$date = Get-Date -format "yyyy-MM-ddTHH-mm"
$log = "c:\Support\FSLogix_logs\$date.log"
New-Item -ItemType File -Path $log


########
# functions 
#########
function log{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $Line
    )
    $inlinedate = get-date
    "($inlinedate) $line" >> $log

}



function Expand-User {
   

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $Username,

        [Parameter(Mandatory)]
        $FileLocation
    )



    $name = $Username
    $folderLocation = $FileLocation

    $dest = Get-ChildItem "$folderLocation" -Filter "*$name*" -Name
    Write-Host
             
   
    # Check only one folder is returned
    if($dest.Count -ne '1'){
        Write-Host "!! ERROR - More than one directy found for $name" -ForegroundColor red
        log -Line "$name not expanded due to more than one directy found"
        return "$name not expanded"
    }

    # Shows User Linked to input username
    $data = Get-ADUser -Identity $name -Properties * ;
    # Check only one folder is returned
    if($data.Count -ne '1'){
    Write-Host
        Write-Host "!! ERROR - More than one AD User found for $name" -ForegroundColor red
        log -Line "$name not expanded due to more than one AD User found"
        return "$name not expanded"
    }

    $tests = Get-ChildItem -Path "$folderLocation\$dest\"
    if($tests.count -ne 1){
        Write-Host
        Write-Host "!! ERROR - VDI In Use" -ForegroundColor red
        log -Line "$name not expanded as VDI Now in use"
        return "$name not expanded"
    }
    
    # Host migration script from FSLogix folder
    Write-Host "Migrating VHD of $name, This may take some time" -foregroundcolor green

    #Setting Paths to ensure latest variables are used
    $longPath = "$folderLocation\$dest\Profile_$name.VHDX"
    $newpath = "$folderLocation\$dest\Profile_$name-New.VHDX"

    $check1 = Test-Path $longPath -PathType Leaf;
    
    #Tests that file can be seen
    if($check1 -ne $true){
        write-host "!! Error - path for $name Cannot be found" -foregroundcolor red
        log -Line "$name not expanded due to error with path"
        return "$name not expanded"

    }

    # Try block to catch run time errors that may corrupt files
   try{
   $out = cmd /c "`"C:\Program Files\FSLogix\Apps\frx.exe`" migrate-vhd -src=`"$longPath`" -dest=`"$newpath`" -size-mbs=6296 -dynamic 1"
      $out
      if($out -like "*Error*"){
          if($out -like ("*Exit code: 9*")){
             Write-Host "Exit Code 9 Is accepted as a pass" -foregroundcolor Green
            log -Line "$name Expanded successful with exit code 9"
           }else{
                Write-host "!! ERROR - Cannot expand Storage, please refere to manual process"  -foregroundcolor red
                log -Line "$name Expansion errored during migration"
                return "$name not expanded"
           }
      }else{
             Write-Host "Migration Succeeded" -foregroundcolor Green
             log -Line "$name Migration successful with exit code 1"
      }

      }catch{
        # Throws Runtime Error & Stops Removal & Rename Proccess at Time of Error
        Write-host "!! ERROR - Cannot expand Storage for $user"  -foregroundcolor red
        log -Line "$name Errored during migration"
        return "$name not expanded"
    }
     
    Remove-Item   "$folderLocation\$dest\Profile_$name.VHDX" | Out-Null
    
   

    Start-Sleep(2)
    # Rename new file
    Write-Host "Renaming New VHD" -foregroundcolor green

    $check2 = Test-Path $newpath -PathType Leaf;
     #Tests that file can be seen
    if($check2 -ne $true){
        write-host "!! Error - New File Cannot be updated for $name, Please Rename & Update Permission Manually" -foregroundcolor red
        log -Line "$name Migrated but unable to rename"
        return "$name expanded but not renamed. No permissions added."
    }

    Rename-Item "$newpath" "Profile_$name.VHDX" | Out-Null
    Start-Sleep(2)
    
    # Setting File Owner to input username
    $acl = Get-Acl $longPath 
    $userobject = New-Object System.Security.Principal.Ntaccount("<<Company>>\$name")
    $acl.SetOwner($userobject)
    $acl | Set-Acl $longPath
  
    
    # Setting Full Access Permission To Folder & File
    $acl = Get-Acl "$folderLocation\$dest"
    $AccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList "<<Company>>\$name","FullControl","ContainerInherit , ObjectInherit","None", "Allow"
    $acl.SetAccessRule($AccessRule)
    $acl | Set-Acl "$folderLocation\$dest"

    ## Run End
Write-Host
Write-Host " ✓✓ Process Finished for $name "
log -Line "$name Migration Process Succeeded"
    return "$name was successfull"
}


####
# PROGRAM START
####
log -Line "$date - Automated Profile Size Scan"

$profileFolders = Get-ChildItem -Path $folderLocation -Attributes "d"

foreach($folder in $profileFolders){
    $items = Get-ChildItem $folderLocation\$folder
    $out = 0
    $flag = 0

    if($items.count -ne 1){
        $temp = $items[0]
         $flag = 1
         $vars =   Get-VHD -Path $folderLocation\$folder\$temp | Select-Object FileSize, Size
    }else{
        #Write-Host  "$folder, INACTIVE" -ForegroundColor Green
        $vars =   Get-VHD -Path $folderLocation\$folder\$items | Select-Object FileSize, Size
    }
   
    $remaining = $vars.Size - $vars.FileSize 
    $max = $vars.Size
    $current = $vars.FileSize ;
    $out += ($remaining / (1024 * 1024)) 
    log -Line "$folder"
    log -Line "HD MAX SIZE: $max"
    log -Line "Current SIZE: $current"
    

}
$Scan = "Finished Scan: $OK profiles are within spec, $MAX profiles out of spec, $ADD Have been added to the upgrade Queue"
log -Line $Scan
Write-Host $Scan



#Automagic Usage of multiple peoplez

#$folderLocation = "\\<<Domain>>\dfsroot\FSLogixProfile"

$FinalisedUsers = ""
foreach($name in $users){
   $FinalisedUsers += Expand-User -Username $name -FileLocation $folderLocation
   $FinalisedUsers += "`n"
}

Write-Host $FinalisedUsers
