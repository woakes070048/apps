Template.flow_list_modal.helpers({

});

Template.flow_list_modal.events({
  'shown.bs.modal #createInsModal': function(event) {
    var categories, data, forms;
    data = [];
    categories = WorkflowManager.getSpaceCategories();
    categories.forEach(function(cat) {
      var o;
      o = {};
      o.text = cat.name;
      o.nodes = [];
      forms = db.forms.find({
        category: cat._id
      });
      forms.forEach(function(f) {
        db.flows.find({
          form: f._id
        }).forEach(function(fl) {
          o.nodes.push({
            text: fl.name,
            flow_id: fl._id
          });
        });
      });
      data.push(o);
    });
    forms = db.forms.find({
      category: {
        $in: [null, ""]
      }
    });
    forms.forEach(function(f) {
      db.flows.find({
        form: f._id
      }).forEach(function(fl) {
        data.push({
          text: fl.name,
          flow_id: fl._id
        });
      });
    });
    $('#tree').treeview({
      data: data
    });
    $('#tree').on('nodeSelected', function(event, data) {
      InstanceManager.newIns(data.flow_id);
    });
  },

  'hidden.bs.modal #createInsModal': function(event) {
    var insId;
    insId = Session.get("instanceId");
    if (insId) {
      return FlowRouter.go("/workflow/draft/" + Session.get("spaceId") + "/" + insId);
    }
  }


})