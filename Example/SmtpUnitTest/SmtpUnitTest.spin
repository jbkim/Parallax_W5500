CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K     = $800
  
  CR            = $0D
  LF            = $0A
  NULL          = $00
  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE
  
       
VAR

DAT
  buff          byte  $0[BUFFER_2K]
  ehlo          byte  "EHLO testemail@domain.net", $0D, $0A, 0
  mfrom         byte  "MAIL FROM: testemail@domain.net", $0D, $0A, 0
  mto           byte  "RCPT TO: testemail@domain.net", $0D, $0A, 0
  mdata         byte  "DATA", $0D, $0A, 0
  subject       byte  "SUBJECT: test", $0D, $0A,  0
  msg           byte  "This is a test from script - yehhhhh!", $0D, $0A, 0
  done          byte  ".", $0D, $0A, 0
  equit         byte  "quit", $0D, $0A, 0


OBJ
  pst           : "Parallax Serial Terminal"
  sock          : "Socket"
  wiz           : "W5500"


 
PUB Main | bytesToRead, buffer, bytesSent, receiving

  receiving := true
  bytesToRead := 0
  pst.Start(115_200)
  pause(500)


  pst.str(string("Initialize", CR))

  'Wiz Mac and Ip
  wiz.QS_Init 
  wiz.SetGateway(192, 168, 1, 1)
  wiz.SetSubnetMask(255, 255, 255, 0)
  wiz.SetIp(192, 168, 1, 105)
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)
  
  sock.Init(0, TCP, 8080)
  
  'sock.RemoteIp(0, 0, 0, 0)
  sock.RemoteIp(68, 6, 19, 4)
  'sock.RemoteIp(71,74,56,22)
  'sock.RemotePort(25)
  sock.RemotePort(587)

  pst.str(string(CR, "Begin SMTP Conversation", CR))

  'Client
  pst.str(string("Open", CR))
  sock.Open
  pst.str(string("Status (open)....."))
  pst.hex(wiz.GetSocketStatus(0), 2)
  pst.char(13)
  
  pst.str(string("Connect", CR))
  sock.Connect
  pause(500)
  pst.str(string("Status (Connect).."))
  pst.hex(wiz.GetSocketStatus(0), 2)
  pst.char(13)


  pause(500)
  pst.str(string("Connecting...",CR))
  'pst.hex(wiz.GetSocketStatus(0), 2)
  'pst.char(13)
   
   
  'Connection?
  repeat until sock.Connected
    pst.str(string("Status.........."))
    pst.hex(wiz.GetSocketStatus(0), 2)
    pst.char(13)
    pause(500)

  pst.str(string("Connected.........", CR))
  pst.hex(wiz.GetSocketStatus(0), 2)
  pst.char(13)
  
  repeat until NULL < bytesToRead := sock.Available 
  buffer := sock.Receive(@buff, bytesToRead)
  pst.str(buffer)

  Send(@ehlo, true)
  Send(@mfrom, true)
  Send(@mto, true)
  Send(@mdata, true)
  Send(@subject, false)
  Send(@msg, false)
  Send(@done, false)
  Send(@equit, true)

  pst.str(string(CR, "Disconnect", CR)) 
  sock.Disconnect
  sock.Close
   
  
PUB Send(cmd, response) | buffer, bytesToRead
  sock.Send(cmd, strsize(cmd))
  pst.str(cmd)
  pause(100)

  if(response)
    repeat until NULL < bytesToRead := sock.Available
    buffer := sock.Receive(@buff, bytesToRead)
    pst.str(buffer)   

PUB PrintNameValue(name, value, digits) | len
  len := strsize(name)
  
  pst.str(name)
  repeat 30 - len
    pst.char($2E)
  if(digits > 0)
    pst.hex(value, digits)
  else
    pst.dec(value)
  pst.char(CR)


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
    else
      pst.char($0D)
  
PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return