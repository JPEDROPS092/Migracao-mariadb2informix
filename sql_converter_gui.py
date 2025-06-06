# sql_converter_gui.py
import tkinter as tk
from tkinter import scrolledtext, filedialog, messagebox, PanedWindow, Frame, Label, Button, Menu
from tkinter import ttk
import logging
from sql_converter_logic import SQLConverter
from logger_config import setup_logger
import webbrowser
import json
import os
import threading

# Configuração do logger
logger = setup_logger()

class SQLConverterApp:
    def __init__(self, master):
        self.master = master
        master.title("Conversor SQL: MariaDB para Informix")
        master.geometry("1000x700")
        
        self.is_converting = False  # Flag para controlar estado de conversão
        
        # Configurar atalhos de teclado
        self.setup_keyboard_shortcuts()
        
        # Configurar menu
        self.create_menu()

        self.converter = SQLConverter()
        self.recent_files = self.load_recent_files()

        # --- PanedWindow para visualização lado a lado ---
        self.paned_window = PanedWindow(master, orient=tk.HORIZONTAL, sashrelief=tk.RAISED)
        self.paned_window.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)

        # --- Frame Esquerdo (Entrada) ---
        left_frame = Frame(self.paned_window, bd=2, relief=tk.SUNKEN)
        self.paned_window.add(left_frame, stretch="always")

        # Toolbar frame
        toolbar_frame = Frame(left_frame)
        toolbar_frame.pack(fill=tk.X, padx=5, pady=2)

        Label(left_frame, text="Script MariaDB:", font=("Arial", 12, "bold")).pack(pady=5, anchor=tk.W)
        
        # Search frame
        search_frame = Frame(left_frame)
        search_frame.pack(fill=tk.X, padx=5, pady=2)
        self.search_entry = tk.Entry(search_frame)
        self.search_entry.pack(side=tk.LEFT, fill=tk.X, expand=True)
        Button(search_frame, text="Buscar", command=self.search_text).pack(side=tk.LEFT, padx=2)
        Button(search_frame, text="Limpar", command=self.clear_search).pack(side=tk.LEFT)

        self.mariadb_text = scrolledtext.ScrolledText(left_frame, wrap=tk.WORD, width=60, height=20, font=("Consolas", 10))
        self.mariadb_text.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        btn_frame = Frame(left_frame)
        btn_frame.pack(fill=tk.X, padx=5, pady=5)
        
        btn_open_file = Button(btn_frame, text="Abrir Arquivo (.sql)", command=self.open_file)
        btn_open_file.pack(side=tk.LEFT, padx=5)
        
        btn_clear = Button(btn_frame, text="Limpar", command=lambda: self.mariadb_text.delete(1.0, tk.END))
        btn_clear.pack(side=tk.LEFT, padx=5)

        # --- Frame Direito (Saída) ---
        right_frame = Frame(self.paned_window, bd=2, relief=tk.SUNKEN)
        self.paned_window.add(right_frame, stretch="always")
        
        Label(right_frame, text="Script Informix (Convertido):", font=("Arial", 12, "bold")).pack(pady=5, anchor=tk.W)
        self.informix_text = scrolledtext.ScrolledText(right_frame, wrap=tk.WORD, width=60, height=20, font=("Consolas", 10))
        self.informix_text.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        btn_frame_right = Frame(right_frame)
        btn_frame_right.pack(fill=tk.X, padx=5, pady=5)
        
        btn_save_file = Button(btn_frame_right, text="Salvar Como...", command=self.save_file)
        btn_save_file.pack(side=tk.RIGHT, padx=5)
        
        btn_copy = Button(btn_frame_right, text="Copiar", command=self.copy_to_clipboard)
        btn_copy.pack(side=tk.RIGHT, padx=5)

        # Configuração inicial do PanedWindow
        self.master.update_idletasks()
        self.paned_window.sash_place(0, self.paned_window.winfo_width() // 2, 0)

        # --- Frame de Conversão ---
        conversion_frame = Frame(master)
        conversion_frame.pack(fill=tk.X, padx=10, pady=5)

        # Progress Bar
        self.progress_var = tk.DoubleVar()
        self.progress_bar = ttk.Progressbar(conversion_frame, 
                                          variable=self.progress_var,
                                          maximum=100,
                                          mode='determinate')
        self.progress_bar.pack(fill=tk.X, pady=(0, 5))

        # Status de Conversão
        self.conversion_status = Label(conversion_frame, 
                                     text="Pronto para converter",
                                     font=("Arial", 10))
        self.conversion_status.pack(pady=(0, 5))

        # --- Botão de Conversão ---
        self.convert_button = Button(conversion_frame, 
                                   text="Converter (Ctrl+R)", 
                                   command=self.convert_sql, 
                                   font=("Arial", 12, "bold"), 
                                   bg="lightblue")
        self.convert_button.pack(pady=5)

        # --- Área de Status/Mensagens ---
        self.status_label = Label(master, text="Pronto.", bd=1, relief=tk.SUNKEN, anchor=tk.W, justify=tk.LEFT)
        self.status_label.pack(fill=tk.X, padx=10, pady=5)

        logger.info("Aplicação inicializada com sucesso")

    def setup_keyboard_shortcuts(self):
        self.master.bind('<Control-o>', lambda e: self.open_file())
        self.master.bind('<Control-s>', lambda e: self.save_file())
        self.master.bind('<Control-r>', lambda e: self.convert_sql())
        self.master.bind('<Control-l>', lambda e: self.clear_all())
        self.master.bind('<Control-f>', lambda e: self.search_entry.focus())

    def create_menu(self):
        menubar = Menu(self.master)
        self.master.config(menu=menubar)
        
        # Menu Arquivo
        file_menu = Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Arquivo", menu=file_menu)
        file_menu.add_command(label="Abrir... (Ctrl+O)", command=self.open_file)
        
        # Submenu de arquivos recentes
        self.recent_menu = Menu(file_menu, tearoff=0)
        file_menu.add_cascade(label="Arquivos Recentes", menu=self.recent_menu)
        
        file_menu.add_separator()
        file_menu.add_command(label="Salvar Como... (Ctrl+S)", command=self.save_file)
        file_menu.add_separator()
        file_menu.add_command(label="Sair", command=self.master.quit)
        
        # Menu Editar
        edit_menu = Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Editar", menu=edit_menu)
        edit_menu.add_command(label="Limpar Tudo (Ctrl+L)", command=self.clear_all)
        edit_menu.add_command(label="Buscar (Ctrl+F)", command=lambda: self.search_entry.focus())
        
        # Menu Ajuda
        help_menu = Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Ajuda", menu=help_menu)
        help_menu.add_command(label="Sobre", command=self.show_about)
        help_menu.add_command(label="Ver Logs", command=self.open_logs)

    def load_recent_files(self):
        try:
            with open('recent_files.json', 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            return []

    def save_recent_files(self):
        with open('recent_files.json', 'w') as f:
            json.dump(self.recent_files, f)

    def update_recent_files_menu(self):
        self.recent_menu.delete(0, tk.END)
        for filepath in self.recent_files:
            self.recent_menu.add_command(
                label=os.path.basename(filepath),
                command=lambda f=filepath: self.open_recent_file(f)
            )

    def open_recent_file(self, filepath):
        if os.path.exists(filepath):
            self.open_file(filepath)
        else:
            messagebox.showwarning("Arquivo não encontrado", 
                                 f"O arquivo {filepath} não existe mais.")
            self.recent_files.remove(filepath)
            self.save_recent_files()
            self.update_recent_files_menu()

    def add_to_recent_files(self, filepath):
        if filepath in self.recent_files:
            self.recent_files.remove(filepath)
        self.recent_files.insert(0, filepath)
        self.recent_files = self.recent_files[:5]  # Mantém apenas os 5 mais recentes
        self.save_recent_files()
        self.update_recent_files_menu()

    def search_text(self):
        search_term = self.search_entry.get()
        if not search_term:
            return
            
        # Remove previous tags
        self.mariadb_text.tag_remove('search', '1.0', tk.END)
        
        start_pos = '1.0'
        while True:
            start_pos = self.mariadb_text.search(search_term, start_pos, tk.END)
            if not start_pos:
                break
            end_pos = f"{start_pos}+{len(search_term)}c"
            self.mariadb_text.tag_add('search', start_pos, end_pos)
            start_pos = end_pos
            
        self.mariadb_text.tag_config('search', background='yellow')

    def clear_search(self):
        self.search_entry.delete(0, tk.END)
        self.mariadb_text.tag_remove('search', '1.0', tk.END)

    def clear_all(self):
        self.mariadb_text.delete(1.0, tk.END)
        self.informix_text.delete(1.0, tk.END)
        self.status_label.config(text="Área de trabalho limpa.")
        logger.info("Área de trabalho limpa pelo usuário")

    def copy_to_clipboard(self):
        self.master.clipboard_clear()
        self.master.clipboard_append(self.informix_text.get(1.0, tk.END))
        self.status_label.config(text="Texto copiado para a área de transferência.")
        logger.info("Texto convertido copiado para a área de transferência")

    def show_about(self):
        about_text = """Conversor SQL: MariaDB para Informix
Versão 1.0

Este programa converte scripts SQL do MariaDB para o formato Informix.
Desenvolvido por JP Code.

© 2025 Todos os direitos reservados."""
        messagebox.showinfo("Sobre", about_text)

    def open_logs(self):
        log_dir = os.path.join(os.getcwd(), 'logs')
        if os.path.exists(log_dir):
            if os.name == 'nt':  # Windows
                os.startfile(log_dir)
            else:  # Linux/Mac
                webbrowser.open(f'file://{log_dir}')
        else:
            messagebox.showinfo("Logs", "Nenhum arquivo de log encontrado.")

    def open_file(self, filepath=None):
        if not filepath:
            filepath = filedialog.askopenfilename(
                defaultextension=".sql",
                filetypes=[("SQL Files", "*.sql"), ("All Files", "*.*")]
            )
        if not filepath:
            return
        try:
            with open(filepath, "r", encoding='utf-8') as f:
                content = f.read()
            self.mariadb_text.delete("1.0", tk.END)
            self.mariadb_text.insert("1.0", content)
            self.status_label.config(text=f"Arquivo '{filepath}' carregado.")
            self.add_to_recent_files(filepath)
            logger.info(f"Arquivo carregado: {filepath}")
        except Exception as e:
            error_msg = f"Não foi possível ler o arquivo: {e}"
            messagebox.showerror("Erro ao Abrir Arquivo", error_msg)
            self.status_label.config(text="Erro ao carregar arquivo.")
            logger.error(f"Erro ao abrir arquivo: {e}")

    def save_file(self):
        converted_sql = self.informix_text.get("1.0", tk.END).strip()
        if not converted_sql:
            messagebox.showwarning("Salvar Arquivo", "Não há nada para salvar.")
            return

        filepath = filedialog.asksaveasfilename(
            defaultextension=".sql",
            filetypes=[("SQL Files", "*.sql"), ("All Files", "*.*")],
            title="Salvar Script Informix Como..."
        )
        if not filepath:
            return
        try:
            with open(filepath, "w", encoding='utf-8') as f:
                f.write(converted_sql)
            self.status_label.config(text=f"Script Informix salvo em '{filepath}'.")
            logger.info(f"Arquivo salvo: {filepath}")
        except Exception as e:
            error_msg = f"Não foi possível salvar o arquivo: {e}"
            messagebox.showerror("Erro ao Salvar Arquivo", error_msg)
            self.status_label.config(text="Erro ao salvar arquivo.")
            logger.error(f"Erro ao salvar arquivo: {e}")

    def convert_sql(self):
        if self.is_converting:
            messagebox.showwarning("Conversão em Andamento", "Uma conversão já está em andamento.")
            return

        mariadb_script = self.mariadb_text.get("1.0", tk.END)
        if not mariadb_script.strip():
            messagebox.showwarning("Conversão", "Área de script MariaDB está vazia.")
            self.status_label.config(text="Nada para converter.")
            logger.warning("Tentativa de conversão com script vazio")
            return

        try:
            # Atualiza estado de conversão
            self.is_converting = True
            self.convert_button.config(state=tk.DISABLED, bg="gray")
            self.conversion_status.config(text="Convertendo...", fg="blue")
            self.progress_var.set(10)
            self.master.update_idletasks()

            logger.info("Iniciando conversão de script")
            
            # Simula progresso durante a conversão
            self.progress_var.set(30)
            self.master.update_idletasks()
            
            informix_script, warnings, items_converted = self.converter.convert(mariadb_script)
            
            # Atualiza progresso
            self.progress_var.set(70)
            self.master.update_idletasks()
            
            self.informix_text.delete("1.0", tk.END)
            self.informix_text.insert("1.0", informix_script)

            # Finaliza progresso
            self.progress_var.set(100)
            self.master.update_idletasks()

            status_message = f"Conversão concluída. {items_converted} itens/padrões processados."
            if warnings:
                status_message += f"\n{len(warnings)} ALERTA(S) GERADO(S) (requer revisão manual):\n"
                for i, warn in enumerate(warnings):
                    status_message += f"  {i+1}. {warn}\n"
                messagebox.showwarning("Atenção Pós-Conversão",
                                     "Conversão realizada com alertas.\nVerifique a barra de status e o script gerado para detalhes.")
                logger.warning(f"Conversão concluída com {len(warnings)} alertas")
                for warn in warnings:
                    logger.warning(f"Alerta de conversão: {warn}")
            else:
                status_message += "\nNenhum alerta específico gerado, mas sempre revise o script final."
                messagebox.showinfo("Sucesso", "Conversão concluída sem alertas específicos. Revise o script gerado.")
                logger.info("Conversão concluída sem alertas")
            
            self.status_label.config(text=status_message.strip())
            logger.info(f"Conversão finalizada: {items_converted} itens processados")

        except Exception as e:
            error_msg = f"Ocorreu um erro durante a conversão: {e}"
            messagebox.showerror("Erro de Conversão", error_msg)
            self.status_label.config(text=f"Erro na conversão: {e}")
            logger.error(f"Erro durante a conversão: {e}", exc_info=True)
        
        finally:
            # Restaura estado normal
            self.is_converting = False
            self.convert_button.config(state=tk.NORMAL, bg="lightblue")
            self.conversion_status.config(text="Pronto para converter", fg="black")
            self.progress_var.set(0)
            self.master.update_idletasks()

def main():
    root = tk.Tk()
    app = SQLConverterApp(root)
    root.mainloop()

if __name__ == "__main__":
    main()