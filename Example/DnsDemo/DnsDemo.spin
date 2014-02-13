CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K         = $800
  BUFFER_16         = $10
  URL_BUFFER        = 128
  
  CR                = $0D
  LF                = $0A
  DOT               = $2E 

  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE

  {{ DNS Packet Enum}}
  TRANSACTION       = $00
  FLAGS             = $02
  QUESTIONS         = $04
  ANSWERS           = $06
  AUTHORITY         = $08
  ADDITIONAL        = $0A
  QUERY             = $0C
  DNS_HEADER_LEN    = QUERY


  ATTEMPTS      = 5
  RESET_PIN     = 4               
       
VAR

DAT
  
  workspace       byte  $0[BUFFER_16]  
  buff            byte  $0[BUFFER_2K]
  msgId           word  $0
  dnsHeader       byte  $01, $00,               { Flags
}                       $00, $01,               { Questions
}                       $00, $00,               { Answer RRS
}                       $00, $00,               { Authority RRS
}                       $00, $00                { Additional RRS }
  
  url1  byte    "www.agaverobotics.com", $0
  url2  byte    "pop.west.cox.net", $0
  url3  byte    "mail.agaverobotics.com", $0
  url4  byte    "finance.google.com" , $0
  url5  byte    "www.weather.gov", $0

  urlBuff byte  $0[URL_BUFFER]

  QTYPE  byte      $00, $01               
  QCLASS byte      $00, $01
               
  rc0   byte    "No error condition." ,$0
  rc1   byte    "Format error", $0
  rc2   byte    "Server failure", $0
  rc3   byte    "Name Error", $0
  rc4   byte    "Not Implemented", $0
  rc5   byte    "Refused", $0
  rc6   byte    "Unknow error", $0
  rcPtr long    @rc0, @rc1, @rc2, @rc3, @rc4, @rc5, @rc6
  rcode byte    $0 
  
  ip1             byte  $00, $00, $00, $00
  ip2             byte  $00, $00, $00, $00
  ip3             byte  $00, $00, $00, $00
  ip4             byte  $00, $00, $00, $00
  ip5             byte  $00, $00, $00, $00
  ip6             byte  $00, $00, $00, $00
  ip7             byte  $00, $00, $00, $00
  ip8             byte  $00, $00, $00, $00
  ip9             byte  $00, $00, $00, $00
  ip10            byte  $00, $00, $00, $00
  ip11            byte  $00, $00, $00, $00
  ip12            byte  $00, $00, $00, $00
  dnsIps          long  @ip1, @ip2, @ip3, @ip4, @ip5, @ip6, @ip7, @ip8, @ip9, @ip10, @ip11, @ip12
  
  buffPtr         long  $00
  transId         long  $00
  null            long  $00

OBJ
  pst           : "Parallax Serial Terminal"
  sock          : "Socket"
  wiz           : "W5500"


 
PUB Init | ptr, url, ansRRS, i

  buffPtr := @buff
  ansRRS := 0
  
  pst.Start(115_200)
  pause(500)

  pst.str(string("Initialize", CR))
  
   'wiz.QS_Init
  wiz.HardReset(WIZ#WIZ_RESET)
  wiz.Start(WIZ#SPI_CS, WIZ#SPI_SCK, WIZ#SPI_MOSI, WIZ#SPI_MISO) 

  'Loop until we get the W5500 version
  'This let us know that the W5500 is ready to go
  repeat until wiz.GetVersion > 0
    pause(250)
    if(i++ > ATTEMPTS*5)
      pst.str(string(CR, "W5500 SPI communication failed!", CR))
      return
  wiz.HardReset(RESET_PIN)
  
  wiz.SetIp(192, 168, 1, 107)
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)
  sock.Init(0, UDP, 53)

  sock.RemoteIp(192,168,1,111)
  sock.RemotePort(53)
  pause(500)

  url := @url5
  
  repeat
    CreateTransactionId($FFFF)
    FillTransactionID
    
    bytemove(@urlBuff, url, strsize(url))
    byte[strsize(url)] := 0
    pst.str(string("URL: "))
    pst.str(@urlBuff)
    pst.char(CR)
    
    'Copy header to the buffer
    bytemove(buffPtr, @msgId, DNS_HEADER_LEN)
    'Format and copy the url
    ptr := ParseUrl(@urlBuff, buffPtr+DNS_HEADER_LEN)
    'Add the QTYPE and QCLASS
    bytemove(ptr, @QTYPE, 4)
    ptr += 4
     
    DisplayMemory(buffPtr, ptr - buffPtr, true)
    ptr := SendReceive(buffPtr, ptr - buffPtr+1)
     
    GetRcode(ptr)
    pst.dec(rcode)
    pst.str(string(": "))
    pst.str(RCodeError)
    pst.char(CR)
     
    if(rcode == 0)
      ansRRS := ParseDnsResponse(ptr) 
     
    repeat i from 0 to ansRRS-1
      ifnot(GetResolvedIp(i) == NULL)
        pst.str(string("ip_"))
        pst.dec(i)
        pst.char($20)
        PrintIP(GetResolvedIp(i))
        pst.char(CR)
    pause(2000)      

PUB ParseUrl(src, dest) | ptr
  ptr := src

  repeat strsize(src)
    if ( byte[ptr++] == DOT )
      byte[ptr-1] := NULL                                'Replace dot with a zero
      byte[dest++] := strsize(src)                       'Insert url segment len
      bytemove(dest, src, strsize(src))                  'Insert url segment
      dest += strsize(src)                               'set pointers
      src := ptr

  byte[dest++] := strsize(src)                           'Insert last url segment
  bytemove(dest, src, strsize(src))
  dest += strsize(src)
  byte[dest++] := NULL
  
  return dest

PUB GetResolvedIp(idx)
  if(IsNullIp( @dnsIps[idx] ) )
    return @null
  return @@dnsIps[idx]

PRI IsNullIp(ipaddr)
  return (byte[ipaddr][0] + byte[ipaddr][1] + byte[ipaddr][2] + byte[ipaddr][3]) == 0
  
PUB GetRcode(src)
  rcode := byte[src+FLAGS+1] & $000F
  return rcode


PUB RCodeError
  case rcode
    0..5  : return @@rcPtr[rcode]
    other : return @rc6

PUB ParseDnsResponse(buffer) | i, len, ansRRS

  i := 0
  
  ' The number of answers to expect
  ansRRS := DeserializeWord(buffer+ANSWERS)

  '--------------------------------------
  'Query Section
  '--------------------------------------
  'Point to the query section which contains 
  'the plain text url to resolve.  Loop until 
  'we reach a zero then jump 4 bytes.
  buffer += QUERY
  repeat until byte[buffer++] == $00
  'Jump past the Type(2) and Class(2)
  buffer += 4

  '-------------------------------------- 
  'Answer Section
  '--------------------------------------
  'The idea is to loop through the answer section
  'and grab the IPs. Nto every answer section will
  'have an IP.  Somethimes they have text only
  repeat ansRRS
    'Encoded name 
    if(byte[buffer] & $C0 == $C0)
      'Check for another encoded name                       
      if(byte[buffer+2] & $C0 == $C0)
        'We have two encoded names to skip                 
        buffer += 2
      'Skip Name(2), Type(2), Class(2), and TTL(4)
      buffer += 10  
    else
      'Increment the pointer until we reach the end of the name
      repeat until byte[buffer++] == $00
     
    len := DeserializeWord(buffer)
    
    'If the length equals 4 we have an IP
    'Otherwise we have text
    if(len == 4)
      buffer += 2 
      bytemove(@@dnsIps[i++], buffer, len)
      buffer += 4
    else
      buffer += (2 + len)
      next  
      
  return i



PUB CreateTransactionId(mask) 
  transId := CNT
  ?transId
  transId &= mask

PUB FillTransactionID
  word[@msgId] := transId

  
PUB SendReceive(buffer, len) | bytesToRead, ptr 
  
  bytesToRead := 0

  pst.str(string("Send Bytes: "))
  pst.dec(len)             
  pst.char(CR)
  
  pst.str(string("Open",CR))
  sock.Open
  
  pst.str(string("Send Message",CR))
  
  sock.Send(buffer, len)
  
  
  'receiving := true
  'repeat while receiving 
    'Data in the buffer?
  bytesToRead := sock.Available
  pst.str(string("Bytes to Read: "))
  pst.dec(bytesToRead)
  pst.char(13)
  pst.char(13)
     
  'Check for a timeout
  if(bytesToRead =< 0 )
    bytesToRead~
    return @null


  if(bytesToRead > 0) 
    'Get the Rx buffer  
    ptr := sock.Receive(buffer, bytesToRead)
    PrintDebug(buffer,bytesToRead)


  pst.str(string(CR, "Disconnect", CR))
  sock.Disconnect
  sock.Close
  return ptr

PUB PrintDebug(buffer,bytesToRead)
  pst.char(CR)
  pst.str(string(CR, "Message from: "))
  PrintIp(buffer)
  pst.char(":")
  pst.dec(DeserializeWord(buffer + 4))
  pst.str(string(" ("))
  pst.dec(DeserializeWord(buffer + 6))
  pst.str(string(")", CR))
   
  DisplayMemory(buffer+8, bytesToRead-8, true)

PUB TxRaw(addr, len) | i
  repeat 5
    pst.char("*")
  repeat i from 0 to len-1
    pst.char(byte[addr][i])
  repeat 5
    pst.char("*")

PUB DisplayMemory(addr, len, isHex) | j
  pst.str(string(13,"-----------------------------------------------------",13))
  pst.str(string(13, "      "))
  repeat j from 0 to $F
    pst.hex(j, 2)
    pst.char($20)
  pst.str(string(13, "      ")) 
  repeat j from 0 to $F
    pst.str(string("-- "))

  pst.char(13) 
  repeat j from 0 to len
    if(j == 0)
      pst.hex(0, 4)
      pst.char($20)
      pst.char($20)
      
    if(isHex)
      pst.hex(byte[addr + j], 2)
    else
      if(byte[addr+j] < $20 OR byte[addr+j] > $7E)
        if(byte[addr+j] == 0)
          pst.char($20)
        else
          pst.hex(byte[addr+j], 2)
      else
        pst.char($20)
        pst.char(byte[addr+j])

    pst.char($20) 
    if((j+1) // $10 == 0) 
      pst.char($0D)
      pst.hex(j+1, 4)
      pst.char($20)
      pst.char($20)  
  pst.char(13)
  
  pst.char(13)
  pst.str(string("Start: "))
  pst.dec(addr)
  pst.str(string(" Len: "))
  pst.dec(len)
  pst.str(string(13,"-----------------------------------------------------",13,13))
  
      
PUB PrintIp(addr) | i
  repeat i from 0 to 3
    pst.dec(byte[addr][i])
    if(i < 3)
      pst.char($2E)
    'else
      'pst.char($0D)
      
PRI SerializeWord(value, buffer)
  byte[buffer++] := (value & $FF00) >> 8
  byte[buffer] := value & $FF

PRI DeserializeWord(buffer) | value
  value := byte[buffer++] << 8
  value += byte[buffer]
  return value
        
PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return