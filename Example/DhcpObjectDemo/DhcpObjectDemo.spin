CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

    { Web Server Configuration }
  DHCP_SOCK     = 7             'which W5500 socket to use


  BUFFER_2K     = $800

  CR            = $0D
  LF            = $0A
  
  ATTEMPTS      = 5

OBJ
  pst           : "Parallax Serial Terminal"
  wiz           : "W5500"
  dhcp          : "Dhcp"

VAR

  long  ipAddress               'each byte in the long represents one octet
  long  dnsAddress
  long  dhcpAddress
  long  routerAddress
  long  gatewayAddress
  long  subnetAddress

  long  leaseTime               'in seconds
  
                        
DAT

  'Working buffer allocation
  buff        byte  $0[BUFFER_2K+1]
  
  'the default MAC address.
  _mac        byte  $50, $38, $58, $33, $32, $41        ':)

  divider     byte  CR, "---------------------------------------------------", CR, $0

   
 
PUB Init | ptr, i
  
  'Start the serial terminal
  pst.Start(115_200)

  Pause(100)
  pst.str(string("Initialize", CR))

  'Init the W5500 board
  wiz.QS_Init
  'Set the hardware address
  wiz.SetMac(_mac[0], _mac[1], _mac[2], _mac[3], _mac[4], _mac[5])

  '--------------------------------------------------- 
  'Invoke DHCP to retrived network parameters
  'This assumes the WizNet 5500 is connected 
  'to a router with DHCP support
  '--------------------------------------------------- 
  pst.str(string(CR,"Retrieving Network Parameters...Please Wait"))
  pst.str(@divider)
  if( InitNetworkParameters )

    'We got an address!
    
    'collect the data automatically assigned
    bytemove(@ipAddress, dhcp.GetIp, 4)
    bytemove(@subnetAddress, wiz.GetSubnetMask, 4)
    bytemove(@dnsAddress, wiz.GetDns, 4)
    bytemove(@dhcpAddress, dhcp.GetDhcpServer, 4)
    bytemove(@routerAddress, dhcp.GetRouter, 4)
    bytemove(@gatewayAddress, wiz.GetGatewayIp, 4)
    bytemove(@_mac, wiz.GetMac, 6)
    leaseTime      := dhcp.GetLeaseTime

    PrintNetworkParams

  else
  
    'Whoops, there was some problem.
    PrintDhcpError

  pst.str(string(CR, "All done!", CR))

PRI InitNetworkParameters | i

  i := 0 
  'Initialize the DHCP object
  dhcp.Init(@buff, DHCP_SOCK)

  'Request an IP. The requested IP
  'might not be assigned by DHCP
  'dhcp.SetRequestIp(192,168,1,108)

  'Invoke the DHCP process
  repeat until dhcp.DoDhcp(true)
    if(++i > ATTEMPTS)
      return false
  return true


PRI PrintDhcpError
  if(dhcp.GetErrorCode > 0)
    pst.char(CR) 
    pst.str(string(CR, "Error Code: "))
    pst.dec(dhcp.GetErrorCode)
    pst.char(CR)
    pst.str(dhcp.GetErrorMessage)
    pst.char(CR)

PRI PrintNetworkParams

  pst.str(string("Assigned IP......."))
  PrintIp(@ipAddress)

  pst.str(string("Subnet Mask......."))
  PrintIp(@subnetAddress)

  pst.str(string("MAC Address......."))

  repeat result from 0 to 5
    pst.hex(byte[@_mac][result], 2)
    if result < 5
      pst.char(":")
    else
      pst.NewLine
      
  pst.str(string("Lease Time........"))
  pst.dec(leaseTime)
  pst.str(string(" (seconds)"))
  pst.char(CR)
 
  pst.str(string("DNS Server........"))
  PrintIp(@dnsAddress)
          
  pst.str(string("DHCP Server......."))
  printIp(@dhcpAddress)

  pst.str(string("Router............"))
  printIp(@routerAddress)

  pst.str(string("Gateway..........."))                                        
  printIp(@gatewayAddress)

PRI PrintIp(addr) | i
  repeat i from 0 to 3
    pst.dec(byte[addr][i])
    if(i < 3)
      pst.char($2E)
    else
      pst.char($0D)
  
PRI Pause(Duration)

  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  