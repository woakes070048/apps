
Meteor.publish "instance_tabular", (tableName, ids, fields)->
#	console.log "instance_tabular user is #{this.userId}"

	unless this.userId
		return this.ready()

	check(tableName, String);

	check(ids, Array);

	check(fields, Match.Optional(Object))

	self = this;

	getMyApprove = (userId, instanceId)->
		instance = db.instances.findOne({_id: instanceId})
		myApprove = null

		if !instance
			return

		if !instance.traces || instance.traces.length < 1
			return

		notFinishedTraces = instance.traces.filterProperty("is_finished", false)

		if notFinishedTraces.length > 0
			approves = notFinishedTraces[0].approves.filterProperty("is_finished", false).filterProperty("handler", userId);

			if approves.length > 0
				approve = approves[0]
				myApprove = {id: approve._id, instance: approve.instance, trace: approve.trace, is_read: approve.is_read}

		if !myApprove
			is_read = false
			instance.traces.forEach (trace) ->
				trace?.approves?.forEach (approve) ->
					if approve.type == 'cc' and approve.user == userId and approve.is_finished == false
						if approve.is_read
							is_read = true
						myApprove = {id: approve._id , is_read: is_read}

		return myApprove

	getStepCurrentName = (instanceId) ->
		stepCurrentName = ""
		instance = db.instances.findOne({_id: instanceId}, {fields: {flow: 1, flow_version: 1, "traces.step":1, "traces": {$slice: -1}}})
		if instance
			flow = db.flows.findOne({_id: instance.flow}, {fields: {current: 1, historys: 1}})
			if flow && instance.traces?[0]?.step
				step = uuflowManager.getStep(instance, flow, instance.traces?[0]?.step)
				if step?.name
					stepCurrentName = step.name

		return stepCurrentName

	handle = db.instances.find({_id: {$in: ids}}).observeChanges {
		changed: (id)->
			instance = db.instances.findOne({_id: id}, {fields: fields})
			myApprove = getMyApprove(self.userId, id)
			if myApprove
				instance.is_read = myApprove.is_read
			else
				instance.is_read = true
			instance.step_current_name = getStepCurrentName(id);
			self.changed("instances", id, instance);
		removed: (id)->
			self.removed("instances", id);
	}

	ids.forEach (id)->
		instance = db.instances.findOne({_id: id}, {fields: fields})
		myApprove = getMyApprove(self.userId, id)
		if myApprove
			instance.is_read = myApprove.is_read
		else
			instance.is_read = true
		instance.step_current_name = getStepCurrentName(id);
		self.added("instances", id, instance);

	self.ready();
	self.onStop ()->
		handle.stop()