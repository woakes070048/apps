InstanceReadOnlyTemplate = {};


InstanceReadOnlyTemplate.instance_attachment = """
    <tr>
        <td class="ins-attach-view">
          	{{this.name}}
        </td>
    </tr>
"""

InstanceReadOnlyTemplate.afSelectUserRead = """
	<div class='selectUser form-control ins_applicant'>{{value}}</div>
"""


InstanceReadOnlyTemplate.afFormGroupRead = """
	<div class='form-group'>
		{{#with getField this.name}}
			{{#if equals type 'section'}}
					<div class='section callout callout-default'>
						<label class="control-label">{{code}}</label>
						<p>{{{description}}}</p>
					</div>
			{{else}}
				{{#if equals type 'table'}}
					<div class="panel panel-default steedos-table">
						<div class="panel-body" style="padding:0px;">
						  	<div class="panel-heading" >
								<label class='control-label'>{{getLabel code}}</label>
								<span class="description">{{{description}}}</span>
							</div>
							<div style="padding:0px;overflow-x:auto;">
								  <table type='table' class="table table-bordered table-condensed autoform-table" style='margin-bottom:0px;' {{this.atts}} id="{{this.code}}Table" data-schema-key="{{this.name}}">
									  <thead id="{{this.name}}Thead" name="{{this.name}}Thead">
											{{{getTableThead this}}}
									  </thead>
									  <tbody id="{{this.name}}Tbody" name="{{this.name}}Tbody">
											{{{getTableBody this}}}
									  </tbody>
								  </table>
							</div>
						</div>
					</div>
				{{else}}
					{{#if showLabel}}
						<label>{{getLabel code}}</label>
					{{/if}}
					<div class='{{getCfClass this}} form-control' readonly disabled>{{{getValue code}}}</div>
				{{/if}}
			{{/if}}
		{{/with}}
	</div>
"""

InstanceReadOnlyTemplate.imageSign = """
	<img src="{{imageURL user}}" class="image-sign" />
"""

InstanceReadOnlyTemplate.create = (tempalteName, steedosData) ->
	template = InstanceReadOnlyTemplate[tempalteName]

	templateCompiled = SpacebarsCompiler.compile(template, {isBody: true});

	templateRenderFunction = eval(templateCompiled);

	Template[tempalteName] = new Blaze.Template(tempalteName, templateRenderFunction);
	Template[tempalteName].steedosData = steedosData
	Template[tempalteName].helpers InstanceformTemplate.helpers

InstanceReadOnlyTemplate.createInstanceSignText = (steedosData)->
	instanceSignTextHtml = _getViewHtml('client/views/instance/instance_sign_text.html')

	instanceSignTextCompiled = SpacebarsCompiler.compile(instanceSignTextHtml, {isBody: true});

	instanceSignTextRenderFunction = eval(instanceSignTextCompiled);

	Template.instanceSignText = new Blaze.Template("instanceSignText", instanceSignTextRenderFunction);
	Template.instanceSignText.steedosData = steedosData
	Template.instanceSignText.helpers InstanceSignText.helpers


InstanceReadOnlyTemplate.init = (steedosData) ->
	InstanceReadOnlyTemplate.create("afSelectUserRead", steedosData);
	InstanceReadOnlyTemplate.create("afFormGroupRead", steedosData);
	if Meteor.isServer
		InstanceReadOnlyTemplate.create("imageSign", steedosData);
		InstanceReadOnlyTemplate.create("instance_attachment", {});
		InstanceReadOnlyTemplate.createInstanceSignText(steedosData)



InstanceReadOnlyTemplate.getValue = (value, field, locale, utcOffset) ->
	if !value && value != false
		return ''
	switch field.type
		when 'email'
			value = if value then '<a href=\'mailto:' + value + '\'>' + value + '</a>' else ''
		when 'url'
			if value
				if value.indexOf("http") == 0
					try
						value = "<a href='" + encodeURI(value) + "' target='_blank'>" + value + "</a>";
					catch e
						value = "<a href='' target='_blank'>" + value + "</a>";

				else
					value = "<a href='http://" + encodeURI(value) + "' target='_blank'>" + value + "</a>";
			else
				value = ''
		when 'group'
			if field.is_multiselect
				value = value?.getProperty("fullname").toString()
			else
				value = value?.fullname
		when 'user'
			if field.is_multiselect
				value = value?.getProperty("name").toString()
			else
				value = value?.name
		when 'password'
			value = '******'
		when 'checkbox'
			if value && value != 'false'
				value = TAPi18n.__("form_field_checkbox_yes", {}, locale)
			else
				value = TAPi18n.__("form_field_checkbox_no", {}, locale)
		when 'dateTime'
			if value && value.length == 16
				t = value.split("T")
				t0 = t[0].split("-");
				t1 = t[1].split(":");

				year = t0[0];
				month = t0[1];
				date = t0[2];
				hours = t1[0];
				seconds = t1[1];

				value = new Date(year, month - 1, date, hours, seconds)
			else
				value = new Date(value)

			value = InstanceReadOnlyTemplate.formatDate(value, utcOffset);
		when 'input'
			if field.is_textarea
				value = Spacebars.SafeString(Markdown(value))
		when 'number'
			if value or value == 0
				if typeof value == 'string'
					value = parseFloat(value)
				value = value.toFixed(field.digits)

	return value;

InstanceReadOnlyTemplate.getLabel = (fields, code) ->
	field = fields.findPropertyByPK("code", code)

	if field.name
		return field.name
	else
		return field.code


InstanceReadOnlyTemplate.getInstanceFormVersion = (instance)->
	form = db.forms.findOne(instance.form);

	form_version = {}

	form_fields = [];

	if form.current._id == instance.form_version
		form_version = form.current
	else
		form_version = _.where(form.historys, {_id: instance.form_version})[0]

	form_version.fields.forEach (field)->
		if field.type == 'section'
			form_fields.push(field);
			if field.fields
				field.fields.forEach (f) ->
					form_fields.push(f);
		else if field.type == 'table'
			field['sfields'] = field['fields']
			delete field['fields']
			form_fields.push(field);
		else
			form_fields.push(field);

	form_version.fields = form_fields;

	return form_version;

InstanceReadOnlyTemplate.getFlowVersion = (instance)->
	flow = db.flows.findOne(instance.flow);
	flow_version = {}
	if flow.current._id == instance.flow_version
		flow_version = flow.current
	else
		flow_version = _.where(flow.historys, {_id: instance.flow_version})[0]

	return flow_version;


_getViewHtml = (path) ->
	viewHtml = Assets.getText(path)

	if viewHtml
		viewHtml = viewHtml.replace(/<template[\w\s\"\=']+>/i,"").replace(/<\/template>/i,"")

	return viewHtml;

_getLocale = (user)->
	if user?.locale?.toLocaleLowerCase() == 'zh-cn'
		locale = "zh-CN"
	else if user?.locale?.toLocaleLowerCase() == 'en-us'
		locale = "en"
	else
		locale = "zh-CN"
	return locale

_getTemplateData = (user, space, instance)->
	if Meteor.isServer
		form_version = InstanceReadOnlyTemplate.getInstanceFormVersion(instance)
	else
		form_version = WorkflowManager.getInstanceFormVersion(instance)

	locale = _getLocale(user)

	steedosData = {}

	if Meteor.isClient
		steedosData = _.clone(WorkflowManager_format.getAutoformSchemaValues())
		steedosData.insname = instance.name
		steedosData.ins_state = instance.state
		steedosData.ins_final_decision = instance.ins_final_decision
		steedosData.ins_code = instance.code
		steedosData.ins_is_archived = instance.is_archived
		steedosData.ins_is_deleted = instance.ins_is_deleted
		steedosData.applicant_name = instance.applicant_name
		steedosData.applicantContext = instance.applicant_name
		steedosData.attachments = instance.attachments

	steedosData.instance = instance
	steedosData.form_version = form_version
	steedosData.locale = locale
	steedosData.utcOffset = user.utcOffset
	steedosData.space = instance.space

	return steedosData;

InstanceReadOnlyTemplate.formatDate = (date, utcOffset)->
	if Meteor.isServer
		passing = false;
	else
		passing = true;

	return moment(date).utcOffset(utcOffset, passing).format("YYYY-MM-DD HH:mm");

InstanceReadOnlyTemplate.getInstanceView = (user, space, instance, options)->

	steedosData = _getTemplateData(user, space, instance)

	instanceTemplate = TemplateManager.getTemplate(instance, options?.templateName);

	instanceTemplate = instanceTemplate.replace(/afSelectUser/g,"afSelectUserRead")

	instanceTemplate = instanceTemplate.replace(/afFormGroup/g,"afFormGroupRead")

	instanceCompiled = SpacebarsCompiler.compile(instanceTemplate, {isBody: true});

	instanceRenderFunction = eval(instanceCompiled);

	Template.instance_readonly_view = new Blaze.Template("instance_readonly_view", instanceRenderFunction);

	Template.instance_readonly_view.steedosData = steedosData

	Template.instance_readonly_view.helpers InstanceformTemplate.helpers

	InstanceReadOnlyTemplate.init(steedosData);

	body = Blaze.toHTMLWithData(Template.instance_readonly_view, steedosData)

	return """
		<div id='instanceform' >
			#{body}
		</div>
	"""

InstanceReadOnlyTemplate.getTracesView = (user, space, instance, options)->

	steedosData = _getTemplateData(user, space, instance)

	flow = db.flows.findOne(instance.flow);
	if flow.instance_style == "table" || options?.templateName == "table"
		tracesHtml = _getViewHtml('client/views/instance/traces_table.html')
	else
		tracesHtml = _getViewHtml('client/views/instance/traces.html')

	traceCompiled = SpacebarsCompiler.compile(tracesHtml, {isBody: true});

	traceRenderFunction = eval(traceCompiled);

	Template.trace_readonly_view = new Blaze.Template("trace_readonly_view", traceRenderFunction);

	Template.trace_readonly_view.steedosData = steedosData

	Template.trace_readonly_view.helpers TracesTemplate.helpers

	body = Blaze.toHTMLWithData(Template.trace_readonly_view, instance.traces)

	return body;

InstanceReadOnlyTemplate.getAttachmentView = (user, space, instance)->

	steedosData = _getTemplateData(user, space, instance)

	attachmentHtml = _getViewHtml('client/views/instance/instance_attachments.html')

	attachmentCompiled = SpacebarsCompiler.compile(attachmentHtml, {isBody: true});

	attachmentRenderFunction = eval(attachmentCompiled);

	Template.attachments_readonly_view = new Blaze.Template("attachments_readonly_view", attachmentRenderFunction);

	Template.attachments_readonly_view.steedosData = steedosData

	Template.attachments_readonly_view.helpers InstanceAttachmentTemplate.helpers

	body = Blaze.toHTMLWithData(Template.attachments_readonly_view, instance.attachments)

	return body;

InstanceReadOnlyTemplate.getOnLoadScript = (instance)->
	form_version = WorkflowManager.getFormVersion(instance.form, instance.form_version)

	form_script = form_version.form_script;

	if form_script && form_script.replace(/\n/g,"").replace(/\s/g,"").length > 0
		form_script = "CoreForm = {};CoreForm.instanceform = {};" + form_script
		form_script += "window.onload = CoreForm.form_OnLoad();"
	else
		form_script = ""



InstanceReadOnlyTemplate.getInstanceHtml = (user, space, instance, options)->

	body = InstanceReadOnlyTemplate.getInstanceView(user, space, instance, options);

	onLoadScript = InstanceReadOnlyTemplate.getOnLoadScript(instance)

	if !Steedos.isMobile()
		flow = db.flows.findOne({_id: instance.flow});
		if flow?.instance_style == 'table'
			instance_style = "instance-table"

	if options?.templateName == 'table'
		instance_style = "instance-table"

	if !options || options.showTrace == true
		trace = InstanceReadOnlyTemplate.getTracesView(user, space, instance)
	else
		trace = ""

	instanceBoxStyle = "";

	if instance && instance.final_decision
		if instance.final_decision == "approved"
			instanceBoxStyle = "box-success"
		else if (instance.final_decision == "rejected")
			instanceBoxStyle = "box-danger"
	if !options || options.showAttachments == true
		attachment = InstanceReadOnlyTemplate.getAttachmentView(user, space, instance)
	else
		attachment = ""

	absoluteUrl = Meteor.absoluteUrl();

	width = "960px"
#	如果给table的parent设置width，则会导致阿里云邮箱显示table 异常
	if options?.width
		width = ""

	allCss = WebAppInternals.refreshableAssets.allCss

	allCssLink = ""

	allCss.forEach (css) ->
		cssHref = absoluteUrl + css.url
		allCssLink += """<link rel="stylesheet" type="text/css" class="__meteor-css__" href="#{cssHref}">"""

	if options?.styles
		allCssLink = ""

	form = db.forms.findOne({_id: instance.form});
	formDescriptionHtml = ""
	if form
		formDescription = form.description
		if formDescription
			formDescriptionHtml = """
				<div class="box-header  with-border instance-header">
					<div>
						#{formDescription}
					</div>
				</div>
				"""

	html = """
		<!DOCTYPE html>
		<html>
			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
				#{allCssLink}
				<script src="https://www.steedos.com/website/libs/jquery.min.js" type="text/javascript"></script>
				<style>
					.steedos{
						width: #{width};
						margin-left: auto;
						margin-right: auto;
					}

					.instance-view .instance-name{
						display: inline !important
					}
					.box-tools{
						display: none;
					}
					.box.collapsed-box .box-body,.box.collapsed-box .box-footer {
					  display: block;
					}

					body{
						background: azure !important;
					}

					#{options?.styles}
				</style>
			</head>
			<body>
				<div class="steedos">
					<div class="instance-view">
						<div class="instance #{instance_style}">
							<div class="instance-form box #{instanceBoxStyle}">
								#{formDescriptionHtml}
								<div class="box-body">
									<div class="col-md-12">
										#{body}
										#{attachment}
									</div>
								</div>
							</div>
							#{trace}
						</div>
					</div>
				</div>
			</body>
			<script>#{onLoadScript}</script>
		</html>
	"""

	return html