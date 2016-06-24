Package.describe({
	name: 'steedos:api',
	version: '0.0.1',
	summary: 'Steedos api libraries',
	git: ''
});

Npm.depends({
  busboy: "0.2.13",
  cookies: "0.6.1",
  mime: "1.3.4"
});

Package.onUse(function(api) { 
	api.versionsFrom('1.0');


	api.use('reactive-var');
	api.use('reactive-dict');
	api.use('coffeescript');
	api.use('random');
	api.use('ddp');
	api.use('check');
	api.use('ddp-rate-limiter');
	api.use('underscore');
	api.use('tracker');
	api.use('session');
	api.use('accounts-base');
	api.use('sha');
	api.use('npm-bcrypt');
	api.use('webapp', 'server');
	api.use('accounts-password@1.1.4');

	api.use('cfs:standard-packages');
	api.use('raix:push');
	api.use('simple:json-routes@2.1.0');

	api.use('steedos:lib');
	api.use('steedos:workflow');


	api.addFiles('lib/restivus/auth.coffee', 'server');
	api.addFiles('lib/restivus/iron-router-error-to-response.js', 'server');
	api.addFiles('lib/restivus/route.coffee', 'server');
	api.addFiles('lib/restivus/restivus.coffee', 'server');

	api.addFiles('lib/URI.js');

	api.addFiles('core.coffee', 'server');

	api.addFiles('steedos/space_users.coffee', 'server');
	api.addFiles('steedos/organizations.coffee', 'server');

	api.addFiles('routes/setup.coffee', 'server');
	api.addFiles('routes/s3.coffee', 'server');
	api.addFiles('routes/push.coffee', 'server');
	api.addFiles('routes/avatar.coffee', 'server');
	api.addFiles('routes/sso.coffee', 'server');

	api.addFiles('accounts_client.coffee', 'client');
});

Package.onTest(function(api) {

});
