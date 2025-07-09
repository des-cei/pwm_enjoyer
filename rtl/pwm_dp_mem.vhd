-- Módulo: pwm_dp_mem
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 01.07.2025

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
entity pwm_dp_mem is
    generic (
        G_DATA_W    : integer   := 32;    -- Ancho de datos en bits (G_STATE_MAX_L2)
        G_ADDR_W    : integer   := 32;    -- Ancho de direcciones en bits (G_MEM_SIZE_MAX_L2)
        G_MEM_DEPTH : integer   := 4096;  -- Profundidad de memoria (G_MEM_SIZE_MAX_N)
        G_MEM_MODE  : string    := "LOW_LATENCY";   -- Modo de funcionamiento de la memoria ("HIGH_PERFORMANCE"/"LOW_LATENCY")
        G_RST_POL   : std_logic := '1'
    );
    port (
        CLK_I       : in std_logic;     
        RST_I       : in std_logic;
        WR_EN_I     : in std_logic;                                 -- Enable de escritura
        WR_ADDR_I   : in std_logic_vector((G_ADDR_W - 1) downto 0); -- Dirección de escritura
        WR_DATA_I   : in std_logic_vector((G_DATA_W - 1) downto 0); -- Dato de escritura
        CYC_SYNC_I  : in std_logic;                                 -- Señal de actualización de memoria
        RD_ADDR_I   : in std_logic_vector((G_ADDR_W - 1) downto 0); -- Dirección de lectura
        RD_DATA_O   : out std_logic_vector((G_DATA_W - 1) downto 0) -- Dato de lectura
    );
end entity pwm_dp_mem;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of pwm_dp_mem is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    component bram_dualport is
        generic (
            -- Data width (in bits)
            C_DATA_WIDTH : integer := 32;
            -- Address width (in bits)
            C_ADDR_WIDTH : integer := 32;
            -- Memory depth (# positions)
            C_MEM_DEPTH  : integer := 4096;
            -- Memory configuration mode
            C_MEM_MODE   : string := "LOW_LATENCY" -- Memory performance configuration mode ("HIGH_PERFORMANCE", "LOW_LATENCY")
        );
        port (
            -- Port A --
            clk_a  : in  std_logic;
            rst_a  : in  std_logic;
            en_a   : in  std_logic;
            we_a   : in  std_logic;
            addr_a : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
            din_a  : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
            dout_a : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
            -- Port B --
            clk_b  : in  std_logic;
            rst_b  : in  std_logic;
            en_b   : in  std_logic;
            we_b   : in  std_logic;
            addr_b : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
            din_b  : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
            dout_b : out std_logic_vector(C_DATA_WIDTH-1 downto 0)
        );
    end component bram_dualport;

    -------------------------------------------------
    -- Tipos
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Constantes
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Port map top
    signal s_wr_en      : std_logic;
    signal s_wr_addr    : std_logic_vector((G_ADDR_W - 1) downto 0);
    signal s_wr_data    : std_logic_vector((G_DATA_W - 1) downto 0);
    signal s_rd_addr    : std_logic_vector((G_ADDR_W - 1) downto 0);
    signal s_rd_data    : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0');
    signal s_cyc_sync   : std_logic;

    -- Port map bram_dp
    signal s_en_a   : std_logic; 
    signal s_en_b   : std_logic; 
    signal s_we_a   : std_logic;
    signal s_we_b   : std_logic;
    signal s_addr_a : std_logic_vector(G_ADDR_W downto 0);  -- (*)
    signal s_addr_b : std_logic_vector(G_ADDR_W downto 0);  -- (*)
    signal s_din_a  : std_logic_vector((G_DATA_W - 1) downto 0);
    signal s_din_b  : std_logic_vector((G_DATA_W - 1) downto 0);
    signal s_dout_a : std_logic_vector((G_DATA_W - 1) downto 0);
    signal s_dout_b : std_logic_vector((G_DATA_W - 1) downto 0);

    -- Señales registradas
    signal s_rd_addr_d1     : std_logic_vector((G_ADDR_W - 1) downto 0);
    signal s_wr_addr_d1     : std_logic_vector((G_ADDR_W - 1) downto 0);
    signal s_cyc_sync_d1    : std_logic;

    -- Señales de control
    signal r_wr_port    : std_logic;
    signal r_en_a       : std_logic;
    signal r_en_b       : std_logic;

begin

    -- Modo de funcionamiento: cada vez que se escribe en la memoria lo hace en una mitad de la misma.
    --  Cuando llega CYC_SYNC, cambia los punteros a cada mitad de la memoria, alternando los puertos
    --  de lectura y escritura.

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    bram_dp : component bram_dualport
        generic map (
            C_DATA_WIDTH => G_STATE_MAX_L2,
            C_ADDR_WIDTH => G_MEM_SIZE_MAX_L2 + 1,  -- (*) Un bit más para doblar la profundidad de memoria
            C_MEM_DEPTH  => 2*G_MEM_SIZE_MAX_N,     -- (**) El doble de la profundidad, para aprovechar el dual port 
            C_MEM_MODE   => "LOW_LATENCY"
        )
        port map (
            -- Port A --
            CLK_A   => CLK_I,
            RST_A   => RST_I,
            EN_A    => s_en_a,
            WE_A    => s_we_a,
            ADDR_A  => s_addr_a,
            DIN_A   => s_din_a,
            DOUT_A  => s_dout_a,
            -- Port B --
            CLK_B   => CLK_I,
            RST_B   => RST_I,
            EN_B    => s_en_b,
            WE_B    => s_we_b,
            ADDR_B  => s_addr_b,
            DIN_B   => s_din_b,
            DOUT_B  => s_dout_b
        );

    -------------------------------------------------
    -- Combinacionales
    -------------------------------------------------
    -- Entradas y salidas
    s_cyc_sync  <= CYC_SYNC_I;
    s_wr_en     <= WR_EN_I;
    s_wr_addr   <= WR_ADDR_I;
    s_wr_data   <= WR_DATA_I;
    s_rd_addr   <= RD_ADDR_I;
    RD_DATA_O   <= s_rd_data;

    -- Switch de puertos (r_wr_port = '0' => Escribe en A, lee en B)
        -- (**) Port A direcciona las direcciones desde 0 hasta (C_MEM_DEPTH - 1),
        -- (**) Port B direcciona las direcciones desde C_MEM_DEPTH hasta (2*C_MEM_DEPTH - 1) 
    s_we_a      <= s_wr_en when (r_wr_port = '0') else '0';
    s_we_b      <= s_wr_en when (r_wr_port = '1') else '0';

    -- s_en_a      <= '1' when (r_wr_port = '1') and (s_wr_addr /= s_wr_addr_d1) else
    --                '1' when (r_wr_port = '0') and (s_rd_addr /= s_rd_addr_d1) else
    --                '0';
    -- s_en_b      <= '1' when (r_wr_port = '0') and (s_wr_addr /= s_wr_addr_d1) else
    --                '1' when (r_wr_port = '1') and (s_rd_addr /= s_rd_addr_d1) else
    --                '0';

    s_en_a      <= '1' when ((s_we_a = '1') or ((r_wr_port = '1') and (s_rd_addr /= s_rd_addr_d1))) else '0';
    s_en_b      <= '1' when ((s_we_b = '1') or ((r_wr_port = '0') and (s_rd_addr /= s_rd_addr_d1))) else '0';

    -- s_addr_a    <= ('0' & s_wr_addr) when (r_wr_port = '1') else ('0' & s_rd_addr);
    -- s_addr_b    <= std_logic_vector(unsigned(s_wr_addr) + to_unsigned(G_MEM_DEPTH, G_ADDR_W + 1)) when (r_wr_port = '0')
    --                 else std_logic_vector(unsigned(s_rd_addr) + to_unsigned(G_MEM_DEPTH, G_ADDR_W + 1));
    
    s_addr_a    <= ('0' & s_wr_addr) when (r_wr_port = '0') else ('0' & s_rd_addr);
    s_addr_b    <= std_logic_vector(unsigned(s_wr_addr) + to_unsigned(G_MEM_SIZE_MAX_N, G_ADDR_W + 1)) when (r_wr_port = '1') else 
                   std_logic_vector(unsigned(s_rd_addr) + to_unsigned(G_MEM_SIZE_MAX_N, G_ADDR_W + 1));
    
    s_din_a     <= s_wr_data when (r_wr_port = '0') else (others => '0');
    s_din_b     <= s_wr_data when (r_wr_port = '1') else (others => '0');
    
    s_rd_data   <= s_dout_b when (r_wr_port = '0') else s_dout_a;

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- Señales registradas
    P_EDGE : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            s_cyc_sync_d1   <= '0';
            s_rd_addr_d1    <= (others => '0');
            s_wr_addr_d1    <= (others => '0');
        elsif rising_edge(CLK_I) then
            s_cyc_sync_d1   <= s_cyc_sync;
            s_rd_addr_d1    <= s_rd_addr;
            s_wr_addr_d1    <= s_wr_addr;
        end if;
    end process P_EDGE;

    -- CYC_SYNC Switch
    P_SWITCH : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_wr_port <= '0';
        elsif rising_edge(CLK_I) then
            if ((s_cyc_sync = '1') and (s_cyc_sync_d1 = '0')) then
                r_wr_port <= not r_wr_port;
            end if;
        end if;
    end process P_SWITCH;

end architecture beh;