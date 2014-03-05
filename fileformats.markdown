---
layout: default
title: Supported log file formats
---

# {{page.title}}

Many file formats are supported by request-log-analyzer. Usually, the tool
detects the file format itself, but if that doesnt work for you, you can 
specify the file format on the command line using the `--format` argument.

The following file formats are supported by request-log-analyzer:

- **Rails request log**: `--format rails`, `--format rails3`, or use 
  `--rails-format <format>` for more parsing options for Rails 2.
- **Merb request log**:  `--format merb`
- **Rack CommonLogger log**: `--format rack`
- **DelayedJob log**:  `--format delayed_job`
- **Apache access log**: `--apache-format <format string>`
- **Amazon S3 access log**:  `--format amazon_s3`
- **MySQL slow query log**:  `--format mysql`
- **nginx access log**: `--format nginx`
- **PostgreSQL query log**:  `--format postgresql`
- **Oink log**:  `--format oink`
- **HAProxy httplog format**:  `--format haproxy`
