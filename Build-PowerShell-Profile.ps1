################################################################################
# Build-Powershell- █▀▀▄ █▀▀▄ ▄▀▀▄ █▀▀▀ ▀█▀ █    █▀▀▀ ░░░░░░░░░░░░░░░░░░░░░░░▒▓█
# ░░░░░░░░░░░░░░░░░ █▄▄▀ █▄▄▀ █  █ █▀▀▀  █  █  ▄ █▀▀  ░░░░░░░░░░░░░░░░░░░░░▒▓█
# ░░░░░░░░░░░░░░░░░ █    ▀  ▀▄ ▀▀  ▀    ▀▀▀ ▀▀▀  ▀▀▀▀ .ps1 ░░░░░░░░░░░░░░░▒▓█
#
# Build a PowerShell profile that combines the commands included in the PSamplio
#   project.
#
# @version 0.1.0
#
# @author Daniel Rieck
#   [daniel.rieck@wsu.edu]
#   (https://github.com/invokeImmediately)
#
# @link https://github.com/invokeImmediately/PSamplio/blob/main/…
#   …Build-PowerShell-Profile.ps1
#
# @license MIT License — Copyright (c) 2023 Daniel C. Rieck
#   Permission is hereby granted, free of charge, to any person obtaining a copy
#     of this software and associated documentation files (the "Software"), to
#     deal in the Software without restriction, including without limitation the
#     rights to use, copy, modify, merge, publish, distribute, sublicense,
#     and/or sell copies of the Software, and to permit persons to whom the
#     Software is furnished to do so, subject to the following conditions:
#   The above copyright notice and this permission notice shall be included in
#     all copies or substantial portions of the Software.
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#     THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#     FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#     DEALINGS IN THE SOFTWARE.
################################################################################

function Build-PowerShell-Profile {
  Param (
    [ string ]
    $bumpMode
  )
  begin {
    class TocLineEntry {
      [ValidateNotNullOrEmpty()][string]$CommandName
      [ValidateNotNullOrEmpty()][long]$LineNumber
    }

    function Build-Profile-from-Cmd-Src-Files {
      Write-Host "Calling command."
      # ·> Prep an empty string that will store a serial concatenation of all
      # ·  commands in this project. <·
      $allCmds = ""

      # ·> Prep an empty string that will store the table of contents and track
      # ·  line numbers. <·
      $profileBuildHeader = Get-Profile-Header-from-Last-Build
      [TocLineEntry[]]$tocEntries = @()
      [string[]]$codeForCommands = @()

      # Dynamically obtain a list of all command files in the PSamplio project
      $cmdSrcFileList = Get-List-of-PowerShell-Command-Source-Files
      $lastLineNum = (Measure-Object -InputObject $profileBuildHeader -Line).Lines + $cmdSrcFileList.Length + 6

      # ·> Extract the command from each source file while building the table of
      # ·  for inline documentation contents section. <·
      $commandNumber = 1
      $cmdSrcFileList | % {

        # ·> Obtain the contents of the file as an array of lines and a multi-
        # ·  line string, the latter of which will be used in combination with
        # ·  regex pattern matching. <·
        $cmdContents = Get-Content -Path ('..\PSamplio\Commands\' + $_.Name) -Raw

        # ·> Remove the file header comment block from the file's contents, thus
        # ·  yielding only the command itself. <·
        $commandCode = Trim-File-Header-from-Command-Source $cmdContents
        $codeForCommands += @( $commandCode )

        # Isolate the name of the function
        $cmdDetails = Get-Command-Details-From-Source $commandCode
        $cmdNm = $cmdDetails.cmdNm
        $cmdLnNum = $cmdDetails.lnNum

        # Track where the line number will fall in the built profile
        $tocEntries += @( [TocLineEntry]@{
          CommandName = $cmdNm
          LineNumber = $lastLineNum + 2
        } )
        $lastLineNum += (Measure-Object -InputObject $commandCode -Line).Lines + 3
      }

      # Write to file, starting with the file header.
      $tableOfContents = Create-Table-of-Contents-from-TOC-Entries $tocEntries
      $commands = Create-Commands-Output-from-File-Scans $codeForCommands $tocEntries
      $profileOutput = $profileBuildHeader + $tableOfContents + $commands
      $profileOutput | Set-Content '..\PSamplio\Microsoft.PowerShell_profile.ps1'

      # TODO: Finish writing function.
      # Add the commands to the file after the TOC.
    }

    function Create-Commands-Output-from-File-Scans {
      param (
        [string[]]$codeForCommands,
        [TocLineEntry[]] $tocEntries
      )

      Write-Host $codeForCommands
      $output = ""
      $commandIndex = 0
      $codeForCommands | % {
        $output += "{0}################################################################################{0}# §{1}: {2}{0}{3}" -f ([Environment]::NewLine), ( $commandIndex + 1 ), $tocEntries[ $commandIndex ].CommandName, $_
        $commandIndex++
      }

      return $output
    }

    function Create-Table-of-Contents-from-TOC-Entries {
      param (
        [TocLineEntry[]] $tocEntries
      )
      $maxEntryLength = 73
      $tableOfContents = "{0}################################################################################{0}# TABLE OF CONTENTS:{0}####################{0}" -f ([Environment]::NewLine)
      $entryNumber = 1
      $tocEntries | % {
        $entryStringLength = $entryNumber.ToString().Length + $_.CommandName.Length + $_.LineNumber.ToString().Length
        if( $entryStringLength -lt $maxEntryLength ) {
          $indentFillString = "." * ( $maxEntryLength - $entryStringLength )
        }
        $tableOfContents += "# §{0}: {1}{2}{3}{4}" -f $entryNumber, $_.CommandName, $indentFillString, $_.LineNumber.ToString(), ([Environment]::NewLine)
        $entryNumber++
      }
      $tableOfContents += "################################################################################{0}" -f ([Environment]::NewLine)
      return $tableOfContents
    }

    function Get-Profile-Header-from-Last-Build {
      $bldDirValid = ( Test-Path '..\PSamplio\' -PathType Container ) -and ( Test-Path '..\PSamplio\.git' -PathType Container )
      if ( -not $bldDirValid ) {
        Write-Error -Exception ( [System.IO.DirectoryNotFoundException]::new( 'Because the current directory does not seem to resemble a PSamplio repo, I am aborting the build process.' ) ) -ErrorAction Stop
      }
      $prevBldPrsnt = Test-Path '..\PSamplio\Microsoft.PowerShell_profile.ps1' -PathType Leaf
      if ( -not $prevBldPrsnt ) {
        Generate-Initial-Profile-Build
      }
      $prevBld = Get-Content -Path '..\PSamplio\Microsoft.PowerShell_profile.ps1' -Raw
      # TODO: Is this header pattern correct?
      [regex]$hdrPtrn = '(?mi)^#+\r?\n(?:#.*\r?\n)*#+\r?\n'
      $mtchInf = Select-String -InputObject $prevBld -Pattern $hdrPtrn -AllMatches
      if ( -not $mtchInf.Length -gt 0 ) {
        Write-Error -Exception ( [System.IO.FileLoadException]::new( 'Did not find an appropriately formed file header comment in the previous build Microsoft.PowerShell_profile.ps1. Aborting the build process.' ) ) -ErrorAction Stop
      }
      return $prevBld.substring( 0, $mtchInf.Matches[0].Length )
    }

    function Generate-Initial-Profile-Build {
      $versionNumber = Read-Host "What version number should the built profile have in its file header comment block? [0.0.0]"
      if ( $versionNumber -eq "" ) {
        $versionNumber = "0.0.0"
      }
      $copyrightYear = Get-Date -Format "yyyy"
      $licenseBlock = "# @license MIT License — Copyright (c) {0} Daniel C. Rieck{1}#   Permission is hereby granted, free of charge, to any person obtaining a copy{1}#     of this software and associated documentation files (the ""Software""), to{1}#     deal in the Software without restriction, including without limitation the{1}#     rights to use, copy, modify, merge, publish, distribute, sublicense,{1}#     and/or sell copies of the Software, and to permit persons to whom the{1}#     Software is furnished to do so, subject to the following conditions:{1}#   The above copyright notice and this permission notice shall be included in{1}#     all copies or substantial portions of the Software.{1}#   THE SOFTWARE IS PROVIDED ""AS IS"", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR{1}#     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,{1}#     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL{1}#     THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER{1}#     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING{1}#     FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER{1}#     DEALINGS IN THE SOFTWARE.{1}" -f $copyrightYear, ([Environment]::NewLine)
      # ·> TODO: Allow additional specifications including profile description,
      # ·  author, links, etc. <·
      ( "################################################################################{0}# Microsoft.Powershell_ █▀▀▄ █▀▀▄ ▄▀▀▄ █▀▀▀ ▀█▀ █    █▀▀▀ ░░░░░░░░░░░░░░░░░░░▒▓█{0}# ░░░░░░░░░░░░░░░░░░░░░ █▄▄▀ █▄▄▀ █  █ █▀▀▀  █  █  ▄ █▀▀  ░░░░░░░░░░░░░░░░░▒▓█{0}# ░░░░░░░░░░░░░░░░░░░░░ █    ▀  ▀▄ ▀▀  ▀    ▀▀▀ ▀▀▀  ▀▀▀▀ .ps1 ░░░░░░░░░░░▒▓█{0}#{0}# PowerShell profile containing commands that are useful for working on web{0}#   coordination and front-end development of WSUWP websites at Washington State{0}#   University. The profile was originallydeveloped to support work on the{0}#   websites of the the Division of Academic Engagement and Student Achievement{0}#   in the Office of the Provost and Executive Vice President.{0}#{0}# @version {1}{0}#{0}# @author Daniel C. Rieck{0}#   [daniel.rieck@wsu.edu]{0}#   (https://github.com/invokeImmediately){0}#{0}# @link https://github.com/invokeImmediately/PSamplio/blob/main/…{0}#   …Microsoft.PowerShell_profile.ps1{0}# @link https://github.com/wsuwebteam/web-design-system{0}# @link https://github.com/wsuwebteam/wsuwp-theme-wds{0}# @link https://github.com/washingtonstateuniversity/WSUWP-Platform{0}# @link https://github.com/washingtonstateuniversity/WSUWP-spine-parent-theme{0}#{0}{2}################################################################################{0}" -f ([Environment]::NewLine), $versionNumber, $licenseBlock) | Set-Content '..\PSamplio\Microsoft.PowerShell_profile.ps1'
    }

    function Get-List-of-PowerShell-Command-Source-Files {
      $list = Get-ChildItem -Path '..\PSamplio\Commands\' -Filter "*.ps1"
      return $list
    }

    function Trim-File-Header-from-Command-Source {
      param (
        [String] $cmdContents
      )
      [regex]$hdrPtrn = '(?mi)^#+\r?\n(?:#.*\r?\n)*#+\r?\n'
      $mtchInf = Select-String -InputObject $cmdContents -Pattern $hdrPtrn -AllMatches
      if ( -not $mtchInf.Length -gt 0 ) {
        Write-Error -Exception ([System.IO.FileLoadException]::new( 'Did not find an appropriately formed file header comment in command source file ' + $_.Name + '. Aborting the build process.' )) -ErrorAction Stop
      }
      return $cmdContents.substring( $mtchInf.Matches[0].Length, $cmdContents.Length - $mtchInf.Matches[0].Length )
    }

    function Get-Command-Details-From-Source {
      param (
        [String] $cmdContents
      )
      [regex]$fnNmPtrn = '(?mi)^Function ([A-Za-z0-9-]+) {\r?$'
      $mtchInf = Select-String -InputObject $cmdContents -Pattern $fnNmPtrn -AllMatches
      if ( -not $mtchInf.Length -gt 0 ) {
        Write-Error -Exception ([System.IO.FileLoadException]::new( 'Did not find the primary function definition in command source file ' + $_.Name + '. Aborting the build process.' )) -ErrorAction Stop
      }
      $details = @{
        cmdNm = $mtchInf.Matches[0].Groups[1].Value
        lnNum = (Measure-Object -InputObject $cmdContents.substring( 0, $mtchInf.Matches[0].Index ) -Line).Lines
      }
      return $details
    }
  } process {
    try {
      $result = Build-Profile-from-Cmd-Src-Files
      # Find the path of each valid command, then append it to the growing collection of all commands
      Write-Output -InputObject $result
    } catch [System.IO.FileLoadException] {
      Write-Host $PSItem.ToString()
    } catch {
      Write-Host $error[0].toString()
    }
  }
}

# $linesInCmd = Get-Content -Path ".\Commands\Compare-Directories.ps1"
# $cmdContents = Get-Content -Path ".\Commands\Compare-Directories.ps1" -Raw
# [regex] $pttrn = '(?mi)^#+\r\n(?:#.*\r\n)*#+\r\n'
# $AllMatches = Select-String -InputObject $cmdContents -Pattern $pttrn -AllMatches
# $AllMatches.Matches[0].Captures.Groups[1].Value
# $cmdContents.Length
# $Results.Length
# $cmdContents.substring( $AllMatches.Matches[0].Length, $cmdContents.Length - $AllMatches.Matches[0].Length )

Build-PowerShell-Profile
