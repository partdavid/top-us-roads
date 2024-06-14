# Prerequisites: gmake powershell gdal unzip

PARALLELISM = 20
URL = https://www2.census.gov/geo/tiger/TIGER2023/ROADS/
STATE_FIPS_CODES_URL = https://www2.census.gov/geo/docs/reference/state.txt
COUNTY_FIPS_CODES_BASEURL = https://www2.census.gov/geo/docs/reference/codes2020/cou # /st06_ca_cou2020.txt

# Include these feature codes, full list at:
# https://www2.census.gov/geo/pdfs/reference/mtfccs2022.pdf
INCLUDE_MTFCCS = S1100,S1200,S1400

.PHONY: clean all debug download cleanempty
.ONESHELL:
SHELL = /usr/local/bin/pwsh
# Honored?
.SHELLFLAGS = -NoLogo -NonInteractive -NoProfile -Command


ifneq (oneshell, $(filter oneshell,$(.FEATURES)))
$(error This makefile requires gmake > 3.82 with the oneshell feature)
endif

top-50.txt:	top-100.txt
	get-content top-100.txt | select-object -first 50 | set-content $@

top-100.txt:	allstreets.csv.gz
	gzip -dc allstreets.csv.gz | convertfrom-csv | select-object -expand name | sort | uniq -c | sort -rn | select-object -first 100 | set-content $@

allstreets.csv.gz:	counties.json
	$$location = ./location counties.json
	get-childitem *.csv | % -throttle $(PARALLELISM) -parallel { $$location = ./location $$_.basename; write-host "Converting $$($$_.name) -> $$($$location.County), $$($$location.State)"; get-content $$_ | convertfrom-csv | ./sanitize -Debug -State $$location.State -County $$location.County } | convertto-csv | gzip >$@

csvs:
	get-childitem *.zip | % -throttle $(PARALLELISM) -parallel { ogr2ogr -f CSV "$$($$_.basename).csv" "$$($$_.basename)/$$($$_.basename).shp" -select 'FULLNAME,RTTYP,MTFCC' }

cleanreports:
	(remove-item -force -erroraction SilentlyContinue top-50.txt,top-100.txt,allstreets.csv) || $$True

cleancsvs:
	get-childitem *.zip | %{ remove-item "$$($$_.basename).csv" }

clean:
	(remove-item -erroraction SilentlyContinue states.json,counties.json) || $True
	get-childitem *.zip | %{ remove-item -recurse -force $$_.basename,$$_,"$$($$_.basename).csv" }

cleanempty:
	get-childitem *.zip | %{ if ((get-childitem $$_.basename).length -eq 0) { remove-item $$_.basename } }

cleanunzipped:	cleanempty
	get-childitem *.zip | %{ if (-not (test-path $$_.basename)) { remove-item $$_ } }

states.json:
	invoke-webrequest $(STATE_FIPS_CODES_URL) | select-object -expand content | convertfrom-csv -delimiter '|' | convertto-json | set-content $@

counties.json:	states.json
	get-content states.json | convertfrom-json | % -throttle $(PARALLELISM) -parallel { invoke-webrequest "$(COUNTY_FIPS_CODES_BASEURL)/st$$($$_.STATE)_$$($$_.STUSAB.ToLower())_cou2020.txt" | select-object -expand content | convertfrom-csv -delimiter '|' } | convertto-json | set-content $@

download:	downloadcodes
	invoke-webrequest $(URL) | select-object -expand Links | ?{ $$_.href -like '*.zip' } | % -throttle $(PARALLELISM) -parallel { if (-not (test-path $$_.href)) { invoke-webrequest "$(URL)/$$($$_.href)" -outfile $$_.href }; if (-not (test-path $$_.href.TrimEnd('.zip'))) { new-item -type Directory $$_.href.TrimEnd('.zip'); unzip -u $$_.href -d $$_.href.TrimEnd('.zip') } }
