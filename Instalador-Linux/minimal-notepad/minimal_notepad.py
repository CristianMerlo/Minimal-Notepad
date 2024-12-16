import sys
import os
from PySide6.QtWidgets import (QApplication, QMainWindow, QTextEdit, 
                             QVBoxLayout, QWidget, QFileDialog, QMenuBar, QMenu,
                             QMessageBox)
from PySide6.QtGui import QFont, QPalette, QColor, QAction, QKeySequence, QKeyEvent
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
        
        # Remove window frame and set window flags for transparency
        self.setWindowFlags(Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint)
        self.setAttribute(Qt.WA_TranslucentBackground)
        
        # Create central widget and layout
        central_widget = QWidget()
        layout = QVBoxLayout()
        
        # Create text area
        self.text_area = QTextEdit()
        self.text_area.textChanged.connect(self.handle_content_changed)
        
        # Set Ubuntu font and styling
        font = QFont('Ubuntu', 12)
        self.text_area.setFont(font)
        
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
                padding: 4px 8px;
                border-radius: 4px;
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
        
        # Add text area to layout
        layout.addWidget(self.text_area)
        central_widget.setLayout(layout)
        self.setCentralWidget(central_widget)
        
        # Create menu
        self.create_menu()
        
        # Make window translucent
        # self.setAttribute(Qt.WA_TranslucentBackground)

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

    def handle_content_changed(self):
        self.is_content_modified = True
        if self.current_file:
            self.setWindowTitle(f"Minimal Notepad - *{self.current_file}")
        else:
            self.setWindowTitle("Minimal Notepad - *Untitled")

    def closeEvent(self, event):
        if self.is_content_modified:
            reply = QMessageBox.question(
                self, 'Save Changes',
                'The document has been modified.\nDo you want to save your changes?',
                QMessageBox.Save | QMessageBox.Discard | QMessageBox.Cancel,
                QMessageBox.Save
            )

            if reply == QMessageBox.Save:
                if self.save_file():
                    event.accept()
                else:
                    event.ignore()
            elif reply == QMessageBox.Cancel:
                event.ignore()
            else:
                event.accept()
        else:
            event.accept()

    def new_file(self):
        if self.maybe_save():
            self.text_area.clear()
            self.current_file = None
            self.is_content_modified = False
            self.setWindowTitle("Minimal Notepad")

    def open_file(self):
        if self.maybe_save():
            file_name, _ = QFileDialog.getOpenFileName(
                self, 'Open File',
                os.path.expanduser('~'),
                'Text Files (*.txt)'
            )
            if file_name:
                self.current_file = file_name
                with open(file_name, 'r', encoding='utf-8') as file:
                    self.text_area.setText(file.read())
                self.is_content_modified = False
                self.setWindowTitle(f"Minimal Notepad - {self.current_file}")

    def maybe_save(self):
        if not self.is_content_modified:
            return True

        reply = QMessageBox.question(
            self, 'Save Changes',
            'The document has been modified.\nDo you want to save your changes?',
            QMessageBox.Save | QMessageBox.Discard | QMessageBox.Cancel,
            QMessageBox.Save
        )

        if reply == QMessageBox.Save:
            return self.save_file()
        elif reply == QMessageBox.Cancel:
            return False
        return True

    def save_file(self):
        if self.current_file:
            return self.save_to_file(self.current_file)
        else:
            return self.save_file_as()

    def save_file_as(self):
        file_name, _ = QFileDialog.getSaveFileName(
            self, 'Save File',
            os.path.expanduser('~'),
            'Text Files (*.txt)'
        )
        if file_name:
            if self.save_to_file(file_name):
                self.current_file = file_name
                self.is_content_modified = False
                self.setWindowTitle(f"Minimal Notepad - {self.current_file}")
                return True
        return False

    def save_to_file(self, file_name):
        try:
            with open(file_name, 'w', encoding='utf-8') as file:
                file.write(self.text_area.toPlainText())
            self.is_content_modified = False
            return True
        except Exception as e:
            QMessageBox.critical(
                self,
                "Error",
                f"Could not save file: {str(e)}"
            )
            return False

    def keyPressEvent(self, event: QKeyEvent):
        # Manejar Ctrl+X para salir
        if event.key() == Qt.Key_X and event.modifiers() == Qt.ControlModifier:
            self.close()
        else:
            super().keyPressEvent(event)

def main():
    app = QApplication(sys.argv)
    notepad = MinimalNotepad()
    notepad.show()
    sys.exit(app.exec())

if __name__ == '__main__':
    main()
