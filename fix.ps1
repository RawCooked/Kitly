$content = [System.IO.File]::ReadAllText("c:\Users\admin\Downloads\files\kitly\kitly.ps1")
[System.IO.File]::WriteAllText("c:\Users\admin\Downloads\files\kitly\kitly.ps1", $content, [System.Text.Encoding]::UTF8)

$utils = [System.IO.File]::ReadAllText("c:\Users\admin\Downloads\files\kitly\utils.ps1")
[System.IO.File]::WriteAllText("c:\Users\admin\Downloads\files\kitly\utils.ps1", $utils, [System.Text.Encoding]::UTF8)
