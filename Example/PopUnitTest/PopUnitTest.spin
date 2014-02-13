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
  user          byte  "USER ", $0D, $0A, 0
  pass          byte  "PASS ", $0D, $0A, 0
  list          byte  "LIST", $0D, $0A, 0
  retr          byte  "RETR 1", $0D, $0A, 0
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
  'Initialize Socket 0 port 8080
  

  'Wiz Mac and Ip
  wiz.QS_Init 
  wiz.SetGateway(192, 168, 1, 1)
  wiz.SetSubnetMask(255, 255, 255, 0)
  wiz.SetIp(192, 168, 1, 105)
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)


  sock.Init(0, TCP, 8080)
  
  'sock.RemoteIp(0,0,0,0)
  sock.RemoteIp(71,74,56,68)
  sock.RemotePort(110)

  pst.str(string(CR, "Begin POP Conversation", CR))

  'Client
  pst.str(string("Open", CR))
  sock.Open
  pst.str(string("Connect", CR))
  sock.Connect

  pause(500)
  pst.str(string("Connecting..."))
  pst.hex(wiz.GetSocketStatus(0), 2)
  pst.char(13)
   
  'Connection?
  repeat until sock.Connected
    pause(100)

  pst.str(string("Connected", CR))
  
  bytesToRead := sock.Available
  buffer := sock.Receive(@buff, bytesToRead)
  pst.str(buffer)

  Send(@user, true)
  Send(@pass, true)
  Send(@list, true)
  Send(@retr, true)
  Send(@equit, true) 

  pst.str(string(CR, "Disconnect", CR)) 
  sock.Disconnect
  sock.Close
   

PUB Send(cmd, response) | buffer, bytesToRead
  sock.Send(cmd, strsize(cmd))
  pst.str(cmd)
  pause(100)

  if(response)
    bytesToRead := sock.Available
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