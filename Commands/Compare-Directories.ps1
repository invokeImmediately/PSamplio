################################################################################
# Compare- █▀▀▄ ▀█▀ █▀▀▄ █▀▀▀ ▄▀▀▀▐▀█▀▌▄▀▀▄ █▀▀▄ ▀█▀ █▀▀▀ ▄▀▀▀ ░░░░░░░░░░░░░░▒▓█
# ░░░░░░░░ █  █  █  █▄▄▀ █▀▀  █     █  █  █ █▄▄▀  █  █▀▀  ▀▀▀█ ░░░░░░░░░░░░▒▓█
# ░░░░░░░░ ▀▀▀  ▀▀▀ ▀  ▀▄▀▀▀▀  ▀▀▀  █   ▀▀  ▀  ▀▄▀▀▀ ▀▀▀▀ ▀▀▀ .ps1 ░░░░░░▒▓█
#
# Find differences in the file structure between two directories.
#
# @version 1.0.0
#
# @author Daniel Rieck
#   [daniel.rieck@wsu.edu]
#   (https://github.com/invokeImmediately)
#
# @link https://github.com/invokeImmediately/PSamplio/blob/main/…
#   …Commands/Compare-Directories.ps1
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

<#
.SYNOPSIS
    Find differences in the file structure between two directories.
.PARAMETER  diffName
    Path to the directory that will be compared to a reference. (Mandatory)
.PARAMETER  refName
    Reference directory that will serve as the basis of the comparison. (Mandatory)
#>
Function Compare-Directories {
  Param (
    [ Parameter( Mandatory=$true ) ]
    [ string ]
    $diffName,

    [ Parameter( Mandatory=$true ) ]
    [ string ]
    $refName
  )
  Try
  {
    $diffItem = Get-Item -ErrorAction Stop -Path $diffName
    $refItem = Get-Item -ErrorAction Stop -Path $refName
    $fsoDiff = gci -ErrorAction Stop -Recurse -path $diffName | ? { $_.FullName -notmatch "node_modules" }
    $fsoRef = gci -ErrorAction Stop -Recurse -path $refName | ? { $_.FullName -notmatch "node_modules" }
    $separator = "-" * 100
    Write-Host (-join ($separator, "`nResults of Compare-Object with basis as name, length.`nDifference Object (=>) ", $diffItem.FullName, "`nReference Object (<=) ", $refItem.FullName, "`n", $separator))
    Compare-Object -ErrorAction Stop -ReferenceObject $fsoRef -DifferenceObject $fsoDiff -Property Name,Length,LastWriteTime -PassThru | Format-Table SideIndicator, Name, @{Label="Length (kb)"; Expression={[math]::Round( ( $_.Length / 1kb ),1 ) } }, LastWriteTime
  }
  Catch
  {
    $itemName = $_.Exception.ItemName
    If ([string]::IsNullOrEmpty($itemName)) {
      $itemName = "Script error"
    }
    Write-Host (-join ($itemName, ": ", $_.Exception.Message))
  }
}
