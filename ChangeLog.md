RELEASE NOTES for Ruby version of Sisimai
================================================================================
- releases: "https://github.com/sisimai/rb-sisimai/releases"
- download: "https://rubygems.org/gems/sisimai"

v5.0.0(beta2)
--------------------------------------------------------------------------------
- release: ""
- version: ""
- changes:
  - **INCOMPATIBLE CHANGES SINCE SISIMAI VERSION 4**
    - **Sisimai requires Ruby 2.4 or later**
    - `Sisimai.make` marked as obsoleted and will be removed at Sisimai v5.1.0,
      use `Sisimai.rise` instead
    - Sisimai does not return the result which reason is `vacation` by default.
      Use `vacation: true` option at `Sisimai.rise()` method to get the parsed
      results for `vacation` reason. #220, #222
    - `Sisimai::Data` and `Sisimai::Fact`
      - #208 `Sisimai::Data` has been renamed to `Sisimai::Fact`
      - #197 `Sisimai::Data.softboucne` marked as obsoleted and will be removed
        at v5.1.0, use `Sisimai::Fact.hardbounce` instead
    - #198 `Sisimai::Message`
      - `Sisimai::Message` no longer creates an object
      - `Sisimai::Message.make` renamed to `Sisimai::Message.rise`
    - Callback feature #191
      - Parameter `:hook` for a callback has been removed from `Sisimai.rise()`
        and `Sisimai.dump()` methods. Use the first element of `:c___` parameter
        for setting a callback method instead.
      - Parameter `:c___` is a parameter of `Sisimai.rise` and `Sisimai.dump`,
        is an array reference and have two elements:
      - The first element of `:c___` is the same with `:hook` parameter, is for
        a callback method email headers and entire message body
      - The second element of `c___` parameter is for a callback method for each
        email file in Maildir/. The callback method is called at the end of each
        email file parsing.
  - Implement Sisimai::RFC2045(Born again Sisimai::MIME) for compatibility with
    the Go language version of Sisimai #199
  - Sisimai uses `minitest` as a test framework, RSpec has been removed
  - #217 `Sisimai::Message.rise` parses twice when the entire message body of a
    bounced mail is multi parted begins with "message/rfc822".
  - #218 Add error messages in some European languages into Office365 and Domino

v4.25.11
--------------------------------------------------------------------------------
- release: "Mon, 22 Feb 2021 21:15:22 +0900 (JST)"
- version: "4.25.11"
- changes:
  - Fix typo in `Sisimai::RFC3464`
  - Import some commits from Sisimai version 5 preview #
    - Improved code for getting an email address in `Sisimai::Address`
    - Improved code for checking the day of month value, for converting a full
      month name and a full day of the week at `Sisimai::DateTime`
    - Improvement code for picking text blocks of message/rfc822 part in RFC5322
    - Add 60+ error message patterns
    - Improved code for encodings in `Sisimai::Lhost::Domino`, `Sisimai::String`

v4.25.10
--------------------------------------------------------------------------------
- release: "Tue, 22 Dec 2020 13:22:22 +0900 (JST)"
- version: "4.25.10"
- changes:
  - #187 Remove the following old methods (marked as obsolete from v4.25.6)
    - `Sisimai::Mail.close` (automatically closes at the EOF)
    - `Sisimai::Mail.type` (use `Sisimai::Mail.kind` instead)
    - `Sisimai::Mail.mail.*` (use `Sisimai::Mail.data.*` instead)
  - `Sisimai::Lhost::Exim` and `Sisimai::Lhost::X3` improvement
  - #205 Code improvement for `Source-IP` field on `Sisimai::ARF`
  - #207 Updates for DMARC and SPF related errors
    - The value of `reason` rejected due to DMARC policy is `policyviolation`
    - The value of `reason` rejected due to no SPF record is `rejected`
    - Add some sample emails related to above into set-of-emails/

v4.25.9
--------------------------------------------------------------------------------
- release: "Sat,  3 Oct 2020 22:00:00 +0900 (JST)"
- version: ""
- changes:
  - Suppress warning messages on Ruby 2.7. Thanks to @koic
    - Suppress keyword argument warnings in Ruby 2.7 #200
    - Suppress a Ruby warning for `Object#=~` and bug fix to match patterns #201
  - #203 Replace `.+` with `[^ ]` on some large regular expressions for serious 
    performance reason.
  - #204 Suport Null MX (RFC7505) on Sendmail sisimai/set-of-emails#4

v4.25.8
--------------------------------------------------------------------------------
- release: "Fri, 17 Jul 2020 11:59:49 +0900 (JST)"
- version: "4.25.8"
- changes:
  - **Repository URL was changed to https://github.com/sisimai/rb-sisimai**
  - `Sisimai::Message.make` method was merged into `Sisimai::Message.new`
  - `Sisimai::Message.divideup` returns an array (faster than a hash)
  - Remove unused code blocks for deciding the order of email header fields at
    `Sisimai::Data.make` method
  - Remove old parameters: `datasrc` and `bounces` at the callback feature #189
  - Implement `Sisimai::Rhost::Spectrum` for parsing bounce mails returned from
    https://www.spectrum.com/.
  - Remove unsed method `Sisimai::Rhost->list`
  - Fix bugs in `Sisimai::Lhost::FML` and `Sisimai::Lhost::X5`
  - Fix code for finding the value of `Diagnostic-Code` field in multiple lines
    at `Sisimai::RFC3464`
  - Implement Sisimai::Rhost::Cox for parsing bounce mails returned from Cox:
    https://cox.com/ #193

v4.25.7
--------------------------------------------------------------------------------
- release: "Sat, 25 Apr 2020 22:22:22 +0900 (JST)"
- version: "4.25.7"
- changes:
  - Bug fix in `rake spec` for removed module `Sisimai::Lhost::UserDefined`

v4.25.6
--------------------------------------------------------------------------------
- release: "Wed, 22 Apr 2020 16:22:22 +0900 (JST)"
- version: "4.25.6"
- changes:
  - Performance improvement: 10% faster, reduced 9% of method calls
  - #176 Make `Sisimai::Message` 27% faster
    - Use the negative look-ahead regular expression code to convert all of the
      email header strings into key-value pairs as a HASH at newly implemented
      method `Sisiai::Message.makemap` #175. Thanks to @xtetsuji
    - Remove `Sisimai::Message.takeapart` (replaced with `makemap`)
    - Remove `Sisimai::Message.headers` (replaced with `makemap`)
    - Code improvement for `require` statement before method calls #177
  - Make `Sisimai::Order` 44% faster
    - Rewrite `Sisimai::Order.make`
    - Remove `Sisimai::Order.by`
    - Remove `Sisimai::Order.headers`
    - Remove `Sisimai::Lhost.headerlist`
    - And all `headerlist` method have been removed from `Sisimai::Lhost::*`,
      `Sisimai::RFC3834` and `Sisimai::ARF`
    - The MTA module to be loaded at first is decided by the first 2 words of
      each bounce mail subject, is defined at `Subject` in `Sisimai::Order`
    - Some variables are replaced with `state`
  - Each `field` parameter has been removed from the following methods because 
    Sisimai detect all the email header fields by `Sisimai::Message.makemap()`
    without having to specify field names at `field` parameter
    - `Sisimai.make`
    - `Sisimai::Message.new`
    - `Sisimai::Message.make`
  - Code improvement for `require` statement before calling `match()` method of
    some modules defined in `$PreMatches` at `Sisimai::Reason::UserUnknown`
  - Remove the following unused methods:
    - `Sisimai::MIME.patterns`
    - `Sisimai::SMTP.command`
  - `Sisimai::Lhost::Google` has been renamed to `Sisimai::Lhost::Gmail`
  - Implement 4 MTA modules: #178 #181
    - `Sisimai::Lhost::Barracuda`
    - `Sisimai::Lhost::PowerMTA`
    - `Sisimai::Lhost::X6`
    - `Sisimai::Lhost::GoogleGroups`
  - "email-" prefix of each sample email in set-of-emails/maildir directory has
    been replaced with "lhost-" sisimai/set-of-emails#14
  - SMTP Agent improvement #158
    - Remove `Email::` prefix from the value of `smtpagent` at parsed results
    - Remove `Sisimai::Lhost->smtpagent` method
  - Improved the following MTA modules:
    - `Sisimai::Lhost::Amavis` #183
    - `Sisimai::Lhost::InterScanMSS`
    - `Sisimai::Lhost::Office365` improvement for reading MIME-encoded subject
    - `Sisimai::Lhost::Exchange2007` supports error messages in `it-CH`
  - Tiny bug fix for `Subject` header decoding
  - Fix bug in code for getting an `"addresser"` address from `From:` field in
    the original message part which are multiple lines at `Sisimai::ARF`. #185
  - New accessor `origin` at `Sisimai::Data` and the parsed results for keeping
    a path to the source email #186
  - #187 `Sisimai::Mail` improvement for compatibilities with the Go language
    version of Sisimai which will be released this summer
    - Removed `Sisimai::Mail::STDIN.name` (not used)
    - Removed `Sisimai::Mail::Maildir.inodes` (not needed to check the inode)
    - Removed `Sisimai::Mail::Maildir.count` (use `offset` instead)
    - Warning message is displayed when the following methods are called:
      - `Sisimai::Mail.close` (automatically closes at the EOF)
      - `Sisimai::Mail.type` (use `Sisimai::Mail.kind` instead)
      - `Sisimai::Mail.mail.*` (use `Sisimai::Mail.data.*` instead)
      - Methods above will be removed at v4.25.10
    - `Sisimai::Mail::Memory.data` renamed to `Sisimai::Mail::Memory.payload`
    - `Sisimai::Mail::Maildir.size` keeps the number of files in the Maildir/
    - `Sisimai::Mail::Maildir.offset` keeps the number of email files in the
      Maildir/ which have been read
    - Call `Sisimai::Mail::*.read` directly instead of `Sisimai::Mail.read`
    - Remove `Sisimai::Lhost::UserDefined` (not used)
  - Add the following D.S.N. codes and error messages (not tested)
    - `Mailbox does not exist!` at `Sisimai::Reason::UserUnknown` (Amazon SES)
    - `Not a valid recipienet` at `Sisimai::Reason::UserUnknown` (Yahoo!)
    - `Envelope blocked` at `Sisimai::Reason::Rejected` (Minecast.com)
    - `5.2.122` is toomanyconn, `5.4.11` is contenterror, `5.7.51` is blocked
      at `Sisimai::Rhost::ExchangeOnline`

v4.25.5
--------------------------------------------------------------------------------
- release: "Wed, 22 Jan 2020 14:44:44 +0900 (JST)"
- version: "4.25.5"
- changes:
  - **JSON READING AS A INPUT SOURCE AND JSON PARSING AS A BOUNCE OBJECT ARE NO
    LONGER PROVIDED AS OF v4.25.5**
  - The following obsoleted classes and modules have been removed #166 #168
    - `Sisimai::Message::Email`
    - `Sisimai::Message::JSON`
    - `Sisimai::Order::Email`
    - `Sisimai::Order::JSON`
    - `Sisimai::Bite::Email`
    - `Sisimai::Bite::JSON`
  - Fix bug in code to detect whether a bounce mail was generated by Office365
    or not at `Sisimai::Lhost::Office365`
  - Import sisimai/p5-Sisimai#342
    - Fix parser code to get an error message which is not beginning with `#`
      character at Exchange2007.
  - Import sisimai/p5-Sisimai#347
    - Support case insensitive error code at `Sisimai::Rhost::FrancePTT`,
  - Import sisimai/p5-Sisimai#348
    - Code improvements at `Sisimai::Lhost::EinsUndEins` for detecting errors
      and setting the value of `rhost`
  - Many Pull-Requests and sample emails for French ESPs by @aderumier
    - Add 4 error code values at `Sisimai::Rhost::FrancePTT`
      - `102` = `blocked`
      - `426` = `suspend`
      - `505` = `systemerror`
      - `999` = `blocked`
    - Add 7 sample emails at set-of-emails/ directory: rhost-franceptt-04, 05,
      06, 07, 08, 10, and 11 for `Sisimai::Rhost::FrancePTT` #353 #357
    - Add many error codes and error messages from Orange and La Poste
  - Import sisimai/p5-Sisimai#350
    - Code improvement at `Sisimai::Lhost::Postfix` for setting `HELO` into the
      value of `smtpcommand` in the parsed results.
  - Import sisimai/p5-Sisimai#351
    - Code improvements at `Sisimai::Lhost::Postfix` for parsing an email which
      have neither delivery reports nor error messages.
  - Import sisimai/p5-Sisimai#352
    - Code improvements at `Sisimai::RFC3834` for parsing a vacation message
      replied automatically from iCloud.
  - Accessor improvements in the following classes:
    - `Sisimai::Message`
    - `Sisimai::Data`
    - `Sisimai::Mail` and child classes in `sisimai/mail` directory
  - Fix duplicated ranges in some regular expressions at `Sisimai::Address`
  - Large scale code improvement at each modules in `Sisimai::Lhost`
  - reduce the number of lines in code about 12%

v4.25.4
--------------------------------------------------------------------------------
- release: "Tue,  3 Dec 2019 12:34:45 +0900 (JST)"
- version: "4.25.4"
- changes:
  - #152 **THE ABILITY TO READ JSON STRING AS AN INPUT SOURCE AND TO PARSE JSON
    FORMATTED BOUNCE MESSAGE WILL NOT BE SUPPORTED AT Sisimai 4.25.5**
  - **The following modules for reading json string as an input source, and for
    parsing json formatted bounce message will be removed at Sisimai 4.25.5**
    - `Sisimai::Message::JSON`
    - `Sisimai::Bite::JSON`
    - `Sisimai::Bite::JSON::AmazonSES`
    - `Sisimai::Bite::JSON::SendGrid`
    - `Sisimai::Order::JSON`
  - Implement a new MTA module class `Sisimai::Lhost`, it is a parent class of
    all the MTA modules for a bounce mail returned as an email message via SMTP
    and **THE FOLLOWING NAME SPACES WERE MARKED AS OBSOLETED OR REMOVED** #153
    - `Sisimai::Bite`: Use `Sisimai::Lhost` instead
    - `Sisimai::Bite::Email`: Merged into `Sisimai::Lhost`
    - `Sisimai::Bite::Email::*`: Moved under `Sisimai::Lhost` as the same named
      MTA module
  - The following modules were marked as obsoleted, will be removed and merged
    into each parent class
    - `Sisimai::Message::Email`
    - `Sisimai::Order::Email`
  - USAGE AND PARAMETERS FOR THE FOLLOWING METHODS HAVE NOT BEEN CHANGED AT ALL
    AND WILL NOT BE CHANGED AFTER Sisimai 4.25.5
    - `Sisimai.make`
    - `Sisimai.dump`
    - `Sisimai::Message.new`
  - Implement `Sisimai::Rhost::IUA` for SMTP error codes at https://www.i.ua/.
  - Update error message pattern for ClamSMTP at "virusdetected" reason.
  - Fix an indicator string for detecting the beginning of the original message
    part at `Sisimai::Bite::Email::MFILTER`
  - Multibyte characters in the original subject header will not be removed and
    replaced with "MULTIBYTE CHARACTERS HAS BEEN REMOVED"
  - Error message `... had no relevant answers.` from GSuite is classified into
    "networkerror" reason.

v4.25.3
--------------------------------------------------------------------------------
- release: ""Sat,  7 Sep 2019 15:00:22 +0900 (JST)
- version: "4.25.3"
- changes:
  - Fix code for getting a recipient address from the original message part at
    `Sisimai::ARF`
  - Fix code for getting a recipient mail address and a subject string from the
    original messaage part at `Sisimai::Bite::Email::MailMarshalSMTP`
  - Fix code to delete unused multipart headers at `Sisimai::MIME.breaksup`
  - Fix code for getting a recipient email address and an expanded address from
    `Final-Recipient:` and `Original-Recipient:` field at `Sisimai::RFC3464`
  - Update code for matching error message "The user you are trying to contact
    is receiving mail at a rate that prevents additional messages from being
    delivered." at `Sisimai::Rhost::GoogleApps`
  - Update error message pattern for "blocked" reason from GMX: "ESMTP Service
    not available No SMTP service Bad DNS PTR resource record."
  - Update error message pattern for "suspend" reason responded from i.ua MTA:
    "550 Mailbox is frozen."

v4.25.2
--------------------------------------------------------------------------------
- release: "Thu,  1 Aug 2019 20:00:00 +0900 (JST)"
- version: "4.25.2"
- changes:
  - THIS RELEASE IS TO FIX SERIOUS BUGS IN ONLY THE PERL VERSION OF SISIMAI
  - Import Pull-Request from https://github.com/sisimai/p5-Sisimai/pull/324
  - Improved MIME decoding code in Sisimai::MIME
  - Strictly checks the number of parsed emails in `make test`

v4.25.1
--------------------------------------------------------------------------------
- release: "4.25.1"
- version: "Tue, 23 Jul 2019 10:00:00 +0900 (JST)"
- changes:
  - Check the format of the value of `Message-Id` header for detecting a bounce
    mail from Exim or not.
  - Call `Sisimai::Rhost::FrancePTT` module when the value of `rhost` includes
    `.wanadoo.fr`.
  - Fix code at `Sisimai::Message::Email.takeapart` method to decode a Subject
    header of the original message.
  - #147 Update error messages for Low Reputation Error from Gmail.
  - Parser code to read bounce mails from m-FILTER at `Sisimai::Message::Email`
    has been improved.
  - Status 5.4.1 from Exchange Online is classified into "rejected" reason.
  - Callback method specified at `Sisimai::Message.new()` with `hook` is called
    just before calling `scan()` method of each `Sisimai::Bite::Email` module.
  - Code improvement in `Sisimai::Bite::Email::Sendmail` for getting error mes-
    sages returned from Google.

v4.25.0
--------------------------------------------------------------------------------
- release: "Tue,  9 Apr 2019 11:22:22 +0900 (JST)"
- version: "4.25.0"
- changes:
  - Implement new class `Sisimai::RFC1894` for parsing message/delivery-status
    part. #133
  - Experimental implementation at the following MTA, Rhost modules:
    - `Sisimai::Bite::Email::Amavis`: amavisd-new
    - `Sisimai::Rhost::TencentQQ`: Tencent QQ (mail.qq.com)
  - Remove unused methods and variables
    - `Sisimai::DateTime.hourname`
    - `$Sisimai::DateTime::HourNames`
    - `Sisimai::RFC5322.is_domainpart`
  - Code refactoring: less lines of code and shallower indentation.
  - Build test for JRuby on Travis CI was temporarily disabled. #138
  - Sisimai works on Ruby 2.6.0
  - Fix `Sisimai::ARF.is_arf` method to remove angle brackets:`<` and `>` from
    `From:` header.
  - Fix serious bug (Hash key typo) in `Sisimai::Rhost::Google`
  - Less Symbol, less `String#to_sym`.
  - Remove `set-of-emails/logo` directory because we cannot change the license
    of each file in the directory to The 2-Clause BSD License.
  - Update error message patterns in the following modules:
    - `Sisimai::Reason::Blocked` (hotmail, ntt docomo)
    - `Sisimai::Reason::PolicyViolation` (postfix)
    - `Sisimai::Reason::Rejected` (postfix)
    - `Sisimai::Reason::SystemError` (hotmail)
    - `Sisimai::Reason::TooManyConn` (ntt docomo)
    - `Sisimai::Reason::UserUnknown` (hotmail)
    - `Sisimai::Bite::Email::McAfee` (userunknown)
    - `Sisimai::Bite::Email::Exchange2007` (securityerror)
  - The order of `Sisimai::Bite::Email` modules to be loaded has been changed:
    Load Office365 and Outlook prior to Exchange2007 and Exchange2003.
  - Update the followng MTA modules for improvements and bug fixes:
    - `Sisimai::Bite::Email::Exchange2007`
  - MIME Decoding in `Subject:` header improved.
  - Bug fix in `Sisimai::MIME.is_mimeencoded` method.
  - Make stable the order of MTA modules which have MTA specific email headers
    at `Sisimai::Order::Email.headers` method.

v4.24.1
--------------------------------------------------------------------------------
- release: "Wed, 14 Nov 2018 11:09:44 +0900 (JST)"
- version: "4.24.1"
- changes:
  - Fix bug in Sisimai::RFC3464: scan method unintentionally detects non-bounce
    mail as a bounce.
  - Remove unused method Sisimai::DateTime.o2d

v4.24.0
--------------------------------------------------------------------------------
- release: "Thu,  1 Nov 2018 18:00:00 +0900 (JST)"
- version: "4.24.0"
- changes:
  - Variable improvement (remove redundant substitution)
  - Remove Sisimai::RFC2606 (Unused module)
  - MIME decoding improvement #130 Thanks to @outreach-soren.
    - Implement Sisimai::MIME.makeflat
    - Implement Sisimai::MIME.breaksup
    - Call Sisimai::MIME.makeflat at Sisimai::Message::Email.parse
    - Other related updates in Sisimai::Bite::Email::*
  - Tiny improvement in Sisimai::String.to_plain
  - Update "blocked" error message patterns for iCloud.
    - A client IP address has no PTR record
    - Invalid HELO/EHLO name

v4.23.0
--------------------------------------------------------------------------------
- release: "Fri, 31 Aug 2018 20:19:54 +0900 (JST)"
- version: "4.23.0"
- changes:
  - #124 Implement Sisimai::Mail::Memory class for reading bounce messages from
    memory(variable).
  - Update regular expression in Sisimai::Bite::Email::Office365 for detecting
    failure on SMTP RCPT.
  - #126 Fix awful bugs(NoMethodError) in Sisimai::Bite::Email::Biglobe, EZweb,
    and KDDI. Thanks to @rinmu.
  - #128 Less method calls: use method chain, bang method.
  - Import commit  sisimai/p5-Sisimai@cccb4ef Some test code have been loosened
    for UTC+13(Pacific/Tongatapu), UTC+14(Pacific/Kiritimati).
  - #127 Fix "NoMethodError" in Sisimai::Bite::Email::Postfix when the value of
    Diagnostic-Code field is folded. Thanks to @Unknown22.

v4.22.7
--------------------------------------------------------------------------------
- release: "Mon, 16 Jul 2018 13:02:54 +0900 (JST)"
- version: "4.22.7"
- changes:
  - Register D.S.N. "4.4.312" and "5.4.312" on Office 365 as "networkerror".
  - Fix error message pattern in Sisimai::Reason::SecurityError.
  - Fix code to get the original Message-Id field which continued to the next
    line. Thanks to Andreas Mock.
  - Update error message pattern in Sisimai::Reason::SpamDetected.
  - Add 15 sample emails for Postfix, Outlook and others.
  - Add 3 sample emails for Sisimai::RFC3464.
  - Add 2 sample vacation emails for Sisimai::RFC3834.

v4.22.6
--------------------------------------------------------------------------------
- release: "Wed, 23 May 2018 20:00:00 +0900 (JST)"
- version: ""
- changes:
  - #115 Fix bug in Sisimai::MIME.qprintd().
  - Error message patterns in Sisimai::Reason::Filtered have been replaced with
    fixed strings.
  - #116 Remove sample email files listed in sisimai/set-of-emails#6 to clarify
    copyrights.
  - The value of "softbounce" in the parsed results is always "1" when a reason
    is "undefined" or "onhold".
  - #117 Less regular expression in each class of Sisimai::Bite::Email.
  - #118 Cool logo for "set-of-emails". Thanks to @batarian71.
  - #119 Implement Sisimai::Rhost::KDDI for detecting a bounce reason of au via
    msmx.au.com or lsean.ezweb.ne.jp. Thanks to @kokubumotohiro.
  - Update sample emails and codes for getting error messages in bounced emails
    on Oath(Yahoo!).
  - Add many sample emails for "notaccept" and "rejected".

v4.22.5
--------------------------------------------------------------------------------
- release: "Fri, 30 Mar 2018 12:29:36 +0900 (JST)"
- version: "4.22.5"
- changes:
  - #112 The order to load MTA modules improvement.
  - Sample emails in set-of-emails/ which are not owned by Sisimai project have
    been removed.
  - Update error message patterns in Sisimai::Reason::Expired.
  - Less regular expression in each child class of Sisimai::Reason #113.
  - Pre-Updates for au.com, the new domain of EZweb from Apr 2018 announced at
    http://news.kddi.com/kddi/corporate/newsrelease/2017/08/22/2637.html #114

v4.22.4
--------------------------------------------------------------------------------
- release: "Wed, 14 Feb 2018 10:44:00 +0900 (JST)"
- version: "4.22.4"
- changes:
  - Import commit sisimai/p5-Sisimai@8c6eb33, Add status code 4.7.25 (RFC-7372)
    as "blocked".
  - The following performance improvements makes 1.49 times faster.
    - It makes rb-Sisimai on JRuby 1.16 times faster.
    - #96 String#+ and sprintf replaced with String#<< at Pull-Request #103.
    - #98 loop do replaced with while(true) at Pull-Request #104.
    - #99 String#=~ and regular expressions /\A...\z/, /\A.../ or /...\z/ have
      been replaced with String#start_with?, String#end_with?, String#include?,
      Array#include?, or String#== at Pull-Request #105, #107, #108.
    - #102 String#sub(/...\z/, '...') has been replaced with String#chomp, or
      String#strip, String#lstrip, String#rstrip at Pull-Request #106.
    - Import Pull-Request sisimai/p5-Sisimai#258, remove /i modifier from each
      regular expressions as possible and call String#downcase before matching.
    - Pull-Request #111, Some Array#each have been replaced with Array#shift in
      while loop.

v4.22.3
--------------------------------------------------------------------------------
- release: "Tue, 26 Dec 2017 09:22:22 +0900 (JST)"
- version: "4.22.3"
- changes:
  - Issue #88: Fix codes in Sisimai.DateTime.parse() for setting numeric values
    using sprintf(). Thanks to @phuong1492.
  - Import Pull-Request sisimai/p5-Sisimai#239, add error message patterns for
    laposte.net and orange.fr.
  - Import Pull-Req sisimai/p5-Sisimai#244 to follow up sisimai/p5-Sisimai#239.
    More support for Orange and La Poste.
  - Import Pull-Request sisimai/p5-Sisimai#245, update error message patterns
    of SFR and Free.fr.
  - Import Pull-Request sisimai/p5-Sisimai#246, large scale updates for Exim
    and error message patterns.
  - Merge Pull-Request #93 from @subuta to fix issue #92. Sisimai.make() method
    passes ActiveSupport::HashWithIndifferentAccess object with `input: "json"`
    parameter. Thanks to @subuta.
  - Import Pull-Request sisimai/p5-Sisimai#247, Add 100+ error message patterns
    into the following reason classes: Blocked, Expired, Filtered, HostUnknown,
    PolicyViolation, MailboxFull, NetworkError, NoRelaying, Rejected, Suspend,
    SpamDetected, SystemError, TooManyConn, and UserUnknown.
  - Fix bug in a regular expression object for concatenating error messages in
    Sisimai::Bite::Email::Exim.
  - Fix a wrong regular expression for detecting a recipient address and error
    messages in Sisiamai::Bite::Email::IMailServer.
  - Import Pull-Request sisimai/p5-Sisimai#247: Improved code at Sisimai::Data
    to remove string like "550-5.1.1" from an error message for to be matched
    exactly with regular expressions defined in each class of Sisimai::Reason.
  - Fixed issue #91, Import and convert error messages and reasons table from
    Sisimai::Bite::Email::Exchange2007 into Sisimai::Rhost::ExchangeOnline for
    detecting an error reason. Thanks to @joaoscotto.
  - Fix code to avoid an error with "invalid byte sequence in UTF-8" reported
    at https://heartbeats.jp/hbblog/2017/12/sisimai.html .
  - Implement Sisimai::Bite::Email::FML to parse bounce mails generated by fml
    mailing list server/manager. Thanks to @ttkzw.

v4.22.2
--------------------------------------------------------------------------------
- release: "Fri, 13 Oct 2017 11:59:53 +0900 (JST)"
- version: "4.22.2"
- changes:
  - Apply Pull-Request #84 (issue #83) for setting the value of `softorhard` in 
    `Sisimai::SMTP::Error.soft_or_hard` method. Thanks to @lunatyq.
  - Fix a wrong value assignment, and code for Performance/StartWith reported
    from Rubocop in Sisimai::Bite::Email::GSuite.
  - Update codes about Lint/AssignmentInCondition, Style/Next, Style/EmptyElse,
    Style/UselessAssignment, and others reported from Rubocop.
  - Fix code for Performance/Casecmp, Performance/LstripRstrip in Sisimai::MIME.
  - Update code for Style/SymbolProc in Sisimai::Message::Email.
  - Support parsing JSON object from SendGrid Event Webhook.
  - Suuport "event": "spamreport" via Feedback Loop on SendGrid Event Webhook.
  - Implement `Sisimai::Address.is_undisclosed` method.
  - Import Pull-Request #237: Support parsing bounce mail from GoDaddy.
  - Fix bug for setting the value of `date` in Sisimai::Bite::Email::Postfix.
  - Remove obsoleted classes: Sisimai::MTA, Sisimai::MSP, and Sisimai::CED.
  - Remove obsoleted method: `Sisimai::Address.parse`.

v4.22.1
--------------------------------------------------------------------------------
- release: "Tue, 29 Aug 2017 17:25:22 +0900 (JST)"
- version: "4.22.1"
- changes:
  - Sisimai::Address was born again: import Pull-Request sisimai/p5-Sisimai#231
    - Implement new email address parser method: find()
    - Implement new constructor: make()
    - Implement new writable accessors: name() and comment()
    - parse() method was marked as obsoleted
  - **Require Oj 3.0.0 or later. Build test fails when the version of installed
    Oj is 2.18.* on CRuby.**
  - Tested on JRuby 9.1.9.0.
  - Fix wrong constant name in Sisimai::Rhost::ExchangeOnline reported at issue
    #77. Thanks to @rdeavila.
  - Improved code in Sisimai::Message::Email to avoid an exception reported at
    issue #82. Thanks to @hiroyuki-sato.
  - Fixed wrong bitwise operation in Sisimai::RFC3464 for getting the original
    message part Thanks to @hiroyuki-sato.

v4.22.0
--------------------------------------------------------------------------------
- release: "Tue, 22 Aug 2017 18:25:55 +0900 (JST)"
- version: "4.22.0"
- changes:
  - Import Pull-Request sisimai/p5-Sisimai#225, bounce reason: "securityerror"
    has been divided into the following three reasons:
    - securityerror
    - virusdetected
    - policyviolation
  - Issue #78 All the MTA modules have been moved to Sisimai::Bite::* and old
    MTA modules: Sisimai::MTA, Sisimai::MSP, Sisimai::CED, and all the methods
    in these classes have been marked as obsoleted.
  - Import Pull-Request sisimai/p5-Sisimai#230 Sisimai::Address.find method has
    been implemented experimentaly as bourne again parser for email addresses.

v4.21.1
--------------------------------------------------------------------------------
- release: "Mon, 29 May 2017 14:22:22 +0900 (JST)"
- version: "4.21.1"
- changes:
  - Pull-Request #73, Fix codes for initializing a hash element with an empty
    string in Sisimai::MTA::Postfix. Thanks to @MichiakiNakaya.
  - Import pull-request: https://github.com/sisimai/p5-Sisimai/pull/222 from
    p5-Sisimai to improve error message patterns.
  - Changes file has been renamed to **ChangeLog.md** and converted to Markdown
    format.
  - Import Pull-Request https://github.com/sisimai/p5-Sisimai/pull/223 for code
    improvement to detect DNS related errors at G Suite.
  - Improved code to detect RFC7505 (NullMX) error: sisimai/set-of-emails#4.
  - Code improvements for checking and decoding irregular MIME encoded strings
    at is_mimeencoded and mimedecode methods in Sisimai::MIME class reported at
    issue #75. Thanks to @winebarrel.
  - Add unit test codes to test all the changes at issue #75.

v4.21.0 - Support G Suite
--------------------------------------------------------------------------------
- release: "Mon, 10 Apr 2017 12:17:22 +0900 (JST)"
- version: "4.21.0"
- changes:
  - Experimental implementation: new MTA module Sisimai::MSP::US::GSuite for
    parsing a bounce mail returned from G Suite.
  - `Sisimai.make()` and `Sisimai::Message.new()` methods check the value of a
    `field` argument more strictly.
  - Improved `Sisimai::SMTP::Status.find()`. The method checks whether a found
    value as D.S.N. is IPv4 address or not.
  - Improved code for getting error messages, D.S.N. values, and SMTP reply
    codes in `Sisimai::MTA::Postfix.scan()` method.
  - Pull-Request #69, Fix some typos. Thanks to @koic.
  - Pull-Request #71, Fix break statement. Thanks to @MichiakiNakaya.
  - Issue #70, All the value of `$PATH` in Makefile have been fixed to build a
    gem file for JRuby Platform. Thanks to @MichiakiNakaya, @hiroyuki-sato.

v4.20.2
--------------------------------------------------------------------------------
- release: "Sat, 11 Mar 2017 16:32:48 +0900 (JST)"
- version: "4.20.2"
- changes:
  - Pull-Request #63 Add some error message patterns for a bounce message from
    Amazon SES SMTP endpoint.
  - Fix regular expression in `Sisimai::Message::Email.headers()` method for
    resolving issue #65 reported from @rdeavila.
  - Issue #67, Fix code in `Sisimai.make()` method for reading bounce email data
    from STDIN. Thanks to @marine_dayo.
  - Callback feature improvement: import pull-request from sisimai/p5-Sisimai
    https://github.com/sisimai/p5-Sisimai/pull/210.

v4.20.1
--------------------------------------------------------------------------------
- release: "Sat, 31 Dec 2016 20:10:22 +0900 (JST)"
- version: "4.20.1"
- changes:
  - Fix the Java version of Gem file.

v4.20.0 - Support Bounce Ojbect (JSON)
--------------------------------------------------------------------------------
- release: "Sat, 31 Dec 2016 13:36:22 +0900 (JST)"
- version: "4.20.0"
- changes:
  - Experimental implementation: New MTA modules for 2 Cloud Email Deliveries.
    These modules can parse JSON formatted bounce objects and can convert to
    Sisimai::Data object.
    - Sisimai::CED::US::AmazonSES
    - Sisimai::CED::US::SendGrid
  - Format of `smtpagent` in the parsed result has been changed. It includes the
    category name of MTA/MSP modules like `MTA::Sendmail`, `MTA::Postfix`, and
    `MSP::US::SendGrid`.
  - The Domain part of dummy email address defined in Sisimai::Address module
    has been changed from `dummy-domain.invalid` to `libsisimai.org.invalid`.
  - `Sisimai::SMTP.is_softbounce()` method has been deleted.
  - Code improvement for avoid `Invalid byte sequence in UTF-8 (ArgumentError)`
    error in `Sisimai::String.to_plain()` method reported from M.R.
  - Sisimai works on Ruby 2.4.0.

v4.19.0 - Callback Feature
--------------------------------------------------------------------------------
- release: "Tue, 18 Oct 2016 14:19:10 +0900 (JST)"
- version: "4.19.0"
- changes:
  - Implement a callback feature at `Sisimai.make()` and `Sisimai.dump()` methods.
    More imformation about the feature are available at the following pages:
    - https://libsisimai.org/en/usage#callback
    - https://libsisimai.org/ja/usage#callback
  - Implement `Sisimai.match()` method: issue #52.
  - Minor bug fix in `Sisimai::MSP::US::AmazonSES.scan()` method.

v4.18.1
--------------------------------------------------------------------------------
- release: "Sun, 11 Sep 2016 20:05:20 +0900 (JST)"
- version: "4.18.1"
- changes:
  - Fix bug in `Sisimai::Mail::STDIN.read()` method reported at issue #61.
    Thanks to @yaegassy.
  - Fix bug in `Sisimai::MIME.qprintd()` reported at issue #60.
  - Improved code related to MIME decoding.
  - Implement `Sisimai::String.to_plain()` for converting from HTML message to
    plain text before parsing. The method and related codes are imported from
    pull-request #197 at p5-Sisimai.

v4.18.0 - Improvements for Microsoft Exchange Servers
--------------------------------------------------------------------------------
- release: "Mon, 22 Aug 2016 20:40:55 +0900 (JST)"
- version: "4.18.0"
- changes:
  - Import pull-request https://github.com/sisimai/rb-Sisimai/pull/59 (soft
    bounce improvement) from Perl version of Sisimai.
  - Sisimai::MTA::Exchange has been renamed to Sisimai::MTA::Exchange2003.
  - Implement new MTA module Sisimai::MTA::Exchange2007.

v4.17.2
--------------------------------------------------------------------------------
- release: "Tue, 26 Jul 2016 21:00:17 +0900 (JST)"
- version: "4.17.2"
- changes:
  - Issue #174, Implement Sisimai::Rhost::ExchangeOnline for the bounce mail
    from on-premises Exchange 2013 and Office 365.
  - The reason of status code: `4.4.5` is `systemfull`.
  - Code improvement at Sisimai::MSP::US::Office365.

v4.17.1
--------------------------------------------------------------------------------
- release: "Wed, 30 Mar 2016 14:00:22 +0900 (JST)"
- version: "4.17.1"
- changes:
  - Ported codes from https://github.com/sisimai/p5-Sisimai/pull/180 for fixing
    issue https://github.com/sisimai/p5-Sisimai/issues/179,  a variable defined
    in `lib/sisimai/mta/exim.rb` is not quoted before passing to `%r//` operator.
  - Fixed serious bug in `Sisimai::Mail::Maildir#read` method reported at issue
    #55 and #56 by pull-request #57. Thanks to @taku1201.

v4.17.0 - New Error Reason "syntaxerror"
--------------------------------------------------------------------------------
- release: "Wed, 16 Mar 2016 12:22:44 +0900 (JST)"
- version: "4.17.0"
- changes:
  - Implement new reason **syntaxerror**. Sisimai will set `syntaxerror` to the
    raeson when the value of `replycode` begins with `50` such as 502, 503,
    or 504. Imported from https://github.com/sisimai/p5-Sisimai/pull/170.
  - Implement `description()` method at each class in `sisimai/reason/*.rb` and
    `Sisimai.reason()` method for getting the list of reasons Sisimai can detect
    and its description: issue #48.
  - Remove unused method `Sisimai::Reason.match()`, issue #49.
  - Some methods of Sisimai::Address class allow `postmaster`, `mailer-daemon`
    (without a domain part) as an email address.
  - `Sisimai::RFC5322.is_mailerdaemon()` method returns true when the argument
    includes `postmaster`.
  - Merge pull-request #51, new method `Sisimai::RFC5322.weedout()` and code
    improvements in all the MTA/MSP modules.


v4.16.0 - New Error Reason "delivered"
--------------------------------------------------------------------------------
- release: "Thu, 18 Feb 2016 13:49:01 +0900 (JST)"
- version: "4.16.0"
- changes:
  - Implement new reason **delivered**. Sisimai set `delivered` to the reason
    when the value of `Status:` field in a bounce message begins with `21. This
    feature is optional and is not enabled by default.
  - Implement new method `Sisimai.engine()`. The method returns the list of MTA
    and MSP module list implemented in Sisimai.
  - Fix serious bug (`gem install` fails on JRuby environment) in Gemfile and
    sisimai.gemspec. This bug is reported at issue #46 and pull-request #47.
    Thanks to @hiroyuki-sato and all the people who helped for resolving this
    issue on https://github.com/rubygems/rubygems/issues/1492.

v4.15.1
--------------------------------------------------------------------------------
- release: "Wed, 17 Feb 2016 01:36:45 +0900 (JST)"
- version: "4.15.1"
- changes:
  - Fix serious bug: command `gem install sisimai` fails on JRuby, reported at
    issue #46. Thanks to @hiroyuki-sato.
  - v4.15.1 exist on Ruby version of Sisimai only.

v4.15.0 - Oj or JrJackson Required
--------------------------------------------------------------------------------
- release: "Sat, 13 Feb 2016 12:40:15 +0900 (JST)"
- version: "4.15.0"
- changes:
  - Beginning with this version, Sisimai requires Oj(MRI) or JrJackson(JRuby)
    for encoding parsed data to JSON string more faster (about 10%-20% faster
    than before). Implemented at pull-request #44 and discussed in issue #42.
    Thanks to @hiroyuki-sato.
  - Implement new MTA/MSP module Sisimai::MSP::US::AmazonWorkMail for parsing
    a bounce mail via Amazon WorkMail. The module and test codes are imported
    from https://github.com/sisimai/p5-Sisimai/pull/162.
  - Implement new MTA/MSP module Sisimai::MSP::US::Office365 for parsing error 
    mails via Microsoft Office 365. The module, test codes, and sample emails
    are imported from https://github.com/sisimai/p5-Sisimai/pull/164.
  - New method `Sisimai::Address#to_s` to get an email address as String, it is
    implemented at pull-request #39. Thanks to @hiroyuki-sato.
  - Almost all of the class variables are removed for resolving issue #40 and
    merged pull-request #43, thanks to @hiroyuki-sato.

v4.14.2 - Ruby Version of Sisimai
--------------------------------------------------------------------------------
- release: "Wed,  3 Feb 2016 13:29:17 +0900 (JST)"
- version: "4.14.2"
- changes:
  - The first release of rb-Sisimai.

