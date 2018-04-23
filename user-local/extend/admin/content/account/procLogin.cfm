<cfset servUser = services.get('user', 'user') />

<!--- Include minified files for production --->
<cfset midfix = (transport.theApplication.managers.singleton.getApplication().isProduction() ? '-min' : '') />

<cfset template.addStyles(transport.theRequest.webRoot & 'plugins/user-local/style/styles#midfix#.css') />
<cfset template.addScripts(transport.theRequest.webRoot & 'plugins/user-local/script/login#midfix#.js') />

<!--- Construct URL from settings --->
<cfset urlBase = 'http#(transport.theCgi.server_port_secure eq true ? 's' : '')#://#transport.theCgi.http_host##transport.theApplication.managers.singleton.getApplication().getPath()##transport.theApplication.managers.plugin.getAdmin().getPath()#?' />

<!--- Check for form submission --->
<cfif transport.theCgi.request_method eq 'POST'>
	<cfset servUser.verifyUser(transport.theSession.managers.singleton.getUser(), form) />

	<cfif structKeyExists(transport.theSession, 'redirect')>
		<cflocation url="#transport.theSession.redirect#" addtoken="false" />
	</cfif>

	<!--- If no saved redirect, send to main page --->
	<cfset theUrl.cleanRedirect() />
	<cfset theUrl.setRedirect('_base', '/index') />

	<cfset theUrl.redirectRedirect() />
</cfif>

<!--- If logged in send to main page --->
<cfif transport.theSession.managers.singleton.getUser().isLoggedIn()>
	<cfset theUrl.cleanRedirect() />
	<cfset theUrl.setRedirect('_base', '/index') />

	<cfset theUrl.redirectRedirect() />
</cfif>
