require 'minitest/autorun'
require 'sisimai/message'

class MessageTest < Minitest::Test
  Methods = { class:  %w[rise load parse divideup makemap] }
  Mailbox = './set-of-emails/mailbox/mbox-0'
  Fhandle = File.open(Mailbox, 'r')
  Mailtxt = Fhandle.read; Fhandle.close
  Lambda1 = lambda do |argv|
    data = { 'x-mailer' => '', 'return-path' => '' }
    if cv = argv['message'].match(/^X-Mailer:\s*(.+)$/)
      data['x-mailer'] = cv[1]
    end

    if cv = argv['message'].match(/^Return-Path:\s*(.+)$/)
      data['return-path'] = cv[1]
    end
    data['from'] = argv['headers']['from'] || ''
    return data
  end

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::Message, e }
  end

  def test_rise
    assert_instance_of String, Mailtxt
    refute_empty Mailtxt

    ca = { data: Mailtxt }
    cv = Sisimai::Message.rise(**ca)
    assert_instance_of Hash,   cv
    assert_instance_of Hash,   cv['header']
    assert_instance_of Array,  cv['ds']
    assert_instance_of Hash,   cv['rfc822']
    assert_instance_of String, cv['from']

    ca = {
      data: Mailtxt,
      hook: Lambda1,
      order:[
        'Sisimai::Lhost::Sendmail', 'Sisimai::Lhost::Postfix', 'Sisimai::Lhost::qmail',
        'Sisimai::Lhost::Exchange2003', 'Sisimai::Lhost::Gmail', 'Sisimai::Lhost::Verizon',
      ]
    }
    cv = Sisimai::Message.rise(**ca)
    assert_instance_of Hash,  cv
    assert_instance_of Array, cv['ds']
    assert_instance_of Array, cv['header']['received']
    assert_instance_of Hash,  cv['catch']

    cv['ds'].each do |e|
      assert_equal 'SMTP',    e['spec']
      assert_match /[@]/,     e['recipient']
      assert_equal true,      e.has_key?('command')
      assert_match /\d{4}/,   e['date']
      refute_empty            e['diagnosis']
      refute_empty            e['action']
      assert_match /.+[.].+/, e['rhost']
      assert_match /.+[.].+/, e['lhost']
      assert_equal 'Sendmail',e['agent']
    end

    %w[content-type to subject date from message-id].each { |e| refute_empty cv['header'][e] }
    %w[return-path to subject date from message-id].each  { |e| refute_empty cv['rfc822'][e] }

    refute_empty cv['catch']['x-mailer']
    refute_empty cv['catch']['return-path']
    refute_empty cv['catch']['from']

    ce = assert_raises ArgumentError do
      Sisimai::Message.rise(nil)
      Sisimai::Message.rise(nil, nil)
    end

    ce = assert_raises NoMethodError do
      Sisimai::Message.rise()
    end
  end

  def test_load
    assert_instance_of Array, Sisimai::Message.load({})
    ce = assert_raises ArgumentError do
      Sisimai::Message.load()
      Sisimai::Message.load(nil, nil)
    end

  end
end

