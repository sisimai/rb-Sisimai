require 'minitest/autorun'
require 'sisimai/address'
require 'sisimai/rfc5322'

class AddressTest < Minitest::Test
  Methods = {
    class:  %w[new find s3s4 expand_verp expand_alias undisclosed is_emailaddress is_mailerdaemon],
    object: %w[address host user verp alias comment name],
  }

  EmailAddrs = [
    # [Input-Value, Address, Name, Comment]
    ['"Neko" <neko@example.jp>',                    'neko@example.jp',    'Neko',                     ''],
    ['"=?ISO-2022-JP?B?dummy?=" <nyan@example.jp>', 'nyan@example.jp',    '=?ISO-2022-JP?B?dummy?=',  ''],
    ['"N Y A N K O" <nyanko@example.jp>',           'nyanko@example.jp',  'N Y A N K O',              ''],
    ['"Shironeko Lui" <lui@example.jp>',            'lui@example.jp',     'Shironeko Lui',            ''],
    ['<aoi@example.jp>',                            'aoi@example.jp',     '',                         ''],
    ['<may@example.jp> may@example.jp',             'may@example.jp',     'may@example.jp',           ''],
    ['Odd-Eyes Aoki <aoki@example.jp>',             'aoki@example.jp',    'Odd-Eyes Aoki',            ''],
    ['Mikeneko Shima <shima@example.jp> SHIMA@EXAMPLE.JP', 'shima@example.jp', 'Mikeneko Shima SHIMA@EXAMPLE.JP', ''],
    ['chosuke@neko <chosuke@example.jp>',           'chosuke@example.jp', 'chosuke@neko',             ''],
    ['akari@chatora.neko <akari@example.jp>',       'akari@example.jp',   'akari@chatora.neko',       ''],
    ['mari <mari@example.jp> mari@host.int',        'mari@example.jp',    'mari mari@host.int',       ''],
    ['8suke@example.gov (Mayuge-Neko)',             '8suke@example.gov',  '8suke@example.gov',        '(Mayuge-Neko)'],
    ['Shibainu Hachibe. (Harima-no-kami) 8be@example.gov', '8be@example.gov', 'Shibainu Hachibe. 8be@example.gov', '(Harima-no-kami)'],
    ['neko(nyaan)chan@example.jp',                  'nekochan@example.jp','nekochan@example.jp',      '(nyaan)'],
    ['(nyaan)neko@example.jp',                      'neko@example.jp',    'neko@example.jp',          '(nyaan)'],
    ['neko(nyaan)@example.jp',                      'neko@example.jp',    'neko@example.jp',          '(nyaan)'],
    ['nora(nyaan)neko@example.jp(cat)',             'noraneko@example.jp','noraneko@example.jp',      '(nyaan) (cat)'],
    ['<neko@example.com>:',                         'neko@example.com',   ':',                        ''],
    ['"<neko@example.org>"',                        'neko@example.org',   '',                         ''],
    ['"neko@example.net"',                          'neko@example.net',   'neko@example.net',         ''],
    ['neko@example.edu',                            'neko@example.edu',   'neko@example.edu',         ''],
    ['`neko@example.cat`',                          'neko@example.cat',   '`neko@example.cat`',       ''],
    ['[neko@example.gov]',                          'neko@example.gov',   '[neko@example.gov]',       ''],
    ['{neko@example.int}',                          'neko@example.int',   '{neko@example.int}',       ''],
    ['"neko.."@example.jp',                         '"neko.."@example.jp','"neko.."@example.jp',      ''],
    ['Mail Delivery Subsystem <MAILER-DAEMON>',     'MAILER-DAEMON',      'Mail Delivery Subsystem',  ''],
    ['postmaster',                                  'postmaster',         'postmaster',               ''],
    ['neko.nyaan@example.com',                      'neko.nyaan@example.com',       'neko.nyaan@example.com',       ''],
    ['neko.nyaan+nyan@example.com',                 'neko.nyaan+nyan@example.com',  'neko.nyaan+nyan@example.com',  ''],
    ['neko-nyaan@example.com',                      'neko-nyaan@example.com',       'neko-nyaan@example.com',       ''],
    ['neko-nyaan@example.org.',                     'neko-nyaan@example.org',       'neko-nyaan@example.org.',      ''],
    ['n@example.com',                               'n@example.com',        'n@example.com',          ''],
    ['"neko.nyaan.@.nyaan.jp"@example.com',         '"neko.nyaan.@.nyaan.jp"@example.com', '"neko.nyaan.@.nyaan.jp"@example.com', ''],
    ['"neko nyaan"@example.org',                    '"neko nyaan"@example.org',     '"neko nyaan"@example.org',     ''],
#   [q|"neko.(),:;<>[]\".NYAAN.\"neko@\\ \"neko\".nyaan"@neko.example.com|, 
#    q|"neko.(),:;<>[]\".NYAAN.\"neko@\\ \"neko\".nyaan"@neko.example.com|,
#    q|"neko.(),:;<>[]\".NYAAN.\"neko@\\ \"neko\".nyaan"@neko.example.com|,
#    ''],
    ['neko-nyaan@neko-nyaan.example.com',           'neko-nyaan@neko-nyaan.example.com', 'neko-nyaan@neko-nyaan.example.com', ''],
    ['neko@nyaan',                                  'neko@nyaan',         'neko@nyaan',               ''],
#   [{q[#!$%&'*+-/=?^_`{}|~@example.org],            q[#!$%&'*+-/=?^_`{}|~@example.org], q[#!$%&'*+-/=?^_`{}|~@example.org], ''],
#   [q*"()<>[]:,;@\\\"!#$%&'-/=?^_`{}| ~.a"@example.org*,
#    q*"()<>[]:,;@\\\"!#$%&'-/=?^_`{}| ~.a"@example.org*,
#    q*"()<>[]:,;@\\\"!#$%&'-/=?^_`{}| ~.a"@example.org*,
#    ''],
    ['" "@example.org',                            '" "@example.org',    '" "@example.org',           ''],
    ['neko@localhost',                             'neko@localhost',     'neko@localhost',            ''],
    ['neko@[IPv6:2001:DB8::1]',                    'neko@[IPv6:2001:DB8::1]', 'neko@[IPv6:2001:DB8::1]', '' ],
  ]
  IsNotEmail = ['22', 'neko', 'cat%neko.jp', '', '@@@@@', '{}']
  ManyEmails = [
    '"Neko, Nyaan" <(nora)neko@example.jp>, Nora Nyaans <neko(nora)@example.jp>',
    'Neko (Nora, Nyaan) <neko@example.jp>, (Neko) "Nora, Mike" <neko@example.jp>',
  ]
  Postmaster = [
    'mailer-daemon@example.jp', 
    'MAILER-DAEMON@example.cat',
    'Mailer-Daemon <postmaster@example.org>',
    'MAILER-DAEMON',
    'postmaster',
    'postmaster@example.org',
  ];
  def test_methods
    cv = Sisimai::Address.new(address: 'maketest@libsisimai.org')
    assert_instance_of Sisimai::Address, cv
    Methods[:class].each  { |e| assert_respond_to Sisimai::Address, e }
    Methods[:object].each { |e| assert_respond_to cv, e }
  end

  def test_address
    ci = 1
    cx = EmailAddrs.size

    EmailAddrs.each do |e|
      refute_empty e[0]
      refute_empty e[1]
      refute_nil   e[2]
      refute_nil   e[3]

      # Sisimai::Address#find
      cv = Sisimai::Address.find(e[0])
      assert_instance_of Array, cv
      assert_equal 1, cv.size
      assert_equal e[1], cv[0][:address], sprintf("[%02d/%02d] value[0] = %s", ci, cx, e[0])
      assert_equal e[2], cv[0][:name],    sprintf("[%02d/%02d] value[0] = %s", ci, cx, e[0])
      assert_equal e[3], cv[0][:comment], sprintf("[%02d/%02d] value[0] = %s", ci, cx, e[0])

      # Sisimai::Address#find(v, true)
      cv = Sisimai::Address.find(e[0], true)
      assert_instance_of Array, cv
      assert_equal 1, cv.size
      assert_equal 1, cv[0].keys.size
      assert_equal e[1], cv[0][:address], sprintf("[%02d/%02d] value[0] = %s", ci, cx, e[0])

      ce = assert_raises ArgumentError do
        Sisimai::Address.find()
        Sisimai::Address.find("", "", "")
      end
      assert_match /wrong number of arguments/, ce.to_s


      # Sisimai::Address#new
      cv = Sisimai::Address.new(Sisimai::Address.find(e[0]).shift)
      ca = ['', '']
      if cc = e[1].match(/\A(.+)[@]([^@]+)\z/)
        ca[0] = cc[1]
        ca[1] = cc[2]
      end

      if Sisimai::Address.is_mailerdaemon(e[0])
        ca[0] = e[1]
        ca[1] = ''
      end

      assert_instance_of Sisimai::Address, cv
      assert_equal false, cv.void
      assert_equal e[1],  cv.address, sprintf("[%02d/%02d] value[0] = %s", ci, cx, e[1])
      assert_equal ca[0], cv.user,    sprintf("[%02d/%02d] value[0] = %s", ci, cx, e[0])
      assert_equal ca[1], cv.host,    sprintf("[%02d/%02d] value[0] = %s", ci, cx, e[0])
      assert_empty        cv.verp,    sprintf("[%02d/%02d] value[0] = %s", ci, cx, e[0])
      assert_empty        cv.alias,   sprintf("[%02d/%02d] value[0] = %s", ci, cx, e[0])
      assert_equal e[2],  cv.name,    sprintf("[%02d/%02d] value[0] = %s", ci, cx, e[0])
      assert_equal e[3],  cv.comment, sprintf("[%02d/%02d] value[0] = %s", ci, cx, e[0])

      # name and comment are the writable accessors
      cv.name    = 'nekochan'
      cv.comment = 'nyaan'
      assert_equal 'nekochan', cv.name
      assert_equal 'nyaan',    cv.comment

      # Sisimai::Address#s3s4
      cv = Sisimai::Address.s3s4(e[0])
      assert_instance_of ::String, cv
      assert_equal e[1], cv

      # Sisimai::Address#is_emailaddress, is_mailerdaemon
      if e[1] =~ /[@]/
        assert_equal true, Sisimai::Address.is_emailaddress(e[1])
      else
        assert_equal true, Sisimai::Address.is_mailerdaemon(e[1])
      end
      ci += 1
    end

    ManyEmails.each do |e|
      cv = Sisimai::Address.find(e)
      assert_instance_of Array, cv
      assert_equal 2, cv.size

      cv.each do |ee|
        ev = Sisimai::Address.new(ee)
        assert_instance_of Hash, ee
        assert_instance_of Sisimai::Address, ev
        assert_equal false, ev.void
        assert_instance_of ::String, ev.address
        assert_instance_of ::String, ev.comment
        assert_instance_of ::String, ev.name
      end
    end

    ce = assert_raises ArgumentError do
      Sisimai::Address.new()
      Sisimai::Address.new(nil)
      Sisimai::Address.s3s4()
      Sisimai::Address.s3s4(nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  # Sisimai::Address#expand_verp
  def test_expand_verp
    ct = 'nyaan+neko=example.jp@example.org'
    cv = Sisimai::Address.new(address: ct)
    assert_equal false, cv.void
    assert_equal 'neko@example.jp', Sisimai::Address.expand_verp(ct)
    assert_equal ct, cv.verp

    ce = assert_raises ArgumentError do
      Sisimai::Address.expand_verp()
      Sisimai::Address.expand_verp(nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  # Sisimai::Address#expand_alias
  def test_expand_alias
    ct = 'neko+nyaan@example.jp'
    cv = Sisimai::Address.new(address: ct)
    assert_equal false, cv.void
    assert_equal 'neko@example.jp', Sisimai::Address.expand_alias(ct)
    assert_equal ct, cv.alias

    ce = assert_raises ArgumentError do
      Sisimai::Address.expand_alias()
      Sisimai::Address.expand_alias(nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  # Sisimai::Address#to_json
  def test_to_json
    cv = Sisimai::Address.new(address: 'nyaan@libsisimai.org')
    assert_equal false, cv.void
    assert_equal cv.address, cv.to_json
  end

  # Sisimai::Address#is_mailerdaemon
  def test_is_mailerdaemon
    Postmaster.each do |e|
      assert_equal true, Sisimai::Address.is_mailerdaemon(e)
    end

    ce = assert_raises ArgumentError do
      Sisimai::Address.is_mailerdaemon()
      Sisimai::Address.is_mailerdaemon(nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_non_email_addresses
    IsNotEmail.each do |e|
      assert_equal e,     Sisimai::Address.s3s4(e)
      assert_equal false, Sisimai::Address.is_mailerdaemon(e)
      assert_nil          Sisimai::Address.find(e)
    end
  end

  def test_undisclosed
    ct = [
      'undisclosed-sender-in-headers@libsisimai.org.invalid',
      'undisclosed-recipient-in-headers@libsisimai.org.invalid',
    ]
    assert_equal ct[0], Sisimai::Address.undisclosed('s')
    assert_equal ct[1], Sisimai::Address.undisclosed('r')
    assert_nil          Sisimai::Address.undisclosed('')

    ce = assert_raises ArgumentError do
      Sisimai::Address.undisclosed()
      Sisimai::Address.undisclosed(nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

end

