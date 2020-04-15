#!/bin/bash

# usage: ./scriptname <file.clns>
# note: the output generated will be saved in /home/arjen/path/data/jacobs/mixcr/clones_v3

outname="/home/arjen/path/data/jacobs/mixcr/clones_v3/"$(basename $1 .clns)_v3.txt

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
-nFeature FR1
-nFeatureImputed FR1
-nMutations FR1
-nFeature CDR1
-nFeatureImputed CDR1
-nMutations CDR1
-nFeature FR2
-nFeatureImputed FR2
-nMutations FR2
-nFeature CDR2
-nFeatureImputed CDR2
-nMutations CDR2
-nFeature FR3
-nFeatureImputed FR3
-nMutations FR3
-nFeature CDR3
-nFeatureImputed CDR3
-nFeature GermlineVCDR3Part
-nFeatureImputed GermlineVCDR3Part
-nMutations GermlineVCDR3Part
-nFeature DRegion
-nFeatureImputed DRegion
-nMutations DRegion
-nFeature GermlineJCDR3Part
-nFeatureImputed GermlineJCDR3Part
-nMutations GermlineJCDR3Part
-nFeature FR4
-nFeatureImputed FR4
-nMutations FR4
-chains
EOF

~/tools/mixcr-3.0.3/mixcr exportClones -o -c IG -pf $presetfile $1 $outname

rm $presetfile
