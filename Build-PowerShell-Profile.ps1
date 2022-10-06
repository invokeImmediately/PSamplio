####################################################################################################
# █▀▀▄ █  █ ▀█▀ █    █▀▀▄    █▀▀▄ ▄▀▀▄▐   ▌█▀▀▀ █▀▀▄ ▄▀▀▀ █  █ █▀▀▀ █    █       █▀▀▄ █▀▀▄ ▄▀▀▄ █▀▀▀
# █▀▀▄ █  █  █  █  ▄ █  █ ▀▀ █▄▄▀ █  █▐ █ ▌█▀▀  █▄▄▀ ▀▀▀█ █▀▀█ █▀▀  █  ▄ █  ▄ ▀▀ █▄▄▀ █▄▄▀ █  █ █▀▀▀
# ▀▀▀   ▀▀  ▀▀▀ ▀▀▀  ▀▀▀     █     ▀▀  ▀ ▀ ▀▀▀▀ ▀  ▀▄▀▀▀  █  ▀ ▀▀▀▀ ▀▀▀  ▀▀▀     █    ▀  ▀▄ ▀▀  ▀   
#
#    ▀█▀ █    █▀▀▀   █▀▀▄ ▄▀▀▀ ▄█
#     █  █  ▄ █▀▀    █▄▄▀ ▀▀▀█  █
#    ▀▀▀ ▀▀▀  ▀▀▀▀ ▀ █    ▀▀▀  ▄█▄▌
#
# Build a PowerShell profile that combines the commands included in the PSamplio project.
#
# @version 0.0.0
#
# @author Daniel Rieck [daniel.rieck@wsu.edu] (https://github.com/invokeImmediately)
# @link https://github.com/invokeImmediately/PSamplio/blob/main/Build-PowerShell-Profile.ps1
# @license MIT License — Copyright (c) 2022 Daniel C. Rieck
#   Permission is hereby granted, free of charge, to any person obtaining a copy of this software
#     and associated documentation files (the "Software"), to deal in the Software without
#     restriction, including without limitation the rights to use, copy, modify, merge, publish,
#     distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
#     Software is furnished to do so, subject to the following conditions:
#   The above copyright notice and this permission notice shall be included in all copies or
#     substantial portions of the Software.
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
#     BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#     NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
#     DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#     OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
####################################################################################################

function Build-PowerShell-Profile {
  Param (
    [ string ]
    $bumpMode
  )
  begin {
    function Build-Profile-from-Cmd-Src-Files {
      # Prep an empty string that will store a serial concatenation of all commands in this project
      $allCmds = ""

      # Prep an empty string that will store the table of contents and track line numbers
      $bldHdr = Get-Prof-Hdr-from-Last-Build
      $tocEntries = [System.Collections.ArrayList]@()
      $lastLineNum = (Measure-Object -InputObject $bldHdr -Line).Lines + 1

      # Dynamically obtain a list of all command files in the PSamplio project
      $cmdSrcFileList = Get-List-of-PS-Cmd-Src-Files

      # ·> Extract the command from each source file while building the table of contents section
      # ·  for inline documentation <·
      $cmdSrcFileList | % {

        # ·> Obtain the contents of the file as an array of lines and a multi-line string, the latter
        # ·  of which will be used in combination with regex pattern matching <·
        $cmdContents = Get-Content -Path ('..\PSamplio\Commands\' + $_.Name) -Raw
        
        # ·> Remove the file header comment block from the file's contents, thus yielding only the
        # ·  command itself <·
        $cmdOnly = Trim-File-Hdr-from-Cmd-Src $cmdContents
        $allCmds += $cmdOnly

        # Isolate the name of the function
        $cmdDetails = Get-Cmd-Details-From-Src $cmdOnly
        $cmdNm = $cmdDetails.cmdNm
        $cmdLnNum = $cmdDetails.lnNum

        # Track where the line number will fall in the built profile
        $tocEntries.Add( @( $cmdNm, ($lastLineNum + $cmdLnNum ) ) )
        $lastLineNum += (Measure-Object -InputObject $cmdOnly -Line).Lines
      }
      return $tocEntries
    }

    function Get-Prof-Hdr-from-Last-Build {
      $bldDirValid = ( Test-Path '..\PSamplio\' -PathType Container ) -and ( Test-Path '..\PSamplio\.git' -PathType Container )
      if ( -not $bldDirValid ) {
        Write-Error -Exception ( [System.IO.DirectoryNotFoundException]::new( 'Because the current directory does not seem to resemble a PSamplio repo, I am aborting the build process.' ) ) -ErrorAction Stop
      }
      $prevBldPrsnt = Test-Path '..\PSamplio\Microsoft.PowerShell_profile.ps1' -PathType Leaf
      if ( -not $prevBldPrsnt ) {
        Gen-Init-Prof-Build
      }
      $prevBld = Get-Content -Path '..\PSamplio\Microsoft.PowerShell_profile.ps1' -Raw
      [regex]$hdrPtrn = '(?mi)^#+\r?\n(?:#.*\r?\n)*#+\r?\n'
      $mtchInf = Select-String -InputObject $prevBld -Pattern $hdrPtrn -AllMatches
      if ( -not $mtchInf.Length -gt 0 ) {
        Write-Error -Exception ( [System.IO.FileLoadException]::new( 'Did not find an appropriately formed file header comment in the previous build Microsoft.PowerShell_profile.ps1. Aborting the build process.' ) ) -ErrorAction Stop
      }
      return $prevBld.substring( 0, $mtchInf.Matches[0].Length )
    }

    function Gen-Init-Prof-Build {
      "####################################################################################################{0}# ▐▀▄▀▌▀█▀ ▄▀▀▀ █▀▀▄ ▄▀▀▄ ▄▀▀▀ ▄▀▀▄ █▀▀▀▐▀█▀▌  █▀▀▄ ▄▀▀▄▐   ▌█▀▀▀ █▀▀▄ ▄▀▀▀ █  █ █▀▀▀ █    █{0}# █ ▀ ▌ █  █    █▄▄▀ █  █ ▀▀▀█ █  █ █▀▀▀  █    █▄▄▀ █  █▐ █ ▌█▀▀  █▄▄▀ ▀▀▀█ █▀▀█ █▀▀  █  ▄ █  ▄ ▀{0}# █   ▀▀▀▀  ▀▀▀ ▀  ▀▄ ▀▀  ▀▀▀   ▀▀  ▀     █  ▀ █     ▀▀  ▀ ▀ ▀▀▀▀ ▀  ▀▄▀▀▀  █  ▀ ▀▀▀▀ ▀▀▀  ▀▀▀{0}#{0}#             █▀▀▄ █▀▀▄ ▄▀▀▄ █▀▀▀ ▀█▀ █    █▀▀▀   █▀▀▄ ▄▀▀▀ ▄█{0}#       ▀     █▄▄▀ █▄▄▀ █  █ █▀▀▀  █  █  ▄ █▀▀    █▄▄▀ ▀▀▀█  █{0}#         ▀▀▀ █    ▀  ▀▄ ▀▀  ▀    ▀▀▀ ▀▀▀  ▀▀▀▀ ▀ █    ▀▀▀  ▄█▄▌{0}#{0}# PowerShell profile containing commands that are useful for working on web coordination and front-{0}#   end development of WSUWP websites at Washington State University. The profile was originally{0}#   developed to support work on the websites of the the Division of Academic Engagement and Student{0}#   Achievement in the Office of the Provost and Executive Vice President.{0}#{0}# @version 1.11.1{0}#{0}# @author Daniel Rieck [daniel.rieck@wsu.edu] (https://github.com/invokeImmediately){0}# @link https://github.com/invokeImmediately/PSamplio/blob/main/Microsoft.PowerShell_profile.ps1{0}# @link https://github.com/wsuwebteam/web-design-system{0}# @link https://github.com/wsuwebteam/wsuwp-theme-wds{0}# @link https://github.com/washingtonstateuniversity/WSUWP-Platform{0}# @link https://github.com/washingtonstateuniversity/WSUWP-spine-parent-theme{0}# @license MIT License — Copyright (c) 2022 Daniel C. Rieck{0}#   Permission is hereby granted, free of charge, to any person obtaining a copy of this software{0}#     and associated documentation files (the ""Software""), to deal in the Software without{0}#     restriction, including without limitation the rights to use, copy, modify, merge, publish,{0}#     distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the{0}#     Software is furnished to do so, subject to the following conditions:{0}#   The above copyright notice and this permission notice shall be included in all copies or{0}#     substantial portions of the Software.{0}#   THE SOFTWARE IS PROVIDED ""AS IS"", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING{0}#     BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND{0}#     NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,{0}#     DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,{0}#     OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.{0}####################################################################################################{0}" -f ([Environment]::NewLine) | Set-Content '..\PSamplio\Microsoft.PowerShell_profile.ps1'
    }

    function Get-List-of-PS-Cmd-Src-Files {
      $list = Get-ChildItem -Path '..\PSamplio\Commands\' -Filter "*.ps1"
      return $list
    }

    function Trim-File-Hdr-from-Cmd-Src {
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

    function Get-Cmd-Details-From-Src {
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

