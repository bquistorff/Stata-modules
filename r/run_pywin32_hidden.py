import sys
import sfi

def run_pywin32_hidden(cmd_line, cwd=None):
    import win32con
    import pywintypes
    import win32service
    import win32process
    import win32event

    # Open Desktop. No need to close as destroyed when process ends
    desktop_name = "pystatacons"
    try:
        _ = win32service.OpenDesktop(desktop_name, 0, True, win32con.MAXIMUM_ALLOWED)
    except win32service.error:  # desktop doesn't exist
        try:
            sa = pywintypes.SECURITY_ATTRIBUTES()
            sa.bInheritHandle = 1
            _ = win32service.CreateDesktop(desktop_name, 0, win32con.MAXIMUM_ALLOWED, sa)  # return if already created
        except win32service.error:
            sfi.SFIToolkit.display("Couldn't create Desktop.")
            sfi.SFIToolkit.pollnow()
            return 1337

    s = win32process.STARTUPINFO()
    s.lpDesktop = desktop_name
    s.dwFlags = win32con.STARTF_USESHOWWINDOW + win32con.STARTF_FORCEOFFFEEDBACK
    s.wShowWindow = win32con.SW_SHOWMINNOACTIVE
    proc_ret = win32process.CreateProcess(None, cmd_line, None, None, False, 0, None, cwd, s)
    #proc_ret = win32process.CreateProcess(r"C:\Windows\System32\cmd.exe", cmd_line, None, None, False, 0, None, cwd, s)
    # hProcess, _, dwProcessId, _
    sfi.SFIToolkit.display(cmd_line + "." + "\n" + "Starting in hidden desktop (pid=" + str(proc_ret[2]) + ").")
    sfi.SFIToolkit.pollnow()
    win32event.WaitForSingleObject(proc_ret[0], win32event.INFINITE)
    ret_code = win32process.GetExitCodeProcess(proc_ret[0])
    return ret_code

sfi.SFIToolkit.display(sys.argv[1])
sfi.SFIToolkit.pollnow()
exit_status = run_pywin32_hidden(sys.argv[1])
sfi.SFIToolkit.exit(exit_status)
