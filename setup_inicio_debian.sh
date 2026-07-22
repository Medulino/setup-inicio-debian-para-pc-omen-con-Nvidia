#!/bin/bash

# 1. Darle permisos de ejecución al propio archivo para el futuro
chmod +x "$0" 2>/dev/null

# 2. Auto-elevar a ROOT si no se ejecutó con sudo
if [ "$EUID" -ne 0 ]; then
    echo "🔑 Requeridos permisos de superusuario. Solicitando sudo..."
    exec sudo bash "$0" "$@"
fi

# ==============================================================================
# SCRIPT DE CONFIGURACIÓN POST-INSTALACIÓN: DEBIAN 13 (TRIXIE)
# Hardware objetivo: GPU NVIDIA / Intel-AMD x86_64
# Entorno: Cinnamon Desktop / LightDM
# ==============================================================================

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
    echo "  5. Limpieza de archivos de arranque residuales en la partición EFI."
    echo ""
    echo " 🔴 REQUISITO CRÍTICO CRUCIAL:"
    echo "    Debes tener DESACTIVADO el 'Secure Boot' (Arranque Seguro) en la BIOS."
    echo "    Si ejecutas este script con Secure Boot activo, el módulo de NVIDIA"
    echo "    será bloqueado por la BIOS y el sistema arrancará en pantalla negra."
    echo ""
    echo " 📌 NOTA SOBRE RESPONSABILIDAD:"
    echo "    El script realiza copias de seguridad previas, pero se ejecuta bajo"
    echo "    tu propia responsabilidad. Revisa el código antes de continuar."
    echo "=========================================================================="
    echo ""
    read -p "¿Has desactivado el Secure Boot en tu BIOS y deseas continuar? (s/N): " confirm
    if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
        echo "❌ Operación cancelada por el usuario."
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# 1. Comprobación de Privilegios de Root
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Este script debe ejecutarse como root (usa 'sudo ./setup-debian.sh')."
  exit 1
fi

# Mostrar el aviso y requerir confirmación
show_disclaimer

echo ""
echo "🚀 Iniciando proceso de configuración..."
sleep 2

# ------------------------------------------------------------------------------
# 2. Configuración y Copia de Seguridad de Repositorios (sources.list)
# ------------------------------------------------------------------------------
echo "📦 [1/6] Configurando repositorios APT (main contrib non-free non-free-firmware)..."

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
# 3. Instalación de Cabeceras del Kernel y Herramientas de Compilación
# ------------------------------------------------------------------------------
echo "🛠️ [2/6] Instalando Linux Headers y entorno de compilación DKMS..."
apt install -y linux-headers-$(uname -r) dkms build-essential

# ------------------------------------------------------------------------------
# 4. Instalación de Controladores NVIDIA y Firmware Propietario
# ------------------------------------------------------------------------------
echo "🎮 [3/6] Instalando controladores propietarios de NVIDIA y firmwares..."
apt install -y nvidia-driver firmware-misc-nonfree nvidia-settings nvidia-smi

echo "⚙️ [4/6] Compilando módulos de kernel para la GPU..."
dpkg-reconfigure nvidia-kernel-dkms
update-initramfs -u -k all

# ------------------------------------------------------------------------------
# 5. Configuración del Gestor de Pantalla (LightDM)
# ------------------------------------------------------------------------------
echo "🖥️ [5/6] Configurando LightDM para evitar conflictos con Cinnamon/Wayland..."
apt install -y lightdm

# Establecer LightDM como predeterminado de forma no interactiva
echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager
systemctl disable gdm3 2>/dev/null || true
systemctl enable lightdm

# ------------------------------------------------------------------------------
# 6. Limpieza de Restos de Arranque UEFI (Ubuntu / Duplicados)
# ------------------------------------------------------------------------------
echo "🧹 [6/6] Limpiando archivos obsoletos en la partición EFI..."

if [ -d "/boot/efi/EFI/ubuntu" ]; then
    rm -rf /boot/efi/EFI/ubuntu
    echo "   ↳ Directorio /boot/efi/EFI/ubuntu eliminado."
fi

if [ -d "/boot/efi/EFI/Ubuntu" ]; then
    rm -rf /boot/efi/EFI/Ubuntu
    echo "   ↳ Directorio /boot/efi/EFI/Ubuntu eliminado."
fi

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
