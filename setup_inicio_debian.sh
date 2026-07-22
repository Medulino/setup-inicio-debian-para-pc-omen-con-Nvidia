#!/bin/bash

# ==============================================================================
# SCRIPT DE CONFIGURACIÓN POST-INSTALACIÓN: DEBIAN 13 (TRIXIE)
# Hardware objetivo: GPU NVIDIA / Intel-AMD x86_64
# Entorno: Cinnamon Desktop / LightDM
# ==============================================================================

# 1. Permisos de ejecución automáticos para el propio script
chmod +x "$0" 2>/dev/null

# 2. Auto-elevación a ROOT si no se ejecuta con sudo/su
if [ "$EUID" -ne 0 ]; then
    echo "🔑 Permisos de superusuario requeridos. Solicitando sudo..."
    exec sudo bash "$0" "$@"
fi

# ------------------------------------------------------------------------------
# ⚠️ DISCLAIMER Y ADVERTENCIAS DE SEGURIDAD
# ------------------------------------------------------------------------------
show_disclaimer() {
    clear
    echo "=========================================================================="
    echo "                      ⚠️  AVISO DE SEGURIDAD Y DISCLAIMER  ⚠️"
    echo "=========================================================================="
    echo " Este script automatiza la configuración del sistema Debian Trixie:"
    echo "  1. Modificación del archivo de repositorios (/etc/apt/sources.list)."
    echo "  2. Instalación de cabeceras de kernel (headers) y compilación DKMS."
    echo "  3. Instalación del controlador propietario de NVIDIA y firmwares."
    echo "  4. Sustitución de GDM3 por LightDM (optimizado para Cinnamon)."
    echo ""
    echo " 🔴 REQUISITO CRÍTICO CRUCIAL:"
    echo "    Debes tener DESACTIVADO el 'Secure Boot' (Arranque Seguro) en la BIOS."
    echo "    Si ejecutas este script con Secure Boot activo, el módulo de NVIDIA"
    echo "    será bloqueado por la BIOS y el sistema arrancará en pantalla negra."
    echo ""
    echo " 📌 NOTA SOBRE RESPONSABILIDAD:"
    echo "    El script realiza copias de seguridad previas, pero se ejecuta bajo"
    echo "    tu propia responsabilidad."
    echo "=========================================================================="
    echo ""
    read -p "¿Has desactivado el Secure Boot en tu BIOS y deseas continuar? (s/N): " confirm
    if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
        echo "❌ Operación cancelada por el usuario."
        exit 1
    fi
}

# Mostrar aviso de seguridad y requerir confirmación
show_disclaimer

echo ""
echo "🚀 Iniciando proceso de configuración..."
sleep 2

# ------------------------------------------------------------------------------
# 1. Configuración y Copia de Seguridad de Repositorios (sources.list)
# ------------------------------------------------------------------------------
echo "📦 [1/5] Configurando repositorios APT (main contrib non-free non-free-firmware)..."

SOURCES_FILE="/etc/apt/sources.list"
BACKUP_FILE="/etc/apt/sources.list.bak_$(date +%Y%m%d_%H%M%S)"

# Crear respaldo del archivo original
cp "$SOURCES_FILE" "$BACKUP_FILE"
echo "   ↳ Copia de seguridad creada en: $BACKUP_FILE"

# Añadir ramas contrib y non-free si no están presentes
sed -i 's/non-free-firmware/contrib non-free non-free-firmware/g' "$SOURCES_FILE"
sed -i 's/main$/main contrib non-free non-free-firmware/g' "$SOURCES_FILE"

# Actualizar la base de datos de paquetes
echo "   ↳ Actualizando índice de paquetes..."
apt update -y

# ------------------------------------------------------------------------------
# 2. Instalación de Cabeceras del Kernel y Herramientas de Compilación
# ------------------------------------------------------------------------------
echo "🛠️ [2/5] Instalando Linux Headers y entorno de compilación DKMS..."
apt install -y linux-headers-$(uname -r) dkms build-essential

# ------------------------------------------------------------------------------
# 3. Instalación de Controladores NVIDIA y Firmware Propietario
# ------------------------------------------------------------------------------
echo "🎮 [3/5] Instalando controladores propietarios de NVIDIA y firmwares..."
apt install -y nvidia-driver firmware-misc-nonfree nvidia-settings nvidia-smi

echo "⚙️ [4/5] Compilando módulos de kernel para la GPU..."
dpkg-reconfigure nvidia-kernel-dkms
update-initramfs -u -k all

# ------------------------------------------------------------------------------
# 4. Configuración del Gestor de Pantalla (LightDM)
# ------------------------------------------------------------------------------
echo "🖥️ [5/5] Configurando LightDM para evitar conflictos con Cinnamon/Wayland..."
apt install -y lightdm

# Establecer LightDM como predeterminado de forma no interactiva
echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager
systemctl disable gdm3 2>/dev/null || true
systemctl enable lightdm

# ------------------------------------------------------------------------------
# Resumen y Finalización
# ------------------------------------------------------------------------------
echo ""
echo "=========================================================================="
echo "✅ ¡PROCESO FINALIZADO CON ÉXITO!"
echo "=========================================================================="
echo " Recordatorios importantes antes de reiniciar:"
echo "  • Asegúrate de que no haya pantallas secundarias o TVs apagadas"
echo "    capturando la señal de vídeo principal."
echo "  • Al volver a iniciar, comprueba la gráfica ejecutando: nvidia-smi"
echo "=========================================================================="
echo ""
read -p "El sistema necesita reiniciar. ¿Reiniciar ahora? (S/n): " reboot_confirm
if [[ "$reboot_confirm" == "s" || "$reboot_confirm" == "S" || -z "$reboot_confirm" ]]; then
    echo "🔄 Reiniciando el sistema..."
    reboot
else
    echo "⚠️ Recuerda reiniciar manualmente el equipo para aplicar los cambios."
fi
