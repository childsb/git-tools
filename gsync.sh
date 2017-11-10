#!/bin/sh
print_help() {
    echo "This command syncs a go project to another machine with a configured \$GOPATH"
    echo ""
    echo "Usage: $0 source-go-project user@destinationHost "
    echo ""
}

sync_go_projects(){
	
	DEST_GO_PATH_FULL=$(ssh $DESTINATION "env" | grep GOPATH)
	DEST_GO_PATH="$(echo $DEST_GO_PATH_FULL | cut -d "=" -f2)"
	SOURCE_RELATIVE="$(echo $SOURCE | sed -e s,$GOPATH/,,g)"
	DEST_ABSOLUTE="${DEST_GO_PATH}/${SOURCE_RELATIVE}"
	echo "Local: \$GOPATH/${SOURCE_RELATIVE}"
	echo "Full Dest: ${DEST_ABSOLUTE}"
	ssh $DESTINATION "mkdir -p ${DEST_ABSOLUTE}"
	rsync -aHep ssh $SOURCE/ $DESTINATION:$DEST_ABSOLUTE/ 
}

if  [ -z "$1" ] || [ -z "$2" ]; then
	print_help
	exit 1
fi

SOURCE=`cd ${1};pwd`

if [[ $SOURCE =~ .*$GOPATH.* ]]; then
	DESTINATION=$2
	sync_go_projects
else
	echo "$SOURCE is not in \$GOPATH, exiting..."
	exit 1
fi

