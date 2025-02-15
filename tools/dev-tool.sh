#!/bin/bash

# v0.1.0
# Verifica que no haya entornos activos 
if [ -n "$VIRTUAL_ENV" ]; then
  echo 'Por favor, correr sin VENV activo (run: deactivate).'
  exit 1
fi

# Verifica que se este en el repo correcto
if [ "$(sh -c 'git config --get remote.origin.url')" != "https://github.com/seedsigner/seedsigner.git" ]; then
  echo 'Por favor, correr dentro del repositorio correcto ("https://github.com/seedsigner/seedsigner.git").'
#  exit 1 # Comented priosionally until the script merges
fi

### PARAMETROS DEL SCRIPT

# Verifica si se ha pasado el primer argumento o se omite (dev/test/"-"/None permitidos)
if [ -z "$1" ] || [ "$1" = "-" ] || [ "$1" = "dev" ]; then
  echo "Modo VENV: dev"
  VENV_MODE="DEV_VENV"
elif 
   [ "$1" = "test" ]; then

  if uname -a | grep -qE 'aarch64|raspberry'; then
    echo "Los tests no son para ARM o Raspberry Pi!"
    exit 1
  fi

  echo "Modo VENV: test" 
  VENV_MODE="TEST_VENV" 
else
  echo 'Por favor, indique un modo para el VENV correcto: dev o test (u omita: dev).'
  exit 1  
fi

# Verifica si se ha pasado el segundo argumento o se omite (any/"-"/None)
if [ -z "$2" ] || [ "$2" = "-" ]; then
  echo "Asumiendo directorio de venv = modo venv elegido"
  VENV_NAME=$VENV_MODE
else
  VENV_NAME=$2
fi

# Verificar si hay un tercer parámetro o se omite (pythonN.M/"-"/None)
if [ -z "$3" ] || [ "$3" = "-" ]; then
  echo "Asumiendo version activa de python $(python --version)"
else
  PYTHON_PATH=$(which $3)
  if [ -z "$PYTHON_PATH" ]; then
    echo "No se encontró Python $3 en tu PATH."
    exit 1
  fi
  alias python=$PYTHON_PATH
  alias python3=$PYTHON_PATH
  shopt -s expand_aliases  
  echo "Usando version de python '$(python --version)'"
fi

### DEPENDENCIAS NECESARIAS (Seccion en revision/debug)
#sudo apt install libssl-dev ? # Ensure OpenSSL is installed
#sudo apt install pkg-config ?
#sudo apt install tk-dev ?para el make de python manual como altinstall _tkinter requiere tk:
#sudo apt-get install libzbar0 ? para tests 

dpkg -l | grep libssl-dev
dpkg -l | grep pkg-config
dpkg -l | grep tk-dev 
dpkg -l | grep libzbar0

## posibles requisitos adicionales???: sudo apt install build-essential pkg-config zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev libbz2-dev


# Reconstruye la ruta de activación del entorno virtual
# Setting actual directory to /src o /tests on repo
REPO_PATH=$(sh -c 'git rev-parse --show-toplevel')

if [ "$VENV_MODE" = "DEV_VENV" ]; then
  # Modo DEV
  ABSOLUTE_VENV_DEST_PATH=$(cd "$REPO_PATH" && pwd)/src
else
  # Modo TEST
  ABSOLUTE_VENV_DEST_PATH=$(cd "$REPO_PATH" && pwd)/tests
fi

echo $ABSOLUTE_VENV_DEST_PATH
cd "$ABSOLUTE_VENV_DEST_PATH"

VENV_ACTIVATE="$VENV_NAME/bin/activate"
VENV_ACTIVATE_PATH=$(pwd)/$VENV_ACTIVATE
VENV_BAK=$(pwd)/"$VENV_NAME"
echo 
echo $VENV_ACTIVATE
echo $VENV_ACTIVATE_PATH
echo $VENV_BAK

# Crea VENV

if [ -f $VENV_ACTIVATE_PATH ]; then # verifica si ya existe el venv para no pisarlo
  echo "Ya existe venv '$VENV_ACTIVATE_PATH'. Borrar o definir otro nombre."
  exit 1
fi

echo "Creando venv (con python -m venv) '$VENV_NAME'..."
python -m venv $VENV_NAME # primera alternativa
if [ ! -f $VENV_ACTIVATE_PATH ]; then   # Si no se genero el venv, prueba con comando 'virtualenv'

  echo "Creando venv (con virtualenv) '$VENV_NAME'..."
  sudo apt install virtualenv
  virtualenv $VENV_NAME # segunda alternativa
  if [ ! -f $VENV_ACTIVATE_PATH ]; then
  
    echo "No se pudo crear venv '$VENV_NAME'..."
    exit 1
  fi
fi
echo


### Instalacion de paquetes necesarios segun el MODO ELEGIDO

if [ "$VENV_MODE" = "DEV_VENV" ]; then
  # Modo DEV
  
  # Instalacion de paquetes necesarios
  echo "Instalando paquetes necesarios ..."

  # Verifica si el archivo seedsigner-emulator/requirements.txt existe
  if [ -f "seedsigner-emulator/requirements.txt" ]; then
     bash -c "source $VENV_ACTIVATE && echo 'Entorno virtual activado en: "$VENV_ACTIVATE_PATH"' && echo && python3 -m pip install --upgrade pip --require-virtualenv && python3 -m pip install --upgrade Pillow --require-virtualenv && python3 -m pip install --upgrade setuptools --require-virtualenv && pip3 install -r seedsigner-emulator/requirements.txt --require-virtualenv && echo 'Los paquetes se han instalado correctamente en el entorno virtual desde requirements.txt' && deactivate"
  else
     bash -c "source $VENV_ACTIVATE && echo 'Entorno virtual activado en: "$VENV_ACTIVATE_PATH"' && echo && python3 -m pip install --upgrade pip --require-virtualenv && python3 -m pip install --upgrade Pillow --require-virtualenv && python3 -m pip install --upgrade setuptools --require-virtualenv && pip3 install git+https://github.com/jreesun/urtypes.git@e0d0db277ec2339650343eaf7b220fffb9233241 --require-virtualenv && pip3 install git+https://github.com/enteropositivo/pyzbar.git@a52ff0b2e8ff714ba53bbf6461c89d672a304411#egg=pyzbar --require-virtualenv && pip3 install embit dataclasses qrcode tk opencv-python --require-virtualenv && echo 'Los paquetes se han instalado correctamente en el entorno virtual.' && deactivate"
  fi

  # Instalando EMULADOR
  echo "Clonando repo seedsigner-emulator ..."
  #git clone http://github.com/enteropositivo/seedsigner-emulator.git
  git clone --single-branch --branch fix-seedsigner-0.8.5 https://github.com/fedebuyito/seedsigner-emulator.git
  rsync -a seedsigner-emulator/seedsigner/emulator ./seedsigner
  rsync -a seedsigner-emulator/seedsigner/resources ./seedsigner
  echo
  
  ### CODIGO PARA AUTOMATIZAR EN BIN/ACTIVATE-DEACTIVATE DENTRO DEL VENV (SOLO EN Modo DEV)

  # Función activate a insertar
  ACTIVATE_CODE=$(cat <<'END'
# INSERTED CODE FOR SEEDSIGNER-EMULATOR INTREGATION ##############################################################################################################
activate () {
    # Obtener el directorio base del entorno virtual
    SRC_DIR=$(cd "$(dirname "$VIRTUAL_ENV")" && pwd)

    # Exportar SRC_DIR para que esté disponible en deactivate
    export SRC_DIR

    # Imprimir el valor de SRC_DIR para depuración
    echo "SRC_DIR: $SRC_DIR"

    # Renombrar archivos originales y crear enlaces simbólicos temporales
    echo "Creando enlaces simbólicos..."

    files=("gui/renderer.py" "hardware/buttons.py" "hardware/camera.py" "hardware/pivideostream.py")

    for file in "${files[@]}"; do
        if [ -f "$SRC_DIR/seedsigner/$file" ] && [ ! -L "$SRC_DIR/seedsigner/$file" ]; then
            mv "$SRC_DIR/seedsigner/$file" "$SRC_DIR/seedsigner/.${file##*/}"
            ln -s "$SRC_DIR/seedsigner-emulator/seedsigner/$file" "$SRC_DIR/seedsigner/$file"
        fi
    done

    # Verificar si los enlaces simbólicos se han creado
    for file in "${files[@]}"; do
        ls -l "$SRC_DIR/seedsigner/$file"
    done

    # Establecer variable de control
    export ACTIVATING_VENV=TRUE
    echo
    echo "ACTIVATING_VENV: '$ACTIVATING_VENV'"
}
##################################################################################################################################################################
END
  )

  # Función clear_links a insertar
  CLEAR_LINKS_CODE=$(cat <<'END'
# INSERTED CODE FOR SEEDSIGNER-EMULATOR INTREGATION ##############################################################################################################
clear_links () {
    # Verificar si estamos activando el entorno para omitir la porción adicional
    if [ -z "${ACTIVATING_VENV:-}" ]; then
        echo "ACTIVATING_VENV: '$ACTIVATING_VENV' or NONE (DEACTIVATING)"
        echo
        # Imprimir el valor de VENV_DIR para depuración
        echo "SRC_DIR: $SRC_DIR"

        # Eliminar los enlaces simbólicos al desactivar el entorno virtual y restaurar archivos originales
        echo "Eliminando enlaces simbólicos..."
        files=("gui/renderer.py" "hardware/buttons.py" "hardware/camera.py" "hardware/pivideostream.py")

        for file in "${files[@]}"; do
            if [ -L "$SRC_DIR/seedsigner/$file" ];then
                echo "Desenlazando $SRC_DIR/seedsigner/$file"
                unlink "$SRC_DIR/seedsigner/$file"
                if [ -f "$SRC_DIR/seedsigner/.${file##*/}" ];then
                    echo "Restaurando $SRC_DIR/seedsigner/.${file##*/}"
                    mv "$SRC_DIR/seedsigner/.${file##*/}" "$SRC_DIR/seedsigner/$file"
                else
                    echo "Archivo temporal no encontrado: $SRC_DIR/seedsigner/.${file##*/}"
                fi
            else
                echo "No es un enlace simbólico: $SRC_DIR/seedsigner/$file"
            fi
        done

        # Verificar si SRC_DIR está definida y luego desactivarla
        if [ -n "${SRC_DIR:-}" ];then
            unset SRC_DIR
        fi
    else
        # Unset the ACTIVATING_VENV variable after activation
        unset ACTIVATING_VENV
    fi  
}
##################################################################################################################################################################
END
  )


  # Verificando que bin/activate ya no haya sido parchado anteriormente
  if grep -q "# INSERTED CODE FOR SEEDSIGNER-EMULATOR INTREGATION #" "$VENV_ACTIVATE_PATH"; then
    echo "$VENV_ACTIVATE_PATH ya ha sido parchado!"

  else
    echo "Patching $VENV_ACTIVATE ...($VENV_ACTIVATE_PATH)"
    echo

    # Crear el archivo de activación con las funciones insertadas al principio
    {
        echo "$ACTIVATE_CODE"
        echo "$CLEAR_LINKS_CODE"
        cat "$VENV_ACTIVATE_PATH"
    } > "${VENV_ACTIVATE_PATH}.aux" && mv "${VENV_ACTIVATE_PATH}.aux" "$VENV_ACTIVATE_PATH"

    # Insertar la llamada a activate justo antes de deactivate nondestructive
    sed -i '/^deactivate nondestructive/i activate # INSERTED LINE FOR SEEDSIGNER-EMULATOR INTEGRATION ########################################' "$VENV_ACTIVATE_PATH"
  
    # Insertar la llamada a clear_links dentro de deactivate
    sed -i '/^deactivate () {/a \    clear_links # INSERTED LINE FOR SEEDSIGNER-EMULATOR INTEGRATION ########################################' "$VENV_ACTIVATE_PATH"
  fi  


else
  # Modo TEST (asume que los requeriments estan porque vienen del repo)
  bash -c ". $VENV_ACTIVATE && cd .. && echo 'Entorno virtual activado en: "$VENV_ACTIVATE_PATH"' && echo && python3 -m pip install --upgrade pip && python3 -m pip install --upgrade setuptools && pip install -r requirements.txt -r tests/requirements.txt --require-virtualenv && echo 'Los paquetes se han instalado correctamente en el entorno virtual desde requirements.txt' && echo && echo 'Instalando modulo seedsigner...' && pip install -e . && deactivate"
  echo
  
fi

echo "Ya puede activar su VENV con: source '$VENV_ACTIVATE'"

unset ACTIVATE_CODE CLEAR_LINKS_CODE VENV_ACTIVATE VENV_ACTIVATE_PATH VENV_NAME ## VERIFICAR SI HAY MAS VARIABLES PARA LIMPIAR

# Abrir una nueva instancia de la terminal para establecerse en el directorio correspondiente

if [ "$VENV_MODE" = "DEV_VENV" ]; then
  # Modo DEV
  ABSOLUTE_DEST_PATH=$ABSOLUTE_VENV_DEST_PATH
else
  # Modo TEST
  ABSOLUTE_DEST_PATH=$(cd "$REPO_PATH" && pwd)  
fi

bash -c "
    # Cambiar al directorio deseado
    cd $ABSOLUTE_DEST_PATH || exit 1

    # Ejecutar el script de configuración de la shell
    if [ -f ~/.bashrc ]; then
        . ~/.bashrc
    fi

    # Mantener la terminal abierta
    exec bash
"


#    printenv > "$VENV_BAK/.shrc"

#    # Abrir una nueva instancia de la shell con el entorno actual y cambiar al nuevo directorio
#    sh -c "
#        # Cargar las variables de entorno actuales
#        set -a
#        . '$VENV_BAK/.shrc'

#        # Cambiar al nuevo directorio
#    cd '$ABSOLUTE_REPO_SRC_PATH' || exit 1

#        # Iniciar una nueva shell
#        exec sh
#    "
#exit 1
