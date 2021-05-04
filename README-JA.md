![](https://libsisimai.org/static/images/logo/sisimai-x01.png)

[![License](https://img.shields.io/badge/license-BSD%202--Clause-orange.svg)](https://github.com/sisimai/rb-sisimai/blob/master/LICENSE)
[![Coverage Status](https://img.shields.io/coveralls/sisimai/rb-sisimai.svg)](https://coveralls.io/r/sisimai/rb-sisimai)
[![Build Status](https://travis-ci.org/sisimai/rb-sisimai.svg?branch=master)](https://travis-ci.org/sisimai/rb-sisimai) 
[![Codacy Badge](https://api.codacy.com/project/badge/grade/38340177e6284a65be69c0c7c3dc2b58)](https://www.codacy.com/app/azumakuniyuki/rb-sisimai)
[![Ruby](https://img.shields.io/badge/ruby-v2.4.0--v2.7.0-red.svg)](https://www.ruby-lang.org/)
[![Gem Version](https://badge.fury.io/rb/sisimai.svg)](https://badge.fury.io/rb/sisimai)

- [**README(English)**](README.md)
- [シシマイ? | What is Sisimai](#what-is-sisimai)
    - [主な特徴的機能 | Key features](#key-features)
    - [コマンドラインでのデモ | Command line demo](#command-line-demo)
- [シシマイを使う準備 | Setting Up Sisimai](#setting-up-sisimai)
    - [動作環境 | System requirements](#system-requirements)
    - [インストール | Install](#install)
        - [RubyGemsから | From RubyGems](#from-rubygems)
        - [GitHubから | From GitHub](#from-github)
- [使い方 | Usage](#usage)
    - [基本的な使い方 | Basic usage](#basic-usage)
    - [解析結果をJSONで得る | Convert to JSON](#convert-to-json)
    - [コールバック機能 | Callback feature](#callback-feature)
    - [ワンライナー | One-Liner](#one-liner)
    - [出力例 | Output example](#output-example)
- [シシマイの仕様 | Sisimai Specification](#sisimai-specification)
    - [Ruby版とPerl版の違い | Differences between Ruby version and Perl version](#differences-between-ruby-version-and-perl-version)
    - [その他の仕様詳細 | Other specification of Sisimai](#other-specification-of-sisimai)
- [Contributing](#contributing)
    - [バグ報告 | Bug report](#bug-report)
    - [解析できないメール | Emails could not be parsed](#emails-could-not-be-parsed)
- [その他の情報 | Other Information](#other-information)
    - [関連サイト | Related sites](#related-sites)
    - [参考情報| See also](#see-also)
- [作者 | Author](#author)
- [著作権 | Copyright](#copyright)
- [ライセンス | License](#license)

What is Sisimai
===================================================================================================
Sisimai(シシマイ)はRFC5322準拠のエラーメールを解析し、解析結果をデータ構造に変換するインターフェイス
を提供するRubyライブラリです。[github.com/sisimai/p5-sisimai](https://github.com/sisimai/p5-sisimai/)
で公開しているPerl版シシマイから移植しました。

![](https://libsisimai.org/static/images/figure/sisimai-overview-1.png)

Key features
---------------------------------------------------------------------------------------------------
* __エラーメールをデータ構造に変換__
  * Rubyのデータ形式(HashとArray)とJSON(String)に対応
* __インストールも使用も簡単__
  * gem install
  * git clone & make
* __高い解析精度__
  * 解析精度はbounceHammerの2倍
  * 68種類のMTA/MDA/ESPに対応
  * Feedback Loopにも対応
  * 29種類のエラー理由を検出

Setting Up Sisimai
===================================================================================================
System requirements
---------------------------------------------------------------------------------------------------
Sisimaiの動作環境についての詳細は[Sisimai | シシマイを使ってみる](https://libsisimai.org/ja/start/)
をご覧ください。


* [Ruby 2.4.0 or later](http://www.ruby-lang.org/)
  * [__Oj | The fastest JSON parser and object serializer__](https://rubygems.org/gems/oj)
* Also works on [JRuby 9.0.4.0 or later](http://jruby.org)
  * [__JrJackson | A mostly native JRuby wrapper for the java jackson json processor jar__](https://rubygems.org/gems/jrjackson)

Install
---------------------------------------------------------------------------------------------------
### From RubyGems.org

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
======
Basic usage
---------------------------------------------------------------------------------------------------
下記のようにSisimaiの`rise()`メソッドをmboxかMaildirのPATHを引数にして実行すると解析結果が配列で
返ってきます。v4.25.6から元データとなった電子メールファイルへのPATHを保持する`origin`が利用できます。

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
v = Sisimai.rise('/path/to/mbox', vacation: true);

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
下記のようにSisimaiの`dump()`メソッドをmboxかMaildirのPATHを引数にして実行すると解析結果が文字列(JSON)
で返ってきます。

```ruby
# Get JSON string from parsed mailbox or Maildir/
puts Sisimai.dump('/path/to/mbox')  # or path to Maildir/

# dump() method also accepts "delivered" option like the following code:
puts Sisimai.dump('/path/to/mbox', delivered: true)
```

Callback feature
---------------------------------------------------------------------------------------------------
`Sisimai.rise`と`Sisimai.dump`の`:c___`引数はコールバック機能で呼び出されるProcオブジェクトを保持する
配列です。`:c___`の1番目の要素には`Sisimai::Message.parse`で呼び出されるProcオブジェクトでメールヘッダ
と本文に対して行う処理を、2番目の要素には、解析対象のメールファイルに対して行う処理をそれぞれ入れます。

各Procオブジェクトで処理した結果は`Sisimai::Data.catch`を通して得られます。

### [0] メールヘッダと本文に対して
`:c___`に渡す配列の最初の要素に入れたProcオブジェクトは`Sisimai::Message->parse()`で呼び出されます。

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

### 各メールのファイルに対して
`Sisimai->rise()`と`Sisimai->dump()`の両メソッドに渡せる引数`c___`(配列リファレンス)の2番目に入れた
コードリファレンスは解析したメールのファイルごとに呼び出されます。

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

コールバック機能のより詳細な使い方は
[Sisimai | 解析方法 - コールバック機能](https://libsisimai.org/ja/usage/#callback)をご覧ください。

One-Liner
---------------------------------------------------------------------------------------------------
```shell
$ ruby -rsisimai -e 'puts Sisimai.dump($*.shift)' /path/to/mbox
```

Output example
---------------------------------------------------------------------------------------------------
![](https://libsisimai.org/static/images/demo/sisimai-dump-02.gif)

```json
[{"catch":{"x-mailer":"","return-path":"neko@example.com"},"token":"7e81d3b9306fc7a7f3fb4c7b705189d6806d3d6b","lhost":"omls-1.kuins.neko.example.jp","rhost":"nekonyaan0022.apcprd01.prod.exchangelabs.com","alias":"","listid":"","reason":"userunknown","action":"failed","origin":"set-of-emails/maildir/bsd/lhost-office365-13.eml","subject":"にゃーん","messageid":"","replycode":"550","smtpagent":"Office365","hardbounce":true,"smtpcommand":"","destination":"neko.kyoto.example.jp","senderdomain":"example.com","feedbacktype":"","diagnosticcode":"Error Details Reported error: 550 5.1.10 RESOLVER.ADR.RecipientNotFound; Recipient not found by SMTP address lookup DSN generated by: NEKONYAAN0022.apcprd01.prod.exchangelabs.com","diagnostictype":"","deliverystatus":"5.1.10","timezoneoffset":"+0000","addresser":"neko@example.com","recipient":"kijitora-nyaan@neko.kyoto.example.jp","timestamp":1493508885}]
```

Sisimai Specification
===================================================================================================
Differences between Ruby version and Perl version
---------------------------------------------------------------------------------------------------
公開中のPerl版Sisimai(p5-sisimai)とRuby版Sisimai(rb-sisimai)は下記のような違いがあります。bounceHammer
2.7.13p3とSisimai(シシマイ)の違いについては[Sisimai | 違いの一覧](https://libsisimai.org/ja/diff/)を
ご覧ください。

| 機能                                        | Ruby version   | Perl version  |
|---------------------------------------------|----------------|---------------|
| 動作環境                                    | Ruby 2.4 - 2.7 | Perl 5.10 -   |
|                                             | JRuby 9.0.4.0- |               |
| 解析精度の割合(2000通のメール)[1]           | 1.00           | 1.00          |
| メール解析速度(1000通のメール)              | 2.22秒[2]      | 1.35秒        |
| インストール方法                            | gem install    | cpanm, cpm    |
| 依存モジュール数(コアモジュールを除く)      | 1モジュール    | 2モジュール   |
| LOC:ソースコードの行数                      | 10300行        | 10500行       |
| テスト件数(spec/,t/,xt/ディレクトリ)        | 453000件       | 311000件      |
| ライセンス                                  | 二条項BSD      | 二条項BSD     |
| 開発会社によるサポート契約                  | 提供中         | 提供中        |

1. [./ANALYTICAL-PRECISION](https://github.com/sisimai/rb-sisimai/blob/master/ANALYTICAL-PRECISION)を参照
2. Xeon E5-2640 2.5GHz x 2 cores | 5000 bogomips | 1GB RAM | Ruby 2.3.4p301

Other spec of Sisimai
---------------------------------------------------------------------------------------------------
- [**解析モジュールの一覧**](https://libsisimai.org/ja/engine/)
- [**バウンス理由の一覧**](https://libsisimai.org/ja/reason/)
- [**Sisimai::Dataのデータ構造**](https://libsisimai.org/ja/data/)

Contributing
===================================================================================================
Bug report
---------------------------------------------------------------------------------------------------
もしもSisimaiにバグを発見した場合は[Issues](https://github.com/sisimai/rb-sisimai/issues)にて連絡を
いただけると助かります。

Emails could not be parsed
---------------------------------------------------------------------------------------------------
Sisimaiで解析できないバウンスメールは
[set-of-emails/to-be-debugged-because/sisimai-cannot-parse-yet](https://github.com/sisimai/set-of-emails/tree/master/to-be-debugged-because/sisimai-cannot-parse-yet)リポジトリに追加してPull-Requestを送ってください。

Other Information
===================================================================================================
Related sites
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
* [README.md - README.md in English](https://github.com/sisimai/rb-sisimai/blob/master/README.md)
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

