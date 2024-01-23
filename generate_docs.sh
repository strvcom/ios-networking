#!/bin/zsh

swift package \
    --allow-writing-to-directory ./docs \
    generate-documentation --target Networking \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path ios-networking \
    --output-path ./docs
