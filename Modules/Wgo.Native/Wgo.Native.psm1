# Wgo.Native.psm1 - Native P/Invoke for NtSetSystemInformation and token operations

function Invoke-WgoStandbyListPurge {
    if (-not ("Wgo.NativeMemory" -as [type])) {
        Add-Type -Namespace Wgo -Name NativeMemory -MemberDefinition @'
[DllImport("ntdll.dll")]
public static extern int NtSetSystemInformation(int SystemInformationClass, ref int SystemInformation, int SystemInformationLength);

[DllImport("kernel32.dll")]
public static extern IntPtr GetCurrentProcess();

[DllImport("advapi32.dll", SetLastError = true)]
public static extern bool OpenProcessToken(IntPtr ProcessHandle, uint DesiredAccess, out IntPtr TokenHandle);

[DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern bool LookupPrivilegeValue(string lpSystemName, string lpName, out long lpLuid);

[StructLayout(LayoutKind.Explicit, Size = 16)]
public struct TOKEN_PRIVILEGES {
    [FieldOffset(0)]  public int PrivilegeCount;
    [FieldOffset(4)]  public long Luid;
    [FieldOffset(12)] public int Attributes;
}

[DllImport("advapi32.dll", SetLastError = true)]
public static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges, ref TOKEN_PRIVILEGES NewState, int BufferLength, IntPtr PreviousState, IntPtr ReturnLength);
'@
    }

    try {
        $hToken = [IntPtr]::Zero
        $TOKEN_ADJUST_PRIVILEGES = 0x20
        $TOKEN_QUERY = 0x8
        if (-not [Wgo.NativeMemory]::OpenProcessToken([Wgo.NativeMemory]::GetCurrentProcess(), ($TOKEN_ADJUST_PRIVILEGES -bor $TOKEN_QUERY), [ref]$hToken)) {
            $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            try { Write-Log ("Standby purge: OpenProcessToken failed (Win32 error $err)") "WARN" } catch { }
            return $null
        }

        $luid = 0L
        if (-not [Wgo.NativeMemory]::LookupPrivilegeValue($null, "SeProfileSingleProcessPrivilege", [ref]$luid)) {
            $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            try { Write-Log ("Standby purge: LookupPrivilegeValue failed (Win32 error $err)") "WARN" } catch { }
            return $null
        }

        $SE_PRIVILEGE_ENABLED = 0x2
        $tp = New-Object Wgo.NativeMemory+TOKEN_PRIVILEGES
        $tp.PrivilegeCount = 1
        $tp.Luid = $luid
        $tp.Attributes = $SE_PRIVILEGE_ENABLED

        if (-not [Wgo.NativeMemory]::AdjustTokenPrivileges($hToken, $false, [ref]$tp, 0, [IntPtr]::Zero, [IntPtr]::Zero)) {
            $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            try { Write-Log ("Standby purge: AdjustTokenPrivileges failed (Win32 error $err)") "WARN" } catch { }
            return $null
        }
        $adjustErr = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        if ($adjustErr -eq 1300) {
            try { Write-Log "Standby purge: SeProfileSingleProcessPrivilege is not assignable to this token (ERROR_NOT_ALL_ASSIGNED) - are you really running as Administrator?" "WARN" } catch { }
            return $null
        }

        $before = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).FreePhysicalMemory

        $cmd = 4
        $result = [Wgo.NativeMemory]::NtSetSystemInformation(0x50, [ref]$cmd, 4)

        if ($result -ne 0) {
            try { Write-Log ("Standby purge: NtSetSystemInformation returned NTSTATUS 0x{0:X8}" -f $result) "WARN" } catch { }
            return $null
        }

        Start-Sleep -Milliseconds 500
        $after = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).FreePhysicalMemory
        return [Math]::Max(0, [Math]::Round(($after - $before) / 1024))
    } catch {
        try { Write-Log ("Standby purge: unexpected error - " + $_.Exception.Message) "WARN" } catch { }
        return $null
    }
}

Export-ModuleMember -Function Invoke-WgoStandbyListPurge