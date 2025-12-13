-- HSPG.vhd  – hobby-servo pulse generator (71 kHz tick, 7-bit command)
-- drives 0.60 ms … 2.40 ms in ~14 µs steps  (0-127 → 43-170 ticks)

library IEEE;
use     IEEE.std_logic_1164.all;
use     IEEE.std_logic_unsigned.all;   -- keeps original style

entity HSPG is
    port (
        CS       : in  std_logic;
        IO_WRITE : in  std_logic;
        IO_DATA  : in  std_logic_vector(15 downto 0);
        CLOCK    : in  std_logic;      -- 71 kHz (14 µs)
        RESETN   : in  std_logic;
        PULSE    : out std_logic;
        OVER     : out std_logic
    );
end HSPG;

architecture a of HSPG is
    -- *** constants recomputed for 14.0 µs tick ************************
    constant MIN_TICKS : std_logic_vector(15 downto 0) := x"002B"; -- 43
    constant MAX_TICKS : std_logic_vector(15 downto 0) := x"00AA"; -- 170
    constant FRAME_TOP : std_logic_vector(15 downto 0) := x"0593"; -- 1427
    --------------------------------------------------------------------
    signal next_cmd : std_logic_vector(15 downto 0) := MIN_TICKS;
    signal cmd      : std_logic_vector(15 downto 0) := MIN_TICKS;
    signal count    : std_logic_vector(15 downto 0) := (others=>'0');
begin
    --------------------------------------------------------------------
    -- 1.  I/O write  (asynchronous to servo frame) --------------------
    --------------------------------------------------------------------
    process (RESETN, CS)
    begin
        if RESETN = '0' then
            next_cmd <= MIN_TICKS;
            OVER     <= '0';

        elsif IO_WRITE = '1' and rising_edge(CS) then
            -- clamp USER value to 0-127  (0x7F)
            if IO_DATA > x"007F" then
                next_cmd <= MAX_TICKS;
                OVER     <= '1';
            else
                next_cmd <= MIN_TICKS +
                             ("000000000"  & IO_DATA(6 downto 0)); -- zero-extend 7 bits
                OVER     <= '0';
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- 2.  Frame timer & pulse generator  (glitch-free) ----------------
    --------------------------------------------------------------------
    process (CLOCK, RESETN)
    begin
        if RESETN = '0' then
            count <= (others=>'0');
            cmd   <= MIN_TICKS;
            PULSE <= '0';

        elsif rising_edge(CLOCK) then
				count <= count + 1;
            -- new 20-ms frame (71 kHz × 1428 ticks ≈ 20 ms)
            if count = FRAME_TOP then
                count <= (others=>'0');
                cmd   <= next_cmd;         -- latch new width
                PULSE <= '1';              -- start pulse

            -- end of HIGH portion
            elsif count = cmd then
                PULSE <= '0';
                count <= count + 1;
            end if;
        end if;
    end process;
end a;
