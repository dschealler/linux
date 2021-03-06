#!/usr/bin/env bash
set -e

# Read in two files, the definition file and template file, the name values in the
# definition file replace the tokens (substitution variables) in the template.
# If a tokenised file is not supplied, then simply return the name value pairs
# from the properties file, without new lines or comments.

if [ -z "$1" ]; then
	echo "$0 Definition File not passed. HALT!"
	exit 1
else
	PROPERTIES=$1
fi

if [ -n "$2" ]; then
	TOKENISED=$2
	if [ ! -f "$2" ]; then
		echo "$0 Template File ($TOKENISED) not found. HALT!"
		exit 2
	fi
fi

#deleting lines starting with # ,blank lines ,lines with only spaces
sed -e 's/#.*$//' -e '/^ *$/d' $PROPERTIES > fileWithoutComments

while read LINE
do           
	IFS="\="
	read -ra array <<< "$LINE"
	if [ -z "$TOKENISED" ]; then
		echo "  ${array[0]}=\"${array[1]}\""
	else		
		name="%${array[0]}%"
#		echo "$0 : Replace $name with ${array[1]}"

		# Mac OSX sed 
		if [[ "$OSTYPE" == "darwin"* ]]; then
			sed -i '' "s^$name^${array[1]}^g" $TOKENISED
		else
			sed -i "s^$name^${array[1]}^g" $TOKENISED
		fi
	fi

done < fileWithoutComments

rm fileWithoutComments
