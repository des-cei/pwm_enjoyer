-- Módulo: state_ctrlr
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 23.06.2025

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
entity state_ctrlr is
    generic (
        G_RST_POL   : std_logic := '1'
    );
    port (
        CLK_I           : in std_logic;
        RST_I           : in std_logic;                                             -- Reset asíncrono
        EN_I            : in std_logic;                                             -- Señal de habilitación
        N_ADDR_I        : in std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);    -- Número de estados del PWM
        N_TOT_CYC_I     : in std_logic_vector((G_PERIOD_MAX_L2 - 1) downto 0);      -- Número total de ciclos que dura la configuración
        UPD_MEM_I       : in std_logic;                                             -- Señal de actualización de memoria
        CNT_END_I       : in std_logic;                                             -- Fin de estado
        NEXT_CONFIG_I   : in mem;                                                   -- Siguiente configuración
        RD_ADDR_O       : out std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);   -- Dirección de memoria (estado) a leer
        EN_CNT_O        : out std_logic;                                            -- Habiltador del contador
        SWITCH_MEM_O    : out std_logic;                                            -- Cambio de memoria
        LAST_CYC_O      : out std_logic;                                            -- Inidicador de último ciclo
        EN_WR_CONFIG_O  : out std_logic                                             -- Bloqueo de escritura de configuración
    );
end entity state_ctrlr;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of state_ctrlr is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Tipos
    -------------------------------------------------
    type FSM is (S_IDLE, S_INIT_CYC, S_NEXT_CYC, S_LAST_CYC, S_FIRST_CYC);

    -------------------------------------------------
    -- Constantes
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Entradas y salidas
    signal r_n_addr         : unsigned((G_MEM_SIZE_MAX_L2 - 1) downto 0);
    signal r_n_tot_cyc      : unsigned((G_PERIOD_MAX_L2 - 1) downto 0);
    signal r_rd_addr        : unsigned((G_MEM_SIZE_MAX_L2 - 1) downto 0);
    signal r_en_cnt         : std_logic;
    signal r_next_config    : mem;
    signal r_switch_mem     : std_logic;
    signal r_last_cyc       : std_logic;
    signal r_en_wr_config   : std_logic;

    -- Otras
    signal r_state          : FSM;
    signal r_update_flag    : std_logic;    -- Para activar SWITCH_MEM al final del siguiente ciclo
    signal r_cnt_end_shift  : std_logic_vector((G_PERIOD_MAX_N - 1) downto 0);
    signal s_cnt_end        : std_logic;
    signal s_cnt_end_sw     : std_logic;

    -- Contadores del first cycle
    signal r_cnt_fc_pulse   : unsigned((G_STATE_MAX_L2 - 1) downto 0);

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Combinacionales
    -------------------------------------------------
    -- Salidas
    RD_ADDR_O       <= std_logic_vector(r_rd_addr);
    EN_CNT_O        <= r_en_cnt;
    SWITCH_MEM_O    <= r_switch_mem;
    LAST_CYC_O      <= r_last_cyc;
    EN_WR_CONFIG_O  <= r_en_wr_config;

    -- Cambios de estado
    s_cnt_end       <= r_cnt_end_shift(to_integer(unsigned(r_n_tot_cyc)) - 2) when (r_n_tot_cyc > 2) else '0';
    s_cnt_end_sw    <= r_cnt_end_shift(to_integer(unsigned(r_n_tot_cyc)) - 3) when (r_n_tot_cyc > 2) else '0';

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- Registro de entradas
    P_REG : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_n_addr        <= (others => '0');
            r_n_tot_cyc     <= (others => '0');
            r_cnt_end_shift <= (others => '0');
        elsif rising_edge(CLK_I) then
            if (EN_I = '1') then
                if (r_switch_mem = '1') then
                    r_n_addr    <= unsigned(N_ADDR_I);
                    r_n_tot_cyc <= unsigned(N_TOT_CYC_I);
                end if;
                r_cnt_end_shift <= r_cnt_end_shift((r_cnt_end_shift'high - 1) downto 0) & CNT_END_I;
            end if;
        end if;
    end process P_REG;       

    -- Petición de actualización
    P_UPDATE : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_update_flag   <= '0';
            r_next_config   <= (others => (others => '0'));   
        elsif rising_edge(CLK_I) then
            if (EN_I = '1') then
                -- Llega petición de cambio de memoria
                if (UPD_MEM_I = '1') then
                    r_update_flag   <= '1';
                    r_next_config   <= NEXT_CONFIG_I;
                -- Se produce el cambio de memoria
                elsif (r_switch_mem = '1') then
                    r_update_flag <= '0';
                end if;
            else
                r_update_flag   <= '0';
            end if;
        end if;
    end process P_UPDATE;

    -- FSM
    P_FSM : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_state         <= S_IDLE;
            r_last_cyc      <= '0';
            r_switch_mem    <= '0';
            r_rd_addr       <= (others => '0');
            r_cnt_fc_pulse  <= (others => '0');
            r_en_cnt        <= '0';
            r_en_wr_config  <= '1';
        elsif rising_edge(CLK_I) then

            case r_state is

                -- No hay enable
                when S_IDLE =>
                    r_last_cyc      <= '0';
                    r_switch_mem    <= '0';
                    r_rd_addr       <= (others => '0');
                    r_en_wr_config  <= '1';
                    if (EN_I = '1') then
                        r_state     <= S_INIT_CYC;
                        r_last_cyc  <= '1';
                        r_en_cnt    <= '1';
                    end if;

                -- Estado inicial: la configuración no ha entrado todavía en la memoria
                when S_INIT_CYC =>
                    r_en_wr_config              <= '1';
                    if (EN_I = '1') then
                        if (r_update_flag = '1') then
                            r_last_cyc          <= '1';
                            r_switch_mem        <= '1';
                            r_rd_addr           <= (others => '0');
                            if (r_switch_mem = '1') then
                                r_state         <= S_FIRST_CYC;
                                r_last_cyc      <= '0';
                                r_switch_mem    <= '0';
                            end if;
                        end if;
                    else
                        r_state                 <= S_IDLE;
                        r_last_cyc              <= '0';
                        r_switch_mem            <= '0';
                        r_rd_addr               <= (others => '0');
                        r_en_cnt                <= '0';
                    end if;

                -- Estado normal, itera entre la configuración actual
                when S_NEXT_CYC =>
                    r_en_wr_config              <= '1';
                    if (EN_I = '1') then
                        r_last_cyc              <= '0';
                        r_switch_mem            <= '0';
                        if (s_cnt_end = '1') then
                            -- Normal
                            if (r_rd_addr < (r_n_addr - 1)) then
                                r_rd_addr       <= r_rd_addr + 1;
                            else
                                r_rd_addr       <= (others => '0');
                                -- Hay petición de update
                                if (r_update_flag = '1') then
                                    r_state     <= S_LAST_CYC;
                                    r_last_cyc  <= '1';
                                end if;
                            end if;
                        end if;
                    else
                        r_state                 <= S_IDLE;
                        r_last_cyc              <= '0';
                        r_switch_mem            <= '0';
                        r_rd_addr               <= (others => '0');
                        r_en_cnt                <= '0';
                    end if;

                -- Último estado antes de cambiar la memoria
                when S_LAST_CYC =>
                    r_en_wr_config              <= '0';
                    if (EN_I = '1') then
                        r_last_cyc              <= '1';
                        -- Normal
                        if (s_cnt_end = '1') then
                            if (r_rd_addr < (r_n_addr - 1)) then
                                r_rd_addr       <= r_rd_addr + 1;
                            else
                                r_rd_addr       <= (others => '0');
                            end if;
                        end if;
                        -- Switch activado
                        if (r_switch_mem = '1') then
                            r_state             <= S_FIRST_CYC;
                            r_last_cyc          <= '0';
                            r_switch_mem        <= '0';
                            r_rd_addr           <= (others => '0');
                        -- Activa el switch
                        elsif (s_cnt_end_sw = '1') then
                            -- Si el último estado dura 1 ciclo
                            if ((r_rd_addr = (r_n_addr - 2)) and (s_cnt_end = '1')) then
                                r_switch_mem    <= '1';
                            -- Si el último estado dura más de un ciclo
                            elsif (r_rd_addr = (r_n_addr - 1)) then
                                r_switch_mem    <= '1';
                            else
                                r_switch_mem    <= '0';
                            end if;
                        end if;
                    else
                        r_state                 <= S_IDLE;
                        r_last_cyc              <= '0';
                        r_switch_mem            <= '0';
                        r_rd_addr               <= (others => '0');
                        r_en_cnt                <= '0';
                    end if;

                -- Primer estado tras cambiar la memoria. Necesita modificar RD_ADDR independientemte de CNT_END_I dado el desfase de r_cnt_end.
                -- Durante este ciclo no debe entrar ninguna nueva escritura de programación
                when S_FIRST_CYC =>
                    r_en_wr_config          <= '0';
                    if (EN_I = '1') then
                        r_last_cyc          <= '0';
                        r_switch_mem        <= '0';
                        if (r_cnt_fc_pulse < (unsigned(r_next_config(to_integer(r_rd_addr))) - 1)) then
                            r_cnt_fc_pulse  <= r_cnt_fc_pulse + 1;
                        else
                            r_cnt_fc_pulse  <= (others => '0');
                            if (r_rd_addr < (r_n_addr - 1)) then
                                r_rd_addr   <= r_rd_addr + 1;
                            else
                                r_rd_addr   <= (others => '0');
                                r_state     <= S_NEXT_CYC;
                            end if;
                        end if;
                    else
                        r_state             <= S_IDLE;
                        r_last_cyc          <= '0';
                        r_switch_mem        <= '0';
                        r_rd_addr           <= (others => '0');
                        r_en_cnt            <= '0';
                    end if;

                when others =>
                    r_state         <= S_IDLE;
                    r_last_cyc      <= '0';
                    r_switch_mem    <= '0';
                    r_rd_addr       <= (others => '0');
                    r_en_cnt        <= '0';
                    r_en_wr_config  <= '0';

            end case;
        end if;
    end process P_FSM;

end architecture beh;