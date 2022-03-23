

Add-Type -AssemblyName System.Windows.Forms

# This function will return the logged-on status of a local or remote computer 
# Written by BigTeddy 10 September 2012 
# Version 1.0 
# Sample usage: 
# GetRemoteLogonStatus '<remoteComputerName>' 
 



[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = New-Object System.Drawing.Point(494,250)
$Form.text                       = "User based on Phone Search"
$Form.TopMost                    = $false
$Form.BackColor = "#eceff1"

$compnameTxtbox                  = New-Object system.Windows.Forms.TextBox
$compnameTxtbox.multiline        = $false
$compnameTxtbox.width            = 307
$compnameTxtbox.height           = 20
$compnameTxtbox.location         = New-Object System.Drawing.Point(163,29)
$compnameTxtbox.Font             = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Number to Search"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(29,29)
$Label1.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$result                          = New-Object system.Windows.Forms.TextBox
$result.multiline                = $true
$result.width                    = 436
$result.height                   = 150
$result.location                 = New-Object System.Drawing.Point(29,67)
$result.Scrollbars = "Vertical"
$result.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)



$Form.controls.AddRange(@($compnameTxtbox,$Label1,$result))


$compnameTxtbox.Add_KeyDown({
    if ($_.KeyCode -eq "Enter") {
            ping
    }
    })

    function GetPhone ($number = '0000') { 
    Get-AdUser -Filter * -Properties MobilePhone, HomePhone, OfficePhone, DisplayName |`
        Select-Object DisplayName, `
        @{Name = "MobilePhone";Expression = {($_.MobilePhone -replace '[^0-9]')}},`
        @{Name = "OfficePhone";Expression = {($_.OfficePhone -replace '[^0-9]')}},`
        @{Name = "HomePhone";Expression = {($_.HomePhone -replace '[^0-9]')}}|`
        Where-Object {($_.MobilePhone -like ("*$number*")) `
        -or ($_.OfficePhone -like ("*$number*"))`
        -or ($_.HomePhone -like ("*$number*"))}
}


function ping(){ 
    $in = $compnameTxtbox.text
            
       
             $dd =  GetPhone($in)

             foreach($d in $dd){
             $result.Text += $d.DisplayName + " | Mb: "+$d.MobilePhone + "`r`n"
             $result.Text += "Office Phone: " + $in + "`r`n`n"
           }
        
        
    }


function closeForm(){$Form.close()}
    


[void]$Form.ShowDialog()