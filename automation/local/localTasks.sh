#!/usr/bin/env bash
set -e

# This script provides a repeatable deployment process. This uses two arguments, the target environment
# identifier and the $3 to deploy. Note: each $3 produced is expected to be uniquely identifiable.

if [ -z "$1" ]; then
	echo "$0 Environment Argument not passed. HALT!"
	exit 1
else
	ENVIRONMENT=$1
fi

if [ -z "$2" ]; then
	echo "$0 Build Number not passed. HALT!"
	exit 2
else
	BUILDNUMBER=$2
fi

if [ -z "$3" ]; then
	echo "$0 : Solution Name not supplied. HALT!"
	exit 3
else
	SOLUTION=$3
fi

if [ -z "$4" ]; then
	echo "$0 : Default working directory not supplied. HALT!"
	exit 4
else
	WORKDIR=$4
fi

echo
# Enter the working directory, this is where the helper scripts should be, all processing of artefacts
# must be relative to this, i.e. .. (remote a local processing are perform in the same relative location
cd $WORKDIR
ls -L -1 propertiesForLocalTasks/$ENVIRONMENT* | xargs -n 1 basename > testTargets 2> /dev/null

targetsDefined=$(cat testTargets)
if [ -z ${targetsDefined} ]; then
	echo "$0 : INFO : No Post Deployment Tasks Attempted."
else
	echo "$0 : +--------------------------------+"
	echo "$0 : | Process Locally Executed Tasks |"
	echo "$0 : +--------------------------------+"
	echo
	echo "$0 :   ENVIRONMENT : $ENVIRONMENT"
	echo "$0 :   BUILDNUMBER : $BUILDNUMBER"
	echo "$0 :   SOLUTION    : $SOLUTION"
	echo "$0 :   WORKDIR     : $WORKDIR"
	echo
	echo "$0 : Executing on $(hostname) as $(whoami) in $(pwd)."

	while read LOCAL_TASK_TARGET
	do
	
		echo
		echo "$0 : --- POST DEPLOYMENT $LOCAL_TASK_TARGET ---"
		
		# The shared script, execute.sh is copied from remote folder
		scriptList=$(./getProperty.sh "./propertiesForLocalTasks/$LOCAL_TASK_TARGET" "deployScriptOverride")
		if [ -z "$scriptList" ]; then
			scriptList="./tasksRunLocal.tsk"
		fi
		./execute.sh "$SOLUTION" "$BUILDNUMBER" "$LOCAL_TASK_TARGET" "$scriptList" "$ACTION" 2>&1 | tee -a postDeploy.log
		# the pipe above will consume the exit status, so use array of status of each command in your last foreground pipeline of commands
		exitCode=${PIPESTATUS[0]} 
		if [ "$exitCode" != "0" ]; then
			echo "$0 : ./execute.sh \"$SOLUTION\" \"$BUILDNUMBER\" \"$LOCAL_TASK_TARGET\" \"$scriptList\" \"$ACTION\" failed! Returned $exitCode"
			exit $exitCode
		fi
						
	done < testTargets
fi

cd ..
rm -f testTargets