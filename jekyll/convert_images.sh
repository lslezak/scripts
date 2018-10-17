#! /bin/sh

find _posts -name '*.md' -exec ./convert_images.rb \{\} \;
