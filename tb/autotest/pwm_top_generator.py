import random


def generar_diccionario():

    # N_ADDR
    longitud = random.randint(2, 8)

    # WR_DATA
    datos = [random.randint(1, 20) for _ in range(longitud)]

    # Probabilidad de empezar en 1
    if random.random() < 0.25:
        datos[0] = 1

    # Probabilidad de acabar en 1
    if random.random() < 0.25:
        datos[-1] = 1

    # Evitar configuración [1,1]
    if datos == [1,1]:
        datos[1] = 2

    # WR_ADDR
    indices = list(range(longitud))

    # N_TOT_CYC
    total = sum(datos)

    # PWM_INIT
    init = random.choice([0, 1])

    # UPD_MEM tiempo
    update = random.randint(2, 100*longitud)

    # PWM
    pwm = []
    last_value = init
    for valor in datos:
        pwm += [last_value]*valor
        if last_value == 0:
            last_value = 1
        else:
            last_value = 0

    # Duración
    duracion = random.randint(2*total, 10*total)

    # Configuración
    return {
        "wr_data":  datos,
        "wr_addr":  indices,
        "n_addr":   longitud,
        "n_tot":    total,
        "pwm_init": init,
        "upd_mem":  update,
        "pwm":      pwm,
        "duracion": duracion
    }


def wr_txt (dic_list):
    """Escribe el .txt. Cada fila es uno de los items del diccionario.
    Números enteros separados por espacios."""

    nombre = "pwm_top_inputs.txt"
    with open(nombre, "w", encoding="utf-8") as f:
        for dic in dic_list:
            f.write(f"{dic['n_addr']:3}" + "\n")
            f.write(" ".join(f'{n:3}' for n in dic['wr_addr']) + "\n")
            f.write(" ".join(f'{n:3}' for n in dic['wr_data']) + "\n")
            f.write(f"{dic['n_tot']:3}" + "\n")
            f.write(f"{dic['pwm_init']:3}" + "\n")
            f.write(f"{dic['upd_mem']:3}" + "\n")
            f.write(" ".join(f'{n:3}' for n in dic['pwm']) + "\n")
            f.write(f"{dic['duracion']:3}" + "\n")
            f.write("-"*4*len(dic['pwm']) + "\n")

    print(f"{nombre} creado correctamente.")


if __name__ == "__main__":

    n_config = 5
    config_list = []
    config_f_list = []

    for i in range(n_config):
        config = generar_diccionario()
        config_list.append(config)
        # print(config["Init"])
        # print(config)

    wr_txt(config_list)
