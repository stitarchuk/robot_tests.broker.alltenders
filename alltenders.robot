*** Settings ***
Library		Selenium2Library
Library		String
Library		DateTime
Library		alltenders_service.py
Resource	alltenders_resource.robot
Resource	alltenders_subkeywords.robot
Resource	alltenders_utils.robot

*** Keywords ***
Отримати посилання на аукціон для глядача
	[Arguments]		${username}	${tender_uaid}  ${lot_index}=${0}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		lot_index:		Index of lot (default 0)
	Оновити тендер			${username}		${tender_uaid}
	Run Keyword And Return  Get Data By Angular  _lots[${lot_index}].auctionUrl

Підготувати клієнт для користувача
	[Arguments]  ${username}
	[Documentation]  Відкрити браузер, створити об’єкт api wrapper, тощо
	...		username:	The name of user
	Open Browser	${USERS.users['${username}'].homepage}	${USERS.users['${username}'].browser}	alias=${username}
	Maximize Browser Window
	Wait For Angular
	Run Keyword If	'${username}' != 'alltenders_Viewer'	Увійти в систему	${username}

##############################################################################
#             Tender operations
##############################################################################

Внести зміни в тендер
	[Arguments]		${username}  ${tender_uaid}  ${field_name}  ${field_data}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		field_name:		The name of field to be edit
	...		field_data:		The name of data to be input
	Оновити тендер	${username}  ${tender_uaid}
	${reply}=	Run Keyword  Змінити поле ${field_name}  ${field_data}
	Save Tender
	[Return]	${reply}

Оновити сторінку з тендером
	[Arguments]		${username}  ${tender_uaid}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	Switch Browser  ${username}
	Run Keyword If  '${username}' == '${viewer}'
	...		Go To  ${USERS.users['${username}'].homepage}
	...		ELSE  Reload Angular Page
	${tenderID}=		Get Data By Angular		tenderID
	#	--- check if page contains the tender --- 
	Run Keyword If  '${tenderID}' == '${tender_uaid}'
	...		Refresh Tender Data  ${username}
	...		ELSE  Знайти тендер по ідентифікатору  ${username}  ${tender_uaid}

Отримати інформацію із тендера
	[Arguments]		${username}  ${tender_uaid}  ${field}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		field:			The name of field
	Оновити тендер  ${username}  ${tender_uaid}
	${locator}=		Set Variable If  'questions' in '${field}'		${tender.menu.questions}
	...								'bids' in '${field}'			${tender.menu.bids}
	...								${tender.menu.description}
	Wait and Click Element		${locator}
	${value}=	Run Keyword If	'${field}' == 'status'	Execute Angular Method  getStatus  ELSE  Get Data By Angular  ${field}
	${value}=	Run Keyword If  '${value}' == '${None}'  Set Variable	${value}
	...			ELSE IF  ${field.endswith('valueAddedTaxIncluded')}  Convert To Boolean  ${value}
	...			ELSE IF  ${field.endswith('amount')} or ${field.endswith('quantity')} or ${field.endswith('latitude')} or ${field.endswith('longitude')}  Convert To Number  ${value} 
	...			ELSE	Set Variable	${value}
	[Return]	${value}

Підготувати дані для оголошення тендера
	[Arguments]		${username}  ${initial_data}  ${role_name}=tender_owner
	[Documentation]
	...		username:		The name of user
	...		initial_data:	The data dictionary of the tender
	${tender_data}=		Run Keyword If  '${role_name}' == 'tender_owner'
	...		prepare_data  ${initial_data}
	...		ELSE  Set Variable  ${initial_data}
	[Return]	${tender_data}

Пошук тендера по ідентифікатору
	[Arguments]		${username}  ${tender_uaid}  ${screenshot}==${True}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		screenshot:		Set true if need capture page screenshot
	Switch Browser		${username}
	Go To				${USERS.users['${username}'].homepage}
	Wait For Angular	
	Wait and Click Element				${menu.search}
	Wait and Input Text					${search.filter.values.common}	${tender_uaid}
	Click Button						${search.filter.search}
	Wait Until Page Contains			${tender_uaid}					${common.wait}
	Run Keyword If  					'${screenshot}' == '${True}'  Capture Page Screenshot
	Wait and Click Element				${search.grid.tenderInfo.title}//span[text() = "${tender_uaid}"]
	Wait Until Page Contains Element	${tender.form}					${common.wait}
	Refresh Tender Data					${username}

Створити тендер
	[Arguments]		${username}  ${tender}
	[Documentation]
	...		username:	The name of user
	...		tender:		The data dictionary of the tender
	${data}=					Get From Dictionary		${tender}	data
	${procurementMethodType}=	Set Variable If  '${mode}' == 'single' or '${mode}' == 'belowThreshold'  belowThreshold  ${data.procurementMethodType}
	${tenderType}=				Get Variable Value		${tenderTypes['${procurementMethodType}']}	Допорогова закупівля
	${items}=					Get From Dictionary		${data}			items
	Switch Browser				${username}
	#	--- create tender ---
	Wait and Click Element		${menu.newTender}
	Wait and Select In Combo	${create.tender.type}				${tenderType}
	Wait and Click Button		${create.tender.create}
	Sleep						2
	#	--- fill attributes for all tenders ---
	Run Keyword And Ignore Error  Set Data By Angular	title						"${data.title}"
	Run Keyword And Ignore Error  Set Data By Angular	title_ru					"${data.title_ru}"
	Run Keyword And Ignore Error  Set Data By Angular	title_en					"${data.title_en}"
	Run Keyword And Ignore Error  Set Data By Angular	description					"${data.description}"
	Run Keyword And Ignore Error  Set Data By Angular	description_ru				"${data.description_ru}"
	Run Keyword And Ignore Error  Set Data By Angular	description_en				"${data.description_en}"
	Run Keyword And Ignore Error  Set Object By Angular	value  						${data.value}
	Run Keyword And Ignore Error  Set Object By Angular	minimalStep  				${data.minimalStep}
	Run Keyword And Ignore Error  Set Data By Angular	minimalStep.amount			${data.minimalStep.amount}
	Run Keyword And Ignore Error  Set Object By Angular	tenderPeriod  				${data.tenderPeriod}
	Run Keyword And Ignore Error  Set Object By Angular	enquiryPeriod  				${data.enquiryPeriod}
	Run Keyword And Ignore Error  Set Object By Angular	procuringEntity				${data.procuringEntity}
	Run Keyword And Ignore Error  Set Data By Angular	cause						"${data.cause}"
	Run Keyword And Ignore Error  Set Data By Angular	causeDescription			"${data.causeDescription}"
	Run Keyword And Ignore Error  Set Data By Angular	procurementMethodDetails	"${data.procurementMethodDetails}"
	#	--- add lots ---
	Run Keyword And Ignore Error  Додати лоти			${data.lots}
	#	--- add items ---
	Execute Angular Method	items[0].delete
	Підтвердити дію в діалозі
	Додати предмети   		${items}
	#	--- fill features ---
	Run Keyword And Ignore Error  Додати нецінові показники	${data.features}
	#	--- save and send to prozorro ---
	${locator}=		Set Variable If  'negotiation' in '${procurementMethodType}' or '${procurementMethodType}' == 'reporting'	Активний	Період уточнень
	Save Tender		${locator}  ${True}
	#	--- gets tender data ---
	${tender_uaid}=			Get Data By Angular		tenderID
	${id}=    				Get Data By Angular		id
	Log						${tender_uaid}
	Set To Dictionary		${data}				id=${id}	tenderID=${tender_uaid}
	Log Object Data			${tender}			created_tender
	[Return]	${tender_uaid}

##############################################################################
#             Item operations
##############################################################################

Видалити предмет закупівлі
	[Arguments]		${username}  ${tender_uaid}  ${item_id}  ${lot_id}=${None}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		item_id:		The ID of item to be removed
	...		lot_id:			The ID of lot wich item to be removed
	Оновити тендер	${username}  ${tender_uaid}
	${index}=		Знайти індекс предмета по ідентифікатору	${item_id}
	Execute Angular Method		items[${index}].delete
	Підтвердити дію в діалозі
	Save Tender
			
Додати предмет закупівлі
	[Arguments]		${username}  ${tender_uaid}  ${item}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		item:			The item's data
	Оновити тендер	${username}  ${tender_uaid}
	Додати предмет	${item}
	Save Tender		${tender_uaid}
	
Отримати інформацію із предмету
	[Arguments]		${username}  ${tender_uaid}  ${item_id}  ${field}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		item_id:		The ID of item
	...		field:			The name of field
	Оновити тендер	${username}  ${tender_uaid}
	${index}=	Знайти індекс предмета по ідентифікатору  ${item_id}
	${value}=	Get Data By Angular  items[${index}].${field}
	${value}=	Run Keyword If  '${value}' == '${None}'  Set Variable	${value}
	...			ELSE IF  ${field.endswith('valueAddedTaxIncluded')}  Convert To Boolean  ${value}
	...			ELSE IF  ${field.endswith('amount')} or ${field.endswith('quantity')} or ${field.endswith('latitude')} or ${field.endswith('longitude')}  Convert To Number  ${value} 
	...			ELSE	Set Variable	${value}
	[Return]	${value}

##############################################################################
#             Lot operations
##############################################################################

Видалити лот
	[Arguments]		${username}  ${tender_uaid}  ${lot_id}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		lot_id:			The ID of lot to be removed
	Оновити тендер	${username}  ${tender_uaid}
	${index}=	Знайти індекс лота по ідентифікатору	${lot_id}
	${count}=	Get Data By Angular  lots[${index}]._items.length
	:FOR  ${idx}  IN RANGE  ${count}  0  -1
	\	Execute Angular Method		lots[${index}]._items[${idx-1}].delete
	\	Підтвердити дію в діалозі
	Execute Angular Method		lots[${index}].delete
	Підтвердити дію в діалозі
	Save Tender

Додати предмет закупівлі в лот
	[Arguments]		${username}  ${tender_uaid}  ${lot_id}  ${item}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		lot_id:			The ID of lot
	...		item:			The item's data
	Оновити тендер	${username}  ${tender_uaid}
	${index}=		Знайти індекс лота по ідентифікатору  ${lot_id}
	${lot_id}=		Get Data By Angular  lots[${index}].id
	Set To Dictionary  	${item}  relatedLot=${lot_id}
	Додати предмет	${item}
	Save Tender		${tender_uaid}

Завантажити документ в лот
	[Arguments]		${username}  ${filepath}  ${tender_uaid}  ${lot_id}
	[Documentation]
	...		username:		The name of user
	...		filepath:		The path to file that will be uploaded
	...		tender_uaid:	The UA ID of the tender
	Оновити тендер	${username}  ${tender_uaid}
	${index}=		Знайти індекс лота по ідентифікатору	${lot_id}
	${idxs}=		Create List		${index}
	${btn_locator}=	Build Xpath 	${tender.form.lot.menu.uploadFile}	@{idxs}
	Upload File		${filepath}		${btn_locator}

Змінити лот
	[Arguments]		${username}  ${tender_uaid}  ${lot_id}  ${field}  ${value}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		lot_id:			The ID of lot 
	...		field:			The name of field
	...		value:			The value to be set
	Оновити тендер	${username}  ${tender_uaid}
	${index}=	Знайти індекс лота по ідентифікатору	${lot_id}
	${value}=	Set Variable If  ${field.endswith('valueAddedTaxIncluded')} or ${field.endswith('amount')} or ${field.endswith('quantity')}  ${value}  "${value}"
	Set Data By Angular  lots[${index}].${field}  ${value}
	Save Tender

Отримати інформацію із лоту
	[Arguments]		${username}  ${tender_uaid}  ${lot_id}  ${field}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		lot_id:			The ID of lot 
	...		field:			The name of field
	Оновити тендер	${username}  ${tender_uaid}
	${index}=	Знайти індекс лота по ідентифікатору  ${lot_id}
	${value}=	Get Data By Angular  lots[${index}].${field}
	${value}=	Run Keyword If  '${value}' == '${None}'  Set Variable	${value}
	...			ELSE IF  ${field.endswith('valueAddedTaxIncluded')}  Convert To Boolean  ${value}
	...			ELSE IF  ${field.endswith('amount')} or ${field.endswith('quantity')}  Convert To Number  ${value} 
	...			ELSE	Set Variable  ${value}
	[Return]	${value}
	
Скасувати лот
  [Arguments]		${username}  ${tender_uaid}  ${lot_id}  ${cancellation_reason}  ${document}  ${new_description}
  Fail  Дане ключове слово не реалізовано
  
Створити лот
	[Arguments]		${username}  ${tender_uaid}  ${lot}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		lot:			The data of lot to be create
	Оновити тендер	${username}	${tender_uaid}
	${index}=		Додати лот	${lot.data}
	Save Tender
	Run Keyword And Return	Munchify Data By Angular 	lots[${index}]

Створити лот із предметом закупівлі
	[Arguments]		${username}  ${tender_uaid}  ${lot}  ${item}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		lot:			The data of lot to be create
	...		item:			The data of item to be add
	Оновити тендер	${username}	${tender_uaid}
	${index}=	Додати лот				${lot.data}
	${lot_id}=	Get Data By Angular		lots[${index}].id
	Set To Dictionary		${item}		relatedLot=${lot_id}
	Додати предмет			${item}
	Save Tender
	Run Keyword And Return	Munchify Data By Angular 	lots[${index}]

##############################################################################
#             Feature operations
##############################################################################

Видалити неціновий показник
	[Arguments]		${username}  ${tender_uaid}  ${feature_id}  ${obj_id}=${Empty}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		feature_id:		The ID of feature
  	Оновити тендер	${username}		${tender_uaid}
	${index}=		Знайти індекс нецінового показника по ідентифікатору  ${feature_id}
	Execute Angular Method		features[${index}].delete
	Підтвердити дію в діалозі
	Save Tender

Додати неціновий показник на лот
	[Arguments]		${username}  ${tender_uaid}  ${feature}  ${lot_id}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		feature:		The feature data
	...		lot_id:			The ID of the lot
	Оновити тендер	${username}		${tender_uaid}
	Змінити неціновий показник на лот	${feature}		${lot_id}

Додати неціновий показник на предмет
	[Arguments]		${username}  ${tender_uaid}  ${feature}  ${item_id}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		feature:		The feature data
	...		item_id:		The ID of the item
	Оновити тендер	${username}		${tender_uaid}
	Змінити неціновий показник на предмет	${feature}		${item_id}

Додати неціновий показник на тендер
	[Arguments]		${username}  ${tender_uaid}  ${feature}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		feature:		The feature data
	Оновити тендер	${username}  ${tender_uaid}
	Змінити неціновий показник на тендер	${feature}
	
Отримати інформацію із нецінового показника
	[Arguments]		${username}  ${tender_uaid}  ${feature_id}  ${field}
	Оновити тендер	${username}  ${tender_uaid}
	${index}=		Знайти індекс нецінового показника по ідентифікатору  ${feature_id}
	${value}=		Get Data By Angular  features[${index}].${field}
	${value}=	Run Keyword If  '${value}' == '${None}'  Set Variable	${value}
	...			ELSE IF  ${field.endswith('value')}  Convert To Number  ${value} 
	...			ELSE  Set Variable  ${value}
#	...			ELSE  Convert To String  ${value}
	[Return]	${value}

##############################################################################
#             Questions
##############################################################################

Відповісти на запитання
	[Arguments]		${username}  ${tender_uaid}  ${answer}  ${question_id}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		question_resp:	The question that must be asked 
	...		answer:			The question answer 
	...		question_id:	The question's ID
	Оновити тендер			${username}  ${tender_uaid}
	Wait and Click Link		${tender.menu.questions}
	${answer}=				Get From Dictionary  ${answer.data}  answer
	${index}=				Знайти індекс запитання по ідентифікатору  ${question_id}
	Answer Question  		${index}  ${answer}
	Wait Until Page Contains Element  ${tender.questions.form.grid}  ${common.wait}
	Reload Angular Page
	Capture Page Screenshot

Задати запитання на лот
	[Arguments]		${username}  ${tender_uaid}  ${lot_id}  ${question}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		lot_id:			The ID of lot 
	...		question:		The question that must be asked 
	Оновити тендер	${username}  ${tender_uaid}
	${lot_index}=	Знайти індекс лота по ідентифікатору	${lot_id}
	${idxs}=		Create List		${lot_index}
	${btn_locator}=	Build Xpath 	${tender.form.lot.menu.question}	@{idxs}
	Run Keyword And Return	Ask Question	${question}		${btn_locator}

Задати запитання на предмет
	[Arguments]		${username}  ${tender_uaid}  ${item_id}  ${question}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		lot_id:			The ID of lot 
	...		question:		The question that must be asked 
	Оновити тендер	${username}  ${tender_uaid}
	${item_index}=	Знайти індекс предмета по ідентифікатору	${item_id}
	${idxs}=		Create List		0  ${item_index}
	${btn_locator}=	Build Xpath 	${tender.form.item.menu.question}	@{idxs}
	Run Keyword And Return	Ask Question	${question}		${btn_locator}

Задати запитання на тендер
	[Arguments]		${username}  ${tender_uaid}  ${question}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		question:		The question that must be asked 
	Оновити тендер	${username}		${tender_uaid}
	Run Keyword And Return	Ask Question	${question}		${tender.form.menu.question}

Отримати інформацію із запитання
	[Arguments]		${username}  ${tender_uaid}  ${question_id}  ${field}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		question_id:	The question's ID 
	...		field:			The name of field
	Оновити тендер	${username}  ${tender_uaid}
	Wait and Click Link	${tender.menu.questions}
	${index}=	Знайти індекс запитання по ідентифікатору  ${question_id}
	${value}=	Get Data By Angular  questions[${index}].${field}
	[Return]	${value}
	
##############################################################################
#             Claims
##############################################################################

Відповісти на вимогу про виправлення умов закупівлі
	[Arguments]		${username}  ${tender_uaid}  ${complaint_id}  ${answer_data}
	[Documentation]  Переводить вимогу зі статусу "claim" у статус "answered"
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		complaint_id:	The ID of the complaint
	...		answer_data: 	The data of answer
	alltenders.Відповісти на вимогу про виправлення умов лоту  ${username}  ${tender_uaid}  ${complaint_id}  ${answer_data}

Відповісти на вимогу про виправлення умов лоту
	[Arguments]		${username}  ${tender_uaid}  ${complaint_id}  ${answer_data}
	[Documentation]  Переводить вимогу зі статусу "claim" у статус "answered"
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		complaint_id:	The ID of the complaint
	...		answer_data: 	The data of answer
	${index}=	Отримати індекс скарги	${username}  ${tender_uaid}  ${complaint_id}
	${info}=	Create Dictionary	
	Execute Angular Method  complaints[${index}].answer
	Execute Javascript
	...		angular.element('div[ng-form=pageComplaintAnswer]').scope().$apply(function(scope) {
	...			var model = scope.model;
	...			model.data.info = {
	...				description: "${answer_data.data.resolution}",
	...				type: "${answer_data.data.resolutionType}"
	...			};
	...			model.apply();
	...		});
	Wait For Progress Bar

Завантажити документацію до вимоги
	[Arguments]		${username}  ${tender_uaid}  ${complaint_id}  ${document}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		complaint_id: 	The ID of complaint
	...		document:		The document that will be uploaded
	${index}=	Отримати індекс скарги	${username}  ${tender_uaid}  ${complaint_id}
	Upload File By Angular  ${document}  complaints[${index}].upload

Отримати документ до скарги
	[Arguments]		${username}  ${tender_uaid}  ${complaint_id}  ${doc_id}  ${award_id}=${None}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		complaint_id:	The ID of the complaint
	...		doc_id:			The ID of the document
	...		award_id:		The ID of the award
	Run Keyword And Return  alltenders.Отримати документ  ${username}  ${tender_uaid}  ${doc_id}

Отримати інформацію із документа до скарги
  	[Arguments]		${username}  ${tender_uaid}  ${complaint_id}  ${doc_id}  ${field}  ${award_id}=${None}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		complaint_id:	The ID of the complaint
	...		doc_id:			The ID of the document
	...		field:			The name of field
	...		award_id:		The ID of the award
	Run Keyword And Return  alltenders.Отримати інформацію із документа  ${username}  ${tender_uaid}  ${doc_id}  ${field}
	
Отримати інформацію із скарги
	[Arguments]		${username}  ${tender_uaid}  ${complaint_id}  ${field}  ${award_id}=${None}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		complaint_id:	The ID of the complaint
	...		field:			The name of field
	...		award_id:		The ID of the award
	${index}=	Отримати індекс скарги	${username}  ${tender_uaid}  ${complaint_id}
	${value}=	Get Data By Angular  complaints[${index}].${field}
	[Return]	${value}

Перетворити вимогу про виправлення умов закупівлі в скаргу
	[Arguments]		${username}  ${tender_uaid}  ${complaint_id}  ${escalating_data}
	[Documentation]
	...		username:			The name of user
	...		tender_uaid:		The UA ID of the tender
	...		complaint_id:		The ID of the complaint
	...		escalating_data:	The escalating data 
	...		[Description]  Переводить вимогу у статус "pending"
	${index}=	Отримати індекс скарги	${username}  ${tender_uaid}  ${complaint_id}
	Execute Angular Method  complaints[${index}].pending
	Wait For Progress Bar

Перетворити вимогу про виправлення умов лоту в скаргу
	[Arguments]		${username}  ${tender_uaid}  ${complaint_id}  ${escalating_data}
	[Documentation]
	...		username:			The name of user
	...		tender_uaid:		The UA ID of the tender
	...		complaint_id:		The ID of the complaint
	...		escalating_data:	The escalating data 
	...		[Description]  Переводить вимогу у статус "pending"
	alltenders.Перетворити вимогу про виправлення умов закупівлі в скаргу  ${username}  ${tender_uaid}  ${complaint_id}  ${escalating_data}
	
Подати вимогу
	[Arguments]		${username}  ${tender_uaid}  ${complaint_id}  ${confirmation_data}
	[Documentation]
	...		username:			The name of user
	...		tender_uaid:		The UA ID of the tender
	...		complaint_id:		The ID of the complaint
	...		confirmation_data:	The confirmation data 
	...		[Description]  Переводить вимогу зі статусу "draft" у статус "claim"
	${index}=	Отримати індекс скарги	${username}  ${tender_uaid}  ${complaint_id}
	Execute Angular Method  complaints[${index}].claim
	Wait For Progress Bar

Підтвердити вирішення вимоги про виправлення умов закупівлі
	[Arguments]		${username}  ${tender_uaid}  ${complaint_id}  ${confirmation_data}
	[Documentation]
	...		username:			The name of user
	...		tender_uaid:		The UA ID of the tender
	...		complaint_id:		The ID of the complaint
	...		confirmation_data:	The confirmation data 
	...		[Description]  Переводить вимогу зі статусу "answered" у статус "resolved"
	${index}=	Отримати індекс скарги	${username}  ${tender_uaid}  ${complaint_id}
	Execute Angular Method  complaints[${index}].resolve
	Wait For Progress Bar

Підтвердити вирішення вимоги про виправлення умов лоту
	[Arguments]		${username}  ${tender_uaid}  ${complaint_id}  ${confirmation_data}
	[Documentation]
	...		username:			The name of user
	...		tender_uaid:		The UA ID of the tender
	...		complaint_id:		The ID of the complaint
	...		confirmation_data:	The confirmation data 
	...		[Description]  Переводить вимогу зі статусу "answered" у статус "resolved"
	alltenders.Підтвердити вирішення вимоги про виправлення умов закупівлі  ${username}  ${tender_uaid}  ${complaint_id}  ${confirmation_data}

Скасувати вимогу про виправлення умов закупівлі
	[Arguments]		${username}  ${tender_uaid}  ${complaint_id}  ${cancellation_data}
	[Documentation]
	...		username:			The name of user
	...		tender_uaid:		The UA ID of the tender
	...		complaint_id:		The ID of the complaint
	...		cancellation_data:	The cancelation data 
	...		[Description]  Переводить вимогу в статус "canceled"
	${index}=	Отримати індекс скарги	${username}  ${tender_uaid}  ${complaint_id}
	Execute Angular Method  complaints[${index}].cancel
	Execute Javascript
	...		angular.element('div[class="ui-dialog-content"]').scope().$apply(function(scope) {
	...			scope.data.data = {
	...				input: "${cancellation_data.data.cancellationReason}"
	...			};
	...			scope.actions.apply();
	...		});
	Wait For Progress Bar

Скасувати вимогу про виправлення умов лоту
	[Arguments]		${username}  ${tender_uaid}  ${complaint_id}  ${cancellation_data}
	[Documentation]
	...		username:			The name of user
	...		tender_uaid:		The UA ID of the tender
	...		complaint_id:		The ID of the complaint
	...		cancellation_data:	The cancelation data 
	...		[Description]  Переводить вимогу в статус "canceled"
	alltenders.Скасувати вимогу про виправлення умов закупівлі  ${username}  ${tender_uaid}  ${complaint_id}  ${cancellation_data}

Створити вимогу про виправлення умов закупівлі
	[Arguments]		${username}  ${tender_uaid}  ${claim}  ${document}=${None}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		claim:			The complaint that must be created
	...		document:		The the document that will be uploaded
	...		[Description]  Створює вимогу у статусі "claim". Можна створити вимогу як з документацією, так і без неї.
	...		[Return]  The complaintID
	${complaintID}=	alltenders.Створити чернетку вимоги про виправлення умов закупівлі  ${username}  ${tender_uaid}  ${claim}
	${status}=		Run Keyword And Return Status  Should Not Be Equal  ${document}  ${None}
	Run keyword If  ${status} == ${True}
	...				alltenders.Завантажити документацію до вимоги  ${username}  ${tender_uaid}  ${complaintID}  ${document}
	alltenders.Подати вимогу  ${username}  ${tender_uaid}  ${complaintID}  ${None}
	[Return]	${complaintID}
  
Створити вимогу про виправлення умов лоту
	[Arguments]		${username}  ${tender_uaid}  ${claim}  ${lot_id}  ${document}=${None}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		claim:			The complaint that must be created
	...		lot_id:			The ID of the lot
	...		document:		The the document that will be uploaded
	...		[Description]  Створює вимогу у статусі "claim". Можна створити вимогу як з документацією, так і без неї.
	...		Якщо lot_index == None, то створюється вимога про виправлення умов тендера.
	...		[Return]  The complaintID
	${complaintID}=	alltenders.Створити чернетку вимоги про виправлення умов лоту  ${username}  ${tender_uaid}  ${claim}  ${lot_id}
	${status}=		Run Keyword And Return Status  Should Not Be Equal  ${document}  ${None}
	Run keyword If  ${status} == ${True}
	...				alltenders.Завантажити документацію до вимоги  ${username}  ${tender_uaid}  ${complaintID}  ${document}
	alltenders.Подати вимогу  ${username}  ${tender_uaid}  ${complaintID}  ${None}
	[Return]	${complaintID}

Створити чернетку вимоги про виправлення умов закупівлі
	[Arguments]		${username}  ${tender_uaid}  ${claim}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		claim:			The complaint that must be created
	...		[Description]  Створює вимогу у статусі "draft".
	...		[Return]  The complaintID
	Оновити тендер	${username}  ${tender_uaid}
	Execute Angular Method  complaint
	${complaintID}=	Створити вимогу  ${claim}
	[Return]	${complaintID}

Створити чернетку вимоги про виправлення умов лоту
	[Arguments]		${username}  ${tender_uaid}  ${claim}  ${lot_id}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		claim:			The complaint that must be created
	...		lot_id:			The ID of the lot
	...		[Description]  Створює вимогу у статусі "draft".
	...		Якщо lot_index == None, то створюється вимога про виправлення умов тендера.
	...		[Return]  The complaintID
	Run Keyword And Return If  '${lot_id}' == '${None}'
	...		alltenders.Створити чернетку вимоги про виправлення умов закупівлі  ${username}  ${tender_uaid}  ${claim}
	Оновити тендер	${username}  ${tender_uaid}
	${index}=		Знайти індекс лота по ідентифікатору  ${lot_id}
	${relatedLot}=	Get Data By Angular  lots[${lot_index}].id
	Set to dictionary  ${claim.data}  relatedLot=${relatedLot}
	Execute Angular Method  lots[${lot_index}].complaint
	${complaintID}=	Створити вимогу  ${claim}
	[Return]	${complaintID}

##############################################################################
#             Bid operations
##############################################################################

Завантажити документ в ставку
	[Arguments]		${username}  ${filepath}  ${tender_uaid}  ${doc_type}=documents
	[Documentation]
	...		username:		The name of user
	...		filepath:		The path to file that will be uploaded
	...		tender_uaid:	The UA ID of the tender
	Оновити тендер						${username}  		${tender_uaid}
	Wait and Click Link					${tender.menu.bids}
	Wait Until Page Contains Element	${tender.form.bid}	${common.wait}
	${tender}=  		Get Data By Angular
	${tender_file}=		extract_file_name  ${filepath}
	Log Object Data  ${tender}  ${tender_file}  json
	Upload File							${filepath}			${tender.form.bid.menu.uploadFile}
	Run Keyword And Return				Munchify Data By Angular		object_path=bids.documents

Змінити документ в ставці
	[Arguments]		${username}  ${tender_uaid}  ${filepath}   ${docid}
	[Documentation]
	...		username:	The name of user
	...		tender_uaid:	The UA ID of the tender
	...		filepath:	The path to file that will be uploaded
	...		docid:		The ID document
	Оновити тендер			${username}  ${tender_uaid}
	Wait and Click Element	${tender.menu.bids}
	Upload File		${filepath}		${tender.form.bid.menu.uploadFile}	upload_locator=${tender.changeFile}
	Run Keyword And Return	Munchify Data By Angular  object_path=bids.documents

Змінити документацію в ставці
	[Arguments]		${username}  ${tender_uaid}  ${doc_data}   ${docid}
	[Documentation]
	...		username:	The name of user
	...		tender_uaid:	The UA ID of the tender
	...		doc_data:	The path to file that will be uploaded
	...		docid:		The ID document
	Оновити тендер			${username}  ${tender_uaid}
	Wait and Click Element  ${tender.menu.bids}
	Execute Angular Method  upload  bids
	${data}=	Object To Json  ${doc_data}
#	${data}=	Get Data By Angular			docuemnts	bids
#	${index}=	Find Document Index By Id	${data}		${doc_id}
#	${document}=	Find Document By Id		${tender}  ${doc_id}
	Execute Javascript
	...		angular.element('files > div').scope().$apply(function(scope) {
	...			var data = ${data}, files = scope.ctrl._files, i = 0, file, title, key;
	...			for (; i < files.length; i++) {
	...				file = files[i]; title = file.title;
	...				if (title && title.indexOf("${doc_id}") != -1) {
	...					for (key in data) {
	...						file[key] = data[key];
	...					}
	...				}
	...			}
	...			scope.model.save();
	...		});
	Wait For Progress Bar

Змінити цінову пропозицію
	[Arguments]		${username}  ${tender_uaid}  ${field}  ${value}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		field:			The name of field
	...		value:			The value to be set
	Оновити тендер			${username}  ${tender_uaid}
	Wait and Click Element	${tender.menu.bids}
	Set Object By Angular	${field}	${value}	bids
	Execute Angular Method	save  bids
	Wait For Progress Bar
	Execute Angular Method	_activate  bids
	${status}=	Run Keyword And Return Status  Page Should Contain Element  ${dialog}
	Run Keyword If  ${status}  Підтвердити дію в діалозі
	Capture Page Screenshot

Отримати інформацію із пропозиції
	[Arguments]		${username}  ${tender_uaid}  ${field}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		field:			The name of field
	Оновити тендер			${username}  ${tender_uaid}
	Wait and Click Element	${tender.menu.bids}
	Capture Page Screenshot
	${value}=	Get Data By Angular  ${field}  bids
	${value}=	Run Keyword If  '${value}' == '${None}'  Set Variable	${value}
	...			ELSE IF  ${field.endswith('valueAddedTaxIncluded')}  Convert To Boolean  ${value}
	...			ELSE IF  ${field.endswith('amount')} or ${field.endswith('quantity')} or ${field.endswith('latitude')} or ${field.endswith('longitude')}  Convert To Number  ${value} 
	...			ELSE	Set Variable	${value}
	[Return]	${value}
  
Отримати посилання на аукціон для учасника
	[Arguments]		${username}	${tender_uaid}  ${lot_index}=${0}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		lot_index:		Index of lot (default 0)
	Оновити тендер			${username}		${tender_uaid}
	Run Keyword And Return  Get Data By Angular  _lots[${lot_index}].auctionUrl

Подати цінову пропозицію
	[Arguments]		${username}  ${tender_uaid}  ${bid}  ${lots_ids}=${None}  ${features_ids}=${None}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		bid:			The data to be set
	...		lots_ids:		The IDs of lots
	Оновити тендер	${username}  ${tender_uaid}
	${tender}=		Munchify Data By Angular
	${contact}=		Get From Dictionary		 ${bid.data.tenderers[0]}	contactPoint
	${features}=	Get From Dictionary	${bid.data}  parameters
	${values}=		Create List
	#	--- fill lots info ---
	${lots_ids}=	Run Keyword If  ${lots_ids}  Set Variable  ${lots_ids}
	...		ELSE  Create List
	:FOR  ${index}  ${lot_id}  IN ENUMERATE  @{lots_ids}
	\	${lot_index}=	Find Index By Id	${tender.lots}  ${lot_id}
	\	${lot_id}=		Get Variable Value	${tender.lots[${lot_index}].id}
	\	Set To Dictionary	${bid.data.lotValues[${index}]}  relatedLot=${lot_id}
	\	${value}=		Create Dictionary  id=${lot_id}  value=${bid.data.lotValues[${index}].value.amount}
	\	Append To List	${values}  ${value}
	#	--- fill features info ---
	${features_ids}=		Run Keyword If  ${features_ids}  Set Variable  ${features_ids}
	...		ELSE  Create List
	:FOR  ${index}  ${feature_id}  IN ENUMERATE  @{features_ids}
	\	${feature_index}=	Find Index By Id	${tender.features}  ${feature_id}
	\	${code}=			Get Variable Value	${tender.features[${feature_index}].code}
	\	Set To Dictionary	${bid.data.parameters[${index}]}  code=${code}
	${data}=		Create Dictionary	contact=${contact}  features=${features}  value=${values}
	${data}=		Object To Json		${data}
	Execute Javascript	angular.element('body').scope().$apply(function(scope){scope.context.tender._lots[0]._makeBid(${data});});
	Wait For Progress Bar
	Execute Angular Method	_activate  bids
	Підтвердити дію в діалозі
	Capture Page Screenshot
	Run Keyword And Return				Munchify Data By Angular			object_path=bids

Подати цінову пропозицію на лоти
    [Arguments]    ${username}  ${tender_uaid}  ${bid}  ${lots_ids}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		bid:			The data to be set
	...		lots_ids:		List of lot's ID
	Оновити тендер				${username}  	${tender_uaid}
	Додати цінову пропозицію	${bid}			lots_ids=${lots_ids}
	Capture Page Screenshot

Скасувати цінову пропозицію
	[Arguments]		${username}  ${tender_uaid}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	Оновити тендер			${username}  		${tender_uaid}
	Execute Angular Method	delete  bids
	Підтвердити дію в діалозі
	Run Keyword And Return  Munchify Data By Angular  object_path=bids

##############################################################################
#             Document operations
##############################################################################

Завантажити документ
	[Arguments]		${username}  ${filepath}  ${tender_uaid}
	[Documentation]
	...		username:		The name of user
	...		filepath:		The path to file that will be uploaded
	...		tender_uaid:	The UA ID of the tender
	Оновити тендер	${username}		${tender_uaid}
	Upload File		${filepath}		${tender.form.menu.uploadFile}
	
Отримати документ
	[Arguments]		${username}  ${tender_uaid}  ${doc_id}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		doc_id:			The ID of the document
	Оновити тендер	${username}		${tender_uaid}
	${document}=	Знайти документ по ідентифікатору		${doc_id}
	${url}=			Get From Dictionary			${document}	url
	${title}=		Get From Dictionary			${document}	title
	${filename}=	Download Document From Url  ${url}  	${OUTPUT_DIR}${/}${title}
	[return]	${filename}

Отримати документ до лоту
	[Arguments]		${username}  ${tender_uaid}  ${lot_id}  ${doc_id}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		lot_id:			The ID of the lot
	...		doc_id:			The ID of the document
	Run Keyword And Return  alltenders.Отримати документ  ${username}  ${tender_uaid}  ${doc_id}

Отримати інформацію із документа
	[Arguments]		${username}  ${tender_uaid}  ${doc_id}  ${field}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		doc_id:			The ID of the document
	...		field:			The name of field
	Оновити тендер	${username}  ${tender_uaid}
	${document}=	Знайти документ по ідентифікатору	${doc_id}
	${value}=		Get From Dictionary		${document}	${field}
	[Return]	${value}

##############################################################################
#             Qualification operations
##############################################################################

Завантажити документ рішення кваліфікаційної комісії
	[Arguments]		${username}  ${document}  ${tender_uaid}  ${award_num}
	[Documentation]
  	...		username:		The name of user
	...		document:		The path to file that will be uploaded
	...		tender_uaid:	The UA ID of the tender
	...		award_num:		The qualification number
	...		[Description] Find tender using uaid,  and call upload_qualification_document
	...		[Return] Reply of API
	${upload_btn}=		Build Xpath		${tender.form.awards.menu.uploadFile}	${award_num}
	Оновити тендер	${username}			${tender_uaid}
	Wait and Click Element				${tender.menu.awards}
	Upload File							${document}								${upload_btn}
	#[Return]  ${doc}

Підтвердити постачальника
	[Arguments]		${username}  ${tender_uaid}  ${award_num}
	[Documentation]
  	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		award_num:		The qualification number
  	...		[Description] Find tender using uaid, create dict with confirmation data and call patch_award
	...		[Return] Nothing
	${activate_btn}=	Build Xpath		${tender.form.awards.menu.activate}		${award_num}
	Оновити тендер	${username}			${tender_uaid}
	Wait and Click Element				${tender.menu.awards}
	Wait and Click Button				${activate_btn}
	Підтвердити дію в діалозі

Дискваліфікувати постачальника
	[Arguments]		${username}  ${tender_uaid}  ${award_num}
	[Documentation]
  	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		award_num:		The qualification number
  	...		[Description] Find tender using uaid, create data dict with unsuccessful status and call patch_award
	...		[Return] Reply of API
	${cancel_btn}=		Build Xpath		${tender.form.awards.menu.cancel}		${award_num}
	Оновити тендер	${username}			${tender_uaid}
	Wait and Click Element				${tender.menu.awards}
	Wait and Click Button				${cancel_btn}
	Підтвердити дію в діалозі
	#[Return]  ${reply}


Скасування рішення кваліфікаційної комісії
	[Arguments]		${username}  ${tender_uaid}  ${award_num}
	[Documentation]
  	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		award_num:		The qualification number
  	...		[Description] Find tender using uaid, create data dict with unsuccessful status and call patch_award
	...		[Return] Reply of API
	Оновити тендер	${username}		${tender_uaid}
	Wait and Click Element			${tender.menu.awards}
	#[Return]  ${reply}

##############################################################################
#             Limited procurement
##############################################################################

Створити постачальника, додати документацію і підтвердити його
	[Arguments]		${username}  ${tender_uaid}  ${supplier_data}  ${document}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		supplier_data:	The data of the supplier
	...		document:		The path to file that will be uploaded
	...		[Description] Find tender using uaid and call create_award, add documentation to that award and update his status to active
	...		[Return] Nothing
	Оновити тендер	${username}			${tender_uaid}
	${data}=  			Object To Json  	${supplier_data.data}
	#	--- create award ---
	Execute Javascript	angular.element('body').scope().$apply(function(scope){scope.context.tender.createAward(${data});});
	Wait Until Page Contains Element	${award}				${common.wait}
	Wait and Click Button				${award.create}
	Wait For Progress Bar
	#	--- upload documentation ---
	alltenders.Завантажити документ рішення кваліфікаційної комісії	${username}  ${document}  ${tender_uaid}  ${0}
	alltenders.Підтвердити постачальника							${username}  ${tender_uaid}  ${0}
	Capture Page Screenshot

Скасувати закупівлю
	[Arguments]		${username}  ${tender_uaid}  ${cancel_reason}  ${document}  ${new_description}
	[Documentation]
	...		username:			The name of user
	...		tender_uaid:		The UA ID of the tender
	...		cancel_reason:		The reason of the cancellation
	...		document:			The path to file that will be uploaded
	...		new_description:	The new description of document
	...		[Description] Find tender using uaid, set cancellation reason, get data from cancel_tender
	...		and call create_cancellation
	...		After that add document to cancellation and change description of document
	...		[Return] Nothing
	Fail  Дане ключове слово не реалізовано
	Оновити тендер	${username}		${tender_uaid}

Завантажити документацію до запиту на скасування
	[Arguments]		${username}  ${tender_uaid}  ${cancel_id}  ${document}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		cancel_id:		The ID of the cancellation
	...		document:		The path to file that will be uploaded
	...		[Description] Find tender using uaid, and call upload_cancellation_document
	...		[Return] ID of added document
	Fail  Дане ключове слово не реалізовано
	Оновити тендер	${username}		${tender_uaid}
	[Return]  ${doc_reply.data.id}

Змінити опис документа в скасуванні
	[Arguments]		${username}  ${tender_uaid}  ${cancel_id}  ${document_id}  ${new_description}
	[Documentation]
	...		username:			The name of user
	...		tender_uaid:		The UA ID of the tender
	...		cancel_id:			The ID of the cancellation
	...		document_id:		The ID of the document
	...		new_description:	The new description of document
	...		[Description] Find tender using uaid, create dict with data about description and call
	...		patch_cancellation_document
	...		[Return] Nothing
	Fail  Дане ключове слово не реалізовано
	Оновити тендер	${username}		${tender_uaid}

Завантажити нову версію документа до запиту на скасування
	[Arguments]		${username}  ${tender_uaid}  ${cancel_num}  ${doc_num}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		cancel_num:		The number of the cancellation
	...		doc_num:		The number of the cancellation document
	...		[Description] Find tender using uaid, create fake documentation and call update_cancellation_document
	...		[Return] Nothing
	Fail  Дане ключове слово не реалізовано
	Оновити тендер	${username}		${tender_uaid}

Підтвердити скасування закупівлі
	[Arguments]		${username}  ${tender_uaid}  ${cancel_id}
	[Documentation]
  	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		cancel_id:		The ID of the cancellation
	...		[Description] Find tender using uaid, get cancellation test_confirmation data and call patch_cancellation
	...		[Return] Nothing
	Fail  Дане ключове слово не реалізовано
	Оновити тендер	${username}		${tender_uaid}

Підтвердити підписання контракту
	[Arguments]		${username}  ${tender_uaid}  ${contract_num}
	[Documentation]
  	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		contract_num:	The number of contract
	...		[Description] Find tender using uaid, get contract test_confirmation data and call patch_contract
	...		[Return] Nothing
	Оновити тендер	${username}		${tender_uaid}
	${endDate}=		Get Data By Angular	awards[0].complaintPeriod.endDate
	${sleep}=		Wait To Date	${endDate}
	Run Keyword If  ${sleep} > 0	Fail  Неможливо укласти угоду для переговорної процедури поки не пройде stand-still період
	Wait and Click Element			${tender.menu.contracts}
	Run Keyword And Ignore Error  Set Data By Angular  _contract._clone.contractNumber  ${contract_num}
	Execute Javascript  angular.element('body').scope().$apply(function(scope){scope.context.tender._contract.activate(true);});
	Підтвердити дію в діалозі

Отримати документ до скасування
	[Arguments]		${username}  ${tender_uaid}  ${cancel_id}  ${doc_id}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		cancel_id:		The ID of the cancellation
	...		doc_id:			The ID of the document
	Run Keyword And Return  alltenders.Отримати документ  ${username}  ${tender_uaid}  ${doc_id}

##############################################################################
#             OpenUA procedure
##############################################################################

Підтвердити кваліфікацію
	[Arguments]		${username}  ${tender_uaid}  ${qualification_num}
	[Documentation]
	...		username:			The name of user
	...		tender_uaid:		The UA ID of the tender
	...		qualification_num:	The number of the qualification
	...		[Description] Find tender using uaid, create data dict with active status and call patch_qualification
	...		[Return] Reply of API
	Оновити тендер	${username}		${tender_uaid}
	${tender}=  Get Data By Angular
	Log Object Data  ${tender}  activate_qualification_${qualification_num}  json
	${index}=	Get Qualification Index  ${qualification_num}
	Execute Angular Method  _qualifications[${index}].activate
	Підтвердити дію в діалозі

Відхилити кваліфікацію
	[Arguments]		${username}  ${tender_uaid}  ${qualification_num}
	[Documentation]
	...		username:			The name of user
	...		tender_uaid:		The UA ID of the tender
	...		qualification_num:	The number of the qualification
	...		[Description] Find tender using uaid, create data dict with unsuccessful status and call patch_qualification
	...		[Return] Reply of API
	Оновити тендер	${username}		${tender_uaid}
	${tender}=  Get Data By Angular
	Log Object Data  ${tender}  reject_qualification_${qualification_num}  json
	${index}=	Get Qualification Index  ${qualification_num}
	Execute Angular Method  _qualifications[${index}].reject
	Підтвердити дію в діалозі

Завантажити документ у кваліфікацію
	[Arguments]		${username}  ${document}  ${tender_uaid}  ${qualification_num}
	[Documentation]
	...		username:			The name of user
	...		tender_uaid:		The UA ID of the tender
	...		document:			The document to be upload
	...		qualification_num:	The number of the qualification
	...		[Description] Find tender using uaid,  and call upload_qualification_document
	...		[Return] Reply of API
	Оновити тендер	${username}		${tender_uaid}
	${index}=		Get Qualification Index  ${qualification_num}
	${read_only}=	Get Data By Angular		_qualifications[${index}].$behavior.upload_readonly
	Should Not Be True		${read_only}
	Upload File By Angular	${document}  	_qualifications[${index}].upload

Скасувати кваліфікацію
	[Arguments]		${username}  ${tender_uaid}  ${qualification_num}
	[Documentation]
	...		username:			The name of user
	...		tender_uaid:		The UA ID of the tender
	...		qualification_num:	The number of the qualification
	...		[Description] Find tender using uaid, create data dict with cancelled status and call patch_qualification
	...		[Return] Reply of API
	Оновити тендер	${username}		${tender_uaid}
	${tender}=  Get Data By Angular
	Log Object Data  ${tender}  cancel_qualification_${qualification_num}  json
	${index}=	Get Qualification Index  ${qualification_num}
	Execute Angular Method  _qualifications[${index}].cancel
	Capture Page Screenshot
	Підтвердити дію в діалозі
	Capture Page Screenshot

Затвердити остаточне рішення кваліфікації
	[Arguments]		${username}  ${tender_uaid}
	[Documentation]
	...		username:			The name of user
	...		tender_uaid:		The UA ID of the tender
	...		[Description] Find tender using uaid and call patch_tender
	...		[Return] Reply of API
	Оновити тендер	${username}		${tender_uaid}
	Wait and Click Element			${tender.menu.activeAfterQualification}
	Підтвердити дію в діалозі
