#!/bin/bash

# Author: MSK
# Last Updated: Friday November 23rd 2007
# Version: 0.5

# ::Overview::
# ------------
# This script uses the numbers input to contruct a pie graph in SVG format.
# Each number input corresponds to a segment in the pie chart. 
#
# Various arithmetic and geometric calculations are performed on the input 
# in order to generate the appropriate coordinates for the pie segments and 
# labels.
#
# Two SVG template files are used.  Each template is used once for each of the 
# numbers input, one template 'circleSegmentPathTemplate.svg' to draw the 
# segment and one template 'segmentLabelsTextTemplate.svg' to draw the label 
# for the segment.
#
# The coordinates that are calculated for each segment and each segment label 
# are simply substituted into the templates.
# 
# Some default colors and labels to apply to the segments are defined below,
# the user should edit the file pieChart.rc to customize segment colors and
# segment labels.

# ::Future development::
# ----------------------
# Allow the user to pass in a list of colors and a list of labels.
# Allow the user to choose ordering of the segments, custom/preserve, 
# ascending, or descending.
# Allow the user to choose starting point of the first segment.
# Allow the user to choose text label orientation, stagitta, chord, 
# horizontal + interior and exterior versions of these.
# Allow the user to choose text label size.
# Allow the user to choose radius of chart.

# ::Version History::
# -------------------
# This pie chart generation utility has not used version control.
#
# Further this version history is written in retrospect at the point of 
# version 0.4 on November 21st 2007 and coincides with the release of 
# version 0.7 of the 'test counts/stats generation' utility. 
#
# A factor contributing to my motivation to write this utility was its
# anticipated use in the 'test counts/stats generation' utility for CALs
# Management Tools.  See the 0.7 and 0.8 entries in the version history 
# of the driver file, 'getTestCounts.sh', for more details.

# Version 0.0
# -----------
# - used only one template
# - had no labels
# - had no frame/bounding-box
# - had no segment outlines
# - very buggy

# Version 0.1
# -----------
# Various improvements and bug fixes.
# - added bounding box
# - added segment outlines
# - segment outline at boundary between first and last segment.

# Version 0.2
# -----------
# - added ability to set colors in script
# - added ability to set labels in script
# - added label template
# - label drawing is buggy
# - found bug when a segment begins in quadrant IV and ends in quadrant II

# Version 0.3
# -----------
# - fixed bugs with label drawing, but still not perfect in some cases 
#   i.e. orientation of label text and
#        centering of label is slightly off, very noticeable in small slices

# Version 0.4
# -----------
# - created 'svg' directory to put SVG templates and SVG output into
# - added the '::Overview::' and '::Version History::' sections/headers to this
#   BASH script which is the driver for this SVG pie chart generation utility. 
# - added coverage classes and coverage quadrants
# - fixed bug with segments beginning in quadrant IV and ending in quadrant II

# Version 0.5
# -----------
# - created 'pieChart.rc', copied color, label, and radius variables to it.
# - added 'chartMargin', 'chartPadding', 'colorOfSegmentOutline', and 
#   'widthOfSegmentOutline' as config variables, also in pieChart.rc
# - fixed bug with segments beginning in quadrant I and ending in quadrant III
# - fixed bug with segments beginning in quadrant I and ending in quadrant II
#
# Notes on bugs:
#   The bugs are fixed by setting the 'large-arc-flag' and the 'sweep-flag' 
#   of the 'path' elements 'A' elliptical-arc command to an appropriate 
#   combination of values.
#
#   The possible combinations are only four:
#   (0 0), (0 1), (1, 0), and (1 1), where (0 1) provides the desired result
#   for most segments.  There are also four coverage classes, this just a
#   coincidence, each (large-arc-flag sweep-flag) combination does not in 
#   general map to a unique coverage class, nor does each coverage class
#   map to a unique (large-arc-flag sweep-flag) combination.  Further only
#   the combinations (0 1) and (1 1) are used here-in, so the sweep flag is
#   always 1 and maybe could be made a constant.
#
#   The appropriate combination for segments beginning in quadrant IV and 
#   ending in quadrant II is (1 1).  While these segments and those beginning 
#   in quadrant I and ending in quadrant III are both members of coverage 
#   class C, they do not share the same combination, the later requires (0 1).
#   It is worth noting also that the same combination is good for two members
#   of two different coverage classes, as exemplified below.
#   
#   The segments beginning in quadrant I and ending in quadrant II are the 
#   the only members of coverage class D, they require flag combination (1 1).
#   
#   This leaves coverage classes A and B bioth of which use case (0 1) for the
#   (large-arc-flag sweep-flag) combination.  These two coverage classes have
#   greater membership than the others and I have not tested instances of all
#   the members, so more bugs of this nature may be found in the future. 


# The following is the list of configuration variable names that can be set
# by editing 'pieChart.rc'.  If you remove a variable from the list then the 
# default value below will be used instead.  Removing a variable name from
# this list is one way to have the default values override the value set in
# 'pieChart.rc'.
configurationVariables="segmentFillColors segmentLabels radiusOfPieChart colorOfSegmentOutline widthOfSegmentOutline"

# The following are the default values for the configuration variables. 
# If these variables exist in 'pieChart.rc' then the values found there 
# will override these default values.
segmentLabels="Reading Mathematics Language-Usage Social-Studies Geography"
segmentFillColors="red orange yellow green blue"
radiusOfPieChart="185"
chartMargin="5"
chartPadding="10"
colorOfSegmentOutline="black"
widthOfSegmentOutline="1"

PI="C/D"
PI="3.14159265358979323846"
degreesPerRadian="57.2957795"
degreesPerRadian=`printf "scale=10; 180 / $PI\n" | bc -l`

configurationDirectory="./"
svgDirectory="./svg/"

configurationFile="pieChart.rc"
pieChartSvg="pieChart.svg"
segmentSvgTemplate="circleSegmentPathTemplate.svg"
segmentLabelSvgTemplate="segmentLabelTextTemplate.svg"

configurationFile="$configurationDirectory$configurationFile"
pieChartSvg="$svgDirectory$pieChartSvg"
segmentSvgTemplate="$svgDirectory$segmentSvgTemplate"
segmentLabelSvgTemplate="$svgDirectory$segmentLabelSvgTemplate"



printf "\nBegin: Creation of SVG pie graph to follow ...\n"



# -----------
# Beg Phase 0
# -----------
if test -e "$configurationFile";
	then
		configurationVariables=`printf "$configurationVariables" | sed -e 's/[\t][\t]*/ /g' -e 's/[ ][ ]*/ /g'`
		numConfigVariables=`printf "$configurationVariables" | wc -w | cut -d " " -f 1 | sed -e 's/[ ][ ]*//g'`
		configVarCount=0
		
		#for x in $configVariableName
		#	do
		#		printf "\n$x\n"
		#		x="$configVariableValue"
		#		printf ": $x\n"
		#	done;

		printf "\n"
		printf "\nWHILE LOOP #0:"
		printf "\n--------------"


		while test "$configVarCount" -lt "$numConfigVariables";
			do
				configVarCount=`expr $configVarCount + 1`
				currConfigVariable=`printf "$configurationVariables" | cut -d " " -f $configVarCount | sed -e 's/[ ][ ]*//g'`
				currConfigVariable=`grep -v -e "^#" -e "^[\t ]*$" $configurationFile | grep "$currConfigVariable" | tail -n 1`
				currConfigVariable=`printf "$currConfigVariable" | sed -e 's/[\t][\t]*/ /g' -e 's/[ ][ ]*/ /g'`
				configVariableName=`printf "$currConfigVariable" | cut -d "=" -f 1`
				configVariableValue=`printf "$currConfigVariable" | cut -d "=" -f 2`
	
				#printf "\n$configVarCount: $configVariableName = $configVariableValue"
				#$configVariableName="$configVariableValue" 

				if test "$configVariableName" = "segmentLabels";
					then
						configVariableValue=`printf "$configVariableValue"`
						segmentLabels="$configVariableValue"
				fi;

				if test "$configVariableName" = "segmentFillColors";
					then
						#configVariableValue=`printf "$configVariableValue" | sed -e 's/"/\\\"/g'`
						configVariableValue=`printf "$configVariableValue"`
						segmentFillColors="$configVariableValue"
				fi;

				if test "$configVariableName" = "radiusOfPieChart";
					then
						configVariableValue=`printf "$configVariableValue" | sed -e 's/\"//g'`
						radiusOfPieChart="$configVariableValue"
				fi;

				if test "$configVariableName" = "chartMargin";
					then
						configVariableValue=`printf "$configVariableValue" | sed -e 's/\"//g'`
						chartMargin="$configVariableValue"
				fi;
	
				if test "$configVariableName" = "chartPadding";
					then
						configVariableValue=`printf "$configVariableValue" | sed -e 's/\"//g'`
						chartPadding="$configVariableValue"
				fi;
	
				if test "$configVariableName" = "colorOfSegmentOutline";
					then
						configVariableValue=`printf "$configVariableValue" | sed -e 's/\"//g'`
						colorOfSegmentOutline="$configVariableValue"
				fi;
	
				if test "$configVariableName" = "widthOfSegmentOutline";
					then
						configVariableValue=`printf "$configVariableValue" | sed -e 's/\"//g'`
						widthOfSegmentOutline="$configVariableValue"
				fi;
				
				#printf "\n$configVarCount: $configVariableName = $configVariableValue"

			done;

fi;

centerXOfPieChart=`expr $radiusOfPieChart + $chartPadding + $chartMargin`
centerYOfPieChart="$centerXOfPieChart"
viewBoxWidth=`expr \\( $radiusOfPieChart + $chartPadding + $chartMargin \\) \* 2`
viewBoxHeight="$viewBoxWidth"

numSegmentsInPie="$#"

quantitiesAssociatedWithEachSliceOfPie="$@"
quantitiesAssociatedWithEachSliceOfPie=`printf "$quantitiesAssociatedWithEachSliceOfPie" | sed -e 's/[ ][ ]*/ /g'`
quantitiesAssociatedWithEachSliceOfPieInAscendingOrder=`printf "$quantitiesAssociatedWithEachSliceOfPie" | sed -e 's/ /\n/g' | sort -g -s | sed -e :a -e N -e 's/\n/ /' -e ta`
quantitiesAssociatedWithEachSliceOfPieInDescendingOrder=`printf "$quantitiesAssociatedWithEachSliceOfPie" | sed -e 's/ /\n/g' | sort --general-numeric-sort --stable --reverse | sed -e :a -e N -e 's/\n/ /' -e ta`

smallestSlice=`printf "$quantitiesAssociatedWithEachSliceOfPieInAscendingOrder" | cut -d " " -f 1`
largestSlice=`printf "$quantitiesAssociatedWithEachSliceOfPieInDescendingOrder" | cut -d " " -f 1`

printf "\nNumber of segments in this pie chart: $numSegmentsInPie"
printf "\nQuantities associated with each slice of pie: $quantitiesAssociatedWithEachSliceOfPie"

printf "\n\nsegmentLabels = $segmentLabels"
printf "\nsegmentFillColors = $segmentFillColors"
printf "\nradiusOfPieChart = $radiusOfPieChart"

printf "\nchartMargin = $chartMargin, chartPadding = $chartPadding"
printf "\nviewBoxWidth = $viewBoxWidth, viewBoxHeight = $viewBoxHeight"

printf "\n\nPie slices ascending: $quantitiesAssociatedWithEachSliceOfPieInAscendingOrder"
printf "\nPie slices descending: $quantitiesAssociatedWithEachSliceOfPieInDescendingOrder"
printf "\nLargest slice: $largestSlice"
printf "\nSmallest slice: $smallestSlice"
# -----------
# End Phase 0
# -----------



# -----------
# Beg Phase 1
# -----------
currSegmentOfPie=0
numCurrSegment=0
ratiosOfSlicesToSmallestSlice=""
sumOfSlices=0

printf "\n"
printf "\nWHILE LOOP #1:"
printf "\n--------------"

while test $currSegmentOfPie -lt $numSegmentsInPie;
	do
		currSegmentOfPie=`expr $currSegmentOfPie + 1`
		numCurrSegment=`printf "$quantitiesAssociatedWithEachSliceOfPieInAscendingOrder" | cut -d " " -f $currSegmentOfPie`
		ratioOfCurrSliceToSmallestSlice=`printf "scale = 10; $numCurrSegment / $smallestSlice\n" | bc -l`
		ratiosOfSlicesToSmallestSlice="$ratiosOfSlicesToSmallestSlice $ratioOfCurrSliceToSmallestSlice"
		sumOfSlices=`expr $sumOfSlices + $numCurrSegment`
	done;

ratiosOfSlicesToSmallestSlice=`printf "$ratiosOfSlicesToSmallestSlice" | sed -e 's/^ //g'`

printf "\nRatios of slices to the smallest slice: $ratiosOfSlicesToSmallestSlice"
printf "\nSum of slices: $sumOfSlices"
# -----------
# End Phase 1
# -----------



# -----------
# Beg Phase 2
# -----------
currSegmentOfPie=0
currSegmentPercentageOfPie=0
currSegmentSweepAngle=0
currSegmentAzimuth="0"
currSegmentQuadrant=0
azimuthsOfSegments="0.0"
percentagesOfSegments=""
begQuadrantsOfSegments=""
endQuadrantsOfSegments=""

printf "\n"
printf "\nWHILE LOOP #2:"
printf "\n--------------"

while test $currSegmentOfPie -lt $numSegmentsInPie;
	do
		currSegmentOfPie=`expr $currSegmentOfPie + 1`
		numCurrSegment=`printf "$quantitiesAssociatedWithEachSliceOfPieInAscendingOrder" | cut -d " " -f $currSegmentOfPie`
		currSegmentPercentageOfPie=`printf "scale = 10; $numCurrSegment / $sumOfSlices\n" | bc -l`
		currSegmentSweepAngle=`printf "scale = 8; $currSegmentPercentageOfPie * 360\n" | bc -l`
		currSegmentAzimuth=`printf "scale = 8; $currSegmentAzimuth + $currSegmentSweepAngle\n" | bc -l`
		currSegmentPercentageOfPie=`printf "scale = 8; $currSegmentPercentageOfPie * 100\n" | bc -l`

		percentagesOfSegments="$percentagesOfSegments $currSegmentPercentageOfPie"
		sweepAnglesOfSegments="$sweepAnglesOfSegments $currSegmentSweepAngle"
		azimuthsOfSegments="$azimuthsOfSegments $currSegmentAzimuth"

		begAzimuthOfCurrentSegment=`printf "$azimuthsOfSegments" | cut -d " " -f $currSegmentOfPie`
		nextSegmentOfPie=`expr $currSegmentOfPie + 1`
		endAzimuthOfCurrentSegment=`printf "$azimuthsOfSegments" | cut -d " " -f $nextSegmentOfPie`

		begAzCurrSeg=`printf "$begAzimuthOfCurrentSegment" | cut -d "." -f 1`
		endAzCurrSeg=`printf "$endAzimuthOfCurrentSegment" | cut -d "." -f 1`

		sagittaAzimuthOfCurrentSegment=`printf "scale = 8; ($endAzimuthOfCurrentSegment + $begAzimuthOfCurrentSegment) / 2\n" | bc -l`
		sagAzCurrSeg=`printf "$sagittaAzimuthOfCurrentSegment" | cut -d "." -f 1`
		segmentSagittaAzimuths="$segmentSagittaAzimuths $sagittaAzimuthOfCurrentSegment"
		

		begQuadrantOfCurrentSegment=""
		endQuadrantOfCurrentSegment=""
		sagittaQuadrantOfCurrentSegment=""

		if test $begAzCurrSeg -ge 0 -a $begAzCurrSeg -le 90; 
			then
				begQuadrantOfCurrentSegment="1"
			else
				if test $begAzCurrSeg -ge 90 -a $begAzCurrSeg -le 180;
					then
						begQuadrantOfCurrentSegment="4"
					else
						if test $begAzCurrSeg -ge 180 -a $begAzCurrSeg -le 270;
							then
								begQuadrantOfCurrentSegment="3"
							else
								if test $begAzCurrSeg -ge 270 -a $begAzCurrSeg -le 360;
					 				then
										begQuadrantOfCurrentSegment="2"
								fi;
						fi;
				fi;
		fi;

		begQuadrantsOfSegments="$begQuadrantsOfSegments $begQuadrantOfCurrentSegment"

		if test $endAzCurrSeg -ge 0 -a $endAzCurrSeg -le 90; 
			then
				endQuadrantOfCurrentSegment="1"
			else
				if test $endAzCurrSeg -ge 90 -a $endAzCurrSeg -le 180;
					then
						endQuadrantOfCurrentSegment="4"
					else
						if test $endAzCurrSeg -ge 180 -a $endAzCurrSeg -le 270;
							then
								endQuadrantOfCurrentSegment="3"
							else
								if test $endAzCurrSeg -ge 270 -a $endAzCurrSeg -le 360;
					 				then
										endQuadrantOfCurrentSegment="2"
								fi;
						fi;
				fi;
		fi;

		endQuadrantsOfSegments="$endQuadrantsOfSegments $endQuadrantOfCurrentSegment"

		if test $sagAzCurrSeg -ge 0 -a $sagAzCurrSeg -le 90; 
			then
				sagittaQuadrantOfCurrentSegment="1"
			else
				if test $sagAzCurrSeg -ge 90 -a $sagAzCurrSeg -le 180;
					then
						sagittaQuadrantOfCurrentSegment="4"
					else
						if test $sagAzCurrSeg -ge 180 -a $sagAzCurrSeg -le 270;
							then
								sagittaQuadrantOfCurrentSegment="3"
							else
								if test $sagAzCurrSeg -ge 270 -a $sagAzCurrSeg -le 360;
					 				then
										sagittaQuadrantOfCurrentSegment="2"
								fi;
						fi;
				fi;
		fi;

		sagittaQuadrantsOfSegments="$sagittaQuadrantsOfSegments $sagittaQuadrantOfCurrentSegment"

	done;

percentagesOfSegments=`printf "$percentagesOfSegments" | sed -e 's/^ //g'`
sweepAnglesOfSegments=`printf "$sweepAnglesOfSegments" | sed -e 's/^ //g'`
azimuthsOfSegments=`printf "$azimuthsOfSegments" | sed -e 's/^ //g'`
begQuadrantsOfSegments=`printf "$begQuadrantsOfSegments" | sed -e 's/^ //g'`
sagittaQuadrantsOfSegments=`printf "$sagittaQuadrantsOfSegments" | sed -e 's/^ //g'`
endQuadrantsOfSegments=`printf "$endQuadrantsOfSegments" | sed -e 's/^ //g'`
segmentSagittaAzimuths=`printf "$segmentSagittaAzimuths" | sed -e 's/^ //g'`

printf "\nPercentages of segments over total pie: $percentagesOfSegments"
printf "\nSweep angles of segments: $sweepAnglesOfSegments"
printf "\nAzimuths of segments: $azimuthsOfSegments"
printf "\nSagitta azimuths of segments: $segmentSagittaAzimuths"
printf "\nQuadrants in which segments begin        : $begQuadrantsOfSegments"
printf "\nQuadrants in which segments sagittas fall: $sagittaQuadrantsOfSegments"
printf "\nQuadrants in which segments end          : $endQuadrantsOfSegments"
# -----------
# End Phase 2
# -----------



# -----------
# Beg Phase 3
# -----------
currSegmentOfPie=0
segmentArcEndXs=""
segmentArcEndYs=""
segmentLabelStartXs=""
segmentLabelStartYs=""
segmentLabelTranslateXs=""
segmentLabelTranslateYs=""
diffBetweenEndAndBeginQuadrantsOfCurrentSegment=""
coverageValue=""
coverageClass=""
coverageQuadrants=""

printf "\n"
printf "\nWHILE LOOP #3:"
printf "\n--------------"
printf "\nSegment Coverage Details: " 

while test $currSegmentOfPie -lt $numSegmentsInPie;
	do
		currSegmentOfPie=`expr $currSegmentOfPie + 1`
		currSegmentSweepAngle=`printf "$sweepAnglesOfSegments" | cut -d " " -f $currSegmentOfPie`

		begAzimuthOfCurrentSegment=`printf "$azimuthsOfSegments" | cut -d " " -f $currSegmentOfPie`
		begQuadrantOfCurrentSegment=`printf "$begQuadrantsOfSegments" | cut -d " " -f $currSegmentOfPie`
		endQuadrantOfCurrentSegment=`printf "$endQuadrantsOfSegments" | cut -d " " -f $currSegmentOfPie`

		sagittaQuadrantOfCurrentSegment=`printf "$sagittaQuadrantsOfSegments" | cut -d " " -f $currSegmentOfPie`
		sagittaAzimuthOfCurrentSegment=`printf "$segmentSagittaAzimuths" | cut -d " " -f $currSegmentOfPie`
		nextSegmentOfPie=`expr $currSegmentOfPie + 1`
		endAzimuthOfCurrentSegment=`printf "$azimuthsOfSegments" | cut -d " " -f $nextSegmentOfPie`

		coverageValue="NAN"
		diffBetweenEndAndBeginQuadrantsOfCurrentSegment=`expr $endQuadrantOfCurrentSegment - $begQuadrantOfCurrentSegment`
		#coverageValue=`printf "$diffBetweenEndAndBeginQuadrantsOfCurrentSegment" | sed -e 's/[ ][ ]*//g'`
		coverageValue="$diffBetweenEndAndBeginQuadrantsOfCurrentSegment"
		coverageClass="UNKNOWN"
		coverageQuadrants="NONE"

		if test $coverageValue -eq 0;
			then
				coverageClass="A"

				if test $begQuadrantOfCurrentSegment -eq 1;
					then
						coverageQuandrants="I"
				fi;

				if test $begQuadrantOfCurrentSegment -eq 2;
					then
						coverageQuandrants="II"
				fi;

				if test $begQuadrantOfCurrentSegment -eq 3;
					then
						coverageQuandrants="III"
				fi;

				if test $begQuadrantOfCurrentSegment -eq 4;
					then
						coverageQuandrants="IV"
				fi;
		fi;
		
		if test $coverageValue -eq 3 -o $coverageValue -eq -1;
			then
				coverageClass="B"
			
				if test $coverageValue -eq 3;
					then
						coverageQuandrants="I IV"
					else
						if test $begQuadrantOfCurrentSegment -eq 4;
							then
								coverageQuandrants="IV III"
							else
								coverageQuandrants="III II"
						fi;
				fi;
		fi;

		if test $coverageValue -eq 2 -o $coverageValue -eq -2;
			then
				coverageClass="C"

				if test $coverageValue -eq 2;
					then
						coverageQuandrants="I IV III" 
					else
						coverageQuandrants="IV III II"
				fi;
		fi;

		if test $coverageValue -eq 1;
			then
				coverageClass="D"

				coverageQuandrants="I IV III II"
		fi;

		printf "$coverageClass ($coverageValue) [$coverageQuandrants]     "

		segmentCoverageClasses="$segmentCoverageClasses $coverageClass"
		segmentCoverageQuandrants="$segmentCoverageQuandrants, $coverageQuandrants"
		segmentCoverageValues="$segmentCoverageValues $coverageValue"

		if test "$coverageClass" = "C";
			then
				if test $endQuadrantOfCurrentSegment -eq 1;
					then
						radianSweepForTrig=`printf "scale = 6; $endAzimuthOfCurrentSegment / $degreesPerRadian\n" | bc -l`
						sweepSignX="positive"
						sweepSignY="negative"
					else
						if test $endQuadrantOfCurrentSegment -eq 2;
							then
								radianSweepForTrig=`printf "scale = 6; (360 - $endAzimuthOfCurrentSegment) / $degreesPerRadian\n" | bc -l`
								sweepSignX="negative"
								sweepSignY="negative"
							else
								if test $endQuadrantOfCurrentSegment -eq 3;
					 				then
										radianSweepForTrig=`printf "scale = 6; ($endAzimuthOfCurrentSegment - 180) / $degreesPerRadian\n" | bc -l`
										sweepSignX="negative"
										sweepSignY="positive"
									else
										if test $endQuadrantOfCurrentSegment -eq 4;
											then
												radianSweepForTrig=`printf "scale = 6; (180 - $endAzimuthOfCurrentSegment) / $degreesPerRadian\n" | bc -l`
												sweepSignX="positive"
												sweepSignY="positive"
										fi;
								fi;
						fi;
				fi; 
			else # coverageClass = A || B || D 
				if test $endQuadrantOfCurrentSegment -eq 1;
					then
						radianSweepForTrig=`printf "scale = 6; $endAzimuthOfCurrentSegment / $degreesPerRadian\n" | bc -l`
						sweepSignX="positive"
						sweepSignY="negative"
					else
						if test $endQuadrantOfCurrentSegment -eq 2;
							then
								radianSweepForTrig=`printf "scale = 6; (360 - $endAzimuthOfCurrentSegment) / $degreesPerRadian\n" | bc -l`
								sweepSignX="negative"
								sweepSignY="negative"
							else
								if test $endQuadrantOfCurrentSegment -eq 3;
					 				then
										radianSweepForTrig=`printf "scale = 6; ($endAzimuthOfCurrentSegment - 180) / $degreesPerRadian\n" | bc -l`
										sweepSignX="negative"
										sweepSignY="positive"
									else
										if test $endQuadrantOfCurrentSegment -eq 4;
											then
												radianSweepForTrig=`printf "scale = 6; (180 - $endAzimuthOfCurrentSegment) / $degreesPerRadian\n" | bc -l`
												sweepSignX="positive"
												sweepSignY="positive"
										fi;
								fi;
						fi;
				fi;
		fi;

		offsetForSegmentArcEndX=`printf "scale = 2; $radiusOfPieChart * s($radianSweepForTrig)\n" | bc -l`
		offsetForSegmentArcEndY=`printf "scale = 2; $radiusOfPieChart * c($radianSweepForTrig)\n" | bc -l`
		
		if test "$sweepSignX" = "positive";
				then
					currSegmentArcEndX=`printf "scale = 2; $centerXOfPieChart + $offsetForSegmentArcEndX\n" | bc -l`	
				else
					if test "$sweepSignX" = "negative";
						then
						currSegmentArcEndX=`printf "scale = 2; $centerXOfPieChart - $offsetForSegmentArcEndX\n" | bc -l`	
					fi;
		fi;
		
		if test "$sweepSignY" = "positive";
				then
					currSegmentArcEndY=`printf "scale = 2; $centerYOfPieChart + $offsetForSegmentArcEndY\n" | bc -l`	
				else
					if test "$sweepSignY" = "negative";
						then
						currSegmentArcEndY=`printf "scale = 2; $centerYOfPieChart - $offsetForSegmentArcEndY\n" | bc -l`	
					fi;
		fi;

		segmentArcEndXs="$segmentArcEndXs $currSegmentArcEndX"
		segmentArcEndYs="$segmentArcEndYs $currSegmentArcEndY"

		if test $sagittaQuadrantOfCurrentSegment -eq 1;
			then
				sagittaRadianSweepForTrig=`printf "scale = 6; $sagittaAzimuthOfCurrentSegment / $degreesPerRadian\n" | bc -l`
				sweepSignX="positive"
				sweepSignY="negative"
			else
				if test $sagittaQuadrantOfCurrentSegment -eq 2;
					then
						sagittaRadianSweepForTrig=`printf "scale = 6; (360 - $sagittaAzimuthOfCurrentSegment) / $degreesPerRadian\n" | bc -l`
						sweepSignX="negative"
						sweepSignY="negative"
					else
						if test $sagittaQuadrantOfCurrentSegment -eq 3;
			 				then
								sagittaRadianSweepForTrig=`printf "scale = 6; ($sagittaAzimuthOfCurrentSegment - 180) / $degreesPerRadian\n" | bc -l`
								sweepSignX="negative"
								sweepSignY="positive"
							else
								if test $sagittaQuadrantOfCurrentSegment -eq 4;
									then
										sagittaRadianSweepForTrig=`printf "scale = 6; (180 - $sagittaAzimuthOfCurrentSegment) / $degreesPerRadian\n" | bc -l`
										sweepSignX="positive"
										sweepSignY="positive"
								fi;
						fi;
				fi;
		fi;

		offsetForLabelStartX=`printf "scale = 2; ($radiusOfPieChart / 4) * s($sagittaRadianSweepForTrig)\n" | bc -l`
		offsetForLabelStartY=`printf "scale = 2; ($radiusOfPieChart / 4) * c($sagittaRadianSweepForTrig)\n" | bc -l`
	
		if test "$sweepSignX" = "positive";
				then
					currSegmentLabelStartX=`printf "scale = 2; $centerXOfPieChart + $offsetForLabelStartX\n" | bc -l`	
					offsetForLabelStartX="$offsetForLabelStartX"
				else
					if test "$sweepSignX" = "negative";
						then
						currSegmentLabelStartX=`printf "scale = 2; $centerXOfPieChart - $offsetForLabelStartX\n" | bc -l`	
						offsetForLabelStartX=`printf "scale = 2; 0 - $offsetForLabelStartX\n" | bc -l`
					fi;
		fi;
		
		if test "$sweepSignY" = "positive";
				then
					currSegmentLabelStartY=`printf "scale = 2; $centerYOfPieChart + $offsetForLabelStartY\n" | bc -l`	
					offsetForLabelStartY="$offsetForLabelStartY"
				else
					if test "$sweepSignY" = "negative";
						then
						currSegmentLabelStartY=`printf "scale = 2; $centerYOfPieChart - $offsetForLabelStartY\n" | bc -l`	
						offsetForLabelStartY=`printf "scale = 2; 0 - $offsetForLabelStartY\n" | bc -l`
					fi;
		fi;

		segmentLabelStartXs="$segmentLabelStartXs $currSegmentLabelStartX"
		segmentLabelStartYs="$segmentLabelStartYs $currSegmentLabelStartY"

		segmentLabelTranslateXs="$segmentLabelTranslateXs $offsetForLabelStartX"	
		segmentLabelTranslateYs="$segmentLabelTranslateYs $offsetForLabelStartY"	
	done;

segmentCoverageClasses=`printf "$segmentCoverageClasses" | sed -e 's/^ //g'`
segmentCoverageQuandrants=`printf "$segmentCoverageQuandrants" | sed -e 's/^, //g'`
segmentCoverageValues=`printf "$segmentCoverageValues" | sed -e 's/^ //g'`

segmentArcEndXs=`printf "$segmentArcEndXs" | sed -e 's/^ //g'`
segmentArcEndYs=`printf "$segmentArcEndYs" | sed -e 's/^ //g'`
segmentLabelStartXs=`printf "$segmentLabelStartXs" | sed -e 's/^ //g'`
segmentLabelStartYs=`printf "$segmentLabelStartYs" | sed -e 's/^ //g'`
segmentLabelTranslateXs=`printf "$segmentLabelTranslateXs" | sed -e 's/^ //g' -e 's/\-/\\\-/g'`
segmentLabelTranslateYs=`printf "$segmentLabelTranslateYs" | sed -e 's/^ //g' -e 's/\-/\\\-/g'`

printf "\nSegment coverage classes: $segmentCoverageClasses"
printf "\nSegment coverage values: $segmentCoverageValues"
printf "\nSegment coverage quadrants: $segmentCoverageQuandrants"
printf "\nX coordinates of end of arcs of segments: $segmentArcEndXs"
printf "\nY coordinates of end of arcs of segments: $segmentArcEndYs"
printf "\nX coordinates of start of segment labels: $segmentLabelStartXs"
printf "\nY coordinates of start of segment labels: $segmentLabelStartYs"
printf "\nSegment label X translations: $segmentLabelTranslateXs"
printf "\nSegment label Y translations: $segmentLabelTranslateYs"
# -----------
# End Phase 3
# -----------



# -----------
# Beg Phase 4
# -----------
currSegmentOfPie=0

printf "<?xml\n\tversion = \"1.0\"\n\tstandalone = \"no\"\n?>\n" > $pieChartSvg

printf "\n<!DOCTYPE" >> $pieChartSvg 
printf "\n\tsvg" >> $pieChartSvg 
printf "\n\tPUBLIC" >> $pieChartSvg 
printf "\n\t\"-//W3C//DTD SVG 12//EN\"" >> $pieChartSvg
printf "\n\t\"http://www.w3.org/Graphics/SVG/1.2/DTD/svg12.dtd\"" >> $pieChartSvg
printf "\n>\n" >> $pieChartSvg

printf "\n<svg" >> $pieChartSvg 
printf "\n\txmlns = \"http://www.w3.org/2000/svg\"" >> $pieChartSvg
printf "\n\tviewbox = \"0 0 $viewBoxWidth $viewBoxHeight\"" >> $pieChartSvg
printf "\n\tbaseProfile = \"tiny\"" >> $pieChartSvg 
printf "\n\tversion = \"1.2\"" >> $pieChartSvg 
printf "\n>\n" >> $pieChartSvg

rectX="0"
rectX="$chartMargin"
rectWidth=`printf "scale=2; $viewBoxWidth - (2 * $chartMargin)\n" | bc -l`
rectY="$rectX"
rectHeight="$rectWidth"
rectCornerFilletRadius="10"
rectFillColor="brown"
rectStrokeColor="black"
rectStrokeWidth="1"

printf "\n\t<rect" >> $pieChartSvg
printf "\n\t\tx = \"$rectX\"" >> $pieChartSvg
printf "\n\t\ty = \"$rectY\"" >> $pieChartSvg
printf "\n\t\trx = \"$rectCornerFilletRadius\"" >> $pieChartSvg
printf "\n\t\try = \"$rectCornerFilletRadius\"" >> $pieChartSvg
printf "\n\t\twidth = \"$rectWidth\"" >> $pieChartSvg
printf "\n\t\theight = \"$rectHeight\"" >> $pieChartSvg
printf "\n\t\tfill = \"$rectFillColor\"" >> $pieChartSvg
printf "\n\t\tstroke = \"$rectStrokeColor\"" >> $pieChartSvg
printf "\n\t\tstroke-width = \"$rectStrokeWidth\"" >> $pieChartSvg
printf "\n\t/>" >> $pieChartSvg
# -----------
# End Phase 4
# -----------



# -----------
# Beg Phase 5
# -----------
printf "\n"
printf "\nWHILE LOOP #4:"
printf "\n--------------"

segmentLabelsSvg=""
currSegmentCoverageClass=""
currSegmentCoverageQuadrants=""
currSegmentCoverageValue=""

while test $currSegmentOfPie -lt $numSegmentsInPie;
	do
		currSegmentOfPie=`expr $currSegmentOfPie + 1`
		prevSegmentOfPie=`expr $currSegmentOfPie - 1`
		nextSegmentOfPie=`expr $currSegmentOfPie + 1`

		currFillColorOfSegment=`printf "$segmentFillColors" | sed -e 's/\"//g' | cut -d " " -f $currSegmentOfPie`
		currSegmentLabel=`printf "$segmentLabels" | sed -e 's/\"//g' | cut -d " " -f $currSegmentOfPie`

		if test $currSegmentOfPie -eq 1;
			then
				currSegmentArcStartX="$centerXOfPieChart"
				currSegmentArcStartY=`expr $centerYOfPieChart - $radiusOfPieChart`

				segmentArcStartXs="$currSegmentArcStartX"
				segmentArcStartYs="$currSegmentArcStartY"
			else
				#currSegmentArcStartX=`printf "$segmentArcEndXs" | cut -d " " -f $prevSegmentOfPie`
				currSegmentArcStartX="$currSegmentArcEndX"
				#currSegmentArcStartX=`printf "$segmentArcEndYs" | cut -d " " -f $prevSegmentOfPie`
				currSegmentArcStartY="$currSegmentArcEndY"

				segmentArcStartXs="$segmentArcStartXs $currSegmentArcStartX"
				segmentArcStartYs="$segmentArcStartYs $currSegmentArcStartY"
		fi;

		if test $currSegmentOfPie -eq $numSegmentsInPie;
			then
				currSegmentArcEndX=`printf "$segmentArcStartXs" | cut -d " " -f 1`
				currSegmentArcEndY=`printf "$segmentArcStartYs" | cut -d " " -f 1`
			else
				currSegmentArcEndX=`printf "$segmentArcEndXs" | cut -d " " -f $currSegmentOfPie`
				currSegmentArcEndY=`printf "$segmentArcEndYs" | cut -d " " -f $currSegmentOfPie`
		fi;

		currSegmentSagittaAzimuth=`printf "$segmentSagittaAzimuths" | cut -d " " -f $currSegmentOfPie`
		currSegmentSagittaAzimuth=`printf "scale = 2; $currSegmentSagittaAzimuth - 90\n" | bc -l`
		
		currSegmentLabelStartX="$centerXOfPieChart"
		currSegmentLabelStartY="$centerYOfPieChart"
		#currSegmentLabelStartX=`printf "$segmentLabelStartXs" | cut -d " " -f $currSegmentOfPie`	
		#currSegmentLabelStartY=`printf "$segmentLabelStartYs" | cut -d " " -f $currSegmentOfPie`	
		currSegmentLabelTranslateX=`printf "$segmentLabelTranslateXs" | cut -d " " -f $currSegmentOfPie`	
		currSegmentLabelTranslateY=`printf "$segmentLabelTranslateYs" | cut -d " " -f $currSegmentOfPie`	

		currSegmentCoverageClass=`printf "$segmentCoverageClasses" | cut -d " " -f $currSegmentOfPie`
		currSegmentCoverageQuadrants=`printf "$segmentCoverageQuadrants" | cut -d "," -f $currSegmentOfPie`
		currSegmentCoverageValue=`printf "$segmentCoverageValues" | cut -d " " -f $currSegmentOfPie`

		if test "$currSegmentCoverageClass" = "A";
			then
				currXAxisRotation="0"
				currLargeArcFlag="0"
				currSweepFlag="1"
		fi;

		if test "$currSegmentCoverageClass" = "B";
			then
				if test $currSegmentCoverageValue -eq -3;
					then	
						currXAxisRotation="0"
						currLargeArcFlag="1"
						currSweepFlag="1"
					else # $currSegmentCoverageValue -eq -1
						currXAxisRotation="0"
						currLargeArcFlag="0"
						currSweepFlag="1"
				fi;
		fi;

		if test "$currSegmentCoverageClass" = "C";
			then
				if test $currSegmentCoverageValue -eq -2;
					then	
						currXAxisRotation="0"
						currLargeArcFlag="1"
						currSweepFlag="1"
					else # $currSegmentCoverageValue -eq 2
						currXAxisRotation="0"
						currLargeArcFlag="0"
						currSweepFlag="1"
				fi
		fi;

		if test "$currSegmentCoverageClass" = "D";
			then
				currXAxisRotation="0"
				currLargeArcFlag="1"
				currSweepFlag="1"
		fi;

		currSegmentSvg=`sed -e "s/ARC_CENTER\-X/$centerXOfPieChart/g" -e "s/ARC_CENTER\-Y/$centerYOfPieChart/g" -e "s/ARC_RADIUS\-X/$radiusOfPieChart/g" -e "s/ARC_RADIUS\-Y/$radiusOfPieChart/g" -e "s/ARC_X\-AXIS\-ROTATION/$currXAxisRotation/g" -e "s/ARC_LARGE\-ARC\-FLAG/$currLargeArcFlag/g" -e "s/ARC_SWEEP\-FLAG/$currSweepFlag/g" -e "s/ARC_FILL\-COLOR/$currFillColorOfSegment/g" -e "s/ARC_STROKE\-COLOR/$colorOfSegmentOutline/g" -e "s/ARC_STROKE\-WIDTH/$widthOfSegmentOutline/g" -e "s/ARC_X1/$currSegmentArcStartX/g" -e "s/ARC_Y1/$currSegmentArcStartY/g" -e "s/ARC_X2/$currSegmentArcEndX/g" -e "s/ARC_Y2/$currSegmentArcEndY/g" $segmentSvgTemplate`
		
		#currSegmentLabelSvg=`sed -e "s/SEGMENT_LABEL-OFFSET-X/$currSegmentLabelTranslateX/g" -e "s/SEGMENT_LABEL-OFFSET-Y/$currSegmentLabelTranslateY/g" $segmentLabelSvgTemplate | sed -e "s/ARC_CENTER-X/$centerXOfPieChart/g" -e "s/ARC_CENTER-Y/$centerYOfPieChart/g" -e "s/SEGMENT_SAGITTA-AZIMUTH/$currSegmentSagittaAzimuth/g" -e "s/SEGMENT_LABEL-START-X/$currSegmentLabelStartX/g" -e "s/SEGMENT_LABEL-START-Y/$currSegmentLabelStartY/g" -e "s/SEGMENT_LABEL/$currSegmentLabel/g"`
		currSegmentLabelSvg=`sed -e "s/SEGMENT_LABEL\-OFFSET\-X/$currSegmentLabelTranslateX/g" -e "s/SEGMENT_LABEL\-OFFSET\-Y/$currSegmentLabelTranslateY/g" -e "s/ARC_CENTER\-X/$centerXOfPieChart/g" -e "s/ARC_CENTER\-Y/$centerYOfPieChart/g" -e "s/SEGMENT_SAGITTA\-AZIMUTH/$currSegmentSagittaAzimuth/g" -e "s/SEGMENT_LABEL\-START\-X/$currSegmentLabelStartX/g" -e "s/SEGMENT_LABEL\-START\-Y/$currSegmentLabelStartY/g" -e "s/SEGMENT\_LABEL/$currSegmentLabel/g" $segmentLabelSvgTemplate`

		segmentLabelsSvg=`printf "$segmentLabelsSvg\n$currSegmentLabelSvg\n"`

		printf "\n$currSegmentSvg" >> $pieChartSvg

	done;
# -----------
# End Phase 5
# -----------



# -----------
# Beg Phase 6
# -----------
extras="none"

halfWidth=`expr \\( $widthOfSegmentOutline / 2 \\)`

if test "$extras" = "line";
	then
		currSegmentArcEndY=`expr $currSegmentArcEndY + $halfWidth`

			printf "\n\n\t<line\n\t\tx1 = \"$centerXOfPieChart\"\n\t\ty1 = \"$centerYOfPieChart\"\n\t\tx2 = \"$currSegmentArcEndX\"\n\t\ty2 = \"$currSegmentArcEndY\"\n\t\tstroke = \"$colorOfSegmentOutline\"\n\t\tstroke-width = \"$widthOfSegmentOutline\"\n\t/>" >> $pieChartSvg
fi;

if test "$extras" = "circle";
	then
		radiusOfCircle=`expr $radiusOfPieChart + $halfWidth`
		colorOfCircle="none"
		colorOfCircleOutline="$colorOfSegmentOutline"
		colorOfCircleOutline="black"
		widthOfCircleOutline="$widthOfSegmentOutline"
		widthOfCircleOutline=`expr $widthOfSegmentOutline + $halfWidth`

		printf "\n\n\t<circle\n\t\tcx = \"$centerXOfPieChart\"\n\t\tcy = \"$centerYOfPieChart\"\n\t\tr = \"$radiusOfCircle\"\n\t\tfill = \"$colorOfCircle\"\n\t\tstroke = \"$colorOfCircleOutline\"\n\t\tstroke-width = \"$widthOfCircleOutline\"\n\t/>" >> $pieChartSvg
fi;

printf "$segmentLabelsSvg\n" >> $pieChartSvg

printf "\n</svg>\n" >> $pieChartSvg

segmentArcStartXs=`printf "$segmentArcStartXs" | sed -e 's/^ //g'`
segmentArcStartYs=`printf "$segmentArcStartYs" | sed -e 's/^ //g'`

printf "\nX coordinates of start of arcs of segments: $segmentArcStartXs"
printf "\nY coordinates of start of arcs of segments: $segmentArcStartYs"
# -----------
# End Phase 6
# -----------



printf "\n\nFinish: An SVG pie graph for the arguments given has been written to $pieChartSvg\n\n"

exit 0;

