----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/03/2022 11:52:48 AM
-- Design Name: 
-- Module Name: CONFIG_INTERFACE - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
--- Description: 
--  this component is the interface to configure the function generator
--
-- generic:
-- - data_width: width of all data related configuration bit vectors
-- - data_width: width of all clock related configuration bit vectors
-- - <propertyname>_default: default value that the functiongenerator will start with
-- - min_cyc_ticks: minimum for cyc_ticks configuration bit vector, usualy it will be 
--   2 to fullfill shannon-nyquist theorem minimally
-- - baud_clk_ticks: for the UART interface, define how many clk ticks occur while
--   sending / receiving 1 bit
--
-- inputs:
-- - CLK: the DAC-FPGA-Component clock, clock for the microchip is derived
--        from this clock signal
-- - CE: 0: Chip-enabled
-- - RX: UARTs RX Signal for receiving data for configuration
--
-- outputs:
-- - TX: the UARTs TX Signal for sending Bits       
-- - cyc_ticks: the configuration for cycle time of functions
-- - thresh: the threshhold for the square function
-- - high: the high value the functions will emit
-- - low: the low value the functions will emit
-- - waveform: the current waveform the generator is emitting
-- - direction: determines if the ramp function counts up or down
--
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CONFIG_INTERFACE is
      generic (data_width : natural := 12;
               clk_width  : natural := 24;
               
               cyc_ticks_default : natural := 255;
               dutycycle_default : natural := 128;
               high_default      : natural := 4095;
               low_default       : natural := 0;
               waveform_default  : natural range 0 to 3 := 1;
               direction_default : std_logic := '1';
               
               min_cyc_ticks : natural := 2;
               
               baud_clk_ticks : natural := 868
               );
      port (CLK          : in  std_logic;
            CE           : in  std_logic;
            
            RX           : in  std_logic;
            TX           : out std_logic;
            
            cyc_ticks    : out std_logic_vector(clk_width - 1 downto 0);
            thresh       : out std_logic_vector(clk_width - 1 downto 0);
            high         : out std_logic_vector(data_width - 1 downto 0);
            low          : out std_logic_vector(data_width - 1 downto 0);
            waveform     : out std_logic_vector(1 downto 0);
            direction    : out std_logic);
end CONFIG_INTERFACE;

architecture Behavioral of CONFIG_INTERFACE is

  --- clocking declarations ---

  component SCLK_ENABLE is
    Port ( CLK     : in  STD_LOGIC;
           CE      : in  STD_LOGIC;
           R       : in  STD_LOGIC;
           DIVIDER : in  natural range 0 to 65535;
           SCLK_EN : out STD_LOGIC);
  end component SCLK_ENABLE;
  
  signal state_machine_EN : std_logic := '1';

  --- UART declarations ---

  component UART
    generic(
            BAUD_CLK_TICKS : integer := 868
            );
    port(
        CLK            : in  std_logic;
        CE             : in  std_logic;
        reset          : in  std_logic;
        tx_start       : in  std_logic;
        data_in        : in  std_logic_vector (7 downto 0);
        data_out       : out std_logic_vector (7 downto 0);
        rx             : in  std_logic;
        rx_uart_rdy    : out std_logic;
        tx             : out std_logic
        );
   end component UART;
   
  -- internal signals between UART and parameter calculation
  
  -- data that goes into the FPGA and out of the UART interface
  signal uart_data_out    : std_logic_vector(7 downto 0) := x"00";
  -- data that goes out of the FPGA and into the UART interface
  signal uart_data_in     : std_logic_vector(7 downto 0) := x"FF";
  -- signal that drops low for one baud rate cycle if new byte has arrived
  signal rx_uart_rdy      : std_logic := '1';
  -- hold till new byte is read into buffer
  signal rx_uart_rdy_hold : std_logic := '1';
  -- pull down for one cycle to start transmission of uart_data_out
  signal tx_uart_start    : std_logic := '0';
  
  --- Parameter Calculation declarations ---
  
  -- instruction set
  constant SETCYCTICKS  : std_logic_vector(7 downto 0)       := x"01";
  constant SETHIGH      : std_logic_vector(7 downto 0)       := x"02";
  constant SETLOW       : std_logic_vector(7 downto 0)       := x"03";
  constant SETDUTYCYCLE : std_logic_vector(7 downto 0)       := x"04";
  constant SETWVFRM     : std_logic_vector(7 downto 0)       := x"05";
  constant SETDIR       : std_logic_vector(7 downto 0)       := x"06";
  
  -- size of instruction in bytes
  constant INSTRUCTIONSIZE : natural := 4;
  -- indices of the instruction number in buffer
  constant INSTMSB         : natural := INSTRUCTIONSIZE * 8 - 1;
  constant INSTLSB         : natural := (INSTRUCTIONSIZE - 1) * 8;
  -- index of data msb
  constant ARGMSB          : natural := (INSTRUCTIONSIZE - 1) * 8 - 1;

  -- type for state machine that interpretes whats in the buffer
  type STATE_t is (IDLE, SHIFT, INTERPRETE, CALCULATE, OUTPUT);
  
  -- signal that steers the state of parameter interpreting and calculating
  -- state machine, set to OUTPUT to overwrite output signals 
  -- with default values on startup
  signal state : STATE_t := OUTPUT;
  
  -- buffer of the instruction byte + argument bytes
  signal ibuff            : std_logic_vector(INSTMSB downto 0) := (others => '1'); 
  -- parameter signals, initialized with default values
  -- cyc_ticks:
  signal cts  : std_logic_vector(clk_width - 1 downto 0)  := std_logic_vector(to_unsigned(cyc_ticks_default, clk_width));
  -- threshhold_signal:
  signal ths  : std_logic_vector(clk_width - 1 downto 0)  := std_logic_vector(to_unsigned(cyc_ticks_default * dutycycle_default / 256, clk_width));
  -- high_signal:
  signal hs   : std_logic_vector(data_width - 1 downto 0) := std_logic_vector(to_unsigned(high_default, data_width));
  -- low_signal:
  signal ls   : std_logic_vector(data_width - 1 downto 0) := std_logic_vector(to_unsigned(low_default, data_width));
  -- waveform_signal:
  signal wvs  : std_logic_vector(1 downto 0)              := std_logic_vector(to_unsigned(waveform_default, waveform'length));
  -- direction_signal:
  signal dirs : std_logic                                 := direction_default;
  
begin

  -- UART ---

  uart_transceiver : UART
  generic map(BAUD_CLK_TICKS => baud_clk_ticks
              )
  port map(CLK         => CLK,
           CE          => CE,
           reset       => '1',
           tx_start    => tx_uart_start,
           data_in     => uart_data_in,
           data_out    => uart_data_out,
           rx_uart_rdy => rx_uart_rdy,
           rx          => Rx,
           tx          => Tx
      );

  --- clocking ---
  --- this clock enable runs on baud rate frequency so the interprete 
  --- and calculate process can iterate through its 5 states within 10 Bits 
  --- 10 Bits = 8 * data + 1 * start + 1 * stop
  --- the internal counter is reset if a new byte has arrived
  sm_en : SCLK_ENABLE
  port map(CLK     => CLK,
           CE      => CE,
           R       => rx_uart_rdy,
           DIVIDER => baud_clk_ticks,
           SCLK_EN => state_machine_EN
           );
           
  -- this process enables the state machine if rx_uart_rdy is low
  -- by pulling down rx_uart_rdy_hold
  enable_sm : process(CLK, CE, state_machine_EN, rx_uart_rdy)
    
  begin
    if rising_edge(CLK) and CE = '0' then
        if rx_uart_rdy_hold = '0' and state_machine_EN = '0' then
            -- reset rx_uart_rdy_hold
            rx_uart_rdy_hold <= '1';
            
        elsif rx_uart_rdy = '0' then
            -- set rx_uart_rdy_hold
            rx_uart_rdy_hold <= '0';            
        end if;
    end if;
  end process enable_sm;         
  
  --- parameter interpretation and calculation state machine ---
  
  process(CLK, state_machine_EN, rx_uart_rdy_hold)
    -- counts the bytes in the buffer
    variable byte_count : natural range 0 to INSTRUCTIONSIZE - 1 := 0;
    -- duty_cycle (initialized on 50%):
    variable dc  : unsigned(7 downto 0) := x"80";
    -- product from which the threshhold is calculated
    variable th_product : std_logic_vector(clk_width + dc'length - 1 downto 0) := (others => '0');
 
  begin
    if rising_edge(CLK) and state_machine_EN = '0' then
        case state is
        when IDLE =>
            if rx_uart_rdy_hold = '0' then
                state <= SHIFT;
            end if;
        when SHIFT =>
            ibuff <= ibuff(ARGMSB downto 0) & uart_data_out;
            -- if three bytes were read 
            if byte_count = INSTRUCTIONSIZE - 1 then
                byte_count := 0;
                state <= INTERPRETE;
            else
                byte_count := byte_count + 1;
                state <= IDLE;
            end if;           
        when INTERPRETE =>
              -- this case statement checks for the first byte in the buffer which
              -- defines the instruction that has to be executed
              -- when storring the data from argument every non relevant bit is ignored
              case ibuff(INSTMSB downto INSTLSB) is
                  when SETCYCTICKS =>
                    cts   <= ibuff(clk_width - 1 downto 0);
                    state <= CALCULATE;
                  when SETHIGH =>
                    hs   <= ibuff(data_width - 1 downto 0);
                    state <= CALCULATE;
                  when SETLOW =>
                    ls   <= ibuff(data_width - 1 downto 0);
                    state <= CALCULATE;
                  when SETDUTYCYCLE =>
                    dc  := unsigned(ibuff(7 downto 0));
                    state <= CALCULATE;
                  when SETWVFRM =>
                    wvs  <= ibuff(1 downto 0);
                    state <= CALCULATE;
                  when SETDIR =>
                    dirs <= ibuff(0);
                    state <= CALCULATE;
                  when others =>
                    -- reset byte count if instruction is not interpretable
                    state <= IDLE;
                    byte_count := 0;
                    ibuff <= (others => '1');
              end case;
        when CALCULATE =>
            -- if cyc_ticks are less than minimum cyc ticks set to minimum cyc ticks
            if cts < std_logic_vector(to_unsigned(min_cyc_ticks, clk_width)) then
                cts <= std_logic_vector(to_unsigned(min_cyc_ticks, clk_width));
            end if;
            -- turn the dutycycle into clock ticks threshhold
            -- since dc's maximum is 255 the calculation goes (cts * dc) / 2^8
            th_product := std_logic_vector(shift_right(unsigned(cts) * unsigned(dc), 8));
            ths <= th_product(clk_width - 1 downto 0);
            state <= OUTPUT;
        when OUTPUT =>
            -- transfers the internal signals to the outputs
            cyc_ticks <= cts;
            thresh    <= ths;
            high      <= hs;
            low       <= ls;
            waveform  <= wvs;
            direction <= dirs;
            
            state     <= IDLE;
            
        when others =>
            
        end case;
    end if;
  end process;

end Behavioral;
