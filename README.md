# git-tools
This repo contains tools for using github and golang

# clone-fork.sh
This is a tool for cloning forks and adding the correct parent as upstream.  It also supports cloning into $GOPATH directory strucuture.  I use GOPATH=/opt/go.

This script only supports a single GOPATH and ignores GOROOT.
```
Usage: ./clone-fork.sh git://github.com/childsb/kubernetes.git [OPTION]...

Options:
 -g, --golang   	clones this project into the proper golang path
 -o, --org   	 	uses specified org instead of trying to discover it from the git path. (only for golang)
 -r, --repo_host	go repo host, defaults to github.com. Even if project is hosted on github, some projects want a dif host in the go dir. structure. (only for golang)
 -a, --add_alias	add the alias 'pu' to git which allows auto updating a forked repo with 'git pu'
 -u, --update		update a forked repo after cloning to match its upstream.
 -h, --help   		show this message

Parts of a golang project path look like:

	$GOPATH/src/[REPOHOST]/[ORG]/[REPO]

 Example:
	For path /opt/go/src/github.com/openshift/origin

	$GOPATH=/opt/go
	REPOHOST=github.com
	ORG=openshift
	repo=origin



```

