
Import-Module '\\AUD444216\C$\Users\ben.camareno\Documents\WindowsPowerShell\ShowUI.1.5\ShowUI\ShowUI.psd1' -Global -Force
New-Window -Title "New Talent User" -Width 520 -Height 450 -WindowStartupLocation CenterScreen -Background DarkGray {

    New-StackPanel -ControlName 'New Talent User'{
        $Subscription = Get-MsolSubscription | select SkuPartNumber -ExpandProperty SkuPartNumber
        
New-TextBlock -Text "First Name" -HorizontalAlignment Center
New-TextBox -Name FirstN -Height 25 -Width 150 -On_TextChanged {

$Email.Text = $FirstN.Text

}
New-TextBlock -Text "Last Name" -HorizontalAlignment Center
New-TextBox -Name LastN -Height 25 -Width 150 -On_TextChanged {
$Email.Text = $FirstN.Text + "."+ $LastN.Text

}
New-Separator -Background DarkGray

New-TextBlock -Text "Job Title" -HorizontalAlignment Center
New-TextBox -Name JobT -Height 25 -Width 150


New-Separator -Background DarkGray

New-TextBlock -Text "Office" -HorizontalAlignment Center
New-ComboBox -Name Office -Items "Adelaide", "Auckland","Brisbane","Canberra","Hong Kong","Malaysia","Melbourne","Perth","Singapore","Sydney","Wellington" -Height 25 -Width 150


New-TextBlock -Text "Department" -HorizontalAlignment Center
New-ComboBox -Name "Department" -Items "Consultancy","Group","Marketing","Sales" -Height 25 -Width 150

New-TextBlock -Text "Company" -HorizontalAlignment Center
New-ComboBox -Name Comp -Items "Talent International", "Avec" -Height 25 -Width 150 -On_DropDownClosed {
        IF ($Comp.Text -eq "Talent International"){
            $Email.Text = $FirstN.Text + "."+ $LastN.Text + "@talentinternational.com"



            }

        IF ($Comp.Text -eq "Avec"){
            $Email.Text = $FirstN.Text + "."+ $LastN.Text + "@avecglobal.com"

        }
        
    

}


New-Separator -Background DarkGray
New-TextBlock -Text "E-Mail Address" -HorizontalAlignment Center
New-TextBox -Name EMail -Height 25 -Width 300


New-Separator -Background DarkGray -Height 50



New-Button -Content "Save and Add" -Height 25 -Width 80 -On_Click {

$out_file = "C:\Users\ben.camareno\Desktop\newusers.csv"
$NewLine = "{0},{1},{2},{3},{4},{5},{6}" -f $FirstN.Text,$LastN.Text,$EMail.Text,$Office.Text,$JobT.Text,$Department.Text,$Comp.Text
$NewLine | add-content -path $out_file

$FirstN.Text = ""
$LastN.Text = ""
$EMail.Text  = ""
$Office.Text = ""
$JobT.Text = ""
$Department.Text = ""
$Comp.Text = ""


}

New-Separator -Background DarkGray 20

New-Button -Content "Save and Create" -Height 25 -Width 100 -On_Click {
$out_file = "C:\Users\ben.camareno\Desktop\newusers.csv"
$NewLine = "{0},{1},{2},{3},{4},{5},{6}" -f $FirstN.Text,$LastN.Text,$EMail.Text,$Office.Text,$JobT.Text,$Department.Text,$Comp.Text
$NewLine | add-content -path $out_file

$FirstN.Text = ""
$LastN.Text = ""
$EMail.Text  = ""
$Office.Text = ""
$JobT.Text = ""
$Department.Text = ""
$Comp.Text = ""

C:\Users\ben.camareno\Desktop\get-msoluserlicence.ps1

}

   
   }

} -Show