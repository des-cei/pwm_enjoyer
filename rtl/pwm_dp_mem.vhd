-- Módulo: pwm_dp_mem
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 01.07.2025

-- NOTE: Se supone que siempre se escribirán estados con valores no nulos

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
        G_DATA_W    : natural   := 32;    -- Ancho de datos en bits (G_STATE_MAX_L2)
        G_ADDR_W    : natural   := 32;    -- Ancho de direcciones en bits (G_MEM_SIZE_MAX_L2)
        G_MEM_DEPTH : natural   := 4096;  -- Profundidad de memoria (G_MEM_SIZE_MAX_N)
        G_MEM_MODE  : string    := "LOW_LATENCY";   -- Modo de funcionamiento de la memoria ("HIGH_PERFORMANCE"/"LOW_LATENCY")
        G_RST_POL   : std_logic := '1'
    );
    port (
        CLK_I               : in std_logic;     
        RST_I               : in std_logic;
        EN_I                : in std_logic;                                     -- Mismo enable que el contador
        ---------
        UNLOCKED_I          : in std_logic;                                     -- Bloqueo de escritura de configuración
        WR_EN_I             : in std_logic;                                     -- Enable de escritura
        WR_ADDR_I           : in std_logic_vector((G_ADDR_W - 1) downto 0);     -- Dirección de escritura
        WR_DATA_I           : in std_logic_vector((G_DATA_W - 1) downto 0);     -- Dato de escritura
        ---------
        SWITCH_MEM_I        : in std_logic;                                     -- Señal de actualización de memoria
        LAST_CYC_I          : in std_logic;                                     -- Indicador de último valor del último ciclo
        N_ADDR_I            : in std_logic_vector((G_ADDR_W - 1) downto 0);     -- Número de estados del PWM
        RD_ADDR_I           : in std_logic_vector((G_ADDR_W - 1) downto 0);     -- Dirección de lectura
        RD_DATA_O           : out std_logic_vector((G_DATA_W - 1) downto 0);    -- Dato de lectura
        RD_DATA_NEXT_O      : out std_logic_vector((G_DATA_W - 1) downto 0);    -- Siguiente dato de lectura
        RD_DATA_NEXT_2_O    : out std_logic_vector((G_DATA_W - 1) downto 0);    -- Siguiente 2 dato de lectura
        EARLY_SW_O          : out std_logic                                     -- Protección ante SWITCH sin configuración previa
    );
end entity pwm_dp_mem;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of pwm_dp_mem is

    -- Forzar el mantener la jerarquía para optimizar los recursos
    attribute keep_hierarchy : string;
    attribute keep_hierarchy of beh : architecture is "yes";

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    component bram_dualport is
        generic (
            -- Data width (in bits)
            C_DATA_WIDTH    : integer := 32;
            -- Address width (in bits)
            C_ADDR_WIDTH    : integer := 32;
            -- Memory depth (# positions)
            C_MEM_DEPTH     : integer := 4096;
            -- Memory configuration mode
            C_MEM_MODE      : string := "LOW_LATENCY" -- Memory performance configuration mode ("HIGH_PERFORMANCE", "LOW_LATENCY")
        );
        port (
            -- Port A --
            clk_a           : in  std_logic;
            rst_a           : in  std_logic;
            en_a            : in  std_logic;
            we_a            : in  std_logic;
            addr_a          : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
            din_a           : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
            dout_a          : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
            -- Port B --
            clk_b           : in  std_logic;
            rst_b           : in  std_logic;
            en_b            : in  std_logic;
            we_b            : in  std_logic;
            addr_b          : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
            din_b           : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
            dout_b          : out std_logic_vector(C_DATA_WIDTH-1 downto 0)
        );
    end component bram_dualport;

    -------------------------------------------------
    -- Tipos
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Constantes
    -------------------------------------------------
    constant C_CEROS_ADDR   : std_logic_vector((WR_ADDR_I'length - 1) downto 0) := (others => '0');
    constant C_UNO_ADDR     : std_logic_vector((WR_ADDR_I'length - 1) downto 0) := (0 => '1', others => '0');
    constant C_UNO          : std_logic_vector((WR_DATA_I'length - 1) downto 0) := (0 => '1', others => '0');

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
    signal s_rd_data_next_2 : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0');
    signal s_switch_mem     : std_logic;
    signal s_last_cyc       : std_logic;
    signal r_n_addr         : std_logic_vector((N_ADDR_I'length - 1) downto 0);

    -- Port map bram_dp
    signal s_rst            : std_logic;    -- bram_dualport resetea a '1'
    signal s_en_a           : std_logic; 
    signal s_en_b           : std_logic; 
    signal s_we_a           : std_logic;
    signal s_we_b           : std_logic;
    signal s_addr_a         : std_logic_vector(G_ADDR_W downto 0);  -- (*)
    signal s_addr_b         : std_logic_vector(G_ADDR_W downto 0);  -- (*)
    signal s_addr_a_next    : std_logic_vector(G_ADDR_W downto 0);  -- (*)
    signal s_addr_b_next    : std_logic_vector(G_ADDR_W downto 0);  -- (*)
    signal s_addr_a_next_2  : std_logic_vector(G_ADDR_W downto 0);  -- (*)
    signal s_addr_b_next_2  : std_logic_vector(G_ADDR_W downto 0);  -- (*)
    signal s_din_a          : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0');
    signal s_din_b          : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0');
    signal s_dout_a         : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0');
    signal s_dout_b         : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0');
    signal s_dout_a_next    : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0');
    signal s_dout_b_next    : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0');
    signal s_dout_a_next_2  : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0');
    signal s_dout_b_next_2  : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0');

    -- Señales de control
    signal r_wr_port            : std_logic;
    signal r_prev_last_state    : std_logic_vector(WR_DATA_I'high downto 0);
    signal r_prev_last2_state   : std_logic_vector(WR_DATA_I'high downto 0);
    signal r_next_first_state   : std_logic_vector(WR_DATA_I'high downto 0);
    signal r_next_first2_state  : std_logic_vector(WR_DATA_I'high downto 0);
    signal r_tmp_last_value     : std_logic_vector(WR_DATA_I'high downto 0);
    signal r_tmp_last2_value    : std_logic_vector(WR_DATA_I'high downto 0);

    -- Señales registradas
    signal s_wr_addr_d1     : std_logic_vector(WR_ADDR_I'high downto 0);
    signal s_rd_addr_d1     : std_logic_vector(WR_ADDR_I'high downto 0);
    signal s_switch_mem_d1  : std_logic;
    signal s_last_cyc_d1    : std_logic;

    -- Enable del contador
    signal s_en_cnt     : std_logic;
    signal s_en_cnt_d1  : std_logic;

    -- Protección
    signal r_early_sw   : std_logic;

    -------------------------------------------------
    -- ILA
    -------------------------------------------------
    attribute MARK_DEBUG : string;
    attribute MARK_DEBUG of s_wr_en             : signal is "true";
    attribute MARK_DEBUG of s_wr_addr           : signal is "true";
    attribute MARK_DEBUG of s_wr_data           : signal is "true";
    attribute MARK_DEBUG of s_rd_addr           : signal is "true";
    attribute MARK_DEBUG of s_rd_data           : signal is "true";
    attribute MARK_DEBUG of s_rd_data_next      : signal is "true";
    attribute MARK_DEBUG of s_rd_data_next_2    : signal is "true";
    attribute MARK_DEBUG of s_switch_mem        : signal is "true";
    attribute MARK_DEBUG of s_last_cyc          : signal is "true";
    attribute MARK_DEBUG of r_n_addr            : signal is "true";
    attribute MARK_DEBUG of s_rst               : signal is "true";
    attribute MARK_DEBUG of s_en_a              : signal is "true";
    attribute MARK_DEBUG of s_en_b              : signal is "true";
    attribute MARK_DEBUG of s_we_a              : signal is "true";
    attribute MARK_DEBUG of s_we_b              : signal is "true";
    attribute MARK_DEBUG of s_addr_a            : signal is "true";
    attribute MARK_DEBUG of s_addr_b            : signal is "true";
    attribute MARK_DEBUG of s_addr_a_next       : signal is "true";
    attribute MARK_DEBUG of s_addr_b_next       : signal is "true";
    attribute MARK_DEBUG of s_addr_a_next_2     : signal is "true";
    attribute MARK_DEBUG of s_addr_b_next_2     : signal is "true";
    attribute MARK_DEBUG of s_din_a             : signal is "true";
    attribute MARK_DEBUG of s_din_b             : signal is "true";
    attribute MARK_DEBUG of s_dout_a            : signal is "true";
    attribute MARK_DEBUG of s_dout_b            : signal is "true";
    attribute MARK_DEBUG of s_dout_a_next       : signal is "true";
    attribute MARK_DEBUG of s_dout_b_next       : signal is "true";
    attribute MARK_DEBUG of s_dout_a_next_2     : signal is "true";
    attribute MARK_DEBUG of s_dout_b_next_2     : signal is "true";
    attribute MARK_DEBUG of r_wr_port           : signal is "true";
    attribute MARK_DEBUG of r_prev_last_state   : signal is "true";
    attribute MARK_DEBUG of r_prev_last2_state  : signal is "true";
    attribute MARK_DEBUG of r_next_first_state  : signal is "true";
    attribute MARK_DEBUG of r_next_first2_state : signal is "true";
    attribute MARK_DEBUG of r_tmp_last_value    : signal is "true";
    attribute MARK_DEBUG of r_tmp_last2_value   : signal is "true";
    attribute MARK_DEBUG of s_wr_addr_d1        : signal is "true";
    attribute MARK_DEBUG of s_rd_addr_d1        : signal is "true";
    attribute MARK_DEBUG of s_switch_mem_d1     : signal is "true";
    attribute MARK_DEBUG of s_last_cyc_d1       : signal is "true";
    attribute MARK_DEBUG of s_en_cnt            : signal is "true";
    attribute MARK_DEBUG of s_en_cnt_d1         : signal is "true";
    attribute MARK_DEBUG of r_early_sw          : signal is "true";

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    bram_dp : component bram_dualport
        generic map (
            C_DATA_WIDTH    => G_DATA_W,
            C_ADDR_WIDTH    => G_ADDR_W + 1,   -- (*) Un bit más para doblar la profundidad de memoria
            C_MEM_DEPTH     => 2*G_MEM_DEPTH,  -- (**) El doble de la profundidad, para aprovechar el dual port 
            C_MEM_MODE      => G_MEM_MODE
        )
        port map (
            -- Port A --
            CLK_A           => CLK_I,
            RST_A           => RST_I,
            EN_A            => s_en_a,
            WE_A            => s_we_a,
            ADDR_A          => s_addr_a,
            DIN_A           => s_din_a,
            DOUT_A          => s_dout_a,
            -- Port B --
            CLK_B           => CLK_I,
            RST_B           => RST_I,
            EN_B            => s_en_b,
            WE_B            => s_we_b,
            ADDR_B          => s_addr_b,
            DIN_B           => s_din_b,
            DOUT_B          => s_dout_b
        );

    bram_dp_next : component bram_dualport
        generic map (
            C_DATA_WIDTH    => G_DATA_W,
            C_ADDR_WIDTH    => G_ADDR_W + 1,   -- (*) Un bit más para doblar la profundidad de memoria
            C_MEM_DEPTH     => 2*G_MEM_DEPTH,  -- (**) El doble de la profundidad, para aprovechar el dual port 
            C_MEM_MODE      => G_MEM_MODE
        )
        port map (
            -- Port A --
            CLK_A           => CLK_I,
            RST_A           => RST_I,
            EN_A            => s_en_a,
            WE_A            => s_we_a,
            ADDR_A          => s_addr_a_next,
            DIN_A           => s_din_a,
            DOUT_A          => s_dout_a_next,
            -- Port B --
            CLK_B           => CLK_I,
            RST_B           => RST_I,
            EN_B            => s_en_b,
            WE_B            => s_we_b,
            ADDR_B          => s_addr_b_next,
            DIN_B           => s_din_b,
            DOUT_B          => s_dout_b_next
        );

    bram_dp_next_2 : component bram_dualport
        generic map (
            C_DATA_WIDTH    => G_DATA_W,
            C_ADDR_WIDTH    => G_ADDR_W + 1,   -- (*) Un bit más para doblar la profundidad de memoria
            C_MEM_DEPTH     => 2*G_MEM_DEPTH,  -- (**) El doble de la profundidad, para aprovechar el dual port 
            C_MEM_MODE      => G_MEM_MODE
        )
        port map (
            -- Port A --
            CLK_A           => CLK_I,
            RST_A           => RST_I,
            EN_A            => s_en_a,
            WE_A            => s_we_a,
            ADDR_A          => s_addr_a_next_2,
            DIN_A           => s_din_a,
            DOUT_A          => s_dout_a_next_2,
            -- Port B --
            CLK_B           => CLK_I,
            RST_B           => RST_I,
            EN_B            => s_en_b,
            WE_B            => s_we_b,
            ADDR_B          => s_addr_b_next_2,
            DIN_B           => s_din_b,
            DOUT_B          => s_dout_b_next_2
        );

    -------------------------------------------------
    -- Combinacionales
    -------------------------------------------------
    -- Entradas y salidas
    s_en_cnt            <= EN_I;
    s_switch_mem        <= SWITCH_MEM_I;
    s_last_cyc          <= LAST_CYC_I;
    s_wr_en             <= WR_EN_I      when (UNLOCKED_I = '1') else '0';
    s_wr_addr           <= WR_ADDR_I    when (UNLOCKED_I = '1') else (others => '0');
    s_wr_data           <= WR_DATA_I    when (UNLOCKED_I = '1') else (others => '0');
    s_rd_addr           <= RD_ADDR_I;
    RD_DATA_O           <= s_rd_data;
    RD_DATA_NEXT_O      <= s_rd_data_next;
    RD_DATA_NEXT_2_O    <= s_rd_data_next_2;
    EARLY_SW_O          <= r_early_sw;

    -- Reset de bram_dualport
    s_rst <= RST_I when (G_RST_POL = '1') else (not RST_I);

    -- Enables generales
    s_en_a <= '1';
    s_en_b <= '1';

    -- Enables de escritura (por defecto escribe en A y lee de B)
    s_we_a <= '1' when (r_wr_port = '0') else '0';
    s_we_b <= not s_we_a;

    -- Dirección de escritura/lectura de la primera BRAM
    s_addr_a <= resize_offset(WR_ADDR_I, 0)                         when (s_we_a = '1') else resize_offset(RD_ADDR_I, 0);
    s_addr_b <= resize_offset(WR_ADDR_I, G_MEM_DEPTH)               when (s_we_b = '1') else resize_offset(RD_ADDR_I, G_MEM_DEPTH);

    -- Dirección de escritura/lectura de la segunda BRAM: escritura igual que la primera, lectura + 1
    s_addr_a_next <=    s_addr_a                                    when (s_we_a = '1') else 
                        resize_offset(C_CEROS_ADDR, 0)              when (unsigned(RD_ADDR_I) = (unsigned(r_n_addr) - 1)) else
                        resize_offset(std_logic_vector(unsigned(RD_ADDR_I) + 1), 0);
    s_addr_b_next <=    s_addr_b                                    when (s_we_b = '1') else 
                        resize_offset(C_CEROS_ADDR, G_MEM_DEPTH)    when (unsigned(RD_ADDR_I) = (unsigned(r_n_addr) - 1)) else
                        resize_offset(std_logic_vector(unsigned(RD_ADDR_I) + 1), G_MEM_DEPTH);

    -- Dirección de escritura/lectura de la tercera BRAM: escritura igual que la primera, lectura + 2
    s_addr_a_next_2 <=  s_addr_a                                    when (s_we_a = '1') else 
                        resize_offset(C_CEROS_ADDR, 0)              when (unsigned(RD_ADDR_I) = (unsigned(r_n_addr) - 2)) else
                        resize_offset(C_UNO_ADDR, 0)                when (unsigned(RD_ADDR_I) = (unsigned(r_n_addr) - 1)) else
                        resize_offset(std_logic_vector(unsigned(RD_ADDR_I) + 2), 0);
    s_addr_b_next_2 <=  s_addr_b                                    when (s_we_b = '1') else 
                        resize_offset(C_CEROS_ADDR, G_MEM_DEPTH)    when (unsigned(RD_ADDR_I) = (unsigned(r_n_addr) - 2)) else
                        resize_offset(C_UNO_ADDR, G_MEM_DEPTH)      when (unsigned(RD_ADDR_I) = (unsigned(r_n_addr) - 1)) else
                        resize_offset(std_logic_vector(unsigned(RD_ADDR_I) + 2), G_MEM_DEPTH);

    -- Dato de escritura
    s_din_a <= WR_DATA_I when (s_wr_en = '1') and (s_we_a = '1') and (s_wr_addr /= s_wr_addr_d1);
    s_din_b <= WR_DATA_I when (s_wr_en = '1') and (s_we_b = '1') and (s_wr_addr /= s_wr_addr_d1);

    -- Dato de lectura actual
    --  SWITCH_D1 = 1   -> Último de la configuración previa
    --  SWITCH = 1      -> Último de la configuración previa o penúltimo si el úlitimo es '1'
    --  Resto de casos  -> Según BRAM
    s_rd_data <=    r_prev_last_state   when (s_switch_mem_d1 = '1') else
                    r_prev_last_state   when ((s_switch_mem = '1') and (r_prev_last_state /= C_UNO)) else
                    r_prev_last2_state  when ((s_switch_mem = '1') and (r_prev_last_state = C_UNO)) else
                    s_dout_a            when (s_we_a = '0') else s_dout_b;

    -- Dato de lectura anticipado
    --  SWITCH_D1 = 1   -> Primer valor de la siguiente config.
    --  SWITCH = 1      -> 1 si el último es '1', primer valor si la siguiente config. si no
    --  Desde RD_ADDR_D1 = ÚLTIMA DIRECCIÓN hasta antes de SWITCH = 1 
    --                  -> Según BRAM si el último es '1', primer valor de la siguiente config.
    s_rd_data_next <=   r_next_first_state  when (s_en_cnt = '0') else
                        r_next_first_state  when (s_switch_mem_d1 = '1') else
                        r_next_first_state  when ((s_switch_mem = '1') and (r_prev_last_state /= C_UNO)) else
                        C_UNO               when ((s_switch_mem = '1') and (r_prev_last_state = C_UNO)) else
                        r_next_first_state  when ((s_rd_addr_d1 = std_logic_vector(unsigned(r_n_addr) - 1) and (s_last_cyc_d1 = '1') and (r_prev_last_state /= C_UNO))) else
                        s_dout_a_next       when (s_we_a = '0') else s_dout_b_next;

    -- 2º Dato de lectura anticipado
    s_rd_data_next_2 <= r_next_first2_state when (s_en_cnt = '0') else
                        r_next_first2_state when (s_switch_mem_d1 = '1') else
                        r_next_first2_state when ((s_switch_mem = '1') and (r_prev_last_state /= C_UNO)) else
                        r_next_first_state  when ((s_switch_mem = '1') and (r_prev_last_state = C_UNO)) else
                        r_next_first2_state when ((s_rd_addr_d1 = std_logic_vector(unsigned(r_n_addr) - 1) and (s_last_cyc_d1 = '1') and (r_prev_last_state /= C_UNO))) else
                        r_next_first_state  when ((s_rd_addr_d1 = std_logic_vector(unsigned(r_n_addr) - 2) and (s_last_cyc_d1 = '1'))) else
                        s_dout_a_next_2     when (s_we_a = '0') else s_dout_b_next_2;

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- Switch de puertos
    P_SWITCH : process (RST_I, SWITCH_MEM_I)
    begin
        if (RST_I = G_RST_POL) then
            r_wr_port   <= '0';
            r_n_addr    <= (others => '0');
        elsif rising_edge(SWITCH_MEM_I) then
            r_wr_port   <= not r_wr_port;
            r_n_addr    <= N_ADDR_I;
        end if;
    end process P_SWITCH;

    -- Registro de señales
    P_EDGE : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            s_wr_addr_d1    <= (others => '1');
            s_rd_addr_d1    <= (others => '0');
            s_switch_mem_d1 <= '0';
            s_last_cyc_d1   <= '0';
            s_en_cnt_d1     <= '0';
        elsif rising_edge(CLK_I) then
            if (s_wr_en = '1') then
                s_wr_addr_d1    <= s_wr_addr;
            end if;
            s_rd_addr_d1    <= s_rd_addr;
            s_switch_mem_d1 <= s_switch_mem;
            s_last_cyc_d1   <= s_last_cyc;
            s_en_cnt_d1     <= s_en_cnt;
        end if;
    end process P_EDGE;

    -- Registro de los valores críticos de la siguiente configuración
    P_NEXT_CONF : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_prev_last_state   <= (others => '0');
            r_prev_last2_state  <= (others => '0');
            r_next_first_state  <= s_dout_a_next;
            r_next_first2_state <= s_dout_a_next_2;
            r_tmp_last_value    <= (others => '0');
            r_tmp_last2_value   <= (others => '0');
        elsif rising_edge(CLK_I) then
            if ((s_en_cnt = '0') and (s_en_cnt_d1 = '1')) then
                r_prev_last_state   <= (others => '0');
                r_prev_last2_state  <= (others => '0');
                r_next_first_state  <= (others => '0');
                r_next_first2_state <= (others => '0');
                r_tmp_last_value    <= (others => '0');
                r_tmp_last2_value   <= (others => '0');
            elsif (s_wr_en = '1') then
                r_tmp_last_value    <= s_wr_data;
                r_tmp_last2_value   <= r_tmp_last_value;

                if (s_wr_addr = C_CEROS_ADDR) then
                    r_next_first_state  <= s_wr_data;
                    if (r_early_sw = '1') then
                        if (to_integer(unsigned(r_n_addr)) > 1) then
                            r_prev_last_state   <= r_tmp_last_value;
                            r_prev_last2_state  <= r_tmp_last2_value;
                        else
                            r_prev_last_state   <= (others => '0');
                            r_prev_last2_state  <= (others => '0');
                        end if;    
                    -- Hay una configuración pendiente de switch que se debe sobreescribir
                    else
                        r_prev_last_state   <= (others => '0');
                        r_prev_last2_state  <= (others => '0');
                    end if;
                else
                    if (to_integer(unsigned(s_wr_addr)) = 1) then
                        r_next_first2_state <= s_wr_data;
                    end if;
                end if;
            end if;
        end if;
    end process P_NEXT_CONF;

    -- Aviso de update sin configuración inmediatamente anterior
    P_EARLY_SW : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_early_sw <= '1';
        elsif rising_edge(CLK_I) then
            if (s_switch_mem = '1') then
                r_early_sw <= '1';
            elsif (s_wr_en = '1') then
                r_early_sw <= '0';
            end if;
        end if;
    end process P_EARLY_SW;

end architecture beh;
