---
layout: default
title: request-log-analyzer
---

# {{page.title}}

A command line tool that parses your log files to create reports. 

- Many file formats are supported, including Rails, nginx, Apache and more.
  See [supported file formats](fileformats.html) for more details.
- Hackable: file formats can be added, and reports can be edited easily, and 
  everything is MIT licensed.
- Keeps memory usage under control, even for large log files. 
- Runs reasonabily fast for Ruby standards.


### Installation & basic usage

Install request-log-analyzer as a Ruby gem (you might need to run this command
as root by prepending `sudo` to it):

``` sh
$ gem install request-log-analyzer
```

To analyze a Rails log file and produce a performance report, run
`request-log-analyzer` like this:

``` sh
$ request-log-analyzer log/production.log
```


### Further reading

- [Supported log file formats](fileformats.html)
- [Ruby benchmarks](benchmarks.html)


### Additional information

Please report issues on the [Github project's issue tracker](https://github.com/wvanbergen/request-log-analyzer/issues).

Do you have a Rails application that is not performing as it should? If you need
an expert to analyze your application, feel free to contact either [Willem van
Bergen](mailto:willem@railsdoctors.com) or [Bart ten Brinke](mailto:bart@railsdoctors.com).
