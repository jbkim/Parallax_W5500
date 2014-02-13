CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K         = $800
  BUFFER_16         = $10
  
  CR                = $0D
  LF                = $0A

  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE

  {{ DNS Packet Enum}}
  TRANSACTION       = $00
  FLAGS             = $02
  QUESTIONS         = $04
  ANSWERS           = $06
  AUTHORITY         = $08
  ADDITIONAL        = $0A
  QUERY             = $0C

  ATTEMPTS      = 5
  RESET_PIN     = 4              
       
VAR

DAT
  
  workspace       byte  $0[BUFFER_16]  
  buff            byte  $0[BUFFER_2K]
                              'reg         B Rcode
  nbNameReg       byte  $68, %0_0101_0000001_0000,       {
}                       $01, $00,                       { 
}                       $00, $01,                       {
}                       $0B, "PropNet5500", $00,         { Question Name
}                       $00, $20, $00, $01,             { PR_NAME
}                       $C0, $08,                       { 
}                       $00, $20, $00, $01,             {
}                       $00, $00, $02, $58,              { TTL = 10 minutes
}                       $00, $06,                       {
}                       %0_00_00000_00000000
 enbNameReg       byte  0
  
  dnsQuery        byte  $68, $C8,               { Transaction Id
}                       $01, $00,               { Flags
}                       $00, $01,               { Questions
}                       $00, $00,               { Answer RRS
}                       $00, $00,               { Authority RRS
}                       $00, $00,               { Additional RRS
}                       $03, "www",             { Query: Length -> www
}                       $06, "google",          {
}                       $03, "com", $00,        { Zero term
}                       $00, $01,               { Host address: Type A
}                       $00, $01                { Class: 01 }
  qend            byte  0

  dnsEmailQuery   byte  $68, $C8,               { Transaction Id
}                       $01, $00,               { Flags
}                       $00, $01,               { Questions
}                       $00, $00,               { Answer RRS
}                       $00, $00,               { Authority RRS
}                       $00, $00,               { Additional RRS
}                       $03, "pop",             { Query: Length -> smtp
}                       $04, "west",            {
}                       $03, "cox",             {
}                       $03, "net", $00,        { Zero term
}                       $00, $01,               { Host address: Type A
}                       $00, $01                { Class: 01 }
  qeend           byte  0

  dnsEmailQuery2   byte $68, $C8,               { Transaction Id
}                       $01, $00,               { Flags
}                       $00, $01,               { Questions
}                       $00, $00,               { Answer RRS
}                       $00, $00,               { Authority RRS
}                       $00, $00,               { Additional RRS
}                       $04, "mail",            { Query: Length -> smtp
}                       $0D, "agaverobotics",   {
}                       $03, "com", $00,        { Zero term
}                       $00, $01,               { Host address: Type A
}                       $00, $01                { Class: 01 }
  qeend2           byte  0

  csvRequest   byte  $68, $C8,                  { Transaction Id
}                       $01, $00,               { Flags
}                       $00, $01,               { Questions
}                       $00, $00,               { Answer RRS
}                       $00, $00,               { Authority RRS
}                       $00, $00,               { Additional RRS
}                       $07, "finance",         { Query: Length -> smtp
}                       $06, "google",          {
}                       $03, "com", $00,        { Zero term
}                       $00, $01,               { Host address: Type A
}                       $00, $01                { Class: 01 }
  csvend           byte  0

  mx               byte  $68, $C8,              { Transaction Id
}                       $01, $00,               { Flags
}                       $00, $01,               { Questions
}                       $00, $00,               { Answer RRS
}                       $00, $00,               { Authority RRS
}                       $00, $00,               { Additional RRS
}                       $03, "cox",             { Query: Length -> smtp
}                       $03, "net", $00,        { Zero term
}                       $00, $01,               { Host address: Type A
}                       $00, $01                { Class: 01 }
  mxend            byte  0

  gov               byte  $68, $C8,              { Transaction Id
}                       $01, $00,               { Flags
}                       $00, $01,               { Questions
}                       $00, $00,               { Answer RRS
}                       $00, $00,               { Authority RRS
}                       $00, $00,               { Additional RRS
}                       $03, "www",             { Query: Length -> 
}                       $07, "weather",          {
}                       $03, "gov", $00,        { Zero term
}                       $00, $01,               { Host address: Type A
}                       $00, $01                { Class: 01 }
  egov            byte  0
                              
                                                             
  dnsResponse     byte  $F0, $90,                         { Transaction Id            
}                       $81, $80,                         { Flags                     
}                       $00, $01,                         { Questions                 
}                       $00, $06,                         { Answer RRS                
}                       $00, $04,                         { Authority RRS             
}                       $00, $04,                         { Additional RRS            
}                       $03, $77, $77, $77,               { Query: Length -> www      
}                       $06, $67, $6F, $6F, $67, $6C, $65,{                           
}                       $03, $63, $6F, $6D, $00,          { Zero term                 
}                       $00, $01,                         { Host address: Type A      
}                       $00, $01,                         { Class: 01                 
}                       $C0, $0C,                         { Answer(1): Label                     
}                       $00, $05,                         { CNAME                     
}                       $00, $01,                         { Class                     
}                       $00, $08, $A7, $C2,               { Time to Live
}                       $00, $08, $03, $77, $77, $77, $01, $6C, $C0, $10, { Data length | Label
}                       $C0, $2C,                         { Label
}                       $00, $01,                         { Type A: Host Address
}                       $00, $01,                         { Class
}                       $00, $00, $00, $EA,               { Time to live
}                       $00, $04, $4A, $7D, $E3, $71,     { Length | IP
}                       $C0, $2C, $00, $01, $00, $01, $00, $00, $00, $EA, $00, $04, $4A, $7D, $E3, $72, { Answer 2
}                       $C0, $2C, $00, $01, $00, $01, $00, $00, $00, $EA, $00, $04, $4A, $7D, $E3, $73, { Answer 3
}                       $C0, $2C, $00, $01, $00, $01, $00, $00, $00, $EA, $00, $04, $4A, $7D, $E3, $74, { Answer 4
}                       $C0, $2C, $00, $01, $00, $01, $00, $00, $00, $EA, $00, $04, $4A, $7D, $E3, $70, { Answer 5
}                       $C0, $30, $00, $02, $00, $01, $00, $01, $3F, $18, $00, $06, $03, $6E, $73, $34, { Answer 6
}                       $C0, $10, $C0, $30, $00, $02, $00, $01, $00, $01, $3F, $18, $00, $06, $03, $6E, $73, $33, {
}                       $C0, $10, $C0, $30, $00, $02, $00, $01, $00, $01, $3F, $18, $00, $06, $03, $6E, $73, $32, {
}                       $C0, $10, $C0, $30, $00, $02, $00, $01, $00, $01, $3F, $18, $00, $06, $03, $6E, $73, $31, {
}                       $C0, $10, $C0, $C6, $00, $01, $00, $01, $00, $04, $B3, $6C, $00, $04, $D8, $EF, $20, $0A, {
}                       $C0, $B4, $00, $01, $00, $01, $00, $04, $B4, $CE, $00, $04, $D8, $EF, $22, $0A, {
}                       $C0, $A2, $00, $01, $00, $01, $00, $04, $B3, $BE, $00, $04, $D8, $EF, $24, $0A, {
}                       $C0, $90, $00, $01, $00, $01, $00, $04, $B3, $7A, $00, $04, $D8, $EF, $26, $0A
  rend            byte  0  


  ip1             byte  $00, $00, $00, $00
  ip2             byte  $00, $00, $00, $00
  ip3             byte  $00, $00, $00, $00
  ip4             byte  $00, $00, $00, $00
  ip5             byte  $00, $00, $00, $00
  dnsIps          long  @ip1, @ip2, @ip3, @ip4, @ip5
  
  buffPtr         long  $00
  transId         long  $00
  null            long  $00

OBJ
  pst           : "Parallax Serial Terminal"
  sock          : "Socket"
  wiz           : "W5500"


 
PUB Init | ptr, i, ansRRS
  'return
  buffPtr := @buff

  pst.Start(115_200)
  pause(500)

  'GetIP(@dnsResponse)
  'return

  pst.str(string("Initialize", CR))
  CreateTransactionId($FFFF)
  FillTransactionID
  
  'DNS Port, Mac and Ip 
  wiz.Start(3, 0, 1, 2) 
  wiz.SetIp(192, 168, 1, 104)
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)
  sock.Init(0, UDP, 53)

  'DNS server IP and port
  sock.RemoteIp(192,168,1,111)
  sock.RemotePort(53)


  'DisplayMemory(@dnsQuery, 32, true) 
  'ptr := SendReceive(@dnsQuery, @qend - @dnsQuery   )
  
  'DisplayMemory(@csvRequest, 32, true) 
  'ptr := SendReceive(@csvRequest, @csvend - @csvRequest   )

  'DisplayMemory(@dnsEmailQuery2, 32, true) 
  'ptr := SendReceive(@dnsEmailQuery2, @qeend2 - @dnsEmailQuery2   )

  DisplayMemory(@gov, @egov - @gov, true) 
  ptr := SendReceive(@gov, @egov - @gov+1  )                                

  ansRRS := ParseDnsResponse(ptr)
  
  repeat i from 0 to ansRRS-1
    ifnot(GetResolvedIp(i) == NULL)
      pst.str(string("ip_"))
      pst.dec(i)
      pst.char($20)
      PrintIP(GetResolvedIp(i))
      pst.char(CR)
      
  sock.Close


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

  return i
  
PUB GetResolvedIp(idx)
  if(IsNullIp( @dnsIps[idx] ) )
    return @null
  return @@dnsIps[idx]

PRI IsNullIp(ipaddr)
  return (byte[ipaddr][0] + byte[ipaddr][1] + byte[ipaddr][2] + byte[ipaddr][3]) == 0
    
PUB CreateTransactionId(mask)
  transId := CNT
  ?transId
  transId &= mask

PUB FillTransactionID
  word[@dnsQuery] := transId
    
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
      pst.char($20)
      if(byte[addr+j] == 0)
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