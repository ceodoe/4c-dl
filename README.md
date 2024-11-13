# 4c-dl

Download and monitor media content from 4chan threads.

This project has three components:

* `4c-dl` - Download all media from a thread
* `4c-dl-mon` - Monitor a thread (automatically download new media until thread dies)
* `4c-dl-web` - Remotely download all media from a thread

## How to use

You need a UNIX-like environment that can run Bash:

* Any modern Linux distribution
* macOS
* Windows with [WSL](https://learn.microsoft.com/en-us/windows/wsl/install)

You need to make the Bash scripts executable before trying to run them:

* `chmod +x 4c-dl.sh`
* `chmod +x 4c-dl-mon.sh`

### 4c-dl

*4c-dl* is the core component and is required for both other components to work. It is a Bash shell script. It downloads all media files from a specified thread (images, videos and audio). Text posts and the thread itself are not preserved.

Usage:

    ./4c-dl.sh <url>

`<url>` is a full URL to a 4chan thread.

Open the script and change the value of the variable `downloadRoot` to set your download root. The default is `$HOME/Downloads/.lewds` ( ͡° ͜ʖ ͡°)

Subdirectories will be created for each board and thread, so a /wsg/ thread with the thread number 12345678 will have its contents downloaded to `$HOME/Downloads/.lewds/wsg/12345678`.

The default interval for checking for new content is 10 minutes on /b/, and 1 hour for every other board. I recommend you keep these default values, because hammering the servers with requests will likely get you blocked, and non-/b/ threads often live on the scale of days, weeks and months. A random variance of ± 2 minutes is introduced to reduce the chances of being identified as a bot and subsequently blocked. Be nice to the servers, and the servers will be nice to you in return.

### 4c-dl-mon

*4c-dl-mon* is a wrapper around *4c-dl* that automatically monitors a 4chan thread for new content, downloads it, and keeps doing so until the thread 404s or is archived. *4c-dl-mon* assumes that *4c-dl* lives in the same directory as itself.

Usage:

    ./4c-dl-mon.sh <url>

`<url>` is a full URL to a 4chan thread.

The script currently takes exactly *one* non-URL argument:

    ./4c-dl-mon.sh list

Passing `list` to the script will list every instance of *4c-dl-mon* already running, and the URL it was passed. If you try to monitor a thread that's already being monitored, *4c-dl-mon* will tell you, then exit.

The script tries to be smart, and will check the HTTP response code of each thread before acting on it. If the thread has 404ed or is archived, the script will exit gracefully. If we get a 403, we exit whilst complaining. If we get a 5xx series error, we skip the download and wait for the next interval, as these kinds of errors are usually temporary and indicate a server issue.

## 4c-dl-web

*4c-dl-web* is a PHP script that calls *4c-dl*. This means you can send a URL from your phone (or any Web-capable device) to your computer running a Web server with PHP, and have a thread downloaded.

*4c-dl-web* is used by sending it an HTTP request:

    <server>/4c-dl-web.php?user=<username>&pw=<password>&url=<url>

*4c-dl-web* supports both `GET` and `POST` requests, but only one at a time.

* `<server>` is the domain or IP address of your web server
* `<user>` is your username on the server
* `<password>` is your password on the server
* `<url>` is a [percent-encoded](https://en.wikipedia.org/wiki/Percent-encoding) URL to a 4chan thread to download

Before using *4c-dl-web*, you need to edit line 2 of `4c-dl-web.php` and specify the location of *4c-dl* in the value of the `$scriptLoc` variable (default is `/opt/scripts/4c-dl.sh`).

Example request:

    http://192.168.0.123/4c-dl-web.php?user=dude&pw=hunter2&url=https%3A%2F%2Fboards.4chan.org%2Fwsg%2Fthread%2F12345678

It is worth noting that you should only ever use *4c-dl-web* within a local network and not over the wider Internet, as you need to supply your username and password in plain text in order to run *4c-dl* from it.

On its own, having to make a long Web request might seem inconvenient, but with the aid of other tools, it can provide a convenient way to download threads while not at your computer, or even let you download an open thread with one click (from a PC Web browser).

### Example bookmarklet implementation for Web browsers

A bookmarklet is a Web browser bookmark that will perform some action when you click it, instead of just going to a web page. We can leverage this functionality to make a request to your Web server running *4c-dl-web*, and let you download any 4chan thread with a single click! Here's an example bookmarklet:

    javascript:(function(){window.open(`http://192.168.0.123/4c-dl-web.php?user=dude&pw=hunter2&url=${encodeURIComponent(location.href)}`);})();

Select the above line of text, then drag it to your bookmarks toolbar. You can then right-click the resulting bookmark, click *Edit bookmark*, give it a nice name such as `4c-dl`, then replace the `user` and `pw` arguments in the URL with your server username and password. You can now browse to a 4chan thread you'd like to download, click the bookmarklet, and the thread will be downloaded automatically. Click "Close" on the temporary page to close it.

### Example Android implementation of *4c-dl-web*

#### Introduction
The reason *4c-dl-web* exists in the first place, is because I wanted to be able to just share a thread URL from my phone and have it get downloaded on my PC. This can be accomplished with an Android phone and a few apps:

* [Readchan](https://play.google.com/store/apps/details?id=com.deezus.pchan&hl=en-US) - A great 4chan reader app (you can also just use a Web browser)
* [Tasker](https://play.google.com/store/apps/details?id=net.dinglisch.android.taskerm&hl=en-US) - Automation framework for Android
* [AutoShare](https://play.google.com/store/apps/details?id=com.joaomgcd.autoshare&hl=en-US) - Tasker plugin that provides a share target

Note that Tasker and AutoShare cost money, but they are cheap and well worth it if you enjoy automation. They are also both useful for lots more than just downloading 4chan threads.

#### Setup

If you're already familiar with *Tasker*, here's a description of the profile:
<details>
    <summary>Tasker profile description</summary>

    Profile: 4c-dl
    	Event: AutoShare [ Configuration:Command: 4c-dl
    Sender: all
    Subject: all
    Text: all
    File: all ]
    
    
    
    Enter Task: 4c-dl
    
    A1: Variable Set [
         Name: %FCDL_URL
         To: %astext
         Structure Output (JSON, etc): On ]
    
    A2: Variable Convert [
         Name: %FCDL_URL
         Function: URL Encode
         Store Result In: %FCDL_URL
         Mode: Default ]
    
    A3: HTTP Request [
         Method: POST
         URL: http://192.168.0.123/4c-dl-web.php
         Body: user=dude&pw=hunter2&url=%FCDL_URL
         Timeout (Seconds): 30
         Structure Output (JSON, etc): On
         Continue Task After Error:On ]
    
    A4: If [ %http_response_code ~ 200 ]
    
        A5: Vibrate [
             Time: 200 ]
    
    A6: Else
    
        A7: Vibrate [
             Time: 100 ]
    
        A8: Wait [
             MS: 150
             Seconds: 0
             Minutes: 0
             Hours: 0
             Days: 0 ]
    
        A9: Vibrate [
             Time: 100 ]
    
        A10: Notify [
              Title: 4c-dl: %http_response_code
              Text: url=%FCDL_URL
             
             %http_headers()
              Number: 0
              Priority: 3
              LED Colour: Red
              LED Rate: 0 ]
    
    A11: End If

Edit the request body in A3 to reflect your username and password on the server.
</details>

<details>
<summary>As XML</summary>

    <TaskerData sr="" dvi="1" tv="6.3.13">
        <Profile sr="prof24" ve="2">
            <cdate>1729314042669</cdate>
            <edate>1731517233801</edate>
            <flags>8</flags>
            <id>24</id>
            <mid0>10</mid0>
            <nme>4c-dl</nme>
            <Event sr="con0" ve="2">
                <code>580953799</code>
                <pri>0</pri>
                <Bundle sr="arg0">
                    <Vals sr="val">
                        <com.twofortyfouram.locale.intent.extra.BLURB>Command: 4c-dl
    Sender: all
    Subject: all
    Text: all
    File: all</com.twofortyfouram.locale.intent.extra.BLURB>
                        <com.twofortyfouram.locale.intent.extra.BLURB-type>java.lang.String</com.twofortyfouram.locale.intent.extra.BLURB-type>
                        <configcaseinsensitiveimage>false</configcaseinsensitiveimage>
                        <configcaseinsensitiveimage-type>java.lang.Boolean</configcaseinsensitiveimage-type>
                        <configcaseinsensitivesub>false</configcaseinsensitivesub>
                        <configcaseinsensitivesub-type>java.lang.Boolean</configcaseinsensitivesub-type>
                        <configcaseinsensitivetext>false</configcaseinsensitivetext>
                        <configcaseinsensitivetext-type>java.lang.Boolean</configcaseinsensitivetext-type>
                        <configcommand>4c-dl</configcommand>
                        <configcommand-type>java.lang.String</configcommand-type>
                        <configexactimage>false</configexactimage>
                        <configexactimage-type>java.lang.Boolean</configexactimage-type>
                        <configexactsub>false</configexactsub>
                        <configexactsub-type>java.lang.Boolean</configexactsub-type>
                        <configexacttext>false</configexacttext>
                        <configexacttext-type>java.lang.Boolean</configexacttext-type>
                        <configimage>&lt;null&gt;</configimage>
                        <configimage-type>java.lang.String</configimage-type>
                        <configregeximage>false</configregeximage>
                        <configregeximage-type>java.lang.Boolean</configregeximage-type>
                        <configregexsub>false</configregexsub>
                        <configregexsub-type>java.lang.Boolean</configregexsub-type>
                        <configregextext>false</configregextext>
                        <configregextext-type>java.lang.Boolean</configregextext-type>
                        <configsubject>&lt;null&gt;</configsubject>
                        <configsubject-type>java.lang.String</configsubject-type>
                        <configtext>&lt;null&gt;</configtext>
                        <configtext-type>java.lang.String</configtext-type>
                        <net.dinglisch.android.tasker.EXTRA_NSR_DEPRECATED>true</net.dinglisch.android.tasker.EXTRA_NSR_DEPRECATED>
                        <net.dinglisch.android.tasker.EXTRA_NSR_DEPRECATED-type>java.lang.Boolean</net.dinglisch.android.tasker.EXTRA_NSR_DEPRECATED-type>
                        <net.dinglisch.android.tasker.RELEVANT_VARIABLES>&lt;StringArray sr=""&gt;&lt;_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES0&gt;%ascommand
    Selected Command
    &lt;/_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES0&gt;&lt;_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES1&gt;%asfile()
    Shared Files
    &lt;/_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES1&gt;&lt;_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES2&gt;%assubject
    Shared Subject
    &lt;/_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES2&gt;&lt;_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES3&gt;%astext
    Shared Text
    &lt;/_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES3&gt;&lt;/StringArray&gt;</net.dinglisch.android.tasker.RELEVANT_VARIABLES>
                        <net.dinglisch.android.tasker.RELEVANT_VARIABLES-type>[Ljava.lang.String;</net.dinglisch.android.tasker.RELEVANT_VARIABLES-type>
                        <net.dinglisch.android.tasker.extras.REQUESTED_TIMEOUT>10000</net.dinglisch.android.tasker.extras.REQUESTED_TIMEOUT>
                        <net.dinglisch.android.tasker.extras.REQUESTED_TIMEOUT-type>java.lang.Integer</net.dinglisch.android.tasker.extras.REQUESTED_TIMEOUT-type>
                        <net.dinglisch.android.tasker.extras.VARIABLE_REPLACE_KEYS>configcommand plugininstanceid plugintypeid </net.dinglisch.android.tasker.extras.VARIABLE_REPLACE_KEYS>
                        <net.dinglisch.android.tasker.extras.VARIABLE_REPLACE_KEYS-type>java.lang.String</net.dinglisch.android.tasker.extras.VARIABLE_REPLACE_KEYS-type>
                        <net.dinglisch.android.tasker.subbundled>true</net.dinglisch.android.tasker.subbundled>
                        <net.dinglisch.android.tasker.subbundled-type>java.lang.Boolean</net.dinglisch.android.tasker.subbundled-type>
                        <plugininstanceid>851612a1-a2ff-4d7e-a473-fb48f73453c5</plugininstanceid>
                        <plugininstanceid-type>java.lang.String</plugininstanceid-type>
                        <plugintypeid>com.joaomgcd.autoshare.intent.IntentReceiveShareEvent</plugintypeid>
                        <plugintypeid-type>java.lang.String</plugintypeid-type>
                    </Vals>
                </Bundle>
                <Str sr="arg1" ve="3">com.joaomgcd.autoshare</Str>
                <Str sr="arg2" ve="3">com.joaomgcd.autoshare.activity.ActivityConfigReceiveShareEvent</Str>
                <Int sr="arg3" val="1"/>
            </Event>
        </Profile>
        <Task sr="task10">
            <cdate>1729311273738</cdate>
            <edate>1731517207925</edate>
            <id>10</id>
            <nme>4c-dl</nme>
            <pri>6</pri>
            <Action sr="act0" ve="7">
                <code>547</code>
                <Str sr="arg0" ve="3">%FCDL_URL</Str>
                <Str sr="arg1" ve="3">%astext</Str>
                <Int sr="arg2" val="0"/>
                <Int sr="arg3" val="0"/>
                <Int sr="arg4" val="0"/>
                <Int sr="arg5" val="3"/>
                <Int sr="arg6" val="1"/>
            </Action>
            <Action sr="act1" ve="7">
                <code>596</code>
                <Str sr="arg0" ve="3">%FCDL_URL</Str>
                <Int sr="arg1" val="19"/>
                <Str sr="arg2" ve="3">%FCDL_URL</Str>
                <Int sr="arg3" val="0"/>
            </Action>
            <Action sr="act10" ve="7">
                <code>38</code>
            </Action>
            <Action sr="act2" ve="7">
                <code>339</code>
                <se>false</se>
                <Bundle sr="arg0">
                    <Vals sr="val">
                        <net.dinglisch.android.tasker.RELEVANT_VARIABLES>&lt;StringArray sr=""&gt;&lt;_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES0&gt;%http_cookies
    Cookies
    The cookies the server sent in the response in the Cookie:COOKIE_VALUE format. You can use this directly in the 'Headers' field of the HTTP Request action&lt;/_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES0&gt;&lt;_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES1&gt;%http_data
    Data
    Data that the server responded from the HTTP request.&lt;/_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES1&gt;&lt;_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES2&gt;%http_file_output
    File Output
    Will always contain the file's full path even if you specified a directory as the File to save.&lt;/_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES2&gt;&lt;_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES3&gt;%http_response_code
    Response Code
    The HTTP Code the server responded&lt;/_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES3&gt;&lt;_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES4&gt;%http_headers()
    Response Headers
    The HTTP Headers the server sent in the response. Each header is in the 'key:value' format&lt;/_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES4&gt;&lt;_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES5&gt;%http_response_length
    Response Length
    The size of the response in bytes&lt;/_array_net.dinglisch.android.tasker.RELEVANT_VARIABLES5&gt;&lt;/StringArray&gt;</net.dinglisch.android.tasker.RELEVANT_VARIABLES>
                        <net.dinglisch.android.tasker.RELEVANT_VARIABLES-type>[Ljava.lang.String;</net.dinglisch.android.tasker.RELEVANT_VARIABLES-type>
                    </Vals>
                </Bundle>
                <Int sr="arg1" val="1"/>
                <Int sr="arg10" val="0"/>
                <Int sr="arg11" val="0"/>
                <Int sr="arg12" val="1"/>
                <Str sr="arg2" ve="3">http://192.168.0.123/4c-dl-web.php</Str>
                <Str sr="arg3" ve="3"/>
                <Str sr="arg4" ve="3"/>
                <Str sr="arg5" ve="3">user=dude&amp;pw=hunter2&amp;url=%FCDL_URL</Str>
                <Str sr="arg6" ve="3"/>
                <Str sr="arg7" ve="3"/>
                <Int sr="arg8" val="30"/>
                <Int sr="arg9" val="0"/>
            </Action>
            <Action sr="act3" ve="7">
                <code>37</code>
                <ConditionList sr="if">
                    <Condition sr="c0" ve="3">
                        <lhs>%http_response_code</lhs>
                        <op>2</op>
                        <rhs>200</rhs>
                    </Condition>
                </ConditionList>
            </Action>
            <Action sr="act4" ve="7">
                <code>61</code>
                <Int sr="arg0" val="200"/>
            </Action>
            <Action sr="act5" ve="7">
                <code>43</code>
            </Action>
            <Action sr="act6" ve="7">
                <code>61</code>
                <Int sr="arg0">
                    <var>100</var>
                </Int>
            </Action>
            <Action sr="act7" ve="7">
                <code>30</code>
                <Int sr="arg0">
                    <var>150</var>
                </Int>
                <Int sr="arg1" val="0"/>
                <Int sr="arg2" val="0"/>
                <Int sr="arg3" val="0"/>
                <Int sr="arg4" val="0"/>
            </Action>
            <Action sr="act8" ve="7">
                <code>61</code>
                <Int sr="arg0">
                    <var>100</var>
                </Int>
            </Action>
            <Action sr="act9" ve="7">
                <code>523</code>
                <Str sr="arg0" ve="3">4c-dl: %http_response_code</Str>
                <Str sr="arg1" ve="3">url=%FCDL_URL

    %http_headers()</Str>
                <Str sr="arg10" ve="3"/>
                <Str sr="arg11" ve="3"/>
                <Str sr="arg12" ve="3"/>
                <Img sr="arg2" ve="2"/>
                <Int sr="arg3" val="0"/>
                <Int sr="arg4" val="0"/>
                <Int sr="arg5" val="3"/>
                <Int sr="arg6" val="0"/>
                <Int sr="arg7" val="0"/>
                <Int sr="arg8" val="0"/>
                <Str sr="arg9" ve="3"/>
            </Action>
        </Task>
    </TaskerData>

</details>

If you save the above XML data as `4c-dl.prf.xml`, then send it to your Android device, you can import the profile by long-pressing the *Profiles* tab in *Tasker*.

----

In *AutoShare*, tap *Manage Commands*, then make a command named *4c-dl*. You can also go to *Share Targets* and uncheck everything besides *AutoShare Command*, as that's all we need.

In *Tasker*, make a new profile by tapping the big plus sign, then *State* > *Plugin* > *AutoShare*. The edit view for the profile will show up. Tap the pencil icon next to "Configuration" to open AutoShare, then *Command* > *Command Filter*. Select *4c-dl* from the list, the command you made earlier. Now go back one step and click the check mark at the top-right of the screen. You will be returned to the edit view. Click the back arrow, and you will prompted to select a task for this new profile.

Tap "New Task", then optionally give the task a name, then tap the check mark. You will then be presented with the task edit view.

For each following step, click the plus sign, search and select the function listed, fill in the listed data, then click the back button:

* Function: Variable Set
    * Name: %FCDL_URL
    * To: %astext
* Function: Variable Convert
    * Name: %FCDL_URL
    * Function: URL Encode
    * Store Result In: %FCDL_URL
* Function: HTTP Request
    * Method: POST
    * URL: http://192.168.0.123/4c-dl-web.php
    * Body: user=dude&pw=hunter2&url=%FCDL_URL
    * Continue Task After Error: Checked

Remember to replace the username and password in the HTTP Request Body to your username and password on the server!

The following steps are optional, but nice feedback to whether the request was successful. Your phone will vibrate once for success, or twice for failure.

* Function: If
    * Condition: %http_response_code ~ 200
    * (tap "If" after pressing back)
* Function: Vibrate
    * Time: 200
* Function: Else
* Function: Vibrate
    * Time: 100
* Function: Wait
    * MS: 150
* Function: Vibrate
    * Time: 100
* Function: Notify
    * Title: 4c-dl: %http_response_code
    * Text: %http_headers()
* Function: End If

#### Usage
Done! Now all you need to do is use it. Share a 4chan thread URL from *Readchan* or your browser, then pick *AutoShare* when it asks for a share target. If you only have the *4c-dl* command in *AutoShare*, it will send the request to your server automatically. If you have more than one command, a menu will pop up, then tap *4c-dl*. The URL you shared will be picked up by AutoShare, sent to Tasker for processing, then the Web request will be made to your server. *4c-dl-web*, in turn, will launch *4c-dl*, which downloads the thread contents to your server.

## Security

4c-dl is not meant to be exposed to the open internet. If you want to remotely download 4chan threads, set up a WireGuard server on your home network, connect to that, then use *4c-dl* as you would if you were home.

## Privacy

*4c-dl* collects no data.

## Contributing

Feel free to submit issues or pull requests. Please note that since this is meant to run internally on a trusted network, I'm not gonna accept contributions that needlessly complicate the scripts just to mitigate security issues that are unrealistic in that context.

## License

    4c-dl - Download and monitor 4chan threads
    Copyright (C) 2024 ceodoe

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
