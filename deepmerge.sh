#!/bin/sh

svn export svn://svn.misuse.org/science/deep_merge/trunk/pkg/deep_merge-0.1.0.gem /tmp/deep_merge-0.1.0.gem
cd /tmp && sudo gem install deep_merge