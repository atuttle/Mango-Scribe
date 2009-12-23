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
<cfoutput>
<div id="ScribePod">
	<cfif eventName eq "scribe-pod">
		<h2>Subscribe</h2>
	</cfif>
	<form action="#getManager().getBlog().getURL()#/generic.cfm" method="get">
		#getSetting('podBlurb')#
		<input type="hidden" name="event" value="scribe-subscribe"/>
		<input type="text" name="email" id="scribeEmail" value="you@yourdomain.com" size="15"
			onClick="clearSubInput(this)" onBlur="fixSubInput(this)" />
		<input type="submit" value="subscribe" />
	</form>
	<script type="text/javascript">
		var clearSubInput = function(box){
			if (box.value == 'you@yourdomain.com'){ box.value = ''; }
		}
		var fixSubInput = function(box){
			if (box.value.length == 0){ box.value = 'you@yourdomain.com'; }
		}
	</script>
</div>
</cfoutput>