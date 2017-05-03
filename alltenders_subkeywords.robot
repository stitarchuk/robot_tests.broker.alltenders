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
	Wait For Progress Bar
	Wait and Click Element				${tender.contact.form}//a[text()[contains(., "${contactPoint.name}")]]

Додати лот
	[Arguments]		${lot}
	[Documentation]
	...		lot: The lot's data
	Wait and Click Element		${tender.menu.addLot}
	Wait For Angular
	Sleep  1
	#	--- check for dialog ---
	${status}=	Run Keyword And Return Status  Page Should Contain Element  ${dialog}
	Run Keyword If  ${status}  Підтвердити дію в діалозі  ELSE  Wait For Progress Bar
	${lot_index}=	Find And Get Data	lots.length
	${lot_index}=	Evaluate			${lot_index}-${1}
	#	--- fill lot attributes ---
	Run Keyword And Ignore Error  Try To Set Data  lots[${lot_index}].id  "${lot.id}"
	Run Keyword And Ignore Error  Try To Set Data  lots[${lot_index}].title  "${lot.title}"
	Run Keyword And Ignore Error  Try To Set Data  lots[${lot_index}].title_ru  "${lot.title_ru}"
	Run Keyword And Ignore Error  Try To Set Data  lots[${lot_index}].title_en  "${lot.title_en}"
	Run Keyword And Ignore Error  Try To Set Data  lots[${lot_index}].description  "${lot.description}"
	Run Keyword And Ignore Error  Try To Set Data  lots[${lot_index}].description_ru  "${lot.description_ru}"
	Run Keyword And Ignore Error  Try To Set Data  lots[${lot_index}].description_en  "${lot.description_en}"
	Run Keyword And Ignore Error  Try To Set Object  lots[${lot_index}].value  ${lot.value}
	Run Keyword And Ignore Error  Try To Set Object  lots[${lot_index}].minimalStep  ${lot.minimalStep}
	Run Keyword And Ignore Error  Try To Set Data  lots[${lot_index}].minimalStep.amount  ${lot.minimalStep.amount}
	[Return]	${lot_index}
	
Додати лоти
	[Arguments]		${lots}
	[Documentation]  lot:  The lot's data
	:FOR  ${lot}  IN  @{lots}
	\	Додати лот		${lot}

Додати нецінові показники
	[Arguments]		${features}
	[Documentation]  features:  The features data
	Run Keyword And Ignore Error  Try To Set Object  features  ${features}

Додати неціновий показник
	[Arguments]		${feature}
	[Documentation]  feature:  The feature data
	${feature}=  Object To Json  ${feature}
	Execute Javascript  angular.element('body').scope().$apply(function(scope) { scope.context.tender.features = (scope.context.tender.features||[]).concat(${feature});});

Додати предмети
	[Arguments]		${items}
	[Documentation]  items:  The items data
	:FOR  ${item}  IN  @{items}
	\	Додати предмет	${item}
	
Додати предмет
	[Arguments]		${item}
	[Documentation]  item:  The item's data
	${status}  ${lot_index}=  Run Keyword And Ignore Error  Знайти індекс лота по ідентифікатору  ${item.relatedLot}
	${lot_index}=	Set Variable If  '${status}' == 'PASS'  ${lot_index}  ${0}
	${idxs}=		Create List  ${lot_index}
	${item_index}=	Find And Get Data  items.length
	Build Xpath and Run Keyword	${idxs}	Wait and Click Button	${tender.form.lot.addItem}
	Wait For Progress Bar
	#	--- fill item attributes ---
	Run Keyword And Ignore Error  Try To Set Data  items[${item_index}].id  "${item.id}"
	Run Keyword And Ignore Error  Try To Set Data  items[${item_index}].relatedLot  "${item.relatedLot}"
	Run Keyword And Ignore Error  Try To Set Data  items[${item_index}].description  "${item.description}"
	Run Keyword And Ignore Error  Try To Set Data  items[${item_index}].description_ru  "${item.description_ru}"
	Run Keyword And Ignore Error  Try To Set Data  items[${item_index}].description_en  "${item.description_en}"
	Run Keyword And Ignore Error  Try To Set Object  items[${item_index}].classification  ${item.classification}
	Run Keyword And Ignore Error  Try To Set Object  items[${item_index}].additionalClassifications  ${item.additionalClassifications}
	Run Keyword And Ignore Error  Try To Set Data  items[${item_index}].quantity  ${item.quantity}
	Run Keyword And Ignore Error  Try To Set Object  items[${item_index}].unit  ${item.unit}
	Run Keyword And Ignore Error  Try To Set Object  items[${item_index}].deliveryDate  ${item.deliveryDate}
	Run Keyword And Ignore Error  Try To Set Object  items[${item_index}].deliveryLocation  ${item.deliveryLocation}
	Run Keyword And Ignore Error  Try To Set Object  items[${item_index}].deliveryAddress  ${item.deliveryAddress}

Додати цінову пропозицію
	[Arguments]		${bid}  ${lot_index}=${0}  ${lots_ids}=${False}
	[Documentation]
	...		bid:		The bid's data to be set
	...		lot_index:	Index of lot (default 0)
	...		lots_ids:	List ID of lots
	${data}=	Get From Dictionary		${bid}						data
	${idxs}=	Create List				${lot_index}
	Build Xpath and Run Keyword	${idxs}  Wait and Click Button  ${tender.form.lot.menu.bid}
	Run Keyword If  ${lots_ids}  Set Bids  ${bid.data.lotValues}  ${lots_ids}  ELSE  Set Bid  ${bid.data.value}  ${idxs}
	Wait and Click CheckBox				${tender.contact.form}//ui-checkbox[@ng-model="model.data.ch1"]
	Wait and Click CheckBox				${tender.contact.form}//ui-checkbox[@ng-model="model.data.ch2"]
	Wait and Click Button				${tender.contact.form.make}
	Wait For Progress Bar
	Wait and Click Link					${tender.menu.bids}
	Wait Until Page Contains Element	${tender.form.bid}					${common.wait}

Змінити неціновий показник на лот
	[Arguments]		${feature}  ${lot_id}
	[Documentation]
	...		feature:	The feature data
	...		lot_id:		The ID of the lot
	${index}=  Знайти індекс лота по ідентифікатору  ${lot_id}
	${lot_id}=  Find And Get Data  lots[${index}].id
	Set To Dictionary  ${feature}  relatedItem=${lot_id}
	Додати неціновий показник	${feature}
	Save Tender

Змінити неціновий показник на предмет
	[Arguments]		${feature}  ${item_id}
	[Documentation]
	...		feature:	The feature data
	...		item_id:	The ID of the item
	${index}=  Знайти індекс предмета по ідентифікатору  ${item_id}
	${item_id}=  Find And Get Data  items[${index}].id
	Set To Dictionary  ${feature}  relatedItem=${item_id}
	Додати неціновий показник	${feature}
	Save Tender
	
Змінити неціновий показник на тендер
	[Arguments]		${feature}
	[Documentation]
	...		feature:		The feature data
	Wait and Click Button		${tender.form.addFeature}
	Додати неціновий показник	${feature}
	Wait and Click CheckBox		${tender.form.showFeature}
	Save Tender

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
	Run Keyword And Ignore Error  Try To Set Data  description  "${description}"

Змінити поле tenderPeriod.endDate
	[Arguments]		${endDate}
	[Documentation]	Change the final date for submission of proposals
	Run Keyword And Ignore Error  Try To Set Data  tenderPeriod.endDate  "${endDate}"

Знайти документ по ідентифікатору
	[Arguments]		${doc_id}
	[Documentation]
	...		doc_id:			The document's ID 
	${data}=  Find And Get Data
	${document}=  Find Document By Id  ${data}  ${doc_id}
	[Return]	${document}

Знайти індекс документа по ідентифікатору
	[Arguments]		${doc_id}
	[Documentation]
	...		doc_id:			The document's ID 
	${data}=  Find And Get Data  documents
	${index}=  Find Document Index By Id  ${data}  ${doc_id}
	Run Keyword If	${index} < 0	Fail	Документ id=${doc_id} не знайдено
	[Return]	${index}

Знайти індекс запитання по ідентифікатору
	[Arguments]		${question_id}
	[Documentation]
	...		question_id:	The question's ID 
	${data}=  Find And Get Data  questions
	${index}=  Find Index By Id  ${data}  ${question_id}
	Run Keyword If	${index} < 0	Fail	Запитання id=${question_id} не знайдено
	[Return]	${index}

Знайти індекс кваліфікації по ідентифікатору
	[Arguments]		${qualification_id}
	[Documentation]
	...		qualification_id:	The qualification's ID 
	${data}=  Find And Get Data  _qualifications
	${index}=  Find Index By Id  ${data}  ${qualification_id}
	Run Keyword If	${index} < 0	Fail	Кваліфікацію id=${qualification_id} не знайдено
	[Return]	${index}
	
Знайти індекс лота по ідентифікатору
	[Arguments]		${lot_id}
	[Documentation]
	...		lot_id:			The ID of the lot
	${data}=  Find And Get Data  lots
	${index}=  Find Index By Id  ${data}  ${lot_id}
	Run Keyword If	${index} < 0	Fail	Лот id=${lot_id} не знайдено
	[Return]	${index}
	
Знайти індекс нецінового показника по ідентифікатору
	[Arguments]		${feature_id}
	[Documentation]
	...		feature_id:		The ID of the feature
	${data}=  Find And Get Data  features
	${index}=  Find Index By Id  ${data}  ${feature_id}
	Run Keyword If	${index} < 0	Fail	Неціновий показник id=${feature_id} не знайдено
	[Return]	${index}

Знайти індекс предмета по ідентифікатору
	[Arguments]		${item_id}
	[Documentation]
	...		item_id:		The ID of item
	${data}=  Find And Get Data  items
	${index}=  Find Index By Id  ${data}  ${item_id}
	Run Keyword If	${index} < 0	Fail	Предмет закупівлі id=${item_id} не знайдено
	[Return]	${index}

Знайти індекс скарги по ідентифікатору
	[Arguments]		${complaint_id}  ${award_index}=${None}
	[Documentation]
	...		complaint_id:	The ID of the complaint
	...		award_index: 	The index of award
	${path}=  Set Variable If  '${award_index}' == '${None}'  complaints  awards[${award_index}].complaints
	${data}=  Find And Get Data  ${path}
	${index}=  Find Index By Id  ${data}  ${complaint_id}
	Run Keyword If	${index} < 0	Fail	Скаргу id=${complaint_id} не знайдено
	[Return]	${index}

#	--- short keyword for alltenders.Пошук тендера по ідентифікатору ---
Знайти тендер по ідентифікатору
	[Arguments]		${username}  ${tender_uaid}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	alltenders.Пошук тендера по ідентифікатору	${username}  ${tender_uaid}  ${False}

Конвертувати дані зі строки
	[Arguments]		${field}  ${value}
	[Documentation]
	...		field:	The name of field
	...		value:	The value of field
	${isNone}=  Is None  ${value}
	${parsed}=	Run Keyword If  ${isNone}  Set Variable	${value}
	...		ELSE IF  ${field.endswith('valueAddedTaxIncluded')}  Convert To Boolean  ${value}
	...		ELSE IF  ${field.endswith('amount')} or ${field.endswith('quantity')} or ${field.endswith('latitude')} or ${field.endswith('longitude')}  Convert To Number  ${value}
#	...		ELSE IF  ${field.endswith('date')} or ${field.endswith('startDate')} or ${field.endswith('endDate')} or ${field.endswith('longitude')}  Convert To Date  ${value}
	...		ELSE	Set Variable	${value}
	[Return]	${parsed}

#	--- short keyword for alltenders.Оновити сторінку з тендером ---
Оновити тендер
	[Arguments]		${username}  ${tender_uaid}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	alltenders.Оновити сторінку з тендером  ${username}  ${tender_uaid}

Сторінка з тендером містить елемент 
	[Arguments]		${username}  ${tender_uaid}  ${locator}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		locator:		What are we waiting for
	alltenders.Оновити сторінку з тендером  ${username}  ${tender_uaid}
	Run Keyword And Return  Element is Responsive  ${locator}

Отримати індекс скарги
	[Arguments]		${username}  ${tender_uaid}  ${complaint_id}  ${award_index}=${None}
	[Documentation]
	...		username:		The name of user
	...		tender_uaid:	The UA ID of the tender
	...		complaint_id:	The ID of the complaint
	${card}=  Set Variable If  '${award_index}' == '${None}'  ${tender.menu.complaints}  ${tender.menu.awards}
	Reload Tender And Switch Card  ${username}  ${tender_uaid}  ${card}
	Run Keyword And Return  Знайти індекс скарги по ідентифікатору  ${complaint_id}  ${award_index}
	
Підтвердити дію в діалозі
	[Arguments]		${timeout}=${common.wait}
	[Documentation]
	...		timeout: Timeout after confirmation
	Wait Until Page Contains Element			${dialog}		${timeout}
	${checkbox}=	Build Xpath					${dialog.body.checkbox}  0
	Click CheckBox If Responsive				${checkbox}
	${checkbox}=	Build Xpath					${dialog.body.checkbox}  1
	Click CheckBox If Responsive				${checkbox}
	Wait and Click Button						${dialog.apply}
	Wait Until Page Does Not Contain Element	${dialog}		${timeout}
	Wait For Progress Bar

Створити вимогу
	[Arguments]		${claim}  ${award_index}=${None}
	[Documentation]
	...		claim:			The complaint that must be created
	...		award_index:	The index of the award
	...		[Return]	The complaintID
	${title}=        Get From Dictionary  ${claim.data}  title
	${description}=  Get From Dictionary  ${claim.data}  description
	Wait Until Page Contains Element	${tender.complaint.form}				${common.wait}
	Wait and Input Text					${tender.complaint.form.title}			${title}
	Wait and Input Text					${tender.complaint.form.description}	${description}
	Wait and Click Button				${tender.complaint.form.make}
	Wait For Progress Bar
	${b_locator}=  	Set Variable If  '${award_index}' == '${None}'  complaints  awards[${award_index}].complaints
	${f_locator}= 	Set Variable If  '${award_index}' == '${None}'  ${tender.form.complaint}  ${tender.form.awards}
	${m_locator}= 	Set Variable If  '${award_index}' == '${None}'  ${tender.menu.complaints}  ${tender.menu.awards}
	Wait and Click Link					${m_locator}
	Wait Until Page Contains Element	${f_locator}  ${common.wait}
	${length}=		Find And Get Data  ${b_locator}.length
	${complaintID}=	Find And Get Data  ${b_locator}[${length-1}].complaintID
	[Return]	${complaintID}

Увійти в систему
	[Arguments]		${username}
	[Documentation]	Login into service
	...		username: The name of user
	Click Link				${user_menu.login}
	Wait and Input Text		${login.window.userName}	${USERS.users['${username}'].login}	
	Wait and Input Text		${login.window.password}	${USERS.users['${username}'].password}	
	Click Button			${login.window.apply}
