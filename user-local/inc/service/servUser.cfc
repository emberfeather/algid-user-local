<cfcomponent extends="plugins.user.inc.service.servUser" output="false">
	<cffunction name="getUser" access="public" returntype="component" output="false">
		<cfargument name="userID" type="string" required="true" />

		<cfset var modelSerial = '' />
		<cfset var results = '' />
		<cfset var user = '' />

		<cfquery name="results" datasource="#variables.datasource.name#">
			SELECT u."userID", u."username"
			FROM "#variables.datasource.prefix#user"."user" u
			WHERE u."userID" = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userID#" null="#arguments.userID eq ''#" />::uuid
		</cfquery>

		<cfset user = getModel('user', 'user') />

		<cfif results.recordCount>
			<cfset modelSerial = variables.transport.theApplication.factories.transient.getModelSerial(variables.transport) />

			<cfset modelSerial.deserialize(results, user) />
		</cfif>

		<cfreturn user />
	</cffunction>

	<cffunction name="getUsers" access="public" returntype="query" output="false">
		<cfargument name="filter" type="struct" default="#{}#" />

		<cfset var results = '' />
		<cfset var useFuzzySearch = variables.transport.theApplication.managers.singleton.getApplication().getUseFuzzySearch() />

		<cfquery name="results" datasource="#variables.datasource.name#">
			SELECT u."userID", u."fullname", u."username"
			FROM "#variables.datasource.prefix#user"."user" u
			WHERE 1=1

			<cfif structKeyExists(arguments.filter, 'search') and arguments.filter.search neq ''>
				AND (
					u."fullname" LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.filter.search#%" />
					OR u."username" LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.filter.search#%" />

					<cfif useFuzzySearch>
						OR dmetaphone(u."fullname") = dmetaphone(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.search#" />)
						OR dmetaphone_alt(u."fullname") = dmetaphone_alt(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filter.search#" />)
					</cfif>
				)
			</cfif>

			ORDER BY u."username" ASC
		</cfquery>

		<cfreturn results />
	</cffunction>

	<cffunction name="setUser" access="public" returntype="void" output="false">
		<cfargument name="user" type="component" required="true" />

		<cfset var eventLog = '' />
		<cfset var observer = '' />
		<cfset var results = '' />

		<!--- Get the event observer --->
		<cfset observer = getPluginObserver('user-local', 'user') />

		<cfset scrub__model(arguments.user) />
		<cfset validate__model(arguments.user) />

		<cfset observer.beforeSave(variables.transport, arguments.user) />

		<cfif arguments.user.getUserID() eq ''>
			<!--- Create the new ID --->
			<cfset arguments.user.setUserID( createUUID() ) />

			<cfset observer.beforeCreate(variables.transport, arguments.user) />

			<!--- TODO Save the new user --->

			<cfset observer.afterCreate(variables.transport, arguments.user) />
		<cfelse>
			<cfset observer.beforeUpdate(variables.transport, arguments.user) />

			<!--- TODO Sync the existing user --->

			<cfset observer.afterUpdate(variables.transport, arguments.user) />
		</cfif>

		<cfset observer.afterSave(variables.transport, arguments.user) />
	</cffunction>
</cfcomponent>
