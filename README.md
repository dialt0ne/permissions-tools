Permissions Tools
=================

Three perl scripts that change permissions with slightly less overhead.

## Why?

When dealing with a multi-terabyte Gluster volume that has millions of files, every operation matters.
And after running strace on chmod and chown, I found that it forces the chmod or chown operation
on every file, regardless whether it's mode or ownership needed changing. These scripts are a little
more efficient and only change the permissions if necessary. When running multiple times, it saves
a few million operations.

## Requirements

These scripts require [perl's implementation](http://search.cpan.org/dist/Lchown/) of [lchown](http://linux.die.net/man/2/lchown). On RHEL/CentOS/Amazon Linux systems, you'll find the `perl-Lchown` package. On Ubuntu/Debian systems it is `liblchown-perl`.

## Usage

```
fast-chown.pl --path /path/to/directory --uid ## --gid ##

fast-chmod.pl --path /path/to/directory --mode ####

fast-both.pl --path /path/to/directory --uid ## --gid ## --mode ####
```

## License and Authors

```
Author: Anthony Tonns

Copyright 2014 Corsis
http://www.corsis.com/

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
