#!/bin/bash

# Script de instalación para Minimal Notepad
# Este script instala todas las dependencias necesarias y configura la aplicación
# para funcionar en sistemas Ubuntu/Debian

echo "=== Instalando Minimal Notepad ==="
echo "Verificando permisos de root..."

# Verificar si se está ejecutando como root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: Por favor, ejecuta este script como root (usando sudo)"
    exit 1
fi

# Actualizar repositorios
echo "Actualizando repositorios..."
apt-get update

# Instalar todas las dependencias necesarias
echo "Instalando dependencias..."
apt-get install -y \
    python3 \
    python3-venv \
    python3-pip \
    python3-full \
    python3-tk \
    libxcb-cursor0 \
    libxcb1 \
    libxcb-xinerama0 \
    libxcb-randr0 \
    libxcb-xfixes0 \
    libxcb-shape0 \
    libxcb-render-util0 \
    libxcb-icccm4 \
    libxcb-keysyms1 \
    libxcb-image0 \
    qt6-wayland

# Crear directorio para la aplicación
echo "Creando directorios de la aplicación..."
APP_DIR="/opt/minimal-notepad"
mkdir -p "$APP_DIR"

# Crear y configurar entorno virtual
echo "Configurando entorno virtual Python..."
python3 -m venv "$APP_DIR/venv"

# Activar entorno virtual e instalar PySide6
echo "Instalando PySide6..."
"$APP_DIR/venv/bin/pip3" install --upgrade pip
"$APP_DIR/venv/bin/pip3" install PySide6

# Crear el archivo ejecutable de la aplicación
echo "Creando archivo principal de la aplicación..."
cat > "$APP_DIR/minimal-notepad.py" << 'EOL'
#!/usr/bin/env python3
import sys
import os
from PySide6.QtWidgets import (QApplication, QMainWindow, QTextEdit, 
                             QVBoxLayout, QWidget, QFileDialog, QMenuBar, QMenu,
                             QMessageBox)
from PySide6.QtGui import QFont, QPalette, QColor, QAction, QKeySequence
from PySide6.QtCore import Qt, QSize

class MinimalNotepad(QMainWindow):
    def __init__(self):
        super().__init__()
        self.current_file = None
        self.is_content_modified = False
        self.initUI()

    def initUI(self):
        # Set window properties
        self.setWindowTitle('Minimal Notepad')
        self.setFixedSize(800, 600)
        self.setWindowFlags(Qt.FramelessWindowHint)
        self.setAttribute(Qt.WA_TranslucentBackground)

        # Create central widget and layout
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        layout = QVBoxLayout(central_widget)

        # Create text edit
        self.text_edit = QTextEdit()
        self.text_edit.setFont(QFont('Ubuntu', 12))
        self.text_edit.textChanged.connect(self.handle_text_changed)
        layout.addWidget(self.text_edit)

        # Set transparent background and white text
        self.setStyleSheet("""
            QMainWindow { 
                background: transparent;
            }
            QWidget {
                background: transparent;
            }
            QTextEdit { 
                background-color: rgba(0, 0, 0, 80); 
                color: white; 
                border: none;
            }
            QMenuBar {
                background: transparent;
                color: white;
                font-size: 14px;
            }
            QMenuBar::item {
                background: transparent;
                color: #00ff00;
                font-weight: bold;
                font-size: 16px;
            }
            QMenuBar::item:selected {
                background-color: rgba(0, 255, 0, 0.2);
                color: #80ff80;
                border: 1px solid #00ff00;
                box-shadow: 0 0 10px #00ff00;
            }
            QMenuBar::item:hover {
                background-color: rgba(0, 255, 0, 0.15);
                color: #80ff80;
                border: 1px solid #00ff00;
                box-shadow: 0 0 15px #00ff00;
            }
            QMenu {
                background-color: rgba(0, 0, 0, 150);
                color: white;
                border: 1px solid #00ff00;
            }
            QMenu::item:selected {
                background-color: rgba(0, 255, 0, 0.3);
                color: #80ff80;
            }
            QMenu::item {
                padding: 5px 20px;
            }
        """)

        self.create_menu()
        self.center_on_screen()

    def create_menu(self):
        # Create menu bar
        menubar = self.menuBar()
        
        # File menu with Japanese characters
        file_menu = menubar.addMenu('クリスティアン')
        
        # New action
        new_action = QAction('New', self)
        new_action.setShortcut(QKeySequence.New)
        new_action.triggered.connect(self.new_file)
        file_menu.addAction(new_action)
        
        # Open action
        open_action = QAction('Open', self)
        open_action.setShortcut(QKeySequence.Open)
        open_action.triggered.connect(self.open_file)
        file_menu.addAction(open_action)
        
        # Save action
        save_action = QAction('Save', self)
        save_action.setShortcut(QKeySequence.Save)
        save_action.triggered.connect(self.save_file)
        file_menu.addAction(save_action)
        
        # Save As action
        save_as_action = QAction('Save As...', self)
        save_as_action.setShortcut(QKeySequence.SaveAs)
        save_as_action.triggered.connect(self.save_file_as)
        file_menu.addAction(save_as_action)
        
        # Exit action
        exit_action = QAction('Exit', self)
        exit_action.triggered.connect(self.close)
        file_menu.addAction(exit_action)

    def center_on_screen(self):
        screen = QApplication.primaryScreen().geometry()
        x = (screen.width() - self.width()) // 2
        y = (screen.height() - self.height()) // 2
        self.move(x, y)

    def handle_text_changed(self):
        if not self.is_content_modified:
            self.is_content_modified = True
            self.update_title()

    def update_title(self):
        title = 'Minimal Notepad'
        if self.current_file:
            title = f'{os.path.basename(self.current_file)} - {title}'
        if self.is_content_modified:
            title = f'*{title}'
        self.setWindowTitle(title)

    def new_file(self):
        if self.check_save_changes():
            self.text_edit.clear()
            self.current_file = None
            self.is_content_modified = False
            self.update_title()

    def open_file(self):
        if self.check_save_changes():
            file_name, _ = QFileDialog.getOpenFileName(self, 'Open File')
            if file_name:
                try:
                    with open(file_name, 'r', encoding='utf-8') as f:
                        self.text_edit.setText(f.read())
                    self.current_file = file_name
                    self.is_content_modified = False
                    self.update_title()
                except Exception as e:
                    QMessageBox.critical(self, 'Error', f'Could not open file: {str(e)}')

    def save_file(self):
        if self.current_file:
            return self._save_file(self.current_file)
        return self.save_file_as()

    def save_file_as(self):
        file_name, _ = QFileDialog.getSaveFileName(self, 'Save File')
        if file_name:
            return self._save_file(file_name)
        return False

    def _save_file(self, file_name):
        try:
            with open(file_name, 'w', encoding='utf-8') as f:
                f.write(self.text_edit.toPlainText())
            self.current_file = file_name
            self.is_content_modified = False
            self.update_title()
            return True
        except Exception as e:
            QMessageBox.critical(self, 'Error', f'Could not save file: {str(e)}')
            return False

    def check_save_changes(self):
        if self.is_content_modified:
            reply = QMessageBox.question(
                self, 'Save Changes',
                'Do you want to save your changes?',
                QMessageBox.Save | QMessageBox.Discard | QMessageBox.Cancel
            )
            
            if reply == QMessageBox.Save:
                return self.save_file()
            elif reply == QMessageBox.Cancel:
                return False
        return True

    def closeEvent(self, event):
        if self.check_save_changes():
            event.accept()
        else:
            event.ignore()

def main():
    app = QApplication(sys.argv)
    notepad = MinimalNotepad()
    notepad.show()
    sys.exit(app.exec())

if __name__ == '__main__':
    main()
EOL

# Crear el script launcher
echo "Creando launcher del sistema..."
cat > /usr/local/bin/minimal-notepad << EOL
#!/bin/bash
# Launcher para Minimal Notepad
export QT_QPA_PLATFORM=xcb
$APP_DIR/venv/bin/python3 $APP_DIR/minimal-notepad.py
EOL

# Hacer ejecutable el launcher
chmod +x /usr/local/bin/minimal-notepad

# Crear el acceso directo en el menú de aplicaciones
echo "Creando acceso directo en el menú..."
cat > /usr/share/applications/minimal-notepad.desktop << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=Minimal Notepad
Comment=A minimalist transparent text editor
Exec=/usr/local/bin/minimal-notepad
Categories=Utility;TextEditor;
Terminal=false
EOL

echo "=== Instalación completada ==="
echo "Puedes ejecutar el editor de dos formas:"
echo "1. Desde el menú de aplicaciones buscando 'Minimal Notepad'"
echo "2. Desde la terminal escribiendo 'minimal-notepad'"
echo ""
echo "Si encuentras algún problema, asegúrate de que:"
echo "- Estás usando un sistema de ventanas X11 o Wayland"
echo "- Tienes los permisos necesarios para ejecutar la aplicación"
echo "- Tu sistema está actualizado"
