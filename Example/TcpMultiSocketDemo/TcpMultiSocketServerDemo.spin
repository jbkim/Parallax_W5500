CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K     = $800
  
  CR            = $0D
  LF            = $0A
  SOCKETS       = 8

  ' W5500 I/O
  SPI_SCK       = 12 ' SPI clock from master to all slaves
  SPI_MISO      = 13 ' SPI master in serial out from slave
  SPI_MOSI      = 14 ' SPI master out serial in to slave
  SPI_CS        = 15 ' SPI chip select (active low)
  PWDN          = 24 
'  RESET_PIN     = 26 ' Reset
  RESET_PIN     = 6 ' Reset
  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE
    
VAR

DAT
  index         byte  "HTTP/1.1 200 OK", CR, LF, {
}                     "Content-Type: text/html", CR, LF, CR, LF, {
}                     "Hello World!", CR, LF, $0

  buff          byte  $0[BUFFER_2K]
  null          long  $00 

OBJ
  pst           : "Parallax Serial Terminal"
  wiz           : "W5500" 
  sock[8]       : "Socket"
 
PUB Main | i

  pst.Start(115_200)
  pause(500)
  
  wiz.HardReset(RESET_PIN)
  wiz.Start(WIZ#SPI_CS, WIZ#SPI_SCK, WIZ#SPI_MOSI, WIZ#SPI_MISO)
  {  }
   'Display W5500 chip's version
  i := wiz.GetVersion
  pst.str(string("W5500 Version = 0x"))
  pst.hex(i,2)
  pst.char(CR)
 
  wiz.SetCommonnMode(0)
  wiz.SetGateway(192, 168, 1, 1)
  wiz.SetSubnetMask(255, 255, 255, 0)
  wiz.SetIp(192, 168, 1, 115)

  pst.str(string("Initialize Sockets",CR))
  repeat i from 0 to SOCKETS-1
    sock[i].Init(i, TCP, 80)

  OpenListeners
  StartListners
      
  pst.str(string("Start Socket server",CR))
  MultiSocketServer
  pause(5000)

  
PUB OpenListeners | i
  pst.str(string("Open",CR))
  repeat i from 0 to SOCKETS-1  
    sock[i].Open
      
PUB StartListners | i
  repeat i from 0 to SOCKETS-1
    if(sock[i].Listen)
      pst.str(string("Listen "))
    else
      pst.str(string("Listener failed ",CR))
    pst.dec(i)
    pst.char(CR)

PUB CloseWait | i
  repeat i from 0 to SOCKETS-1
    if(sock[i].IsCloseWait) 
      sock[i].Disconnect
      sock[i].Close
      
    if(sock[i].IsClosed)  
      sock[i].Open
      sock[i].Listen
      
PUB MultiSocketServer | bytesToRead, i
  bytesToRead := i := 0
  repeat
    pst.str(string("TCP Service", CR))
    CloseWait
    
    repeat until sock[i].Connected
      i := ++i // SOCKETS

    pst.str(string("Connected "))
    pst.dec(i)
    pst.char(CR)
    
    'Data in the buffer?
    repeat until bytesToRead := sock[i].Available

    'Check for a timeout
    if(bytesToRead < 0)
      pst.str(string("Timeout",CR))
      CloseWait
      bytesToRead~
      next
      
    'Get the Rx buffer
    pst.str(string("Copy Rx Data",CR))
    sock[i].Receive(@buff, bytesToRead)

    'Process the Rx data
    pst.char(CR)
    pst.str(string("Request:",CR))
    pst.str(@buff)

    pst.str(string("Send Response",CR))
    sock[i].Send(@index, strsize(@index))


    if(sock[i].Disconnect)
      pst.str(string("Disconnected", CR))
    else
      pst.str(string("Force Close", CR))
      
    sock[i].Open
    sock[i].Listen
    sock[i].SetSocketIR($FF)

    i := ++i // SOCKETS
    bytesToRead~
    
     
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