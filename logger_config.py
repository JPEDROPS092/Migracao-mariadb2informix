import logging
import os
from datetime import datetime

def setup_logger():
    # Cria o diretório logs se não existir
    if not os.path.exists('logs'):
        os.makedirs('logs')

    # Configura o logger principal
    logger = logging.getLogger('SQLConverter')
    logger.setLevel(logging.DEBUG)

    # Cria um handler para arquivo com rotação diária
    log_file = os.path.join('logs', f'converter_{datetime.now().strftime("%Y%m%d")}.log')
    file_handler = logging.FileHandler(log_file, encoding='utf-8')
    file_handler.setLevel(logging.DEBUG)

    # Cria um handler para console
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)

    # Define o formato dos logs
    file_formatter = logging.Formatter(
        '[%(asctime)s] %(levelname)-8s %(name)s: %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    console_formatter = logging.Formatter(
        '%(asctime)s [%(levelname)s] %(message)s',
        datefmt='%H:%M:%S'
    )
    
    file_handler.setFormatter(file_formatter)
    console_handler.setFormatter(console_formatter)

    # Remove handlers existentes para evitar duplicação
    logger.handlers = []
    
    # Adiciona os handlers ao logger
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)

    # Log inicial de sessão
    logger.info("="*50)
    logger.info("Iniciando nova sessão do Conversor SQL")
    logger.info(f"Arquivo de log: {log_file}")
    logger.info("="*50)

    return logger
