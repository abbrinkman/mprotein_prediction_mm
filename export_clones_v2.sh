#!/bin/bash

# usage: ./scriptname <file.clns>
# note: the output generated will be save in the same directory as the inputfile

outname=$(echo $1 |sed 's/\.clns/_v2.txt/')

# tempfile with presets
presetfile=$(mktemp)

cat <<EOF > $presetfile
-cloneId
-count
-fraction
-vHitsWithScore
-dHitsWithScore
-jHitsWithScore
-cHitsWithScore
-aaFeature FR1
-aaFeatureImputed FR1
-aaMutations FR1
-aaFeature CDR1
-aaFeatureImputed CDR1
-aaMutations CDR1
-aaFeature FR2
-aaFeatureImputed FR2
-aaMutations FR2
-aaFeature CDR2
-aaFeatureImputed CDR2
-aaMutations CDR2
-aaFeature FR3
-aaFeatureImputed FR3
-aaMutations FR3
-aaFeature CDR3
-aaFeatureImputed CDR3
-aaFeature GermlineVCDR3Part
-aaFeatureImputed GermlineVCDR3Part
-aaMutations GermlineVCDR3Part
-aaFeature DRegion
-aaFeatureImputed DRegion
-aaMutations DRegion
-aaFeature GermlineJCDR3Part
-aaFeatureImputed GermlineJCDR3Part
-aaMutations GermlineJCDR3Part
-aaFeature FR4
-aaFeatureImputed FR4
-aaMutations FR4
-chains
EOF

~/tools/mixcr-3.0.3/mixcr exportClones -o -c IG -pf $presetfile $1 $outname

rm $presetfile
