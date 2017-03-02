*** Settings ***
Library		alltenders_service.py
Resource	alltenders.robot
Resource	alltenders_resource.robot
Resource	alltenders_utils.robot

*** Keywords ***
Додати контакт
	[Arguments]		${button_locator}	${contactPoint}
	[Documentation]
	...		button_locator:		The locator of button to open the contact form
	...		contactPoint:		The data of the contact
	Wait and Click Button				${button_locator}
	Wait Until Page Contains Element	${tender.contact.form}					${common.wait}
	Wait and Click Button				${tender.contact.form.create}
	Wait and Input Text					${tender.contact.form.name}				${contactPoint.name}
	Wait and Input Text					${tender.contact.form.telephone}		${contactPoint.telephone}
	Wait and Click Button				${tender.contact.form.save}
	Sleep								2
	Wait and Click Element				${tender.contact.form}//a[text()[contains(., "${contactPoint.name}")]]

Додати лот
	[Arguments]		${lot}
	[Documentation]
	...		lot: The lot's data
	Wait and Click Element		${tender.menu.addLot}
	Wait For Angular
	Sleep						1
	#	--- check for dialog ---
	${status}=	Run Keyword And Return Status  Page Should Contain Element  ${dialog}
	Run Keyword If  ${status}  Підтвердити дію в діалозі
	...			ELSE	 Wait For Progress Bar
	#	--- get data by Angular
	${lot_index}=				Get Data By Angular		lots.length
	${lot_index}=				Evaluate				${lot_index}-${1}
	${valueAddedTaxIncluded}=	Get Data By Angular		lots[${lot_index}].value.valueAddedTaxIncluded
	${idxs}=					Create List				${lot_index}
	#	--- fill lot attributes ---
	Build Xpath and Run Keyword	${idxs}  Wait and Input Text			${tender.form.lot.title}		${lot.title}
	Build Xpath and Run Keyword	${idxs}  Wait and Input Text			${tender.form.lot.description}	${lot.description}
	Build Xpath and Run Keyword	${idxs}  Wait and Input Text			${tender.form.lot.amount}		${lot.value.amount}
	Run Keyword If  '${lot.value.valueAddedTaxIncluded}' != '${valueAddedTaxIncluded}'
	...		Build Xpath and Run Keyword	${idxs}  Wait and Click CheckBox	${tender.form.lot.taxIncluded}
	Build Xpath and Run Keyword	${idxs}  Wait and Input Text			${tender.form.lot.minimalStep}	${lot.minimalStep.amount}
	#	--- fill multi-languages attributes by JS ---
	Run Keyword And Ignore Error  Set Data By Angular  lots[${lot_index}].description_ru						"${lot.description_ru}"
	Run Keyword And Ignore Error  Set Data By Angular  lots[${lot_index}].description_en						"${lot.description_en}"
	Run Keyword And Ignore Error  Set Data By Angular  lots[${lot_index}].title_ru								"${lot.title_ru}"
	Run Keyword And Ignore Error  Set Data By Angular  lots[${lot_index}].title_en								"${lot.title_en}"
	#	--- fill other by JS ---
	Run Keyword And Ignore Error  Set Data By Angular  lots[${lot_index}].id  									"${lot.id}"
	Run Keyword And Ignore Error  Set Data By Angular  lots[${lot_index}].minimalStep.currency					"${lot.minimalStep.currency}"
	Run Keyword And Ignore Error  Set Data By Angular  lots[${lot_index}].minimalStep.valueAddedTaxIncluded		${lot.minimalStep.valueAddedTaxIncluded}
	Run Keyword And Ignore Error  Set Data By Angular  lots[${lot_index}].value.currency						"${lot.value.currency}"
	[Return]	${lot_index}
	
Додати лоти
	[Arguments]		${lots}
	[Documentation]
	...		lot: The lot's data
	${lot_map}=		Create Dictionary
	:FOR  ${lot}  IN  @{lots}
	\	${index}=			Додати лот			${lot}
	\	${lot_data}=		Create Dictionary	index=${index}  		items_count=${0}
	\	Set To Dictionary	${lot_map}			${lot.id}=${lot_data}
	[Return]	${lot_map}

Додати нецінові показники
	[Arguments]		${features}
	[Documentation]
	...		features: The features data
	Run Keyword And Ignore Error  Set Object By Angular  features  ${features}

Додати період уточнень
	[Arguments]		${enquiryPeriod}
	[Documentation]
	...		enquiryPeriod:	The enquiry period data
	${enquiryStartDate}=	Convert Tender Datetime		${enquiryPeriod}	startDate
	${enquiryEndDate}=		Convert Tender Datetime		${enquiryPeriod}	endDate
	Wait and Input Text		${tender.form.enquiry.startDate}	${enquiryStartDate}
	Wait and Input Text		${tender.form.enquiry.endDate}		${enquiryEndDate}
		
Додати предмети
	[Arguments]		${items}  ${lots_map}
	[Documentation]
	...		items:		The items data
	...		lots_map:	The map of lots (key = lot_id, value = lot_index)
	${tender_index}=	Set Variable  ${0}
	:FOR  ${item}  IN  @{items}
	\	${status}	${lot_id}=		Run Keyword And Ignore Error  Get From Dictionary  ${item}  relatedLot
	\	${status}	${lot_data}=	Run Keyword If  '${status}' == 'PASS'  Run Keyword And Ignore Error  Get From Dictionary  ${lots_map}  ${lot_id}
	\	${lot_data}=				Run Keyword If  '${status}' == 'PASS'  Set Variable  ${lot_data}  ELSE  Create Dictionary  index=${0}  items_count=${tender_index}
	\	${lot_index}=				Get From Dictionary	${lot_data}  index
	\	${item_index}=				Get From Dictionary	${lot_data}  items_count
	\	${next_item}=				Evaluate			${item_index}+1
	\	Set To Dictionary			${lot_data}			items_count=${next_item}
	\	${tender_index}=			Set Variable If  '${status}' == 'PASS'  ${tender_index}  ${next_item}
	\	Додати предмет в лот		${item}  ${lot_index}  ${item_index}

Додати предмет
	[Arguments]		${item}  ${lot_index}=${0}  ${item_index}=${0}
	[Documentation]
	...		item: The item's data
	...		lot_index: Index of lot (default 0)
	...		item_index: Index of item (default 0)
	${idxs}=				Create List				${lot_index}	${item_index}
	${description}=			Get From Dictionary		${item}									description
	${quantity}=			Get From Dictionary		${item}									quantity
	${cpv}=					Get From Dictionary		${item}									classification
	${dkpp}=				Get From Dictionary		${item.additionalClassifications[0]}	id								
	${unit}=				Get From Dictionary		${item}									unit
	${deliveryLocation}=	Get From Dictionary		${item}									deliveryLocation
	${deliveryAddress}=		Get From Dictionary		${item}									deliveryAddress
	${deliveryDate}=		Convert Tender Datetime	${item.deliveryDate}					endDate
	#	--- fill item header ---
	Build Xpath and Run Keyword	${idxs}  Wait and Input Text		${tender.form.item.description}		${description}
	Build Xpath and Run Keyword	${idxs}  Wait and Select In Combo	${tender.form.item.cpv}				${cpv.id}		2
	Build Xpath and Run Keyword	${idxs}  Wait and Select In Combo	${tender.form.item.dkpp}			${dkpp}			2
	Build Xpath and Run Keyword	${idxs}  Wait and Input Text		${tender.form.item.quantity}		${quantity}
	Build Xpath and Run Keyword	${idxs}  Wait and Select In Combo	${tender.form.item.unit}			${unit.code}	2
	Build Xpath and Run Keyword	${idxs}  Wait and Input Text		${tender.form.item.deliveryEndDate}	${deliveryDate}

	#	--- fill multi-languages attributes by JS ---
	Run Keyword And Ignore Error  Set Data By Angular  items[${item_index}].description_ru					"${item.description_ru}"
	Run Keyword And Ignore Error  Set Data By Angular  items[${item_index}].description_en					"${item.description_en}"
	#	--- fill cpv attributes by JS ---
	Run Keyword And Ignore Error  Set Data By Angular  items[${item_index}].classification.description		"${cpv.description}"
	Run Keyword And Ignore Error  Set Data By Angular  items[${item_index}].classification.description_ru	"${cpv.description_ru}"
	Run Keyword And Ignore Error  Set Data By Angular  items[${item_index}].classification.description_en	"${cpv.description_en}"
	#	--- fill unit attributes by JS ---
	Run Keyword And Ignore Error  Set Data By Angular  items[${item_index}].unit.name						"${unit.name}"
	Run Keyword And Ignore Error  Set Data By Angular  items[${item_index}].unit.name_ru					"${unit.name_ru}"
	Run Keyword And Ignore Error  Set Data By Angular  items[${item_index}].unit.name_en					"${unit.name_en}"
	#	--- fill delivery location by JS ---
	Run Keyword And Ignore Error  Set Object By Angular	items[${item_index}].deliveryLocation				${deliveryLocation}
	#	--- fill delivery address by JS ---
	Run Keyword And Ignore Error  Set Object By Angular	items[${item_index}].deliveryAddress				${deliveryAddress}

Додати предмет в лот
	[Arguments]		${item}  ${lot_index}=${0}  ${item_index}=${0}
	[Documentation]
	...		item: The item's data
	...		lot_index: Index of lot (default 0)
	...		item_index: Index of item (default 0)
	${idxs}=		Create List	${lot_index}
	Build Xpath and Run Keyword	${idxs}	Wait and Click Button	${tender.form.lot.addItem}
	Wait For Progress Bar
	Додати предмет	${item}  ${lot_index}  ${item_index}

Додати цінову пропозицію
	[Arguments]		${bid}  ${lot_index}=${0}  ${lots_ids}=${False}
	[Documentation]
	...		bid:		The bid's data to be set
	...		lot_index:	Index of lot (default 0)
	...		lots_ids:	List ID of lots
	${data}=	Get From Dictionary		${bid}						data
	${idxs}=	Create List				${lot_index}
	Build Xpath and Run Keyword	${idxs}  Wait and Click Button		${tender.form.lot.menu.bid}
	Run Keyword If  ${lots_ids}		Set Bids	${bid.data.lotValues}	${lots_ids}
	...		ELSE	Set Bid  ${bid.data.value}  ${idxs}
#	Додати контакт						${tender.contact.form.select}
	Wait and Click CheckBox				${tender.contact.form}//ui-checkbox[@ng-model="model.data.ch1"]
	Wait and Click CheckBox				${tender.contact.form}//ui-checkbox[@ng-model="model.data.ch2"]
	Wait and Click Button				${tender.contact.form.make}
	Wait For Progress Bar
	Wait and Click Link					${tender.menu.bids}
	Wait Until Page Contains Element	${tender.form.bid}					${common.wait}

Змінити неціновий показник
	[Arguments]		${feature}  ${enums_length}=${2}
	[Documentation]
	...		feature:		The feature data
	...		enums_length:	The length of feature's enums
	Wait Until Page Contains Element	${tender.form.feature}				${common.wait}
	#	--- fill feature ---
	${title}=		Decode Bytes String	${feature.title}
	${description}=	Decode Bytes String	${feature.description}
	Wait and Input Text		${tender.form.feature.title}		${title}
	Wait and Input Text		${tender.form.feature.description}	${description}
	#	--- fill enums ---
	${enums}=		Get From Dictionary	${feature}				enum
	${item_title}=	Convert To String 	${tender.form.feature.item.title}
	${item_value}=	Convert To String 	${tender.form.feature.item.value}
	${index}=		Set Variable		${1}
	:FOR  ${enum}  IN  @{enums}
	\	${value}=	Convert To Number	${enum.value}	2
	\	${title}=	Decode Bytes String	${enum.title}
	\	Run Keyword If  ${value} == 0
	\	...		Run Keywords
	\	...			Wait and Input Text  ${item_title.format(0)}  ${title}
	\	...			AND
	\	...			Continue For Loop
	\	Run Keyword If  ${index} >= ${enums_length}	Click Button  ${tender.form.feature.add}
	\	Wait and Input Text  ${item_title.format(${index})}	${title}
	\	Wait and Input Text  ${item_value.format(${index})}	${value}
	\	${index}=	Set Variable		${index + 1}
	Capture Page Screenshot
	Wait and Click Button	${tender.form.feature.apply}
	Wait For Progress Bar
	

Змінити неціновий показник на лот
	[Arguments]		${feature}  ${lot_id}
	[Documentation]
	...		feature:	The feature data
	...		lot_id:		The ID of the lot
	${length}=		Set Variable							${2}
	${lot_index}=	Знайти індекс лота по ідентифікатору	${lot_id}
	${idxs}=		Create List								${lot_index}
	${lot_id}=		Get Data By Angular						lots[${lot_index}].id
	${features}=	Get Data By Angular						features
	:FOR  ${index}  ${cur_feature}  IN ENUMERATE  @{features}
	\	${featureOf}=	Get From Dictionary  ${cur_feature}	featureOf
	\	${relatedItem}=	Get From Dictionary  ${cur_feature}	relatedItem
	\	Continue For Loop If  '${featureOf}' != 'lot' or '${relatedItem}' != '${lot_id}'
	\	${length}=		Get Data By Angular  features[${index}].enum.length
	\	Exit For Loop
	Build Xpath and Run Keyword	${idxs}  Wait and Click Button		${tender.form.lot.addFeature}
	Змінити неціновий показник	${feature}	${length}
	Build Xpath and Run Keyword	${idxs}  Wait and Click CheckBox	${tender.form.lot.showFeature}

Змінити неціновий показник на предмет
	[Arguments]		${feature}  ${item_id}
	[Documentation]
	...		feature:	The feature data
	...		item_id:	The ID of the item
	Fail  Функція поки не реалізовано в сценарії автоматичного тестування

Змінити неціновий показник на тендер
	[Arguments]		${feature}
	[Documentation]
	...		feature:		The feature data
	Wait and Click Button		${tender.form.addFeature}
	Змінити неціновий показник	${feature}
	Wait and Click CheckBox		${tender.form.showFeature}

Змінити поле features
	[Arguments]		${features}
	[Documentation]
	...		features: The features data
	:FOR  ${feature}  IN  @{features}
	\	${featureOf}=		Get From Dictionary		${feature}	featureOf
	\	Run Keyword If  '${featureOf}' == 'tenderer'
	\	...		Run Keywords
	\	...			Змінити неціновий показник на тендер  ${feature}
	\	...			AND
	\	...			Continue For Loop
	\	${status}	${relatedItem}=	Run Keyword And Ignore Error  Get From Dictionary  ${feature}  relatedItem
	\	Continue For Loop If  '${status}' != 'PASS'
	\	Run Keyword If	'${featureOf}' == 'lot'		Змінити неціновий показник на лот		${feature}  ${relatedItem}
	\	...			ELSE IF	'${featureOf}' == 'item'	Змінити неціновий показник на предмет	${feature}  ${relatedItem}

Змінити поле description
	[Arguments]		${description}
	[Documentation]	Change the description
	Wait and Input Text		${tender.form.header.description}	${description}

Змінити поле tenderPeriod.endDate
	[Arguments]		${endDate}
	[Documentation]	Change the final date for submission of proposals
	Wait and Input Text		${tender.form.proposal.endDate}		${endDate}

Знайти індекс документа по ідентифікатору
	[Arguments]		${doc_id}
	[Documentation]
	...		doc_id:			The document's ID 
	${documents}=	Get Data By Angular		documents
	${index}=		Find Index By Id		${documents}	${doc_id}
	Run Keyword If	${index} < 0	Fail	Документ id=${doc_id} не знайдено
	[Return]	${index}

Знайти індекс запитання по ідентифікатору
	[Arguments]		${question_id}
	[Documentation]
	...		question_id:	The question's ID 
	${questions}=	Get Data By Angular		questions
	${index}=		Find Index By Id		${questions}	${question_id}
	Run Keyword If	${index} < 0	Fail	Запитання id=${question_id} не знайдено
	[Return]	${index}

Знайти індекс лота по ідентифікатору
	[Arguments]		${lot_id}
	[Documentation]
	...		lot_id:			The ID of the lot
	${lots}=		Get Data By Angular		lots
	${index}=		Find Index By Id		${lots}		${lot_id}
	Run Keyword If	${index} < 0	Fail	Лот id=${lot_id} не знайдено
	[Return]	${index}

Знайти індекс предмета по ідентифікатору
	[Arguments]		${item_id}
	[Documentation]
	...		item_id:		The ID of item
	${items}=		Get Data By Angular		items
	${index}=		Find Index By Id		${items}	${item_id}
	Run Keyword If	${index} < 0	Fail	Предмет закупівлі id=${item_id} не знайдено
	[Return]	${index}

Знайти запитання по ідентифікатору
	[Arguments]		${question_id}
	[Documentation]
	...		question_id:	The question's ID 
	${questions}=	Get Data By Angular		questions
	${index}=		Find Index By Id		${questions}	${question_id}
	Run Keyword If	${index} < 0	Fail	Запитання id=${question_id} не знайдено
	[Return]	${questions[${index}]}	

Знайти лот по ідентифікатору
	[Arguments]		${lot_id}
	[Documentation]
	...		lot_id:			The ID of the lot
	${lots}=		Get Data By Angular		lots
	${index}=		Find Index By Id		${lots}	${lot_id}
	Run Keyword If	${index} < 0	Fail	Лот id=${lot_id} не знайдено
	[Return]	${lots[${index}]}	

Знайти предмет по ідентифікатору
	[Arguments]		${item_id}
	[Documentation]
	...		item_id:		The ID of item
	${items}=		Get Data By Angular		items
	${index}=		Find Index By Id		${items}	${item_id}
	Run Keyword If	${index} < 0	Fail	Предмет закупівлі id=${item_id} не знайдено
	[Return]	${items[${index}]}	
	
#	--- short keyword for alltenders.Пошук тендера по ідентифікатору ---
Знайти тендер по ідентифікатору
	[Arguments]		${username}  ${tender_uaid}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	alltenders.Пошук тендера по ідентифікатору	${username}  ${tender_uaid}  ${False}

Конвертувати дані зі строки
	[Arguments]		${fieldname}  ${value}
	[Documentation]
	...		fieldname:	The name of field
	...		value:		The value of field
	${parsed}=  Run Keyword If  '${fieldname}' == 'value.valueAddedTaxIncluded'  Convert To Boolean  ${value}	
	...		ELSE IF  '${field}' == 'minimalStep.amount' or '${field}' == 'value.amount' or '${field}' == 'items[0].deliveryLocation.latitude' or '${field}' == 'items[0].deliveryLocation.longitude' or '${field}' == 'items[0].quantity'  Convert To Number  ${value.split(' ')[0]}
	...		ELSE IF  '${fieldname}' == 'tenderPeriod.endDate' or '${fieldname}' == 'tenderPeriod.startDate' or '${fieldname}' == 'enquiryPeriod.endDate' or '${fieldname}' == 'enquiryPeriod.startDate' or '${fieldname}' == 'items[0].deliveryDate.endDate' or '${fieldname}' == 'items[0].deliveryDate.startDate' or '${fieldname}' == 'questions[0].date'  ua_date_to_iso  ${value}
	...		ELSE	Set Variable	${value}
	[Return]	${parsed}

#	--- short keyword for alltenders.Оновити сторінку з тендером ---
Оновити тендер
	[Arguments]		${username}  ${tender_uaid}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	alltenders.Оновити сторінку з тендером  ${username}  ${tender_uaid}

Підтвердити дію в діалозі
	[Arguments]		${timeout}=${common.wait}
	[Documentation]
	...		timeout: Timeout after confirmation
	Wait Until Page Contains Element			${dialog}		${timeout}
	Wait and Click Button						${dialog.apply}
	Wait Until Page Does Not Contain Element	${dialog}		${timeout}
	Wait For Progress Bar

Увійти в систему
	[Arguments]		${username}
	[Documentation]	Login into service
	...		username: The name of user
	Click Link				${user_menu.login}
	Wait and Input Text		${login.window.userName}	${USERS.users['${username}'].login}	
	Wait and Input Text		${login.window.password}	${USERS.users['${username}'].password}	
	Click Button			${login.window.apply}
