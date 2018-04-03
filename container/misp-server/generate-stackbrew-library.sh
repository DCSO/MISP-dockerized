#!/bin/bash
set -eu

declare -A aliases
aliases=(
	[2.4.88]='2.4 latest'
)

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"
#base=stretch
base=

versions=( */ )
versions=( "${versions[@]%/}" )

# get the most recent commit which modified any of "$@"
fileCommit() {
	git log -1 --format='format:%H' HEAD -- "$@"
}

# get the most recent commit which modified "$1/Dockerfile" or any file COPY'd from "$1/Dockerfile"
dirCommit() {
	local dir="$1"; shift
	(
		cd "$dir"
		fileCommit \
			Dockerfile \
			$(git show HEAD:./Dockerfile | awk '
				toupper($1) == "COPY" {
					for (i = 2; i < NF; i++) {
						print $i
					}
				}
			')
	)
}

cat <<-EOH
# this file is generated via https://github.com/DCSO/MISP-dockerized/blob/$(fileCommit "$self")/$self

Maintainers: DCSO GmbH <misp@dcso.de> (@dcso)
GitRepo: https://github.com/DCSO/MISP-dockerized
EOH

# prints "$2$1$3$1...$N"
join() {
	local sep="$1"; shift
	local out; printf -v out "${sep//%/%%}%s" "$@"
	echo "${out#$sep}"
}

for version in "${versions[@]}"; do
	# with base:
	#commit="$(dirCommit "$version/$base")"
	# without base:
	commit="$(dirCommit "$version")"
	
	#with base:
	#fullVersion="$(git show "$commit":"$version/$base/Dockerfile" | awk '$1 == "ENV" && $2 == "MISP_TAG" { print $3; exit }')"
	# without base:
	fullVersion="$(git show "$commit":"$version/Dockerfile" | awk '$1 == "ENV" && $2 == "MISP_TAG" { print $3; exit }')"
	fullVersion="${fullVersion%[.-]*}"

	versionAliases=( $fullVersion )
	if [ "$version" != "$fullVersion" ]; then
		versionAliases+=( $version )
	fi
	versionAliases+=( ${aliases[$version]:-} )

	echo
	cat <<-EOE
		Tags: $(join ', ' "${versionAliases[@]}")
		Architectures: amd64
		GitCommit: $commit
		Directory: $version/$base
	EOE

done
