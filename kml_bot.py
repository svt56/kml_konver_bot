import asyncio
import logging
from aiogram import Bot, Dispatcher, types, F
from aiogram.filters.command import Command
import sqlite3
import hashlib
import re
from datetime import datetime
import shutil
import os
import subprocess
def sanitize_filename(filename):
    # Разделяем имя файла и расширение
    name, ext = os.path.splitext(filename)
    # Удаляем из имени все символы, кроме букв и цифр
    sanitized_name = re.sub(r'[^a-zA-Z0-9]', '', name)
    # Возвращаем новое имя файла с прежним расширением
    return sanitized_name + ext
# Создаем подключение к базе данных
name_db = 'kml_log.db'
conn = sqlite3.connect(name_db)
cursor = conn.cursor()
# Считываем токен из базы данных
API_TOKEN = cursor.execute('SELECT key FROM key WHERE id=1').fetchone()[0]
# Включаем логирование, чтобы не пропустить важные сообщения
logging.basicConfig(level=logging.INFO)
# Объект бота
bot = Bot(token=API_TOKEN)
# Диспетчер
dp = Dispatcher()
# Массив разрешенных расширений
ext_f = ['kml', 'kmz']
# Получаем список разрешенных пользователей
b = cursor.execute("SELECT * FROM prava").fetchall()
allowed_users = [i[1] for i in b]
# Функция для получения MD5 хеша файла
def hash_md5(filepath):
    md5_hash = hashlib.md5()
    with open(filepath, "rb") as file:
        for chunk in iter(lambda: file.read(128 * md5_hash.block_size), b''):
            md5_hash.update(chunk)
    return md5_hash.hexdigest()
# Хэндлер на команду /start
@dp.message(Command("start", "help"))
async def send_welcome(message: types.Message):
 if int(message.from_user.id) not in allowed_users:
  return await message.reply("Извините, у вас нет доступа к этому боту.")
 await message.reply("Привет! Отправьте мне файл, который нужно обработать.")
 # Обработчик получения документов
@dp.message(F.document)
async def handle_docs(message: types.Message):
    if int(message.from_user.id) not in allowed_users:
        return await message.reply("Извините, вы не можете использовать этот бот.")
    document_id = message.document.file_id
    file_info = await bot.get_file(document_id)
    file_path = file_info.file_path
    #if str(message.document.mime_type) != "application/vnd.google-earth.kml+xml" or str(message.document.mime_type) != "application/vnd.google-earth.kmz":
    #    return await message.reply(f"Не то расширение. MiMe type вашего фала: {message.document.mime_type}")
    destination = f"{message.document.file_name}"
    await bot.download_file(file_path, destination)
    new_name = sanitize_filename(message.document.file_name)
    os.rename(message.document.file_name, new_name)
    #получаем md5
    md5 = hash_md5(new_name)
    # смотрим есть такой файл или нет
    in_filez = cursor.execute("""select count (id) from filez where md5 = ?""", (md5,)).fetchall()
    in_md5_log = cursor.execute("""select count (id) from md5_log where md5 = ?""", (md5,)).fetchall()
    if int(in_filez[0][0]) > 0:
        await message.reply(f"файл с MD5 хэш: {md5} уже был, с ним связано {in_filez[0][0]} строк, файл присылылася {in_md5_log[0][0]}")
    else:
        await message.reply(f"Файл {new_name} получен. MD5 хэш файла: {md5}.")
    #вносим в бд сведения об отправленном файле
    date = datetime.now()
    cursor.execute("INSERT INTO md5_log (md5, name_file, from_id, datee, timee) VALUES (?, ?, ?, ?, ? );", (md5, new_name, message.from_user.id, date.strftime('%d.%m.%Y'), date.strftime('%H.%M.%S')))
    conn.commit()
    subprocess.Popen(['bash', 'kml_extract.sh', f"{new_name}", str(message.from_user.id), str(API_TOKEN), str(name_db)])

@dp.message(Command("show"))
async def send_show(message: types.Message):
    if int(message.from_user.id) not in allowed_users:
        return await message.reply("Извините, у вас нет доступа к этому боту.")
    count = cursor.execute("""select count (*) from filez""").fetchall()
    await message.reply(f"Всего записей {count[0][0]}")
@dp.message(Command("download"))
async def send_show(message: types.Message):
    if int(message.from_user.id) not in allowed_users:
        return await message.reply("Извините, у вас нет доступа к этому боту.")
    count = cursor.execute("""select count (*) from filez""").fetchall()
    await message.reply("Здесь можно будет получить всю базу данных")
# Запуск процесса поллинга новых апдейтов
async def main():
    await dp.start_polling(bot)

if __name__ == "__main__":
    asyncio.run(main())
