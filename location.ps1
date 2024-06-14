#!/usr/bin/env pwsh

# Determine state and county of the FIPS code that appears
# in the third underscore-separated field of the specified
# filename.

[CmdletBinding()]
param(
  [Parameter(Mandatory, Position=0)] [string]$Filename,
  [string]$CountyList = './counties.json',
  [string]$StateList = './states.json'
)

$default_state = 'UN'
$default_county = 'Unknown'
$states = get-content $StateList | convertfrom-json
$counties = get-content $CountyList | convertfrom-json

$fields = $Filename -split '_'
$code = $fields[2]
if ($code) {
  $state_code = $code.substring(0, 2)
  $county_code = $code.substring(2)
  $state = $states | ?{ $_.STATE -eq $state_code } | select-object -expand STUSAB
  $county = $counties | ?{ $_.STATEFP -eq $state_code -and $_.COUNTYFP -eq $county_code } | select-object -expand COUNTYNAME
}

[PSCustomObject]@{
  state = $state ?? $default_state
  county = $county ?? $default_county
}

