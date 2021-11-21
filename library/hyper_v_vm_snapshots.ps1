#!powershell
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# WANT_JSON
# POWERSHELL_COMMON

$params = Parse-Args $args;
$result = @{};
Set-Attr $result "changed" $false;

$name = Get-Attr -obj $params -name name -failifempty $true -emptyattributefailmessage "missing required argument: name"
$snapshotname = Get-Attr -obj $params -name snapshotname -failifempty $true -emptyattributefailmessage "missing required argument: snapshotname"

$showlog = Get-Attr -obj $params -name showlog -default "false" | ConvertTo-Bool
$state = Get-Attr -obj $params -name state -default "create"

if ("create","restore" -notcontains $state) {
    Fail-Json $result "The state: $state doesn't exist; State can only be: create, restore"
}

#####   Functions   #####
Function VM-Checkpoint {
    $CheckVM = Get-VM -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $name}    

    if ($CheckVM) {
        $CheckVM | Foreach-Object {
            $_ | Checkpoint-VM -SnapshotName $snapshotname
            $result.changed = $true
            }
        }
    else{
        $result.skipped = $true
        $result.msg = 'VM: ' + $name + ' does not exist'
        }
}

Function VM-Restore {
    $CheckVM = Get-VM -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $name}    

    if ($CheckVM) {
        $CheckVM | Foreach-Object {
            $_ | Get-VMSnapshot -Name $snapshotname | Sort CreationTime | Select -Last 1 | Restore-VMSnapshot -Confirm:$false
            $result.changed = $true
            }
        }
    else{
        $result.skipped = $true
        $result.msg = 'VM: ' + $name + ' does not exist'
        }
}

#####   Code run from here   #####
Try {
    switch ($state) {
                "create" {VM-Checkpoint}
                "restore" {VM-Restore}
        }
    Exit-Json $result;
}
Catch {Fail-Json $result $_.Exception.Message}