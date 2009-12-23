<!---
LICENSE INFORMATION:

Copyright 2009, Adam Tuttle

Licensed under the Apache License, Version 2.0 (the "License"); you may not
use this file except in compliance with the License.

You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.

VERSION INFORMATION:

This file is part of Scribe.
--->
<cfcomponent displayname="Handler" extends="BasePlugin">

	<cffunction name="init" access="public" output="false" returntype="any">
		<cfargument name="mainManager" type="any" required="true" />
		<cfargument name="preferences" type="any" required="true" />

		<cfset setManager(arguments.mainManager) />
		<cfset setPreferencesManager(arguments.preferences) />
		<cfset setPackage("com/fusiongrokker/plugins/Scribe") />

		<!--- get database type --->
		<cfset variables.objQryAdapter = getManager().getQueryInterface() />
		<cfset variables.dbType = objQryAdapter.getDBType() />

		<!--- setup jsonUtil for management --->
		<cfset variables.jsonutil = createObject("component","JSONUtil") />

		<!--- set default preferences --->
		<cfset initSettings(
			fromEmail = "",
			subject = "[{blogTitle}] {postTitle}",
			body =	"A new blog post is available on {blogTitle}!<br/>#chr(13)&chr(10)#<br/>#chr(13)&chr(10)#" &
					"<strong>{postTitle}</strong><br/>#chr(13)&chr(10)#" &
					"{excerpt}<br/>#chr(13)&chr(10)#<br/>#chr(13)&chr(10)#" &
					"Click here to view the entry: <a href='{url}'>{url}</a><br/>#chr(13)&chr(10)#<br/>#chr(13)&chr(10)#" &
					"<a href='{unsubscribeUrl}'>click here to unsubscribe</a>",
			PodTitle = "Subscribe",
			PodBlurb = '',
			TableName = "emailSubscribers",
			DoubleOptIn = true
		)/>

		<cfreturn this/>
	</cffunction>

<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->
	<cffunction name="setup" hint="This is run when a plugin is activated" access="public" output="false" returntype="any">
		<cfset var qNewTable = ""/>
		<cfset var sql = ""/>
		<cfset var qIX = ""/>
		<cfset var qFK = ""/>
		<cfset var qNC = ""/>
		<cfset var tablePrefix = variables.objQryAdapter.getTablePrefix() />
		<!--- create appropriate SQL to check for, and create our table--->
		<cfif findNoCase("mssql", variables.dbType)>
			<!--- mssql --->
			<cftry>
				<cfset sql = "IF (NOT(EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '#tablePrefix##getSetting('TableName')#'))) BEGIN CREATE TABLE #tablePrefix##getSetting('TableName')#(email varchar(200) NOT NULL, blogId varchar(50), ActiveFlag varchar(35) NOT NULL, CONSTRAINT PK_#tablePrefix##getSetting('TableName')# PRIMARY KEY CLUSTERED(email ASC)) END"/>
				<cfset qNewTable = variables.objQryAdapter.makeQuery(query=sql,returnResult=false) />
				<cfcatch>
					<!--- there was a problem creating the table, get the user to do it manually --->
					<cfreturn "Error while creating the email subscription table (MSSQL1). Please consult the documentation to create the table manually."/>
				</cfcatch>
			</cftry>
			<cftry>
				<cfset sql = "IF NOT EXISTS (SELECT NULL FROM sysobjects WHERE name = 'FK_#tablePrefix##getSetting('TableName')#_#tablePrefix#blog' AND parent_obj = OBJECT_ID(N'#tablePrefix##getSetting('TableName')#')) begin ALTER TABLE #tablePrefix##getSetting('TableName')# WITH CHECK ADD CONSTRAINT [FK_#tablePrefix##getSetting('TableName')#_#tablePrefix#blog] FOREIGN KEY([blogId]) REFERENCES #tablePrefix#blog ([id]) END" />
				<cfset qFK = variables.objQryAdapter.makeQuery(query=sql,returnResult=false) />
				<cfcatch>
					<!--- there was a problem creating the index, get the user to do it manually --->
					<cfreturn "Error while creating the email subscription table (MSSQL2). Please consult the documentation to create the table manually."/>
				</cfcatch>
			</cftry>
			<!--- if the table already existed (previous plugin version), we need to add the column --->
			<cftry>
				<cfset sql = "IF NOT EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=N'#tablePrefix##getSetting('TableName')#' AND COLUMN_NAME = N'ActiveFlag' ) BEGIN ALTER TABLE #tablePrefix##getSetting('TableName')# ADD ActiveFlag varchar(35) DEFAULT 'active' NOT NULL END" />
				<cfset qNC = variables.objQryAdapter.makeQuery(query=sql,returnResult=false) />
				<cfcatch>
					<cfreturn "Error adding new column to table (MSSQL3). Please consult the documentation to add it manually."/>
				</cfcatch>
			</cftry>
		<cfelse>
			<!--- mysql --->
			<cftry>
				<cfset sql = "CREATE TABLE IF NOT EXISTS `#tablePrefix##getSetting('TableName')#` (`email` varchar(200) NOT NULL, `blogId` varchar(50) NOT NULL, `ActiveFlag` varchar(35) NOT NULL, PRIMARY KEY (`email`)) ENGINE=MyISAM DEFAULT CHARSET=utf8;"/>
				<cfset qNewTable = variables.objQryAdapter.makeQuery(query=sql,returnResult=false) />
				<cfcatch>
					<!--- there was a problem creating the table, get the user to do it manually --->
					<cfreturn "Error while creating the email subscription table (MySQL1). Please consult the documentation to create the table manually."/>
				</cfcatch>
			</cftry>
			<cftry>
				<cfset sql = "CREATE INDEX `IX_#tablePrefix##getSetting('TableName')#_blogId` ON `#tablePrefix##getSetting('TableName')#`" />
				<cfset qIX = variables.objQryAdapter.makeQuery(query=sql,returnResult=false) />
				<cfcatch>
					<!--- No biggy, let it slide. --->
				</cfcatch>
			</cftry>
			<cftry>
				<cfset sql = "ALTER TABLE `#tablePrefix##getSetting('TableName')#` ADD COLUMN `ActiveFlag` varchar(35) NOT NULL DEFAULT 'active'"/>
				<cfset qNC = variables.objQryAdapter.makeQuery(query=sql,returnResult=false) />
				<cfcatch>
					<!--- No biggy, let it slide. --->
				</cfcatch>
			</cftry>
		</cfif>
		<!--- at this point, assume the table was created, and just return --->
		<cfreturn "Scribe is activated.<br/>Would you like to <a href='generic_settings.cfm?event=Scribe-settings&amp;owner=Scribe&amp;selected=Scribe-settings'>change its settings</a>?" />
	</cffunction>
	<cffunction name="unsetup" hint="This is run when a plugin is de-activated" access="public" output="false" returntype="any">
		<cfreturn "Plugin De-activated" />
	</cffunction>
	<cffunction name="upgrade" hint="This is run when upgrading from a previous version with auto-install" output="false" returntype="any">
		<cfreturn "Upgrade complete." />
	</cffunction>

<!--- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: --->
	<cffunction name="handleEvent" hint="Asynchronous event handling" access="public" output="false" returntype="any">
		<cfargument name="event" type="any" required="true" />
		<!--- this plugin doesn't respond to any asynch events --->
		<cfreturn />
	</cffunction>
	<cffunction name="processEvent" hint="Synchronous event handling" access="public" output="false" returntype="any">
		<cfargument name="event" type="any" required="true" />
		<cfset var eventName = arguments.event.getName()/>
		<cfset var local = structNew()/>

		<cfset local.unsubURL = "generic.cfm?event=scribe-unsubscribe&email=" />
		<cfset local.subURL = "generic.cfm?event=scribe-subscribe&email=" />

		<cfif eventName EQ "Scribe-pod">
			<cfsavecontent variable="local.content">
				<cfinclude template="podContent.cfm"/>
			</cfsavecontent>
			<cfset event.outputData = event.outputData & local.content />

		<cfelseif eventName EQ "getPods">
			<!--- render pod body --->
			<cfsavecontent variable="local.content">
				<cfoutput>
					<cfinclude template="podContent.cfm" />
				</cfoutput>
			</cfsavecontent>
			<cfset local.pod = structnew() />
			<cfset local.pod.title = getSetting("PodTitle") />
			<cfset local.pod.content = local.content />
			<cfset local.pod.id = "scribe" />
			<cfset arguments.event.addPod(local.pod)>

		<cfelseif eventName EQ "scribe-subscribe">
			<cfscript>
				local.email = "you@yourdomain.com";
				if (structKeyExists(event.getData().externalData, "email")){
					local.email = event.getData().externalData.email;
				}
				if (local.email neq "you@yourdomain.com" and len(trim(local.email))){
					local.result = subscribe(local.email);
					if (local.result){
						event.data.message.setTitle("Subscribe Successful");
						if (getSetting('DoubleOptIn')){
							event.data.message.setData("<p>You have been <strong><em>subscribed</em></strong>, and an activation link has been sent to your email address. You will not receive any subscription emails until you follow the link it contains to activate your subscription.</p><p>Was that an accident? <a href='#local.unsubURL & urlEncodedFormat(local.email)#'>Click here to <strong><em>unsubscribe</em></strong>.</a></p>");
						}else{
							event.data.message.setData("<p>You have been <strong><em>subscribed</em></strong>.</p><p>Was that an accident? <a href='#local.unsubURL & urlEncodedFormat(local.email)#'>Click here to <strong><em>unsubscribe</em></strong>.</a></p>");
						}
					}else{
						event.data.message.setTitle("Subscribe Failed");
						event.data.message.setData("<p>Your subscription failed. Sorry!</p>");
					}
				}else{
					event.data.message.setTitle("Subscribe Failed");
					event.data.message.setData("<p>You must enter your email address.</p>");
				}
			</cfscript>

		<cfelseif eventName EQ "scribe-activate">
			<cfscript>
				local.code = "";
				if (structKeyExists(event.getData().externalData, "code")){
					local.code = event.getData().externalData.code;
				}
				local.result = activate(local.code);
				if (local.result){
					event.data.message.setTitle("Activation Complete");
					event.data.message.setData("<p>Your subscription is now active! Thank you!</p>");
				}else{
					event.data.message.setTitle("Activation Failed");
					event.data.message.setData("<p>Sorry! We were not able to activate a subscription with the code provided. Please make sure the full code from the email is included in the URL.</p><p>An activation link will only work once. If your subscription is already active and you click the link again, you will see this message.</p>");
				}
			</cfscript>

		<cfelseif eventName EQ "scribe-unsubscribe">
			<cfscript>
				local.email = "you@yourdomain.com";
				if (structKeyExists(event.getData().externalData, "email")){
					local.email = event.getData().externalData.email;
				}
				if (local.email neq "you@yourdomain.com" and len(trim(local.email))){
					local.result = unsubscribe(local.email);
					if (local.result){
						event.data.message.setTitle("Unsubscribe Successful");
						event.data.message.setData("<p>You have been <strong><em>unsubscribed</em></strong>.</p><p>Was that an accident? <a href='#local.subURL & urlEncodedFormat(local.email)#'>Click here to <strong><em>subscribe</em></strong>.</a></p>");
					}else{
						event.data.message.setTitle("Unsubscribe Failed");
						event.data.message.setData("<p>Your unsubscription failed. Sorry! It looks like the email address you entered is invalid. Please try again.</p>");
					}
				}else{
					event.data.message.setTitle("Unsubscribe Failed");
					event.data.message.setData("<p>You must enter your email address.</p>");
				}
			</cfscript>

		<cfelseif eventName EQ "Scribe-manage-unsub">
			<cfscript>
				local.rtn = StructNew();
				local.rtn.message = true;
				if (not emailIsValid(event.data.externalData.email)){
					local.rtn.message = "You must enter a valid email address";
				}
				try{
					local.sql = "delete from #variables.objQryAdapter.getTablePrefix()##getSetting('TableName')# where email like '#event.data.externalData.email#' and blogId = '#getManager().getBlog().getId()#'";
					local.result = variables.objQryAdapter.makeQuery(local.sql, -1, false);
					local.rtn.message = true;
				}catch(any e){
					local.rtn.message = "Delete failed";
				}
				local.data = arguments.event.data;
				local.data.message.setData(variables.jsonutil.serializeCustom(local.rtn));
			</cfscript>

		<cfelseif eventName EQ "getPodsList">
			<!--- register the pod for the pod-manager --->
			<cfset local.pod = structnew() />
			<cfset local.pod.title = "Scribe" />
			<cfset local.pod.id = "scribe" />
			<cfset arguments.event.addPod(local.pod)>

		<cfelseif eventName EQ "settingsNav">
			<!--- add our settings link --->
			<cfset local.link = structnew() />
			<cfset local.link.owner = "Scribe">
			<cfset local.link.page = "settings" />
			<cfset local.link.title = "Scribe" />
			<cfset local.link.eventName = "Scribe-settings" />
			<cfset arguments.event.addLink(local.link)>

		<cfelseif eventName EQ "Scribe-settings">
			<!--- render settings page --->
			<cfsavecontent variable="local.content">
				<cfoutput>
					<cfinclude template="settings.cfm">
				</cfoutput>
			</cfsavecontent>
			<cfset local.data = arguments.event.data />
			<cfset local.data.message.setTitle("Scribe email subscription settings") />
			<cfset local.data.message.setData(local.content) />

		<cfelseif eventName eq "Scribe-doMail">
			<!--- this event is run by scheduled job, scheduled during "afterPostAdd" --->
			<!--- <cflog file="Scribe" text="Sending email - postid: #event.data.externalData.postId#" /> --->
			<cfset sendEmailByPostId(arguments.event.data.externalData.postId) />
			<!--- cleanup: delete the scheduled job --->
			<cfschedule
				action="delete"
				task="Mango_Scribe_subscription_#arguments.event.data.externalData.postId#" />

		<cfelseif eventName eq "afterPostAdd" or eventName eq "afterPostUpdate">
			<!--- handle post creation: do we email? --->
			<cfscript>
				//default to false, do nothing
				local.doMail = false;

				//if newItem.status = draft, do not mail
				if (event.data.newItem.getStatus() eq "published"){
					//default to email=true
					local.doMail = true;

					//if oldItem.status = published, then this was just a correction, do not email
					if (structKeyExists(event, "oldItem") and not isSimpleValue(event.oldItem) and event.oldItem.getStatus() eq "published"){
						local.doMail = false;
					}
				}

				//get post info
				if (local.doMail){
					local.publishDate = event.data.newItem.getPostedOn();
					local.postId = event.data.newItem.getId();
				}
			</cfscript>
			<cfif local.doMail>
				<!---
					scheduling a one-run job in the past causes it to be run immediately, so we don't
					need to worry about the publish date/time, just use it!
				--->
				<!--- <cflog file="Scribe" text="Scheduling job! Post Title: #event.newItem.getTitle()#" /> --->
				<cfschedule
					task="Mango_Scribe_subscription_#local.postId#"
					url="#getManager().getBlog().getUrl()#generic.cfm?event=scribe-doMail&postId=#local.postId#"
					action="update"
					operation="HTTPRequest"
					interval="once"
					startDate="#dateFormat(local.publishDate,'yyyy-mm-dd')#"
					startTime="#timeFormat(local.publishDate, 'HH:MM:SS')#"
				/>
			</cfif>
		</cfif>
		<cfreturn arguments.event />
	</cffunction>

<!--- private, internal methods --->
	<cffunction name="subscribe" output="false" access="private" returntype="boolean" hint="I subscribe an email address to future posts">
		<cfargument name="email" type="string" required="true"/>
		<cfargument name="requireActivation" type="boolean" required="false" default="true"/>
		<cfset var local = structNew()/>
		<cfset arguments.email = trim(arguments.email)/>
		<!--- validate email address --->
		<cfif not emailIsValid(arguments.email)>
			<cfreturn false />
		</cfif>
		<cfif arguments.requireActivation and getSetting('DoubleOptIn')>
			<cfset local.active = createUUID() />
		<cfelse>
			<cfset local.active = "active" />
		</cfif>
		<!--- check existence (fur current blogId) --->
		<cfset local.sql = "select 1 as rows from #variables.objQryAdapter.getTablePrefix()##getSetting('TableName')# where email='#arguments.email#' and blogId='#getManager().getBlog().getId()#'"/>
		<cfset local.sqlResult = variables.objQryAdapter.makeQuery(local.sql)/>
		<cfif local.sqlResult.recordCount eq 0>
			<!--- insert new subscription --->
			<cfset local.sql = "insert into #variables.objQryAdapter.getTablePrefix()##getSetting('TableName')#(email,blogId,activeFlag) values('#arguments.email#','#getManager().getBlog().getId()#','#local.active#')"/>
			<cfset local.result = variables.objQryAdapter.makeQuery(local.sql, -1, false)/>
			<!--- send activation email --->
			<cfif arguments.requireActivation and getSetting('DoubleOptIn')>
				<cfset sendActivationEmail(arguments.email,local.active)/>
			</cfif>
		<cfelseif not arguments.requireActivation>
			<!--- update so inactives become active --->
			<cfset local.sql = "update #variables.objQryAdapter.getTablePrefix()##getSetting('TableName')# set activeFlag='#local.active#' where email='#arguments.email#' and blogId='#getManager().getBlog().getId()#'"/>
			<cfset local.result = variables.objQryAdapter.makeQuery(local.sql, -1, false)/>
		</cfif>
		<cfreturn true/>
	</cffunction>
	<cffunction name="unsubscribe" output="false" access="private" returntype="boolean" hint="I unsubscribe an email address from future posts">
		<cfargument name="email" type="string" required="true"/>
		<cfset var local = structNew()/>
		<cfset arguments.email = trim(arguments.email)/>
		<!--- validate email address --->
		<cfif not emailIsValid(arguments.email)>
			<cfreturn false />
		</cfif>
		<!--- build sql statement: remove if found --->
		<cfset local.sql = "delete from #variables.objQryAdapter.getTablePrefix()##getSetting('TableName')# where email like '#arguments.email#' and blogId = '#getManager().getBlog().getId()#'"/>
		<!--- execute sql --->
		<cfset local.result = variables.objQryAdapter.makeQuery(local.sql, -1, false)/>
		<cfreturn true/>
	</cffunction>
	<cffunction name="sendEmailByPostId" output="false" access="private" returntype="void" hint="I wrap the sendEmailsRaw function to send emails for a specific post">
		<cfargument name="postId" type="string" required="true"/>
		<cfscript>
			var local = structNew();
			local.args = structNew();

			//lookup subscribers (emails)
			local.args.toEmail = getSubscribers();

			//save time by doing nothing else if there are no subscribers
			if (arrayLen(local.args.toEmail) eq 0){
				return;
			}

			//lookup post metadata (title,uri,excerpt)
			try {
				local.postMgr = getManager().getPostsManager();
				local.post = local.postMgr.getPostById(arguments.postId);
			}catch (any e){
				if (e.errorCode neq "PostNotFound"){ objThrow(e); }
				else { throw(message: "Scribe Plugin: Post not found", detail: "The postid supplied to lookup the post does not reference an existing post."); }
			}
			local.args.postTitle = local.post.getTitle();
			local.args.postURI = getManager().getBlog().getUrl() & local.post.getURL();
			local.args.postExcerpt = local.post.getExcerpt();
			local.args.postBody = local.post.getContent();
			local.args.postAuthor = local.post.getAuthor();

			//use custom from email, if provided
			local.fromEmail = getSetting('fromEmail');
			if (lcase(local.fromEmail) eq '{authoremail}'){
				local.args.fromEmail = getManager().getAuthorsManager().getAuthorById(
					local.post.getAuthorId()
				).getEmail();
			}else if (local.fromEmail neq '' and find('@', local.fromEmail)){
				local.args.fromEmail = local.fromEmail;
			}else{
				local.args.fromEmail = '';
			}

			//if there is no excerpt, use the first 200 characters of the post... (after stripping tags)
			if (not len(local.args.postExcerpt)){
				local.args.postExcerpt = left(reReplaceNoCase(local.args.postBody,"<[^>]*>","", "ALL"), 200);
			}

			//lookup preferences (blog title, email template)
			local.args.blogTitle = getManager().getBlog().getTitle();
	 		local.args.emailTemplate = getSetting("body");
	 		local.args.subjTemplate = getSetting("subject");

			//send emails
			sendEmailsRaw(argumentCollection=local.args);
		</cfscript>
	</cffunction>
	<cffunction name="sendEmailsRaw" output="false" access="private" returntype="void" hint="I send the post email">
		<cfargument name="toEmail" type="array" required="true"/>
		<cfargument name="fromEmail" type="string" required="true"/>
		<cfargument name="blogTitle" type="string" required="true"/>
		<cfargument name="postAuthor" type="string" required="true"/>
		<cfargument name="postTitle" type="string" required="true"/>
		<cfargument name="postURI" type="string" required="true"/>
		<cfargument name="postExcerpt" type="string" required="true"/>
		<cfargument name="postBody" type="string" required="true"/>
		<cfargument name="emailTemplate" type="string" required="true"/>
		<cfargument name="subjTemplate" type="string" required="true"/>
		<cfscript>
			var local = structNew();

			local.emailCount = arrayLen(arguments.toEmail);
			if (local.emailCount eq 0){
				return; //nobody is subscribed
			}

			local.mailer = getManager().getMailer();
			//fill out body template
			local.body = replace(arguments.emailTemplate, "{url}",arguments.postURI,"ALL");
			local.body = replace(local.body, "{excerpt}", arguments.postExcerpt, "ALL");
			local.body = replace(local.body, "{body}", arguments.postBody, "ALL");
			local.body = replace(local.body, "{blogTitle}", arguments.blogTitle, "ALL");
			local.body = replace(local.body, "{postTitle}", arguments.postTitle, "ALL");
			local.body = replace(local.body, "{author}", arguments.postAuthor, "ALL");

			//setup argumentCollection
			local.args = structNew();
			if (arguments.fromEmail neq ''){
				local.args.from = arguments.fromEmail;
			}
			local.args.type = "html";
			local.args.subject = replaceList(
				arguments.subjTemplate,
				"{blogTitle},{postTitle}",
				"#arguments.blogTitle#,#arguments.postTitle#"
			);

			for (local.e = 1; local.e lte local.emailCount; local.e = local.e + 1){
				local.args.to = arguments.toEmail[local.e];

				//last minute updates to the body (per-email address)
				local.unsubURL = getManager().getBlog().getUrl() & "/generic.cfm?event=scribe-unsubscribe&email=#local.e#";
				local.body = replace(local.body, "{unsubscribeUrl}", local.unsubURL, "ALL");
				local.args.body = local.body;

				//send the email
				local.mailer.sendEmail(argumentCollection = local.args);
			}
		</cfscript>
	</cffunction>
	<cffunction name="mailSubscribersCustom" output="false" access="private" returntype="void" hint="I send a custom message to all subscribers">
		<cfargument name="subj" type="string" required="true"/>
		<cfargument name="body" type="string" required="true"/>

		<cfscript>
			var local = structNew();

			//get from and to addresses
			local.from = getSetting('fromEmail');
			if (local.from neq '' and find('@', local.from)){
				local.args.from = local.from;
			}else{
				//this case catches invalid email addresses, OR {authorEmail}
				//in either case, we'll just use the blog default email instead

				//instead of passing an empty string (as below), don't pass anything
				//local.args.from = '';
			}

			//get subscribers
			local.subscribers = getSubscribers();

			//if no subscribers, just kill it here
			local.emailCount = arrayLen(local.subscribers);
			if (arrayLen(local.subscribers) eq 0){
				return;
			}

			//mailing object
			local.mailer = getManager().getMailer();

			//setup argumentCollection
			local.args.type = "html";
			local.args.subject = arguments.subj;
			local.args.body = arguments.body;

			for (local.e = 1; local.e lte local.emailCount; local.e = local.e + 1){
				//set the TO address to the current subscriber
				local.args.to = local.subscribers[local.e];

				//send the email
				local.mailer.sendEmail(argumentCollection = local.args);
			}
		</cfscript>
	</cffunction>
	<cffunction name="emailIsValid" access="private" output="false" returntype="boolean">
		<cfargument name="email" type="string" required="true"/>
		<cfset var local = structNew()/>
		<cfset arguments.email = trim(arguments.email)/>
		<!--- validate email address --->
		<cfset local.emailRegex = "^[^0-9][a-zA-Z0-9_]+([.][a-zA-Z0-9_]+)*[@][a-zA-Z0-9_]+([.][a-zA-Z0-9_]+)*[.][a-zA-Z]{2,4}$"/>
		<cfset local.emailValid = reReplaceNoCase(arguments.email,local.emailRegex,"true")/>
		<cfif (local.emailValid neq "true")>
			<cfreturn false />
		</cfif>
		<cfreturn true />
	</cffunction>
	<cffunction name="getSubscribers" access="private" output="false" returntype="array">
		<cfscript>
			var local = structNew();
			local.sql = "select email from #variables.objQryAdapter.getTablePrefix()##getSetting('TableName')# where blogId='#getManager().getBlog().getId()#' and activeFlag='active'";
			local.sqlResult = variables.objQryAdapter.makeQuery(local.sql);
			return listToArray(valueList(local.sqlResult.email));
		</cfscript>
	</cffunction>
	<cffunction name="sendActivationEmail" access="private" output="false" returntype="void">
		<cfargument name="email" type="string" required="true"/>
		<cfargument name="code" type="string" required="true"/>
		<cfscript>
			var local = structNew();
			local.args = structNew();

			local.confirm = getManager().getBlog().getUrl() & "/generic.cfm?event=scribe-activate&code=#arguments.code#";
			local.deny = getManager().getBlog().getUrl() & "/generic.cfm?event=scribe-unsubscribe&email=#arguments.email#";

			local.args.from = getSetting('fromEmail');
			if (not(len(trim(local.args.from)))){
				structDelete(local.args, "from");
			}

			local.args.to = arguments.email;
			local.args.type="html";
			local.args.subject = "[#getManager().getBlog().getTitle()#] Confirm Subscription";
			local.args.body = "Hello,<br/><br/>You are receiving this email because you subscribed to <strong>#getManager().getBlog().getTitle()#</strong><br/><br/>";
			local.args.body = local.args.body & "To confirm your subscription, please click here: <a href='#local.confirm#'>#local.confirm#</a><br /><br />";
			local.args.body = local.args.body & "If you did not create this subscription, or otherwise want to remove this request, click here: <a href='#local.deny#'>#local.deny#</a>";

			local.mailer = getManager().getMailer();
			local.mailer.sendEmail(argumentCollection = local.args);
		</cfscript>
	</cffunction>
	<cffunction name="activate" access="private" output="false" returntype="boolean">
		<cfargument name="code" type="string" required="true"/>
		<cfscript>
			var local = structNew();
			local.sql = "select 1 as rows from #variables.objQryAdapter.getTablePrefix()##getSetting('TableName')# where blogId='#getManager().getBlog().getId()#' and ActiveFlag='#arguments.code#'";
			local.sqlResult = variables.objQryAdapter.makeQuery(local.sql);
			//any matches found?
			if (not local.sqlResult.recordCount gt 0){
				return false;
			}else{
				local.sql = "update #variables.objQryAdapter.getTablePrefix()##getSetting('TableName')# set ActiveFlag='active' where blogId='#getManager().getBlog().getId()#' and ActiveFlag='#arguments.code#'";
				local.sqlResult = variables.objQryAdapter.makeQuery(local.sql,-1,false);
				return true;
			}
		</cfscript>
	</cffunction>

	<!--- add throw for cfscript usage --->
	<cffunction name="throw">
		<cfargument name="message" type="string" required="false" default="" />
		<cfargument name="detail" type="string" required="false" default="" />
		<cfthrow message="#arguments.message#" detail="#arguments.detail#" />
	</cffunction>
	<cffunction name="objThrow">
		<cfargument name="obj" type="any" required="true" />
		<cfthrow object="#arguments.obj#" />
	</cffunction>

</cfcomponent>