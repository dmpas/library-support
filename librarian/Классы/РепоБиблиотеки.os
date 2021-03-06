#Использовать gitrunner
#Использовать logos
#Использовать opm
#Использовать fs

Перем ИмяРепозитория;
Перем ЭтоФорк;
Перем ПутьSSH;
Перем URLДетальнойИнформации;
Перем КаталогРабочейКопии;

Перем Лог;
Перем ЭтоВин;

Процедура НастроитьПоОписанию(Знач ОписаниеРепо) Экспорт

	ИмяРепозитория = ОписаниеРепо.ИмяРепозитория;
	ЭтоФорк = ОписаниеРепо.ЭтоФорк;
	ПутьSSH = ОписаниеРепо.ПутьSSH;
	URLДетальнойИнформации = ОписаниеРепо.URLДетальнойИнформации;

КонецПроцедуры

Процедура УстановитьКаталогРабочейКопии(Знач Каталог) Экспорт
	КаталогРабочейКопии = Каталог;
КонецПроцедуры

Процедура ПолучитьАктуальныйКод(Знач ИмяВетки) Экспорт

	Лог.Информация(СтрШаблон("Клонирую ветку %1 в %2", ИмяВетки, КаталогРабочейКопии));
	ФС.ОбеспечитьПустойКаталог(КаталогРабочейКопии);

	ГитМенеджер = Новый ГитРепозиторий();
	ГитМенеджер.УстановитьРабочийКаталог(КаталогРабочейКопии);
	ГитМенеджер.КлонироватьРепозиторий(ПутьSSH, КаталогРабочейКопии);

	ГитМенеджер.ПерейтиВВетку(ИмяВетки);
	ГитМенеджер.Получить();

КонецПроцедуры

Функция ПрочитатьОписаниеПакета(Знач РабочийКаталог)

	ОписаниеПакета = Новый ОписаниеПакета();

	ПутьКМанифесту = ОбъединитьПути(РабочийКаталог, "packagedef");

	Файл_Манифест = Новый Файл(ПутьКМанифесту);
	Если Файл_Манифест.Существует() Тогда
		Контекст = Новый Структура("Описание", ОписаниеПакета);
		ЗагрузитьСценарий(ПутьКМанифесту, Контекст);
	КонецЕсли;

	Возврат ОписаниеПакета;

КонецФункции

Процедура СобратьПакет(Знач КаталогПакета) Экспорт

	Лог.Информация("Каталог пакета: %1", КаталогПакета);

	ОписаниеПакета = ПрочитатьОписаниеПакета(КаталогРабочейКопии);
	СвойстваПакета = ОписаниеПакета.Свойства();

	Если ЭтоВин Тогда
		СтрокаКоманды = СтрШаблон("cmd /C opm build %1", КаталогРабочейКопии);
	Иначе
		СтрокаКоманды = СтрШаблон("bash -c ""opm build %1""", КаталогРабочейКопии);
	КонецЕсли;
	КодВозврата = 0;
	Лог.Информация("Запускаю сборку %1", СтрокаКоманды);
	ЗапуститьПриложение(СтрокаКоманды, КаталогПакета, Истина, КодВозврата);

	ПакетУспешноСобран = КодВозврата = 0;
	Если ПакетУспешноСобран Тогда
		Лог.Информация("Пакет <%1> успешно собран", ИмяРепозитория);
	Иначе
		Лог.Ошибка("Ошибка сборки пакета <%1>", ИмяРепозитория);
	КонецЕсли;

	НайденныеФайлы = НайтиФайлы(КаталогПакета, ПолучитьМаскуВсеФайлы());
	Если НайденныеФайлы.Количество() = 0 Тогда
		Возврат;
	КонецЕсли;

	ИмяПакетаМассив = СтрРазделить(НайденныеФайлы[0].Имя, "-");
	ИмяПакета = "";
	Для сч = 0 По ИмяПакетаМассив.ВГраница() - 1 Цикл
		ИмяПакета = ИмяПакета + ИмяПакетаМассив[сч] + "-";
	КонецЦикла;
	ИмяПакета = Лев(ИмяПакета, СтрДлина(ИмяПакета) - 1);

	КопироватьФайл(НайденныеФайлы[0].ПолноеИмя, ОбъединитьПути(КаталогПакета, ИмяПакета) + ".ospx");

КонецПроцедуры

Лог = Логирование.ПолучитьЛог("oscript.infrastructure");
Си = Новый СистемнаяИнформация;
ЭтоВин = Найти(СИ.ВерсияОС, "Windows") > 0;
