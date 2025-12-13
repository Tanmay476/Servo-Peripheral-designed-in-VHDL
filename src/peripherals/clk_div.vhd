-- clk_div.vhd
-- Divides 12-MHz input clock to several lower frequencies.
-- 100 kHz, 71.006 kHz (odd divisor 169), 10 kHz, 100 Hz, 32 Hz, 10 Hz, 4 Hz
-- Kevin Johnson, March 2018  |  71-kHz patch 2025

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity clk_div is
    port (
        clock_12MHz  : in  std_logic;
        clock_100kHz : out std_logic;
        clock_71kHz  : out std_logic;
        clock_10kHz  : out std_logic;
        clock_100Hz  : out std_logic;
        clock_32Hz   : out std_logic;
        clock_10Hz   : out std_logic;
        clock_4Hz    : out std_logic
    );
end clk_div;

architecture a of clk_div is
    --------------------------------------------------------------------
    constant clk_freq  : integer := 12_000_000;          -- 12-MHz crystal
    constant half_freq : integer := clk_freq/2;          -- 6  MHz

    --------------------------------------------------------------------
    -- Counters --------------------------------------------------------
    --------------------------------------------------------------------
    signal count_100kHz : integer range 0 to half_freq/100_000;

    -- *** 71-kHz odd-div 169 : full-period counter + phase bit
    constant DIV_71k    : integer := 169;
    signal count_71kHz  : integer range 0 to DIV_71k-1;
    signal phase_71kHz  : std_logic;                     -- 0 = first 85 ticks

    signal count_10kHz  : integer range 0 to half_freq/10_000;
    signal count_100Hz  : integer range 0 to half_freq/100;
    signal count_32Hz   : integer range 0 to half_freq/32;
    signal count_10Hz   : integer range 0 to half_freq/10;
    signal count_4Hz    : integer range 0 to half_freq/4;

    --------------------------------------------------------------------
    -- Internal flip-flops that drive outputs --------------------------
    --------------------------------------------------------------------
    signal clock_100kHz_int : std_logic;
    signal clock_71kHz_int  : std_logic;
    signal clock_10kHz_int  : std_logic;
    signal clock_100Hz_int  : std_logic;
    signal clock_32Hz_int   : std_logic;
    signal clock_10Hz_int   : std_logic;
    signal clock_4Hz_int    : std_logic;
begin
    --------------------------------------------------------------------
    process
    begin
        wait until rising_edge(clock_12MHz);

        -- expose internal clocks
        clock_100kHz <= clock_100kHz_int;
        clock_71kHz  <= clock_71kHz_int;
        clock_10kHz  <= clock_10kHz_int;
        clock_100Hz  <= clock_100Hz_int;
        clock_32Hz   <= clock_32Hz_int;
        clock_10Hz   <= clock_10Hz_int;
        clock_4Hz    <= clock_4Hz_int;

        ----------------------------------------------------------------
        -- 100 kHz  (toggle every 60 cycles)
        ----------------------------------------------------------------
        if count_100kHz < (half_freq/100_000 - 1) then
            count_100kHz <= count_100kHz + 1;
        else
            count_100kHz     <= 0;
            clock_100kHz_int <= not clock_100kHz_int;
        end if;

        ----------------------------------------------------------------
        -- 71.006 kHz  – odd divisor 169  (85 ticks HIGH, 84 ticks LOW)
        ----------------------------------------------------------------
        if phase_71kHz = '0' then                  -- first 85 input ticks
            if count_71kHz < 84 then
                count_71kHz <= count_71kHz + 1;
            else
                count_71kHz     <= 0;
                phase_71kHz     <= '1';
                clock_71kHz_int <= not clock_71kHz_int;
            end if;
        else                                       -- next 84 input ticks
            if count_71kHz < 83 then
                count_71kHz <= count_71kHz + 1;
            else
                count_71kHz     <= 0;
                phase_71kHz     <= '0';
                clock_71kHz_int <= not clock_71kHz_int;
            end if;
        end if;

        ----------------------------------------------------------------
        -- 10 kHz
        ----------------------------------------------------------------
        if count_10kHz < (half_freq/10_000 - 1) then
            count_10kHz <= count_10kHz + 1;
        else
            count_10kHz     <= 0;
            clock_10kHz_int <= not clock_10kHz_int;
        end if;

        ----------------------------------------------------------------
        -- 100 Hz
        ----------------------------------------------------------------
        if count_100Hz < (half_freq/100 - 1) then
            count_100Hz <= count_100Hz + 1;
        else
            count_100Hz     <= 0;
            clock_100Hz_int <= not clock_100Hz_int;
        end if;

        ----------------------------------------------------------------
        -- 32 Hz
        ----------------------------------------------------------------
        if count_32Hz < (half_freq/32 - 1) then
            count_32Hz <= count_32Hz + 1;
        else
            count_32Hz     <= 0;
            clock_32Hz_int <= not clock_32Hz_int;
        end if;

        ----------------------------------------------------------------
        -- 10 Hz
        ----------------------------------------------------------------
        if count_10Hz < (half_freq/10 - 1) then
            count_10Hz <= count_10Hz + 1;
        else
            count_10Hz     <= 0;
            clock_10Hz_int <= not clock_10Hz_int;
        end if;

        ----------------------------------------------------------------
        -- 4 Hz
        ----------------------------------------------------------------
        if count_4Hz < (half_freq/4 - 1) then
            count_4Hz <= count_4Hz + 1;
        else
            count_4Hz     <= 0;
            clock_4Hz_int <= not clock_4Hz_int;
        end if;
    end process;
end a;
