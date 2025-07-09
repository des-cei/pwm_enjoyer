-- Módulo: bram_dualport test bench
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 07.07.2025

-----------------------------------------------------------
-- Librerías
-----------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.my_pkg.all;

-----------------------------------------------------------
-- Entidad
-----------------------------------------------------------
entity bram_dualport_tb is
end entity bram_dualport_tb;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of bram_dualport_tb is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    component bram_dualport is
        generic (
            C_DATA_WIDTH    : integer   := 32;    -- Ancho de datos en bits (G_STATE_MAX_L2)
            C_ADDR_WIDTH    : integer   := 32;    -- Ancho de direcciones en bits (G_MEM_SIZE_MAX_L2)
            C_MEM_DEPTH     : integer   := 4096;  -- Profundidad de memoria (G_MEM_SIZE_MAX_N)
            G_MEM_MODE      : string    := "LOW_LATENCY"    -- Modo de funcionamiento de la memoria ("HIGH_PERFORMANCE"/"LOW_LATENCY")
        );
        port (
            -- Port A --
            CLK_A_I     : in  std_logic;
            RST_A_I     : in  std_logic;
            EN_A_I      : in  std_logic;
            WE_A_I      : in  std_logic;
            ADDR_A_I    : in  std_logic_vector((C_ADDR_WIDTH - 1) downto 0);
            DIN_A_I     : in  std_logic_vector((C_DATA_WIDTH - 1) downto 0);
            DOUT_A_O    : out std_logic_vector((C_DATA_WIDTH - 1) downto 0);
            -- Port B --
            CLK_B_I     : in  std_logic;
            RST_B_I     : in  std_logic;
            EN_B_I      : in  std_logic;
            WE_B_I      : in  std_logic;
            ADDR_B_I    : in  std_logic_vector((C_ADDR_WIDTH - 1) downto 0);
            DIN_B_I     : in  std_logic_vector((C_DATA_WIDTH - 1) downto 0);
            DOUT_B_O    : out std_logic_vector((C_DATA_WIDTH - 1) downto 0)
        );
    end component bram_dualport;

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Simulación
    constant clk_period : time := (10**9/G_SYS_CLK_HZ) * 1 ns;
    signal sim          : std_logic_vector(47 downto 0) := (others => '0'); -- 6 caracteres ASCII

    -- Port map
    signal CLK_A_I     : std_logic;
    signal RST_A_I     : std_logic;
    signal EN_A_I      : std_logic;
    signal WE_A_I      : std_logic;
    signal ADDR_A_I    : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);
    signal DIN_A_I     : std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);
    signal DOUT_A_O    : std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);
    signal CLK_B_I     : std_logic;
    signal RST_B_I     : std_logic;
    signal EN_B_I      : std_logic;
    signal WE_B_I      : std_logic;
    signal ADDR_B_I    : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);
    signal DIN_B_I     : std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);
    signal DOUT_B_O    : std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);

    -------------------------------------------------
    -- Funciones y procedimientos
    -------------------------------------------------
    -- Wait
    procedure p_wait (
        constant period : in time;
        signal clk      : in std_logic
    ) is
    begin
        wait for 0.99*period;
        wait until rising_edge(clk);
    end procedure p_wait;

    -- Reset
    procedure reset (
        signal rst_a    : out std_logic;
        signal rst_b    : out std_logic;
        signal en_a     : out std_logic;
        signal en_b     : out std_logic;
        signal we_a     : out std_logic;
        signal we_b     : out std_logic;
        signal addr_a   : out std_logic_vector;
        signal addr_b   : out std_logic_vector;
        signal din_a    : out std_logic_vector;
        signal din_b    : out std_logic_vector
    ) is
    begin
        rst_a   <= '1';
        rst_b   <= '1';
        en_a    <= '0';
        en_b    <= '0';
        we_a    <= '0';
        we_b    <= '0';
        addr_a  <= (others => '0');
        addr_b  <= (others => '0');
        din_a   <= (others => '0');
        din_b   <= (others => '0');
        p_wait(clk_period, CLK_A_I);
        rst_a   <= '0';
        rst_b   <= '0';
    end procedure reset;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    uut : component bram_dualport
        generic map (
            C_DATA_WIDTH    => G_STATE_MAX_L2,
            C_ADDR_WIDTH    => G_MEM_SIZE_MAX_L2,
            C_MEM_DEPTH     => G_MEM_SIZE_MAX_N,
            G_MEM_MODE      => "LOW_LATENCY"
        )
        port map (
            CLK_A_I     => CLK_A_I,
            RST_A_I     => RST_A_I,
            EN_A_I      => EN_A_I,
            WE_A_I      => WE_A_I,
            ADDR_A_I    => ADDR_A_I,
            DIN_A_I     => DIN_A_I,
            DOUT_A_O    => DOUT_A_O,
            CLK_B_I     => CLK_B_I,
            RST_B_I     => RST_B_I,
            EN_B_I      => EN_B_I,
            WE_B_I      => WE_B_I,
            ADDR_B_I    => ADDR_B_I,
            DIN_B_I     => DIN_B_I,
            DOUT_B_O    => DOUT_B_O
        );

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- Reloj
    P_CLK_A : process
    begin
        CLK_A_I <= '0';
        wait for clk_period/2;
        CLK_A_I <= '1';
        wait for clk_period/2;
    end process;

    P_CLK_B : process
    begin
        CLK_B_I <= '0';
        wait until rising_edge(CLK_A_I);
        wait for clk_period/4;
        CLK_B_I <= '1';
        wait for clk_period/2;
    end process;

    -------------------------------------------------
    -- Estímulos
    -------------------------------------------------
    P_STIM : process
    begin

        assert FALSE report "Start simulation" severity note;

        ------------------------------
        -- Init
        ------------------------------
        sim <= x"49_4E_49_54_20_20";
        reset(RST_A_I, RST_B_I, EN_A_I, EN_B_I, WE_A_I, WE_B_I, ADDR_A_I, ADDR_B_I, DIN_A_I, DIN_B_I);
        p_wait(10*clk_period, CLK_A_I);

        ------------------------------
        -- Escritura en A (del 1 al 4)
        ------------------------------
        sim <= x"57_52_20_41_20_20";
        for i in 0 to 3 loop
            EN_A_I      <= '1';
            WE_A_I      <= '1';
            ADDR_A_I    <= std_logic_vector(to_unsigned(i, ADDR_A_I'length));
            DIN_A_I     <= std_logic_vector(to_unsigned(i + 1, DIN_A_I'length));
            p_wait(clk_period, CLK_A_I);
        end loop;

        EN_A_I      <= '0';
        WE_A_I      <= '0';

        ------------------------------
        -- Escritura en B (del 5 al 9)
        ------------------------------
        wait until rising_edge(CLK_B_I);

        sim <= x"57_52_20_42_20_20";
        for i in 0 to 3 loop
            EN_B_I      <= '1';
            WE_B_I      <= '1';
            ADDR_B_I    <= std_logic_vector(to_unsigned(i + 4, ADDR_B_I'length));
            DIN_B_I     <= std_logic_vector(to_unsigned(i + 1, DIN_B_I'length));
            p_wait(clk_period, CLK_B_I);
        end loop;

        EN_B_I      <= '0';
        WE_B_I      <= '0';

        ------------------------------
        -- STOP
        ------------------------------
        sim <= x"53_54_4F_50_20_20";
        reset(RST_A_I, RST_B_I, EN_A_I, EN_B_I, WE_A_I, WE_B_I, ADDR_A_I, ADDR_B_I, DIN_A_I, DIN_B_I);
        p_wait(10*clk_period, CLK_A_I);

        ------------------------------
        -- Lectura desde A
        ------------------------------
        sim <= x"52_45_41_44_20_41";
        for i in 0 to 3 loop
            EN_A_I      <= '1';
            ADDR_A_I    <= std_logic_vector(to_unsigned(i, ADDR_A_I'length));
            p_wait(clk_period, CLK_A_I);
        end loop;

        ------------------------------
        -- Lectura desde B
        ------------------------------
        wait until rising_edge(CLK_B_I);

        sim <= x"52_45_41_44_20_42";
        for i in 0 to 3 loop
            EN_B_I      <= '1';
            ADDR_B_I    <= std_logic_vector(to_unsigned(i + 4, ADDR_B_I'length));
            p_wait(clk_period, CLK_B_I);
        end loop;

        ------------------------------
        -- End
        ------------------------------
        sim <= x"45_4E_44_49_4E_47";
        p_wait(10*clk_period, CLK_A_I);

        assert FALSE report "End simulation" severity failure;

    end process;

end architecture beh;