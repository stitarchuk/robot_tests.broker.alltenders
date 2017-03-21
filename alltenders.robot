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
	Оновити тендер			${username}  ${tender_uaid}
	Run Keyword And Return  Змінити поле ${field_name}  ${field_data}
	Save Tender

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
	Should Not Be Equal		${value}	${None}
#	${value}=	Run Keyword If  '${field}' == 'value.valueAddedTaxIncluded'  Convert To Boolean  ${value}
#	...			ELSE IF  '${field}' == 'minimalStep.amount' or '${field}' == 'value.amount' or '${field}' == 'items[0].deliveryLocation.latitude' or '${field}' == 'items[0].deliveryLocation.longitude' or '${field}' == 'items[0].quantity'  Convert To Number  ${value} 
	${value}=	Run Keyword If  ${field.endswith('valueAddedTaxIncluded')}  Convert To Boolean  ${value}
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
	${procurementMethodType}=	Set Variable If  '${mode}' == 'single'  belowThreshold  ${data.procurementMethodType}
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
	${tender_json}=			Get Data By Angular
	Log object data			${tender_json}		tender_json		json
	Log object data			${tender}			created_tender
	
	#	--- save and send to prozorro ---
	${locator}=		Set Variable If  'negotiation' in '${procurementMethodType}' or '${procurementMethodType}' == 'reporting'	Активний	Період уточнень
	Save Tender		${locator}  ${True}
	#	--- gets tender data ---
	${tender_uaid}=			Get Data By Angular		tenderID
	${id}=    				Get Data By Angular		id
	Log						${tender_uaid}
	Set To Dictionary		${data}				id=${id}	tenderID=${tender_uaid}
	Log object data			${tender}			created_tender
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
	${index}=		Знайти індекс предмета по ідентифікатору  ${item_id}
	${value}=		Get Data By Angular  items[${index}].${field}
	Should Not Be Equal  ${value}  ${None}
	${value}=	Run Keyword If  ${field.endswith('valueAddedTaxIncluded')}  Convert To Boolean  ${value}
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
	${index}=		Знайти індекс лота по ідентифікатору	${lot_id}
	Set Data By Angular	lots[${index}].${field}				${value}
	Save Tender

Отримати інформацію із лоту
	[Arguments]		${username}  ${tender_uaid}  ${lot_id}  ${field}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		lot_id:			The ID of lot 
	...		field:			The name of field
	Оновити тендер	${username}  ${tender_uaid}
	${index}=		Знайти індекс лота по ідентифікатору  ${lot_id}
	${value}=		Get Data By Angular  lots[${index}].${field}
	Should Not Be Equal  ${value}  ${None}
	${value}=	Run Keyword If  ${field.endswith('valueAddedTaxIncluded')}  Convert To Boolean  ${value}
	...			ELSE IF  ${field.endswith('amount')}  Convert To Number  ${value} 
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
	Should Not Be Equal  ${value}  ${None}
	${value}=	Run Keyword If  ${field.endswith('value')}  Convert To Number  ${value} 
	...			ELSE  Set Variable  ${value}
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
	${index}=		Знайти індекс запитання по ідентифікатору  ${question_id}
	${value}=		Get Data By Angular  questions[${index}].${field}
	Should Not Be Equal  ${value}  ${None}
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
	alltenders.Відповісти на вимогу про виправлення умов закупівлі  ${username}  ${tender_uaid}  ${complaint_id}  ${answer_data}

Відповісти на вимогу про виправлення умов лоту
	[Arguments]		${username}  ${tender_uaid}  ${complaint_id}  ${answer_data}
	[Documentation]  Переводить вимогу зі статусу "claim" у статус "answered"
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		complaint_id:	The ID of the complaint
	...		answer_data: 	The data of answer
	Оновити тендер	${username}  ${tender_uaid}
	${index}=		Знайти індекс скарги по ідентифікатору  ${complaint_id}
	Run Keyword And Ignore Error  Set Data By Angular	complaints[${index}].resolution  				"${answer_data.data.resolution}"
	Run Keyword And Ignore Error  Set Data By Angular	complaints[${index}].resolutionType  			"${answer_data.data.resolutionType}"
	Run Keyword And Ignore Error  Set Data By Angular	complaints[${index}].status  					"${answer_data.data.status}"
	Run Keyword And Ignore Error  Set Data By Angular	complaints[${index}].tendererAction  			"${answer_data.data.tendererAction}"
	Save Tender
	Fail  Дане ключове слово не реалізовано


Створити вимогу
	[Arguments]		${username}  ${tender_uaid}  ${complaint}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		complaint:		The complaint that must be created
	${title}=				Get From Dictionary		${complaint.data}	title
	${description}=			Get From Dictionary		${complaint.data}	description
	Оновити тендер						${username}  ${tender_uaid}
	Wait and Click Button				${tender.form.menu.complaint}
	Wait Until Page Contains Element	${tender.complaint.form}				${common.wait}
	Wait and Input Text					${tender.complaint.form.title}			${title}
	Wait and Input Text					${tender.complaint.form.description}	${description}
#	Додати контакт						${tender.complaint.form.contact}		${contactPoint}
	Capture Page Screenshot
	Wait and Click Button				${tender.complaint.form.make}
	Wait and Click Link					${tender.menu.complaints}
	Wait Until Page Contains Element	${tender.form.complaint}				${common.wait}
	Capture Page Screenshot
	${complaint_index}=					Get Data By Angular				complaints.length
	${complaint_index}=					Evaluate	${complaint_index}-${1}
	${resp}=							Munchify Data By Angular		complaints[${complaint_index}]
	Set To Dictionary					${resp}							index=${complaint_index}
	[Return]	${resp}

Завантажити документацію до вимоги old
	[Arguments]		${username}  ${tender_uaid}  ${complaint}  ${filepath}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		complaint: 		The data of complaint
	...		filepath:		The path to file that will be uploaded
	${complaint_index}=					Get From Dictionary			${complaint}	index
	${complaint_form}=					Evaluate					${complaint_index}+1
	${complaint_form}=					Build Xpath For Parent		${tender.form.complaint}	${complaint_form}
	Оновити тендер						${username}  				${tender_uaid}
	Wait and Click Link					${tender.menu.complaints}
	Wait Until Page Contains Element	${complaint_form}			${common.wait}
	Upload File							${filepath}					${complaint_form}${tender.form.complaint.right.menu.button}	2
	Run Keyword And Return				Munchify Data By Angular	complaints[complaint_index].documents

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
	Оновити тендер	${username}  ${tender_uaid}
	${index}=		Знайти індекс скарги по ідентифікатору  ${complaint_id}
	${value}=		Get Data By Angular  complaints[${index}].${field}
	Should Not Be Equal  ${value}  ${None}
	[Return]	${value}

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
	Execute Angular Method	activate  bids
	Підтвердити дію в діалозі
	Capture Page Screenshot
	
		
#	${value}=	Convert To Number	${value}	2
#	Wait and Click Link					${tender.menu.bids}
#	Wait Until Page Contains Element	${tender.form.bid}					${common.wait}
#	Wait and Input Text					${tender.form.bid.value}			${value}
#	Wait and Click Button				${tender.form.bid.menu.save}
#	Wait and Click Button				${tender.form.bid.menu.activate}
#	Підтвердити дію в діалозі
#	Capture Page Screenshot

Отримати інформацію із пропозиції
	[Arguments]		${username}  ${tender_uaid}  ${field}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		field:			The name of field
	Оновити тендер			${username}  ${tender_uaid}
	Wait and Click Element	${tender.menu.bids}
	${value}=	Get Data By Angular  ${field}  bids
	Should Not Be Equal		${value}	${None}
	${value}=	Run Keyword If  ${field.endswith('valueAddedTaxIncluded')}  Convert To Boolean  ${value}
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
	Execute Angular Method	activate  bids
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
	Оновити тендер		${username}  		${tender_uaid}
	Execute Angular Method	delete  bids
	Підтвердити дію в діалозі
	Run Keyword And Return				Munchify Data By Angular		object_path=bids

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
#	[Return]   ${reply}
	
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
	Should Not Be Equal  ${value}  ${None}
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
