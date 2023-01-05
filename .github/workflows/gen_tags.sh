#!/bin/sh

IMAGE_NAME=$(echo $REPO_NAME | sed 's/docker-//g')

VERSION=$(grep 'ARG NEXTCLOUD_RELEASE=' Dockerfile | sed -E 's/.*=(.*)/\1/g')

VER=( ${VERSION//./ } )

MAJOR=${VER[0]}
MINOR=${VER[1]}
PATCH=${VER[2]}

VERSION_TAGS+=(latest)
VERSION_TAGS+=("${MAJOR}")
VERSION_TAGS+=("${MAJOR}.${MINOR}")
VERSION_TAGS+=("${MAJOR}.${MINOR}.${PATCH}")

BASES+=(${IMAGE_NAME})
BASES+=(ghcr.io/${IMAGE_NAME})

for b in "${BASES[@]}"
do
   for t in "${VERSION_TAGS[@]}"
   do
      TAGS+=( "${b}:${t}" )
   done
done

echo "TAGS<<EOF"
printf '%s\n' ${TAGS[@]}
echo "EOF"

echo "TAGS<<EOF" >> $GITHUB_ENV
printf '%s\n' ${TAGS[@]} >> $GITHUB_ENV
echo "EOF" >> $GITHUB_ENV
