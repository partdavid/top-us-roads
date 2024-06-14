# Top U.S. Roads

This repository contains scripts to extract U.S. Census data for the
"All Roads" TIGER/Line shapefile (for each state and county in the
United States), does some light sanitization on the data and produces
three reports:

- [`top-100.txt`](./top-100.txt) and [`top-50.txt`](./top-50.txt) --
  Lists of the top 100 and top 50 street names
- [`allstreets.csv.gz`] -- A gzip-compressed CSV file of all the
  streets in the U.S., with county, state and original and sanitized
  versions of the street names

## Using this Repository

You'll need `gmake`, the `ogr2ogr` tool installed with `gdal`,
the `unzip` command and Powershell core. On MacOS, you can
install these with:

```
brew install make powershell gdal
```

Check the [`Makefile`](./Makefile) which has some URLs at the
top that tell you the specific sources of U.S. Census data it
will download and use, and some configurations (for example,
the MFTCC codes that are considered "streets").

Then you can do the download of all the individual county shapefiles
by running `gmake cleanreports download` (using the `cleanreports`
target ensures that the summary reports I generated and include are
going to get regenerated).

Once that's successful, you can do `gmake csvs`, which will generate
CSV files from the ESRI shapefiles using the `ogr2ogr` tool.

Once that works, you can do `gmake top-50.txt` to generate the
reports.

To remove the reports so you can remake them, do `gmake cleanreports`.
To remove the CSV files, do `gmake cleancsvs`. To clean everything to
start over, go `gmake clean`.

## Analyzing the Data

The `allstreets.csv` file can be obtained by running `gzip -d
allstreets.csv.gz`. It has about 9.4M rows, and I'm not sure how
well Excel or another spreadsheet program handles that, so you
might want to use some tool to extract it first, following
the pattern here (or in the programming language of your choice).

## Contributing, Details and Caveats

There is a lot of potential work that can be done to further clean up
the data and conform to a particular definition of what a street
is. These scripts are not well-tested, either, so I expect there are
gaps and insufficiencies; to a first approximation, if the goal is to
estimate the most common street names, it doesn't seem like they matter
much. This work was inspired by [Reddit user darinhq's 2014 analysis](https://www.reddit.com/r/dataisbeautiful/comments/2oo23a/comment/cmowsmt/), which I discovered through [a quiz on jetpunk.com](https://www.jetpunk.com/user-quizzes/23069/common-american-street-names-quiz), and largely agrees with it, even though that was done with
only Primary and Secondary roads (which covers only highways and major
thoroughfares), which is why I think inaccuracies are probably marginal.

The [`./sanitize`](./sanitize.ps1) script describes the transformations
and canonicalizations are done, like stripping the direction qualifier
and road type qualifier and respelling numerical streets. This is where
a lot could probably be done to improve the data. Create a pull request
and I may review it, on no particular schedule.

Counties are considered separately and no attempt is made to either
knit roads in neighboring counties together or split them on some
other basis, like municipality.

I've checked in some generated artifacts for convenience, like
the `states.json`, `counties.json` (though their source URL is given,
it's not as convenient to find as the shapefiles) and the final
reports to "publish" these results.

The license in this repository describes rules for reuse and
distribution of these small bits of source code; the data is public.
