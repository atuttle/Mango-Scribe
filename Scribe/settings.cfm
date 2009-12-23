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
<cfparam name="form.doubleOptIn" default="false" />
<cftry>
	<cfset tmp = getSetting('podBlurb') />
	<cfcatch>
		<cfset setSettings(podBlurb='') />
		<cfset persistSettings() />
	</cfcatch>
</cftry>
<cfscript>
	//handle settings form post
	if (structKeyExists(form, "body")){
		local.update = structNew();
		local.update.fromEmail = form.fromEmail;
		local.update.subject = form.subject;
		local.update.body = form.body;
		local.update.podTitle = form.podTitle;
		local.update.podBlurb = form.podBlurb;
		local.update.doubleOptIn = form.doubleOptIn;
		setSettings(argumentCollection=local.update);
		persistSettings();
		event.data.message.setstatus("success");
		event.data.message.setType("settings");
		event.data.message.settext("Scribe Settings Updated");
	}
</cfscript>
<!--- handle import form post --->
<cfif structKeyExists(form, "action") and form.action eq "import">
	<cfloop list="#form.addSubscribers#" delimiters=";,#chr(10)##chr(13)#" index="local.e">
		<cfif len(trim(local.e))>
			<cfset subscribe(local.e, false) />
		</cfif>
	</cfloop>
<!--- handle send-mail --->
<cfelseif structKeyExists(form, "action") and form.action eq "sendMail">
	<cfparam name="form.txtMailSubj" default="" />
	<cfparam name="form.txtMailBody" default="" />
	<cfif len(form.txtMailSubj) eq 0 or len(form.txtMailBody) eq 0>
		<cfset local.mailMsg = "Both subject and body are required fields" />
	<cfelse>
		<cfset local.mailMsg = "" />
		<cfset mailSubscribersCustom(form.txtMailSubj, form.txtMailBody)/>
	</cfif>
</cfif> 

<!--- get current subscribed emails --->
<cfset local.subscribers = getSubscribers() />

<style type="text/css">
	#manageSubscribers ul li {
		list-style: none;
		font-size: .9em;
		width: 25%;
		overflow: hidden;
		float: left;
	}
	#manageSubscribers ul {
		padding-left: 0;
	}
	.err {
		display: block;
		border: 0;
		border-top: 1px solid #aa0000 !important;
		border-bottom: 1px solid #aa0000 !important;
		background: #ff99cc !important;
		color: #000000 !important; /* #aa0000 */
	}
	.msg {
		display: block;
		border: 0;
		border-top: 1px solid #cccc33;
		border-bottom: 1px solid #cccc33;
		background: #ffff99;
		color: #000000;
		padding: 8px;
	}
</style>

<cfoutput>
<form method="post" action="">
	<fieldset>
		<legend>Settings</legend>
		<p>
			<label for="podTitle">Pod Title:</label>
			<span class="hint">
				Title to display over the pod.
			</span>
			<span class="field">
				<input type="text" id="podTitle" name="podTitle" value="#getSetting('podTitle')#" size="30" />
			</span>
		</p>
		<p>
			<label for="podBlurb">Pod Blurb:</label>
			<span class="hint">
				This is just some text that gets displayed in the pod. You can leave it blank if you don't want to include any additional information. HTML is allowed.
			</span>
			<span class="field">
				<textarea rows="6" cols="70" name="podBlurb" id="podBlurb">#getSetting('podBlurb')#</textarea>
			</span>
		</p>
		<p>
			<label for="fromEmail">From Email:</label>
			<span class="hint">
				This field is optional. By default, your blog's global default email address will be used.<br/>
				You may use <strong>{authorEmail}</strong> to specify that the post-author's email address should be used.
			</span>
			<span class="field">
				<input type="text" id="fromEmail" name="fromEmail" value="#getSetting('fromEmail')#" size="30" />
			</span>
		</p>
		<p>
			<label for="DoubleOptIn">Use Double Opt-In:</label>
			<span class="field">
				<input type="checkbox" name="DoubleOptIn" id="DoubleOptIn" value="true" <cfif getSetting('DoubleOptIn')>checked="checked" </cfif>/>
				<label for="DoubleOptIn" style="font-weight:normal !important;"
				>Enabling this setting will require user confirmation via link emailed to them.</label>
			</span>
		</p>
		<p>
			<label for="subject">Subject Template:</label>
			<span class="hint">
				<strong>Available fields:</strong><br />{blogTitle}<br />{postTitle}
			</span>
			<span class="field">
				<input type="text" id="subject" name="subject" size="30" value="#getSetting('subject')#" class="required" />
			</span>
		</p>
		<p>
			<label for="body">Body Template:</label>
			<span class="hint">
				<strong>Available fields:</strong><br />
				{blogTitle}<br />{postTitle}<br />{author}<br />{url}<br />{body}<br />{excerpt} (If blank, uses first 200 characters of body)<br />{unsubscribeUrl}
			</span>
			<span class="field">
				<textarea id="body" name="body" rows="6" cols="70" class="required">#htmlEditFormat(getSetting("body"))#</textarea>
			</span>
		</p>
		<input type="submit" value="Save Changes" />
	</fieldset>
</form>
<form id="subscribers" action="" method="post">
	<fieldset>
		<legend>Subscribers</legend>
		<cfparam name="form.action" default="manage" />
		<input type="radio" name="action" id="btnManage" value="manage" <cfif form.action eq "manage">checked="checked"</cfif> /><label for="btnManage">Manage</label>&nbsp;&nbsp;
		<input type="radio" name="action" id="btnExport" value="export" <cfif form.action eq "export">checked="checked"</cfif> /><label for="btnExport">Export</label>&nbsp;&nbsp;
		<input type="radio" name="action" id="btnImport" value="import" <cfif form.action eq "import">checked="checked"</cfif> /><label for="btnImport">Import</label>&nbsp;&nbsp;
		<input type="radio" name="action" id="btnMail" value="sendMail" <cfif form.action eq "sendMail">checked="checked"</cfif> /><label for="btnMail">Send Mail</label>
		<br /><br />
		<div id="manageSubscribers" class="pane">
			<span class="msg">You have #arrayLen(local.subscribers)# subscribers</span><br/>
			<ul>
				<cfloop list="#arrayToList(local.subscribers)#" index="local.thisSubscriber">
					<li>
						<a href="output.cfm?event=Scribe-manage-unsub&email=#local.thisSubscriber#" title="Remove #local.thisSubscriber#"
						><img border="0" alt="Remove #local.thisSubscriber#" src="#getAdminAssetPath()#images/delete.png"/></a>
						#local.thisSubscriber#
					</li>
				</cfloop>
			</ul>
		</div>
		<div id="exportSubscribers" class="pane">
			<p>
				<label for="export">Export Subscribers</label>
				<span class="field">
					<textarea name="export" id="export" rows="10" cols="60"
					><cfloop list="#arrayToList(local.subscribers)#" index="local.thisSubscriber">#local.thisSubscriber#; </cfloop></textarea>
				</span>
			</p>
		</div>
		<div id="massAddSubscribers" class="pane">
			<p>
				<label for="subscribers">Add Subscribers</label>
				<span class="hint">
					Enter one per line, or a comma-delimited or semicolon-delimted list.
				</span>
				<span class="field">
					<textarea name="addSubscribers" id="addSubscribers" rows="10" cols="60"></textarea>
				</span>
			</p>
			<input type="submit" value="Add Subscribers" />
		</div>
		<div id="mailSubscribers" class="pane">
			<p>
				<span class="msg">
					<cfset local.tmp.fromEmail = getSetting('fromEmail') />
					<cfif not len(local.tmp.fromEmail)>
						<cfset local.tmp.fromEmail = "blank = blog global default" />
					<cfelse>
						<cfset local.tmp.fromEmail = "<a href='mailto:#local.tmp.fromEmail#'>#local.tmp.fromEmail#</a>" />
					</cfif>
					Mail will be sent from the "from" email defined above (#local.tmp.fromEmail#). 
					You have #arrayLen(local.subscribers)# subscribers.
				</span><br/>
				<cfparam name="local.mailMsg" default="" />
				<cfif len(local.mailMsg) gt 0>
					<span class="msg err">
						#local.mailMsg#
					</span>
				</cfif>
				<br/>
				<label for="txtMailSubj">Subject:</label>
				<span class="field">
					<input class="required" type="text" name="txtMailSubj" id="txtMailSubj" size="50" />
				</span><br/>
				<label for="txtMailBody">Message body</label>
				<span class="field">
					<textarea class="htmlEditor required" cols="40" rows="15" name="txtMailBody" id="txtMailBody"></textarea>
				</span>
				<br/>
				<input type="submit" value="Send Mail" />
			</p>
		</div>
	</fieldset>
</form>
</cfoutput>
<script type="text/javascript">
	$(document).ready(function(){
		//set default views
		<cfif form.action eq "manage">
			<cfset local.dispSection = "##manageSubscribers" />
		<cfelseif form.action eq "export">
			<cfset local.dispSection = "##exportSubscribers" />
		<cfelseif form.action eq "import">
			<cfset local.dispSection = "##massAddSubscribers" />
		<cfelseif form.action eq "sendMail">
			<cfset local.dispSection = "##mailSubscribers" />
		</cfif>
		$(".pane:not(<cfoutput>#local.dispSection#</cfoutput>)").hide();
		$("<cfoutput>#local.dispSection#</cfoutput>").show();

		//convert links to use ajax
		$("#manageSubscribers ul a").click(function(e){
			var listItem = $(this).parent();
			var email = this.href.split('=');
			email = email[2];
			var confirmDelete = confirm("Remove subscriber:\n\n" + email + "\n\nThis action can not be undone.");
			if (confirmDelete){
				$.getJSON(this.href,function(data){
					if (data.MESSAGE == true){
						$(listItem).fadeOut("slow");
						var _val = $("#export").attr('value');
						var _regex = new RegExp(email + '(; )?');
						_val = _val.replace(_regex, "");
						$("#export").attr('value',_val);
					}else{
						alert(data.MESSAGE);
					}
				});
			}
			e.preventDefault();
		});

		//setup radio button view switches
		$("#btnManage").click(function(){
			$(".pane").hide();
			$("#manageSubscribers").show("slow", jumpDown);
		});
		$("#btnExport").click(function(){
			$(".pane").hide();
			$("#exportSubscribers").show("slow", jumpDown);
		});
		$("#btnImport").click(function(){
			$(".pane").hide();
			$("#massAddSubscribers").show("slow", jumpDown);
		});
		$("#btnMail").click(function(){
			$(".pane").hide();
			$("#mailSubscribers").show("slow", jumpDown);
		});
	});
	function jumpDown(){
		var newLoc = window.location.href.split('#');
		newLoc = newLoc[0] + '#subscribers';
		window.location.href = newLoc;
	}
</script>