'*********************************************************************************************
{
AUTHOR: Mike Gebhard
COPYRIGHT: Parallax Inc.
LAST MODIFIED: 10/30/2012
VERSION 1.0
LICENSE: MIT (see end of file)

DESCRIPTION:
The DNS object

}
'*********************************************************************************************
 
CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K         = $800
  BUFFER_16         = $10
  URL_BUFFER        = $80
  
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

  DNS_PORT          = 53               
       
VAR

DAT
  msgId           word  $0
  dnsHeader       byte  $01, $00,               { Flags
}                       $00, $01,               { Questions
}                       $00, $00,               { Answer RRS
}                       $00, $00,               { Authority RRS
}                       $00, $00                { Additional RRS }

  qtype           byte  $00, $01                { Host address: Type A }
  qclass          byte  $00, $01                { Class: 01 }

  urlBuff         byte  $0[URL_BUFFER]              
  rc0             byte  "No error condition." ,$0
  rc1             byte  "Format error", $0
  rc2             byte  "Server failure", $0
  rc3             byte  "Name Error", $0
  rc4             byte  "Not Implemented", $0
  rc5             byte  "Refused", $0
  rc6             byte  "Unknow error", $0
  rc7             byte  "DNS IP is empty", 0
  rcPtr           long  @rc0, @rc1, @rc2, @rc3, @rc4, @rc5, @rc6, @rc7
  rcode           byte  $0

  dnsServerIp     byte  $00, $00, $00, $00      '68, 105, 28, 12

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
  dnsCnt          byte  $00
  dnsIps          long  @ip1, @ip2, @ip3, @ip4, @ip5, @ip6, @ip7, @ip8, @ip9, @ip10, @ip11, @ip12

  buffPtr         long  $00
  transId         long  $00
  null            long  $00

OBJ
  sock          : "Socket"
  wiz           : "W5500"
 
PUB Init(buffer, socket) | dnsPtr
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  buffPtr := buffer

  'DNS Port, Mac and Ip 
  sock.Init(socket, UDP, DNS_PORT)

  'Get the default DNS from DHCP
  'dnsPtr := wiz.GetRouter
  dnsPtr := wiz.GetDns

  'Note: The DNS IP could be null if DHCP is not used
  'or DNS is not manully set. 
  if(dnsPtr > NULL) 
    sock.RemoteIp(byte[dnsPtr][0], byte[dnsPtr][1], byte[dnsPtr][2], byte[dnsPtr][3])
    sock.RemotePort(DNS_PORT)
    return true
  else
    rcode := 7
    return false
    
'Use this if you need to manually set DNS
PUB SetDnsServerIp(octet3, octet2, octet1, octet0)
  dnsServerIp[0] := octet3
  dnsServerIp[1] := octet2
  dnsServerIp[2] := octet1
  dnsServerIp[3] := octet0
  wiz.CopyDns(@dnsServerIp, 4)
  sock.RemoteIp(octet3 , octet2, octet1, octet0)
  sock.RemotePort(53)

PUB GetIpCount
  return dnsCnt
  
PUB GetResolvedIp(idx)

  if(idx > dnsCnt-1)
    return @null
    
  if(IsNullIp( @dnsIps[idx] ) )
    return @null
    
  return @@dnsIps[idx]

PRI IsNullIp(ipaddr)
  return (byte[ipaddr][0] + byte[ipaddr][1] + byte[ipaddr][2] + byte[ipaddr][3]) == 0 
    
PUB ResolveDomain(url) | ptr, dnsPtr

  bytefill(@ip1, 0, @dnsIps-@ip1)

  bytemove(@urlBuff, url, strsize(url))
  byte[strsize(url)] := 0
  
  {   }  
  dnsPtr := wiz.GetDns
  sock.RemoteIp(byte[dnsPtr][0], byte[dnsPtr][1], byte[dnsPtr][2], byte[dnsPtr][3])
  sock.RemotePort(DNS_PORT)
  
     
  CreateTransactionId($FFFF)
  FillTransactionID
  
  'Copy header to the buffer
  bytemove(buffPtr, @msgId, DNS_HEADER_LEN)
  
  'Format and copy the url
  ptr := ParseUrl(@urlBuff, buffPtr+DNS_HEADER_LEN)
  
  'Add the QTYPE and QCLASS
  bytemove(ptr, @QTYPE, 4)
  ptr += 4

  ptr := SendReceive(buffPtr, ptr - buffPtr)

  if(ptr == @null)
  
  ParseDnsResponse(ptr)
  return  GetResolvedIp(0)
  
  'return  ptr


PRI ParseUrl(src, dest) | ptr
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


PUB GetRcode(src)

  CreateTransactionId($FFFF)
  FillTransactionID
  
  rcode := byte[src+FLAGS+1] & $000F
  return rcode


PUB RCodeError
  case rcode
    0..7  : return @@rcPtr[rcode]
    other : return @rc6

PRI ParseDnsResponse(buffer) | i, len, ansRRS

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
       
  dnsCnt := i    


PUB CreateTransactionId(mask) 
  transId := CNT
  ?transId
  transId &= mask

PUB FillTransactionID
  word[@msgId] := transId


PRI DeserializeWord(buffer) | value
  value := byte[buffer++] << 8
  value += byte[buffer]
  return value

PUB SendReceive(buffer, len) | bytesToRead, ptr 
  
  bytesToRead := 0

  'Open socket and Send Message 
  sock.Open
  sock.Send(buffer, len)

  bytesToRead := sock.Available
   
  'Check for a timeout
  if(bytesToRead =< 0 )
    bytesToRead~
    return @null

  if(bytesToRead > 0) 
    'Get the Rx buffer  
    ptr := sock.Receive(buffer, bytesToRead)

  sock.Disconnect
  return ptr
  
CON
{{
 ______________________________________________________________________________________________________________________________
|                                                   TERMS OF USE: MIT License                                                  |                                                            
|______________________________________________________________________________________________________________________________|
|Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    |     
|files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    |
|modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software|
|is furnished to do so, subject to the following conditions:                                                                   |
|                                                                                                                              |
|The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.|
|                                                                                                                              |
|THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          |
|WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         |
|COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   |
|ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         |
 ------------------------------------------------------------------------------------------------------------------------------ 
}}