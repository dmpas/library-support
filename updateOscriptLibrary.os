#Использовать json
#Использовать fs
#Использовать gitrunner
#Использовать logos
#Использовать opm

Перем Лог;
Перем ЭтоВин;

Процедура ВывестиЛинию()
	Лог.Информация("===========================");
КонецПроцедуры

// Копипаст из opm + подставлен РабочийКаталог
//
Функция ПрочитатьОписаниеПакета(Знач РабочийКаталог) Экспорт
	
	ОписаниеПакета = Новый ОписаниеПакета();
	
	ПутьКМанифесту = ОбъединитьПути(РабочийКаталог, "packagedef");
	
	Файл_Манифест = Новый Файл(ПутьКМанифесту);
	Если Файл_Манифест.Существует() Тогда
		Контекст = Новый Структура("Описание", ОписаниеПакета);
		ЗагрузитьСценарий(ПутьКМанифесту, Контекст);
	КонецЕсли;		
	
	Возврат ОписаниеПакета;
	
КонецФункции

Процедура СформироватьList(КаталогПубликации)

	ПутьКСпискуПакетов = ОбъединитьПути(КаталогПубликации, "list.txt");
	
	НайденныеФайлы = НайтиФайлы(КаталогПубликации, ПолучитьМаскуВсеФайлы(), Ложь);
	
	ЗаписьТекста = Новый ЗаписьТекста(ПутьКСпискуПакетов, КодировкаТекста.UTF8NoBom);
	
	Для Каждого НайденныйФайл Из НайденныеФайлы Цикл	
		Если НайденныйФайл.ЭтоФайл() Тогда
			Продолжить;
		КонецЕсли;
		
		ЗаписьТекста.ЗаписатьСтроку(НайденныйФайл.Имя);	
	КонецЦикла;
	
	ЗаписьТекста.Закрыть();

КонецПроцедуры	

Си = Новый СистемнаяИнформация;
ЭтоВин = Найти(СИ.ВерсияОС, "Windows") > 0;

КаталогСборки = ОбъединитьПути(ТекущийКаталог(), "build");
КаталогИсходников = ОбъединитьПути(КаталогСборки, "src");
КаталогСобранныхПакетов = ОбъединитьПути(КаталогСборки, "out");

ФС.ОбеспечитьКаталог(КаталогСборки);
ФС.ОбеспечитьКаталог(КаталогИсходников);
ФС.ОбеспечитьПустойКаталог(КаталогСобранныхПакетов);

Лог = Логирование.ПолучитьЛог("libUpdate");

Сервер = "https://api.github.com";
Соединение = Новый HTTPСоединение(Сервер);

Ресурс = "/orgs/oscript-library/repos";
Заголовки = Новый Соответствие();
Заголовки.Вставить("Accept", "application/vnd.github.v3+json");
Заголовки.Вставить("User-Agent", "oscript-library-autobuilder");

ТокенАвторизации = Си.ПолучитьПеременнуюСреды("GITHUB_OAUTH_TOKEN");
Если ЗначениеЗаполнено(ТокенАвторизации) Тогда
	Заголовки.Вставить("Authorization", СтрШаблон("token %1", ТокенАвторизации));
КонецЕсли;

Лог.Информация("Запрашиваю список репозиториев");

Запрос = Новый HTTPЗапрос(Ресурс, Заголовки);
Ответ  = Соединение.Получить(Запрос);

Если Ответ.КодСостояния <> 200 Тогда
	Сообщить(Ответ.ПолучитьТелоКакСтроку());
	ВызватьИсключение Ответ.КодСостояния;
КонецЕсли;

ПарсерJSON = Новый ПарсерJSON();
ДанныеОтвета = ПарсерJSON.ПрочитатьJSON(Ответ.ПолучитьТелоКакСтроку());

КаталогПубликации = Си.ПолучитьПеременнуюСреды("PATH_TO_OSCRIPT_HUB");
Если НЕ ЗначениеЗаполнено(КаталогПубликации) Тогда
	КаталогПубликации = "/var/www/hub.oscript.io/download";
КонецЕсли;

ПутьККэшуБиблиотек = ОбъединитьПути(КаталогПубликации, "libData.json");
Если НЕ ФС.ФайлСуществует(ПутьККэшуБиблиотек) Тогда
	ЗаписьТекста = Новый ЗаписьТекста;
	ЗаписьТекста.Открыть(ПутьККэшуБиблиотек, КодировкаТекста.UTF8NoBOM);
	ЗаписьТекста.Записать("{}");
	ЗаписьТекста.Закрыть();
КонецЕсли;

ЧтениеТекста = Новый ЧтениеТекста;
ЧтениеТекста.Открыть(ПутьККэшуБиблиотек, КодировкаТекста.UTF8NoBOM);
ТекстКэшБиблиотек = ЧтениеТекста.Прочитать();
ЧтениеТекста.Закрыть();
КэшБиблиотек = ПарсерJSON.ПрочитатьJSON(ТекстКэшБиблиотек);

Для Каждого Репозиторий Из ДанныеОтвета Цикл
	
	ВывестиЛинию();
	
	ИмяРепозитория = Репозиторий.Получить("name");

	Лог.Информация("Обрабатываю " + ИмяРепозитория);
	КаталогПакета = ОбъединитьПути(КаталогСобранныхПакетов, ИмяРепозитория);
	ФС.ОбеспечитьПустойКаталог(КаталогПакета);
	
	ПутьКРепозиторию = Репозиторий.Получить("clone_url");
	ЭтоФорк = Репозиторий.Получить("fork");
	КаталогРепозитория = ОбъединитьПути(КаталогИсходников, ИмяРепозитория);
	
	Если НЕ ФС.КаталогСуществует(КаталогРепозитория) Тогда
		ГитМенеджер = Новый ГитРепозиторий();
		ГитМенеджер.УстановитьРабочийКаталог(КаталогИсходников);
		ГитМенеджер.КлонироватьРепозиторий(ПутьКРепозиторию);
		Лог.Информация("Репозиторий успешно склонирован: " + ИмяРепозитория);
	КонецЕсли;
	
	ГитРепозиторий = Новый ГитРепозиторий();
	ГитРепозиторий.УстановитьРабочийКаталог(КаталогРепозитория);
	
	ГитРепозиторий.ПерейтиВВетку("master");
	ГитРепозиторий.Получить();
	
	Если ЭтоФорк Тогда
		Лог.Информация("Это форк. Получаю информацию о родителе");
		РесурсРепозиторий = "/repos/oscript-library/" + ИмяРепозитория;
		ЗапросРепозиторий = Новый HTTPЗапрос(РесурсРепозиторий, Заголовки);
		ОтветРепозиторий  = Соединение.Получить(ЗапросРепозиторий);
		ТелоОтвета = ОтветРепозиторий.ПолучитьТелоКакСтроку();
		ДанныеОтветаРепозиторий = ПарсерJSON.ПрочитатьJSON(ТелоОтвета);
		ПутьКРепозиториюРодителю = ДанныеОтветаРепозиторий.Получить("parent").Получить("clone_url");
		
		ВнешниеРепозитории = ГитРепозиторий.ПолучитьСписокВнешнихРепозиториев();
		ВнешнийРепозиторийУжеДобавлен = Ложь;
		Для Каждого ВнешнийРепозиторий Из ВнешниеРепозитории Цикл
			Если ВнешнийРепозиторий.Адрес = ПутьКРепозиториюРодителю Тогда
				ВнешнийРепозиторийУжеДобавлен = Истина;
				Прервать;
			КонецЕсли;
		КонецЦикла;
		
		Если НЕ ВнешнийРепозиторийУжеДобавлен Тогда
			ГитРепозиторий.ДобавитьВнешнийРепозиторий("origin1", ПутьКРепозиториюРодителю);
			ГитРепозиторий.Получить("origin1", "master");
		КонецЕсли;

		Лог.Информация("Информация о родителе получена");

	КонецЕсли;
	
	ГитРепозиторий.ОбновитьПодмодули(Истина, Истина);
	
	ГитРепозиторий.Отправить();
	
	Попытка
		ОписаниеПакета = ПрочитатьОписаниеПакета(КаталогРепозитория);
		СвойстваПакета = ОписаниеПакета.Свойства();
	Исключение
		Лог.Ошибка("Некорректный манифест в репозитории <%1>", ИмяРепозитория);
		Лог.Ошибка(ОписаниеОшибки());
		УдалитьФайлы(КаталогПакета);
		Продолжить;
	КонецПопытки;

	ИДБиблиотеки = СвойстваПакета.Имя;
	ВерсияБиблиотеки = СвойстваПакета.Версия;
	
	ДанныеБиблиотеки = КэшБиблиотек.Получить(ИДБиблиотеки);
	Если ДанныеБиблиотеки = Неопределено Тогда
		ДанныеБиблиотеки = Новый Соответствие;
	КонецЕсли;
	ПоследняяВерсия = ДанныеБиблиотеки.Получить("lastVersion");
	Если ПоследняяВерсия = ВерсияБиблиотеки Тогда
		Лог.Информация("Версия пакета %1 совпадает с версией в БД.", ИДБиблиотеки);
		Лог.Информация("Пропускаю сборку");
		УдалитьФайлы(КаталогПакета);
		Продолжить;
	КонецЕсли;
	МассивВерсий = ДанныеБиблиотеки.Получить("versions");
	Если МассивВерсий = Неопределено Тогда
		МассивВерсий = Новый Массив;
	КонецЕсли;
	Если МассивВерсий.Найти(ВерсияБиблиотеки) = Неопределено Тогда
		МассивВерсий.Добавить(ВерсияБиблиотеки);
	КонецЕсли; 

	ДанныеБиблиотеки.Вставить("id", ИДБиблиотеки);	
	ДанныеБиблиотеки.Вставить("lastVersion", ВерсияБиблиотеки);
	ДанныеБиблиотеки.Вставить("versions", МассивВерсий);

	Если ЭтоВин Тогда
		СтрокаКоманды = СтрШаблон("cmd /C opm build %1", КаталогРепозитория);
	Иначе
		СтрокаКоманды = СтрШаблон("bash -c ""opm build %1""", КаталогРепозитория);
	КонецЕсли;
	КодВозврата = 0;
	Лог.Информация("Запускаю сборку");
	ЗапуститьПриложение(СтрокаКоманды, КаталогПакета, Истина, КодВозврата);
	
	Если КодВозврата = 0 Тогда
		Сообщение = СтрШаблон("Пакет <%1> успешно собран", ИмяРепозитория);    
		КэшБиблиотек.Вставить(ИДБиблиотеки, ДанныеБиблиотеки);
	Иначе
		Сообщение = СтрШаблон("Ошибка сборки пакета <%1>", ИмяРепозитория); 
	КонецЕсли;
	Лог.Информация(Сообщение);
	
	НайденныеФайлы = НайтиФайлы(КаталогПакета, ПолучитьМаскуВсеФайлы());
	Если НайденныеФайлы.Количество() = 0 Тогда
		УдалитьФайлы(КаталогПакета);
		Продолжить;
	КонецЕсли;
	
	ИмяПакета = СтрРазделить(НайденныеФайлы[0].Имя, "-")[0];
	КопироватьФайл(НайденныеФайлы[0].ПолноеИмя, ОбъединитьПути(КаталогПакета, ИмяПакета) + ".ospx");
	
	Если ИмяПакета <> ИмяРепозитория Тогда
		ФС.КопироватьСодержимоеКаталога(КаталогПакета, ОбъединитьПути(КаталогСобранныхПакетов, ИмяПакета));
		УдалитьФайлы(КаталогПакета);
	КонецЕсли;
	
КонецЦикла;

ВывестиЛинию();
Лог.Информация("Сборка пакетов завершена");

ВывестиЛинию();
Лог.Информация("Публикую библиотеки в хаб");
ФС.КопироватьСодержимоеКаталога(КаталогСобранныхПакетов, КаталогПубликации);
Лог.Информация("Пакеты опубликованы");

ТекстКэшБиблиотек = ПарсерJSON.ЗаписатьJSON(КэшБиблиотек);
ЗаписьТекста = Новый ЗаписьТекста;
ЗаписьТекста.Открыть(ПутьККэшуБиблиотек, КодировкаТекста.UTF8NoBOM);
ЗаписьТекста.Записать(ТекстКэшБиблиотек);
ЗаписьТекста.Закрыть();

Лог.Информация("База пакетов обновлена");

СформироватьList(КаталогПубликации);
Лог.Информация("Обновлен list.txt");
