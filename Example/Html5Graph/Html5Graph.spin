CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K     = $800
  
  CR            = $0D
  LF            = $0A
  
  { Web Server Configuration }
  SOCKETS       = 3
  HTTP_PORT     = 8080
  DHCP_SOCK     = 3
  ATTEMPTS      = 5
  DISK_PARTION  = 0

  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE

  DHCP_ATTEMPTS = 10


  PWDN            = 24
  USB_Rx          = 31
  USB_Tx          = 30
  
  { DHCP Lease Counter }
  CNT_PIN         = 17
  NCO_FREQ        = 610         '($8000)(80x10^6)/2^32 = 610.3516Hz                           
  FREQ_610        = $8000       ' AN001-P8X32ACounters-v2.0_2.pdf (page 6)  
    
VAR
  long  seed

DAT
  index byte  "HTTP/1.1 200 OK", CR, LF, {
}             "Content-Type: text/html", CR, LF, CR, LF, {
}             "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>", CR, LF, {
}             "<html  xmlns='http://www.w3.org/1999/xhtml'>" , CR, LF, {
}             "<head><meta http-equiv='Content-Type' content='text/html; charset=utf-8' />", CR, LF, {
}             "<title>Graph Example</title>", CR, LF, {
}             "<script type='text/javascript' src='http://www.mikegebhard.com/graph.js'></script>", CR, LF, {
}             "<script type='text/javascript'>" , CR, LF, {
}             "window.onload = function() {", CR, LF, {
}             "g_graph = new Graph({", CR, LF, {
}             "'id': 'firstgraph',", CR, LF, {
}             "'strokeStyle': '#819C58',", CR, LF, {
}             "'fillStyle': 'rgba(64,128,0,0.25)',", CR, LF, {
}             "'call': function(){ return ( Math.floor(latestTemp())); }", CR, LF, {
}             "});", CR, LF, {
}             "g_graph2 = new Graph({", CR, LF, {
}             "'id': 'secondgraph',", CR, LF, {
}             "'strokeStyle': '#819C58',", CR, LF, {
}             "'fillStyle': 'rgba(64,128,0,0.25)',", CR, LF, {
}             "'call': function(){ return ( Math.floor(latestHumidity())); }", CR, LF, {
}             "});}", CR, LF, {
}             "</script>", CR, LF, {
}             "<script type='text/javascript'>", CR, LF, {
}             "setInterval(", $22, "getRequest('xmltemp', 'placeholder')", $22, ", 500);", CR, LF, {
}             "</script>", CR, LF, {
}             "</head>", CR, LF, {
}             "<body>", CR, LF, {
}             "<div><span id='placeholder'>10.0</span></div>", CR, LF, {
}             "<div><canvas id='firstgraph' width='600' height='200'></canvas></div>", CR, LF, {
}             "<div><span id='placeholder2'>5.0</span></div>", CR, LF, { 
}             "<div><canvas id='secondgraph' width='600' height='200'></canvas></div>", CR, LF, {
}             "</body>", CR, LF, {
}             "</html>", 0

  xml   byte  "HTTP/1.1 200 OK", CR, LF, {
  }           "Content-Type: text/xml", CR, LF, CR, LF, {
  }           "<?xml version='1.0' encoding='utf-8'?><root><temp>"
  
  temperature   byte  $30, $30, $2E, $30, "</temp><humidity>"
  humidity      byte  $30, $30, $2E, $30, "</humidity></root>", 0
  buff          byte  $0[BUFFER_2K] 
  resPtr        long $0[25]
  null          long  $00
  dhcpLease     long  $00
  
OBJ
  pst             : "Parallax Serial Terminal"
  wiz             : "W5500.spin" 
  sock[SOCKETS]   : "Socket.spin"
  dhcp            : "Dhcp" 
 
PUB Main | i, page, dnsServer

  i := 0
  
  if(ina[USB_Rx] == 0)      '' Check to see if USB port is powered
    outa[USB_Tx] := 0       '' Force Propeller Tx line LOW if USB not connected
  else                      '' Initialize normal serial communication to the PC here                              
    pst.Start(115_200)      '' http://forums.parallax.com/showthread.php?135067-Serial-Quirk&p=1043169&viewfull=1#post1043169
    pause(500)

  pst.str(string("Initialize W5500", CR))

  wiz.QS_Init
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)
  
  'wiz.HardReset(WIZ#WIZ_RESET)
  'wiz.Start(WIZ#SPI_CS, WIZ#SPI_SCK, WIZ#SPI_MOSI, WIZ#SPI_MISO)
  '

  'Invoke DHCP to retrived network parameters
  'This assumes the WizNet 5500 is connected 
  'to a router with DHCP support
  pst.str(string(CR,"Retrieving Network Parameters...Please Wait"))
  pst.str(@divider)
  if(InitNetworkParameters)
    PrintNetworkParams
  else
    PrintDhcpError
    return 

  'Setup a 610 Hz square wave on pin 7
  ctrb := %00100_000 << 23 + 1 << 9 + CNT_PIN 
  frqb := FREQ_610 
  dira[CNT_PIN] := 1
   
  'Positive edge counter on pin 7
  ctra := %01010 << 26 + CNT_PIN
  frqa := 1

  repeat
    pst.str(string(CR,"Initialize Sockets"))
    pst.str(@divider)
    repeat i from 0 to SOCKETS-1
      sock[i].Init(i, TCP, 8080)
           
    OpenListeners
    StartListners
    
     pst.str(string(CR, "Start Socket Services", CR))
    \MultiSocketServer
    pst.str(string("I blew up!"))
    pause(5000)

    
PUB MultiSocketServer | bytesToRead, i, page, j, x , bytesSent, ptr
  bytesToRead := bytesSent := i := j := x := 0
  repeat

    if(dhcpLease - phsa/NCO_FREQ <  dhcpLease/2)
      pst.str(string(CR, "Renew DHCP Lease", CR))
      pst.str(string("Requesting IP....."))
      if(dhcp.DoDhcp(false))
        PrintIp(dhcp.GetIp)
        dhcpLease := dhcp.GetLeaseTime
        phsa := 1
        pause(1500)

    bytesToRead~ 
    CloseWait

    repeat until sock[i].Connected
      i := ++i // SOCKETS

    'Data in the buffer?
    repeat until bytesToRead := sock[i].Available
    
    'Check for a timeout error
    if(bytesToRead < 0)
      pst.str(string(CR, "Timeout",CR))
      'PrintStatus(i)
      'PrintAllStatuses 
      next

    'Get the Rx buffer  
    sock[i].Receive(@buff, bytesToRead)

    page :=  ParseResource(@buff)

    'pst.dec(strsize(page))
    'pst.char(CR)

    bytesSent := 0
    ptr := page
    repeat until bytesSent == strsize(page)
      bytesSent += sock[i].Send(ptr, strsize(ptr))
      ptr := page + bytesSent

    sock[i].Disconnect
    sock[i].SetSocketIR($FF)
    
    i := ++i // SOCKETS
    
  
PUB OpenListeners | i
  repeat i from 0 to SOCKETS-1  
    sock[i].Open
      
PRI StartListners | i
  repeat i from 0 to SOCKETS-1
    if(sock[i].Listen)
      pst.str(string("Socket "))
    else
      pst.str(string("Listener failed ",CR))
    pst.dec(i)
    pst.str(string(" Port....."))
    pst.dec(sock[i].GetPort)
    pst.char(CR)

PUB CloseWait | i
  repeat i from 0 to SOCKETS-1
    if(sock[i].IsCloseWait) 
      sock[i].Disconnect
      sock[i].Close
      
    if(sock[i].IsClosed)  
      sock[i].Open
      sock[i].Listen

PRI PrintStatus(id)
  pst.str(string("Status ("))
  pst.dec(id)
  pst.str(string(")......."))
  pst.hex(wiz.GetSocketStatus(id), 2)
  pst.char(13)

PRI PrintAllStatuses | i
  pst.str(string(CR, "Socket Status", CR))
  repeat i from 0 to SOCKETS-1
    pst.dec(i)
    pst.str(string("  "))
  pst.char(CR)
  repeat i from 0 to SOCKETS-1
    pst.hex(wiz.GetSocketStatus(i), 2)
    pst.char($20)
  pst.char(CR)

PUB ParseResource(header) | ptr, value, i, done, j
  ptr := header
  i := 0
  done := false

  repeat until IsEndOfLine(byte[ptr])
    if(IsToken(byte[ptr]))
      byte[ptr] := 0
      resPtr[i++] := ++ptr
    else
      ++ptr

    if(ptr - header > 500)
      pst.str(string(CR, "+++++++++++++++[ERROR]++++++++++++++",CR))
      return @index

  resPtr[0] := header
  repeat j from 0 to i-1
    if(strcomp(resPtr[j], string("HTTP")))
      return @index
      
    if(strcomp(resPtr[j], string("xmltemp")))
      value := GetTemp
      WriteNode(@temperature, value)
      value := GetHumidity
      WriteNode(@humidity, value) 
      return @xml

  if(strcomp(resPtr[j], string("halo")))
    'do something

PRI InitNetworkParameters | i
   
  'Initialize the DHCP object
  dhcp.Init(@buff, DHCP_SOCK)

  'Request an IP. The requested IP
  'might not be assigned by DHCP
  'dhcp.SetRequestIp(192,168,1,130)

  'Invoke the SHCP process
  i := 1
  repeat until dhcp.DoDhcp(true)
    if(++i > ATTEMPTS)
      return false
  return true

PRI PrintNetworkParams

  pst.str(string("Assigned IP......."))
  PrintIp(dhcp.GetIp)
  
  pst.str(string("Lease Time........"))
  pst.dec(dhcp.GetLeaseTime)
  pst.str(string(" (seconds)"))
  pst.char(CR)
 
  pst.str(string("DNS Server........"))
  PrintIp(wiz.GetDns)

  pst.str(string("DHCP Server......."))
  printIp(dhcp.GetDhcpServer)

  pst.str(string("Router............"))
  printIp(dhcp.GetRouter)

  pst.str(string("Gateway..........."))                                        
  printIp(wiz.GetGatewayIp)


PRI PrintDhcpError
  if(dhcp.GetErrorCode > 0)
    pst.str(string(CR, "Error Code: "))
    pst.dec(dhcp.GetErrorCode)
    pst.char(CR)
    pst.str(dhcp.GetErrorMessage)
    pst.char(CR)

        
PUB IsToken(value)
  return lookdown(value: "/", "?", "=", " ")

PUB IsEndOfLine(value)
  return lookdown(value: CR, LF)    

PUB GetTemp
  seed := CNT 
  ?seed
  return seed & $8F + 5

PUB GetHumidity
  seed := CNT 
  ?seed
  return !seed & $7F + 1
    
PUB WriteNode(buffer, value) | t1
  t1 := value
  t1 := t1/100
  value -= t1 * 100
  byte[buffer][0] := t1 + $30

  t1 := value
  t1 := t1/10
  value -= t1 * 10
  byte[buffer][1] := t1 + $30
  
  t1 := value
  byte[buffer][3] := t1 + $30


PUB Toggle(pin, count)
  repeat count
    dira[pin]~~
      !outa[pin]
      waitcnt(80_000_000/8 + cnt)


     
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

DAT
  divider   byte  CR, "-----------------------------------------------", CR, $0