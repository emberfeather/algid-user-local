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

			<!--- Save the new user --->
			<cftransaction>
				<cfquery datasource="#variables.datasource.name#" result="results">
					INSERT INTO "#variables.datasource.prefix#user"."user"
					(
						"userID",
						"fullname",
						"username",
						"language",
						"password",
						"salt"
					) VALUES (
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.user.getUserID()#" />::uuid,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.user.getFullname()#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.user.getUsername()#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.user.getLanguage()#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.user.getPassword()#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.user.getSalt()#" />::uuid
					)
				</cfquery>
			</cftransaction>

			<cfset observer.afterCreate(variables.transport, arguments.user) />
		<cfelse>
			<cfset observer.beforeUpdate(variables.transport, arguments.user) />

			<!--- Update the existing user --->
			<cftransaction>
				<cfquery datasource="#variables.datasource.name#" result="results">
					UPDATE "#variables.datasource.prefix#user"."user"
					SET
						"fullname" = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.user.getFullname()#" />,
						"username" = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.user.getUsername()#" />,
						"language" = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.user.getLanguage()#" />,
						"password" = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.user.getPassword()#" />,
						"salt" = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.user.getSalt()#" />::uuid
					WHERE
						"userID" = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.user.getUserID()#" />::uuid
				</cfquery>
			</cftransaction>

			<cfset observer.afterUpdate(variables.transport, arguments.user) />
		</cfif>

		<cfset observer.afterSave(variables.transport, arguments.user) />
	</cffunction>

	<cffunction name="verifyUser" access="public" returntype="void" output="false">
		<cfargument name="user" type="component" required="true" />
		<cfargument name="request" type="struct" default="#{}#" />

		<cfset var authResp = '' />
		<cfset var axMessage = '' />
		<cfset var discovered = '' />
		<cfset var discoveries = '' />
		<cfset var eventLog = '' />
		<cfset var ext = '' />
		<cfset var fullName = '' />
		<cfset var observer = '' />
		<cfset var openIDConsumer = '' />
		<cfset var openIDResp = '' />
		<cfset var results = '' />
		<cfset var returnUrl = '' />
		<cfset var verified = '' />
		<cfset var verification = '' />

		<cfset observer = getPluginObserver('user-local', 'user') />
		<cfset observer.beforeVerify(variables.transport, arguments.user) />

		<cfquery name="results" datasource="#variables.datasource.name#">
			SELECT u."userID", u."username", u."password", u."salt", bru."roleID"
			FROM "#variables.datasource.prefix#user"."user" u
			LEFT JOIN "#variables.datasource.prefix#user"."bRole2User" bru
				ON u."userID" = bru."userID"
			JOIN "#variables.datasource.prefix#user"."identifier" i
				ON u."userID" = i."userID"
			WHERE u."archivedOn" IS NULL
				AND u."username" = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.request.username#" />
		</cfquery>

		<cfif results.recordCount>
			<cfset arguments.user.setUserID(results.userID.toString()) />
			<cfset arguments.user.setUsername(results.username) />

			<cfif results.password eq ''>
				<!--- Missing passwords accept whatever the first password provided is. --->
				<cfset arguments.user.setPassword(arguments.request.password) />
				<cfset this.setUser(arguments.user) />
			<cfelse>
				<!--- Verify that the password is correct. --->
				<cfif results.salt.toString() neq ''>
					<cfset arguments.user.setSalt(results.salt.toString()) />
				</cfif>
				<cfif arguments.user.hashPassword(arguments.request.password) neq results.password>
					<cfthrow type="validation" message="The password provided does not match user" detail="The password does not match for #arguments.request.username#">
				</cfif>
			</cfif>

			<!--- Add the roles to the user --->
			<cfloop query="results">
				<cfset arguments.user.addRoles(results.roleID.toString()) />
			</cfloop>

			<!--- After Success Event --->
			<cfset observer.afterSuccess(variables.transport, arguments.user) />
		<cfelse>
			<!--- After Fail Event --->
			<cfset observer.afterFail(variables.transport, arguments.user, verified, 'User does not exist in system') />

			<cfthrow type="validation" message="The username provided does not exist as a current user" detail="Could not find the #arguments.request.username# as a current user">
		</cfif>

		<!--- After Verify Event --->
		<cfset observer.afterVerify(variables.transport, arguments.user) />
	</cffunction>
</cfcomponent>
