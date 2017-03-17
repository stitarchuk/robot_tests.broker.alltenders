*** Settings ***
Library		Selenium2Screenshots
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
	...		lot_index: Index of lot (default 0)
	Оновити тендер			${username}		${tender_uaid}
	Run Keyword And Return  Get Data By Angular  _lots[${lot_index}].auctionUrl

Отримати посилання на аукціон для учасника
	[Arguments]		${username}	${tender_uaid}  ${lot_index}=${0}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		lot_index: Index of lot (default 0)
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
	[Arguments]		${username}  ${field}
	[Documentation]
	...		username:	The name of user
	...		field:		The name of field
	Оновити тендер  ${username}  ${TENDER['TENDER_UAID']}
	${locator}=  Set Variable If  'questions' in '${field}'		${tender.menu.questions}
	...							'bids' in '${field}'			${tender.menu.bids}
	...							${tender.menu.description}
	Wait and Click Element		${locator}
	${value}=	Run Keyword If	'${field}' == 'status'	Execute Angular Method  getStatus  ELSE  Get Data By Angular  ${field}
	Should Not Be Equal		${value}	${None}
	${value}=	Run Keyword If  '${field}' == 'value.valueAddedTaxIncluded'  Convert To Boolean  ${value}
	...			ELSE IF  '${field}' == 'minimalStep.amount' or '${field}' == 'value.amount' or '${field}' == 'items[0].deliveryLocation.latitude' or '${field}' == 'items[0].deliveryLocation.longitude' or '${field}' == 'items[0].quantity'  Convert To Number  ${value} 
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
#	Run Keyword And Return	prepare_data  ${initial_data}

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
	${title}=					Get From Dictionary		${data}		title
	${description}=				Get From Dictionary		${data}		description
	${value}=					Get From Dictionary		${data}		value
	${minimalStep}=				Get From Dictionary		${data}		minimalStep
	${tenderPeriod}=			Get From Dictionary		${data}		tenderPeriod
	${items}=					Get From Dictionary		${data}		items
	${proposalStartDate}=		Convert Tender Datetime	${tenderPeriod}		startDate
	${proposalEndDate}=			Convert Tender Datetime	${tenderPeriod}		endDate
	
	Switch Browser				${username}
	#	--- create tender ---
	Wait and Click Element		${menu.newTender}
	Wait and Select In Combo	${create.tender.type}				${tenderType}
	Wait and Click Button		${create.tender.create}
	Sleep						2
	#	--- fill tender attributes ---
	Wait and Input Text			${tender.form.header.title}			${title}
	Wait and Input Text			${tender.form.header.description}	${description}
	Wait and Input Text			${tender.form.header.amount}		${value.amount}
	Wait and Select In Combo	${tender.form.header.currency}		${value.currency}
	Run Keyword If  '${value.valueAddedTaxIncluded}' == '${True}'  Wait and Click CheckBox	${tender.form.header.taxIncluded}
	Wait and Input Text			${tender.form.header.minimalStep}	${minimalStep.amount}
	Wait and Input Text			${tender.form.proposal.startDate}	${proposalStartDate}
	Wait and Input Text			${tender.form.proposal.endDate}		${proposalEndDate}
	#	--- get enquiryPeriod ---
	${status}  ${enquiryPeriod}=	Run Keyword And Ignore Error	Get From Dictionary		${data}	enquiryPeriod
	${enquiryStartDate}=		Convert Tender Datetime	${enquiryPeriod}	startDate
	${enquiryEndDate}=			Convert Tender Datetime	${enquiryPeriod}	endDate
	Run Keyword If  '${status}' == 'PASS'
	...		Run Keywords
	...			Wait and Input Text			${tender.form.enquiry.startDate}	${enquiryStartDate}
	...			AND
	...			Wait and Input Text			${tender.form.enquiry.endDate}		${enquiryEndDate}
	#	--- fill procuringEntity by JS ---
	Run Keyword And Ignore Error  Set Object By Angular  procuringEntity		${data.procuringEntity}
	#	--- fill multi-languages attributes by JS ---
	Run Keyword And Ignore Error  Set Data By Angular  description_ru			"${data.description_ru}"
	Run Keyword And Ignore Error  Set Data By Angular  description_en			"${data.description_en}"
	Run Keyword And Ignore Error  Set Data By Angular  title_ru					"${data.title_ru}"
	Run Keyword And Ignore Error  Set Data By Angular  title_en					"${data.title_en}"
	#	--- fill minimalStep currency by JS ---
	Run Keyword And Ignore Error  Set Data By Angular  minimalStep.amount		${minimalStep.amount}
	Run Keyword And Ignore Error  Set Data By Angular  minimalStep.currency		"${minimalStep.currency}"
	#	--- add lots ---
	${lots_map}=	Run Keyword If  '${mode}' == 'multiLot' or '${procurementMethodType}' == 'aboveThresholdUA' or '${procurementMethodType}' == 'aboveThresholdEU'
	...				Додати лоти  ${data.lots}
	...				ELSE  Create Dictionary	
	#	--- clear default item ---
	Execute Angular Method		items[0].delete
	Підтвердити дію в діалозі
	#	--- add items ---
	Додати предмети   			${items}	${lots_map}
	#	--- fill features ---
	${status}  ${features}=  Run Keyword And Ignore Error  Get From Dictionary  ${data}  features
	Run Keyword If  '${status}'=='PASS'  Run Keyword And Ignore Error	Додати нецінові показники	${features}
	#	--- save and send to prozorro ---
#	Save Tender		send=${True}
	Save Tender		Період уточнень  ${True}
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
	[Arguments]		${username}  ${tender_uaid}  ${item_id}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		item_id:		The ID of item to be removed
	Оновити тендер				${username}  ${tender_uaid}
	${index}=					Знайти індекс предмета по ідентифікатору	${item_id}
	Execute Angular Method		items[${index}].delete
	Підтвердити дію в діалозі
	Save Tender
			
Додати предмет закупівлі
	[Arguments]		${username}  ${tender_uaid}  ${item}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		item:			The item's data
	Оновити тендер			${username}  ${tender_uaid}
	${lot_index}=			Convert To Number		0
	${item_index}=			Get Data By Angular		items.length
	Додати предмет в лот	${item}  ${lot_index}  ${item_index}
	Save Tender				${tender_uaid}
	
Отримати інформацію із предмету
	[Arguments]		${username}  ${tender_uaid}  ${item_id}  ${field_name}
	Fail  Дане ключове слово не реалізовано

##############################################################################
#             Lot operations
##############################################################################

Видалити лот
	[Arguments]		${username}  ${tender_uaid}  ${lot_id}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		lot_id:			The ID of lot to be removed
	Оновити тендер				${username}  ${tender_uaid}
	${lot_index}=				Знайти індекс лота по ідентифікатору	${lot_id}
	${items_count}=				Get Data By Angular  lots[${lot_index}]._items.length
	Run Keyword If	${items_count} > 0  Fail  Неможливо видалити лот з прив’язаними предметами закупівлі 
	Execute Angular Method		lots[${lot_index}].delete
	Підтвердити дію в діалозі
	Save Tender

Додати предмет закупівлі в лот
	[Arguments]		${username}  ${tender_uaid}  ${lot_id}  ${item}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		lot_id:			The ID of lot
	...		item:			The item's data
	Оновити тендер			${username}  ${tender_uaid}
	${lot_index}=			Знайти індекс лота по ідентифікатору	${lot_id}
	${item_index}=			Get Data By Angular						lots[${lot_index}]._items.length
	Додати предмет в лот	${item}  ${lot_index}  ${item_index}
	Save Tender				${tender_uaid}

Завантажити документ в лот
	[Arguments]		${username}  ${filepath}  ${tender_uaid}  ${lot_id}
	[Documentation]
	...		username:		The name of user
	...		filepath:		The path to file that will be uploaded
	...		tender_uaid:	The UA ID of the tender
	Оновити тендер	${username}  ${tender_uaid}
	${lot_index}=	Знайти індекс лота по ідентифікатору	${lot_id}
	${idxs}=		Create List		${lot_index}
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
	Оновити тендер		${username}  ${tender_uaid}
	${lot_index}=		Знайти індекс лота по ідентифікатору	${lot_id}
	Set Data By Angular	lots[${lot_index}].${field}				${value}
	Save Tender

Отримати інформацію із лоту
	[Arguments]		${username}  ${lot_id}  ${field}
	[Documentation]
	...		username:	The name of user
	...		lot_id:		The ID of lot 
	...		field:		The name of field
	Reload Angular Page
	${lot_index}=		Знайти індекс лота по ідентифікатору	${lot_id}
	${value}=			Get Data By Angular						lots[${lot_index}].${field}
	Should Not Be Equal	${value}	${None}
	${value}=	Run Keyword If  '${field}' == 'value.valueAddedTaxIncluded'  					Convert To Boolean	${value}
	...			ELSE IF  '${field}' == 'minimalStep.amount' or '${field}' == 'value.amount'		Convert To Number	${value} 
	...			ELSE	Set Variable	${value}
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

##############################################################################
#             Feature operations
##############################################################################

Видалити неціновий показник
  [Arguments]		${username}  ${tender_uaid}  ${feature_id}  ${obj_id}=${Empty}
  Fail  Дане ключове слово не реалізовано

Додати неціновий показник на лот
	[Arguments]		${username}  ${tender_uaid}  ${feature}  ${lot_id}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		feature:		The feature data
	...		lot_id:			The ID of the lot
	Оновити тендер						${username}		${tender_uaid}
	Змінити неціновий показник на лот	${feature}		${lot_id}

Додати неціновий показник на предмет
	[Arguments]		${username}  ${tender_uaid}  ${feature}  ${item_id}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		feature:		The feature data
	...		item_id:		The ID of the item
	Оновити тендер							${username}		${tender_uaid}
	Змінити неціновий показник на предмет	${feature}		${item_id}

Додати неціновий показник на тендер
	[Arguments]		${username}  ${tender_uaid}  ${feature}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		feature:		The feature data
	Оновити тендер							${username}  ${tender_uaid}
	Змінити неціновий показник на тендер	${feature}
	
Отримати інформацію із нецінового показника
  [Arguments]		${username}  ${tender_uaid}  ${feature_id}  ${field_name}
  Fail  Дане ключове слово не реалізовано

##############################################################################
#             Questions
##############################################################################

Відповісти на питання
	[Arguments]		${username}  ${tender_uaid}  ${question_resp}  ${answer}  ${question_id}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		question_resp:	The question that must be asked 
	...		answer:			The question answer 
	...		question_id:	The question's ID
	Оновити тендер						${username}						${tender_uaid}
	${answer}=		Get From Dictionary	${answer.data}					answer
	${index}=		Find Index By Id	${question_resp}				${question_id}
	Wait and Click Link					${tender.menu.questions}
	Answer Question  					${index}  						${answer}
	Wait Until Page Contains Element	${tender.questions.form.grid}	${common.wait}
	Reload Angular Page
	Capture Page Screenshot

Задати питання до лоту
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

Задати питання на предмет
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

Задати питання
	[Arguments]		${username}  ${tender_uaid}  ${question}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		question:		The question that must be asked 
	Оновити тендер	${username}		${tender_uaid}
	Run Keyword And Return	Ask Question	${question}		${tender.form.menu.question}

Отримати інформацію із запитання
	[Arguments]		${username}  ${question_id}  ${field}
	[Documentation]
	...		username:		The name of user
	...		question_id:	The question's ID 
	...		field:			The name of field
	Reload Angular Page
	Wait and Click Link	${tender.menu.questions}
	${question_index}=	Знайти індекс запитання по ідентифікатору	${question_id}
	${value}=			Get Data By Angular							questions[${question_index}].${field}
	Should Not Be Equal	${value}	${None}
	[Return]	${value}
	






##############################################################################
#             Claims
##############################################################################

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

Завантажити документацію до вимоги
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

##############################################################################
#             Bid operations
##############################################################################

Завантажити документ в ставку
	[Arguments]		${username}  ${filepath}  ${tender_uaid}
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
	[Arguments]		${username}  ${filepath}  ${bidid}  ${docid}
	[Documentation]
	...		username:	The name of user
	...		filepath:	The path to file that will be uploaded
	...		bidid:		The ID rate
	...		docid:		The ID document
	Upload File		${filepath}		${tender.form.bid.menu.uploadFile}	upload_locator=${tender.changeFile}
	Run Keyword And Return	Munchify Data By Angular  object_path=bids.documents

Змінити цінову пропозицію
	[Arguments]		${username}  ${tender_uaid}  ${field}  ${value}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		field:			The name of field
	...		value:			The value to be set
	${value}=	Convert To Number	${value}	2
	Оновити тендер						${username}  		${tender_uaid}
	Wait and Click Link					${tender.menu.bids}
	Wait Until Page Contains Element	${tender.form.bid}					${common.wait}
	Wait and Input Text					${tender.form.bid.value}			${value}
	Wait and Click Button				${tender.form.bid.menu.save}
#	Wait and Click Button				${tender.form.bid.menu.activate}
#	Підтвердити дію в діалозі
	Capture Page Screenshot

Подати цінову пропозицію
	[Arguments]		${username}  ${tender_uaid}  ${bid}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		bid:			The data to be set
	Run Keyword If	'${mode}' == 'multiLot'  Fail	Неможливо подати цінову пропозицію без прив’язки до лоту
	Оновити тендер						${username}							${tender_uaid}
	Додати цінову пропозицію			${bid}
	Wait and Click Button				${tender.form.bid.menu.activate}
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
	[Arguments]		${username}  ${tender_uaid}  ${test_bid_data}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		test_bid_data:	The data to be remove
	${btn_remove}=		Build Xpath For Parent				${tender.form.bid.right.menu.button}  5
	Оновити тендер						${username}  		${tender_uaid}
	Wait and Click Link					${tender.menu.bids}
	Wait Until Page Contains Element	${tender.form.bid}	${common.wait}
	Wait and Click Button				${btn_remove}
	Підтвердити дію в діалозі
	Capture Page Screenshot
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
	
Отримати документ
	[Arguments]		${username}  ${tender_uaid}  ${doc_id}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	Reload Angular Page
	${doc_index}=		Знайти індекс документа по ідентифікатору	${doc_id}
	${value}=			Get Data By Angular							documents[${doc_index}]
	Should Not Be Equal	${value}	${None}
	[Return]	${value}

Отримати документ до лоту
	[Arguments]		${username}  ${tender_uaid}  ${lot_id}  ${doc_id}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	Run Keyword And Return  alltenders.Отримати документ  ${username}  ${tender_uaid}  ${doc_id}

Отримати інформацію із документа
	[Arguments]		${username}  ${tender_uaid}  ${doc_id}  ${field}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	Reload Angular Page
	${doc_index}=		Знайти індекс документа по ідентифікатору	${doc_id}
	${value}=			Get Data By Angular							documents[${doc_index}].${field}
	Should Not Be Equal	${value}	${None}
	[Return]	${value}

