CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K     = $800
  
  CR            = $0D
  LF            = $0A
  NULL          = $00
  RESET_PIN     = 4 
  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE
    
VAR

DAT
  user_pw       byte  "web:web"
  _null         byte  $0
  null_type     byte  "|" , $0
  authValue     byte  "Basic "
  base64auth    byte  $0[64]
  auth          byte  "HTTP/1.1 401 Access Denied", CR, LF,  {
}                     "WWW-Authenticate: Basic realm=", $22, "localhost", $22, CR, LF, {
}                     "Content-Length: 4033", CR, LF, {
}                     "Content-Type: text/html", CR, LF, CR, LF, {
}                     "<h1>401 Access Denied</h1>", CR, LF, $0  
  index         byte  "HTTP/1.1 200 OK", CR, LF, {
}                     "Content-Type: text/html", CR, LF, CR, LF, {
}                     "<html>" ,CR, LF, {
}                     "<head>" ,CR, LF, {
}                     "<title>Hello</title></head>", CR, LF, {
}                     "<body>", CR, LF, {
}                     "<h1>Hello World!</h1>", CR, LF, {
}                     "<div><form id=", $22, "post", $22, " name=", $22, "post", $22, " method=", $22, "post", $22, " >",{
}                     "<input id='textbox' type='text' name='textbox' value='Hello World!' />", CR, LF, {
}                     "<input name=", $22, "button", $22, " type=", $22, "submit", $22, {
}                     " value=", $22, "Go", $22, " />", {
}                     "</form></div></body></html>", CR, LF, $0
  notFound      byte  "HTTP/1.0 404 Not Found", CR, LF, {
}                     "Content-Type: text/html", CR, LF, CR, LF, { 
}                     "<h1>404 Not Found!</h1>", CR, LF, $0
  statusLine    byte  "++++", $0
  buff          byte  $0[BUFFER_2K]
  resPtr        long  $0[50]
  tokens        long  $0
  t1            long  $0

OBJ
  pst           : "Parallax Serial Terminal"
  wiz           : "W5500" 
  sock          : "Socket"
  b64           : "base64"
  req           : "HttpHeader"
 
PUB Main | bytesToRead

  bytesToRead := 0
  pst.Start(115_200)
  pause(500)

  'Encode the username and password used in basic authentication
  repeat t1 from 0 to @_null - @user_pw - 1
    b64.out(user_pw[t1])
  t1 := b64.end
  bytemove(@base64auth, t1, strsize(t1))
  pst.str(@base64auth)
  pst.char(CR)

  wiz.HardReset(WIZ#WIZ_RESET)
  wiz.Start(WIZ#SPI_CS, WIZ#SPI_SCK, WIZ#SPI_MOSI, WIZ#SPI_MISO)
  
  wiz.SetIp(192, 168, 1, 105)
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)
  
  pst.str(string("Initialize Socket",CR))
  sock.Init(0, TCP, 8080)

  pst.str(string("Start Socket server",CR))
  repeat
    CloseWait
    sock.Open
    
    ifnot(sock.Listen)
      pst.str(string("Listener failed!"))
      sock.Disconnect 
      next 
    
    'Connection?
    repeat until sock.Connected
    
    'Data in the buffer?
    repeat until bytesToRead := sock.Available

    'Check for a timeout
    if(bytesToRead < 0)
      bytesToRead~
      pst.str(string("Timeout",CR))
      next

    'Get the Rx buffer  
    sock.Receive(@buff, bytesToRead)

    pst.str(@buff)
    pst.str(string(CR, "******[ End of Header ]********************", CR))

    'Tokenize the header
    req.TokenizeHeader(@buff, bytesToRead)

    'Quit if the browser is looking for favicon.ico
    if(req.UrlContains(string("favicon.ico")))
      'pst.str(string("404 Error", CR))
      sock.Send(@notFound, strsize(@notFound))
      sock.Disconnect
      bytesToRead~
      next
    
    {{ Process the Rx data}}
    'Check for Authorization header
    if(IsAuthenticated)
      'pst.str(string("Authenticated", CR))
      sock.Send(@index, strsize(@index))
    else
      pst.str(string("Not Authenticated", CR))
      sock.Send(@auth, strsize(@auth))

    'Reset
    sock.Disconnect
    bytesToRead~

PUB CloseWait | i
  if(sock.IsCloseWait) 
    sock.Close
    
PUB IsAuthenticated
  return strcomp( @authValue, req.Header( string("Authorization") ) )

PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return