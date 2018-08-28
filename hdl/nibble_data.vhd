----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Description: Data for sending an empty UDP packet out over the MII interface.
--              "user_data" is asserted where you should replace 'nibble' with 
--              data that you wish to send.
-- 
-- The packet only requires 164 cycles to send, but a 12 bit counter is used to
-- allow you to increase the packet size to 1518 (the maximum for standard
-- ethernet) if you desire.   
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity nibble_data is
    generic (
        eth_src_mac       : std_logic_vector(47 downto 0);
        eth_dst_mac       : std_logic_vector(47 downto 0);
        ip_src_addr       : std_logic_vector(31 downto 0);
        ip_dst_addr       : std_logic_vector(31 downto 0));
    Port ( clk        : in  STD_LOGIC;
           start      : in  STD_LOGIC;
           busy       : out STD_LOGIC;
           data       : out STD_LOGIC_VECTOR (3 downto 0) := (others => '0');
           user_data  : out STD_LOGIC                     := '0';
           data_valid : out STD_LOGIC                     := '0');
end nibble_data;

architecture Behavioral of nibble_data is
    constant ip_header_bytes   : integer := 20;
    constant udp_header_bytes  : integer := 8;
    constant data_bytes        : integer := 1024*4;
    constant ip_total_bytes    : integer := ip_header_bytes + udp_header_bytes + data_bytes;
    constant udp_total_bytes   : integer := udp_header_bytes + data_bytes;

    signal counter : unsigned(15 downto 0) := (others => '0');
    
    
    -- Ethernet frame header
    -- Mac addresses come from module's generic 
    signal eth_type          : std_logic_vector(15 downto 0) := x"0800";

    -- IP header
    -- IP addresses come from module's generic 
    signal ip_version        : std_logic_vector( 3 downto 0) := x"4";
    signal ip_header_len     : std_logic_vector( 3 downto 0) := x"5";
    signal ip_dscp_ecn       : std_logic_vector( 7 downto 0) := x"00";
    signal ip_identification : std_logic_vector(15 downto 0) := x"0000";     -- Checksum is optional
    signal ip_length         : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(ip_total_bytes, 16));
    signal ip_flags_and_frag : std_logic_vector(15 downto 0) := x"0000";     -- no flags48 bytes
    signal ip_ttl            : std_logic_vector( 7 downto 0)  := x"80";
    signal ip_protocol       : std_logic_vector( 7 downto 0)  := x"11";
    signal ip_checksum       : std_logic_vector(15 downto 0) := x"0000";   -- Calcuated later on
    -- for calculating the checksum 
    signal ip_checksum1     : unsigned(31 downto 0) := (others => '0');
    signal ip_checksum2     : unsigned(15 downto 0) := (others => '0');
    
    -- UDP Header
    signal udp_src_port      : std_logic_vector(15 downto 0) := x"1000";     -- port 4096
    signal udp_dst_port      : std_logic_vector(15 downto 0) := x"1000";     -- port 4096
    signal udp_length        : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(udp_total_bytes, 16)); 
    signal udp_checksum      : std_logic_vector(15 downto 0) := x"0000";     -- Checksum is optional, and if presentincludes the data
begin
   ---------------------------------------------
   -- Calutate the TCP checksum using logic
   -- This should all colapse down to a constant
   -- at build-time (example #s found on the web)
   ----------------------------------------------
   --- Step 1) 4500 + 0030 + 4422 + 4000 + 8006 + 0000 + (0410 + 8A0C + FFFF + FFFF) = 0002BBCF (32-bit sum)
   ip_checksum1 <= to_unsigned(0,32) 
                 + unsigned(ip_version & ip_header_len & ip_dscp_ecn)
                 + unsigned(ip_identification)
                 + unsigned(ip_length)
                 + unsigned(ip_flags_and_frag)
                 + unsigned(ip_ttl & ip_protocol)
                 + unsigned(ip_src_addr(31 downto 16))
                 + unsigned(ip_src_addr(15 downto  0))
                 + unsigned(ip_dst_addr(31 downto 16))
                 + unsigned(ip_dst_addr(15 downto  0));
   -- Step 2) 0002 + BBCF = BBD1 = 1011101111010001 (1's complement 16-bit sum, formed by "end around carry" of 32-bit 2's complement sum)
   ip_checksum2 <= ip_checksum1(31 downto 16) + ip_checksum1(15 downto 0);
   -- Step 3) ~BBD1 = 0100010000101110 = 442E (1's complement of 1's complement 16-bit sum)
   ip_checksum  <= NOT std_logic_vector(ip_checksum2);

generate_nibbles: process (clk) 
    begin
        if rising_edge(clk) then
            -- Update the counter of where we are 
            -- in the packet
            if counter /= 0 or start = '1' then
               counter <= counter + 1;
            end if;
            
            -- Note, this uses the current value of counter, not the one assigned above!
            data <= "0000";
            case counter is 
              -- We pause at 0 count when idle (see below case statement)
              when x"0000" => NULL;
              -----------------------------
              -- MAC Header 
              -----------------------------
              -- Ethernet destination
              when x"0001" => data <= eth_dst_mac(43 downto 40); data_valid <= '1';
              when x"0002" => data <= eth_dst_mac(47 downto 44);
              when x"0003" => data <= eth_dst_mac(35 downto 32);
              when x"0004" => data <= eth_dst_mac(39 downto 36);
              when x"0005" => data <= eth_dst_mac(27 downto 24);
              when x"0006" => data <= eth_dst_mac(31 downto 28);
              when x"0007" => data <= eth_dst_mac(19 downto 16);
              when x"0008" => data <= eth_dst_mac(23 downto 20);
              when x"0009" => data <= eth_dst_mac(11 downto  8);
              when x"000A" => data <= eth_dst_mac(15 downto 12);
              when x"000B" => data <= eth_dst_mac( 3 downto  0);
              when x"000C" => data <= eth_dst_mac( 7 downto  4);
              -- Ethernet source
              when x"000D" => data <= eth_src_mac(43 downto 40);
              when x"000E" => data <= eth_src_mac(47 downto 44);
              when x"000F" => data <= eth_src_mac(35 downto 32);
              when x"0010" => data <= eth_src_mac(39 downto 36);
              when x"0011" => data <= eth_src_mac(27 downto 24);
              when x"0012" => data <= eth_src_mac(31 downto 28);
              when x"0013" => data <= eth_src_mac(19 downto 16);
              when x"0014" => data <= eth_src_mac(23 downto 20);
              when x"0015" => data <= eth_src_mac(11 downto  8);
              when x"0016" => data <= eth_src_mac(15 downto 12);
              when x"0017" => data <= eth_src_mac( 3 downto  0);
              when x"0018" => data <= eth_src_mac( 7 downto  4);
              -- Ether Type 08:00
              when x"0019" => data <= eth_type(11 downto  8);
              when x"001A" => data <= eth_type(15 downto 12); 
              when x"001B" => data <= eth_type( 3 downto  0);
              when x"001C" => data <= eth_type( 7 downto  4);
              -------------------------
              -- User data packet
              ------------------------------
              -- IPv4 Header
              ----------------------------
              when x"001D" => data <= ip_header_len;
              when x"001E" => data <= ip_version;
              
              when x"001F" => data <= ip_dscp_ecn( 3 downto  0);
              when x"0020" => data <= ip_dscp_ecn( 7 downto  4);
              -- Length of total packet (excludes etherent header and ethernet FCS) = 0x0030
              when x"0021" => data <= ip_length(11 downto  8);
              when x"0022" => data <= ip_length(15 downto 12);
              when x"0023" => data <= ip_length( 3 downto  0);
              when x"0024" => data <= ip_length( 7 downto  4);
              -- all zeros
              when x"0025" => data <= ip_identification(11 downto  8);
              when x"0026" => data <= ip_identification(15 downto 12);
              when x"0027" => data <= ip_identification( 3 downto  0);
              when x"0028" => data <= ip_identification( 7 downto  4);
              -- No flags, no frament offset.
              when x"0029" => data <= ip_flags_and_frag(11 downto  8);
              when x"002A" => data <= ip_flags_and_frag(15 downto 12);
              when x"002B" => data <= ip_flags_and_frag( 3 downto  0);
              when x"002C" => data <= ip_flags_and_frag( 7 downto  4);
              -- Time to live
              when x"002D" => data <= ip_ttl( 3 downto  0);
              when x"002E" => data <= ip_ttl( 7 downto  4);
              -- Protocol (UDP)
              when x"002F" => data <= ip_protocol( 3 downto  0);
              when x"0030" => data <= ip_protocol( 7 downto  4);
              -- Header checksum
              when x"0031" => data <= ip_checksum(11 downto  8);
              when x"0032" => data <= ip_checksum(15 downto 12);
              when x"0033" => data <= ip_checksum( 3 downto  0);
              when x"0034" => data <= ip_checksum( 7 downto  4);
              -- source address
              when x"0035" => data <= ip_src_addr(27 downto 24);
              when x"0036" => data <= ip_src_addr(31 downto 28);
              when x"0037" => data <= ip_src_addr(19 downto 16);
              when x"0038" => data <= ip_src_addr(23 downto 20);
              when x"0039" => data <= ip_src_addr(11 downto  8);
              when x"003A" => data <= ip_src_addr(15 downto 12);
              when x"003B" => data <= ip_src_addr( 3 downto  0);
              when x"003C" => data <= ip_src_addr( 7 downto  4);
              -- dest address
              when x"003D" => data <= ip_dst_addr(27 downto 24);
              when x"003E" => data <= ip_dst_addr(31 downto 28);
              when x"003F" => data <= ip_dst_addr(19 downto 16);
              when x"0040" => data <= ip_dst_addr(23 downto 20);
              when x"0041" => data <= ip_dst_addr(11 downto  8);
              when x"0042" => data <= ip_dst_addr(15 downto 12);
              when x"0043" => data <= ip_dst_addr( 3 downto  0);
              when x"0044" => data <= ip_dst_addr( 7 downto  4);
              -- No options in this packet
              
              ------------------------------------------------
              -- UDP/IP Header - from port 4096 to port 4096
              ------------------------------------------------
              -- Source port 4096
              when x"0045" => data <= udp_src_port(11 downto  8);
              when x"0046" => data <= udp_src_port(15 downto 12);
              when x"0047" => data <= udp_src_port( 3 downto  0);
              when x"0048" => data <= udp_src_port( 7 downto  4);
              -- Target port 4096
              when x"0049" => data <= udp_dst_port(11 downto  8);
              when x"004A" => data <= udp_dst_port(15 downto 12);
              when x"004B" => data <= udp_dst_port( 3 downto  0);
              when x"004C" => data <= udp_dst_port( 7 downto  4);
              -- UDP Length (header + data) 24 octets
              when x"004D" => data <= udp_length(11 downto  8);
              when x"004E" => data <= udp_length(15 downto 12);
              when x"004F" => data <= udp_length( 3 downto  0);
              when x"0050" => data <= udp_length( 7 downto  4);
              -- UDP Checksum not suppled
              when x"0051" => data <= udp_checksum(11 downto  8);
              when x"0052" => data <= udp_checksum(15 downto 12);
              when x"0053" => data <= udp_checksum( 3 downto  0);
              when x"0054" => data <= udp_checksum( 7 downto  4);
              --------------------------------------------
              -- Finally! the  user data (defaults 
              -- to "0000" due to assignement above CASE).
              ---------------------------------------------
              when x"0055" => user_data <= '1';

              --------------------------------------------
              -- Ethernet Frame Check Sequence (CRC) will 
              -- be added here, overwriting these nibbles
              --------------------------------------------
              when x"2055" => data_valid <= '0'; user_data <= '0';
              when x"2056" => NULL;
              when x"2057" => NULL;
              when x"2058" => NULL;
              when x"2059" => NULL;
              when x"205A" => NULL;
              when x"205B" => NULL;
              when x"205C" => NULL;
              ----------------------------------------------------------------------------------
              -- End of frame - there needs to be at least 20 octets (40 counts) before  sending 
              -- the next packet, (maybe more depending  on medium?) 12 are for the inter packet
              -- gap, 8 allow for the preamble that will be added to the start of this packet.
              --
              -- Note that when the count of 0000 adds one  more nibble, so if start is assigned 
              -- '1' this should be minimum that is  within spec.
              ----------------------------------------------------------------------------------
              when x"2083" => counter <= (others => '0'); busy  <= '0';
              when others => data <= "0000";
            end case;
         end if;    
    end process;
end Behavioral;
