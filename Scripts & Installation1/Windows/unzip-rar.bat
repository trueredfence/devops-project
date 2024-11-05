@echo off
setlocal

:: Hard-coded parameters
set "zip_file=%~dp0open.zip"        :: Specify the path to your zip file
set "password=abc"                  :: Specify the password for the zip file (not directly supported by Windows unzip)
set "output_dir=%~dp0open"          :: Specify the output directory

:: Create output directory if it doesn't exist
if not exist "%output_dir%" (
    mkdir "%output_dir%"
)

:: Unzip using PowerShell
powershell -command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%zip_file%', '%output_dir%')"

endlocal
