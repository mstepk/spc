#!/bin/bash

copyrightGPL='COPYING'

### Copyright 2014 Mark S. Kalusha (MSK) ###
### DUAL Licsence ## GPLv3 or later, or Ruby License ###
#
# This program, sbc (simpleBarCharter) is free software: you can redistribute
# it and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# For a current copy of this programs source code
# find me, MSK, as 'mstepk' on GitHub
# https://github.com/ => https://github.com/mstepk/sbc

exitCode=1
runInBackground=''

workingDir=`pwd`
begDTStamp=`date +%Y%m%d_%H%M_%s` # 20140203_1719_1391469551
whoAmI=`whoami`
if test "$whoAmI" = "$USER"; then uUser="$whoAmI"; fi;

YSBC=$1
yourSimpleBarChart_SVG=$2
geometry=$3
displays=$4

paramsGO=0
if test -e "$YSBC";
	then
		if test "$yourSimpleBarChart_SVG";
			then
				if test "$geometry" != '';
					then
						if test "$displays" = '' -o "$displays" = '0';
							then
								printf '\nparamGo FALSE, displays (%s)\n' "$displays"
								paramsGO=0
							else
								printf '\nparamGo TRUE, displays (%s)\n' "$displays"
								paramsGO=1
						fi;
				fi;
		fi;
fi;  

slimWebKitBrowser=`which uzbl-core`
if test -e "$slimWebKitBrowser"; then slimWB=1; else slimWB=0; fi;

WB=$slimWebKitBrowser
WBoptA='--uri=file://'
WBoptB='--geometry='
WBoptC='--named='
WBoptA="$WBoptA/$YSBC"
WBoptB="$WBoptB$geometry" # $plotWidth"'x'"$plotHeight"
WBoptC="$WBoptC$yourSimpleBarChart_SVG"
wbOpts="$WBoptA $WBoptB $WBoptC"
slimDisplay="$WB $wbOpts"

fatWebKitBrowser=`which chromium-browser`
if test -e "$fatWebKitBrowser"; then fatWB=1; else fatWB=0; fi;

geometry=`printf '%s' "$geometry" | sed -e 's/x/,/g'`
WB=$fatWebKitBrowser
WBoptA='--app=file://'
WBoptB='--app-window-size='
WBoptA="$WBoptA/$YSBC"
WBoptB="$WBoptB$geometry" # $plotWidth,$plotHeight"
wbOpts="$WBoptA $WBoptB"
fatDisplay="$WB $wbOpts"

WB=''
displayInBothThinAnFat=0
preferredWB='fat'
if test $displayInBothThinAnFat -eq 1;
	then
		WB="$slimDisplay $fatDisplay"
		displays="$slimWebKitBrowser $fatWebKitBrowser"
	else
		if test $preferredWB = 'slim';
			then
				printf '\nSLIM preferred (%s)' "$slimWebKitBrowser" 
				if test $slimWB -eq 1;
					then
						WB="$slimDisplay $runInbackground"
						displays="$slimWebKitBrowser"
					else
						if test $fatWB -eq 1;
							then
								WB="$fatDisplay $runInBackghround"
								displays="$fatWebKitBrowser"
						fi;
				fi;
		fi;
		if test $preferredWB = 'fat';
			then
				printf '\nFAT preferred (%s)' "$fatWebKitBrowser" 
				if test $fatWB -eq 1;
					then
						WB="$fatDisplay $runInBackground"
						displays="$fatWebKitBrowser"
					else
						if test $slimWB -eq 1;
							then
								WB="$slimDisplay $runInBackground"
								displays="$slimWebKitBrowser"
						fi;
				fi;
		fi;
fi;

if test $paramsGO -eq 1;
	then
		if test "$displays" = '' -o "$WB" = '';
			then
				printf '\niNiether slim (%s) nor fat (%s) WebKit browsers were found, to view your Simple Bar Chart (%s) open it using your favorite browser or SVG application.\n' "$slimWebKitBrowser" "$fatWebKitBrowser" "$YSBC"
			else
				printf '\nDisplaying your SBC instance (%s)' "$yourSimpleBarChart_SVG"
				printf '\nusing a new browser (%s) window!\n' "$displays" # "$WB"
				if test $displayInBothThinAnFat -eq 1;
					then 
						if test $slimWB -eq 1; then $slimDisplay & fi;
						printf '\n%s\n' 'SLIM' 
						if test $fatWB -eq 1; then $fatDisplay & fi;
						printf '\n%s\n' 'FAT' 
						exitCode=0
					else
						$WB
						exitCode=0
				fi;
		fi;
	else
		printf '\nparamsGO false (%s), check your params, expect two regular files as first two params, and integer 1 as third param, think of that one as comitting your request.' "$paramsGO"
		exitCode=2
fi;

myProgram="$0"
WKBL=`ls -lhAt $myProgram | cut -d ' ' -f 10-` # Web Kit Browser Launcher

exit $exitCode;

