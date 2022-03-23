Connect-MsolService
$htmlComp = ""
$filePath = 'C:\Users\gaustin\Desktop\LicensedUsers'+"$date"+'.csv'
$filePath
$all = Get-ADUser -Filter * -Properties * 


foreach($usr in $all){
       
    if($usr.LastLogonDate -lt (get-date).AddDays(-180) -and $usr.LastLogonDate -and $usr.EmailAddress){
       


        $licensedUsers = Get-MsolUser -UserPrincipalName $usr.EmailAddress -erroraction 'silentlycontinue' | Where-Object {$_.islicensed}
  
        foreach ($user in $licensedUsers) { 
            if($user.UserPrincipalName.StartsWith("_")){
                continue
            }
            $licenses = $user.Licenses
            $licenseArray = $licenses | foreach-Object {$_.AccountSkuId}
            $licenseString = $licenseArray -join ", "

            $licensedSharedMailboxProperties = [pscustomobject][ordered]@{
                DisplayName       = $user.DisplayName
                Licenses          = $licenseString
                LastLoginDate     = $usr.LastLogonDate
                UserPrincipalName = $user.UserPrincipalName
            }
            
            $licensedSharedMailboxProperties | Export-CSV –Append -Path $filePath -NoTypeInformation 
        }
        

    }else{

    }   

    $htmlComp
    
}


