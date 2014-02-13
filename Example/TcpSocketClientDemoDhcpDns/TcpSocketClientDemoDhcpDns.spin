CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  { Protocol }
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE
  
  { PST Display }
  CR            = $0D
  LF            = $0A
  
  BUFFER_2K     = $800

  ATTEMPTS      = 5
 
  { Serial IO PINs } 
  USB_Rx        = 31
  USB_Tx        = 30
  
  { Run time DHCP and DNS socket paramters }
  DHCP_SOCKET   = 7
  DNS_SOCKET    = 6

  {{ Dev Board PIN IO }}
  {
  SPI_MISO          = 2 ' SPI master in serial out from slave 
  SPI_MOSI          = 1 ' SPI master out serial in to slave
  SPI_CS            = 3 ' SPI chip select (active low)
  SPI_SCK           = 0  ' SPI clock from master to all slaves
  WIZ_INT           = 13
  WIZ_RESET         = 4
  WIZ_SPI_MODE      = 15
  }
  {{ WizNet W5500 for QuickStart PIN IO }} 
  SPI_SCK           = 12 ' SPI clock from master to all slaves
  SPI_MISO          = 13 ' SPI master in serial out from slave
  SPI_MOSI          = 14 ' SPI master out serial in to slave
  SPI_CS            = 15 ' SPI chip select (active low)
  WIZ_POWER_DOWN    = 24 ' Power down (active high)       
  WIZ_INT           = 25 ' Interupt (active low)
'  WIZ_RESET         = 26 ' Reset (active low)
  WIZ_RESET         = 6 ' Reset (active low)

      
 
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

  s_google      byte  "GET / HTTP/1.1", CR, LF, {
}               byte  "Host: google.com", CR, LF, {
}               byte  "User-Agent: Wiz5500", CR, LF, CR, LF, $0

  weather       byte  "GET / HTTP/1.1", CR, LF, {
}               byte  "Host: www.weather.gov", CR, LF, {
}               byte  "User-Agent: Wiz5500", CR, LF, CR, LF, $0

  basicAuthReq  byte  "GET /spinneret/formtest.php HTTP/1.1", CR, LF, {
}               byte  "Host: rcc.cfbtechnologies.com", CR, LF, {
}               byte  "User-Agent: Wiz5500", CR, LF, {
}               byte  "Authorization: Basic dGVzdDojYnhGeFgheWxTR3A=", CR, LF, CR, LF, $0

  basicAuthPost byte  "POST /spinneret/formtest.php HTTP/1.1", CR, LF, {
}               byte  "Host: rcc.cfbtechnologies.com", CR, LF, {
}               byte  "User-Agent: Wiz5500", CR, LF, {
}               byte  "Content-Type: application/x-www-form-urlencoded", CR, LF, {
}               byte  "Content-Length: 27", CR, LF, {
}               byte  "Authorization: Basic dGVzdDojYnhGeFgheWxTR3A=", CR, LF, CR, LF, {
}               byte  "name=This is a test message", CR, LF, $0

  buff          byte  $0[BUFFER_2K]

  t1            long  $0
  null          long  $00
  site          byte  "finance.google.com", $0

OBJ
  pst           : "Parallax Serial Terminal"
  wiz           : "W5500"
  sock          : "Socket"
  dhcp          : "Dhcp"
  dns           : "Dns"
   

PUB Main | bytesToRead, buffer, bytesSent, receiving, remoteIP, dnsServer, totalBytes, i, dnsInit

  'wiz.HardReset(WIZ_RESET)
  receiving := true
  bytesToRead := 0

  dnsInit := 0

  if(ina[USB_Rx] == 0)      '' Check to see if USB port is powered
    outa[USB_Tx] := 0       '' Force Propeller Tx line LOW if USB not connected
  else                      '' Initialize normal serial communication to the PC here                              
    pst.Start(115_200)      '' http://forums.parallax.com/showthread.php?135067-Serial-Quirk&p=1043169&viewfull=1#post1043169
    pause(500)

  pst.str(string("Initialize W5500", CR)) 

  wiz.QS_Init
  
  'wiz.Start(SPI_CS, SPI_SCK, SPI_MOSI, SPI_MISO)


  'Loop until we get the W5500 version
  'This lets us know if the W5500 is ready to go 
  i := 0
  repeat until wiz.GetVersion > 0
    pause(250)
    if(i++ > ATTEMPTS*5)
      pst.str(string(CR, "SPI communication failed!", CR))
      return   
  pst.str(string("WizNet 5500 Ver: ") )
  pst.dec(wiz.GetVersion)
  pst.char(CR)

  wiz.SetMac($00, $08, $DC, $16, $F8, $01)

  pst.str(string("Getting network paramters", CR))
  dhcp.Init(@buff, DHCP_SOCKET)

  pst.str(string("--------------------------------------------------", CR))

  'SetRequestIp allows us to request a specific IP - No guarentee 
  'dhcp.SetRequestIp(192, 168, 1, 110)                    
 
  pst.str(string("Requesting IP....."))      
  repeat until dhcp.DoDhcp(true)
    if(++t1 > ATTEMPTS)
      quit
   
  if(t1 > ATTEMPTS)
    pst.char(CR) 
    pst.str(string(CR, "DHCP Attempts: "))
    pst.dec(t1)
    pst.str(string(CR, "Error Code: "))
    pst.dec(dhcp.GetErrorCode)
    pst.char(CR)
    pst.str(dhcp.GetErrorMessage)
    pst.char(CR)
    return
  else
    PrintIp(dhcp.GetIp)

  { Stress test      
  repeat
    pst.str(string("Requesting IP....."))
    t1 := 0
    'wiz.SetIp(0,0,0,0)
    repeat until dhcp.RenewDhcp
      if(++t1 > ATTEMPTS)
        quit
    if(t1 > ATTEMPTS)
      pst.char(CR) 
      pst.str(string(CR, "DHCP Attempts: "))
      pst.dec(t1)
      pst.str(string(CR, "Error Code: "))
      pst.dec(dhcp.GetErrorCode)
      pst.char(CR)
      pst.str(dhcp.GetErrorMessage)
      pst.char(CR)
      return
    else
      PrintIp(dhcp.GetIp)
    'pause(2000)
   }
  
  pst.str(string("Lease Time........"))
  pst.dec(dhcp.GetLeaseTime)
  pst.char(CR)
 
  pst.str(string("DNS..............."))
  dnsServer := wiz.GetDns
  PrintIp(wiz.GetDns)

  pst.str(string("DHCP Server......."))
  printIp(dhcp.GetDhcpServer)

  pst.str(string("Router............"))
  printIp(dhcp.GetRouter)

  pst.str(string("Gateway..........."))                                        
  printIp(wiz.GetGatewayIp)
  
  pst.char(CR) 

  pst.str(string("DNS Init (bool)..."))
  if(dns.Init(@buff, DNS_SOCKET))
    pst.str(string("True"))
  else
    pst.str(string("False"))
  pst.char(CR)

  pst.str(string("Resolved IP(0)....")) 
  'remoteIP := dns.ResolveDomain(string("www.agaverobotics.com"))
  'remoteIP := dns.ResolveDomain(string("finance.google.com"))
  'remoteIP := dns.ResolveDomain(string("google.com"))
  'remoteIP := dns.ResolveDomain(string("www.weather.gov"))
  remoteIP := dns.ResolveDomain(string("rcc.cfbtechnologies.com"))
   
  PrintIp(remoteIP)
   
  pst.str(string("Resolved IPs......"))
  pst.dec(dns.GetIpCount)
  pst.char(13)
  pst.char(13)
 
   'remoteIP := dns.GetResolvedIp(1) 

  pst.str(string("Initialize Socket"))
  sock.Init(0, TCP, 8080)
  sock.RemoteIp(byte[remoteIP][0], byte[remoteIP][1], byte[remoteIP][2], byte[remoteIP][3])  
  sock.RemotePort(80)

  'PrintIp(wiz.GetRemoteIP(0))

{{*****************************************************************   }}    
  pst.str(string(CR, "Begin GET Client Web Request", CR))
'repeat
  sock.Open
  pause(100)
  sock.Connect

  pst.str(string(CR, "Connecting to.....")) 
  PrintIp(wiz.GetRemoteIP(0))
  pst.char(CR) 
   
  'Connection?
  repeat until sock.Connected
    pause(100)

  pst.str(string("Sending HTTP Request", CR)) 
  'bytesSent := sock.Send(@request2, strsize(@request2))
  'bytesSent := sock.Send(@google, strsize(@google))
  'bytesSent := sock.Send(@s_google, strsize(@s_google))
  'bytesSent := sock.Send(@weather, strsize(@weather))
  bytesSent := sock.Send(@basicAuthReq, strsize(@basicAuthReq))
  'bytesSent := sock.Send(@basicAuthPost, strsize(@basicAuthPost))
  
  pst.str(string("Bytes Sent........"))
  pst.dec(bytesSent)
  pst.char(13)

  totalBytes := 0
  receiving := true
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
      next 

    if(bytesToRead > 0) 
      'Get the Rx buffer  
      buffer := sock.Receive(@buff, bytesToRead)
      pst.str(buffer)
      
    bytesToRead~

  pst.str(string("Bytes Received...."))
  pst.dec(totalBytes)
  pst.char(CR)
  
  pst.str(string("Disconnect", CR, CR)) 
  sock.Disconnect

  {{*****************************************************************   }} 
  
  pst.str(string(CR, "Begin POST Client Web Request", CR))
  sock.Open
  pause(100)
  sock.Connect

  pst.str(string(CR, "Connecting to.....")) 
  PrintIp(wiz.GetRemoteIP(0))
  pst.char(CR)
    
    'Connection?
  repeat until sock.Connected
    pause(100)

  pst.str(string("Sending HTTP Request", CR)) 
  'bytesSent := sock.Send(@request2, strsize(@request2))
  'bytesSent := sock.Send(@google, strsize(@google))
  'bytesSent := sock.Send(@s_google, strsize(@s_google))
  'bytesSent := sock.Send(@weather, strsize(@weather))
  'bytesSent := sock.Send(@basicAuthReq, strsize(@basicAuthReq))
  bytesSent := sock.Send(@basicAuthPost, strsize(@basicAuthPost))
  
  pst.str(string("Bytes Sent........"))
  pst.dec(bytesSent)
  pst.char(13)

  totalBytes := 0
  receiving := true
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
      next 

    if(bytesToRead > 0) 
      'Get the Rx buffer  
      buffer := sock.Receive(@buff, bytesToRead)
      pst.str(buffer)
      pst.char(CR)
      
    bytesToRead~

  pst.str(string("Bytes Received...."))
  pst.dec(totalBytes)
  pst.char(CR)
  
  pst.str(string("Disconnect", CR, CR)) 
  sock.Disconnect


  'Power down for x seconds
  'pst.str(string("Power Down", CR))
  'wiz.PowerDown(WIZ#WIZ_POWER_DOWN)
  'pause(10_000)

  'Power Up
  'The pause is required 
  'min pause is around 1/2 sec found from experimentation
  'pst.str(string("Power Up", CR))
  'wiz.PowerUp(WIZ#WIZ_POWER_DOWN)
  'wiz.PowerDown(WIZ#WIZ_POWER_DOWN)
  'wiz.PowerUp(WIZ#WIZ_POWER_DOWN)
  'pause(500)


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
  i := 0
  repeat i from 0 to 3
    pst.dec(byte[addr][i] & $FF)
    if(i < 3)
      pst.char($2E)
    else
      pst.char($0D)


PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return