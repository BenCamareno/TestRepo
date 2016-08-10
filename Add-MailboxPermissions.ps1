### GUI - Edit user/shared mailbox permissions ###
### Author: Ben Camareno ###
### Date: 04/08/2016 #######
### Company: Talent International ###


#$serviceun = 'itaccounts@talentint.onmicrosoft.com'
#$servicepw = cat '\\tiad01\C$\Scripts\password.txt' | convertto-securestring
#$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $serviceun, $servicepw
#Connect-msolservice -Credential $cred

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential ben.camareno@talentinternational.com -Authentication Basic -AllowRedirection
Import-PSSession $Session -AllowClobber
Import-Module 'C:\Users\administrator.TALENTINT\Documents\WindowsPowerShell\ShowUI.1.5\ShowUI\ShowUI.psd1' -Global -Force


New-Window -Title "Edit Mailbox Permissions" -Width 270 -Height 420 -WindowStartupLocation CenterScreen -ResizeMode NoResize -Background DarkSlateBlue{

New-StackPanel -HorizontalAlignment Center {
New-Menu -Items "File","Edit","Help" -IsMainMenu -Width 270
New-Separator -Background DarkSlateBlue -Height 10
    
    
    New-StackPanel -ControlName 'Edit Mailbox Permissions'{        

    $Users = Get-Mailbox -RecipientTypeDetails UserMailbox | select Alias -ExpandProperty Alias | Sort-Object 
    $SharedMB = Get-Mailbox -RecipientTypeDetails SharedMailbox | select Alias -ExpandProperty Alias | Sort-Object 
    $UserMailbox = Get-Mailbox -RecipientTypeDetails UserMailbox | select Alias -ExpandProperty Alias | Sort-Object 
          

   
New-TextBlock -Text "User" -Foreground GhostWhite -HorizontalAlignment Center
   
New-ComboBox -Name User -Items $Users -Height 25 -Width 150 -HorizontalContentAlignment Center -IsEditable -On_DropDownOpened {
    
    $FullAccess.IsChecked = $false
    $SendAs.IsChecked = $false
    $SubID.Text = ""
    $SubID1.Text = ""

}

New-Button -Name CheckAccess -Content "Check Access" -Height 25 -Width 100 -HorizontalAlignment Center  -On_Click{


Get-Mailbox -RecipientTypeDetails SharedMailbox | Get-MailboxPermission -User $User.Text | ogv -Title "Mailbox Permission"
Get-Mailbox -RecipientTypeDetails SharedMailbox | Get-RecipientPermission -Trustee $User.Text | ogv -Title "Recipient Permission"
}
New-Separator -Background DarkSlateBlue -Height 10

New-TextBlock -Text "Shared Mailbox" -Foreground GhostWhite -HorizontalAlignment Center
New-ComboBox -Name SubID -Items $SharedMB -SnapsToDevicePixels -Height 25 -Width 250 -HorizontalContentAlignment Center -On_DropDownClosed {


   $CurrentPerm1 = Get-Mailbox -Identity $SubID.Text  | Get-MailboxPermission -User $User.Text 
    IF ($CurrentPerm1.AccessRights -like "FullAccess"){
        $FullAccess.IsThreeState = $true
        $FullAccess.Indeterminate = $true



    }
    $CurrentPerm2 = Get-Mailbox -Identity $SubID.Text | Get-RecipientPermission -Trustee $User.Text 
   IF ($CurrentPerm2.AccessRights -like "SendAs"){
        $SendAs.IsThreeState = $true
        $FullAccess.Indeterminate = $true


}} 

New-Separator -Background DarkSlateBlue

New-TextBlock -Text "User Mailbox" -Foreground GhostWhite  -HorizontalAlignment Center 
New-ComboBox -Name SubID1 -Items $UserMailbox -Height 25 -Width 250 -HorizontalContentAlignment Center -On_DropDownClosed {

  $CurrentPerm1 = Get-Mailbox -Identity $SubID1.Text  | Get-MailboxPermission -User $User.Text 
    IF ($CurrentPerm1.AccessRights -like "FullAccess"){
        $SendAs.IsThreeState = $true
        $SendAs.Indeterminate = $true



    }
    $CurrentPerm2 = Get-Mailbox -Identity $SubID1.Text | Get-RecipientPermission -Trustee $User.Text 
   IF ($CurrentPerm2.AccessRights -like "SendAs"){
        $SendAs.IsThreeState = $true
        $SendAs.Indeterminate = $true

}   

}


New-Separator -Background DarkSlateBlue -Height 10

    New-StackPanel {

New-TextBlock -Text "Full Access" -Foreground GhostWhite -HorizontalAlignment Center
New-CheckBox -Name FullAccess -HorizontalAlignment Center -IsThreeState -On_Checked {

    Get-Mailbox -Identity $SubID.Text  | Add-MailboxPermission -User $User.Text -AccessRights "FullAccess" -Confirm:$false -Verbose
    Get-Mailbox -Identity $SubID1.Text  | Add-MailboxPermission -User $User.Text -AccessRights "FullAccess" -Confirm:$false -Verbose
    


} -On_Unchecked {

    Get-Mailbox -Identity $SubID.Text  | Remove-MailboxPermission -User $User.Text -AccessRights "FullAccess" -Confirm:$false -Verbose
    Get-Mailbox -Identity $SubID1.Text  | Remove-MailboxPermission -User $User.Text -AccessRights "FullAccess" -Confirm:$false -Verbose


}

New-TextBlock -Text "Send As" -Foreground GhostWhite -HorizontalAlignment Center
New-CheckBox -Name SendAs -HorizontalAlignment Center -IsThreeState -On_Checked {

    Get-Mailbox -Identity $SubID.Text | Add-RecipientPermission -Trustee $User.Text -AccessRights "SendAs" -Confirm:$false -Verbose
    Get-Mailbox -Identity $SubID1.Text | Add-RecipientPermission -Trustee $User.Text -AccessRights "SendAs" -Confirm:$false -Verbose


} -On_Unchecked {

    Get-Mailbox -Identity $SubID.Text | Remove-RecipientPermission -Trustee $User.Text -AccessRights "SendAs" -Confirm:$false -Verbose
    Get-Mailbox -Identity $SubID1.Text | Remove-RecipientPermission -Trustee $User.Text -AccessRights "SendAs" -Confirm:$false -Verbose


}
}


New-Separator -Height 30 -Background DarkSlateBlue
       
New-Button -Row 2 -Content "Save" -Height 25 -Width 150 -VerticalAlignment Bottom -HorizontalAlignment Center -On_Click {
 

    IF ($FullAccess.IsChecked -eq "True"){
    Get-Mailbox -Identity $SubID.Text  | Add-MailboxPermission -User $User.Text -AccessRights "FullAccess" -Confirm:$false -Verbose
    Get-Mailbox -Identity $SubID1.Text  | Add-MailboxPermission -User $User.Text -AccessRights "FullAccess" -Confirm:$false -Verbose
    }

    IF ($SendAs.IsChecked -eq "True"){

    Get-Mailbox -Identity $SubID.Text | Add-RecipientPermission -Trustee $User.Text -AccessRights "SendAs" -Confirm:$false -Verbose
    Get-Mailbox -Identity $SubID1.Text | Add-RecipientPermission -Trustee $User.Text -AccessRights "SendAs" -Confirm:$false -Verbose
    }
    
        IF ($FullAccess.IsChecked -eq "False"){
    Get-Mailbox -Identity $SubID.Text  | Remove-MailboxPermission -User $User.Text -AccessRights "FullAccess" -Confirm:$false -Verbose
    Get-Mailbox -Identity $SubID1.Text  | Remove-MailboxPermission -User $User.Text -AccessRights "FullAccess" -Confirm:$false -Verbose

    }

    IF ($SendAs.IsChecked -eq "False"){

    Get-Mailbox -Identity $SubID.Text | Remove-RecipientPermission -Trustee $User.Text -AccessRights "SendAs" -Confirm:$false -Verbose
    Get-Mailbox -Identity $SubID1.Text | Remove-RecipientPermission -Trustee $User.Text -AccessRights "SendAs" -Confirm:$false -Verbose
    }     
        
        
   

}}}
    

} -Show