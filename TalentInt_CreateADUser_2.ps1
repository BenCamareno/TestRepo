### Talent International New User Creation - Active Directory Component - Powershell Script ###
### Version 1.0 ###
### 10/05/16 ###
### Areas labled with "Modify these variables to adjust script" are safe top adjust. Anything with !!! should not be adjusted ###

###############################################################################################################################################################

### Configuration Details --- Modify these variables to adjust script

# Location of newuser csv file
$newusers = Import-Excel C:\Users\ben.camareno\Desktop\newus.xlsx
# Password used for new user accounts
$Password = 'Talent99'
# Default New User Organisational Unit in ADUser
$OrgUnit = "OU=_New Users,OU=Users,OU=AP,DC=talentint,DC=internal"

### Connect to OnPrem ActiveDirectory
Import-Module ActiveDirectory

### Create ActiveDirectory Users
foreach($user in $newusers){

## Office Details --- Modify these variables to adjust script
# Perth
IF($user.office -eq 'Perth' -AND $user.company -ne 'Avec')
{$streetaddress = 'Level 5, 150 Street Georges Terrace'
$state = 'WA'
$PostalCode = '6000'
$Country = 'AU'
$OfficePhone = '+61 8 9221 3300'
$fax = '+61 8 9221 3133'
$Company = $user.company}
ELSEIF($user.office -eq 'Perth' -AND $user.company -eq 'Avec')
{$streetaddress = 'Level 5, 150 Street Georges Terrace'
$state = 'WA'
$PostalCode = '6000'
$Country = 'AU'
$OfficePhone = '+61 8 6212 5500'
$fax = '+61 8 9221 3133'
$Company = $user.company}

# Sydney
IF($user.office -eq 'Sydney' -AND $user.company -ne 'Avec')
{$streetaddress = 'Level 9, 201 Elizabeth Street'
$state = 'NSW'
$PostalCode = '2000'
$Country = 'AU'
$OfficePhone = '+61 2 9223 9855'
$fax = '+61 2 9223 9833'
$Company = $user.company}
ELSEIF($user.office -eq 'Sydney' -AND $user.company -eq 'Avec')
{$streetaddress = 'Level 9, 201 Elizabeth Street'
$state = 'NSW'
$PostalCode = '2000'
$Country = 'AU'
$OfficePhone = '+61 2 9223 9855'
$fax = '+61 2 9223 9833'
$Company = $user.company}

# Adelaide
IF($user.office -eq 'Adelaide')
{$streetaddress = 'Level 10, 26 Flinders Street'
$state = 'SA'
$PostalCode = '5000'
$Country = 'AU'
$OfficePhone = '+61 8 8228 1555'
$fax = '+61 8 8228 1599'
$Company = $user.company}

# Brisbane
IF($user.office -eq 'Brisbane')
{$streetaddress = 'Level 21, Central Plaza 2,
66 Eagle Street'
$state = 'QLD'
$PostalCode = '4000'
$Country = 'AU'
$OfficePhone = '+61 7 3221 3333'
$fax = '+61 7 3221 3533'
$Company = $user.company}

# Canberra
IF($user.office -eq 'Canberra')
{$streetaddress = 'Level 2, Equinox 4, 70 Kent Street'
$state = 'ACT'
$PostalCode = '2600'
$Country = 'AU'
$OfficePhone = '+61 2 6285 3500'
$fax = '+61 2 6285 3400'
$Company = $user.company}

# Melbourne
IF($user.office -eq 'Melbourne')
{$streetaddress = 'Level 5, 459 Little Collins Street'
$state = 'VIC'
$PostalCode = '3000'
$Country = 'AU'
$OfficePhone = '+61 3 9602 4222'
$fax = '+61 3 9602 4202'
$Company = $user.company}

# Auckland
IF($user.office -eq 'Auckland')
{$streetaddress = 'Level 11, DLA Piper Tower,
205 Queen Street'
$state = ''
$PostalCode = '1010'
$Country = 'NZ'
$OfficePhone = '+64 9 281 4150'
$fax = '+64 9 281 4160'
$Company = $user.company}

# Wellington
IF($user.office -eq 'Wellington')
{$streetaddress = 'Level 8, 99 Customhouse Quay'
$state = ''
$PostalCode = '6143'
$Country = 'NZ'
$OfficePhone = '+64 4 499 1200'
$fax = '+64 4 499 1202'
$Company = $user.company}

# Malaysia
IF($user.office -eq 'Malaysia')
{$streetaddress = '27th Floor, Axiata Tower
9, Jalan Stesen Sentral 5'
$state = 'KL Sentral'
$PostalCode = '50470'
$Country = 'MY'
$OfficePhone = '+60 3 2776 6947'
$fax = '+65 6513 4877'
$Company = $user.company}

# Singapore
IF($user.office -eq 'Singapore')
{$streetaddress = '76A Amoy Street'
$state = ''
$PostalCode = '069895'
$Country = 'SG'
$OfficePhone = '+65 6812 5786'
$fax = '+65 6513 4877'
$Company = $user.company}

# Hong Kong
IF($user.office -eq 'Hong Kong')
{$streetaddress = '9th Floor, Lucky Building
39, Wellington Street, Central'
$state = ''
$PostalCode = ''
$Country = 'HK'
$OfficePhone = '+852 2868 9130'
$fax = ''
$Company = $user.company}


# Bristol
IF ($user.office -eq 'Bristol'){
        $streetaddress = '1st Floor, 26 Baldwin Street, Bristol, BS1 1SE'
        $state = ''
        $PostalCode = ''
        $Country = 'GB'
        $OfficePhone = '+44 (0) 117 332 0818'
        $fax = ''
        $Company = $user.company
}

# London
IF ($user.office -eq 'London'){
        $streetaddress = 'Vintners Place, 68 Upper Thames Street, London, EC4V 3BJ'
        $state = ''
        $PostalCode = ''
        $Country = 'GB'
        $OfficePhone = '+44 (0) 203 002 5500'
        $fax = ''
        $Company = $user.company
}

# Manchester
IF ($user.office -eq 'Manchester'){
        $streetaddress = '2nd Floor, Old Exchange Buildings, 29 – 31 King Street, Manchester, M2 6AD'
        $state = ''
        $PostalCode = ''
        $Country = 'GB'
        $OfficePhone = '+44 (0) 161 667 6750'
        $fax = ''
        $Company = $user.company
}

# Birmingham
IF ($user.office -eq 'Birmingham'){
        $streetaddress = '1st Floor, 138 Edmund Street, Birmingham, B3 2ES'
        $state = ''
        $PostalCode = ''
        $Country = 'GB'
        $OfficePhone = '+44 (0) 121 647 1100'
        $fax = ''
        $Company = $user.company
}


### !!! Creates New User based on above criteria !!! 
New-ADUser -userprincipalname $user.emailaddress -GivenName $user.firstname -Surname $user.lastname -Name ($user.firstname+" "+$user.lastname) -DisplayName ($user.firstname+" "+$user.lastname) -StreetAddress $streetaddress -state $state -PostalCode $postalcode -Country $Country -OfficePhone $OfficePhone -Fax $fax -Path $OrgUnit -AccountPassword (ConvertTo-SecureString -AsPlaintext ($password) -Force) -ChangePasswordAtLogon $true -Title $user.jobtitle -Office $user.office -City $user.Office -Description $user.jobtitle -Department $user.department -Company $user.company -Enabled 1 -samaccountname ($user.firstname+"."+$user.lastname) -EmailAddress $user.EmailAddress

### Adds email proxyaddresses -- Modify these variables to adjust script
$username = $user.firstname+"."+$user.lastname

IF($user.company -eq 'Talent International'){
Set-ADuser -identity $username -Add @{Proxyaddresses="SMTP:"+$username+"@talentinternational.com"}
Set-ADuser -identity $username -Add @{Proxyaddresses="smtp:"+$username+"@avecglobal.com"}
Set-ADuser -identity $username -Add @{Proxyaddresses="smtp:"+$username+"@talentrise.org"}
}

IF($user.company -eq 'Avec'){
Set-ADuser -identity $username -Add @{Proxyaddresses="smtp:"+$username+"@talentinternational.com"}
Set-ADuser -identity $username -Add @{Proxyaddresses="SMTP:"+$username+"@avecglobal.com"}
Set-ADuser -identity $username -Add @{Proxyaddresses="smtp:"+$username+"@talentrise.org"}
}

IF($user.company -eq 'Talent Rise'){
Set-ADuser -identity $username -Add @{Proxyaddresses="smtp:"+$username+"@talentinternational.com"}
Set-ADuser -identity $username -Add @{Proxyaddresses="smtp:"+$username+"@avecglobal.com"}
Set-ADuser -identity $username -Add @{Proxyaddresses="SMTP:"+$username+"@talentrise.org"}
}
<#
### Group Memberships
# DaaS Desktop
IF($user.company -ne 'Avec'){
Add-ADGroupMember -Identity "DesktopUsers" -Members $username
}

# Avec
IF($user.company -eq 'Avec'){
Add-ADGroupMember -Identity !All_Avec_Staff -Members $username
}

# Talent Rise
IF($user.company -eq 'Talent Rise'){
Add-ADGroupMember -Identity AP_Department_TalentRise_M -Members $username
}

# Perth
IF($user.office -eq 'Perth'){
Add-ADGroupMember -Identity !All_Perth_Office -Members $username
Add-ADGroupMember -Identity AP-Printers-Perth -Members $username
Add-ADGroupMember -Identity AP_Department_Perth_M -Members $username
}
# Sydney
IF($user.office -eq 'Sydney'){
Add-ADGroupMember -Identity !All_Sydney_Office -Members $username
Add-ADGroupMember -Identity AP_Department_Sydney_M -Members $username
}
# Adelaide
IF($user.office -eq 'Adelaide'){
Add-ADGroupMember -Identity !All_Adelaide_Office -Members $username
Add-ADGroupMember -Identity AP-Printers-Adelaide -Members $username
Add-ADGroupMember -Identity AP_Department_Adelaide_M -Members $username
}
# Brisbane
IF($user.office -eq 'Brisbane'){
Add-ADGroupMember -Identity !All_Brisbane_Office -Members $username
Add-ADGroupMember -Identity AP-Printers-Brisbane -Members $username
Add-ADGroupMember -Identity AP_Department_Brisbane_M -Members $username
}
# Canberra
IF($user.office -eq 'Canberra'){
Add-ADGroupMember -Identity !All_Canberra_Office -Members $username
Add-ADGroupMember -Identity AP-Printers-Canberra -Members $username
Add-ADGroupMember -Identity AP_Department_Canberra_M -Members $username
}
# Melbourne
IF($user.office -eq 'Melbourne'){
Add-ADGroupMember -Identity !All_Melbourne_Office -Members $username
Add-ADGroupMember -Identity AP-Printers-Melbourne -Members $username
Add-ADGroupMember -Identity AP_Department_Melbourne_M -Members $username
}
# Auckland
IF($user.office -eq 'Auckland'){
Add-ADGroupMember -Identity !All_Auckland_Office -Members $username
Add-ADGroupMember -Identity AP_Department_Auckland_M -Members $username
}
# Wellington
IF($user.office -eq 'Wellington'){
Add-ADGroupMember -Identity !All_Wellington_Office -Members $username
Add-ADGroupMember -Identity AP_Department_Wellington_M -Members $username
}
# Malaysia
IF($user.office -eq 'Malaysia'){
Add-ADGroupMember -Identity !All_Malaysia_Office -Members $username
Add-ADGroupMember -Identity AP_Department_Malaysia_M -Members $username
}
# Singapore
IF($user.office -eq 'Singapore'){
Add-ADGroupMember -Identity !All_Singapore_Office -Members $username
Add-ADGroupMember -Identity AP_Department_Singapore_M -Members $username
}
# Hong Kong
IF($user.office -eq 'Hong Kong'){
Add-ADGroupMember -Identity !All_HongKong_Office -Members $username
Add-ADGroupMember -Identity AP_Department_HongKong_M -Members $username
}#>
}

### Empties CSV file
Remove-item '\\tiad01\c$\Scripts\newusers.csv'
$csv = @"
FirstName,LastName,EmailAddress,Office,JobTitle,Department,Company
"@

$csv >> '\\tiad01\c$\Scripts\newusers.csv'