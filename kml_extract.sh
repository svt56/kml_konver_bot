#!/bin/bash
#how_arg=$# #количство переменных
name_db=$4
# 1 - название файйла, 2 id от кого, 3 токен, 4 навзание бд
token=$3
# Функция отправки сообщения
function sendtlg {
url="https://api.telegram.org/bot$token/sendMessage"
if [ -z "$3" ]
    then
    curl -s -X POST "$url" -d chat_id="$2" -d text="$1"
    else
    curl -s -X POST "$url" -d chat_id="$2" -d text="$1" -d protect_content="1" -d reply_to_message_id="$3"
fi
}
#убираем из имени файла лишниие символы
new_name=$(echo "$1" | tr -cd '[:alnum:]._-')
# Переименовываем файл, если новое имя отличается от старого
if [ "$1" != "$new_name" ]; then
    mv "$1" "$new_name"
else
new_name=$1
fi
ext=${new_name##*.} #получаем расширение файла
# блок функций
# md5 файла
md5=$(md5sum -z $new_name | cut -d " " -f 1 )
# обрабатываем координаты
echo "название поступившего файла""|""md5""|""название документа""|""название места""|""пояснение""|""координаты""|""долгота""|""широта""|""дата и время создания точки" > "$new_name"".csv"
# проверяем расширение файла, при необходимости извлекаем поступившего
if [[ $ext != "kml" ]]
then
    name=$(unzip -o $new_name "*.kml" | tail -1 | grep -Eo '[a-z]*.kml')
    mv $name $new_name".kml"
#    rm -f $new_name
    new_name=$new_name".kml"
fi
# Опередяелем длинну до Placemark
path=''
MR=0
#заносим данные в базы и файл

#проверяем много записей или одна
if [[ $(grep -i '<Point' $new_name | wc -l)  -gt 1 ]] # если вторая группа не равно нулю занчит их много
then
    # Опередяелем длинну до Placemark
    while [ "$MR" == $(cat $new_name | yq -p xml '.kml.Document.'$path'Placemark | length') ]
    do
        MR=$(cat $new_name | yq -p xml '.kml.Document.'$path'Placemark | length')
        path=$path"Folder."
    done
    path='.kml.Document.'$path
    tasks_in_total=$(cat $new_name | yq -p xml $path'Placemark | length')
    b=0.421
    sendtlg "Записей%20$tasks_in_total.%20Время%20конвертования%20около%20в%20секундах$(echo "scale=4; $tasks_in_total*$b" | bc)" "$2"
    #sendtlg "Всего%20строчек%20$tasks_in_total.%20Время%20выполнения%20в%20секундах$(bc<<<"scale=3;$tasks_in_total*$B")" "$2"
    for (( j=0; j < $tasks_in_total; j++ ))
    do
        des1=$(cat $new_name | yq -p xml $path'Placemark['$j'].description'); des1=${des1//$'\n'/}; des1=${des1//\|/;}; des1=${des1//\°/g}; des1=${des1//\'/s} #удаляем перенос строки
        coord=$(cat $new_name | yq -p xml $path'Placemark['$j'].Point.coordinates')
        dolg=$(echo $coord | cut -d "," -f 1)
        shir=$(echo $coord | cut -d "," -f 2)
        name_f=$(cat $new_name | yq -p xml $path'name')
        name_mark=$(cat $new_name | yq -p xml $path'Placemark['$j'].name')
        time_shtamp=$(cat $new_name | yq -p xml $path'Placemark['$j'].TimeStamp.when')
        #запись в csv
        echo "$new_name""|""$md5""|""$name_f""|""$name_mark""|""$des1""|""$coord""|""$dolg""|""$shir""|""$time_shtamp" >> "$new_name"".csv"
        #запись в базц данных
        sqlite3 $name_db "INSERT INTO filez (name_file, md5, doc_name, name, descript, coord, dolg, shir, whenn, date_ins) VALUES ('$new_name', '$md5', '$name_f', '$name_mark', '$des1', '$coord', '$dolg', '$shir', '$time_shtamp', '$(date +"%Y-%m-%d")');"
    done
else #или считаем что она одна
        path='.kml.Document.'$path
        des1=$(cat $new_name | yq -p xml $path'Placemark.description'); des1=${des1//$'\n'/}; des1=${des1//\|/;}; des1=${des1//\°/g}; des1=${des1//\'/s} #удаляем перенос строки
        coord=$(cat $new_name | yq -p xml $path'Placemark.Point.coordinates')
        dolg=$(echo $coord | cut -d "," -f 1)
        shir=$(echo $coord | cut -d "," -f 2)
        name_f=$(cat $new_name | yq -p xml $path'name')
        name_mark=$(cat $new_name | yq -p xml $path'Placemark.name')
        time_shtamp=$(cat $new_name | yq -p xml $path'Placemark.TimeStamp.when')
        #запись в csv
        echo "$new_name""|""$md5""|""$name_f""|""$name_mark""|""$des1""|""$coord""|""$dolg""|""$shir""|""$time_shtamp" >> "$new_name"".csv"
        #запись в базц данных
        sqlite3 $name_db "INSERT INTO filez (name_file, md5, doc_name, name, descript, coord, dolg, shir, whenn, date_ins) VALUES ('$new_name', '$md5', '$name_f', '$name_mark', '$des1', '$coord', '$dolg', '$shir', '$time_shtamp', '$(date +"%Y-%m-%d")');"
fi
#делаем html таблицу
# shellcheck disable=SC2140
echo "<!DOCTYPE html PUBLIC -//IETF//DTD HTML 2.0//EN><HTML lang="ru"><BODY> <meta charset="UTF-8"><table border="1">" > "$new_name"".html"
while read INPUT
do
    echo "<tr><td>${INPUT//|/</td><td>}</td></tr>" >> "$new_name"".html"
done < "$new_name.csv"
echo "</TABLE></BODY></HTML>" >> "$new_name"".html"
#отправить в телеграмм
#id=
curl -F document=@"$new_name.csv" https://api.telegram.org/bot"$token"/sendDocument?chat_id="$2"
curl -F document=@"$new_name.html" https://api.telegram.org/bot"$token"/sendDocument?chat_id="$2"
mv $new_name.csv csv/$new_name.csv
rm -f $new_name.html $name
mv $1 downloads/$1
