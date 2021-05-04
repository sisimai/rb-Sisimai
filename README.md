![](https://libsisimai.org/static/images/logo/sisimai-x01.png)

[![License](https://img.shields.io/badge/license-BSD%202--Clause-orange.svg)](https://github.com/sisimai/rb-sisimai/blob/master/LICENSE)
[![Coverage Status](https://img.shields.io/coveralls/sisimai/rb-sisimai.svg)](https://coveralls.io/r/sisimai/rb-sisimai)
[![Build Status](https://travis-ci.org/sisimai/rb-sisimai.svg?branch=master)](https://travis-ci.org/sisimai/rb-sisimai) 
[![Codacy Badge](https://api.codacy.com/project/badge/grade/38340177e6284a65be69c0c7c3dc2b58)](https://www.codacy.com/app/azumakuniyuki/rb-sisimai)
[![Ruby](https://img.shields.io/badge/ruby-v2.4.0--v2.7.0-red.svg)](https://www.ruby-lang.org/)
[![Gem Version](https://badge.fury.io/rb/sisimai.svg)](https://badge.fury.io/rb/sisimai)

- [**README-JA(日本語)**](README-JA.md)
- [What is Sisimai](#what-is-sisimai)
    - [Key features](#key-features)
    - [Command line demo](#command-line-demo)
- [Setting Up Sisimai](#setting-up-sisimai)
    - [System requirements](#system-requirements)
    - [Install](#install)
        - [From RubyGems](#from-rubygems)
        - [From GitHub](#from-github)
- [Usage](#usage)
    - [Basic usage](#basic-usage)
    - [Convert to JSON](#convert-to-json)
    - [Callback feature](#callback-feature)
    - [One-Liner](#one-liner)
    - [Output example](#output-example)
- [Sisimai Specification](#sisimai-specification)
    - [Differences between Ruby version and Perl version](#differences-between-ruby-version-and-perl-version)
    - [Other specification of Sisimai](#other-specification-of-sisimai)
- [Contributing](#contributing)
    - [Bug report](#bug-report)
    - [Emails could not be parsed](#emails-could-not-be-parsed)
- [Other Information](#other-information)
    - [Related sites](#related-sites)
    - [See also](#see-also)
- [Author](#author)
- [Copyright](#copyright)
- [License](#license)

What is Sisimai
===================================================================================================
Sisimai is a Ruby library for analyzing RFC5322 bounce emails and generating structured data from
parsed results. The Ruby version of Sisimai is ported from the Perl version of Sisimai at
[github.com/sisimai/p5-sisimai](https://github.com/sisimai/p5-sisimai/).

![](https://libsisimai.org/static/images/figure/sisimai-overview-1.png)

Key Features
---------------------------------------------------------------------------------------------------
* __Convert Bounce Mails to Structured Data__
  * Supported formats are Ruby(Hash, Array) and JSON(String)
* __Easy to Install, Use.__
  * gem install
  * git clone & make
* __High Precision of Analysis__
  * 2 times higher than bounceHammer
  * Support 68 MTAs/MDAs/ESPs
  * Support Feedback Loop Message(ARF)
  * Can detect 29 error reasons

Command line demo
---------------------------------------------------------------------------------------------------
The following screen shows a demonstration of Sisimai at the command line using Ruby(rb-sisimai) and
Perl(p5-sisimai) version of Sisimai.
![](https://libsisimai.org/static/images/demo/sisimai-dump-01.gif)

Setting Up Sisimai
===================================================================================================
System requirements
---------------------------------------------------------------------------------------------------
More details about system requirements are available at
[Sisimai | Getting Started](https://libsisimai.org/en/start/) page.


* [Ruby 2.4.0 or later](http://www.ruby-lang.org/)
  * [__Oj | The fastest JSON parser and object serializer__](https://rubygems.org/gems/oj)
* Also works on [JRuby 9.0.4.0 or later](http://jruby.org)
  * [__JrJackson | A mostly native JRuby wrapper for the java jackson json processor jar__](https://rubygems.org/gems/jrjackson)

Install
---------------------------------------------------------------------------------------------------
### From RubyGems

```shell
$ sudo gem install sisimai
Fetching: sisimai-4.25.5.gem (100%)
Successfully installed sisimai-4.25.5
Parsing documentation for sisimai-4.25.5
Installing ri documentation for sisimai-4.25.5
Done installing documentation for sisimai after 6 seconds
1 gem installed
```

### From GitHub

```shell
$ cd /usr/local/src
$ git clone https://github.com/sisimai/rb-sisimai.git
$ cd ./rb-sisimai
$ sudo make depend install-from-local
gem install bundle rake minitest coveralls
...
4 gems installed
bundle exec rake install
sisimai 4.25.5 built to pkg/sisimai-4.25.5.gem.
sisimai (4.25.5) installed.
```

Usage
===================================================================================================
Basic usage
---------------------------------------------------------------------------------------------------
`rise()` method provides feature for getting parsed data from bounced email messages like following.
Beginning with v4.25.6, new accessor `origin` which keeps the path to email file as a data source is
available.


```ruby
#! /usr/bin/env ruby
require 'sisimai'
v = Sisimai.rise('/path/to/mbox')       # or path to Maildir/

# Beginning with v4.23.0, both rise() and dump() method of Sisimai class can read bounce messages
# from variable instead of a path to mailbox
f = File.open('/path/to/mbox', 'r');    # or path to Maildir/
v = Sisimai.rise(f.read)

# If you want to get bounce records which reason is "delivered", set "delivered" option to rise()
# method like the following:
v = Sisimai.rise('/path/to/mbox', delivered: true)

# Beginning with v5.0.0, sisimai does not return the reulst which "reason" is "vaction" by default.
# If you want to get bounce records which reason is "vacation", set "vacation" option to rise()
# method like the following:
v = Sisimai.rise('/path/to/mbox', vacation: true );

if v.is_a? Array
  v.each do |e|
    puts e.class                # Sisimai::Data
    puts e.recipient.class      # Sisimai::Address
    puts e.timestamp.class      # Sisimai::Time

    puts e.addresser.address    # shironeko@example.org # From
    puts e.recipient.address    # kijitora@example.jp   # To
    puts e.recipient.host       # example.jp
    puts e.deliverystatus       # 5.1.1
    puts e.replycode            # 550
    puts e.reason               # userunknown
    puts e.origin               # /var/spool/bounce/Maildir/new/1740074341.eml
    puts e.hardbounce           # true

    h = e.damn                  # Convert to HASH
    j = e.dump('json')          # Convert to JSON string
    puts e.dump('json')         # JSON formatted bounce data
  end
end
```

Convert to JSON
---------------------------------------------------------------------------------------------------
`Sisimai.dump()` method provides feature for getting parsed data as JSON string from bounced email
messages like following.

```ruby
# Get JSON string from parsed mailbox or Maildir/
puts Sisimai.dump('/path/to/mbox')  # or path to Maildir/

# dump() method also accepts "delivered" option like the following code:
puts Sisimai.dump('/path/to/mbox', delivered: true)
```

Callback feature
---------------------------------------------------------------------------------------------------
`:c___` argument of `Sisimai.rise` and `Sisimai.dump` is an Array and is a parameter to receive Proc
objects for callback feature. The first element of `:c___` argument is called at `Sisimai::Message.parse`
for dealing email headers and entire message body. The second element of `:c___` argument is called
at the end of each email file parsing. The result generated by the callback method is accessible via
`Sisimai::Data.catch`.

### [0] For email headers and the body
Callback method set in the first element of `:c___` is called at `Sisimai::Message.parse()`.

```ruby
#! /usr/bin/env ruby
require 'sisimai'
code = lambda do |args|
  head = args['headers']    # (*Hash)  Email headers
  body = args['message']    # (String) Message body
  adds = { 'x-mailer' => '', 'queue-id' => '' }

  if cv = body.match(/^X-Postfix-Queue-ID:\s*(.+)$/)
    adds['queue-id'] = cv[1]
  end
  r['x-mailer'] = head['x-mailer'] || ''
  return adds
end

data = Sisimai.rise('/path/to/mbox', c___: [code, nil])
json = Sisimai.dump('/path/to/mbox', c___: [code, nil])

puts data[0].catch['x-mailer']  # "Apple Mail (2.1283)"
puts data[0].catch['queue-id']  # "43f4KX6WR7z1xcMG"
```

### For each email file
Callback method set in the second element of `:c___` is called at `Sisimai.rise()` method for dealing
each email file.

```ruby
path = '/path/to/maildir'
code = lambda do |args|
  kind = args['kind']   # (String) Sisimai::Mail.kind
  mail = args['mail']   # (String) Entire email message
  path = args['path']   # (String) Sisimai::Mail.path
  sisi = args['sisi']   # (Array)  List of Sisimai::Data

  sisi.each do |e|
    # Insert custom fields into the parsed results
    e.catch ||= {}
    e.catch['size'] = mail.size
    e.catch['kind'] = kind.capitalize

    if cv = mail.match(/^Return-Path: (.+)$/)
      # Return-Path: <MAILER-DAEMON>
      e.catch['return-path'] = cv[1]
    end
    e.catch['parsedat'] = Time.new.localtime.to_s

    # Append X-Sisimai-Parsed: header and save into other path
    a = sprintf("X-Sisimai-Parsed: %d", sisi.size)
    p = sprintf("/path/to/another/directory/sisimai-%s.eml", e.token)
    v = mail.sub(/^(From:.+?)$/, '\1' + "\n" + a)
    f = File.open(p, 'w:UTF-8')
    f.write(v)
    f.close

    # Remove the email file in Maildir/ after parsed
    File.delete(path) if kind == 'maildir'

    # Need to not return a value
  end
end

list = Sisimai.rise(path, c___: [nil, code])

puts list[0].catch['size']          # 2202
puts list[0].catch['kind']          # "Maildir"
puts list[0].catch['return-path']   # "<MAILER-DAEMON>"
```

More information about the callback feature is available at
[Sisimai | How To Parse - Callback](https://libsisimai.org/en/usage/#callback) Page.

One-Liner
---------------------------------------------------------------------------------------------------
```shell
% ruby -rsisimai -e 'puts Sisimai.dump($*.shift)' /path/to/mbox
```

Output example
---------------------------------------------------------------------------------------------------
![](https://libsisimai.org/static/images/demo/sisimai-dump-02.gif)

```json
[{"catch":{"x-mailer":"","return-path":"<shironeko@mx.example.co.jp>"},"token":"cf17945938502bd876603a375f0e9517c921bbab","lhost":"localhost","rhost":"mx-s.neko.example.jp","alias":"","listid":"","reason":"hasmoved","action":"failed","origin":"set-of-emails/maildir/bsd/lhost-sendmail-22.eml","subject":"Nyaaaan","messageid":"0000000011111.fff0000000003@mx.example.co.jp","replycode":"","smtpagent":"Sendmail","hardbounce":true,"smtpcommand":"DATA","destination":"example.net","senderdomain":"example.co.jp","feedbacktype":"","diagnosticcode":"450 busy - please try later 551 not our customer 503 need RCPT command [data]","diagnostictype":"SMTP","deliverystatus":"5.1.6","timezoneoffset":"+0900","addresser":"shironeko@example.co.jp","recipient":"kijitora@example.net","timestamp":1397054085}]
```

Sisimai Specification
===================================================================================================
Differences between Ruby version and Perl version
---------------------------------------------------------------------------------------------------
The following table show the differences between Ruby version of Sisimai and Perl version of Sisimai.
Information about differences between Sisimai and bounceHammer are available at
[Sisimai | Differences](https://libsisimai.org/en/diff/) page.

| Features                                    | Ruby version   | Perl version  |
|---------------------------------------------|----------------|---------------|
| System requirements                         | Ruby 2.4 - 2.7 | Perl 5.10 -   |
|                                             | JRuby 9.0.4.0- |               |
| Analytical precision ratio(2000 emails)[1]  | 1.00           | 1.00          |
| The speed of parsing email(1000 emails)     | 2.22s[2]       | 1.35s         |
| How to install                              | gem install    | cpanm, cpm    |
| Dependencies (Except core modules)          | 1 module       | 2 modules     |
| LOC:Source lines of code                    | 10300 lines    | 10500 lines   |
| The number of tests(spec/,t/,xt/) directory | 453000 tests   | 311000 tests  |
| License                                     | BSD 2-Clause   | BSD 2-Clause  |
| Support Contract provided by Developer      | Available      | Available     |

1. See [./ANALYTICAL-PRECISION](https://github.com/sisimai/rb-sisimai/blob/master/ANALYTICAL-PRECISION)
2. Xeon E5-2640 2.5GHz x 2 cores | 5000 bogomips | 1GB RAM | Ruby 2.3.4p301

Other specification of Sisimai
---------------------------------------------------------------------------------------------------
- [**Parser Engines**](https://libsisimai.org/en/engine/)
- [**Bounce Reason List**](https://libsisimai.org/en/reason/)
- [**Data Structure of Sisimai::Data**](https://libsisimai.org/en/data/)

Contributing
===================================================================================================
Bug report
---------------------------------------------------------------------------------------------------
Please use the [issue tracker](https://github.com/sisimai/rb-sisimai/issues) to report any bugs.

Emails could not be parsed
---------------------------------------------------------------------------------------------------
Bounce mails which could not be parsed by Sisimai are saved in the repository
[set-of-emails/to-be-debugged-because/sisimai-cannot-parse-yet](https://github.com/sisimai/set-of-emails/tree/master/to-be-debugged-because/sisimai-cannot-parse-yet). 
If you have found any bounce email cannot be parsed using Sisimai, please add the email into the
directory and send Pull-Request to this repository.

Other Information
===================================================================================================
Related Sites
---------------------------------------------------------------------------------------------------
* __@libsisimai__ | [Sisimai on Twitter (@libsisimai)](https://twitter.com/libsisimai)
* __libSISIMAI.ORG__ | [Sisimai | The successor to bounceHammer, Library to parse bounce mails](https://libsisimai.org/)
* __Sisimai Blog__ | [blog.libsisimai.org](http://blog.libsisimai.org/)
* __Facebook Page__ | [facebook.com/libsisimai](https://www.facebook.com/libsisimai/)
* __GitHub__ | [github.com/sisimai/rb-sisimai](https://github.com/sisimai/rb-sisimai)
* __RubyGems.org__ | [rubygems.org/gems/sisimai](https://rubygems.org/gems/sisimai)
* __Perl verson__ | [Perl version of Sisimai](https://github.com/sisimai/p5-sisimai)
* __Fixtures__ | [set-of-emails - Sample emails for "make test"](https://github.com/sisimai/set-of-emails)

See also
---------------------------------------------------------------------------------------------------
* [README-JA.md - README.md in Japanese(日本語)](https://github.com/sisimai/rb-sisimai/blob/master/README-JA.md)
* [RFC3463 - Enhanced Mail System Status Codes](https://tools.ietf.org/html/rfc3463)
* [RFC3464 - An Extensible Message Format for Delivery Status Notifications](https://tools.ietf.org/html/rfc3464)
* [RFC3834 - Recommendations for Automatic Responses to Electronic Mail](https://tools.ietf.org/html/rfc3834)
* [RFC5321 - Simple Mail Transfer Protocol](https://tools.ietf.org/html/rfc5321)
* [RFC5322 - Internet Message Format](https://tools.ietf.org/html/rfc5322)

Author
===================================================================================================
[@azumakuniyuki](https://twitter.com/azumakuniyuki)

Copyright
===================================================================================================
Copyright (C) 2015-2021 azumakuniyuki, All Rights Reserved.

License
===================================================================================================
This software is distributed under The BSD 2-Clause License.

