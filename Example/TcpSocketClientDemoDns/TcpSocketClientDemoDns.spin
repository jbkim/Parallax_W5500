CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K     = $800
  
  CR            = $0D
  LF            = $0A
  RESET_PIN     = 4
  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE
   
  
       
VAR

DAT
  request       byte  "GET /index.htm HTTP/1.1", CR, LF, {
}               byte  "User-Agent: Wiz5500", CR, LF, CR, LF, $0

  request2      byte  "GET /default.aspx HTTP/1.1", CR, LF, {
}               byte  "Host: agaverobotics.com", CR, LF, {
}               byte  "User-Agent: Wiz5500", CR, LF, CR, LF, $0

  google        byte  "GET /finance/historical?q=FB&output=csv HTTP/1.1", CR, LF, {
}               byte  "Host: finance.google.com", CR, LF, {
}               byte  "User-Agent: Wiz5500", CR, LF, CR, LF, $0

  buff          byte  $0[BUFFER_2K]
  null          long  $00




OBJ
  pst           : "Parallax Serial Terminal"
  wiz           : "W5500"
  sock          : "Socket"
  dns           : "Dns"

PUB Main | bytesToRead, buffer, bytesSent, receiving, ipaddr, ptr, totalBytes

  receiving := true
  bytesToRead := 0
  pst.Start(115_200)
  pause(500)

  pst.str(string("Initialize W5500", CR))
  
  'wiz.QS_Init
  wiz.HardReset(WIZ#WIZ_RESET)
  wiz.Start(WIZ#SPI_CS, WIZ#SPI_SCK, WIZ#SPI_MOSI, WIZ#SPI_MISO)
  
  'Set network parameters
  wiz.SetCommonnMode(0)
'  wiz.SetGateway(192, 168, 1, 1)
  wiz.SetGateway(192, 168, 1, 111)
  wiz.SetSubnetMask(255, 255, 255, 0)
  wiz.SetIp(192, 168, 1, 105)
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)

  pst.str(string("Resolve domain IP", CR))

  ifnot(dns.Init(@buff, 6))
'    dns.SetDnsServerIp(192, 168, 1, 1)   '68, 105, 28, 12   '192, 168, 1, 1
    dns.SetDnsServerIp(8, 8, 8, 8)   '68, 105, 28, 12   '192, 168, 1, 1
    
  'ptr := dns.ResolveDomain(string("www.agaverobotics.com"))
  ptr := dns.ResolveDomain(string("finance.google.com"))
   
  pst.str(string("Initialize", CR)) 
  buffer := sock.Init(0, TCP, -1)
  sock.RemoteIp(byte[ptr][0], byte[ptr][1], byte[ptr][2], byte[ptr][3])  
  sock.RemotePort(80)

  pst.str(string(CR, "Begin Client Web request", CR))

  'Client
  pst.str(string("Open", CR))
  sock.Open
  pst.str(string("Connect", CR))
  sock.Connect
   
  'Connection?
  repeat until sock.Connected
    pause(100)

  pst.str(string("Send HTTP Header", CR)) 
  'bytesSent := sock.Send(@request2, strsize(@request2))
  bytesSent := sock.Send(@google, strsize(@google))
  pst.str(string("Bytes Sent: "))
  pst.dec(bytesSent)
  pst.char(13)


  repeat while receiving 
    'Data in the buffer?
    bytesToRead := sock.Available
    totalBytes += bytesToRead 
     
    'Check for a timeout
    if(bytesToRead < 0)
      receiving := false
      pst.str(string("Timeout", CR))
      return

    if(bytesToRead == 0)
      receiving := false
      pst.str(string("Done", CR))
      next 

    if(bytesToRead > 0) 
      'Get the Rx buffer  
      buffer := sock.Receive(@buff, bytesToRead)
      pst.str(buffer)
      
    bytesToRead~

  pst.str(string("Total Bytes: "))
  pst.dec(totalBytes)
  pst.char(13)
  
  pst.str(string(CR, "Disconnect", CR)) 
  sock.Disconnect

   
PUB PrintIp(addr) | i
  repeat i from 0 to 3
    pst.dec(byte[addr][i])
    if(i < 3)
      pst.char($2E)
    else
      pst.char($0D)
  
PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return