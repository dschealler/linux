#!/usr/bin/env bash
function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  
scriptName='installApacheAnt.sh'

echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	echo "version not passed, HALT!"
	exit 1
else
	version="$1"
	echo "[$scriptName]   version    : $version"
fi

mediaCache="$2"
if [ -z "$mediaCache" ]; then
	mediaCache='/vagrant/.provision'
	echo "[$scriptName]   mediaCache : $mediaCache (default)"
else
	echo "[$scriptName]   mediaCache : $mediaCache"
fi

# Set parameters
executeExpression "antVersion=\"apache-ant-${version}\""
executeExpression "antSource=\"$antVersion-bin.tar.gz\""

if [ ! -f ${mediaCache}/${antSource} ]; then
	echo "[$scriptName] Media (${mediaCache}/${antSource}) not found, attempting download ..."
	executeExpression "curl -s -o ${mediaCache}/${antSource} \"http://archive.apache.org/dist/ant/binaries/${antSource}\""
fi

executeExpression "cp \"${mediaCache}/${antSource}\" ."
executeExpression "tar -xf $antSource"
executeExpression "sudo mv $antVersion /opt/"

# Configure to directory on the default PATH
executeExpression "sudo ln -s /opt/$antVersion/bin/ant /usr/bin/ant"

# Set environment (user default) variable
echo ANT_HOME=\"/opt/$antVersion\" > $scriptName
chmod +x $scriptName
sudo mv -v $scriptName /etc/profile.d/

echo "[$scriptName] List start script contents ..."
executeExpression "cat /etc/profile.d/$scriptName"

echo "[$scriptName] --- end ---"
