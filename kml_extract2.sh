#!/bin/bash
#sudo snap install yq
#source progress_bar.sh
how_arg=$# #количство переменных
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
# прогресс бар
bar_size=20
bar_char_done="#"
bar_char_todo="-"
bar_percentage_scale=3
function show_progress {
    local current="$1"
    local total="$2"
    # calculate the progress in percentage
    percent=$(bc <<< "scale=$bar_percentage_scale; 100 * $current / $total" )
    # The number of done and todo characters
    done=$(bc <<< "scale=0; $bar_size * $percent / 100" )
    #echo ${done}
    todo=$(bc <<< "scale=0; $bar_size - $done" )
    # build the done and todo sub-bars
    done_sub_bar=$(printf "%${done}s" | tr " " "${bar_char_done}")
    todo_sub_bar=$(printf "%${todo}s" | tr " " "${bar_char_todo}")
    # output the bar
    echo -ne "\rProgress : [${done_sub_bar}${todo_sub_bar}] ${percent}%"
    #echo -ne "\rProgress : ${percent}"
    if [ $total -eq $current ]; then
        echo -e "\nDONE"
    fi
}
# md5 файла
md5=$(md5sum -z $new_name | cut -d " " -f 1 )
md5_count=$(sqlite3 kml_log.db "select count (id) from filez where md5='$md5'") #колиство записей с этим файлом
if [[ md5_count -gt 0 ]]
then
  echo "такой файл был"
  echo "строчек с этим файлом ""$md5_count"
else
  echo "такого не было"
fi

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
#if [[ $(cat $new_name | yq -p xml '.kml.Document.Placemark[1]') != "null" ]] # если вторая группа не равно нулю занчит их много
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
    echo "Записей: "$tasks_in_total". Время конвертования около "$(echo "scale=4; $tasks_in_total*$b" | bc)" секунды"
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
        sqlite3 kml_log.db "INSERT INTO filez (name_file, md5, doc_name, name, descript, coord, dolg, shir, whenn, date_ins) VALUES ('$new_name', '$md5', '$name_f', '$name_mark', '$des1', '$coord', '$dolg', '$shir', '$time_shtamp', '$(date +"%Y-%m-%d")');"
        show_progress $j $tasks_in_total
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
        sqlite3 kml_log.db "INSERT INTO filez (name_file, md5, doc_name, name, descript, coord, dolg, shir, whenn, date_ins) VALUES ('$new_name', '$md5', '$name_f', '$name_mark', '$des1', '$coord', '$dolg', '$shir', '$time_shtamp', '$(date +"%Y-%m-%d")');"
fi
#делаем html таблицу
echo "<!DOCTYPE html PUBLIC -//IETF//DTD HTML 2.0//EN><HTML lang="ru"><BODY> <meta charset="UTF-8"><table border="1">" > "$new_name"".html"
while read INPUT
do
    echo "<tr><td>${INPUT//|/</td><td>}</td></tr>" >> "$new_name"".html"
done < "$new_name.csv"
echo "</TABLE></BODY></HTML>" >> "$new_name"".html"
