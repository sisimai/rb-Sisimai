require 'minitest/autorun'
require 'sisimai/rfc2045'

class RFC2045Test < Minitest::Test
  Methods = { class: %w[is_encoded decodeH parameter boundary decodeQ decodeB levelout makeflat] }

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::RFC2045, e }
  end

  Pt1 = 'ASCII TEXT'
  Pt2 = '白猫にゃんこ'
  Pt3 = 'ニュースレター'
  Be2 = '=?utf-8?B?55m954yr44Gr44KD44KT44GT?='
  Qe3 = '=?utf-8?Q?=E3=83=8B=E3=83=A5=E3=83=BC=E3=82=B9=E3=83=AC=E3=82=BF=E3=83=BC?='
  Pt4 = '何でも薄暗いじめじめした所でニャーニャー泣いていた事だけは記憶している。'
  Be4 = [
    '=?utf-8?B?5L2V44Gn44KC6JaE5pqX44GE44GY44KB44GY44KB44GX44Gf5omA?=',
    '=?utf-8?B?44Gn44OL44Oj44O844OL44Oj44O85rOj44GE44Gm44GE44Gf5LqL?=',
    '=?utf-8?B?44Gg44GR44Gv6KiY5oa244GX44Gm44GE44KL44CC?=',
  ]
  Be5 = [
    '=?SHIFT_JIS?B?ib2CxYLglJaIw4KigraC34K2gt+CtYK9j4qCxYNqg4OBW4Nqg4OBWw==?=',
    '=?SHIFT_JIS?B?i4OCooLEgqKCvY6Wgr6Cr4LNi0yJr4K1gsSCooLpgUI=?=',
  ]
  Be6 = [
    '=?ISO-2022-JP?B?GyRCMj8kRyRiR3YwRSQkJDgkYSQ4JGEkNyQ/PWokRyVLJWMhPCVLGyhC?=',
    '=?ISO-2022-JP?B?GyRCJWMhPDVjJCQkRiQkJD87diRAJDEkTzUtMjEkNyRGJCQkaxsoQg==?=',
    '=?ISO-2022-JP?B?GyRCISMbKEI=?=',
  ]

  def test_is_encoded
    assert_equal false, Sisimai::RFC2045.is_encoded(Pt1)
    assert_equal false, Sisimai::RFC2045.is_encoded(Pt2)
    assert_equal true,  Sisimai::RFC2045.is_encoded(Be2)
    assert_equal true,  Sisimai::RFC2045.is_encoded(Qe3)

    ce = assert_raises ArgumentError do
      Sisimai::RFC2045.is_encoded()
      Sisimai::RFC2045.is_encoded("", "")
    end
    assert_match /wrong number of arguments/, ce.to_s
    assert_nil   Sisimai::RFC2045.is_encoded(nil)
  end

  IR1 = [
    '[NEKO] =?UTF-8?B?44OL44Oj44O844Oz?=',
    '=?UTF-8?B?44OL44Oj44O844Oz?= [NYAAN]',
    '[NEKO] =?UTF-8?B?44OL44Oj44O844Oz?= [NYAAN]'
  ]
  def test_decodeH
    # decocdeH returns the original string when it is not encoded text
    assert_equal Pt1, Sisimai::RFC2045.decodeH([Pt1])
    assert_equal Pt2, Sisimai::RFC2045.decodeH([Pt2])
    assert_equal Pt2, Sisimai::RFC2045.decodeH([Be2])
    assert_equal Pt3, Sisimai::RFC2045.decodeH([Qe3])
    assert_equal Pt4, Sisimai::RFC2045.decodeH(Be4)
    assert_equal Pt4, Sisimai::RFC2045.decodeH(Be5)
    assert_equal Pt4, Sisimai::RFC2045.decodeH(Be6)

    IR1.each do |e|
      cv = Sisimai::RFC2045.decodeH([e])
      assert_equal true, Sisimai::RFC2045.is_encoded(e)
      refute_empty cv
      assert_match /ニャーン/, cv
    end
    ce = assert_raises ArgumentError do
      Sisimai::RFC2045.decodeH()
      Sisimai::RFC2045.decodeH("", "")
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  Be7 = '44Gr44KD44O844KT'
  Pt7 = 'にゃーん'
  def test_decodeB
    # decocdeB returns the original string when it is not encoded text
    assert_nil    Sisimai::RFC2045.decodeB(nil)
    assert_nil    Sisimai::RFC2045.decodeB(Pt7)
    assert_equal  Pt7, Sisimai::RFC2045.decodeB(Be7)

    ce = assert_raises ArgumentError do
      Sisimai::RFC2045.decodeB()
      Sisimai::RFC2045.decodeB("", "")
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  Qe4 = '=4e=65=6b=6f'
  Qe5 = 'I will be traveling for work on July 10-31.  During that time I will have i=
ntermittent access to email and phone, and I will respond to your message a=
s promptly as possible.
Please contact our Client Service Support Team (information below) if you n=
eed immediate assistance on regular account matters, or contact my colleagu=
e Neko Nyaan (neko@example.org; +0-000-000-0000) for all other needs.
'
  def test_decodeQ
    # Part of Quoted-Printable
    assert_nil            Sisimai::RFC2045.decodeQ(nil)
    assert_equal 'Neko',  Sisimai::RFC2045.decodeQ(Qe4)
    assert_equal 'neko',  Sisimai::RFC2045.decodeQ('neko')

    cv = Sisimai::RFC2045.decodeQ(Qe5)
    assert_equal true,  Qe5.size > cv.size
    refute_match /a=$/, cv
    refute_match /[=]/, cv

    ce = assert_raises ArgumentError do
      Sisimai::RFC2045.decodeQ()
      Sisimai::RFC2045.decodeQ("", "")
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  Ct1 = 'multipart/MIXED; boundary="nekochan"; charset=utf-8'
  Ct2 = 'QUOTED-PRINTABLE'
  def test_parameter
    assert_equal 'multipart/mixed', Sisimai::RFC2045.parameter(Ct1)
    assert_equal 'nekochan',        Sisimai::RFC2045.parameter(Ct1, 'boundary')
    assert_equal 'utf-8',           Sisimai::RFC2045.parameter(Ct1, 'charset')
    assert_empty                    Sisimai::RFC2045.parameter(Ct1, 'nyaan')

    assert_equal 'quoted-printable',Sisimai::RFC2045.parameter(Ct2)
    assert_empty                    Sisimai::RFC2045.parameter(Ct2, 'neko')

    ce = assert_raises ArgumentError do
      Sisimai::RFC2045.parameter()
      Sisimai::RFC2045.parameter("", "", "")
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  Ct3 = 'Content-Type: multipart/mixed; boundary=Apple-Mail-1-526612466'
  Ct4 = 'Apple-Mail-1-526612466'
  def test_boundary
    assert_equal Ct4,               Sisimai::RFC2045.boundary(Ct3)
    assert_equal '--' + Ct4,        Sisimai::RFC2045.boundary(Ct3, 0)
    assert_equal '--' + Ct4 + '--', Sisimai::RFC2045.boundary(Ct3, 1)
    assert_equal '--' + Ct4 + '--', Sisimai::RFC2045.boundary(Ct3, 2)

    ce = assert_raises ArgumentError do
      Sisimai::RFC2045.boundary()
      Sisimai::RFC2045.boundary("", "", "")
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  MP3 = 'Content-Description: "error-message"
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable

This is the mail delivery agent at messagelabs.com.

I was unable to deliver your message to the following addresses:

maria@dest.example.net

Reason: 550 maria@dest.example.net... No such user'
  def test_haircut
    cv = Sisimai::RFC2045.haircut(MP3)
    assert_instance_of Array, cv
    assert_equal 3, cv.size
    assert_equal 'text/plain; charset="utf-8"', cv[0]
    assert_equal 'quoted-printable',            cv[1]
    refute_empty cv[2]

    cv = Sisimai::RFC2045.haircut(MP3, true)
    assert_instance_of Array, cv
    assert_equal       2,     cv.size
    assert_equal 'text/plain; charset="utf-8"', cv[0]
    assert_equal 'quoted-printable',            cv[1]

    ce = assert_raises ArgumentError do
      Sisimai::RFC2045.haircut()
      Sisimai::RFC2045.haircut("", "", "")
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  Ct5 = 'multipart/mixed; boundary="b0Nvs+XKfKLLRaP/Qo8jZhQPoiqeWi3KWPXMgw=="'
  MP5 = '
--b0Nvs+XKfKLLRaP/Qo8jZhQPoiqeWi3KWPXMgw==
Content-Description: "error-message"
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable

This is the mail delivery agent at messagelabs.com.

I was unable to deliver your message to the following addresses:

maria@dest.example.net

Reason: 550 maria@dest.example.net... No such user

The message subject was: Re: BOAS FESTAS!
The message date was: Tue, 23 Dec 2014 20:39:24 +0000
The message identifier was: DB/3F-17375-60D39495
The message reference was: server-5.tower-143.messagelabs.com!1419367172!32=
691968!1

Please do not reply to this email as it is sent from an unattended mailbox.
Please visit www.messagelabs.com/support for more details
about this error message and instructions to resolve this issue.


--b0Nvs+XKfKLLRaP/Qo8jZhQPoiqeWi3KWPXMgw==
Content-Type: message/delivery-status

Reporting-MTA: dns; server-15.bemta-3.messagelabs.com
Arrival-Date: Tue, 23 Dec 2014 20:39:34 +0000

'
  def test_levelout
    cv = Sisimai::RFC2045.levelout(Ct5, MP5)
    assert_instance_of Array, cv
    assert_equal           2, cv.size

    cv.each do |e|
      assert_instance_of Array, e
      refute_empty e[0]
      refute_empty e[2]
    end

    ce = assert_raises ArgumentError do
      Sisimai::RFC2045.levelout()
      Sisimai::RFC2045.levelout("", "", "")
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  Ct6 = {'content-type' => 'multipart/report; report-type=delivery-status; boundary="NekoNyaan--------1"'}
  MP6 = '--NekoNyaan--------1
Content-Type: multipart/related; boundary="NekoNyaan--------2"

--NekoNyaan--------2
Content-Type: multipart/alternative; boundary="NekoNyaan--------3"

--NekoNyaan--------3
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: base64

c2lyb25la28K

--NekoNyaan--------3
Content-Type: text/html; charset="UTF-8"
Content-Transfer-Encoding: base64

PGh0bWw+CjxoZWFkPgogICAgPHRpdGxlPk5la28gTnlhYW48L3RpdGxlPgo8L2hl
YWQ+Cjxib2R5PgogICAgPGgxPk5la28gTnlhYW48L2gxPgo8L2JvZHk+CjwvaHRt
bD4K

--NekoNyaan--------2
Content-Type: image/jpg

/9j/4AAQSkZJRgABAQEBLAEsAAD/7VaWUGhvdG9zaG9wIDMuMAA4QklNBAwAAAAA
Vk4AAAABAAAArwAAAQAAAAIQAAIQAAAAVjIAGAAB/9j/7gAOQWRvYmUAZAAAAAAB
/9sAhAAGBAQEBQQGBQUGCQYFBgkLCAYGCAsMCgoLCgoMEAwMDAwMDBAMDAwMDAwM
DAwMDAwMDAwMDAwMDAwMDAwMDAwMAQcHBw0MDRgQEBgUDg4OFBQODg4OFBEMDAwM
DBERDAwMDAwMEQwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAz/wAARCAEAAK8D
AREAAhEBAxEB/90ABAAW/8QBogAAAAcBAQEBAQAAAAAAAAAABAUDAgYBAAcICQoL

--NekoNyaan--------2
Content-Type: message/delivery-status

Reporting-MTA: dns; example.jp
Received-From-MTA: dns; neko.example.jp
Arrival-Date: Thu, 11 Oct 2018 23:34:45 +0900 (JST)

Final-Recipient: rfc822; kijitora@example.jp
Action: failed
Status: 5.1.1
Diagnostic-Code: User Unknown

--NekoNyaan--------2
Content-Type: message/rfc822

Received: ...

--NekoNyaan--------2--
'
  def test_makeflat
    cv = Sisimai::RFC2045.makeflat(Ct6['content-type'], MP6)
    refute_empty cv
    assert_equal true, cv.size < MP6.size

    assert_match /sironeko/,    cv
    assert_match /kijitora[@]/, cv
    assert_match /Received:/,   cv
    refute_match /[<]html[>]/,  cv
    refute_match /4AAQSkZJRgABAQEBLAEsAAD/, cv
    assert_empty  Sisimai::RFC2045.makeflat()

    ce = assert_raises ArgumentError do
      Sisimai::RFC2045.makeflat()
      Sisimai::RFC2045.makeflat("", "", "")
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

end

