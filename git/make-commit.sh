#!/bin/bash -eux
set -o pipefail

if [ -d committer-info-passthrough ]; then
  GIT_AUTHOR_NAME="$(cat committer-info-passthrough/author_name)"
  GIT_AUTHOR_EMAIL="$(cat committer-info-passthrough/author_email)"
  SUBJECT="$(cat committer-info-passthrough/subject)"
  GIT_COMMITTER_NAME=$COMMITTER_NAME
  GIT_COMMITTER_EMAIL=$COMMITTER_EMAIL
else
  GIT_AUTHOR_NAME=$COMMITTER_NAME
  GIT_AUTHOR_EMAIL=$COMMITTER_EMAIL
  EMAIL=$GIT_AUTHOR_EMAIL
fi

set -o nounset
echo "
making commit:
subject: $SUBJECT
message: $EXTRA_MESSAGE_DETAILS
"

export \
  GIT_AUTHOR_NAME \
  GIT_AUTHOR_EMAIL \
  EMAIL \
  GIT_COMMITTER_NAME \
  GIT_COMMITTER_EMAIL \
  SUBJECT \
  EXTRA_MESSAGE_DETAILS

cat >/tmp/commit <<"COMMIT_FUNC"
  cd $1

  if [ ! -z "$(git status -s)" ]; then
    git add -A .

    branch="$(git branch | grep -v '*.*detached' | tr -d [:blank:])"
    git checkout $branch

    git commit -v --allow-empty -m "$SUBJECT

    $EXTRA_MESSAGE_DETAILS"
  fi

COMMIT_FUNC

chmod +x /tmp/commit

pushd "src"
  git submodule foreach --recursive | tac | sed -e s/Entering//g -e s/\'//g | xargs -I% /tmp/commit %
  /tmp/commit $PWD
popd

cp -R src/. out/
