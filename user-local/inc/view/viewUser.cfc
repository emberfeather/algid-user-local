<cfcomponent extends="plugins.user.inc.view.viewUser" output="false">
	<cffunction name="login" access="public" returntype="string" output="false">
		<cfargument name="request" type="struct" default="#{}#" />

		<cfset var html = '' />
		<cfset var i18n = '' />
		<cfset var iconDir = '' />
		<cfset var iconSize = 32 />
		<cfset var theForm = '' />
		<cfset var theURL = '' />

		<cfset i18n = variables.transport.theApplication.managers.singleton.getI18N() />
		<cfset theURL = variables.transport.theRequest.managers.singleton.getUrl() />
		<cfset theForm = variables.transport.theApplication.factories.transient.getForm('login', i18n) />

		<cfset theUrl.cleanLogin() />
		<cfset theUrl.setLogin('_base', '/account/login') />

		<!--- Add the resource bundle for the view --->
		<cfset theForm.addBundle('plugins/user-local/i18n/inc/view', 'viewUser') />

		<cfset theForm.addElement('text', {
			name = 'username',
			label = 'username',
			required = true,
			value = ( structKeyExists(arguments.request, 'username') ? arguments.request.username : '' )
		}) />

		<cfset theForm.addElement('password', {
			name = 'password',
			label = 'password',
			required = true,
			value = ( structKeyExists(arguments.request, 'password') ? arguments.request.password : '' )
		}) />

		<cfreturn theForm.toHTML(theURL.getLogin(), { submit: 'Login' }) />
	</cffunction>

	<cffunction name="datagrid" access="public" returntype="string" output="false">
		<cfargument name="data" type="any" required="true" />
		<cfargument name="options" type="struct" default="#{}#" />

		<cfset var datagrid = '' />
		<cfset var i18n = '' />

		<cfset arguments.options.theURL = variables.transport.theRequest.managers.singleton.getURL() />
		<cfset i18n = variables.transport.theApplication.managers.singleton.getI18N() />
		<cfset datagrid = variables.transport.theApplication.factories.transient.getDatagrid(i18n, variables.transport.theSession.managers.singleton.getSession().getLocale()) />

		<!--- Add the resource bundle for the view --->
		<cfset datagrid.addBundle('plugins/user/i18n/inc/view', 'viewUser') />
		<cfset datagrid.addBundle('plugins/user-local/i18n/inc/view', 'viewUser') />

		<cfset datagrid.addColumn({
				key = 'fullname',
				label = 'fullname'
			}) />

		<cfset datagrid.addColumn({
				key = 'identifier',
				label = 'identity'
			}) />

		<cfset datagrid.addColumn({
				class = 'phantom align-right width-min',
				value = [ 'delete', 'edit' ],
				link = [
					{
						'user' = 'userID',
						'_base' = '/admin/user/archive'
					},
					{
						'user' = 'userID',
						'_base' = '/admin/user/edit'
					}
				],
				linkClass = [ 'delete', '' ],
				title = 'fullname'
			}) />

		<cfreturn datagrid.toHTML( arguments.data, arguments.options ) />
	</cffunction>
</cfcomponent>
