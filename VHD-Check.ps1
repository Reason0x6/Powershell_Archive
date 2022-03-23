    $folderLocation = "\\<Domain>\dfsroot\FSLogixProfile"
    $OK = 0
    $MAX = 0
    $users

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
        $out += ($remaining / (1024 * 1024)) 

        if($out -gt 150){
                $OK += 1
        }else{
               
                $MAX += 1
                if($flag -eq 1){
                   
                }else{
                    $name = $items.Name -replace ".*_" -replace ""
                    $name = $name -replace ".VHDX" -replace ""
                    $users+=($name)
                }
        }


    }
    Write-Host "Finished Scan: $OK profiles are within spec, $MAX profiles out of spec"

    $users