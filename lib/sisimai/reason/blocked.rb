module Sisimai
  module Reason
    # Sisimai::Reason::Blocked checks the bounce reason is "blocked" or not. This class is called
    # only Sisimai::Reason class.
    #
    # This is the error that SMTP connection was rejected due to a client IP address or a hostname,
    # or the parameter of "HELO/EHLO" command. This reason has added in Sisimai 4.0.0.
    module Blocked
      class << self
        Regex = %r{(?>
           [ ]said:[ ]550[ ]blocked
          |[(][^ ]+[@][^ ]+:blocked[)]
          |access[ ]denied[.][ ]ip[ ]name[ ]lookup[ ]failed
          |access[ ]from[ ]ip[ ]address[ ][^ ]+[ ]blocked
          |all[ ]mail[ ]servers[ ]must[ ]have[ ]a[ ]ptr[ ]record[ ]with[ ]a[ ]valid[ ]reverse[ ]dns[ ]entry
          |bad[ ](:?dns[ ]ptr[ ]resource[ ]record|sender[ ]ip[ ]address)
          |banned[ ]sending[ ]ip  # Office365
          |blacklisted[ ]by
          |(?:blocked|refused)[ ]-[ ]see[ ]https?://
          |blocked[ ]using[ ]
          |can[']t[ ]determine[ ]purported[ ]responsible[ ]address
          |cannot[ ](?:
             find[ ]your[ ]hostname
            |resolve[ ]your[ ]address
            )
          |client[ ]host[ ](?:
             [^ ]+[ ]blocked[ ]using
            |rejected:[ ](?:
               abus[ ]detecte[ ]gu_eib_0[24]      # SFR
              |cannot[ ]find[ ]your[ ]hostname    # Yahoo!
              |may[ ]not[ ]be[ ]mail[ ]exchanger
              |was[ ]not[ ]authenticated          # Microsoft
              )
            )
          |confirm[ ]this[ ]mail[ ]server
          |connection[ ](?:
             dropped
            |refused[ ]by
            |reset[ ]by[ ]peer
            |was[ ]dropped[ ]by[ ]remote[ ]host
            )
          |connections[ ](?:
             not[ ]accepted[ ]from[ ]ip[ ]addresses[ ]on[ ]spamhaus[ ]xbl
            |will[ ]not[ ]be[ ]accepted[ ]from[ ][^ ]+,[ ]because[ ]the[ ]ip[ ]is[ ]in[ ]spamhaus's[ ]list
            )
          |currently[ ]sending[ ]spam[ ]see:[ ]
          |domain[ ](?:
             [^ ]+[ ]mismatches[ ]client[ ]ip
            |does[ ]not[ ]exist:
            )
          |dns[ ]lookup[ ]failure:[ ][^ ]+[ ]try[ ]again[ ]later
          |dnsbl:attrbl
          |dynamic/zombied/spam[ ]ips[ ]blocked
          |email[ ]blocked[ ]by[ ](?:[^ ]+[.]barracudacentral[.]org|spamhaus)
          |error:[ ]no[ ]valid[ ]recipients[ ]from[ ]
          |esmtp[ ]not[ ]accepting[ ]connections  # icloud.com
          |fix[ ]reverse[ ]dns[ ]for[ ][^ ]+
          |go[ ]away
          |helo[ ]command[ ]rejected:
          |host[ ]+[^ ]refused[ ]to[ ]talk[ ]to[ ]me:[ ]\d+[ ]blocked
          |host[ ]network[ ]not[ ]allowed
          |hosts[ ]with[ ]dynamic[ ]ip
          |http://(?:
             spf[.]pobox[.]com/why[.]html
            |www[.]spamcop[.]net/bl[.]
            )
          |invalid[ ]ip[ ]for[ ]sending[ ]mail[ ]of[ ]domain
          |ip[ ]\d{1,3}[.]\d{1,3}[.]\d{1,3}[.]\d{1,3}[ ]is[ ]blocked[ ]by[ ]EarthLink # Earthlink
          |ip[/]domain[ ]reputation[ ]problems
          |is[ ](?:
             in[ ]a[ ]black[ ]list(?:[ ]at[ ][^ ]+[.])?
            |in[ ]an[ ][^ ]+rbl[ ]on[ ][^ ]+
            |not[ ]allowed[ ]to[ ]send[ ](?:
               mail[ ]from
              |from[ ][<][^ ]+[>][ ]per[ ]it's[ ]spf[ ]record
              )
            )
          |mail[ ]server[ ]at[ ][^ ]+[ ]is[ ]blocked
          |mail[ ]from[ ]\d+[.]\d+[.]\d+[.]\d[ ]refused:
          |message[ ]from[ ][^ ]+[ ]rejected[ ]based[ ]on[ ]blacklist
          |message[ ]was[ ]rejected[ ]for[ ]possible[ ]spam/virus[ ]content
          |messages[ ]from[ ][^ ]+[ ]temporarily[ ]deferred[ ]due[ ]to[ ]user[ ]complaints   # Yahoo!
          |no[ ](?:
             access[ ]from[ ]mail[ ]server
            |ptr[ ]record[ ]found[.]
            )
          |not[ ]currently[ ]accepting[ ]mail[ ]from[ ]your[ ]ip  # Microsoft
          |part[ ]of[ ]their[ ]network[ ]is[ ]on[ ]our[ ]block[ ]list
          |please[ ](?:
             get[ ]a[ ]custom[ ]reverse[ ]dns[ ]name[ ]from[ ]your[ ]isp[ ]for[ ]your[ ]host
            |inspect[ ]your[ ]spf[ ]settings
            |use[ ]the[ ]smtp[ ]server[ ]of[ ]your[ ]isp
            )
          |ptr[ ]record[ ]setup
          |rejected[ ]because[ ]the[ ]sending[ ]mta[ ]or[ ]the[ ]sender[ ]has[ ]not[ ]passed[ ]validation
          |rejected[ ]due[ ]to[ ](?:
             a[ ]poor[ ]email[ ]reputation[ ]score
            |the[ ]sending[ ]mta's[ ]poor[ ]reputation
            )
          |rejecting[ ]open[ ]proxy   # Sendmail(srvrsmtp.c)
          |reverse[ ]dns[ ](?:
             failed
            |required
            |lookup[ ]for[ ]host[ ][^ ]+[ ]failed[ ]permanently
            )
          |sender[ ]ip[ ](?:
             address[ ]rejected
            |reverse[ ]lookup[ ]rejected
            )
          |server[ ]access[ ](?:
             [^ ]+[ ]forbidden[ ]by[ ]invalid[ ]rdns[ ]record[ ]of[ ]your[ ]mail[ ]server
            |forbidden[ ]by[ ]your[ ]ip[ ]
            )
          |server[ ]ip[ ][^ ]+[ ]listed[ ]as[ ]abusive
          |service[ ]not[ ]available,[ ]closing[ ]transmission[ ]channel
          |service[ ]permits[ ]\d+[ ]unverifyable[ ]sending[ ]ips
          |smtp[ ]error[ ]from[ ]remote[ ]mail[ ]server[ ]after[ ]initial[ ]connection:   # Exim
          |sorry,[ ](?:
             that[ ]domain[ ]isn'?t[ ]in[ ]my[ ]list[ ]of[ ]allowed[ ]rcpthosts
            |your[ ]remotehost[ ]looks[ ]suspiciously[ ]like[ ]spammer
            )
          |spf[ ](?:
             [(]sender[ ]policy[ ]framework[)][ ]domain[ ]authentication[ ]fail
            |record
            |check:[ ]fail
            )
          |spf:[ ][^ ]+[ ]is[ ]not[ ]allowed[ ]to[ ]send[ ]mail[.][ ][a-z0-9]_401
          |temporarily[ ]deferred[ ]due[ ]to[ ]unexpected[ ]volume[ ]or[ ]user[ ]complaints
          |the[ ](?:email|domain|ip)[ ][^ ]+[ ]is[ ]blacklisted
          |this[ ]system[ ]will[ ]not[ ]accept[ ]messages[ ]from[ ]servers[/]devices[ ]with[ ]no[ ]reverse[ ]dns
          |to[ ]submit[ ]messages[ ]to[ ]this[ ]e-mail[ ]system[ ]has[ ]been[ ]rejected
          |too[ ]many[ ](?:
             spams[ ]from[ ]your[ ]ip  # free.fr
            |unwanted[ ]messages[ ]have[ ]been[ ]sent[ ]from[ ]the[ ]following[ ]ip[ ]address[ ]above
            )
          |unresolvable[ ]relay[ ]host[ ]name
          |veuillez[ ]essayer[ ]plus[ ]tard[.][ ]service[ ]refused,[ ]please[ ]try[ ]later[.][ ][0-9a-z_]+(?:103|510)
          |your[ ](?:
             network[ ]is[ ]temporary[ ]blacklisted
            |sender's[ ]ip[ ]address[ ]is[ ]listed[ ]at[ ][^ ]+[.]abuseat[.]org
            |server[ ]requires[ ]confirmation
            )
          |was[ ]blocked[ ]by[ ][^ ]+
          |we[ ]do[ ]not[ ]accept[ ]mail[ ]from[ ](?: # @mail.ru
             dynamic[ ]ips
            |hosts[ ]with[ ]dynamic[ ]ip[ ]or[ ]generic[ ]dns[ ]ptr-records
            )
          |you[ ]are[ ](?:
             not[ ]allowed[ ]to[ ]connect
            |sending[ ]spam
            )
          |your[ ](?:
             email[ ]address[ ]has[ ]been[ ]blacklisted
            |network[ ]is[ ]temporary[ ]blacklisted
            |sender's[ ]ip[ ]address[ ]is[ ]listed[ ]at[ ][^ ]+[.]abuseat[.]org
            |server[ ]requires[ ]confirmation
            )
          )
        }x

        def text; return 'blocked'; end
        def description; return 'Email rejected due to client IP address or a hostname'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          return true if argv1 =~ Regex
          return false
        end

        # Blocked due to client IP address or hostname
        # @param    [Hash] argvs  Hash to be detected the value of reason
        # @return   [true,false]  true: is blocked
        #                         false: is not blocked by the client
        # @see      http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return true if argvs['reason'] == 'blocked'
          return true if Sisimai::SMTP::Status.name(argvs['deliverystatus']).to_s == 'blocked'
          return true if match(argvs['diagnosticcode'].downcase)
          return false
        end

      end
    end
  end
end
