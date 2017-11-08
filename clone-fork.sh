# Copyright Bradley Childs 2017 (bchilds@gmail.com)
#
# This script clones a git repo and adds its upstream parent
# to the remotes..
#
#
# curl https://api.github.com/repos/childsb/kubernetes

# git clone https://github.com/childsb/kubernetes.git
# git clone git://github.com/childsb/kubernetes.git
#
#!/bin/sh

print_help() {
    echo "Usage: $0 git://github.com/childsb/kubernetes.git [OPTION]..."
    echo ""
    echo "Options:"
    echo " -g, --golang   	clones this project into the proper golang path"
    echo " -o, --org   	 	uses specified org instead of trying to discover it from the git path. (only for golang)"
    echo " -r, --repo_host  	git repo host (defaults to github.com)"
    echo " -a, --add_alias      add the alias 'pu' to git which allows auto updating a forked repo with 'git pu'"
    echo " -u, --update		update a forked repo after cloning to match the upstream."
    echo " -h, --help       	show this message"
    echo ""
    echo "Parts of a golang project path look like:"
	echo ""
    echo "	\$GOPATH/src/[REPOHOST]/[ORG]/[REPO]"
    echo ""
    echo " Example:"
    echo "	For path /opt/go/src/github.com/openshift/origin"
    echo ""
    echo "	\$GOPATH=/opt/go"
    echo "	REPOHOST=github.com"
    echo "	ORG=openshift"
    echo "	repo=origin"
	echo ""
}

print_parsed(){
	# this is just for debugging when editing the script..
	echo "proto: ${proto}"
	echo "url: ${url}"
	echo "user: ${user}"
	echo "host: ${host}"
	echo "port: ${port}"
	echo "path: ${path}"
	echo "org: ${org}"
	echo "repo_full: ${repo_full}"
	echo "repo: ${repo}"
}

parse_url() {

	# extract the protocol
	if [[ $1 =~ .*://.* ]]; then
		# protocol specified
		proto="$(echo $1 | grep :// | sed -e's,^\(.*://\).*,\1,g')"
		# remove the protocol -- updated
		url=$(echo $1 | sed -e s,$proto,,g)
		# extract the user (if any)
		user="$(echo $url | grep @ | cut -d@ -f1)"

		# extract the host 
		host=$(echo $url | sed -e s,$user@,,g | cut -d/ -f1)
		# try to extract the port
		port="$(echo $host | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"
		# extract the path (if any)
		path="$(echo $url | grep / | cut -d/ -f2-)"

		
	else
		# echo "WARN: no proto specified.."
		proto=""
		url=$1
		# extract the host
		user="$(echo $url | grep @ | cut -d@ -f1)"
		host=$(echo $url | sed -e s,$user@,,g | cut -d/ -f1)
		path="$(echo $url | grep / | cut -d/ -f2-)"
		
	fi
	
	if [[ $path =~ .*/.* ]]; then
		org="$(echo $path | cut -d "/" -f1)"
	else
		org="$(echo $host | cut -d ":" -f2)"
	fi
	
	repo_full="$(echo $path | cut -d "/" -f2)"
	repo="$(echo $repo_full | sed -e 's/\.git//g')"
}

add_pu_alias() {
	git config --global alias.pu '!git fetch origin -v; git fetch upstream -v; git rebase upstream/master'
}

detect_git_host() {
	# Some git projects have custom 'hosts'. (/opt/go/src/somethingweird/project)
	# Since the 'custom host' isn't discoverable this function is to detect
	# those projects and set the host as needed.
	#
	# there are other odd behaviors because of this... For instance, for the default host
	# github.com, the path structure is #GOPATH/src/github.com/${org}/project
	# but for custom hosts, the org is omitted... So for kubernetes the path is
	#
	# $GOAPTH/src/k8s.io/kubernetes and not $GOPATH/src/k8s.io/kubernetes/kubernetes
	#
	
	
	if ! [ -z ${REPO_HOST} ]; then
	  # if REPO_HOST set at this point it was done via arg, dont override it..
	  return
	fi
	
	# Set the default repo host..
	REPO_HOST="github.com"
	
	if  [ "$repo" = "kubernetes" ]; then
		REPO_HOST="k8s.io"
		ORG_OVERIDE=${REPO_HOST}
		echo "Found kubernetes, using $REPO_HOST for repo"
		return
	fi
	
}

setup_git() {

	# finds the parent of a forked repo.
	parent_url=$(curl -sS "https://api.github.com/repos/${org}/${repo}" | jq -cr '.parent.ssh_url')

	if [ "$parent_url" != "null" ]; then
		# parse the parent URL to determine the real ORG
		parse_url $parent_url
	fi

	if  [ "$GO_LANG" = true ]; then
		# check for common repo over-rides
		detect_git_host
		echo "Using git host ${REPO_HOST}"
		echo "GOLANG specified, cloning into $GOPATH/src/ "
		if ! [  -z ${ORG_OVERIDE} ]; then
		
			if [ ${REPO_HOST}==${ORG_OVERIDE} ]; then
				# if the repo host and ORG OVERIDE are the same, then skip creating the org
				# this is for like kubernetes which uses $GOPATH/src/k8s.io/kubernetes and not
				# $GOPATH/src/k8s.io/kubernetes/kubernetes 
					echo "Custom Repo Host found, not using the ORG in path.." 
				mkdir -p  ${GOPATH}/src/${REPO_HOST}/
				cd  ${GOPATH}/src/${REPO_HOST}/
			else
				echo "Using $ORG_OVERIDE instead of $ORG" 
				mkdir -p  ${GOPATH}/src/${REPO_HOST}/${ORG_OVERIDE}
				cd  ${GOPATH}/src/${REPO_HOST}/${ORG_OVERIDE}
			fi
			
		else
			echo "No ORG over ride"
			mkdir -p ${GOPATH}/src/$REPO_HOST/$org
			cd  ${GOPATH}/src/$REPO_HOST/$org
		fi	
	fi
	echo "current dir: `pwd`"
	git clone $primary_repo || { echo >&2 "git clone failed, exiting.."; exit 1; }
	cd $repo

	if [ "$parent_url" == "null" ]; then
		echo "No upstream set."
	else
		echo "Adding upstream remote ${parent_url}"
		git remote add upstream ${parent_url}
		if [ "${UPDATE_UPSTREAM}" == "true" ]; then
			echo "Updating fork from master... this will not PUSH to the fork"
			git fetch origin -v; git fetch upstream -v; git rebase upstream/master
			echo""
			echo "Its suggested to 'git push origin' to push the updates to the fork"
			echo""
		fi 
	fi
	


}

if ! [ -x "$(command -v jq)" ]; then
  echo 'This script requires jq, Please install (https://stedolan.github.io/jq/download/)' >&2

  exit 1
fi

GO_LANG=false
UPDATE_UPSTREAM=false

# Parse args
while [ "${1+isset}" ]; do
    case "$1" in
        -g|--golang)
           GO_LANG=true
            shift 1 
            ;;
        -a| --add_alias)
           shift 1 
           add_pu_alias
            ;;
        -u| --update)
           UPDATE_UPSTREAM=true
           shift 1 
            ;;
        -h|--help)
            print_help
  	    	exit 1
            ;;
        -r|--repo_host)
            REPO_HOST=$2
  	    shift 2
            ;;
        -o|--org)
            ORG_OVERIDE=$2
  	    shift 2
            ;;
   *)
     primary_repo=$1
     shift 1
    ;;
    esac
done

if  [ -z ${primary_repo} ]; then
  print_help
  exit 1
       
fi

if  [ "$GO_LANG" = true ] && [ -z "$GOPATH" ]; then
	echo "Go project specified via CLI flag (-g) but no \$GOPATH set"
	exit 1
fi

# Parse the git URL into pieces.
parse_url $primary_repo
setup_git
echo "Cloned $primary_repo into `pwd`"



