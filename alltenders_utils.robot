*** Settings ***
Library		alltenders_service.py
Resource	alltenders_resource.robot

*** Keywords ***
Answer Question
	[Arguments]		${index}  ${answer}
	[Documentation]
	...		index:			The index of question
	...		answer:			The question's answer
	Wait For Angular	
	Execute Angular Method						questions[${index}].answerToQuestion
	Wait Until Page Contains Element			${tender.contact.form}			${common.wait}
	Wait and Input Text							${tender.contact.form.answer}	${answer}
	Wait and Click Button						${tender.contact.form.send}
	Wait For Progress Bar
	Wait Until Page Does Not Contain Element	${tender.contact.form}

Ask Question
	[Arguments]		${question}  ${btn_locator}
	[Documentation]
	...		question:		The question that must be asked 
	...		btn_locator:	The locator of button that should be clicked to display the question dialog

#	${author}=				Get From Dictionary		${question.data}	author
#	${contactPoint}=		Get From Dictionary		${author}			contactPoint
	${title}=				Get From Dictionary		${question.data}	title
	${description}=			Get From Dictionary		${question.data}	description
	Wait and Click Button						${btn_locator}
	Wait Until Page Contains Element			${tender.question.form}					${common.wait}
	Wait and Input Text							${tender.question.form.title}			${title}
	Wait and Input Text							${tender.question.form.description}		${description}
#	Додати контакт								${tender.question.form.contact}			${contactPoint}
	Capture Page Screenshot
	Wait and Click Button						${tender.question.form.send}
	Wait For Progress Bar
	Wait Until Page Does Not Contain Element	${tender.question.form}
	Run Keyword And Return				Munchify Data By Angular	questions	${True}

Build Xpath and Run Keyword
	[Arguments]		${idxs}  ${keyword}  @{kw_args}
	[Documentation]
	...		idxs:		Indexes for build xpath
	...		keyword:	Keyword to be run
	...		kw_args:	Arguments for keyword
	${locator}=  	Get From List	${kw_args}	0
	${locator}=  	Build Xpath 	${locator}  @{idxs}
	Set List Value  ${kw_args}  	0  			${locator}
	Run Keyword And Return  ${keyword}  @{kw_args}

Decode Bytes String
	[Arguments]		${string}
	[Documentation]	Decodes the given bytes string to a Unicode string.
	...		string: the string
	${bytes}=  Convert To Bytes  ${string}
	Run Keyword And Return  Decode Bytes To String  ${bytes}  UTF-8

Execute Angular Method
	[Arguments]		${method_path}  ${object_path}=tender
	[Documentation]
	...		method_path:	The path to the method to be executed (from ${object_path})
	...		object_path:	The path to the object (from sope.context)
	Log Many		${object_path}  ${method_path}
	${path}=		Set Variable If  '${method_path}' == '${None}'  ${object_path}  ${object_path}.${method_path}
	Run Keyword And Return	Execute Javascript	return angular.element('body').scope().$apply(function(scope){return scope.context.${path}();});

Get Data By Angular
	[Arguments]		${data_path}=${None}  ${object_path}=tender
	[Documentation]
	...		data_path: 		The path to the data (from ${object_path})
	...		object_path:	The path to the object (from sope.context)
	Log Many	${object_path}  ${data_path}
	${path}=	Set Variable If  '${data_path}' == '${None}'  ${object_path}  ${object_path}.${data_path}
	Run Keyword And Return	Execute Javascript
	...		return angular.element('body').scope().$apply(function(scope) {	
	...			var clearAngularData = function(obj) {
	...				var result = obj, key, value;
	...				if (obj instanceof Object && obj.constructor === Object) {
	...					result = {};
	...					for (key in obj) {
	...						if (key[0] === '$' || key[0] === '_' || !obj.hasOwnProperty(key) || typeof (value = obj[key]) === 'function') continue;
	...						result[key] = clearAngularData(value);
	...					}
	...				} else if (angular.isArray(obj)) {
	...					result = [];
	...					for (key = 0; key < obj.length; key++) {
	...						result.push(clearAngularData(obj[key]));
	...					}
	...				}
	...				return result;
	...			}, paths = '${path}'.split('.'), value = scope.context, i = 0, path, index;
	...			for (; i < paths.length; i++) {
	...				if ((path = paths[i].split("[")).length > 1) value = value[path[0]][parseInt(path[1])]; else value = value[path];
	...			}
	...			return clearAngularData(value);
	...		});

Log Arguments
	[Arguments]		@{arguments}
	[Documentation]
	...      Logs the given ``arguments`` as separate entries using the INFO level.
	Log Many		@{arguments}

Munchify Data By Angular
	[Arguments]		${data_path}=${None}  ${object_path}=tender  ${data}=${False}
	[Documentation]
	...		data_path: 		The path to the data (from ${object_path})
	...		object_path:	The path to the object (from sope.context)
	${response}=	Get Data By Angular			${data_path}	${object_path}
	Run Keyword And Return	Munchify Dictionary	${response}		${data}

Refresh Tender Data
	[Arguments]		${username}
	[Documentation]
	...		username:	The name of user
	${tender}=			Munchify Data By Angular
	Set To Dictionary	${USERS.users['${username}'].tender_data}	data=${tender}

Reload Angular Page
	[Arguments]		${timeout}=${common.wait}
	[Documentation]
	...		timeout: 	Timeout
	Reload Page
	Wait For Angular	${timeout}

Save Tender
	[Arguments]		${locator}=${tender.form}  ${send}=${False}
	${timeout}=		Set Variable	${240}
	#	--- save and send to prozorro ---
	Execute Javascript			window.scroll(0, 0)
	Wait and Click Element		${tender.menu.save}
	Run Keyword If	'${send}' == '${True}'	Wait and Click Element	${tender.menu.send}
	Wait For Progress Bar		${timeout}
	Sleep						1
	Reload Angular Page
	Run Keyword If  'xpath=' in '${locator}'  Wait Until Page Contains Element  ${locator}  ${timeout}
	...			ELSE  Wait Until Page Contains  ${locator}  ${timeout}
	Capture Page Screenshot

Set Bid
	[Arguments]		${value}  ${idxs}
	[Documentation]
	...		value:	The bid's value to be set
	...		idxs:	List index of lots
	${amount}=		Get From Dictionary		${value}	amount
	Build Xpath and Run Keyword	${idxs}  Wait and Input Text	${tender.contact.form.lot.amount}	${amount}

Set Bids
	[Arguments]		${bid}  ${lots_ids}
	[Documentation]
	...		bid:		The bid's data to be set
	...		lots_ids:	List ID of lots
	:FOR  ${lot_id}  IN  @{lots_ids}
	\	${lot_index}=	Знайти індекс лота по ідентифікатору	${lot_id}
	\	${idxs}=		Create List								${lot_index}
	\	${lot_value}=	Get From List							${bid}			${lot_index}
	\	Set Bid			${lot_value.value}	${idxs}

Set Object By Angular
	[Arguments]		${data_path}  ${object}  ${object_path}=tender
	[Documentation]
	...		data_path: 		The path to the data (from ${object_path})
	...		object:			The object to set
	...		object_path:	The path to the object (from sope.context)
	${object}=  Object To Json  ${object}
	Run Keyword And Return  Set Data By Angular  ${data_path}  ${object}  ${object_path}

Set Data By Angular
	[Arguments]		${data_path}  ${value}  ${object_path}=tender
	[Documentation]
	...		data_path: 		The path to the data (from ${object_path})
	...		value:			The value to set
	...		object_path:	The path to the object (from sope.context)
	Log Many	${object_path}  ${data_path}  ${value}
	${path}=	Set Variable If  '${data_path}' == '${None}'  ${object_path}  ${object_path}.${data_path}
	Run Keyword And Return	Execute Javascript	return angular.element('body').scope().$apply(function(scope){return scope.context.${path}=${value};});

Upload File
	[Arguments]		${filepath}  ${btn_locator}  ${btn_index}=${None}  ${upload_locator}=${tender.uploadFile}
	[Documentation]
	...		filepath:		The path to file that will be uploaded
	...		btn_locator:	The locator of button that should be clicked to display the File Upload dialog
	...		btn_index:		The index of button locator
	...		upload_locator:	The locator for file upload <input> element
	${status}	${btn_index}=	Run Keyword And Ignore Error	Convert To Number	${btn_index}
	${btn_upload}=	Run Keyword If  '${status}' == 'PASS'  Build Xpath For Parent	${btn_locator}	${btn_index}
	...				ELSE	Set Variable	${btn_locator}
	Wait and Click Button						${btn_upload}
	Wait Until Page Contains Element			${upload_locator}				${common.wait}
	Choose File									${upload_locator}				${filepath}
	Wait and Click Button						${tender.uploadFile.form.save}	60
	Capture Page Screenshot
	Wait Until Page Does Not Contain Element	${tender.uploadFile.form}		${common.wait}
	Wait For Progress Bar
	
Wait Until Element is Responsive
	[Arguments]		${locator}  ${timeout}=${common.wait}
	[Documentation]
	...		locator: What are we waiting for
	...		timeout: Timeout
	Wait Until Page Contains Element	${locator}	${timeout}
	Wait Until Element Is Visible		${locator}	${timeout}
	Wait Until Element Is Enabled		${locator}	${timeout}

Wait and Click Button
	[Arguments]		${locator}  ${timeout}=${common.wait}
	[Documentation]
	...		locator: What are we waiting for and where to click
	...		timeout: Timeout
	Wait Until Element is Responsive	${locator}	${timeout}
	Click Button						${locator}

Wait and Click CheckBox
	[Arguments]		${locator}  ${timeout}=${common.wait}
	[Documentation]
	...		locator:	The checkbox xpath locator
	...		timeout:	Timeout
	Wait and Click Element		${locator}${checkbox.label}		${timeout}

Wait and Click Element
	[Arguments]		${locator}  ${timeout}=${common.wait}
	[Documentation]
	...		locator: What are we waiting for and where to click
	...		timeout: Timeout
	Wait Until Element is Responsive	${locator}	${timeout}
	Click Element						${locator}
 
Wait and Click Link
	[Arguments]		${locator}  ${timeout}=${common.wait}
	[Documentation]
	...		locator:	What are we waiting for and where to click
	...		timeout:	Timeout
	Wait Until Element is Responsive	${locator}	${timeout}
	Click Link							${locator}
 
Wait and Input Text
	[Arguments]		${locator}  ${data}  ${timeout}=${common.wait}
	[Documentation]
	...		locator:	The input xpath locator
	...		data:		What are we input
	...		timeout:	Timeout
 	Wait Until Element is Responsive	${locator}	${timeout}
 	${data}=	Convert To String		${data}
 	Input text							${locator}	${data}

Wait and Select In Combo
	[Arguments]		${locator}  ${text}  ${wait_before_select}=1  ${timeout}=${common.wait}
	[Documentation]
	...		locator:	The combo xpath locator
	...		text:		The text to combo input
	...		timeout:	Timeout
	Wait and Click Element	${locator}/div	${timeout}
	Sleep					1
	Wait and Input Text		${locator}${combobox.filter}	${text}	${timeout}
	Sleep					${wait_before_select}
	${selector}=			Build Xpath From Template	${locator}${combobox.selector}	${text}	
	Wait and Click Element	${selector}
	Sleep  					1

Wait For Angular
	[Arguments]		${timeout}=${common.wait}
	[Documentation]
	...		timeout: Timeout
	Wait For Condition	return angular.element(document.querySelector('[ng-app]')).injector().get('$browser').notifyWhenNoOutstandingRequests!=undefined  ${timeout}

Wait For Progress Bar
	[Arguments]		${timeout}=${common.wait}
	[Documentation]
	...		timeout: Timeout
	Wait Until Element Is Not Visible	${progress.bar}		${timeout}
