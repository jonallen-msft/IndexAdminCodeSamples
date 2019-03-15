<#
DISCLAIMER
   THIS CODE IS SAMPLE CODE. THESE SAMPLES ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND.
   MICROSOFT FURTHER DISCLAIMS ALL IMPLIED WARRANTIES INCLUDING WITHOUT LIMITATION ANY IMPLIED WARRANTIES
   OF MERCHANTABILITY OR OF FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK ARISING OUT OF THE USE OR
   PERFORMANCE OF THE SAMPLES REMAINS WITH YOU. IN NO EVENT SHALL MICROSOFT OR ITS SUPPLIERS BE LIABLE FOR
   ANY DAMAGES WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF BUSINESS PROFITS, BUSINESS
   INTERRUPTION, LOSS OF BUSINESS INFORMATION, OR OTHER PECUNIARY LOSS) ARISING OUT OF THE USE OF OR
   INABILITY TO USE THE SAMPLES, EVEN IF MICROSOFT HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
   BECAUSE SOME STATES DO NOT ALLOW THE EXCLUSION OR LIMITATION OF LIABILITY FOR CONSEQUENTIAL OR
   INCIDENTAL DAMAGES, THE ABOVE LIMITATION MAY NOT APPLY TO YOU.
#>
    
# the essence of this script is to review the method to track SMB1 usage prior to disabling the feature

# IT IS NOT DESIGNED TO BE RUN IN ONE COMPLETE EXECUTION BUT AS INDIVIDUAL STEPS WITH INVESTIGATION AND CONSIDERATION AT ALL STAGES

#Requires -RunAsAdministrator

# is SMB1 enabled?
Get-WindowsOptionalFeature -Online | Where-Object FeatureName -like *smb* | Format-Table -AutoSize


###################

# Let's see what SMB event logs we have

# Event Viewer
#   Applications and Services Logs
#       Microsoft
#           SMBServer

Get-WinEvent -ListLog * -ea SilentlyContinue | Where-Object LogName -like *smb*

# Audit is where SMB1 activity will be logged
# check for events in this and if you see none over an extended length of time then there is no activity being logged
# meaning that you could disable SMB1 windows feature and hopefully not see something catastrophic

# Get log create date
$CreateDate = (get-item (Get-WinEvent -ListLog *smbserver/audit* | Select-Object logfilepath).logfilepath.tostring().replace('%SystemRoot%', "$env:systemroot")).CreationTime
$CreateDate

# lets see if we are logging SMB1 activity
$IsSMB1AuditOn = (Get-SmbServerConfiguration | Select-Object auditsmb1access).auditsmb1access
$IsSMB1AuditOn

# if we aren't auditing events then lets turn that on
if ($IsSMB1AuditOn = $false) {
    Set-SmbServerConfiguration –AuditSmb1Access $true 
    write-host "SMB1 event auditing enabled"
}

# have we got any events logged? 
$EventCount = (Get-WinEvent -LogName Microsoft-Windows-SMBServer/audit -ea SilentlyContinue | Measure-Object ).Count

# if we have then lets check out some of the details...
if ($eventcount) {
    try {
        write-host "$EventCount events logged. Showing first 3 ... "
        Get-WinEvent -LogName Microsoft-Windows-SMBServer/audit | Select-Object -first 3 timecreated, machinename, userid, message | Format-Table -a -Wrap
    }
    catch {
        write-warning $Error[0].Exception
    }
}
else {
    write-host "$EventCount events logged since Auditing started on $CreateDate."
}


# to turn off SMB1 event auditing Note use of -force to override the confirmation challenge
#    Set-SmbServerConfiguration –AuditSmb1Access $false -force

# to disable SMB1 feature
# NOTE :: THIS REQUIRES A SYSTEM RESTART
# Disable-WindowsOptionalFeature -FeatureName  "SMB1Protocol" -Online
