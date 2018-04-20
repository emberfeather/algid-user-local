<cfcomponent extends="plugins.user.inc.model.modUser" output="false">
	<cffunction name="init" access="public" returntype="component" output="false">
		<cfargument name="i18n" type="component" required="true" />
		<cfargument name="locale" type="string" default="en_US" />

		<cfset super.init(arguments.i18n, arguments.locale) />

		<!--- Password --->
		<cfset add__attribute(
				attribute = 'password'
			) />

		<!--- Salt --->
		<cfset add__attribute(
				attribute = 'salt'
			) />

		<!--- Set the bundle information for translation --->
		<cfset add__bundle('plugins/user-local/i18n/inc/model', 'modUser') />

		<cfreturn this />
	</cffunction>

	<cffunction name="getSalt" access="public" returntype="string" output="false">
		<cfif variables.instance.salt eq ''>
			<cfset this.setSalt(createUUID()) />
		</cfif>

		<cfreturn super.getSalt() />
	</cffunction>

	<cffunction name="hashPassword" access="public" returntype="string" output="false">
		<cfargument name="value" type="string" required="true" />

		<!--- Encrypt the value using the salt. --->
		<cfreturn hash(
			input=this.getSalt() & arguments.value,
			algorithm='SHA-512',
			numIterations=10) />
	</cffunction>

	<cffunction name="setPassword" access="public" returntype="void" output="false">
		<cfargument name="value" type="string" required="true" />

		<!--- Encrypt the new password using the salt before storing. --->
		<cfset arguments.value = this.hashPassword(value) />

		<cfset super.setPassword(argumentCollection = arguments) />
	</cffunction>
</cfcomponent>
