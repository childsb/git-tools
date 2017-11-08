# git-tools
Tools for using git / github / golang

# clone-fork.sh
This is a tool for cloning forks and adding the correct parent as upstream.  It also supports cloning into $GOPATH if the project is golang.

```
Usage: ./clone-fork.sh git://github.com/childsb/kubernetes.git [OPTION]...

Options:
 -g, --golang   	clones this project into the proper golang path
 -o, --org   	 	uses specified org instead of trying to discover it from the git path. (only for golang)
 -r, --repo_host  	git repo host (defaults to github.com)
 -a, --add_alias      add the alias 'pu' to git which allows auto updating a forked repo with 'git pu'
 -u, --update		update a forked repo after cloning to match the upstream.
 -h, --help       	show this message

Parts of a golang project path look like:

	$GOPATH/src/[REPOHOST]/[ORG]/[REPO]

 Example:
	For path /opt/go/src/github.com/openshift/origin

	$GOPATH=/opt/go
	REPOHOST=github.com
	ORG=openshift
	repo=origin
```

