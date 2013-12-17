# W5500 Driver for Parallax Propeller

## Description
-. [Parallax Propeller chip](http://parallax.com/microcontrollers/propeller)

-. [WIZnet W5500 Ethernet controller](http://wizwiki.net/wiki/doku.php?id=products:w5500:start)

-. [WIZnet WIZ550io module](http://wizwiki.net/wiki/doku.php?id=products:wiz550io:allpages)

## Files
* W5500.spin : W5500 driver
* Socket.spin : Socket library
* TcpMultiSocketServerDemo.spin : webserver demo program

## Connection
  SPI_SCK       = 12 ' SPI clock from master to all slaves
  
  SPI_MISO      = 13 ' SPI master in serial out from slave
  
  SPI_MOSI      = 14 ' SPI master out serial in to slave
  
  SPI_CS        = 15 ' SPI chip select (active low)
  
  
  RESET_PIN     = 6 ' Reset

![image](https://raw.github.com/jbkim/Parallax_W5500/master/Photo/Propeller_WIZ550io.jpg)