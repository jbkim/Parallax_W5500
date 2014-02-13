CON
  BUFFER_2K         = $800
  BUFFER_16         = $10
  
  CR                = $0D
  LF                = $0A
  DHCP_OPTIONS      = $F0
  DHCP_END          = $FF
  HARDWARE_ADDR_LEN = $06
  MAGIC_COOKIE_LEN  = $04
  UPD_HEADER_LEN    = $08
  MAX_DHCP_OPTIONS  = $10
  DHCP_PACKET_LEN        = $156 '342
  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE

  {{ DHCP Packet Pointers }}
  DHCP_OP            = $00
  DHCP_HTYPE         = $01
  DHCP_HLEN          = $02
  DHCP_HOPS          = $03
  DHCP_XID           = $04
  DHCP_SEC           = $08
  DHCP_FLAGS         = $0A
  DHCP_CIADDR        = $0C  
  DHCP_YIADDR        = $10
  DHCP_SIADDR        = $14
  DHCP_GIADDR        = $18
  DHCP_CHADDR        = $1C
  DHCP_BOOTP         = $2C
  DHCP_MAGIC_COOKIE  = $EC
  DHCP_DHCP_OPTIONS  = $F0

  {{ DHCP Options Enum}}
  SUBNET_MASK         = 01
  ROUTER_IP           = 03
  DOMAIN_NAME_SERVER  = 06
  HOST_NAME           = 12
  REQUEST_IP          = 50
  IP_LEASE_TIME       = 51
  MESSAGE_TYPE        = 53
  DHCP_SERVER_IP      = 54
  PARAM_REQUEST       = 55
  
  

  {{ DHCP Message Types}}
  DHCP_DISCOVER       = 1       
  DHCP_OFFER          = 2       
  DHCP_REQUEST        = 3       
  DHCP_DECLINE        = 4       
  DHCP_ACK            = 5       
  DHCP_NAK            = 6       
  DHCP_RELEASE        = 7

  {{ Packet Types }}
  #0, SUCCESS, DISCOVER_ERROR, OFFER_ERROR, REQUEST_ERROR, ACK_ERROR, DUNNO_ERROR 

  HOST_PORT           = 68
  REMOTE_PORT         = 67
      
                        
       
VAR

DAT
  noErr           byte  "Success", 0
  errDis          byte  "Discover Error", 0
  errOff          byte  "Offer Error", 0
  errReq          byte  "Request Error", 0
  errAck          byte  "Ack Error", 0
  errDunno        byte  "Unidentified Error", $0 
  requestIp       byte  00, 00, 00, 00
  errorCode       byte  $00
  magicCookie     byte  $63, $82, $53, $63
  paramReq        byte  $01, $03, $06, $2A ' Paramter Request; mask, router, domain name server, network time
  hostName        byte  "propnet", $0
  leaseTime       byte  $00, $00, $00, $00
  optionPtr       long  $F0
  buffPtr         long  $00_00_00_00
  transId         long  $00_00_00_00
  null            long  $00_00_00_00
  errors          long  @noErr, @errDis, @erroff, @errReq, @errAck, @errDunno

  _dhcpServer      byte  $00, $00, $00, $00
  _router          byte  $00, $00, $00, $00 
  

   
OBJ
  sock          : "Socket"
  wiz           : "W5500" 
 
PUB Init(buffer, socket)

  buffPtr := buffer

  'Set up the host socket 
  sock.Init(socket, UDP, HOST_PORT)


PUB GetErrorCode
  return errorCode

PUB GetErrorMessage
  if(errorCode > -1 OR errorCode < DUNNO_ERROR)
    return @@errors[errorCode]
  else
    return @@errors[DUNNO_ERROR]

PUB GetLeaseTime | lease
  lease := byte[@leaseTime][0] << 24 | byte[@leaseTime][1]  << 16 | byte[@leaseTime][2] << 8 | byte[@leaseTime][3]
  return lease
  'return byte[@leaseTime][2]

PUB GetIp
  return wiz.GetIp  

PUB SetRequestIp(octet3, octet2, octet1, octet0)
  requestIp[0] := octet3 
  requestIp[1] := octet2
  requestIp[2] := octet1
  requestIp[3] := octet0

PRI IsRequestIp
   return requestIp[0] | requestIp[1] | requestIp[2] | requestIp[3]

PUB GetRequestIP
  return @requestIp
 
PUB DoDhcp(resetIp)
 
  errorCode := 0
  CreateTransactionId

  if(resetIp)
    wiz.SetIp(0,0,0,0)

  ifnot(DiscoverOffer)
    sock.Close
    return false

  ifnot(RequestAck) 
    sock.Close
    return false
 
  sock.Close 
  return true
  
PUB RenewDhcp
  errorCode := 0
  CreateTransactionId

  ifnot(RequestAck) 
    sock.Close
    return false
 
  sock.Close 
  return true
  
PRI DiscoverOffer | ptr

  InitRequest
  
  ptr := Discover
  if(ptr == @null)
    errorCode := DISCOVER_ERROR
    return false
        
  ifnot(Offer)
    errorCode := OFFER_ERROR
    return false

  return true

  
PRI RequestAck  | ptr

  InitRequest
  
  ptr := Request
  if(ptr == @null)
    errorCode := REQUEST_ERROR
    return false
    
  ifnot(Ack)
    errorCode := ACK_ERROR
    return false

  return true 

 
PRI InitRequest
  bytefill(buffPtr, 0, DHCP_MAGIC_COOKIE)
  sock.RemoteIp(255, 255, 255, 255)   
  sock.RemotePort(REMOTE_PORT)

  
PRI Discover | len
  'optionPtr is a global pointer used in the
  'WriteDhcpOption and ReadDhcpOption methods
  optionPtr := DHCP_OPTIONS + buffPtr
  
  FillOpHtypeHlenHops($01, $01, $06, $00)
  
  FillTransactionID
  FillMac
  FillMagicCookie
  WriteDhcpOption(MESSAGE_TYPE, 1, DHCP_DISCOVER)
  if(IsRequestIp)
    WriteDhcpOption(REQUEST_IP, 4, @requestIp)
  WriteDhcpOption(PARAM_REQUEST, 4, @paramReq)
  WriteDhcpOption(HOST_NAME, strsize(@hostName), @hostName)
  len := EndDhcpOptions
  return SendReceive(buffPtr, len)


PRI Offer | ptr
  optionPtr := DHCP_OPTIONS + buffPtr

  'Move the pointer 8 bytes to the right
  'On receive the first 8 bytes in the UDP packet are IP:Port and len
  buffPtr += UPD_HEADER_LEN

  'Set the IP
  GetSetIp
  
  ' Set DNS server IP
  ptr := ReadDhcpOption(DOMAIN_NAME_SERVER)
  Wiz.copyDns(ptr+1, byte[ptr])

  'Set the Gateway IP
  'GetSetGateway

  'Set the ubnet mask
  ptr := ReadDhcpOption(SUBNET_MASK)
  wiz.CopySubnet(ptr+1, byte[ptr])

  'Set the router IP to the Gateway
  'Mike G 10/16/2012
  'From research and asking network guys the router IP (option 3)
  'should also be the gateway.
  ptr := ReadDhcpOption(ROUTER_IP)
  SetRouter(ptr+1)
  Wiz.CopyGateway(ptr+1, byte[ptr])

  'Set the DHCP server IP
  ptr := ReadDhcpOption(DHCP_SERVER_IP)
  SetDhcpServer(ptr+1) 

  ptr := ReadDhcpOption(MESSAGE_TYPE)
  
  'Reset the pointer
  buffPtr -= UPD_HEADER_LEN

  return byte[ptr][1] & $FF == OFFER_ERROR

PRI Request | len
  optionPtr := DHCP_OPTIONS + buffPtr
  
  bytefill(buffPtr, 0, BUFFER_2K)
  FillOpHtypeHlenHops($01, $01, $06, $00)
  FillTransactionID
  FillMac
  FillServerIp
  FillMagicCookie
  WriteDhcpOption(MESSAGE_TYPE, 1, DHCP_REQUEST)
  IsRequestIp
    WriteDhcpOption(REQUEST_IP, 4, @requestIp)
  WriteDhcpOption(DHCP_SERVER_IP, 4, GetDhcpServer)
  WriteDhcpOption(HOST_NAME, strsize(@hostName), @hostName)
  len := EndDhcpOptions
  return SendReceive(buffPtr, len)


PRI Ack | ptr

  buffPtr += UPD_HEADER_LEN

  optionPtr := DHCP_OPTIONS + buffPtr

  ptr := ReadDhcpOption(IP_LEASE_TIME)
  FillLeaseTime(ptr+1)

  ptr := ReadDhcpOption(MESSAGE_TYPE) 
  
  buffPtr -= UPD_HEADER_LEN
  
  return byte[ptr][1] & $FF == DHCP_ACK
  
PRI GetSetIp | ptr
  ptr := buffPtr + DHCP_YIADDR
  Wiz.SetIp(byte[ptr][0], byte[ptr][1], byte[ptr][2], byte[ptr][3])
  requestIp[0] := byte[ptr][0]
  requestIp[1] := byte[ptr][1]
  requestIp[2] := byte[ptr][2]
  requestIp[3] := byte[ptr][3] 
  

PRI FillOpHTypeHlenHops(op, htype, hlen, hops)
  byte[buffPtr][DHCP_OP] := op
  byte[buffPtr][DHCP_HTYPE] := htype
  byte[buffPtr][DHCP_HLEN] := hlen
  byte[buffPtr][DHCP_HOPS] := hops  


PRI CreateTransactionId
  transId := CNT
  ?transId

PRI FillLeaseTime(ptr)
  'leaseTime :=  ptr[0] << 24 |  ptr[1] << 16 | ptr[2] << 8 | ptr[3]
  bytemove(@leaseTime, ptr, 4)
  
PRI FillTransactionID
  bytemove(buffPtr+DHCP_XID, @transId, 4)

PRI FillMac
  bytemove(buffPtr+DHCP_CHADDR, wiz.GetMac, HARDWARE_ADDR_LEN)    

PRI FillServerIp
  bytemove(buffPtr+DHCP_SIADDR, GetDhcpServer, 4)

  
PRI FillMagicCookie
  bytemove(buffPtr+DHCP_MAGIC_COOKIE, @magicCookie, MAGIC_COOKIE_LEN)


PRI WriteDhcpOption(option, len, data)
  byte[optionPtr++] := option
  byte[optionPtr++] := len
  
  if(len == 1)
    byte[optionPtr] := data
  else
    bytemove(optionPtr, data, len)
    
  optionPtr += len

PRI ReadDhcpOption(option) | ptr
  'Init pointer to options
  ptr := DHCP_OPTIONS + buffPtr

  'Repeat until we reach the end of the UPD packet
  repeat MAX_DHCP_OPTIONS

    if(byte[ptr] == DHCP_END)
      return -2
  
    if(byte[ptr++] == option)
      'return a pointer to the length byte
      return ptr

    'point to the next option code 
    ptr += byte[ptr] + 1

  return -1  
    
  
PRI EndDhcpOptions | len
  byte[optionPtr] := DHCP_END
  return DHCP_PACKET_LEN



PUB SetRouter(source)
  bytemove(@_router, source, 4)
  
PUB GetRouter
  return @_router


PUB SetDhcpServer(source)
  bytemove(@_dhcpServer, source, 4)

PUB GetDhcpServer
  return  @_dhcpServer

{  
PRI SendReceive(buffer, len) | bytesToRead, ptr, tryagain 
  
  bytesToRead := 0
  tryagain := false
  'Open socket and Send Message 
  sock.Open
  sock.Send(buffer, len)

  repeat
     bytesToRead += sock.Available
      
     'Check for a timeout
     if(bytesToRead =< 0 )
       bytesToRead~
       return @null
 
     if(bytesToRead > 0)
       'Get the Rx buffer    
       ifnot(tryagain) 
         ptr := sock.Receive(buffer, bytesToRead)
       else
         sock.Receive(buffer, bytesToRead)
       'Retry if we did not receive all expected
       'bytes as read from the UDP header  
       ifnot(UpdRxLen(ptr-8) == bytesToRead-8)         
         buffer += bytesToRead
         tryagain := true
       else
         quit

  sock.Disconnect
  return ptr
}
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
  
PUB UpdRxLen(buffer)
  return sock.DeserializeWord(buffer + 6)