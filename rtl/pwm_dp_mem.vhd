-- Módulo: pwm_dp_mem
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 01.07.2025
-- NOTE: Se supone que siempre se escribirán estados con valores no nulos.
--  La escritura de datos nuevos se tiene que realizar tras SWITCH_MEM = '1' y antes de LAST_CYC = '1', evitando flancos clave.

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
        CLK_I           : in std_logic;     
        RST_I           : in std_logic;
        ---------
        EN_WR_CONFIG_I  : in std_logic;                                     -- Bloqueo de escritura de configuración
        WR_EN_I         : in std_logic;                                     -- Enable de escritura
        WR_ADDR_I       : in std_logic_vector((G_ADDR_W - 1) downto 0);     -- Dirección de escritura
        WR_DATA_I       : in std_logic_vector((G_DATA_W - 1) downto 0);     -- Dato de escritura
        ---------
        SWITCH_MEM_I    : in std_logic;                                     -- Señal de actualización de memoria
        LAST_CYC_I      : in std_logic;                                     -- Indicador de último valor del último ciclo
        N_ADDR_I        : in std_logic_vector((G_ADDR_W - 1) downto 0);     -- Número de estados del PWM
        RD_ADDR_I       : in std_logic_vector((G_ADDR_W - 1) downto 0);     -- Dirección de lectura
        RD_DATA_O       : out std_logic_vector((G_DATA_W - 1) downto 0);    -- Dato de lectura
        RD_DATA_NEXT_O  : out std_logic_vector((G_DATA_W - 1) downto 0);    -- Siguiente dato de lectura
        NEXT_CONFIG_O   : out mem                                           -- Siguiente configuración
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
            n_addr      : in  std_logic_vector(C_ADDR_WIDTH-2 downto 0);
            -- Port A --
            clk_a       : in  std_logic;
            rst_a       : in  std_logic;
            en_a        : in  std_logic;
            we_a        : in  std_logic;
            addr_a      : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
            din_a       : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
            dout_a      : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
            dout_a_next : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
            -- Port B --
            clk_b       : in  std_logic;
            rst_b       : in  std_logic;
            en_b        : in  std_logic;
            we_b        : in  std_logic;
            addr_b      : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
            din_b       : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
            dout_b      : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
            dout_b_next : out std_logic_vector(C_DATA_WIDTH-1 downto 0)
        );
    end component bram_dualport;

    -------------------------------------------------
    -- Tipos
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Constantes
    -------------------------------------------------
    constant C_ONE  : std_logic_vector((G_DATA_W - 1) downto 0) := std_logic_vector(to_unsigned(1, G_DATA_W));

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Port map top
    signal s_wr_en          : std_logic;
    signal s_wr_addr        : std_logic_vector((G_ADDR_W - 1) downto 0);
    signal s_wr_data        : std_logic_vector((G_DATA_W - 1) downto 0);
    signal s_rd_addr        : std_logic_vector((G_ADDR_W - 1) downto 0);
    signal s_rd_data        : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0');
    signal s_rd_data_next   : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0');
    signal s_switch_mem     : std_logic;
    signal s_last_cyc       : std_logic;
    signal r_n_addr         : std_logic_vector((G_ADDR_W - 1) downto 0);

    -- Port map bram_dp
    signal s_rst            : std_logic;    -- bram_dualport resetea a '1'
    signal s_en_a           : std_logic; 
    signal s_en_b           : std_logic; 
    signal s_we_a           : std_logic;
    signal s_we_b           : std_logic;
    signal s_addr_a         : std_logic_vector(G_ADDR_W downto 0);  -- (*)
    signal s_addr_b         : std_logic_vector(G_ADDR_W downto 0);  -- (*)
    signal s_din_a          : std_logic_vector((G_DATA_W - 1) downto 0);
    signal s_din_b          : std_logic_vector((G_DATA_W - 1) downto 0);
    signal s_dout_a         : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0');
    signal s_dout_b         : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0');
    signal s_dout_a_next    : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0');
    signal s_dout_b_next    : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0');

    -- Señales de control
    signal r_wr_port    : std_logic;

    -- Señales registradas
    signal s_rd_addr_d1     : std_logic_vector((G_ADDR_W - 1) downto 0);
    signal s_wr_addr_d1     : std_logic_vector((G_ADDR_W - 1) downto 0);
    signal s_wr_en_d1       : std_logic;
    signal s_switch_mem_d1  : std_logic;
    signal s_last_cyc_d1    : std_logic;
    signal r_n_addr_d1      : std_logic_vector((G_ADDR_W - 1) downto 0);

    -- Otras
    signal r_next_1_value   : std_logic_vector((G_DATA_W - 1) downto 0);    -- Primer valor de la configuración siguiente
    signal r_next_2_value   : std_logic_vector((G_DATA_W - 1) downto 0);    -- Segundo valor de la configuración siguiente
    signal r_act_N_value    : std_logic_vector((G_DATA_W - 1) downto 0);    -- Último valor de la configuración actual
    signal r_next_N_value   : std_logic_vector((G_DATA_W - 1) downto 0);    -- Último valor de la configuración siguiente
    signal r_first_cyc      : std_logic;                                    -- Primer ciclo
    signal r_last_addr      : std_logic;                                    -- Última dirección del ciclo
    
    signal s_rd_data_0      : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0'); -- RD_DATA cuando la config no termina en 1
    signal s_rd_data_1      : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0'); -- RD_DATA cuando la config termina en 1
    signal s_rd_data_next_0 : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0'); -- RD_DATA-NEXT cuando la config no termina en 1
    signal s_rd_data_next_1 : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0'); -- RD_DATA-NEXT cuando la config termina en 1

    signal r_next_config    : mem;

begin

    -- Modo de funcionamiento: cada vez que se escribe en la memoria lo hace en una mitad de la misma.
    --  Cuando llega SWITCH_MEM, cambia los punteros a cada mitad de la memoria, alternando los puertos
    --  de lectura y escritura.

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    bram_dp : component bram_dualport
        generic map (
            C_DATA_WIDTH    => G_DATA_W,
            C_ADDR_WIDTH    => G_ADDR_W + 1,   -- (*) Un bit más para doblar la profundidad de memoria
            C_MEM_DEPTH     => 2*G_MEM_DEPTH,  -- (**) El doble de la profundidad, para aprovechar el dual port 
            C_MEM_MODE      => "LOW_LATENCY"
        )
        port map (
            N_ADDR      => r_n_addr,
            -- Port A --
            CLK_A       => CLK_I,
            RST_A       => RST_I,
            EN_A        => s_en_a,
            WE_A        => s_we_a,
            ADDR_A      => s_addr_a,
            DIN_A       => s_din_a,
            DOUT_A      => s_dout_a,
            DOUT_A_NEXT => s_dout_a_next,
            -- Port B --
            CLK_B       => CLK_I,
            RST_B       => RST_I,
            EN_B        => s_en_b,
            WE_B        => s_we_b,
            ADDR_B      => s_addr_b,
            DIN_B       => s_din_b,
            DOUT_B      => s_dout_b,
            DOUT_B_NEXT => s_dout_b_next
        );

    -------------------------------------------------
    -- Combinacionales
    -------------------------------------------------
    -- Entradas y salidas
    s_switch_mem    <= SWITCH_MEM_I;
    s_last_cyc      <= LAST_CYC_I;
    s_wr_en         <= WR_EN_I      when (EN_WR_CONFIG_I = '1') else '0';
    s_wr_addr       <= WR_ADDR_I    when (EN_WR_CONFIG_I = '1') else (others => '0');
    s_wr_data       <= WR_DATA_I    when (EN_WR_CONFIG_I = '1') else (others => '0');
    s_rd_addr       <= RD_ADDR_I;
    RD_DATA_O       <= s_rd_data;
    RD_DATA_NEXT_O  <= s_rd_data_next;
    NEXT_CONFIG_O   <= r_next_config;

    -- Reset de bram_dualport
    s_rst <= RST_I when (G_RST_POL = '1') else (not RST_I);

    -- Switch de puertos (r_wr_port = '0' => Escribe en A, lee en B)
    s_we_a      <= s_wr_en when (r_wr_port = '0') else '0';
    s_we_b      <= s_wr_en when (r_wr_port = '1') else '0';

    s_en_a      <= '1' when ((s_we_a = '1') or ((r_wr_port = '1') and (s_rd_addr /= s_rd_addr_d1))) else '0';
    s_en_b      <= '1' when ((s_we_b = '1') or ((r_wr_port = '0') and (s_rd_addr /= s_rd_addr_d1))) else '0';

    s_addr_a    <= ('0' & s_wr_addr) when (r_wr_port = '0') else ('0' & s_rd_addr);
    s_addr_b    <= std_logic_vector(unsigned(s_wr_addr) + to_unsigned(G_MEM_SIZE_MAX_N, G_ADDR_W + 1)) when (r_wr_port = '1') else 
                   std_logic_vector(unsigned(s_rd_addr) + to_unsigned(G_MEM_SIZE_MAX_N, G_ADDR_W + 1));
    
    s_din_a     <= s_wr_data when (r_wr_port = '0') else (others => '0');
    s_din_b     <= s_wr_data when (r_wr_port = '1') else (others => '0');
    
    -- Datos de salida cuando el último valor de la configuración no es '1'
    s_rd_data_0     <=  r_next_1_value when ((r_first_cyc = '1') and (s_last_cyc_d1 = '0')) else        -- Primer valor tras inicio
                        r_act_N_value when (r_first_cyc = '1') else                                     -- Valor durante el inicio
                        r_act_N_value when ((s_last_cyc = '0') and (s_last_cyc_d1 = '1')) else          -- Primer valor tras switch
                        s_dout_a when ((s_switch_mem = '1') and (r_wr_port = '0')) else                 -- Valor durante el switch
                        s_dout_b when ((s_switch_mem = '1') and (r_wr_port = '1')) else                 -- Valor durante el switch   
                        s_dout_b when (r_wr_port = '0') else s_dout_a;                                  -- Valores operativos

    s_rd_data_next_0    <=  r_next_2_value when ((r_first_cyc = '1') and (s_last_cyc_d1 = '0')) else    -- Primer valor tras inicio
                            r_next_1_value when (r_first_cyc = '1') else                                -- Valor durante el inicio
                            r_next_1_value when ((r_last_addr = '1') and (s_switch_mem = '0')) else     -- Valor durante el último estado antes del switch
                            r_next_1_value when (s_switch_mem = '1') else                               -- Valor durante el switch
                            r_next_1_value when ((s_last_cyc = '0') and (s_last_cyc_d1 = '1')) else     -- Primer valor tras switch
                            s_dout_b_next when (r_wr_port = '0') else s_dout_a_next;                    -- Valores operativos

    -- Datos de salida cuando el último valor de la configuración es un '1'
    s_rd_data_1     <=  r_next_1_value when ((r_first_cyc = '1') and (s_last_cyc_d1 = '0')) else        -- Primer valor tras inicio
                        r_act_N_value when (r_first_cyc = '1') else                                     -- Valor durante el inicio
                        C_ONE when ((s_last_cyc = '0') and (s_last_cyc_d1 = '1')) else                  -- Primer valor tras switch
                        s_dout_a when ((s_switch_mem = '1') and (r_wr_port = '0')) else                 -- Valor durante el switch
                        s_dout_b when ((s_switch_mem = '1') and (r_wr_port = '1')) else                 -- Valor durante el switch
                        s_dout_b when (r_wr_port = '0') else s_dout_a;                                  -- Valores operativos

    s_rd_data_next_1    <=  r_next_2_value when ((r_first_cyc = '1') and (s_last_cyc_d1 = '0')) else    -- Primer valor tras inicio
                            r_next_1_value when (r_first_cyc = '1') else                                -- Valor durante el inicio
                            r_next_1_value when ((s_last_cyc = '0') and (s_last_cyc_d1 = '1')) else     -- Primer valor tras switch
                            s_dout_a_next when ((s_switch_mem = '1') and (r_wr_port = '0')) else        -- Valor durante el switch
                            s_dout_b_next when ((s_switch_mem = '1') and (r_wr_port = '1')) else        -- Valor durante el switch
                            s_dout_b_next when (r_wr_port = '0') else s_dout_a_next;                    -- Valores operativos

    with to_integer(unsigned(r_act_N_value)) select
        s_rd_data   <=  s_rd_data_1 when 1,
                        s_rd_data_0 when others;

    with to_integer(unsigned(r_act_N_value)) select
        s_rd_data_next  <=  s_rd_data_next_1 when 1,
                            s_rd_data_next_0 when others;

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- Señales registradas
    P_EDGE : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            s_switch_mem_d1 <= '0';
            s_rd_addr_d1    <= (others => '0');
            s_wr_addr_d1    <= (others => '0');
            s_wr_en_d1      <= '0';
            s_last_cyc_d1   <= '0';
            r_n_addr_d1     <= (others => '0');
        elsif rising_edge(CLK_I) then
            s_switch_mem_d1 <= s_switch_mem;
            s_rd_addr_d1    <= s_rd_addr;
            s_wr_addr_d1    <= s_wr_addr;
            s_wr_en_d1      <= s_wr_en;
            s_last_cyc_d1   <= s_last_cyc;
            r_n_addr_d1     <= r_n_addr;
        end if;
    end process P_EDGE;

    -- SWITCH_MEM Switch: conmuta las tablas ante un flanco en SWITCH_MEM
    P_SWITCH : process (RST_I, SWITCH_MEM_I)
    begin
        if (RST_I = G_RST_POL) then
            r_wr_port <= '0';
            r_n_addr  <= (others => '0');
        elsif rising_edge(SWITCH_MEM_I) then
            r_wr_port <= not r_wr_port;
            r_n_addr  <= N_ADDR_I;
        end if;
    end process P_SWITCH;

    -- Primeros y últimos valores de las siguientes configuraciones
    P_NEXT_VAL : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_next_1_value  <= (others => '0');
            r_next_2_value  <= (others => '0');
            r_act_N_value   <= (others => '0');
            r_next_N_value  <= (others => '0');
            r_first_cyc     <= '1';
            r_last_addr     <= '0'; 
        elsif rising_edge(CLK_I) then
            if ((s_wr_en = '1') and (s_wr_en_d1 = '0')) then
                r_next_1_value  <= WR_DATA_I;
            elsif ((s_wr_en = '1') and (to_integer(unsigned(s_wr_addr)) = 1)) then
                r_next_2_value  <= WR_DATA_I;
            elsif ((s_wr_en = '0') and (s_wr_en_d1 = '1')) then
                r_next_N_value  <= WR_DATA_I;
            elsif ((s_switch_mem = '0') and (s_switch_mem_d1 = '1')) then
                r_act_N_value   <= r_next_N_value;
            end if;

            if (to_integer(unsigned(s_rd_addr)) /= 0) then
                r_first_cyc     <= '0';
            end if;

            r_last_addr         <= '0';
            if ((s_rd_addr = std_logic_vector(unsigned(r_n_addr_d1) - 1)) and (s_last_cyc = '1') and (s_switch_mem = '0')) then
                r_last_addr     <= '1';
            end if;
        end if;
    end process P_NEXT_VAL;

    -- Registro de la siguiente configuración para pasarla como entrada a STATE_CTRLR
    P_NEXT_CONFIG : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_next_config <= (others => (others => '0'));
        elsif rising_edge(CLK_I) then
            if (s_wr_en = '1') then
                if (s_wr_en_d1 = '0') then
                    r_next_config <= (others => (others => '0'));
                end if;
                r_next_config(to_integer(unsigned(WR_ADDR_I))) <= WR_DATA_I;
            end if;
        end if;
    end process P_NEXT_CONFIG;


end architecture beh;