# Bash script and Telegram bot for converting KML and KMZ to CSV and HTML
## kml_extract2.sh Этот скрипт позволяет конвертировать файлы форматов KML и KMZ в CSV и HTML. Он может быть полезен для анализа данных из геопространственных источников. <br />
Для использования скрипта необходимо выполнить следующие шаги:<br />
Устаноить дополнительный компонент *sudo snap install yq* <br />
Создать базу данных sqlite, структура базы данных в конце описания<br />
Скачать скрипт *kml_extract2.sh*. <br />
Открыть терминал и перейти в папку, где находится скрипт.<br />
Запустить скрипт, указав в качестве аргумента файл формата KML или KMZ.<br />

Пример использования:
./kml_extract2.sh simple.kmz

В результате выполнения скрипта будут созданы файлы  и , содержащие данные из исходного файла в формате CSV и HTML соответственно.<br />
Для получения дополнительной информации о том, как настроить Telegram-бота для автоматизации процесса конвертации, обратитесь к соответствующей документации.<br />
В скрипт встроен прогресс бар для удобства отслеживания процесса конвертации.
## Telegram bot состоит из двух файлов и базы данных
### kml_bot.py файл бота телерамм,нужен aiogram вресии 3.х
### kml_extract.sh файл конвертере
Для использования скрипта необходимо выполнить следующие шаги:<br />
Устаноить дополнительный компонент *sudo snap install yq* <br />
Создать базу данных sqlite, структура базы данных в конце описания<br />
Заполнить в базе данных таблицу key (здесь хранится токен) *insert into key ('key') value ('telegram token');*<br />
Заполнить таблицу prava, ввести telegram id тех, кто имеет парва обраться к боту, или убрать проверку из бота
Скачать скрипт *kml_extract.sh* и *kml_bot.py* <br />
созать папки рядом сос криптами csv и downloads
Запустить *kml_bot.py* <br />



## ФОРМАТ таблиц базы данных 
### база данных прав
CREATE TABLE prava<br />
(<br />
id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,<br />
tlg INTEGER,<br />
admin INTEGER<br />
);<br />

CREATE TABLE md5_log<br />
(<br />
id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,<br />
datee TEXT,<br />
timee TEXT,<br />
name_file TEXT,<br />
from_id TEXT,<br />
md5 TEXT NOT NULL<br />
);<br />

### база данных токена
CREATE TABLE key <br />
(<br />
id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,<br />
key TEXT NOT NULL<br />
);<br />
### база данных файлов обработанных
CREATE TABLE filez<br />
(<br />
id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,<br />
name_file TEXT,<br />
md5 TEXT,<br />
doc_name TEXT,<br />
name TEXT,<br />
descript TEXT,<br />
coord TEXT,<br />
dolg TEXT,<br />
shir TEXT,<br />
whenn TEXT,<br />
date_ins TEXT,<br />
from_id<br />
);<br />
