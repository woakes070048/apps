Template.instance_view.helpers
	instance: ->
		Session.get("change_date")
		if (Session.get("instanceId"))
			steedos_instance = WorkflowManager.getInstance();
			return steedos_instance;


	unequals: (a, b) ->
		return !(a == b)

	# 只有在流程属性上设置tableStype 为true 并且不是手机版才返回true.
	isTableView: (flowId)->
		flow = WorkflowManager.getFlow(flowId);

		if Steedos.isMobile()
			return false

		if flow?.instance_style == 'table'
			return true
		# return true
		return false;

	readOnlyView: ()->
		steedos_instance = WorkflowManager.getInstance();
		if steedos_instance
			return InstanceReadOnlyTemplate.getInstanceView(db.users.findOne({_id: Meteor.userId()}), Session.get("spaceId"), steedos_instance);
	isIReadable: ()->
		return ApproveManager.isReadOnly();

	instanceStyle: (flowId)->
		flow = WorkflowManager.getFlow(flowId);

		if Steedos.isMobile()
			return ""

		if flow?.instance_style == 'table'
			return "instance-table"
		return "";

	tracesTemplateName: (flowId)->
		flow = WorkflowManager.getFlow(flowId);

		if Steedos.isMobile()
			return "instance_traces"

		if flow?.instance_style == 'table'
			return "instance_traces_table"
		# return true
		return "instance_traces";

	instance_box_style: ->
		box = Session.get("box")
		if box == "inbox" || box == "draft"
			judge = Session.get("judge")
			if judge
				if (judge == "approved")
					return "box-success"
				else if (judge == "rejected")
					return "box-danger"
		ins = WorkflowManager.getInstance();
		if ins && ins.final_decision
			if ins.final_decision == "approved"
				return "box-success"
			else if (ins.final_decision == "rejected")
				return "box-danger"

	formDescription: ->
		ins = WorkflowManager.getInstance();
		if ins
			return WorkflowManager.getForm(ins.form)?.description

Template.instance_view.onCreated ->
	Form_formula.initFormScripts()

Template.instance_view.onRendered ->

	Form_formula.runFormScripts("instanceform", "onload");

	if Session.get("box") == "inbox"
		InstanceManager.setApproveHaveRead(Session.get("instanceId"))

	$(".workflow-main").addClass("instance-show")

	$('[data-toggle="tooltip"]').tooltip()
	if !Steedos.isMobile() && !Steedos.isPad()
		# 增加.css("right","-1px")代码是为了fix掉perfectScrollbar会造成右侧多出空白的问题
		$('.instance').perfectScrollbar().css("right","-1px")
		if Session.get("box") == "inbox"
			$('.instance').on 'ps-y-reach-end', ->
				if this.scrollTop == 0
					# 内容高度不足已出现滚动条时也会触发该事件，需要排除掉。
					return
				unless $('.instance-wrapper .instance-view').hasClass 'suggestion-active'
					$('.instance-wrapper .instance-view').toggleClass 'suggestion-active'
					InstanceManager.fixInstancePosition(true)
	else if Session.get("box") == "inbox"
		preScrollTop = 0
		loap = 0
		$(".instance").scroll (event)->
			clearTimeout loap
			self = this
			# 这里增加setTimeout除了优化性能外，更重要的是解决触发次数过多造成的动画效果不流畅问题
			loap = setTimeout ->
				scrollTop = self.scrollTop
				scrollH = self.scrollHeight
				viewH = $(self).innerHeight()
				diffValue = (scrollH-viewH) - scrollTop
				if diffValue < 20
					if scrollTop >= preScrollTop
						unless $('.instance-wrapper .instance-view').hasClass 'suggestion-active'
							$('.instance-wrapper .instance-view').toggleClass 'suggestion-active'
							setTimeout ->
								InstanceManager.fixInstancePosition(true)
							,100
					preScrollTop = scrollTop
			,100

Template.instance_view.events
	'change .instance-view .form-control,.instance-view .suggestion-control,.instance-view .checkbox input,.instance-view .af-radio-group input,.instance-view .af-checkbox-group input': (event, template) ->
		Session.set("instance_change", true);

	'change .ins-file-input': (event, template)->
		InstanceManager.uploadAttach(event.target.files, false)

		$(".ins-file-input").val('')

	'click .btn-instance-back': (event)->
		backURL = "/workflow/space/" + Session.get("spaceId") + "/" + Session.get("box")
		FlowRouter.go(backURL)
