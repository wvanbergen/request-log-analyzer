---
layout: default
title: Ruby benchmarks
---

# {{page.title}}

request-log-analyzer runs on all Rubies, but not every Ruby is created
equal.

``` sh
$ time ./bin/request-log-analyzer 40MBRailsFile.log

ruby-1.9.2-p180   15.19s user 0.95s system 99% cpu 16.143 total
ree-1.8.7-2011.03 22.81s user 1.28s system 92% cpu 25.938 total
ruby-1.8.7-p334   25.21s user 1.02s system 99% cpu 26.238 total
jruby-1.5.3       32.64s user 4.84s system 99% cpu 37.629 total
rbx-2.0.0pre      39.62s user 2.24s system 104% cpu 40.098 total
macruby           75.00s user 20.10s system 110% cpu 1:26.13 total
```