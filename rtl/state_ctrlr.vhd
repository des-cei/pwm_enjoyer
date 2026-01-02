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
        G_RST_POL           : std_logic := '1';
        G_MEM_SIZE_MAX_L2   : natural := 32;    -- Tamaño del vector del número máximo de estados
        G_PERIOD_MAX_L2     : natural := 32     -- Tamaño del vector del número máximo de periodos de reloj de una configuración
    );
    port (
        CLK_I           : in std_logic;
        RST_I           : in std_logic;                                             -- Reset asíncrono
        EN_I            : in std_logic;                                             -- Señal de habilitación
        N_ADDR_I        : in std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);    -- Número de estados del PWM
        N_TOT_CYC_I     : in std_logic_vector((G_PERIOD_MAX_L2 - 1) downto 0);      -- Número total de ciclos que dura la configuración
        UPD_MEM_I       : in std_logic;                                             -- Señal de actualización de memoria
        CNT_END_I       : in std_logic;                                             -- Fin de estado
        CNT_END_PRE_I   : in std_logic;                                             -- Fin de estado anticipado
        EARLY_SW_I      : in std_logic;                                             -- Protección ante SWITCH sin configuración previa
        RD_ADDR_O       : out std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);   -- Dirección de memoria (estado) a leer
        EN_CNT_O        : out std_logic;                                            -- Habiltador del contador
        SWITCH_MEM_O    : out std_logic;                                            -- Cambio de memoria
        LAST_CYC_O      : out std_logic;                                            -- Indicador de último ciclo
        UNLOCKED_O      : out std_logic;                                            -- Bloqueo de escritura de configuración
        STATUS_O        : out std_logic_vector(1 downto 0)                          -- Estado (00 = Apagado, 01 = Apagando, 11 = Activo)
    );
end entity state_ctrlr;

-----------------------------------------------------------
-- Arquitectura
architecture beh of state_ctrlr is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Tipos
    -------------------------------------------------
    type FSM is (S_IDLE, S_INIT, S_INIT_SW, S_NEXT_CYC, S_LAST_CYC, S_END_CYC);

    -------------------------------------------------
    -- Constantes
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Entradas y salidas
    signal r_n_addr         : unsigned((N_ADDR_I'length - 1) downto 0);
    signal r_n_tot_cyc      : unsigned((N_TOT_CYC_I'length - 1) downto 0);
    signal r_rd_addr        : unsigned((G_MEM_SIZE_MAX_L2 - 1) downto 0);
    signal r_en_cnt         : std_logic;
    signal s_switch_mem     : std_logic;
    signal r_last_cyc       : std_logic;
    signal r_unlocked       : std_logic;

    -- Otras
    signal r_state          : FSM;
    signal r_next_state     : FSM;
    signal r_update_flag    : std_logic;    -- Para activar SWITCH_MEM al final del siguiente ciclo

    -- Petición de apagado
    signal r_en_d1      : std_logic;
    signal r_en_down    : std_logic;
    signal r_off        : std_logic;
    signal s_active     : std_logic;

    -- Contador de pulsos de la configuración
    signal r_cnt_pulse  : unsigned(31 downto 0);

    -- Indicador de final de ciclo
    signal r_cyc_end    : std_logic;

    -------------------------------------------------
    -- ILA
    -------------------------------------------------
    attribute MARK_DEBUG : string;
    attribute MARK_DEBUG of r_n_addr        : signal is "true";
    attribute MARK_DEBUG of r_n_tot_cyc     : signal is "true";
    attribute MARK_DEBUG of r_rd_addr       : signal is "true";
    attribute MARK_DEBUG of r_en_cnt        : signal is "true";
    attribute MARK_DEBUG of s_switch_mem    : signal is "true";
    attribute MARK_DEBUG of r_last_cyc      : signal is "true";
    attribute MARK_DEBUG of r_unlocked      : signal is "true";
    attribute MARK_DEBUG of r_state         : signal is "true";
    attribute MARK_DEBUG of r_next_state    : signal is "true";
    attribute MARK_DEBUG of r_update_flag   : signal is "true";
    attribute MARK_DEBUG of r_en_d1         : signal is "true";
    attribute MARK_DEBUG of r_en_down       : signal is "true";
    attribute MARK_DEBUG of r_off           : signal is "true";
    attribute MARK_DEBUG of s_active        : signal is "true";
    attribute MARK_DEBUG of r_cnt_pulse     : signal is "true";
    attribute MARK_DEBUG of r_cyc_end       : signal is "true";

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
    SWITCH_MEM_O    <= s_switch_mem;
    LAST_CYC_O      <= r_last_cyc;
    UNLOCKED_O      <= r_unlocked;
    STATUS_O        <=  "00" when ((r_state = S_IDLE) or (r_state = S_INIT)) else
                        "01" when (((r_state = S_NEXT_CYC) and (EN_I = '0')) or
                                (r_state = S_END_CYC)) else
                        "11";

    -- Ciclo activo
    s_active <= '1' when (EN_I = '1') or (r_en_d1 = '1') or (r_en_down = '1') else '0';

    -- Cambio de memoria
    s_switch_mem <= '1' when ((r_cyc_end = '1') and (r_last_cyc = '1')) or (r_state = S_INIT_SW) else '0';

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- Registro de entradas
    P_REG : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_n_addr        <= (others => '0');
            r_n_tot_cyc     <= (others => '0');
        elsif rising_edge(CLK_I) then
            if (s_active = '1') then
                if (s_switch_mem = '1') then
                    r_n_addr    <= unsigned(N_ADDR_I);
                    r_n_tot_cyc <= unsigned(N_TOT_CYC_I);
                end if;
            end if;
        end if;
    end process P_REG;

    -- Petición de actualización
    P_UPDATE : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_update_flag   <= '0';  
        elsif rising_edge(CLK_I) then
            if (EN_I = '1') then
                if (EARLY_SW_I = '0') then
                    -- Llega petición de cambio de memoria
                    if (UPD_MEM_I = '1') then
                        r_update_flag   <= '1';
                    -- Se produce el cambio de memoria
                    elsif (s_switch_mem = '1') then
                        r_update_flag <= '0';
                    end if;
                end if;
            else
                r_update_flag   <= '0';
            end if;
        end if;
    end process P_UPDATE;

    -- Petición de apagado
    P_EN_OFF : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_en_d1     <= '0';
            r_en_down   <= '0';
        elsif rising_edge(CLK_I) then
            r_en_d1     <= EN_I;
            if ((EN_I = '0') and (r_en_d1 = '1')) then
                r_en_down <= '1';
            elsif (r_off = '1') then
                r_en_down   <= '0';
            end if;
        end if;
    end process P_EN_OFF;

    -- Contador de pulsos de la configuración
    P_CNT : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_cnt_pulse <= (others => '0');
        elsif rising_edge(CLK_I) then
            if (s_active = '1') then
                if ((r_state = S_NEXT_CYC) or (r_state = S_LAST_CYC) or (r_state = S_END_CYC)) then
                    if (s_switch_mem = '1') then
                        r_cnt_pulse <= (others => '0');
                    else
                        if (r_cnt_pulse < (r_n_tot_cyc - 1)) then
                            r_cnt_pulse <= r_cnt_pulse + 1;
                        else
                            r_cnt_pulse <= (others => '0');
                        end if;
                    end if;
                else
                    r_cnt_pulse <= (others => '0');
                end if;
            else
                r_cnt_pulse <= (others => '0');
            end if;
        end if;
    end process P_CNT;

    -- Indicador de final de ciclo
    P_CYC_END : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_cyc_end <= '0';
        elsif rising_edge(CLK_I) then
            if (s_active = '1') then
                if (r_cnt_pulse = (r_n_tot_cyc - 2)) then
                    r_cyc_end <= '1';
                else
                    r_cyc_end <= '0';
                end if;
            else
                r_cyc_end <= '0';
            end if;
        end if;
    end process P_CYC_END;

    -- Control del RD_ADDR
    P_RD_ADDR : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_rd_addr <= (others => '0');
        elsif rising_edge(CLK_I) then
            if (s_active = '1') then
                if (CNT_END_PRE_I = '1') then
                    if ((r_state = S_NEXT_CYC) or (r_state = S_LAST_CYC) or (r_state = S_END_CYC)) then
                        if (r_rd_addr < (r_n_addr - 1)) then
                            r_rd_addr <= r_rd_addr + 1;
                        else
                            r_rd_addr <= (others => '0');
                        end if;
                    else
                        r_rd_addr <= (others => '0');
                    end if;
                end if;
            else
                r_rd_addr <= (others => '0');
            end if;
        end if;
    end process P_RD_ADDR;

    -- FSM Next State
    P_FSM_NEXT : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_state <= S_IDLE;
        elsif rising_edge(CLK_I) then
            r_state <= r_next_state;
        end if;
    end process P_FSM_NEXT;

    -- FSM
    P_FSM : process (RST_I, r_state, EN_I, r_cyc_end, r_update_flag)
    begin
        if (RST_I = G_RST_POL) then
            r_next_state    <= S_IDLE;
            r_last_cyc      <= '0';
            r_en_cnt        <= '0';
            r_off           <= '0';
            r_unlocked      <= '1';
        else

            case r_state is

                -- No hay enable
                when S_IDLE =>
                    r_en_cnt            <= '0';
                    r_last_cyc          <= '0';
                    r_off               <= '1';
                    r_unlocked          <= '1';
                    if (EN_I = '1') then
                        r_next_state    <= S_INIT;
                    end if;

                -- Estado inicial: la configuración no ha entrado todavía en la memoria
                when S_INIT =>
                    r_en_cnt                <= '0';
                    r_last_cyc              <= '0';
                    r_off                   <= '0';
                    r_unlocked              <= '1';
                    if (EN_I = '1') then
                        if (EARLY_SW_I = '0') then
                            if (r_update_flag = '1') then
                                r_next_state    <= S_INIT_SW;
                            end if;
                        end if;
                    else
                        r_next_state        <= S_IDLE;
                    end if;

                -- Primer switch
                when S_INIT_SW =>
                    r_en_cnt            <= '1';
                    r_last_cyc          <= '1';
                    r_off               <= '0';
                    r_unlocked          <= '0';
                    if (EN_I = '1') then
                        r_next_state    <= S_NEXT_CYC;
                    else
                        r_next_state    <= S_IDLE;
                    end if;

                -- Estado normal, itera entre la configuración actual
                when S_NEXT_CYC =>
                    r_en_cnt                    <= '1';
                    r_last_cyc                  <= '0';
                    r_off                       <= '0';
                    r_unlocked                  <= '1';
                    if (r_cyc_end = '1') then
                        if (EN_I = '1') then
                            if (r_update_flag = '1') then
                                r_next_state    <= S_LAST_CYC;
                            else
                                r_next_state    <= S_NEXT_CYC;
                            end if;
                        else
                            r_next_state            <= S_END_CYC;
                        end if;
                    end if;

                -- Último estado antes de cambiar la memoria
                when S_LAST_CYC =>
                    r_en_cnt                <= '1';
                    r_last_cyc              <= '1';
                    r_off                   <= '0';
                    r_unlocked              <= '0';
                    if (r_cyc_end = '1') then
                        if (EN_I = '1') then
                            r_next_state    <= S_NEXT_CYC;
                        else
                            r_next_state    <= S_END_CYC;
                        end if;
                    end if;

                -- Último ciclo antes de apagar
                when S_END_CYC =>
                    r_en_cnt                <= '1';
                    r_last_cyc              <= '0';
                    r_off                   <= '0';
                    r_unlocked              <= '0';
                    if (r_cyc_end = '1') then
                        r_next_state    <= S_IDLE;
                    end if;
                        
                when others =>
                    r_next_state            <= S_IDLE;
                    r_en_cnt                <= '0';
                    r_last_cyc              <= '0';
                    r_off                   <= '0';
                    r_unlocked              <= '0';

            end case;
        end if;
    end process P_FSM;

end architecture beh;