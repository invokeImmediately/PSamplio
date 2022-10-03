####################################################################################################
# ▄▀▀▀ ▄▀▀▄ ▐▀▀▄▐   ▌█▀▀▀ █▀▀▄ ▐▀█▀▌   █  █ █▀▀▄ ▀█▀    ▄▀▀▀▐▀█▀▌█▀▀▄   ▐▀█▀▌▄▀▀▄   ▐   ▌▀█▀ ▐▀▀▄
# █    █  █ █  ▐ █ █ █▀▀  █▄▄▀   █  ▀▀ █  █ █▄▄▀  █  ▀▀ ▀▀▀█  █  █▄▄▀ ▀▀  █  █  █ ▀▀▐ █ ▌ █  █  ▐
#  ▀▀▀  ▀▀  ▀  ▐  █  ▀▀▀▀ ▀  ▀▄  █      ▀▀  ▀  ▀▄▀▀▀    ▀▀▀   █  ▀  ▀▄    █   ▀▀     ▀ ▀ ▀▀▀ ▀  ▐
#
#    █▀▀▄ ▄▀▀▄▐   ▌▄▀▀▀    █▀▀▀ ▀█▀ █    █▀▀▀ ▐▀▀▄ ▄▀▀▄ ▐▀▄▀▌█▀▀▀   █▀▀▄ ▄▀▀▀ ▄█
#    █  █ █  █▐ █ ▌▀▀▀█ ▀▀ █▀▀▀  █  █  ▄ █▀▀  █  ▐ █▄▄█ █ ▀ ▌█▀▀    █▄▄▀ ▀▀▀█  █
#    ▀▀▀   ▀▀  ▀ ▀ ▀▀▀     ▀    ▀▀▀ ▀▀▀  ▀▀▀▀ ▀  ▐ █  ▀ █   ▀▀▀▀▀ ▀ █    ▀▀▀  ▄█▄▌
# 
# Convert a URI string, which contain problematic characters such as forward slashes and colons, to
#   a windows-compatible file name.
#
# @version 1.0.0
#
# @author Daniel Rieck [daniel.rieck@wsu.edu] (https://github.com/invokeImmediately)
# @link https://github.com/invokeImmediately/PSamplio/blob/main/Commands/Compare-Directories.ps1
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

<#
.SYNOPSIS
    Convert a URI string into a string that is compatible with file naming rules
    in Windows.
.DESCRIPTION
    Replaces "/", ".", and ":" with "⁄" (U+2044: Fraction slash), "·" (U+00B7:
    Middle dot), and "¦" (U+00A6: Broken bar), respectively.
.PARAMETER  uri
    Mandatory uri string.
.PARAMETER  keepScheme
    Optional boolean flag that controls whether the scheme component followed by
    the two slashes preceding the authority component are dropped. Default:
    false
#>
Function Convert-Uri-Str-to-Windows-Filename {
  Param (
    [ Parameter( Mandatory = $true,
      ValueFromPipelineByPropertyName = $true ) ]
    [ string ]
    $uri,

    [ Parameter( Mandatory = $false,
      ValueFromPipelineByPropertyName = $true ) ]
    [ bool ]
    $keepProtocol = $false
  )
  If ( !$keepProtocol ) {
    $uri = $uri -replace "https?://", ""
  }
  $uriFn = ( ( $uri -replace '/', '⁄' ) -replace '\.', '·' ) -replace ':', '¦'
  Return $uriFn
}
