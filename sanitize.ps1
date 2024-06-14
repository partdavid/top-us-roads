#!/usr/bin/env pwsh

# Process a record from the CSV file extracted from the ESRI
# shapefiles, filter out those with empty names and sanitize the
# street name, stripping direction prefixes, road type suffixes and
# respelling ordinal numbers. Produce an object with the state and
# county that have been specified, the sanitized name and the original
# name.

[CmdletBinding()]
param(
  [Parameter(Mandatory, ValueFromPipeline)] [PSCustomObject]$Record,
  [string[]]$IncludeMtfccs = @('S1100','S1200','S1400'),
  [string]$State = 'UN',
  [string]$County = 'Unknown',
  # https://www2.census.gov/geo/pdfs/maps-data/data/tiger/tgrshp2023/TGRSHP2023_TechDoc_B.pdf
  [string[]]$StripDirections = @('N','S','E','W','NE','NW','SE','SW','O','NO','SO'),
  [string[]]$StripRoadTypeSuffix = @(
    'Aly',
    'Ave',
    'Blvd',
    'Cr',
    'Ct',
    'Cv',
    'Dr',
    'Cir',
    'Creek',
    'Hwy',
    'Loop',
    'Pl',
    'Pkwy',
    'Rd',
    'Slough',
    'St',
    'Ter',
    'Tpke',
    'Trl',
    'Way'),
  [hashtable]$CanonicalizeOrdinals = @{
    '1st' = 'First'
    '2nd' = 'Second'
    '3rd' = 'Third'
    '4th' = 'Fourth'
    '5th' = 'Fifth'
    '6th' = 'Sixth'
    '7th' = 'Seventh'
    '8th' = 'Eighth'
    '9th' = 'Ninth'
    '10th' = 'Tenth'
    '11th' = 'Eleventh'
    '12th' = 'Twelfth'
    '13th' = 'Thirteenth'
    '14th' = 'Fourteenth'
    '15th' = 'Fifteenth'
    '16th' = 'Sixteenth'
    '17th' = 'Seventeenth'
    '18th' = 'Eighteenth'
    '19th' = 'Nineteenth'
    '20th' = 'Twentieth'
    '21st' = 'Twenty-first'
    '22nd' = 'Twenty-second'
    '23rd' = 'Twenty-third'
    '24th' = 'Twenty-fourth'
    '25th' = 'Twenty-fifth'
    '26th' = 'Twenty-sixth'
    '27th' = 'Twenty-seventh'
    '28th' = 'Twenty-eighth'
    '29th' = 'Twenty-ninth'
    '30th' = 'Thirtieth'
  }
)

process {
  if ($Record.FULLNAME -and $Record.MTFCC -in $IncludeMtfccs) {
    $words = $Record.FULLNAME -split ' '
    if ($words) {
      # Why doesn't -Debug work?
      if ($words.length -gt 1 -and $words[0] -in $StripDirections) {
        $words = $words[1 .. ($words.length - 1)]
      }
      if ($words.length -gt 1 -and $words[-1] -in $StripDirections) {
        $words = $words[0 .. ($words.length - 2)]
      }
      if ($words.length -gt 1 -and $words[-1] -in $StripRoadTypeSuffix) {
        $words = $words[0 .. ($words.length - 2)]
      }
      if ($words[0] -in $CanonicalizeOrdinals.Keys) {
        $words[0] = $CanonicalizeOrdinals[$words[0]]
      }
      [PSCustomObject]@{
        state         = $State
        county        = $County
        name          = $words -join ' '
        original_name = $Record.FULLNAME
      }
    }
  }
}
